#define CVS_CVAR_MAXLEN 64

#define CVARS_DEBUG	0

enum CVSEntry
{
	Handle:CVSE_cvar,
	String:CVSE_oldval[CVS_CVAR_MAXLEN],
	String:CVSE_newval[CVS_CVAR_MAXLEN]
}

static Handle:CvarSettingsArray;
static Handle:ScalingCvar;
static bool:bTrackingStarted;

InitCvarSettings()
{
	CvarSettingsArray = CreateArray(_:CVSEntry);
	RegConsoleCmd("lgofnoc_cvarsettings", CVS_CvarSettings_Cmd, "List all ConVars being enforced by Lgofnoc");
	RegConsoleCmd("lgofnoc_cvardiff", CVS_CvarDiff_Cmd, "List any ConVars that have been changed from their initialized values");
	
	RegServerCmd("lgofnoc_addcvar", CVS_AddCvar_Cmd, "Add a ConVar to be set by Lgofnoc");
	RegServerCmd("lgofnoc_addcvar_tiered", CVS_AddCvar_Tiered_Cmd, "Add a ConVar with several possible values, one of which is selected based on player number and set by Lgofnoc");
	RegServerCmd("lgofnoc_setcvars", CVS_SetCvars_Cmd, "Starts enforcing ConVars that have been added.");
	RegServerCmd("lgofnoc_resetcvars", CVS_ResetCvars_Cmd, "Resets enforced ConVars.  Cannot be used during a match!");

	ScalingCvar = CreateConVar("lgofnoc_cvar_tier", "1", "What cvar tier to apply when reading lgofnoc_addcvar_tiered commands.", FCVAR_PLUGIN);
}

public Action:CVS_SetCvars_Cmd(args)
{
	#if CVARS_DEBUG
		LogMessage("[Lgofnoc] CvarSettings: No longer accepting new ConVars");
	#endif
	SetEnforcedCvars();
	bTrackingStarted = true;
}

public Action:CVS_AddCvar_Cmd(args)
{
	if (args != 2)
	{
		PrintToServer("Usage: lgofnoc_addcvar <cvar> <newValue>");
		#if CVARS_DEBUG
			decl String:cmdbuf[MAX_NAME_LENGTH];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			LogError("[Lgofnoc] Invalid Cvar Add: %s", cmdbuf);
		#endif
		return Plugin_Handled;
	}
	
	decl String:cvar[CVS_CVAR_MAXLEN], String:newval[CVS_CVAR_MAXLEN];
	GetCmdArg(1, cvar, sizeof(cvar));
	GetCmdArg(2, newval, sizeof(newval));
	
	AddCvar(cvar, newval);
	
	return Plugin_Handled;
}

public Action:CVS_AddCvar_Tiered_Cmd(args)
{
	new playernum = GetConVarInt(ScalingCvar);
	if (args < ++playernum)
	{
		PrintToServer("Usage: lgofnoc_addcvar_tiered <cvar> <1v1Value> <2v2Value> <...>");
		#if CVARS_DEBUG
			decl String:cmdbuf[MAX_NAME_LENGTH];
			GetCmdArgString(cmdbuf, sizeof(cmdbuf));
			LogError("[Lgofnoc] Invalid Cvar Add: %s", cmdbuf);
		#endif
		return Plugin_Handled;
	}
	
	decl String:cvar[CVS_CVAR_MAXLEN], String:newval[CVS_CVAR_MAXLEN];
	GetCmdArg(1, cvar, sizeof(cvar));
	GetCmdArg(playernum, newval, sizeof(newval));
	
	AddCvar(cvar, newval);
	
	return Plugin_Handled;
}

public Action:CVS_ResetCvars_Cmd(args)
{
	// Maybe change to matchmode check
	/*if (IsPluginEnabled())
	{
		PrintToServer("Can't reset tracking in the middle of a match");
		return Plugin_Handled;
	}*/
	ClearAllCvarSettings();
	PrintToServer("Server CVar Tracking Information Reset!");
	return Plugin_Handled;
}

public Action:CVS_CvarSettings_Cmd(client, args)
{
	if (!bTrackingStarted)
	{
		ReplyToCommand(client, "[Lgofnoc] CVar tracking has not been started!! THIS SHOULD NOT OCCUR DURING A MATCH!");
		return Plugin_Handled;
	}
	
	new cvscount = GetArraySize(CvarSettingsArray);
	decl cvsetting[CVSEntry];
	decl String:buffer[CVS_CVAR_MAXLEN], String:name[CVS_CVAR_MAXLEN];
	
	ReplyToCommand(client, "[Lgofnoc] Enforced Server CVars (Total %d)", cvscount);
	
	GetCmdArg(1, buffer, sizeof(buffer));
	new offset = StringToInt(buffer);
	
	if (offset < 0 || offset > cvscount) return Plugin_Handled;
	
	new temp = cvscount;
	if (offset + 20 < cvscount) temp = offset + 20;
	
	for (new i = offset; i < temp && i < cvscount; i++)
	{
		GetArrayArray(CvarSettingsArray, i, cvsetting[0]);
		GetConVarString(cvsetting[CVSE_cvar], buffer, sizeof(buffer));
		GetConVarName(cvsetting[CVSE_cvar], name, sizeof(name));
		ReplyToCommand(client, "[Lgofnoc] Server CVar: %s, Desired Value: %s, Current Value: %s", name, cvsetting[CVSE_newval], buffer);
	}
	if (offset + 20 < cvscount) ReplyToCommand(client, "[Lgofnoc] To see more CVars, use lgofnoc_cvarsettings %d", offset+20);
	return Plugin_Handled;
}

public Action:CVS_CvarDiff_Cmd(client, args)
{
	if (!bTrackingStarted)
	{
		ReplyToCommand(client, "[Lgofnoc] CVar tracking has not been started!! THIS SHOULD NOT OCCUR DURING A MATCH!");
		return Plugin_Handled;
	}
	
	new cvscount = GetArraySize(CvarSettingsArray);
	decl cvsetting[CVSEntry];
	decl String:buffer[CVS_CVAR_MAXLEN], String:name[CVS_CVAR_MAXLEN];
	
	GetCmdArg(1, buffer, sizeof(buffer));
	new offset = StringToInt(buffer);
	
	if (offset > cvscount) return Plugin_Handled;
	
	new foundCvars;
	
	while (offset < cvscount && foundCvars < 20)
	{
		GetArrayArray(CvarSettingsArray, offset, cvsetting[0]);
		GetConVarString(cvsetting[CVSE_cvar], buffer, sizeof(buffer));
		GetConVarName(cvsetting[CVSE_cvar], name, sizeof(name));
		if (!StrEqual(cvsetting[CVSE_newval], buffer))
		{
			ReplyToCommand(client, "[Lgofnoc] Server CVar: %s, Desired Value: %s, Current Value: %s", name, cvsetting[CVSE_newval], buffer);
			foundCvars++;
		}
		offset++;
	}
	
	if (offset < cvscount) ReplyToCommand(client, "[Lgofnoc] To see more CVars, use lgofnoc_cvarsettings %d", offset);
	return Plugin_Handled;
}

ClearAllCvarSettings()
{
	bTrackingStarted = false;
	new cvsetting[CVSEntry];
	for (new i; i < GetArraySize(CvarSettingsArray); i++)
	{
		GetArrayArray(CvarSettingsArray, i, cvsetting[0]);
		
		UnhookConVarChange(cvsetting[CVSE_cvar], CVS_ConVarChange);
		SetConVarString(cvsetting[CVSE_cvar], cvsetting[CVSE_oldval]);
	}
	ClearArray(CvarSettingsArray);
}

static SetEnforcedCvars()
{
	new cvsetting[CVSEntry];
	for (new i; i < GetArraySize(CvarSettingsArray); i++)
	{
		GetArrayArray(CvarSettingsArray, i, cvsetting[0]);
		#if CVARS_DEBUG
			decl String:debug_buffer[CVS_CVAR_MAXLEN];
			GetConVarName(cvsetting[CVSE_cvar], debug_buffer, sizeof(debug_buffer));
			LogMessage("cvar = %s, newval = %s", debug_buffer, cvsetting[CVSE_newval]);
		#endif
		SetConVarString(cvsetting[CVSE_cvar], cvsetting[CVSE_newval]);
	}
}

static AddCvar(const String:cvar[], const String:newval[])
{
	if (bTrackingStarted)
	{
		#if CVARS_DEBUG
		LogMessage("[Lgofnoc] CvarSettings: Attempt to track new cvar %s during a match!", cvar);
		#endif
		return;
	}
	
	if (strlen(cvar) >= CVS_CVAR_MAXLEN)
	{
		LogError("[Lgofnoc] CvarSettings: CVar Specified (%s) is longer than max cvar/value length (%d)", cvar, CVS_CVAR_MAXLEN);
		return;
	}
	if (strlen(newval) >= CVS_CVAR_MAXLEN)
	{
		LogError("[Lgofnoc] CvarSettings: New Value Specified (%s) is longer than max cvar/value length (%d)", newval, CVS_CVAR_MAXLEN);
		return;
	}
	
	new Handle:newCvar = FindConVar(cvar);
	
	if (newCvar == INVALID_HANDLE)
	{
		LogError("[Lgofnoc] CvarSettings: Could not find CVar specified (%s)", cvar);
		return;
	}
	
	decl newEntry[CVSEntry];
	decl String:cvarBuffer[CVS_CVAR_MAXLEN];
	for (new i; i < GetArraySize(CvarSettingsArray); i++)
	{
		GetArrayArray(CvarSettingsArray, i, newEntry[0]);
		GetConVarName(newEntry[CVSE_cvar], cvarBuffer, CVS_CVAR_MAXLEN);
		if (StrEqual(cvar, cvarBuffer, false))
		{
			// Already tracking this cvar, but tracking not started
			// Modify the value
			strcopy(newEntry[CVSE_newval], CVS_CVAR_MAXLEN, newval);
			SetArrayArray(CvarSettingsArray, i, newEntry[0]);
		}
	}
	
	GetConVarString(newCvar, cvarBuffer, CVS_CVAR_MAXLEN);
	
	newEntry[CVSE_cvar] = newCvar;
	strcopy(newEntry[CVSE_oldval], CVS_CVAR_MAXLEN, cvarBuffer);
	strcopy(newEntry[CVSE_newval], CVS_CVAR_MAXLEN, newval);
	
	HookConVarChange(newCvar, CVS_ConVarChange);
	
	#if CVARS_DEBUG
		LogMessage("[Lgofnoc] CvarSettings: cvar = %s, newval = %s, oldval = %s", cvar, newval, cvarBuffer);
	#endif
	
	PushArrayArray(CvarSettingsArray, newEntry[0]);
}

public CVS_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (bTrackingStarted)
	{
		decl String:name[CVS_CVAR_MAXLEN];
		GetConVarName(convar, name, sizeof(name));
		PrintToChatAll("!!! [Lgofnoc] Tracked Server CVar \"%s\" changed from \"%s\" to \"%s\" !!!", name, oldValue, newValue);
	}
}
