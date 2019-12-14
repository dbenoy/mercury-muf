!@program m-cmd-@dig.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@dig.muf - $m/cmd/at_dig                                            *)
(*   A replacement for the built-in @dig command which tries to mimic stock  *)
(*   behavior while adding features.                                         *)
(*                                                                           *)
(*   The business itself is taken care of by m-lib-@dig.muf, so that the     *)
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
$NOTE    @dig command with more features.
$DOCCMD  @list __PROG__=2-46

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/at_dig
$INCLUDE $m/lib/pennies
$INCLUDE $m/lib/match

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Create a room."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <room> [=<parent> [=<regname>]]" }cat
    " "
    { "  Creates a new room, sets its parent, and gives it a personal registered name.  If no parent is given, it defaults to the first ABODE room down the environment tree from the current room.  If it fails to find one, it sets the parent to " "default_room_parent" sysparm stod unparseobj ".  If no <regname> is given, then it doesn't register the object.  If one is given, then the object's dbref is recorded in the player's _reg/<regname> property, so that they can refer to the object later as $<regname>.  Digging a room costs " "room_cost" sysparm M-LIB-PENNIES-pennies ", and you must be able to link to the parent room if specified.  Only a builder may use this command." }cat
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @dig." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  strip var! parent
  strip var! roomname

  (* Create room *)
  roomname @ parent @ M-LIB-AT_DIG-dig
  dup not if
    pop
    exit
  then

  (* Register room *)
  regname @ if
    dup regname @ M-LIB-MATCH-register_object
  then
;
.
c
q
!@register m-cmd-@dig.muf=m/cmd/at_dig
!@set $m/cmd/at_dig=M3
!@set $m/cmd/at_dig=W

