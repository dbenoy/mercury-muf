@program m-cmd-morph.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-morph.muf - $m/cmd/morph                                            *)
(*   Load saved alternative description presets made inside @editobject.     *)
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

$INCLUDE $m/cmd/at_editobject

: help ( -- )
  "MORPH <morph name>" .tell
  " " .tell
  "  Loads a 'morph,' from the object editor."
  "  Morphs are a preset collection of descriptions and other cosmetic details." .tell
;

: main ( s --  )
  dup not if
    "What do you want to morph into?" .tell
    pop
    M-CMD-AT_EDITOBJECT-ListMorphs
    exit
  then

  "#help" over stringpfx if pop help exit then

  var! morph_name

  morph_name @ 1 M-CMD-AT_EDITOBJECT-LoadMorph if
    "me" match "_config/morph_mesg" getpropstr dup if .tell else { "You morph into a " me @ "_morph" getpropstr "." }join .tell pop then
    "me" match "_config/morph_omesg" getpropstr dup if "me" match name " " strcat swap strcat then .otell
  then
;
.
c
q
@register m-cmd-morph.muf=m/cmd/morph
@set $m/cmd/morph=M3

