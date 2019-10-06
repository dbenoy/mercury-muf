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
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    Handle sending emotive messages.   
$DOCCMD  @list __PROG__=2-53

(* Begin configurable options *)

(* End configurable options *)

(* ------------------------------------------------------------------------ *)

$PUBDEF :

$INCLUDE $m/lib/program
$INCLUDE $m/lib/array
$INCLUDE $m/lib/string
$INCLUDE $m/lib/color

$DEF OPTIONS_VALID { "highlight" "color_name" "color_quoted" "color_unquoted" }list
$DEF OPTIONS_VALID_HIGHLIGHT { "STANDARD" "STOCK" "PLAIN" "NONE" "TAGS" }list

(
option_get
option_set
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

(* ------------------------------------------------------------------------ *)

: hexstr ( i -- s )
  dup 0 < if "Negative hex." abort then
  ""
  begin
    over 16 % dup 10 < if intostr else 10 - "A" ctoi + itoc then swap strcat
    swap 16 / swap
    over not
  until
  nip
;

: zeropad ( s i -- s )
  over strlen over < if
    over strlen - "0" * swap strcat
  else
    pop
  then
;

: color_srand[ -- str:colorhex ]
  srand abs
  dup 256 % var! r
  256 /
  dup 256 % var! g
  256 /
  256 % var! b

  r @ 256 * 256 * g @ 256 * + b @ + .itox 6 .zeropad
;

: color_constrain[ str:color int:min int:max -- str:newcolor ]
  max @ min @ < if
    max @ dup min @ max ! min !
  then

  color @
  2 strcut swap .xtoi var! r
  2 strcut swap .xtoi var! g
  2 strcut swap .xtoi var! b

  max @ min @ - 255.0 /
  dup r @ * int r !
  dup g @ * int g !
  b @ * int b !

  min @
  dup r @ + r !
  dup g @ + g !
  b @ + b !

  r @ 256 * 256 * g @ 256 * + b @ + .itox 6 .zeropad
;

: option_valid[ ref:object str:option str:value -- bool:valid? ]
  option @ tolower option !

  option @ "highlight" = if
    value @ OPTIONS_VALID_HIGHLIGHT .array_hasval exit
  then

  option @ "color_name" = if
    value @ .color_strip object @ name stringcmp 0 = exit
  then

  option @ "color_quoted" = option @ "color_unquoted" = or if
    "[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]" smatch exit
  then
;

: option_default[ ref:object str:option -- str:default ]
  option @ tolower option !

  option @ "highlight" = if
  then

  option @ "color_name" = option @ "color_quoted" = or option @ "color_unquoted" = or if
    (* Generate a random pastel color seeded off the option name and the object's name *)
    { "COLOR" "muckname" sysparm object @ name }join sha1hash setseed
    color_srand M-LIB-COLOR-rgb2hsl var! hsl
    option @ "color_name" = option @ "color_quoted" = or if
      (* Constrain the saturation *)
      hsl @ 1 [] 0.2 * 0.5 + hsl @ 1 ->[] hsl !
      (* Constrain the lightness *)
      hsl @ 2 [] 0.2 * 0.7 + hsl @ 2 ->[] hsl !
    then
    option @ "color_unquoted" = if
      (* Constrain the saturation, a little more muted *)
      hsl @ 1 [] 0.2 * 0.2 + hsl @ 1 ->[] hsl !
      (* Set the lightness, a little darker *)
      0.5 hsl @ 2 ->[] hsl !
    then
    hsl @ M-LIB-COLOR-hsl2rgb
    option @ "color_name" = if
      { "[#" rot "]" object @ name " " "_" subst }join
    else
    then
  then
;

: option_get[ ref:object str:option -- str:value ]
  object @ option @ option_default
;

: color_quotelevel[ ref:object int:level ]
  level @ 0 <= if
    object @ "color_unquoted" option_get exit
  then
  object @ "color_quoted" option_get
  (* Boost the saturation by 10% for every additional quote level *)
  M-LIB-COLOR-rgb2hsl var! hsl
  hsl @ 1 [] level @ 1 - 10.0 / +
  dup 1.0 > if pop 1.0 then
  hsl @ 1 ->[] hsl !
  hsl @ M-LIB-COLOR-hsl2rgb
;

$DEF EINSTRING over swap instring dup not if pop strlen else nip -- then
: style[ str:message ref:from ref:to -- str:result ]
  message @ .color_escape message !
  0 var! quote_level
  1 var! quoting_up
  "" var! highlighted_message
  from @ name var! from_name
  from @ name " " "_" subst var! from_sname
  0 var! message_pos
  begin
    (* Pull out the remaining message at this point, and the previous character before this point *)
    message_pos @ not if
      ""
      message @
    else
      message @ message_pos @ -- strcut
      swap pop
      1 strcut
    then
    var! message_remain
    var! message_prevchar
    (* Check if there is anything here to highlight *)
    message_remain @ from_name @ instring 1 = message_remain @ from_sname @ instring 1 = or if
      message_prevchar @ "[0-9a-zA-Z]" smatch not if
        message_remain @ from_name @ strlen strcut swap pop "[0-9a-zA-Z]*" smatch not if
          (* We are at the object's name, and it is on its own, Place the highlighted name and increment past it. *)
          highlighted_message @ from @ "color_name" option_get .color_strcat highlighted_message !
          message_pos @ from_name @ strlen + message_pos !
          continue
        then
      then
    then
    message_remain @ "\"" instr 1 = if
      message_prevchar @ "\"" = quoting_up @ and message_prevchar @ " " = or message_prevchar @ "" = or if
        (* Going up! Increase the quote level then place the quote mark. *)
        1 quoting_up !
        quote_level ++
        highlighted_message @ { "[#" from @ quote_level @ color_quotelevel "]\"" }join .color_strcat highlighted_message !
        message_pos ++
        continue
      else
        (* Going down. Place the quote marke, then decrease the quote level. *)
        highlighted_message @ { "[#" from @ quote_level @ color_quotelevel "]\"" }join .color_strcat highlighted_message !
        message_pos ++
        0 quoting_up !
        quote_level --
        continue
      then
    then
    (* Nothing got highlighted *)
    (* Find the next potential highlight point, cut and increment to there. *)
    {
      message_remain @ from_name @ EINSTRING
      message_remain @ from_sname @ EINSTRING
      message_remain @ "\"" EINSTRING
    }list .array_min
    dup 1 < if
      pop 1
    then
    highlighted_message @ message_remain @ 3 pick strcut pop { "[#" from @ quote_level @ color_quotelevel "]" }join swap strcat .color_strcat highlighted_message !
    message_pos @ swap + message_pos !
    message_pos @ message @ strlen >=
  until

  highlighted_message @
;

(* ------------------------------------------------------------------------ *)

(*****************************************************************************)
(*                             M-LIB-EMOTE-emote                             *)
(*****************************************************************************)
: M-LIB-EMOTE-emote[ str:message str:prefix str:suffix ref:from -- ]
  "me" match from @ = not if
    "force_mlev1_name_notify" sysparm if
      .mlev2 not if "Requires MUCKER level 2 or above to send as other players." abort then
    then
  then
  (* TODO: Alert every player, puppet, and _listen in the room, not just others in the same loc @ *)
  loc @ contents begin
    dup thing? over "ZOMBIE" flag? and over player? or if
      dup var! to
      to @ { prefix @ message @ from @ to @ style suffix @ }join .color_notify
    then
    next
    dup not
  until
;
PUBLIC M-LIB-EMOTE-emote
$LIBDEF M-LIB-EMOTE-emote

(*****************************************************************************)
(*                         M-LIB-EMOTE-history_clean                         *)
(*****************************************************************************)
: M-LIB-EMOTE-history_clean[ ref:room -- ]
  .needs_mlev3
;
PUBLIC M-LIB-EMOTE-history_clean
$LIBDEF M-LIB-EMOTE-history_clean

(*****************************************************************************)
(*                          M-LIB-EMOTE-history_get                          *)
(*****************************************************************************)
: M-LIB-EMOTE-history_get[ ref:room -- arr:history ]
  .needs_mlev3
;
PUBLIC M-LIB-EMOTE-history_get
$LIBDEF M-LIB-EMOTE-history_get

(*****************************************************************************)
(*                          M-LIB-EMOTE-option_get                           *)
(*****************************************************************************)
: M-LIB-EMOTE-option_get[ ref:object str:option -- str:value ]
  (* M1 OK *)

  option @ string? not if "Non-string argument (1)." abort then
  option @ OPTIONS_VALID .array_hasval not if
    "Invalid option." abort
  then
;
PUBLIC M-LIB-EMOTE-option_get
$LIBDEF M-LIB-EMOTE-option_get

(*****************************************************************************)
(*                          M-LIB-EMOTE-option_set                           *)
(*****************************************************************************)
: M-LIB-EMOTE-option_set[ ref:object str:option str:value -- bool:success? ]
  .needs_mlev3

  option @ string? not if "Non-string argument (1)." abort then
  option @ OPTIONS_VALID .array_hasval not if
    "Invalid option." abort
  then
;
PUBLIC M-LIB-EMOTE-option_set
$LIBDEF M-LIB-EMOTE-option_set

(*****************************************************************************)
(*                             M-LIB-EMOTE-style                             *)
(*****************************************************************************)
: M-LIB-EMOTE-style[ str:message ref:from ref:to -- str:result ]
  (* M1 OK *)

  message @ string? not if "Non-string argument (1)." abort then
  from @ dbref? not if "Non-dbref argument (2)." abort then
  to @ dbref? not if "Non-dbref argument (3)." abort then

  message @ from @ to @ style
;
PUBLIC M-LIB-EMOTE-style
$LIBDEF M-LIB-EMOTE-style

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-emote.muf=m/lib/emote
!@set $m/lib/emote=M3
!@set $m/lib/emote=L
!@set $m/lib/emote=S
!@set $m/lib/emote=H

