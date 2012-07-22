new Handle:g_hFwdPrePluginsLoaded;
new Handle:g_hFwdPostPluginsLoaded;
//new Handle:g_hFwdUnloadPre;

new bool:g_bMatchModeLoaded;
static bool:lgoLoadThisFrame=false;
stock bool:IsMatchModeInProgress() { return g_bMatchModeLoaded; }

RegisterMatchModeCommands()
{
	RegAdminCmd("sm_forcematch", ForceMatchCmd, ADMFLAG_CONFIG, "Loads matchmode on a given config. Will unload a previous config if one is loaded");
	RegAdminCmd("sm_softmatch", SoftMatchCmd, ADMFLAG_CONFIG, "Loads matchmode on a given config only if no match is currently running.");
	RegAdminCmd("sm_resetmatch", ResetMatchCmd, ADMFLAG_CONFIG, "Unloads matchmode if it is currently running");
	RegServerCmd("command_buffer_done_callback", CmdBufDoneCallback);
	RegServerCmd("lgofnoc_loadplugin", LgoLoadPluginCmd);
	g_hFwdPrePluginsLoaded = CreateGlobalForward("LGO_OnMatchModeStart_PrePlugins", ET_Event, Param_String);
	g_hFwdPostPluginsLoaded = CreateGlobalForward("LGO_OnMatchModeStart", ET_Event, Param_String);
	//g_hFwdMMUnload = CreateGlobalForward("LGO_OnMatchModeUnloaded", ET_Event);
}

RegisterMatchModeNatives()
{
	CreateNative("LGO_IsMatchModeLoaded", LGO_IsMatchModeLoaded);
	CreateNative("LGO_StartMatch", LGO_StartMatch);
	CreateNative("LGO_EndMatch", LGO_EndMatch);
}

MatchMode_ExecuteConfigs()
{
	if(IsMatchModeInProgress())
	{
		decl String:mapbuf[128];
		GetCurrentMap(mapbuf, sizeof(mapbuf));
		StrCat(mapbuf, sizeof(mapbuf), ".cfg");
	
		ServerCommand("exec lgofnoc/lgofnoc.cfg");
		ExecuteConfigCfg("lgofnoc.cfg");
	
		ServerCommand("exec lgofnoc/%s", mapbuf);
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
	
	Call_StartForward(g_hFwdPrePluginsLoaded);
	Call_PushString(config);
	Call_Finish();
	
	ServerCommand("sm plugins load_unlock");
	UnloadAllPluginsButMe();
	ServerCommand("exec lgofnoc/lgofnoc_plugins.cfg");
	ExecuteConfigCfg("lgofnoc_plugins.cfg");
	return true;
}

// Load a plugin from plugins/ or plugins/optional
public Action:LgoLoadPluginCmd(args)
{
	decl String:plugin[PLATFORM_MAX_PATH], String:path[PLATFORM_MAX_PATH];
	GetCmdArg(1, plugin, sizeof(plugin));
	BuildPath(Path_SM, path, sizeof(path), "plugins/%s", plugin);
	if(FileExists(path))
	{
		ServerCommand("sm plugins load %s", plugin);
		lgoLoadThisFrame=true;
		return Plugin_Handled;
	}
	BuildPath(Path_SM, path, sizeof(path), "plugins/optional/%s", plugin);
	if(FileExists(path))
	{
		ServerCommand("sm plugins load optional/%s", plugin);
		lgoLoadThisFrame=true;
		return Plugin_Handled;
	}
	PrintToServer("Load Failed: Plugin %s not found in plugins/ or plugins/optional/", plugin);
	return Plugin_Handled;
}

GameFramePluginCheck()
{
	if(lgoLoadThisFrame)
	{
		lgoLoadThisFrame=false;
		ServerCommand("sm plugins load_lock");
		ServerCommand("command_buffer_done_callback"); // see you in the next call
	}
}

public Action:CmdBufDoneCallback(args)
{
	if(!IsMatchModeInProgress()) return Plugin_Handled;
	// We're back! Only a tick!
	MatchModeLoad_PostPlugins();
	return Plugin_Handled;
}


MatchModeLoad_PostPlugins()
{
	// Sequential!

	Call_StartForward(g_hFwdPostPluginsLoaded);
	Call_PushString(g_sCurrentConfig);
	Call_Finish();

	ServerCommand("exec lgofnoc/lgofnoc_once.cfg");
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
	ServerCommand("exec lgofnoc/lgofnoc_off.cfg");
	ExecuteConfigCfg("lgofnoc_off.cfg");
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

public LGO_IsMatchModeLoaded(Handle:plugin, numParams)
{
	return _:IsMatchModeInProgress();
}

public LGO_StartMatch(Handle:plugin, numParams)
{
	decl len;
	GetNativeStringLength(1, len);
	new String:config[len+1];
	GetNativeString(1, config, len+1);

	return MatchMode_Load(config);
}

public LGO_EndMatch(Handle:plugin, numParams)
{
	if(IsMatchModeInProgress()) 
	{
		MatchMode_Unload(bool:GetNativeCell(1));
	}
}