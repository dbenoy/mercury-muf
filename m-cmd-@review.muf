!@program m-cmd-@review.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@review - $m/cmd/at_review                                          *)
(*   <description>                                                           *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* USAGE:                                                                    *)
(*   <Basic usage information, if required>                                  *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   <routine name> <arguments>                                              *)
(*     <description>                                                         *)
(*                                                                           *)
(*   <routine name> <arguments>                                              *)
(*     <description>                                                         *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   <if nessessary>                                                         *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October, 2019                            *)
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
$NOTE    Read emote history.
$DOCCMD  @list __PROG__=2-<last header line>

$INCLUDE $m/lib/emote
$INCLUDE $m/lib/notify

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "See the room message log."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    action_name @
    " "
    "  Shows a list of recent player emotes (Such as poses and spoofs, etc.) that happened in this room."
    "  If a message didn't start with the name of the player who sent it, then it will be shown here, so you can use this as a way to check who a spoofed message was actually from."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  (* Ascend the tree until we hit a room *)
  me @ begin location dup room? until var! room

  { }list var! output_lines
  room @ M-LIB-EMOTE-history_get SORTTYPE_CASE_ASCEND "timestamp" array_sort_indexed foreach
    nip
    var! this_entry
    (* Start with the timestamp. This will also be used to sort the results later. *)
    { "[#00AAAA][" "%F %T" this_entry @ "timestamp" [] timefmt "][!FFFFFF]" }join var! this_line
    (* Add the message text itself. *)
    {
      this_line @
      " "
      this_entry @ "message" []
      {
        "to" me @
        this_entry @ "object_name" [] me @ name = if
          "highlight_mention" "no"
        then
        "message_format" this_entry @ "message_format" [] dup not if pop "" then
        "color_name"     this_entry @ "color_name"     [] dup not if pop "" then
        "color_unquoted" this_entry @ "color_unquoted" [] dup not if pop "" then
        "color_quoted"   this_entry @ "color_quoted"   [] dup not if pop "" then
      }dict
      M-LIB-EMOTE-style
    }join this_line !
    (* Append the name of the object if necessary. *)
    this_entry @ "object_name" [] var! owner_tag
    this_entry @ "object_owner" [] if
      this_entry @ "object_owner" [] this_entry @ "object_name" [] != if
        { owner_tag @ " - " this_entry @ "object_owner" [] }join owner_tag !
      then
    then
    this_entry @ "message" [] "_" " " subst owner_tag @ instr 1 = not if
      { this_line @ " [#0000AA](" owner_tag @ ")" }join this_line !
    then
    (* Put the completed line in the list *)
    this_line @ output_lines @ array_appenditem output_lines !
  repeat
  output_lines @ { me @ }list M-LIB-NOTIFY-color_array_notify
;
.
c
q
!@register m-cmd-@review.muf=m/cmd/at_review
!@set $m/cmd/at_review=M3

