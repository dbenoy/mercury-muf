!@program m-lib-quota.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-quota.muf - $m/lib/quota                                            *)
(*   A library for retreiving information on object quotas for builders.     *)
(*   Used by the mercury-muf building commands.                              *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-QUOTA-GetQuota[ ref:player str:type -- int:quota ]                *)
(*     Gets the quota of total objects of a given type, for a given player.  *)
(*     M3 required. (Object types: "room" "exit" "thing")                    *)
(*                                                                           *)
(*   M-LIB-QUOTA-GetUsage[ ref:player str:type -- int:usage ]                *)
(*     Gets the current total objects owned of a given type, for a given     *)
(*     player. M3 required. (Object types: "room" "exit" "thing")            *)
(*                                                                           *)
(*   M-LIB-QUOTA-QuotaCheck[ str:type bool:noisy -- bool:hasanyroom? ]       *)
(*     Checks if the current player has any available space to create        *)
(*     objects of a given type. Optionally, if room is unavailable, it will  *)
(*     be noisy and display a notification to the player about it. Unquelled *)
(*     wizards will always return true regardless of their current quota.    *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   Quota information is stored in the property @/quota/<type> where type   *)
(*   is "room" "exit", or "thing". This property is stored on this program   *)
(*   object itself for global values, and individual player values are       *)
(*   stored on the players themselves.                                       *)
(*                                                                           *)
(*   The '@' symbol makes this property wizard-only.                         *)
(*                                                                           *)
(*   The value is stored as a string number, or "-1" for unlimited. "0" will *)
(*   effectively prevent any building for that type.                         *)
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
$NOTE    Object quotas for building commands.
$DOCCMD  @list __PROG__=2-60

(* Begin configurable options *)

$DEFINE DEFAULT_QUOTA
{
  "thing" -1
  "room" -1
  "exit" -1
  "program" -1
}dict
$ENDDEF

(* End configurable options *)

$INCLUDE $m/lib/program

$PUBDEF :

(*****************************************************************************)
(*                           M-LIB-QUOTA-GetQuota                            *)
(*****************************************************************************)
: M-LIB-QUOTA-GetQuota[ ref:player str:type -- int:quota ]
  .needs_mlev3

  player @ dbref? not if "Non-dbref argument (1)." abort then
  type @ string? not if "Non-string argument (2)." abort then

  { type @ }list { "room" "exit" "thing" }list array_intersect not if "Quota type not recognized." abort then

  player @ "@/quota/" type @ strcat getpropstr number? if
    player @ "@/quota/" type @ strcat getpropstr atoi
    dup -1 >= if exit then
    pop
  then

  prog "@/quota/" type @ strcat getpropstr number? if
    prog "@/quota/" type @ strcat getpropstr atoi
    dup -1 >= if exit then
    pop
  then

  DEFAULT_QUOTA type @ []
;
PUBLIC M-LIB-QUOTA-GetQuota
$LIBDEF M-LIB-QUOTA-GetQuota

(*****************************************************************************)
(*                           M-LIB-QUOTA-GetUsage                            *)
(*****************************************************************************)
: M-LIB-QUOTA-GetUsage[ ref:player str:type -- int:usage ]
  .needs_mlev3

  player @ dbref? not if "Non-dbref argument (1)." abort then
  type @ string? not if "Non-string argument (2)." abort then

  player @ ok? not if exit 0 then
  player @ player? not if exit 0 then

  var statsPos
  type @ case
    "room" = when
      1 statsPos !
    end
    "exit" = when
      2 statsPos !
    end
    "thing" = when
      3 statsPos !
    end
    default
      "Quota usage type not recognized." abort
    end
  endcase

  { player @ stats }array statsPos @ []
;
PUBLIC M-LIB-QUOTA-GetUsage
$LIBDEF M-LIB-QUOTA-GetUsage

(*****************************************************************************)
(*                          M-LIB-QUOTA-QuotaCheck                           *)
(*****************************************************************************)
: M-LIB-QUOTA-QuotaCheck[ str:type bool:noisy -- bool:hasanyroom? ]
  (* M1 OK *)

  type @ string? not if "Non-string argument (1)." abort then

  { type @ }list { "room" "exit" "thing" }list array_intersect not if "Quota type not recognized." abort then

  "me" match "WIZARD" flag? not if
    "me" match type @ M-LIB-QUOTA-GetQuota
    dup -1 != if
      "me" match type @ M-LIB-QUOTA-GetUsage swap >= if
        noisy @ if { "You already have too many '" type @ "' objects. See @quota." }join .tell then
        0 exit
      then
    else
      pop
    then
  then
  1
;
PUBLIC M-LIB-QUOTA-QuotaCheck
$LIBDEF M-LIB-QUOTA-QuotaCheck

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-quota.muf=m/lib/quota
!@set $m/lib/quota=L
!@set $m/lib/quota=M3
!@set $m/lib/quota=W

