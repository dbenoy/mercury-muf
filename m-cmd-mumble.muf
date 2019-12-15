!@program m-cmd-mumble.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-mumble.muf - $m/cmd/mumble                                          *)
(*   Semi-private communication command using $m/lib/emote                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- November 2019                            *)
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
$NOTE    Semi-private message command.
$DOCCMD  @list __PROG__=2-30

(* Begin configurable options *)

$DEF OVERHEAR_REDACT_FACTOR 0.5 (* This fraction of the message will be redacted for overhearing targets *)

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/string
$INCLUDE $m/lib/match
$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/emote
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/color
$INCLUDE $m/lib/array
$INCLUDE $m/lib/notify

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
    { action_name @ toupper " <player>=<message>" }cat
    " "
    "Send a semi-private message to a player or object in your location. All other listeners in the same room will see a portion of the message. Some of it will be redacted, but maybe they might be able to piece together what you said!"
    " "
    "For example, if your name is Igor, and you type 'mumble Sara=I want to give you a present!' then Sara will see the message clearly, but others in the room might see:"
    "  Igor mumbles, \"I want ... ... you ... ...\" to Sara."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: redact[ str:message float:redact_factor ]
  (* Split message on quotes and spaces *)
  message @ " |\"" 0 M-LIB-STRING-regslice var! message_parts
  (* Remove empty elements *)
  { message_parts @ foreach nip dup not if pop then repeat }list message_parts !
  (* Anything between the quotes and spaces is up for redaction. Count how many we have *)
  0 var! redact_count_eligible
  message_parts @ foreach
    nip
    dup "\"" != swap " " != and if
      redact_count_eligible ++
    then
  repeat
  (* Produce a target number of elements we want to redact based on the redact_factor *)
  redact_count_eligible @ redact_factor @ * ceil int var! redact_count_target
  redact_count_target @ redact_count_eligible @ > if redact_count_eligible @ redact_count_target ! then
  (* Produce the random selection of indexes *)
  { }list var! redact_points
  begin
    redact_points @ array_count redact_count_target @ >= if break then
    random redact_count_eligible @ %
    dup redact_points @ M-LIB-ARRAY-hasval if
      pop continue
    then
    redact_points @ []<- redact_points !
  repeat
  (* Produce the redacted message using the selected indexes *)
  0 var! this_point
  {
    message_parts @ foreach
      nip
      dup "\"" = over " " = or if
        continue
      then
      this_point @ redact_points @ M-LIB-ARRAY-hasval if
        pop "..."
      then
      this_point ++
    repeat
  }list array_interpret var! redact_message
  (* Return the result *)
  redact_message @
;

: main ( s --  )
  "=" split
  over not over not or if
    pop
    "What do you want to mumble?" .tell
    exit
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
    "%N is not connected." { to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub .tell
    exit
  then
  (* Notify the target *)
  to @
  message @ {
    "from" me @
    "to" to @
    "message_format" "[!FFFFFF]%I mumbles \"@1[!FFFFFF]\" to you." { me @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub
    "highlight_mention" "no"
    "highlight_quote_level_min" 1
  }dict M-LIB-EMOTE-style
  .notify
  (* Notify self with a copy *)
  me @
  message @ {
    "from" me @
    "to" me @
    "message_format" "[!FFFFFF]You mumble \"@1[!FFFFFF]\" to %i." { to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub
    "highlight_mention" "no"
    "highlight_quote_level_min" 1
  }dict M-LIB-EMOTE-style
  .notify
  (* Notify everyone else in the room *)
  loc @ begin dup room? if break then location repeat M-LIB-NOTIFY-cast_targets foreach
    nip
    var! cast_to
    cast_to @ to @ = if continue then
    cast_to @ me @ = if continue then
    cast_to @
    message @ OVERHEAR_REDACT_FACTOR redact {
      "from" me @
      "to" cast_to @
      "message_format" "[!FFFFFF]%1I mumbles \"@1[!FFFFFF]\" to %2i." { me @ to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub
      "highlight_mention" "no"
      "highlight_quote_level_min" 1
    }dict M-LIB-EMOTE-style
    .notify
  repeat
;
.
c
q
!@register m-cmd-mumble.muf=m/cmd/mumble
!@set $m/cmd/mumble=M3

