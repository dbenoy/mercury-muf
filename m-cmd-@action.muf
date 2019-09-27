@program m-cmd-@action.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m_cmd-@action.muf - $m/cmd/at_action                                      *)
(*   A replacement for the built-in @action command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o #help argument for usage information.                                 *)
(*   o Uses $m/lib/quota to enforce player object quotas.                    *)
(*   o Also link the exit with the same command.                             *)
(*   o Can act as a library for other objects to create exits with proper    *)
(*     permission checks, penny charges, etc.                                *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_ACTION-Action[ str:source str:exitname -- ref:room ]           *)
(*     Attempts to create an action as though the current player ran the     *)
(*     @action command, including all the same message output, permission    *)
(*     checks, penny manipulation, etc. M3 required.                         *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   Calls public routines on the following commands, so they must be        *)
(*   installed and registered:                                               *)
(*     m-cmd-@link.muf                                                       *)
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
$NOTE    @action command with more features.
$DOCCMD  @list __PROG__=2-52

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/quota
$INCLUDE $m/lib/match
$INCLUDE $m/lib/pennies
$INCLUDE $m/cmd/at_link

$DEF NEEDSM2 trig caller = not caller mlevel 2 < and if "Requires MUCKER level 2 or above." abort then
$DEF NEEDSM3 trig caller = not caller mlevel 3 < and if "Requires MUCKER level 3 or above." abort then
$DEF NEEDSM4 trig caller = not caller "WIZARD" flag? not and if "Requires MUCKER level 4 or above." abort then

$PUBDEF :

: doNewExit ( d s -- d s )
  2 try
    newexit "" exit
  catch
    #-1 swap exit
  endcatch
;
 
(*****************************************************************************)
(*                          M-CMD-AT_ACTION-Action                           *)
(*****************************************************************************)
: M-CMD-AT_ACTION-Action[ str:source str:exitname -- ref:room ]
  NEEDSM3

  "exit" 1 M-LIB-QUOTA-QuotaCheck not if #-1 exit then

  "exit_cost" sysparm atoi var! cost
  
  exitname @ not if
    "You must specify a direction or action name to open." .tell
    #-1 exit
  then
  
  exitname @ name-ok? not if
    "That's a strange name for an exit!" .tell
    #-1 exit
  then
  
  source @ not if
    "You must specify a source object." .tell
    #-1 exit
  then

  source @ 1 1 1 1 M-LIB-MATCH-Match source !

  source @ not if
    #-1 exit
  then

  "me" match source @ controls not if
    "Permission denied. (you don't control the attachment point)" .tell
    #-1 exit
  then
  
  source @ exit? if
    "You can't attach an action to an action." .tell
    #-1 exit
  then
  
  source @ program? if
    "You can't attach an action to a program." .tell
    #-1 exit
  then
  
  cost @ M-LIB-PENNIES-ChkPayFor not if
    { "Sorry, you don't have enough " "pennies" sysparm " to create an action/exit." }join .tell
    #-1 exit
  then
  
  source @ exitname @ doNewExit
  dup if .tell pop #-1 exit else pop then
  
  cost @ M-LIB-PENNIES-DoPayFor
  
  "Action " over name strcat " (#" strcat over intostr strcat ") created." strcat .tell
;
PUBLIC M-CMD-AT_ACTION-Action
$LIBDEF M-CMD-AT_ACTION-Action

(* ------------------------------------------------------------------------- *)

: help (  --  )
  "@ACTION <name>=<source>[,<destination>[; <destination2>; ... <destinationN>]] [=<regname>]" .tell
  " " .tell
  { "  Creates a new action and attaches it to the thing, room, or player specified. If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object. This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, etc. You may only attach actions you control to things you control. Creating an action costs " "exit_cost" sysparm M-LIB-PENNIES-Pennies ". The action can then be linked with the command @LINK." }join .tell
;
 
: main ( s --  )
  "#help" over stringpfx if pop help exit then
  
  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @action." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  "," split
  strip var! destination
  strip var! source
  strip var! exitname
  
  (* Create action *)
  source @ exitname @ M-CMD-AT_ACTION-Action var! newAction
  newAction @ not if exit then
  
  (* Perform link *)
  destination @ if
    "Trying to link..." .tell
    "#" newAction @ intostr strcat destination @ M-CMD-AT_LINK-Link not if exit then
  then
  
  (* Register action *)
  regname @ if
    dup regname @ M-LIB-MATCH-RegisterObject
  then
;
.
c
q
@register m-cmd-@action.muf=m/cmd/at_action
@set $m/cmd/at_action=L
@set $m/cmd/at_action=M3
@set $m/cmd/at_action=W

