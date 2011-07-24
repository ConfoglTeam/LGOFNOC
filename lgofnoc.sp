#pragma semicolon 1

#include <sourcemod>
#include "includes/functions.sp"
#include "includes/configs.sp"
#include "includes/customtags.inc"
#include "includes/keyvalues_stocks.inc"

#include "modules/MapInfo.sp"
#include "modules/CvarSettings.sp"
#include "modules/MatchMode.sp"

public Plugin:myinfo = 
{
	name = "LGOFNOC Config Manager",
	author = "Confogl Team",
	description = "A competitive configuration management system for Source games",
	version = "1.0",
	url = "http://github.com/ProdigySim/LGOFNOC/"
}

public OnPluginStart()
{
	InitConfigsPaths();
	InitCvarSettings();
	RegisterMatchModeCommands();
	
	AddCustomServerTag("lgofnoc", true);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegisterConfigsNatives();
	RegisterMapInfoNatives();
	RegPluginLibrary("lgofnoc");
}

public OnPluginEnd()
{
	ClearAllCvarSettings();
	RemoveCustomServerTag("lgofnoc");
}

public OnMapStart()
{
	UpdateMapInfo();
	MatchMode_ExecuteConfigs();
}

public OnMapEnd() 
{
	MapInfo_OnMapEnd();
}

public OnGameFrame()
{
	GameFramePluginCheck();
}
