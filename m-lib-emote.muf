!@program m-lib-emote.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-emote.muf - $m/lib/emote                                            *)
(*   Handle sending out emotive messages from an object into its containing  *)
(*   room. This is meant to unify the behavior of say, pose, ooc, spoof, etc *)
(*                                                                           *)
(*   Unlike the standard '.otell', these messages are sent to every player,  *)
(*   puppet, and _listen object in the same room, even if they, or the       *)
(*   sender, are contained within vehicles, player inventories, etc.         *)
(*                                                                           *)
(*   A variety of styling options are used for colors and highlighting based *)
(*   on which object is sending, and which object is receiving the messages. *)
(*                                                                           *)
(*   The styling routine can be called on its own, as well, so that you can  *)
(*   make it so your output from page, whisper, chat channels, etc all share *)
(*   the same styles and features.                                           *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o Optionally keeps a log of messages in the room properties, which can  *)
(*     be configured on a room-by-room basis.                                *)
(*   o The sender object's name is colorized, or otherwise highlighted. You  *)
(*     can specify the coloring to use by setting a MCC color-coded %n on    *)
(*     the object.                                                           *)
(*   o Nested quotations are detected, and highlighted.                      *)
(*     (eg. color0 "color1 "color2" color1" color0)                          *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October, 2019                            *)
(*      - Original implementation.                                           *)
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
$NOTE    Handle sending emotive messages.   
$DOCCMD  @list __PROG__=2-53

(* Begin configurable options *)

(* End configurable options *)

(
get_option
set_option
  "highlight"
    "STANDARD" - Standard highlighting
    "STOCK" - Colors are assigned to users automatically. User specified colors are ignored.
    "PLAIN" - Every line is highlighted the same, using the built-in color theme.
    "NONE" - The entire emote is a single color, using the built-in color theme.
    "TAGS" - Like NONE, but also adds additional character tags into the line to highlight names.
  "color_name"
    A string of the object's name with color codes in it. (Must match the object's name when color-stripped to be valid)
  "color_quoted"
    Six-digit capitalized hex number for the color of the text inside quotes.
  "color_unquoted"
    Six-digit capitalized hex number for the color of the text outside quotes.

history_get[ room ]
  {
    {
      "timestamp" <integer timestamp>
      "object_name" <string name of object>
      "object_type" <"PLAYER" "THING" "EXIT" "ROOM" or "PROGRAM">
      "object_owner" <string name of player>
      "message_prefix" <string of message prefix>
      "message_text" string
    }dict
    ...
  }list

history_clean[ room ]
  - Removes messages with old timestamps
  - Removes oldest messages if they exceed the maximum lines the room is set to keep
  - Removes everything if the room is set to not keep history

emote[ message, prefix, suffix, sender ]
  - Sends an object's spoof, pose, say, page, whisper, variety of actions, etc to the room the object is in.
  - Ascend the tree until you hit a 'room' type object, then notify every object under that room. This handles alerting your contents, people outside your vehicle, etc. This should probably check if objects are either players, puppets, or listeners before going through the effort of running 'style' on the message.
  - Stores a history of the messages in the room object along with details like the sender, and timestamp.

style[ message, sender, recipient ]
  - Colorize the name of the source (or its underscores-to-spaces equivalent) object no matter where it appears on the line.
  - The name can be arbitrarily colored by the sender
  - Colorize things based on the quote level
  - If no coloring is specified by the sender's settings, then generate it from a hash of their name. (Or simply randomly assign it the first time the code attempts to retrieve it and fails?)
  - Only the sender's name (Or its underscores-to-spaces equivalent) can be arbitrarily colorized by the sender, so it should stand out where the message originated from
  - Colorize or otherwise highlight when *your* name is said
  - The recipient controls whether they see colors or not, and if not, then highlighting can be added in different ways, like underscores or tildes or whatever.
  - Aborts if it has newlines in it
)

(
: doColorize ( s -- s )
  
  var myRetval       "" myRetval       !
  var myCurrentColor 0  myCurrentColor !
  var myLastChange
 
  "\"" explode
  
  (* loop until string is gone *)
  begin
    dup while
    swap
    
    myCurrentColor @
    
    (* If the retval now ends in a space, or is null, color++, otherwise color-- *)
    (* This change will apply next iteration *)
    over not if
      myCurrentColor @ myLastChange @ + myCurrentColor !
    else
      over dup strlen swap striptail strlen = if
        myCurrentColor @ -- myCurrentColor !
        -1 myLastChange !
      else
        myCurrentColor @ ++ myCurrentColor !
        1 myLastChange !
      then
      (* Edit by NightEyes: never let indent depth go negative, it makes no sense *)
      myCurrentColor @ 0 < if
        1 myCurrentColor !
        1 myLastChange !
      then
    then
    
    (* Apply the color to the current string, and add it to the retval *)
    getColor textattr myRetval @ swap strcat
    
    over 1 = not if (* If this isn't the last one, then we should replace the quote. *)
      "\"" getQuoteColor textattr strcat
    then
    
    myRetval !
    
    --
  repeat
  
  pop
  myRetval @+
;
)

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-emote.muf=m/lib/emote
!@set $m/lib/emote=M3

