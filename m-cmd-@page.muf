!@program m-cmd-@page.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@page.muf - $m/cmd/at_page                                          *)
(*   Private communication command using $m/lib/emote                        *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October 2019                             *)
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
$NOTE    Private message command.
$DOCCMD  @list __PROG__=2-30

$include $m/lib/match
$include $m/lib/emote
$include $m/lib/theme
$include $m/lib/color

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Think something."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop var! action_name
  {
    { action_name @ toupper " <player>=[:]<message>" }join
    " "
    "Send a private message to a player. If the message starts with a colon it acts as a 'pose style' message. If a player is offline, the message will be delivered to them the next time they're available."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  dup not if
    pop
    "Please specify a player, and a message." command @ toupper .theme_tag_err .color_tell
    exit
  then
  "=" split
  dup not if
    pop
    "Please specify a message." command @ toupper .theme_tag_err .color_tell
    exit
  then
  var highlight_ooc_style
  dup ":" instr 1 = if
    1 strcut swap pop
    me @ name
    over 1 strcut pop dup "-" = over ":" = or swap "," = or not if
      " " strcat
    then
    swap strcat
    "no" highlight_ooc_style !
  else
    me @ name ": " strcat swap strcat
    "yes" highlight_ooc_style !
  then
  var! message
  { "quiet" "no" "tag" command @ toupper "match_start" "online" }dict M-LIB-MATCH-pmatch
  dup 0 < if pop exit then
  var! to
  to @ awake? if
    to @
    message @ {
      "from" me @
      "to" to @
      "highlight_mention" "no"
      "highlight_ooc_style" highlight_ooc_style @
    }dict M-LIB-EMOTE-style
    "PAGE" .theme_tag .color_notify
    message @ {
      "from" me @
      "to" me @
      "highlight_mention" "no"
      "highlight_ooc_style"
      highlight_ooc_style @
    }dict M-LIB-EMOTE-style { "[#0000AA] (to " to @ name ")" }join .color_strcat
    "PAGE" .theme_tag .color_tell
  else
    { to @ name " is offline." }join command @ toupper .theme_tag .color_tell
  then
;
.
c
q
!@register m-cmd-@page.muf=m/cmd/at_page
!@set $m/cmd/at_page=M3

