!@program m-cmd-@action.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@action.muf - $m/cmd/at_action                                      *)
(*   A replacement for the built-in @action command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   The business itself is taken care of by m-lib-@action.muf, so that the  *)
(*   command can more easily be run from other programs like automated       *)
(*   building programs, but still retain proper message output, permission   *)
(*   checks, penny handling, etc.                                            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
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
$DOCCMD  @list __PROG__=2-39

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/at_action
$INCLUDE $m/lib/at_link
$INCLUDE $m/lib/pennies
$INCLUDE $m/lib/match

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Create a new action/exit."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <name>=<source>[,<destination>[; <destination2>; ... <destinationN>]] [=<regname>]" }cat
    " "
    { "  Creates a new action and attaches it to the thing, room, or player specified. If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object. This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, etc. You may only attach actions you control to things you control. Creating an action costs " "exit_cost" sysparm M-LIB-PENNIES-pennies ". The action can then be linked with the command @LINK." }cat
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
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
  source @ exitname @ M-LIB-AT_ACTION-action var! newAction
  newAction @ not if exit then

  (* Perform link *)
  destination @ if
    "Trying to link..." .tell
    "#" newAction @ intostr strcat destination @ M-LIB-AT_LINK-link not if exit then
  then

  (* Register action *)
  regname @ if
    dup regname @ M-LIB-MATCH-register_object
  then
;
.
c
q
!@register m-cmd-@action.muf=m/cmd/at_action
!@set $m/cmd/at_action=M3
!@set $m/cmd/at_action=W

