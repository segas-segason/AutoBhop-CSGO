#include <sourcemod> 
#include <sdktools>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

#define SERVER_TAG "[Autobhop]"

int g_iround = 0, aa, ebh, st, ec;
float sjc, slc;

Handle abVelocity;
Handle abMeterLocation;
Handle abXRound;

bool MrBool;

public Plugin myinfo =
{
	name = "AutoBhop",
	author = "Cruze",
	description = "Turns on autobhop",
	version = "1.3",
	url = "https://github.com/Cruze03/CSGO-Autobhop-every-x-round"
}
public void OnPluginStart() 
{
	abVelocity		=	CreateConVar("sm_ab_velocity",		"1", "Whether to show velocity when bhop is enabled.");
	abMeterLocation	=	CreateConVar("sm_absm_location", 	"0", "Where should speed meter be shown. 0 = CenterHUD, 1 = New CSGO HUD");
	abXRound		=	CreateConVar("sm_ab_round", 		"1", "Toggle autobhop on every which round?");
	
	AutoExecConfig(true, "autobhop");
	
	LoadTranslations("autobhop.phrases");
	
	HookEvent("round_start", OnBhop_RoundStart);
	HookEvent("player_spawn", OnBhop_PlayerSpawn);
	
	HookUserMessage(GetUserMessageId("TextMsg"), TextMsgHook);
}

public void OnMapStart() 
{
	aa = GetConVarInt(FindConVar("sv_airaccelerate"));
	ebh = GetConVarInt(FindConVar("sv_enablebunnyhopping"));
	sjc = GetConVarFloat(FindConVar("sv_staminajumpcost"));
	slc = GetConVarFloat(FindConVar("sv_staminalandcost"));
	st = GetConVarInt(FindConVar("mp_solid_teammates"));
	g_iround = 0;
	MrBool = false;
	ec = 5; //just incase player_spawn not called.
}

public Action TextMsgHook(UserMsg umId, Handle hMsg, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
{
    //Thank you SM9(); for this!!

	char szName[40]; PbReadString(hMsg, "params", szName, sizeof(szName), 0);
	char szValue[40]; PbReadString(hMsg, "params", szValue, sizeof(szValue), 1);
    
	if (StrEqual(szName, "#SFUI_Notice_Game_will_restart_in", false)) 
	{
		CreateTimer(StringToFloat(szValue), Timer_GameRestarted);
	}
	return Plugin_Continue;
}

public Action Timer_GameRestarted(Handle hTimer)
{
	g_iround = 1; //for some reason 1st round is not being counted after restartgame therefore "1"
}

public void OnBhop_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	//Added for late join players.
	
	if(GetConVarInt(FindConVar("sv_autobunnyhopping")) == 1)
	{
		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, false))
		{
			SetEntProp(i, Prop_Send, "m_CollisionGroup", 2);
		}
	}
	else
	{
		if(!MrBool) //This part is for test ._. Trying to put enemy collision's value to the value which was there before autobhop was enabled.
		{
			for (int i = 1; i <= MaxClients; i++) if(IsValidClient(i, true, true))
			{
				ec = GetEntProp(i, Prop_Send, "m_CollisionGroup");
			}
			MrBool = true;
		}
	}
}

public void OnBhop_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(GameRules_GetProp("m_bWarmupPeriod") != 1)
	{
		g_iround++;
	}
	if((g_iround % GetConVarInt(abXRound)) == 0)
	{
		SetConVarInt(FindConVar("sv_airaccelerate"), 150, true);
		SetConVarInt(FindConVar("sv_autobunnyhopping"), 1, true);
		SetConVarInt(FindConVar("sv_enablebunnyhopping"), 1, true);
		SetConVarFloat(FindConVar("sv_staminajumpcost"), 0.0, true);
		SetConVarFloat(FindConVar("sv_staminalandcost"), 0.0, true);
		SetConVarInt(FindConVar("mp_solid_teammates"), 0, true);
		CPrintToChatAll(" {green}%s {default}%t", SERVER_TAG,"AutoBhop On");
		for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, true))
		{
			PrintHintText(i, "%t", "AutoBhop On");
			SetEntProp(i, Prop_Send, "m_CollisionGroup", 2);
		}
	}
	else
	{
		if(GetConVarInt(FindConVar("sv_autobunnyhopping")) != 0)
		{
			SetConVarInt(FindConVar("sv_airaccelerate"), aa, true);
			SetConVarInt(FindConVar("sv_autobunnyhopping"), 0, true);
			SetConVarInt(FindConVar("sv_enablebunnyhopping"), ebh, true);
			SetConVarFloat(FindConVar("sv_staminajumpcost"), sjc, true);
			SetConVarFloat(FindConVar("sv_staminalandcost"), slc, true);
			SetConVarInt(FindConVar("mp_solid_teammates"), st, true);
			CPrintToChatAll(" {green}%s {default}%t", SERVER_TAG,"AutoBhop Off");
			for (int i = 1; i <= MaxClients; i++) if (IsValidClient(i, true, true))
			{
				PrintHintText(i, "%t", "AutoBhop Off");
				SetEntProp(i, Prop_Send, "m_CollisionGroup", ec);
			}
		}
	}
	
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) 
{

	if(GetConVarInt(FindConVar("sv_autobunnyhopping")) == 1  && IsValidClient(client) && GetConVarBool(abVelocity)) 
	{	
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
		float fVelocity = SquareRoot(Pow(vVel[0], 2.0) + Pow(vVel[1], 2.0));
		SetHudTextParamsEx(-1.0, 0.65, 0.1, {255, 255, 255, 255}, {0, 0, 0, 255}, 0, 0.0, 0.0, 0.0);
		if(IsPlayerAlive(client))
		{
			if(GetConVarBool(abMeterLocation))
			{
				ShowHudText(client, 3, "%t %.2f м/с", "Speed", fVelocity);
			}
			else
			{
				PrintHintText(client, "%t %.2f м/с", "Speed", fVelocity);
			}
		}
		if(IsClientObserver(client))
		{
			int spectarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

			if (spectarget < 1 || spectarget > MaxClients || !IsClientInGame(spectarget))
				return;

			char ClientName[32];
			GetClientName(spectarget, ClientName, 32);
			if(GetConVarBool(abMeterLocation))
			{
				if(IsFakeClient(spectarget))
				{
					ShowHudText(client, 3, "BOT %s %t %.2f м/с", ClientName, "Speed", fVelocity);
				}
				else
				{
					ShowHudText(client, 3, "%s %t %.2f м/с", ClientName, "Speed", fVelocity);
				}
			}
			else
			{
				if(IsFakeClient(spectarget))
				{
					if (GetClientTeam(spectarget) == 2)
					{
						PrintHintText(client, "BOT %s %t %.2f м/с", ClientName, "Speed", fVelocity);
					}
					else
					{
						PrintHintText(client, "BOT %s %t %.2f м/с", ClientName, "Speed", fVelocity);
					}
				}
				else
				{
					if (GetClientTeam(spectarget) == 2)
					{
						PrintHintText(client, "%s %t %.2f м/с", ClientName, "Speed", fVelocity);
					}
					else
					{
						PrintHintText(client, "%s %t %.2f м/с", ClientName, "Speed", fVelocity);
					}
				}
			}
		}
		return;
	}
}
	
bool IsValidClient(int client, bool bAllowBots = true, bool bAllowDead = true)
{
    if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
    {
        return false;
    }
    return true;
}
