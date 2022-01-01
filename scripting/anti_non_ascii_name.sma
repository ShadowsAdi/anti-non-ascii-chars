/* Sublime AMXX Editor v4.2 */

/* Uncomment this if you want use reAPI support. */
//#define USE_REAPI

#include <amxmodx>
#if !defined USE_REAPI
#include <fakemeta>

#define BLOCK_FUNC		FMRES_HANDLED
#define CONTINUE_FUNC	FMRES_IGNORED
#else
#include <reapi>

#define BLOCK_FUNC		HC_SUPERCEDE
#define CONTINUE_FUNC	HC_CONTINUE
#endif

#if !defined MAX_NAME_LENGTH
#define MAX_NAME_LENGTH 32
#endif

#define PLUGIN  "Anti NON-ASCII Characters in Name"
#define VERSION "1.3"
#define AUTHOR  "Shadows Adi"

new Array:g_aNewNames

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_cvar("standard_ascii", AUTHOR, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)

	#if !defined USE_REAPI
	register_forward(FM_ClientUserInfoChanged, "FM_ClientUserInfoChanged_Pre")
	#else 
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "RG_SetClientUserInfoName_Pre")
	#endif

	g_aNewNames = ArrayCreate(MAX_NAME_LENGTH)
}

public plugin_cfg()
{
	new szConfigsDir[256], szFileName[256]
	get_localinfo("amxx_configsdir", szConfigsDir, charsmax(szConfigsDir))
	formatex(szFileName, charsmax(szFileName), "%s/NewNames.ini", szConfigsDir)

	new iFile = fopen(szFileName, "rt")

	if(iFile)
	{
		new szData[48]

		while(fgets(iFile, szData, charsmax(szData)))
		{
			trim(szData)

			if(szData[0] == '#' || szData[0] == EOS || szData[0] == ';')
				continue

			replace_all(szData, charsmax(szData), "^"", "")

			ArrayPushString(g_aNewNames, szData)
		}
	}
	fclose(iFile)
}

public plugin_end()
{
	ArrayDestroy(g_aNewNames)
}

#if !defined USE_REAPI
public FM_ClientUserInfoChanged_Pre(id)
{
	new szName[MAX_NAME_LENGTH]
	get_user_info(id, "name", szName, charsmax(szName))

	return check_player_name(id, szName)
}
#else

/* We need to call the checking function in this player state, because reapi's RG_CBasePlayer_SetClientUserInfoName is called only
   when a player is changing his name, not the same behaviour as RG_CSGameRules_ClientUserInfoChanged.*/
public client_putinserver(id)
{
	new szName[MAX_NAME_LENGTH]

	get_user_name(id, szName, charsmax(szName))

	check_player_name(id, szName)
}

public RG_SetClientUserInfoName_Pre(id, szBuffer[], szNewName[])
{
	SetHookChainReturn(ATYPE_BOOL, true)

	return check_player_name(id, szNewName)

}
#endif

check_player_name(id, szName[])
{
	new bool:bFound
	for(new i; i < strlen(szName); i++)
	{
		if(!isalnum(szName[i]) && !is_standard_ascii(szName[i]))
		{
			bFound = true
			break;
		}
	}

	if(bFound)
	{
		new szTemp[MAX_NAME_LENGTH]
		new iRandom = random(ArraySize(g_aNewNames) - 1)

		ArrayGetString(g_aNewNames, iRandom, szTemp, charsmax(szTemp))

		set_user_info(id, "name", szTemp)

		if(is_user_connected(id))
		{
			client_print_color(id, id, "^1Your name has been ^4changed ^1because ^4non-ASCII characters ^1has been found in your name!")
		}

		return BLOCK_FUNC
	}

	return CONTINUE_FUNC
}

is_standard_ascii(iChar[])
{
	// ASCII Standard without some characters. See https://www.rapidtables.com/code/text/ascii-table.html#table
	if(iChar[0] > 31 && iChar[0] < 128)
	{
		return true
	}

	return false
}
