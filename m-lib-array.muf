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
(* QUICK DEFINITIONS:                                                        *)
(*   .array_hasval ( ? a -- i )                                              *)
(*     Returns true if the array has a given value element.                  *)
(*                                                                           *)
(*   .array_haskey ( ? a -- i )                                              *)
(*     Returns true if the array has a given key                             *)
(*                                                                           *)
(*   .array_max ( a -- ? )                                                   *)
(*     Given an array of numbers, compares them all and returns the highest. *)
(*                                                                           *)
(*   .array_min ( a -- ? )                                                   *)
(*     Given an array of numbers, compares them all and returns the lowest.  *)
(*                                                                           *)
(*   .array_appendarray ( a a -- a )                                         *)
(*     Like ARRAY_APPENDITEM but appends every value in the given array.     *)
(*                                                                           *)
(*   .carve_array ( s1 s2 -- a )                                             *)
(*     Like EXPLODE_ARRAY but it doesn't remove the separators, it cuts just *)
(*     before them and keeps them in the resulting strings. Concatenating    *)
(*     the elements will return the original string.                         *)
(*                                                                           *)
(*   .slice_array ( s1 s2 -- a )                                             *)
(*     Like EXPLODE_ARRAY but it the separators are also included in the     *)
(*     resulting array. Concatenating the elements will return the original  *)
(*     string.                                                               *)
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

$PUBDEF .carve_array dup -rot explode_array 1 array_cut foreach nip 3 pick swap strcat swap array_appenditem repeat nip
$PUBDEF .slice_array dup -rot explode_array 1 array_cut foreach nip 3 pick rot array_appenditem array_appenditem repeat nip
$PUBDEF .array_hasval 0 -rot foreach nip over = if swap pop 1 swap break then repeat pop
$PUBDEF .array_haskey 0 -rot foreach pop over = if swap pop 1 swap break then repeat pop
$PUBDEF .array_max dup 0 array_getitem swap foreach nip over over > if pop else nip then repeat
$PUBDEF .array_min dup 0 array_getitem swap foreach nip over over < if pop else nip then repeat
$PUBDEF .array_appendarray foreach nip swap array_appenditem repeat

(* Iterate over a string, separating it whenever anything inside a given array is found and producing an array of all the elements *)
(* "01x2345y67" { "x" "y" }list -> { "01" "x" "2345" "y" "67" }list *)
$DEF EINSTRING over swap instring dup not if pop strlen else nip -- then
: dice_array[ str:source arr:sep -- arr:result ]
  { }list var! result
  begin
    (* If we're at a separator, slice it off into the result list. First matching separator takes priority *)
    sep @ foreach
      nip
      source @ over instring 1 = if
        source @ swap strlen strcut source ! result @ array_appenditem result !
        break
      then
      pop
    repeat
    (* Find the next match for each separator and keep the closest one *)
    {
      sep @ foreach
        nip
        source @ swap EINSTRING
      repeat
    }list .array_min
    (* Slice off everything up to the next separator into the result list *)
    source @ swap strcut source ! result @ array_appenditem result !
    source @ not
  until
  result @
;

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-array.muf=m/lib/array
!@set $m/lib/array=L

