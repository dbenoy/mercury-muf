!@program m-cmd-@whereis.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@whereis.muf $m/cmd/at_whereis                                      *)
(*   Outputs the location of another player.                                 *)
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
$NOTE    Shows the location of another player.
$DOCCMD  @list __PROG__=2-28

(* Begin configurable options *)

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/room
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/match
$INCLUDE $m/lib/theme
$INCLUDE $m/cmd/at_map

(* ------------------------------------------------------------------------- *)

: M-HELP-desc ( s -- s )
  pop
  "Show a player's location."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " [#nomap ]<player>[=<mapname>]" }join
    " "
    "  Displays the location of another player. Unless #nomap is specified, the map at the location of the player will also be shown. If a map name is specified, it will show the player's location on that map. The map program (Typically @map #list) can display a list of globally available maps."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: location_text[ ref:player -- str:result ]
  "" var! result
  {
    player @ begin
      location
      dup not if pop break then
      dup room? not if continue then
      dup M-LIB-ROOM-public? not if continue then
      "%t" { 3 pick }list { }dict M-LIB-GRAMMAR-sub swap
    repeat
  }list ", " array_join
;

: main ( s --  )
  dup "#nomap " stringpfx if 7 strcut swap pop 0 else 1 then var! show_map
  "=" split
  var! map_room
  var! player
  player @ not if
    "Please specify a player." .theme_err .color_tell
    exit
  then
  player @ { "quiet" "no" "match_start" "online" }dict M-LIB-MATCH-pmatch player !
  player @ 0 < if exit then
  player @ begin dup room? if break then location repeat var! player_room
  player_room @ M-LIB-ROOM-public? not if
    { player @ name " is in a private location." }join .theme_err .color_tell
    exit
  then
  map_room @ if
    map_room @ M-CMD-AT_MAP-match
    dup #-2 = if
      pop "I don't know which one you mean!" .theme_err .color_tell
      exit
    then
    dup ok? not if
      pop "I can't find that map." .theme_err .color_tell
      exit
    then
  else
    player @ location
  then
  map_room !
  show_map @ if
    player @ map_room @ M-CMD-AT_MAP-display
  then
  { player @ name " is " player @ location_text "." }join .tell
;
.
c
q
!@register m-cmd-@whereis=m/cmd/at_whereis
!@set $m/cmd/at_whereis=M3

