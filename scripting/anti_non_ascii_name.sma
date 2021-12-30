/* Sublime AMXX Editor v4.2 */

/* Uncomment this if you want use reAPI support. */
//#define USE_REAPI

#include <amxmodx>
#include <amxmisc>
#if !defined USE_REAPI
#include <fakemeta>
#else
#include <reapi>
#endif

#if !defined MAX_NAME_LENGTH
#define MAX_NAME_LENGTH 32
#endif

#define PLUGIN  "Anti NON-ASCII Chars in Name"
#define VERSION "1.1"
#define AUTHOR  "Shadows Adi"

new Array:g_aNewNames

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	#if !defined USE_REAPI
	register_forward(FM_ClientUserInfoChanged, "FM_ClientUserInfoChanged_Pre")
	#else 
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "RG_SetClientUserInfoName_Pre")
	#endif

	g_aNewNames = ArrayCreate(MAX_NAME_LENGTH)
}

public plugin_end()
{
	ArrayDestroy(g_aNewNames)
}

public plugin_cfg()
{
	new szConfigsDir[256], szFileName[256]
	get_configsdir(szConfigsDir, charsmax(szConfigsDir))
	formatex(szFileName, charsmax(szFileName), "%s/NewNames.ini", szConfigsDir)

	new iFile = fopen(szFileName, "rt")

	if(iFile)
	{
		new szData[48], szTemp[MAX_NAME_LENGTH]

		while(fgets(iFile, szData, charsmax(szData)))
		{
			trim(szData)

			if(szData[0] == '#' || szData[0] == EOS || szData[0] == ';')
				continue

			parse(szData, szTemp, charsmax(szTemp))

			ArrayPushString(g_aNewNames, szTemp)
		}
	}
	fclose(iFile)
}

#if !defined USE_REAPI
public FM_ClientUserInfoChanged_Pre(id)
{
	new szName[MAX_NAME_LENGTH]
	get_user_info(id, "name", szName, charsmax(szName))

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

		client_print_color(id, id, "^1Your name has been ^4changed ^1because ^4non-ASCII characters ^1has been found in your name!")
		return FMRES_HANDLED
	}

	return FMRES_IGNORED
}
#else

public RG_SetClientUserInfoName_Pre(id, szBuffer[], szNewName[])
{
	new iPos = containi(szBuffer, "name")
	new bool:bFound
	if(iPos != -1)
	{
		for(new i; i < strlen(szNewName); i++)
		{
			if(!isalnum(szNewName[i])  && !is_standard_ascii(szName[i]))
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

			set_member(id, m_szNewName, szTemp)

			client_print_color(id, id, "^1Your name has been ^4changed ^1because ^4non-ASCII characters ^1has been found in your name!")
			return HC_SUPERCEDE
		}
	}
	return HC_CONTINUE
}
#endif

stock is_standard_ascii(iChar[])
{
	// ASCII Standard without some characters. See https://www.rapidtables.com/code/text/ascii-table.html#table
	if(iChar[0] > 31 && iChar[0] < 128)
	{
		return true
	}

	return false
}
