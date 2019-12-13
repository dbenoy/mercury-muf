!@program m-cmd-ponder.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-ponder.muf - $m/cmd/ponder                                          *)
(*   Ponder command using $m/lib/emote                                       *)
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
$NOTE    Ponder command.
$DOCCMD  @list __PROG__=2-30

$include $m/lib/emote

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Think something."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <message>" }cat
    " "
    "Think <message> noticibly to everyone in the room.  If your name is Igor, and you typed 'ponder What if Pinocchio said his nose will grow?', then you and everyone in the room will see:"
    " "
    "Igor . o O ( What if Pinocchio said his nose will grow? )"
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  dup not if
    pop
    "Ponder what?" .tell
    exit
  then
  { me @ name " . o O ( "}cat swap " )" strcat strcat
  { "from" me @ }dict M-LIB-EMOTE-emote
;
.
c
q
!@register m-cmd-ponder.muf=m/cmd/ponder
!@set $m/cmd/ponder=M3

