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
hook OnPlayerGiveDamage( playerid, damagedid, Float: amount, weaponid, bodypart )
{
    if ( p_Class[ damagedid ] == CLASS_POLICE )
    {
        new Float: x, Float: y, Float: z;

        GetPlayerPos( damagedid, x, y, z );

        if ( x >= -1650.0 && x <= -1571.0 && y >= 647.0 && y <= 711.0 )
            return ShowPlayerHelpDialog( playerid, 2000, "You cannot damage LEO officers while they are within the Police Department HQ." ), 0;
    }
    return 1;
}