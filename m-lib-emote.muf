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

$DEF HISTORY_PROPDIR   "@emote/history/"
$DEF HISTORY_DEFAULT_MAX_COUNT 100
$DEF HISTORY_DEFAULT_MAX_AGE   604800 (* One week *)
$DEF OPTIONS_PROPDIR  "_config/emote/"
$DEF USERLOG

(* End configurable options *)

$IFDEF HISTORY_DEFAULT_MAX_COUNT<1
  ($ABORT HISTORY_DEFAULT_MAX_COUNT must be greater than 0.) (* Doesn't seem to work at the moment: https://github.com/fuzzball-muck/fuzzball/issues/477 *)
$ENDIF

(* ------------------------------------------------------------------------ *)

$PUBDEF :

$INCLUDE $m/lib/program
$INCLUDE $m/lib/array
$INCLUDE $m/lib/string
$INCLUDE $m/lib/color

$DEF OPTIONS_VALID { "highlight" "color_name" "color_quoted" "color_unquoted" "color_mention" }list
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
  - If no coloring is specified by the sender's settings, then generate it from a hash of their name.
  - Only the sender's name (Or its underscores-to-spaces equivalent) can be arbitrarily colorized by the sender, so it should stand out where the message originated from.
  - The sender's name is not colorized if it appears in quotes.
  - Colorize or otherwise highlight when *your* name is said
  - The recipient controls whether they see colors or not, and if not, then highlighting can be added in different ways, like underscores or tildes or whatever.
  - Aborts if it has newlines in it
)

(* ------------------------------------------------------------------------ *)

: color_srand[ -- str:colorhex ]
  srand abs
  dup 256 % var! r
  256 /
  dup 256 % var! g
  256 /
  256 % var! b

  r @ 256 * 256 * g @ 256 * + b @ + .itox 6 .zeropad
;

: color_complementary[ str:color -- str:result ]
    color_srand M-LIB-COLOR-rgb2hsl var! hsl
    hsl @ 0 [] 0.5 + 1.0 fmod hsl @ 0 ->[] hsl !
    hsl @ M-LIB-COLOR-hsl2rgb
;

: color_saturate[ str:color -- str:result ]
    color_srand M-LIB-COLOR-rgb2hsl var! hsl
    1.0 hsl @ 1 ->[] hsl !
    hsl @ M-LIB-COLOR-hsl2rgb
;

: history_max_count
  HISTORY_DEFAULT_MAX_COUNT
;

: history_max_age
  HISTORY_DEFAULT_MAX_AGE
;


: option_valid[ str:value ref:object str:option -- bool:valid? ]
  value @ not if 0 exit then

  option @ tolower option !

  option @ "highlight" = if
    value @ OPTIONS_VALID_HIGHLIGHT .array_hasval exit
  then

  option @ "color_name" = if
    value @ .color_strip object @ name stringcmp 0 = exit
  then

  option @ "color_quoted" = option @ "color_unquoted" = or option @ "color_mention" = or if
    value @ "[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]" smatch exit
  then
;

: option_default[ ref:object str:option -- str:default ]
  option @ tolower option !

  option @ "highlight" = if
    "STANDARD"
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

  option @ "color_mention" = if
    "2F2FFF"
  then
;

: option_get[ ref:object str:option -- str:value ]
  object @ OPTIONS_PROPDIR "/" strcat option @ strcat getpropstr

  dup object @ option @ option_valid not if
    pop object @ option @ option_default
  then
;

: history_clean[ ref:room int:max_count -- ]
  systime var! now
  (* Verify the validity of the entries and nuke invalid ones *)
  0 var! max_serial (* Also find the highest serial *)
  0 var! entry_count (* And also the total number of entries *)
  { }list var! timestamps (* And collect all the timestamps, including duplicates *)
  HISTORY_PROPDIR begin
    room @ swap nextprop
    dup not if pop break then
    dup var! entry_dir
    (* Check the serial *)
    entry_dir @ "/" rsplit nip var! entry_serial
    entry_serial @ number? not if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": Invalid serial number. Removing." }join .tell
$ENDIF
      room @ entry_dir @ remove_prop
      continue
    then
    entry_serial @ atoi entry_serial !
    (* Ensure we're dealing with a propdir *)
    room @ entry_dir @ propdir? not if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": Not a propdir. Removing." }join .tell
$ENDIF
      room @ entry_dir @ remove_prop
      continue
    then
    (* Grab the timestamp entry and ensure the message is not expired *)
    room @ entry_dir @ "/" strcat "timestamp" strcat getprop var! entry_timestamp
    entry_timestamp @ not if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": No timestamp. Removing." }join .tell
$ENDIF
      room @ entry_dir @ remove_prop
      continue
    then
    now @ entry_timestamp @ -
    dup 0 < if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": Future timestamp!" }join .tell
$ENDIF
    then
    history_max_age > if
      room @ entry_dir @ remove_prop
      continue
    then
    (* We're good. Track this entry. *)
    entry_serial @ max_serial @ > if entry_serial @ max_serial ! then
    { entry_timestamp @ intostr "-" entry_serial @ intostr }join timestamps @ array_appenditem timestamps !
    entry_count ++
  repeat
  (* Is the highest serial entry greater than the currently stored serial number? If so, increment it. *)
  max_serial @ room @ HISTORY_PROPDIR getpropval > if
    room @ HISTORY_PROPDIR max_serial @ setprop
  then
  (* Have we exceeded the maximum entry count? If so, remove entries starting with the smallest timestamp *)
  entry_count @ max_count @ > if
    timestamps @ 0 array_sort entry_count @ max_count @ - array_cut pop foreach
      nip
      (* Packed above in "TIMESTAMP-SERIAL" format. *)
      "-" rsplit nip
      HISTORY_PROPDIR "/" strcat swap strcat
      room @ swap remove_prop
    repeat
  then
;

: history_add[ ref:message str:prefix str:suffix str:from ref:room -- ]
  (* I don't know if this is concurrency-safe or not. I'm not sure how MUF  *)
  (* parsels out its time. Accidental perfect simulteneity is probably a    *)
  (* silly thing to worry about in a chat server but I might as well drop   *)
  (* this comment here. Maybe it is possible for this to run at the exact   *)
  (* same instant twice? Better increment the serial the instant we get     *)
  (* here. Maybe the daemon will have threads in the future...              *)
  room @ HISTORY_PROPDIR getpropval ++ var! serial
  room @ HISTORY_PROPDIR serial @ setprop
  {
    "timestamp" systime
    "trigger_command" command @
    "trigger_dbref" "#" trig intostr strcat
    "trigger_owner" trig owner name
    "object_name" from @ name
    "object_type"
      begin
        from @ player? if "PLAYER" break then
        from @ thing? if "THING" break then
        from @ exit? if "EXIT" break then
        from @ room? if "ROOM" break then
        from @ program? if "PROGRAM" break then
        "UNKNOWN"
      1 until
    "object_owner" from @ owner name
    "message_prefix" prefix @
    "message_suffix" suffix @
    "message_text" message @
  }dict var! entry
  room @ { HISTORY_PROPDIR "/" serial @ intostr "/" }join entry @ array_put_propvals
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
  "" var! result
  (* Emotes are not colored by the user *)
  message @ .color_escape message !
  (* Store some frequently accessed information *)
  from @ name var! from_name
  from @ name " " "_" subst var! from_sname
  to @ name var! to_name
  to @ name " " "_" subst var! to_sname
  (* Iterate through the string *)
  0 var! quote_level
  1 var! quoting_up
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
    (* Check for from object's name *)
    message_remain @ from_name @ instring 1 = message_remain @ from_sname @ instring 1 = or if
      message_prevchar @ "[0-9a-zA-Z]" smatch not if
        message_remain @ from_name @ strlen strcut swap pop "[0-9a-zA-Z]*" smatch not if
          quote_level @ not if
            (* We are at the from object's name, and it is on its own, and we're outside of quotes. Place the highlighted name and increment past it. *)
            result @ from @ "color_name" option_get .color_strcat result !
            message_pos @ from_name @ strlen + message_pos !
            continue
          then
        then
      then
    then
    (* Check for to object's name *)
    from @ to @ != if
      message_remain @ to_name @ instring 1 = message_remain @ to_sname @ instring 1 = or if
        message_prevchar @ "[0-9a-zA-Z]" smatch not if
          message_remain @ to_name @ strlen strcut swap pop "[0-9a-zA-Z]*" smatch not if
            (* We are at the to object's name, and it is on its own, and we are not emoting to ourselves. Place the highlighted name and increment past it. *)
            result @ { { "[#" to @ "color_mention" option_get "]" }join message_remain @ to_name @ strlen strcut pop }join .color_strcat result !
            message_pos @ to_name @ strlen + message_pos !
            continue
          then
        then
      then
    then
    (* Check for quotes *)
    message_remain @ "\"" instr 1 = if
      message_prevchar @ "\"" = quoting_up @ and message_prevchar @ " " = or message_prevchar @ "" = or if
        (* Going up! Increase the quote level then place the quote mark. *)
        1 quoting_up !
        quote_level ++
        result @ { "[#" from @ quote_level @ color_quotelevel "]\"" }join .color_strcat result !
        message_pos ++
        continue
      else
        (* Going down. Place the quote marke, then decrease the quote level. *)
        result @ { "[#" from @ quote_level @ color_quotelevel "]\"" }join .color_strcat result !
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
      message_remain @ to_name @ EINSTRING
      message_remain @ to_sname @ EINSTRING
      message_remain @ "\"" EINSTRING
    }list .array_min
    dup 1 < if
      pop 1
    then
    result @ message_remain @ 3 pick strcut pop { "[#" from @ quote_level @ color_quotelevel "]" }join swap strcat .color_strcat result !
    message_pos @ swap + message_pos !
    message_pos @ message @ strlen >=
  until

  result @
;

: emote_to_object[ str:message str:prefix str:suffix ref:from ref:parent -- ]
  (* TODO: Sort out how 'listeners' work and make sure they're notified too? *)
  parent @ contents begin
    dup while
    dup thing? over player? or if
      dup var! to
      to @ player? to @ thing? or if
        to @ player? to @ "ZOMBIE" flag? or if
          to @ { prefix @ message @ from @ to @ style suffix @ }join .color_notify
          (
          to @ { prefix @ message @ from @ to @ style suffix @ }join "MCC" "ANSI-24BIT" M-LIB-COLOR-transcode notify
          to @ { prefix @ message @ from @ to @ style suffix @ }join "MCC" "ANSI-8BIT" M-LIB-COLOR-transcode notify
          to @ { prefix @ message @ from @ to @ style suffix @ }join "MCC" "ANSI-4BIT-VGA" M-LIB-COLOR-transcode notify
          to @ { prefix @ message @ from @ to @ style suffix @ }join "MCC" "ANSI-4BIT-XTERM" M-LIB-COLOR-transcode notify
          )
        then
        (* Notify all the things/players inside, too *)
        message @ prefix @ suffix @ from @ to @ emote_to_object
      then
    then
    next
  repeat
  pop
;

(* ------------------------------------------------------------------------ *)

(*****************************************************************************)
(*                             M-LIB-EMOTE-emote                             *)
(*****************************************************************************)
: M-LIB-EMOTE-emote[ str:message str:prefix str:suffix ref:from -- ]
  from @ dbref? not if "Non-dbref argument (4)." abort then
  "me" match from @ = not if
    "force_mlev1_name_notify" sysparm if
      .mlev2 not if "Requires MUCKER level 2 or above to send as other players." abort then
    then
  then
  message @ string? not if "Non-string argument (1)." abort then
  prefix @ string? not if "Non-string argument (2)." abort then
  suffix @ string? not if "Non-string argument (3)." abort then
  (* Ascend the object tree until a room is found *)
  from @ begin location dup room? until var! room
  (* Store the emote in the room history *)
  room @ history_max_count -- history_clean
  message @ prefix @ suffix @ from @ room @ history_add
  (* Construct styled messages and send out notifies *)
  message @ prefix @ suffix @ from @ room @ emote_to_object
;
PUBLIC M-LIB-EMOTE-emote
$LIBDEF M-LIB-EMOTE-emote

(*****************************************************************************)
(*                         M-LIB-EMOTE-history_clean                         *)
(*****************************************************************************)
: M-LIB-EMOTE-history_clean[ ref:room -- ]
  .needs_mlev3
  room @ dbref? not if "Non-dbref argument (1)." abort then
  history_max_count history_clean
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
  option @ OPTIONS_VALID .array_hasval not if "Invalid option." abort then

  object @ option @ option_get
;
PUBLIC M-LIB-EMOTE-option_get
$LIBDEF M-LIB-EMOTE-option_get

(*****************************************************************************)
(*                          M-LIB-EMOTE-option_set                           *)
(*****************************************************************************)
: M-LIB-EMOTE-option_set[ ref:object str:option str:value -- bool:success? ]
  .needs_mlev3

  option @ string? not if "Non-string argument (1)." abort then
  option @ OPTIONS_VALID .array_hasval not if "Invalid option." abort then
  object @ thing? object @ player? or not if "Only player and thing objects can have emote options." abort then

  value @ object @ option @ option_valid not if
    0 exit
  then

  object @ OPTIONS_PROPDIR "/" strcat option @ strcat value @ setprop
  1
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

  message @ "\r" instr if "Newlines are not allowed in style strings" abort then

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
!@set $m/lib/emote=W
!@set $m/lib/emote=L

