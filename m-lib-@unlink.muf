!@program m-lib-@unlink.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-@unlink.muf - $m/lib/at_unlink                                      *)
(*   A replacement for the built-in @unlink command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-AT_UNLINK-Unlink[ s:thing -- i:success? ]                         *)
(*     Attempts to perform an unlink as though the current player ran the    *)
(*     @unlink command, including all the same message output, permission    *)
(*     checks, etc. M4 required.                                             *)
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
$DOCCMD  @list __PROG__=2-40

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/match
$INCLUDE $m/lib/pennies

$PUBDEF :

(* ------------------------------------------------------------------------- *)

: controlsLink[ d:who d:thing -- i:success? ]
  thing @ ok? not if
    0 exit
  then

  thing @ program? if
    0 exit
  then

  thing @ getlinks array_make foreach
    swap pop
    dup ok? if
      who @ swap controls if 1 exit then
    else
      pop
    then
  repeat
  0 exit
;

(*****************************************************************************)
(*                          M-LIB-AT_UNLINK-unlink                           *)
(*****************************************************************************)
: M-LIB-AT_UNLINK-unlink[ s:thing -- i:success? ]
  M-LIB-PROGRAM-needs_mlev4

  "link_cost" sysparm atoi var! tp_link_cost
  "player_start" sysparm match var! tp_player_start

  thing @ { "quiet" "no" "match_absolute" "yes" "match_home" "no" "match_nil" "no" }dict M-LIB-MATCH-match thing !

  thing @ not if
    0 exit
  then

  "me" match thing @ controls "me" match thing @ controlsLink or not if
    "Permission denied. (You don't control the exit or its link)" tell
    0 exit
  then

  thing @ case
    exit? when
      thing @ getlink var! doRefund
      thing @ #-1 setlink
      "Unlinked." tell
      doRefund @ if
        thing @ owner tp_link_cost @ addpennies
      then
      thing @ mlevel if
        thing @ "!mucker" set
        "Action priority Level reset to 0." tell
      then
    end
    room? when
      thing @ #-1 setlink
      "Dropto removed." tell
    end
    thing? when
      thing @ thing @ owner setlink
      "Thing's home reset to owner." tell
    end
    player? when
      thing @ tp_player_start setlink
      "Player's home reset to default player start room." tell
    end
    default
      "You can't unlink that!" tell
    end
  endcase
  1
;
PUBLIC M-LIB-AT_UNLINK-Unlink
$LIBDEF M-LIB-AT_UNLINK-Unlink

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-@unlink.muf=m/lib/at_unlink
!@set $m/lib/at_unlink=L
!@set $m/lib/at_unlink=M3
!@set $m/lib/at_unlink=W

