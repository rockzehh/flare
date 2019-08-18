#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
#include <morecolors>

#pragma newdecls required

#define MAX_ENTITIES 2048

#define VERSION "1.2.6.7"

//Booleans
bool g_bHL2MP = false, g_bUnknown = false;
bool g_bFlareEnt[MAX_ENTITIES + 1];

//Strings
char g_sSpawnList[PLATFORM_MAX_PATH];
char g_sColorList[PLATFORM_MAX_PATH];
char g_sNPCList[PLATFORM_MAX_PATH];
char g_sBlackList[PLATFORM_MAX_PATH];
char g_sAuthID[MAXPLAYERS + 1][64];
char g_sMap[64];
char g_sPropname[MAX_ENTITIES + 1][64];
char g_sInternet[MAXPLAYERS + 1][128];
char g_sRenderFX[MAX_ENTITIES + 1][64];

//Floats
float g_fZero[3] = {0.0, 0.0, 0.0};

//Handles
Handle g_hLimit;

//Integers
int g_iOwner[MAX_ENTITIES + 1];
int g_iEntityDissolver;
int g_iCount[MAXPLAYERS + 1];
int g_iLimit;
int g_iColor[MAX_ENTITIES + 1][4];
int g_iBeam;
int g_iHalo;
int g_iLaser;
int g_iPhys;
int g_iBalance[MAXPLAYERS + 1];
int g_iLastPlayer[MAXPLAYERS + 1] = -1;
int g_iWhite[4] = {255, 255, 255, 200};
int g_iGray[4] = {255, 255, 255, 300};
int g_iRed[4] = {255, 0, 0, 175};
int g_iGreen[4] = {0, 255, 0, 175};
int g_iBlue[4] = {0, 0, 255, 175};

#include include/flare_global.sp

public Plugin myinfo = 
{
	name = "Flare - Main",
	author = "FusionLock",
	description = "A mod for SourceMod that contains commands that are used to spawn/manipulate entities.",
	version = VERSION,
	url = "https://github.com/xfusionlockx/flare"
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	//Checking if Flare is supported for the game
	char sGameName[64], sPath[PLATFORM_MAX_PATH];

	GetGameFolderName(sGameName, sizeof(sGameName));

	if(StrEqual(sGameName, "hl2mp", true))
	{
		g_bHL2MP = true;
	}else{
		g_bUnknown = true;
	}

	if(g_bUnknown)
	{
		PrintToServer("Flare doesn't support '%s'! Unloading the plugin.", sGameName);
		ServerCommand("sm plugins unload fl_main.smx");
	}

	//Now loading the plugin

	//Finding/Creating directories and files Flare needs
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/flare");
	if(!DirExists(sPath))
	{
		ThrowError("[Flare] The plugin cannot run without the 'data/flare' folder!");
	}
	
	BuildPath(Path_SM, g_sSpawnList, sizeof(g_sSpawnList), "data/flare/spawns.txt");
	BuildPath(Path_SM, g_sColorList, sizeof(g_sColorList), "data/flare/colors.txt");
	BuildPath(Path_SM, g_sNPCList, sizeof(g_sNPCList), "data/flare/npcs.txt");
	BuildPath(Path_SM, g_sBlackList, sizeof(g_sBlackList), "data/flare/blacklist.txt");

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/flare/saves");
	if(!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}

	GetCurrentMap(g_sMap, sizeof(g_sMap));

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/flare/saves/%s", g_sMap);
	if(!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}

	//Commands
	RegAdminCmd("sm_explosion", Command_Explode, ADMFLAG_SLAY, "Creates an explosion to all props within a certain area.");
	
	RegConsoleCmd("sm_spawn", Command_Spawn, "Spawns a prop from a given alias.");
	RegConsoleCmd("sm_delete", Command_Delete, "Removes a entity.");
	RegConsoleCmd("sm_freezeprop", Command_FreezeProp, "Disables motion on a prop.");
	RegConsoleCmd("sm_unfreezeprop", Command_UnFreezeProp, "Enables motion on a prop.");
	RegConsoleCmd("sm_rotate", Command_Rotate, "Changes a entity's angle.");
	RegConsoleCmd("sm_straight", Command_Straighten, "Set's a entity's angle to 0, 0, 0.");
	RegConsoleCmd("sm_stack", Command_Stack, "Stacks your props.");
	RegConsoleCmd("sm_save", Command_SaveBuild, "Saves your building so you can load them again.");
	RegConsoleCmd("sm_load", Command_LoadBuild, "Loads your buildings you saved.");
	RegConsoleCmd("sm_color", Command_Color, "Colors an entity.");
	RegConsoleCmd("sm_door", Command_Door, "Spawns a door.");
	RegConsoleCmd("sm_smove", Command_SMove, "Moves a entity by specific degrees.");
	RegConsoleCmd("sm_alpha", Command_Alpha, "Changes the transparency value on entities.");
	RegConsoleCmd("sm_axis", Command_Axis, "Shows an axis.");
	RegConsoleCmd("sm_ladder", Command_Ladder, "Creates a working ladder.");
	RegConsoleCmd("sm_internet", Command_Internet, "Creates a prop to go onto the internet.");
	RegConsoleCmd("sm_seturl", Command_SetUrl, "Sets the url of the internet prop.");
	RegConsoleCmd("sm_light", Command_Light, "Creates a working, move-able light.");
	RegConsoleCmd("sm_npc", Command_NPC, "Creates a npc from a list.");
	RegConsoleCmd("sm_clear", Command_ClearBuild, "Removes a build save file.");
	RegConsoleCmd("sm_deleteall", Command_DeleteAll, "Removes all your entites.");
	RegConsoleCmd("sm_moveto", Command_MoveTo, "Moves your entity to a specific origin.");
	RegConsoleCmd("sm_skin", Command_Skin, "Changes the entity skin.");
	RegConsoleCmd("sm_owner", Command_Owner, "Returns the owners name of the entity.");
	RegConsoleCmd("sm_balance", Command_Balance, "Returns the clients balance.");
	RegConsoleCmd("sm_fly", Command_Fly, "Enables noclip on a client.");
	RegConsoleCmd("sm_msg", Command_SendMessage, "Sends a private message to a player.");
	RegConsoleCmd("sm_reply", Command_Reply, "Replies to the previous message.");
	RegConsoleCmd("sm_count", Command_Count, "Counts how many props and npcs you've spawned.");
	RegConsoleCmd("sm_renderfx", Command_RenderFX, "Changes the render fx on the prop you are looking at.");

	//Convars
	CreateConVar("flare", "1", "Shows that the Flare plugin is running on the server.", FCVAR_NOTIFY);
	CreateConVar("flare_version", VERSION, "The version of Flare that the server is running.", FCVAR_NOTIFY);
	g_hLimit = CreateConVar("flare_max_props", "150", "The maximum amount of props a player can spawn", FCVAR_NOTIFY);

	HookConVarChange(g_hLimit, Flare_ConVarChanged);

	g_iLimit = GetConVarInt(g_hLimit);

	//Notice that plugin loaded
	PrintToServer("[Flare] Flare ver%s has loaded successfully.", VERSION);
}

public void OnClientPutInServer(int iClient)
{
	char sPath[PLATFORM_MAX_PATH];

	GetClientAuthId(iClient, AuthId_Steam2, g_sAuthID[iClient], sizeof(g_sAuthID[]), true);

	ReplaceString(g_sAuthID[iClient], sizeof(g_sAuthID[]), ":", "_");

	Format(g_sInternet[iClient], sizeof(g_sInternet[]), "%N's Internet", iClient);

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/flare/saves/%s/%s", g_sMap, g_sAuthID[iClient]);
	if(!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);
	}

	g_iCount[iClient] = 0;
	
	g_iLastPlayer[iClient] = -1;

	g_iBalance[iClient] = 0;
}

public void OnClientDisconnect(int iClient)
{
	g_iLastPlayer[iClient] = -1;
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if(g_iLastPlayer[i] == iClient)
			{
				g_iLastPlayer[i] = -1;
			}
		}
	}
	
	for(int i = 0; i < GetMaxEntities(); i++)
	{
		if(Flare_CheckOwner(iClient, i))
		{
			if(g_bFlareEnt[i])
			{
				g_bFlareEnt[i] = false;
				
				AcceptEntityInput(i, "kill");
			}
		}
	}
}

public void OnMapStart()
{
	g_iEntityDissolver = CreateEntityByName("env_entity_dissolver");

	DispatchKeyValue(g_iEntityDissolver, "target", "deleted");
	DispatchKeyValue(g_iEntityDissolver, "magnitude", "50");
	DispatchKeyValue(g_iEntityDissolver, "dissolvetype", "3");

	DispatchSpawn(g_iEntityDissolver);

	DispatchKeyValue(g_iEntityDissolver, "classname", "entity_dissolver");
	
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt");
	g_iBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iPhys = PrecacheModel("materials/sprites/physbeam.vmt");
	g_iLaser = PrecacheModel("materials/sprites/laser.vmt");

	PrecacheModel("models/props_c17/door01_left.mdl");
	PrecacheModel("models/props_lab/monitor02.mdl");
	
	PrecacheSound("weapons/airboat/airboat_gun_lastshot1.wav");
	PrecacheSound("weapons/airboat/airboat_gun_lastshot2.wav");
	PrecacheSound("ambient/levels/citadel/weapon_disintegrate4.wav");
}

public void OnMapEnd()
{
	RemoveEdict(g_iEntityDissolver);
}

/*public void OnEntityDestroyed(int iEntity)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if(Flare_CheckOwner(i, iEntity))
			{
				if(g_bFlareEnt[iEntity])
				{
					g_bFlareEnt[iEntity] = false;
					
					g_iCount[i]--;
				}
			}
		}
	}
}*/

public void Flare_ConVarChanged(Handle hConVar, char[] sOldValue, char[] sNewValue)
{
	if(hConVar == g_hLimit)
	{
		g_iLimit = GetConVarInt(g_hLimit);
	}
}

public bool Flare_FilterPlayer(int iEntity, any contentsMask)
{
	return iEntity > MaxClients;
}

public void OnGameFrame()
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			int iEnt = Flare_UseEntity(i);

			if(iEnt == -1)
			{}else{
				char sClassname[64], sTargetname[128];

				GetEntityClassname(iEnt, sClassname, sizeof(sClassname));

				if(StrEqual(sClassname, "flare_internet", true))
				{
					GetEntPropString(iEnt, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

					ShowMOTDPanel(i, g_sInternet[Flare_GetOwner(iEnt)], sTargetname, MOTDPANEL_TYPE_URL);
				}
			}
		}
	}
}

//Commands:
public Action Command_Spawn(int iClient, int iArgs)
{
	char sAlias[64], sPropString[256], sPropBuffer[2][128];

	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]spawn{default} <alias>");
		return Plugin_Handled;
	}

	if(g_iCount[iClient] >= g_iLimit)
	{
		Flare_ReplyCommand(iClient, "You have reached your props limit.");
		return Plugin_Handled;
	}

	GetCmdArg(1, sAlias, sizeof(sAlias));

	Handle hProps = CreateKeyValues("Props");

	FileToKeyValues(hProps, g_sSpawnList);

	KvJumpToKey(hProps, "Models", false);
	
	KvGetString(hProps, sAlias, sPropString, sizeof(sPropString), "null");

	KvRewind(hProps);

	CloseHandle(hProps);

	if(StrEqual(sPropString, "null", true))
	{
		Flare_ReplyCommand(iClient, "Prop not found.");

		return Plugin_Handled;
	}

	ExplodeString(sPropString, "^", sPropBuffer, 2, sizeof(sPropBuffer[]));
	
	if !Flare_CheckBlackList(iClient, true, sAlias) *then return Plugin_Handled;

	Flare_SpawnEntity(iClient, sAlias, sPropBuffer[0], sPropBuffer[1], 255, 255, 255, 255);

	Flare_ReplyCommand(iClient, "Successfully spawned '{green}%s{default}'.", sAlias);

	return Plugin_Handled;
}

public Action Command_Delete(int iClient, int iArgs)
{
	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Flare_ClientBeam(iClient, iEntity, false);

			g_bFlareEnt[iEntity] = false;
			
			Format(g_sRenderFX[iEntity], sizeof(g_sRenderFX[]), "default");
			
			Flare_RemoveEntity(iEntity);

			g_iCount[iClient]--;
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_FreezeProp(int iClient, int iArgs)
{
	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Flare_ClientBeam(iClient, iEntity, true);
			
			AcceptEntityInput(iEntity, "disablemotion");

			Flare_ReplyCommand(iClient, "You have froze entity {green}#%i{default}.", iEntity);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_UnFreezeProp(int iClient, int iArgs)
{
	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Flare_ClientBeam(iClient, iEntity, true);
					
			AcceptEntityInput(iEntity, "enablemotion");

			Flare_ReplyCommand(iClient, "You have unfroze entity {green}#%i{default}.", iEntity);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Rotate(int iClient, int iArgs)
{
	float fAngles[3], fEntAngles[3], fFinAngles[3];

	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]rotate{default} <x> <y> <z>");
		return Plugin_Handled;
	}

	for(int i = 0; i < 3; i++)
	{
		char sDegree[64];

		GetCmdArg(i+1, sDegree, sizeof(sDegree));

		fAngles[i] = StringToFloat(sDegree);
	}

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			GetEntPropVector(iEntity, Prop_Data, "m_angAbsRotation", fEntAngles);

			fFinAngles[0] = fEntAngles[0] += fAngles[0];
			fFinAngles[1] = fEntAngles[1] += fAngles[1];
			fFinAngles[2] = fEntAngles[2] += fAngles[2];

			TeleportEntity(iEntity, NULL_VECTOR, fFinAngles, NULL_VECTOR);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Straighten(int iClient, int iArgs)
{
	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Flare_ClientBeam(iClient, iEntity, true);
			
			TeleportEntity(iEntity, NULL_VECTOR, g_fZero, NULL_VECTOR);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Stack(int iClient, int iArgs)
{
	char sAmount[64], sModel[256], sAlias[64], sClassname[64], sRenderFX[64];
	char sX[64], sY[64], sZ[64];

	float fEntityOrigin[3], fAngles[3], fAddOrigin[3];

	int iSkin, iColor[4], iStackCount;
	
	if(iArgs < 2)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]stack{default} <amount> <x> <y> <z>");
		return Plugin_Handled;
	}

	if(g_iCount[iClient] >= g_iLimit)
	{
		Flare_ReplyCommand(iClient, "You have reached your props limit.");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, sAmount, sizeof(sAmount));
	
	GetCmdArg(2, sX, sizeof(sX));
	GetCmdArg(3, sY, sizeof(sY));
	GetCmdArg(4, sZ, sizeof(sZ));

	fAddOrigin[0] = StringToFloat(sX), fAddOrigin[1] = StringToFloat(sY), fAddOrigin[2] = StringToFloat(sZ);
	
	int iAmount = StringToInt(sAmount);

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			GetEntityClassname(iEntity, sClassname, sizeof(sClassname));

			if(StrEqual(sClassname, "prop_door_rotating", true) || StrEqual(sClassname, "flare_internet", true) || StrEqual(sClassname, "flare_ladder", true) || StrEqual(sClassname, "flare_light", true) || StrContains(sClassname, "npc_", true) != -1)
			{
				Flare_ReplyCommand(iClient, "Cannot stack this entity!");
				return Plugin_Handled;
			}

			iColor = g_iColor[iEntity];
			iSkin = GetEntProp(iEntity, Prop_Data, "m_nSkin", 1);

			Format(sAlias, sizeof(sAlias), g_sPropname[iEntity]);

			GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			Format(sRenderFX, sizeof(sRenderFX), g_sRenderFX[iEntity]);
		}else{
			Flare_NotLooking(iClient);
			return Plugin_Handled;
		}
	}else{
		Flare_NotYours(iClient);
		return Plugin_Handled;
	}

	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);

	for (int i = 0; i < iAmount; i++)
	{
		iStackCount++;

		if(g_iCount[iClient] >= g_iLimit)
		{
			Flare_ReplyCommand(iClient, "You have reached your props limit.");
			return Plugin_Handled;
		}

		char sSkin[64];

		float fOrigin[3], fOldOrigin[3];

		fOldOrigin[0] = fAddOrigin[0] * iStackCount;
		fOldOrigin[1] = fAddOrigin[1] * iStackCount;
		fOldOrigin[2] = fAddOrigin[2] * iStackCount;

		AddVectors(fEntityOrigin, fOldOrigin, fOrigin);

		int iProp = CreateEntityByName("prop_physics_override");

		PrecacheModel(sModel);

		IntToString(iSkin, sSkin, sizeof(sSkin));

		DispatchKeyValue(iProp, "model", sModel);
		DispatchKeyValue(iProp, "skin", sSkin);

		DispatchSpawn(iProp);

		AcceptEntityInput(iProp, "disablemotion");

		TeleportEntity(iProp, fOrigin, fAngles, NULL_VECTOR);

		SetEntityRenderColor(iProp, iColor[0], iColor[1], iColor[2], iColor[3]);
		SetEntityRenderMode(iProp, RENDER_TRANSALPHA);
		
		Flare_SetRenderFX(iProp, sRenderFX);

		g_iColor[iProp][0] = iColor[0];
		g_iColor[iProp][1] = iColor[1];
		g_iColor[iProp][2] = iColor[2];
		g_iColor[iProp][3] = iColor[3];

		Flare_SetOwner(iClient, iProp);

		g_bFlareEnt[iProp] = true;

		Format(g_sPropname[iProp], sizeof(g_sPropname[]), sAlias);

		g_iCount[iClient]++;
	}
	
	return Plugin_Handled;
}

public Action Command_SaveBuild(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]save{default} <buildname>");
		return Plugin_Handled;
	}

	char sSaveName[64];

	GetCmdArg(1, sSaveName, sizeof(sSaveName));

	Flare_SaveBuild(iClient, sSaveName);

	return Plugin_Handled;
}

public Action Command_LoadBuild(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]load{default} <buildname>");
		return Plugin_Handled;
	}

	char sSaveName[64];

	GetCmdArg(1, sSaveName, sizeof(sSaveName));

	Flare_LoadBuild(iClient, sSaveName);

	return Plugin_Handled;
}

public Action Command_Color(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]color{default} <color name>");
		return Plugin_Handled;
	}

	char sColor[64], sColorString[128], sColorBuffer[3][64], sClassname[64];

	GetCmdArg(1, sColor, sizeof(sColor));

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Handle hColors = CreateKeyValues("Colors");

			FileToKeyValues(hColors, g_sColorList);

			KvJumpToKey(hColors, "Names", false);
				
			KvGetString(hColors, sColor, sColorString, sizeof(sColorString), "null");

			KvRewind(hColors);

			CloseHandle(hColors);

			if(StrEqual(sColorString, "null", true))
			{
				Flare_ReplyCommand(iClient, "Color not found.");

				return Plugin_Handled;
			}

			ExplodeString(sColorString, "^", sColorBuffer, 3, sizeof(sColorBuffer[]));

			GetEdictClassname(iEntity, sClassname, sizeof(sClassname));

			if(StrEqual(sClassname, "flare_light", true))
			{
				int iLight = GetEntPropEnt(iEntity, view_as<PropType>(1), "m_hMoveChild");

				g_iColor[iEntity][0] = StringToInt(sColorBuffer[0]);
				g_iColor[iEntity][1] = StringToInt(sColorBuffer[1]);
				g_iColor[iEntity][2] = StringToInt(sColorBuffer[2]);

				g_iColor[iLight][0] = StringToInt(sColorBuffer[0]);
				g_iColor[iLight][1] = StringToInt(sColorBuffer[1]);
				g_iColor[iLight][2] = StringToInt(sColorBuffer[2]);

				SetEntityRenderColor(iLight, g_iColor[iLight][0], g_iColor[iLight][1], g_iColor[iLight][2], g_iColor[iLight][3]);
				SetEntityRenderColor(iEntity, g_iColor[iEntity][0], g_iColor[iEntity][1], g_iColor[iEntity][2], g_iColor[iEntity][3]);
			}else{
				g_iColor[iEntity][0] = StringToInt(sColorBuffer[0]);
				g_iColor[iEntity][1] = StringToInt(sColorBuffer[1]);
				g_iColor[iEntity][2] = StringToInt(sColorBuffer[2]);

				SetEntityRenderColor(iEntity, g_iColor[iEntity][0], g_iColor[iEntity][1], g_iColor[iEntity][2], g_iColor[iEntity][3]);
			}

			Flare_ClientBeam(iClient, iEntity, true);

			Flare_ReplyCommand(iClient, "You have set entity {green}#%i{default} to {green}%s{default}.", iEntity, sColor);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Door(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]door{default} <skin>");
		return Plugin_Handled;
	}

	if(g_iCount[iClient] >= g_iLimit)
	{
		Flare_ReplyCommand(iClient, "You have reached your props limit.");
		return Plugin_Handled;
	}

	char sDoor[64];

	GetCmdArg(1, sDoor, sizeof(sDoor));

	Flare_SpawnDoor(iClient, sDoor, 255, 255, 255, 255);

	Flare_ReplyCommand(iClient, "Spawned door.");

	return Plugin_Handled;
}

public Action Command_SMove(int iClient, int iArgs)
{
	float fAddOrigin[3], fEntityOrigin[3], fOrigin[3];

	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]smove{default} <x> <y> <z>");
		return Plugin_Handled;
	}

	for(int i = 0; i < 3; i++)
	{
		char sDegree[64];

		GetCmdArg(i+1, sDegree, sizeof(sDegree));

		fAddOrigin[i] = StringToFloat(sDegree);
	}

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityOrigin);

			AddVectors(fEntityOrigin, fAddOrigin, fOrigin);

			TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Alpha(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]alpha{default} <transparency>");
		return Plugin_Handled;
	}

	char sAlpha[64];

	GetCmdArg(1, sAlpha, sizeof(sAlpha));

	int iAlpha = StringToInt(sAlpha);

	if(iAlpha < 50 || iAlpha > 255)
	{
		iAlpha = 255;
	}

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Flare_ClientBeam(iClient, iEntity, true);

			g_iColor[iEntity][3] = iAlpha;
					
			SetEntityRenderColor(iEntity, g_iColor[iEntity][0], g_iColor[iEntity][1], g_iColor[iEntity][2], g_iColor[iEntity][3]);

			Flare_ReplyCommand(iClient, "You have set alpha transparency of entity {green}#%i{default} to {green}%i{default}.", iEntity, g_iColor[iEntity][3]);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Axis(int iClient, int iArgs)
{
	float fOrigin[3], fOriginX[3], fOriginY[3], fOriginZ[3];

	GetClientAbsOrigin(iClient, fOrigin);
	GetClientAbsOrigin(iClient, fOriginX);
	GetClientAbsOrigin(iClient, fOriginY);
	GetClientAbsOrigin(iClient, fOriginZ);

	fOriginX[0] += 50;
	fOriginY[1] += 50;
	fOriginZ[2] += 50;

	TE_SetupBeamPoints(fOrigin, fOriginX, g_iBeam, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, g_iRed, 10);
	TE_SendToClient(iClient);

	TE_SetupBeamPoints(fOrigin, fOriginY, g_iBeam, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, g_iGreen, 10);
	TE_SendToClient(iClient);

	TE_SetupBeamPoints(fOrigin, fOriginZ, g_iBeam, g_iHalo, 0, 15, 60.0, 3.0, 3.0, 1, 0.0, g_iBlue, 10);
	TE_SendToClient(iClient);

	Flare_ReplyCommand(iClient, "Created X, Y, Z axis markers.");

	return Plugin_Handled;
}

public Action Command_Ladder(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]ladder{default} <1 or 2>");
		return Plugin_Handled;
	}

	if(g_iCount[iClient] >= g_iLimit)
	{
		Flare_ReplyCommand(iClient, "You have reached your props limit.");
		return Plugin_Handled;
	}

	char sLadder[64], sModel[128];

	GetCmdArg(1, sLadder, sizeof(sLadder));

	if(StrEqual(sLadder, "1", true))
	{
		Format(sModel, sizeof(sModel), "models/props_c17/metalladder001.mdl");
	}else{
		Format(sModel, sizeof(sModel), "models/props_c17/metalladder002.mdl");
	}

	float fAngles[3], fFinalAngles[3], fFinalOrigin[3], fEyeOrigin[3];

	GetClientEyePosition(iClient, fEyeOrigin);
	GetClientEyeAngles(iClient, fAngles);
	GetClientAbsAngles(iClient, fFinalAngles);

	Handle hTraceRay = TR_TraceRayFilterEx(fEyeOrigin, fAngles, MASK_SOLID, RayType_Infinite, Flare_FilterPlayer);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fFinalOrigin, hTraceRay);

		if(g_iCount[iClient] >= g_iLimit)
		{}else{
			int iEnt = CreateEntityByName("prop_physics_override");

			PrecacheModel(sModel);

			DispatchKeyValue(iEnt, "model", sModel);
			DispatchKeyValue(iEnt, "physdamagescale", "0.0");
			DispatchKeyValue(iEnt, "classname", "flare_ladder");
			DispatchKeyValue(iEnt, "spawnflags", "8");

			DispatchSpawn(iEnt);

			int iLadder = CreateEntityByName("func_useableladder");

			DispatchKeyValue(iLadder, "point0", "30 0 0");
			DispatchKeyValue(iLadder, "point1", "30 0 128");
			DispatchKeyValue(iLadder, "StartDisabled", "0");

			DispatchSpawn(iLadder);

			SetVariantString("!activator");

			AcceptEntityInput(iLadder, "setparent", iEnt);

			TeleportEntity(iEnt, fFinalOrigin, fFinalAngles, NULL_VECTOR);

			g_iColor[iEnt][0] = 255;
			g_iColor[iEnt][1] = 255;
			g_iColor[iEnt][2] = 255;
			g_iColor[iEnt][3] = 255;

			SetEntityRenderColor(iEnt, g_iColor[iEnt][0], g_iColor[iEnt][1], g_iColor[iEnt][2], g_iColor[iEnt][3]);
			SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
			
			Flare_SetRenderFX(iEnt, "default");

			Format(g_sPropname[iEnt], sizeof(g_sPropname[]), "ladder");

			g_iCount[iClient]++;

			g_bFlareEnt[iEnt] = true;

			Flare_SetOwner(iClient, iEnt);
		}
	}

	return Plugin_Handled;
}

public Action Command_Internet(int iClient, int iArgs)
{
	if(g_iCount[iClient] >= g_iLimit)
	{
		Flare_ReplyCommand(iClient, "You have reached your props limit.");
		return Plugin_Handled;
	}

	float fAngles[3], fFinalAngles[3], fFinalOrigin[3], fEyeOrigin[3];

	GetClientEyePosition(iClient, fEyeOrigin);
	GetClientEyeAngles(iClient, fAngles);
	GetClientAbsAngles(iClient, fFinalAngles);

	Handle hTraceRay = TR_TraceRayFilterEx(fEyeOrigin, fAngles, MASK_SOLID, RayType_Infinite, Flare_FilterPlayer);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fFinalOrigin, hTraceRay);

		if(g_iCount[iClient] >= g_iLimit)
		{}else{
			int iEnt = CreateEntityByName("prop_physics_override");

			DispatchKeyValue(iEnt, "model", "models/props_lab/monitor02.mdl");
			DispatchKeyValue(iEnt, "targetname", "http://google.com");
			DispatchKeyValue(iEnt, "classname", "flare_internet");

			DispatchSpawn(iEnt);

			TeleportEntity(iEnt, fFinalOrigin, fFinalAngles, NULL_VECTOR);

			g_iColor[iEnt][0] = 255;
			g_iColor[iEnt][1] = 255;
			g_iColor[iEnt][2] = 255;
			g_iColor[iEnt][3] = 255;

			SetEntityRenderColor(iEnt, g_iColor[iEnt][0], g_iColor[iEnt][1], g_iColor[iEnt][2], g_iColor[iEnt][3]);
			SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
			
			Flare_SetRenderFX(iEnt, "default");

			Format(g_sPropname[iEnt], sizeof(g_sPropname[]), "internet");

			g_iCount[iClient]++;

			g_bFlareEnt[iEnt] = true;

			Flare_SetOwner(iClient, iEnt);
		}
	}

	return Plugin_Handled;
}

public Action Command_SetUrl(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]seturl{default} <url>");
		return Plugin_Handled;
	}

	char sUrl[128], sClassname[64];

	GetCmdArgString(sUrl, sizeof(sUrl));

	if(StrContains(sUrl, "http://", false) != -1 || StrContains(sUrl, "https://", false) != -1)
	{
		//Do Nothing.
	}else{
		Format(sUrl, sizeof(sUrl), "http://%s", sUrl);
	}

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			GetEdictClassname(iEntity, sClassname, sizeof(sClassname));

			if(StrEqual(sClassname, "flare_internet", true))
			{
				DispatchKeyValue(iEntity, "targetname", sUrl);
				
				Flare_ClientBeam(iClient, iEntity, true);

				Flare_ReplyCommand(iClient, "Set internet url to {green}%s{default}.", sUrl);
			}else{
				Flare_ReplyCommand(iClient, "You can only preform this command on internet props.");
			}
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Light(int iClient, int iArgs)
{
	if(g_iCount[iClient] >= g_iLimit)
	{
		Flare_ReplyCommand(iClient, "You have reached your props limit.");
		return Plugin_Handled;
	}

	float fAngles[3], fFinalAngles[3], fFinalOrigin[3], fEyeOrigin[3];

	GetClientEyePosition(iClient, fEyeOrigin);
	GetClientEyeAngles(iClient, fAngles);
	GetClientAbsAngles(iClient, fFinalAngles);

	Handle hTraceRay = TR_TraceRayFilterEx(fEyeOrigin, fAngles, MASK_SOLID, RayType_Infinite, Flare_FilterPlayer);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fFinalOrigin, hTraceRay);

		if(g_iCount[iClient] >= g_iLimit)
		{}else{
			char sLightName[32], sLightOutput[32], sLightColor[32], sLightAlpha[32];

			Format(sLightColor, sizeof(sLightColor), "%d %d %d", 255, 255, 255);

			IntToString(255, sLightAlpha, sizeof(sLightAlpha));

			int iEnt = CreateEntityByName("prop_physics_override");

			PrecacheModel("models/roller_spikes.mdl");

			DispatchKeyValue(iEnt, "model", "models/roller_spikes.mdl");
			DispatchKeyValue(iEnt, "physdamagescale", "1.0");
			DispatchKeyValue(iEnt, "classname", "flare_light");
			DispatchKeyValue(iEnt, "spawnflags", "256");
			DispatchKeyValue(iEnt, "rendermode", "1");
			DispatchKeyValue(iEnt, "renderamt", sLightAlpha);

			g_iColor[iEnt][0] = 255;
			g_iColor[iEnt][1] = 255;
			g_iColor[iEnt][2] = 255;
			g_iColor[iEnt][3] = 255;

			SetEntityRenderColor(iEnt, g_iColor[iEnt][0], g_iColor[iEnt][1], g_iColor[iEnt][2], g_iColor[iEnt][3]);
			SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
			
			Flare_SetRenderFX(iEnt, "default");

			DispatchSpawn(iEnt);

			int iLight = CreateEntityByName("light_dynamic");

			DispatchKeyValue(iLight, "rendercolor", sLightColor);
			DispatchKeyValue(iLight, "classname", "flare_light");
			DispatchKeyValue(iLight, "inner_cone", "300");
			DispatchKeyValue(iLight, "cone", "500");
			DispatchKeyValue(iLight, "spotlight_radius", "500");
			DispatchKeyValue(iLight, "brightness", "0.5");

			DispatchSpawn(iLight);

			SetVariantString("!activator");

			AcceptEntityInput(iLight, "setparent", iEnt);

			int iRandom = iClient + GetRandomInt(1, 1000);

			Format(sLightName, 32, "light_%d", iRandom);
			Format(sLightOutput, 32, "%s,toggle,,0,-1", sLightName);

			DispatchKeyValue(iLight, "targetname", sLightName);
			DispatchKeyValue(iEnt, "OnPlayerUse", sLightOutput);

			SetVariantInt(500);

			AcceptEntityInput(iLight, "distance");
			AcceptEntityInput(iEnt, "disableshadow");
			AcceptEntityInput(iLight, "TurnOn");

			g_iColor[iLight][0] = 255;
			g_iColor[iLight][1] = 255;
			g_iColor[iLight][2] = 255;
			g_iColor[iLight][3] = 255;

			TeleportEntity(iEnt, fFinalOrigin, fFinalAngles, NULL_VECTOR);

			Format(g_sPropname[iEnt], sizeof(g_sPropname[]), "light");

			g_iCount[iClient]++;

			g_bFlareEnt[iEnt] = true;

			Flare_SetOwner(iClient, iEnt);
		}
	}

	return Plugin_Handled;
}

public Action Command_NPC(int iClient, int iArgs)
{
	if(!g_bHL2MP)
	{
		Flare_ReplyCommand(iClient, "You can only use this command on Half-Life 2: Deathmatch.");
		return Plugin_Handled;
	}

	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]npc{default} <npcname>");
		return Plugin_Handled;
	}

	if(g_iCount[iClient] >= g_iLimit)
	{
		Flare_ReplyCommand(iClient, "You have reached your props limit.");
		return Plugin_Handled;
	}

	char sNPC[64], sNPCString[256];

	GetCmdArg(1, sNPC, sizeof(sNPC));

	Handle hNpcs = CreateKeyValues("NPCS");

	FileToKeyValues(hNpcs, g_sNPCList);

	KvJumpToKey(hNpcs, "Names", false);
	
	KvGetString(hNpcs, sNPC, sNPCString, sizeof(sNPCString), "null");

	KvRewind(hNpcs);

	CloseHandle(hNpcs);

	if(StrEqual(sNPCString, "null", true))
	{
		Flare_ReplyCommand(iClient, "Cannot spawn this npc.");

		return Plugin_Handled;
	}

	float fAngles[3], fFinalAngles[3], fFinalOrigin[3], fEyeOrigin[3];

	GetClientEyePosition(iClient, fEyeOrigin);
	GetClientEyeAngles(iClient, fAngles);
	GetClientAbsAngles(iClient, fFinalAngles);

	Handle hTraceRay = TR_TraceRayFilterEx(fEyeOrigin, fAngles, MASK_SOLID, RayType_Infinite, Flare_FilterPlayer);
	
	if !Flare_CheckBlackList(iClient, false, sNPC) *then return Plugin_Handled;

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fFinalOrigin, hTraceRay);

		if(g_iCount[iClient] >= g_iLimit)
		{}else{
			int iNPC = CreateEntityByName(sNPCString);

			DispatchSpawn(iNPC);

			TeleportEntity(iNPC, fFinalOrigin, fFinalAngles, NULL_VECTOR);

			g_iColor[iNPC][0] = 255;
			g_iColor[iNPC][1] = 255;
			g_iColor[iNPC][2] = 255;
			g_iColor[iNPC][3] = 255;

			SetEntityRenderColor(iNPC, g_iColor[iNPC][0], g_iColor[iNPC][1], g_iColor[iNPC][2], g_iColor[iNPC][3]);
			SetEntityRenderMode(iNPC, RENDER_TRANSALPHA);
			
			Flare_SetRenderFX(iNPC, "default");

			ReplaceString(sNPCString, sizeof(sNPCString), "npc_", "");

			Format(g_sPropname[iNPC], sizeof(g_sPropname[]), sNPCString);

			g_iCount[iClient]++;

			g_bFlareEnt[iNPC] = true;

			Flare_SetOwner(iClient, iNPC);
			
			SetEntProp(iNPC, Prop_Data, "m_takedamage", 0, 1);
		}
	}

	return Plugin_Handled;
}

public Action Command_ClearBuild(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]clear{default} <buildname>");
		return Plugin_Handled;
	}

	char sSaveName[64];

	GetCmdArg(1, sSaveName, sizeof(sSaveName));

	char sPath[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/flare/saves/%s/%s/%s.txt", g_sMap, g_sAuthID[iClient], sSaveName);

	if(FileExists(sPath, true))
	{
		DeleteFile(sPath);

		Flare_ReplyCommand(iClient, "Cleared {green}%s{default}.", sSaveName);
	}else{
		Flare_ReplyCommand(iClient, "{green}%s{default} save file does not exist in the database..", sSaveName);
	}

	return Plugin_Handled;
}

public Action Command_DeleteAll(int iClient, int iArgs)
{
	for(int i = 0; i < GetMaxEntities(); i++)
	{
		if(Flare_CheckOwner(iClient, i))
		{
			if(g_bFlareEnt[i])
			{
				g_bFlareEnt[i] = false;
				
				Format(g_sRenderFX[i], sizeof(g_sRenderFX[]), "default");
				
				Flare_RemoveEntity(i);

				g_iCount[iClient]--;
			}
		}
	}

	return Plugin_Handled;
}

public Action Command_MoveTo(int iClient, int iArgs)
{
	float fAddOrigin[3];

	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]moveto{default} <x> <y> <z>");
		return Plugin_Handled;
	}

	for(int i = 0; i < 3; i++)
	{
		char sDegree[64];

		GetCmdArg(i+1, sDegree, sizeof(sDegree));

		fAddOrigin[i] = StringToFloat(sDegree);
	}

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			TeleportEntity(iEntity, fAddOrigin, NULL_VECTOR, NULL_VECTOR);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Skin(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]skin{default} <skin number>");
		return Plugin_Handled;
	}

	char sSkin[64];

	GetCmdArg(1, sSkin, sizeof(sSkin));

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Flare_ClientBeam(iClient, iEntity, true);

			DispatchKeyValue(iEntity, "skin", sSkin);

			Flare_ReplyCommand(iClient, "You have set the skin of entity {green}#%i{default} to {green}%s{default}.", iEntity, sSkin);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Owner(int iClient, int iArgs)
{
	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(g_bFlareEnt[iEntity])
	{
		Flare_ReplyCommand(iClient, "The owner of entity {green}#%i{default} is {green}%N{default}.", iEntity, Flare_GetOwner(iEntity));
	}else{
		Flare_NotLooking(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Balance(int iClient, int iArgs)
{
	Flare_ReplyCommand(iClient, "Your balance is {green}$%i{default}.", g_iBalance[iClient]);

	return Plugin_Handled;
}

public Action Command_Fly(int iClient, int iArgs)
{
	MoveType iMoveType = GetEntityMoveType(iClient);
	
	if (iMoveType == MOVETYPE_NOCLIP)
	{
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		Flare_ReplyCommand(iClient, "Noclip has been disabled.");
	} else {
		SetEntityMoveType(iClient, MOVETYPE_NOCLIP);
		Flare_ReplyCommand(iClient, "Noclip has been enabled.");
	}
	
	return Plugin_Handled;
}

public Action Command_SendMessage(int iClient, int iArgs)
{
	char sArg[128], sMessage[512];
	
	if (iArgs < 2)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]msg{default} <recipent> <message>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArgString(sMessage, sizeof(sMessage));
	
	int iTarget = FindTarget(iClient, sArg, true, false);
	
	if (iTarget == -1)
	{
		Flare_ReplyCommand(iClient, "{green}%N{default} is not a valid client!", iTarget);
		return Plugin_Handled;
	}
	
	if(iTarget == iClient)
	{
		Flare_ReplyCommand(iClient, "You cannot message yourself!");
		return Plugin_Handled;
	}
	
	ReplaceString(sMessage, sizeof(sMessage), sArg, "", true);
	TrimString(sMessage);
	
	Flare_PrintChat(iClient, "To: {green}%N{default} - %s", iTarget, sMessage);
	Flare_PrintChat(iTarget, "From: {green}%N{default} - %s", iClient, sMessage);
	
	g_iLastPlayer[iClient] = iTarget;
	
	ClientCommand(iTarget, "play friends/message.wav");
	
	return Plugin_Handled;
}

public Action Command_Reply(int iClient, int iArgs)
{
	char sMessage[512];

	if (iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]reply{default} <message>");
		return Plugin_Handled;
	}

	GetCmdArgString(sMessage, sizeof(sMessage));
	
	if(g_iLastPlayer[iClient] == -1)
	{
		Flare_ReplyCommand(iClient, "No-one has messaged you yet! Type {green}!msg{default} to message someone!");
		return Plugin_Handled;
	}
	
	Flare_PrintChat(iClient, "To: {green}%N{default} - %s", g_iLastPlayer[iClient], sMessage);
	Flare_PrintChat(g_iLastPlayer[iClient], "From: {green}%N{default} - %s", iClient, sMessage);
	
	ClientCommand(g_iLastPlayer[iClient], "play friends/message.wav");
	
	return Plugin_Handled;
}

public Action Command_Count(int iClient, int iArgs)
{
	Flare_ReplyCommand(iClient, "You've spawned {green}%i{default} entities.", g_iCount[iClient]);
	
	return Plugin_Handled;
}

public Action Command_RenderFX(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		Flare_ReplyCommand(iClient, "{green}[flr_tag]renderfx{default} <renderfx>");
		return Plugin_Handled;
	}

	char sAlias[64];

	GetCmdArg(1, sAlias, sizeof(sAlias));

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		Flare_NotLooking(iClient);
		return Plugin_Handled;
	}

	if(Flare_CheckOwner(iClient, iEntity))
	{
		if(g_bFlareEnt[iEntity])
		{
			Flare_SetRenderFX(iEntity, sAlias);

			Flare_ClientBeam(iClient, iEntity, true);

			Flare_ReplyCommand(iClient, "You have set entity {green}#%i{default} to renderfx {green}%s{default}.", iEntity, sAlias);
		}else{
			Flare_NotLooking(iClient);
		}
	}else{
		Flare_NotYours(iClient);
	}

	return Plugin_Handled;
}

public Action Command_Explode(int iClient, int iArgs)
{
	float fAngles[3], fFinalAngles[3], fFinalOrigin[3], fOrigin[3];
	
	GetClientEyePosition(iClient, fOrigin);
	GetClientEyeAngles(iClient, fAngles);
	GetClientAbsAngles(iClient, fFinalAngles);
	
	int iExplosion = CreateEntityByName("env_physexplosion");
	int iExplosionEffect = CreateEntityByName("env_ar2explosion");
	
	DispatchKeyValue(iExplosion, "inner_radius", "175");
	DispatchKeyValue(iExplosion, "magnitude", "1750");
	DispatchKeyValue(iExplosion, "spawnflags", "18");
	DispatchKeyValue(iExplosion, "targetname", "physics_explosion");
	DispatchKeyValue(iExplosion, "radius", "1000");
	
	DispatchKeyValue(iExplosionEffect, "material", "particle/particle_ring_wave_8");
	DispatchKeyValue(iExplosionEffect, "targetname", "phys_explode_visual");
	DispatchKeyValue(iExplosionEffect, "spawnflags", "1");
	
	DispatchSpawn(iExplosion);
	DispatchSpawn(iExplosionEffect);

	Handle hTraceRay = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SOLID, RayType_Infinite, Flare_FilterPlayer);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fFinalOrigin, hTraceRay);
		
		TeleportEntity(iExplosion, fFinalOrigin, fFinalAngles, NULL_VECTOR);
		TeleportEntity(iExplosionEffect, fFinalOrigin, fFinalAngles, NULL_VECTOR);
		
		CloseHandle(hTraceRay);
	}
	
	AcceptEntityInput(iExplosion, "Explode");
	AcceptEntityInput(iExplosionEffect, "Explode");

	AcceptEntityInput(iExplosion, "kill");
	AcceptEntityInput(iExplosionEffect, "kill");
	
	return Plugin_Handled;
}

//Stocks:
void Flare_RemoveEntity(int iEntity)
{
	DispatchKeyValue(iEntity, "classname", "deleted");

	AcceptEntityInput(g_iEntityDissolver, "dissolve");
}

void Flare_ClientBeam(int iClient, int iEntity, bool bChange)
{
	float fAngles[3], fOrigin[3], fEOrigin[3];
	char sSound[64];
	
	if(bChange)
	{
		GetClientAbsOrigin(iClient, fOrigin);
		GetClientEyeAngles(iClient, fAngles);
			
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEOrigin);

		TE_SetupBeamPoints(fOrigin, fEOrigin, g_iPhys, g_iHalo, 0, 15, 0.1, 3.0, 3.0, 1, 0.0, g_iWhite, 10);
		TE_SendToAll();
	
		TE_SetupSparks(fEOrigin, g_fZero, 3, 2);
		TE_SendToAll();
	
		switch(GetRandomInt(0, 1))
		{
			case 0:
			{
				Format(sSound, sizeof(sSound), "weapons/airboat/airboat_gun_lastshot1.wav");
			}
			case 1:
			{
				Format(sSound, sizeof(sSound), "weapons/airboat/airboat_gun_lastshot2.wav");
			}
			default:
			{
			}
		}
	
		EmitSoundToAll(sSound, iEntity, 2, 100, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}else{
		Format(sSound, sizeof(sSound), "ambient/levels/citadel/weapon_disintegrate4.wav");

		GetClientAbsOrigin(iClient, fOrigin);
		GetClientEyeAngles(iClient, fAngles);

		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEOrigin);

		TE_SetupBeamPoints(fOrigin, fEOrigin, g_iLaser, g_iHalo, 0, 15, 0.25, 15.0, 15.0, 1, 0.0, g_iGray, 10);
		TE_SendToAll();

		TE_SetupBeamRingPoint(fEOrigin, 10.0, 60.0, g_iBeam, g_iHalo, 0, 15, 0.5, 5.0, 0.0, g_iGray, 10, 0);
		TE_SendToAll();

		EmitAmbientSound(sSound, fEOrigin, iEntity, 100, 0, 1.0, 100, 0.0);
	}
}

void Flare_SaveBuild(int iClient, char[] sSaveName)
{
	float fOrigin[3], fAngles[3];
	char sBuffers[14][256], sCount[32], sPath[PLATFORM_MAX_PATH], sTargetname[128];

	int iCount = 0;

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/flare/saves/%s/%s/%s.txt", g_sMap, g_sAuthID[iClient], sSaveName);
	if(FileExists(sPath))
	{
		DeleteFile(sPath);
	}

	KeyValues hSaveDatabase = CreateKeyValues(sSaveName);

	FileToKeyValues(hSaveDatabase, sPath);

	for(int i = 0; i < GetMaxEntities(); i++)
	{
		if(g_bFlareEnt[i] && IsValidEntity(i) && Flare_CheckOwner(iClient, i))
		{
			GetEdictClassname(i, sBuffers[0], sizeof(sBuffers[]));
			GetEntPropString(i, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

			GetEntPropString(i, Prop_Data, "m_ModelName", sBuffers[1], sizeof(sBuffers[]));

			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fOrigin);
			GetEntPropVector(i, Prop_Send, "m_angRotation", fAngles);

			RoundFloat(fOrigin[0]);
			RoundFloat(fOrigin[1]);
			RoundFloat(fOrigin[2]);

			RoundFloat(fAngles[0]);
			RoundFloat(fAngles[1]);
			RoundFloat(fAngles[2]);

			IntToString(GetEntProp(i, Prop_Data, "m_nSkin", 1), sBuffers[8], sizeof(sBuffers[]));

			FloatToString(fOrigin[0], sBuffers[2], sizeof(sBuffers[]));
			FloatToString(fOrigin[1], sBuffers[3], sizeof(sBuffers[]));
			FloatToString(fOrigin[2], sBuffers[4], sizeof(sBuffers[]));
			FloatToString(fAngles[0], sBuffers[5], sizeof(sBuffers[]));
			FloatToString(fAngles[1], sBuffers[6], sizeof(sBuffers[]));
			FloatToString(fAngles[2], sBuffers[7], sizeof(sBuffers[]));
			IntToString(GetEntProp(i, Prop_Send, "m_CollisionGroup", 4, 0), sBuffers[9], sizeof(sBuffers[]));

			int iOffset = GetEntSendPropOffs(i, "m_clrRender");
		 
			if(iOffset > 0) 
			{
				IntToString((GetEntData(i, iOffset, 1)), sBuffers[10], sizeof(sBuffers));
				IntToString((GetEntData(i, iOffset + 1, 1)), sBuffers[11], sizeof(sBuffers));
				IntToString((GetEntData(i, iOffset + 2, 1)), sBuffers[12], sizeof(sBuffers));
				IntToString((GetEntData(i, iOffset + 3, 1)), sBuffers[13], sizeof(sBuffers));
			}

			iCount++;

			IntToString(i, sCount, sizeof(sCount));

			Flare_SaveString(hSaveDatabase, sCount, "classname", sBuffers[0]);
			Flare_SaveString(hSaveDatabase, sCount, "targetname", sTargetname);
			Flare_SaveString(hSaveDatabase, sCount, "model", sBuffers[1]);
			Flare_SaveString(hSaveDatabase, sCount, "o1", sBuffers[2]);
			Flare_SaveString(hSaveDatabase, sCount, "o2", sBuffers[3]);
			Flare_SaveString(hSaveDatabase, sCount, "o3", sBuffers[4]);
			Flare_SaveString(hSaveDatabase, sCount, "a1", sBuffers[5]);
			Flare_SaveString(hSaveDatabase, sCount, "a2", sBuffers[6]);
			Flare_SaveString(hSaveDatabase, sCount, "a3", sBuffers[7]);
			Flare_SaveString(hSaveDatabase, sCount, "skin", sBuffers[8]);
			Flare_SaveString(hSaveDatabase, sCount, "collision", sBuffers[9]);
			Flare_SaveString(hSaveDatabase, sCount, "r", sBuffers[10]);
			Flare_SaveString(hSaveDatabase, sCount, "g", sBuffers[11]);
			Flare_SaveString(hSaveDatabase, sCount, "b", sBuffers[12]);
			Flare_SaveString(hSaveDatabase, sCount, "a", sBuffers[13]);
			Flare_SaveString(hSaveDatabase, sCount, "renderfx", g_sRenderFX[i]);
			Flare_SaveString(hSaveDatabase, sCount, "propname", g_sPropname[i]);
		}
	}

	KeyValuesToFile(hSaveDatabase, sPath);

	CloseHandle(hSaveDatabase);

	Flare_ReplyCommand(iClient, "Saved {green}%d{default} props into {green}%s{default}.", iCount, sSaveName);
}

void Flare_LoadBuild(int iClient, char[] sSaveName)
{
	char sPath[PLATFORM_MAX_PATH];
	float fDelay = 0.10;

	BuildPath(Path_SM, sPath, sizeof(sPath), "data/flare/saves/%s/%s/%s.txt", g_sMap, g_sAuthID[iClient], sSaveName);

	if(FileExists(sPath, true))
	{
		Handle hLoadData;

		CreateDataTimer(fDelay, Timer_Load, hLoadData);

		WritePackCell(hLoadData, iClient);
		WritePackString(hLoadData, sPath);
		WritePackString(hLoadData, sSaveName);

		fDelay += 0.10;

		Flare_ReplyCommand(iClient, "Loaded {green}%s{default}.", sSaveName);
	}else{
		Flare_ReplyCommand(iClient, "{green}%s{default} save file does not exist in the database..", sSaveName);
	}
}

int Flare_UseEntity(int iClient)
{
	float fEntityOrigin[3], fClientOrigin[3];

	int iButtons = GetClientButtons(iClient);

	int iEntity = GetClientAimTarget(iClient, false);

	if(iEntity == -1)
	{
		return -1;
	}else{
		if(iButtons & IN_USE)
		{
			if(g_bFlareEnt[iEntity])
			{
				GetClientAbsOrigin(iClient, fClientOrigin);
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityOrigin);

				float fDistance = GetVectorDistance(fClientOrigin, fEntityOrigin);

				if(fDistance <= 150)
				{
					return iEntity;
				}
			}
		}
	}

	return -1;
}

//Timers:
public Action Timer_Load(Handle hTimer, Handle hPack)
{
	ResetPack(hPack);

	int iClient = ReadPackCell(hPack);

	float fOrigin[3], fAngles[3];
	char sBuffers[15][256], sPath[PLATFORM_MAX_PATH], sCount[64], sSaveName[64], sPropname[256], sTargetname[256];

	ReadPackString(hPack, sPath, sizeof(sPath));
	ReadPackString(hPack, sSaveName, sizeof(sSaveName));

	KeyValues hLoad = CreateKeyValues(sSaveName);

	FileToKeyValues(hLoad, sPath);

	for(int iCount = 0; iCount < MAX_ENTITIES; iCount++)
	{
		IntToString(iCount, sCount, sizeof(sCount));

		Flare_LoadString(hLoad, sCount, "classname", "null", sBuffers[0]);

		if(StrEqual(sBuffers[0], "null", true))
		{}else{
			Flare_LoadString(hLoad, sCount, "targetname", "null", sTargetname);
			Flare_LoadString(hLoad, sCount, "model", "null", sBuffers[1]);
			Flare_LoadString(hLoad, sCount, "o1", "null", sBuffers[2]);
			Flare_LoadString(hLoad, sCount, "o2", "null", sBuffers[3]);
			Flare_LoadString(hLoad, sCount, "o3", "null", sBuffers[4]);
			Flare_LoadString(hLoad, sCount, "a1", "null", sBuffers[5]);
			Flare_LoadString(hLoad, sCount, "a2", "null", sBuffers[6]);
			Flare_LoadString(hLoad, sCount, "a3", "null", sBuffers[7]);
			Flare_LoadString(hLoad, sCount, "skin", "null", sBuffers[8]);
			Flare_LoadString(hLoad, sCount, "collision", "null", sBuffers[9]);
			Flare_LoadString(hLoad, sCount, "r", "null", sBuffers[10]);
			Flare_LoadString(hLoad, sCount, "g", "null", sBuffers[11]);
			Flare_LoadString(hLoad, sCount, "b", "null", sBuffers[12]);
			Flare_LoadString(hLoad, sCount, "a", "null", sBuffers[13]);
			Flare_LoadString(hLoad, sCount, "renderfx", "null", sBuffers[14]);
			Flare_LoadString(hLoad, sCount, "propname", "null", sPropname);

			fOrigin = g_fZero;
			fAngles = g_fZero;

			fOrigin[0] = StringToFloat(sBuffers[2]);
			fOrigin[1] = StringToFloat(sBuffers[3]);
			fOrigin[2] = StringToFloat(sBuffers[4]);

			fAngles[0] = StringToFloat(sBuffers[5]);
			fAngles[1] = StringToFloat(sBuffers[6]);
			fAngles[2] = StringToFloat(sBuffers[7]);

			if(StrEqual(sBuffers[0], "prop_physics", true))
			{
				if(g_iCount[iClient] >= g_iLimit)
				{}else{
					int iProp = CreateEntityByName("prop_physics_override");

					PrecacheModel(sBuffers[1]);

					DispatchKeyValue(iProp, "model", sBuffers[1]);
					DispatchKeyValue(iProp, "skin", sBuffers[8]);
					DispatchKeyValue(iProp, "targetname", sTargetname);

					SetEntProp(iProp, Prop_Send, "m_CollisionGroup", StringToInt(sBuffers[9]), 4, 0);

					DispatchSpawn(iProp);

					g_iColor[iProp][0] = StringToInt(sBuffers[10]);
					g_iColor[iProp][1] = StringToInt(sBuffers[11]);
					g_iColor[iProp][2] = StringToInt(sBuffers[12]);
					g_iColor[iProp][3] = StringToInt(sBuffers[13]);

					SetEntityRenderColor(iProp, g_iColor[iProp][0], g_iColor[iProp][1], g_iColor[iProp][2], g_iColor[iProp][3]);
					SetEntityRenderMode(iProp, RENDER_TRANSALPHA);
					
					Flare_SetRenderFX(iProp, sBuffers[14]);

					TeleportEntity(iProp, fOrigin, fAngles, NULL_VECTOR);

					AcceptEntityInput(iProp, "disablemotion");

					Format(g_sPropname[iProp], sizeof(g_sPropname[]), sPropname);

					Flare_SetOwner(iClient, iProp);

					g_bFlareEnt[iProp] = true;

					g_iCount[iClient]++;
				}
			}else if(StrEqual(sBuffers[0], "cycler", true))
			{
				if(g_iCount[iClient] >= g_iLimit)
				{}else{
					int iProp = CreateEntityByName("cycler");

					PrecacheModel(sBuffers[1]);

					DispatchKeyValue(iProp, "model", sBuffers[1]);
					DispatchKeyValue(iProp, "skin", sBuffers[8]);
					DispatchKeyValue(iProp, "targetname", sTargetname);

					SetEntProp(iProp, Prop_Send, "m_CollisionGroup", StringToInt(sBuffers[9]), 4, 0);

					DispatchSpawn(iProp);

					g_iColor[iProp][0] = StringToInt(sBuffers[10]);
					g_iColor[iProp][1] = StringToInt(sBuffers[11]);
					g_iColor[iProp][2] = StringToInt(sBuffers[12]);
					g_iColor[iProp][3] = StringToInt(sBuffers[13]);

					SetEntityRenderColor(iProp, g_iColor[iProp][0], g_iColor[iProp][1], g_iColor[iProp][2], g_iColor[iProp][3]);
					SetEntityRenderMode(iProp, RENDER_TRANSALPHA);
					
					Flare_SetRenderFX(iProp, sBuffers[14]);

					TeleportEntity(iProp, fOrigin, fAngles, NULL_VECTOR);

					Format(g_sPropname[iProp], sizeof(g_sPropname[]), sPropname);

					Flare_SetOwner(iClient, iProp);

					g_bFlareEnt[iProp] = true;

					g_iCount[iClient]++;
				}
			}else if(StrEqual(sBuffers[0], "prop_door_rotating", true))
			{
				if(g_iCount[iClient] >= g_iLimit)
				{}else{
					int iDoor = CreateEntityByName("prop_door_rotating");

					DispatchKeyValue(iDoor, "targetname", sTargetname);
					DispatchKeyValue(iDoor, "model", "models/props_c17/door01_left.mdl");
					DispatchKeyValue(iDoor, "skin", sBuffers[8]);
					DispatchKeyValue(iDoor, "distance", "90");
					DispatchKeyValue(iDoor, "speed", "100");
					DispatchKeyValue(iDoor, "returndelay", "-1");
					DispatchKeyValue(iDoor, "dmg", "-20");
					DispatchKeyValue(iDoor, "opendir", "0");
					DispatchKeyValue(iDoor, "spawnflags", "8192");
					DispatchKeyValue(iDoor, "OnFullyOpen", "!caller,close,,3,-1");
					DispatchKeyValue(iDoor, "hardware", "1");

					DispatchSpawn(iDoor);

					TeleportEntity(iDoor, fOrigin, fAngles, NULL_VECTOR);

					g_iColor[iDoor][0] = StringToInt(sBuffers[10]);
					g_iColor[iDoor][1] = StringToInt(sBuffers[11]);
					g_iColor[iDoor][2] = StringToInt(sBuffers[12]);
					g_iColor[iDoor][3] = StringToInt(sBuffers[13]);

					SetEntityRenderColor(iDoor, g_iColor[iDoor][0], g_iColor[iDoor][1], g_iColor[iDoor][2], g_iColor[iDoor][3]);
					SetEntityRenderMode(iDoor, RENDER_TRANSALPHA);
					
					Flare_SetRenderFX(iDoor, sBuffers[14]);

					g_iCount[iClient]++;

					Flare_SetOwner(iClient, iDoor);

					g_bFlareEnt[iDoor] = true;

					Format(g_sPropname[iDoor], sizeof(g_sPropname[]), sPropname);
				}
			}else if(StrEqual(sBuffers[0], "flare_ladder", true))
			{
				if(g_iCount[iClient] >= g_iLimit)
				{}else{
					int iEnt = CreateEntityByName("prop_physics_override");

					PrecacheModel(sBuffers[1]);

					DispatchKeyValue(iEnt, "model", sBuffers[1]);
					DispatchKeyValue(iEnt, "physdamagescale", "0.0");
					DispatchKeyValue(iEnt, "classname", "flare_ladder");
					DispatchKeyValue(iEnt, "spawnflags", "8");

					DispatchSpawn(iEnt);

					int iLadder = CreateEntityByName("func_useableladder");

					DispatchKeyValue(iLadder, "point0", "30 0 0");
					DispatchKeyValue(iLadder, "point1", "30 0 128");
					DispatchKeyValue(iLadder, "StartDisabled", "0");

					DispatchSpawn(iLadder);

					SetVariantString("!activator");

					AcceptEntityInput(iLadder, "setparent", iEnt);

					TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);

					g_iColor[iEnt][0] = StringToInt(sBuffers[10]);
					g_iColor[iEnt][1] = StringToInt(sBuffers[11]);
					g_iColor[iEnt][2] = StringToInt(sBuffers[12]);
					g_iColor[iEnt][3] = StringToInt(sBuffers[13]);

					SetEntityRenderColor(iEnt, g_iColor[iEnt][0], g_iColor[iEnt][1], g_iColor[iEnt][2], g_iColor[iEnt][3]);
					SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
					
					Flare_SetRenderFX(iEnt, sBuffers[14]);

					Format(g_sPropname[iEnt], sizeof(g_sPropname[]), sPropname);

					g_iCount[iClient]++;

					g_bFlareEnt[iEnt] = true;

					Flare_SetOwner(iClient, iEnt);
				}
			}else if(StrEqual(sBuffers[0], "flare_internet", true))
			{
				if(g_iCount[iClient] >= g_iLimit)
				{}else{
					int iEnt = CreateEntityByName("prop_physics_override");

					DispatchKeyValue(iEnt, "model", sBuffers[1]);
					DispatchKeyValue(iEnt, "targetname", sTargetname);
					DispatchKeyValue(iEnt, "classname", "flare_internet");

					DispatchSpawn(iEnt);

					TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);

					AcceptEntityInput(iEnt, "disablemotion");

					g_iColor[iEnt][0] = StringToInt(sBuffers[10]);
					g_iColor[iEnt][1] = StringToInt(sBuffers[11]);
					g_iColor[iEnt][2] = StringToInt(sBuffers[12]);
					g_iColor[iEnt][3] = StringToInt(sBuffers[13]);

					SetEntityRenderColor(iEnt, g_iColor[iEnt][0], g_iColor[iEnt][1], g_iColor[iEnt][2], g_iColor[iEnt][3]);
					SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
					
					Flare_SetRenderFX(iEnt, sBuffers[14]);

					Format(g_sPropname[iEnt], sizeof(g_sPropname[]), sPropname);

					g_iCount[iClient]++;

					g_bFlareEnt[iEnt] = true;

					Flare_SetOwner(iClient, iEnt);
				}
			}else if(StrEqual(sBuffers[0], "flare_light", true))
			{
				if(g_iCount[iClient] >= g_iLimit)
				{}else{
					char sLightName[32], sLightOutput[32], sLightColor[32];

					Format(sLightColor, sizeof(sLightColor), "%d %d %d", StringToInt(sBuffers[10]), StringToInt(sBuffers[11]), StringToInt(sBuffers[12]));

					int iEnt = CreateEntityByName("prop_physics_override");

					PrecacheModel("models/roller_spikes.mdl");

					DispatchKeyValue(iEnt, "model", "models/roller_spikes.mdl");
					DispatchKeyValue(iEnt, "physdamagescale", "1.0");
					DispatchKeyValue(iEnt, "classname", "flare_light");
					DispatchKeyValue(iEnt, "spawnflags", "256");
					DispatchKeyValue(iEnt, "rendermode", "1");
					DispatchKeyValue(iEnt, "renderamt", sBuffers[13]);

					g_iColor[iEnt][0] = StringToInt(sBuffers[10]);
					g_iColor[iEnt][1] = StringToInt(sBuffers[11]);
					g_iColor[iEnt][2] = StringToInt(sBuffers[12]);
					g_iColor[iEnt][3] = StringToInt(sBuffers[13]);

					SetEntityRenderColor(iEnt, g_iColor[iEnt][0], g_iColor[iEnt][1], g_iColor[iEnt][2], g_iColor[iEnt][3]);
					SetEntityRenderMode(iEnt, RENDER_TRANSALPHA);
					
					Flare_SetRenderFX(iEnt, sBuffers[14]);

					DispatchSpawn(iEnt);

					AcceptEntityInput(iEnt, "disablemotion");

					int iLight = CreateEntityByName("light_dynamic");

					DispatchKeyValue(iLight, "rendercolor", sLightColor);
					DispatchKeyValue(iLight, "classname", "flare_light");
					DispatchKeyValue(iLight, "inner_cone", "300");
					DispatchKeyValue(iLight, "cone", "500");
					DispatchKeyValue(iLight, "spotlight_radius", "500");
					DispatchKeyValue(iLight, "brightness", "0.5");

					DispatchSpawn(iLight);

					SetVariantString("!activator");

					AcceptEntityInput(iLight, "setparent", iEnt);

					int iRandom = iClient + GetRandomInt(1, 1000);

					Format(sLightName, 32, "light_%d", iRandom);
					Format(sLightOutput, 32, "%s,toggle,,0,-1", sLightName);

					DispatchKeyValue(iLight, "targetname", sLightName);
					DispatchKeyValue(iEnt, "OnPlayerUse", sLightOutput);

					SetVariantInt(500);

					AcceptEntityInput(iLight, "distance");
					AcceptEntityInput(iEnt, "disableshadow");
					AcceptEntityInput(iLight, "TurnOn");

					g_iColor[iLight][0] = StringToInt(sBuffers[10]);
					g_iColor[iLight][1] = StringToInt(sBuffers[11]);
					g_iColor[iLight][2] = StringToInt(sBuffers[12]);
					g_iColor[iLight][3] = StringToInt(sBuffers[13]);

					TeleportEntity(iEnt, fOrigin, fAngles, NULL_VECTOR);

					Format(g_sPropname[iEnt], sizeof(g_sPropname[]), sPropname);

					g_iCount[iClient]++;

					g_bFlareEnt[iEnt] = true;

					Flare_SetOwner(iClient, iEnt);
				}
			}else if(StrContains(sBuffers[0], "npc_", true) != -1)
			{
				if(g_iCount[iClient] >= g_iLimit)
				{}else{
					int iNPC = CreateEntityByName(sBuffers[0]);

					DispatchSpawn(iNPC);

					TeleportEntity(iNPC, fOrigin, fAngles, NULL_VECTOR);

					g_iColor[iNPC][0] = StringToInt(sBuffers[10]);
					g_iColor[iNPC][1] = StringToInt(sBuffers[11]);
					g_iColor[iNPC][2] = StringToInt(sBuffers[12]);
					g_iColor[iNPC][3] = StringToInt(sBuffers[13]);

					SetEntityRenderColor(iNPC, g_iColor[iNPC][0], g_iColor[iNPC][1], g_iColor[iNPC][2], g_iColor[iNPC][3]);
					SetEntityRenderMode(iNPC, RENDER_TRANSALPHA);
					
					Flare_SetRenderFX(iNPC, sBuffers[14]);

					Format(g_sPropname[iNPC], sizeof(g_sPropname[]), sPropname);

					g_iCount[iClient]++;

					g_bFlareEnt[iNPC] = true;

					Flare_SetOwner(iClient, iNPC);
					
					SetEntProp(iNPC, Prop_Data, "m_takedamage", 0, 1);
				}
			}
		}
	}
	CloseHandle(hLoad);
}
