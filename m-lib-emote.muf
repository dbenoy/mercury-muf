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
(* PROPERTIES:                                                               *)
(*   "_config/emote/highlight_allow_custom"                                  *)
(*     Use this to alter how objects see custom colors when they receive an  *)
(*     emote. This does not affect any colors that may be in the prefix or   *)
(*     suffix components of the emote.                                       *)
(*       "YES" -     Normal behavior. The sending object's color_* options   *)
(*                   take effect.                                            *)
(*       "NO"  -     Default colors. The sending object's color_* options    *)
(*                   are ignored and the emotes are seen as if the sender    *)
(*                   never set any colors in the first place (they are       *)
(*                   auto-selected).                                         *)
(*       "PLAIN" -   The sending object's color_* options are ignored and    *)
(*                   everyone's colors are made to be the same. A system     *)
(*                   default is used.                                        *)
(*       "NOCOLOR" - Colors are stripped out entirely, even from the         *)
(*                   highlight_mention_* options. (but not any characters    *)
(*                   those options may have added.)                          *)
(*                                                                           *)
(*   "_config/emote/highlight_mention_names"                                 *)
(*     A semicolon separated list of words which, if seen in an emote this   *)
(*     object receives, will be highlighted. It defaults to the receiving    *)
(*     object's name, and the object's underscores-to-spaces equivalent. Set *)
(*     this to a semicolon to disable highlighting.                          *)
(*                                                                           *)
(*   "_config/emote/highlight_mention_before"                                *)
(*   "highlight_mention_after"                                               *)
(*     When highlighting words from highlight_mention_names, these strings   *)
(*     wrap around it. Color codes in these strings are allowed to affect    *)
(*     the highlighted name. It defaults to giving the word a blue color.    *)
(*                                                                           *)
(*   "_config/emote/color_name"                                              *)
(*     When this object sends an emote, this MCC coded color string that     *)
(*     will be used in place of its name. It must match the object's name    *)
(*     when the colors are stripped out, but it may replace underscores with *)
(*     spaces.                                                               *)
(*                                                                           *)
(*   "_config/emote/color_quoted"                                            *)
(*     When this object sends an emote, this six-digit hexadecimal RGB color *)
(*     will be used for everything in the emote outside of quotes.           *)
(*                                                                           *)
(*   "_config/emote/color_unquoted"                                          *)
(*     When this object sends an emote, this six-digit hexadecimal RGB color *)
(*     will be used for everything in the emote inside of quotes.            *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-EMOTE-emote[ str:message str:prefix str:suffix ref:from -- ]      *)
(*     Send an emote from a given object. The emote is sent to every zombie  *)
(*     and player object in the same room, no matter where the sender and    *)
(*     the recipient are located in the room's object tree. The emote is     *)
(*     also logged in the room's properties for a certain amount of time.    *)
(*     The prefix and suffix are MCC coded colored strings that enclose the  *)
(*     emote, and are not affected by the color highlighting routine. The    *)
(*     message may not have a newline character.                             *)
(*                                                                           *)
(*     See OPTIONS SETTINGS for how the various options affect the emotes.   *)
(*                                                                           *)
(*   M-LIB-EMOTE-history_clean[ ref:room -- ]                                *)
(*     Clears out old or invalid emote history entries on a given room.      *)
(*                                                                           *)
(*   M-LIB-EMOTE-history_get[ ref:room -- arr:history ]                      *)
(*     Get the emote history stored in a room's properties. It is returned   *)
(*     in this format, with an entry for each line:                          *)
(*                                                                           *)
(*     {                                                                     *)
(*       {                                                                   *)
(*         "timestamp"       - The 'systime' of the emote.                   *)
(*         "trigger_command" - The command @ that sent the emote.            *)
(*         "trigger_dbref"   - The trigger that sent the emote.              *)
(*         "trigger_owner"   - The owner of the trigger.                     *)
(*         "object_name"     - The name of the object that sent the emote.   *)
(*         "object_type"     - Type of the object that sent the emote:       *)
(*                             "PLAYER" "THING" "EXIT" "ROOM" "PROGRAM"      *)
(*         "object_owner"    - Owner of the object that sent the emote.      *)
(*         "message_prefix"  - The prefix text.                              *)
(*         "message_suffix"  - The suffix text.                              *)
(*         "message_text"    - The emote message itself.                     *)
(*       }dict                                                               *)
(*       ...                                                                 *)
(*     }list                                                                 *)
(*                                                                           *)
(*     Only timestamp, object_name, message_text are guaranteed to be        *)
(*     present. The caller is expected to be able to handle the absence of   *)
(*     entries, or the addition of new ones, but can expect them to always   *)
(*     be strings, except for the timestamp, which will always be an         *)
(*     integer.                                                              *)
(*                                                                           *)
(*   M-LIB-EMOTE-option_get[ ref:object str:option -- str:value ]            *)
(*     Specify a configuration option to get an emote setting from an        *)
(*     object. At present, option names are the names from PROPERTIES above, *)
(*     without the propdir component.                                        *)
(*                                                                           *)
(*   M-LIB-EMOTE-style[ str:message ref:from ref:to -- str:result ]          *)
(*     Colors and highlights an emote as if it were sent from and to the     *)
(*     given objects and returns the resulting string.                       *)
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
$DOCCMD  @list __PROG__=2-146

(* Begin configurable options *)

$DEF HISTORY_PROPDIR           "_emote/@history/" (* Use a @ privileged property! *)
$DEF HISTORY_PROP_MAX_COUNT    "_emote/history_max_count"
$DEF HISTORY_PROP_MAX_AGE      "_emote/history_max_count"
$DEF HISTORY_DEFAULT_MAX_COUNT 100
$DEF HISTORY_DEFAULT_MAX_AGE   604800 (* One week *)
$DEF OPTIONS_PROPDIR           "_config/emote/"
$DEF USERLOG
$DEF THEME_COLOR_NAME          "A8A8A8"
$DEF THEME_COLOR_UNQUOTED      "626262"
$DEF THEME_COLOR_QUOTED        "A8A8A8"

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

$DEF OPTIONS_VALID { "highlight_allow_custom" "highlight_mention_before" "highlight_mention_after" "highlight_mention_names" "color_name" "color_quoted" "color_unquoted" }list
$DEF OPTIONS_VALID_HIGHLIGHT_ALLOW_CUSTOM { "YES" "NO" "PLAIN" "NOCOLOR" }list

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

: history_max_count ( d -- )
  (* TODO: Get it from the room properties. Also maybe have an enforced maximum? *)
  pop HISTORY_DEFAULT_MAX_COUNT
;

: history_max_age ( d -- )
  (* TODO: Get it from the room properties. Also maybe have an enforced maximum? *)
  pop HISTORY_DEFAULT_MAX_AGE
;

: option_valid[ str:value ref:object str:option -- bool:valid? ]
  value @ not if 0 exit then
  option @ tolower option !
  option @ "highlight_allow_custom" = if
    { value @ }list OPTIONS_VALID_HIGHLIGHT_ALLOW_CUSTOM array_union not not exit
  then
  option @ "color_name" = if
    value @ .color_strip object @ name stringcmp 0 = exit
  then
  option @ "color_quoted" = option @ "color_unquoted" = or if
    value @ "[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]" smatch exit
  then
  option @ "highlight_mention_before" = option @ "highlight_mention_after" = or if
    value @ strlen 30 < exit
  then
  option @ "highlight_mention_names" = if
    value @ strlen 200 < exit
  then
;

: option_default[ ref:object str:option -- str:default ]
  option @ tolower option !
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
    exit
  then
  option @ "highlight_allow_custom" = if
    "STANDARD" exit
  then
  option @ "highlight_mention_before" = if
    "[>000069][>001063]" exit
  then
  option @ "highlight_mention_after" = if
    "[<999063][<000069]" exit
  then
  option @ "highlight_mention_names" = if
    { object @ name ";" object @ name " " "_" subst }join exit
  then
;

: option_get[ ref:object str:option -- str:value ]
  object @ OPTIONS_PROPDIR "/" strcat option @ strcat getpropstr
  dup object @ option @ option_valid not if
    pop object @ option @ option_default
  then
  option @ "highlight_allow_custom" = if
    toupper
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
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": Invalid serial number. Removing." }join userlog
$ENDIF
      room @ entry_dir @ remove_prop
      continue
    then
    entry_serial @ atoi entry_serial !
    (* Ensure we're dealing with a propdir *)
    room @ entry_dir @ propdir? not if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": Not a propdir. Removing." }join userlog
$ENDIF
      room @ entry_dir @ remove_prop
      continue
    then
    (* Grab the timestamp entry and ensure the message is not expired *)
    room @ entry_dir @ "/" strcat "timestamp" strcat getprop var! entry_timestamp
    entry_timestamp @ not if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": No timestamp. Removing." }join userlog
$ENDIF
      room @ entry_dir @ remove_prop
      continue
    then
    now @ entry_timestamp @ -
    dup 0 < if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": Future timestamp!" }join userlog
$ENDIF
    then
    room @ history_max_age > if
      room @ entry_dir @ remove_prop
      continue
    then
    (* Verify every property in here is a string, and ensure some essential properties *)
    0 var! good_count
    entry_dir @ "/" strcat begin
      room @ swap nextprop
      dup not if pop break then
      dup "/" rsplit nip "timestamp" = if
        continue
      then
      room @ over getprop string? not if
        0 good_count !
        pop break
      then
      dup "/" rsplit nip "object_name" = if good_count ++ then
      dup "/" rsplit nip "message_text" = if good_count ++ then
    repeat
    good_count @ 2 < if
$IFDEF USERLOG
      { "Bad emote history entry '" entry_dir @ "' on room #" room @ intostr ": Invalid properties, or essential properties missing. Removing." }join userlog
$ENDIF
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

: highlight_quotelevel_get[ ref:to ref:from int:level -- str:result ]
  to @ "highlight_allow_custom" option_get "NOCOLOR" = if "" exit then
  var color_unquoted
  var color_quoted
  begin
    to @ "highlight_allow_custom" option_get "NO" = if
      from @ "color_unquoted" option_default color_unquoted !
      from @ "color_quoted" option_default color_quoted !
      break
    then
    to @ "highlight_allow_custom" option_get "PLAIN" = if
      THEME_COLOR_UNQUOTED color_unquoted !
      THEME_COLOR_QUOTED color_quoted !
      break
    then
    from @ "color_unquoted" option_get color_unquoted !
    from @ "color_quoted" option_get color_quoted !
  1 until

  level @ 0 <= if
    color_unquoted @
  else
    color_quoted @
    (* Boost the lightness by 10% for every additional quote level *)
    M-LIB-COLOR-rgb2hsl var! hsl
    hsl @ 2 [] level @ 1 - 10.0 / +
    dup 1.0 > if pop 1.0 then
    hsl @ 2 ->[] hsl !
    hsl @ M-LIB-COLOR-hsl2rgb
  then

  "[#" swap strcat "]" strcat
;

: highlight_name[ ref:to ref:from -- str:result ]
  to @ "highlight_allow_custom" option_get "NOCOLOR" = if
    from @ name exit
  then
  to @ "highlight_allow_custom" option_get "NO" = if
    from @ "color_name" option_default exit
  then
  to @ "highlight_allow_custom" option_get "PLAIN" = if
    { "[#" THEME_COLOR_NAME "]" from @ name }join exit
  then
  from @ "color_name" option_get
;

: highlight_mention_before_get[ ref:to -- str:result ]
  to @ "highlight_mention_before" option_get
  to @ "highlight_allow_custom" option_get "NOCOLOR" = if
    .color_strip
  then
;

: highlight_mention_after_get[ ref:to -- str:result ]
  to @ "highlight_mention_after" option_get
  to @ "highlight_allow_custom" option_get "NOCOLOR" = if
    .color_strip
  then
;

$DEF EINSTRING over swap instring dup not if pop strlen else nip -- then
: style[ str:message ref:from ref:to -- str:result ]
  "" var! result
  (* Emotes are not colored by the message text itself *)
  message @ .color_escape message !
  (* Store some frequently accessed information *)
  from @ name var! from_name
  from @ name " " "_" subst var! from_sname
  to @ "highlight_mention_names" option_get ";" explode_array var! to_names
  { to_names @ foreach nip dup not if pop then repeat }list to_names !
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
            result @ to @ from @ highlight_name .color_strcat result !
            message_pos @ from_name @ strlen + message_pos !
            continue
          then
        then
      then
    then
    (* Check for to object's name *)
    from @ to @ != if
      "" to_names @ foreach nip dup message_remain @ swap instring 1 = if break else pop then repeat var! found_name
      found_name @ if
        message_prevchar @ "[0-9a-zA-Z]" smatch not if
          message_remain @ found_name @ strlen strcut swap pop "[0-9a-zA-Z]*" smatch not if
            (* We are at the to object's name, and it is on its own, and we are not emoting to ourselves. Place the highlighted name and increment past it. *)
            result @ { to @ highlight_mention_before_get message_remain @ found_name @ strlen strcut pop to @ highlight_mention_after_get }join .color_strcat result !
            message_pos @ found_name @ strlen + message_pos !
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
        result @ to @ from @ quote_level @ highlight_quotelevel_get "\"" strcat .color_strcat result !
        message_pos ++
        continue
      else
        (* Going down. Place the quote marke, then decrease the quote level. *)
        result @ to @ from @ quote_level @ highlight_quotelevel_get "\"" strcat .color_strcat result !
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
      to_names @ foreach nip message_remain @ swap EINSTRING repeat
      message_remain @ "\"" EINSTRING
    }list .array_min
    dup 1 < if
      pop 1
    then
    result @ message_remain @ 3 pick strcut pop to @ from @ quote_level @ highlight_quotelevel_get swap strcat .color_strcat result !
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
  message @ not if "Empty emote." abort then
  (* Ascend the object tree until a room is found *)
  from @ begin location dup room? until var! room
  (* Store the emote in the room history *)
  room @ room @ history_max_count -- history_clean
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
  room @ room @ history_max_count history_clean
;
PUBLIC M-LIB-EMOTE-history_clean
$LIBDEF M-LIB-EMOTE-history_clean

(*****************************************************************************)
(*                          M-LIB-EMOTE-history_get                          *)
(*****************************************************************************)
: M-LIB-EMOTE-history_get[ ref:room -- arr:history ]
  .needs_mlev3
  room @ room @ history_max_count history_clean
  {
    HISTORY_PROPDIR begin
      room @ swap nextprop
      dup not if pop break then
      room @ over array_get_propvals swap
    repeat
  }list
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

