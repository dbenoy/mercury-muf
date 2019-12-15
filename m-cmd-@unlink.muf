!@program m-cmd-@unlink.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@unlink.muf - $m/cmd/at_unlink                                      *)
(*   A replacement for the built-in @unlink command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   The business itself is taken care of by m-lib-@unlink.muf, so that the  *)
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
$NOTE    @unlink command with more features.
$DOCCMD  @list __PROG__=2-39

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/at_unlink
$INCLUDE $m/lib/pennies

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Remove the 'link' between two objects."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <exit>" }cat
    { action_name @ " here" }cat
    " "
    { "  Removes the link on the exit in the specified direction, or removes the drop-to on the room. Unlinked exits may be picked up and dropped elsewhere. Be careful, anyone can relink an unlinked exit, becoming its new owner" "link_cost" sysparm atoi if " (but you will be reimbursed your " "link_cost" sysparm M-LIB-PENNIES-pennies ")" then "." }cat
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "=" split
  pop
  strip var! exitname

  (* Perform unlink *)
  exitname @ M-LIB-AT_UNLINK-unlink pop
;
.
c
q
!@register m-cmd-@unlink.muf=m/cmd/at_unlink
!@set $m/cmd/at_unlink=M3
!@set $m/cmd/at_unlink=W

