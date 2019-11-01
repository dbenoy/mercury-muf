!@program m-cmd-@setup.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@setup.muf - $m/cmd/at_setup                                        *)
(*   A menu-driven configuration tool for setting up the most common player  *)
(*   options.                                                                *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*     - Modified slightly for inclusion in mercury-muf                      *)
(*     - Removed "Jaffa's cmd-look" support, and other unneeded libraries.   *)
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
$NOTE    A menu for editing common settings.
$DOCCMD  @list __PROG__=2-34

(* Begin configurable options *)

$DEF .chars-per-row 79

$DEF EMOTE_TEST_FROM #1

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

: M-HELP-desc ( d -- s )
  pop
  "FIXME"
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <object>" }join
    "  FIXME"
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

$PUBDEF :

$INCLUDE $m/lib/program
$INCLUDE $m/lib/color
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/grammar
$INCLUDE $m/lib/emote
$INCLUDE $m/cmd/at_lsedit

(* Begin global variables *)

lvar g_table  (* Set to the appropriate table in main *)

(* These are intialized in main. *)
lvar g_table_main
lvar g_table_pronoun
lvar g_table_emote

(* End global variables *)

(* ------------------------------------------------------------------------- *)

( ###################### setters and getters for tables ##################### )
(***** Change menus *****)
: set_menu[ var:newmenu --  ]
  newmenu @ @ g_table !
;

(***** get/set Flag *****)
: get_flag[ str:flag str:valueTrue str:valueFalse -- str:value ]
  .me flag @ flag? if
    valueTrue @
  else
    valueFalse @
  then
;

: set_flag[ str:flag --  ]
  read

  dup "{y|ye|yes}" smatch if
    .me flag @ set
    pop exit
  then

  dup "{n|no}" smatch if
    .me "!" flag @ strcat set
    pop exit
  then

  "Cancelled." .theme_err .color_tell
  pop
;

(***** get/set String Property *****)
: get_str[ str:property str:unsetValue -- str:value ]
  .me property @ getpropstr

  dup not if
    pop unsetValue @ { .me }list { "name_match" "no" "name_theme" "no" "color" "keep" }dict M-LIB-GRAMMAR-sub exit
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
    .me property @ remove_prop
  else
    .me property @ rot setprop
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
    .me property @ rot setprop
    "Set." .tell
  else
    "'" swap strcat "' is not one of the options." strcat .theme_err .color_tell
  then
;

(***** get/set String Boolean Property *****)
: get_str_bool[ str:property str:valueTrue str:valueFalse -- str:value ]
  .me property @ getpropstr

  "yes" stringcmp not if
    valueTrue @
  else
    valueFalse @
  then
;

: get_str_bool2[ str:property str:valueTrue str:valueFalse -- str:value ] (* this one is for defaulting to yes *)
  .me property @ getpropstr

  "no" stringcmp not if
    valueFalse @
  else
    valueTrue @
  then
;

: set_str_bool[ str:property --  ]
  read

  dup "{y|ye|yes}" smatch if
    .me property @ "yes" setprop
    pop exit
  then

  dup "{n|no}" smatch if
    .me property @ "no" setprop
    pop exit
  then

  "Cancelled." .theme_err .color_tell
  pop
;

: set_str_bool2[ str:property --  ] (* This one is for clearing a prop, instead of setting no *)
  read

  dup "{y|ye|yes}" smatch if
    .me property @ "yes" setprop
    pop exit
  then

  dup "{n|no}" smatch if
    .me property @ remove_prop
    pop exit
  then

  "Cancelled." .theme_err .color_tell
  pop
;

(***** get/set Integer Boolean Property *****)
: get_bool[ str:property str:valueTrue str:valueFalse -- str:value ]
  .me property @ getpropval if
    valueTrue @
  else
    valueFalse @
  then
;

: set_bool[ str:property --  ]
  read

  dup "{y|ye|yes}" smatch if
    .me property @ 1 setprop
    pop exit
  then

  dup "{n|no}" smatch if
    .me property @ 0 setprop
    pop exit
  then

  "Cancelled." .theme_err .color_tell
  pop
;

(***** get an MPI parsed value *****)
: get_mpi[ str:property str:unsetValue -- str:value ]
  .me property @ prog name 0 parseprop

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
  .me .theme_name
;

: set_obj_name[  --  ]
  read
  .me swap setname
;

(***** set a string to {eval:{list:<property list>}}, and edit the corresponding list *****)
: set_mpi_list[ str:property str:listprop --  ]
  (* Use existing property if available *)
  .me property @ getpropstr
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

  .me listprop @ M-CMD-AT_LSEDIT-ListEdit if
    .me property @ "{eval:{list:" listprop @ strcat "}}" strcat setprop
  then
;

(***** Get/set the current morph *****)
: get_morph[  -- str:value ]
  .me "/_morph" getpropstr

  dup "\r" instr if
    pop "UNKNOWN" exit
  then

  dup not if
    .me "/_morph" "Default" setprop
    pop "Default" exit
  then
;

(***** get/set Emote setting *****)
: get_emote_option[ str:option str:prefix_default -- str:value ]
  .me option @ M-LIB-EMOTE-config_get
  .color_escape
  .me "_config/emote/" option @ strcat getpropstr not if
    prefix_default @ swap strcat
  then
;

: set_emote_option[ str:option --  ]
  "(Enter a space to reset to default)" .tell

  read

  dup strip not if
    .me "_config/emote/" option @ strcat remove_prop
  else
    dup .me option @ M-LIB-EMOTE-config_valid not if
      "That is not a valid value for this setting." .theme_err .color_tell
      pop exit
    then
    .me "_config/emote/" option @ strcat rot setprop
  then
;

(***** Test emote style *****)
: get_emote_style[ ref:from bool:force_allow_custom str:test_string -- str:value ]
  test_string @ .me "highlight_mention_names" M-LIB-EMOTE-config_get ";" split pop "@1" subst
  { from @ }list { "name_match" "yes" "name_theme" "no" "color" "strip" }dict M-LIB-GRAMMAR-sub
  { "from" from @ "to" me @ }dict force_allow_custom @ if "yes" swap "highlight_allow_custom" ->[] then M-LIB-EMOTE-style
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

(* ########################### TABLE DEFINITIONS ########################### *)
: table_main (  -- a )
  {
    "" (* Blank line after header *)

    3

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
      "[#00AAAA][[#55FFFF]3[#00AAAA]] Pronouns"
      'get_null { }list
      {
      }list "\r" array_join
      'set_menu { g_table_pronoun }list
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

    "" "Settings" 1
    { "S1"
      "[#00AAAA][[#55FFFF]S1[#00AAAA]] Pose Settings/Colors"
      'get_null { }list
      {
      }list "\r" array_join
      'set_menu { g_table_emote }list
    }list


    "" (* Blank line before footer *)
  }list
;

: table_pronoun (  -- a )
  {
    "" (* Blank line after header *)

    1

    { "A"
      "[#00AAAA][[#55FFFF]A[#00AAAA]]bsolute Posessive (his/hers/its):   [#5555FF]@1"
      'get_str     { "%a" "[#0000AA]%a[!FFFFFF]" }list
      {
        "Enter the absolute posessive pronoun (his/hers/its) of this character:"
      }list "\r" array_join
      'set_str     { "%a" }list
    }list

    { "S"
      "[#00AAAA][[#55FFFF]S[#00AAAA]]ubjective (he/she/it):              [#5555FF]@1"
      'get_str     { "%s" "[#0000AA]%s[!FFFFFF]" }list
      {
        "Enter the subjective pronoun (he/she/it) of this character:"
      }list "\r" array_join
      'set_str     { "%s" }list
    }list

    { "O"
      "[#00AAAA][[#55FFFF]O[#00AAAA]]bjective (him/her/it):              [#5555FF]@1"
      'get_str     { "%o" "[#0000AA]%o[!FFFFFF]" }list
      {
        "Enter the objective pronoun (him/her/it) of this character:"
      }list "\r" array_join
      'set_str     { "%o" }list
    }list

    { "P"
      "[#00AAAA][[#55FFFF]P[#00AAAA]]ossessive (his/her/its):            [#5555FF]@1"
      'get_str     { "%p" "[#0000AA]%p[!FFFFFF]" }list
      {
        "Enter the poessive pronoun (his/her/its) of this character:"
      }list "\r" array_join
      'set_str     { "%p" }list
    }list

    { "R"
      "[#00AAAA][[#55FFFF]R[#00AAAA]]eflexive (himself/herself/itself):  [#5555FF]@1"
      'get_str     { "%r" "[#0000AA]%r[!FFFFFF]" }list
      {
        "Enter the reflexive pronoun (himself/herself/itself) of this character:"
      }list "\r" array_join
      'set_str     { "%r" }list
    }list

    ""

    { "B"
      "[#00AAAA][[#55FFFF]B[#00AAAA]]ack to Main"
      'get_null { }list
      {
      }list "\r" array_join
      'set_menu { g_table_main }list
    }list
  }list
;

: table_emote (  -- a )
  {
    "" 1

    { ""
      "  @1"
      'get_emote_style { .me 1 "%N waves. \"Hello there!\" %s says." }list
      {
      }list "\r" array_join
      'set_null { }list
    }list

    { ""
      "  @1"
      'get_emote_style { EMOTE_TEST_FROM 0 "%N says, \"Hi, @1!\"" }list
      {
      }list "\r" array_join
      'set_null { }list
    }list

    "" "Colors" 1

    { "C1"
      "[#00AAAA][[#55FFFF]C1[#00AAAA]] Name Color:                 [#5555FF]@1[!FFFFFF]"
      'get_emote_option { "color_name" "[#0000AA]" }list
      {
        "This is what will appear in place of the character's name, when the character sends any kind of pose-like message. It needs to match the actual name of the character, but you can replace underscores with spaces, and you can add MCC color codes."
        "Enter the name of this character with MCC color codes:"
      }list "\r" array_join
      'set_emote_option { "color_name" }list
    }list

    { "C2"
      "[#00AAAA][[#55FFFF]C2[#00AAAA]] Unquoted Text Color:        [#5555FF]@1[!FFFFFF]"
      'get_emote_option { "color_unquoted" "[#0000AA]" }list
      {
        "This is the color that will appear when this character sends any kind of pose-like message, for text that is not within quotes, and is not the name of the character."
        "Enter the color code for unquoted text:"
      }list "\r" array_join
      'set_emote_option { "color_unquoted" }list
    }list

    { "C3"
      "[#00AAAA][[#55FFFF]C3[#00AAAA]] Quoted Text Color:          [#5555FF]@1[!FFFFFF]"
      'get_emote_option { "color_quoted" "[#0000AA]" }list
      {
        "This is the color that will appear when this character sends any kind of pose-like message, for text that is within quotes."
        "Enter the color code for quoted text:"
      }list "\r" array_join
      'set_emote_option { "color_quoted" }list
    }list

    "" "Settings" 1

    { "S1"
      "[#00AAAA][[#55FFFF]S1[#00AAAA]] Allow Custom Colors:        [#5555FF]@1[!FFFFFF]"
      'get_emote_option { "highlight_allow_custom" "[#0000AA]" }list
      {
        "This affects the colors when you see an emote."
        "  YES - Normal behavior. You see colors the way that other characters have set them."
        "  NO - Default colors. Characters still have unique colors, but they are determined by the system."
        "  PLAIN - Everybody's colors are the same."
        "  NOCOLOR - Colors are stripped out entirely, even from 'mention highlights.'"
        ""
      }list "\r" array_join
      'set_emote_option { "highlight_allow_custom" }list
    }list

    { "S2"
      "[#00AAAA][[#55FFFF]S2[#00AAAA]] 'Mention Highlight' Names:  [#5555FF]@1[!FFFFFF]"
      'get_emote_option { "highlight_mention_names" "[#0000AA]" }list
      {
        "This is a semicolon separated list of words which are 'mention highlighted,' meaning when you see these names, they will be highlighted with text or color codes before and after."
        "This defaults to just your player name. You can use this if you want additional words to be highlighted too."
        ""
      }list "\r" array_join
      'set_emote_option { "highlight_mention_names" }list
    }list

    { "S3"
      "[#00AAAA][[#55FFFF]S3[#00AAAA]] Mention Highlight:          [#5555FF]@1[!FFFFFF]"
      'get_emote_option { "highlight_mention_format" "[#0000AA]" }list
      {
        "When you see your name (or any name in the 'Mention Highlight' Names setting), this performs the highlight. Set text, color codes, etc, and place @1 where you want the highlighted text to go. For example: \"[#0000FF]@1\" to make it bright blue, or \"[@1]\" to surround it with brackets."
        ""
      }list "\r" array_join
      'set_emote_option { "highlight_mention_format" }list
    }list

    ""

    { "B"
      "[#00AAAA][[#55FFFF]B[#00AAAA]]ack to Main"
      'get_null { }list
      {
      }list "\r" array_join
      'set_menu { g_table_main }list
    }list
  }list
;

(* ------------------------------------------------------------------------- *)

: do_menu_header (  --  )

  "[#FFFFFF]----[#0000AA][ [#FFFF55]Setup[#0000AA] ][#FFFFFF]" dup .color_strlen .chars-per-row swap - "-" * strcat
  .color_tell
;

: do_menu_footer (  --  )
  "[#0000AA][ [#AAAAAA]" "muckname" sysparm strcat "[#0000AA] ][#FFFFFF]----" strcat

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
  table_main         g_table_main         !
  table_pronoun      g_table_pronoun      !
  table_emote        g_table_emote        !

  g_table_main set_menu
;

: main
  tables_init
  do_edit
;
.
c
q
!@register m-cmd-@setup.muf=m/cmd/at_setup
!@set $m/cmd/at_setup=M3
!@set $m/cmd/at_setup=W

