!@program m-cmd-@create.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@create.muf - $m/cmd/at_create                                      *)
(*   A replacement for the built-in @create command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   The business itself is taken care of by m-lib-@create.muf, so that the  *)
(*   command can more easily be run from other programs like automated       *)
(*   building programs, but still retain proper message output, permission   *)
(*   checks, penny handling, etc.                                            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
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
$DOCCMD  @list __PROG__=2-39

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/at_create
$INCLUDE $m/lib/pennies
$INCLUDE $m/lib/match

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Create a thing."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <object> [=<cost>[=<regname>]]" }cat
    " "
    { "  Creates a new object and places it in your inventory.  This costs at least " "object_cost" sysparm M-LIB-PENNIES-pennies ".  If <cost> is specified, you are charged that many pennies, and in return, the object is endowed with a value according to the formula: " M-LIB-PENNIES-endow_str_get ".  The maximum value of an object is " "max_object_endowment" sysparm M-LIB-PENNIES-pennies ", which would cost " "max_object_endowment" sysparm atoi M-LIB-PENNIES-endow_cost_get intostr M-LIB-PENNIES-pennies " to create. If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object.  This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, et cetera.  Only a builder may use this command." }cat
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @create." tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  strip var! cost
  strip var! thingname

  (* Create thing *)
  thingname @ cost @ M-LIB-AT_CREATE-create
  dup not if
    pop
    exit
  then

  (* Register thing *)
  regname @ if
    dup regname @ M-LIB-MATCH-register_object
  then
;
.
c
q
!@register m-cmd-@create.muf=m/cmd/at_create
!@set $m/cmd/at_create=M3
!@set $m/cmd/at_create=W

