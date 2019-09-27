@program m-cmd-@editobject.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@editobject.muf - $m/cmd/at_editobject                              *)
(*    A command for editing objects of any type, including players, rooms,   *)
(*    things, and exits.                                                     *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_EDITOBJECT-EditObject[ str:objname -- bool:editopened? ]       *)
(*     Starts the interactive object editor as if the player ran the         *)
(*     @editobject command, including the same permissions checks and object *)
(*     name matching. If for some reason the editor fails to open for this   *)
(*     object, false will be returned. M2 required.                          *)
(*                                                                           *)
(*   M-CMD-AT_EDITOBJECT-SaveMorph[ str:morph_name bool:quiet                *)
(*                                  -- bool:success? ]                       *)
(*   M-CMD-AT_EDITOBJECT-LoadMorph[ str:morph_name bool:quiet                *)
(*                                  -- bool:success? ]                       *)
(*     Save or load a specified morph. If quiet is true, then only error     *)
(*     messages will be displayed.                                           *)
(*                                                                           *)
(*   M-CMD-AT_EDITOBJECT-ListMorphs[  --  ]                                  *)
(*     Outputs a list of available morphs to the player.                     *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   This program is how morph information used by m-cmd-morph.muf is added  *)
(*   to player properties. The morph command itself doesn't have any options *)
(*   for managing morph data.                                                *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*     - Updated for inclusion in mercury-muf                                *)
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
$NOTE    An interface for editing objects.
$DOCCMD  @list __PROG__=2-54
 
(* Begin configurable options *)
 
$DEF .chars-per-row 79
 
(* End configurable options *)
 
(* Begin global variables *)
 
  lvar ourObject (* Set to the object being edited in main *)
  lvar ourTable  (* Set to the appropriate table in main *)
 
  (* These are intialized in main. *)
  lvar ourAttrTable
  lvar ourPronounTable
  lvar ourMorphTable
  lvar ourPlayerPrefTable
  lvar ourPlayerTable
  lvar ourRoomFlagsTable
  lvar ourRoomTable
  lvar ourThingPrefTable
  lvar ourThingFlagsTable
  lvar ourThingTable
  lvar ourExitTable
  lvar ourProgramTable
 
(* End global variables *)
 
$DEF NEEDSM2 trig caller = not caller mlevel 2 < and if "Requires MUCKER level 2 or above." abort then
$DEF NEEDSM3 trig caller = not caller mlevel 3 < and if "Requires MUCKER level 3 or above." abort then
$DEF NEEDSM4 trig caller = not caller "WIZARD" flag? not and if "Requires MUCKER level 4 or above." abort then

$PUBDEF :

$INCLUDE $m/lib/ansi
$INCLUDE $m/lib/match
$INCLUDE $m/cmd/at_action
$INCLUDE $m/cmd/at_attach
$INCLUDE $m/cmd/at_link
$INCLUDE $m/cmd/at_unlink
$INCLUDE $m/cmd/at_recycle
$INCLUDE $m/cmd/at_lsedit
 
$DEF .author prog "_author" getpropstr
$DEF .version prog "_version" getpropstr begin dup ".0" instr while "." ".0" subst repeat
 
$DEFINE .header
  prog name " " strcat .version strcat " -- by " strcat .author strcat 49 "%-*s" fmtstring
  "(Queries to:" prog owner name strcat ")" strcat 30 "%*s" fmtstring strcat .tell
  "-------------------------------------------------------------------------------" .tell
$ENDDEF
 
$DEFINE .footer
  "-------------------------------------------------------------------------------" .tell
  "*Done*" 69 "%-*s" fmtstring
  prog "L" flag? prog "V" flag? or if "(#" prog intostr strcat ")" strcat 10 "%*s" fmtstring strcat then .tell
$ENDDEF
 
(*****************************************************************************)
(                             support functions                               )
(*****************************************************************************)
: chkPerms ( d -- b )
  (* You can always edit yourself *)
  "me" match over dbcmp if
    1 exit
  then
 
  (* Builders can edit anything they control *)
  "me" match swap controls "me" match "BUILDER" flag? "me" match "WIZARD" flag? or and if
    1 exit
  then
 
  0 exit
;
 
: doCopyProps[ ref:from str:fromprop ref:to str:toprop -- ]
 
  to @ toprop @ propdir? toprop @ strlen toprop @ "#" instr = and if (* If it's a list type prop and it exists, destroy it before copying contents in *)
    to @ toprop @ remove_prop
  then
 
  to @ toprop @ from @ fromprop @ getprop setprop
 
  (* If it's a propdir, recursively descend the tree *)
  from @ fromprop @ propdir? if
    fromprop @ "/" strcat fromprop !
    from @ fromprop @ nextprop
    begin
      dup while
 
      from @   (* from stays the same *)
      over     (* The curently iterated item is the new fromprop *)
      to @     (* to stays the same *)
      toprop @ 5 pick "/" rsplit "/" swap strcat swap pop strcat (* The new toprop is the old toprop, plus the relitive name of the currently iterated item. *)
      doCopyProps
 
      from @ swap nextprop
    repeat
    pop
  then
;
 
(* For some reason, default stod returns #0 on failure.  <sigh>  Here's a replacement.  *)
: str-to-dbref ( s -- d )
 
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
: setMenu[ var:newmenu --  ]
  newmenu @ @ ourTable !
;
 
: setDefaultMenu[ --  ]
  ourObject @ player? if
    ourPlayerTable @ ourTable ! exit
  then
 
  ourObject @ room? if
    ourRoomTable @ ourTable ! exit
  then
 
  ourObject @ thing? if
    ourThingTable @ ourTable ! exit
  then
 
  ourObject @ exit? if
    ourExitTable @ ourTable ! exit
  then
 
  ourObject @ program? if
    ourProgramTable @ ourTable ! exit
  then
 
  "Unknown object type!" abort
;
 
(***** get/set Flag *****)
: getFlag[ str:flag str:valueTrue str:valueFalse -- str:value ]
  ourObject @ flag @ flag? if
    valueTrue @
  else
    valueFalse @
  then
;
 
: setFlag[ str:flag --  ]
  read
 
  dup "{y|ye|yes}" smatch if
    ourObject @ flag @ set
    pop exit
  then
 
  dup "{n|no}" smatch if
    ourObject @ "!" flag @ strcat set
    pop exit
  then
 
  "Cancelled." .tell
  pop
;
 
(***** get/set String Property *****)
: getStr[ str:property str:unsetValue -- str:value ]
  ourObject @ property @ getpropstr
 
  dup not if
    pop ourObject @ unsetValue @ pronoun_sub exit
  then
 
  dup "\r" instr if
    "\r" split pop
    "~&R..." strcat
  then
;
 
: setStr[ str:property --  ]
  "(Enter a space, to clear.)" .tell
 
  read
 
  dup strip not if
    ourObject @ property @ remove_prop
  else
    ourObject @ property @ rot setprop
  then
;
 
(***** set String Property From a List of Selections *****)
: setStrPick[ str:property list:options --  ]
 
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
    ourObject @ property @ rot setprop
    "Set." .tell
  else
    "'" swap strcat "' is not one of the options." strcat .tell
  then
;
 
(***** get/set String Boolean Property *****)
: getStrBool[ str:property str:valueTrue str:valueFalse -- str:value ]
  ourObject @ property @ getpropstr
 
  "yes" stringcmp not if
    valueTrue @
  else
    valueFalse @
  then
;
 
: getStrBool2[ str:property str:valueTrue str:valueFalse -- str:value ] (* this one is for defaulting to yes *)
  ourObject @ property @ getpropstr
 
  "no" stringcmp not if
    valueFalse @
  else
    valueTrue @
  then
;
 
: setStrBool[ str:property --  ]
  read
 
  dup "{y|ye|yes}" smatch if
    ourObject @ property @ "yes" setprop
    pop exit
  then
 
  dup "{n|no}" smatch if
    ourObject @ property @ "no" setprop
    pop exit
  then
 
  "Cancelled." .tell
  pop
;
 
: setStrBool2[ str:property --  ] (* This one is for clearing a prop, instead of setting no *)
  read
 
  dup "{y|ye|yes}" smatch if
    ourObject @ property @ "yes" setprop
    pop exit
  then
 
  dup "{n|no}" smatch if
    ourObject @ property @ remove_prop
    pop exit
  then
 
  "Cancelled." .tell
  pop
;
 
(***** get/set Integer Boolean Property *****)
: getBool[ str:property str:valueTrue str:valueFalse -- str:value ]
  ourObject @ property @ getpropval if
    valueTrue @
  else
    valueFalse @
  then
;
 
: setBool[ str:property --  ]
  read
 
  dup "{y|ye|yes}" smatch if
    ourObject @ property @ 1 setprop
    pop exit
  then
 
  dup "{n|no}" smatch if
    ourObject @ property @ 0 setprop
    pop exit
  then
 
  "Cancelled." .tell
  pop
;
 
(***** get an MPI parsed value *****)
: getMPI[ str:property str:unsetValue -- str:value ]
  ourObject @ property @ prog name 0 parseprop
 
  dup not if
    pop unsetValue @ exit
  then
 
  dup "\r" instr if
    "\r" split pop
    "~&R..." strcat
  then
;
 
(***** get/set name *****)
: getObjName[  -- str:value ]
  ourObject @ name
;
 
: setObjName[  --  ]
  read
  ourObject @ swap setname
;
 
(***** set a string to {eval:{list:<property list>}}, and edit the corresponding list *****)
: setMPIList[ str:property str:listprop --  ]
  (* Use existing property if available *)
  ourObject @ property @ getpropstr
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
 
  ourObject @ listprop @ M-CMD-AT_LSEDIT-ListEdit if
    ourObject @ property @ "{eval:{list:" listprop @ strcat "}}" strcat setprop
  then
;
 
(***** get/set Obvious Exits Output *****)
: getObvExits[ str:valueYes str:valueNo str:valueMaybe -- str:value ]
  ourObject @ "/_/sc" getpropstr
 
  dup not if
    pop valueNo @ exit
  then
 
  "[Exits: {obvexits}]" stringcmp not if
    valueYes @
  else
    valueMaybe @
  then
;
 
: setObvExits[ --  ]
  read
 
  dup "{y|ye|yes}" smatch if
    ourObject @ "/_/sc" "[Exits: {obvexits}]" setprop
    pop exit
  then
 
  dup "{n|no}" smatch if
    ourObject @ "/_/sc" remove_prop
    pop exit
  then
 
  "Cancelled." .tell
  pop
;
(***** Get/set the current morph *****)
: getMorph[  -- str:value ]
  ourObject @ "/_morph" getpropstr
 
  dup "\r" instr if
    pop "UNKNOWN" exit
  then
 
  dup not if
    ourObject @ "/_morph" "Default" setprop
    pop "Default" exit
  then
;
 
lvar ourMorphPropTable
: doMorph[ str:morph_name bool:save bool:quiet -- bool:success? ]
  ourMorphPropTable @ not if
    {
      "Appearance" "_/de"
      "Scent" "_/scent"
      "Texture" "_/texture"
      "Flavor" "_/flavor"
      "Aura" "_/aura"
      "Sound" "_/sound"
      "Writing" "_/writing"
      "Image URL" "_/image"
      "Description 'list data'" "_/dl"
      "Pronoun (Name)" "%n"
      "Pronoun (Absolute Posessive)" "%a"
      "Pronoun (Subjective)" "%s"
      "Pronoun (Objective)" "%o"
      "Pronoun (Posessive)" "%p"
      "Pronoun (Reflexive)" "%r"
      "Species" "_/species"
      "Sex" "gender_prop" sysparm
      "Character attribute information" "_attr"
      "Say/pose configuration" "_config/say"
      "Morph 'Message'" "_config/morph_mesg"
      "Morph 'OMessage'" "_config/morph_omesg"
    }dict ourMorphPropTable !
  then

  "_morph/" morph_name @ strcat var! morph_dir

  save @ if
    ourObject @ morph_dir @ propdir? if
      quiet @ not if "Clearing existing morph..." .tell then
      ourObject @ morph_dir @ remove_prop
      quiet @ not if "Saving morph..." .tell then
    else
      quiet @ not if "Creating new morph..." .tell then
    then
  else
    ourObject @ morph_dir @ propdir? if
      quiet @ not if "Loading morph..." .tell then
    else
      { "Morph '" morph_name @ "' not found." }join "bold,red" textattr .tell
      0 exit
    then
  then

  ourMorphPropTable @ foreach
    var! property
    var! name

    save @ if
      ourObject @ property @ propdir? ourObject @ property @ getpropstr or if
        quiet @ not if { "  Saving '" name @ "'..." }join .tell then
        ourObject @ property @ ourObject @ { morph_dir @ "/" property @ }join doCopyProps
      then
    else
      ourObject @ { morph_dir @ "/" property @ }join propdir? ourObject @ { morph_dir @ "/" property @ }join getpropstr or if
        quiet @ not if { "  Loading '" name @ "'..." }join .tell then
        ourObject @ { morph_dir @ "/" property @ }join ourObject @ property @ doCopyProps
      then
    then
  repeat

  ourObject @ "/_morph" morph_name @ setprop
  1
;
 
: initialCaps ( s -- s )
  strip
  ""
  swap " " explode_array foreach
    swap pop
    1 strcut tolower swap toupper swap strcat
    " " swap strcat
    strcat
  repeat
  strip
;

: setMorph[ int:save --  ]
  read

  initialCaps
  "_" " " subst

  save @ 0 doMorph pop
;
 
: setDeleteMorph[  --  ]
  read

  initialCaps
  "_" " " subst

  var! morph_name

  "_morph/" morph_name @ strcat var! morph_dir

  ourObject @ morph_dir @ propdir? if
    ourObject @ morph_dir @ remove_prop
    { "Morph '" morph_name @ "' deleted." }join .tell
  else
    { "Morph '" morph_name @ "' not found." }join "bold,red" textattr .tell
  then
;
 
: setListMorph[  --  ]
  ourObject @ "/_morph/" propdir? if
    "  Saved morphs:" "dim,cyan" textattr .tell
    ourObject @ "/_morph/" nextprop
    begin
      dup while
 
      ourObject @ over propdir? if
        dup "/" rsplit swap pop "    - " "dim,cyan" textattr swap "bold,blue" textattr strcat .tell
      then
 
      ourObject @ swap nextprop
    repeat
    pop
  else
    "  No saved morphs." .tell
  then
;
 
(***** Get source or destinations for exits *****)
: getSource[  -- str:value ]
  ourObject @ exit? if
    ourObject @ location
 
    dup "me" match swap controls if
      unparseobj
    else
      name
    then
  else
    "UNKNOWN"
  then
;
 
: setSource[  --  ]
  "(Enter a #dbref, *player_name, present object's name, 'me', 'here', or 'home')" .tell
  read 

  { "#" ourObject @ intostr }join swap M-CMD-AT_ATTACH-Attach
;
 
: getObjLink[ str:valueUnlinked -- str:value ]
  ourObject @ getlink
 
  dup not if
    pop valueUnlinked @ exit
  then
 
  dup "me" match swap controls if
    unparseobj
  else
    name
  then
;
 
: setObjLink[  --  ]
  "(Enter a #dbref, *player_name, present object's name, 'me', 'here', or 'home' or '.' to unlink)" .tell
  read

  dup "." = if
    { "#" ourObject @ intostr }join M-CMD-AT_UNLINK-Unlink pop
  else
    { "#" ourObject @ intostr }join swap M-CMD-AT_LINK-Relink pop
  then
;
 
(***** create/switch to/delete exits *****)
: setEditExits[  --  ]
  ourObject @ program? ourObject @ exit? if
    "Should not be called on an exit or program." abort
  then
 
  ourObject @ exits_array var! myExits
 
  myExits @ foreach
    swap ++ intostr "bold,cyan" textattr "] " rot name strcat "dim,cyan" textattr strcat "[" "dim,cyan" textattr swap strcat .tell
  repeat
  "Select an exit:" .tell
 
  read
 
  atoi -- (* I like counting from 0 .. but 0 is atoi's error code.  So whatever.  I'll count from 1 *)
 
  myExits @ swap [] dup not if
    pop "Sorry, that's not one of the selections." .tell exit
  then
 
  dup chkPerms not if
    pop "Permission denied.  (Try exiting the editor and running 'help @chown' for information on seizing exits.)" .tell exit
  then
 
  ourObject !
  setDefaultMenu
;
 
: setNewExit[  --  ]
 
  "Enter the name of the new exit:" .tell
 
  "#" ourObject @ intostr strcat read M-CMD-AT_ACTION-Action
 
  dup if
    dup chkPerms not if
      pop "FATAL ERROR: Permission denied editing newly created exit!" .tell pid kill
    then
 
    ourObject !
    setDefaultMenu
  else
    pop
  then
;
 
: setRecycleExit[  --  ]
 
  ourObject @ program? ourObject @ exit? if
    "Should not be called on an exit or program." abort
  then
 
  ourObject @ exits_array var! myExits
 
  myExits @ foreach
    swap ++ intostr "bold,cyan" textattr "] " rot name strcat "dim,cyan" textattr strcat "[" "dim,cyan" textattr swap strcat .tell
  repeat
  "Select an exit:" .tell
 
  read
 
  atoi -- (* I like counting from 0 .. but 0 is atoi's error code.  So whatever.  I'll count from 1 *)
 
  myExits @ swap [] dup not if
    pop "Sorry, that's not one of the selections." .tell exit
  then
 
  dup chkPerms not if
    pop "Permission denied.  (Try exiting the editor and running 'help @chown' for information on seizing exits.)" .tell exit
  then
 
  "#" swap intostr strcat 1 M-CMD-AT_RECYCLE-Recycle
;
 
(***** Change to parent objects *****)
: setParent[  --  ]
  ourObject @ location
 
  dup not if
    pop "This doesn't have a parent!" .tell exit
  then
 
  dup chkPerms not if
    pop "Permission denied." .tell exit
  then
 
  ourObject !
  setDefaultMenu
;
 
: getParent[ str:valueRoom str:valuePlayer str:valueOtherwise -- str:value ]
  ourObject @ location
 
  dup room? if
    pop valueRoom @ exit
  then
 
  dup player? if
    pop valuePlayer @ exit
  then
 
  pop valueOtherwise @ exit
;
 
(***** Get the type of this object *****)
: getObject[ str:valueRoom str:valuePlayer str:valueOtherwise -- str:value ]
 
  ourObject @ room? if
    valueRoom @ exit
  then
 
  ourObject @ player? if
    valuePlayer @ exit
  then
 
  valueOtherwise @ exit
;
 
(***** force user to execute command *****)
: setExternal[ ref:program str:newCommand --  ]
  command @ var! oldCommand
 
  newCommand @ command !
  "" program @ call
  oldCommand @ command !
;
 
(***** do nothing *****)
: setNull[  --  ]
;
 
: getNull[  -- str:value ]
  ""
;
 
(#############################################################################)
(############################## PLAYER TABLES ################################)
(#############################################################################)
 
: getAttrTable (  -- a )
  {
    "" (* Blank line after header *)
    "Attributes" 3
 
    { "A1"
      "~&060[~&160A1~&060] Flight:      ~&140%s"
      'getStrBool { "_attr/flight?" "Yes" "No" }list
 
      {
        "** Builders may access this attribute by @locking to attr/flight?:yes, or with the MPI code: {if:{eq:{prop:attr/flight?,me},yes},<code>}"
        "Can this character fly? (y/n)"
      }list "\r" array_join
      'setStrBool { "_attr/flight?" }list
    }list
 
    { "A2"
      "~&060[~&160A2~&060] Swim:        ~&140%s"
      'getStrBool { "_attr/swim?" "Yes" "No" }list
 
      {
        "** Builders may access this attribute by @locking to attr/swim?:yes, or with the MPI code: {if:{eq:{prop:attr/swim?,me},yes},<code>}"
        "Can this character swim?"
      }list "\r" array_join
      'setStrBool { "_attr/swim?" }list
    }list
 
    { "A3"
      "~&060[~&160A3~&060] Gills:        ~&140%s"
      'getStrBool { "_attr/gills?" "Yes" "No" }list
 
      {
        "** Builders may access this attribute by @locking to attr/gills?:yes, or with the MPI code: {if:{eq:{prop:attr/gills?,me},yes},<code>}"
        "Can this character breathe underwater?"
      }list "\r" array_join
      'setStrBool { "_attr/gills?" }list
    }list
 
    { "A4"
      "~&060[~&160A4~&060] Size:        ~&140%s"
      'getStr     { "_attr/size" "~&110[Unset]~&R" }list
 
      {
        "** Builders may access this attribute by @locking to attr/size:<value>, or with the MPI code: {if:{eq:{prop:attr/size,me},<value>},<code>}"
        "How big is this character?"
      }list "\r" array_join
      'setStrPick { "_attr/size" { "micro" "normal" "macro" }list }list
    }list
 
    { "A5"
      "~&060[~&160A5~&060] Can Drive:   ~&140%s"
      'getStrBool { "_attr/candrive?" "Yes" "No" }list
 
      {
        "** Builders may access this attribute by @locking to attr/candrive?:yes, or with the MPI code: {if:{eq:{prop:attr/candrive?,me},yes},<code>}"
        "Can this character drive an automobile?"
      }list "\r" array_join
      'setStrBool { "_attr/candrive?" }list
    }list
 
    { "A6"
      "~&060[~&160A6~&060] Space Travel: ~&140%s"
      'getStrBool { "_attr/spacetravel?" "Yes" "No" }list
 
      {
        "** Builders may access this attribute by @locking to attr/spacetravel?:yes, or with the MPI code: {if:{eq:{prop:attr/spacetravel?,me},yes},<code>}"
        "Can this character survive exposure to space or lack of oxygen?"
      }list "\r" array_join
      'setStrBool { "_attr/spacetravel?" }list
    }list
 
    ""
    { "B"
      "~&060[~&160B~&060]ack to %s Edit"
      'getObject { "Room" "Player" "Object" }list
 
      {
      }list "\r" array_join
      'setDefaultMenu { }list
    }list
  }list
;
 
: getPronounTable (  -- a )
  {
    "" (* Blank line after header *)
 
    1
 
    { "N"
      "~&060[~&160N~&060]ame (Pronoun substitution name):    ~&140%s"
      'getStr     { "%n" "~&040%n~&R" }list
 
      {
        "This name holds a special purpose.  The system's pronoun substitution routines also can retrieve your name, but unlike most retrievals of your name, you can set this value to whatever you want.  If this feature is abused, people will likely stop using it, so please just stick to reasonable things.  Such as: if your name is The_Great_Gazoo, entering 'The Great Gazoo' for your pronoun substition name is perfectly reasonable.  So are things like 'the grey cat' or 'a fuzzy walrus'."
        "However, entering things like 'The_Great_Gazoo wh0 r0x0rz!!!' is irratating, and discourages people from using pronoun substition for names."
        ""
        "Enter the pronoun substition name for this character:"
      }list "\r" array_join
      'setStr     { "%n" }list
    }list
 
    { "A"
      "~&060[~&160A~&060]bsolute Posessive (his/hers/its):   ~&140%s"
      'getStr     { "%a" "~&040%a~&R" }list
 
      {
        "Enter the absolute posessive pronoun (his/hers/its) of this character:"
      }list "\r" array_join
      'setStr     { "%a" }list
    }list
 
    { "S"
      "~&060[~&160S~&060]ubjective (he/she/it):              ~&140%s"
      'getStr     { "%s" "~&040%s~&R" }list
 
      {
        "Enter the subjective pronoun (he/she/it) of this character:"
      }list "\r" array_join
      'setStr     { "%s" }list
    }list
 
    { "O"
      "~&060[~&160O~&060]bjective (him/her/it):              ~&140%s"
      'getStr     { "%o" "~&040%o~&R" }list
 
      {
        "Enter the objective pronoun (him/her/it) of this character:"
      }list "\r" array_join
      'setStr     { "%o" }list
    }list
 
    { "P"
      "~&060[~&160P~&060]ossessive (his/her/its):            ~&140%s"
      'getStr     { "%p" "~&040%p~&R" }list
 
      {
        "Enter the poessive pronoun (his/her/its) of this character:"
      }list "\r" array_join
      'setStr     { "%p" }list
    }list
 
    { "R"
      "~&060[~&160R~&060]eflexive (himself/herself/itself):  ~&140%s"
      'getStr     { "%r" "~&040%r~&R" }list
 
      {
        "Enter the reflexive pronoun (himself/herself/itself) of this character:"
      }list "\r" array_join
      'setStr     { "%r" }list
    }list
 
    ""
    { "B"
      "~&060[~&160B~&060]ack to %s Edit"
      'getObject { "Room" "Player" "Object" }list
 
      {
      }list "\r" array_join
      'setDefaultMenu { }list
    }list
  }list
;
 
: getMorphTable (  -- a )
  {
    "" (* Blank line after header *)
 
    1
 
    { ""
      "~&060Species: ~&140%s"
      'getStr     { "_/species" "~&110[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    { ""
      "~&060Gender:  ~&140%s"
      'getStr     { "gender_prop" sysparm "~&110[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    "" 1
 
    { ""
      "~&060Description: ~&140%s"
      'getMPI     { "_/de" "~&110[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    { ""
      "~&060Scent:       ~&140%s"
      'getMPI     { "_/scent" "~&110[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    { ""
      "~&060Texture:     ~&140%s"
      'getMPI     { "_/texture" "~&110[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    { ""
      "~&060flavor:      ~&140%s"
      'getMPI     { "_/flavor" "~&110[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    { ""
      "~&060Aura:        ~&140%s"
      'getMPI     { "_/aura" "~&110[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    { ""
      "~&060Sound:       ~&140%s"
      'getMPI { "_/sound" "~&040[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    { ""
      "~&060Writing:     ~&140%s"
      'getMPI { "_/writing" "~&040[Unset]~&R" }list
 
      {
      }list "\r" array_join
      'setNull { }list
    }list
 
    ""

    "Morphs" 4
 
    { "M"
      "~&060[~&160M~&060]orph List"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setListMorph { }list
    }list
 
    { "S"
      "  ~&060[~&160S~&060]ave Morph"
      'getNull { }list
 
      {
        "The currently displayed descriptions and messages will be saved. If the morph does not exist, it will be created."
        ""
        "Please enter the name of the morph you wish to save."
      }list "\r" array_join
      'setMorph { 1 }list
    }list
 
    { "L"
      "   ~&060[~&160L~&060]oad Morph"
      'getNull { }list
 
      {
        "Please enter the name of the morph you wish to load."
      }list "\r" array_join
      'setMorph { 0 }list
    }list
 
    { "D"
      "    ~&060[~&160D~&060]elete Morph"
      'getNull { }list
 
      {
        "Enter the name of the morph you wish to delete."
      }list "\r" array_join
      'setDeleteMorph { }list
    }list
 
    "" "Morph Messages" 1
 
    { "1"
      "~&060[~&1601~&060] Morph Message:  ~&140%s"
      'getStr     { "_config/morph_mesg" "~&040[Unset]~&R" }list
 
      {
        "This message is displayed to you when you change to this morph.  (with the 'morph' command only)"
        "  eg.: You shift into super dragon mode!"
        ""
        "Please enter your morph message:"
      }list "\r" array_join
      'setStr     { "_config/morph_mesg" }list
    }list
 
    { "2"
      "~&060[~&1602~&060] Morph OMessage: ~&140%s"
      'getStr     { "_config/morph_omesg" "~&040[Unset]~&R" }list
 
      {
        "This message is displayed to everyone else in your location when you change to this morph.  (with the 'morph' command only)"
        "Your name is prepended to the message automatically when shown."
        "  eg.: shifts into super dragon mode!"
        ""
        "Please enter your morph omessage:"
      }list "\r" array_join
      'setStr     { "_config/morph_omesg" }list
    }list

    ""
    { "{P|B}"
      "~&060[~&160B~&060]ack to Player Edit"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setDefaultMenu { }list
    }list

  }list
;
 
: getPlayerPrefTable (  -- a )
  {
    "" (* Blank line after header *)
    "Preferences" 2
    { "1"
      "~&060[~&1601~&060] Allowing 'hand':          ~&140%s"
      'getStrBool { "_hand/hand_ok" "Yes" "No" }list
 
      {
        "The 'hand' program by Wog is used to move an item from your inventory into someone else's.  However, it may not be preferable to allow people to hand you objects.  Use your descresion."
        ""
        "Allow 'hand'ing of objects to this character? (y/n)"
      }list "\r" array_join
      'setStrBool { "_hand/hand_ok" }list
    }list
 
    { "2"
      "~&060[~&1602~&060] Showing @doing in whospe: ~&140%s"
      'getStrBool { "_prefs/wsseedoing" "Yes" "No" }list
 
      {
        "The whospe program displays species, gender, and status information about everyone in your current room.  If you want to optionally see a short 'Doing' string.  (The same string that's shown in the WHO command)  You may select it here."
        ""
        "Show @doing in whospe? (y/n)"
      }list "\r" array_join
      'setStrBool { "_prefs/wsseedoing" }list
    }list
 
    { "3"
      "~&060[~&1603~&060] Hiding from whospe #far:  ~&140%s"
      'getStrBool { "_prefs/wsobject" "Yes" "No" }list
 
      {
        "The whospe program displays species, gender, and status information about everyone in your current room.  It also, however, may be used to display information about people remotely.  If you're zealous about your privacy, you can prevent people from using this command on you."
        ""
        "Hide from whospe #far? (y/n)"
      }list "\r" array_join
      'setStrBool { "_prefs/wsobject" }list
    }list
 
    { "4"
      "~&060[~&1604~&060] Hiding from whereis:      ~&140%s"
      'getStrBool { "_prefs/whereis/unfindable" "Yes" "No" }list
 
      {
        "Use the 'whereis' program to find your friends by entering 'whereis <name>'.  If you're zealous about your privacy and you want to hide from this feature, select it here."
        ""
        "Hide from whereis? (y/n)"
      }list "\r" array_join
      'setStrBool2 { "_prefs/whereis/unfindable" }list
    }list
 
    { "5"
      "~&060[~&1605~&060] Ride mode:                ~&140%s"
      'getStr { "ride/_mode" "Walk" }list
 
      {
        "The 'ride' program by Riss allows you to be automatically led by another character, rather than having to follow them manually.  However, not everyone has a horse style back on which to ride.  Select your style of 'riding' from the list below."
        ""
      }list "\r" array_join
      'setStrPick { "ride/_mode" { "Ride" "Taur" "Paw" "Walk" "Hand" }list }list
    }list
 
    { "6"
      "~&060[~&1606~&060] Run 'saysetup'"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setExternal { #163 "saysetup" }list
    }list
 
    "" "Sweep messages" 1
 
    { "S1"
      "~&060[~&160S1~&060] Sweep Room Message:      ~&140%s"
      'getStr     { "_sweep/sweep" "~&040[Unset]~&R" }list
 
      {
        "This message is shown to everyone in the room, including yourself, when you sweep a room.  To sweep a room, simply type 'sweep', and all the sleepers in the room will be kicked out.  Your name is prefixed to this message automatically."
        ""
        "Enter this character's sweep room message:"
      }list "\r" array_join
      'setStr     { "_sweep/sweep" }list
    }list
 
    { "S2"
      "~&060[~&160S2~&060] Sweep Player Message:    ~&140%s"
      'getStr     { "_sweep/fmt/std" "~&040[Unset]~&R" }list
 
      {
        "This message is shown to everyone in the room, including yourself, when you sweep an indivisual player or object.  To sweep a player, type sweep <name>, and it'll be tossed out.  Your name is prefixed to this message automatically."
        "Pronoun substitution is done from the perspective of the object who gets swept.  So use %n in this message to be replaced by the name of the player who gets swept.  For example 'sweeps %n into the nap room.'"
        ""
        "Enter the sweep player message:"
      }list "\r" array_join
      'setStr     { "_sweep/fmt/std" }list
    }list
 
    { "S3"
      "~&060[~&160S3~&060] Swept Message:           ~&140%s"
      'getStr     { "_sweep/swept" "~&040[Unset]~&R" }list
 
      {
        "This message is shown to everyone in the room, including yourself, when you get swept from a room.  Your name is prefixed to this message automatically."
        ""
        "Enter this character's swept message:"
 
      }list "\r" array_join
      'setStr     { "_sweep/swept" }list
    }list
 
    ""
    { "B"
      "~&060[~&160B~&060]ack to %s Edit"
      'getObject { "Room" "Player" "Object" }list
 
      {
      }list "\r" array_join
      'setDefaultMenu { }list
    }list
  }list
;
 
: getPlayerTable (  -- a )
  {
    1
    "" (* Blank line after header *)
 
    { "1"
      "~&060[~&1601~&060] Species: ~&140%s"
      'getStr     { "_/species" "~&110[Unset]~&R" }list
 
      {
        "Your species is the type of being your character is."
        "To avoid confusion, please prefix your species name with 'Anthro ' if this character is anthropomorphic."
        ""
        "Enter the species of this character:"
      }list "\r" array_join
      'setStr     { "_/species" }list
    }list
 
    2
 
    { "2"
      "~&060[~&1602~&060] Gender:  ~&140%s"
      'getStr     { "gender_prop" sysparm "~&110[Unset]~&R" }list
 
      {
        "The system recognizes the values 'Male', 'Female', 'Herm', 'Hermaphrodite', and 'Neuter'.  However, you're free to enter whatever you want."
        ""
        "Enter the gender of this character:"
      }list "\r" array_join
      'setStr     { "gender_prop" sysparm }list
    }list
 
    { "3"
      "~&060[~&1603~&060] Pronoun Substitution"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourPronounTable }list
    }list
 
    "" "Descriptions" 1
 
    { "{D1|D}"
      "~&060[~&160D1~&060] Description: ~&140%s"
      'getMPI     { "_/de" "~&110[Unset]~&R" }list
 
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
      'setMPIList { "_/de" "_/dl/desc" }list
    }list
 
    { "D2"
      "~&060[~&160D2~&060] Scent:       ~&140%s"
      'getMPI     { "_/scent" "~&110[Unset]~&R" }list
 
      {
        "This is where you enter this character's aroma."
        "To see an object or player's scent, use the 'smell' command."
        ""
        "Enter this character's scent:"
      }list "\r" array_join
      'setMPIList { "_/scent" "_/dl/scent" }list
    }list
 
    { "D3"
      "~&060[~&160D3~&060] Texture:     ~&140%s"
      'getMPI     { "_/texture" "~&110[Unset]~&R" }list
 
      {
        "A character's 'texture' is the sensation of touching the character."
        "To see an object or player's texture, use the 'feel' command."
        ""
        "Enter this character's texture:"
      }list "\r" array_join
      'setMPIList { "_/texture" "_/dl/texture" }list
    }list
 
    { "D4"
      "~&060[~&160D4~&060] flavor:      ~&140%s"
      'getMPI     { "_/flavor" "~&110[Unset]~&R" }list
 
      {
        "This is where you describe the taste of this character when nibbled or licked."
        "To see an object or player's flavor, use the 'taste' command."
        ""
        "Enter this character's flavor:"
      }list "\r" array_join
      'setMPIList { "_/flavor" "_/dl/flavor" }list
    }list
 
    { "D5"
      "~&060[~&160D5~&060] Aura:        ~&140%s"
      'getMPI     { "_/aura" "~&110[Unset]~&R" }list
 
      {
        "Your 'aura' is the general feelings you inspire.  For example, if you look at a car salesman, his description may be 'He's smiling, happy, polite, and friendly', but his aura would be 'He's a liar and a cheat and he hates you.'"
        "To see an object or player's aura, use the 'sense' command."
        ""
        "Enter this character's aura:"
      }list "\r" array_join
      'setMPIList { "_/aura" "_/dl/aura" }list
    }list
 
    { "D6"
      "~&060[~&160D6~&060] Sound:       ~&140%s"
      'getMPI { "_/sound" "~&040[Unset]~&R" }list
 
      {
        "This property is for the sounds this character often makes.  You aren't limited to sounds which you constantly make.  You can also describe sounds you make from time to time."
        "To see an object or player's sound, use the 'hear' command."
        ""
        "Enter this character's sound:"
      }list "\r" array_join
      'setMPIList { "_/sound" "_/dl/sound" }list
    }list
 
    { "D7"
      "~&060[~&160D7~&060] Writing:     ~&140%s"
      'getMPI { "_/writing" "~&040[Unset]~&R" }list
 
      {
        "This property is for any overt writing on this character.  i.e. T-Shirts, Signs, etc."
        "To see anything's writing, use the 'read' command."
        ""
        "Enter this character's writing:"
      }list "\r" array_join
      'setMPIList { "_/writing" "_/dl/writing" }list
    }list
 
    "" "Flags" 3
 
    { "C"
      "~&060[~&160C~&060]olor: ~&140%s"
      'getFlag    { "COLOR" "          Yes" "BLACK & WHITE" }list
 
      {
        "Does your client support color? (y/n)"
      }list "\r" array_join
      'setFlag    { "COLOR" }list
    }list
 
    { "S"
      "~&060[~&160S~&060]ilent:         ~&140%s"
      'getFlag    { "SILENT" "Yes" "No" }list
 
      {
        "A player can set themselves \"SILENT\" and not see all the dbrefs and dark objects that they own.  They won't see objects in a dark room either.  They still control the objects though."
        ""
        "Set the SILENT flag on this character? (y/n)"
      }list "\r" array_join
      'setFlag    { "SILENT" }list
    }list
 
    { "H"
      "~&060[~&160H~&060]aven:          ~&140%s"
      'getFlag    { "HAVEN" "Yes" "No" }list
 
      {
        "If a player is set HAVEN, they cannot be paged."
        "There are also other benifits to setting yourself HAVEN.  Whereis, and other intrusive programs should stop bothering you and helping others bother you."
        ""
        "Set the HAVEN flag on this character? (y/n)"
      }list "\r" array_join
      'setFlag    { "HAVEN" }list
    }list
 
    ({ "L"
      "~&060[~&160L~&060]ink_OK:        ~&140%s"
      'getFlag    { "LINK_OK" "~&110YES~&R" "No" }list
 
      {
        "When you're set LINK_OK, people can set the 'homes' of objects on you.  This is generally dangerous, because when combined with the STICKY flag on an object, it can be real hard to get rid of if someone sets its home on you.  If you end up in this situation, try @unlink <object name>.  It's a good idea to leave this off at all times unless you want someone to link an object to you."
        ""
        "Set the LINK_OK flag on this character? (y/n)"
      }list "\r" array_join
      'setFlag    { "LINK_OK" }list
    }list
 
    { "K"
      "~&060[~&160K~&060]ill_OK:        ~&140%s"
      'getFlag    { "KILL_OK" "Yes" "No" }list
 
      {
        "On systems where the KILL_OK flag is used, you cannot kill someone unless both you and they are set Kill_OK."
        "Getting killed is no big deal. If you are killed, you just get kicked into the street, and all things you carry return to their homes. You also collect 50 pennies in insurance money (unless you have >= 10000 pennies)."
        ""
        "Set the KILL_OK flag on this character? (y/n)"
      }list "\r" array_join
      'setFlag    { "KILL_OK" }list
    }list
 
    { "X"
      "~&060[~&160X~&060] Forcible:     ~&140%s"
      'getFlag    { "XFORCIBLE" "~&110YES~&R" "No" }list
 
      {
        "When set XForcible, a player can force your character to perform an action as though it was entered directly by that character."
        "This flag must also be used in combination with the @flock command.  See 'help @flock' for more details."
        ""
        "OOPS!  There seems to be a problem with the program setting this flag..  Try @set <object>=X instead." ("Set the XFORCIBLE flag on this character? {y/n}")
      }list "\r" array_join
      'setNull    { }list
    }list
 
    { "J"
      "~&060[~&160J~&060]ump_OK:        ~&140%s"
      'getFlag    { "JUMP_OK" "Yes" "No" }list
 
      {
        "Allow teleports and throwing? {y/n}"
      }list "\r" array_join
      'setFlag    { "JUMP_OK" }list
    }list)
 
    "" "Settings" 2
 
    { "S1"
      "~&060[~&160S1~&060] Automatically Show Map: ~&140%s"
      'getStrBool2 { "_prefs/automap" "Yes" "No" }list
 
      {
        "This preference is used by Latitude MUCK to determine if it should display the map to you every time you enter a new area.  This makes navigation easy, but very spammy."
        ""
        "Automatically show the map? (y/n)"
      }list "\r" array_join
      'setStrBool { "_prefs/automap" }list
    }list
 
    { "S3"
      "~&060[~&160S3~&060] Morphs"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourMorphTable }list
    }list
 
    { "S2"
      "~&060[~&160S2~&060] Preferences"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourPlayerPrefTable }list
    }list
 
    { "S4"
      "~&060[~&160S4~&060] Attributes"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourAttrTable }list
    }list
 
    "" (* Blank line before footer *)
  }list
;
 
(#############################################################################)
(################################ ROOM TABLE #################################)
(#############################################################################)
: getRoomFlagsTable (  -- a )
  {
    "" "Flags" 1
 
    { "A"
      "~&060[~&160A~&060]bode:   ~&140%s"
      'getFlag { "ABODE" "~&110YES ~&100(Object/player homes can be set here freely!)~&R" "No ~&100(Object/player homes can not be set here freely.)~&R" }list
 
      {
        "With the ABODE flag, you can allow anyone to '@link' their objects/players into your room.  When an object is swept, it will go to its 'home' which is defined by the '@link' command.  Normally, people can't set an object's home in an area they don't control unless the ABODE flag is set."
        "Also, you should set this on any environment rooms you create whihc others need to use.  (In fact, you should probably set it on every environment room you make.)  This flag is nessessary for other users to @tel their rooms into your environment, or to get a properly parented room when they create a room under your environment."
        ""
        "Set the ABODE flag on this room? (y/n)"
      }list "\r" array_join
      'setFlag { "ABODE" }list
    }list
 
    { "D"
      "~&060[~&160D~&060]ark:    ~&140%s"
      'getFlag { "DARK" "~&110YES~&R ~&100(The contents list does not show!)~&R" "No ~&100(The contents list behaves normally.)~&R" }list
 
      {
        "If you set a room DARK, then no one will be able to see the contents of your room, even while inside it.  Meaning players won't be able to detect that other players or objects are inside your area."
        "The owner of the room is uneffected by DARK unless they also have the SILENT flag set on themselves."
        ""
        "Set the DARK flag on this room? (y/n)"
      }list "\r" array_join
      'setFlag { "DARK" }list
    }list
 
    { "H"
      "~&060[~&160H~&060]aven:   ~&140%s"
      'getFlag { "HAVEN" "Yes ~&100(Kill and whereis are forbidden.)~&R" "No ~&100(Kill and whereis behave normally.)~&R" }list
 
      {
        "If a room is set HAVEN, you can not use the kill command in that room."
        "The HAVEN flag on a room also may have similar qualities to a HAVEN flag on a player.  For example, 'whereis' considers a room private if it is set HAVEN."
        ""
        "Set the HAVEN flag on this room? (y/n)"
      }list "\r" array_join
      'setFlag { "HAVEN" }list
    }list
 
    ({ "J"
      "~&060[~&160J~&060]ump_OK: ~&140%s"
      'getFlag { "JUMP_OK" "Yes" "No" }list
 
      {
        "The JUMP_OK flag allows teleports to/from a room."
        ""
        "Set the JUMP_OK flag on this room? {y/n}"
      }list "\r" array_join
      'setFlag { "JUMP_OK" }list
    }list)
 
    { "L"
      "~&060[~&160L~&060]ink_OK: ~&140%s"
      'getFlag { "LINK_OK" "~&110YES~&R ~&100(This room can be linked to freely!)~&R" "No ~&100(This room may not be linked to freely.)~&R" }list
 
      {
        "Setting the LINK_OK flag on a room allows anyone to create an exit into your room.  If you want someone to create an exit into your area, set the area LINK_OK, then tell them it's 'dbref' number (You'll see it to the right of the name of the room in 'look', if you're not set SILENT.)  If you want a reverse exit, then you'll have to get them to set their area LINK_OK."
        "It's highly reccomended you turn this off when you're done."
        ""
        "Set the LINK_OK flag on this room? (y/n)"
      }list "\r" array_join
      'setFlag    { "LINK_OK" }list
    }list
 
    { "S"
      "~&060[~&160S~&060]ticky:  ~&140%s"
      'getFlag { "STICKY" "Yes ~&100(Drop-to is delayed.)~&R" "No ~&100(Drop-to is instantaneous.)~&R" }list
 
      {
        "If a room is STICKY, its drop-to is delayed until the last person leaves the room.  A drop-to is where objects go when you drop them in that room, and it's set with @link."
        ""
        "Set the STICKY flag on this room? (y/n)"
      }list "\r" array_join
      'setFlag { "STICKY" }list
    }list
 
    { "V"
      "~&060[~&160V~&060]ehicle: ~&140%s"
      'getFlag { "VEHICLE" "Yes ~&100(Vehicles may NOT use this room.)~&R" "No ~&100(Vehicles may use this room.)~&R" }list
 
      {
        "When the VEHICLE flag is set on a room it means that vehicle objects may *NOT* use the room.  This allows a way to prevent vehicles from entering areas where it would be illogical for them to be."
        ""
        "Set the VEHICLE flag on this room? (y/n)"
      }list "\r" array_join
      'setFlag { "VEHICLE" }list
    }list
 
    { "Z"
      "~&060[~&160Z~&060]ombie:  ~&140%s"
      'getFlag { "ZOMBIE" "Yes ~&100(Puppets may NOT use this room.)~&R" "No ~&100(Puppets may use this room.)~&R" }list
 
      {
        "When the ZOMBIE flag is set on a room it means that puppet/zombie objects may *NOT* use the room.  This allows a way to prevent zombies from entering areas where they are not wanted."
        ""
        "Set the ZOMBIE flag on this room? (y/n)"
      }list "\r" array_join
      'setFlag    { "ZOMBIE" }list
    }list
 
    ""
    { "{P|B}"
      "~&060[~&160B~&060]ack to Room Edit"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourRoomTable }list
    }list
  }list
;
 
: getRoomTable (  -- a )
  {
    "" (* Blank line after header *)
    1
 
    { "N"
      "~&060[~&160N~&060]ame: ~&140%s"
      'getObjName { }list
 
      {
        "Enter the room's new name:"
      }list "\r" array_join
      'setObjName { }list
    }list
 
    3
 
    { "F"
      "~&060[~&160F~&060]lags"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourRoomFlagsTable }list
    }list
 
    "" "Descriptions" 1
 
    { "{D1|D}"
      "~&060[~&160D1~&060] Description: ~&140%s"
      'getMPI     { "_/de" "~&110[Unset]~&R" }list
 
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
      'setMPIList { "_/de" "_/dl/desc" }list
    }list
 
    { "D2"
      "~&060[~&160D2~&060] Scent:       ~&140%s"
      'getMPI     { "_/scent" "~&110[Unset]~&R" }list
 
      {
        "This is where you enter the room's aroma."
        "To see anything's scent, use the 'smell' command."
        ""
        "Enter this character's scent:"
      }list "\r" array_join
      'setMPIList { "_/scent" "_/dl/scent" }list
    }list
 
    { "D3"
      "~&060[~&160D3~&060] Texture:     ~&140%s"
      'getMPI     { "_/texture" "~&110[Unset]~&R" }list
 
      {
        "You may enter anything you want for the room's texture.  Because rooms are often large, it'd be hard to go around feeling every surface in them, so describe whatever you want.  Choose some surfaces or all of them, and describe the sensation of touching them."
        "To see anything's texture, use the 'feel' command."
        ""
        "Enter this character's texture:"
      }list "\r" array_join
      'setMPIList { "_/texture" "_/dl/texture" }list
    }list
 
    { "D4"
      "~&060[~&160D4~&060] flavor:      ~&140%s"
      'getMPI     { "_/flavor" "~&110[Unset]~&R" }list
 
      {
        "Here, describe what it's like to lick this area."
        "To see anything's flavor, use the 'taste' command."
        ""
        "Enter this character's flavor:"
      }list "\r" array_join
      'setMPIList { "_/flavor" "_/dl/flavor" }list
    }list
 
    { "D5"
      "~&060[~&160D5~&060] Aura:        ~&140%s"
      'getMPI     { "_/aura" "~&110[Unset]~&R" }list
 
      {
        "An area's 'aura' is the feeling it inspires.  For example, if you look at an old mansion, you may see 'The furnature is beautifully crafted and priclessly maintained, and the architecture is astonishing.', but its aura may be 'This place is terrifying, it's dark and creepy.'"
        "To see anything's aura, use the 'sense' command."
        ""
        "Enter this character's aura:"
      }list "\r" array_join
      'setMPIList { "_/aura" "_/dl/aura" }list
    }list
 
    { "D6"
      "~&060[~&160D6~&060] Sound:       ~&140%s"
      'getMPI { "_/sound" "~&040[Unset]~&R" }list
 
      {
        "This property is for the sounds most often heard in the room.  It's best to make a general description of what aural feelings the room tends to inspire."
        "To see anything's sound, use the 'hear' command."
        ""
        "Enter this character's sound:"
      }list "\r" array_join
      'setMPIList { "_/sound" "_/dl/sound" }list
    }list
 
    { "D7"
      "~&060[~&160D7~&060] Writing:     ~&140%s"
      'getMPI { "_/writing" "~&040[Unset]~&R" }list
 
      {
        "This property is for any overt writing in the area.  i.e. a large banner.  As for signs, it's best to create a sign object with @create and set the writing on that instead."
        "To see anything's writing, use the 'read' command."
        ""
        "Enter this character's writing:"
      }list "\r" array_join
      'setMPIList { "_/writing" "_/dl/writing" }list
    }list
 
    "" "Messages" 2
 
    { "M1"
      "~&060[~&160M1~&060] @success Message:  ~&140%s"
      'getMPI { "_/sc" "~&040[Unset]~&R" }list
 
      {
        "The @success and @oscuccess messages are seen when an object is 'used'.  Using a room is done by entering it and looking around, both automatically when first entering the room, and when issuing the 'look' command."
        "In nearly all cases however, this field is used to display the 'Obvious Exists' to any user who looks around this room.  In other words, to display a list of all exits which are not set DARK.  To do so, simply put '{obvexits}' in this string."
        "(Also, you may set the {obvexits} behaviour by setting the property '/obvexits' in any room up your environment tree.  The default is: '{commas:{if:{le:{strlen:%exits},77},%exits,{parse:x,{&exits},{name:{&x}}}}}'  This is an advanced property, ask a skilled builder for help if you wish to tweak it.)"
        ""
        "Example: [Exits: {obvexits}]"
        ""
        "Enter this room's @success message:"
      }list "\r" array_join
      'setStr { "_/sc" }list
    }list
 
    { "M2"
      "~&060[~&160M2~&060] @osuccess Message: ~&140%s"
      'getMPI { "_/osc" "~&040[Unset]~&R" }list
 
      {
        "The @success and @osuccess messages are seen when an object is 'used'.  Using a room is done by entering it and looking around, both automatically when first entering the room, and when issuing the 'look' command."
        "This message is of little use at all, it's reccomended you DON'T SET IT unless you have a good reason."
        "Everyone in the room sees this message except the looker, and the looker's name is prepended to the message."
        ""
        "Example: glances around the room."
        ""
        "Enter this room's @osuccess message:"
      }list "\r" array_join
      'setStr { "_/osc" }list
    }list
 
    { "M3"
      "~&060[~&160M3~&060] @fail Message:     ~&140%s"
      'getMPI { "_/fl" "~&040[Unset]~&R" }list
 
      {
        "The @fail and @ofail messages are seen when an object fails to be 'used'.  Using a room is done by entering it and looking around, both automatically when first entering the room, and when issuing the 'look' command."
        "This message will only be displayed if the room is @locked against you.  See the 'help @lock' command for more information."
        "Generally, this message is of little use."
        ""
        "Example: You have trouble finding the exits here."
        ""
        "Enter this room's @fail message:"
      }list "\r" array_join
      'setStr { "_/fl" }list
    }list
 
    { "M4"
      "~&060[~&160M4~&060] @ofail Message:    ~&140%s"
      'getMPI { "_/ofl" "~&040[Unset]~&R" }list
 
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
      'setStr { "_/ofl" }list
    }list
 
    { "M5"
      "~&060[~&160M5~&060] @drop Message:     ~&140%s"
      'getMPI { "_/dr" "~&040[Unset]~&R" }list
 
      {
        "The @drop and @odrop messages, when set on a room, are triggered when someone drops a program or thing type object in this room."
        "This message is shown only to the person who does the dropping."
        ""
        "Example: You drop some rubbish in the park."
        ""
        "Enter this room's @drop message:"
      }list "\r" array_join
      'setStr { "_/dr" }list
    }list
 
    { "M6"
      "~&060[~&160M6~&060] @odrop Message:    ~&140%s"
      'getMPI { "_/odr" "~&040[Unset]~&R" }list
 
      {
        "The @drop and @odrop messages, when set on a room, are triggered when someone drops a program or thing type object in this room."
        "This message is shown to everyone else in the room, with the name of the dropper prepended to it."
        ""
        "Example: just dropped some rubbish in the park."
        ""
        "Enter this room's @odrop message:"
      }list "\r" array_join
      'setStr { "_/odr" }list
    }list
 
    "" "Exits" 4
 
    { "E1"
      "~&060[~&160E1~&060] New Exit"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setNewExit { }list
    }list
 
    { "E2"
      "~&060[~&160E2~&060] Recycle Exit"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setRecycleExit { }list
    }list
 
 
    { "E3"
      "~&060[~&160E3~&060] Edit Exit"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setEditExits { }list
    }list
 
    { "E4"
      "~&060[~&160E4~&060] Shown: ~&140%s"
      'getObvExits { "Yes" "~&110NO~&R" "~&040Unknown~&R" }list
 
      {
        "Do you want all exits without the DARK flag to be shown automatically when looking at the room? (y/n)"
      }list "\r" array_join
      'setObvExits { }list
    }list
 
    "" (* Blank line before footer *)
  }list
;
 
(#############################################################################)
(################################ EXIT TABLE #################################)
(#############################################################################)
: getExitTable (  -- a )
  {
    "" (* Blank line after header *)
    1
 
    { "N"
      "~&060[~&160N~&060]ame: ~&140%s"
      'getObjName { }list
 
      {
        "TIP: You can create aliases for this exit by putting semicolons in its name string.  For example, if you use '[O]ut;out;o' for the name, 'out', and 'o' will both trigger the exit, but only '[O]ut' will show in the obvious exists list."
        ""
        "Enter this exit's new name:"
      }list "\r" array_join
      'setObjName { }list
    }list
 
    2
 
    { "S"
      "~&060[~&160S~&060]ource: ~&140%s"
      'getSource { }list
 
      {
        "The source of an exit is the parent room to which it's attached.  If you attach an exit to an environment room, then all rooms contained within it, and the rooms within them, and so on, will be able to use the exit.  So either place the source of this exit in the environment room for your area to allow access anywhere in your area, or put it in the specific room you want an exit from."
        ""
        "Enter this exit's new source:"
      }list "\r" array_join
      'setSource { }list
    }list
 
    { "T"
      "~&060[~&160T~&060]arget: ~&140%s"
      'getObjLink { "~&110NOTHING!~&R" }list
 
      {
        "The destination of an exit is its target.  It can be another room, a thing object, a program, or a player.  In the case of a room, using the exit will teleport you to that room.  In the case of a program, using the exit will execute the program.  In the case of a thing object, using the exit will teleport the objet to you.  In the case of a player, using the exit will teleport you to that player."
        ""
        "Enter this exit's new target:"
        "WARNING: An unlinked exit may be claimed by anyone."
      }list "\r" array_join
      'setObjLink { }list
    }list
 
    4
 
    { "A"
      "~&060[~&160A~&060]bate: ~&140%s"
      'getFlag { "ABATE" "Yes" "No" }list
 
      {
        "When the ABATE flag is set on an exit, it causes the exit to run at a lower 'priority', meaning if another exit would normally be run when your exit is not present, then your exit is ignored.  Without this flag, exit priority is determined by whatever's closest to the person issuing the command.  There are also ways to set priorities even higher than normal, which are available to MUCK staff."
        ""
        "Set the ABATE flag on this exit? (y/n)"
      }list "\r" array_join
      'setFlag { "ABATE" }list
    }list
 
    { "D"
      "~&060[~&160D~&060]ark: ~&140%s"
      'getFlag { "DARK" "Yes" "No" }list
 
      {
        "If you set an exit DARK, it will not show up in the usual obvious exits output for the room it's in."
        "Some programs may also respond to the DARK flag on this exit."
        ""
        "Set the DARK flag on this exit? (y/n)"
      }list "\r" array_join
      'setFlag { "DARK" }list
    }list
 
    { "V"
      "~&060[~&160V~&060]ehicle: ~&140%s"
      'getFlag { "VEHICLE" "Yes" "No" }list
 
      {
        "To DISALLOW vehicles from using this exit, set the VEHICLE flag."
        ""
        "Set the VEHICLE flag on this exit? (y/n)"
      }list "\r" array_join
      'setFlag { "VEHICLE" }list
    }list
 
    { "Z"
      "~&060[~&160Z~&060]zombie: ~&140%s"
      'getFlag { "ZOMBIE" "Yes" "No" }list
 
      {
        "To DISALLOW zombies/puppets from using this exit, set the ZOMBIE flag."
        ""
        "Set the ZOMBIE flag on this exit? (y/n)"
      }list "\r" array_join
      'setFlag { "ZOMBIE" }list
    }list
 
    "" "Descriptions" 1
 
    { "{D1|D}"
      "~&060[~&160D1~&060] Description: ~&140%s"
      'getMPI     { "_/de" "~&110[Unset]~&R" }list
 
      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path' and use this field as a visual description of that entrance.  It's always best not to leave this on its defaults, if you're certian that this exit has no physical description, enter something like 'You can't see it' and possibly a description why."
        ""
        "Enter the visual description of this exit:"
      }list "\r" array_join
      'setMPIList { "_/de" "_/dl/desc" }list
    }list
 
    { "D2"
      "~&060[~&160D2~&060] Scent:       ~&140%s"
      'getMPI     { "_/scent" "~&110[Unset]~&R" }list
 
      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of that entrance's aroma."
        ""
        "Enter this exit's scent:"
      }list "\r" array_join
      'setMPIList { "_/scent" "_/dl/scent" }list
    }list
 
    { "D3"
      "~&060[~&160D3~&060] Texture:     ~&140%s"
      'getMPI     { "_/texture" "~&110[Unset]~&R" }list
 
      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of that entrance's feeling to the touch."
        ""
        "Enter this exit's texture:"
      }list "\r" array_join
      'setMPIList { "_/texture" "_/dl/texture" }list
    }list
 
    { "D4"
      "~&060[~&160D4~&060] flavor:      ~&140%s"
      'getMPI     { "_/flavor" "~&110[Unset]~&R" }list
 
      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of that entrance's flavor."
        ""
        "Enter this exit's flavor:"
      }list "\r" array_join
      'setMPIList { "_/flavor" "_/dl/flavor" }list
    }list
 
    { "D5"
      "~&060[~&160D5~&060] Aura:        ~&140%s"
      'getMPI     { "_/aura" "~&110[Unset]~&R" }list
 
      {
        "It's most effective to alias your exits to 'door' or 'archway' or 'path', etc.  and use this field as a description of the feeling this direction gives a character.  For example, 'you think it might be a bad idea to go that way' is very useful to the observant player."
        ""
        "Enter this exit's aura:"
      }list "\r" array_join
      'setMPIList { "_/aura" "_/dl/aura" }list
    }list
 
    { "D6"
      "~&060[~&160D6~&060] Sound:       ~&140%s"
      'getMPI { "_/sound" "~&110[Unset]~&R" }list
 
      {
        "Use this field to describe the sounds coming from the direction of the exit."
        ""
        "Enter this exit's sound:"
      }list "\r" array_join
      'setMPIList { "_/sound" "_/dl/sound" }list
    }list
 
    { "D7"
      "~&060[~&160D7~&060] Writing:     ~&140%s"
      'getMPI { "_/writing" "~&110[Unset]~&R" }list
 
      {
        "Use this field if there's writing on your exit.  For example 'Room 101' and 'Rented by xyz' are very useful to passers by."
        ""
        "Enter this exit's writing:"
      }list "\r" array_join
      'setMPIList { "_/writing" "_/dl/writing" }list
    }list
 
    "" "Messages" 2
 
    { "M1"
      "~&060[~&160M1~&060] @success Message:  ~&140%s"
      'getMPI { "_/sc" "~&110[Unset]~&R" }list
 
      {
        "This message is shown when anyone who uses this exit, to the person who uses it.  You should always set this on non-program exits."
        ""
        "Example: You go east"
        ""
        "Enter this exit's @success message:"
      }list "\r" array_join
      'setStr { "_/sc" }list
    }list
 
    { "M2"
      "~&060[~&160M2~&060] @osuccess Message: ~&140%s"
      'getMPI { "_/osc" "~&110[Unset]~&R" }list
 
      {
        "This message is shown when anyone uses this exit, to everyone else in the room.  You should always set this on non-program exits."
        ""
        "Example: goes east."
        ""
        "Enter this exit's @osuccess message:"
      }list "\r" array_join
      'setStr { "_/osc" }list
    }list
 
    { "M3"
      "~&060[~&160M3~&060] @fail Message:     ~&140%s"
      'getMPI { "_/fl" "~&110[Unset]~&R" }list
 
      {
        "This message is shown when someone tries to use an exit, but fails (because it's locked or otherwise), to the person who tried to use it. You should always set this on non-program exits."
        ""
        "Example: You can't go east because the door is locked."
        ""
        "Enter this exit's @fail message:"
      }list "\r" array_join
      'setStr { "_/fl" }list
    }list
 
    { "M4"
      "~&060[~&160M4~&060] @ofail Message:    ~&140%s"
      'getMPI { "_/ofl" "~&110[Unset]~&R" }list
 
      {
        "This message is shown when someone tries to use an exit, but fails (because it's locked or otherwise), to everyone else in the room. You should always set this on non-program exits."
        ""
        "Example: tries to go east but the door is locked."
        ""
        "Enter this exit's @ofail message:"
      }list "\r" array_join
      'setStr { "_/ofl" }list
    }list
 
    { "M5"
      "~&060[~&160M5~&060] @drop Message:     ~&140%s"
      'getMPI { "_/dr" "~&040[Unset]~&R" }list
 
      {
        "This message is shown to the person using the exit, when they arrive on the other side of the exit.  It's pretty much useless, as in order for this message to be sown, the @success message must have just shown as well.  There's little reason to se this."
        ""
        "Example: And now you've arrived on the other side."
        ""
        "Enter this exit's @drop message:"
      }list "\r" array_join
      'setStr { "_/dr" }list
    }list
 
    { "M6"
      "~&060[~&160M6~&060] @odrop Message:    ~&140%s"
      'getMPI { "_/odr" "~&110[Unset]~&R" }list
 
      {
        "This message is essential for every exit.  It's shown when someone using your exit has arrived on the other side, to everyone else on the other side.  It is crucial in order for people to understand where someone just came from, if they join you in the room."
        ""
        "Example: comes from the west."
        ""
        "Enter this exit's @odrop message:"
      }list "\r" array_join
      'setStr { "_/odr" }list
    }list
 
    ""
    { "{P|R|O}"
      "~&060Edit Parent %s"
      'getParent { "~&060[~&160R~&060]oom" "~&060[~&160P~&060]layer" "~&060[~&160O~&060]bject" }list
 
      {
      }list "\r" array_join
      'setParent { }list
    }list
  }list
;
 
(#############################################################################)
(############################### THING TABLE #################################)
(#############################################################################)
: getThingPrefTable (  -- a )
  {
    "" (* Blank line after header *)
    "Preferences" 2
    { "1"
      "~&060[~&1601~&060] Allowing 'hand':          ~&140%s"
      'getStrBool { "_hand/hand_ok" "Yes" "No" }list
 
      {
        "The 'hand' program by Wog is used to move an item from your inventory into someone else's.  However, it may not be preferable to allow people to hand your puppet objects.  Use your descresion."
        ""
        "Allow 'hand'ing of objects to this character? (y/n)"
      }list "\r" array_join
      'setStrBool { "_hand/hand_ok" }list
    }list
 
    { "2"
      "~&060[~&1602~&060] Showing @doing in whospe: ~&140%s"
      'getStrBool { "_prefs/wsseedoing" "Yes" "No" }list
 
      {
        "The whospe program displays species, gender, and status information about everyone in your current room.  If you want your puppet to optionally see a short 'Doing' string.  (The same string that's shown in the WHO command)  You may select it here."
        ""
        "Show @doing in whospe? (y/n)"
      }list "\r" array_join
      'setStrBool { "_prefs/wsseedoing" }list
    }list
 
    { "3"
      "~&060[~&1603~&060] Ride mode:                ~&140%s"
      'getStr { "ride/_mode" "Walk" }list
 
      {
        "The 'ride' program by Riss allows your puppet to be automatically led by another character or puppet, rather than having to follow them manually.  However, not everyone has a horse style back on which to ride.  Select your style of 'riding' from the list below."
        ""
      }list "\r" array_join
      'setStrPick { "ride/_mode" { "Ride" "Taur" "Paw" "Walk" "Hand" }list }list
    }list
 
    { "4"
      "~&060[~&1604~&060] Run 'saysetup'"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setExternal { #163 "saysetup" }list
    }list
 
    ""
    { "B"
      "~&060[~&160B~&060]ack to %s Edit"
      'getObject { "Room" "Player" "Object" }list
 
      {
      }list "\r" array_join
      'setDefaultMenu { }list
    }list
  }list
;
 
: getThingFlagsTable (  -- a )
  {
    "" "Flags" 1
 
    { "D"
      "~&060[~&160D~&060]ark:    ~&140%s"
      'getFlag { "DARK" "Yes ~&100(This object is hidden from 'contents' listings.)~&R" "No  ~&100(This object appears in 'contents' listings.)~&R" }list
 
      {
        "Use this flag to prevent your object from being shown in a 'contents' listing when looking at its container.  For example, it makes objects appear invisible when placed in rooms."
        ""
        "Set the DARK flag on this object? (y/n)"
      }list "\r" array_join
      'setFlag { "DARK" }list
    }list
 
    { "J"
      "~&060[~&160J~&060]ump_OK: ~&140%s"
      'getFlag { "JUMP_OK" "Yes ~&100(This object may be teleported freely.)~&R" "No  ~&100(This object may only be teleported by its controller.)~&R" }list
 
      {
        "Some programs made by lower-leveled programmers on the MUCK may wish to teleport your objects.  Setting the JUMP_OK flag on your object permits programs to teleport them."
        ""
        "Set the JUMP_OK flag on this object? (y/n)"
      }list "\r" array_join
      'setFlag { "JUMP_OK" }list
    }list
 
    { "S"
      "~&060[~&160S~&060]ticky:  ~&140%s"
      'getFlag { "STICKY" "Yes ~&100(This object goes home when it's dropped.)~&R" "No  ~&100(This object may be dropped.)~&R" }list
 
      {
        "To have an object get automatically sent home when dropped, set the STICKY flag on it.  This is useful for creating objects which you don't want to become lost in the muck when their users are no longer interested in them.  If you prefer to teleport your objects home manually, investigate the @find and @tel commands."
        ""
        "Set the STICKY flag on this object? (y/n)"
      }list "\r" array_join
      'setFlag { "STICKY" }list
    }list
 
    { "V"
      "~&060[~&160V~&060]ehicle: ~&140%s"
      'getFlag { "VEHICLE" "Yes ~&100(You can climb into this object.)~&R" "No  ~&100(This object doesn't hold players.)~&R" }list
 
      {
        "When an object has the VEHICLE flag, it allows players to climb inside of the object, by using an exit placed on the vehcile, linked to the vehicle.  Also, it allows the occupents of the vehicle to hear what's going on outside.  (But not vice-versa)"
        ""
        "Set the VEHICLE flag on this object? (y/n)"
      }list "\r" array_join
      'setFlag { "VEHICLE" }list
    }list
 
    { "Z"
      "~&060[~&160Z~&060]ombie:  ~&140%s"
      'getFlag { "ZOMBIE" "Yes ~&100(This object simulates a player.)~&R" "No  ~&100(This object does not simualte a player.)~&R" }list
 
      {
        "When an object has the ZOMBIE flag, it simulates a player object.  Some programs will begin to treat it as a player (such as whospe), and you can give it preferences, attributes, a sex and a gender.  Also, on MUCKs configured to allow zombies, anything the zombie hears will be automatically broadcasted to the object's owner.  Allowing you to use it as a player with the @force command.  See 'help force' for more details.  (Zombies are also known as 'puppets' or 'pets')"
        ""
        "Set the ZOMBIE flag on this object? (y/n)"
      }list "\r" array_join
      'setFlag { "ZOMBIE" }list
    }list
 
 
    ""
    { "{P|B}"
      "~&060[~&160B~&060]ack to Object Edit"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourThingTable }list
    }list
  }list
;
 
: getThingTable (  -- a )
  {
    "" (* Blank line after header *)
    2
 
    { "N"
      "~&060[~&160N~&060]ame: ~&140%s"
      'getObjName { }list
 
      {
        "Enter this object's new name:"
      }list "\r" array_join
      'setObjName { }list
    }list
 
    { "H"
      "~&060[~&160H~&060]ome: ~&140%s"
      'getObjLink { "~&110Nowhere?!~&R" }list
 
      {
        "An object's 'home' is where it's sent when the server isn't sure where to put it.  For example, if it's contained in a room that gets recycled, or it's swept with the 'sweep' command, it will be sent to its home.  A thing's home can be a player, room, or another object."
        ""
        "Enter this object's new home:"
      }list "\r" array_join
      'setObjLink { }list
    }list
 
    { "1"
      "~&060[~&1601~&060] Species: ~&140%s"
      'getStr     { "_/species" "~&040[Unset]~&R" }list
 
      {
        "Your species is the type of being your puppet/object is.  This has little meaning unless this object has the ZOMBIE flag turned on."
        "To avoid confusion, pleased prefix the species name with 'Anthro ' if this puppet/object is anthropomorphic."
        ""
        "Enter the species of this puppet/object:"
      }list "\r" array_join
      'setStr     { "_/species" }list
    }list
 
    { "2"
      "~&060[~&1602~&060] Gender: ~&140%s"
      'getStr     { "gender_prop" sysparm "~&040[Unset]~&R" }list
 
      {
        "The sex flag is used for objects with the ZOMBIE flag, as well as for any other reason an object would need pronoun substitution.  For example, you may want to set this to 'Neuter' if you want its pronouns to come up as 'it/its/etc' when you use the smell command on it."
        "The system recognizes the values 'Male', 'Female', 'Herm', 'Hermaphrodite', and 'Neuter'.  However, you're free to enter whatever you want."
        ""
        "Enter the gender of this puppet/object:"
      }list "\r" array_join
      'setStr     { "gender_prop" sysparm }list
    }list
 
    "" "Descriptions" 1
 
    { "{D1|D}"
      "~&060[~&160D1~&060] Description: ~&140%s"
      'getMPI     { "_/de" "~&110[Unset]~&R" }list
 
      {
        "If this object is a zombie, you should enter a description in the same way you would enter a player description.  Otherwise, simply give a general description of the visual appearance of this object.  Also, if this object has any exits attached, you may want to put a short description of how to access its commands here."
        ""
        "Enter the visual description of this object:"
      }list "\r" array_join
      'setMPIList { "_/de" "_/dl/desc" }list
    }list
 
    { "D2"
      "~&060[~&160D2~&060] Scent:       ~&140%s"
      'getMPI     { "_/scent" "~&110[Unset]~&R" }list
 
      {
        "This is where you enter the object's aroma.  You can see an object/room/exit/player/program's scent with the 'smell' command."
        ""
        "Enter this object's scent:"
      }list "\r" array_join
      'setMPIList { "_/scent" "_/dl/scent" }list
    }list
 
    { "D3"
      "~&060[~&160D3~&060] Texture:     ~&140%s"
      'getMPI     { "_/texture" "~&110[Unset]~&R" }list
 
      {
        "This is where you enter the object's feeling to the touch.  You can see an object/room/exit/player/program's texture with the 'feel' command."
        ""
        "Enter this object's texture:"
      }list "\r" array_join
      'setMPIList { "_/texture" "_/dl/texture" }list
    }list
 
    { "D4"
      "~&060[~&160D4~&060] flavor:      ~&140%s"
      'getMPI     { "_/flavor" "~&110[Unset]~&R" }list
 
      {
        "This is where you enter the object's sensation to the taste.  You can see an object/room/exit/player/program's flavor with the 'taste' command."
        ""
        "Enter this object's flavor:"
      }list "\r" array_join
      'setMPIList { "_/flavor" "_/dl/flavor" }list
    }list
 
    { "D5"
      "~&060[~&160D5~&060] Aura:        ~&140%s"
      'getMPI     { "_/aura" "~&110[Unset]~&R" }list
 
      {
        "This is where you enter the feeling which the object gives a character.  For example 'That thing looks scary!', or 'Perhaps it's not a useful as it looks' are very good aura descriptions.  You can see an object/room/exit/player/program's aura with the 'sense' command."
        ""
        "Enter this object's aura:"
      }list "\r" array_join
      'setMPIList { "_/aura" "_/dl/aura" }list
    }list
 
    { "D6"
      "~&060[~&160D6~&060] Sound:       ~&140%s"
      'getMPI { "_/sound" "~&040[Unset]~&R" }list
 
      {
        "Use this field only if the object makes sounds, and enter a short description of the noises it makes.  You can see an object/room/exit/player/program's sound with the 'hear' command."
        ""
        "Enter this object's sound:"
      }list "\r" array_join
      'setMPIList { "_/sound" "_/dl/sound" }list
    }list
 
    { "D7"
      "~&060[~&160D7~&060] Writing:     ~&140%s"
      'getMPI { "_/writing" "~&040[Unset]~&R" }list
 
      {
        "If anything is written on your object, enter it here.  For example 'Made in Japan', or 'Property of xyz'.  You can see an object/room/exit/player/program's writing with the 'read' command."
        ""
        "Enter this object's writing:"
      }list "\r" array_join
      'setMPIList { "_/writing" "_/dl/writing" }list
    }list
 
    "" "Messages" 2
 
    { "M1"
      "~&060[~&160M1~&060] @success Message:  ~&140%s"
      'getMPI { "_/sc" "~&110[Unset]~&R" }list
 
      {
        ""
        "Example: You pick up {name:this}."
        ""
        "Enter this object's @success message:"
      }list "\r" array_join
      'setStr { "_/sc" }list
    }list
 
    { "M2"
      "~&060[~&160M2~&060] @osuccess Message: ~&140%s"
      'getMPI { "_/osc" "~&110[Unset]~&R" }list
 
      {
        ""
        "Example: picks up {name:this}."
        ""
        "Enter this object's @osuccess message:"
      }list "\r" array_join
      'setStr { "_/osc" }list
    }list
 
    { "M3"
      "~&060[~&160M3~&060] @fail Message:     ~&140%s"
      'getMPI { "_/fl" "~&110[Unset]~&R" }list
 
      {
        ""
        "Example: You try to pick up {name:this} but it's glued to the floor."
        ""
        "Enter this object's @fail message:"
      }list "\r" array_join
      'setStr { "_/fl" }list
    }list
 
    { "M4"
      "~&060[~&160M4~&060] @ofail Message:    ~&140%s"
      'getMPI { "_/ofl" "~&110[Unset]~&R" }list
 
      {
        ""
        "Example: tries to pick up {name:this} but it's glued to the floor."
        ""
        "Enter this object's @ofail message:"
      }list "\r" array_join
      'setStr { "_/ofl" }list
    }list
 
    { "M5"
      "~&060[~&160M5~&060] @drop Message:     ~&140%s"
      'getMPI { "_/dr" "~&110[Unset]~&R" }list
 
      {
        ""
        "Example: You toss the {name:this} onto the floor."
        ""
        "Enter this object's @drop message:"
      }list "\r" array_join
      'setStr { "_/dr" }list
    }list
 
    { "M6"
      "~&060[~&160M6~&060] @odrop Message:    ~&140%s"
      'getMPI { "_/odr" "~&110[Unset]~&R" }list
 
      {
        ""
        "Example: tosses a {name:this} onto the floor."
        ""
        "Enter this object's @odrop message:"
      }list "\r" array_join
      'setStr { "_/odr" }list
    }list
 
    "" "Settings" 3
 
    { "S1"
      "~&060[~&160S1~&060] Preferences"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourThingPrefTable }list
    }list
 
    { "S2"
      "~&060[~&160S2~&060] Attributes"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourAttrTable }list
    }list
 
    { "{S3|F}"
      "~&060[~&160F~&060]lags"
      'getNull { }list
 
      {
      }list "\r" array_join
      'setMenu { ourThingFlagsTable }list
    }list
 
    "" (* Blank line before footer *)
  }list
;
 
(#############################################################################)
(############################## PROGRAM TABLE ################################)
(#############################################################################)
: getProgramTable (  -- a )
  {
  }list
;

(* ------------------------------------------------------------------------- *)
 
: doMenuHeader (  --  )
 
  "~&170----~&040[ ~&130Object Editor~&040 ]~&170" dup ansi_strlen .chars-per-row swap - "-" * strcat
  ourObject @ unparseobj
 
  dup ansi_strlen .chars-per-row 20 - <= if
    "~&040[ ~&R" swap strcat "~&040 ]~&170----" strcat
     dup ansi_strlen .chars-per-row swap - rot swap ansi_strcut pop swap strcat
  else
    "\r~&RObject: " swap strcat strcat
  then
 
  ansi-tell
;
 
: doMenuFooter (  --  )
  "~&040[ ~&070" prog name strcat .version strcat prog "L" flag? prog "V" flag? or if " (#" strcat prog intostr strcat ")" strcat then " -- by " strcat .author strcat "~&040 ]~&170----" strcat
 
  "~&170" "-" .chars-per-row * strcat over ansi_strlen .chars-per-row swap - ansi_strcut pop swap strcat
 
  ansi-tell
;
 
: drawSeparator ( s -- s )
  dup not if
    pop " "
  else
    "~&170-----~&040[ ~&060" swap strcat "~&040 ]~&170" strcat "-" .chars-per-row * strcat
    .chars-per-row ansi_strcut pop
  then
;
 
: drawItem ( a -- s )
  (* Get 'get' string. *)
  dup 1 [] over 2 [] rot 3 []
 
  array_vals ++ rotate execute
 
  (* Substitute 'get' string *)
  "%s" subst
;
 
: doMenu (  --  )
  0  var! item_on_row   (* The current item on the row *)
  2  var! items_per_row (* The current max number of items per row *)
  "" var! row_string    (* The string data of the row *)
 
  doMenuHeader
 
  ourTable @ foreach
    swap pop
 
    (* Handle items_per_row changes *)
    dup int? if
      (* Flush the current row if we're on it. *)
      item_on_row @ if
        row_string @ ansi-tell
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
        row_string @ ansi-tell
        "" row_string !
        0 item_on_row !
      then
 
      (* Draw a separator *)
      drawSeparator ansi-tell
 
      continue
    then
 
    (* Handle item entries *)
    dup array? if
      (* Get the item *)
      drawItem
 
      (* Pad with required spaces *)
      .chars-per-row items_per_row @ / over ansi_strlen over >= if
        4 - ansi_strcut pop "~&R ..." strcat
      else
        over ansi_strlen -
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
        row_string @ ansi-tell
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
    row_string @ ansi-tell
    "" row_string !
    0 item_on_row !
  then
  doMenuFooter
;
 
: doSet ( a --  )
  dup 5 [] over 6 [] rot 4 []
 
  (* Display help string *)
  ansi-tell
 
  (* Get value *)
  array_vals ++ rotate execute
;
 
: doEdit (  --  )
  0 var! nomatch
 
  begin
    doMenu
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
    ourTable @ foreach
      swap pop
 
      dup array? if
        over over 0 [] smatch if
          doSet
          0 nomatch !
          pop break
        then
      then
 
      pop
    repeat
  repeat
 
  ">> Editor exited." .tell
;
 
: initTables (  --  )
 
  (* Not very elegant I know.. *)
  getPlayerPrefTable    ourPlayerPrefTable !
  getAttrTable          ourAttrTable       !
  getMorphTable         ourMorphTable      !
  getPronounTable       ourPronounTable    !
  getPlayerTable        ourPlayerTable     !
  getRoomFlagsTable     ourRoomFlagsTable  !
  getRoomTable          ourRoomTable       !
  getThingPrefTable     ourThingPrefTable  !
  getThingFlagsTable    ourThingFlagsTable !
  getThingTable         ourThingTable      !
  getExitTable          ourExitTable       !
  getProgramTable       ourProgramTable    !
 
  setDefaultMenu
;
 
(*****************************************************************************)
(*                       M-CMD-AT_EDITOBJECT-SaveMorph                       *)
(*****************************************************************************)
: M-CMD-AT_EDITOBJECT-SaveMorph[ str:morph_name bool:quiet -- bool:success? ]
  NEEDSM3

  morph_name @ initialCaps "_" " " subst morph_name !

  "me" match ourObject !
  morph_name @ 1 quiet @ doMorph
;
PUBLIC M-CMD-AT_EDITOBJECT-SaveMorph
$LIBDEF M-CMD-AT_EDITOBJECT-SaveMorph

(*****************************************************************************)
(*                       M-CMD-AT_EDITOBJECT-LoadMorph                       *)
(*****************************************************************************)
: M-CMD-AT_EDITOBJECT-LoadMorph[ str:morph_name bool:quiet -- bool:success? ]
  NEEDSM3

  morph_name @ initialCaps "_" " " subst morph_name !

  "me" match ourObject !
  morph_name @ 0 quiet @ doMorph
;
PUBLIC M-CMD-AT_EDITOBJECT-LoadMorph
$LIBDEF M-CMD-AT_EDITOBJECT-LoadMorph

(*****************************************************************************)
(*                      M-CMD-AT_EDITOBJECT-ListMorphs                       *)
(*****************************************************************************)
: M-CMD-AT_EDITOBJECT-ListMorphs[  --  ]
  NEEDSM2

  "me" match ourObject !
  setListMorph
;
PUBLIC M-CMD-AT_EDITOBJECT-ListMorphs
$LIBDEF M-CMD-AT_EDITOBJECT-ListMorphs

(*****************************************************************************)
(*                      M-CMD-AT_EDITOBJECT-EditObject                       *)
(*****************************************************************************)
: M-CMD-AT_EDITOBJECT-EditObject[ str:objname -- bool:editopened? ]
  NEEDSM2

  objname @ 1 1 1 1 M-LIB-MATCH-Match
  dup not if
    pop 0 exit
  then
 
  dup chkPerms not if
    pop "Permission denied." .tell 0 exit
  then
 
  ourObject !
 
  (* Initialize globals *)
  initTables
 
  doEdit
  1
;
PUBLIC M-CMD-AT_EDITOBJECT-EditObject
$LIBDEF M-CMD-AT_EDITOBJECT-EditObject

(* ------------------------------------------------------------------------- *)

: help ( --  )
  .header
  {
    { "Use '" command @ " <object name>' to bring up an object editing dialog." }join
    "You can edit players, rooms, things, exits, etc."
    " "
    "Try editing 'me' or 'here'."
  }tell
  prog "VIEWABLE" flag? if
    "Type '" prog "_docs" getpropstr not if "@list #" else "@view #" then
    strcat prog intostr strcat "' for more information." strcat .tell
  then
  .footer 
;
 
: main
  dup not if
    { "Use '" command @ " <object>' to edit objects." }join .tell
    pop exit
  then

  "#help" over stringpfx if pop help exit then

  M-CMD-AT_EDITOBJECT-EditObject pop
;
.
c
q
@register m-cmd-@editobject.muf=m/cmd/at_editobject
@set $m/cmd/at_editobject=L
@set $m/cmd/at_editobject=M3
@set $m/cmd/at_editobject=W
@set $m/cmd/at_editobject=V

