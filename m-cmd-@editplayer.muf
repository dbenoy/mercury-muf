@program m-cmd-@editplayer.muf
1 99999 d
i
$pragma comment_recurse
(*****************************************************************************)
(* m-cmd-@editplayer.muf - $m/cmd/at_editplayer                              *)
(*   A simple command to call $m/cmd/at_editobject on the player.            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- September, 2019                          *)
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
$NOTE    Player editor.
$DOCCMD  @list $m/cmd/at_editplayer=2,30

$include $m/cmd/at_editobject

: help ( -- )
  "@EDITPLAYER" .tell
  " " .tell
  "  Open a player editor dialog." .tell
;

: main ( s --  )
  if help exit then

  "me" M-CMD-AT_EDITOBJECT-EditObject pop
;
.
c
q
@register m-cmd-@editplayer.muf=m/cmd/at_editplayer
@set $m/cmd/at_editplayer=M3

