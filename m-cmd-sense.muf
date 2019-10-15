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
(*   @set smell=%v:smell                                                     *)
(*   @set smell=%w:smells                                                    *)
(*   @set smell=%x:smelled                                                   *)
(*   @set smell=%y:smelling                                                  *)
(*   @set smell=%z:smelled                                                   *)
(*   @set smell=_sense/aspect:scent                                          *)
(*   @set smell=_sense/overt:no                                              *)
(*   @set smell=_sense/contents_room:random                                  *)
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
(*   "_/<aspect>"                                                            *)
(*     On any object: This is the property you set an object its sense       *)
(*     description, where <aspect> is whatever you defined below in the      *)
(*     "_sense/aspect" property on the trigger action, 'sense' by default.   *)
(*                                                                           *)
(*     In the special case where the aspect is 'appearance', the property    *)
(*     used is "_/de" instead.                                               *)
(*                                                                           *)
(*     This is parsed as MPI.                                                *)
(*                                                                           *)
(*   "_sense/aspect"                                                         *)
(*     The thing that this sense acts upon. For example, for 'taste' it      *)
(*     would be 'flavor'. This also controls which property on objects is    *)
(*     used to store the description for this sense.                         *)
(*                                                                           *)
(*   "_sense/cast_room"                                                      *)
(*   "_sense/cast_object"                                                    *)
(*     On the trigger action: The message everyone in the room or non-room   *)
(*     object will see when the command is performed on it.                  *)
(*                                                                           *)
(*   "_sense/contents_room"                                                  *)
(*   "_sense/contents_object"                                                *)
(*     On the trigger action: If this is set to "yes" then when sensing a    *)
(*     room or non-room object, the object's contents will also be listed.   *)
(*     If set to "random" then only a portion of the object's contents will  *)
(*     be listed.                                                            *)
(*                                                                           *)
(*   "_sense/default_desc_object"                                            *)
(*   "_sense/default_desc_room"                                              *)
(*     On the trigger action: The default description that comes up when a   *)
(*     room or non-room's description is unset.                              *)
(*                                                                           *)
(*   "_sense/exits_room"                                                     *)
(*   "_sense/exits_object"                                                   *)
(*     On the trigger action: If this is set to "yes" then when sensing a    *)
(*     room or non-room, its actions will also be listed.                    *)
(*                                                                           *)
(*   "_sense/tell_object"                                                    *)
(*   "_sense/tell_room"                                                      *)
(*     On the trigger action: The message seen when someone successfully     *)
(*     performs the command on a room or non-room.  (Just before the         *)
(*     description.)                                                         *)
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
(*   Also, if you supply a '@<aspect>' alias to the action, players can use  *)
(*   @<aspect> object=value to set an object's aspect description for        *)
(*   objects they control.                                                   *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   All 'cast', 'tell', and 'default_desc' properties on the trigger use    *)
(*   the object substitution function from $m/lib/grammar, with these        *)
(*   objects:                                                                *)
(*                                                                           *)
(*     1 - The trigger action itself.                                        *)
(*     2 - The object doing the action.                                      *)
(*     3 - The target object/room.                                           *)
(*                                                                           *)
(*   Also, prior to the grammar substitution, these strings are substituted: *)
(*     "!1" - Aspect being acted on (_sense/aspect i.e. scent)               *)
(*                                                                           *)
(*   When listing the contents of a room, the %i property is used to get the *)
(*   name, and it is themed for the object type with $m/lib/theme.           *)
(*                                                                           *)
(*   The "match_name" option is used on all substitutions (except for exit   *)
(*   names when listing exits). "match_name" means that you can always be    *)
(*   sure that the name used in substitution matches the actual name of the  *)
(*   object, even if a builder puts something strange into the object's      *)
(*   properties.                                                             *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- October, 2019                            *)
(*     - Small modifications to bring it in line with Mercury MUF project    *)
(*       standards.                                                          *)
(*     - Changed the default from smell/scent to sense/aura.                 *)
(*     - The notice messages are now defined universally on the action, and  *)
(*       not in the environment.                                             *)
(*     - Removed the 'sense everyone in the room at once' feature.           *)
(*     - Removed the target notification and made it so everyone sees the    *)
(*       room notification.                                                  *)
(*     - Added contents and exits listing, can now be used as a 'look'       *)
(*       program.                                                            *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*     - Original implementation from Latitude MUCK                          *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004-2019 Daniel Benoy                                      *)
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

$DEF NOTICE_FORCE_NAME "yes" (* Require %d, %i, and %n properties in notices to match object name? *)
$DEF LISTING_OBJECTS_FORCE_NAME "yes" (* Non-exit %i values must match object name? *)
$DEF LISTING_EXITS_FORCE_NAME "no" (* Exit %i values must match exit name? *)

$DEFINE DEFAULT_TRIG_PROPS
  {
    "aspect"              "aura"
    "cast_object"         ""
    "cast_room"           ""
    "exits_room"          "no"
    "exits_object"        "no"
    "contents_room"       "no"
    "contents_object"     "no"
    "default_desc_object" "%3S doesn't seem to have a !1."
    "default_desc_room"   "This area has no distinct !1."
    "tell_object"         ""
    "tell_room"           ""
  }dict
$ENDDEF

(* End configurable options *)

$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/color

(* ------------------------------------------------------------------------- *)
: get_conf_on_action ( d s -- s )
  swap "_sense/" 3 pick strcat getpropstr
  dup if
    nip
  else
    pop
    DEFAULT_TRIG_PROPS swap []
    dup string? not if pop "" then
  then
;

: get_conf ( s -- s )
  trig swap get_conf_on_action
;

$def CAPS tolower 1 strcut swap toupper swap strcat

: M-HELP-desc ( d -- s )
  var! action
  "%v" { action @ }list { }dict M-LIB-GRAMMAR-sub CAPS " something." strcat
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
      "  %V an object, or %v the room in general if you don't specify an object." { action @ }list { }dict M-LIB-GRAMMAR-sub
      " "
      { action_name @ " <container>'s <object>" }join
      "  %V an object that is inside of another object." { action @ }list { }dict M-LIB-GRAMMAR-sub
    then
    action_name @ action_at_name @ and if
      " "
    then
    action_at_name @ if
      { action_at_name @ " <object>=<new" action @ "aspect" get_conf_on_action tolower ">" }join
      { "  Set a new " action @ "aspect" get_conf_on_action tolower " on an object." }join
    then
  }list
;
WIZCALL M-HELP-help

: sub_standard ( s -- s )
  "aspect" get_conf "!1" subst
;

: get_sense_prop ( -- s )
  "aspect" get_conf
  dup "appearance" stringcmp not if
    pop "_/de" exit
  then
  dup prop-name-ok? not over "/" instr or if
    "Trigger aspect has invalid characters!" abort
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

: line_contents[ ref:object int:is_random -- ]
  0 var! contents_random_skipped
  0 var! contents_total
  { }dict var! contents_datum
  { }list var! contents_data
  object @ loc @ = object @ me @ = or var! is_here
  object @ contents begin
    dup while
    dup var! room_object
    (* Exclude yourself, child rooms, and DARK objects *)
    room_object @ me @ = if
      next continue
    then
    room_object @ room? if
      next continue
    then
    room_object @ exit? if
      next continue
    then
    me @ room_object @ controls not me @ "SILENT" flag? or room_object @ "DARK" flag? and if
      next continue
    then
    me @ room_object @ controls not me @ "SILENT" flag? or object @ "DARK" flag? and if
      next continue
    then
    (* This is a detectable object, increment the total, and add it to the list to print later, unless it randomly gets ignored *)
    contents_total ++
    is_random @ random 3 % and if
      contents_random_skipped ++
      next continue
    then
    { "name" "%i" { room_object @ }list { "name_match" LISTING_OBJECTS_FORCE_NAME "name_theme" "yes" }dict M-LIB-GRAMMAR-sub }dict contents_datum !
    room_object @ player? if
      "A-" room_object @ name strcat contents_datum @ "index" array_setitem contents_datum !
    else room_object @ thing? room_object @ "ZOMBIE" flag? and if
      "B-" room_object @ name strcat contents_datum @ "index" array_setitem contents_datum !
    else
      "C-" room_object @ name strcat contents_datum @ "index" array_setitem contents_datum !
    then then
    contents_datum @ contents_data @ []<- contents_data !
    next
  repeat
  contents_total @ if
    {
      contents_data @ SORTTYPE_CASE_ASCEND "index" array_sort_indexed foreach
        nip
        "name" []
      repeat
    }list var! contents_names
    contents_names @ if
      { "You can %v " { trig }list { }dict M-LIB-GRAMMAR-sub contents_names @ "and" M-LIB-GRAMMAR-oxford_join }join
      contents_random_skipped @ if
        ", among other " "aspect" get_conf "s" strcat strcat strcat
      then
      "." strcat
    else
      { "There are other " "aspect" get_conf "s " is_here @ if "here" else "there" then ", too." }join
    then
  else
    ""
  then
;

: line_exits[ ref:object -- ]
  0 var! contents_total
  { }list var! contents_names
  object @ loc @ = object @ me @ = or var! is_here
  object @ exits begin
    dup while
    dup var! room_object
    (* Exclude yourself, child rooms, and DARK objects *)
    me @ room_object @ controls not room_object @ "DARK" flag? and if
      next continue
    then
    (* This is a detectable exit, increment the total, and add it to the list to print later. *)
    contents_total ++
    "%i" { room_object @ }list { "name_match" LISTING_EXITS_FORCE_NAME "name_theme" "yes" }dict M-LIB-GRAMMAR-sub contents_names @ []<- contents_names !
    next
  repeat
  contents_total @ if
    contents_names @ SORTTYPE_CASE_ASCEND array_sort contents_names !
    { "There is also " contents_names @ "and" M-LIB-GRAMMAR-oxford_join " " is_here @ if "here" else "there" then "." }join
  else
    ""
  then
;

(*****************************************************************************)
(                                 cmd_sense                                   )
(*****************************************************************************)
: sense_room[ ref:object ]
  (* Notify others *)
  "cast_room" get_conf sub_standard { trig me @ object @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub .color_cast
  (* Notify me *)
  "tell_room" get_conf sub_standard { trig me @ object @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub .color_tell
  (* Output room desc *)
  object @ get_sense_prop getpropstr if
    object @ get_sense_prop "(@" "aspect" get_conf strcat ")" strcat 1 parseprop
  else
    "default_desc_room" get_conf sub_standard { trig me @ object @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub
  then
  .color_tell
  (* Output contents *)
  "contents_room" get_conf dup "random" stringcmp not if pop 2 else "yes" stringcmp not then var! conf_contents_room
  conf_contents_room @ if
    object @ conf_contents_room @ 2 = line_contents .color_tell
  then
  (* Output exits *)
  "exits_room" get_conf "yes" stringcmp not if
    object @ line_exits .color_tell
  then
;

: sense_non_room[ ref:object ]
  (* Notify others *)
  "cast_object" get_conf sub_standard { trig me @ object @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub .color_cast
  (* Notify me *)
  "tell_object" get_conf sub_standard { trig me @ object @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub .color_tell
  (* Output desc *)
  object @ get_sense_prop getpropstr if
    object @ get_sense_prop "(@" "aspect" get_conf strcat ")" strcat 1 parseprop
  else
    "default_desc_object" get_conf sub_standard { trig me @ object @ }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub
  then
  .color_tell
  (* Output contents *)
  "contents_object" get_conf dup "random" stringcmp not if pop 2 else "yes" stringcmp not then var! conf_contents_object
  conf_contents_object @ if
    object @ conf_contents_object @ 2 = line_contents .color_tell
  then
  (* Output exits *)
  (* You can more-or-less only trigger actions on 'thing' type, and 'room' type objects, so only show exits for those *)
  object @ thing? if
    "exits_object" get_conf "yes" stringcmp not if
      object @ line_exits .color_tell
    then
  then
;

: cmd_sense_at ( s s -- d )
  strip swap strip

  match
  dup #-2 = if
    "I don't know which one you mean!" .err_tell
    pop exit
  then

  dup ok? not if
    "I don't see that here." .err_tell
    pop exit
  then

  dup location loc @ = not over loc @ = not and over location me @ = not and me @ "WIZARD" flag? not and if
    "I don't see that here." .err_tell
    pop exit
  then

  dup room? me @ "WIZARD" flag? not and if (* Only allow wizards to sniff into a room *)
    "You can't see that clearly." .err_tell exit
  then

  dup exit? if
    dup "_transparent?" getpropstr "window" stringcmp not if
      dup owner over getlink owner dbcmp if
        getlink
      then
    then
  then

  dup exit? if
    "You can't %1v through that exit." sub_standard { trig }list { "name_match" "yes" }dict M-LIB-GRAMMAR-sub .err_tell exit
  then

  swap
  rmatch
  dup #-2 = if
    "I don't know which one you mean!" .err_tell
    pop exit
  then

  dup ok? not if
    "I don't see that there." .err_tell
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
    "I don't know which one you mean!" .err_tell
    pop exit
  then

  dup ok? not if
    "I don't see that here." .err_tell
    pop exit
  then

  dup location loc @ = not over loc @ = not and over location me @ = not and me @ "WIZARD" flag? not and if
    "I don't see that here." .err_tell
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
    "Guests can't set their !1" sub_standard .err_tell exit
  then

  strip
  "=" split swap

  dup not if
    "You must use the format <object>=<player>" .err_tell exit
  then

  "aspect" get_conf "@" 1 strncmp not "aspect" get_conf "~" 1 strncmp not or if
    me @ "WIZARD" flag? not prog mlevel 4 >= not or if
      "Permission denied." .err_tell
      pop pop exit
    then
  then

  match
  dup #-2 = if
    "I don't know which one you mean." .err_tell
    pop pop exit
  then

  dup ok? not if
    "I don't see that here." .err_tell
    pop pop exit
  then

  me @ over controls not if
    "Permission denied." .err_tell
    pop pop exit
  then

  swap

  dup if
    get_sense_prop swap setprop
    "aspect" get_conf 1 strcut swap toupper swap strcat " set." strcat .err_tell
  else
    pop get_sense_prop remove_prop
    "aspect" get_conf 1 strcut swap toupper swap strcat " cleared." strcat .err_tell
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

