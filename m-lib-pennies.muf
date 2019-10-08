!@program m-lib-pennies.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-pennies.muf - $m/lib/pennies                                        *)
(*   A library for managing penny values.                                    *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-PENNIES-GetEndowStr ( -- s )                                      *)
(*     Returns a string representing the 'endowment formula' that is used to *)
(*     calculate the penny 'value' of an object based on how many pennies    *)
(*     are spent to create it.                                               *)
(*                                                                           *)
(*   M-LIB-PENNIES-GetEndow ( i -- i )                                       *)
(*     Given a number of pennies spent to create an object, return the       *)
(*     object's penny 'value.'                                               *)
(*                                                                           *)
(*   M-LIB-PENNIES-GetCost ( i -- i )                                        *)
(*     Given an object's penny 'value,' return the number of pennies that    *)
(*     would need to be spent in order to create it.                         *)
(*                                                                           *)
(*   M-LIB-PENNIES-Pennies ( ? -- s )                                        *)
(*     Given a number in int or string form, using the system @tune name for *)
(*     penny/pennies, return a string in the style of "1 penny", or          *)
(*     "2 pennies"                                                           *)
(*                                                                           *)
(*   M-LIB-PENNIES-ChkPayFor ( i -- b )                                      *)
(*     Check if the current player can afford to spend a given number of     *)
(*     pennies. M3 required.                                                 *)
(*                                                                           *)
(*   M-LIB-PENNIES-DoPayFor ( i --  )                                        *)
(*     Deduct a given number of pennies from the current player. Aborts if   *)
(*     there are insufficient pennies. M3 required.                          *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   At the endowment formula routines simply use the same hard-coded        *)
(*   formulas that you find inside the built-in MUCK building commands. In   *)
(*   the future, this may change to allow this library to be used to control *)
(*   system-wide customizations to this endowment formula.                   *)
(*                                                                           *)
(*   So in the future maybe a 1:1 cost/value ratio could be used, for        *)
(*   example when these routines are used.                                   *)
(*                                                                           *)
(*   Unfortunately, the RECYCLE primitive will refund pennies as though it   *)
(*   was being called as part of the @recycle command, and it uses the       *)
(*   hard-coded formulas, so this would need to be worked around by          *)
(*   m-cmd-@recycle.muf and all other routines that would want to call       *)
(*   RECYCLE, if we wanted to use an alternative formula system.             *)
(*                                                                           *)
(*   See: https://github.com/fuzzball-muck/fuzzball/issues/456               *)
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
$NOTE    Manage pennies.
$DOCCMD  @list __PROG__=2-77

(* Begin configurable options *)

(* End configurable options *)

$DEF ENDOWMENT_FORMULA        5 / --               (* Equation for pennies spent into object value *)
$DEF ENDOWMENT_FORMULA_STRING "((<cost> / 5) - 1)" (* The above equation in human readable form *)
$DEF COST_FORMULA             ++ 5 *               (* Inverse of ENDOWMENT_FORMULA. Desired object value into pennies required *)

$INCLUDE $m/lib/program

$PUBDEF :

(*****************************************************************************)
(*                         M-LIB-PENNIES-GetEndowStr                         *)
(*****************************************************************************)
: M-LIB-PENNIES-GetEndowStr ( -- s )
  (* M1 OK *)

  ENDOWMENT_FORMULA_STRING
;
PUBLIC M-LIB-PENNIES-GetEndowStr
$LIBDEF M-LIB-PENNIES-GetEndowStr

(*****************************************************************************)
(*                          M-LIB-PENNIES-GetEndow                           *)
(*****************************************************************************)
: M-LIB-PENNIES-GetEndow ( i -- i )
  (* M1 OK *)

  ENDOWMENT_FORMULA
;
PUBLIC M-LIB-PENNIES-GetEndow
$LIBDEF M-LIB-PENNIES-GetEndow

(*****************************************************************************)
(*                           M-LIB-PENNIES-GetCost                           *)
(*****************************************************************************)
: M-LIB-PENNIES-GetCost ( i -- i )
  (* M1 OK *)

  COST_FORMULA
;
PUBLIC M-LIB-PENNIES-GetCost
$LIBDEF M-LIB-PENNIES-GetCost

(*****************************************************************************)
(*                           M-LIB-PENNIES-Pennies                           *)
(*****************************************************************************)
: M-LIB-PENNIES-Pennies ( ? -- s )
  (* M1 OK *)

  dup string? if
    atoi
  then

  dup int? not if
    "String or int argument expected (1)." abort
  then

  dup intostr " " strcat swap dup 1 = swap -1 = or if "penny" sysparm else "pennies" sysparm then strcat
;
PUBLIC M-LIB-PENNIES-Pennies
$LIBDEF M-LIB-PENNIES-Pennies

(*****************************************************************************)
(*                          M-LIB-PENNIES-ChkPayFor                          *)
(*****************************************************************************)
: M-LIB-PENNIES-ChkPayFor ( i -- b )
  .needs_mlev3
  "i" checkargs

  dup 0 < if "Negative value (1)." abort then

  "me" match "WIZARD" flag? if (* Wizards have a sideways 8 in their pockets. *)
    pop 1 exit
  then

  "me" match pennies <=
;
PUBLIC M-LIB-PENNIES-ChkPayFor
$LIBDEF M-LIB-PENNIES-ChkPayFor

(*****************************************************************************)
(*                          M-LIB-PENNIES-DoPayFor                           *)
(*****************************************************************************)
: M-LIB-PENNIES-DoPayFor ( i --  )
  .needs_mlev3
  "i" checkargs

  dup 0 < if "Negative value (1)." abort then

  "me" match "WIZARD" flag? if (* Wizards have a sideways 8 in their pockets. *)
    pop exit
  then

  dup M-LIB-PENNIES-ChkPayFor not if
    "Not enough pennies!" abort
  then

  "me" match owner swap -1 * addpennies
;
PUBLIC M-LIB-PENNIES-DoPayFor
$LIBDEF M-LIB-PENNIES-DoPayFor

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-pennies.muf=m/lib/pennies
!@set $m/lib/pennies=L
!@set $m/lib/pennies=M3
!@set $m/lib/pennies=W

