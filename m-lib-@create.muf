!@program m-lib-@create.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-@create.muf - $m/lib/at_create                                      *)
(*   A replacement for the built-in @create command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o Uses $m/lib/quota to enforce player object quotas.                    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-AT_CREATE-create[ s:thingname s:payment -- d:thing ]              *)
(*     Attempts to create an object as though the current player ran the     *)
(*     @create command, including all the same message output, permission    *)
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
$NOTE    @create command with more features.
$DOCCMD  @list __PROG__=2-43

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/quota
$INCLUDE $m/lib/match
$INCLUDE $m/lib/pennies

$PUBDEF :

(* ------------------------------------------------------------------------- *)

: doNewObject ( d s -- d s )
  2 try
    newobject "" exit
  catch
    #-1 swap exit
  endcatch
;

(*****************************************************************************)
(*                          M-LIB-AT_CREATE-create                           *)
(*****************************************************************************)
: M-LIB-AT_CREATE-create[ s:thingname s:payment -- d:thing ]
  M-LIB-PROGRAM-needs_mlev4

  "thing" 1 M-LIB-QUOTA-QuotaCheck not if #-1 exit then

  "max_object_endowment" sysparm atoi var! tp_max_endowment
  "object_cost" sysparm atoi var! tp_object_cost

  thingname @ not if
    "Please specify a valid name for this thing." .tell
    #-1 exit
  then

  thingname @ name-ok? not if
    "Please specify a valid name for this thing." .tell
    #-1 exit
  then

  payment @ atoi payment !
  payment @ 0 < if
    "You can't create an object for less than nothing!" .tell
    #-1 exit
  then

  payment @ tp_object_cost @ < if
    tp_object_cost @ payment !
  then

  payment @ M-LIB-PENNIES-payfor_chk not if
    { "Sorry, you don't have enough " "pennies" sysparm "." }cat .tell
    #-1 exit
  then

  (* Create the object *)
  "me" match thingname @ doNewObject
  dup if .tell pop #-1 exit else pop then

  "Object " over name strcat " (#" strcat over intostr strcat ") created." strcat .tell

  (* Endow the object *)
  payment @ M-LIB-PENNIES-payfor
  payment @ M-LIB-PENNIES-endow_get var! thingValue
  thingValue @ tp_max_endowment @ > if tp_max_endowment @ thingValue ! then
  thingValue @ 0 < if 0 thingValue ! then
  dup thingValue @ addpennies
;
PUBLIC M-LIB-AT_CREATE-create
$LIBDEF M-LIB-AT_CREATE-create

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-@create.muf=m/lib/at_create
!@set $m/lib/at_create=L
!@set $m/lib/at_create=M3
!@set $m/lib/at_create=W

