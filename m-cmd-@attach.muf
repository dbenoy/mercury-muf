!@program m-cmd-@attach.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@attach.muf - $m/cmd/at_attach                                      *)
(*   A replacement for the built-in @attach command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   The business itself is taken care of by m-lib-@attach.muf, so that the  *)
(*   command can more easily be run from other programs like automated       *)
(*   building programs, but still retain proper message output, permission   *)
(*   checks, penny handling, etc.                                            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
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
$VERSION 1.001
$AUTHOR  Daniel Benoy
$NOTE    @attach command with more features.
$DOCCMD  @list __PROG__=2-36

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/at_attach

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Relocate an action/exit."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <action>=<new source>" }cat
    " "
    "  Removes the action from where it was and attaches it to the new source. You must control the action in question."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @attach." tell
    pop exit
  then

  "=" split
  strip var! source
  strip var! action

  (* Reattach exit *)
  action @ source @ M-LIB-AT_ATTACH-attach pop
;
.
c
q
!@register m-cmd-@attach.muf=m/cmd/at_attach
!@set $m/cmd/at_attach=M3
!@set $m/cmd/at_attach=W

