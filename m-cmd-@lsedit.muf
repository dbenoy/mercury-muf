@program m-cmd-@lsedit.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@lsedit.muf - $m/cmd/at_lsedit                                      *)
(*    A simple editor for 'list' properties.                                 *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_LSEDIT-LSEdit[ str:objname str:propname -- bool:modified? ]    *)
(*     Starts the list editor as though the player had executed the @lsedit  *)
(*     command, including object name matching and permissions checks.       *)
(*     It returns whether the list property was modified. Requires M3.       *)
(*                                                                           *)
(*   M-CMD-AT_LSEDIT-ListEdit[ ref:object str:propname -- bool:modified? ]   *)
(*     Like M-CMD-AT_LSEDIT-LSEdit, but skips name matching and permissions  *)
(*     checks. Requires wizbit.                                              *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- September, 2019                          *)
(*     - Original implementation                                             *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2019                                                        *)
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
$VERSION 1.0
$AUTHOR  Daniel Benoy
$NOTE    Editor for 'list' properties.
$DOCCMD  @list __PROG__=2-38
 
(* Begin configurable options *)
 
$DEF .chars-per-row 79
 
(* End configurable options *)

$INCLUDE $lib/editor
$INCLUDE $lib/lmgr
$INCLUDE $m/lib/match

$DEF .author prog "_author" getpropstr
$DEF .version prog "_version" getpropstr begin dup strlen 1 - over ".0" rinstr = not while dup ".0" instr while "." ".0" subst repeat

$DEF NEEDSM2 trig caller = not caller mlevel 2 < and if "Requires MUCKER level 2 or above." abort then
$DEF NEEDSM3 trig caller = not caller mlevel 3 < and if "Requires MUCKER level 3 or above." abort then
$DEF NEEDSM4 trig caller = not caller "WIZARD" flag? not and if "Requires MUCKER level 4 or above." abort then

$PUBDEF :

(*****************************************************************************)
(*                         M-CMD-AT_LSEDIT-ListEdit                          *)
(*****************************************************************************)
: M-CMD-AT_LSEDIT-ListEdit[ ref:object str:propname -- bool:modified? ]
  NEEDSM4

  object @ dbref? not if "Non-dbref argument (1)." abort then
  propname @ string? not if "Non-string argument (2)." abort then

  read_wants_blanks

  0 var! modified
  propname @ object @ LMGRgetlist array_make var! linedata
  "save" var! cmds
  1 var! curpos
  begin
    linedata @ array_vals "save" curpos @ ".i $" EDITORloop
    var! cmd
    var! cmdendline
    var! cmdstartline
    var! cmdargs
    curpos !
    cmds !
    array_make linedata !

    cmd @ "save" stringcmp not cmd @ "end" stringcmp not or if
      propname @ object @ LMGRdeletelist
      linedata @ array_vals 1 propname @ object @ LMGRputrange
      "< Saved. >" .tell
      1 modified !
      cmd @ "end" stringcmp not if break then
      continue
    then

    cmd @ "abort" stringcmp not if
      "< Aborting without saving. >" .tell
      break
    then
  repeat

  modified @
;
PUBLIC M-CMD-AT_LSEDIT-ListEdit
$LIBDEF M-CMD-AT_LSEDIT-ListEdit

(*****************************************************************************)
(*                          M-CMD-AT_LSEDIT-LSEdit                           *)
(*****************************************************************************)
: M-CMD-AT_LSEDIT-LSEdit[ str:objname str:propname -- bool:modified? ]
  NEEDSM3

  objname @ string? not if "Non-string argument (1)." abort then
  propname @ string? not if "Non-string argument (2)." abort then

  objname @ 1 1 1 1 M-LIB-MATCH-Match var! object
  object @ not if 0 exit then

  "me" match object @ controls not if
    "Permission denied. (You don't control what was matched.)" .tell
    0 exit
  then

  "me" match "WIZARD" flag? not if
    propname @ "~" instr 1 = propname @ "/~" instr or propname @ "@" instr 1 = or propname @ "/@" instr or if
      "Permission denied. (The property is restricted.)" .tell
      0 exit
    then
  then

  "<    Welcome to the line editor.  You can get help by entering '.h'     >" .tell
  "<     '.end' will exit and save.  '.abort' will abort any changes.      >" .tell
  "<           To save changes and continue editing, use '.save'           >" .tell

  object @ propname @ M-CMD-AT_LSEDIT-ListEdit
;
PUBLIC M-CMD-AT_LSEDIT-LSEdit
$LIBDEF M-CMD-AT_LSEDIT-LSEdit

(* ------------------------------------------------------------------------- *)

: help (  --  )
  "@LSEDIT <obj>=<prop>" .tell
  " " .tell
  "  Runs a line editor to edit a named 'list' type property on an object." .tell
;
 
: main ( s --  )
  "#help" over stringpfx if pop help exit then
  
  "=" split
  strip var! propname
  strip var! objname

  objname @ propname @ M-CMD-AT_LSEDIT-LSEdit pop
;
.
c
q
@register cmd-@lsedit.muf=m/cmd/at_lsedit
@set $m/cmd/at_lsedit=M3
@set $m/cmd/at_lsedit=W
@set $m/cmd/at_lsedit=L

