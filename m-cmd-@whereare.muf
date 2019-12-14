!@program m-cmd-@whereare.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@whereare.muf $m/cmd/at_whereare                                    *)
(*   A command for displaying the populations of public areas.               *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- November, 2019                           *)
(*      - Original implementation.                                           *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2019  Daniel Benoy                                          *)
(*                                                                           *)
(* This program is free software; you can redistribute it and/or modify      *)
(* it under the terms of the GNU General Public License as published by      *)
(* the Free Software Foundation; either version 2 of the License, or         *)
(* {at your option} any later version.                                       *)
(*                                                                           *)
(* This program is distributed in the hope that it will be useful,           *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of            *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *)
(* GNU General Public License for more details.                              *)
(*                                                                           *)
(* You should have received a copy of the GNU General Public License         *)
(* along with this program; if not, write to the Free Software               *)
(* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA   *)
(*****************************************************************************)
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    Shows locations of players
$DOCCMD  @list __PROG__=2-<last header line>

(* Begin configurable options *)

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/room
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/color
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/grammar

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .tag M-LIB-THEME-tag
$DEF .tag_err M-LIB-THEME-tag_err

(* ------------------------------------------------------------------------- *)

: M-HELP-desc ( s -- s )
  pop
  "Show player locations."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " [<threshold>]" }cat
    " "
    "  Lists all rooms that contain players. If a <threshold> number is supplied, then it will only list rooms with that many players or more."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

$PUBDEF :

(* Checks if a room has any child rooms *)
: envroom? ( d -- b )
  contents_array foreach
    nip
    room? if 1 exit then
  repeat
  0
;

$DEFINE ROOM_INFO_DEFAULT
  {
    "parent" #-1
    "children" { }list
    "players" { }list
  }dict
$ENDDEF
: room_info_get[ int:threshold -- dict:room_info ]
  { }dict var! room_info
  (* Start with an array of all player locations, and a 'players' dict element listing all the players in those locations *)
  online_array foreach
    nip
    var! player_ref
    player_ref @ begin location dup room? if break then repeat var! player_room
    (* Skip this player if the room is ineligible *)
    player_room @ M-LIB-ROOM-public? not player_room @ envroom? or if
      continue
    then
    (* Create room entry if needed and add the player *)
    room_info @ player_room @ int []
    dup not if pop ROOM_INFO_DEFAULT then
    dup "players" []
    player_ref @ swap []<-
    { }list array_union (* Removes duplicates *)
    swap "players" ->[]
    room_info @ player_room @ int ->[] room_info !
  repeat
  (* Strip out rooms with fewer than the required number of players *)
  {
    room_info @ foreach
      dup "players" [] array_count threshold @ < if
        pop pop
      then
    repeat
  }dict room_info !
  (* If no players were elegible, then we're done. *)
  room_info @ not if
    { }dict exit
  then
  (* Add parent locations, and parent/child links *)
  room_info @ foreach
    var! location_entry
    var! location_id
    location_id @ dbref var! this_child
    { location_id @ dbref begin location dup not if pop break then dup repeat }list foreach
      nip
      var! this_parent
      (* Skip to the next parent if this one is inelegible, but always allow #0. *)
      this_parent @ #0 != if
        this_parent @ M-LIB-ROOM-public? not if
          continue
        then
      then
      (* Add the parent relationship to this location's entry *)
      room_info @ this_child @ int []
      dup not if pop ROOM_INFO_DEFAULT then
      this_parent @ swap "parent" ->[]
      room_info @ this_child @ int ->[]
      room_info !
      (* Add the child relationship to the parent's entry *)
      room_info @ this_parent @ int []
      dup not if pop ROOM_INFO_DEFAULT then
      dup "children" []
      this_child @ swap []<-
      { }list array_union (* Removes duplicates *)
      swap "children" ->[]
      room_info @ this_parent @ int ->[]
      room_info !
      (* Continue ascending the tree to look for this parent's parent *)
      this_parent @ this_child !
    repeat
  repeat
  (* Return data structure *)
  room_info @
;
PUBLIC room_info_get
$LIBDEF room_info_get

$DEF TRUNCATE_LENGTH 80
: truncated_join[ arr:join_me -- str:result ]
  join_me @ not if "" exit then
  join_me @ 1 array_cut join_me ! 0 []
  var! result
  begin
    join_me @ not if break then
    result @ M-LIB-COLOR-strlen TRUNCATE_LENGTH >= if break then
    join_me @ 1 array_cut join_me ! 0 []
    result @ "[!FFFFFF], " strcat swap strcat result !
  repeat
  join_me @ if
    { result @ "[!FFFFFF] (and " join_me @ array_count intostr " more)" }cat result !
  then
  result @
;

: room_info_render[ arr:room_info int:room_id -- arr:lines ]
  { }list var! lines
  room_info @ room_id @ [] var! room_info_entry
  room_id @ dbref var! room_dbref
  room_dbref @ envroom? if
    #0 room_dbref @ = not if
      "[#555555]%T:" { room_dbref @ }list { }dict M-LIB-GRAMMAR-sub lines @ []<- lines !
    then
    (* Display this room's children *)
    room_info_entry @ "children" [] foreach
      nip
      int var! child_id
      room_info @ child_id @ room_info_render foreach
        nip
        #0 room_dbref @ = if
          "| " swap strcat
        else
          "  " swap strcat
        then
        lines @ []<- lines !
      repeat
    repeat
  else
    (* Sort active/inactive players *)
    { }list var! players_active
    { }list var! players_idle
    room_info_entry @ "players" [] foreach
      nip
      dup awake? not if
        pop continue
      then
      var! player_this
      {
        "name" player_this @ name
        "theme_name" player_this @ M-LIB-THEME-name
      }dict
      player_this @ M-LIB-THEME-idle? if
        players_idle @ []<- players_idle !
      else
        players_active @ []<- players_active !
      then
    repeat
    (* Sort and strip out sorting key data structure *)
    { players_active @ SORTTYPE_CASE_ASCEND "name" array_sort_indexed foreach nip "theme_name" [] repeat }list players_active !
    { players_idle @ SORTTYPE_CASE_ASCEND "name" array_sort_indexed foreach nip "theme_name" [] repeat }list players_idle !
    (* Fetch directions if any *)
    room_dbref @ M-LIB-ROOM-directions var! room_directions
    (* Add lines to list *)
    lines @
    { room_dbref @ M-LIB-THEME-name }cat
    room_directions @ if { "[!FFFFFF] ([#AA5500]" room_directions @ "[!FFFFFF])" }cat strcat then
    swap []<-
    players_active @ if  { "  [#FFFFFF]Awake:[!FFFFFF]  " players_active @ truncated_join }cat swap []<- then
    players_idle @ if    { "  [#FFFFFF]Idle:[!FFFFFF]   " players_idle @ truncated_join }cat swap []<- then
    lines !
  then
  lines @
;

: main ( s --  )
  dup not if pop "1" then
  var! threshold
  threshold @ number? not if
    "Invalid threshold value." command @ toupper .tag_err .tell exit
  then
  threshold @ atoi threshold !
  threshold @ 0 <= if
    "Invalid threshold value." command @ toupper .tag_err .tell exit
  then
  threshold @ room_info_get
  dup not if
    pop 
    { "No locations found with " threshold @ intostr " or more players." }cat command @ toupper .tag_err .tell
    exit
  then
  "/----" command @ toupper .tag .tell
  0 room_info_render foreach
    nip
    command @ toupper .tag .tell
  repeat
  "\\----" command @ toupper .tag .tell
;
.
c
q
!@register m-cmd-@whereare=m/cmd/at_whereare
!@set $m/cmd/at_whereare=M3

