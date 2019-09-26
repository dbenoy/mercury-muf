@program m-cmd-@create.muf
1 99999 d
i
$pragma comment_recurse
(*****************************************************************************)
(* m-cmd-@create.muf - $m/cmd/at_create                                      *)
(*   A replacement for the built-in @create command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o #help argument for usage information.                                 *)
(*   o Uses $m/lib/quota to enforce player object quotas.                    *)
(*   o Can act as a library for other programs to create objects.            *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_CREATE-Create[ str:thingname str:payment -- ref:thing ]        *)
(*     Attempts to create an object as though the current player ran the     *)
(*     @create command, including all the same message output, permission    *)
(*     checks, penny manipulation, etc. M3 required.                         *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*      - Split from lib-create.muf and cmd-lib-create.muf into mercury-muf  *)
(*        project                                                            *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*      - Original implementation for Latitude MUCK                          *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004-2019 Daniel Benoy                                      *)
(*                                                                           *)
(* This program is free software; you can redistribute it and/or modify it   *)
(* under the terms of the GNU General Public License as published by the     *)
(* Free Software Foundation; either version 2 of the License, or (at your    *)
(* option) any later version.                                                *)
(*                                                                           *)
(* This program is distributed in the hope that it will be useful, but       *)
(* WITHOUT ANY WARRANTY;without even the implied warranty of MERCHANTABILITY *)
(* or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License  *)
(* for more details.                                                         *)
(*                                                                           *)
(* You should have received a copy of the GNU General Public License along   *)
(* with this program; if not, write to the Free Software Foundation, Inc.,   *)
(* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA                     *)
(*****************************************************************************)
$VERSION 1.001
$AUTHOR  Daniel Benoy
$NOTE    @create command with more features.
$DOCCMD  @list $m/cmd/at_create=2-45

(* Begin configurable options *)

(* End configurable options *)

$include $m/lib/quota
$include $m/lib/match
$include $m/lib/pennies

$def NEEDSM2 trig caller = not caller mlevel 2 < and if "Requires MUCKER level 2 or above." abort then
$def NEEDSM3 trig caller = not caller mlevel 3 < and if "Requires MUCKER level 3 or above." abort then
$def NEEDSM4 trig caller = not caller "WIZARD" flag? not and if "Requires MUCKER level 4 or above." abort then

$pubdef :

: doNewObject ( d s -- d s )
  2 try
    newobject "" exit
  catch
    #-1 swap exit
  endcatch
;

(*****************************************************************************)
(*                          M-CMD-AT_CREATE-Create                           *)
(*****************************************************************************)
: M-CMD-AT_CREATE-Create[ str:thingname str:payment -- ref:thing ]
  NEEDSM3

  "thing" 1 M-LIB-QUOTA-QuotaCheck not if #-1 exit then

  "max_object_endowment" sysparm atoi var! tp_max_endowment
  "object_cost" sysparm atoi var! tp_object_cost

  thingname @ not if
    "Please specify a valid name for this thing." .tell
    #-1 exit
  then

  thingname @ name-ok? not if
    "Please specify a valid name for this thing." .tell
    #-1 exit
  then
  
  payment @ atoi payment !
  payment @ 0 < if
    "You can't create an object for less than nothing!" .tell
    #-1 exit
  then

  payment @ tp_object_cost @ < if
    tp_object_cost @ payment !
  then
  
  payment @ M-LIB-PENNIES-ChkPayFor not if
    { "Sorry, you don't have enough " "pennies" sysparm "." }join .tell
    #-1 exit
  then
  
  (* Create the object *)
  "me" match thingname @ doNewObject
  dup if .tell pop #-1 exit else pop then
  
  "Object " over name strcat " (#" strcat over intostr strcat ") created." strcat .tell
  
  (* Endow the object *)
  payment @ M-LIB-PENNIES-DoPayFor
  payment @ M-LIB-PENNIES-GetEndow var! thingValue
  thingValue @ tp_max_endowment @ > if tp_max_endowment @ thingValue ! then
  thingValue @ 0 < if 0 thingValue ! then
  dup thingValue @ addpennies
;
PUBLIC M-CMD-AT_CREATE-Create
$libdef M-CMD-AT_CREATE-Create
 
(*****************************************************************************)
(*                                cmdCreate                                  *)
(*****************************************************************************)
: help (  --  )
  "@CREATE <object> [=<cost>[=<regname>]]" .tell
 
  { "  Creates a new object and places it in your inventory.  This costs at least " "object_cost" sysparm M-LIB-PENNIES-Pennies ".  If <cost> is specified, you are charged that many pennies, and in return, the object is endowed with a value according to the formula: " M-LIB-PENNIES-GetEndowStr ".  The maximum value of an object is " "max_object_endowment" sysparm M-LIB-PENNIES-Pennies ", which would cost " "max_object_endowment" sysparm atoi M-LIB-PENNIES-GetCost intostr M-LIB-PENNIES-Pennies " to create. If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object.  This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, et cetera.  Only a builder may use this command." }join .tell
;
 
: main ( s --  )
  "#help" over stringpfx if pop help exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @create." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  strip var! cost
  strip var! thingname

  (* Create thing *)
  thingname @ cost @ M-CMD-AT_CREATE-Create
  dup not if
    pop
    exit
  then

  (* Register thing *)
  regname @ if
    dup regname @ M-LIB-MATCH-RegisterObject
  then
;
.
c
q
@register m-cmd-@create.muf=m/cmd/at_create
@set $m/cmd/at_create=L
@set $m/cmd/at_create=M3
@set $m/cmd/at_create=W

