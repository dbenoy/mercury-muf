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

(* Begin configurable options *)

$DEF MAIL_PROPDIR "_page/mail"
$DEF MAIL_MAX 100

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/match
$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/emote
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/color

: M-HELP-desc ( d -- s )
  pop
  "Private message."
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

: mail_add[ ref:message str:highlight_ooc_style ref:to -- bool:success? ]
  0 var! mail_total
  MAIL_PROPDIR "/" strcat begin
    to @ swap nextprop
    dup not if pop break then
    mail_total ++
  repeat
  mail_total @ MAIL_MAX >= if
    "%N's mailbox is full." { to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub command @ toupper .theme_tag_err .color_tell
    0 exit
  then
  mode var! old_mode
  preempt
  to @ MAIL_PROPDIR getpropval ++ var! serial
  to @ MAIL_PROPDIR serial @ setprop
  {
    "timestamp" systime
    "color_name" .me "color_name" M-LIB-EMOTE-config_get
    "color_quoted" .me "color_quoted" M-LIB-EMOTE-config_get
    "color_unquoted" .me "color_unquoted" M-LIB-EMOTE-config_get
    "highlight_ooc_style" highlight_ooc_style @
    "message" message @
  }dict var! entry
  to @ { MAIL_PROPDIR "/" serial @ intostr "/" }join entry @ array_put_propvals
  old_mode @ setmode
  1
;

: mail_read[  --  ]
  mode var! old_mode
  preempt
  {
    MAIL_PROPDIR "/" strcat begin
      .me swap nextprop
      dup not if pop break then
      .me over array_get_propvals swap
    repeat
  }list
  old_mode @ setmode
  SORTTYPE_CASE_ASCEND "timestamp" array_sort_indexed foreach
    nip
    var! mail_entry
      mail_entry @ "message" []
      dup string? not if pop continue then
      {
        "to"                  .me
        "highlight_mention"   "no"
        "color_name"          mail_entry @ "color_name"          [] dup string? not if pop "" then
        "color_unquoted"      mail_entry @ "color_unquoted"      [] dup string? not if pop "" then
        "color_quoted"        mail_entry @ "color_quoted"        [] dup string? not if pop "" then
        "highlight_ooc_style" mail_entry @ "highlight_ooc_style" [] dup string? not if pop "" then
      }dict M-LIB-EMOTE-style { "[#008080] (Sent " "%F %T" mail_entry @ "timestamp" [] timefmt ")" }join .color_strcat
      "PAGE" .theme_tag .color_tell
  repeat
  .me MAIL_PROPDIR remove_prop
;

: main ( s --  )
  (* Handle special invocation *)
  command @ "Queued event." = if
    dup "Connect" = if
      pop
      mail_read
      exit
    then
    "Unsupported queued invocation '" swap strcat "'." strcat prog name toupper .theme_tag_err .color_tell
    exit
  then
  (* Check mail just in case *)
  mail_read
  (* Handle page *)
  .me player? not if
    pop
    "Only players can page." command @ toupper .theme_tag_err .color_tell
    exit
  then
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
    .me name
    over 1 strcut pop dup "-" = over ":" = or swap "," = or not if
      " " strcat
    then
    swap strcat
    "no" highlight_ooc_style !
  else
    .me name ": " strcat swap strcat
    "yes" highlight_ooc_style !
  then
  var! message
  { "quiet" "no" "tag" command @ toupper "match_start" "online" }dict M-LIB-MATCH-pmatch
  dup 0 < if pop exit then
  (* Notify the target *)
  "" var! note
  var! to
  to @ awake? if
    to @
    message @ {
      "from" .me
      "to" to @
      "highlight_mention" "no"
      "highlight_ooc_style" highlight_ooc_style @
    }dict M-LIB-EMOTE-style
    "PAGE" .theme_tag .color_notify
    "[#0000AA] (to %n)" { to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub note !
  else
    message @ highlight_ooc_style @ to @ mail_add not if
      exit
    then
    "[#008080] (%N is offline, mailed)" { to @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub note !
  then
  (* Notify self with a copy *)
  message @ {
    "from" .me
    "to" .me
    "highlight_mention" "no"
    "highlight_ooc_style"
    highlight_ooc_style @
  }dict M-LIB-EMOTE-style note @ .color_strcat
  "PAGE" .theme_tag .color_tell
;
.
c
q
!@register m-cmd-@page.muf=m/cmd/at_page
!@set $m/cmd/at_page=M3
!@set $m/cmd/at_page=L
!@register #prop #0:_connect m-cmd-@page.muf=m-cmd-@page.muf

