!@program m-cmd-@who.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@who.muf - $m/cmd/at_who                                            *)
(*   Displays a list of connected players.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy - November, 2019                            *)
(*     - Original implementation.                                            *)
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
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    Displays connected players.
$DOCCMD  @list __PROG__=2-30

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/string
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/color
$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/room

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .err M-LIB-THEME-err

(* ------------------------------------------------------------------------- *)

: M-HELP-desc ( s -- s )
  pop
  "Display connected players."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " [#room]" }join
    " "
    "  Displays all connected players on the server. If #room is specified, then only players in the current room will be displayed, including sleeping players and puppet objects."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: gradient[ str:source int:bright int:dim -- str:result ]
  "" var! result
  source @ strlen var! source_length
  begin
    source @ not if break then
    source @ strlen float source_length @ float / bright @ dim @ - * int dim @ + var! brightness
    source @ 1 strcut source !
    { "[#" brightness @ M-LIB-STRING-itox dup dup "]" }join swap strcat
    result @ swap strcat result !
  repeat
  result @
;

$DEF .color_fillfield rot M-LIB-COLOR-strlen - dup 1 < if pop pop "" else * then

: table_column_widths[ arr:data -- arr:widths ]
  { }list var! widths
  data @ foreach
    var! row
    var! row_num
    row @ foreach
      var! cell
      var! column_num
      cell @ M-LIB-COLOR-strlen var! cell_width
      widths @ column_num @ [] var! column_width
      cell_width @ column_width @ > if
        begin
          widths @ array_count column_num @ > if break then
          0 widths @ []<- widths !
        repeat
        cell_width @ ++ widths @ column_num @ ->[] widths !
      then
    repeat
  repeat
  widths @
;

: table_render_header[ arr:row arr:widths -- str:line ]
  "" var! line
  row @ foreach
    var! cell
    var! column_num
    widths @ column_num @ [] var! column_width
    "[#FFFFFF]" cell @ strcat
    column_num @ row @ array_count -- < if
      dup "_" column_width @ 2 - .color_fillfield 255 85 gradient M-LIB-COLOR-strcat
      dup " " column_width @ .color_fillfield M-LIB-COLOR-strcat
    else
      dup "_" column_width @ .color_fillfield 255 85 gradient M-LIB-COLOR-strcat
    then
    line @ swap M-LIB-COLOR-strcat line !
  repeat
  line @
;

$DEF FOOTER_BRACKET_OPEN "[#555555]-[#AAAAAA]-[#FFFFFF]-( "
$DEF FOOTER_BRACKET_CLOSE "[#FFFFFF] )-[#AAAAAA]-[#555555]-"
: table_render_footer[ dict:opts arr:widths -- str:line ]
  0 var! width
  widths @ foreach nip width @ + width ! repeat
  { FOOTER_BRACKET_OPEN opts @ "footer_left" [] dup not if pop "" then FOOTER_BRACKET_CLOSE }join var! footer_left
  { FOOTER_BRACKET_OPEN opts @ "footer_right" [] dup not if pop "" then FOOTER_BRACKET_CLOSE }join var! footer_right
  { footer_left @ footer_left @ footer_right @ strcat "-" width @ .color_fillfield footer_right @ }join
;

: table_render[ arr:data dict:opts -- arr:lines ]
  { }list var! lines
  var line
  var cell
  var column_num
  var column_width
  var row
  var row_num
  (* Precalculate column widths *)
  opts @ "widths" []
  dup not if data @ table_column_widths then
  var! widths
  (* Draw header *)
  data @ 1 array_cut data ! 0 [] widths @ table_render_header lines @ []<- lines !
  (* Draw body *)
  data @ foreach
    row !
    row_num !
    "" line !
    row @ foreach
      cell !
      column_num !
      widths @ column_num @ [] column_width !
      cell @ M-LIB-COLOR-strlen column_width @ > if cell @ column_width @ M-LIB-COLOR-strcut pop cell ! then
      line @ cell @ dup " " column_width @ .color_fillfield M-LIB-COLOR-strcat M-LIB-COLOR-strcat line !
    repeat
    line @ lines @ []<- lines !
  repeat
  (* Draw footer *)
  opts @ widths @ table_render_footer lines @ []<- lines !
  (* Return lines *)
  lines @
;

: sex_color ( s -- s )
  dup M-LIB-GRAMMAR-sex_category
  dup "female" stringcmp not if
    pop "[#FF55FF]"
  else dup "hermaphrodite" stringcmp not if
    pop "[#55FF55]"
  else dup "male" stringcmp not if
    pop "[#5555FF]"
  else dup "neuter" stringcmp not if
    pop "[#AAAAAA]"
  else dup "nonbinary" stringcmp not if
    pop "[#00AA00]"
  else
    pop "[#555555]"
  then then then then then
  swap strcat
;

: sex_color_chr ( s -- s )
  M-LIB-GRAMMAR-sex_category
  dup "female" stringcmp not if
    pop "[#FF55FF]F"
  else dup "hermaphrodite" stringcmp not if
    pop "[#55FF55]H"
  else dup "male" stringcmp not if
    pop "[#5555FF]M"
  else dup "neuter" stringcmp not if
    pop "[#AAAAAA]N"
  else dup "nonbinary" stringcmp not if
    pop "[#00AA00]X"
  else
    pop "[#555555]?"
  then then then then then
;

: short_time ( d -- s )
  dup 31536000 >= if
    31536000 / intostr "y" strcat
  else dup 86400 >= if
    86400 / intostr "d" strcat
  else dup 3600 >= if
    3600 / intostr "h" strcat
  else dup 60 >= if
    60 / intostr "m" strcat
  else
    intostr "s" strcat
  then then then then
;

: main ( s --  )
  strip
  dup if
    "#room" stringcmp not if
      1
    else
      "Unrecognized #option." .err .tell
      exit
    then
  else
    0
  then
  var! room_only
  room_only @ if
    me @ begin dup room? if break then location repeat var! room
    0 var! room_awake
    0 var! room_asleep
    (* Construct a room_players data structure with information on room players/puppets *)
    { }list var! room_players
    room @ M-LIB-NOTIFY-cast_targets foreach
      nip
      var! room_player
      room_player @ thing? room_player @ "ZOMBIE" flag? and not room_player @ player? not and if continue then
      room_player @ "DARK" flag? if continue then
      {
        "name"       room_player @ name
        "theme_name" room_player @ M-LIB-THEME-name
        "sex"        room_player @ "gender_prop" sysparm getpropstr sex_color
        "species"    room_player @ "_/species" getpropstr
      }dict room_players @ []<- room_players !
      room_player @ awake? if
        room_awake ++
      else
        room_asleep ++
      then
    repeat
    (* Convert room_players into a 2D list array, and render it as a table *)
    {
      { "Name" "Sex" "Species" }list
      room_players @ SORTTYPE_CASE_ASCEND "name" array_sort_indexed foreach
        nip
        var! room_player_entry
        {
          room_player_entry @ "theme_name" []
          room_player_entry @ "sex" []
          room_player_entry @ "species" []
        }list
      repeat
    }list { "widths" { 33 16 30 }list "footer_right" { room_awake @ "/" room_asleep @ " " room @ name }join }dict table_render { me @ }list M-LIB-NOTIFY-array_notify_color
  else
    (* Construct a all_players data structure with information on connected players *)
    { }dict var! all_players
    #-1 descr_array foreach
      nip
      var! player_descr
      player_descr @ descrdbref var! player_dbref
      player_dbref @ not if continue then
      player_dbref @ "DARK" flag? if continue then
      all_players @ player_dbref @ int [] var! player_entry
      player_entry @ if
        (* If the connected time is higher, take that instead *)
        player_descr @ descrtime player_entry @ "on_time" [] > if
          player_descr @ descrtime player_entry @ "on_time" ->[] player_entry !
        then
        (* If the idle time is lower, take that instead *)
        player_descr @ descridle player_entry @ "idle_time" [] < if
          player_descr @ descridle player_entry @ "idle_time" ->[] player_entry !
        then
      else
        {
          "name"           player_dbref @ name
          "on_time"        player_descr @ descrtime
          "idle_time"      player_descr @ descridle
          "theme_name"     player_dbref @ M-LIB-THEME-name
          "sex"            player_dbref @ "gender_prop" sysparm getpropstr sex_color_chr
          "species"        player_dbref @ "_/species" getpropstr
          "theme_location" player_dbref @ location dup M-LIB-ROOM-public? if M-LIB-THEME-name else pop "[#555555](Private)" then
          "location"       player_dbref @ location dup M-LIB-ROOM-public? if name else pop "(Private)" then
        }dict player_entry !
      then
      player_entry @ "idle_time" [] short_time player_entry @ "idle_time_str" ->[] player_entry !
      player_entry @ "on_time" [] short_time player_entry @ "on_time_str" ->[] player_entry !
      player_entry @ all_players @ player_dbref @ int ->[] all_players !
    repeat
    (* Convert all_players into a 2D list array, and render it as a table *)
    {
      { "Name" "S" "Species" "Time" "Idle" "Location" }list
      { all_players @ foreach nip repeat }list SORTTYPE_CASE_ASCEND "name" array_sort_indexed SORTTYPE_CASE_ASCEND "location" array_sort_indexed foreach
        nip
        var! room_player_entry
        {
          room_player_entry @ "theme_name" []
          room_player_entry @ "sex" []
          room_player_entry @ "species" []
          room_player_entry @ "on_time_str" []
          room_player_entry @ "idle_time_str" []
          room_player_entry @ "theme_location" []
        }list
      repeat
    }list {
      "widths" { 24 3 17 5 5 25 }list
      "footer_left" { all_players @ array_count intostr " Players Online" }join
      "footer_right" { "%H:%M - %F" systime timefmt }join
    }dict table_render { me @ }list M-LIB-NOTIFY-array_notify_color
  then
;
.
c
q
!@register m-cmd-@who.muf=m/cmd/at_who
!@set $m/cmd/at_who=M3


