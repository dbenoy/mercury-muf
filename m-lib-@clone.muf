!@program m-lib-@clone.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-@clone.muf - $m/lib/at_clone                                        *)
(*   A replacement for the built-in @clone command which tries to mimic      *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o Uses $m/lib/quota to enforce player object quotas.                    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-AT_CLONE-clone[ s:thingname -- d:thing ]                          *)
(*     Attempts to create an object as though the current player ran the     *)
(*     @clone command, including all the same message output, permission     *)
(*     checks, penny manipulation, etc. M4 required.                         *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*      - Split from lib-create.muf and cmd-lib-create.muf into mercury-muf  *)
(*        project                                                            *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*      - Original implementation for Latitude MUCK                          *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004-2019 Daniel Benoy                                      *)
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
$NOTE    @clone command with more features.
$DOCCMD  @list __PROG__=2-43

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/quota
$INCLUDE $m/lib/match
$INCLUDE $m/lib/pennies

$PUBDEF :

(* ------------------------------------------------------------------------- *)

: doCopyObj ( d -- d s )
  1 try
    copyobj "" exit
  catch
    #-1 swap exit
  endcatch
;

(*****************************************************************************)
(*                         M-LIB-AT_CLONE-clone                              *)
(*****************************************************************************)
: M-LIB-AT_CLONE-clone[ s:thingname -- d:thing ]
  M-LIB-PROGRAM-needs_mlev4

  "thing" 1 M-LIB-QUOTA-QuotaCheck not if #-1 exit then

  "max_object_endowment" sysparm atoi var! tp_max_endowment
  "object_cost" sysparm atoi var! tp_object_cost

  thingname @ not if
    "Clone what?" .tell
    0 exit
  then

  thingname @ { "quiet" "no" "match_absolute" "yes" "match_home" "no" "match_nil" "no" }dict M-LIB-MATCH-match var! thing

  thing @ not if
    0 exit
  then

  thing @ thing? not if
    "That is not a cloneable object." .tell
    0 exit
  then

  thing @ name "thing" ext-name-ok? not if
    "You cannot clone an object with this name." .tell
    0 exit
  then

  "me" match thing @ controls not if
    "Permission denied. (you can't clone this)"
    0 exit
  then

  thing @ pennies M-LIB-PENNIES-endow_cost_get var! cost

  cost @ tp_object_cost @ < if
    tp_object_cost @ cost !
  then

  cost @ M-LIB-PENNIES-payfor_chk not if
    { "Sorry, you don't have enough " "pennies" sysparm "." }cat .tell
    #-1 exit
  then

  thing @ doCopyObj
  dup if .tell pop #-1 exit else pop then

  var! newThing

  { "Object " thing @ unparseobj " cloned as " newThing @ unparseobj "." }cat .tell

  (* Endow the object *)
  cost @ M-LIB-PENNIES-payfor
;
PUBLIC M-LIB-AT_CLONE-clone
$LIBDEF M-LIB-AT_CLONE-clone

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-@clone.muf=m/lib/at_clone
!@set $m/lib/at_clone=M3
!@set $m/lib/at_clone=W

