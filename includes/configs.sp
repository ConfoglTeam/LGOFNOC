#pragma semicolon 1
#include <sourcemod>

#if defined __LGOFNOC_CONFIGS__
#endinput
#endif

#define __LGOFNOC_CONFIGS__

static const String:customCfgDir[] = "cfgogl";

//static Handle:hCustomConfig;
static String:configsPath[PLATFORM_MAX_PATH];
static String:cfgPath[PLATFORM_MAX_PATH];
static String:customCfgPath[PLATFORM_MAX_PATH];
static DirSeparator;

Configs_OnModuleStart()
{
	InitPaths();
}
Configs_APL()
{
	CreateNative("LGO_BuildConfigPath", _native_BuildConfigPath);
	CreateNative("LGO_ExecuteConfigCfg", _native_ExecConfigCfg);
}

InitPaths()
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
