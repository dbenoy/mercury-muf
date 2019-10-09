!@program m-cmd-sense.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* cmd-senses.muf $cmd/senses                                                *)
(*   This program lets you give additional kinds of descriptions to objects, *)
(*   like taste, feel, sound, smell, etc. Make an action linked to this      *)
(*   program, customize some properties, and then it will create a new       *)
(*   command for that type of 'sensing.'                                     *)
(*                                                                           *)
(*   It can also be used as a 'look' program.                                *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* EXAMPLE:                                                                  *)
(*   @act smell;sniff;@smell=#0                                              *)
(*   @link smell=m-cmd-sense.muf                                             *)
(*   @set smell=_sense/presverb:smell                                        *)
(*   @set smell=_sense/pastverb:smelled                                      *)
(*   @set smell=_sense/prespart:smelling                                     *)
(*   @set smell=_sense/pastpart:smelled                                      *)
(*   @set smell=_sense/noun:scent                                            *)
(*   @set smell=_sense/overt:no                                              *)
(*   @set smell=_sense/everyone:yes                                          *)
(*   @create testobject                                                      *)
(*   smell testobject                                                        *)
(*   > You smell testobject.                                                 *)
(*   > testobject doesn't seem to have a scent.                              *)
(*   @smell testobject=It's like old cheese!                                 *)
(*   > Scent set.                                                            *)
(*   smell testobject                                                        *)
(*   > You smell testobject.                                                 *)
(*   > It's like old cheese!                                                 *)
(*                                                                           *)
(* PROPERTIES:                                                               *)
(*   "_/<noun>"                                                              *)
(*     On objects: This is the property you set an object its sense          *)
(*     description, where <noun> is whatever you defined below in the        *)
(*     "_sense/noun" property on the trigger action, or 'sense' by default.  *)
(*                                                                           *)
(*     In the special case where the noun is 'appearance', ththe property    *)
(*     used is "_/de" instead.                                               *)
(*                                                                           *)
(*     This is parsed as MPI.                                                *)
(*                                                                           *)
(*   "_sense/presverb"                                                       *)
(*     On the trigger action: The verb in present tense. (i.e. fly)          *)
(*                                                                           *)
(*   "_sense/pastverb"                                                       *)
(*     On the trigger action: The verb in past tense.    (i.e. flew)         *)
(*                                                                           *)
(*   "_sense/prespart"                                                       *)
(*     On the trigger action: The present participle     (i.e. flying)       *)
(*                                                                           *)
(*   "_sense/pastpart"                                                       *)
(*     On the trigger action: The past participle        (i.e. flown)        *)
(*                                                                           *)
(*   "_sense/noun"                                                           *)
(*     On the trigger action: The NOUN being acted on.   (i.e. wings)        *)
(*                                                                           *)
(*   "_sense/overt"                                                          *)
(*     On the trigger action: If this is "yes" then the target, as well as   *)
(*     others in the same location, will be alerted that the event has       *)
(*     happened.  Otherwise they will not.                                   *)
(*                                                                           *)
(*   "_sense/everyone"                                                       *)
(*     On the trigger action: Set this to "Yes" to make '<command> here' act *)
(*     on everyone/everything in the room as well as getting the description *)
(*     for the room itself. Set it to "Random" to make it get random descs   *)
(*     from the room, (and not show their source) Leave it unset, or set it  *)
(*     to anything else to make it only show the room description.           *)
(*                                                                           *)
(*   "_sense/desc"                                                           *)
(*     On the trigger action: The default description that comes up when the *)
(*     object's description is unset.                                        *)
(*                                                                           *)
(*   "_sense/roomdesc"                                                       *)
(*     On the trigger action: The default description that comes up when a   *)
(*     room's description is unset.                                          *)
(*                                                                           *)
(*   "_sense/notice"                                                         *)
(*     On the trigger action: The message seen when someone successfully     *)
(*     performs the command on an object. (Just before the description.)     *)
(*                                                                           *)
(*   "_sense/tnotice"                                                        *)
(*     On the trigger action: The message the target object sees when the    *)
(*     command is performed on them.                                         *)
(*                                                                           *)
(*   "_sense/onotice"                                                        *)
(*     On the trigger action: The message everyone else in the room sees     *)
(*     when the command is performed on someone.                             *)
(*                                                                           *)
(*   "_sense/noticehere"                                                     *)
(*     On the trigger action: The message seen when someone successfully     *)
(*     performs the command on a room.  (Just before the description.)       *)
(*                                                                           *)
(*   "_sense/onoticehere"                                                    *)
(*     On the trigger action: The message everyone else in the room sees     *)
(*     when the command is performed on a room.                              *)
(*                                                                           *)
(* USAGE:                                                                    *)
(*   <command>                                                               *)
(*     Verbs the room in general, viewing its desc and potentially the descs *)
(*     of objects in the room.                                               *)
(*                                                                           *)
(*   <command> <object>                                                      *)
(*     Verbs a specific object and views its desc.                           *)
(*                                                                           *)
(*   <command> <object>'s <object>                                           *)
(*     Verbs an object inside of a container object.                         *)
(*                                                                           *)
(*   Also, if you supply a '@<noun>' alias to the action, when that command  *)
(*   is used, it will allow                                                  *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   The following subtitutions are made in all 'notice' properties, as well *)
(*   as the 'desc' and 'roomdesc' properties.                                *)
(*     -"[PRESVERB]" - Present Tense Verb {i.e. eat}                         *)
(*     -"[PASTVERB]" - Past Tense {i.e. ate}                                 *)
(*     -"[PRESPART]" - Present Participle {i.e. eating}                      *)
(*     -"[PASTPART]" - Past Participle {i.e. eaten}                          *)
(*     -"[NOUN]"     - Noun being acted on {i.e. food}                       *)
(*                                                                           *)
(*   The following substituions are made to the _sense/notice string:        *)
(*     -Pronoun substitutions are made with the target as the subject.       *)
(*                                                                           *)
(*   The following substituions are made to the _sense/onotice string:       *)
(*     -The name of the person performing the action is prepended to the     *)
(*      string.                                                              *)
(*     -Pronoun substituions are made with the target as the subject.        *)
(*                                                                           *)
(*   The following subtitutions are made to the _sense/tnotice string:       *)
(*     -Pronoun substitutions are made with the person performing the action *)
(*      as the subject.                                                      *)
(*                                                                           *)
(*   The following substitutions are made to the _sense/onoticehere string:  *)
(*     -The name of the person performing the action is prepended to the     *)
(*      string.                                                              *)
(*     -Pronoun substitutions are made with the person performing the action *)
(*      as the subject.                                                      *)
(*                                                                           *)
(*   In the case of all pronoun substitution, %N will be replaced by the     *)
(*   real MUCK name of the subject, rather than the customizable property    *)
(*   name.                                                                   *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- October, 2019                            *)
(*     - Small modifications to bring it in line with Mercury MUF project    *)
(*       standards.                                                          *)
(*     - Changed the default from smell/scent to sense/aura.                 *)
(*     - The notice messages are now defined universally on the action, and  *)
(*       not in the environment.                                             *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*     - Original implementation from Latitude MUCK                          *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004  Daniel Benoy                                          *)
(*                                                                           *)
(* This program is free software; you can redistribute it and/or modify      *)
(* it under the terms of the GNU General Public License as published by      *)
(* the Free Software Foundation; either version 2 of the License, or         *)
(* {at your option} any later version.                                       *)
(*                                                                           *)
(* This program is distributed in the hope that it will be useful,           *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of            *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *)
(* GNU General Public License for more details.                              *)
(*                                                                           *)
(* You should have received a copy of the GNU General Public License         *)
(* along with this program; if not, write to the Free Software               *)
(* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA   *)
(*****************************************************************************)
$VERSION 1.0
$AUTHOR  Daniel Benoy
$NOTE    Customizable smell/taste/feel etc.
$DOCCMD  @list __PROG__=2-172

(* Begin configurable options *)

$DEF GUEST_CHECK ( d -- b ) "@guest" getprop (* is 'd' a guest? *)

$DEFINE DEFAULT_TRIG_PROPS
  {
    "presverb"    "sense"
    "pastverb"    "sensed"
    "prespart"    "sensing"
    "pastpart"    "sensed"
    "noun"        "aura"
    "overt"       "no"
    "everyone"    "no"
    "desc"        "%S doesn't seem to have a [NOUN]." 
    "roomdesc"    "This area has no distinct [NOUN]."
    "notice"      "You [PRESVERB] %N."
    "tnotice"     "just [PASTVERB] you!"
    "onotice"     "has just [PASTPART]"
    "noticehere"  ""
    "onoticehere" "is [PRESPART] the room [NOUN]s."
  }dict
$ENDDEF

(* End configurable options *)

(* ------------------------------------------------------------------------- *)
: get_conf_on_action ( d s -- s )
  swap "_sense/" 3 pick strcat getpropstr
  dup if
    nip
  else
    pop
    DEFAULT_TRIG_PROPS swap []
  then
;

: get_conf ( s -- s )
  trig swap get_conf_on_action
;

$def CAPS tolower 1 strcut swap toupper swap strcat

: M-HELP-desc ( d -- s )
  "presverb" get_conf_on_action CAPS " something." strcat
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- s )
  var! action
  (* Get the first action name without an @ *)
  "" var! action_name
  action @ name ";" explode_array foreach
    nip
    dup "@" stringpfx not if
      toupper action_name ! break
    then
    pop
  repeat
  (* Get the first action name with an @ *)
  "" var! action_at_name
  action @ name ";" explode_array foreach
    nip
    dup "@" stringpfx if
      toupper action_at_name ! break
    then
    pop
  repeat
  (* Construct the help lines *)
  {
    action_name @ if
      { action_name @ " [<object>]" }join
      { "  " action @ "presverb" get_conf_on_action CAPS " an object, or " action @ "presverb" get_conf_on_action tolower " the room in general if you don't specify an object." }join
      " "
      { action_name @ " <container>'s <object>" }join
      { "  " action @ "presverb" get_conf_on_action CAPS " an object that is inside of another object." }join
    then
    action_name @ action_at_name @ and if
      " "
    then
    action_at_name @ if
      { action_at_name @ " <object>=<new" action @ "noun" get_conf_on_action tolower ">" }join
      { "  Set a new " action @ "noun" get_conf_on_action tolower " on an object." }join
    then
  }list
;
WIZCALL M-HELP-help

: sub_standard ( s -- s )
  "presverb" get_conf "[PRESVERB]" subst
  "pastverb" get_conf "[PASTVERB]" subst
  "prespart" get_conf "[PRESPART]" subst
  "pastpart" get_conf "[PASTPART]" subst
  "noun"     get_conf "[NOUN]" subst
;

: sub_pronouns ( d s -- s' )
  over exit? if
    swap name ";" split pop dup rot rot "%N" subst swap "%n" subst
    "That direction's" "%A" subst
    "that direction's" "%a" subst
    "That direction"   "%S" subst
    "that direction"   "%s" subst
    "That direction"   "%O" subst
    "that direction"   "%o" subst
    "That direction's" "%P" subst
    "that direction's" "%p" subst
    "That direction"   "%R" subst
    "that direction"   "%r" subst
  else
    over name "%N" subst pronoun_sub
  then
;

: get_sense_prop ( -- s )
  "noun" get_conf
  dup "appearance" stringcmp not if
    pop "_/de" exit
  then
  dup prop-name-ok? not over "/" instr or if
    "Trigger noun has invalid characters!" abort
  then
  "_/" swap strcat
;

: contains? ( d1 d2 -- b ) (* If d1 is within d2, or they are identical *)
  swap
  begin
    dup #0 dbcmp not while
    over over dbcmp if pop pop 1 exit then
    location
  repeat
  pop pop 0
;

(*****************************************************************************)
(                                 cmd_sense                                   )
(*****************************************************************************)
: sense_room[ ref:object ]
  (* Notify me *)
  object @ "noticehere" get_conf sub_standard .tell
  (* Output room desc *)
  object @ get_sense_prop getpropstr if
    object @ get_sense_prop "(@" "noun" get_conf strcat ")" strcat 1 parseprop
  else
    "roomdesc" get_conf sub_standard
  then
  .tell
  (* Output descs of items in the room *)
  "everyone" get_conf
  dup "random" stringcmp not if
    pop 2
  else
    "yes" stringcmp not
  then
  var! everyone
  everyone @ if
    object @ contents begin
      dup while
      dup var! room_object
      everyone @ 2 = random 3 % and if
        next continue
      then
      room_object @ room? if
        next continue
      then
      me @ room_object @ controls not room_object @ "DARK" flag? and if
        next continue
      then
      room_object @ get_sense_prop getpropstr not if
        next continue
      then
      " " .tell
      { " [ " room_object @ name " ] " room_object @ get_sense_prop "(@" "noun" get_conf strcat ")" strcat 1 parseprop }join .tell
      next
    repeat
  then
  (* Notify others *)
  "overt" get_conf "yes" stringcmp not if
    object @ me @ { me @ name " " me @ "onoticehere" get_conf sub_standard sub_pronouns }join notify_except
  then
;

: sense_non_room[ ref:object ]
  (* Notify me *)
  object @ "notice" get_conf sub_standard sub_pronouns .tell
  (* Output desc *)
  object @ get_sense_prop getpropstr if
    object @ get_sense_prop "(@" "noun" get_conf strcat ")" strcat 1 parseprop
  else
    object @ "desc" get_conf sub_standard sub_pronouns
  then
  .tell
  (* Notify others *)
  object @ me @ contains? not "overt" get_conf "yes" stringcmp not and if
    (* Target *)
    object @ { me @ name " " me @ "tnotice" get_conf sub_standard sub_pronouns }join notify
    (* In the room *)
    object @ me @ object @ 2 { me @ name " " object @ "onotice" get_conf sub_standard sub_pronouns object @ "." }join notify_exclude
  then
;

: cmd_sense_at ( s s -- d )
  strip swap strip

  match
  dup #-2 = if
    "I don't know which one you mean!" .tell
    pop exit
  then

  dup ok? not if
    "I don't see that here." .tell
    pop exit
  then

  dup location loc @ = not over loc @ = not and over location me @ = not and me @ "WIZARD" flag? not and if
    "I don't see that here." .tell
    pop exit
  then

  dup room? me @ "WIZARD" flag? not and if (* Only allow wizards to sniff into a room *)
    "You can't see that clearly." .tell exit
  then

  dup exit? if
    dup "_transparent?" getpropstr "window" stringcmp not if
      dup owner over getlink owner dbcmp if
        getlink
      then
    then
  then

  dup exit? if
    "You can't [PRESVERB] through that exit." sub_standard .tell exit
  then

  swap
  rmatch
  dup #-2 = if
    "I don't know which one you mean!" .tell
    pop exit
  then

  dup ok? not if
    "I don't see that there." .tell
    pop exit
  then

  dup room? if
    sense_room
  else
    sense_non_room
  then
;

: cmd_sense ( s --  )
  dup not if
    loc @ sense_room exit
  then

  dup "=" instr if
    dup "=" split pop match ok? if
      "=" split cmd_sense_at exit
    then
  then

  dup "'s " instr if
    dup "'s " split pop match ok? if
      "'s " split cmd_sense_at exit
    then
  then

  dup " at " instr if
    dup " at " split pop match ok? if
      " at " split cmd_sense_at exit
    then
  then

  match
  dup #-2 = if
    "I don't know which one you mean!" .tell
    pop exit
  then

  dup ok? not if
    "I don't see that here." .tell
    pop exit
  then

  dup location loc @ = not over loc @ = not and over location me @ = not and me @ "WIZARD" flag? not and if
    "I don't see that here." .tell
    pop exit
  then

  dup room? if
    sense_room
  else
    sense_non_room
  then
;

(*****************************************************************************)
(                                  cmd_set                                    )
(*****************************************************************************)
: cmd_set ( s --  )
  me @ GUEST_CHECK if
    "Guests can't set their [NOUN]" sub_standard .tell exit
  then

  strip
  "=" split swap

  dup not if
    "You must use the format <object>=<player>" .tell exit
  then

  "noun" get_conf "@" 1 strncmp not "noun" get_conf "~" 1 strncmp not or if
    me @ "WIZARD" flag? not prog mlevel 4 >= not or if
      "Permission denied." .tell
      pop pop exit
    then
  then

  match
  dup #-2 = if
    "I don't know which one you mean." .tell
    pop pop exit
  then

  dup ok? not if
    "I don't see that here." .tell
    pop pop exit
  then

  me @ over controls not if
    "Permission denied." .tell
    pop pop exit
  then

  swap

  dup if
    get_sense_prop swap setprop
    "noun" get_conf 1 strcut swap toupper swap strcat " set." strcat .tell
  else
    pop get_sense_prop remove_prop
    "noun" get_conf 1 strcut swap toupper swap strcat " cleared." strcat .tell
  then
;

(*****************************************************************************)
(                                   main                                      )
(*****************************************************************************)
: main
  command @ "@" stringpfx if
    cmd_set exit
  then
  cmd_sense
;
.
c
q
!@register m-cmd-sense.muf=m/cmd/sense
!@set $m/cmd/sense=M3
!@set $m/cmd/sense=W

