!@program m-cmd-pose.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-pose.muf - $m/cmd/pose                                              *)
(*   Pose command using $m/lib/emote                                         *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October 2019                             *)
(*      - Original implementation                                            *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2019 Daniel Benoy                                           *)
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
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    Pose command.
$DOCCMD  @list __PROG__=2-30

$include $m/lib/emote

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( s -- s )
  pop
  "Do something."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop var! action_name
  {
    { action_name @ toupper " <message>" }cat
    { "  Poses a message to everyone in the room.  This is used for actions.  i.e.: if your name was Igor, and you typed '" action_name @ tolower " falls down.', everyone would see:" }cat
    "    Igor falls down."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  dup not if
    pop
    "What do you want to do?" tell
    exit
  then
  me @ name
  over pose-separator? not if
    " " strcat
  then
  swap strcat
  { "from" me @ }dict M-LIB-EMOTE-emote
;
.
c
q
!@register m-cmd-pose.muf=m/cmd/pose
!@set $m/cmd/pose=M3

