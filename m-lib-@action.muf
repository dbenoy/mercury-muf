!@program m-lib-@action.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-@action.muf - $m/lib/at_action                                      *)
(*   A replacement for the built-in @action command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-AT_ACTION-action[ str:source str:exitname -- ref:room ]           *)
(*     Attempts to create an action as though the current player ran the     *)
(*     @action command, including all the same message output, permission    *)
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
$NOTE    @action command with more features.
$DOCCMD  @list __PROG__=2-52

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/quota
$INCLUDE $m/lib/match
$INCLUDE $m/lib/pennies

$PUBDEF :

(* ------------------------------------------------------------------------- *)

: doNewExit ( d s -- d s )
  2 try
    newexit "" exit
  catch
    #-1 swap exit
  endcatch
;

(*****************************************************************************)
(*                          M-LIB-AT_ACTION-action                           *)
(*****************************************************************************)
: M-LIB-AT_ACTION-action[ str:source str:exitname -- ref:room ]
  M-LIB-PROGRAM-needs_mlev4

  "exit" 1 M-LIB-QUOTA-QuotaCheck not if #-1 exit then

  "exit_cost" sysparm atoi var! cost

  exitname @ not if
    "You must specify a direction or action name to open." .tell
    #-1 exit
  then

  exitname @ name-ok? not if
    "That's a strange name for an exit!" .tell
    #-1 exit
  then

  source @ not if
    "You must specify a source object." .tell
    #-1 exit
  then

  source @ { "quiet" "no" "match_absolute" "yes" "match_home" "no" "match_nil" "no" }dict M-LIB-MATCH-match source !

  source @ ok? not if
    #-1 exit
  then

  "me" match source @ controls not if
    "Permission denied. (you don't control the attachment point)" .tell
    #-1 exit
  then

  source @ exit? if
    "You can't attach an action to an action." .tell
    #-1 exit
  then

  source @ program? if
    "You can't attach an action to a program." .tell
    #-1 exit
  then

  cost @ M-LIB-PENNIES-payfor_chk not if
    { "Sorry, you don't have enough " "pennies" sysparm " to create an action/exit." }cat .tell
    #-1 exit
  then

  source @ exitname @ doNewExit
  dup if .tell pop #-1 exit else pop then

  cost @ M-LIB-PENNIES-payfor

  "Action " over name strcat " (#" strcat over intostr strcat ") created." strcat .tell
;
PUBLIC M-LIB-AT_ACTION-action
$LIBDEF M-LIB-AT_ACTION-action

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-@action.muf=m/lib/at_action
!@set $m/lib/at_action=L
!@set $m/lib/at_action=M3
!@set $m/lib/at_action=W

