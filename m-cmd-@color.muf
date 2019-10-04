!@program m-cmd-@color.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@color.muf - $m/cmd/at_color                                        *)
(*   Manage text color settings.                                             *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy - October, 2019                             *)
(*      - Original Implementation                                            *)
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
$VERSION 1.0
$AUTHOR  Daniel Benoy
$NOTE    Manage text color settings.
$DOCCMD  @list __PROG__=2-30

$include $m/lib/color

(* ------------------------------------------------------------------------ *)

: itox1 ( i -- s )
  dup 16 >= over 0 < or if
    "Only converts one hexadecimal digit." abort
  then

  dup 10 < if
    intostr
  else
    10 - "A" ctoi + itoc
  then
;

: itox2 ( i -- s )
  dup 256 >= over 0 < or if
    "Only converts one byte values into hex." abort
  then

  dup 16 / itox1 swap 16 % itox1 strcat
;

: text_gradient[ str:color_me int:red int:green int:blue int:step_red int:step_green int:step_blue bool:reverse -- str:result ]
  "" var! retval
  begin
    (* Split off one character *)
    reverse @ if
      color_me @ dup strlen 1 - strcut swap color_me !
    else
      color_me @ 1 strcut color_me !
    then
    (* Colorize the character *)
    { "[#" red @ itox2 green @ itox2 blue @ itox2 "]" }join swap strcat
    (* Concatinate the character with retval *)
    reverse @ if
      retval @ strcat retval !
    else
      retval @ swap strcat retval !
    then
    (* Increment the counters *)
    red @ step_red @ + red !
    red @ 0 < if 0 red ! then
    red @ 255 > if 255 red ! then
    green @ step_green @ + green !
    green @ 0 < if 0 green ! then
    green @ 255 > if 255 green ! then
    blue @ step_blue @ + blue !
    blue @ 0 < if 0 blue ! then
    blue @ 255 > if 255 blue ! then
  color_me @ not until
  retval @
;

(* ------------------------------------------------------------------------ *)

: info ( -- )
  {
    { "Current Color Encoding: " 85 85 255 0 15 0 0 text_gradient "[#BBBBBB]" me @ M-LIB-COLOR-encoding_get }join .color_transcode
    " "
    "Available Encodings: " 85 85 255 0 15 0 0 text_gradient .color_transcode
    M-LIB-COLOR-encoding_player_valid foreach
      nip
      { "  [#BBBBBB]" rot }join .color_transcode
    repeat
    "  [#BBBBBB]NOCOLOR" .color_transcode
  }tell
;

: cmd_help ( -- )
  {
    "@COLOR"
    "  Display your current color text settings."
    " "
    "@COLOR #SETUP"
    "  Enter a color test dialog that helps you configure your color text settings."
    " "
    "@COLOR #SET <type>"
    "  Set a specific color encoding type. (e.g. Use '@COLOR #SET NOCOLOR' to turn off color)"
  }tell
;

: cmd_setup ( s -- )
  pop

  me @ "COLOR" flag? var! had_color

  M-LIB-COLOR-encoding_player_valid foreach
    nip
    var! this_option
    " " .tell
    me @ "COLOR" set
    this_option @ M-LIB-COLOR-testpattern { me @ }list array_notify
    had_color @ not if me @ "!COLOR" set then
    " " .tell
    { "Would you like to use " this_option @ "? (y/n)" }join .tell
    begin
      read
      "no" over stringpfx if pop break then
      "yes" over stringpfx if
        me @ "COLOR" set
        me @ this_option @ M-LIB-COLOR-encoding_set
        "Done." 85 85 255 0 50 0 0 text_gradient .color_tell
        exit
      then
    repeat
  repeat

  me @ "!COLOR" set
  "Color disabled." .tell
;

: cmd_set ( s -- b )
  dup "NOCOLOR" stringcmp 0 = if
    pop
    me @ "!COLOR" set
    "Color off." .tell
    exit
  then

  dup 1 array_make M-LIB-COLOR-encoding_player_valid array_intersect not if
    " " .tell
    dup if
      "[#BBBBBB]" swap strcat "Encoding '' unknown." 255 85 85 0 0 15 0 text_gradient 10 .color_strcut rot swap strcat strcat .color_tell
    else
      pop "Please specify an encoding." 255 85 85 0 0 15 0 text_gradient .color_tell
    then
    " " .tell
    info
    " " .tell
    exit
  then

  me @ "COLOR" set
  me @ swap toupper M-LIB-COLOR-encoding_set
  "Done." 85 85 255 0 50 0 0 text_gradient .color_tell
;

: main ( s --  )
  " " split
  strip var! args
  strip var! option
  option @ if
    "#HELP" option @ stringcmp not if args @ cmd_help exit then
    "#SETUP" option @ stringcmp not if args @ cmd_setup exit then
    "#SET"  option @ stringcmp not if args @ cmd_set exit then
  else
    info
    " " .tell
  then
  "See @color #help" 85 85 255 0 18 0 0 text_gradient " for options." 85 85 255 0 18 0 1 text_gradient strcat .color_tell
;
.
c
q
!@register m-cmd-@color.muf=m/cmd/at_color
!@set $m/cmd/at_color=M3

