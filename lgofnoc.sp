/*
	This program is free software: you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the Free Software
	Foundation, either version 3 of the License, or (at your option) any later
	version.

	This program is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
	PARTICULAR PURPOSE.  See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along with
	this program.  If not, see <http://www.gnu.org/licenses/>.

	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved. 
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved. 
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase. 
	Source is Copyright (C) Valve Corporation. 

	Valve, the Valve logo, Left 4 Dead, Left 4 Dead 2, Steam, and the Steam
	logo are trademarks and/or registered trademarks of Valve Corporation.
	All other trademarks are property of their respective owners.
*/
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
	RegisterMatchModeNatives();
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
