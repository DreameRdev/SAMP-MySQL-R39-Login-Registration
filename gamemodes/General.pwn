#include 										<a_samp>
#include 										<a_mysql>

#define SQL_HOST 								"127.1.0.0"
#define SQL_USER 								"root"
#define SQL_PASS								""
#define SQL_DATA 								"samp_db"
#define SQL_ACCOUNTDB                           "samp_accounts"

enum
{
	SQL_ACCOUNT_CHECK,
	SQL_ACCOUNT_LOAD,
	SQL_ACCOUNT_SAVE,
	DIALOG_REGISTER,
	DIALOG_LOGIN,
}

native WP_Hash(buffer[], len, const str[]);
#define ForEachPlayer(%0) for(new index_%0=0,%0=ConnectedPlayerList[0];index_%0<ConnectedPlayers;index_%0++,%0=ConnectedPlayerList[index_%0])

new SQLConnect,
	ConnectedPlayers=0,
    ConnectedPlayerList[MAX_PLAYERS+1];

enum pInfoEnum
{
	pName[MAX_PLAYER_NAME],
	pIP[15],
	bool: pLogged,
}
new pInfo[MAX_PLAYERS][pInfoEnum];

main()
{

}

public OnGameModeInit()
{
    SQLConnect = mysql_connect(SQL_HOST,SQL_USER,SQL_DATA,SQL_PASS);
    if(mysql_errno() != 0)
    {
        print("FEHLER: Es konnte keine MySQL Verbindung aufgebaut werden!");
        mysql_close();
		SendRconCommand("exit");
    }
    
	mysql_tquery(SQLConnect,"CREATE TABLE IF NOT EXISTS "SQL_ACCOUNTDB" (id int(11) NOT NULL AUTO_INCREMENT,Name varchar(24) NOT NULL,Passwort varchar(129) NOT NULL,PRIMARY KEY (`id`))");
	return 1;
}

public OnGameModeExit()
{
	mysql_close();
    return 1;
}

public OnPlayerConnect(playerid)
{
	SetPlayerColor(playerid, -1);
	TogglePlayerSpectating(playerid,true);
	
	GetPlayerName(playerid,pInfo[playerid][pName],MAX_PLAYER_NAME);
	GetPlayerIp(playerid,pInfo[playerid][pIP],15);
	
	SetSpawnInfo(playerid,0,random(311),-5000.0000,-5000.0000,-5000.0000,0,0,0,0,0,0,0);
	
	new query[66];
	mysql_format(SQLConnect,query,sizeof(query),"SELECT * FROM "SQL_ACCOUNTDB" WHERE Name='%s'",pInfo[playerid][pName]);
	mysql_pquery(SQLConnect,query,"OnQueryFinish","siii",pInfo[playerid][pName],SQL_ACCOUNT_CHECK,playerid,SQLConnect);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	for(new i;i<ConnectedPlayers;i++)
	{
	 	if(ConnectedPlayerList[i] != playerid)continue;
		ConnectedPlayers--;
		ConnectedPlayerList[i] = ConnectedPlayerList[ConnectedPlayers];
		return 1;
	}
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	new string[255];
	switch(dialogid)
	{
	    case DIALOG_REGISTER:
		{
		    if(!response) return Kick(playerid);
            WP_Hash(inputtext,129,inputtext);
			mysql_format(SQLConnect,string,sizeof(string),"INSERT INTO "SQL_ACCOUNTDB" (`Name`,`Passwort`) VALUES ('%s','%e')",pInfo[playerid][pName],inputtext);
			mysql_tquery(SQLConnect,string);
			Prepareforplaying(playerid);
		}

		case DIALOG_LOGIN:
		{
		    if(!response) return Kick(playerid);
		    WP_Hash(inputtext,129,inputtext);
			mysql_format(SQLConnect,string,sizeof(string),"SELECT * FROM "SQL_ACCOUNTDB" WHERE Name='%s' AND Passwort='%e'",pInfo[playerid][pName],inputtext);
			mysql_pquery(SQLConnect,string,"OnQueryFinish","siii",pInfo[playerid][pName],SQL_ACCOUNT_LOAD,playerid,SQLConnect);
		}
	}
    return 1;
}


forward OnQueryFinish(index[],sqlresultid,extraid,SconnectionHandle);
public OnQueryFinish(index[],sqlresultid,extraid,SconnectionHandle)
{
	new rows,fields;
	switch(sqlresultid)
	{
	    case SQL_ACCOUNT_CHECK:
	    {
	        cache_get_data(rows,fields);
	        if(!rows)
			{
				return ShowPlayerDialog(extraid,DIALOG_REGISTER,DIALOG_STYLE_INPUT,"Registration","Dein Accountname wurde nicht gefunden.\nDu kannst dich registrieren indem du dein\nPasswort unten in das Textfeld eingibst.","Registrieren","Verlassen");
			}
	        else
	        {
	            return ShowPlayerDialog(extraid,DIALOG_LOGIN,DIALOG_STYLE_INPUT,"Login","Dein Accoutname wurde gefunden.\nDu kannst dich einloggen indem du dein\nPasswort unten in das Textfeld eingibst.","Login","Verlassen");
	        }
	    }
	    
	    case SQL_ACCOUNT_LOAD:
	    {
	        cache_get_data(rows,fields);
	        if(!rows)
	        {
	            return ShowPlayerDialog(extraid,DIALOG_LOGIN,DIALOG_STYLE_INPUT,"Login","Dein Accoutname wurde gefunden.\nDu kannst dich einloggen indem du dein\nPasswort unten in das Textfeld eingibst.\n\nDas angegebene Passwort ist nicht korrekt!","Login","Verlassen");
	        }
	        Prepareforplaying(extraid);
	    }
	}
	return 1;
}

stock Prepareforplaying(playerid)
{
	pInfo[playerid][pLogged] = true;
	TogglePlayerSpectating(playerid, false);
	SpawnPlayer(playerid);
    SetPlayerPos(playerid,0,0,0); //Beliebigen Spawn einfügen
	
	if(ConnectedPlayers >= GetMaxPlayers()) return 0;
	ConnectedPlayerList[ConnectedPlayers++] = playerid;
	return 1;
}