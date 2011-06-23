//new Handle:g_hFwdPluginsLoaded;

new bool:g_bMatchModeLoaded;

stock bool:IsMatchModeInProgress() { return g_bMatchModeLoaded; }

MatchMode_OnPluginStart()
{
	RegAdminCmd("sm_forcematch", ForceMatchCmd, ADMFLAG_CONFIG, "Loads matchmode on a given config. Will unload a previous config if one is loaded");
	RegServerCmd("command_buffer_done_callback", CmdBufDoneCallback);
}

MatchMode_OnConfigsExecuted()
{
	if(IsMatchModeInProgress())
	{
		decl String:mapbuf[128];
		GetCurrentMap(mapbuf, sizeof(mapbuf));
		StrCat(mapbuf, sizeof(mapbuf), ".cfg");
	
		ServerCommand("exec cfgogl/confogl.cfg");
		ExecuteConfigCfg("confogl.cfg");
	
		ServerCommand("exec cfgogl/%s", mapbuf);
		ExecuteConfigCfg(mapbuf);
	}
}

MatchMode_APL()
{
//	g_hFwdPluginsLoaded = CreateGlobalForward("LGO_OnMatchModeLoaded", ET_Event, Param_String);
//	g_hFwdMMUnload = CreateGlobalForward("LGO_OnMatchModeUnloaded", ET_Event);
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

public Action:ResetMatchCmd(client, args)
{
	MatchMode_Unload();
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
	PrintToChatAll("Starting Matchmode with config %s", config);
	g_bMatchModeLoaded=true;
	ServerCommand("sm plugins load_unlock");
	UnloadAllPluginsButMe();
	ServerCommand("exec cfgogl/confogl_plugins.cfg");
	ExecuteConfigCfg("confogl_plugins.cfg");
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

	ServerCommand("exec cfgogl/confogl_once.cfg");
	ExecuteConfigCfg("confogl_once.cfg");
	RestartMapCountdown(5.0);
	PrintToChatAll("Config %s loaded! Map will restart in 5 seconds.");
	return true;
}

MatchMode_Unload(bool:restartMap=true)
{
//	Call_StartForward(g_hFwdMMUnload);
//	Call_Finish();
	g_bMatchModeLoaded=false;
	ServerCommand("sm plugins load_unlock");
	UnloadAllPluginsButMe();
	PrintToChatAll("Confogl Matchmode unloaded.");
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
	ForceChangeLevel(map, "Restarting Map for Confogl");
	return Plugin_Handled;
}