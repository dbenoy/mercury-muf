!@program m-cmd-@attach.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m_cmd-@attach.muf - $m/cmd/at_attach                                      *)
(*   A replacement for the built-in @attach command which tries to mimic     *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o Can act as a library for other programs to attach exits with proper   *)
(*     permission checks, penny charges, etc.                                *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_ATTACH-Attach[ str:action str:source -- bool:success? ]        *)
(*     Attempts to attach an exit as though the current player ran the       *)
(*     @attach command, including all the same message output, permission    *)
(*     checks, etc. M3 required.                                             *)
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
$DOCCMD  @list __PROG__=2-42

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/match

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Relocate an action/exit."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <action>=<new source>" }join
    " "
    "  Removes the action from where it was and attaches it to the new source. You must control the action in question."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: doReattach ( d d -- s )
  2 try
    moveto "" exit
  catch
    exit
  endcatch
;
(*****************************************************************************)
(*                          M-CMD-AT_ATTACH-Attach                           *)
(*****************************************************************************)
: M-CMD-AT_ATTACH-Attach[ str:action str:source -- bool:success? ]
  .needs_mlev3

  source @ not action @ not or if
    "You must specify an action name and a source object." .tell
    0 exit
  then

  action @ 1 1 1 1 M-LIB-MATCH-Match action !
  action @ not if
    0 exit
  then

  action @ exit? not if
    "That's not an action!" .tell
    0 exit
  then

  "me" match action @ controls not if
    "Permission denied. (you don't control the action you're trying to reattach)" .tell
    0 exit
  then

  source @ 1 1 1 1 M-LIB-MATCH-Match source !
  source @ not if
    0 exit
  then

  "me" match source @ controls not if
    "Permission denied. (you don't control the attachment point)" .tell
    0 exit
  then

  source @ exit? if
    "You can't attach an action to an action." .tell
    0 exit
  then

  source @ program? if
    "You can't attach an action to a program." .tell
    0 exit
  then

  action @ source @ doReattach
  dup if .tell pop #-1 exit else pop then

  "Action re-attached." .tell

  action @ mlevel if
    action @ "!M" set
    "Action priority Level reset to zero." .tell
  then

  1
;
PUBLIC M-CMD-AT_ATTACH-Attach
$LIBDEF M-CMD-AT_ATTACH-Attach

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @attach." .tell
    pop exit
  then

  "=" split
  strip var! source
  strip var! action

  (* Reattach exit *)
  action @ source @ M-CMD-AT_ATTACH-Attach pop
;
.
c
q
!@register m-cmd-@attach.muf=m/cmd/at_attach
!@set $m/cmd/at_attach=L
!@set $m/cmd/at_attach=M3

