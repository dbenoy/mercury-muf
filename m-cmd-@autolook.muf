!@program m-cmd-@autolook.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@autolook.muf - $m/cmd/at_autolook                                  *)
(*   A command for showing basic information on the room you're in, for use  *)
(*   with '@tune autolook_cmd'.                                              *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PROPERTIES:                                                               *)
(*   "_room/short_desc"                                                      *)
(*     On rooms: The description shown if you have enabled the option        *)
(*     "_config/autolook/location_shortdesc". Strings longer than 80         *)
(*     characters are ignored.                                               *)
(*                                                                           *)
(*   "_config/autolook/map"                                                  *)
(*     On the object using @autolook: Display the map using $m/cmd/at_map    *)
(*                                                                           *)
(*   "_config/autolook/location_name"                                        *)
(*     On the object using @autolook: Display the name of the location.      *)
(*                                                                           *)
(*   "_config/autolook/location_desc"                                        *)
(*     On the object using @autolook: Display the full description of the    *)
(*     location.                                                             *)
(*                                                                           *)
(*   "_config/autolook/location_short_desc"                                  *)
(*     On the object using @autolook: Display the _shotrdesc of the          *)
(*     location.                                                             *)
(*                                                                           *)
(*   "_config/autolook/location_exits"                                       *)
(*     On the object using @autolook: Display a list of exits in the         *)
(*     location.                                                             *)
(*                                                                           *)
(*   "_config/autolook/location_players"                                     *)
(*     On the object using @autolook: Display a list of players in the       *)
(*     location.                                                             *)
(*                                                                           *)
(*   "_config/autolook/location_things"                                      *)
(*     On the object using @autolook: Display a list of thing objects in the *)
(*     location.                                                             *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- November, 2019                           *)
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
$NOTE    Auto look for @tune autolook_cmd.
$DOCCMD  @list __PROG__=2-62

(* Begin configurable options *)

$DEF CONFIG_PROPDIR "_config/autolook"

lvar g_config_defaults
: config_defaults
  g_config_defaults @ if g_config_defaults @ exit then
  {
    "map"                 "yes"
    "location_name"       "yes"
    "location_desc"       "no"
    "location_short_desc" "yes"
    "location_exits"      "yes"
    "location_players"    "yes"
    "location_things"     "no"
  }dict dup g_config_defaults !
;

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/theme
$INCLUDE $m/lib/color
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/map

$DEF .notify M-LIB-NOTIFY-notify_color

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( s -- s )
  pop
  "Show location info."
;
WIZCALL M-HELP-desc

: M-HELP-help ( s -- a )
  ";" split pop toupper var! action_name
  {
    action_name @
    " "
    "  Shows information on your current location. This command is meant to be run automatically when you first arrive in a room. Some rooms may not be shown based on privacy settings."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: enabled[ str:opt_name -- bool:enabled? ]
  me @ { CONFIG_PROPDIR "/" opt_name @ }cat getpropstr
  dup not if
    pop config_defaults opt_name @ []
    dup not if
      pop "yes"
    then
  then
  "no" stringcmp
;

: notify_objects[ ref:notify_me str:title arr:objects -- ]
  objects @ not if exit then
  {
    objects @ foreach
      nip
      dup exit? if
        M-LIB-THEME-fancy_exit
      else
        M-LIB-THEME-name
      then
      "[!FFFFFF]" strcat
    repeat
  }list objects !
  0 var! objects_total_length
  objects @ foreach
    nip
    objects_total_length @ swap M-LIB-COLOR-strlen + objects_total_length !
  repeat
  objects_total_length @ 150 < if
    notify_me @ { "[ [#FFFFFF]" title @ ":" " " 8 title @ strlen - * }cat objects @ "and" M-LIB-GRAMMAR-oxford_join M-LIB-COLOR-strcat "[!FFFFFF] ]" M-LIB-COLOR-strcat .notify
  else
    notify_me @ { "[#FFFFFF]" title @ ":" }cat .notify
    objects @ foreach
      nip
      me @ "  " rot strcat .notify
    repeat
  then
;

: notify_autolook[ ref:notify_me -- ]
  (* Show room map *)
  "map" enabled if
    loc @ loc @ M-LIB-MAP-display pop
  then
  (* Show room name *)
  "location_name" enabled if
    me @ loc @ M-LIB-THEME-name .notify
  then
  (* Show room short description *)
  0 var! short_desc_shown
  loc @ room? if
    "location_short_desc" enabled if
      loc @ "_room/short_desc" getpropstr
      dup over strlen 80 <= and if
        notify_me @ swap notify
        1 short_desc_shown !
      then
    then
  then
  (* Show room description *)
  "location_desc" enabled if
    loc @ "_/de" "(@Desc)" 1 parseprop
    dup if
      (* Add a blank line if both types of descs are shown *)
      short_desc_shown @ if notify_me @ " " notify then
      notify_me @ swap notify
    then
  then
  (* Show room exits *)
  "location_exits" enabled if
    me @ "Exits" loc @ exits_array notify_objects
  then
  (* Show room players *)
  "location_players" enabled if
    me @ "Players" { loc @ contents_array foreach nip dup player? not if pop then repeat }list notify_objects
  then
  (* Show room things *)
  "location_things" enabled if
    me @ "Things" { loc @ contents_array foreach nip dup player? over room? or if pop then repeat }list notify_objects
  then
;

: main ( s --  )
  pop
  me @ notify_autolook
;
.
c
q
!@register m-cmd-@autolook.muf=m/cmd/at_autolook
!@set $m/cmd/at_autolook=M3

