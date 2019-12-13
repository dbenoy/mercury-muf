!@program m-cmd-@dig.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@dig.muf - $m/cmd/at_dig                                            *)
(*   A replacement for the built-in @dig command which tries to mimic stock  *)
(*   behavior while adding features.                                         *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o Uses $m/lib/quota to enforce player object quotas.                    *)
(*   o Can act as a library for other objects to create rooms with proper    *)
(*     permission checks, penny charges, etc.                                *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_DIG-dig[ str:roomname str:parent -- ref:dbref ]                *)
(*     Attempts to create an room as though the current player ran the @dig  *)
(*     command, including all the same message output, permission checks,    *)
(*     penny manipulation, etc. M3 required.                                 *)
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

$INCLUDE $m/lib/program
$INCLUDE $m/lib/quota
$INCLUDE $m/lib/match
$INCLUDE $m/lib/pennies

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

(* ------------------------------------------------------------------------ *)

: doNewRoom ( d s -- d s )
  2 try
    newroom "" exit
  catch
    #-1 swap exit
  endcatch
;

(*****************************************************************************)
(*                           M-CMD-AT_DIG-dig                                *)
(*****************************************************************************)

: M-CMD-AT_DIG-dig[ str:roomname str:parent -- ref:dbref ]
  M-LIB-PROGRAM-needs_mlev3

  "room" 1 M-LIB-QUOTA-QuotaCheck not if #-1 exit then

  roomname @ not if
    "You must specify a name for the room." .tell
    #-1 exit
  then

  roomname @ name-ok? not if
    "That's a silly name for a room!" .tell
    #-1 exit
  then

  "room_cost" sysparm atoi var! cost

  cost @ M-LIB-PENNIES-payfor_chk not if
    { "Sorry, you don't have enough " "pennies" sysparm " to dig a room." }cat .tell
    #-1 exit
  then

  (* Find default parent and create room *)
  "me" match location begin
    dup while

    dup "ABODE" flag? if
      break
    then

    location
  repeat

  dup not if
    pop "default_room_parent" sysparm stod
  then

  roomname @ doNewRoom
  dup if .tell pop #-1 exit else pop then
  var! newroom

  "Room " newroom @ name strcat " (#" strcat newroom @ intostr strcat ") created." strcat .tell

  cost @ M-LIB-PENNIES-payfor

  parent @ if
    "Trying to set parent..." .tell

    parent @ { "quiet" "no" "match_absolute" "yes" "match_home" "no" "match_nil" "no" }dict M-LIB-MATCH-match parent !

    parent @ ok? parent @ #-3 = or not if
      "Parent set to default." .tell
    else
      "me" match parent @ controls not parent @ "ABODE" flag? not and parent @ newroom @ = not and if
        "Permission denied. Parent set to default" .tell
      else
        newroom @ parent @ moveto
        "Parent set to " parent @ unparseobj strcat "." strcat .tell
      then
    then
  then

  newroom @
;
PUBLIC M-CMD-AT_DIG-dig
$LIBDEF M-CMD-AT_DIG-dig

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
  roomname @ parent @ M-CMD-AT_DIG-dig
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
!@set $m/cmd/at_dig=L
!@set $m/cmd/at_dig=M3
!@set $m/cmd/at_dig=W

