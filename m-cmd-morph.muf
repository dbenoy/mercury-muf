!@program m-cmd-morph.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-morph.muf - $m/cmd/morph                                            *)
(*   Loads morphs created by the @morph command.                             *)
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
$NOTE    Morph loader.
$DOCCMD  @list __PROG__=2-30

$INCLUDE $m/lib/theme
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/emote
$INCLUDE $m/cmd/at_morph

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .err M-LIB-THEME-err

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Change into a different form."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <morph name>" }cat
    " "
    "  Loads a 'morph,' from the object editor."
    "  Morphs are a preset collection of descriptions and other cosmetic details."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: help ( -- )
;

: main ( s --  )
  dup not if
    "What do you want to morph into?" .err .tell
    pop exit
  then

  var! morph_name

  me @ morph_name @ 1 M-CMD-AT_MORPH-load if
    me @ morph_name @ 1 M-CMD-AT_MORPH-mesg_get { "from" me @ }dict M-LIB-EMOTE-emote
  then
;
.
c
q
!@register m-cmd-morph.muf=m/cmd/morph
!@set $m/cmd/morph=M3

