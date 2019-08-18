#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#define VERSION "1.0.0"

public Plugin myinfo = 
{
	name = "Flare - Chat Hooks",
	author = "FusionLock",
	description = "Chat hooks for the Flare plugin.",
	version = VERSION,
	url = "https://github.com/xfusionlockx/flare"
}

public void OnPluginStart()
{
	//sm_rotate
	RegConsoleCmd("sm_flip", Command_Flip, "Flare - Chat Hook");
	RegConsoleCmd("sm_r", Command_Rotate, "Flare - Chat Hook");
	RegConsoleCmd("sm_roll", Command_Roll, "Flare - Chat Hook");

	//sm_delete
	RegConsoleCmd("sm_del", Command_Delete, "Flare - Chat Hook");

	//sm_deleteall
	RegConsoleCmd("sm_delall", Command_DeleteAll, "Flare - Chat Hook");

	//sm_straight
	RegConsoleCmd("sm_stand", Command_Straight, "Flare - Chat Hook");

	//sm_alpha
	RegConsoleCmd("sm_amt", Command_Alpha, "Flare - Chat Hook");

	AddCommandListener(HandleChat, "say");
	AddCommandListener(HandleChat, "say_team");  
}

public Action HandleChat(int iClient, char[] sCommand, int iArgs)
{
	if(IsChatTrigger())
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
} 

public Action Command_Flip(int iClient, int iArgs)
{
	char sArg[64];

	GetCmdArg(1, sArg, sizeof(sArg));

	FakeClientCommand(iClient, "sm_rotate %s", sArg);

	return Plugin_Handled;
}

public Action Command_Rotate(int iClient, int iArgs)
{
	char sArg[64];

	GetCmdArg(1, sArg, sizeof(sArg));

	FakeClientCommand(iClient, "sm_rotate 0 %s", sArg);

	return Plugin_Handled;
}

public Action Command_Roll(int iClient, int iArgs)
{
	char sArg[64];

	GetCmdArg(1, sArg, sizeof(sArg));

	FakeClientCommand(iClient, "sm_rotate 0 0 %s", sArg);

	return Plugin_Handled;
}

public Action Command_Delete(int iClient, int iArgs)
{
	FakeClientCommand(iClient, "sm_delete");

	return Plugin_Handled;
}

public Action Command_DeleteAll(int iClient, int iArgs)
{
	FakeClientCommand(iClient, "sm_deleteall");

	return Plugin_Handled;
}

public Action Command_Straight(int iClient, int iArgs)
{
	FakeClientCommand(iClient, "sm_straight");

	return Plugin_Handled;
}

public Action Command_Alpha(int iClient, int iArgs)
{
	char sArg[64];

	GetCmdArg(1, sArg, sizeof(sArg));

	FakeClientCommand(iClient, "sm_alpha %s", sArg);

	return Plugin_Handled;
}
