!@program m-cmd-map.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-map.muf - $m/cmd/map                                                *)
(*   Views maps created by the @map command.                                 *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- September, 2019                          *)
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
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    Map viewer.  
$DOCCMD  @list __PROG__=2-30

$INCLUDE $m/lib/array
$INCLUDE $m/lib/string
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/color
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/map

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .err M-LIB-THEME-err

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Consult the map."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " [<map name>]" }cat
    " "
    "  Views the map of the current area, or a given map by name if available."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: help ( -- )
;

: main ( s --  )
  dup if
    M-LIB-MAP-match

    dup #-2 = if
      pop "I don't know which one you mean!" .err .tell exit
    then

    dup ok? not if
      pop "I can't find that map." .err .tell exit
    then
  else
    pop loc @
  then
  var! map_room

  map_room @ M-LIB-MAP-env_get not if
    "It seems to be uncharted territory." .tell exit
  then

  map_room @
  dup room? if
    (* If you're asking for the map of a room, show your position on that room's map *)
    loc @
  else
    (* Otherwise, show the position of the object on its own map. *)
    dup
  then
  M-LIB-MAP-render { me @ }list M-LIB-NOTIFY-array_notify_color
  M-LIB-MAP-reg_get var! other_maps
  {
    me @ begin
      dup location
      over map_room @ = if
        swap pop
      then
      dup while
    repeat
    pop
  }list var! other_env
  {
    other_maps @ foreach
      swap stod other_env @ M-LIB-ARRAY-hasval not if pop then
    repeat
  }list other_maps !
  other_maps @ if
    { "The " other_maps @ "and" M-LIB-STRING-oxford_join M-LIB-COLOR-escape " map" other_maps @ array_count 1 > if "s are " else " is " then "available here, too." }cat .tell
  then
;
.
c
q
!@register m-cmd-map.muf=m/cmd/map
!@set $m/cmd/map=M3

