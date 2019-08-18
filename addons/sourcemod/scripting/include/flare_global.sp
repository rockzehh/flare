int Flare_SetOwner(int iClient, int iEntity)
{
	g_iOwner[iEntity] = iClient;
}

int Flare_GetOwner(int iEntity)
{
	return g_iOwner[iEntity];
}

bool Flare_CheckOwner(int iClient, int iEntity)
{
	if(Flare_GetOwner(iEntity) == iClient && g_bFlareEnt[iEntity])
	{
		return true;
	}

	return false;
}

void Flare_PlayChatSound(int iClient)
{
	if(IsClientInGame(iClient))
	{
		switch (GetRandomInt(0, 1))
		{
			case 0:
			{
				ClientCommand(iClient, "play npc/stalker/stalker_footstep_left1");
			}
			
			case 1:
			{
				ClientCommand(iClient, "play npc/stalker/stalker_footstep_right1");
			}
			
			default:
			{
			}
		}
	}
}

public void Flare_HudMessage(int iClient, int iChannel, 
float fX, float fY, 
int iR, int iG, int iB, int iA, 
int iEffect, 
float fFadeIn, float fFadeOut, 
float fHoldTime, float fFxTime, 
char[] sMessage)
{
	Handle hHudMessage;
	if (!iClient)
	{
		hHudMessage = StartMessageAll("HudMsg");
	} else {
		hHudMessage = StartMessageOne("HudMsg", iClient);
	}
	if (hHudMessage != INVALID_HANDLE)
	{
		BfWriteByte(hHudMessage, iChannel);
		BfWriteFloat(hHudMessage, fX);
		BfWriteFloat(hHudMessage, fY);
		BfWriteByte(hHudMessage, iR);
		BfWriteByte(hHudMessage, iG);
		BfWriteByte(hHudMessage, iB);
		BfWriteByte(hHudMessage, iA);
		BfWriteByte(hHudMessage, iR);
		BfWriteByte(hHudMessage, iG);
		BfWriteByte(hHudMessage, iB);
		BfWriteByte(hHudMessage, iA);
		BfWriteByte(hHudMessage, iEffect);
		BfWriteFloat(hHudMessage, fFadeIn);
		BfWriteFloat(hHudMessage, fFadeOut);
		BfWriteFloat(hHudMessage, fHoldTime);
		BfWriteFloat(hHudMessage, fFxTime);
		BfWriteString(hHudMessage, sMessage);
		EndMessage();
	}
}

bool Flare_CheckBlackList(int iClient, bool bProp, char[] sAlias)
{
	char sBlackListString[128];
	
	KeyValues hBlackList = CreateKeyValues("BlackList");
	
	FileToKeyValues(hBlackList, g_sBlackList);
	
	KvJumpToKey(hBlackList, bProp ? "Props" : "NPCS", false);
	
	KvGetString(hBlackList, sAlias, sBlackListString, sizeof(sBlackListString), "null");
	
	KvRewind(hBlackList);
	
	CloseHandle(hBlackList);
	
	if(StrEqual(sBlackListString, "null", true))
	{
		return true;
	}else{
		Flare_ReplyCommand(iClient, "You cannot spawn the %s {green}%s{default}! {green}%s{default}", bProp ? "prop" : "npc", sAlias, sBlackListString);
		return false;
	}
}

void Flare_SetRenderFX(int iEntity, char[] sAlias)
{
	if(StrEqual(sAlias, "default", false))
	{
		SetEntityRenderFx(iEntity, RENDERFX_NONE);
	}else if(StrEqual(sAlias, "pulse", false))
	{
		SetEntityRenderFx(iEntity, RENDERFX_PULSE_FAST);
	}else if(StrEqual(sAlias, "fade", false))
	{
		SetEntityRenderFx(iEntity, RENDERFX_FADE_FAST);
	}else if(StrEqual(sAlias, "strobe", false))
	{
		SetEntityRenderFx(iEntity, RENDERFX_STROBE_FAST);
	}else if(StrEqual(sAlias, "flicker", false))
	{
		SetEntityRenderFx(iEntity, RENDERFX_FLICKER_FAST);
	}else if(StrEqual(sAlias, "distort", false))
	{
		SetEntityRenderFx(iEntity, RENDERFX_DISTORT);
	}else if(StrEqual(sAlias, "hologram", false))
	{
		SetEntityRenderFx(iEntity, RENDERFX_HOLOGRAM);
	}
	
	Format(g_sRenderFX[iEntity], sizeof(g_sRenderFX[]), sAlias);
}

void Flare_PrintChat(int iClient, char[] sMessage, any:...)
{
	char sBuffer[MAX_MESSAGE_LENGTH], sBuffer2[MAX_MESSAGE_LENGTH];
	
	Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);
	VFormat(sBuffer2, sizeof(sBuffer2), sBuffer, 3);
	
	CPrintToChat(iClient, "{blue}[Flare]{default} %s", sBuffer2);
	
	Flare_PlayChatSound(iClient);
}

void Flare_PrintChatAll(char[] sMessage, any:...)
{
	char sBuffer[MAX_MESSAGE_LENGTH], sBuffer2[MAX_MESSAGE_LENGTH];
	
	Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);
	VFormat(sBuffer2, sizeof(sBuffer2), sBuffer, 2);
	
	CPrintToChatAll("{blue}[Flare]{default} %s", sBuffer2);
	
	Flare_PlayChatSound(iClient);
}

void Flare_ReplyCommand(int iClient, char[] sMessage, any:...) {
	char sBuffer[MAX_MESSAGE_LENGTH * 2], sBuffer2[MAX_MESSAGE_LENGTH];

	Format(sBuffer, sizeof(sBuffer), "\x01%s", sMessage);

	VFormat(sBuffer2, sizeof(sBuffer2), sBuffer, 3);
	
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		CRemoveTags(sBuffer2, sizeof(sBuffer2));
		
		ReplaceString(sBuffer2, sizeof(sBuffer2), "[flr_tag]", "sm_", true);
		
		PrintToConsole(iClient, "[Flare] %s", sBuffer2);
	}else{
		ReplaceString(sBuffer2, sizeof(sBuffer2), "[flr_tag]", "!", true);
		
		CPrintToChat(iClient, "{blue}[Flare]{default} %s", sBuffer2);
		
		Flare_PlayChatSound(iClient);
	}
}

void Flare_SpawnEntity(int iClient, char[] sAlias, char[] sEntity, char[] sModel, int iR, int iG, int iB, int iA)
{
	float fAngles[3], fFinalAngles[3], fFinalOrigin[3], fOrigin[3];

	GetClientEyePosition(iClient, fOrigin);
	GetClientEyeAngles(iClient, fAngles);
	GetClientAbsAngles(iClient, fFinalAngles);

	Handle hTraceRay = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SOLID, RayType_Infinite, Flare_FilterPlayer);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fFinalOrigin, hTraceRay);

		int iEntity = CreateEntityByName(sEntity);

		PrecacheModel(sModel);

		DispatchKeyValue(iEntity, "model", sModel);

		DispatchSpawn(iEntity);

		SetEntityRenderColor(iEntity, iR, iG, iB, iA);
		SetEntityRenderMode(iEntity, RENDER_TRANSALPHA);
		
		Flare_SetRenderFX(iEntity, "default");

		g_iColor[iEntity][0] = iR;
		g_iColor[iEntity][1] = iG;
		g_iColor[iEntity][2] = iB;
		g_iColor[iEntity][3] = iA;

		Flare_SetOwner(iClient, iEntity);

		g_iCount[iClient]++;

		g_bFlareEnt[iEntity] = true;

		Format(g_sPropname[iEntity], sizeof(g_sPropname[]), sAlias);

		TeleportEntity(iEntity, fFinalOrigin, fFinalAngles, NULL_VECTOR);

		CloseHandle(hTraceRay);
	}
}

void Flare_NotLooking(int iClient)
{
	Flare_ReplyCommand(iClient, "You are not looking at anything!");
}

void Flare_NotYours(int iClient)
{
	Flare_ReplyCommand(iClient, "That does not belong to you!");
}

void Flare_SaveString(KeyValues hVault, char[] sKey,  char[] sSaveKey, char[] sVariable)
{
	KvJumpToKey(hVault, sKey, true);

	KvSetString(hVault, sSaveKey, sVariable);

	KvRewind(hVault);
}

void Flare_LoadString(KeyValues hVault, char[] sKey, char[] sSaveKey, char[] sDefaultValue, char sReference[256])
{
	KvJumpToKey(hVault, sKey, false);
	
	KvGetString(hVault, sSaveKey, sReference, sizeof(sReference), sDefaultValue);

	KvRewind(hVault);
}

void Flare_SpawnDoor(int iClient, char[] sSkin, int iR, int iG, int iB, int iA)
{
	float fAngles[3], fFinalAngles[3], fFinalOrigin[3], fEyeOrigin[3], fOrigin[3];

	GetClientEyePosition(iClient, fEyeOrigin);
	GetClientEyeAngles(iClient, fAngles);
	GetClientAbsAngles(iClient, fFinalAngles);

	Handle hTraceRay = TR_TraceRayFilterEx(fEyeOrigin, fAngles, MASK_SOLID, RayType_Infinite, Flare_FilterPlayer);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(fFinalOrigin, hTraceRay);

		int iDoor = CreateEntityByName("prop_door_rotating");

		DispatchKeyValue(iDoor, "model", "models/props_c17/door01_left.mdl");
		DispatchKeyValue(iDoor, "skin", sSkin);
		DispatchKeyValue(iDoor, "distance", "90");
		DispatchKeyValue(iDoor, "speed", "100");
		DispatchKeyValue(iDoor, "returndelay", "-1");
		DispatchKeyValue(iDoor, "dmg", "-20");
		DispatchKeyValue(iDoor, "opendir", "0");
		DispatchKeyValue(iDoor, "spawnflags", "8192");
		DispatchKeyValue(iDoor, "OnFullyOpen", "!caller,close,,3,-1");
		DispatchKeyValue(iDoor, "hardware", "1");

		DispatchSpawn(iDoor);

		fOrigin[0] = fFinalOrigin[0];
		fOrigin[1] = fFinalOrigin[1];
		fOrigin[2] = fFinalOrigin[2] += 52;

		TeleportEntity(iDoor, fOrigin, fFinalAngles, NULL_VECTOR);

		g_iColor[iDoor][0] = iR;
		g_iColor[iDoor][1] = iG;
		g_iColor[iDoor][2] = iB;
		g_iColor[iDoor][3] = iA;

		SetEntityRenderColor(iDoor, g_iColor[iDoor][0], g_iColor[iDoor][1], g_iColor[iDoor][2], g_iColor[iDoor][3]);
		SetEntityRenderMode(iDoor, RENDER_TRANSALPHA);

		g_iCount[iClient]++;

		Flare_SetOwner(iClient, iDoor);

		g_bFlareEnt[iDoor] = true;

		Format(g_sPropname[iDoor], sizeof(g_sPropname[]), "door");

		CloseHandle(hTraceRay);
	}
}