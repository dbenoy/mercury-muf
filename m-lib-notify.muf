!@program m-lib-notify.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-notify - $m/lib/notify                                              *)
(*   Routines for handling 'notify' output.                                  *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-NOTIFY-cast_targets[ ref:object -- ]                              *)
(*     Given an object, return all the players and things within that        *)
(*     object, plus all the players and things within them, and so on        *)
(*     recursively.                                                          *)
(*                                                                           *)
(*     The object can be a room, and it will give you the players and things *)
(*     contained in that room even if they are inside of vehicles or player  *)
(*     inventories, etc.                                                     *)
(*                                                                           *)
(*     This is for a more thorough method of room notification than the      *)
(*     standard 'otell' which only notifies others standing inside your same *)
(*     location directly, and not deeper inside the tree.                    *)
(*                                                                           *)
(*     Any contained sub-rooms are not traversed.                            *)
(*                                                                           *)
(*   M-LIB-NOTIFY-color_array_notify[ arr:strings arr:targets -- ]           *)
(*     Like the ARRAY_NOTIFY primitive, but it can use MCC color codes.      *)
(*                                                                           *)
(* CONVENIENCE ROUTINES:                                                     *)
(*   .cast ( s -- )                                                          *)
(*     Displays a message to every player and every thing in your current    *)
(*     location, including ones that are contained within other players and  *)
(*     things, recursively. (See M-LIB-NOTIFY-cast_targets above)            *)
(*                                                                           *)
(*   .ocast ( s -- )                                                         *)
(*     Like .cast, but excludes the player's self.                           *)
(*                                                                           *)
(*   .color_notify ( d s -- )                                                *)
(*     Like the NOTIFY primitive, but supports MCC color codes.              *)
(*                                                                           *)
(*   .color_tell ( s -- )                                                    *)
(*     Like the TELL primitive, but supports MCC color codes.                *)
(*                                                                           *)
(*   .color_otell ( s -- )                                                   *)
(*     Like the OTELL primitive, but supports MCC color codes.               *)
(*                                                                           *)
(*   .color_cast ( s -- )                                                    *)
(*     Like .cast, but supports MCC color codes.                             *)
(*                                                                           *)
(*   .color_ocast ( s -- )                                                   *)
(*     Like .ocast, but supports MCC color codes.                            *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- November, 2019                           *)
(*      - Original implementation.                                           *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2019                                                        *)
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
$VERSION 1.0
$AUTHOR  Daniel Benoy
$NOTE    Notify output library.
$DOCCMD  @list __PROG__=2-72

(* Begin configurable options *)

(* Comment this out to remove the dependency on $m/lib/color *)
$DEF M_LIB_COLOR

(* End configurable options *)

(* ------------------------------------------------------------------------ *)

$PUBDEF :

$include $m/lib/program

$IFDEF M_LIB_COLOR
  $INCLUDE $m/lib/color
$ELSE
  $DEF M-LIB-COLOR-encoding_get pop "NOCOLOR"
  $DEF M-LIB-COLOR-transcode pop pop
$ENDIF

: cast_targets ( d -- a )
  {
    swap contents_array foreach
      nip
      dup thing? over player? or not if
        pop
        continue
      then
      dup cast_targets array_vals pop
    repeat
  }list
;

(*****************************************************************************)
(*                         M-LIB-NOTIFY-cast_targets                         *)
(*****************************************************************************)
: M-LIB-NOTIFY-cast_targets[ ref:object -- ]
  (* M1 OK *)

  object @ dbref? not if "Non-dbref argument (1)." abort then

  object @ cast_targets
;
PUBLIC M-LIB-NOTIFY-cast_targets
$LIBDEF M-LIB-NOTIFY-cast_targets

(*****************************************************************************)
(*                      M-LIB-NOTIFY-color_array_notify                      *)
(*****************************************************************************)
: M-LIB-NOTIFY-color_array_notify[ arr:strings arr:targets -- ]
  .needs_mlev2 (* TODO: Support mlev1 with "force_mlev1_name_notify" sysparm. The logic for this in prefix_message in the fbmuck source is actually a bit involved *)

  strings @ array? not if "Non-array argument (1)." abort then
  strings @ foreach nip string? not if "Array of strings expected (1)." abort then repeat
  targets @ array? not if "Non-array argument (2)." abort then
  targets @ foreach nip dbref? not if "Array of dbrefs expected (2)." abort then repeat

  strings @ foreach
    nip
    var! message
    { }dict var! transcode_cache
    targets @ foreach
      nip
      var! to
      to @ owner M-LIB-COLOR-encoding_get var! to_encoding
      transcode_cache @ to_encoding @ [] if
        transcode_cache @ to_encoding @ []
      else
        message @ "MCC" to_encoding @ M-LIB-COLOR-transcode
        dup transcode_cache @ to_encoding @ ->[] transcode_cache !
      then
      to @ swap notify
    repeat
  repeat
;
PUBLIC M-LIB-NOTIFY-color_array_notify
$LIBDEF M-LIB-NOTIFY-color_array_notify

(*****************************************************************************)
(*                           Convenience Routines                            *)
(*****************************************************************************)
$PUBDEF .color_notify 1 array_make swap 1 array_make M-LIB-NOTIFY-color_array_notify
$PUBDEF .color_tell 1 array_make { me @ }list M-LIB-NOTIFY-color_array_notify
$PUBDEF .color_otell 1 array_make { me @ }list loc @ contents_array array_diff M-LIB-NOTIFY-color_array_notify
$PUBDEF .color_cast 1 array_make me @ begin location dup room? until M-LIB-NOTIFY-cast_targets M-LIB-NOTIFY-color_array_notify
$PUBDEF .color_ocast 1 array_make { me @ }list me @ begin location dup room? until M-LIB-NOTIFY-cast_targets array_diff M-LIB-NOTIFY-color_array_notify
$PUBDEF .cast 1 array_make me @ begin location dup room? until M-LIB-NOTIFY-cast_targets \array_notify
$PUBDEF .ocast 1 array_make { me @ }list me @ begin location dup room? until M-LIB-NOTIFY-cast_targets array_diff \array_notify

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-notify.muf=m/lib/notify
!@set $m/lib/notify=W
!@set $m/lib/notify=L

