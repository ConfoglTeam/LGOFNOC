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
// COPYRIGHT PSYCHONIC
// USED WITH PERMISSION
#if defined _customtags_included
	#endinput
#endif
#define _customtags_included

#define CUSTOM_TAGS_VERSION 4

#define SV_TAG_SIZE 64

static Handle:sv_tags;
static Handle:custom_tags;
static bool:are_tags_hooked = false;
static bool:ignore_next_change = false;
static EngineVersion:engine_version = Engine_Unknown;

stock AddCustomServerTag(const String:tag[], bool:force=false)
{
	if (sv_tags == INVALID_HANDLE && (sv_tags = FindConVar("sv_tags")) == INVALID_HANDLE)
	{
		// game doesn't support sv_tags
		return;
	}
	
	if (!force
		&& (engine_version != Engine_Unknown || (engine_version = GetEngineVersion()) != Engine_Unknown)
		&& engine_version >= Engine_Left4Dead2)
	{
		return;
	}
	
	if (custom_tags == INVALID_HANDLE)
	{
		custom_tags = CreateArray(SV_TAG_SIZE);
		PushArrayString(custom_tags, tag);
	}
	else if (FindStringInArray(custom_tags, tag) == -1)
	{
		PushArrayString(custom_tags, tag);
	}
	
	decl String:current_tags[SV_TAG_SIZE];
	GetConVarString(sv_tags, current_tags, sizeof(current_tags));
	if (StrContains(current_tags, tag) > -1)
	{
		// already have tag
		return;
	}
	
	decl String:new_tags[SV_TAG_SIZE];
	Format(new_tags, sizeof(new_tags), "%s%s%s", current_tags, (current_tags[0]!=0)?",":"", tag);
	
	new flags = GetConVarFlags(sv_tags);
	SetConVarFlags(sv_tags, flags & ~FCVAR_NOTIFY);
	ignore_next_change = true;
	SetConVarString(sv_tags, new_tags);
	ignore_next_change = false;
	SetConVarFlags(sv_tags, flags);
	
	if (!are_tags_hooked)
	{
		HookConVarChange(sv_tags, OnTagsChanged);
		are_tags_hooked = true;
	}
}

stock RemoveCustomServerTag(const String:tag[])
{
	if (sv_tags == INVALID_HANDLE && (sv_tags = FindConVar("sv_tags")) == INVALID_HANDLE)
	{
		// game doesn't support sv_tags
		return;
	}
	
	// we wouldn't have to check this if people aren't removing before adding, but... you know...
	if (custom_tags != INVALID_HANDLE)
	{
		new idx = FindStringInArray(custom_tags, tag);
		if (idx > -1)
		{
			RemoveFromArray(custom_tags, idx);
		}
	}
	
	decl String:current_tags[SV_TAG_SIZE];
	GetConVarString(sv_tags, current_tags, sizeof(current_tags));
	if (StrContains(current_tags, tag) == -1)
	{
		// tag isn't on here, just bug out
		return;
	}
	
	ReplaceString(current_tags, sizeof(current_tags), tag, "");
	ReplaceString(current_tags, sizeof(current_tags), ",,", "");
	
	new flags = GetConVarFlags(sv_tags);
	SetConVarFlags(sv_tags, flags & ~FCVAR_NOTIFY);
	ignore_next_change = true;
	SetConVarString(sv_tags, current_tags);
	ignore_next_change = false;
	SetConVarFlags(sv_tags, flags);
}

public OnTagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (ignore_next_change)
	{
		// we fired this callback, no need to reapply tags
		return;
	}
	
	// reapply each custom tag
	new cnt = GetArraySize(custom_tags);
	for (new i = 0; i < cnt; i++)
	{
		decl String:tag[SV_TAG_SIZE];
		GetArrayString(custom_tags, i, tag, sizeof(tag));
		AddCustomServerTag(tag);
	}
}
