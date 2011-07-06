//new Handle:g_hFwdPluginsLoaded;

new bool:g_bMatchModeLoaded;

stock bool:IsMatchModeInProgress() { return g_bMatchModeLoaded; }

RegisterMatchModeCommands()
{
	RegAdminCmd("sm_forcematch", ForceMatchCmd, ADMFLAG_CONFIG, "Loads matchmode on a given config. Will unload a previous config if one is loaded");
	RegAdminCmd("sm_softmatch", SoftMatchCmd, ADMFLAG_CONFIG, "Loads matchmode on a given config only if no match is currently running.");
	RegAdminCmd("sm_resetmatch", ResetMatchCmd, ADMFLAG_CONFIG, "Unloads matchmode if it is currently running");
	RegServerCmd("command_buffer_done_callback", CmdBufDoneCallback);
	//	g_hFwdPluginsLoaded = CreateGlobalForward("LGO_OnMatchModeLoaded", ET_Event, Param_String);
	//	g_hFwdMMUnload = CreateGlobalForward("LGO_OnMatchModeUnloaded", ET_Event);
}

MatchMode_ExecuteConfigs()
{
	if(IsMatchModeInProgress())
	{
		decl String:mapbuf[128];
		GetCurrentMap(mapbuf, sizeof(mapbuf));
		StrCat(mapbuf, sizeof(mapbuf), ".cfg");
	
		ServerCommand("exec cfgogl/lgofnoc.cfg");
		ExecuteConfigCfg("lgofnoc.cfg");
	
		ServerCommand("exec cfgogl/%s", mapbuf);
		ExecuteConfigCfg(mapbuf);
	}
}

public Action:ResetMatchCmd(client, args)
{
	if(!IsMatchModeInProgress()) 
	{
		ReplyToCommand(client, "There is no LGOFNOC match in progress");
	}
	else
	{
		MatchMode_Unload();
	}
	
	
	return Plugin_Handled;
}

public Action:SoftMatchCmd(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "Must specify a config to use");
		return Plugin_Handled;
	}
	if(IsMatchModeInProgress()) return Plugin_Handled;
	
	decl String:configbuf[64];
	GetCmdArg(1, configbuf, sizeof(configbuf));
	if(!MatchMode_Load(configbuf))
	{
		ReplyToCommand(client, "Matchmode failed to load!");
	}
	return Plugin_Handled;
}

public Action:ForceMatchCmd(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "Must specify a config to use");
		return Plugin_Handled;
	}
	
	decl String:configbuf[64];
	GetCmdArg(1, configbuf, sizeof(configbuf));
	if(!MatchMode_Load(configbuf))
	{
		ReplyToCommand(client, "Matchmode failed to load!");
	}
	return Plugin_Handled;	 
}

bool:MatchMode_Load(const String:config[])
{
	if(IsMatchModeInProgress())
	{
		MatchMode_Unload(false);
	}
	if(!SetCustomCfg(config))
	{
		PrintToChatAll("No such config %s", config);
		return false;
	}
	LoadMapInfo();
	PrintToChatAll("Starting Matchmode with config %s", config);
	g_bMatchModeLoaded=true;
	ServerCommand("sm plugins load_unlock");
	UnloadAllPluginsButMe();
	ServerCommand("exec cfgogl/lgofnoc_plugins.cfg");
	ExecuteConfigCfg("lgofnoc_plugins.cfg");
	ServerCommand("sm plugins load_lock");
	ServerCommand("command_buffer_done_callback"); // see you in the next call
	return true;
}

public Action:CmdBufDoneCallback(args)
{
	// We're back! Only a tick!
	MatchModeLoad_PostPlugins();
	return Plugin_Handled;
}


MatchModeLoad_PostPlugins()
{
	// Sequential!

//  Maybe later
//	Call_StartForward(g_hFwdPluginsLoaded);
//	Call_PushString(config);
//	Call_Finish();

	ServerCommand("exec cfgogl/lgofnoc_once.cfg");
	ExecuteConfigCfg("lgofnoc_once.cfg");
	RestartMapCountdown(5.0);
	PrintToChatAll("Config %s loaded! Map will restart in 5 seconds.", g_sCurrentConfig);
	return true;
}

MatchMode_Unload(bool:restartMap=true)
{
//	Call_StartForward(g_hFwdMMUnload);
//	Call_Finish();
	g_bMatchModeLoaded=false;
	ServerCommand("sm plugins load_unlock");
	UnloadAllPluginsButMe();
	CloseMapInfo();
	PrintToChatAll("Lgofnoc Matchmode unloaded.");
	if(restartMap) {
		RestartMapCountdown(5.0);
		PrintToChatAll("Map will restart in 5 seconds.");
	}
}

// Unload all plugins except one
stock UnloadAllPluginsButMe()
{
	new Handle:plugit = GetPluginIterator();
	new Handle:myself = GetMyHandle();
	while (MorePlugins(plugit))
	{
		new Handle:plugin = ReadPlugin(plugit);
		if(plugin != myself)
		{
			UnloadPlugin(plugin);
		}
	}
}

stock UnloadPlugin(Handle:plugin)
{
	static String:namebuf[PLATFORM_MAX_PATH]; // probably a good idea

	GetPluginFilename(plugin, namebuf, sizeof(namebuf));
	ServerCommand("sm plugins unload %s", namebuf);
}

RestartMapCountdown(Float:time)
{
	CreateTimer(time, RestartMapCallback);
}

public Action:RestartMapCallback(Handle:timer)
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	ForceChangeLevel(map, "Restarting Map for Lgofnoc");
	return Plugin_Handled;
}
