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
(* PUBLIC FUNCTIONS:                                                         *)
(*   M-LIB-NOTIFY-array_notify_color[ y:strings y:targets -- ]               *)
(*     Like the ARRAY_NOTIFY primitive, but it can use MCC color codes.      *)
(*                                                                           *)
(*   M-LIB-NOTIFY-cast ( s -- )                                              *)
(*     Displays a message to every player and every thing in your current    *)
(*     location, including ones that are contained within other players and  *)
(*     things, recursively. (See M-LIB-NOTIFY-cast_targets above)            *)
(*                                                                           *)
(*   M-LIB-NOTIFY-cast_color ( s -- )                                        *)
(*     Like M-LIB-NOTIFY-cast, but supports MCC color codes.                 *)
(*                                                                           *)
(*   M-LIB-NOTIFY-cast_targets[ d:object -- ]                                *)
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
(*   M-LIB-NOTIFY-notify_color ( d s -- )                                    *)
(*     Like the NOTIFY primitive, but supports MCC color codes.              *)
(*                                                                           *)
(*   M-LIB-NOTIFY-ocast ( s -- )                                             *)
(*     Like M-LIB-NOTIFY-cast, but excludes the player's self.               *)
(*                                                                           *)
(*   M-LIB-NOTIFY-ocast_color ( s -- )                                       *)
(*     Like M-LIB-NOTIFY-ocast, but supports MCC color codes.                *)
(*                                                                           *)
(*   M-LIB-NOTIFY-otell_color ( s -- )                                       *)
(*     Like the OTELL primitive, but supports MCC color codes.               *)
(*                                                                           *)
(*   M-LIB-NOTIFY-tell_color ( s -- )                                        *)
(*     Like the TELL primitive, but supports MCC color codes.                *)
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

(* TODO: Support mlev1 with "force_mlev1_name_notify" sysparm. The logic for this in prefix_message in the fbmuck source is actually a bit involved, though. *)

(* Begin configurable options *)

(* Comment this out to remove the dependency on $m/lib/color *)
$DEF M_LIB_COLOR

(* End configurable options *)

(* ------------------------------------------------------------------------ *)

$PUBDEF :

$IFDEF M_LIB_COLOR
  $INCLUDE $m/lib/color
$ENDIF

: cast_targets ( d -- Y )
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

$IFDEF M_LIB_COLOR
: array_notify_color[ y:strings y:targets -- ]
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
$ELSE
: array_notify_color ( y y -- )
  array_notify
;
$ENDIF

(*****************************************************************************)
(*                      M-LIB-NOTIFY-array_notify_color                      *)
(*****************************************************************************)
: M-LIB-NOTIFY-array_notify_color[ y:strings y:targets -- ]
  (* Permissions inherited *)

  strings @ array? not if "Non-array argument (1)." abort then
  strings @ foreach nip string? not if "Array of strings expected (1)." abort then repeat
  targets @ array? not if "Non-array argument (2)." abort then
  targets @ foreach nip dbref? not if "Array of dbrefs expected (2)." abort then repeat

  strings @ targets @ array_notify_color
;
PUBLIC M-LIB-NOTIFY-array_notify_color
$LIBDEF M-LIB-NOTIFY-array_notify_color

(*****************************************************************************)
(*                             M-LIB-NOTIFY-cast                             *)
(*****************************************************************************)
: M-LIB-NOTIFY-cast ( s -- )
  (* Permissions inherited *)

  "s" checkargs

  1 array_make me @ begin location dup room? until cast_targets array_notify
;
PUBLIC M-LIB-NOTIFY-cast
$LIBDEF M-LIB-NOTIFY-cast

(*****************************************************************************)
(*                          M-LIB-NOTIFY-cast_color                          *)
(*****************************************************************************)
: M-LIB-NOTIFY-cast_color ( s -- )
  (* Permissions inherited *)

  "s" checkargs

  1 array_make me @ begin location dup room? until cast_targets array_notify_color
;
PUBLIC M-LIB-NOTIFY-cast_color
$LIBDEF M-LIB-NOTIFY-cast_color

(*****************************************************************************)
(*                         M-LIB-NOTIFY-cast_targets                         *)
(*****************************************************************************)
: M-LIB-NOTIFY-cast_targets[ d:object -- ]
  (* Permissions inherited *)

  object @ dbref? not if "Non-dbref argument (1)." abort then

  object @ cast_targets
;
PUBLIC M-LIB-NOTIFY-cast_targets
$LIBDEF M-LIB-NOTIFY-cast_targets

(*****************************************************************************)
(*                         M-LIB-NOTIFY-notify_color                         *)
(*****************************************************************************)
: M-LIB-NOTIFY-notify_color ( d s -- )
  (* Permissions inherited *)

  "ds" checkargs

  1 array_make swap 1 array_make array_notify_color
;
PUBLIC M-LIB-NOTIFY-notify_color
$LIBDEF M-LIB-NOTIFY-notify_color

(*****************************************************************************)
(*                            M-LIB-NOTIFY-ocast                             *)
(*****************************************************************************)
: M-LIB-NOTIFY-ocast ( s -- )
  (* Permissions inherited *)

  "s" checkargs

  1 array_make { me @ }list me @ begin location dup room? until cast_targets array_diff array_notify
;
PUBLIC M-LIB-NOTIFY-ocast
$LIBDEF M-LIB-NOTIFY-ocast

(*****************************************************************************)
(*                         M-LIB-NOTIFY-ocast_color                          *)
(*****************************************************************************)
: M-LIB-NOTIFY-ocast_color ( s -- )
  (* Permissions inherited *)

  "s" checkargs

  1 array_make { me @ }list me @ begin location dup room? until cast_targets array_diff array_notify_color
;
PUBLIC M-LIB-NOTIFY-ocast_color
$LIBDEF M-LIB-NOTIFY-ocast_color

(*****************************************************************************)
(*                         M-LIB-NOTIFY-otell_color                          *)
(*****************************************************************************)
: M-LIB-NOTIFY-otell_color ( s -- )
  (* Permissions inherited *) 

  "s" checkargs

  1 array_make { me @ }list loc @ contents_array array_diff array_notify_color
;
PUBLIC M-LIB-NOTIFY-otell_color
$LIBDEF M-LIB-NOTIFY-otell_color

(*****************************************************************************)
(*                          M-LIB-NOTIFY-tell_color                          *)
(*****************************************************************************)
: M-LIB-NOTIFY-tell_color ( s -- )
  (* Permissions inherited *)

  "s" checkargs

  1 array_make { me @ }list array_notify_color
;
PUBLIC M-LIB-NOTIFY-tell_color
$LIBDEF M-LIB-NOTIFY-tell_color

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-notify.muf=m/lib/notify
!@set $m/lib/notify=M2
!@set $m/lib/notify=H
!@set $m/lib/notify=S
!@set $m/lib/notify=L

