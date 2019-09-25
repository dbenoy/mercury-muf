@program m-cmd-@open.muf
1 99999 d
i
$pragma comment_recurse
(*****************************************************************************)
(* m-cmd-@open.muf - $m/cmd/at_open                                          *)
(*   A replacement for the built-in @open command which tries to mimic stock *)
(*   behavior while adding features.                                         *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o #help argument for usage information.                                 *)
(*   o Uses $m/lib/quota to enforce player object quotas.                    *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   Calls public routines on the following commands, so they must be        *)
(*   installed and registered:                                               *)
(*     m-cmd-@action.muf                                                     *)
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
$NOTE    @open command with more features.
$DOCCMD  @list $m/cmd/at_open=2-44

(* Begin configurable options *)

(* End configurable options *)

$include $m/lib/match
$include $m/lib/pennies
$include $m/cmd/at_action
$include $m/cmd/at_link

(*****************************************************************************)
(*                                 cmdOpen                                   *)
(*****************************************************************************)
: help (  --  )
  "@OPEN <exit> [=<object> [; <object2>; ... <objectn> ] [=<regname>]]" .tell
 
  { "  Opens an exit in the current room, optionally attempting to link it simultaneously.  If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object.  This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, etc.  Opening an exit costs " "exit_cost" sysparm M-LIB-PENNIES-Pennies ", and " "link_cost" sysparm M-LIB-PENNIES-Pennies " to link it, and you must control the room where it is being opened." }join .tell
;
 
: main ( s --  )
  "#help" over stringpfx if pop help exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @open." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  strip var! destination
  strip var! exitname
  
  (* Create action *)
  { "#" loc @ intostr }join exitname @ M-CMD-AT_ACTION-Action var! newAction
  newAction @ not if exit then
  
  (* Perform link *)
  destination @ if
    "Trying to link..." .tell  
    { "#" newAction @ intostr }join destination @ M-CMD-AT_LINK-Link not if exit then
  then
  
  (* Register action *)
  regname @ if
    dup regname @ M-LIB-MATCH-RegisterObject
  then
;
.
c
q
@register m-cmd-@open.muf=m/cmd/at_open
@set $m/cmd/at_open=M3

