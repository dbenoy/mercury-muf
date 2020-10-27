!@program m-cmd-whisper.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-whisper.muf - $m/cmd/whisper                                        *)
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

(* Begin configurable options *)

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/match
$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/emote
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/color

$DEF .notify M-LIB-NOTIFY-notify_color

(* ------------------------------------------------------------------------- *)

: M-HELP-desc ( d -- s )
  pop
  "Private message a player or object."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop var! action_name
  {
    { action_name @ toupper " <player>=[:]<message>" }cat
    " "
    "Send a private message to a player or object in your location. If the message starts with a colon it acts as a 'pose style' message."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  "=" split
  over not over not or if
    pop
    "What do you want to whisper?" tell
    exit
  then
  1 var! highlight_quote_level_min
  dup ":" instr 1 = if
    1 strcut swap pop
    me @ name
    over pose-separator? not if
      " " strcat
    then
    swap strcat
    0 highlight_quote_level_min !
  then
  var! message
  {
    "quiet" "no"
    "match_absolute"   "no"
    "match_player"     "no"
    "match_registered" "no"
    "match_me"         "yes"
    "match_here"       "no"
    "match_home"       "no"
    "match_nil"        "no"
  }dict M-LIB-MATCH-match
  dup not if pop exit then
  var! to
  (* Check if the target is online *)
  to @ player? to @ thing? to @ "ZOMBIE" flag? and or not to @ owner awake? not or if
    "%N is not connected." { to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub tell
    exit
  then
  (* Notify the target *)
  to @
  message @ {
    "from" me @
    "to" to @
    "message_format" "[!FFFFFF]%I whispers \"@1[!FFFFFF]\" to you." { me @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub 
    "highlight_mention" "no"
    "highlight_quote_level_min" highlight_quote_level_min @
  }dict M-LIB-EMOTE-style
  .notify
  (* Notify self with a copy *)
  me @
  message @ {
    "from" me @
    "to" me @
    "message_format" "[!FFFFFF]You whisper \"@1[!FFFFFF]\" to %i." { to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub 
    "highlight_mention" "no"
    "highlight_quote_level_min" highlight_quote_level_min @
  }dict M-LIB-EMOTE-style
  .notify
;
.
c
q
!@register m-cmd-whisper.muf=m/cmd/whisper
!@set $m/cmd/whisper=M3

