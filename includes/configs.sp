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

#if defined __LGOFNOC_CONFIGS__
#endinput
#endif

#define __LGOFNOC_CONFIGS__

static const String:customCfgDir[] = "lgofnoc";

//static Handle:hCustomConfig;
public String:g_sCurrentConfig[PLATFORM_MAX_PATH]="";

static String:configsPath[PLATFORM_MAX_PATH];
static String:cfgPath[PLATFORM_MAX_PATH];
static String:customCfgPath[PLATFORM_MAX_PATH];
static DirSeparator;

RegisterConfigsNatives()
{
	CreateNative("LGO_BuildConfigPath", _native_BuildConfigPath);
	CreateNative("LGO_ExecuteConfigCfg", _native_ExecConfigCfg);
}

InitConfigsPaths()
{
	BuildPath(Path_SM, configsPath, sizeof(configsPath), "configs/confogl/");
	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "../../cfg/");
	DirSeparator= cfgPath[strlen(cfgPath)-1];
}

bool:SetCustomCfg(const String:cfgname[])
{
	if(!strlen(cfgname))
	{
		return false;
	}
	
	Format(customCfgPath, sizeof(customCfgPath), "%s%s%c%s", cfgPath, customCfgDir, DirSeparator, cfgname);
	if(!DirExists(customCfgPath))
	{
		LogError("[Configs] Custom config directory %s does not exist!", customCfgPath);
		// Revert customCfgPath
		customCfgPath[0]=0;
		return false;
	}
	new thislen = strlen(customCfgPath);
	if(thislen+1 < sizeof(customCfgPath))
	{
		customCfgPath[thislen] = DirSeparator;
		customCfgPath[thislen+1] = 0;
	}
	else
	{
		LogError("[Configs] Custom config directory %s path too long!", customCfgPath);
		customCfgPath[0]=0;
		return false;
	}
	strcopy(g_sCurrentConfig, sizeof(g_sCurrentConfig), cfgname);
	
	return true;	
}

BuildConfigPath(String:buffer[], maxlength, const String:sFileName[])
{
	if(customCfgPath[0])
	{
		Format(buffer, maxlength, "%s%s", customCfgPath, sFileName);
		if(FileExists(buffer))
		{
			return;
		}
		else
		{
		}
	}
	// no more default reverting...	
}

ExecuteConfigCfg(const String:sFileName[])
{
	if(strlen(sFileName) == 0)
	{
		return;
	}
	
	decl String:sFilePath[PLATFORM_MAX_PATH];
	
	if(customCfgPath[0])
	{
		Format(sFilePath, sizeof(sFilePath), "%s%s", customCfgPath, sFileName);
		if(FileExists(sFilePath))
		{
			ServerCommand("exec %s%s", customCfgPath[strlen(cfgPath)], sFileName);
		}
		else
		{
		}
	}
}

public _native_BuildConfigPath(Handle:plugin, numParams)
{
	decl len;
	GetNativeStringLength(3, len);
	new String:filename[len+1];
	GetNativeString(3, filename, len+1);
		
	len = GetNativeCell(2);
	new String:buf[len];
	BuildConfigPath(buf, len, filename);
	
	SetNativeString(1, buf, len);
}

public _native_ExecConfigCfg(Handle:plugin, numParams)
{
	decl len;	
	GetNativeStringLength(1, len);
	new String:filename[len+1];
	GetNativeString(1, filename, len+1);
	
	ExecuteConfigCfg(filename);
}
