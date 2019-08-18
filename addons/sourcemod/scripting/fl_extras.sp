#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <geoip>

#pragma newdecls required

#include include/flare_global.sp

#define VERSION "1.0.1"

bool g_bConnectionMessages = false;

char g_sCommandList[5][128];

ConVar g_hConnectionMessages = null;

Handle g_hCommandTimer = null;

int g_iCommandOrder = 0;

public Plugin myinfo = 
{
	name = "Flare - Extras",
	author = "FusionLock",
	description = "Extras for the Flare plugin.",
	version = VERSION,
	url = "https://github.com/xfusionlockx/flare"
}

public void OnPluginStart()
{
	//ConVars
	g_hConnectionMessages = CreateConVar("flare_connectionmsg", "0", "Enables/Disables the connection messages.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	HookConVarChange(g_hConnectionMessages, Flare_ConVarChanged);

	g_bConnectionMessages = GetConVarBool(g_hConnectionMessages);
	
	//Get Builds
	//RegConsoleCmd("sm_builds", Command_GetBuilds, "Lists all your builds.");
	
	//Command Hud
	AddCommandListener(HandleChat, "say");
	AddCommandListener(HandleChat, "say_team"); 
	
	//Thirdperson
	RegConsoleCmd("sm_firstperson", Command_FirstPerson, "Enables firstperson.");
	RegConsoleCmd("sm_thirdperson", Command_ThirdPerson, "Enables thirdperson.");
}

public void OnMapStart()
{
	int iSpeedMod = CreateEntityByName("player_speedmod");
	
	DispatchKeyValue(iSpeedMod, "spawnflags", "0");
	DispatchKeyValue(iSpeedMod, "targetname", "prop_flying");
	
	DispatchSpawn(iSpeedMod);
	
	AcceptEntityInput(iSpeedMod, "ModifySpeed 1.10");
	
	//g_hCommandTimer = CreateTimer(0.1, Timer_CommandList, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	//CloseHandle(g_hCommandTimer);
}

public void OnClientAuthorized(int iClient, const char[] sAuth)
{
	if(g_bConnectionMessages)
	{
		char sAuthID[64], sIP[64], sCountry[4];

		GetClientAuthId(iClient, AuthId_Steam2, sAuthID, sizeof(sAuthID), true);
		GetClientIP(iClient, sIP, sizeof(sIP));
		GeoipCode3(sIP, sCountry);
		
		CPrintToChatAll("[C] {olive}%N{default} <{olive}%s{default}> | Country: {olive}%s{default}", iClient, sAuthID, sCountry);
	
		for (int i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				ClientCommand(i, "play npc/metropolice/vo/on1.wav");
			}
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	if(g_bConnectionMessages)
	{
		char sAuthID[64];

		GetClientAuthId(iClient, AuthId_Steam2, sAuthID, sizeof(sAuthID), true);
		
		CPrintToChatAll("[D] {olive}%N{default} <{olive}%s{default}>", iClient, sAuthID);
	
		for (int i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				ClientCommand(i, "play npc/metropolice/vo/off1.wav");
			}
		}
	}
}

public void Flare_ConVarChanged(ConVar hConvar, char[] sOldData, char[] sNewData)
{
	if(hConvar == g_hConnectionMessages)
	{
		g_bConnectionMessages = view_as<bool>(StringToInt(sNewData));
	}
}

public Action Command_GetBuilds(int iClient, int iArgs)
{
	char sPath[PLATFORM_MAX_PATH], sMap[64], sAuthID[64], sBuildName[PLATFORM_MAX_PATH];
	
	GetCurrentMap(sMap, sizeof(sMap));
	
	GetClientAuthId(iClient, AuthId_Steam2, sAuthID, sizeof(sAuthID), true);
	
	ReplaceString(sAuthID, sizeof(sAuthID), ":", "_");
	
	Format(sPath, sizeof(sPath), "data/flare/saves/%s/%s", sMap, sAuthID);
	
	Flare_ReplyCommand(iClient, "Open the console to see your build list.");
	
	PrintToConsole(iClient, "[Flare] Displaying Build List:");
	
	FileType ftType;
 
	Handle hDir = OpenDirectory(sPath);
	if (hDir == INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
 
	while (ReadDirEntry(hDir, sBuildName, sizeof(sBuildName), ftType))
	{
		PrintToConsole(iClient, sBuildName);
	}

	delete hDir;
	
	return Plugin_Handled;
}

public Action HandleChat(int iClient, char[] sCommand, int iArgs)
{
	char sCommandString[128];
	
	if(IsChatTrigger())
	{
		GetCmdArgString(sCommandString, sizeof(sCommandString));
		
		ReplaceString(sCommandString, sizeof(sCommandString), "say !", "!");
		StripQuotes(sCommandString);
		
		switch(g_iCommandOrder)
		{
			case 0:
			{
				Format(g_sCommandList[0], sizeof(g_sCommandList[]), sCommandString);
				Format(sCommandString, sizeof(sCommandString), "");
				g_iCommandOrder = 1;
			}
			
			case 1:
			{
				Format(g_sCommandList[1], sizeof(g_sCommandList[]), g_sCommandList[0]);
				Format(g_sCommandList[0], sizeof(g_sCommandList[]), sCommandString);
				g_iCommandOrder = 2;
			}
			
			case 2:
			{
				Format(g_sCommandList[1], sizeof(g_sCommandList[]), g_sCommandList[0]);
				Format(g_sCommandList[2], sizeof(g_sCommandList[]), g_sCommandList[1]);
				Format(g_sCommandList[0], sizeof(g_sCommandList[]), sCommandString);
				g_iCommandOrder = 3;
			}
			
			case 3:
			{
				Format(g_sCommandList[1], sizeof(g_sCommandList[]), g_sCommandList[0]);
				Format(g_sCommandList[2], sizeof(g_sCommandList[]), g_sCommandList[1]);
				Format(g_sCommandList[3], sizeof(g_sCommandList[]), g_sCommandList[2]);
				Format(g_sCommandList[0], sizeof(g_sCommandList[]), sCommandString);
				g_iCommandOrder = 4;
			}
			
			case 4:
			{
				Format(g_sCommandList[1], sizeof(g_sCommandList[]), g_sCommandList[0]);
				Format(g_sCommandList[2], sizeof(g_sCommandList[]), g_sCommandList[1]);
				Format(g_sCommandList[3], sizeof(g_sCommandList[]), g_sCommandList[2]);
				Format(g_sCommandList[4], sizeof(g_sCommandList[]), g_sCommandList[3]);
				Format(g_sCommandList[0], sizeof(g_sCommandList[]), sCommandString);
				g_iCommandOrder = 0;
			}
		}
	}

	return Plugin_Continue;
} 

public Action Command_ThirdPerson(int iClient, int iArgs)
{
	Flare_ThirdPerson(iClient, true);

	Flare_ReplyCommand(iClient, "Enabled thirdperson mode.");

	return Plugin_Handled;
}

public Action Command_FirstPerson(int iClient, int iArgs)
{
	Flare_ThirdPerson(iClient, false);
	
	Flare_ReplyCommand(iClient, "Enabled firstperson mode.");

	return Plugin_Handled;
}

void Flare_ThirdPerson(int iClient, bool bThirdPerson)
{
	if(bThirdPerson)
	{
		SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(iClient, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(iClient, Prop_Send, "m_iFOV", 120);
	}else{
		SetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget", iClient);
		SetEntProp(iClient, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(iClient, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(iClient, Prop_Send, "m_iFOV", 90);
	}
}

//Timers
public Action Timer_CommandList(Handle hTimer)
{
	char sCommandList[1024];
	
	for (int i = 1; i < GetMaxClients(); i++)
	{
		if(IsClientInGame(i))
		{
			Format(sCommandList, sizeof(sCommandList), "%s\n%s\n%s\n%s\n%s", g_sCommandList[0], g_sCommandList[1], g_sCommandList[2], g_sCommandList[3], g_sCommandList[4]);
			
			Flare_HudMessage(i, 1, 3.0, 0.0, 255, 255, 0, 255, 0, 0.6, 0.01, 0.01, 0.01, sCommandList);
		}
	}
}
