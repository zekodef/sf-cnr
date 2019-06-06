/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\hotel_da_novic.pwn
 * Purpose: hotel da novic with operational apartments (very dated)
 */

/* ** Includes ** */
#include 							< YSI\y_hooks >

/* ** Definitions ** */
#define MAX_AFLOORS                 ( 20 )

/* ** Variables ** */
enum E_FLAT_DATA
{
	E_OWNER[ 24 ],    		E_NAME[ 30 ], 		E_LOCKED,
	bool: E_CREATED,		E_FURNITURE
};

static stock
	g_apartmentData                 [ 19 ] [ E_FLAT_DATA ], // A1 = 19 Floors
	g_apartmentElevator             = INVALID_OBJECT_ID,
	g_apartmentElevatorGate         = INVALID_OBJECT_ID,
    g_apartmentElevatorLevel        = 0,
	g_apartmentElevatorDoor1		[ MAX_AFLOORS ]	= INVALID_OBJECT_ID,
	g_apartmentElevatorDoor2		[ MAX_AFLOORS ] = INVALID_OBJECT_ID,
	p_apartmentEnter                [ MAX_PLAYERS char ]
;

/* ** Hooks ** */
hook OnScriptInit( )
{
	// load objects for apartments
	initializeHotelObjects( );

	// Load apartments
	mysql_function_query( dbHandle, "SELECT * FROM `APARTMENTS`", true, "NovicHotel_Load", "" );

	// Apartments
	CreateDynamicObject( 4587, -1971.51, 1356.26, 65.32, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 28.26, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 55.54, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 82.77, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 3781, -1971.50, 1356.27, 109.89, 0.00, 0.00, -180.00, .priority = 1 );
	CreateDynamicObject( 4605, -1992.10, 1353.31, 1.11, 0.00, 0.00, -180.00, .priority = 1 );

	g_apartmentElevator = CreateDynamicObject( 18755, -1955.09, 1365.51, 8.36, 0.00, 0.00, 90.00 );

	for( new level, Float: Z; level < MAX_AFLOORS; level++ )
	{
		switch( level )
		{
		    case 0:     Z = 8.36;
		    case 1:     Z = 17.03;
		    default:    Z = 17.03 + ( ( level - 1 ) * 5.447 );
		}
		g_apartmentElevatorDoor1[ level ] = CreateDynamicObject( 18756, -1955.05, 1361.64, Z, 0.00, 0.00, -90.00 );
		g_apartmentElevatorDoor2[ level ] = CreateDynamicObject( 18757, -1955.05, 1361.64, Z, 0.00, 0.00, -90.00 );
	}

	// Bank
	g_bankvaultData[ CITY_SF ] [ E_OBJECT ] = CreateDynamicObject( 18766, -1412.565063, 859.274536, 983.132873, 0.000000, 90.000000, 90.000000 );
	g_bankvaultData[ CITY_LV ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ CITY_LV ] [ E_WORLD ] );
	g_bankvaultData[ CITY_LS ] [ E_OBJECT ] = CreateDynamicObject( 2634, 2114.742431, 1233.155273, 1017.616821, 0.000000, 0.000000, -90.000000, g_bankvaultData[ CITY_LS ] [ E_WORLD ] );
	SetDynamicObjectMaterial( g_bankvaultData[ CITY_SF ] [ E_OBJECT ], 0, 18268, "mtbtrackcs_t", "mp_carter_cage", -1 );
	return 1;
}

hook OnPlayerKeyStateChange( playerid, newkeys, oldkeys )
{
	static
		Float: X, Float: Y, Float: Z;

	if ( PRESSED( KEY_SECONDARY_ATTACK ) )
	{
		// Call Elevator Down
		if ( CanPlayerExitEntrance( playerid ) && ! IsPlayerTied( playerid ) && ! IsPlayerInAnyVehicle( playerid ) )
		{
			if ( IsPlayerInArea( playerid, -2005.859375, -1917.968750, 1339.843750, 1396.484375 ) && GetPlayerInterior( playerid ) == 0 )
			{
				GetDynamicObjectPos( g_apartmentElevator, X, Y, Z );
				if ( IsPlayerInRangeOfPoint( playerid, 2.0, X, Y, Z ) )
				{
					ClearAnimations( playerid ); // clear-fix

				    if ( IsDynamicObjectMoving( g_apartmentElevator ) )
				        return SendError( playerid, "You must wait for the elevator to stop operating to select a floor again." );

	                szLargeString = "Ground Floor\n";

	                for ( new i = 0; i < sizeof( g_apartmentData ); i++ ) // First floor
	                {
	                    if ( g_apartmentData[ i ] [ E_CREATED ] ) {
	                    	format( szLargeString, sizeof( szLargeString ), "%s%s - %s\n", szLargeString, g_apartmentData[ i ] [ E_OWNER ], g_apartmentData[ i ] [ E_NAME ] );
	                    } else {
						    strcat( szLargeString, "$5,000,000 - Available For Purchase!\n" );
						}
					}

					ShowPlayerDialog( playerid, DIALOG_APARTMENTS, DIALOG_STYLE_LIST, "{FFFFFF}Apartments", szLargeString, "Select", "Cancel" );
					return 1;
				}

				for ( new floors = 0; floors < MAX_AFLOORS; floors++ )
				{
					GetDynamicObjectPos( g_apartmentElevatorDoor1[ floors ], X, Y, Z );
                	if ( IsPlayerInRangeOfPoint( playerid, 4.0, X, Y, Z ) )
                	{
						ClearAnimations( playerid ); // clear-fix
					    if ( IsDynamicObjectMoving( g_apartmentElevator ) ) {
		       				SendError( playerid, "The elevator is operating, please wait." );
		       				break;
						}

	    				PlayerPlaySound( playerid, 1085, 0.0, 0.0, 0.0 );
						NovicHotel_CallElevator( floors ); // First floor
						break;
                	}
				}

				UpdatePlayerEntranceExitTick( playerid );
				return 1;
			}
		}
	}
	return 1;
}

hook OnDialogResponse( playerid, dialogid, response, listitem, inputtext[ ] )
{
	if ( dialogid == DIALOG_APARTMENTS && response )
	{
		new Float: X, Float: Y, Float: Z;
		GetDynamicObjectPos( g_apartmentElevator, X, Y, Z );
		if ( !IsPlayerInRangeOfPoint( playerid, 2.0, X, Y, Z ) )
			return SendError( playerid, "You must be near the elevator to use this!" );

	    if ( listitem == 0 ) NovicHotel_CallElevator( 0 );
	    else
	    {
			new id = listitem - 1;
			p_apartmentEnter{ playerid } = id;
			if ( strmatch( g_apartmentData[ id ] [ E_OWNER ], "No-one" ) || isnull( g_apartmentData[ id ] [ E_OWNER ] ) || !g_apartmentData[ id ] [ E_CREATED ] )
			{
			 	ShowPlayerDialog( playerid, DIALOG_APARTMENTS_BUY, DIALOG_STYLE_MSGBOX, "{FFFFFF}Are you interested?", "{FFFFFF}This apartment is available for sale. The price is $5,000,000.\nIf you wish to buy it, please click 'Purchase'.", "Purchase", "Deny" );
			}
			else if ( !strmatch( g_apartmentData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
			    if ( g_apartmentData[ id ] [ E_LOCKED ] ) {
					return SendError( playerid, "This apartment has been locked by its owner." );
				}
			}
	    	NovicHotel_CallElevator( id + 1 );
		}
	}
	else if ( dialogid == DIALOG_APARTMENTS_BUY && response )
	{
	    if ( NovicHotel_GetPlayerApartments( playerid ) > 0 )
	        return SendError( playerid, "You can only own one apartment." );

	    if ( GetPlayerCash( playerid ) < 5000000 )
	        return SendError( playerid, "You don't have enough money for this ($5,000,000)." );

		GivePlayerCash( playerid, -5000000 );

		new aID = p_apartmentEnter{ playerid };
		g_apartmentData[ aID ] [ E_CREATED ] = true;
		format( g_apartmentData[ aID ] [ E_OWNER ], 24, "%s", ReturnPlayerName( playerid ) );
		format( g_apartmentData[ aID ] [ E_NAME ], 30, "Apartment %d", aID );
		g_apartmentData[ aID ] [ E_LOCKED ] = 0;

		format( szNormalString, 100, "INSERT INTO `APARTMENTS` VALUES (%d,'%s','Apartment %d',0)", aID, mysql_escape( ReturnPlayerName( playerid ) ), aID );
	    mysql_single_query( szNormalString );

		SendServerMessage( playerid, "You have purchased an apartment for "COL_GOLD"$5,000,000"COL_WHITE"." );
	}
	else if ( dialogid == DIALOG_FLAT_CONFIG && response )
	{
		for( new id, x = 0; id < sizeof( g_apartmentData ); id ++ )
		{
			if ( g_apartmentData[ id ] [ E_CREATED ] && strmatch( g_apartmentData[ id ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
			{
		       	if ( x == listitem )
		      	{
					SetPVarInt( playerid, "flat_editing", id );
		      	    SendServerMessage( playerid, "You are now controlling the settings over "COL_GREY"%s", g_apartmentData[ id ] [ E_NAME ] );
		      		ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
		      		break;
				}
		      	x++;
			}
		}
	}
	else if ( dialogid == DIALOG_FLAT_CONTROL )
	{
	    if ( !response )
	        return cmd_flat( playerid, "config" );

		switch( listitem )
		{
		    case 0:
		    {
		    	SetPlayerSpawnLocation( playerid, "APT", GetPVarInt( playerid, "flat_editing" ) );
				SendServerMessage( playerid, "You have set your spawning location to the specified apartment. To stop this you can use \"/flat stopspawn\"." );
				ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
			}
			case 1:
			{
		        new id = GetPVarInt( playerid, "flat_editing" );
             	g_apartmentData[ id ] [ E_LOCKED ] = ( g_apartmentData[ id ] [ E_LOCKED ] == 1 ? 0 : 1 );
				mysql_single_query( sprintf( "UPDATE `APARTMENTS` SET `LOCKED`=%d WHERE `ID`=%d", g_apartmentData[ id ] [ E_LOCKED ], id  ) );
				SendServerMessage( playerid, "You have %s the specified apartment.", g_apartmentData[ id ] [ E_LOCKED ] == 1 ? ( "locked" ) : ( "unlocked" ) );
				ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
			}
		    case 2:
		    {
		   		ShowPlayerDialog( playerid, DIALOG_FLAT_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Owned Apartments", ""COL_WHITE"Input the apartment title you want to change with:", "Submit", "Back" );
			}
		    case 3: ShowPlayerDialog( playerid, DIALOG_YOU_SURE_APART, DIALOG_STYLE_MSGBOX, "{FFFFFF}Owned Apartments", ""COL_WHITE"Are you sure that you want to sell your apartment?", "Yes", "No" );
		}
	}
	else if ( dialogid == DIALOG_YOU_SURE_APART )
	{
		if ( ! response )
   			return ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );

		new id = GetPVarInt( playerid, "flat_editing" );

		g_apartmentData[ id ] [ E_CREATED ] = false;
		strcpy( g_apartmentData[ id ] [ E_OWNER ], "No-one" );
		// format( g_apartmentData[ id ] [ E_OWNER ], MAX_PLAYER_NAME, "%s", "No-one" );
		format( g_apartmentData[ id ] [ E_NAME ], 30, "Apartment %d", id );
		g_apartmentData[ id ] [ E_LOCKED ] = 0;

		format( szNormalString, 40, "DELETE FROM `APARTMENTS` WHERE `ID`=%d", id );
	    mysql_single_query( szNormalString );

        GivePlayerCash( playerid, 3000000 );
        printf( "%s(%d) sold their apartment", ReturnPlayerName( playerid ), playerid );

   		return SendClientMessage( playerid, -1, ""COL_GREY"[SERVER]"COL_WHITE" You have successfully sold your apartment for "COL_GOLD"$3,000,000"COL_WHITE".");
	}
	else if ( dialogid == DIALOG_FLAT_TITLE )
	{
	    if ( !response )
	        return ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );

		if ( !strlen( inputtext ) )
			return ShowPlayerDialog( playerid, DIALOG_FLAT_TITLE, DIALOG_STYLE_INPUT, "{FFFFFF}Owned Apartments", ""COL_WHITE"Input the apartment title you want to change with:\n\n"COL_RED"Must be more than 0 characters.", "Submit", "Back" );

		new id = GetPVarInt( playerid, "flat_editing" );
		mysql_single_query( sprintf( "UPDATE `APARTMENTS` SET `NAME`='%s' WHERE `ID`=%d", mysql_escape( inputtext ), id ) );
		format( g_apartmentData[ id ] [ E_NAME ], 30, "%s", inputtext );
 		SendServerMessage( playerid, "You have successfully changed the name of your apartment." );
  		ShowPlayerDialog( playerid, DIALOG_FLAT_CONTROL, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", "Spawn Here\nLock Apartment\nModify Apartment Name\nSell Apartment", "Select", "Back" );
	}
	return 1;
}

hook OnDynamicObjectMoved( objectid )
{
	if ( objectid == g_apartmentElevator )
	{
		DestroyDynamicObject( g_apartmentElevatorGate ), g_apartmentElevatorGate = INVALID_OBJECT_ID;

		new Float: Y, Float: Z, i = g_apartmentElevatorLevel;
		GetDynamicObjectPos( g_apartmentElevatorDoor1[ i ], Y, Y, Z );
		MoveDynamicObject( g_apartmentElevatorDoor1[ i ], -1956.8068, Y, Z, 5.0 );

		GetDynamicObjectPos( g_apartmentElevatorDoor2[ i ], Y, Y, Z );
		MoveDynamicObject( g_apartmentElevatorDoor2[ i ], -1953.3468, Y, Z, 5.0 );
		return 1;
	}
	return 1;
}

/* ** SQL Threads ** */
thread NovicHotel_Load( )
{
	new
		rows, fields, i = -1, aID,
		Field[ 5 ],
	    loadingTick = GetTickCount( )
	;

	cache_get_data( rows, fields );
	if ( rows )
	{
		while( ++i < rows )
		{
			cache_get_field_content( i, "ID", Field ),			aID = strval( Field );
			cache_get_field_content( i, "OWNER", g_apartmentData[ aID ] [ E_OWNER ], dbHandle, 24 );
			cache_get_field_content( i, "NAME", g_apartmentData[ aID ] [ E_NAME ], dbHandle, 30 );
			cache_get_field_content( i, "LOCKED", Field ), g_apartmentData[ aID ] [ E_LOCKED ] = strval( Field );
			g_apartmentData[ aID ] [ E_CREATED ] = true;
		}
	}
	printf( "[FLATS]: %d apartments have been loaded. (Tick: %dms)", i, GetTickCount( ) - loadingTick );
	return 1;
}

/* ** Commands ** */
CMD:flat( playerid, params[ ] )
{
	new count = 0;
	szBigString[ 0 ] = '\0';
	for( new i; i < sizeof( g_apartmentData ); i++ ) if ( g_apartmentData[ i ] [ E_CREATED ] )
	{
		if ( strmatch( g_apartmentData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) )
		{
		    count++;
		    format( szBigString, sizeof( szBigString ), "%s%s\n", szBigString, g_apartmentData[ i ] [ E_NAME ] );
		}
	}
	if ( count == 0 ) return SendError( playerid, "You don't own any apartments." );

	ShowPlayerDialog( playerid, DIALOG_FLAT_CONFIG, DIALOG_STYLE_LIST, "{FFFFFF}Owned Apartments", szBigString, "Select", "Cancel" );
	return 1;
}

/* ** Functions ** */
stock NovicHotel_IsOwner( playerid, apartmentid ) {
	return g_apartmentData[ apartmentid ] [ E_CREATED ] && strmatch( g_apartmentData[ apartmentid ] [ E_OWNER ], ReturnPlayerName( playerid ) );
}

stock NovicHotel_SetPlayerToFloor( playerid, floor )
{
	pauseToLoad( playerid );
    SetPlayerInterior( playerid, 0 );
    SetPlayerFacingAngle( playerid, 180.0 );
    SetPlayerPos( playerid, -1955.0114, 1360.8344, 17.03 + ( floor * 5.447 ) );
	return 1;
}

stock NovicHotel_UpdateOwnerName( playerid, const newName[ ] )
{
	mysql_format( dbHandle, szNormalString, sizeof( szNormalString ), "UPDATE `APARTMENTS` SET `OWNER` = '%e' WHERE `OWNER` = '%e'", newName, ReturnPlayerName( playerid ) );
	mysql_single_query( szNormalString );

	for( new i = 0; i < sizeof( g_apartmentData ); i++ ) {
		if ( strmatch( g_apartmentData[ i ] [ E_OWNER ], ReturnPlayerName( playerid ) ) ) {
			format( g_apartmentData[ i ] [ E_OWNER ], 24, "%s", newName );
		}
	}
	return 1;
}

stock NovicHotel_CallElevator( level )
{
	new Float: Z, Float: LastZ;

	if ( level >= MAX_AFLOORS )
	    return -1; // Invalid Floor

	switch( level ) {
	    case 0:     Z = 8.36;
	    case 1:     Z = 17.03;
	    default:    Z = 17.03 + ( ( level - 1 ) * 5.447 );
	}

	GetDynamicObjectPos( g_apartmentElevatorDoor1[ g_apartmentElevatorLevel ], LastZ, LastZ, LastZ );
	MoveDynamicObject( g_apartmentElevatorDoor1[ g_apartmentElevatorLevel ], -1955.05, 1361.64, LastZ, 5.0 );
	MoveDynamicObject( g_apartmentElevatorDoor2[ g_apartmentElevatorLevel ], -1955.05, 1361.64, LastZ, 5.0 );

	DestroyDynamicObject( g_apartmentElevatorGate ), g_apartmentElevatorGate = INVALID_OBJECT_ID;
	g_apartmentElevatorGate = CreateDynamicObject( 19304, -1955.08, 1363.74, LastZ, 0.00, 0.00, 0.00 );
 	SetObjectInvisible( g_apartmentElevatorGate ); // Just looks ugly...
	MoveDynamicObject( g_apartmentElevatorGate, -1955.08, 1363.74, Z, 7.0 );

	MoveDynamicObject( g_apartmentElevator, -1955.09, 1365.51, Z, 7.0 );

	g_apartmentElevatorLevel = level; // For the last level.
	return 1;
}

stock NovicHotel_GetPlayerApartments( playerid )
{
	for( new i; i < sizeof( g_apartmentData ); i++ ) if ( g_apartmentData[ i ] [ E_CREATED ] )
	{
		if ( strmatch( g_apartmentData[ i ][ E_OWNER ], ReturnPlayerName( playerid ) ) )
		    return 1;
	}
	return 0;
}

static stock initializeHotelObjects( )
{
	CreateDynamicObject(2298, -1985.83, 1338.86, 15.12,   0.00, 0.00, -149.22);
	CreateDynamicObject(2841, -1987.06, 1337.19, 15.12,   0.00, 0.00, 27.30);
	CreateDynamicObject(2854, -1984.05, 1335.72, 15.64,   0.00, 0.00, -152.40);
	CreateDynamicObject(322, -1986.60, 1334.10, 15.10,   90.00, 0.00, -81.78);
	CreateDynamicObject(19173, -1985.02, 1334.90, 17.59,   0.00, 0.00, 30.24);
	CreateDynamicObject(2313, -2000.97, 1334.05, 15.12,   0.00, 0.00, 129.12);
	CreateDynamicObject(948, -2000.36, 1333.39, 15.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -2002.44, 1335.72, 15.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1996.12, 1336.56, 15.12,   0.00, 0.00, -89.94);
	CreateDynamicObject(1703, -1999.12, 1339.38, 15.12,   0.00, 0.00, -28.14);
	CreateDynamicObject(1433, -1998.11, 1336.72, 15.30,   0.00, 0.00, 0.00);
	CreateDynamicObject(1791, -2001.67, 1334.40, 21.10,   0.00, 0.00, 130.14);
	CreateDynamicObject(1703, -1980.57, 1362.46, 15.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1978.67, 1358.45, 15.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(1742, -1986.98, 1354.63, 15.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1356.05, 15.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1357.49, 15.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(2629, -1944.44, 1369.48, 15.12,   0.00, 0.00, -24.18);
	CreateDynamicObject(2628, -1942.33, 1360.38, 15.12,   0.00, 0.00, 200.94);
	CreateDynamicObject(2632, -1945.13, 1359.30, 15.12,   0.00, 0.00, 22.50);
	CreateDynamicObject(2630, -1944.97, 1359.29, 15.17,   0.00, 0.00, -69.72);
	CreateDynamicObject(2823, -1941.60, 1361.71, 15.14,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1943.38, 1368.56, 15.14,   0.00, 0.00, 94.74);
	CreateDynamicObject(1703, -1967.23, 1368.44, 15.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1965.35, 1362.87, 15.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1969.25, 1364.60, 15.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1963.44, 1366.64, 15.12,   0.00, 0.00, -90.00);
	CreateDynamicObject(1433, -1966.55, 1365.76, 15.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1966.77, 1365.77, 15.82,   0.00, 0.00, 0.00);
	CreateDynamicObject(2132, -1977.66, 1368.48, 15.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(2131, -1975.62, 1368.44, 15.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1979.65, 1368.47, 15.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.65, 1368.47, 15.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(2822, -1979.57, 1368.39, 27.10,   0.00, 0.00, -119.10);
	CreateDynamicObject(2851, -1977.48, 1366.77, 32.49,   0.00, 0.00, 55.92);
	CreateDynamicObject(640, -1989.72, 1374.46, 15.81,   0.00, 0.00, 90.00);
	CreateDynamicObject(640, -2001.74, 1377.44, 15.81,   0.00, 0.00, 150.00);
	CreateDynamicObject(1594, -2000.27, 1371.24, 15.60,   0.00, 0.00, 21.78);
	CreateDynamicObject(1594, -1996.87, 1367.44, 15.60,   0.00, 0.00, -30.00);
	CreateDynamicObject(1594, -2000.86, 1363.47, 15.60,   0.00, 0.00, 38.22);
	CreateDynamicObject(2823, -2000.17, 1371.34, 16.01,   0.00, 0.00, -5.04);
	CreateDynamicObject(2823, -1996.90, 1367.48, 16.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -2000.93, 1363.38, 16.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1997.03, 1367.15, 16.01,   0.00, 0.00, 116.04);
	CreateDynamicObject(2823, -2000.44, 1371.00, 16.01,   0.00, 0.00, 126.24);
	CreateDynamicObject(1703, -1963.44, 1366.64, 20.57,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1967.23, 1368.44, 20.57,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1969.25, 1364.60, 20.57,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1965.35, 1362.87, 20.57,   0.00, 0.00, 180.00);
	CreateDynamicObject(1433, -1966.55, 1365.76, 20.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1966.77, 1365.77, 21.29,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1978.67, 1358.45, 20.57,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1980.57, 1362.46, 20.57,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1986.98, 1354.63, 20.57,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1356.05, 20.57,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1357.49, 20.57,   0.00, 0.00, 90.00);
	CreateDynamicObject(2632, -1945.13, 1359.30, 20.57,   0.00, 0.00, 22.50);
	CreateDynamicObject(2628, -1942.33, 1360.38, 20.57,   0.00, 0.00, 200.94);
	CreateDynamicObject(2823, -1941.60, 1361.71, 20.59,   0.00, 0.00, 0.00);
	CreateDynamicObject(2630, -1944.97, 1359.29, 20.63,   0.00, 0.00, -69.72);
	CreateDynamicObject(2298, -1985.83, 1338.86, 20.57,   0.00, 0.00, -149.22);
	CreateDynamicObject(2841, -1987.06, 1337.19, 20.59,   0.00, 0.00, 27.30);
	CreateDynamicObject(19173, -1985.02, 1334.90, 22.57,   0.00, 0.00, 30.24);
	CreateDynamicObject(2854, -1984.05, 1335.72, 21.10,   0.00, 0.00, -152.40);
	CreateDynamicObject(322, -1986.60, 1334.10, 20.57,   90.00, 0.00, -81.78);
	CreateDynamicObject(1433, -1998.11, 1336.72, 20.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1999.12, 1339.38, 20.57,   0.00, 0.00, -28.14);
	CreateDynamicObject(1703, -1996.12, 1336.56, 20.57,   0.00, 0.00, -89.94);
	CreateDynamicObject(2313, -2000.97, 1334.05, 20.57,   0.00, 0.00, 129.12);
	CreateDynamicObject(948, -2000.36, 1333.39, 20.57,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -2002.44, 1335.72, 20.57,   0.00, 0.00, 0.00);
	CreateDynamicObject(1594, -2000.86, 1363.47, 21.05,   0.00, 0.00, 38.22);
	CreateDynamicObject(1594, -1996.87, 1367.44, 21.01,   0.00, 0.00, -30.00);
	CreateDynamicObject(1594, -2000.27, 1371.24, 21.01,   0.00, 0.00, 21.78);
	CreateDynamicObject(640, -2001.74, 1377.44, 21.29,   0.00, 0.00, 150.00);
	CreateDynamicObject(2823, -2000.93, 1363.38, 21.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -2000.44, 1371.00, 21.41,   0.00, 0.00, 126.24);
	CreateDynamicObject(2823, -2000.17, 1371.34, 21.41,   0.00, 0.00, -5.04);
	CreateDynamicObject(2823, -1997.03, 1367.15, 21.41,   0.00, 0.00, 116.04);
	CreateDynamicObject(2823, -1996.90, 1367.48, 21.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -1989.72, 1374.46, 21.27,   0.00, 0.00, 90.00);
	CreateDynamicObject(2131, -1975.62, 1368.44, 20.57,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1977.66, 1368.48, 20.57,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1979.65, 1368.47, 20.57,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.65, 1368.47, 20.57,   0.00, 0.00, 180.00);
	CreateDynamicObject(2629, -1944.44, 1369.48, 20.57,   0.00, 0.00, -24.18);
	CreateDynamicObject(2823, -1943.38, 1368.56, 20.59,   0.00, 0.00, 94.74);
	CreateDynamicObject(1703, -1978.67, 1358.45, 26.04,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1980.57, 1362.46, 26.04,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1969.25, 1364.60, 26.04,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1967.23, 1368.44, 26.04,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1963.44, 1366.64, 26.04,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1965.35, 1362.87, 26.04,   0.00, 0.00, 180.00);
	CreateDynamicObject(1433, -1966.55, 1365.76, 26.22,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1966.77, 1365.77, 26.74,   0.00, 0.00, 0.00);
	CreateDynamicObject(2630, -1944.97, 1359.29, 26.10,   0.00, 0.00, -69.72);
	CreateDynamicObject(2628, -1942.33, 1360.38, 26.04,   0.00, 0.00, 200.94);
	CreateDynamicObject(2632, -1945.13, 1359.30, 26.04,   0.00, 0.00, 22.50);
	CreateDynamicObject(2823, -1941.60, 1361.71, 26.08,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1943.38, 1368.56, 26.06,   0.00, 0.00, 94.74);
	CreateDynamicObject(2629, -1944.44, 1369.48, 26.04,   0.00, 0.00, -24.18);
	CreateDynamicObject(1742, -1986.98, 1354.63, 26.04,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1356.05, 26.04,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1357.49, 26.04,   0.00, 0.00, 90.00);
	CreateDynamicObject(2841, -1987.06, 1337.19, 26.04,   0.00, 0.00, 27.30);
	CreateDynamicObject(2298, -1985.83, 1338.86, 26.04,   0.00, 0.00, -149.22);
	CreateDynamicObject(2854, -1984.05, 1335.72, 26.60,   0.00, 0.00, -152.40);
	CreateDynamicObject(19173, -1985.02, 1334.90, 27.78,   0.00, 0.00, 30.24);
	CreateDynamicObject(1703, -1996.12, 1336.56, 26.04,   0.00, 0.00, -89.94);
	CreateDynamicObject(1703, -1999.12, 1339.38, 26.04,   0.00, 0.00, -28.14);
	CreateDynamicObject(1433, -1998.11, 1336.72, 26.22,   0.00, 0.00, 0.00);
	CreateDynamicObject(2313, -2000.97, 1334.05, 26.04,   0.00, 0.00, 129.12);
	CreateDynamicObject(948, -2002.44, 1335.72, 26.04,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -2000.36, 1333.39, 26.04,   0.00, 0.00, 0.00);
	CreateDynamicObject(1791, -2001.67, 1334.40, 26.54,   0.00, 0.00, 130.14);
	CreateDynamicObject(640, -2001.74, 1377.44, 26.72,   0.00, 0.00, 150.00);
	CreateDynamicObject(1594, -2000.27, 1371.24, 26.52,   0.00, 0.00, 21.78);
	CreateDynamicObject(1594, -2000.86, 1363.47, 26.52,   0.00, 0.00, 38.22);
	CreateDynamicObject(1594, -1996.87, 1367.44, 26.52,   0.00, 0.00, -30.00);
	CreateDynamicObject(2823, -2000.93, 1363.38, 26.92,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1997.03, 1367.15, 26.92,   0.00, 0.00, 116.04);
	CreateDynamicObject(2823, -1996.90, 1367.48, 26.92,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -2000.17, 1371.34, 26.92,   0.00, 0.00, -5.04);
	CreateDynamicObject(2823, -2000.44, 1371.00, 26.92,   0.00, 0.00, 126.24);
	CreateDynamicObject(640, -1989.72, 1374.46, 26.72,   0.00, 0.00, 90.00);
	CreateDynamicObject(2134, -1980.65, 1368.47, 26.04,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1979.65, 1368.47, 26.04,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1977.66, 1368.48, 26.04,   0.00, 0.00, 180.00);
	CreateDynamicObject(2131, -1975.62, 1368.44, 26.04,   0.00, 0.00, 180.00);
	CreateDynamicObject(2822, -1979.57, 1368.39, 22.00,   0.00, 0.00, -119.10);
	CreateDynamicObject(1703, -2000.32, 1353.23, 26.03,   0.00, 0.00, 46.14);
	CreateDynamicObject(1703, -1995.46, 1351.56, 26.03,   0.00, 0.00, 226.08);
	CreateDynamicObject(640, -1989.74, 1348.68, 26.72,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1985.12, 1350.72, 26.04,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1982.79, 1354.39, 26.04,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1982.79, 1354.39, 15.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1985.12, 1350.72, 15.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1995.46, 1351.56, 15.12,   0.00, 0.00, 226.08);
	CreateDynamicObject(1703, -2000.32, 1353.23, 15.12,   0.00, 0.00, 46.14);
	CreateDynamicObject(1703, -1995.46, 1351.56, 20.57,   0.00, 0.00, 226.08);
	CreateDynamicObject(1703, -2000.32, 1353.23, 20.57,   0.00, 0.00, 46.14);
	CreateDynamicObject(640, -1989.74, 1348.68, 15.81,   0.00, 0.00, 90.00);
	CreateDynamicObject(640, -1989.74, 1348.68, 21.27,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1985.12, 1350.72, 20.57,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1982.79, 1354.39, 20.57,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1963.44, 1366.64, 31.49,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1967.23, 1368.44, 31.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1969.25, 1364.60, 31.49,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1965.35, 1362.87, 31.49,   0.00, 0.00, 180.00);
	CreateDynamicObject(1433, -1966.55, 1365.76, 31.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1966.77, 1365.77, 32.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2632, -1945.13, 1359.30, 31.49,   0.00, 0.00, 22.50);
	CreateDynamicObject(2630, -1944.97, 1359.29, 31.55,   0.00, 0.00, -69.72);
	CreateDynamicObject(2628, -1942.33, 1360.38, 31.49,   0.00, 0.00, 200.94);
	CreateDynamicObject(2823, -1941.60, 1361.71, 31.51,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1943.38, 1368.56, 31.51,   0.00, 0.00, 94.74);
	CreateDynamicObject(2629, -1944.44, 1369.48, 31.49,   0.00, 0.00, -24.18);
	CreateDynamicObject(1703, -1982.79, 1354.39, 31.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1985.12, 1350.72, 31.49,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1978.67, 1358.45, 31.49,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1980.57, 1362.46, 31.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1986.98, 1357.49, 31.49,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1356.07, 31.49,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1354.63, 31.49,   0.00, 0.00, 90.00);
	CreateDynamicObject(2131, -1975.62, 1368.44, 31.49,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1977.66, 1368.48, 31.49,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1979.65, 1368.47, 31.49,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.65, 1368.47, 31.49,   0.00, 0.00, 180.00);
	CreateDynamicObject(2822, -1979.57, 1368.39, 32.49,   0.00, 0.00, -119.10);
	CreateDynamicObject(1742, -1981.50, 1363.73, 42.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1981.50, 1363.77, 42.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1980.26, 1363.74, 47.85,   0.04, 0.00, 0.00);
	CreateDynamicObject(2000, -1950.63, 1374.00, 56.14,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1981.69, 1363.75, 53.31,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1980.27, 1363.76, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1981.51, 1363.76, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(2576, -1980.86, 1337.87, 42.39,   0.00, 0.00, 210.00);
	CreateDynamicObject(1744, -1984.81, 1334.76, 49.85,   0.00, 0.00, 210.00);
	CreateDynamicObject(2563, -1985.28, 1337.53, 42.39,   0.00, 0.00, 210.00);
	CreateDynamicObject(1820, -1988.60, 1333.17, 42.40,   0.00, 0.00, 0.00);
	CreateDynamicObject(2196, -1987.99, 1334.26, 48.38,   0.00, 0.00, 70.00);
	CreateDynamicObject(321, -1981.87, 1337.16, 44.61,   -87.54, 61.86, 0.00);
	CreateDynamicObject(1825, -2001.13, 1367.23, 42.40,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1966.04, 1368.27, 42.40,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1968.59, 1364.71, 42.40,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1964.08, 1363.20, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1968.59, 1364.71, 47.88,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1966.04, 1368.27, 47.82,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1964.08, 1363.20, 47.87,   0.00, 0.00, 180.00);
	CreateDynamicObject(2576, -1980.86, 1337.87, 47.85,   0.00, 0.00, 210.00);
	CreateDynamicObject(321, -1981.87, 1337.16, 50.07,   -87.54, 61.86, 0.00);
	CreateDynamicObject(2563, -1985.28, 1337.53, 47.85,   0.00, 0.00, 210.00);
	CreateDynamicObject(1820, -1988.60, 1333.17, 47.86,   0.00, 0.00, 0.00);
	CreateDynamicObject(1825, -2001.13, 1367.23, 47.84,   0.00, 0.00, 0.00);
	CreateDynamicObject(1744, -1984.81, 1334.76, 44.39,   0.00, 0.00, 210.00);
	CreateDynamicObject(2196, -1987.99, 1334.26, 42.90,   0.00, 0.00, 70.00);
	CreateDynamicObject(1724, -1986.45, 1350.62, 42.39,   0.00, 0.00, 90.00);
	CreateDynamicObject(2629, -1950.42, 1364.58, 42.44,   0.00, 0.00, 90.00);
	CreateDynamicObject(2630, -1950.42, 1366.39, 42.44,   0.00, 0.00, 90.00);
	CreateDynamicObject(2628, -1941.78, 1369.04, 42.40,   0.00, 0.00, -30.00);
	CreateDynamicObject(2627, -1943.23, 1359.67, 42.40,   0.00, 0.00, -66.00);
	CreateDynamicObject(2629, -1950.42, 1364.58, 47.90,   0.00, 0.00, 90.00);
	CreateDynamicObject(2630, -1950.42, 1366.39, 47.90,   0.00, 0.00, 90.00);
	CreateDynamicObject(2628, -1941.78, 1369.04, 47.86,   0.00, 0.00, -30.00);
	CreateDynamicObject(2627, -1943.23, 1359.67, 47.86,   0.00, 0.00, -66.00);
	CreateDynamicObject(1724, -1986.45, 1350.62, 47.85,   0.00, 0.00, 90.00);
	CreateDynamicObject(2628, -1941.78, 1369.04, 53.32,   0.00, 0.00, -30.00);
	CreateDynamicObject(2627, -1943.23, 1359.67, 53.32,   0.00, 0.00, -66.00);
	CreateDynamicObject(2629, -1950.42, 1364.58, 53.36,   0.00, 0.00, 90.00);
	CreateDynamicObject(2630, -1950.42, 1366.39, 53.36,   0.00, 0.00, 90.00);
	CreateDynamicObject(1724, -1986.43, 1350.60, 53.32,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1968.58, 1364.69, 53.32,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1964.08, 1363.20, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1966.04, 1368.27, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(321, -1981.87, 1337.16, 55.52,   -87.54, 61.86, 0.00);
	CreateDynamicObject(2576, -1980.86, 1337.87, 53.30,   0.00, 0.00, 210.00);
	CreateDynamicObject(2563, -1985.28, 1337.53, 53.32,   0.00, 0.00, 210.00);
	CreateDynamicObject(1744, -1984.81, 1334.76, 55.32,   0.00, 0.00, 210.00);
	CreateDynamicObject(1820, -1988.60, 1333.17, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(2196, -1987.99, 1334.26, 53.82,   0.00, 0.00, 70.00);
	CreateDynamicObject(1825, -2001.13, 1367.23, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2000.56, 1333.31, 42.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2002.45, 1335.54, 42.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2000.56, 1333.31, 47.85,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2002.45, 1335.54, 47.85,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2000.56, 1333.31, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2002.45, 1335.54, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(1724, -1982.98, 1353.77, 58.77,   0.00, 0.00, 137.64);
	CreateDynamicObject(1703, -1964.08, 1363.20, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1966.04, 1368.27, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1968.59, 1364.71, 58.77,   0.00, 0.00, 90.00);
	CreateDynamicObject(2627, -1943.23, 1359.67, 58.77,   0.00, 0.00, -66.00);
	CreateDynamicObject(2629, -1950.42, 1364.58, 58.89,   0.00, 0.00, 90.00);
	CreateDynamicObject(2630, -1950.42, 1366.39, 58.87,   0.00, 0.00, 90.00);
	CreateDynamicObject(2628, -1941.78, 1369.04, 58.77,   0.00, 0.00, -30.00);
	CreateDynamicObject(1724, -1986.43, 1350.60, 64.23,   0.00, 0.00, 90.00);
	CreateDynamicObject(321, -1981.87, 1337.16, 60.99,   -87.54, 61.86, 0.00);
	CreateDynamicObject(2576, -1980.86, 1337.87, 58.77,   0.00, 0.00, 210.00);
	CreateDynamicObject(2563, -1985.30, 1337.54, 58.77,   0.00, 0.00, 210.00);
	CreateDynamicObject(1820, -1988.60, 1333.17, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1744, -1984.81, 1334.76, 66.23,   0.00, 0.00, 210.00);
	CreateDynamicObject(2196, -1987.99, 1334.26, 59.27,   0.00, 0.00, 70.00);
	CreateDynamicObject(2010, -2000.56, 1333.31, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2002.45, 1335.54, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1968.59, 1364.71, 64.23,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1966.04, 1368.27, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1964.08, 1363.20, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2628, -1941.78, 1369.04, 64.23,   0.00, 0.00, -30.00);
	CreateDynamicObject(2629, -1950.42, 1364.58, 64.31,   0.00, 0.00, 90.00);
	CreateDynamicObject(2627, -1943.23, 1359.67, 64.23,   0.00, 0.00, -66.00);
	CreateDynamicObject(2630, -1950.42, 1366.39, 64.31,   0.00, 0.00, 90.00);
	CreateDynamicObject(321, -1981.87, 1337.16, 6.45,   -87.54, 61.86, 0.00);
	CreateDynamicObject(321, -1982.03, 1337.35, 66.45,   -87.54, 61.86, 0.00);
	CreateDynamicObject(2576, -1980.86, 1337.87, 64.23,   0.00, 0.00, 210.00);
	CreateDynamicObject(2563, -1985.28, 1337.53, 64.23,   0.00, 0.00, 210.00);
	CreateDynamicObject(1820, -1988.60, 1333.17, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(2196, -1987.99, 1334.26, 64.73,   0.00, 0.00, 70.00);
	CreateDynamicObject(1744, -1984.81, 1334.76, 60.77,   0.00, 0.00, 210.00);
	CreateDynamicObject(2010, -2002.45, 1335.54, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -2000.56, 1333.31, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1825, -2001.13, 1367.23, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1825, -2001.13, 1367.23, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1516, -1965.03, 1365.65, 42.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1965.03, 1365.70, 48.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(1516, -1965.03, 1365.65, 47.87,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1965.03, 1365.70, 42.93,   0.00, 0.00, 0.00);
	CreateDynamicObject(2762, -1998.67, 1353.41, 42.81,   0.00, 0.00, 90.00);
	CreateDynamicObject(1670, -1998.63, 1353.90, 43.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1721, -1998.69, 1355.07, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(1721, -1997.64, 1354.06, 42.40,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1997.63, 1352.82, 42.40,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1999.71, 1352.82, 42.40,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1999.69, 1354.06, 42.40,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1998.69, 1351.82, 42.40,   0.00, 0.00, 0.00);
	CreateDynamicObject(2858, -1998.78, 1353.02, 43.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -2001.26, 1367.22, 43.27,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1980.08, 1363.75, 42.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1978.63, 1363.76, 42.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(2204, -1986.81, 1353.64, 42.39,   0.00, 0.00, 90.32);
	CreateDynamicObject(344, -1986.63, 1354.87, 43.43,   -19.38, -86.82, 90.00);
	CreateDynamicObject(2131, -1982.07, 1368.49, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1984.36, 1368.42, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1986.38, 1368.49, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.01, 1368.48, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.01, 1368.48, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1979.01, 1368.48, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1978.00, 1368.48, 42.40,   0.00, 0.00, 180.00);
	CreateDynamicObject(2823, -1980.47, 1368.37, 43.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(2858, -1979.06, 1368.36, 43.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(2851, -1984.69, 1368.32, 43.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(638, -2001.79, 1377.47, 43.10,   0.00, 0.00, 150.00);
	CreateDynamicObject(2596, -1959.46, 1365.79, 45.26,   0.00, 0.00, 270.00);
	CreateDynamicObject(2596, -1959.46, 1365.79, 50.26,   0.00, 0.00, 270.00);
	CreateDynamicObject(2596, -1959.46, 1365.79, 56.26,   0.00, 0.00, 270.00);
	CreateDynamicObject(2596, -1959.46, 1365.79, 61.26,   0.00, 0.00, 270.00);
	CreateDynamicObject(2596, -1959.48, 1365.79, 67.26,   0.00, 0.00, 270.00);
	CreateDynamicObject(1516, -1965.03, 1365.65, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1965.03, 1365.70, 53.86,   0.00, 0.00, 0.00);
	CreateDynamicObject(2131, -1982.07, 1368.49, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2823, -1980.47, 1368.37, 48.94,   0.00, 0.00, 0.00);
	CreateDynamicObject(2858, -1979.06, 1368.36, 48.94,   0.00, 0.00, 0.00);
	CreateDynamicObject(2133, -1986.38, 1368.49, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1984.36, 1368.42, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.01, 1368.48, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.01, 1368.48, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1979.01, 1368.48, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1978.00, 1368.48, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2859, -2001.26, 1367.22, 48.72,   0.00, 0.00, 0.00);
	CreateDynamicObject(638, -2001.79, 1377.47, 48.56,   0.00, 0.00, 150.00);
	CreateDynamicObject(2762, -1998.67, 1353.41, 48.26,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1999.71, 1352.82, 47.88,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1999.69, 1354.06, 47.88,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1997.63, 1352.82, 47.88,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1998.69, 1351.82, 47.88,   0.00, 0.00, 0.00);
	CreateDynamicObject(1721, -1997.64, 1354.06, 47.88,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1998.69, 1355.07, 47.88,   0.00, 0.00, 180.00);
	CreateDynamicObject(2858, -1998.78, 1353.02, 48.70,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1998.63, 1353.90, 48.70,   0.00, 0.00, 0.00);
	CreateDynamicObject(638, -2001.79, 1377.47, 54.02,   0.00, 0.00, 150.00);
	CreateDynamicObject(2859, -2001.26, 1367.22, 54.20,   0.00, 0.00, 0.00);
	CreateDynamicObject(2762, -1998.67, 1353.41, 53.72,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1998.69, 1351.82, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(1721, -1999.71, 1352.82, 53.32,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1999.69, 1354.06, 53.32,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1997.64, 1354.06, 53.32,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1997.63, 1352.82, 53.32,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1998.69, 1355.07, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(1670, -1998.63, 1353.90, 54.16,   0.00, 0.00, 0.00);
	CreateDynamicObject(2858, -1998.78, 1353.02, 54.14,   0.00, 0.00, 0.00);
	CreateDynamicObject(1721, -1998.69, 1355.07, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(1721, -1999.69, 1354.06, 58.77,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1999.72, 1352.80, 58.77,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1997.63, 1352.82, 58.77,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1997.64, 1354.06, 58.77,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1998.69, 1351.82, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(2762, -1998.67, 1353.41, 59.19,   0.00, 0.00, 90.00);
	CreateDynamicObject(2858, -1998.78, 1353.02, 59.61,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1998.63, 1353.90, 59.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -2001.26, 1367.22, 59.65,   0.00, 0.00, 0.00);
	CreateDynamicObject(1721, -1998.69, 1355.07, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(1721, -1999.69, 1354.06, 64.23,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1997.64, 1354.06, 64.23,   0.00, 0.00, 90.00);
	CreateDynamicObject(1721, -1999.72, 1352.80, 64.23,   0.00, 0.00, -90.00);
	CreateDynamicObject(1721, -1998.69, 1351.82, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1721, -1997.63, 1352.82, 64.23,   0.00, 0.00, 90.00);
	CreateDynamicObject(2762, -1998.67, 1353.41, 64.63,   0.00, 0.00, 90.00);
	CreateDynamicObject(2858, -1998.78, 1353.02, 65.05,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1998.63, 1353.90, 65.07,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -2001.26, 1367.22, 65.11,   0.00, 0.00, 0.00);
	CreateDynamicObject(638, -2001.79, 1377.47, 64.95,   0.00, 0.00, 150.00);
	CreateDynamicObject(638, -2001.79, 1377.47, 59.47,   0.00, 0.00, 150.00);
	CreateDynamicObject(2842, -1987.08, 1336.59, 42.40,   0.00, 0.00, 30.00);
	CreateDynamicObject(2842, -1987.08, 1336.59, 47.85,   0.00, 0.00, 30.00);
	CreateDynamicObject(2842, -1987.08, 1336.59, 53.32,   0.00, 0.00, 30.00);
	CreateDynamicObject(2842, -1987.08, 1336.59, 58.77,   0.00, 0.00, 30.00);
	CreateDynamicObject(2842, -1987.08, 1336.59, 64.23,   0.00, 0.00, 30.00);
	CreateDynamicObject(2131, -1982.07, 1368.49, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1984.36, 1368.42, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1986.38, 1368.49, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1978.00, 1368.48, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(2823, -1980.47, 1368.37, 54.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(2858, -1979.06, 1368.36, 54.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(2134, -1979.01, 1368.48, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.01, 1368.48, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.01, 1368.48, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(2851, -1984.69, 1368.32, 54.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(1516, -1965.03, 1365.65, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1965.03, 1365.70, 59.31,   0.00, 0.00, 0.00);
	CreateDynamicObject(1516, -1965.03, 1365.65, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1965.03, 1365.70, 64.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(2851, -1984.69, 1368.32, 48.94,   0.00, 0.00, 0.00);
	CreateDynamicObject(2133, -1978.00, 1368.48, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(2131, -1982.07, 1368.49, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1986.38, 1368.49, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(2858, -1979.06, 1368.32, 59.83,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1980.47, 1368.37, 59.82,   0.00, 0.00, 0.00);
	CreateDynamicObject(2851, -1984.69, 1368.32, 59.82,   0.00, 0.00, 0.00);
	CreateDynamicObject(2134, -1979.01, 1368.48, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.01, 1368.48, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.00, 1368.47, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1984.36, 1368.42, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1978.00, 1368.48, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2858, -1979.06, 1368.32, 65.29,   0.00, 0.00, 0.00);
	CreateDynamicObject(2134, -1979.01, 1368.48, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2823, -1980.47, 1368.37, 65.28,   0.00, 0.00, 0.00);
	CreateDynamicObject(2134, -1980.01, 1368.48, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.00, 1368.47, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2131, -1982.07, 1368.49, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2851, -1984.69, 1368.32, 65.29,   0.00, 0.00, 0.00);
	CreateDynamicObject(2132, -1984.36, 1368.42, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1986.38, 1368.49, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(2204, -1986.81, 1353.64, 47.85,   0.00, 0.00, 90.32);
	CreateDynamicObject(344, -1986.63, 1354.87, 48.89,   -19.38, -86.82, 90.00);
	CreateDynamicObject(1742, -1978.82, 1363.74, 47.85,   0.04, 0.00, 0.00);
	CreateDynamicObject(1742, -1981.70, 1363.74, 47.85,   0.04, 0.00, 0.00);
	CreateDynamicObject(1742, -1983.13, 1363.75, 53.31,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1980.25, 1363.75, 53.31,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1978.83, 1363.74, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1981.69, 1363.76, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1982.96, 1363.77, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1742, -1980.07, 1363.76, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(2204, -1986.79, 1353.63, 58.77,   0.00, 0.00, 90.32);
	CreateDynamicObject(2204, -1986.81, 1353.64, 64.23,   0.00, 0.00, 90.32);
	CreateDynamicObject(2204, -1986.81, 1353.63, 53.32,   0.00, 0.00, 90.32);
	CreateDynamicObject(19086, -1986.69, 1354.39, 55.41,   0.00, 0.00, 90.00);
	CreateDynamicObject(344, -1986.63, 1354.87, 59.53,   -19.38, -86.82, 90.00);
	CreateDynamicObject(344, -1986.63, 1354.87, 65.29,   -19.38, -86.82, 90.00);
	CreateDynamicObject(2964, -1965.47, 1365.88, 69.63,   0.00, 0.00, 3.30);
	CreateDynamicObject(338, -1965.07, 1366.45, 70.56,   -32.76, -91.98, 0.00);
	CreateDynamicObject(338, -1964.31, 1365.76, 70.56,   -32.76, -91.98, 30.42);
	CreateDynamicObject(338, -1966.47, 1365.57, 70.56,   -32.76, -91.98, -209.46);
	CreateDynamicObject(2995, -1966.00, 1365.51, 70.56,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.57, 1365.94, 70.56,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.63, 1365.60, 70.56,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.04, 1366.26, 70.56,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.86, 1365.73, 70.56,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.09, 1366.22, 70.56,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.48, 1365.99, 70.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.39, 1365.92, 70.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.44, 1365.80, 70.28,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.50, 1365.96, 70.28,   0.00, 0.00, 0.00);
	CreateDynamicObject(2857, -1967.78, 1367.98, 70.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2857, -1963.64, 1363.52, 70.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2628, -1941.19, 1368.21, 69.63,   0.00, 0.00, -27.36);
	CreateDynamicObject(2631, -1942.60, 1360.45, 69.63,   0.00, 0.00, 23.46);
	CreateDynamicObject(2629, -1941.93, 1360.68, 69.68,   0.00, 0.00, -66.42);
	CreateDynamicObject(2859, -1941.69, 1362.59, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1943.04, 1367.83, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1944.80, 1366.83, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(2630, -1946.54, 1359.21, 69.63,   0.00, 0.00, 244.98);
	CreateDynamicObject(2815, -1948.21, 1365.55, 69.63,   0.00, 0.00, 90.36);
	CreateDynamicObject(2229, -1982.53, 1336.32, 69.62,   0.00, 0.00, -150.06);
	CreateDynamicObject(2311, -1985.89, 1334.83, 69.63,   0.00, 0.00, 30.90);
	CreateDynamicObject(2229, -1987.92, 1333.19, 69.62,   0.00, 0.00, -150.06);
	CreateDynamicObject(1786, -1985.08, 1335.21, 70.13,   0.00, 0.00, -149.52);
	CreateDynamicObject(2344, -1985.78, 1337.63, 70.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2849, -1985.38, 1335.19, 69.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(2566, -1998.99, 1334.80, 70.07,   0.00, 0.00, 129.42);
	CreateDynamicObject(2816, -2000.58, 1333.43, 70.12,   0.00, 0.00, 114.84);
	CreateDynamicObject(2819, -2001.19, 1336.12, 70.17,   0.00, 0.00, -82.68);
	CreateDynamicObject(1703, -1990.51, 1347.50, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1986.80, 1339.73, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1989.36, 1336.55, 69.63,   0.00, 0.00, 72.90);
	CreateDynamicObject(2894, -2002.52, 1335.68, 70.12,   0.00, 0.00, 83.46);
	CreateDynamicObject(2816, -1986.23, 1337.24, 70.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2841, -2000.06, 1336.46, 69.63,   0.00, 0.00, -49.56);
	CreateDynamicObject(948, -1991.62, 1348.52, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -1987.69, 1348.57, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1991.77, 1343.84, 69.63,   0.00, 0.00, 90.30);
	CreateDynamicObject(1703, -1988.57, 1342.31, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1987.40, 1345.91, 69.63,   0.00, 0.00, 270.00);
	CreateDynamicObject(1433, -1989.55, 1345.18, 69.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1989.68, 1345.38, 70.32,   0.00, 0.00, 24.72);
	CreateDynamicObject(1670, -1989.28, 1344.93, 70.32,   0.00, 0.00, 46.26);
	CreateDynamicObject(638, -1993.29, 1369.20, 70.33,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.23, 1371.94, 70.33,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.23, 1362.46, 70.33,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1359.17, 70.33,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1353.50, 70.33,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.35, 1350.69, 70.33,   0.00, 0.00, 178.56);
	CreateDynamicObject(2147, -1977.72, 1368.49, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1978.54, 1368.46, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.20, 1368.46, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.86, 1368.46, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1980.52, 1368.46, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1975.73, 1368.46, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.36, 1368.41, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1982.36, 1368.41, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1983.36, 1368.41, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(2851, -1979.16, 1368.42, 70.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(2851, -1976.32, 1368.59, 70.81,   0.00, 0.00, -47.76);
	CreateDynamicObject(2858, -1979.91, 1368.38, 70.76,   0.00, 0.00, 0.00);
	CreateDynamicObject(322, -2002.57, 1335.74, 69.99,   -35.28, 95.70, 0.00);
	CreateDynamicObject(14455, -1986.79, 1356.28, 71.29,   0.00, 0.00, 270.00);
	CreateDynamicObject(14455, -1978.01, 1363.44, 71.29,   0.00, 0.00, 180.00);
	CreateDynamicObject(640, -1986.60, 1360.65, 70.30,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1968.62, 1370.18, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1965.30, 1370.18, 69.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1961.71, 1368.24, 69.63,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1961.67, 1364.86, 69.63,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1963.94, 1361.00, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1967.18, 1360.96, 69.63,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1970.79, 1363.09, 69.63,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1970.87, 1366.32, 69.63,   0.00, 0.00, 90.00);
	CreateDynamicObject(19172, -1966.09, 1357.16, 72.50,   0.00, 0.00, 185.00);
	CreateDynamicObject(19174, -1984.98, 1334.94, 72.47,   0.00, 0.00, 210.54);
	CreateDynamicObject(1703, -1987.36, 1345.89, 75.09,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1990.51, 1347.50, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1991.77, 1343.84, 75.09,   0.00, 0.00, 90.30);
	CreateDynamicObject(1703, -1988.57, 1342.31, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(14455, -1986.79, 1356.28, 76.75,   0.00, 0.00, 270.00);
	CreateDynamicObject(640, -1986.60, 1360.65, 75.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(14455, -1978.01, 1363.44, 76.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(948, -1987.69, 1348.57, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -1991.62, 1348.52, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1989.55, 1345.18, 75.27,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1986.80, 1339.73, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1989.36, 1336.55, 75.09,   0.00, 0.00, 72.90);
	CreateDynamicObject(1703, -1970.79, 1363.09, 75.09,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1970.87, 1366.32, 75.09,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1967.18, 1360.96, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1963.94, 1361.00, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1961.67, 1364.86, 75.09,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1961.71, 1368.24, 75.09,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1965.30, 1370.18, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1968.62, 1370.18, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(2815, -1948.21, 1365.55, 75.09,   0.00, 0.00, 90.36);
	CreateDynamicObject(2859, -1944.80, 1366.83, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1943.04, 1367.83, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1941.69, 1362.59, 75.09,   0.00, 0.00, 0.00);
	CreateDynamicObject(2630, -1946.54, 1359.21, 75.09,   0.00, 0.00, 244.98);
	CreateDynamicObject(2628, -1941.19, 1368.21, 75.09,   0.00, 0.00, -27.36);
	CreateDynamicObject(2631, -1942.60, 1360.45, 75.09,   0.00, 0.00, 23.46);
	CreateDynamicObject(2629, -1941.93, 1360.68, 75.13,   0.00, 0.00, -66.42);
	CreateDynamicObject(2857, -1963.64, 1363.52, 75.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(2857, -1967.78, 1367.98, 75.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(2311, -1985.89, 1334.83, 75.09,   0.00, 0.00, 30.90);
	CreateDynamicObject(2229, -1982.53, 1336.32, 75.09,   0.00, 0.00, -150.06);
	CreateDynamicObject(2229, -1987.92, 1333.19, 75.09,   0.00, 0.00, -150.06);
	CreateDynamicObject(2816, -1986.23, 1337.24, 75.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2344, -1985.80, 1337.62, 75.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(1786, -1985.08, 1335.21, 75.59,   0.00, 0.00, -149.52);
	CreateDynamicObject(2849, -1985.38, 1335.19, 75.15,   0.00, 0.00, 0.00);
	CreateDynamicObject(2841, -2000.06, 1336.46, 75.09,   0.00, 0.00, -49.56);
	CreateDynamicObject(2566, -1998.99, 1334.80, 75.51,   0.00, 0.00, 129.42);
	CreateDynamicObject(2816, -2000.58, 1333.43, 75.59,   0.00, 0.00, 114.84);
	CreateDynamicObject(2819, -2001.19, 1336.12, 75.63,   0.00, 0.00, -82.68);
	CreateDynamicObject(2894, -2002.53, 1335.70, 75.55,   0.00, 0.00, 83.46);
	CreateDynamicObject(322, -2002.57, 1335.74, 75.43,   -35.28, 95.70, 0.00);
	CreateDynamicObject(638, -1993.35, 1350.69, 75.79,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1353.50, 75.79,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1359.17, 75.79,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.21, 1362.47, 75.79,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1369.20, 75.79,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.23, 1371.94, 75.79,   0.00, 0.00, 178.56);
	CreateDynamicObject(1670, -1989.68, 1345.38, 75.79,   0.00, 0.00, 24.72);
	CreateDynamicObject(1670, -1989.28, 1344.93, 75.79,   0.00, 0.00, 46.26);
	CreateDynamicObject(2132, -1975.73, 1368.46, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2147, -1977.72, 1368.49, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1978.54, 1368.46, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.20, 1368.46, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.86, 1368.46, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1980.52, 1368.46, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.36, 1368.41, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1982.36, 1368.41, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1983.36, 1368.41, 75.09,   0.00, 0.00, 180.00);
	CreateDynamicObject(2851, -1979.16, 1368.42, 76.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2858, -1979.91, 1368.38, 76.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2851, -1976.10, 1368.41, 76.15,   0.00, 0.00, -47.76);
	CreateDynamicObject(2964, -1965.47, 1365.88, 75.09,   0.00, 0.00, 3.30);
	CreateDynamicObject(338, -1966.47, 1365.57, 76.01,   -32.76, -91.98, -209.46);
	CreateDynamicObject(338, -1964.31, 1365.76, 76.01,   -32.76, -91.98, 30.42);
	CreateDynamicObject(338, -1965.07, 1366.45, 76.01,   -32.76, -91.98, 0.00);
	CreateDynamicObject(2995, -1964.48, 1365.99, 75.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.41, 1365.92, 75.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.09, 1366.22, 76.03,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.00, 1365.51, 76.03,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.63, 1365.60, 76.03,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.57, 1365.94, 76.03,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.86, 1365.73, 76.03,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.57, 1365.94, 81.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.04, 1366.26, 76.03,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.50, 1365.96, 75.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.44, 1365.80, 75.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(19172, -1966.09, 1357.16, 78.09,   0.00, 0.00, 185.00);
	CreateDynamicObject(19174, -1984.98, 1334.94, 78.47,   0.00, 0.00, 210.54);
	CreateDynamicObject(2628, -1941.19, 1368.21, 80.55,   0.00, 0.00, -27.36);
	CreateDynamicObject(2859, -1943.04, 1367.83, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(2631, -1942.60, 1360.45, 80.55,   0.00, 0.00, 23.46);
	CreateDynamicObject(2859, -1941.69, 1362.59, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1944.80, 1366.83, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(2629, -1941.93, 1360.68, 80.59,   0.00, 0.00, -66.42);
	CreateDynamicObject(2630, -1946.54, 1359.21, 80.55,   0.00, 0.00, 244.98);
	CreateDynamicObject(2815, -1948.21, 1365.55, 80.55,   0.00, 0.00, 90.36);
	CreateDynamicObject(1703, -1970.87, 1366.32, 80.55,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1965.30, 1370.18, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1968.62, 1370.18, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1961.71, 1368.24, 80.55,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1961.67, 1364.86, 80.55,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1963.94, 1361.00, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1967.18, 1360.96, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1970.79, 1363.09, 80.55,   0.00, 0.00, 90.00);
	CreateDynamicObject(2857, -1963.64, 1363.52, 81.25,   0.00, 0.00, 0.00);
	CreateDynamicObject(2857, -1967.78, 1367.98, 81.25,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -1987.69, 1348.57, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -1991.62, 1348.52, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1987.40, 1345.91, 80.55,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1990.51, 1347.50, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1991.77, 1343.84, 80.55,   0.00, 0.00, 90.30);
	CreateDynamicObject(1703, -1988.57, 1342.31, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1986.80, 1339.73, 80.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1989.36, 1336.55, 80.55,   0.00, 0.00, 72.90);
	CreateDynamicObject(2229, -1982.53, 1336.32, 80.55,   0.00, 0.00, -150.06);
	CreateDynamicObject(1433, -1989.55, 1345.18, 80.73,   0.00, 0.00, 0.00);
	CreateDynamicObject(2229, -1987.92, 1333.19, 80.55,   0.00, 0.00, -150.06);
	CreateDynamicObject(2816, -1986.23, 1337.24, 81.25,   0.00, 0.00, 0.00);
	CreateDynamicObject(2344, -1985.80, 1337.62, 81.25,   0.00, 0.00, 0.00);
	CreateDynamicObject(2841, -2000.06, 1336.46, 80.55,   0.00, 0.00, -49.56);
	CreateDynamicObject(1786, -1985.08, 1335.21, 81.05,   0.00, 0.00, -149.52);
	CreateDynamicObject(2311, -1985.89, 1334.83, 80.55,   0.00, 0.00, 30.90);
	CreateDynamicObject(2849, -1985.38, 1335.19, 80.61,   0.00, 0.00, 0.00);
	CreateDynamicObject(2566, -1998.99, 1334.80, 80.97,   0.00, 0.00, 129.42);
	CreateDynamicObject(2816, -2000.58, 1333.43, 81.03,   0.00, 0.00, 114.84);
	CreateDynamicObject(2894, -2002.53, 1335.70, 81.03,   0.00, 0.00, 83.46);
	CreateDynamicObject(2819, -2001.17, 1336.12, 81.07,   0.00, 0.00, -82.68);
	CreateDynamicObject(322, -2002.57, 1335.74, 80.89,   -35.28, 95.70, 0.00);
	CreateDynamicObject(638, -1993.35, 1350.69, 81.25,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1353.50, 81.25,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1359.17, 81.25,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.21, 1362.47, 81.25,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1369.20, 81.25,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.23, 1371.94, 81.25,   0.00, 0.00, 178.56);
	CreateDynamicObject(1670, -1989.28, 1344.93, 81.25,   0.00, 0.00, 46.26);
	CreateDynamicObject(1670, -1989.68, 1345.38, 81.25,   0.00, 0.00, 24.72);
	CreateDynamicObject(2964, -1965.47, 1365.88, 80.55,   0.00, 0.00, 3.30);
	CreateDynamicObject(338, -1965.07, 1366.45, 81.47,   -32.76, -91.98, 0.00);
	CreateDynamicObject(338, -1964.31, 1365.76, 81.47,   -32.76, -91.98, 30.42);
	CreateDynamicObject(338, -1966.47, 1365.57, 81.47,   -32.76, -91.98, -209.46);
	CreateDynamicObject(2995, -1964.86, 1365.73, 81.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.63, 1365.60, 81.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.00, 1365.51, 81.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.09, 1366.22, 81.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.04, 1366.26, 81.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.48, 1365.99, 81.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.41, 1365.92, 81.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.44, 1365.80, 81.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.50, 1365.96, 81.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2628, -1941.19, 1368.21, 86.01,   0.00, 0.00, -27.36);
	CreateDynamicObject(2815, -1948.21, 1365.55, 86.01,   0.00, 0.00, 90.36);
	CreateDynamicObject(2859, -1944.80, 1366.83, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1943.04, 1367.83, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1941.69, 1362.59, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(2631, -1942.60, 1360.45, 86.01,   0.00, 0.00, 23.46);
	CreateDynamicObject(2629, -1941.93, 1360.68, 86.07,   0.00, 0.00, -66.42);
	CreateDynamicObject(2630, -1946.54, 1359.21, 86.01,   0.00, 0.00, 244.98);
	CreateDynamicObject(1703, -1968.62, 1370.18, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1965.30, 1370.18, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1961.71, 1368.24, 86.01,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1961.67, 1364.86, 86.01,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1963.94, 1361.00, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1970.87, 1366.32, 86.01,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1970.79, 1363.09, 86.01,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1967.18, 1360.96, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2857, -1963.64, 1363.52, 86.71,   0.00, 0.00, 0.00);
	CreateDynamicObject(2857, -1967.78, 1367.98, 86.71,   0.00, 0.00, 0.00);
	CreateDynamicObject(14455, -1986.79, 1356.28, 82.21,   0.00, 0.00, 270.00);
	CreateDynamicObject(14455, -1978.01, 1363.44, 82.21,   0.00, 0.00, 180.00);
	CreateDynamicObject(640, -1986.60, 1360.65, 81.25,   0.00, 0.00, 0.00);
	CreateDynamicObject(14455, -1978.01, 1363.44, 87.67,   0.00, 0.00, 180.00);
	CreateDynamicObject(14455, -1986.79, 1356.28, 87.67,   0.00, 0.00, 270.00);
	CreateDynamicObject(640, -1986.60, 1360.65, 86.71,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1987.40, 1345.91, 86.01,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1990.51, 1347.50, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1991.77, 1343.84, 86.01,   0.00, 0.00, 90.30);
	CreateDynamicObject(1703, -1988.57, 1342.31, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(1433, -1989.55, 1345.18, 86.19,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1986.80, 1339.73, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1989.36, 1336.55, 86.01,   0.00, 0.00, 72.90);
	CreateDynamicObject(2816, -1986.23, 1337.24, 86.71,   0.00, 0.00, 0.00);
	CreateDynamicObject(2344, -1985.78, 1337.61, 86.71,   0.00, 0.00, 0.00);
	CreateDynamicObject(2229, -1982.53, 1336.32, 86.01,   0.00, 0.00, -150.06);
	CreateDynamicObject(2229, -1987.92, 1333.19, 86.01,   0.00, 0.00, -150.06);
	CreateDynamicObject(2311, -1985.89, 1334.83, 86.01,   0.00, 0.00, 30.90);
	CreateDynamicObject(1786, -1985.08, 1335.21, 86.51,   0.00, 0.00, -149.52);
	CreateDynamicObject(2849, -1985.38, 1335.19, 86.01,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1989.28, 1344.93, 86.71,   0.00, 0.00, 46.26);
	CreateDynamicObject(1670, -1989.68, 1345.38, 86.71,   0.00, 0.00, 24.72);
	CreateDynamicObject(2566, -1998.98, 1334.78, 86.41,   0.00, 0.00, 129.42);
	CreateDynamicObject(2816, -2000.58, 1333.43, 86.47,   0.00, 0.00, 114.84);
	CreateDynamicObject(2819, -2001.19, 1336.12, 86.51,   0.00, 0.00, -82.68);
	CreateDynamicObject(2894, -2002.53, 1335.70, 86.47,   0.00, 0.00, 83.46);
	CreateDynamicObject(2841, -2000.06, 1336.46, 86.01,   0.00, 0.00, -49.56);
	CreateDynamicObject(322, -2002.57, 1335.74, 86.33,   -35.28, 95.70, 0.00);
	CreateDynamicObject(638, -1993.35, 1350.69, 86.69,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1353.50, 86.69,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1359.17, 86.69,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.21, 1362.47, 86.69,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1369.20, 86.69,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.23, 1371.94, 86.69,   0.00, 0.00, 178.56);
	CreateDynamicObject(2134, -1983.36, 1368.41, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1982.36, 1368.41, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.36, 1368.41, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1980.52, 1368.46, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.86, 1368.46, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.20, 1368.46, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1978.54, 1368.46, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2147, -1977.72, 1368.49, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1975.73, 1368.46, 80.55,   0.00, 0.00, 180.00);
	CreateDynamicObject(2851, -1976.10, 1368.41, 81.61,   0.00, 0.00, -47.76);
	CreateDynamicObject(2851, -1979.16, 1368.42, 81.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(2858, -1979.91, 1368.38, 81.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(2964, -1965.47, 1365.88, 86.01,   0.00, 0.00, 3.30);
	CreateDynamicObject(338, -1966.47, 1365.57, 86.93,   -32.76, -91.98, -209.46);
	CreateDynamicObject(338, -1964.31, 1365.76, 86.93,   -32.76, -91.98, 30.42);
	CreateDynamicObject(338, -1965.07, 1366.45, 86.93,   -32.76, -91.98, 0.00);
	CreateDynamicObject(2995, -1964.86, 1365.73, 86.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.04, 1366.26, 86.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.57, 1365.94, 86.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.63, 1365.60, 86.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.00, 1365.51, 86.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.09, 1366.22, 86.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.41, 1365.92, 86.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.48, 1365.99, 86.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.42, 1365.78, 86.65,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.50, 1365.96, 86.65,   0.00, 0.00, 0.00);
	CreateDynamicObject(14455, -1986.79, 1356.28, 93.13,   0.00, 0.00, 270.00);
	CreateDynamicObject(14455, -1978.01, 1363.44, 93.13,   0.00, 0.00, 180.00);
	CreateDynamicObject(640, -1986.60, 1360.65, 92.17,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1970.79, 1363.09, 91.47,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1970.87, 1366.32, 91.47,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1968.62, 1370.18, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1965.30, 1370.18, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1967.20, 1360.97, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2857, -1967.78, 1367.98, 92.13,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1963.94, 1361.00, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1961.67, 1364.86, 91.47,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1961.71, 1368.24, 91.47,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1965.30, 1370.18, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(2857, -1963.64, 1363.52, 92.17,   0.00, 0.00, 0.00);
	CreateDynamicObject(2964, -1965.47, 1365.88, 91.47,   0.00, 0.00, 3.30);
	CreateDynamicObject(2815, -1948.21, 1365.55, 91.47,   0.00, 0.00, 90.36);
	CreateDynamicObject(2859, -1944.80, 1366.83, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(2630, -1946.54, 1359.21, 91.47,   0.00, 0.00, 244.98);
	CreateDynamicObject(2628, -1941.19, 1368.21, 91.47,   0.00, 0.00, -27.36);
	CreateDynamicObject(2859, -1943.04, 1367.83, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(2859, -1941.69, 1362.59, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(2631, -1942.60, 1360.45, 91.47,   0.00, 0.00, 23.46);
	CreateDynamicObject(2629, -1941.93, 1360.68, 91.47,   0.00, 0.00, -66.42);
	CreateDynamicObject(1703, -1991.77, 1343.84, 91.47,   0.00, 0.00, 90.30);
	CreateDynamicObject(1703, -1990.51, 1347.50, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1987.40, 1345.91, 91.47,   0.00, 0.00, 270.00);
	CreateDynamicObject(1703, -1988.57, 1342.31, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(1433, -1989.55, 1345.16, 91.65,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1989.68, 1345.38, 92.17,   0.00, 0.00, 24.72);
	CreateDynamicObject(1670, -1989.28, 1344.93, 92.17,   0.00, 0.00, 46.26);
	CreateDynamicObject(1703, -1986.80, 1339.73, 91.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1989.36, 1336.55, 91.47,   0.00, 0.00, 72.90);
	CreateDynamicObject(2816, -1986.24, 1337.26, 92.17,   0.00, 0.00, 0.00);
	CreateDynamicObject(2344, -1985.78, 1337.61, 92.17,   0.00, 0.00, 0.00);
	CreateDynamicObject(2229, -1982.53, 1336.32, 91.47,   0.00, 0.00, -150.06);
	CreateDynamicObject(2229, -1987.92, 1333.19, 91.47,   0.00, 0.00, -150.06);
	CreateDynamicObject(1786, -1985.08, 1335.21, 91.97,   0.00, 0.00, -149.52);
	CreateDynamicObject(2311, -1985.89, 1334.83, 91.47,   0.00, 0.00, 30.90);
	CreateDynamicObject(2849, -1985.38, 1335.21, 91.55,   0.00, 0.00, 0.00);
	CreateDynamicObject(2841, -2000.06, 1336.46, 91.47,   0.00, 0.00, -49.56);
	CreateDynamicObject(2566, -1998.98, 1334.78, 91.87,   0.00, 0.00, 129.42);
	CreateDynamicObject(2819, -2001.19, 1336.12, 91.95,   0.00, 0.00, -82.68);
	CreateDynamicObject(2894, -2002.53, 1335.70, 91.93,   0.00, 0.00, 83.46);
	CreateDynamicObject(2816, -2000.58, 1333.43, 91.93,   0.00, 0.00, 114.84);
	CreateDynamicObject(322, -2002.57, 1335.74, 91.79,   -35.28, 95.70, 0.00);
	CreateDynamicObject(638, -1993.35, 1350.69, 92.17,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1353.50, 92.17,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1359.17, 92.17,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.21, 1362.47, 92.17,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.29, 1369.20, 92.17,   0.00, 0.00, 178.56);
	CreateDynamicObject(638, -1993.23, 1371.94, 92.17,   0.00, 0.00, 178.56);
	CreateDynamicObject(2134, -1983.36, 1368.41, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1982.36, 1368.41, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.36, 1368.41, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1980.52, 1368.46, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.86, 1368.46, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.22, 1368.47, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1978.54, 1368.46, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2147, -1977.72, 1368.49, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1975.73, 1368.46, 86.01,   0.00, 0.00, 180.00);
	CreateDynamicObject(2851, -1976.10, 1368.41, 0.07,   0.00, 0.00, -47.76);
	CreateDynamicObject(2858, -1979.91, 1368.38, 87.15,   0.00, 0.00, 0.00);
	CreateDynamicObject(2851, -1979.16, 1368.42, 87.13,   0.00, 0.00, 0.00);
	CreateDynamicObject(2134, -1983.36, 1368.41, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1982.36, 1368.41, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1981.36, 1368.41, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1980.52, 1368.46, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.86, 1368.46, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1979.22, 1368.47, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2170, -1978.54, 1368.46, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2147, -1977.72, 1368.49, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1975.73, 1368.46, 91.47,   0.00, 0.00, 180.00);
	CreateDynamicObject(2851, -1976.10, 1368.41, 87.07,   0.00, 0.00, -47.76);
	CreateDynamicObject(2851, -1976.10, 1368.41, 92.53,   0.00, 0.00, -47.76);
	CreateDynamicObject(2858, -1979.91, 1368.38, 92.59,   0.00, 0.00, 0.00);
	CreateDynamicObject(2851, -1979.16, 1368.42, 92.59,   0.00, 0.00, 0.00);
	CreateDynamicObject(338, -1964.31, 1365.76, 92.39,   -32.76, -91.98, 30.42);
	CreateDynamicObject(338, -1966.47, 1365.57, 92.39,   -32.76, -91.98, -209.46);
	CreateDynamicObject(338, -1965.07, 1366.45, 92.39,   -32.76, -91.98, 0.00);
	CreateDynamicObject(2995, -1966.09, 1366.22, 92.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.86, 1365.73, 92.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.63, 1365.60, 92.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.57, 1365.94, 92.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.00, 1365.51, 92.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.04, 1366.26, 92.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.48, 1365.99, 92.15,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1964.41, 1365.92, 92.15,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.42, 1365.78, 92.13,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.50, 1365.96, 92.13,   0.00, 0.00, 0.00);
	CreateDynamicObject(19172, -1966.09, 1357.16, 83.09,   0.00, 0.00, 185.00);
	CreateDynamicObject(19172, -1966.09, 1357.16, 89.09,   0.00, 0.00, 185.00);
	CreateDynamicObject(19172, -1966.09, 1357.16, 94.09,   0.00, 0.00, 185.00);
	CreateDynamicObject(19174, -1984.98, 1334.94, 83.47,   0.00, 0.00, 210.54);
	CreateDynamicObject(19174, -1984.98, 1334.94, 89.47,   0.00, 0.00, 210.54);
	CreateDynamicObject(19174, -1984.98, 1334.94, 94.47,   0.00, 0.00, 210.54);
	CreateDynamicObject(1433, -1986.15, 1337.43, 69.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1967.81, 1367.81, 69.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1963.70, 1363.40, 69.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1967.80, 1367.83, 75.27,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1963.70, 1363.40, 75.27,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1986.15, 1337.43, 75.27,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1963.70, 1363.40, 80.73,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1967.80, 1367.83, 80.73,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1986.15, 1337.43, 80.73,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1963.70, 1363.40, 86.19,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1967.80, 1367.83, 86.19,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1986.15, 1337.43, 86.19,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1967.80, 1367.83, 91.65,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1963.70, 1363.40, 91.65,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1986.15, 1337.43, 91.65,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1946.51, 1364.10, 113.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(2853, -1944.55, 1365.05, 113.63,   0.00, 0.00, -273.36);
	CreateDynamicObject(2854, -1944.36, 1365.59, 113.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(1575, -1944.19, 1365.25, 113.21,   0.00, 0.00, 116.70);
	CreateDynamicObject(1670, -1944.48, 1364.54, 113.65,   0.00, 0.00, -135.60);
	CreateDynamicObject(3461, -1947.00, 1368.29, 114.65,   0.00, 0.00, -7.68);
	CreateDynamicObject(3461, -1947.01, 1362.45, 114.65,   0.00, 0.00, -7.68);
	CreateDynamicObject(1703, -1942.63, 1366.00, 113.12,   0.00, 0.00, 270.00);
	CreateDynamicObject(2700, -1943.23, 1359.49, 116.21,   0.00, 0.00, 114.84);
	CreateDynamicObject(2700, -1942.23, 1369.49, 116.21,   0.00, 0.00, 242.40);
	CreateDynamicObject(19128, -1967.59, 1363.71, 113.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(19128, -1967.58, 1367.67, 113.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(19128, -1963.61, 1363.70, 113.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(19128, -1963.63, 1367.68, 113.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(1957, -1971.76, 1365.35, 114.03,   0.00, 0.00, 94.98);
	CreateDynamicObject(1957, -1971.75, 1366.21, 114.03,   0.00, 0.00, -89.46);
	CreateDynamicObject(1840, -1971.71, 1365.73, 113.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(2229, -1971.92, 1364.76, 113.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(2229, -1971.94, 1367.42, 113.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(1714, -1973.48, 1364.71, 113.13,   0.00, 0.00, 113.04);
	CreateDynamicObject(1714, -1973.54, 1367.12, 113.13,   0.00, 0.00, 50.46);
	CreateDynamicObject(2255, -1974.32, 1365.83, 115.33,   0.00, 0.00, 90.00);
	CreateDynamicObject(2126, -1943.91, 1364.57, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(1575, -1944.37, 1364.68, 113.21,   0.00, 0.00, 49.80);
	CreateDynamicObject(1575, -1944.59, 1365.61, 113.21,   0.00, 0.00, 22.92);
	CreateDynamicObject(2032, -1971.61, 1365.30, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(1212, -1944.84, 1364.59, 0.06,   0.00, 162.24, 0.00);
	CreateDynamicObject(2267, -1944.54, 1370.89, 115.44,   0.00, 0.00, -27.16);
	CreateDynamicObject(2283, -1966.10, 1357.14, 115.79,   0.00, 0.00, 182.82);
	CreateDynamicObject(2393, -1992.68, 1370.18, 116.17,   90.00, 0.00, -90.00);
	CreateDynamicObject(1985, -1994.12, 1370.44, 115.91,   0.00, 0.00, 0.00);
	CreateDynamicObject(2341, -1986.65, 1368.45, 113.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(2340, -1986.68, 1369.45, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(2133, -1986.67, 1370.42, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(2133, -1986.67, 1371.42, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(2141, -1986.69, 1372.42, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(2132, -1984.65, 1368.45, 113.12,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1983.65, 1368.43, 113.13,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1982.65, 1368.43, 113.13,   0.00, 0.00, 180.00);
	CreateDynamicObject(2131, -1980.65, 1368.41, 113.13,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1979.65, 1368.43, 113.13,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1978.65, 1368.43, 113.13,   0.00, 0.00, 180.00);
	CreateDynamicObject(2427, -1978.72, 1368.05, 114.18,   0.00, 0.00, 180.00);
	CreateDynamicObject(1484, -1978.17, 1367.94, 113.26,   0.00, 0.00, 0.00);
	CreateDynamicObject(2866, -1982.93, 1368.30, 114.18,   0.00, 0.00, 202.38);
	CreateDynamicObject(2867, -1986.64, 1369.54, 114.18,   0.00, 0.00, -121.80);
	CreateDynamicObject(2915, -1993.35, 1368.22, 113.31,   0.00, 0.00, 89.82);
	CreateDynamicObject(2915, -1993.51, 1367.29, 113.31,   0.00, 0.00, 123.96);
	CreateDynamicObject(2632, -1993.65, 1367.19, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(2629, -1993.57, 1365.97, 113.18,   0.00, 0.00, 270.00);
	CreateDynamicObject(2851, -1985.67, 1368.35, 114.06,   0.00, 0.00, -106.32);
	CreateDynamicObject(2851, -1986.39, 1368.25, 114.18,   0.00, 0.00, -89.04);
	CreateDynamicObject(640, -2001.81, 1377.15, 113.81,   0.00, 0.00, -30.84);
	CreateDynamicObject(2393, -1992.68, 1360.43, 116.17,   90.00, 0.00, -90.00);
	CreateDynamicObject(1985, -1994.10, 1360.70, 115.91,   0.00, 0.00, 0.00);
	CreateDynamicObject(2632, -1993.65, 1357.95, 113.13,   0.00, 0.00, 90.00);
	CreateDynamicObject(2628, -1993.49, 1358.90, 113.18,   0.00, 0.00, -88.80);
	CreateDynamicObject(2627, -1993.91, 1362.71, 113.18,   0.00, 0.00, -86.82);
	CreateDynamicObject(2630, -1993.67, 1357.29, 113.18,   0.00, 0.00, -90.48);
	CreateDynamicObject(1703, -2000.95, 1368.55, 113.12,   0.00, 0.00, 61.08);
	CreateDynamicObject(1703, -1999.67, 1364.55, 113.12,   0.00, 0.00, 126.72);
	CreateDynamicObject(1703, -2000.64, 1360.11, 113.12,   0.00, 0.00, 61.08);
	CreateDynamicObject(1703, -1999.86, 1355.92, 113.12,   0.00, 0.00, 126.72);
	CreateDynamicObject(2566, -1999.01, 1334.74, 113.56,   0.00, 0.00, 128.82);
	CreateDynamicObject(2816, -2002.59, 1335.77, 113.61,   0.00, 0.00, -373.08);
	CreateDynamicObject(2855, -2000.72, 1333.44, 113.61,   0.00, 0.00, 0.00);
	CreateDynamicObject(348, -2000.74, 1333.25, 113.78,   -86.04, -57.30, 0.00);
	CreateDynamicObject(2818, -2000.11, 1336.43, 113.12,   0.00, 0.00, -50.22);
	CreateDynamicObject(1703, -1997.29, 1348.17, 113.12,   0.00, 0.00, -52.14);
	CreateDynamicObject(1703, -1999.55, 1343.82, 113.12,   0.00, 0.00, -231.24);
	CreateDynamicObject(1703, -1996.15, 1344.67, 113.12,   0.00, 0.00, -139.74);
	CreateDynamicObject(1703, -2000.69, 1347.09, 113.12,   0.00, 0.00, 38.58);
	CreateDynamicObject(2126, -1998.98, 1345.95, 113.13,   0.00, 0.00, -52.86);
	CreateDynamicObject(1670, -1997.91, 1345.37, 113.65,   0.00, 0.00, 38.04);
	CreateDynamicObject(1670, -1998.58, 1346.27, 113.65,   0.00, 0.00, 222.78);
	CreateDynamicObject(2311, -1982.21, 1337.05, 113.12,   0.00, 0.00, -148.26);
	CreateDynamicObject(2311, -1984.28, 1335.78, 113.12,   0.00, 0.00, -149.16);
	CreateDynamicObject(2311, -1986.32, 1334.52, 113.12,   0.00, 0.00, -149.16);
	CreateDynamicObject(1786, -1982.73, 1336.55, 113.63,   0.00, 0.00, -158.94);
	CreateDynamicObject(1786, -1986.91, 1333.95, 113.63,   0.00, 0.00, -123.42);
	CreateDynamicObject(1786, -1984.87, 1335.20, 113.63,   0.00, 0.00, -150.60);
	CreateDynamicObject(1703, -1984.41, 1340.65, 113.12,   0.00, 0.00, 20.40);
	CreateDynamicObject(1703, -1988.57, 1337.76, 113.12,   0.00, 0.00, 46.86);
	CreateDynamicObject(1703, -1990.88, 1333.75, 113.12,   0.00, 0.00, 78.90);
	CreateDynamicObject(14619, -1988.61, 1335.08, 113.50,   0.00, 0.00, 102.12);
	CreateDynamicObject(14467, -1989.57, 1347.87, 115.36,   0.00, 0.00, 0.00);
	CreateDynamicObject(1546, -1978.37, 1368.41, 114.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(1546, -1978.83, 1368.45, 114.32,   0.00, 0.00, 114.42);
	CreateDynamicObject(2275, -1988.01, 1374.37, 115.51,   0.00, 0.00, 180.00);
	CreateDynamicObject(2273, -1989.60, 1374.37, 115.83,   0.00, 0.00, 180.00);
	CreateDynamicObject(2275, -1991.31, 1374.37, 115.51,   0.00, 0.00, 180.00);
	CreateDynamicObject(640, -1985.67, 1379.81, 113.81,   0.00, 0.00, 90.00);
	CreateDynamicObject(640, -1991.15, 1379.81, 113.81,   0.00, 0.00, 90.00);
	CreateDynamicObject(640, -1996.63, 1379.81, 113.81,   0.00, 0.00, 90.00);
	CreateDynamicObject(3461, -1992.05, 1348.39, 114.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(3461, -1988.06, 1348.39, 114.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1982.68, 1339.27, 113.30,   0.00, 0.00, 16.56);
	CreateDynamicObject(1433, -1986.67, 1337.49, 113.30,   0.00, 0.00, 47.88);
	CreateDynamicObject(1433, -1989.06, 1334.82, 113.30,   0.00, 0.00, 79.62);
	CreateDynamicObject(3461, -1983.68, 1343.43, 115.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(3461, -1989.14, 1339.49, 115.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(3461, -1992.71, 1333.99, 115.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(2190, -1984.03, 1363.27, 113.91,   0.00, 0.00, 0.00);
	CreateDynamicObject(2162, -1987.00, 1354.71, 113.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(2162, -1987.01, 1356.51, 113.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(2163, -1987.00, 1358.30, 113.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(2165, -1986.48, 1360.13, 113.12,   0.00, 0.00, 90.00);
	CreateDynamicObject(2166, -1986.43, 1362.09, 113.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2171, -1982.55, 1363.09, 113.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2169, -1984.47, 1363.05, 113.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(1715, -1983.66, 1362.14, 113.13,   0.00, 0.00, 222.78);
	CreateDynamicObject(1715, -1985.63, 1362.44, 113.13,   0.00, 0.00, -2.40);
	CreateDynamicObject(1715, -1985.52, 1360.80, 113.13,   0.00, 0.00, -75.42);
	CreateDynamicObject(2853, -1986.57, 1361.58, 113.91,   0.00, 0.00, 0.00);
	CreateDynamicObject(2853, -1982.21, 1363.23, 113.91,   0.00, 0.00, 211.62);
	CreateDynamicObject(2854, -1985.73, 1363.13, 113.91,   0.00, 0.00, 0.00);
	CreateDynamicObject(2894, -1983.49, 1363.20, 113.91,   0.00, 0.00, -19.38);
	CreateDynamicObject(2600, -1998.19, 1333.09, 113.89,   0.00, 0.00, 21.36);
	CreateDynamicObject(2611, -1984.27, 1363.57, 115.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(921, -1985.59, 1363.50, 115.98,   0.00, 0.00, 0.00);
	CreateDynamicObject(2051, -1992.78, 1351.74, 115.49,   0.00, 0.00, 270.00);
	CreateDynamicObject(2051, -1992.77, 1353.73, 115.49,   0.00, 0.00, 270.00);
	CreateDynamicObject(1433, -1998.40, 1353.85, 113.31,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1998.43, 1351.40, 113.31,   0.00, 0.00, 0.00);
	CreateDynamicObject(348, -1998.26, 1354.20, 113.86,   90.00, 8.34, -71.70);
	CreateDynamicObject(348, -1998.59, 1353.61, 113.86,   90.00, 8.34, 3.18);
	CreateDynamicObject(348, -1998.63, 1351.53, 113.86,   90.00, 8.34, -73.86);
	CreateDynamicObject(348, -1998.09, 1351.67, 113.86,   90.00, 8.34, -142.68);
	CreateDynamicObject(1670, -1986.61, 1337.40, 113.83,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1988.88, 1334.96, 113.83,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1982.72, 1339.25, 113.83,   0.00, 0.00, 0.00);
	CreateDynamicObject(2344, -1982.98, 1339.43, 113.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(2344, -1986.51, 1337.80, 113.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(2344, -1989.35, 1335.13, 113.81,   0.00, 0.00, 0.00);
	CreateDynamicObject(2232, -1971.91, 1363.53, 113.68,   0.00, 0.00, 90.00);
	CreateDynamicObject(2232, -1971.73, 1367.85, 113.68,   0.00, 0.00, 90.00);
	CreateDynamicObject(3525, -1997.72, 1357.50, 111.20,   0.00, 0.00, 180.00);
	CreateDynamicObject(640, -2001.65, 1377.50, 102.91,   0.00, 0.00, -28.26);
	CreateDynamicObject(2286, -2002.06, 1377.77, 105.33,   0.00, 0.00, 60.78);
	CreateDynamicObject(2566, -1999.03, 1334.75, 97.32,   0.00, 0.00, 128.34);
	CreateDynamicObject(2853, -2000.78, 1333.42, 97.37,   0.00, 0.00, 27.36);
	CreateDynamicObject(2854, -2002.63, 1335.77, 97.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(2255, -2001.55, 1334.71, 98.86,   0.00, 0.00, 129.06);
	CreateDynamicObject(3525, -2000.84, 1333.40, 99.24,   0.00, 0.00, 129.06);
	CreateDynamicObject(3525, -2002.74, 1335.61, 99.24,   0.00, 0.00, 129.06);
	CreateDynamicObject(3525, -1984.76, 1341.99, 99.92,   0.00, 0.00, 270.00);
	CreateDynamicObject(2964, -1966.19, 1364.69, 96.75,   0.00, 0.00, 140.28);
	CreateDynamicObject(338, -1966.04, 1365.51, 97.69,   74.00, -78.30, 0.00);
	CreateDynamicObject(338, -1965.69, 1363.97, 97.69,   74.00, -78.30, -24.18);
	CreateDynamicObject(2995, -1966.80, 1364.98, 97.69,   0.00, 0.00, -38.04);
	CreateDynamicObject(2995, -1965.96, 1365.01, 97.69,   61.00, 0.00, 4.02);
	CreateDynamicObject(2995, -1966.79, 1364.64, 97.69,   456.00, 0.00, -48.66);
	CreateDynamicObject(2995, -1966.59, 1365.38, 97.69,   455.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.99, 1364.09, 97.69,   51.00, 0.00, -61.20);
	CreateDynamicObject(2995, -1965.29, 1364.49, 97.69,   21.00, 21.00, 0.00);
	CreateDynamicObject(2995, -1965.61, 1364.08, 97.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1965.41, 1364.09, 97.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(2995, -1966.95, 1365.27, 97.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(2244, -1986.67, 1373.40, 97.69,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -1977.65, 1368.35, 97.44,   0.00, 0.00, 90.00);
	CreateDynamicObject(2298, -1986.07, 1338.79, 15.12,   0.00, 0.00, 210.90);
	CreateDynamicObject(2393, -1982.78, 1378.14, 105.03,   0.00, 90.00, 180.00);
	CreateDynamicObject(1985, -1984.14, 1378.39, 105.26,   0.00, 0.00, 0.00);
	CreateDynamicObject(2628, -1989.47, 1374.61, 102.25,   0.00, 0.00, 180.00);
	CreateDynamicObject(2629, -1990.97, 1374.65, 102.26,   0.00, 0.00, 180.00);
	CreateDynamicObject(2611, -1966.69, 1370.24, 9.42,   0.00, 0.00, 0.00);
	CreateDynamicObject(2612, -1968.21, 1368.64, 9.41,   0.00, 0.00, 87.18);
	CreateDynamicObject(2207, -1964.96, 1364.10, 6.30,   0.00, 0.00, 0.00);
	CreateDynamicObject(2208, -1968.27, 1364.64, 6.34,   0.00, 0.00, 0.00);
	CreateDynamicObject(2208, -1962.32, 1364.70, 6.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(1671, -1964.03, 1365.97, 6.91,   0.00, 0.00, 0.00);
	CreateDynamicObject(2182, -1967.74, 1368.85, 6.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(2181, -1965.83, 1369.83, 6.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(2202, -1967.89, 1366.39, 6.47,   0.00, 0.00, 88.80);
	CreateDynamicObject(2190, -1964.91, 1364.39, 7.06,   0.00, 0.00, 127.62);
	CreateDynamicObject(2223, -1963.46, 1364.33, 7.14,   0.00, 0.00, -41.16);
	CreateDynamicObject(2059, -1965.89, 1364.60, 7.22,   0.00, 0.00, 151.98);
	CreateDynamicObject(2164, -1959.11, 1367.43, 6.38,   0.00, 0.00, -89.46);
	CreateDynamicObject(1893, -1964.18, 1367.05, 11.08,   0.00, 0.00, 0.00);
	CreateDynamicObject(1893, -1967.29, 1367.00, 11.14,   0.12, 2.40, 0.00);
	CreateDynamicObject(1893, -1961.08, 1367.07, 11.08,   0.00, 0.00, 0.00);
	CreateDynamicObject(2197, -1962.89, 1368.84, 6.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(2197, -1962.21, 1368.85, 6.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(2197, -1961.55, 1368.85, 6.45,   0.00, 0.00, 0.00);
	CreateDynamicObject(2262, -1962.22, 1369.80, 9.13,   0.00, 0.00, 0.00);
	CreateDynamicObject(2855, -1967.63, 1364.70, 7.20,   0.00, 0.00, 0.00);
	CreateDynamicObject(2190, -1967.19, 1364.60, 7.19,   0.00, 0.00, 155.52);
	CreateDynamicObject(2190, -1960.84, 1364.57, 7.19,   0.00, 0.00, 155.52);
	CreateDynamicObject(2855, -1967.63, 1364.70, 7.34,   0.00, 0.00, 0.00);
	CreateDynamicObject(2855, -1967.63, 1364.70, 7.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(2854, -1962.17, 1364.79, 7.19,   0.00, 0.00, 196.62);
	CreateDynamicObject(2687, -1968.45, 1364.59, 8.25,   0.00, 0.00, 85.32);
	CreateDynamicObject(2688, -1959.09, 1364.75, 8.04,   0.00, 0.00, -90.84);
	CreateDynamicObject(2258, -1968.63, 1361.31, 9.32,   0.00, 0.00, -272.82);
	CreateDynamicObject(2291, -1968.09, 1362.44, 6.39,   0.00, 0.00, 87.24);
	CreateDynamicObject(2291, -1968.17, 1361.46, 6.39,   0.00, 0.00, 87.24);
	CreateDynamicObject(2291, -1968.19, 1360.46, 6.39,   0.00, 0.00, 87.24);
	CreateDynamicObject(2291, -1968.25, 1359.48, 6.39,   0.00, 0.00, 87.24);
	CreateDynamicObject(2291, -1968.31, 1358.54, 6.39,   0.00, 0.00, 87.24);
	CreateDynamicObject(1671, -1960.40, 1365.67, 6.91,   0.00, 0.00, -50.76);
	CreateDynamicObject(1671, -1967.00, 1365.74, 6.91,   0.00, 0.00, 14.40);
	CreateDynamicObject(2199, -1954.69, 1370.23, 6.43,   0.00, 0.00, 0.00);
	CreateDynamicObject(2216, -1961.58, 1364.97, 7.25,   -26.04, 25.62, -130.26);
	CreateDynamicObject(1671, -1964.87, 1368.59, 6.91,   0.00, 0.00, -149.04);
	CreateDynamicObject(1823, -1965.86, 1360.42, 6.26,   3.60, -0.18, 90.06);
	CreateDynamicObject(2816, -1966.44, 1360.81, 6.79,   -3.00, 2.22, -75.54);
	CreateDynamicObject(2853, -1966.25, 1361.17, 6.80,   -2.52, -6.00, -152.58);
	CreateDynamicObject(1775, -1966.64, 1358.27, 7.40,   0.00, 0.00, -181.56);
	CreateDynamicObject(2894, -1967.90, 1369.00, 7.27,   0.00, 0.00, 98.88);
	CreateDynamicObject(2601, -1964.99, 1369.93, 7.35,   0.00, 0.00, 129.78);
	CreateDynamicObject(2601, -1964.02, 1364.12, 7.16,   0.00, 0.00, -70.86);
	CreateDynamicObject(2601, -1964.89, 1369.99, 7.35,   0.00, 0.00, 67.80);
	CreateDynamicObject(2601, -1964.66, 1369.85, 7.30,   92.04, -38.88, 96.06);
	CreateDynamicObject(2601, -1964.84, 1369.90, 7.35,   0.00, 0.00, 242.52);
	CreateDynamicObject(2601, -1964.77, 1370.07, 7.35,   0.00, 0.00, 123.48);
	CreateDynamicObject(2601, -1964.63, 1370.04, 7.35,   0.00, 0.00, 123.48);
	CreateDynamicObject(2601, -1964.63, 1370.04, 7.35,   0.00, 0.00, 123.48);
	CreateDynamicObject(2601, -1965.02, 1369.67, 7.35,   0.00, 0.00, 96.06);
	CreateDynamicObject(1543, -1967.98, 1369.68, 7.27,   0.00, 0.00, -107.34);
	CreateDynamicObject(1235, -1963.87, 1369.90, 7.02,   0.00, 0.00, 0.00);
	CreateDynamicObject(2608, -1956.43, 1370.07, 7.85,   0.00, 0.00, 0.00);
	CreateDynamicObject(2608, -1952.58, 1370.08, 7.85,   0.00, 0.00, 0.00);
	CreateDynamicObject(2183, -1948.76, 1366.36, 6.40,   0.00, 0.00, 0.00);
	CreateDynamicObject(2308, -1943.81, 1364.72, 6.32,   0.00, 0.00, 179.64);
	CreateDynamicObject(2174, -1945.95, 1363.75, 6.36,   0.00, 0.00, -180.12);
	CreateDynamicObject(2175, -1950.01, 1363.76, 6.34,   0.00, 0.00, -180.18);
	CreateDynamicObject(2174, -1947.99, 1363.76, 6.36,   0.00, 0.00, -180.12);
	CreateDynamicObject(2190, -1946.75, 1363.55, 7.14,   0.00, 0.00, 151.38);
	CreateDynamicObject(2190, -1943.81, 1363.64, 7.10,   0.00, 0.00, 208.56);
	CreateDynamicObject(2190, -1948.80, 1363.39, 7.14,   0.00, 0.00, 179.28);
	CreateDynamicObject(2190, -1950.82, 1363.53, 7.14,   0.00, 0.00, 157.56);
	CreateDynamicObject(2190, -1946.47, 1366.68, 7.21,   0.00, 0.00, 341.40);
	CreateDynamicObject(2190, -1947.47, 1366.55, 7.21,   0.00, 0.00, 326.88);
	CreateDynamicObject(2190, -1948.19, 1367.29, 7.21,   0.00, 0.00, 185.40);
	CreateDynamicObject(2190, -1947.04, 1367.73, 7.21,   0.00, 0.00, 100.44);
	CreateDynamicObject(2463, -1944.50, 1363.11, 6.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2463, -1946.01, 1363.11, 6.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2463, -1947.51, 1363.11, 6.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2463, -1948.95, 1363.10, 6.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2463, -1950.40, 1363.09, 6.33,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1947.68, 1362.97, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1950.20, 1363.02, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1949.78, 1363.01, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1949.36, 1363.01, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1948.94, 1362.99, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1948.52, 1362.99, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1948.10, 1362.98, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1943.88, 1362.94, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1947.25, 1362.97, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1946.83, 1362.97, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1946.41, 1362.97, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1945.99, 1362.97, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1945.57, 1362.97, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1945.15, 1362.97, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1944.72, 1362.96, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1944.30, 1362.95, 7.80,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1950.62, 1363.02, 7.79,   0.00, 0.00, 0.00);
	CreateDynamicObject(2493, -1947.67, 1362.98, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2493, -1950.62, 1363.02, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2493, -1950.20, 1363.03, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2493, -1949.78, 1363.01, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2493, -1949.36, 1362.98, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2493, -1948.94, 1362.96, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2493, -1948.52, 1362.97, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2493, -1948.10, 1362.99, 7.09,   0.34, 0.00, 0.00);
	CreateDynamicObject(2494, -1947.25, 1362.97, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1946.83, 1362.98, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1946.41, 1362.99, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1945.99, 1362.99, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1945.56, 1363.00, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1945.14, 1362.97, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1943.88, 1362.96, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1944.72, 1362.98, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2494, -1944.30, 1362.96, 7.12,   0.00, 0.00, 0.00);
	CreateDynamicObject(2685, -1950.59, 1370.25, 8.29,   0.00, 0.00, 0.00);
	CreateDynamicObject(2578, -1947.24, 1357.93, 7.44,   0.00, 0.00, -179.10);
	CreateDynamicObject(2579, -1945.86, 1358.12, 7.47,   0.00, 0.00, -163.86);
	CreateDynamicObject(2583, -1944.62, 1358.96, 7.16,   0.00, 0.00, -135.72);
	CreateDynamicObject(2585, -1948.08, 1358.52, 7.38,   0.00, 0.00, 465.06);
	CreateDynamicObject(2596, -1947.67, 1358.27, 10.02,   30.96, -0.18, 145.92);
	CreateDynamicObject(2596, -1966.47, 1358.21, 10.03,   22.80, -1.74, 177.24);
	CreateDynamicObject(2690, -1943.47, 1367.25, 7.96,   0.00, 0.00, -92.76);
	CreateDynamicObject(2961, -1951.18, 1366.98, 8.02,   0.00, 0.00, 89.64);
	CreateDynamicObject(1671, -1944.65, 1364.70, 6.91,   0.00, 0.00, -149.04);
	CreateDynamicObject(1671, -1946.84, 1364.30, 6.91,   0.00, 0.00, -356.34);
	CreateDynamicObject(1671, -1946.37, 1365.72, 6.91,   0.00, 0.00, -198.48);
	CreateDynamicObject(1671, -1947.95, 1365.95, 6.91,   0.00, 0.00, -174.84);
	CreateDynamicObject(1671, -1948.12, 1368.33, 6.91,   0.00, 0.00, -98.88);
	CreateDynamicObject(1671, -1946.09, 1368.27, 6.91,   0.00, 0.00, -53.52);
	CreateDynamicObject(1671, -1948.71, 1364.25, 6.91,   0.00, 0.00, -314.10);
	CreateDynamicObject(1671, -1950.10, 1364.43, 6.91,   0.00, 0.00, -386.88);
	CreateDynamicObject(2690, -1960.60, 1370.16, 7.96,   0.00, 0.00, -4.38);
	CreateDynamicObject(2961, -1959.08, 1368.34, 8.02,   0.00, 0.00, -90.30);
	CreateDynamicObject(2202, -1947.11, 1369.86, 6.47,   0.00, 0.00, 0.36);
	CreateDynamicObject(2197, -1944.49, 1368.83, 6.47,   0.00, 0.00, 0.48);
	CreateDynamicObject(2164, -1943.38, 1368.85, 6.44,   0.00, 0.00, -89.46);
	CreateDynamicObject(1235, -1967.98, 1363.81, 6.99,   0.00, 0.00, 11.64);
	CreateDynamicObject(1235, -1943.86, 1361.85, 6.99,   0.00, 0.00, -20.58);
	CreateDynamicObject(1235, -1943.70, 1366.36, 6.99,   0.00, 0.00, -20.58);
	CreateDynamicObject(2612, -1943.38, 1364.28, 8.89,   0.00, 0.00, -90.06);
	CreateDynamicObject(2611, -1946.48, 1370.25, 8.92,   0.00, 0.00, 0.00);
	CreateDynamicObject(19371, -1944.91, 1363.13, 8.08,   0.00, 0.00, -90.18);
	CreateDynamicObject(19371, -1948.03, 1363.16, 8.08,   0.00, 0.00, -90.18);
	CreateDynamicObject(19371, -1949.81, 1363.17, 8.08,   0.00, 0.00, -90.78);
	CreateDynamicObject(19371, -1949.81, 1363.19, 8.75,   0.00, 0.00, -90.78);
	CreateDynamicObject(19371, -1948.03, 1363.18, 8.77,   0.00, 0.00, -90.18);
	CreateDynamicObject(19371, -1944.90, 1363.15, 8.86,   0.00, 0.00, -90.18);
	CreateDynamicObject(2587, -1949.91, 1363.37, 7.54,   0.00, 0.00, -180.66);
	CreateDynamicObject(322, -1949.65, 1363.45, 7.11,   91.50, 4.44, -209.76);
	CreateDynamicObject(1893, -1954.98, 1369.40, 11.17,   0.12, 0.40, 0.00);
	CreateDynamicObject(1893, -1945.54, 1366.86, 11.17,   0.12, 0.40, 0.00);
	CreateDynamicObject(1893, -1950.07, 1366.85, 11.17,   0.12, 0.40, 0.00);
	CreateDynamicObject(1893, -1947.74, 1366.85, 11.17,   0.12, 0.40, 0.00);
	CreateDynamicObject(2588, -1944.48, 1358.83, 9.96,   0.00, 0.00, -135.30);
	CreateDynamicObject(2587, -1944.48, 1358.82, 8.85,   0.00, 0.00, -134.94);
	CreateDynamicObject(2255, -1947.72, 1358.61, 8.78,   0.00, 0.00, -256.08);
	CreateDynamicObject(2253, -1968.16, 1364.70, 7.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(2253, -1959.60, 1364.70, 7.46,   0.00, 0.00, 0.00);
	CreateDynamicObject(2268, -1950.69, 1366.98, 8.45,   0.00, 0.00, -270.00);
	CreateDynamicObject(2261, -1967.95, 1364.60, 8.96,   0.00, 0.00, 90.00);
	CreateDynamicObject(2264, -1954.49, 1369.15, 8.49,   0.00, 0.00, 180.00);
	CreateDynamicObject(2267, -1947.41, 1363.29, 9.17,   0.00, 0.00, 180.00);
	CreateDynamicObject(1543, -1948.46, 1367.49, 7.20,   0.00, 0.00, 0.00);
	CreateDynamicObject(1543, -1948.54, 1367.39, 7.20,   0.00, 0.00, -45.78);
	CreateDynamicObject(1543, -1948.58, 1367.45, 7.20,   0.00, 0.00, 136.02);
	CreateDynamicObject(1543, -1948.56, 1367.59, 7.23,   -5.88, -89.34, 35.28);
	CreateDynamicObject(2601, -1948.26, 1366.40, 7.28,   0.00, 0.00, 115.14);
	CreateDynamicObject(2894, -1948.79, 1366.51, 7.21,   0.00, 0.00, 27.42);
	CreateDynamicObject(1543, -1950.86, 1364.00, 7.13,   0.00, 0.00, 0.00);
	CreateDynamicObject(2220, -1946.11, 1367.38, 7.28,   -28.32, 24.12, -85.56);
	CreateDynamicObject(2217, -1945.70, 1366.39, 7.25,   -22.32, 24.48, -299.58);
	CreateDynamicObject(2853, -1943.72, 1364.73, 7.11,   0.00, 0.00, -25.38);
	CreateDynamicObject(2580, -1945.96, 1358.07, 9.39,   0.00, 0.00, -165.06);
	CreateDynamicObject(2709, -1950.22, 1363.43, 7.26,   0.00, 0.00, 0.00);
	CreateDynamicObject(2709, -1949.99, 1363.59, 7.18,   1.50, 87.18, -25.98);
	CreateDynamicObject(2256, -1947.43, 1363.03, 9.52,   0.00, 0.00, -0.36);
	CreateDynamicObject(2298, -1985.83, 1338.86, 31.49,   0.00, 0.00, -149.22);
	CreateDynamicObject(2841, -1987.06, 1337.19, 31.49,   0.00, 0.00, 27.30);
	CreateDynamicObject(2854, -1984.05, 1335.72, 32.01,   0.00, 0.00, -152.40);
	CreateDynamicObject(19173, -1985.02, 1334.90, 33.49,   0.00, 0.00, 30.24);
	CreateDynamicObject(640, -1989.72, 1374.46, 32.19,   0.00, 0.00, 90.00);
	CreateDynamicObject(640, -2001.74, 1377.44, 32.19,   0.00, 0.00, 150.00);
	CreateDynamicObject(640, -1989.74, 1348.68, 32.19,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1999.12, 1339.38, 31.49,   0.00, 0.00, -28.14);
	CreateDynamicObject(1703, -1996.12, 1336.56, 31.49,   0.00, 0.00, -89.94);
	CreateDynamicObject(1433, -1998.11, 1336.72, 31.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(2313, -2000.97, 1334.05, 31.49,   0.00, 0.00, 129.12);
	CreateDynamicObject(948, -2000.36, 1333.39, 31.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -2002.44, 1335.72, 31.49,   0.00, 0.00, 0.00);
	CreateDynamicObject(1791, -2001.67, 1334.40, 31.99,   0.00, 0.00, 130.14);
	CreateDynamicObject(1703, -1995.46, 1351.56, 31.49,   0.00, 0.00, 226.08);
	CreateDynamicObject(1703, -2000.32, 1353.23, 31.49,   0.00, 0.00, 46.14);
	CreateDynamicObject(1594, -2000.86, 1363.47, 32.19,   0.00, 0.00, 38.22);
	CreateDynamicObject(1594, -1996.87, 1367.44, 32.19,   0.00, 0.00, -30.00);
	CreateDynamicObject(1594, -2000.27, 1371.24, 32.19,   0.00, 0.00, 21.78);
	CreateDynamicObject(2823, -2000.93, 1363.38, 32.59,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1997.03, 1367.15, 32.59,   0.00, 0.00, 116.04);
	CreateDynamicObject(2823, -1996.91, 1367.50, 32.59,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -2000.44, 1371.00, 32.59,   0.00, 0.00, 126.24);
	CreateDynamicObject(2823, -2000.17, 1371.34, 32.59,   0.00, 0.00, -5.04);
	CreateDynamicObject(1703, -1963.44, 1366.64, 36.95,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1967.23, 1368.44, 36.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1965.35, 1362.87, 36.95,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1969.25, 1364.60, 36.95,   0.00, 0.00, 90.00);
	CreateDynamicObject(1433, -1966.55, 1365.76, 37.13,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1966.77, 1365.77, 37.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1980.57, 1362.46, 36.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1978.67, 1358.45, 36.95,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1982.79, 1354.39, 36.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1985.12, 1350.72, 36.95,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1354.63, 36.95,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1357.49, 36.95,   0.00, 0.00, 90.00);
	CreateDynamicObject(1742, -1986.98, 1356.07, 36.95,   0.00, 0.00, 90.00);
	CreateDynamicObject(2841, -1987.06, 1337.19, 36.95,   0.00, 0.00, 27.30);
	CreateDynamicObject(2298, -1985.83, 1338.86, 36.95,   0.00, 0.00, -149.22);
	CreateDynamicObject(19173, -1985.02, 1334.90, 38.95,   0.00, 0.00, 30.24);
	CreateDynamicObject(2854, -1984.05, 1335.72, 37.48,   0.00, 0.00, -152.40);
	CreateDynamicObject(1703, -1996.12, 1336.56, 36.95,   0.00, 0.00, -89.94);
	CreateDynamicObject(1703, -1999.12, 1339.38, 36.95,   0.00, 0.00, -28.14);
	CreateDynamicObject(1433, -1998.11, 1336.72, 37.17,   0.00, 0.00, 0.00);
	CreateDynamicObject(948, -2000.36, 1333.39, 36.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(1791, -2001.67, 1334.40, 37.45,   0.00, 0.00, 130.14);
	CreateDynamicObject(2313, -2000.97, 1334.05, 36.95,   0.00, 0.00, 129.12);
	CreateDynamicObject(948, -2002.44, 1335.72, 36.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -2001.74, 1377.44, 37.65,   0.00, 0.00, 150.00);
	CreateDynamicObject(1594, -2000.27, 1371.24, 37.65,   0.00, 0.00, 21.78);
	CreateDynamicObject(1594, -1996.87, 1367.44, 37.65,   0.00, 0.00, -30.00);
	CreateDynamicObject(1594, -2000.86, 1363.47, 37.65,   0.00, 0.00, 38.22);
	CreateDynamicObject(640, -1989.74, 1348.68, 37.65,   0.00, 0.00, 90.00);
	CreateDynamicObject(640, -1989.72, 1374.46, 37.65,   0.00, 0.00, 90.00);
	CreateDynamicObject(2823, -1996.91, 1367.50, 38.05,   0.00, 0.00, 0.00);
	CreateDynamicObject(2823, -1997.03, 1367.15, 38.05,   0.00, 0.00, 116.04);
	CreateDynamicObject(2823, -2000.17, 1371.34, 38.05,   0.00, 0.00, -5.04);
	CreateDynamicObject(2823, -2000.44, 1371.00, 38.05,   0.00, 0.00, 126.24);
	CreateDynamicObject(2823, -2000.93, 1363.38, 38.05,   0.00, 0.00, 0.00);
	CreateDynamicObject(2632, -1945.13, 1359.30, 36.95,   0.00, 0.00, 22.50);
	CreateDynamicObject(2630, -1944.97, 1359.29, 36.95,   0.00, 0.00, -69.72);
	CreateDynamicObject(2628, -1942.33, 1360.38, 36.95,   0.00, 0.00, 200.94);
	CreateDynamicObject(2823, -1941.60, 1361.71, 36.97,   0.00, 0.00, 0.00);
	CreateDynamicObject(2629, -1944.44, 1369.48, 36.95,   0.00, 0.00, -24.18);
	CreateDynamicObject(2823, -1943.38, 1368.56, 36.97,   0.00, 0.00, 94.74);
	CreateDynamicObject(1703, -1991.08, 1345.78, 58.77,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1996.71, 1339.26, 58.77,   0.00, 0.00, -58.92);
	CreateDynamicObject(1703, -1998.55, 1335.38, 58.77,   0.00, 0.00, -232.38);
	CreateDynamicObject(1703, -1987.64, 1344.45, 58.77,   0.00, 0.00, -90.86);
	CreateDynamicObject(1703, -1992.56, 1342.48, 58.77,   0.00, 0.00, 90.54);
	CreateDynamicObject(1824, -1989.99, 1343.06, 59.29,   0.00, 0.00, 90.00);
	CreateDynamicObject(1896, -1981.50, 1356.12, 59.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(1724, -1981.04, 1353.09, 58.77,   0.00, 0.00, 180.00);
	CreateDynamicObject(1724, -1979.34, 1354.34, 58.77,   0.00, 0.00, -137.64);
	CreateDynamicObject(1724, -1982.98, 1353.77, 64.23,   0.00, 0.00, 137.64);
	CreateDynamicObject(1724, -1981.04, 1353.09, 64.23,   0.00, 0.00, 180.00);
	CreateDynamicObject(1724, -1979.34, 1354.34, 64.23,   0.00, 0.00, -137.64);
	CreateDynamicObject(1896, -1981.50, 1356.12, 65.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1824, -1989.99, 1343.06, 64.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1991.08, 1345.78, 64.23,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1987.64, 1344.45, 64.23,   0.00, 0.00, -90.86);
	CreateDynamicObject(1703, -1992.56, 1342.48, 64.23,   0.00, 0.00, 90.54);
	CreateDynamicObject(1703, -1996.71, 1339.26, 64.23,   0.00, 0.00, -58.92);
	CreateDynamicObject(1703, -1998.55, 1335.38, 64.23,   0.00, 0.00, -232.38);
	CreateDynamicObject(1724, -1982.98, 1353.77, 53.32,   0.00, 0.00, 137.64);
	CreateDynamicObject(1724, -1981.04, 1353.09, 53.32,   0.00, 0.00, 180.00);
	CreateDynamicObject(1724, -1979.34, 1354.34, 53.32,   0.00, 0.00, -137.64);
	CreateDynamicObject(1896, -1981.50, 1356.12, 54.30,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1987.64, 1344.45, 53.32,   0.00, 0.00, -90.86);
	CreateDynamicObject(1703, -1991.08, 1345.78, 53.32,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1992.56, 1342.48, 53.32,   0.00, 0.00, 90.54);
	CreateDynamicObject(1824, -1989.99, 1343.06, 53.82,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1998.55, 1335.38, 53.32,   0.00, 0.00, -232.38);
	CreateDynamicObject(1703, -1996.71, 1339.26, 53.32,   0.00, 0.00, -58.92);
	CreateDynamicObject(1724, -1986.43, 1350.60, 58.77,   0.00, 0.00, 90.00);
	CreateDynamicObject(1724, -1979.34, 1354.34, 47.85,   0.00, 0.00, -137.64);
	CreateDynamicObject(1724, -1981.04, 1353.09, 47.85,   0.00, 0.00, 180.00);
	CreateDynamicObject(1724, -1982.98, 1353.77, 47.85,   0.00, 0.00, 137.64);
	CreateDynamicObject(1703, -1987.64, 1344.45, 47.85,   0.00, 0.00, -90.86);
	CreateDynamicObject(1703, -1991.08, 1345.78, 47.85,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1992.56, 1342.48, 47.85,   0.00, 0.00, 90.54);
	CreateDynamicObject(1824, -1989.99, 1343.06, 48.36,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1996.71, 1339.26, 47.85,   0.00, 0.00, -58.92);
	CreateDynamicObject(1703, -1998.55, 1335.38, 47.85,   0.00, 0.00, -232.38);
	CreateDynamicObject(1724, -1979.34, 1354.34, 42.39,   0.00, 0.00, -137.64);
	CreateDynamicObject(1724, -1981.04, 1353.09, 42.39,   0.00, 0.00, 180.00);
	CreateDynamicObject(1724, -1982.98, 1353.77, 42.39,   0.00, 0.00, 137.64);
	CreateDynamicObject(1896, -1981.50, 1356.12, 43.38,   0.00, 0.00, 0.00);
	CreateDynamicObject(1896, -1981.50, 1356.12, 48.82,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1987.64, 1344.45, 42.39,   0.00, 0.00, -90.86);
	CreateDynamicObject(1703, -1991.08, 1345.78, 42.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1992.56, 1342.48, 42.39,   0.00, 0.00, 90.54);
	CreateDynamicObject(1703, -1996.71, 1339.26, 42.39,   0.00, 0.00, -58.92);
	CreateDynamicObject(1703, -1998.55, 1335.38, 42.39,   0.00, 0.00, -232.38);
	CreateDynamicObject(1824, -1989.99, 1343.06, 42.91,   0.00, 0.00, 90.00);
	CreateDynamicObject(2131, -1975.62, 1368.44, 36.95,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1977.66, 1368.48, 36.95,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1980.65, 1368.47, 36.95,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1979.65, 1368.47, 36.95,   0.00, 0.00, 180.00);
	CreateDynamicObject(2822, -1979.57, 1368.39, 38.01,   0.00, 0.00, -119.10);
	CreateDynamicObject(2851, -1978.67, 1368.27, 37.87,   0.00, 0.00, 55.92);
	CreateDynamicObject(2631, -1950.28, 1365.41, 53.36,   0.00, 0.00, 90.00);
	CreateDynamicObject(2631, -1950.28, 1365.41, 47.90,   0.00, 0.00, 90.00);
	CreateDynamicObject(2631, -1950.28, 1365.41, 42.44,   0.00, 0.00, 90.00);
	CreateDynamicObject(2631, -1950.28, 1365.41, 58.83,   0.00, 0.00, 90.00);
	CreateDynamicObject(2631, -1950.28, 1365.41, 64.27,   0.00, 0.00, 90.00);
	CreateDynamicObject(2308, -1986.43, 1362.15, 107.66,   0.00, 0.00, 360.00);
	CreateDynamicObject(2200, -1986.67, 1359.94, 107.67,   0.00, 0.00, 90.00);
	CreateDynamicObject(2205, -1986.35, 1358.96, 107.67,   0.00, 0.00, -90.00);
	CreateDynamicObject(2190, -1986.33, 1359.27, 108.60,   0.00, 0.00, 46.80);
	CreateDynamicObject(2238, -1986.68, 1357.36, 109.02,   0.00, 0.00, 0.00);
	CreateDynamicObject(2008, -1984.45, 1363.11, 107.66,   0.00, 0.00, 0.00);
	CreateDynamicObject(2162, -1982.45, 1363.60, 107.66,   0.00, 0.00, 0.00);
	CreateDynamicObject(1714, -1985.13, 1358.58, 107.67,   0.00, 0.00, -54.96);
	CreateDynamicObject(1714, -1984.24, 1362.01, 107.67,   0.00, 0.00, 125.76);
	CreateDynamicObject(2894, -1986.53, 1362.83, 108.45,   0.00, 0.00, 47.40);
	CreateDynamicObject(2894, -1986.31, 1357.97, 108.61,   0.00, 0.00, 115.20);
	CreateDynamicObject(2255, -1986.40, 1358.07, 110.14,   0.00, 0.00, 90.00);
	CreateDynamicObject(18885, -1974.34, 1365.94, 108.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(3525, -1974.59, 1364.53, 110.54,   0.00, 0.00, 90.00);
	CreateDynamicObject(3525, -1974.59, 1367.25, 110.54,   0.00, 0.00, 90.00);
	CreateDynamicObject(358, -2000.21, 1332.81, 107.96,   -14.28, -98.56, 347.52);
	CreateDynamicObject(2566, -1998.89, 1334.64, 108.05,   0.00, 0.00, 129.84);
	CreateDynamicObject(1744, -2001.58, 1333.72, 109.48,   0.00, 0.00, 129.84);
	CreateDynamicObject(356, -2001.60, 1334.23, 109.88,   -103.06, -7.68, -75.48);
	CreateDynamicObject(348, -2000.28, 1333.38, 108.10,   90.00, 0.00, -106.68);
	CreateDynamicObject(3052, -2002.93, 1336.32, 107.78,   0.00, 0.00, -4.32);
	CreateDynamicObject(2043, -2002.29, 1336.04, 107.77,   0.00, 0.00, 73.86);
	CreateDynamicObject(351, -2002.62, 1336.18, 107.96,   -101.32, -13.28, 126.96);
	CreateDynamicObject(1704, -2001.30, 1342.06, 107.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(1704, -2002.65, 1339.78, 107.67,   0.00, 0.00, 90.00);
	CreateDynamicObject(1704, -2000.33, 1338.59, 107.67,   0.00, 0.00, -180.00);
	CreateDynamicObject(1433, -2000.76, 1340.29, 107.87,   0.00, 0.00, 0.00);
	CreateDynamicObject(348, -2001.11, 1340.11, 108.39,   90.00, 0.00, 55.86);
	CreateDynamicObject(348, -2000.66, 1339.84, 108.39,   90.00, 0.00, 56.10);
	CreateDynamicObject(348, -2000.79, 1340.73, 108.39,   90.00, 0.00, -27.66);
	CreateDynamicObject(2254, -2001.74, 1334.25, 111.25,   0.00, 0.00, 129.96);
	CreateDynamicObject(2208, -1997.86, 1365.24, 107.66,   0.00, 0.00, 90.00);
	CreateDynamicObject(2208, -1997.86, 1358.88, 107.66,   0.00, 0.00, 90.00);
	CreateDynamicObject(1722, -1997.98, 1363.72, 107.67,   0.00, 0.00, -9.90);
	CreateDynamicObject(1722, -1996.46, 1365.90, 107.67,   0.00, 0.00, 124.80);
	CreateDynamicObject(1722, -1996.74, 1367.09, 107.67,   0.00, 0.00, 70.08);
	CreateDynamicObject(1722, -1999.42, 1365.79, 107.67,   0.00, 0.00, 281.34);
	CreateDynamicObject(1722, -1999.31, 1367.44, 107.67,   0.00, 0.00, 247.44);
	CreateDynamicObject(1722, -1997.82, 1369.06, 107.67,   0.00, 0.00, -209.58);
	CreateDynamicObject(2212, -1997.87, 1365.52, 108.58,   -25.50, 23.52, 27.24);
	CreateDynamicObject(2212, -1997.82, 1366.56, 108.58,   -25.50, 23.52, -173.82);
	CreateDynamicObject(2212, -1998.13, 1367.60, 108.58,   -25.50, 23.52, -89.94);
	CreateDynamicObject(2894, -1997.94, 1365.12, 108.53,   0.00, 0.00, -25.74);
	CreateDynamicObject(2894, -1997.64, 1366.97, 108.53,   0.00, 0.00, 131.10);
	CreateDynamicObject(3525, -1992.82, 1367.71, 110.27,   0.00, 0.00, -90.00);
	CreateDynamicObject(3525, -1992.82, 1363.79, 110.27,   0.00, 0.00, -90.00);
	CreateDynamicObject(3525, -1992.82, 1358.33, 110.27,   0.00, 0.00, -90.00);
	CreateDynamicObject(3525, -1992.82, 1353.98, 110.27,   0.00, 0.00, -90.00);
	CreateDynamicObject(1704, -1999.30, 1361.34, 107.67,   0.00, 0.00, 60.66);
	CreateDynamicObject(1704, -1995.89, 1360.74, 107.67,   0.00, 0.00, 283.80);
	CreateDynamicObject(1704, -1998.76, 1357.90, 107.67,   0.00, 0.00, 492.60);
	CreateDynamicObject(348, -1997.90, 1361.50, 108.53,   90.00, 0.00, -125.46);
	CreateDynamicObject(348, -1997.63, 1359.04, 108.53,   90.00, 0.00, 121.44);
	CreateDynamicObject(1703, -1999.96, 1353.30, 107.66,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1997.91, 1349.26, 107.66,   0.00, 0.00, 178.62);
	CreateDynamicObject(1703, -2001.70, 1350.33, 107.66,   0.00, 0.00, 88.86);
	CreateDynamicObject(1670, -1998.03, 1358.76, 108.54,   0.00, 0.00, 139.98);
	CreateDynamicObject(1670, -1998.03, 1361.23, 108.54,   0.00, 0.00, -39.78);
	CreateDynamicObject(1549, -1999.68, 1358.93, 107.67,   0.00, 0.00, 192.36);
	CreateDynamicObject(1549, -1999.67, 1361.00, 107.67,   0.00, 0.00, 239.52);
	CreateDynamicObject(2894, -1997.77, 1360.52, 108.53,   0.00, 0.00, 63.96);
	CreateDynamicObject(2894, -1997.88, 1359.77, 108.53,   0.00, 0.00, 133.68);
	CreateDynamicObject(2229, -1982.60, 1336.45, 107.66,   0.00, 0.00, 218.64);
	CreateDynamicObject(2229, -1982.96, 1336.15, 107.66,   0.00, 0.00, 218.64);
	CreateDynamicObject(2311, -1984.79, 1335.27, 107.66,   0.00, 0.00, 31.02);
	CreateDynamicObject(2311, -1986.84, 1334.06, 107.66,   0.00, 0.00, 31.02);
	CreateDynamicObject(2232, -1983.76, 1335.94, 108.75,   0.00, 0.00, 247.50);
	CreateDynamicObject(2232, -1986.48, 1334.29, 108.75,   0.00, 0.00, 165.12);
	CreateDynamicObject(2188, -1966.55, 1371.40, 108.63,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1963.01, 1370.97, 107.66,   0.00, 0.00, 229.86);
	CreateDynamicObject(1703, -1965.69, 1368.43, 107.66,   0.00, 0.00, 178.68);
	CreateDynamicObject(1703, -1968.87, 1369.43, 107.66,   0.00, 0.00, 120.78);
	CreateDynamicObject(1722, -1966.01, 1372.90, 107.67,   0.00, 0.00, -200.64);
	CreateDynamicObject(1824, -1966.84, 1363.35, 108.19,   0.00, 0.00, 0.06);
	CreateDynamicObject(1703, -1967.87, 1365.66, 107.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1970.33, 1362.41, 107.67,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1963.49, 1364.40, 107.67,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1965.71, 1360.89, 107.67,   0.00, 0.00, 180.00);
	CreateDynamicObject(2393, -1982.78, 1378.14, 110.41,   0.00, 90.00, 180.00);
	CreateDynamicObject(1985, -1984.14, 1378.39, 110.62,   0.00, 0.00, 0.00);
	CreateDynamicObject(2631, -1989.64, 1374.85, 107.66,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -2001.65, 1377.50, 108.36,   0.00, 0.00, -28.26);
	CreateDynamicObject(2628, -1989.47, 1374.61, 107.70,   0.00, 0.00, 180.00);
	CreateDynamicObject(2629, -1990.97, 1374.65, 107.69,   0.00, 0.00, 180.00);
	CreateDynamicObject(2255, -1990.02, 1374.34, 110.42,   0.00, 0.00, 180.00);
	CreateDynamicObject(2258, -2001.95, 1377.90, 111.09,   0.00, 0.00, 60.00);
	CreateDynamicObject(2131, -1981.52, 1368.47, 107.67,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1978.54, 1368.48, 107.67,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1983.57, 1368.42, 107.67,   0.00, 0.00, 180.58);
	CreateDynamicObject(2131, -1985.64, 1368.57, 107.67,   0.00, 0.00, 493.98);
	CreateDynamicObject(2134, -1980.54, 1368.48, 107.67,   0.00, 0.00, 180.58);
	CreateDynamicObject(2256, -1976.32, 1368.00, 110.64,   0.00, 0.00, 180.00);
	CreateDynamicObject(1302, -1980.97, 1374.00, 107.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(1302, -1975.62, 1373.98, 107.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(2862, -1978.55, 1368.40, 108.72,   0.00, 0.00, 166.98);
	CreateDynamicObject(2862, -1980.50, 1368.43, 108.72,   0.00, 0.00, 166.98);
	CreateDynamicObject(1776, -1978.22, 1373.86, 108.76,   0.00, 0.00, 0.00);
	CreateDynamicObject(1714, -1941.39, 1365.19, 107.67,   0.00, 0.00, -61.62);
	CreateDynamicObject(2208, -1942.70, 1363.31, 107.67,   0.00, 0.00, 90.00);
	CreateDynamicObject(2816, -1942.81, 1365.67, 108.53,   0.00, 0.00, -117.72);
	CreateDynamicObject(2855, -1942.66, 1363.31, 108.53,   0.00, 0.00, 127.02);
	CreateDynamicObject(2894, -1942.57, 1365.01, 108.53,   0.00, 0.00, 77.04);
	CreateDynamicObject(2894, -1942.87, 1364.19, 108.53,   0.00, 0.00, 304.26);
	CreateDynamicObject(2202, -1943.35, 1369.80, 107.67,   0.00, 0.00, -26.64);
	CreateDynamicObject(2202, -1943.08, 1359.80, 107.67,   0.00, 0.00, 202.08);
	CreateDynamicObject(1704, -1944.54, 1365.18, 107.67,   0.00, 0.00, 52.92);
	CreateDynamicObject(1704, -1944.18, 1363.28, 107.67,   0.00, 0.00, 115.38);
	CreateDynamicObject(3525, -1947.03, 1362.21, 110.61,   0.00, 0.00, 180.00);
	CreateDynamicObject(3525, -1947.03, 1368.63, 110.61,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1948.57, 1362.87, 107.67,   0.00, 0.00, 109.56);
	CreateDynamicObject(1703, -1949.32, 1366.37, 107.67,   0.00, 0.00, 63.66);
	CreateDynamicObject(1433, -1946.94, 1364.94, 107.85,   0.00, 0.00, 0.00);
	CreateDynamicObject(2855, -1946.71, 1364.68, 108.36,   0.00, 0.00, 126.36);
	CreateDynamicObject(2853, -1947.04, 1365.16, 108.36,   0.00, 0.00, 39.30);
	CreateDynamicObject(2229, -1987.64, 1333.55, 107.66,   0.00, 0.00, 218.64);
	CreateDynamicObject(2229, -1988.03, 1333.33, 107.66,   0.00, 0.00, 218.64);
	CreateDynamicObject(2104, -1984.84, 1335.15, 108.16,   0.00, 0.00, 215.34);
	CreateDynamicObject(2101, -1985.62, 1334.98, 108.17,   0.00, 0.00, 207.36);
	CreateDynamicObject(1703, -1985.83, 1340.33, 107.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1990.50, 1335.49, 107.67,   0.00, 0.00, 68.64);
	CreateDynamicObject(1703, -1989.00, 1338.77, 107.67,   0.00, 0.00, 36.54);
	CreateDynamicObject(1703, -1990.82, 1347.21, 107.67,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1992.50, 1344.10, 107.67,   0.00, 0.00, 88.68);
	CreateDynamicObject(1703, -1988.78, 1342.70, 107.67,   0.00, 0.00, 176.40);
	CreateDynamicObject(1433, -1989.92, 1345.10, 107.84,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1990.01, 1345.10, 108.37,   0.00, 0.00, 93.30);
	CreateDynamicObject(640, -1989.75, 1348.54, 108.36,   0.00, 0.00, 90.00);
	CreateDynamicObject(640, -1994.67, 1332.88, 108.36,   0.00, 0.00, 90.00);
	CreateDynamicObject(1704, -1982.67, 1354.83, 107.66,   0.00, 0.00, 0.00);
	CreateDynamicObject(1704, -1983.16, 1351.72, 107.66,   0.00, 0.00, 146.52);
	CreateDynamicObject(1704, -1980.90, 1352.38, 107.66,   0.00, 0.00, 225.90);
	CreateDynamicObject(1433, -1982.23, 1353.13, 107.84,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1982.15, 1353.13, 108.37,   0.00, 0.00, 59.76);
	CreateDynamicObject(1704, -1978.03, 1360.99, 107.66,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1977.39, 1358.74, 107.84,   0.00, 0.00, 0.00);
	CreateDynamicObject(1704, -1978.22, 1356.72, 107.66,   0.00, 0.00, 146.52);
	CreateDynamicObject(1704, -1975.35, 1357.74, 107.66,   0.00, 0.00, 225.90);
	CreateDynamicObject(1670, -1977.35, 1358.70, 108.37,   0.00, 0.00, 136.26);
	CreateDynamicObject(1704, -1982.72, 1351.40, 113.12,   0.00, 0.00, 151.56);
	CreateDynamicObject(1704, -1980.48, 1353.00, 113.12,   0.00, 0.00, 251.46);
	CreateDynamicObject(1704, -1983.25, 1354.62, 113.12,   0.00, 0.00, 14.58);
	CreateDynamicObject(1433, -1982.23, 1353.13, 113.30,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1982.15, 1353.13, 113.82,   0.00, 0.00, 59.76);
	CreateDynamicObject(1704, -1978.41, 1357.40, 113.12,   0.00, 0.00, 117.60);
	CreateDynamicObject(1704, -1975.65, 1358.17, 113.12,   0.00, 0.00, 242.88);
	CreateDynamicObject(1433, -1977.39, 1358.74, 113.30,   0.00, 0.00, 0.00);
	CreateDynamicObject(1704, -1977.52, 1360.67, 113.12,   0.00, 0.00, -19.62);
	CreateDynamicObject(1670, -1977.35, 1358.70, 113.78,   0.00, 0.00, 136.26);
	CreateDynamicObject(2611, -1986.85, 1362.54, 109.69,   0.00, 0.00, 90.00);
	CreateDynamicObject(1704, -1975.44, 1358.99, 96.75,   0.00, 0.00, 261.00);
	CreateDynamicObject(1704, -1978.59, 1357.60, 96.75,   0.00, 0.00, 124.98);
	CreateDynamicObject(1704, -1976.83, 1360.51, 96.75,   0.00, 0.00, -24.30);
	CreateDynamicObject(1433, -1977.39, 1358.74, 96.93,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1977.36, 1358.74, 97.45,   0.00, 0.00, 237.12);
	CreateDynamicObject(1704, -1981.83, 1354.65, 96.75,   0.00, 0.00, -25.14);
	CreateDynamicObject(1704, -1983.87, 1353.13, 96.75,   0.00, 0.00, 73.80);
	CreateDynamicObject(1704, -1981.27, 1351.85, 96.75,   0.00, 0.00, 206.22);
	CreateDynamicObject(1670, -1982.29, 1353.11, 97.47,   0.00, 0.00, 172.74);
	CreateDynamicObject(1433, -1982.23, 1353.13, 96.93,   0.00, 0.00, 0.00);
	CreateDynamicObject(2010, -1986.25, 1350.78, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2164, -1986.86, 1357.72, 96.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(2164, -1986.86, 1359.48, 96.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(2167, -1986.89, 1361.27, 96.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(2779, -1978.08, 1363.20, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2778, -1979.64, 1363.11, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2779, -1981.25, 1363.27, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2640, -1982.60, 1363.37, 97.59,   0.00, 0.00, 0.00);
	CreateDynamicObject(2172, -1984.52, 1363.18, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(1714, -1983.82, 1362.37, 96.75,   0.00, 0.00, -128.94);
	CreateDynamicObject(1714, -1985.96, 1362.26, 96.75,   0.00, 0.00, -244.98);
	CreateDynamicObject(2193, -1986.50, 1362.18, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2611, -1986.85, 1362.54, 98.76,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1987.78, 1346.06, 96.75,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1991.17, 1347.44, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1989.27, 1342.69, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1987.28, 1341.18, 96.75,   0.00, 0.00, 1.86);
	CreateDynamicObject(1703, -1990.57, 1337.95, 96.75,   0.00, 0.00, 63.06);
	CreateDynamicObject(2229, -1983.23, 1336.20, 96.75,   0.00, 0.00, 209.22);
	CreateDynamicObject(19175, -1985.24, 1334.66, 99.33,   0.00, 0.00, 211.14);
	CreateDynamicObject(1433, -1987.46, 1338.98, 96.95,   0.00, 0.00, 0.00);
	CreateDynamicObject(1670, -1987.36, 1338.89, 97.47,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1992.64, 1344.11, 96.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(1575, -1989.83, 1344.81, 97.27,   0.02, 0.00, 73.08);
	CreateDynamicObject(2823, -1990.43, 1345.27, 97.27,   0.00, 0.00, 29.10);
	CreateDynamicObject(2823, -1989.89, 1345.36, 97.28,   0.00, 0.00, -148.74);
	CreateDynamicObject(2823, -1990.25, 1344.85, 97.29,   0.00, 0.00, -61.68);
	CreateDynamicObject(1433, -1990.18, 1345.01, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -1989.48, 1348.61, 97.44,   0.00, 0.00, 90.00);
	CreateDynamicObject(2011, -1993.07, 1349.38, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -1993.06, 1352.56, 97.44,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -1993.06, 1358.74, 97.44,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1996.41, 1351.42, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1999.57, 1352.52, 96.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1998.37, 1355.36, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1997.46, 1353.25, 96.93,   0.00, 0.00, 0.00);
	CreateDynamicObject(1575, -1997.65, 1352.94, 97.43,   0.00, 0.00, 80.34);
	CreateDynamicObject(1575, -1997.65, 1352.94, 97.59,   0.00, 0.00, 52.20);
	CreateDynamicObject(1575, -1997.73, 1353.47, 97.43,   0.00, 0.00, -64.26);
	CreateDynamicObject(1575, -1997.22, 1353.52, 97.61,   0.00, 0.00, 25.26);
	CreateDynamicObject(1575, -1997.22, 1353.52, 97.43,   0.00, 0.00, -47.04);
	CreateDynamicObject(3525, -1997.72, 1356.70, 98.73,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -1993.06, 1365.02, 97.44,   0.00, 0.00, 0.00);
	CreateDynamicObject(640, -1993.06, 1370.99, 97.44,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1998.90, 1363.91, 96.75,   0.00, 0.00, 131.10);
	CreateDynamicObject(1703, -2000.51, 1366.81, 96.75,   0.00, 0.00, 401.04);
	CreateDynamicObject(1703, -1995.44, 1364.70, 96.75,   0.00, 0.00, 580.74);
	CreateDynamicObject(1703, -1997.26, 1367.84, 96.75,   0.00, 0.00, -47.52);
	CreateDynamicObject(1670, -1999.59, 1366.31, 96.75,   0.00, 0.00, -84.42);
	CreateDynamicObject(1433, -1998.02, 1365.71, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2860, -1997.90, 1365.70, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2259, -1993.16, 1367.70, 98.81,   0.00, 0.00, -90.00);
	CreateDynamicObject(2258, -1992.64, 1361.92, 99.02,   0.00, 0.00, -90.00);
	CreateDynamicObject(2259, -1993.16, 1356.74, 98.82,   0.00, 0.00, -90.00);
	CreateDynamicObject(640, -2001.65, 1377.50, 97.44,   0.00, 0.00, -28.26);
	CreateDynamicObject(2393, -1982.78, 1378.14, 99.73,   0.00, 90.00, 180.00);
	CreateDynamicObject(1985, -1984.14, 1378.39, 99.98,   0.00, 0.00, 0.00);
	CreateDynamicObject(2628, -1989.07, 1374.61, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(2632, -1989.92, 1374.80, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(2629, -1990.97, 1374.65, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1961.32, 1364.54, 96.75,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1962.80, 1367.45, 96.75,   0.00, 0.00, -55.50);
	CreateDynamicObject(1703, -1965.73, 1368.87, 96.75,   0.00, 0.00, -18.66);
	CreateDynamicObject(1703, -1969.06, 1368.86, 96.75,   0.00, 0.00, 3.36);
	CreateDynamicObject(2857, -1963.43, 1364.65, 96.75,   0.00, 0.00, 27.66);
	CreateDynamicObject(2857, -1966.18, 1367.10, 96.75,   0.00, 0.00, 105.84);
	CreateDynamicObject(2857, -1968.18, 1365.87, 96.75,   0.00, 0.00, 116.76);
	CreateDynamicObject(338, -1966.93, 1364.50, 97.69,   74.00, -78.30, -74.46);
	CreateDynamicObject(1209, -1981.11, 1368.30, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(2132, -1982.57, 1368.36, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1984.60, 1368.39, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(2133, -1985.59, 1368.39, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(2341, -1986.59, 1368.37, 96.75,   0.00, 0.00, 180.00);
	CreateDynamicObject(2340, -1986.60, 1369.36, 97.44,   0.00, 0.00, 90.00);
	CreateDynamicObject(2131, -1986.34, 1370.39, 96.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(2340, -1986.58, 1372.45, 96.75,   0.00, 0.00, 90.00);
	CreateDynamicObject(2822, -1984.56, 1368.24, 97.44,   0.00, 0.00, 95.40);
	CreateDynamicObject(2851, -1982.90, 1368.28, 97.44,   0.00, 0.00, -99.48);
	CreateDynamicObject(2851, -1983.60, 1368.26, 97.44,   0.00, 0.00, -99.48);
	CreateDynamicObject(19128, -1946.89, 1365.34, 96.75,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1943.00, 1362.49, 96.75,   0.00, 0.00, -146.46);
	CreateDynamicObject(1703, -1942.08, 1366.20, 96.75,   0.00, 0.00, -89.34);
	CreateDynamicObject(1703, -1944.58, 1369.08, 96.75,   0.00, 0.00, -45.84);
	CreateDynamicObject(2256, -1942.57, 1369.91, 99.41,   0.00, 0.00, -26.70);
	CreateDynamicObject(2256, -1943.43, 1359.06, 99.41,   0.00, 0.00, -157.26);
	CreateDynamicObject(3525, -1947.10, 1368.65, 99.41,   0.00, 0.00, 0.00);
	CreateDynamicObject(3525, -1947.06, 1362.17, 99.41,   0.00, 0.00, 180.00);
	CreateDynamicObject(2315, -1985.02, 1335.34, 96.75,   0.00, 0.00, 30.90);
	CreateDynamicObject(2315, -1987.09, 1334.09, 96.75,   0.00, 0.00, 30.90);
	CreateDynamicObject(2232, -1986.95, 1334.18, 97.83,   0.00, 0.00, 214.08);
	CreateDynamicObject(2232, -1983.70, 1336.02, 97.83,   0.00, 0.00, 214.08);
	CreateDynamicObject(2229, -1987.91, 1333.41, 96.75,   0.00, 0.00, 209.22);
	CreateDynamicObject(1786, -1985.78, 1334.54, 97.23,   0.00, 0.00, 211.44);
	CreateDynamicObject(1786, -1984.46, 1335.38, 97.23,   0.00, 0.00, 211.44);
	CreateDynamicObject(3525, -1982.82, 1336.32, 99.27,   0.00, 0.00, 211.14);
	CreateDynamicObject(3525, -1987.59, 1333.50, 99.27,   0.00, 0.00, 211.14);
	CreateDynamicObject(2842, -2000.19, 1336.51, 96.73,   0.00, 0.00, -52.50);
	CreateDynamicObject(2286, -2002.06, 1377.77, 99.62,   0.00, 0.00, 60.78);
	CreateDynamicObject(1704, -1980.90, 1352.38, 102.21,   0.00, 0.00, 225.90);
	CreateDynamicObject(1704, -1983.16, 1351.72, 102.21,   0.00, 0.00, 146.52);
	CreateDynamicObject(1704, -1982.67, 1354.83, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1704, -1978.22, 1356.72, 102.21,   0.00, 0.00, 146.52);
	CreateDynamicObject(1704, -1975.35, 1357.74, 102.21,   0.00, 0.00, 225.90);
	CreateDynamicObject(1433, -1977.39, 1358.74, 102.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(1704, -1978.03, 1360.99, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(18885, -1974.34, 1365.94, 103.31,   0.00, 0.00, 90.00);
	CreateDynamicObject(3525, -1974.59, 1364.53, 105.10,   0.00, 0.00, 90.00);
	CreateDynamicObject(3525, -1974.59, 1367.25, 105.10,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1970.33, 1362.41, 102.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(1703, -1968.87, 1369.43, 102.21,   0.00, 0.00, 120.78);
	CreateDynamicObject(1824, -1966.84, 1363.35, 102.74,   0.00, 0.00, 0.06);
	CreateDynamicObject(1703, -1965.71, 1360.89, 102.21,   0.00, 0.00, 180.00);
	CreateDynamicObject(1703, -1963.49, 1364.40, 102.21,   0.00, 0.00, -90.00);
	CreateDynamicObject(1703, -1967.87, 1365.66, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1963.01, 1370.97, 102.21,   0.00, 0.00, 229.86);
	CreateDynamicObject(1703, -1965.69, 1368.43, 102.21,   0.00, 0.00, 178.68);
	CreateDynamicObject(2188, -1966.55, 1371.40, 103.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1722, -1966.01, 1372.90, 102.21,   0.00, 0.00, -200.64);
	CreateDynamicObject(1302, -1975.62, 1373.98, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1776, -1978.22, 1373.86, 103.30,   0.00, 0.00, 0.00);
	CreateDynamicObject(1302, -1980.97, 1374.00, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2631, -1989.64, 1374.85, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2202, -1943.35, 1369.80, 102.21,   0.00, 0.00, -26.64);
	CreateDynamicObject(1703, -1949.32, 1366.37, 102.21,   0.00, 0.00, 63.66);
	CreateDynamicObject(2202, -1943.08, 1359.80, 102.21,   0.00, 0.00, 202.08);
	CreateDynamicObject(1703, -1948.57, 1362.87, 102.21,   0.00, 0.00, 109.56);
	CreateDynamicObject(1433, -1946.94, 1364.94, 102.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(2853, -1947.04, 1365.16, 102.90,   0.00, 0.00, 39.30);
	CreateDynamicObject(2855, -1946.71, 1364.68, 102.90,   0.00, 0.00, 126.36);
	CreateDynamicObject(1704, -1944.18, 1363.28, 102.21,   0.00, 0.00, 115.38);
	CreateDynamicObject(1704, -1944.54, 1365.18, 102.21,   0.00, 0.00, 52.92);
	CreateDynamicObject(2208, -1942.70, 1363.31, 102.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(2894, -1942.57, 1365.01, 103.07,   0.00, 0.00, 77.04);
	CreateDynamicObject(2894, -1942.87, 1364.19, 103.07,   0.00, 0.00, 304.26);
	CreateDynamicObject(2855, -1942.66, 1363.31, 103.07,   0.00, 0.00, 127.02);
	CreateDynamicObject(2816, -1942.81, 1365.67, 103.07,   0.00, 0.00, -117.72);
	CreateDynamicObject(1714, -1941.39, 1365.19, 102.21,   0.00, 0.00, -61.62);
	CreateDynamicObject(3525, -1947.03, 1362.21, 105.05,   0.00, 0.00, 180.00);
	CreateDynamicObject(3525, -1947.03, 1368.63, 105.05,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1982.23, 1353.13, 102.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(2200, -1986.67, 1359.94, 102.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(2205, -1986.35, 1358.96, 102.21,   0.00, 0.00, -90.00);
	CreateDynamicObject(2162, -1982.45, 1363.60, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2008, -1984.45, 1363.11, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(2308, -1986.43, 1362.15, 102.21,   0.00, 0.00, 360.00);
	CreateDynamicObject(2255, -1986.40, 1358.07, 104.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(2611, -1986.85, 1362.54, 104.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(2894, -1986.53, 1362.83, 103.00,   0.00, 0.00, 47.40);
	CreateDynamicObject(1714, -1984.24, 1362.01, 102.21,   0.00, 0.00, 125.76);
	CreateDynamicObject(1714, -1985.13, 1358.58, 102.21,   0.00, 0.00, -54.96);
	CreateDynamicObject(2190, -1986.33, 1359.27, 103.15,   0.00, 0.00, 46.80);
	CreateDynamicObject(1433, -2000.76, 1340.29, 102.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(1433, -1989.92, 1345.10, 102.39,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1990.82, 1347.21, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1992.50, 1344.10, 102.21,   0.00, 0.00, 88.68);
	CreateDynamicObject(1703, -1988.80, 1342.68, 102.21,   0.00, 0.00, 176.40);
	CreateDynamicObject(1703, -1985.83, 1340.33, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1703, -1990.50, 1335.49, 102.21,   0.00, 0.00, 68.64);
	CreateDynamicObject(1703, -1989.00, 1338.77, 102.21,   0.00, 0.00, 36.54);
	CreateDynamicObject(2229, -1982.60, 1336.45, 102.21,   0.00, 0.00, 218.64);
	CreateDynamicObject(2229, -1982.96, 1336.15, 102.21,   0.00, 0.00, 218.64);
	CreateDynamicObject(2311, -1984.79, 1335.27, 102.21,   0.00, 0.00, 31.02);
	CreateDynamicObject(2229, -1987.64, 1333.55, 102.21,   0.00, 0.00, 218.64);
	CreateDynamicObject(2229, -1988.03, 1333.33, 102.21,   0.00, 0.00, 218.64);
	CreateDynamicObject(2232, -1986.48, 1334.29, 103.31,   0.00, 0.00, 165.12);
	CreateDynamicObject(2101, -1985.62, 1334.98, 102.73,   0.00, 0.00, 207.36);
	CreateDynamicObject(2104, -1984.84, 1335.15, 102.71,   0.00, 0.00, 215.34);
	CreateDynamicObject(2232, -1983.76, 1335.94, 103.31,   0.00, 0.00, 247.50);
	CreateDynamicObject(640, -1994.67, 1332.88, 102.91,   0.00, 0.00, 90.00);
	CreateDynamicObject(358, -2000.19, 1332.81, 102.21,   -14.28, -98.56, 347.52);
	CreateDynamicObject(2566, -1998.89, 1334.64, 102.61,   0.00, 0.00, 129.84);
	CreateDynamicObject(1744, -2001.58, 1333.72, 103.97,   0.00, 0.00, 129.84);
	CreateDynamicObject(2254, -2001.74, 1334.25, 105.73,   0.00, 0.00, 129.96);
	CreateDynamicObject(348, -2000.28, 1333.38, 102.66,   90.00, 0.00, -106.68);
	CreateDynamicObject(1704, -2002.65, 1339.78, 102.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(1704, -2000.33, 1338.59, 102.21,   0.00, 0.00, -180.00);
	CreateDynamicObject(1704, -2001.30, 1342.06, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(348, -2001.11, 1340.11, 102.91,   90.00, 0.00, 55.86);
	CreateDynamicObject(348, -2000.66, 1339.84, 102.91,   90.00, 0.00, 56.10);
	CreateDynamicObject(348, -2000.79, 1340.73, 102.91,   90.00, 0.00, -27.66);
	CreateDynamicObject(1703, -1997.91, 1349.26, 102.21,   0.00, 0.00, 178.62);
	CreateDynamicObject(1703, -2001.70, 1350.33, 102.21,   0.00, 0.00, 88.86);
	CreateDynamicObject(1703, -1999.96, 1353.30, 102.21,   0.00, 0.00, 0.00);
	CreateDynamicObject(1704, -1998.76, 1357.90, 102.21,   0.00, 0.00, 492.60);
	CreateDynamicObject(1704, -1995.89, 1360.74, 102.21,   0.00, 0.00, 283.80);
	CreateDynamicObject(1704, -1999.30, 1361.34, 102.21,   0.00, 0.00, 60.66);
	CreateDynamicObject(1549, -1999.68, 1358.93, 102.21,   0.00, 0.00, 192.36);
	CreateDynamicObject(1549, -1999.67, 1361.00, 102.21,   0.00, 0.00, 239.52);
	CreateDynamicObject(2208, -1997.86, 1358.88, 102.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(3525, -1997.72, 1357.50, 105.02,   0.00, 0.00, 180.00);
	CreateDynamicObject(3525, -1992.82, 1363.79, 105.02,   0.00, 0.00, -90.00);
	CreateDynamicObject(3525, -1992.82, 1358.33, 105.02,   0.00, 0.00, -90.00);
	CreateDynamicObject(3525, -1992.82, 1353.98, 105.02,   0.00, 0.00, -90.00);
	CreateDynamicObject(3525, -1992.82, 1367.71, 105.02,   0.00, 0.00, -90.00);
	CreateDynamicObject(2208, -1997.86, 1365.24, 102.21,   0.00, 0.00, 90.00);
	CreateDynamicObject(1722, -1998.04, 1363.90, 102.21,   0.00, 0.00, -9.90);
	CreateDynamicObject(1722, -1999.42, 1365.79, 102.21,   0.00, 0.00, 281.34);
	CreateDynamicObject(1722, -1999.31, 1367.44, 102.21,   0.00, 0.00, 247.44);
	CreateDynamicObject(1722, -1997.82, 1369.06, 102.21,   0.00, 0.00, -209.58);
	CreateDynamicObject(1722, -1996.46, 1365.90, 102.21,   0.00, 0.00, 124.80);
	CreateDynamicObject(1722, -1996.74, 1367.09, 102.21,   0.00, 0.00, 70.08);
	CreateDynamicObject(2894, -1997.93, 1365.16, 103.07,   0.00, 0.00, -25.74);
	CreateDynamicObject(2212, -1997.72, 1365.80, 103.13,   -25.50, 23.52, 27.24);
	CreateDynamicObject(2894, -1997.64, 1366.97, 10.21,   0.00, 0.00, 131.10);
	CreateDynamicObject(2894, -1997.64, 1366.97, 103.07,   0.00, 0.00, 131.10);
	CreateDynamicObject(2212, -1998.13, 1367.60, 103.13,   -25.50, 23.52, -89.94);
	CreateDynamicObject(2255, -1990.02, 1374.34, 104.86,   0.00, 0.00, 180.00);
	CreateDynamicObject(2134, -1983.57, 1368.42, 102.21,   0.00, 0.00, 180.58);
	CreateDynamicObject(2131, -1981.52, 1368.47, 102.21,   0.00, 0.00, 180.00);
	CreateDynamicObject(2131, -1985.46, 1368.63, 102.21,   0.00, 0.00, 493.98);
	CreateDynamicObject(2134, -1980.54, 1368.48, 102.21,   0.00, 0.00, 180.58);
	CreateDynamicObject(2132, -1978.54, 1368.48, 102.21,   0.00, 0.00, 180.00);
	CreateDynamicObject(2862, -1978.55, 1368.40, 103.27,   0.00, 0.00, 166.98);
	CreateDynamicObject(2862, -1980.50, 1368.43, 103.25,   0.00, 0.00, 166.98);
	CreateDynamicObject(2256, -1976.32, 1368.00, 104.96,   0.00, 0.00, 180.00);
	CreateDynamicObject(1670, -1977.35, 1358.70, 102.91,   0.00, 0.00, 136.26);
	CreateDynamicObject(1670, -1982.15, 1353.13, 102.91,   0.00, 0.00, 59.76);
	CreateDynamicObject(1670, -1990.01, 1345.10, 102.91,   0.00, 0.00, 93.30);
	CreateDynamicObject(2311, -1986.84, 1334.06, 102.21,   0.00, 0.00, 31.02);
	CreateDynamicObject(640, -1989.75, 1348.54, 102.91,   0.00, 0.00, 90.00);
	CreateDynamicObject(1670, -1998.03, 1361.23, 103.09,   0.00, 0.00, -39.78);
	CreateDynamicObject(348, -1997.90, 1361.50, 103.09,   90.00, 0.00, -125.46);
	CreateDynamicObject(348, -1997.63, 1359.04, 103.08,   90.00, 0.00, 121.44);
	CreateDynamicObject(3052, -2002.93, 1336.26, 102.32,   0.00, 0.00, -4.32);
	CreateDynamicObject(351, -2002.60, 1336.17, 102.50,   -101.32, -13.28, 126.96);
	CreateDynamicObject(2043, -2002.29, 1336.04, 102.32,   0.00, 0.00, 73.86);
	CreateDynamicObject(356, -2001.60, 1334.23, 104.38,   -103.06, -7.68, -75.48);
	CreateDynamicObject(2894, -1997.77, 1360.52, 103.09,   0.00, 0.00, 63.96);
	CreateDynamicObject(2894, -1997.88, 1359.77, 103.09,   0.00, 0.00, 133.68);
	CreateDynamicObject(2862, -1980.50, 1368.43, 103.09,   0.00, 0.00, 166.98);
	CreateDynamicObject(2862, -1978.55, 1368.40, 103.09,   0.00, 0.00, 166.98);
	CreateDynamicObject(3525, -1982.82, 1336.32, 104.77,   0.00, 0.00, 211.14);
	CreateDynamicObject(3525, -1987.59, 1333.50, 104.77,   0.00, 0.00, 211.14);
	CreateDynamicObject(2817, -2000.10, 1336.26, 107.67,   0.00, 0.00, -50.16);
	CreateDynamicObject(2817, -2000.10, 1336.26, 102.21,   0.00, 0.00, -50.16);
	CreateDynamicObject(2630, -1992.34, 1375.26, 107.67,   0.00, 0.00, -203.58);
	CreateDynamicObject(2630, -1992.34, 1375.26, 102.21,   0.00, 0.00, -203.58);
	CreateDynamicObject(2627, -1987.16, 1375.02, 102.19,   0.00, 0.00, 180.00);
	CreateDynamicObject(2627, -1987.16, 1375.02, 107.66,   0.00, 0.00, 180.00);
	CreateDynamicObject(2255, -2001.55, 1334.71, 114.81,   0.00, 0.00, 129.06);
}