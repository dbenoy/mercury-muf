@program m-cmd-@quota.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@quota.muf - $m/cmd/at_quota                                        *)
(*   For use with other $m/lib/quota programs, displays object quota and     *)
(*   usage information for a player.                                         *)
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
$NOTE    Displays player object quotas.
$DOCCMD  @list __PROG__=2-34

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/quota

(*****************************************************************************)
(*                                  cmdQuota                                 *)
(*****************************************************************************)
: help (  --  )
  "@QUOTA [<player>]" .tell
  " " .tell
  "Displays quota information and ownership totals." .tell
;

$DEF QUOTA_STRING dup -1 = if pop "---" else intostr then

: main ( s --  )
  dup "#help" over stringpfx and if pop help exit then

  dup not if
    pop "me"
  then

  dup if
    .pmatch
  else
    pop me @
  then

  dup #-1 = if
    "No such player." .tell
    pop exit
  then

  var! target

  me @ "WIZARD" flag? not target @ me @ != and if
    "Permission denied." .tell
    exit
  then

  "Owned"                                 "Quota"                                              ""         "%12s%12s%12s" fmtstring .tell
  target @ "thing" M-LIB-QUOTA-GetUsage   target @ "thing" M-LIB-QUOTA-GetQuota   QUOTA_STRING "Things"   "%12s%12s%12i" fmtstring .tell
  target @ "exit" M-LIB-QUOTA-GetUsage    target @ "exit" M-LIB-QUOTA-GetQuota    QUOTA_STRING "Exits"    "%12s%12s%12i" fmtstring .tell
  target @ "room" M-LIB-QUOTA-GetUsage    target @ "room" M-LIB-QUOTA-GetQuota    QUOTA_STRING "Rooms"    "%12s%12s%12i" fmtstring .tell
;

.
c
q
@register m-cmd-@quota.muf=m/cmd/at_quota
@set $m/cmd/at_quota=M3

