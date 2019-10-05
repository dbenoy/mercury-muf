!@program m-lib-array.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-array.muf - $m/lib/array                                            *)
(*   Array manipulation routines.                                            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October, 2019                            *)
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
$NOTE    Array manipulation routines.
$DOCCMD  @list __PROG__=2-30

$PUBDEF :
$PUBDEF .array_hasval ( ? a -- i ) 0 -rot foreach nip over = if swap pop 1 swap break then repeat pop
$PUBDEF .array_haskey ( ? a -- i ) 0 -rot foreach pop over = if swap pop 1 swap break then repeat pop
$PUBDEF .array_max ( a -- ? ) dup 0 array_getitem swap foreach nip over over > if pop else nip then repeat
$PUBDEF .array_min ( a -- ? ) dup 0 array_getitem swap foreach nip over over < if pop else nip then repeat
$PUBDEF .array_appendarray ( a a -- a ) foreach nip swap array_appenditem repeat
$PUBDEF .array_join ( a s -- s ) "" swap 1 array_cut swap array_vals pop swap foreach nip 3 pick swap strcat strcat repeat swap pop
$PUBDEF .join ( {s} s -- s ) over 2 + 0 swap - rotate array_make swap .array_join

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-array.muf=m/lib/array
!@set $m/lib/array=L

