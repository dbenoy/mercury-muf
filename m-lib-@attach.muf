!@program m-lib-@attach.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-@attach.muf - $m/lib/at_attach                                      *)
(*   A replacement for the built-in @attach command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-AT_ATTACH-attach[ s:action s:source -- i:success? ]               *)
(*     Attempts to attach an exit as though the current player ran the       *)
(*     @attach command, including all the same message output, permission    *)
(*     checks, etc. M4 required.                                             *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*      - Original implementation                                            *)
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
$VERSION 1.001
$AUTHOR  Daniel Benoy
$NOTE    @attach command with more features.
$DOCCMD  @list __PROG__=2-37

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/match

$PUBDEF :

(* ------------------------------------------------------------------------- *)

: doReattach ( d d -- s )
  2 try
    moveto "" exit
  catch
    exit
  endcatch
;
(*****************************************************************************)
(*                          M-LIB-AT_ATTACH-attach                           *)
(*****************************************************************************)
: M-LIB-AT_ATTACH-attach[ s:action s:source -- i:success? ]
  M-LIB-PROGRAM-needs_mlev4

  source @ not action @ not or if
    "You must specify an action name and a source object." tell
    0 exit
  then

  action @ { "quiet" "no" "match_absolute" "yes" "match_home" "no" "match_nil" "no" }dict M-LIB-MATCH-match action !
  action @ not if
    0 exit
  then

  action @ exit? not if
    "That's not an action!" tell
    0 exit
  then

  "me" match action @ controls not if
    "Permission denied. (you don't control the action you're trying to reattach)" tell
    0 exit
  then

  source @ { "quiet" "no" "match_absolute" "yes" "match_home" "no" "match_nil" "no" }dict M-LIB-MATCH-match source !
  source @ not if
    0 exit
  then

  "me" match source @ controls not if
    "Permission denied. (you don't control the attachment point)" tell
    0 exit
  then

  source @ exit? if
    "You can't attach an action to an action." tell
    0 exit
  then

  source @ program? if
    "You can't attach an action to a program." tell
    0 exit
  then

  action @ source @ doReattach
  dup if tell pop #-1 exit else pop then

  "Action re-attached." tell

  action @ mlevel if
    action @ "!M" set
    "Action priority Level reset to zero." tell
  then

  1
;
PUBLIC M-LIB-AT_ATTACH-attach
$LIBDEF M-LIB-AT_ATTACH-attach

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-@attach.muf=m/lib/at_attach
!@set $m/lib/at_attach=L
!@set $m/lib/at_attach=M3

