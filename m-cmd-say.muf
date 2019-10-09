!@program m-cmd-say.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-say.muf - $m/cmd/say                                                *)
(*   Say command using $m/lib/emote                                          *)
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
$NOTE    Say command.
$DOCCMD  @list __PROG__=2-30

$include $m/lib/emote

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( s -- s )
  pop
  "Make your character speak out loud."
;
WIZCALL M-HELP-desc

: M-HELP-help ( s -- a )
  ";" split pop var! action_name
  {
    { action_name @ toupper " <message>" }join
    { "  Says <message> out loud to everyone in the room.  If your name is Igor, and you typed '" action_name @ " Hello everyone!', then you and everyone in the room will see:" }join
    "    Igor says, \"Hello everyone!\""
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  dup not if
    pop
    "Say what?" .tell
    exit
  then
  { me @ name " says, \""}join swap "\"" strcat strcat
  "" "" me @ M-LIB-EMOTE-emote
;
.
c
q
!@register m-cmd-say.muf=m/cmd/say
!@set $m/cmd/say=M3

