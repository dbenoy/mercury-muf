!@program m-lib-program.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-sec.muf - $m/lib/program                                            *)
(*   Some simple MUF program related routines.                               *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy - October 2019                              *)
(*      - Original implementation.                                           *)
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
$NOTE    Simple MUF program related routines.
$DOCCMD  @list __PROG__=2-30

$PUBDEF :

$PUBDEF .version prog "_version" getpropstr begin dup strlen 1 - over ".0" rinstr = not while dup ".0" instr while "." ".0" subst repeat
$PUBDEF .author prog "_author" getpropstr
$PUBDEF .note prog "_note" getpropstr
$PUBDEF .docs prog "_docs" getpropstr
$PUBDEF .mlev2 trig caller = caller mlevel 2 >= or
$PUBDEF .mlev3 trig caller = caller mlevel 3 >= or
$PUBDEF .mlev4 trig caller = caller "WIZARD" flag? or
$PUBDEF .needs_mlev2 .mlev2 not if "Requires MUCKER level 2 or above." abort then
$PUBDEF .needs_mlev3 .mlev3 not if "Requires MUCKER level 3 or above." abort then
$PUBDEF .needs_mlev4 .mlev4 not if "Requires MUCKER level 4 or above." abort then

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-program.muf=m/lib/program
!@set $m/lib/program.muf=L

