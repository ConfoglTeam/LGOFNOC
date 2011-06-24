#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define DEBUG_MI					0

new Handle:kMIData;
new Handle:kLocalMIData;
static bool:MapDataAvailable;

RegisterMapInfoNatives()
{
	CreateNative("LGO_IsMapDataAvailable", _native_IsMapDataAvailable);
	CreateNative("LGO_GetMapValueInt", _native_GetMapValueInt);
	CreateNative("LGO_GetMapValueFloat", _native_GetMapValueFloat);
	CreateNative("LGO_GetMapValueVector", _native_GetMapValueVector);
	CreateNative("LGO_GetMapValueString", _native_GetMapValueString);
	CreateNative("LGO_CopyMapSubsection", _native_CopyMapSubsection);
}

MapInfo_OnMapEnd()
{
	MapDataAvailable = false;
}


CloseMapInfo()
{
	if(kMIData != INVALID_HANDLE)
	{
		CloseHandle(kMIData);
		kMIData = INVALID_HANDLE;
	}
	if(kLocalMIData != INVALID_HANDLE)
	{
		CloseHandle(kLocalMIData);
		kLocalMIData = INVALID_HANDLE;
	}
}

LoadMapInfo()
{
	decl String:sNameBuff[PLATFORM_MAX_PATH];
	
	#if DEBUG_MI
		LogMessage("[MI] Loading MapInfo KeyValues");
	#endif

	kMIData = CreateKeyValues("MapInfo");	
	kLocalMIData = CreateKeyValues("MapInfo");	
	FileToKeyValues(kMIData, "cfg/cfgogl/mapinfo.txt");
	BuildConfigPath(sNameBuff, sizeof(sNameBuff), "mapinfo.txt"); //Build our filepath
	FileToKeyValues(kLocalMIData, sNameBuff);
}

UpdateMapInfo()
{
	decl String:sCurMap[128];
	if(kMIData == INVALID_HANDLE || kLocalMIData == INVALID_HANDLE) 
	{
		MapDataAvailable = false;
		return;
	}
	GetCurrentMap(sCurMap, sizeof(sCurMap));

	KvRewind(kMIData);
	if(!KvJumpToKey(kMIData, sCurMap))
	{
		LogMessage("[MI] Global MapInfo for %s is missing.", sCurMap);
		KvJumpToKey(kMIData, sCurMap, true);
	}
	KvRewind(kLocalMIData);
	if(!KvJumpToKey(kLocalMIData, sCurMap))
	{
		LogMessage("[MI] Local MapInfo for %s is missing.", sCurMap);
		KvJumpToKey(kLocalMIData, sCurMap, true);
	}

	MapDataAvailable = true;
}

stock bool:IsMapDataAvailable() return MapDataAvailable;

stock GetMapValueInt(const String:key[], defvalue=0) 
{
	return KvGetNum(kLocalMIData, key, KvGetNum(kMIData, key, defvalue)); 
}
stock Float:GetMapValueFloat(const String:key[], Float:defvalue=0.0) 
{
	return KvGetFloat(kLocalMIData, key, KvGetFloat(kMIData, key, defvalue)); 
}
stock GetMapValueVector(const String:key[], Float:vector[3], Float:defvalue[3]=NULL_VECTOR) 
{
	decl Float:temp[3];
	KvGetVector(kMIData, key, temp, defvalue);
	KvGetVector(kLocalMIData, key, vector, temp);
}
stock GetMapValueString(const String:key[], String:value[], maxlength, const String:defvalue[])
{
	decl String:temp[maxlength];
	KvGetString(kMIData, key, temp, maxlength, defvalue);
	KvGetString(kLocalMIData, key, value, maxlength, temp);
}

stock CopyMapSubsection(Handle:kv, const String:section[])
{
	if(KvJumpToKey(kLocalMIData, section, false))
	{
		KvCopySubkeys(kLocalMIData, kv);
		KvGoBack(kLocalMIData);
	}
	else if(KvJumpToKey(kMIData, section, false))
	{
		KvCopySubkeys(kMIData, kv);
		KvGoBack(kMIData);
	}
}

public _native_IsMapDataAvailable(Handle:plugin, numParams)
{
	return IsMapDataAvailable();
}

public _native_GetMapValueInt(Handle:plugin, numParams)
{
	decl len, defval;
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	defval = GetNativeCellRef(2);
	
	return GetMapValueInt(key, defval);
}

public _native_GetMapValueFloat(Handle:plugin, numParams)
{
	decl len, Float:defval;
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	defval = GetNativeCellRef(2);
	
	return _:GetMapValueFloat(key, defval);
}

public _native_GetMapValueVector(Handle:plugin, numParams)
{
	decl len, Float:defval[3], Float:value[3];
	
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	GetNativeArray(3, defval, 3);
	
	GetMapValueVector(key, value, defval);
	
	SetNativeArray(2, value, 3);
}

public _native_GetMapValueString(Handle:plugin, numParams)
{
	decl len;
	GetNativeStringLength(1, len);
	new String:key[len+1];
	GetNativeString(1, key, len+1);
	
	GetNativeStringLength(4, len);
	new String:defval[len+1];
	GetNativeString(4, defval, len+1);
	
	len = GetNativeCell(3);
	new String:buf[len+1];
	
	GetMapValueString(key, buf, len, defval);
	
	SetNativeString(2, buf, len);
}

public _native_CopyMapSubsection(Handle:plugin, numParams)
{
	decl len, Handle:kv;
	GetNativeStringLength(2, len);
	new String:key[len+1];
	GetNativeString(2, key, len+1);
	
	kv = GetNativeCell(1);
	
	CopyMapSubsection(kv, key);
}
