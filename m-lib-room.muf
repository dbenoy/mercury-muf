!@program m-lib-room.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-sec.muf - $m/lib/room                                               *)
(*   Helper routines for room objects.                                       *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC FUNCTIONS:                                                         *)
(*   M-LIB-ROOM-directions[ ref:room -- str:directions ]                     *)
(*     Returns a short string describing how to get to the room. Max 40      *)
(*     characters.                                                           *)
(*                                                                           *)
(*   M-LIB-ROOM-public?[ ref:room -- bool:public? ]                          *)
(*     Checks if the room is 'public' meaning it's marked as okay for        *)
(*     programs to reveal the name of the room and the listing of players    *)
(*     present when listing rooms.                                           *)
(*                                                                           *)
(*   M-LIB-ROOM-short_desc[ ref:room -- str:desc ]                           *)
(*     Returns a short string describing the room. Max 80 characters.        *)
(*                                                                           *)
(* PROPERTIES:                                                               *)
(*   "_room/directions"                                                      *)
(*     On any room: A short string describing how to get to the room for use *)
(*     with room listing and player finding commands. Strings over 40        *)
(*     characters are ignored.                                               *)
(*                                                                           *)
(*   "_room/short_desc"                                                      *)
(*     On any room: A short string describing the room for use with room     *)
(*     listing, player finding, and quick room info commands. Strings over   *)
(*     80 characters are ignored.                                            *)
(*                                                                           *)
(*   "_room/public"                                                          *)
(*     On any room: If this is set to "yes" it advises public room listing   *)
(*     commands that it is okay to display this room's name and players.     *)
(*     If this is not set it may use the value from environment rooms        *)
(*     instead. Defaults to 'yes'. #0 is never public. HAVEN or DARK rooms   *)
(*     are never public.                                                     *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy - November 2019                             *)
(*      - Original implementation.                                           *)
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
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    Fetches information about room objects.
$DOCCMD  @list __PROG__=2-30

$PUBDEF :

(*****************************************************************************)
(*                           M-LIB-ROOM-directions                           *)
(*****************************************************************************)
: M-LIB-ROOM-directions[ ref:room -- str:directions ]
  (* Permissions inherited *)
  room @ dbref? not if "Non-dbref argument (1)." abort then
  room @ room? not if "Non-room argument (1)." abort then
  room @ "_room/directions" getpropstr
  dup strlen 40 <= not if pop "" then
;
PUBLIC M-LIB-ROOM-directions
$LIBDEF M-LIB-ROOM-directions

(*****************************************************************************)
(*                            M-LIB-ROOM-public?                             *)
(*****************************************************************************)
: M-LIB-ROOM-public?[ ref:room -- bool:public? ]
  (* Permissions inherited *)
  room @ dbref? not if "Non-dbref argument (1)." abort then
  room @ room? not if "Non-room argument (1)." abort then
  room @ #0 = if 0 exit then
  room @ "HAVEN" flag? if 0 exit then
  room @ "DARK" flag? if 0 exit then
  room @ "_room/public" envpropstr swap pop "no" stringcmp
;
PUBLIC M-LIB-ROOM-public?
$LIBDEF M-LIB-ROOM-public?

(*****************************************************************************)
(*                           M-LIB-ROOM-short_desc                           *)
(*****************************************************************************)
: M-LIB-ROOM-short_desc[ ref:room -- str:desc ]
  (* Permissions inherited *)
  room @ dbref? not if "Non-dbref argument (1)." abort then
  room @ room? not if "Non-room argument (1)." abort then
  room @ "_room/short_desc" getpropstr
  dup strlen 80 <= not if pop "" then
;
PUBLIC M-LIB-ROOM-short_desc
$LIBDEF M-LIB-ROOM-short_desc

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-room.muf=m/lib/room
!@set $m/lib/room=M2
!@set $m/lib/room=H
!@set $m/lib/room=S
!@set $m/lib/room=L

