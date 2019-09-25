@program m-cmd-@excavate.muf
1 99999 d
i
$pragma comment_recurse
(*****************************************************************************)
(* m-cmd-@excavate.muf - $m/cmd/at_excavate                                  *)
(*   Dig rooms, create, and link exits with one command.                     *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o Uses $m/lib/quota to enforce player object quotas.                    *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   Calls public routines on the following commands, so they must be        *)
(*   installed and registered:                                               *)
(*     m-cmd-@action.muf                                                     *)
(*     m-cmd-@dig.muf                                                        *)
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
$VERSION 1.1
$AUTHOR  Daniel Benoy
$NOTE    Make rooms and exits at the same time.
$DOCCMD  @list $m/cmd/at_excavate=2-43

(* Begin configurable options *)

(* End configurable options *)

$include $m/lib/pennies
$include $m/cmd/at_action
$include $m/cmd/at_dig
$include $m/cmd/at_link

(*****************************************************************************)
(*                               cmdExcavate                                 *)
(*****************************************************************************)
: help (  --  )
  "@EXCAVATE <room>[=<exit to room>[=<backlink from room>]]" .tell
  " " .tell
  { "  Creates a new room and, optionally, an exit leading from your current location to the room, and/or an exit leading from the room to your current location. The room is automatically parented to the same position in the environment tree as your current location. Creating a room costs " "room_cost" sysparm M-LIB-PENNIES-Pennies ".  Creating an exit costs " "exit_cost" sysparm M-LIB-PENNIES-Pennies ". Only a builder may use this command." }join .tell
;
 
: main ( s --  )
  "#help" over stringpfx if pop help exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @excavate." .tell
    pop exit
  then

  "=" split "=" split
  strip var! backexit
  strip var! foreexit
  strip var! roomname
  
  roomname @ "" M-CMD-AT_DIG-Dig dup not if pop exit then var! newroom
  
  foreexit @ if
    "Creating " foreexit @ strcat "..." strcat .tell
    { "#" loc @ intostr }join foreexit @ M-CMD-AT_ACTION-Action dup not if pop exit then var! newforeexit
    "Trying to link..." .tell
    { "#" newforeexit @ intostr }join { "#" newroom @ intostr }join M-CMD-AT_LINK-Link not if exit then
  then
  
  backexit @ if
    "Creating " backexit @ strcat "..." strcat .tell
    { "#" newroom @ intostr }join backexit @ M-CMD-AT_ACTION-Action dup not if pop exit then var! newbackexit
    "Trying to link..." .tell
    { "#" newbackexit @ intostr }join { "#" loc @ intostr }join M-CMD-AT_LINK-Link not if exit then
  then
;
.
c
q
@register m-cmd-@excavate.muf=m/cmd/at_excavate
@set $m/cmd/at_excavate=M3

