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
#include <keyvalues>
#include <textparse>

#if defined __keyvalues_stocks__
#endinput
#endif
#define __keyvalues_stocks__


static Handle:kvparser;
static Handle:currentKv;

// parser state tracking
static bool:justStarted;

stock AddFileToKeyValues(Handle:kv, const String:file[])
{
	if(kvparser == INVALID_HANDLE) kvparser=InitParser();
	currentKv=kv;
	justStarted=true;
	SMC_ParseFile(kvparser, file);
	currentKv=INVALID_HANDLE;
}

static Handle:InitParser()
{
	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders(parser, KVAdder_NewSection, KVAdder_KeyValue, KVAdder_EndSection);
	return parser;
}

public SMCResult:KVAdder_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	decl String:buf[255];
	if(justStarted)
	{
		justStarted=false;
		KvGetSectionName(currentKv, buf, sizeof(buf));
		if(StrEqual(name, buf))
		{
			return SMCParse_Continue;
		}
	}
	KvJumpToKey(currentKv, name, true);	
	return SMCParse_Continue;
}

public SMCResult:KVAdder_KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	KvSetString(currentKv, key, value);
	return SMCParse_Continue;
}

public SMCResult:KVAdder_EndSection(Handle:smc)
{
	KvGoBack(currentKv);
}
