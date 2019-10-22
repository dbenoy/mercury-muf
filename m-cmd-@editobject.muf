!@program m-cmd-@editobject.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@editobject.muf - $m/cmd/at_editobject                              *)
(*    A command for editing objects of any type, including players, rooms,   *)
(*    things, and exits.                                                     *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*     - Modified for inclusion in mercury-muf                               *)
(*     - Removed "Jaffa's cmd-look" support, and other unneeded libraries.   *)
(*     - Reduced the scope of the menus to just be a tool for builders,      *)
(*       rather than having a bunch of options for player settings, etc.     *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*     - Original implementation for Latitude MUCK                           *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004-2019                                                   *)
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
$VERSION 1.001
$AUTHOR  Daniel Benoy
$NOTE    An interface for editing objects.
$DOCCMD  @list __PROG__=2-34

(* Begin configurable options *)

$DEF .chars-per-row 79

(* End configurable options *)

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Edit an object."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <object>" }join
    "  Brings up an editing menu system to modify an object. You can edit players, rooms, things, exits, etc."
    "  Try editing 'me' or 'here'."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

$PUBDEF :

$INCLUDE $m/lib/program
$INCLUDE $m/lib/color
$INCLUDE $m/lib/match
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/grammar
$INCLUDE $m/cmd/at_action
$INCLUDE $m/cmd/at_attach
$INCLUDE $m/cmd/at_link
$INCLUDE $m/cmd/at_unlink
$INCLUDE $m/cmd/at_recycle
$INCLUDE $m/cmd/at_lsedit

(* Begin global variables *)

lvar g_object (* Set to the object being edited in main *)
lvar g_table  (* Set to the appropriate table in main *)

(* These are intialized in main. *)
lvar g_table_mgc
lvar g_table_player_flags
lvar g_table_player
lvar g_table_room_flags
lvar g_table_room
lvar g_table_thing_flags
lvar g_table_thing
lvar g_table_exit
lvar g_table_program

(* End global variables *)

(*****************************************************************************)
(                             support functions                               )
(*****************************************************************************)
: chk_perms ( d -- b )
  (* You can always edit yourself *)
  (
  "me" match over dbcmp if
    1 exit
  then
  )

  (* Builders can edit anything they control *)
  "me" match swap controls "me" match "BUILDER" flag? "me" match "WIZARD" flag? or and if
    1 exit
  then

  0 exit
;

(* For some reason, default stod returns #0 on failure.  <sigh>  Here's a replacement.  *)
: str_to_dbref ( s -- d )

  dup string? not if
    pop #-1 exit
  then

  dup "#" instr 1 = if
    1 strcut swap pop (* Shave off the # if there is one *)
  then

  dup number? not if
    pop #-1 exit
  then

  stod
;

(*****************************************************************************)
(                          gets and sets for tables                           )
(*****************************************************************************)
(***** Change menus *****)
: set_menu[ var:newmenu --  ]
  newmenu @ @ g_table !
;

: set_menu_default[ --  ]
  g_object @ player? if
    g_table_player @ g_table ! exit
  then

  g_object @ room? if
    g_table_room @ g_table ! exit
  then

  g_object @ thing? if
    g_table_thing @ g_table ! exit
  then

  g_object @ exit? if
    g_table_exit @ g_table ! exit
  then

  g_object @ program? if
    g_table_program @ g_table ! exit
  then

  "Unknown object type!" abort
;

(***** get/set Flag *****)
: get_flag[ str:flag str:valueTrue str:valueFalse -- str:value ]
  g_object @ flag @ flag? if
    valueTrue @
  else
    valueFalse @
  then
;

: set_flag[ str:flag --  ]
  read

  dup "{y|ye|yes}" smatch if
    g_object @ flag @ set
    pop exit
  then

  dup "{n|no}" smatch if
    g_object @ "!" flag @ strcat set
    pop exit
  then

  "Cancelled." .tell
  pop
;

(***** get/set String Property *****)
: get_str[ str:property str:unsetValue -- str:value ]
  g_object @ property @ getpropstr

  dup not if
    pop unsetValue @ { g_object @ }list { "name_match" "no" "name_theme" "no" "color" "keep" }dict M-LIB-GRAMMAR-sub exit
  then

  dup "\r" instr if
    "\r" split pop
    "[!FFFFFF]..." strcat
  then
;

: set_str[ str:property --  ]
  "(Enter a space, to clear.)" .tell

  read

  dup strip not if
    g_object @ property @ remove_prop
  else
    g_object @ property @ rot setprop
  then
;

(***** set String Property From a List of Selections *****)
: set_str_pick[ str:property list:options --  ]

  "Options:" .tell
  options @ "\r" array_join .tell
  " " .tell

  read

  0
  options @ foreach
    swap pop
    3 pick stringcmp not if
      pop 1 break
    then
  repeat

  if
    tolower 1 strcut swap toupper swap strcat
    g_object @ property @ rot setprop
    "Set." .tell
  else
    "'" swap strcat "' is not one of the options." strcat .tell
  then
;

(***** get/set String Boolean Property *****)
: get_str_bool[ str:property str:valueTrue str:valueFalse -- str:value ]
  g_object @ property @ getpropstr

  "yes" stringcmp not if
    valueTrue @
  else
    valueFalse @
  then
;

: get_str_bool2[ str:property str:valueTrue str:valueFalse -- str:value ] (* this one is for defaulting to yes *)
  g_object @ property @ getpropstr

  "no" stringcmp not if
    valueFalse @
  else
    valueTrue @
  then
;

: set_str_bool[ str:property --  ]
  read

  dup "{y|ye|yes}" smatch if
    g_object @ property @ "yes" setprop
    pop exit
  then

  dup "{n|no}" smatch if
    g_object @ property @ "no" setprop
    pop exit
  then

  "Cancelled." .tell
  pop
;

: set_str_bool2[ str:property --  ] (* This one is for clearing a prop, instead of setting no *)
  read

  dup "{y|ye|yes}" smatch if
    g_object @ property @ "yes" setprop
    pop exit
  then

  dup "{n|no}" smatch if
    g_object @ property @ remove_prop
    pop exit
  then

  "Cancelled." .tell
  pop
;

(***** get/set Integer Boolean Property *****)
: get_bool[ str:property str:valueTrue str:valueFalse -- str:value ]
  g_object @ property @ getpropval if
    valueTrue @
  else
    valueFalse @
  then
;

: set_bool[ str:property --  ]
  read

  dup "{y|ye|yes}" smatch if
    g_object @ property @ 1 setprop
    pop exit
  then

  dup "{n|no}" smatch if
    g_object @ property @ 0 setprop
    pop exit
  then

  "Cancelled." .tell
  pop
;

(***** get an MPI parsed value *****)
: get_mpi[ str:property str:unsetValue -- str:value ]
  g_object @ property @ prog name 0 parseprop

  dup not if
    pop unsetValue @ exit
  then

  dup "\r" instr if
    "\r" split pop
    "[!FFFFFF]..." strcat
  then
;

(***** get/set name *****)
: get_obj_name[  -- str:value ]
  g_object @ .theme_name
;

: set_obj_name[  --  ]
  read
  g_object @ swap setname
;

(***** set a string to {eval:{list:<property list>}}, and edit the corresponding list *****)
: set_mpi_list[ str:property str:listprop --  ]
  (* Use existing property if available *)
  g_object @ property @ getpropstr
  dup "{eval:{list:" stringpfx if
    12 strcut swap pop
    dup strlen 2 - strcut "}}" stringcmp not if
      dup listprop !
    then
  then
  pop

"<   You are now editing a multi-line description.  To produce a blank   >" .tell
"<    line, press space, then enter.  Enter '.h' to get command help.    >" .tell
"< '.end' will exit and save the list.  '.abort' will abort any changes. >" .tell
"<    To save changes to the list, and continue editing, use '.save'     >" .tell

  g_object @ listprop @ M-CMD-AT_LSEDIT-ListEdit if
    g_object @ property @ "{eval:{list:" listprop @ strcat "}}" strcat setprop
  then
;

(***** get/set Obvious Exits Output *****)
: get_obv_exits[ str:valueYes str:valueNo str:valueMaybe -- str:value ]
  g_object @ "/_/sc" getpropstr

  dup not if
    pop valueNo @ exit
  then

  "[Exits: {obvexits}]" stringcmp not if
    valueYes @
  else
    valueMaybe @
  then
;

: set_obv_exits[ --  ]
  read

  dup "{y|ye|yes}" smatch if
    g_object @ "/_/sc" "[Exits: {obvexits}]" setprop
    pop exit
  then

  dup "{n|no}" smatch if
    g_object @ "/_/sc" remove_prop
    pop exit
  then

  "Cancelled." .tell
  pop
;

(***** Get/set the current morph *****)
: get_morph[  -- str:value ]
  g_object @ "/_morph" getpropstr

  dup "\r" instr if
    pop "UNKNOWN" exit
  then

  dup not if
    g_object @ "/_morph" "Default" setprop
    pop "Default" exit
  then
;

(***** Get source or destinations for exits *****)
: get_source[  -- str:value ]
  g_object @ exit? if
    g_object @ location

    dup "me" match swap controls if
      .theme_unparseobj
    else
      .theme_name
    then
  else
    "UNKNOWN"
  then
;

: set_source[  --  ]
  "(Enter a #dbref, *player_name, present object's name, 'me', 'here', or 'home')" .tell
  read

  { "#" g_object @ intostr }join swap M-CMD-AT_ATTACH-Attach
;

: get_link[ str:valueUnlinked -- str:value ]
  g_object @ getlink

  dup not if
    pop valueUnlinked @ exit
  then

  dup "me" match swap controls if
    .theme_unparseobj
  else
    .theme_name
  then
;

: set_link[  --  ]
  "(Enter a #dbref, *player_name, present object's name, 'me', 'here', or 'home' or '.' to unlink)" .tell
  read

  dup "." = if
    { "#" g_object @ intostr }join M-CMD-AT_UNLINK-unlink pop
  else
    { "#" g_object @ intostr }join swap M-CMD-AT_LINK-relink pop
  then
;

(***** create/switch to/delete exits *****)
: set_exits_edit[  --  ]
  g_object @ program? g_object @ exit? if
    "Should not be called on an exit or program." abort
  then

  g_object @ exits_array var! myExits

  myExits @ foreach
    swap ++ intostr "bold,cyan" textattr "] " rot name strcat "dim,cyan" textattr strcat "[" "dim,cyan" textattr swap strcat .tell
  repeat
  "Select an exit:" .tell

  read

  atoi -- (* I like counting from 0 .. but 0 is atoi's error code.  So whatever.  I'll count from 1 *)

  myExits @ swap [] dup not if
    pop "Sorry, that's not one of the selections." .tell exit
  then

  dup chk_perms not if
    pop "Permission denied.  (Try exiting the editor and running 'help @chown' for information on seizing exits.)" .tell exit
  then

  g_object !
  set_menu_default
;

: set_exit_new[  --  ]

  "Enter the name of the new exit:" .tell

  "#" g_object @ intostr strcat read M-CMD-AT_ACTION-Action

  dup if
    dup chk_perms not if
      pop "FATAL ERROR: Permission denied editing newly created exit!" .tell pid kill
    then

    g_object !
    set_menu_default
  else
    pop
  then
;

: set_exit_recycle[  --  ]

  g_object @ program? g_object @ exit? if
    "Should not be called on an exit or program." abort
  then

  g_object @ exits_array var! myExits

  myExits @ foreach
    swap ++ intostr "bold,cyan" textattr "] " rot name strcat "dim,cyan" textattr strcat "[" "dim,cyan" textattr swap strcat .tell
  repeat
  "Select an exit:" .tell

  read

  atoi -- (* I like counting from 0 .. but 0 is atoi's error code.  So whatever.  I'll count from 1 *)

  myExits @ swap [] dup not if
    pop "Sorry, that's not one of the selections." .tell exit
  then

  dup chk_perms not if
    pop "Permission denied.  (Try exiting the editor and running 'help @chown' for information on seizing exits.)" .tell exit
  then

  "#" swap intostr strcat 1 M-CMD-AT_RECYCLE-Recycle
;

(***** Change to parent objects *****)
: set_parent[  --  ]
  g_object @ location

  dup not if
    pop "This doesn't have a parent!" .tell exit
  then

  dup chk_perms not if
    pop "Permission denied." .tell exit
  then

  g_object !
  set_menu_default
;

: get_parent[ str:valueRoom str:valuePlayer str:valueOtherwise -- str:value ]
  g_object @ location

  dup room? if
    pop valueRoom @ exit
  then

  dup player? if
    pop valuePlayer @ exit
  then

  pop valueOtherwise @ exit
;

(***** Get the type of this object *****)
: get_object_type[ str:valueRoom str:valuePlayer str:valueOtherwise -- str:value ]

  g_object @ room? if
    valueRoom @ exit
  then

  g_object @ player? if
    valuePlayer @ exit
  then

  valueOtherwise @ exit
;

(***** force user to execute command *****)
: set_external[ ref:program str:newCommand --  ]
  command @ var! oldCommand

  newCommand @ command !
  "" program @ call
  oldCommand @ command !
;

(***** do nothing *****)
: set_null[  --  ]
;

: get_null[  -- str:value ]
  ""
;

(#############################################################################)
(############################## PLAYER TABLES ################################)
(#############################################################################)
: table_mgc (  -- a )
  {
    "" (* Blank line after header *)

    1

    "Names"

    { "N"
      "[#00AAAA][[#55FFFF]N[#00AAAA]]ame:                                [#5555FF]@1"
      'get_str     { "%n" "[#0000AA]%n[!FFFFFF]" }list

      {
        "This is an alternative version of your name that you want to show up in sentences generated by the server. MCC color codes are allowed, but may be ignored. It can be anything you want, but it's possible it will be ignored if it doesn't match your name with only minor differences, such as replacing underscores with spaces."
        ""
        "Enter the substition name for this object:"
      }list "\r" array_join
      'set_str     { "%n" }list
    }list

    { "D"
      "[#00AAAA][[#55FFFF]D[#00AAAA]]efinite Name:                       [#5555FF]@1"
      'get_str     { "%d" "[#0000AA]%d[!FFFFFF]" }list

      {
        "This is the 'definite noun phrase' for the name of your object."
        "In the case of proper nouns/phrases, such as player names, just use the name alone."
        "Example objects: the golden ticket, the honarary degree, The Crown of England, C3P0."
        "Example rooms: the dark cave, the evil lair, the hospital, Fluttershy's House."
        ""
        "Enter the definite noun phrase for this object:"
      }list "\r" array_join
      'set_str     { "%d" }list
    }list

    { "I"
      "[#00AAAA][[#55FFFF]I[#00AAAA]]ndefinite Name:                     [#5555FF]@1"
      'get_str     { "%i" "[#0000AA]%i[!FFFFFF]" }list

      {
        "This is the 'indefinite/definite noun phrase' for the name of your object. Use the indefinite noun phrase, unless the definite sense is more appropriate for this particular object."
        "In the case of proper nouns/phrases, such as player names, just use the name alone."
        "Example objects: a golden ticket, an honarary degree, The Crown of England, C3P0."
        "Example rooms: a dark cave, an evil lair, the hospital, Fluttershy's House."
        ""
        "Enter the indefinite noun phrase for this object:"
      }list "\r" array_join
      'set_str     { "%i" }list
    }list

    "Pronouns"

    { "A"
      "[#00AAAA][[#55FFFF]A[#00AAAA]]bsolute Posessive (his/hers/its):   [#5555FF]@1"
      'get_str     { "%a" "[#0000AA]%a[!FFFFFF]" }list

      {
        "Enter the absolute posessive pronoun (his/hers/its) of this object:"
      }list "\r" array_join
      'set_str     { "%a" }list
    }list

    { "S"
      "[#00AAAA][[#55FFFF]S[#00AAAA]]ubjective (he/she/it):              [#5555FF]@1"
      'get_str     { "%s" "[#0000AA]%s[!FFFFFF]" }list

      {
        "Enter the subjective pronoun (he/she/it) of this object:"
      }list "\r" array_join
      'set_str     { "%s" }list
    }list

    { "O"
      "[#00AAAA][[#55FFFF]O[#00AAAA]]bjective (him/her/it):              [#5555FF]@1"
      'get_str     { "%o" "[#0000AA]%o[!FFFFFF]" }list

      {
        "Enter the objective pronoun (him/her/it) of this object:"
      }list "\r" array_join
      'set_str     { "%o" }list
    }list

    { "P"
      "[#00AAAA][[#55FFFF]P[#00AAAA]]ossessive (his/her/its):            [#5555FF]@1"
      'get_str     { "%p" "[#0000AA]%p[!FFFFFF]" }list

      {
        "Enter the poessive pronoun (his/her/its) of this object:"
      }list "\r" array_join
      'set_str     { "%p" }list
    }list

    { "R"
      "[#00AAAA][[#55FFFF]R[#00AAAA]]eflexive (himself/herself/itself):  [#5555FF]@1"
      'get_str     { "%r" "[#0000AA]%r[!FFFFFF]" }list

      {
        "Enter the reflexive pronoun (himself/herself/itself) of this object:"
      }list "\r" array_join
      'set_str     { "%r" }list
    }list

    "Verbs"

    { "V"
      "[#00AAAA][[#55FFFF]V[#00AAAA]]erb:                                [#5555FF]@1"
      'get_str     { "%v" "[#0000AA]%v[!FFFFFF]" }list

      {
        "This is typically only used on exit objects."
        "Enter the verb (eat, go east) of this object:"
      }list "\r" array_join
      'set_str     { "%v" }list
    }list

    { "W"
      "[#00AAAA][[#55FFFF]W[#00AAAA]] Present Indicitive Verb:           [#5555FF]@1"
      'get_str     { "%w" "[#0000AA]%w[!FFFFFF]" }list

      {
        "This is typically only used on exit objects."
        "Enter the present indicitive verb (eats, goes east) of this object:"
      }list "\r" array_join
      'set_str     { "%w" }list
    }list

    { "X"
      "[#00AAAA][[#55FFFF]X[#00AAAA]] Past Tense Verb:                   [#5555FF]@1"
      'get_str     { "%x" "[#0000AA]%x[!FFFFFF]" }list

      {
        "This is typically only used on exit objects."
        "Enter the past tense verb (ate, went east) of this object:"
      }list "\r" array_join
      'set_str     { "%x" }list
    }list

    { "Y"
      "[#00AAAA][[#55FFFF]Y[#00AAAA]] Participle Verb:                   [#5555FF]@1"
      'get_str     { "%y" "[#0000AA]%y[!FFFFFF]" }list

      {
        "This is typically only used on exit objects."
        "Enter the participle verb (eating, going east) of this object:"
      }list "\r" array_join
      'set_str     { "%y" }list
    }list

    { "Z"
      "[#00AAAA][[#55FFFF]Z[#00AAAA]] Past Tense Participle Verb:        [#5555FF]@1"
      'get_str     { "%z" "[#0000AA]%z[!FFFFFF]" }list

      {
        "This is typically only used on exit objects."
        "Enter the past tense participle verb (eaten, gone east) of this object:"
      }list "\r" array_join
      'set_str     { "%z" }list
    }list


    ""
    { "B"
      "[#00AAAA][[#55FFFF]B[#00AAAA]]ack to @1 Edit"
      'get_object_type { "Room" "Player" "Object" }list

      {
      }list "\r" array_join
      'set_menu_default { }list
    }list
  }list
;

: table_player_flags (  -- a )
  {
    "" "Flags" 1

    { "C"
      "[#00AAAA][[#55FFFF]C[#00AAAA]]olor:      [#5555FF]@1"
      'get_flag    { "COLOR" "Yes [#555555](Color enabled.)[!FFFFFF]" "[#FF5555]NO[!FFFFFF]  [#550000](Color is disabled!)[!FFFFFF]" }list

      {
        "Does your client support color? (y/n)"
      }list "\r" array_join
      'set_flag    { "COLOR" }list
    }list

    { "S"
      "[#00AAAA][[#55FFFF]S[#00AAAA]]ilent:     [#5555FF]@1"
      'get_flag    { "SILENT" "Yes [#555555](You won't be able to see your DARK objects.)[!FFFFFF]" "No  [#555555](You will be able to see your objects even if they're DARK.)[!FFFFFF]" }list

      {
        "A player can set themselves \"SILENT\" and not see all the dbrefs and dark objects that they own.  They won't see objects in a dark room either.  They still control the objects though."
        ""
        "Set the SILENT flag on this character? (y/n)"
      }list "\r" array_join
      'set_flag    { "SILENT" }list
    }list

    { "H"
      "[#00AAAA][[#55FFFF]H[#00AAAA]]aven:      [#5555FF]@1"
      'get_flag    { "HAVEN" "Yes [#555555](You're set to not be disturbed.)[!FFFFFF]" "No  [#555555](You can receive pages, etc.)[!FFFFFF]" }list

      {
        "If a player is set HAVEN, they cannot be paged."
        "There are also other benifits to setting yourself HAVEN.  Whereis, and other intrusive programs should stop bothering you and helping others bother you."
        ""
        "Set the HAVEN flag on this character? (y/n)"
      }list "\r" array_join
      'set_flag    { "HAVEN" }list
    }list

    { "L"
      "[#00AAAA][[#55FFFF]L[#00AAAA]]ink_OK:    [#5555FF]@1"
      'get_flag    { "LINK_OK" "[#FF5555]YES[!FFFFFF] [#550000](Others can set their object homes on you!)[!FFFFFF]" "No  [#555555](Others can not set their object homes on you.)[!FFFFFF]" }list

      {
        "When you're set LINK_OK, people can set the 'homes' of objects on you.  This is generally dangerous, because when combined with the STICKY flag on an object, it can be real hard to get rid of if someone sets its home on you.  If you end up in this situation, try @unlink <object name>.  It's a good idea to leave this off at all times unless you want someone to link an object to you."
        ""
        "Set the LINK_OK flag on this character? (y/n)"
      }list "\r" array_join
      'set_flag    { "LINK_OK" }list
    }list

    { "X"
      "[#00AAAA][[#55FFFF]X[#00AAAA]] Forcible: [#5555FF]@1"
      'get_flag    { "XFORCIBLE" "[#FF5555]YES[!FFFFFF] [#550000](Others can force you to perform actions!)[!FFFFFF]" "No  [#555555](Others can't force you to perform actions.)[!FFFFFF]" }list

      {
        "When set XForcible, a player can force your character to perform an action as though it was entered directly by that character."
        "This flag must also be used in combination with the @flock command.  See 'help @flock' for more details."
        ""
        "Set the XFORCIBLE flag on this character? (y/n)"
      }list "\r" array_join
      'set_flag    { "XFORCIBLE" }list
    }list

    { "J"
      "[#00AAAA][[#55FFFF]J[#00AAAA]]ump_OK:    [#5555FF]@1"
      'get_flag    { "JUMP_OK" "Yes [#555555](Teleports and thowing allowed.)[!FFFFFF]" "No  [#555555](Teleports and throwing blocked.)[!FFFFFF]" }list

      {
        "Allow teleports and throwing? (y/n)"
      }list "\r" array_join
      'set_flag    { "JUMP_OK" }list
    }list

    ""
    { "{P|B}"
      "[#00AAAA][[#55FFFF]B[#00AAAA]]ack to Player Edit"
      'get_null { }list

      {
      }list "\r" array_join
      'set_menu { g_table_player }list
    }list
  }list
;

: table_player (  -- a )
  {
    2
    "" (* Blank line after header *)

    { "1"
      "[#00AAAA][[#55FFFF]1[#00AAAA]] Species: [#5555FF]@1"
      'get_str     { "_/species" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "Your species is the type of being your character is."
        "To avoid confusion, please prefix your species name with 'Anthro ' if this character is anthropomorphic."
        ""
        "Enter the species of this character:"
      }list "\r" array_join
      'set_str     { "_/species" }list
    }list

    { "2"
      "[#00AAAA][[#55FFFF]2[#00AAAA]] Gender: [#5555FF]@1"
      'get_str     { "gender_prop" sysparm "[#FF5555][Unset][!FFFFFF]" }list

      {
        "The system recognizes the values 'Male', 'Female', 'Herm', 'Hermaphrodite', and 'Neuter'.  However, you're free to enter whatever you want."
        ""
        "Enter the gender of this character:"
      }list "\r" array_join
      'set_str     { "gender_prop" sysparm }list
    }list

    { "3"
      "[#00AAAA][[#55FFFF]3[#00AAAA]] Pronoun/Name/Verb Substitution"
      'get_null { }list

      {
      }list "\r" array_join
      'set_menu { g_table_mgc }list
    }list

    { "4"
      "[#00AAAA][[#55FFFF]4[#00AAAA]] Flags"
      'get_null { }list

      {
      }list "\r" array_join
      'set_menu { g_table_player_flags }list
    }list

    "" "Descriptions" 1

    { "{D1|D}"
      "[#00AAAA][[#55FFFF]D1[#00AAAA]] Description: [#5555FF]@1"
      'get_mpi     { "_/de" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "The 'Description' of a player is the description of their physical characteristics and mannerisms."
        "Everything that another player would see when observing this player for any length of time should be in his standard description."
        ""
        "Tips for a good description:"
        "  1) Detail is important, but so is brevity.  If your desc is so long no one has the patience read it, then its detail serves no purpose."
        "  2) Avoid implying things about the reader.  'You glance over at his shoulders and see..' is annoying and presumptious.  Also, things like 'His scent tickles your nose' may not be appropriate, because nothing says a character has to have a nose."
        ""
        "Enter the visual description of this character:"
      }list "\r" array_join
      'set_mpi_list { "_/de" "_/dl/appearance" }list
    }list

    { "D2"
      "[#00AAAA][[#55FFFF]D2[#00AAAA]] Scent:       [#5555FF]@1"
      'get_mpi     { "_/scent" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This is where you enter this character's aroma."
        "To see an object or player's scent, use the 'smell' command."
        ""
        "Enter this character's scent:"
      }list "\r" array_join
      'set_mpi_list { "_/scent" "_/dl/scent" }list
    }list

    { "D3"
      "[#00AAAA][[#55FFFF]D3[#00AAAA]] Texture:     [#5555FF]@1"
      'get_mpi     { "_/texture" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "A character's 'texture' is the sensation of touching the character."
        "To see an object or player's texture, use the 'feel' command."
        ""
        "Enter this character's texture:"
      }list "\r" array_join
      'set_mpi_list { "_/texture" "_/dl/texture" }list
    }list

    { "D4"
      "[#00AAAA][[#55FFFF]D4[#00AAAA]] flavor:      [#5555FF]@1"
      'get_mpi     { "_/flavor" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This is where you describe the taste of this character when nibbled or licked."
        "To see an object or player's flavor, use the 'taste' command."
        ""
        "Enter this character's flavor:"
      }list "\r" array_join
      'set_mpi_list { "_/flavor" "_/dl/flavor" }list
    }list

    { "D5"
      "[#00AAAA][[#55FFFF]D5[#00AAAA]] Aura:        [#5555FF]@1"
      'get_mpi     { "_/aura" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "Your 'aura' is the general feelings you inspire.  For example, if you look at a car salesman, his description may be 'He's smiling, happy, polite, and friendly', but his aura would be 'He's a liar and a cheat and he hates you.'"
        "To see an object or player's aura, use the 'sense' command."
        ""
        "Enter this character's aura:"
      }list "\r" array_join
      'set_mpi_list { "_/aura" "_/dl/aura" }list
    }list

    { "D6"
      "[#00AAAA][[#55FFFF]D6[#00AAAA]] Sound:       [#5555FF]@1"
      'get_mpi { "_/sound" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "This property is for the sounds this character often makes.  You aren't limited to sounds which you constantly make.  You can also describe sounds you make from time to time."
        "To see an object or player's sound, use the 'hear' command."
        ""
        "Enter this character's sound:"
      }list "\r" array_join
      'set_mpi_list { "_/sound" "_/dl/sound" }list
    }list

    { "D7"
      "[#00AAAA][[#55FFFF]D7[#00AAAA]] Writing:     [#5555FF]@1"
      'get_mpi { "_/writing" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "This property is for any overt writing on this character.  i.e. T-Shirts, Signs, etc."
        "To see anything's writing, use the 'read' command."
        ""
        "Enter this character's writing:"
      }list "\r" array_join
      'set_mpi_list { "_/writing" "_/dl/writing" }list
    }list

    "" (* Blank line before footer *)
  }list
;

(#############################################################################)
(################################ ROOM TABLE #################################)
(#############################################################################)
: table_room_flags (  -- a )
  {
    "" "Flags" 1

    { "A"
      "[#00AAAA][[#55FFFF]A[#00AAAA]]bode:   [#5555FF]@1"
      'get_flag { "ABODE" "[#FF5555]YES [#555555](Object/player homes can be set here freely!)[!FFFFFF]" "No [#555555](Object/player homes can not be set here freely.)[!FFFFFF]" }list

      {
        "With the ABODE flag, you can allow anyone to '@link' their objects/players into your room.  When an object is swept, it will go to its 'home' which is defined by the '@link' command.  Normally, people can't set an object's home in an area they don't control unless the ABODE flag is set."
        "Also, you should set this on any environment rooms you create whihc others need to use.  (In fact, you should probably set it on every environment room you make.)  This flag is nessessary for other users to @tel their rooms into your environment, or to get a properly parented room when they create a room under your environment."
        ""
        "Set the ABODE flag on this room? (y/n)"
      }list "\r" array_join
      'set_flag { "ABODE" }list
    }list

    { "D"
      "[#00AAAA][[#55FFFF]D[#00AAAA]]ark:    [#5555FF]@1"
      'get_flag { "DARK" "[#FF5555]YES[!FFFFFF] [#555555](The contents list does not show!)[!FFFFFF]" "No [#555555](The contents list behaves normally.)[!FFFFFF]" }list

      {
        "If you set a room DARK, then no one will be able to see the contents of your room, even while inside it.  Meaning players won't be able to detect that other players or objects are inside your area."
        "The owner of the room is uneffected by DARK unless they also have the SILENT flag set on themselves."
        ""
        "Set the DARK flag on this room? (y/n)"
      }list "\r" array_join
      'set_flag { "DARK" }list
    }list

    { "H"
      "[#00AAAA][[#55FFFF]H[#00AAAA]]aven:   [#5555FF]@1"
      'get_flag { "HAVEN" "Yes [#555555](Kill and whereis are forbidden.)[!FFFFFF]" "No [#555555](Kill and whereis behave normally.)[!FFFFFF]" }list

      {
        "If a room is set HAVEN, you can not use the kill command in that room."
        "The HAVEN flag on a room also may have similar qualities to a HAVEN flag on a player.  For example, 'whereis' considers a room private if it is set HAVEN."
        ""
        "Set the HAVEN flag on this room? (y/n)"
      }list "\r" array_join
      'set_flag { "HAVEN" }list
    }list

    ({ "J"
      "[#00AAAA][[#55FFFF]J[#00AAAA]]ump_OK: [#5555FF]@1"
      'get_flag { "JUMP_OK" "Yes" "No" }list

      {
        "The JUMP_OK flag allows teleports to/from a room."
        ""
        "Set the JUMP_OK flag on this room? {y/n}"
      }list "\r" array_join
      'set_flag { "JUMP_OK" }list
    }list)

    { "L"
      "[#00AAAA][[#55FFFF]L[#00AAAA]]ink_OK: [#5555FF]@1"
      'get_flag { "LINK_OK" "[#FF5555]YES[!FFFFFF] [#555555](This room can be linked to freely!)[!FFFFFF]" "No [#555555](This room may not be linked to freely.)[!FFFFFF]" }list

      {
        "Setting the LINK_OK flag on a room allows anyone to create an exit into your room.  If you want someone to create an exit into your area, set the area LINK_OK, then tell them it's 'dbref' number (You'll see it to the right of the name of the room in 'look', if you're not set SILENT.)  If you want a reverse exit, then you'll have to get them to set their area LINK_OK."
        "It's highly reccomended you turn this off when you're done."
        ""
        "Set the LINK_OK flag on this room? (y/n)"
      }list "\r" array_join
      'set_flag    { "LINK_OK" }list
    }list

    { "S"
      "[#00AAAA][[#55FFFF]S[#00AAAA]]ticky:  [#5555FF]@1"
      'get_flag { "STICKY" "Yes [#555555](Drop-to is delayed.)[!FFFFFF]" "No [#555555](Drop-to is instantaneous.)[!FFFFFF]" }list

      {
        "If a room is STICKY, its drop-to is delayed until the last person leaves the room.  A drop-to is where objects go when you drop them in that room, and it's set with @link."
        ""
        "Set the STICKY flag on this room? (y/n)"
      }list "\r" array_join
      'set_flag { "STICKY" }list
    }list

    { "V"
      "[#00AAAA][[#55FFFF]V[#00AAAA]]ehicle: [#5555FF]@1"
      'get_flag { "VEHICLE" "Yes [#555555](Vehicles may NOT use this room.)[!FFFFFF]" "No [#555555](Vehicles may use this room.)[!FFFFFF]" }list

      {
        "When the VEHICLE flag is set on a room it means that vehicle objects may *NOT* use the room.  This allows a way to prevent vehicles from entering areas where it would be illogical for them to be."
        ""
        "Set the VEHICLE flag on this room? (y/n)"
      }list "\r" array_join
      'set_flag { "VEHICLE" }list
    }list

    { "Z"
      "[#00AAAA][[#55FFFF]Z[#00AAAA]]ombie:  [#5555FF]@1"
      'get_flag { "ZOMBIE" "Yes [#555555](Puppets may NOT use this room.)[!FFFFFF]" "No [#555555](Puppets may use this room.)[!FFFFFF]" }list

      {
        "When the ZOMBIE flag is set on a room it means that puppet/zombie objects may *NOT* use the room.  This allows a way to prevent zombies from entering areas where they are not wanted."
        ""
        "Set the ZOMBIE flag on this room? (y/n)"
      }list "\r" array_join
      'set_flag    { "ZOMBIE" }list
    }list

    ""
    { "{P|B}"
      "[#00AAAA][[#55FFFF]B[#00AAAA]]ack to Room Edit"
      'get_null { }list

      {
      }list "\r" array_join
      'set_menu { g_table_room }list
    }list
  }list
;

: table_room (  -- a )
  {
    "" (* Blank line after header *)
    1

    { "N"
      "[#00AAAA][[#55FFFF]N[#00AAAA]]ame: [#5555FF]@1"
      'get_obj_name { }list

      {
        "Enter the room's new name:"
      }list "\r" array_join
      'set_obj_name { }list
    }list

    3

    { "F"
      "[#00AAAA][[#55FFFF]F[#00AAAA]]lags"
      'get_null { }list

      {
      }list "\r" array_join
      'set_menu { g_table_room_flags }list
    }list

    "" "Descriptions" 1

    { "{D1|D}"
      "[#00AAAA][[#55FFFF]D1[#00AAAA]] Description: [#5555FF]@1"
      'get_mpi     { "_/de" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "The 'Description' of a room is the visual description of what's noticed when entering or exploring it."
        "Try to avoid describing the other senses (although you can if you really want to) because the place for that is in the other descriptions."
        ""
        "Tips for a good description:"
        "  1) Detail is important, but so is brevity.  If your desc is so long no one has the patience read it, then its detail serves no purpose."
        "  2) Avoid implying things about the reader.  'You you look inside the closet and see..' is annoying and presumptious.  Also, things like 'This room's scent tickles your nose' may not be appropriate, because nothing says a character has to have a nose."
        ""
        "Enter the visual description of the room:"
      }list "\r" array_join
      'set_mpi_list { "_/de" "_/dl/appearance" }list
    }list

    { "D2"
      "[#00AAAA][[#55FFFF]D2[#00AAAA]] Scent:       [#5555FF]@1"
      'get_mpi     { "_/scent" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This is where you enter the room's aroma."
        "To see anything's scent, use the 'smell' command."
        ""
        "Enter this character's scent:"
      }list "\r" array_join
      'set_mpi_list { "_/scent" "_/dl/scent" }list
    }list

    { "D3"
      "[#00AAAA][[#55FFFF]D3[#00AAAA]] Texture:     [#5555FF]@1"
      'get_mpi     { "_/texture" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "You may enter anything you want for the room's texture.  Because rooms are often large, it'd be hard to go around feeling every surface in them, so describe whatever you want.  Choose some surfaces or all of them, and describe the sensation of touching them."
        "To see anything's texture, use the 'feel' command."
        ""
        "Enter this character's texture:"
      }list "\r" array_join
      'set_mpi_list { "_/texture" "_/dl/texture" }list
    }list

    { "D4"
      "[#00AAAA][[#55FFFF]D4[#00AAAA]] flavor:      [#5555FF]@1"
      'get_mpi     { "_/flavor" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "Here, describe what it's like to lick this area."
        "To see anything's flavor, use the 'taste' command."
        ""
        "Enter this character's flavor:"
      }list "\r" array_join
      'set_mpi_list { "_/flavor" "_/dl/flavor" }list
    }list

    { "D5"
      "[#00AAAA][[#55FFFF]D5[#00AAAA]] Aura:        [#5555FF]@1"
      'get_mpi     { "_/aura" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "An area's 'aura' is the feeling it inspires.  For example, if you look at an old mansion, you may see 'The furnature is beautifully crafted and priclessly maintained, and the architecture is astonishing.', but its aura may be 'This place is terrifying, it's dark and creepy.'"
        "To see anything's aura, use the 'sense' command."
        ""
        "Enter this character's aura:"
      }list "\r" array_join
      'set_mpi_list { "_/aura" "_/dl/aura" }list
    }list

    { "D6"
      "[#00AAAA][[#55FFFF]D6[#00AAAA]] Sound:       [#5555FF]@1"
      'get_mpi { "_/sound" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "This property is for the sounds most often heard in the room.  It's best to make a general description of what aural feelings the room tends to inspire."
        "To see anything's sound, use the 'hear' command."
        ""
        "Enter this character's sound:"
      }list "\r" array_join
      'set_mpi_list { "_/sound" "_/dl/sound" }list
    }list

    { "D7"
      "[#00AAAA][[#55FFFF]D7[#00AAAA]] Writing:     [#5555FF]@1"
      'get_mpi { "_/writing" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "This property is for any overt writing in the area.  i.e. a large banner.  As for signs, it's best to create a sign object with @create and set the writing on that instead."
        "To see anything's writing, use the 'read' command."
        ""
        "Enter this character's writing:"
      }list "\r" array_join
      'set_mpi_list { "_/writing" "_/dl/writing" }list
    }list

    "" "Messages" 2

    { "M1"
      "[#00AAAA][[#55FFFF]M1[#00AAAA]] @success Message:  [#5555FF]@1"
      'get_mpi { "_/sc" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "The @success and @oscuccess messages are seen when an object is 'used'.  Using a room is done by entering it and looking around, both automatically when first entering the room, and when issuing the 'look' command."
        "In nearly all cases however, this field is used to display the 'Obvious Exists' to any user who looks around this room.  In other words, to display a list of all exits which are not set DARK.  To do so, simply put '{obvexits}' in this string."
        "(Also, you may set the {obvexits} behaviour by setting the property '/obvexits' in any room up your environment tree.  The default is: '{commas:{if:{le:{strlen:%exits},77},%exits,{parse:x,{&exits},{name:{&x}}}}}'  This is an advanced property, ask a skilled builder for help if you wish to tweak it.)"
        ""
        "Example: [Exits: {obvexits}]"
        ""
        "Enter this room's @success message:"
      }list "\r" array_join
      'set_str { "_/sc" }list
    }list

    { "M2"
      "[#00AAAA][[#55FFFF]M2[#00AAAA]] @osuccess Message: [#5555FF]@1"
      'get_mpi { "_/osc" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "The @success and @osuccess messages are seen when an object is 'used'.  Using a room is done by entering it and looking around, both automatically when first entering the room, and when issuing the 'look' command."
        "This message is of little use at all, it's reccomended you DON'T SET IT unless you have a good reason."
        "Everyone in the room sees this message except the looker, and the looker's name is prepended to the message."
        ""
        "Example: glances around the room."
        ""
        "Enter this room's @osuccess message:"
      }list "\r" array_join
      'set_str { "_/osc" }list
    }list

    { "M3"
      "[#00AAAA][[#55FFFF]M3[#00AAAA]] @fail Message:     [#5555FF]@1"
      'get_mpi { "_/fl" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "The @fail and @ofail messages are seen when an object fails to be 'used'.  Using a room is done by entering it and looking around, both automatically when first entering the room, and when issuing the 'look' command."
        "This message will only be displayed if the room is @locked against you.  See the 'help @lock' command for more information."
        "Generally, this message is of little use."
        ""
        "Example: You have trouble finding the exits here."
        ""
        "Enter this room's @fail message:"
      }list "\r" array_join
      'set_str { "_/fl" }list
    }list

    { "M4"
      "[#00AAAA][[#55FFFF]M4[#00AAAA]] @ofail Message:    [#5555FF]@1"
      'get_mpi { "_/ofl" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "The @fail and @ofail messages are seen when an object fails to be 'used'.  Using a room is done by entering it and looking around, both automatically when first entering the room, and when issuing the 'look' command."
        "This message will only be displayed if the room is @locked against you.  See the 'help @lock' command for more information."
        "Everyone in the room sees this message except the looker, and the looker's name is prepended to the message."
        "Generally, this message is of little use."
        ""
        "Example: appaears to be unable to find the exits.  Perhaps you should help %o?"
        ""
        "Enter this room's @ofail message:"
      }list "\r" array_join
      'set_str { "_/ofl" }list
    }list

    { "M5"
      "[#00AAAA][[#55FFFF]M5[#00AAAA]] @drop Message:     [#5555FF]@1"
      'get_mpi { "_/dr" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "The @drop and @odrop messages, when set on a room, are triggered when someone drops a program or thing type object in this room."
        "This message is shown only to the person who does the dropping."
        ""
        "Example: You drop some rubbish in the park."
        ""
        "Enter this room's @drop message:"
      }list "\r" array_join
      'set_str { "_/dr" }list
    }list

    { "M6"
      "[#00AAAA][[#55FFFF]M6[#00AAAA]] @odrop Message:    [#5555FF]@1"
      'get_mpi { "_/odr" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "The @drop and @odrop messages, when set on a room, are triggered when someone drops a program or thing type object in this room."
        "This message is shown to everyone else in the room, with the name of the dropper prepended to it."
        ""
        "Example: just dropped some rubbish in the park."
        ""
        "Enter this room's @odrop message:"
      }list "\r" array_join
      'set_str { "_/odr" }list
    }list

    "" "Exits" 4

    { "E1"
      "[#00AAAA][[#55FFFF]E1[#00AAAA]] New Exit"
      'get_null { }list

      {
      }list "\r" array_join
      'set_exit_new { }list
    }list

    { "E2"
      "[#00AAAA][[#55FFFF]E2[#00AAAA]] Recycle Exit"
      'get_null { }list

      {
      }list "\r" array_join
      'set_exit_recycle { }list
    }list

    { "E3"
      "[#00AAAA][[#55FFFF]E3[#00AAAA]] Edit Exit"
      'get_null { }list

      {
      }list "\r" array_join
      'set_exits_edit { }list
    }list

    { "E4"
      "[#00AAAA][[#55FFFF]E4[#00AAAA]] Shown: [#5555FF]@1"
      'get_obv_exits { "Yes" "[#FF5555]NO[!FFFFFF]" "[#0000AA]Unknown[!FFFFFF]" }list

      {
        "Do you want all exits without the DARK flag to be shown automatically when looking at the room? (y/n)"
      }list "\r" array_join
      'set_obv_exits { }list
    }list

    "" (* Blank line before footer *)
  }list
;

(#############################################################################)
(################################ EXIT TABLE #################################)
(#############################################################################)
: table_exit (  -- a )
  {
    "" (* Blank line after header *)
    1

    { "N"
      "[#00AAAA][[#55FFFF]N[#00AAAA]]ame: [#5555FF]@1"
      'get_obj_name { }list

      {
        "TIP: You can create aliases for this exit by putting semicolons in its name string.  For example, if you use '[O]ut;out;o' for the name, 'out', and 'o' will both trigger the exit, but only '[O]ut' will show in the obvious exists list."
        ""
        "Enter this exit's new name:"
      }list "\r" array_join
      'set_obj_name { }list
    }list

    2

    { "S"
      "[#00AAAA][[#55FFFF]S[#00AAAA]]ource: [#5555FF]@1"
      'get_source { }list

      {
        "The source of an exit is the parent room to which it's attached.  If you attach an exit to an environment room, then all rooms contained within it, and the rooms within them, and so on, will be able to use the exit.  So either place the source of this exit in the environment room for your area to allow access anywhere in your area, or put it in the specific room you want an exit from."
        ""
        "Enter this exit's new source:"
      }list "\r" array_join
      'set_source { }list
    }list

    { "T"
      "[#00AAAA][[#55FFFF]T[#00AAAA]]arget: [#5555FF]@1"
      'get_link { "[#FF5555]NOTHING![!FFFFFF]" }list

      {
        "The destination of an exit is its target.  It can be another room, a thing object, a program, or a player.  In the case of a room, using the exit will teleport you to that room.  In the case of a program, using the exit will execute the program.  In the case of a thing object, using the exit will teleport the objet to you.  In the case of a player, using the exit will teleport you to that player."
        ""
        "Enter this exit's new target:"
        "WARNING: An unlinked exit may be claimed by anyone."
      }list "\r" array_join
      'set_link { }list
    }list

    4

    { "A"
      "[#00AAAA][[#55FFFF]A[#00AAAA]]bate: [#5555FF]@1"
      'get_flag { "ABATE" "Yes" "No" }list

      {
        "When the ABATE flag is set on an exit, it causes the exit to run at a lower 'priority', meaning if another exit would normally be run when your exit is not present, then your exit is ignored.  Without this flag, exit priority is determined by whatever's closest to the person issuing the command.  There are also ways to set priorities even higher than normal, which are available to MUCK staff."
        ""
        "Set the ABATE flag on this exit? (y/n)"
      }list "\r" array_join
      'set_flag { "ABATE" }list
    }list

    { "D"
      "[#00AAAA][[#55FFFF]D[#00AAAA]]ark: [#5555FF]@1"
      'get_flag { "DARK" "Yes" "No" }list

      {
        "If you set an exit DARK, it will not show up in the usual obvious exits output for the room it's in."
        "Some programs may also respond to the DARK flag on this exit."
        ""
        "Set the DARK flag on this exit? (y/n)"
      }list "\r" array_join
      'set_flag { "DARK" }list
    }list

    { "V"
      "[#00AAAA][[#55FFFF]V[#00AAAA]]ehicle: [#5555FF]@1"
      'get_flag { "VEHICLE" "Yes" "No" }list

      {
        "To DISALLOW vehicles from using this exit, set the VEHICLE flag."
        ""
        "Set the VEHICLE flag on this exit? (y/n)"
      }list "\r" array_join
      'set_flag { "VEHICLE" }list
    }list

    { "Z"
      "[#00AAAA][[#55FFFF]Z[#00AAAA]]zombie: [#5555FF]@1"
      'get_flag { "ZOMBIE" "Yes" "No" }list

      {
        "To DISALLOW zombies/puppets from using this exit, set the ZOMBIE flag."
        ""
        "Set the ZOMBIE flag on this exit? (y/n)"
      }list "\r" array_join
      'set_flag { "ZOMBIE" }list
    }list

    "" "Descriptions" 1

    { "{D1|D}"
      "[#00AAAA][[#55FFFF]D1[#00AAAA]] Description: [#5555FF]@1"
      'get_mpi     { "_/de" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path' and use this field as a visual description of that entrance.  It's always best not to leave this on its defaults, if you're certian that this exit has no physical description, enter something like 'You can't see it' and possibly a description why."
        ""
        "Enter the visual description of this exit:"
      }list "\r" array_join
      'set_mpi_list { "_/de" "_/dl/appearance" }list
    }list

    { "D2"
      "[#00AAAA][[#55FFFF]D2[#00AAAA]] Scent:       [#5555FF]@1"
      'get_mpi     { "_/scent" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of that entrance's aroma."
        ""
        "Enter this exit's scent:"
      }list "\r" array_join
      'set_mpi_list { "_/scent" "_/dl/scent" }list
    }list

    { "D3"
      "[#00AAAA][[#55FFFF]D3[#00AAAA]] Texture:     [#5555FF]@1"
      'get_mpi     { "_/texture" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of that entrance's feeling to the touch."
        ""
        "Enter this exit's texture:"
      }list "\r" array_join
      'set_mpi_list { "_/texture" "_/dl/texture" }list
    }list

    { "D4"
      "[#00AAAA][[#55FFFF]D4[#00AAAA]] flavor:      [#5555FF]@1"
      'get_mpi     { "_/flavor" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of that entrance's flavor."
        ""
        "Enter this exit's flavor:"
      }list "\r" array_join
      'set_mpi_list { "_/flavor" "_/dl/flavor" }list
    }list

    { "D5"
      "[#00AAAA][[#55FFFF]D5[#00AAAA]] Aura:        [#5555FF]@1"
      'get_mpi     { "_/aura" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of the feeling this direction gives a character.  For example, 'you think it might be a bad idea to go that way' is very useful to the observant player."
        ""
        "Enter this exit's aura:"
      }list "\r" array_join
      'set_mpi_list { "_/aura" "_/dl/aura" }list
    }list

    { "D6"
      "[#00AAAA][[#55FFFF]D6[#00AAAA]] Sound:       [#5555FF]@1"
      'get_mpi { "_/sound" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "Use this field to describe the sounds coming from the direction of the exit."
        ""
        "Enter this exit's sound:"
      }list "\r" array_join
      'set_mpi_list { "_/sound" "_/dl/sound" }list
    }list

    { "D7"
      "[#00AAAA][[#55FFFF]D7[#00AAAA]] Writing:     [#5555FF]@1"
      'get_mpi { "_/writing" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "Use this field if there's writing on your exit.  For example 'Room 101' and 'Rented by xyz' are very useful to passers by."
        ""
        "Enter this exit's writing:"
      }list "\r" array_join
      'set_mpi_list { "_/writing" "_/dl/writing" }list
    }list

    "" "Messages" 2

    { "M1"
      "[#00AAAA][[#55FFFF]M1[#00AAAA]] @success Message:  [#5555FF]@1"
      'get_mpi { "_/sc" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This message is shown when anyone who uses this exit, to the person who uses it.  You should always set this on non-program exits."
        ""
        "Example: You go east"
        ""
        "Enter this exit's @success message:"
      }list "\r" array_join
      'set_str { "_/sc" }list
    }list

    { "M2"
      "[#00AAAA][[#55FFFF]M2[#00AAAA]] @osuccess Message: [#5555FF]@1"
      'get_mpi { "_/osc" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This message is shown when anyone uses this exit, to everyone else in the room.  You should always set this on non-program exits."
        ""
        "Example: goes east."
        ""
        "Enter this exit's @osuccess message:"
      }list "\r" array_join
      'set_str { "_/osc" }list
    }list

    { "M3"
      "[#00AAAA][[#55FFFF]M3[#00AAAA]] @fail Message:     [#5555FF]@1"
      'get_mpi { "_/fl" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This message is shown when someone tries to use an exit, but fails (because it's locked or otherwise), to the person who tried to use it. You should always set this on non-program exits."
        ""
        "Example: You can't go east because the door is locked."
        ""
        "Enter this exit's @fail message:"
      }list "\r" array_join
      'set_str { "_/fl" }list
    }list

    { "M4"
      "[#00AAAA][[#55FFFF]M4[#00AAAA]] @ofail Message:    [#5555FF]@1"
      'get_mpi { "_/ofl" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This message is shown when someone tries to use an exit, but fails (because it's locked or otherwise), to everyone else in the room. You should always set this on non-program exits."
        ""
        "Example: tries to go east but the door is locked."
        ""
        "Enter this exit's @ofail message:"
      }list "\r" array_join
      'set_str { "_/ofl" }list
    }list

    { "M5"
      "[#00AAAA][[#55FFFF]M5[#00AAAA]] @drop Message:     [#5555FF]@1"
      'get_mpi { "_/dr" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "This message is shown to the person using the exit, when they arrive on the other side of the exit.  It's pretty much useless, as in order for this message to be sown, the @success message must have just shown as well.  There's little reason to se this."
        ""
        "Example: And now you've arrived on the other side."
        ""
        "Enter this exit's @drop message:"
      }list "\r" array_join
      'set_str { "_/dr" }list
    }list

    { "M6"
      "[#00AAAA][[#55FFFF]M6[#00AAAA]] @odrop Message:    [#5555FF]@1"
      'get_mpi { "_/odr" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This message is essential for every exit.  It's shown when someone using your exit has arrived on the other side, to everyone else on the other side.  It is crucial in order for people to understand where someone just came from, if they join you in the room."
        ""
        "Example: comes from the west."
        ""
        "Enter this exit's @odrop message:"
      }list "\r" array_join
      'set_str { "_/odr" }list
    }list

    ""
    { "{P|R|O}"
      "[#00AAAA]Edit Parent @1"
      'get_parent { "[#00AAAA][[#55FFFF]R[#00AAAA]]oom" "[#00AAAA][[#55FFFF]P[#00AAAA]]layer" "[#00AAAA][[#55FFFF]O[#00AAAA]]bject" }list

      {
      }list "\r" array_join
      'set_parent { }list
    }list
  }list
;

(#############################################################################)
(############################### THING TABLE #################################)
(#############################################################################)
: table_thing_flags (  -- a )
  {
    "" "Flags" 1

    { "D"
      "[#00AAAA][[#55FFFF]D[#00AAAA]]ark:    [#5555FF]@1"
      'get_flag { "DARK" "Yes [#555555](This object is hidden from 'contents' listings.)[!FFFFFF]" "No  [#555555](This object appears in 'contents' listings.)[!FFFFFF]" }list

      {
        "Use this flag to prevent your object from being shown in a 'contents' listing when looking at its container.  For example, it makes objects appear invisible when placed in rooms."
        ""
        "Set the DARK flag on this object? (y/n)"
      }list "\r" array_join
      'set_flag { "DARK" }list
    }list

    { "J"
      "[#00AAAA][[#55FFFF]J[#00AAAA]]ump_OK: [#5555FF]@1"
      'get_flag { "JUMP_OK" "Yes [#555555](This object may be teleported freely.)[!FFFFFF]" "No  [#555555](This object may only be teleported by its controller.)[!FFFFFF]" }list

      {
        "Some programs made by lower-leveled programmers on the MUCK may wish to teleport your objects.  Setting the JUMP_OK flag on your object permits programs to teleport them."
        ""
        "Set the JUMP_OK flag on this object? (y/n)"
      }list "\r" array_join
      'set_flag { "JUMP_OK" }list
    }list

    { "S"
      "[#00AAAA][[#55FFFF]S[#00AAAA]]ticky:  [#5555FF]@1"
      'get_flag { "STICKY" "Yes [#555555](This object goes home when it's dropped.)[!FFFFFF]" "No  [#555555](This object may be dropped.)[!FFFFFF]" }list

      {
        "To have an object get automatically sent home when dropped, set the STICKY flag on it.  This is useful for creating objects which you don't want to become lost in the muck when their users are no longer interested in them.  If you prefer to teleport your objects home manually, investigate the @find and @tel commands."
        ""
        "Set the STICKY flag on this object? (y/n)"
      }list "\r" array_join
      'set_flag { "STICKY" }list
    }list

    { "V"
      "[#00AAAA][[#55FFFF]V[#00AAAA]]ehicle: [#5555FF]@1"
      'get_flag { "VEHICLE" "Yes [#555555](You can climb into this object.)[!FFFFFF]" "No  [#555555](This object doesn't hold players.)[!FFFFFF]" }list

      {
        "When an object has the VEHICLE flag, it allows players to climb inside of the object, by using an exit placed on the vehcile, linked to the vehicle.  Also, it allows the occupents of the vehicle to hear what's going on outside.  (But not vice-versa)"
        ""
        "Set the VEHICLE flag on this object? (y/n)"
      }list "\r" array_join
      'set_flag { "VEHICLE" }list
    }list

    { "Z"
      "[#00AAAA][[#55FFFF]Z[#00AAAA]]ombie:  [#5555FF]@1"
      'get_flag { "ZOMBIE" "Yes [#555555](This object simulates a player.)[!FFFFFF]" "No  [#555555](This object does not simualte a player.)[!FFFFFF]" }list

      {
        "When an object has the ZOMBIE flag, it simulates a player object.  Some programs will begin to treat it as a player (such as whospe), and you can give it preferences, attributes, a sex and a gender.  Also, on MUCKs configured to allow zombies, anything the zombie hears will be automatically broadcasted to the object's owner.  Allowing you to use it as a player with the @force command.  See 'help force' for more details.  (Zombies are also known as 'puppets' or 'pets')"
        ""
        "Set the ZOMBIE flag on this object? (y/n)"
      }list "\r" array_join
      'set_flag { "ZOMBIE" }list
    }list

    ""
    { "{P|B}"
      "[#00AAAA][[#55FFFF]B[#00AAAA]]ack to Object Edit"
      'get_null { }list

      {
      }list "\r" array_join
      'set_menu { g_table_thing }list
    }list
  }list
;

: table_thing (  -- a )
  {
    "" (* Blank line after header *)
    2

    { "N"
      "[#00AAAA][[#55FFFF]N[#00AAAA]]ame: [#5555FF]@1"
      'get_obj_name { }list

      {
        "Enter this object's new name:"
      }list "\r" array_join
      'set_obj_name { }list
    }list

    { "H"
      "[#00AAAA][[#55FFFF]H[#00AAAA]]ome: [#5555FF]@1"
      'get_link { "[#FF5555]Nowhere?![!FFFFFF]" }list

      {
        "An object's 'home' is where it's sent when the server isn't sure where to put it.  For example, if it's contained in a room that gets recycled, or it's swept with the 'sweep' command, it will be sent to its home.  A thing's home can be a player, room, or another object."
        ""
        "Enter this object's new home:"
      }list "\r" array_join
      'set_link { }list
    }list

    { "1"
      "[#00AAAA][[#55FFFF]1[#00AAAA]] Species: [#5555FF]@1"
      'get_str     { "_/species" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "Your species is the type of being your puppet/object is.  This has little meaning unless this object has the ZOMBIE flag turned on."
        "To avoid confusion, pleased prefix the species name with 'Anthro ' if this puppet/object is anthropomorphic."
        ""
        "Enter the species of this puppet/object:"
      }list "\r" array_join
      'set_str     { "_/species" }list
    }list

    { "2"
      "[#00AAAA][[#55FFFF]2[#00AAAA]] Gender: [#5555FF]@1"
      'get_str     { "gender_prop" sysparm "[#0000AA][Unset][!FFFFFF]" }list

      {
        "The sex flag is used for objects with the ZOMBIE flag, as well as for any other reason an object would need pronoun substitution.  For example, you may want to set this to 'Neuter' if you want its pronouns to come up as 'it/its/etc' when you use the smell command on it."
        "The system recognizes the values 'Male', 'Female', 'Herm', 'Hermaphrodite', and 'Neuter'.  However, you're free to enter whatever you want."
        ""
        "Enter the gender of this puppet/object:"
      }list "\r" array_join
      'set_str     { "gender_prop" sysparm }list
    }list

    { "F"
      "[#00AAAA][[#55FFFF]F[#00AAAA]]lags"
      'get_null { }list

      {
      }list "\r" array_join
      'set_menu { g_table_thing_flags }list
    }list

    "" "Descriptions" 1

    { "{D1|D}"
      "[#00AAAA][[#55FFFF]D1[#00AAAA]] Description: [#5555FF]@1"
      'get_mpi     { "_/de" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "If this object is a zombie, you should enter a description in the same way you would enter a player description.  Otherwise, simply give a general description of the visual appearance of this object.  Also, if this object has any exits attached, you may want to put a short description of how to access its commands here."
        ""
        "Enter the visual description of this object:"
      }list "\r" array_join
      'set_mpi_list { "_/de" "_/dl/appearance" }list
    }list

    { "D2"
      "[#00AAAA][[#55FFFF]D2[#00AAAA]] Scent:       [#5555FF]@1"
      'get_mpi     { "_/scent" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This is where you enter the object's aroma.  You can see an object/room/exit/player/program's scent with the 'smell' command."
        ""
        "Enter this object's scent:"
      }list "\r" array_join
      'set_mpi_list { "_/scent" "_/dl/scent" }list
    }list

    { "D3"
      "[#00AAAA][[#55FFFF]D3[#00AAAA]] Texture:     [#5555FF]@1"
      'get_mpi     { "_/texture" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This is where you enter the object's feeling to the touch.  You can see an object/room/exit/player/program's texture with the 'feel' command."
        ""
        "Enter this object's texture:"
      }list "\r" array_join
      'set_mpi_list { "_/texture" "_/dl/texture" }list
    }list

    { "D4"
      "[#00AAAA][[#55FFFF]D4[#00AAAA]] flavor:      [#5555FF]@1"
      'get_mpi     { "_/flavor" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This is where you enter the object's sensation to the taste.  You can see an object/room/exit/player/program's flavor with the 'taste' command."
        ""
        "Enter this object's flavor:"
      }list "\r" array_join
      'set_mpi_list { "_/flavor" "_/dl/flavor" }list
    }list

    { "D5"
      "[#00AAAA][[#55FFFF]D5[#00AAAA]] Aura:        [#5555FF]@1"
      'get_mpi     { "_/aura" "[#FF5555][Unset][!FFFFFF]" }list

      {
        "This is where you enter the feeling which the object gives a character.  For example 'That thing looks scary!', or 'Perhaps it's not a useful as it looks' are very good aura descriptions.  You can see an object/room/exit/player/program's aura with the 'sense' command."
        ""
        "Enter this object's aura:"
      }list "\r" array_join
      'set_mpi_list { "_/aura" "_/dl/aura" }list
    }list

    { "D6"
      "[#00AAAA][[#55FFFF]D6[#00AAAA]] Sound:       [#5555FF]@1"
      'get_mpi { "_/sound" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "Use this field only if the object makes sounds, and enter a short description of the noises it makes.  You can see an object/room/exit/player/program's sound with the 'hear' command."
        ""
        "Enter this object's sound:"
      }list "\r" array_join
      'set_mpi_list { "_/sound" "_/dl/sound" }list
    }list

    { "D7"
      "[#00AAAA][[#55FFFF]D7[#00AAAA]] Writing:     [#5555FF]@1"
      'get_mpi { "_/writing" "[#0000AA][Unset][!FFFFFF]" }list

      {
        "If anything is written on your object, enter it here.  For example 'Made in Japan', or 'Property of xyz'.  You can see an object/room/exit/player/program's writing with the 'read' command."
        ""
        "Enter this object's writing:"
      }list "\r" array_join
      'set_mpi_list { "_/writing" "_/dl/writing" }list
    }list

    "" "Messages" 2

    { "M1"
      "[#00AAAA][[#55FFFF]M1[#00AAAA]] @success Message:  [#5555FF]@1"
      'get_mpi { "_/sc" "[#FF5555][Unset][!FFFFFF]" }list

      {
        ""
        "Example: You pick up {name:this}."
        ""
        "Enter this object's @success message:"
      }list "\r" array_join
      'set_str { "_/sc" }list
    }list

    { "M2"
      "[#00AAAA][[#55FFFF]M2[#00AAAA]] @osuccess Message: [#5555FF]@1"
      'get_mpi { "_/osc" "[#FF5555][Unset][!FFFFFF]" }list

      {
        ""
        "Example: picks up {name:this}."
        ""
        "Enter this object's @osuccess message:"
      }list "\r" array_join
      'set_str { "_/osc" }list
    }list

    { "M3"
      "[#00AAAA][[#55FFFF]M3[#00AAAA]] @fail Message:     [#5555FF]@1"
      'get_mpi { "_/fl" "[#FF5555][Unset][!FFFFFF]" }list

      {
        ""
        "Example: You try to pick up {name:this} but it's glued to the floor."
        ""
        "Enter this object's @fail message:"
      }list "\r" array_join
      'set_str { "_/fl" }list
    }list

    { "M4"
      "[#00AAAA][[#55FFFF]M4[#00AAAA]] @ofail Message:    [#5555FF]@1"
      'get_mpi { "_/ofl" "[#FF5555][Unset][!FFFFFF]" }list

      {
        ""
        "Example: tries to pick up {name:this} but it's glued to the floor."
        ""
        "Enter this object's @ofail message:"
      }list "\r" array_join
      'set_str { "_/ofl" }list
    }list

    { "M5"
      "[#00AAAA][[#55FFFF]M5[#00AAAA]] @drop Message:     [#5555FF]@1"
      'get_mpi { "_/dr" "[#FF5555][Unset][!FFFFFF]" }list

      {
        ""
        "Example: You toss the {name:this} onto the floor."
        ""
        "Enter this object's @drop message:"
      }list "\r" array_join
      'set_str { "_/dr" }list
    }list

    { "M6"
      "[#00AAAA][[#55FFFF]M6[#00AAAA]] @odrop Message:    [#5555FF]@1"
      'get_mpi { "_/odr" "[#FF5555][Unset][!FFFFFF]" }list

      {
        ""
        "Example: tosses a {name:this} onto the floor."
        ""
        "Enter this object's @odrop message:"
      }list "\r" array_join
      'set_str { "_/odr" }list
    }list

    "" (* Blank line before footer *)
  }list
;

(#############################################################################)
(############################## PROGRAM TABLE ################################)
(#############################################################################)
: table_program (  -- a )
  {
  }list
;

(* ------------------------------------------------------------------------- *)

: do_menu_header (  --  )

  "[#FFFFFF]----[#0000AA][ [#FFFF55]Object Editor[#0000AA] ][#FFFFFF]" dup .color_strlen .chars-per-row swap - "-" * strcat
  g_object @ .theme_unparseobj

  dup .color_strlen .chars-per-row 20 - <= if
    "[#0000AA][ [!FFFFFF]" swap strcat "[#0000AA] ][#FFFFFF]----" strcat
     dup .color_strlen .chars-per-row swap - rot swap .color_strcut pop swap strcat
  else
    "\r[!FFFFFF]Object: " swap strcat strcat
  then

  .color_tell
;

: do_menu_footer (  --  )
  "[#0000AA][ [#AAAAAA]" prog name strcat .version strcat prog "L" flag? prog "V" flag? or if " (#" strcat prog intostr strcat ")" strcat then " -- by " strcat .author strcat "[#0000AA] ][#FFFFFF]----" strcat

  "[#FFFFFF]" "-" .chars-per-row * strcat over .color_strlen .chars-per-row swap - .color_strcut pop swap strcat

  .color_tell
;

: draw_separator ( s -- s )
  dup not if
    pop " "
  else
    "[#FFFFFF]-----[#0000AA][ [#00AAAA]" swap strcat "[#0000AA] ][#FFFFFF]" strcat "-" .chars-per-row * strcat
    .chars-per-row .color_strcut pop
  then
;

: draw_item ( a -- s )
  (* Get 'get' string. *)
  dup 1 [] over 2 [] rot 3 []

  array_vals ++ rotate execute

  (* Substitute 'get' string *)
  "" .color_strcat (* HACK: This will preprocess the string and make it so that when it's subst it won't affect colors around it, but it will be affected by colors around it *)
  "@1" subst
;

: do_menu (  --  )
  0  var! item_on_row   (* The current item on the row *)
  2  var! items_per_row (* The current max number of items per row *)
  "" var! row_string    (* The string data of the row *)

  do_menu_header

  g_table @ foreach
    swap pop

    (* Handle items_per_row changes *)
    dup int? if
      (* Flush the current row if we're on it. *)
      item_on_row @ if
        row_string @ .color_tell
        "" row_string !
        0 item_on_row !
      then

      items_per_row !

      continue
    then

    (* Handle separators *)
    dup string? if
      (* Flush the current row if we're on it. *)
      item_on_row @ if
        row_string @ .color_tell
        "" row_string !
        0 item_on_row !
      then

      (* Draw a separator *)
      draw_separator .color_tell

      continue
    then

    (* Handle item entries *)
    dup array? if
      (* Get the item *)
      draw_item

      (* Pad with required spaces *)
      .chars-per-row items_per_row @ / over .color_strlen over >= if
        4 - .color_strcut pop "[!FFFFFF] ..." strcat
      else
        over .color_strlen -
        begin
          dup while

          swap " " strcat swap

          --
        repeat
        pop
      then

      row_string @ swap strcat row_string ! (* Append drawn item to string *)
      item_on_row @ ++ (* Increment the current item count *)

      dup items_per_row @ >= if
        row_string @ .color_tell
        "" row_string !

        pop 0
      then

      item_on_row !

      continue
    then

    "Invalid item in table" abort
  repeat

  (* Flush the current row if we're on it. *)
  item_on_row @ if
    row_string @ .color_tell
    "" row_string !
    0 item_on_row !
  then
  do_menu_footer
;

: do_set ( a --  )
  dup 5 [] over 6 [] rot 4 []

  (* Display help string *)
  .color_tell

  (* Get value *)
  array_vals ++ rotate execute
;

: do_edit (  --  )
  0 var! nomatch

  begin
    do_menu
    nomatch @ if
      "'" swap strcat "' is invalid.  Try again, or enter 'Q' to quit." strcat .tell
    else
      "Please make a selection, or enter 'Q' to quit." .tell
    then

    read

    (* Let users speak from inside the editor *)
    dup "\"" 1 strncmp not if
      "me" match swap force
      continue
    then

    (* Let users pose from inside the editor *)
    dup ":" 1 strncmp not if
      "me" match swap force
      continue
    then

    (* Q always quits *)
    dup "{Q|QUIT}" smatch if
      pop break
    then

    (* Match selections *)
    1 nomatch !
    g_table @ foreach
      swap pop

      dup array? if
        over over 0 [] smatch if
          do_set
          0 nomatch !
          pop break
        then
      then

      pop
    repeat
  repeat

  ">> Editor exited." .tell
;

: tables_init (  --  )
  (* Not very elegant I know.. *)
  table_mgc          g_table_mgc          !
  table_player_flags g_table_player_flags !
  table_player       g_table_player       !
  table_room_flags   g_table_room_flags   !
  table_room         g_table_room         !
  table_thing_flags  g_table_thing_flags  !
  table_thing        g_table_thing        !
  table_exit         g_table_exit         !
  table_program      g_table_program      !

  set_menu_default
;

: main
  dup not if
    { "Use '" command @ " <object>' to edit objects." }join .tell
    pop exit
  then

  { "quiet" "no" "absolute" "yes" "nohome" "yes" "nonil" "yes" }dict M-LIB-MATCH-match
  dup not if
    pop exit
  then

  dup chk_perms not if
    pop "Permission denied." .tell 0 exit
  then

  g_object !

  (* Initialize globals *)
  tables_init

  do_edit
;
.
c
q
!@register m-cmd-@editobject.muf=m/cmd/at_editobject
!@set $m/cmd/at_editobject=M3
!@set $m/cmd/at_editobject=W

