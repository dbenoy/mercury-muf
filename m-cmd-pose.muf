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
  "Make your character act for others to see."
;
WIZCALL M-HELP-desc

: M-HELP-help ( s -- a )
  ";" split pop toupper var! action_name
  {
    { action_name @ " <message>" }join
    ":<message>"
    " "
    "  Poses a message to everyone in the room.  This is used for actions.  i.e.: if your name was Igor, and you typed 'pose falls down.', everyone would see:"
    " "
    "    Igor falls down."
    " "
    "  There's also an abbreviated form of the 'pose' command: ':falls down.'"
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  dup not if
    pop
    "What do you want to do?" .tell
    exit
  then
  me @ name
  over 1 strcut pop dup "-" = swap "," = or not if
    " " strcat
  then
  swap strcat
  "" "" me @ M-LIB-EMOTE-emote
;
.
c
q
!@register m-cmd-pose.muf=m/cmd/pose
!@set $m/cmd/pose=M3

