/*
 * Irresistible Gaming (c) 2018
 * Developed by Lorenc
 * Module: cnr\features\cop\_cop.pwn
 * Purpose: encloses all cop/police (LEO) modules & components (cnr)
 */

/* ** Includes ** */
#include "irresistible\cnr\features\cop\jail.pwn"
#include "irresistible\cnr\features\cop\cop_chat.pwn"
#include "irresistible\cnr\features\cop\arrest.pwn"
#include "irresistible\cnr\features\cop\bail.pwn"
#include "irresistible\cnr\features\cop\ticket.pwn"
#include "irresistible\cnr\features\cop\emp.pwn"

/* ** Hooks ** */
/*hook OnPlayerTakeDamage( playerid, issuerid, Float: amount, weaponid, bodypart )
{
    if ( p_Class[ playerid ] == CLASS_POLICE && !IsPlayerNPC( playerid ) )
    {
        new Float: x, Float: y, Float: z;

        GetPlayerPos( playerid, x, y, z );

        if ( x >= -1650.0 && x <= -1571.0 && y >= 647.0 && y <= 711.0 )
            return ShowPlayerHelpDialog( issuerid, 2000, "You cannot damage LEO officers while they are within the Police Department HQ." ), 0;
    }
    return 1;
}*/