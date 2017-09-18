#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <sdkhooks>
#include <morecolors>
#include <steamtools>
#include <tf2_ammo>
#include <tf2attributes>
#include <tf2_objects>

#pragma newdecls required

// Condition start sounds
#define SOUND_BELL		"misc/halloween/strongman_bell_01.wav"
#define	SOUND_CRITS		"vo/halloween_merasmus/sf12_wheel_crits02.mp3"
#define SOUND_MINICRITS 		"items/powerup_pickup_base.wav"
#define SOUND_SPEEDBOOST 		"items/powerup_pickup_agility.wav"
#define SOUND_HEALTHBOOST 		"items/powerup_pickup_regeneration.wav"
#define SOUND_SUPERJUMP 		"vo/halloween_merasmus/sf12_wheel_jump01.mp3"
#define SOUND_INFJUMPS 		"vo/scout_apexofjump01.mp3"
#define SOUND_MELEEONLY 		"vo/halloween_merasmus/sf14_merasmus_effect_noguns_01.mp3"
#define SOUND_CLASSONLY 		"misc/killstreak.wav"
#define SOUND_GRAVITY 		"vo/halloween_merasmus/sf12_wheel_gravity05.mp3"
#define SOUND_UNDERWATER 		"vo/halloween_merasmus/sf14_merasmus_effect_swimming_02.mp3"
#define SOUND_GHOST 		"vo/halloween_merasmus/sf12_wheel_ghosts01.mp3"
#define SOUND_GHOST "vo/halloween_merasmus/sf12_wheel_ghosts01.mp3"
#define SOUND_DWARF "vo/scout_sf12_badmagic28.mp3"
#define SOUND_MILK "weapons/jar_explode.wav"
#define SOUND_POGO "vo/scout_apexofjump02.mp3"
#define SOUND_SLOWSPEED "vo/scout_jeers04.mp3"
#define SOUND_LOWHEALTH "vo/heavy_negativevocalization06.mp3"
#define SOUND_BLEEDING "vo/halloween_merasmus/sf12_wheel_bloody03.mp3"
#define SOUND_FREEFORALL "ui/duel_score_behind.wav"
#define SOUND_KNOCKOUT "player/pl_impact_stun.wav"
#define SOUND_STRONGRECOIL "weapons/air_burster_explode3.wav"
#define SOUND_MINIGUN "vo/heavy_specialweapon02.mp3"
#define SOUND_INSTAGIB "weapons/shooting_star_shoot_charged.wav"
#define SOUND_KNOCKBACK "items/powerup_pickup_knockout_melee_hit.wav"
#define SOUND_FASTHANDS "items/powerup_pickup_knockout.wav"
#define SOUND_HSONLY		"weapons/sniper_rifle_classic_shoot_crit.wav"

// Other
#define SOUND_WHOOSH 	"playgamesound misc/halloween/strongman_fast_whoosh_01.wav"

// ConVars
ConVar g_hCvarTimerWaiting;

// Handles
Handle g_RRTimer = INVALID_HANDLE;
Handle g_HintTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_Cvar_Gravity = INVALID_HANDLE;
Handle g_Cvar_FriendlyFire = INVALID_HANDLE;
Handle g_BleedTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_KnockoutTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_MilkTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_CritTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle g_SlowspeedTimer[MAXPLAYERS+1] = INVALID_HANDLE;

// Booleans
bool CanRoulette = true;
bool HideChatCurrentCondition[MAXPLAYERS+1] = false;
bool g_FullCrit[MAXPLAYERS+1] = false;
bool g_SoundHasPlayed[MAXPLAYERS+1] = false;
bool g_bDoubleJump = false; //True = Ininite jumps enabled, False = Disabled
bool g_bHasStrongRecoil[MAXPLAYERS+1] = {false, ...};

// Floats
float g_flBoost = 250.0;

// Menus
Menu g_MapMenu = null;

// Integers
int sRoll;
int g_iHealth[MAXPLAYERS+1] = 0;
int jump[MAXPLAYERS + 1] = 0;
int g_fLastButtons[MAXPLAYERS+1];
int g_fLastFlags[MAXPLAYERS+1];
int g_iJumps[MAXPLAYERS+1];
int g_iJumpMax = 999;
int Gravity_Roll;
int OriginalHealth[MAXPLAYERS+1];

// Classtype
TFClassType g_Classonly_OldClass[MAXPLAYERS+1] = TFClass_Unknown;
TFClassType RandomClass = TFClass_Unknown;

// Chars
char g_CurrentCond[MAXPLAYERS+1] = "";
char NewGravityAmount[64];

// Enums
enum nRoll
{
	ROULETTE_CRITS=0,
	ROULETTE_MINICRITS, // 1
	ROULETTE_SPEEDBOOST, // 2
	ROULETTE_HEALTHBOOST, //3
	ROULETTE_SUPERJUMP, //4
	ROULETTE_INFJUMPS, //5
	ROULETTE_MELEEONLY, //6
	ROULETTE_CLASSONLY, //7
	ROULETTE_GRAVITY, //8
	ROULETTE_UNDERWATER, //9
	ROULETTE_GHOST, //10
	ROULETTE_DWARF, //11
	ROULETTE_MILK, //12
	ROULETTE_POGO, //13
	ROULETTE_SLOWSPEED, //14
	ROULETTE_LOWHEALTH, //15
	ROULETTE_BLEEDING, //16
	ROULETTE_FREEFORALL, //17
	ROULETTE_KNOCKOUT, //18
	ROULETTE_STRONGRECOIL, //19
	ROULETTE_MINIGUN, // 20
	ROULETTE_INSTAGIB, //21
	ROULETTE_KNOCKBACK, //22
	ROULETTE_FASTHANDS // 23
};

int nRollRows = view_as<int>(nRoll);

public Plugin myinfo = {
    name = "Round Roulette",
    author = "Kah!",
    description = "New special conditions every round.",
    version = "0.1"
};

public void OnPluginStart() {
	Steam_SetGameDescription("Round Roulette (0.1 Beta)");
	AddServerTag("rr");

	g_Cvar_Gravity = FindConVar("sv_gravity");
	g_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");

	g_hCvarTimerWaiting = CreateConVar("sm_rr_timerwaiting", "10.0", "Amounts of seconds before new condition is chosen every round.");

	RegAdminCmd("sm_rr_selectmode", Command_SelectMode, ADMFLAG_GENERIC, "Usage: sm_rr_selectmode <0-23>");
	RegAdminCmd("sm_rr_reroulette", Command_ReRoulette, ADMFLAG_GENERIC, "Usage: sm_rr_reroulette");	
}

public void OnMapStart() {
	Steam_SetGameDescription("Round Roulette");

	HookEvent("teamplay_round_active", Event_RoundStart);
	HookEvent("teamplay_round_start", Event_RoundSoonStart);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_win_panel", Event_RoundWin);
	HookEvent("teamplay_round_stalemate", Event_RoundWin);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_PostInventory);

	PrepareSound(SOUND_CRITS);
	PrepareSound(SOUND_MINICRITS);
	PrepareSound(SOUND_BELL);
	PrepareSound(SOUND_SPEEDBOOST);
	PrepareSound(SOUND_HEALTHBOOST);
	PrepareSound(SOUND_SUPERJUMP);
	PrepareSound(SOUND_INFJUMPS);
	PrepareSound(SOUND_MELEEONLY);
	PrepareSound(SOUND_CLASSONLY);
	PrepareSound(SOUND_GRAVITY);
	PrepareSound(SOUND_GHOST);
	PrepareSound(SOUND_UNDERWATER);
	PrepareSound(SOUND_GHOST);
	PrepareSound(SOUND_DWARF);
	PrepareSound(SOUND_MILK);
	PrepareSound(SOUND_POGO);
	PrepareSound(SOUND_SLOWSPEED);
	PrepareSound(SOUND_LOWHEALTH);
	PrepareSound(SOUND_BLEEDING);
	PrepareSound(SOUND_FREEFORALL);
	PrepareSound(SOUND_KNOCKOUT);
	PrepareSound(SOUND_STRONGRECOIL);
	PrepareSound(SOUND_MINIGUN);
	PrepareSound(SOUND_INSTAGIB);
	PrepareSound(SOUND_KNOCKBACK);
	PrepareSound(SOUND_FASTHANDS);
	PrepareSound(SOUND_HSONLY);

	CanRoulette = true;
	for(int client = 1; client <= MaxClients; client++) {
		TerminateRoundRoulette(client);
	}

	g_MapMenu = BuildMapMenu();
}

public void OnMapEnd()
{
	if (g_MapMenu != INVALID_HANDLE)
	{
		delete(g_MapMenu);
		g_MapMenu = null;
	}

	SetConVarInt(g_Cvar_Gravity, 800);
	KillTimerSafe(g_RRTimer);
}

Menu BuildMapMenu()
{
	Menu menu = new Menu(Menu_ChangeMap);

	menu.AddItem("0", "0: Crits");
	menu.AddItem("1", "1: Mini-Crits");
	menu.AddItem("2", "2: Speed Boost");
	menu.AddItem("3", "3: Health Boost");
	menu.AddItem("4", "4: Super Jump");
	menu.AddItem("5", "5: Infinite Jumps");
	menu.AddItem("6", "6: Melee Only");
	menu.AddItem("7", "7: One class only (randomed)");
	menu.AddItem("8", "8: Low gravity");
	menu.AddItem("9", "9: Underwater");
	menu.AddItem("10", "10: Ghost");
	menu.AddItem("11", "11: Dwarf");
	menu.AddItem("12", "12: Milk");
	menu.AddItem("13", "13: Pogo Jump");
	menu.AddItem("14", "14: Slow Speed");
	menu.AddItem("15", "15: Low Health");
	menu.AddItem("16", "16: Bleeding");
	menu.AddItem("17", "17: Friendly Fire");
	menu.AddItem("18", "18: Knockout");
	menu.AddItem("19", "19: Strong Recoil");
	menu.AddItem("20", "20: Heavy & Minigun only");
	menu.AddItem("21", "21: Instagib");
	menu.AddItem("22", "22: Knockback");
	menu.AddItem("23", "23: Fast Hands");
	menu.AddItem("24", "24: Headshots only");

	menu.SetTitle("List of condition IDs:");

	return menu;
}

public int Menu_ChangeMap(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		for(int iClient = 1; iClient <= MaxClients; iClient++) {
			if(IsValidClient(iClient)) {
				TerminateRoundRoulette(iClient);
			}
		}

		sRoll = param2;
		for(int client = 1; client <= MaxClients; client++) {
			if(IsValidClient(client)) {
				RoundRoulette(client);

				PrintToChat(client, "\x04[RR]\x01 Admin has changed mode to \x04%s\x01!", g_CurrentCond);
				ChatCurrentConditionInfo(client);
			}
		}
	}
}

public void OnGameFrame() {
    if (g_bDoubleJump) {                            // double jump active
        for (int i = 1; i <= MaxClients; i++) {     // cycle through players
            if (
                IsClientInGame(i) &&                // is in the game
                IsPlayerAlive(i)                    // is alive
            ) {
                DoubleJump(i);                      // Check for double jumping
            }
        }
    }
}

public void OnClientDisconnect(int client) {
	KillTimerSafe(g_HintTimer[client]);
	TerminateRoundRoulette(client);
	HideChatCurrentCondition[client] = false;
	g_FullCrit[client] = false;
	g_SoundHasPlayed[client] = false;
	g_Classonly_OldClass[client] = TFClass_Unknown;
	KillTimerSafe(g_BleedTimer[client]);
	KillTimerSafe(g_KnockoutTimer[client]);
	KillTimerSafe(g_MilkTimer[client]);
	g_bHasStrongRecoil[client] = false;
	KillTimerSafe(g_CritTimer[client]);
	KillTimerSafe(g_SlowspeedTimer[client]);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void StrongRecoil_Perk(int client, bool apply){

	g_bHasStrongRecoil[client] = apply;

}

public Action Event_PostInventory(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	switch(sRoll) {
		case ROULETTE_MELEEONLY:
		{
			if(IsValidClient(client)) {
				TF2_RemoveWeaponSlot(client, 0);
				TF2_RemoveWeaponSlot(client, 1);

				int iWeapon = GetPlayerWeaponSlot(client, 2);
				if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);

				TF2_RemoveWeaponSlot(client, 3);
				TF2_RemoveWeaponSlot(client, 4);
			}
		}
		case ROULETTE_MINIGUN:
		{
			if(IsValidClient(client)) {
				TF2_RemoveWeaponSlot(client, 2);
				TF2_RemoveWeaponSlot(client, 1);

				int iWeapon = GetPlayerWeaponSlot(client, 0);
				if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);

				TF2Attrib_SetByName(client, "minigun spinup time decreased", 0.0);
			}
		}
		case ROULETTE_INSTAGIB:
		{
			if(IsValidClient(client)) {
				TF2_RemoveWeaponSlot(client, 1);
				TF2_RemoveWeaponSlot(client, 2);

				TF2_RemoveWeaponSlot(client, 0);
				SpawnWeapon(client, "tf_weapon_sniperrifle", 526, 1, 0, "76 ; 5.0 ; 96 ; 1.6 ; 47 ; 1 ; 389 ; 1 ; 305 ; 1 ; 309 ; 1");
			}
		}
		case ROULETTE_FASTHANDS:
		{
			TF2Attrib_SetByName(client, "reload time decreased", 0.1);
			TF2Attrib_SetByName(client, "fire rate bonus", 0.5);
			TF2Attrib_SetByName(client, "clip size bonus", 5.0);
			TF2Attrib_SetByName(client, "maxammo primary increased", 5.0);
			TF2Attrib_SetByName(client, "maxammo secondary increased", 5.0);
		}
	}

	return Plugin_Continue;
}

public Action OnGetMaxHealth(int entity, int &maxhealth)
{
	switch(sRoll) {
		case ROULETTE_LOWHEALTH:
		{
			int client = entity;
			if(!IsValidClient(client)) return Plugin_Continue;
			if(!g_iHealth[client]) return Plugin_Continue;
			maxhealth = g_iHealth[client];
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool isAlive=false)
{
    if(!client||client>MaxClients)    return false;
    if(isAlive) return IsClientInGame(client) && IsPlayerAlive(client);
    return IsClientInGame(client);
}

public void KillTimerSafe(Handle &hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

stock int PrepareSound(const char[] szSoundPath)
{
    PrecacheSound(szSoundPath, true);
    char s[PLATFORM_MAX_PATH];
    Format(s, sizeof(s), "sound/%s", szSoundPath);
    AddFileToDownloadsTable(s);
}

public Action Command_SelectMode(int client, int args) {
	if(args > 0) {

		if(CanRoulette == false) {
			char target[32];
			GetCmdArg(1, target, sizeof(target));

			int iRoll = StringToInt(target);

			for(int iClient = 1; iClient <= MaxClients; iClient++) {
				if(IsValidClient(iClient)) {
					TerminateRoundRoulette(iClient); // terminate current one first
				}
			}

			sRoll = iRoll; // new roll

			ReplyToCommand(client, "\x04[RR]\x01 Mode changed successfully.");

			for(int index = 1; index <= MaxClients; index++) {
				if(IsValidClient(index)) {
					RoundRoulette(index); // force the new condition

					PrintToChat(index, "\x04[RR]\x01 Admin has changed mode to \x04%s\x01!", g_CurrentCond);
					ChatCurrentConditionInfo(index);
				}
			}

			return Plugin_Continue;
		} else {
			ReplyToCommand(client, "\x04[RR]\x01 Round must be active before you can change mode.");
			return Plugin_Continue;
		}

	} else {
		ReplyToCommand(client, "\x04[RR]\x01 Usage: sm_rr_selectmode <0-23>");

		g_MapMenu.Display(client, 20);

		return Plugin_Continue;
	}
}

public Action Command_ReRoulette(int client, int args) {
	if(args < 1) {

		if(CanRoulette == false) {

			for(int iClient = 1; iClient <= MaxClients; iClient++) {
				if(IsValidClient(iClient)) {
					TerminateRoundRoulette(iClient); // terminate current one first
				}
			}

			sRoll = GetRandomInt(0, nRollRows);

			for(int index = 1; index <= MaxClients; index++) {
				if(IsValidClient(index)) {
					RoundRoulette(index); // force the new condition
				}
			}

			ReplyToCommand(client, "\x04[RR]\x01 Mode changed successfully.");
			PrintToChatAll("\x04[RR]\x01 Admin has re-roulette the mode to \x04%s\x01!", g_CurrentCond);

			return Plugin_Continue;
		} else {
			ReplyToCommand(client, "\x04[RR]\x01 Round must be active before you can change mode.");
			return Plugin_Continue;
		}

	} else {
		ReplyToCommand(client, "\x04[RR]\x01 Usage: sm_rr_reroulette");
		return Plugin_Continue;
	}
}

public int PanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		//
	} else if (action == MenuAction_Cancel) {
		//
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(CanRoulette == true) {
		float TimerWaiting = GetConVarFloat(g_hCvarTimerWaiting);

		CanRoulette = false;

		PrintToChatAll("\x04[RR]\x01 New condition in: \x04%i\x01 seconds.", RoundFloat(TimerWaiting));
		g_RRTimer = CreateTimer(TimerWaiting, LetsRoulette);
	}
}

public Action LetsRoulette(Handle timer) {
	if(CanRoulette == false) {
		// Terminates current condition, if there is one, before it actually rolls a new and picks that
		for(int index = 1; index <= MaxClients; index++) {
			if(IsValidClient(index)) {
				TerminateRoundRoulette(index);
			}
		}

		sRoll = GetRandomInt(0, nRollRows);

		for(int client = 1; client <= MaxClients; client++) {
			if(IsValidClient(client)) {
				RoundRoulette(client);
			}
		}

		CanRoulette = false;
	}
}

public Action Timer_Hint(Handle timer, any client){
	if(IsValidClient(client)) {

		if(!StrEqual(g_CurrentCond, "", true)) { // fixes hint box appearing when mode isnt picked yet
			PrintHintText(client, "[RR] Current round condition: %s", g_CurrentCond);
		}
	}

	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	switch(sRoll) {
		case ROULETTE_CRITS, ROULETTE_INSTAGIB:
		{
			if(g_FullCrit[client] == true)
			{
				result = true;
				return Plugin_Handled;
			}
		}
		case ROULETTE_STRONGRECOIL:
		{
			StrongRecoil_CritCheck(client, weapon);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

stock int OnJump(any client){
    switch(sRoll)
	{
        case ROULETTE_SUPERJUMP:
		{
            if(GetEntProp(client, Prop_Send, "m_bJumping") == 1){
                float vect[3];
                GetEntPropVector(client, Prop_Data, "m_vecVelocity", vect);
                vect[2] = 750 + 25 * 13.0;
                vect[0] *= (1 + Sine(float(25) * FLOAT_PI / 50));
                vect[1] *= (1 + Sine(float(25) * FLOAT_PI / 50));
                TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vect);
                ClientCommand(client, SOUND_WHOOSH);
            }
        }
    }
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
    switch(sRoll)
	{
        case ROULETTE_SUPERJUMP:
		{
            if(!(GetEntityFlags(client) & FL_ONGROUND)){
                if(jump[client] == 0){
                    jump[client] = 1;
                    OnJump(client);
                }
            } else {
                if(jump[client] != 0){
                    jump[client] = 0;
                }
            }
        }
		case ROULETTE_POGO:
		{
            if(!(GetEntityFlags(client) & FL_ONGROUND)){
                if(jump[client] == 0){
                    jump[client] = 1;
                    OnJump(client);
                }
            }else{
                if(jump[client] != 0){
                    jump[client] = 0;
                }
            }
        }
	}

    return Plugin_Continue;
}

stock int SetSpeed(int client, float speed){
    if(TF2_IsPlayerInCondition(client, TFCond_Charging) || TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly)){
        return;
    }
    SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", speed);
}

stock float GetDefSpeed(int client){
    TFClassType class = TF2_GetPlayerClass(client);
    switch(class){
        case TFClass_Scout:{ return 400.0; }
        case TFClass_Soldier:{ return 240.0; }
        case TFClass_Pyro:{ return 300.0; }
        case TFClass_DemoMan:{ return 280.0; }
        case TFClass_Heavy:{ return 230.0; }
        case TFClass_Engineer:{ return 300.0; }
        case TFClass_Medic:{ return 320.0; }
        case TFClass_Sniper:{ return 300.0; }
        case TFClass_Spy:{ return 300.0; }
    }
    return 300.0;//Average
}

public Action Timer_Bleeding(Handle timer, any client) {
	int curhealth = (GetClientHealth(client) - 1);
	SetEntityHealth(client, curhealth);

	if(curhealth <= 0){
		SDKHooks_TakeDamage(client, 0, 0, 1.0, DMG_GENERIC); //To actually kill
	}

	return Plugin_Continue;
}

public Action Timer_Knockout(Handle timer, any client) {
	TF2_StunPlayer(client, 3.5, 0.0, TF_STUNFLAG_BONKSTUCK, 0);
}

public Action Timer_Milk(Handle timer, any client) {
	TF2_AddCondition(client, TFCond_Milked, TFCondDuration_Infinite, 0);
}

public Action Timer_Crits(Handle timer, any client) {
	TF2_AddCondition(client, TFCond_Buffed, TFCondDuration_Infinite, 0);
}

public Action Timer_Slowspeed(Handle timer, any client) {
	SetSpeed(client, FloatMul(GetDefSpeed(client), 0.8)); //20% slower speed
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
    Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES|FORCE_GENERATION);
    if (hWeapon == INVALID_HANDLE)
        return -1;
    TF2Items_SetClassname(hWeapon, name);
    TF2Items_SetItemIndex(hWeapon, index);
    TF2Items_SetLevel(hWeapon, level);
    TF2Items_SetQuality(hWeapon, qual);
    char atts[32][32];
    int count = ExplodeString(att, " ; ", atts, 32, 32);
    if (count > 1)
    {
        TF2Items_SetNumAttributes(hWeapon, count/2);
        int i2 = 0;
        for (int i = 0; i < count; i += 2)
        {
            TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
            i2++;
        }
    }  else {
        TF2Items_SetNumAttributes(hWeapon, 0);
	}
    int entity = TF2Items_GiveNamedItem(client, hWeapon);
    CloseHandle(hWeapon);
    EquipPlayerWeapon(client, entity);
    return entity;
}

public int RoundRoulette(int targets) {
	switch(sRoll) {
		case ROULETTE_CRITS:
		{
			g_CurrentCond = "Crits";

			g_FullCrit[targets] = true;
			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_CRITS, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_MINICRITS:
		{
			g_CurrentCond = "Mini-Crits";

			if(g_CritTimer[targets] == INVALID_HANDLE) {
				g_CritTimer[targets] = CreateTimer(1.0, Timer_Crits, targets, TIMER_REPEAT);
			}

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_MINICRITS, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_SPEEDBOOST:
		{
			g_CurrentCond = "Speed boost";

			TF2_AddCondition(targets, TFCond_SpeedBuffAlly, TFCondDuration_Infinite, 0);
			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_SPEEDBOOST, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_HEALTHBOOST:
		{
			g_CurrentCond = "Health boost";

			int iHealth = GetClientHealth(targets);
			g_iHealth[targets] = iHealth + 500;

			if(TF2_GetPlayerClass(targets) == TFClass_Scout) {
				if(iHealth < 126) {
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			} else if(TF2_GetPlayerClass(targets) == TFClass_Soldier) {
				if(iHealth < 201) {
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			} else if(TF2_GetPlayerClass(targets) == TFClass_Pyro) {
				if(iHealth < 176) {
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			} else if(TF2_GetPlayerClass(targets) == TFClass_DemoMan) {
				if(iHealth < 176) {
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			} else if(TF2_GetPlayerClass(targets) == TFClass_Heavy) {
				if(iHealth < 326) { // the choco bar gives more max hp
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			} else if(TF2_GetPlayerClass(targets) == TFClass_Engineer) {
				if(iHealth < 151) { // gunslinger? gives more max hp
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			} else if(TF2_GetPlayerClass(targets) == TFClass_Sniper) {
				if(iHealth < 126) {
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			} else if(TF2_GetPlayerClass(targets) == TFClass_Spy) {
				if(iHealth < 126) {
					SetEntityHealth(targets, g_iHealth[targets]);
				}
			}

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_HEALTHBOOST, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_SUPERJUMP:
		{
			g_CurrentCond = "Super jump";
			TF2Attrib_SetByName(targets, "cancel falling damage", 1.0);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_SUPERJUMP, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
			// further effects take change in onplayerruncmd
		}
		case ROULETTE_INFJUMPS:
		{
			g_CurrentCond = "Infinite jumps";
			g_bDoubleJump = true;

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_INFJUMPS, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_MELEEONLY:
		{
			g_CurrentCond = "Melee only";

			TF2_RemoveWeaponSlot(targets, 0);
			TF2_RemoveWeaponSlot(targets, 1);

			int iWeapon = GetPlayerWeaponSlot(targets, 2);
			if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(targets, Prop_Send, "m_hActiveWeapon", iWeapon);

			TF2_RemoveWeaponSlot(targets, 3);
			TF2_RemoveWeaponSlot(targets, 4);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_MELEEONLY, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_CLASSONLY:
		{
			g_CurrentCond = "One class only";

			if(TF2_GetPlayerClass(targets) != TFClass_Unknown) {
				g_Classonly_OldClass[targets] = TF2_GetPlayerClass(targets); // used to switch them back to the old class after
			} else {
				g_Classonly_OldClass[targets] = TFClass_Scout; // sets it to scout in case they're not a class yet
			}

			if(RandomClass == TFClass_Unknown) {
				RandomClass = view_as<TFClassType>(GetRandomInt(1, 9));
			}

			if(TF2_GetPlayerClass(targets) != RandomClass && RandomClass != TFClass_Unknown) {
				TF2_SetPlayerClass(targets, RandomClass, true);
			}

			TF2_RegeneratePlayer(targets);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_CLASSONLY, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_GRAVITY:
		{
			Gravity_Roll = GetRandomInt(1, 2);

			if(Gravity_Roll == 1) {
				NewGravityAmount = "400"; // 50% higher

				g_CurrentCond = "Low Gravity (50%)";
			} else if(Gravity_Roll == 2) {
				NewGravityAmount = "600"; // 25% higher

				g_CurrentCond = "Low Gravity (25%)";
			}

			SetConVarInt(g_Cvar_Gravity, StringToInt(NewGravityAmount));

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_GRAVITY, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_UNDERWATER:
		{
			g_CurrentCond = "Underwater";

			TF2_AddCondition(targets, TFCond_SwimmingCurse, TFCondDuration_Infinite, 0);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_UNDERWATER, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_GHOST:
		{
			g_CurrentCond = "Ghost";

			Invisible(targets, 0.4); //Barely visible

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_GHOST, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_DWARF:
		{
			g_CurrentCond = "Dwarf";

			SizePlayer(targets, 0.5); //Half size

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_DWARF, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_MILK:
		{
			g_CurrentCond = "Milk";

			if(g_MilkTimer[targets] == INVALID_HANDLE) {
				g_MilkTimer[targets] = CreateTimer(1.0, Timer_Milk, targets, TIMER_REPEAT);
			}

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_MILK, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_POGO:
		{
			g_CurrentCond = "Pogo Jump";

			TF2Attrib_SetByName(targets, "cancel falling damage", 1.0);
			TF2Attrib_SetByName(targets, "increased jump height", 3.0);
			SetEntityGravity(targets, 1.7);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_POGO, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_SLOWSPEED:
		{
			g_CurrentCond = "Slower speed";

			if(g_SlowspeedTimer[targets] == INVALID_HANDLE) {
				g_SlowspeedTimer[targets] = CreateTimer(1.0, Timer_Slowspeed, targets, TIMER_REPEAT);
			}

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_SLOWSPEED, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_LOWHEALTH:
		{
			g_CurrentCond = "Low Health";

			OriginalHealth[targets] = GetClientHealth(targets);
			g_iHealth[targets] = 1;
			SetEntityHealth(targets, g_iHealth[targets]);

			// Sets sentry health to 1
			int sentry=-1;
			while((sentry=FindEntityByClassname(sentry, "CObjectSentrygun"))!=-1)
			{
				SetVariantInt(1);
				AcceptEntityInput(sentry, "AddHealth");
			}

			if(TF2_GetPlayerClass(targets) == TFClass_Medic) {
				TF2Attrib_SetByName(targets, "overheal penalty", 0.0);
			}

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_LOWHEALTH, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_BLEEDING:
		{
			g_CurrentCond = "Bleeding";

			if(g_BleedTimer[targets] == INVALID_HANDLE) {
				g_BleedTimer[targets] = CreateTimer(1.0, Timer_Bleeding, targets, TIMER_REPEAT);
			}

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_BLEEDING, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_FREEFORALL:
		{
			g_CurrentCond = "Free for all";

			SetConVarBool(g_Cvar_FriendlyFire, true);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_FREEFORALL, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_KNOCKOUT:
		{
			g_CurrentCond = "Knockout";

			if(g_KnockoutTimer[targets] == INVALID_HANDLE) {
				g_KnockoutTimer[targets] = CreateTimer(35.0, Timer_Knockout, targets, TIMER_REPEAT);
			}

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_KNOCKOUT, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_STRONGRECOIL:
		{
			g_CurrentCond = "Strong Recoil";

			StrongRecoil_Perk(targets, true);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_STRONGRECOIL, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_MINIGUN:
		{
			g_CurrentCond = "Heavy & Minigun only";

			TF2_SetPlayerClass(targets, TFClass_Heavy);
			TF2_RegeneratePlayer(targets);

			TF2_RemoveWeaponSlot(targets, 2);
			TF2_RemoveWeaponSlot(targets, 1);

			int iWeapon = GetPlayerWeaponSlot(targets, 0);
			if(iWeapon > MaxClients && IsValidEntity(iWeapon))
				SetEntPropEnt(targets, Prop_Send, "m_hActiveWeapon", iWeapon);

			TF2Attrib_SetByName(targets, "minigun spinup time decreased", 0.0);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_MINIGUN, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_INSTAGIB:
		{
			g_CurrentCond = "Instagib";

			g_FullCrit[targets] = true;

			TF2_SetPlayerClass(targets, TFClass_Sniper);
			TF2_RegeneratePlayer(targets);

			TF2_RemoveWeaponSlot(targets, 1);
			TF2_RemoveWeaponSlot(targets, 2);

			TF2_RemoveWeaponSlot(targets, 0);
			SpawnWeapon(targets, "tf_weapon_sniperrifle", 526, 1, 0, "76 ; 5.0 ; 96 ; 1.6 ; 47 ; 1 ; 389 ; 1 ; 305 ; 1 ; 309 ; 1");


			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_INSTAGIB, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_KNOCKBACK:
		{
			g_CurrentCond = "Knockback";

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_KNOCKBACK, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		case ROULETTE_FASTHANDS:
		{
			g_CurrentCond = "Fast hands";

			TF2Attrib_SetByName(targets, "reload time decreased", 0.1);
			TF2Attrib_SetByName(targets, "fire rate bonus", 0.5);
			TF2Attrib_SetByName(targets, "clip size bonus", 5.0);
			TF2Attrib_SetByName(targets, "maxammo primary increased", 5.0);
			TF2Attrib_SetByName(targets, "maxammo secondary increased", 5.0);

			TF2_SetPlayerClass(targets, TFClass_Scout);

			TF2_RegeneratePlayer(targets);

			if(g_SoundHasPlayed[targets] == false) {
				EmitSoundToClient(targets, SOUND_FASTHANDS, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, false, 0.0);
				g_SoundHasPlayed[targets] = true;
			}
		}
		default:
		{
			g_CurrentCond = "Normal";

			// Remove all, because you never know actually.
			g_FullCrit[targets] = false;
			g_SoundHasPlayed[targets] = false;

			TF2_RemoveCondition(targets, TFCond_Buffed);
			TF2_RemoveCondition(targets, TFCond_SpeedBuffAlly);
		}
	}

	if(HideChatCurrentCondition[targets] == false && CanRoulette == false) {
		PrintToChat(targets, "\x04[RR]\x01 Special condition this round is: \x04%s\x01!", g_CurrentCond);

		ChatCurrentConditionInfo(targets);

		HideChatCurrentCondition[targets] = true;
	}

	KillTimerSafe(g_HintTimer[targets]);
	g_HintTimer[targets] = CreateTimer(3.0, Timer_Hint, targets, TIMER_REPEAT);
}

public int ChatCurrentConditionInfo(int targets) {
	if(StrEqual(g_CurrentCond, "Normal", false)) {
		PrintToChat(targets, "\x04[RR]\x01 No condition this round. Just a normal game.");
	} else if(StrEqual(g_CurrentCond, "Crits", false)) {
		PrintToChat(targets, "\x04[RR]\x01 All hits will now deal critical damage.");
	} else if(StrEqual(g_CurrentCond, "Mini-Crits", false)) {
		PrintToChat(targets, "\x04[RR]\x01 All hits will now be mini-crits.");
	} else if(StrEqual(g_CurrentCond, "Speed boost", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You have gained additional speed boost!");
	} else if(StrEqual(g_CurrentCond, "Health boost", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You have gained additional 500 HP.");
	} else if(StrEqual(g_CurrentCond, "Super jump", false)) {
		PrintToChat(targets, "\x04[RR]\x01 Your jumps are super high.");
	} else if(StrEqual(g_CurrentCond, "Infinite jumps", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You now have infinite amounts of jumps.");
	} else if(StrEqual(g_CurrentCond, "Melee only", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You can not use anything else than melee this round.");
	} else if(StrEqual(g_CurrentCond, "One class only", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You can only play as this class this round.");
	} else if(StrEqual(g_CurrentCond, "Low gravity", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You have lower gravity than usual.");
	} else if(StrEqual(g_CurrentCond, "Underwater", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You are now swimming in jarate.");
	} else if(StrEqual(g_CurrentCond, "Ghost", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You are less visible.");
	} else if(StrEqual(g_CurrentCond, "Dwarf", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You are now smaller than usual.");
	} else if(StrEqual(g_CurrentCond, "Milk", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You are cowered in mad milk and enemies will heal themselves when hitting you.");
	} else if(StrEqual(g_CurrentCond, "Pogo jump", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You can jump higher, but will fall in normal speed.");
	} else if(StrEqual(g_CurrentCond, "Slower speed", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You are much slower than usual.");
	} else if(StrEqual(g_CurrentCond, "Low health", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You have 1 HP.");
	} else if(StrEqual(g_CurrentCond, "Bleeding", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You take periodic 1 damage every second.");
	} else if(StrEqual(g_CurrentCond, "Free for all", false)) {
		PrintToChat(targets, "\x04[RR]\x01 Friendly fire is enabled, you can now damage your teammates.");
	} else if(StrEqual(g_CurrentCond, "Knockout", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You will be stunned for 3.5 seconds every 35 seconds from now on.");
	} else if(StrEqual(g_CurrentCond, "Strong recoil", false)) {
		PrintToChat(targets, "\x04[RR]\x01 It is now much harder for you to aim.");
	} else if(StrEqual(g_CurrentCond, "Heavy & minigun only", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You can only play as heavy with a modified minigun.");
	} else if(StrEqual(g_CurrentCond, "Instagib", false)) {
		PrintToChat(targets, "\x04[RR]\x01 All hits are critical and instantly kills enemies.");
	} else if(StrEqual(g_CurrentCond, "Knockback", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You take a lot of knockback when enemies hit you.");
	} else if(StrEqual(g_CurrentCond, "Fast hands", false)) {
		PrintToChat(targets, "\x04[RR]\x01 You have more maxammo and faster attack/reload speeds.");
	} else if(StrEqual(g_CurrentCond, "Headshots Only", false)) {
		PrintToChat(targets, "\x04[RR]\x01 To deal damage, your hit must be a headshot. Everything else deals 0 damage.");
	}
}

public int TerminateRoundRoulette(int targets) {
	g_SoundHasPlayed[targets] = false;
	switch(sRoll) {
		case ROULETTE_CRITS:
		{
			g_FullCrit[targets] = false;
		}
		case ROULETTE_MINICRITS:
		{
			KillTimerSafe(g_CritTimer[targets]);
			TF2_RemoveCondition(targets, TFCond_Buffed);
		}
		case ROULETTE_SPEEDBOOST:
		{
			TF2_RemoveCondition(targets, TFCond_SpeedBuffAlly);
		}
		case ROULETTE_HEALTHBOOST:
		{
			// this doesn't need anything, resets itself on death
		}
		case ROULETTE_SUPERJUMP:
		{
			TF2Attrib_RemoveByName(targets, "cancel falling damage");
		}
		case ROULETTE_INFJUMPS:
		{
			g_bDoubleJump = false;
		}
		case ROULETTE_MELEEONLY:
		{
			ForcePlayerSuicide(targets);
			TF2_RegeneratePlayer(targets);
		}
		case ROULETTE_CLASSONLY:
		{
			TF2_SetPlayerClass(targets, g_Classonly_OldClass[targets]);
			TF2_RegeneratePlayer(targets);

			g_Classonly_OldClass[targets] = TFClass_Unknown;
			RandomClass = TFClass_Unknown;
		}
		case ROULETTE_GRAVITY:
		{
			char OldGravityAmount[64] = "800";
			NewGravityAmount = "800";
			Gravity_Roll = 0;

			SetConVarInt(g_Cvar_Gravity, StringToInt(OldGravityAmount));
		}
		case ROULETTE_UNDERWATER:
		{
			TF2_RemoveCondition(targets, TFCond_SwimmingCurse);
		}
		case ROULETTE_GHOST:
		{
			Invisible(targets, 1.0); //Fully visible
		}
		case ROULETTE_DWARF:
		{
			SizePlayer(targets, 1.0); //Full size
			TF2_RespawnPlayer(targets);
		}
		case ROULETTE_MILK:
		{
			KillTimerSafe(g_MilkTimer[targets]);
			TF2_RemoveCondition(targets, TFCond_Milked);
		}
		case ROULETTE_POGO:
		{
			TF2Attrib_RemoveByName(targets, "cancel falling damage");
			TF2Attrib_RemoveByName(targets, "increased jump height");
			SetEntityGravity(targets, 1.0);
		}
		case ROULETTE_SLOWSPEED:
		{
			KillTimerSafe(g_SlowspeedTimer[targets]);
			SetSpeed(targets, FloatMul(GetDefSpeed(targets), 1.0)); //Normal speed
		}
		case ROULETTE_LOWHEALTH:
		{
			SetEntityHealth(targets, OriginalHealth[targets]);
			TF2Attrib_RemoveByName(targets, "overheal penalty");
		}
		case ROULETTE_BLEEDING:
		{
			KillTimerSafe(g_BleedTimer[targets]);
		}
		case ROULETTE_FREEFORALL:
		{
			SetConVarBool(g_Cvar_FriendlyFire, false);
		}
		case ROULETTE_KNOCKOUT:
		{
			KillTimerSafe(g_KnockoutTimer[targets]);
		}
		case ROULETTE_STRONGRECOIL:
		{
			StrongRecoil_Perk(targets, false);
		}
		case ROULETTE_MINIGUN:
		{
			TF2Attrib_RemoveByName(targets, "minigun spinup time decreased");

			ForcePlayerSuicide(targets);
			TF2_RegeneratePlayer(targets);
		}
		case ROULETTE_INSTAGIB:
		{
			g_FullCrit[targets] = false;
			ForcePlayerSuicide(targets);
			TF2_RegeneratePlayer(targets);
		}
		case ROULETTE_KNOCKBACK:
		{
			// nothing really.
		}
		case ROULETTE_FASTHANDS:
		{
			TF2Attrib_RemoveByName(targets, "reload time decreased");
			TF2Attrib_RemoveByName(targets, "fire rate bonus");
			TF2Attrib_RemoveByName(targets, "clip size bonus");
			TF2Attrib_RemoveByName(targets, "maxammo primary increased");
			TF2Attrib_RemoveByName(targets, "maxammo secondary increased");

			TF2_SetPlayerClass(targets, TFClass_Scout);
			ForcePlayerSuicide(targets);

			TF2_RegeneratePlayer(targets);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	switch(sRoll) {
		case ROULETTE_INSTAGIB:
		{
			if(damagetype & DMG_FALL)
			{
				damage=1.0;
				return Plugin_Changed;
			} else {
				damage = 999.0;
				return Plugin_Changed;
			}
		}
		case ROULETTE_KNOCKBACK:
		{
			char path[75];
			Format(path, sizeof(path), "weapons/airstrike_small_explosion_0%d.wav", GetRandomInt(1,3));  //Explosion sound

			EmitSoundToAll(path, victim, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			PlayEffect(victim, "mvm_loot_flyember", 0.0, 0.0, 0.0, "flag");                                                  //Small explosion particle
			SetEntProp(victim, Prop_Send, "m_bJumping", 1);
			float angles[3];
			float velocity[3];
			GetClientEyeAngles(attacker, angles);
			GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(velocity, 2000.0);
			velocity[0] += GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
			velocity[1] += GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
			velocity[2] += GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
		}
	}

	return Plugin_Continue;
}

int PlayEffect(int ent, char[] particleType, float x=0.0, float y=0.0, float z=0.0, const char[] place=""){
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle)){
		float pos[3];
		if(x == 0.0){
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		}else{
			pos[0] = x;pos[1] = y;pos[2] = z;
		}
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		if(!StrEqual(place, "")){
			char tName[MAX_NAME_LENGTH];
			Format(tName, sizeof(tName), "target%i", ent);
			DispatchKeyValue(ent, "targetname", tName);

			char pName[64];
			Format(pName, sizeof(pName), "tf2particle%d", ent);
			DispatchKeyValue(particle, "targetname", pName);
			DispatchKeyValue(particle, "parentname", tName);
			DispatchSpawn(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle, 0);
			SetVariantString(place);
			AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
		}
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(7.0, Timer_RemoveEffect, particle);
		return 0;
	}
	return -1;
}

public Action Timer_RemoveEffect(Handle timer, any ent){
	DeleteParticle(ent);
	return Plugin_Stop;
}

int DeleteParticle(any particle){
	if(IsValidEntity(particle)){
		AcceptEntityInput(particle, "Kill");
	}
}

stock int Invisible(int client, float percent, int color1=0, int color2=0, int color3=0)
{
	int iColor[4] = {255,255,255,0};
	if(percent >= 1 || percent < 0){
		iColor[3] = 255;
	}else{
		iColor[3] = RoundFloat(FloatMul(255.0, percent));
	}
	if(color1 != 0){
		iColor[0] = color1;
		iColor[1] = color2;
		iColor[2] = color3;
	}

	SetEntityColor(client, iColor);

	if(TF2_IsPlayerInCondition(client, TFCond_Disguised)) { return; }

	for(int i=0; i<3; i++){
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			SetEntityColor(iWeapon, iColor);
		}
	}

	char strClass[20];
	for(int i=MaxClients+1; i<GetMaxEntities(); i++)
	{
	if(IsValidEntity(i))
	{
		GetEdictClassname(i, strClass, sizeof(strClass));
		if((strncmp(strClass, "tf_wearable", 11) == 0 || strncmp(strClass, "tf_powerup", 10) == 0) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
		{
			SetEntityColor(i, iColor);
		}
	}
	}

	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		SetEntityColor(iWeapon, iColor);
	}
}

stock int SetEntityColor(int iEntity, int iColor[4])
{
	SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iEntity, iColor[0], iColor[1], iColor[2], iColor[3]);
}

stock int SizePlayer(int client, float scale){
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
	SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * scale);
	float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 };
	float vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	ScaleVector(vecTF2PlayerMin, scale);
	ScaleVector(vecTF2PlayerMax, scale);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecTF2PlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecTF2PlayerMax);
}

void StrongRecoil_CritCheck(int client, int iWeapon){

	if(!g_bHasStrongRecoil[client])
		return;

	if(GetPlayerWeaponSlot(client, 2) == iWeapon)
		return;

	float fShake[3];
	fShake[0] = GetRandomFloat(-20.0, -80.0);
	fShake[1] = GetRandomFloat(-25.0, 25.0);
	fShake[2] = GetRandomFloat(-25.0, 25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);

}

public bool TraceFilterNotSelf(int entity, int contentsMask, any client)
{
	if(entity == client)
	{
		return false;
	}

	return true;
}

stock bool IsEntityStuck(int iEntity)
{
	float flOrigin[3];
	float flMins[3];
	float flMaxs[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flOrigin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", flMins);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", flMaxs);

	TR_TraceHullFilter(flOrigin, flOrigin, flMins, flMaxs, MASK_SOLID, TraceFilterNotSelf, iEntity);
	return TR_DidHit();
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsValidClient(client)) {
		if(CanRoulette == false) { // its already chosen and round is active
			RoundRoulette(client);
			if(g_HintTimer[client] == INVALID_HANDLE) {
				KillTimerSafe(g_HintTimer[client]);
				g_HintTimer[client] = CreateTimer(3.0, Timer_Hint, client, TIMER_REPEAT);
			}
		}
	}
}

public Action Event_RoundSoonStart(Event event, const char[] name, bool dontBroadcast) {
	//CanRoulette = true;
}

public Action Event_RoundWin(Event event, const char[] name, bool dontBroadcast) {
	for(int client = 1; client <= MaxClients; client++) {
		if(client > 0 && IsValidClient(client)) {
			TerminateRoundRoulette(client);

			KillTimerSafe(g_HintTimer[client]);
			HideChatCurrentCondition[client] = false;
		}
	}

	CanRoulette = true;
	g_CurrentCond = "";
	KillTimerSafe(g_RRTimer);
}

stock int DoubleJump(const any client) {

	int	fCurFlags	= GetEntityFlags(client);		// current flags
	int	fCurButtons	= GetClientButtons(client);		// current buttons

	if (g_fLastFlags[client] & FL_ONGROUND) {		// was grounded last frame
		if (
			!(fCurFlags & FL_ONGROUND) &&			// becomes airbirne this frame
			!(g_fLastButtons[client] & IN_JUMP) &&	// was not jumping last frame
			fCurButtons & IN_JUMP					// started jumping this frame
		) {
			OriginalJump(client);					// process jump from the ground
		}
	} else if (										// was airborne last frame
		fCurFlags & FL_ONGROUND						// becomes grounded this frame
	) {
		Landed(client);							// process landing on the ground
	} else if (										// remains airborne this frame
		!(g_fLastButtons[client] & IN_JUMP) &&		// was not jumping last frame
		fCurButtons & IN_JUMP						// started jumping this frame
	) {
		ReJump(client);								// process attempt to double-jump
	}

	g_fLastFlags[client]	= fCurFlags;				// update flag state for next frame
	g_fLastButtons[client]	= fCurButtons;			// update button state for next frame
}

stock int OriginalJump(const any client) {
	g_iJumps[client]++;	// increment jump count
}

stock int Landed(const any client) {
	g_iJumps[client] = 0;	// reset jumps count
}

stock int ReJump(const any client) {
	if ( 1 <= g_iJumps[client] <= g_iJumpMax) {						// has jumped at least once but hasn't exceeded max re-jumps
		g_iJumps[client]++;											// increment jump count
		float vVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);	// get current speeds

		vVel[2] = g_flBoost;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);		// boost player
	}
}
