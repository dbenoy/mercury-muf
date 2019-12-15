!@program m-cmd-@lsedit.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@lsedit.muf - $m/cmd/at_lsedit                                      *)
(*    A simple editor for 'list' properties.                                 *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
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
$DOCCMD  @list __PROG__=2-30

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/lsedit

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Edit a list property on an object."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <object>=<prop>" }cat
    " "
    "  Runs a line editor to edit the 'list' type property named <prop> on <object>."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "=" split
  strip var! propname
  strip var! objname

  objname @ propname @ M-LIB-LSEDIT-lsedit pop
;
.
c
q
!@register m-cmd-@lsedit.muf=m/cmd/at_lsedit
!@set $m/cmd/at_lsedit=M3
!@set $m/cmd/at_lsedit=W

