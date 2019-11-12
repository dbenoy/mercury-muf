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
(*   "_config/emote/highlight_mention_format"                                *)
(*     When highlighting words from highlight_mention_names, this is used to *)
(*     add the highlight. @1 in this string is replaced with the text being  *)
(*     highlighted. It defaults to giving the word a blue color.             *)
(*                                                                           *)
(*   "_config/emote/color_name"                                              *)
(*     When this object sends an emote, this MCC coded color string that     *)
(*     will be used in place of its name. It must match the object's name    *)
(*     when the colors are stripped out, but it may replace underscores with *)
(*     spaces.                                                               *)
(*                                                                           *)
(*   "_config/emote/color_quoted"                                            *)
(*     When this object sends an emote, this color (In MGC [#HHHHHH] format) *)
(*     will be used for everything in the emote outside of quotes.           *)
(*                                                                           *)
(*   "_config/emote/color_unquoted"                                          *)
(*     When this object sends an emote, this color (In MGC [#HHHHHH] format) *)
(*     will be used for everything in the emote inside of quotes.            *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-EMOTE-emote[ str:message dict:opts -- ]                           *)
(*     Send an emote from the "from" object in opts. The emote is sent to    *)
(*     every zombie and player object in the same room, no matter where the  *)
(*     sender and the recipient are located in the room's object tree. The   *)
(*     emote is also logged in the room's properties for a certain amount of *)
(*     time. The message may not have a newline character.                   *)
(*                                                                           *)
(*     See M-LIB-EMOTE-style below for information on opts.                  *)
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
(*         "message"         - The emote message itself.                     *)
(*         "color_name"      - The color_name option from the sender.        *)
(*         "color_quoted"    - The color_quoted option from the sender.      *)
(*         "color_unquoted"  - The color_unquoted option from the sender.    *)
(*       }dict                                                               *)
(*       ...                                                                 *)
(*     }list                                                                 *)
(*                                                                           *)
(*     Only timestamp, object_name, message are guaranteed to be present.    *)
(*     The caller is expected to be able to handle the absence of other      *)
(*     entries, or the addition of new ones, but can expect them to always   *)
(*     be strings, except for the timestamp, which will always be an         *)
(*     integer.                                                              *)
(*                                                                           *)
(*   M-LIB-EMOTE-config_get[ ref:object str:option -- str:value ]            *)
(*     Specify a configuration option to get an emote setting from an        *)
(*     object. At present, option names are the names from PROPERTIES above, *)
(*     without the propdir component.                                        *)
(*                                                                           *)
(*   M-LIB-EMOTE-config_valid[ str:value ref:object str:option               *)
(*                             -- bool:valid? ]                              *)
(*     Specify a configuration option to check the validity of an emote      *)
(*     setting on an object. At present, option names are the names from     *)
(*     PROPERTIES above, without the propdir component.                      *)
(*                                                                           *)
(*   M-LIB-EMOTE-style[ str:message dict:opts -- str:result ]                *)
(*     Colors and highlights an emote as if it were sent from and to the     *)
(*     given objects and returns the resulting string.                       *)
(*                                                                           *)
(*     The following options can be supplied:                                *)
(*       "to" (dbref)                                                        *)
(*         When styling, treat this object as the target. The object will be *)
(*         checked for configuration options (See PROPERTIES above), such as *)
(*         name highlighting.                                                *)
(*                                                                           *)
(*       "from" (dbref)                                                      *)
(*         When styling, treat this object as the sender. The object will be *)
(*         checked for configuration options (See PROPERTIES above), such as *)
(*         name highlighting. M-LIB-EMOTE-emote uses this option to          *)
(*         determine which room to broadcast to.                             *)
(*                                                                           *)
(*       "message_format" (string)                                           *)
(*         This can be used to encapsulate the message in an MCC color coded *)
(*         string. @1 is replaced with the result of the styling. Example:   *)
(*                                                                           *)
(*         "Mercury says Hello!" + "[TEST]--- @1 ---"                        *)
(*         -> "[TEST]--- Mercury says Hello! ---"                            *)
(*                                                                           *)
(*       "highlight_mention" ("yes"/"no")                                    *)
(*         Enable mention highlighting.                                      *)
(*                                                                           *)
(*       "highlight_ooc_style" ("yes"/"no")                                  *)
(*         If the emote starts with the sender's name and a colon, then      *)
(*         treat the rest of the emote as if it's in quotes for coloring     *)
(*         purposes.                                                         *)
(*                                                                           *)
(*       "highlight_quote_level_min" (number)                                *)
(*         The lowest quote level (0 being 'not in quotes') that is allowed  *)
(*         when doing quote level highlighting.                              *)
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
$DOCCMD  @list __PROG__=2-156

(* Begin configurable options *)

$DEF HISTORY_PROPDIR           "_emote/@history/" (* Use a @ privileged property! *)
$DEF HISTORY_PROP_MAX_COUNT    "_emote/history_max_count"
$DEF HISTORY_PROP_MAX_AGE      "_emote/history_max_count"
$DEF HISTORY_DEFAULT_MAX_COUNT 100
$DEF HISTORY_DEFAULT_MAX_AGE   604800 (* One week *)
$DEF OPTIONS_PROPDIR           "_config/emote/"
$DEF USERLOG
$DEF THEME_COLOR_NAME          "[#A8A8A8]"
$DEF THEME_COLOR_UNQUOTED      "[#626262]"
$DEF THEME_COLOR_QUOTED        "[#A8A8A8]"

(* End configurable options *)

$IFDEF HISTORY_DEFAULT_MAX_COUNT<1
  ($ABORT HISTORY_DEFAULT_MAX_COUNT must be greater than 0.) (* Doesn't seem to work at the moment: https://github.com/fuzzball-muck/fuzzball/issues/477 *)
$ENDIF

(* ------------------------------------------------------------------------ *)

$PUBDEF :

$INCLUDE $m/lib/program
$INCLUDE $m/lib/array
$INCLUDE $m/lib/string
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/color

$DEF OPTIONS_VALID { "highlight_allow_custom" "highlight_mention_format" "highlight_mention_names" "color_name" "color_quoted" "color_unquoted" }list
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

: history_max_count ( d -- )
  (* TODO: Get it from the room properties. Also maybe have an enforced maximum? *)
  pop HISTORY_DEFAULT_MAX_COUNT
;

: history_max_age ( d -- )
  (* TODO: Get it from the room properties. Also maybe have an enforced maximum? *)
  pop HISTORY_DEFAULT_MAX_AGE
;

: config_valid[ str:value ref:object str:option -- bool:valid? ]
  value @ not if 0 exit then
  option @ tolower option !
  option @ "highlight_allow_custom" = if
    { value @ }list OPTIONS_VALID_HIGHLIGHT_ALLOW_CUSTOM array_intersect not not exit
  then
  option @ "color_name" = if
    object @ if
      value @ .color_strip "_" " " subst object @ name stringcmp 0 = exit
    else
      1 exit
    then
  then
  option @ "color_quoted" = option @ "color_unquoted" = or if
    value @
    dup dup toupper != if pop 0 exit then
    2 strcut swap "[#" != if pop 0 exit then
    6 strcut swap "[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]" smatch not if pop 0 exit then
    1 strcut swap "]" != if pop 0 exit then
    not exit
  then
  option @ "highlight_mention_format" = if
    value @ "@1" instr value @ strlen 60 < and exit
  then
  option @ "highlight_mention_names" = if
    value @ strlen 200 < exit
  then
;

: config_default[ ref:object str:option -- str:default ]
  option @ tolower option !
  option @ "color_name" = option @ "color_quoted" = or option @ "color_unquoted" = or if
    object @ not if "" exit then
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
      { "[#" rot "]" }join
    then
    exit
  then
  option @ "highlight_allow_custom" = if
    "YES" exit
  then
  option @ "highlight_mention_format" = if
    "[>000069][>001063]@1[<999063][<000069]" exit
  then
  option @ "highlight_mention_names" = if
    object @ not if "" exit then
    object @ name
    object @ name " " "_" subst over over != if
      ";" swap strcat strcat
    else
      pop
    then
    exit
  then
;

: config_get[ ref:object str:option dict:overrides -- str:value ]
  (* Check for an override *)
  overrides @ option @ [] dup if
    exit
  then
  pop
  (* Fetch the config option *)
  object @ ok? if
    object @ OPTIONS_PROPDIR "/" strcat option @ strcat getpropstr
  else
    object @ option @ config_default
  then
  dup object @ option @ config_valid not if
    pop object @ option @ config_default
  then
  option @ "highlight_allow_custom" = if
    toupper
  then
;

: history_clean[ ref:room int:max_count -- ]
  mode var! old_mode
  preempt
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
      dup "/" rsplit nip "message" = if good_count ++ then
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
  old_mode @ setmode
;

: history_add[ ref:message dict:opts ref:room -- ]
  mode var! old_mode
  preempt
  opts @ "from" [] var! from
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
    "color_name" from @ "color_name" opts @ config_get
    "color_quoted" from @ "color_quoted" opts @ config_get
    "color_unquoted" from @ "color_unquoted" opts @ config_get
    "message_format" opts @ "message_format" []
    "message" message @
  }dict var! entry
  room @ { HISTORY_PROPDIR "/" serial @ intostr "/" }join entry @ array_put_propvals
  old_mode @ setmode
;

: highlight_quotelevel_get[ ref:to ref:from int:level dict:opts -- str:result ]
  to @ "highlight_allow_custom" opts @ config_get "NOCOLOR" = if "" exit then
  var color_unquoted
  var color_quoted
  begin
    to @ "highlight_allow_custom" opts @ config_get "NO" = if
      from @ "color_unquoted" config_default color_unquoted !
      from @ "color_quoted" config_default color_quoted !
      break
    then
    to @ "highlight_allow_custom" opts @ config_get "PLAIN" = if
      THEME_COLOR_UNQUOTED color_unquoted !
      THEME_COLOR_QUOTED color_quoted !
      break
    then
    from @ "color_unquoted" opts @ config_get color_unquoted !
    from @ "color_quoted" opts @ config_get color_quoted !
  1 until

  level @ 0 <= if
    color_unquoted @
  else
    color_quoted @
  then
;

: highlight_name[ ref:to ref:from dict:opts -- str:result ]
  to @ if
    to @ "highlight_allow_custom" opts @ config_get "NOCOLOR" = if
      from @ "color_name" opts @ config_get .color_strip exit
    then
    to @ "highlight_allow_custom" opts @ config_get "NO" = if
      from @ "color_name" config_default exit
    then
    to @ "highlight_allow_custom" opts @ config_get "PLAIN" = if
      { THEME_COLOR_NAME from @ "color_name" opts @ config_get .color_strip }join exit
    then
  then
  from @ "color_name" opts @ config_get
;

: highlight_mention_format_get[ ref:to dict:opts -- str:result ]
  to @ "highlight_mention_format" opts @ config_get
  to @ "highlight_allow_custom" opts @ config_get "NOCOLOR" = if
    .color_strip
  then
;

$DEF EINSTRING over swap instring dup not if pop strlen else nip -- then
: style[ str:message dict:opts -- str:result ]
  "" var! result
  (* Emotes are not colored by the message text itself *)
  message @ .color_escape message !
  (* Store some frequently accessed information *)
  opts @ "from" [] var! from
  opts @ "to" [] var! to
  opts @ "highlight_mention" [] var! highlight_mention
  opts @ "highlight_ooc_style" [] var! highlight_ooc_style
  opts @ "highlight_quote_level_min" [] var! highlight_quote_level_min
  var from_uname
  var from_sname
  to @ from @ opts @ highlight_name var! from_hname
  from_hname @ .color_strip "_" " " subst var! from_uname
  from_hname @ .color_strip " " "_" subst var! from_sname
  var to_names
  to @ "highlight_mention_names" opts @ config_get ";" explode_array to_names !
  { to_names @ foreach nip dup not if pop then repeat }list to_names !
  (* Iterate through the string *)
  highlight_quote_level_min @ var! quote_level
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
    from_hname @ if
      message_remain @ from_uname @ instring 1 = message_remain @ from_sname @ instring 1 = or if
        message_prevchar @ "[0-9a-zA-Z]" smatch not if
          message_remain @ from_uname @ strlen strcut swap pop "[0-9a-zA-Z]*" smatch not if
            quote_level @ highlight_quote_level_min @ <= if
              (* We are at the from object's name, and it is on its own, and we're outside of quotes. Place the highlighted name and increment past it. *)
              result @ from_hname @ .color_strcat result !
              message_pos @ from_uname @ strlen + message_pos !
              highlight_ooc_style @ if
                (* Is this the beginning of the string, and is it followed by a colon? *)
                message_pos @ from_uname @ strlen = message_remain @ from_uname @ strlen strcut swap pop ":" instr 1 = and if
                  result @ to @ from @ quote_level @ opts @ highlight_quotelevel_get ":" strcat strcat result !
                  quote_level ++
                  quote_level @ highlight_quote_level_min !
                  message_pos ++
                then
              then
              continue
            then
          then
        then
      then
    then
    (* Check for to object's name *)
    to_names @ highlight_mention @ and if
      "" to_names @ foreach nip dup message_remain @ swap instring 1 = if swap pop break else pop then repeat var! found_name
      found_name @ if
        message_prevchar @ "[0-9a-zA-Z]" smatch not if
          message_remain @ found_name @ strlen strcut swap pop "[0-9a-zA-Z]*" smatch not if
            (* We are at the to object's name, and it is on its own, and we are not emoting to ourselves. Place the highlighted name and increment past it. *)
            result @ { to @ opts @ highlight_mention_format_get message_remain @ found_name @ strlen strcut pop "@1" subst }join .color_strcat result !
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
        result @ to @ from @ quote_level @ opts @ highlight_quotelevel_get "\"" strcat .color_strcat result !
        message_pos ++
        continue
      else
        (* Going down. Place the quote marke, then decrease the quote level. *)
        result @ to @ from @ quote_level @ opts @ highlight_quotelevel_get "\"" strcat .color_strcat result !
        message_pos ++
        0 quoting_up !
        quote_level --
        quote_level @ highlight_quote_level_min @ <= if highlight_quote_level_min @ quote_level ! then
        continue
      then
    then
    (* Nothing got highlighted *)
    (* Find the next potential highlight point, cut and increment to there. *)
    {
      message_remain @ "\"" EINSTRING
      from_hname @ if
        message_remain @ from_uname @ EINSTRING
        message_remain @ from_sname @ EINSTRING
      then
      to_names @ highlight_mention @ and if
        to_names @ foreach nip message_remain @ swap EINSTRING repeat
      then
    }list .array_min
    dup 1 < if
      pop 1
    then
    result @ message_remain @ 3 pick strcut pop to @ from @ quote_level @ opts @ highlight_quotelevel_get swap strcat .color_strcat result !
    message_pos @ swap + message_pos !
    message_pos @ message @ strlen >=
  until
  (* Apply the 'format' *)
  opts @ "message_format" [] result @ "@1" subst result !
  (* Return the result *)
  result @
;

: emote_cast[ str:message dict:opts ref:parent -- ]
  parent @ M-LIB-NOTIFY-cast_targets foreach
    nip
    var! to
    opts @
    to @ swap "to" ->[]
    opts @ "from" [] to @ = if
      0 swap "highlight_mention" ->[]
    then
    to @ message @ rot style .color_notify
  repeat
;

(* Take style options in user supplied format and clean them up into the format expected by the internal code *)
: style_opts_process[ dict:opts_in -- dict:opts_out ]
  var opt
  (* Set defaults *)
  {
    "from" #-1
    "to" #-1
    "message_format" "@1"
    "highlight_mention" "yes"
    "highlight_ooc_style" "no"
    "highlight_allow_custom" ""
    "highlight_mention_format" ""
    "highlight_mention_names" ""
    "highlight_quote_level_min" 0
    "color_name" ""
    "color_unquoted" ""
    "color_quoted" ""
  }dict var! opts_out
  (* Handle dbrefs *)
  { "from" "to" }list foreach
    nip
    opt !
    opts_in @ opt @ []
    dup string? if
      stod
    then
    dup dbref? if
      opts_out @ opt @ ->[] opts_out !
    else
      pop
    then
  repeat
  (* Handle strings *)
  { "message_format" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] opts_out @ opt @ ->[] opts_out !
  repeat
  (* Handle config overrides *)
  { "color_name" "color_unquoted" "color_quoted" "highlight_allow_custom" "highlight_mention_format" "highlight_mention_names" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] #-1 opt @ config_valid not if continue then
    opts_in @ opt @ [] opts_out @ opt @ ->[] opts_out !
  repeat
  (* Handle yes/no options *)
  { "highlight_mention" "highlight_ooc_style" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] "{yes|no}" smatch not if continue then
    opts_in @ opt @ [] "yes" stringcmp not opts_out @ opt @ ->[] opts_out !
  repeat
  (* Handle numbers *)
  { "highlight_quote_level_min" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not opts_in @ opt @ [] int? not and if continue then
    opts_in @ opt @ [] dup string? if atoi then opts_out @ opt @ ->[] opts_out !
  repeat
  (* Return result *)
  opts_out @
;

(* ------------------------------------------------------------------------- *)

(*****************************************************************************)
(*                             M-LIB-EMOTE-emote                             *)
(*****************************************************************************)
: M-LIB-EMOTE-emote[ str:message dict:opts -- ]
  message @ string? not if "Non-string argument (1)." abort then
  opts @ array? not if "Non-array argument (2)." abort then
  opts @ style_opts_process opts !
  opts @ "from" [] var! from
  from @ ok? not if "Valid object required for 'from' option." abort then
  opts @ "to" [] if "Emote with 'to' option specified." abort then
  "me" match from @ = not if
    "force_mlev1_name_notify" sysparm if
      .mlev2 not if "Requires MUCKER level 2 or above to send as other players." abort then
    then
  then
  message @ not if "Empty emote." abort then
  message @ "\r" instr if "Newlines are not allowed in emote message strings" abort then
  (* Ascend the object tree until a room is found *)
  from @ begin location dup room? until var! room
  (* Store the emote in the room history *)
  room @ room @ history_max_count -- history_clean
  message @ opts @ room @ history_add
  (* Construct styled messages and send out notifies *)
  message @ opts @ room @ emote_cast
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
  mode var! old_mode
  preempt
  room @ room @ history_max_count history_clean
  {
    HISTORY_PROPDIR begin
      room @ swap nextprop
      dup not if pop break then
      room @ over array_get_propvals swap
    repeat
  }list
  old_mode @ setmode
;
PUBLIC M-LIB-EMOTE-history_get
$LIBDEF M-LIB-EMOTE-history_get

(*****************************************************************************)
(*                          M-LIB-EMOTE-config_get                           *)
(*****************************************************************************)
: M-LIB-EMOTE-config_get[ ref:object str:option -- str:value ]
  (* M1 OK *)

  option @ string? not if "Non-string argument (1)." abort then
  option @ OPTIONS_VALID .array_hasval not if "Invalid option." abort then

  object @ option @ { }dict config_get
;
PUBLIC M-LIB-EMOTE-config_get
$LIBDEF M-LIB-EMOTE-config_get

(*****************************************************************************)
(*                         M-LIB-EMOTE-config_valid                          *)
(*****************************************************************************)
: M-LIB-EMOTE-config_valid[ str:value ref:object str:option -- bool:valid? ]
  (* M1 OK *)

  option @ string? not if "Non-string argument (1)." abort then
  option @ OPTIONS_VALID .array_hasval not if "Invalid option." abort then

  value @ object @ option @ config_valid
;
PUBLIC M-LIB-EMOTE-config_valid
$LIBDEF M-LIB-EMOTE-config_valid

(*****************************************************************************)
(*                             M-LIB-EMOTE-style                             *)
(*****************************************************************************)
: M-LIB-EMOTE-style[ str:message dict:opts -- str:result ]
  (* M1 OK *)
  message @ string? not if "Non-string argument (1)." abort then
  opts @ array? not if "Non-array argument (2)." abort then
  opts @ style_opts_process opts !
  message @ "\r" instr if "Newlines are not allowed in style message strings" abort then
  message @ opts @ style
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

