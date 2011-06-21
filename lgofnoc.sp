#pragma semicolon 1

#define PLUGIN_VERSION	"1.0"

#include <sourcemod>
#include <sdktools>
#include <socket>
#include "includes/functions.sp"
#include "includes/configs.sp"
#include "includes/customtags.inc"

#include "modules/MapInfo.sp"
#include "modules/CvarSettings.sp"
#include "modules/MatchMode.sp"

public Plugin:myinfo = 
{
	name = "LGOFNOC Config Manager",
	author = "Confogl Team",
	description = "A competitive configuration management system for Source games",
	version = PLUGIN_VERSION,
	url = "http://github.com/ProdigySim/LGOFNOC/"
}

public OnPluginStart()
{
	Configs_OnModuleStart();
	MI_OnModuleStart();
	MatchMode_OnPluginStart();
	
	CVS_OnModuleStart();
	
	AddCustomServerTag("lgofnoc", true);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	Configs_APL();
	MatchMode_APL();
	MI_APL();
	RegPluginLibrary("lgofnoc");
}

public OnPluginEnd()
{
	CVS_OnModuleEnd();
	RemoveCustomServerTag("lgofnoc");
}

public OnMapStart()
{
	MI_OnMapStart();
	MatchMode_OnMapStart();
}

public OnMapEnd()
{
	MI_OnMapEnd();
	
}

public OnConfigsExecuted()
{
	CVS_OnConfigsExecuted();
}
