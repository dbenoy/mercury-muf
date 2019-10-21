!@program m-cmd-@map.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@map.muf - $m/cmd/at_map                                            *)
(*    A program for displaying a map with a marker whose position is         *)
(*    dynamically determined depending on which room you're in when you      *)
(*    issue the map command.                                                 *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o Your current location is identified by an 'X' or a marker of your     *)
(*     choice.                                                               *)
(*   o Maps may be stored in an environment room and you can edit the map    *)
(*     from any room in the environment.                                     *)
(*   o Stores a global list of maps which you can view at any time.          *)
(*   o Rooms may be marked on multiple maps. So you can make 'maps within    *)
(*     maps.'                                                                *)
(*   o Maps can be made in color, using MCC color codes.                     *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_MAP-display[ ref:map_room ref:mark_room -- bool:success? ]     *)
(*     Shows the map of map_room (Its closest environment map). mark_room is *)
(*     which room will receieve the X marker on that map. Use #-1 to not     *)
(*     show a marker.                                                        *)
(*                                                                           *)
(*   M-CMD-AT_MAP-edit[ ref:env_room -- bool:success? ]                      *)
(*     Shows an editing dialog for the map of env_room.                      *)
(*                                                                           *)
(*   M-CMD-AT_MAP-env_get[ ref:map_room -- ref:env_room ]                    *)
(*     Given an object, find which environment room has its map. #-1 if no   *)
(*     map is available.                                                     *)
(*                                                                           *)
(*   M-CMD-AT_MAP-match[ str:map_name -- ref:object ]                        *)
(*     Like the MATCH primitive, but it takes the object that matches, and   *)
(*     returns the environment room of that object's map. You must control   *)
(*     the object that maps in order to see its environment room, unless the *)
(*     match is for a global map registered with M-CMD-AT_MAP-reg_add.       *)
(*                                                                           *)
(*   M-CMD-AT_MAP-position[ ref:env_room ref:mark_room -- bool:success? ]    *)
(*     Shows an editing dialog for you to mark the position of mark_room on  *)
(*     the map in env_room.                                                  *)
(*                                                                           *)
(*   M-CMD-AT_MAP-reg_add[ str:map_name ref:env_room -- bool:success? ]      *)
(*     Registers a map name globally. Registered map names can be listed,    *)
(*     and can always be viewed with @map <name>.                            *)
(*                                                                           *)
(*   M-CMD-AT_MAP-reg_del[ ref:env_room -- bool:success? ]                   *)
(*     Removes the map in env_room from the list of registered names created *)
(*     by M-CMD-AT_MAP-reg_add.                                              *)
(*                                                                           *)
(*   M-CMD-AT_MAP-reg_get[ -- dict:global_maps ]                             *)
(*     Returns a dict of registered names created by M-CMD-AT_MAP-reg_add,   *)
(*     keyed by dbrefs of the environment room for each name in string form. *)
(*                                                                           *)
(*   M-CMD-AT_MAP-remove[ ref:map_room -- bool:success? ]                    *)
(*     Deletes the map of map_room (Its closest environment map).            *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   Maps are stored as a 'list' type property named _map.                   *)
(*   This program ascends the environment tree to find the _map list, and    *)
(*   it's displayed, supporting MCC color codes.                             *)
(*                                                                           *)
(*   The position of the current room is stored as x/y coordinates in        *)
(*   _mapx/num, and _mapy/num, where 'num' is the dbref of the map on which  *)
(*   the position mark is placed.  (Without the '#' sign). This is also      *)
(*   ascended up the environment tree, so you can have on environment room   *)
(*   within another, and you can set the position of the child environment   *)
(*   room within the parent's map.  Thus allowing you to put a map within a  *)
(*   map.                                                                    *)
(*                                                                           *)
(*   For example:                                                            *)
(*     World Environment Room (#51) (Parent: #0)                             *)
(*       _map#/<a map of the world>                                          *)
(*                                                                           *)
(*     Country X Environment Room (#79) (Parent: #51)                        *)
(*       _map#/<a map of country X>                                          *)
(*       _mapx/51:<x coordinate of the country's location in the world>      *)
(*       _mapy/51:<y coordinate of the country's location in the world>      *)
(*                                                                           *)
(*     Provence Z Environment Room (#105) (Parent: #79)                      *)
(*       _map#/<a map of provence Z>                                         *)
(*       _mapx/79:<x coordinate of the provence's location in the country>   *)
(*       _mapy/79:<y coordinate of the provence's location in the country>   *)
(*                                                                           *)
(*     City Q Environment Room (#117) (Parent: #105)                         *)
(*       _map#/<a map of City Q>                                             *)
(*       _mapx/105:<x of city in provence>                                   *)
(*       _mapy/105:<y of city in provence>                                   *)
(*       _mapx/79:<OVERRIDE OF PROVENCE'S LOCATION IN COUNTRY, X>            *)
(*       _mapx/79:<OVERRIDE OF PROVENCE'S LOCATION IN COUNTRY, Y>            *)
(*                                                                           *)
(*     City Q General Hospital Environment Room (#1056) (Parent: #117)       *)
(*       _mapx/117:<hospital's x in city>                                    *)
(*       _mapy/117:<hospital's y in city>                                    *)
(*                                                                           *)
(*     If 'map' is issued in a child room of 'hospital' it will look in look *)
(*     up the tree for the closest _map.  Which is City Q (assuming the room *)
(*     itself doesn't have a _map), and it will display that map.  It will   *)
(*     then look up the tree for the coordinates for the map room's dbref    *)
(*     (117).  Assuming they're not directly in the room, it will find those *)
(*     coordinates in the hospital environment room.                         *)
(*                                                                           *)
(*     If a wizard created Provence Z's environment room, it might have been *)
(*     added to the global map list.  If so, you could stand inside the      *)
(*     hospital and ask for that map by name.  In which case, it would       *)
(*     ascend the environment tree looking for Provence Z's dbref (105)      *)
(*     instead of City Q's (117).  In that case, it'd probably find it in    *)
(*     City Q, so you'd see an X on City Q's location if you asked for a map *)
(*     of Provence Z while standing in the hospital.                         *)
(*                                                                           *)
(*     Also, if you issued a request for country x's map then you'd get      *)
(*     overriden by any environment that happens to be closer down the       *)
(*     environmnet to where you're standing.                                 *)
(*                                                                           *)
(* TODO:                                                                     *)
(*   @map #marker <-- Change the marker for the current area                 *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.2 -- Daniel Benoy -- October, 2019                            *)
(*     - Modified for inclusion in mercury-muf                               *)
(*   Version 1.1 -- Daniel Benoy -- May, 2004                                *)
(*     - Removed all jmap.muf code and replaced it with original code. (to   *)
(*       change the license to GPLv2)                                        *)
(*     - Created public functions for accessing map displaying routines      *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*     - Derived from jmap.muf v0.1 by Jessy@FurryMUCK                       *)
(*     - Added color support                                                 *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004  Daniel Benoy                                          *)
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
$VERSION 1.002
$AUTHOR  Daniel Benoy
$NOTE    Area map displaying program.

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/string
$INCLUDE $m/lib/color
$INCLUDE $m/lib/theme
$INCLUDE $m/cmd/at_lsedit

(* ------------------------------------------------------------------------- *)

: M-HELP-desc ( d -- s )
  pop
  "Manage area maps."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop var! action_name
  {
    action_name @ toupper
    "  A utility for creating and displaying area maps."
    " "
    { "  " action_name @ tolower " ......................... Display map of current area" }join
    { "  " action_name @ tolower " <map> ................... Display <map>" }join
    { "  " action_name @ tolower " #list ................... Display list of available maps" }join
    { "  " action_name @ tolower " #create <env room>....... Create a map in the given environment room" }join
    { "  " action_name @ tolower " #wizcreate <env room>.... Same as #create, but also add to the list of maps" }join
    { "  " action_name @ tolower " #edit ................... Edit current map" }join
    { "  " action_name @ tolower " #edit <map> ............. Edit some other map" }join
    { "  " action_name @ tolower " #remove ................. Remove current map" }join
    { "  " action_name @ tolower " #remove <map> ........... Remove some other map" }join
    { "  " action_name @ tolower " #position ............... Set position of current room on its map" }join
    { "  " action_name @ tolower " #position <map> ......... Set position of current room on another map" }join
  }list
;
WIZCALL M-HELP-help

: cmd_help2 (  --  )
  {
    "To create a map for your area, prepare an ascii drawing, (preferably in a text file, and approximately 79 by 24 characters in size), and an environment room for your area.  Also, give it the ABODE flag with '@set <envroom dbref>=A"
    " "
    "To create an environment room, simply @dig or otherwise create a room, and then 'teleport' your other rooms into it, by standing in the room to be teleported and entering @tel here=<dbref of environment room>"
    " "
    "Once you create an environment room, (or if you have one already), teleport yourself into it with @tel me=<dbref of environment room>  (If you forget your environment room's dbref, try @find) and run '$com #create' to create a map and store it in the environment room.  From then on, if you wish to change your map you can run '$com #edit' from any room under that environment." command @ "$com" subst
    " "
    "However, before you leave your environmeny room, and if your MUCK supports it, please register this area's position within the map of the area it's inside.  (i.e. Put an X for this area on the map of the whole city.)"
    "To see if your MUCK supports this, run map #list and look for the area in which your area resides on the list.  Then (while you're still in the environment) run '$com #position' and enter the appropriate name of the parent map." command @ "$com" subst
    " "
    "Next, go to each room in your area and run '$com #position' while standing in it.  Enter 'here' when prompted for which map you want to mark." command @ "$com" subst
  }tell
;

: maptell ( s --  )
  dup .color_tell
  me @ thing? me @ "VEHICLE" flag? and if
    dup me @ "_/oecho" getpropstr dup not if pop "Outside>" then " " strcat swap strcat me @ { me @ }list M-LIB-COLOR-cast_to
  else
    pop
  then
;

: chk_abort ( s --  )
  ".abort" stringpfx if
    "Aborted!" command @ .theme_tag .color_tell
    pid kill
  then
;

: doRead  (  -- s )
  begin
    read

    dup if
      dup "{\"|:|say |pose }*" smatch if
        .me swap force
        continue
      then
    then

    break
  repeat
;

: read_yes_no (  -- b )
  begin
    doRead

    "yes" over stringpfx if
      pop 1 break
    then

    "no" swap stringpfx if
      0 break
    then

    ".abort" swap stringcmp if
      0 break
    then

    "Please enter 'Yes' or 'No'." command @ toupper .theme_tag .color_tell
  repeat
;

: map_name_get ( d -- s )
  dup "_map#" envpropstr if
    prog "_maps/" rot intostr strcat getpropstr
  else
    pop ""
  then
;

: map_env_get ( d -- d' )
  "_map#" envpropstr number? not if
    pop #-1 exit (* D'oh!  No map! *)
  then
;

: marker_get (  -- s )
  "[#FF5F5F]X"
;

(* ------------------------------------------------------------------------- *)

(*****************************************************************************)
(*                           M-CMD-AT_MAP-display                            *)
(*****************************************************************************)
: M-CMD-AT_MAP-display[ ref:map_room ref:mark_room -- bool:success? ]
  (* M1 OK *)
  map_room @ dbref? not if "Non-dbref argument (1)." abort then
  mark_room @ dbref? not if "Non-dbref argument (2)." abort then

  var my_x
  var my_y
  0 var! my_is_marked

  (* Change map_room into the room that actually contains the map *)
  map_room @ map_env_get map_room !

  map_room @ not if
    (* D'oh!  No map! *)
    0 exit
  then

  mark_room @ if
    (* Get the location of map_room on the map *)
    mark_room @ "_mapx/" map_room @ intostr strcat envpropstr atoi my_x !
    mark_room @ "_mapy/" map_room @ intostr strcat envpropstr atoi my_y ! and if
      1 my_is_marked !
    else
      mark_room @ "_mapy" getpropstr dup my_y !
      mark_room @ "_mapx" getpropstr dup my_x ! and if
        1 my_is_marked !
      then
    then
  then

  map_room @ "_map#" getpropstr atoi
  1 begin
    over over >= while
    "_map#/" over intostr strcat map_room @ swap getpropstr

    my_is_marked @ if (* Show marker if applicable *)
      over my_y @ = if
        my_x @ .color_strcut
        swap dup .color_strlen -- .color_strcut pop marker_get .color_strcat swap
        .color_strcat
      then
    then

    maptell
    ++
  repeat
  pop pop

  1
;
PUBLIC M-CMD-AT_MAP-display
$LIBDEF M-CMD-AT_MAP-display

(*****************************************************************************)
(*                             M-CMD-AT_MAP-edit                             *)
(*****************************************************************************)
: M-CMD-AT_MAP-edit[ ref:env_room -- bool:success? ]
  .needs_mlev3
  env_room @ dbref? not if "Non-dbref argument (1)." abort then

  { "You are now editing the map in environment room " env_room @ unparseobj "." }join command @ toupper .theme_tag .color_tell
  "You can get help by entering '.h' on a line by itself." command @ toupper .theme_tag .color_tell
  "'.end' will save and exit." command @ toupper .theme_tag .color_tell
  "'.abort' will abort any changes." command @ toupper .theme_tag .color_tell
  "To save changes and continue editing, use '.save'." command @ toupper .theme_tag .color_tell
  env_room @ "_map" M-CMD-AT_LSEDIT-ListEdit
  dup not if
    "Aborted!" command @ toupper .theme_tag .color_tell
  then
;
PUBLIC M-CMD-AT_MAP-edit
$LIBDEF M-CMD-AT_MAP-edit

: M-CMD-AT_MAP-position[ ref:env_room ref:mark_room -- bool:success? ]
  .needs_mlev3
  env_room @ dbref? not if "Non-dbref argument (1)." abort then
  mark_room @ dbref? not if "Non-dbref argument (2)." abort then

  (* TODO: Draw upper guide *)
  0 var! max_x
  0 var! max_y

  env_room @ "_map#" getpropstr atoi dup max_y !
  1 begin
    over over >= while
    "_map#/" over intostr strcat env_room @ swap getpropstr

    dup .color_strlen max_x @ > if
      dup .color_strlen max_x !
    then

    over intostr "   " over strlen strcut swap pop swap strcat " " strcat swap .color_strcat .color_tell
    ++
  repeat
  pop pop

  (* Draw X axis guide *)
  "    " 1 begin
    dup max_x @ <= while

    dup 10 / intostr rot swap strcat swap

    ++
  repeat
  pop
  .tell

  "    " 1 begin
    dup max_x @ <= while

    dup 10 % intostr rot swap strcat swap

    ++
  repeat
  pop
  .tell

  (* Ask for coordinates *)
  begin
    "What is this room's column number on the map?" command @ toupper .theme_tag .color_tell
    "[Enter column number, or .abort to quit]" command @ toupper .theme_tag .color_tell
    doRead strip
    dup chk_abort
    dup number? not if
      "Sorry, that's not a number." command @ toupper .theme_tag .color_tell
      pop continue
    then

    atoi dup 0 <= swap max_x @ > or if
      "Invalid entry: the column number must be between 1 and " max_x @ intostr strcat "." strcat command @ toupper .theme_tag .color_tell
      pop continue
    then

    mark_room @ "_mapx/" env_room @ intostr strcat rot setprop break
  repeat

  begin
    "What is this room's row number on the map?" command @ toupper .theme_tag .color_tell
    "[Enter column number, or .abort to quit]" command @ toupper .theme_tag .color_tell
    doRead strip
    dup chk_abort
    dup number? not if
      "Sorry, that's not a number." command @ toupper .theme_tag .color_tell
      pop continue
    then

    atoi dup 0 <= swap max_y @ > or if
      "Invalid entry: the column number must be between 1 and " max_y @ intostr strcat "." strcat command @ toupper .theme_tag .color_tell
      pop continue
    then

    mark_room @ "_mapy/" env_room @ intostr strcat rot setprop break
  repeat

  "Set." command @ toupper .theme_tag .color_tell
  1
;

(*****************************************************************************)
(*                           M-CMD-AT_MAP-env_get                            *)
(*****************************************************************************)
: M-CMD-AT_MAP-env_get[ ref:map_room -- ref:env_room ]
  (* M1 OK *)
  map_room @ dbref? not if "Non-dbref argument (1)." abort then
  map_room @ map_env_get
;
PUBLIC M-CMD-AT_MAP-env_get
$LIBDEF M-CMD-AT_MAP-env_get

(*****************************************************************************)
(*                             M-CMD-AT_MAP-match                            *)
(*****************************************************************************)
: M-CMD-AT_MAP-match[ str:map_name -- ref:object ]
  (* M1 OK *)
  map_name @ string? not if "Non-string argument (1)." abort then

  map_name @ "#" stringpfx if
    map_name @ 1 strcut swap pop
    dup number? not if
      pop #-1 exit
    then
    stod

    dup if
      "me" match over controls not if (* You can't view other people's maps by dbref *)
        pop #-1 exit
      then
    then
    exit
  then

  map_name @ "$" stringpfx if
    map_name @ match

    dup if
      "me" match over controls not if (* You can't view other people's maps by $name *)
        pop #-1 exit
      then
    then
    exit
  then

  map_name @ "*" stringpfx if
    map_name @ 1 strcut swap pop
    pmatch

    dup if
      "me" match over controls not if (* You can't view the map of a player unless you control them *)
        pop #-1 exit
      then
    then
    exit
  then

  prog "_maps/" nextprop begin
    dup while
    prog over getpropstr map_name @ instring if
      "" "_maps/" subst
      dup number? not if
        pop #-1 exit
      then
      stod exit
      break
    then
    prog swap nextprop
  repeat

  map_name @ match dup ok? not if pop #-1 then
  dup if
    "me" match over controls not if (* You can't view the map of the match unless you control the result *)
      pop #-1 exit
    then
  then
;
PUBLIC M-CMD-AT_MAP-match
$LIBDEF M-CMD-AT_MAP-match

(*****************************************************************************)
(*                           M-CMD-AT_MAP-reg_add                            *)
(*****************************************************************************)
: M-CMD-AT_MAP-reg_add[ str:map_name ref:env_room -- bool:success? ]
  .needs_mlev3
  map_name @ string? not if "Non-string argument (1)." abort then
  map_name @ prop-name-ok? not if "Invalid map name (1)." abort then
  map_name @ "/" instr map_name @ "~" instr 1 = or map_name @ "@" instr 1 = or if "Invalid map name (1)." abort then
  map_name @ "{here|home|me|nil}" smatch if "Invalid map name (1)." abort then
  env_room @ dbref? not if "Non-dbref argument (2)." abort then

  env_room @ not if
    0 exit
  then

  prog "_maps/" env_room @ intostr strcat map_name @ setprop

  1
;
PUBLIC M-CMD-AT_MAP-reg_add
$LIBDEF M-CMD-AT_MAP-reg_add

(*****************************************************************************)
(*                           M-CMD-AT_MAP-reg_del                            *)
(*****************************************************************************)
: M-CMD-AT_MAP-reg_del[ ref:env_room -- bool:success? ]
  .needs_mlev3
  env_room @ dbref? not if "Non-dbref argument (1)." abort then

  env_room @ not if
    0 exit
  then

  prog "_maps/" env_room @ intostr strcat getprop not if
    0 exit
  then

  prog "_maps/" env_room @ intostr strcat remove_prop

  1
;
PUBLIC M-CMD-AT_MAP-reg_del
$LIBDEF M-CMD-AT_MAP-reg_del

(*****************************************************************************)
(*                           M-CMD-AT_MAP-reg_get                            *)
(*****************************************************************************)
: M-CMD-AT_MAP-reg_get[ -- dict:global_maps ]
  (* M1 OK *)
  {
    prog "_maps/" nextprop
    begin
      dup while
      dup "_maps/" strlen strcut swap pop "#" swap strcat
      prog 3 pick getpropstr
      prog 4 rotate nextprop
    repeat
    pop
  }dict
;
PUBLIC M-CMD-AT_MAP-reg_get
$LIBDEF M-CMD-AT_MAP-reg_get

(*****************************************************************************)
(*                            M-CMD-AT_MAP-remove                            *)
(*****************************************************************************)
: M-CMD-AT_MAP-remove[ ref:env_room -- bool:success? ]
  .needs_mlev3
  env_room @ dbref? not if "Non-dbref argument (1)." abort then

  env_room @ not if
    0 exit
  then

  prog "_maps/" env_room @ intostr strcat remove_prop
  env_room @ "_map#" remove_prop

  1
;
PUBLIC M-CMD-AT_MAP-remove
$LIBDEF M-CMD-AT_MAP-remove

(* ------------------------------------------------------------------------- *)

: cmd_position ( s --  )
  dup if
    M-CMD-AT_MAP-match

    dup #-2 = if
      pop pop "I don't know which one you mean!" command @ toupper .theme_tag_err .color_tell exit
    then

    dup ok? not if
      pop pop "I can't find that map." command @ toupper .theme_tag_err .color_tell exit
    then
  else
    pop .loc
  then

  dup map_env_get not if
    "Area unmapped." command @ toupper .theme_tag .color_tell exit
  then

  .me over controls not if
    "Permission denied." command @ toupper .theme_tag_err .color_tell exit
  then

  .loc M-CMD-AT_MAP-position not if
    exit
  then
;

: cmd_show ( s --  )
  dup if
    M-CMD-AT_MAP-match

    dup #-2 = if
      pop "I don't know which one you mean!" command @ toupper .theme_tag_err .color_tell exit
    then

    dup ok? not if
      pop "I can't find that map." command @ toupper .theme_tag_err .color_tell exit
    then
  else
    pop .loc
  then

  dup map_env_get not if
    "Area unmapped." command @ toupper .theme_tag .color_tell exit
  then

  dup room? if
    (* If you're asking for the map of a room, show your position on that room's map *)
    .loc
  else
    (* Otherwise, show the position object on its own map. *)
    dup
  then

  M-CMD-AT_MAP-display pop
;

: cmd_list ( s --  )
  M-CMD-AT_MAP-reg_get
  dup not if
    pop "Sorry, no maps have been installed." command @ toupper .theme_tag .color_tell exit
  then
  "Available maps:" command @ toupper .theme_tag .color_tell
  foreach
    nip
    "    " swap strcat command @ toupper .theme_tag .color_tell
  repeat
;

: cmd_remove ( s --  )
  dup if
    M-CMD-AT_MAP-match

    dup #-2 = if
      pop pop "I don't know which one you mean!" command @ toupper .theme_tag_err .color_tell exit
    then

    dup ok? not if
      pop pop "I can't find that map." command @ toupper .theme_tag_err .color_tell exit
    then
  else
    pop .loc
  then

  dup map_env_get not if
    pop "There's no map to remove." command @ toupper .theme_tag_err .color_tell exit
  then

  .me over map_env_get controls not if
    pop "Permission denied." command @ toupper .theme_tag_err .color_tell exit
  then

  map_env_get

  dup #-1 M-CMD-AT_MAP-display pop

  "Are you certian you want to remove this map? (y/n)" command @ toupper .theme_tag .color_tell
  read_yes_no if
    dup M-CMD-AT_MAP-remove if
      "Removed." command @ toupper .theme_tag .color_tell
    else
      "Error removing map!" command @ toupper .theme_tag .color_tell
    then
  else
    "Aborted!" command @ toupper .theme_tag .color_tell exit
  then
;

: cmd_wizcreate ( s --  )
  .me "WIZARD" flag? not if
    pop "You have to be an administrator to use this command." command @ toupper .theme_tag_err .color_tell exit
  then

  dup not if
    pop "Please specify an environment room." command @ toupper .theme_tag_err .color_tell exit
  then

  M-CMD-AT_MAP-match

  dup #-2 = if
    pop "I don't know which one you mean!" command @ toupper .theme_tag_err .color_tell exit
  then

  dup ok? not if
    pop "I can't find that map." command @ toupper .theme_tag_err .color_tell exit
  then

  dup "_map#" getpropstr number? if
    pop "Existing map found.  Try map #edit" command @ toupper .theme_tag_err .color_tell exit
  then

  .me over controls not if (* Probably not needed *)
    "Permission denied." command @ toupper .theme_tag_err .color_tell exit
  then

  "What is the name of this map?" command @ toupper .theme_tag .color_tell
  "[Enter map name, or .abort to quit]" command @ toupper .theme_tag .color_tell
  DoRead strip
  dup chk_abort

  dup prop-name-ok? not
  over "/" instr or
  over "~" instr 1 = or
  over "@" instr 1 = or
  over "{here|home|me|nil}" smatch or
  if
    pop "Sorry, that's not a valid map name." command @ toupper .theme_tag_err .color_tell exit
  then

  swap

  dup M-CMD-AT_MAP-edit not if
    pop exit
  then

  M-CMD-AT_MAP-reg_add not if
    "Could not register map!" command @ toupper .theme_tag_err .color_tell exit
  then
;

: cmd_create ( s --  )
  dup not if
    pop "Please specify an environment room." command @ toupper .theme_tag_err .color_tell exit
  then

  M-CMD-AT_MAP-match

  dup #-2 = if
    pop "I don't know which one you mean!" command @ toupper .theme_tag_err .color_tell exit
  then

  dup ok? not if
    pop "I can't find that map." command @ toupper .theme_tag_err .color_tell exit
  then

  dup room? not if
    "Why would you want a map on that?" command @ toupper .theme_tag_err .color_tell exit
  then

  dup "_map#" getpropstr number? if
    pop "Existing map found.  Try map #edit" command @ toupper .theme_tag_err .color_tell exit
  then

  .me over controls not if
    "Permission denied." command @ toupper .theme_tag_err .color_tell exit
  then

  dup .loc = if
    "WARNING: ENSURE YOU ARE RUNNING THIS COMMAND IN YOUR ENVIRONMENT ROOM." "bold,red" textattr .tell
    "         If not, type '.abort' now!"                                    "bold,red" textattr .tell
  then

  M-CMD-AT_MAP-edit not if
    exit
  then
;

: cmd_edit ( s --  )

  dup if
    M-CMD-AT_MAP-match

    dup #-2 = if
      pop pop "I don't know which one you mean!" command @ toupper .theme_tag_err .color_tell exit
    then

    dup ok? not if
      pop pop "I can't find that map." command @ toupper .theme_tag_err .color_tell exit
    then
  else
    .loc
  then

  map_env_get

  dup not if
    pop "Area unmapped." command @ toupper .theme_tag .color_tell exit
  then

  .me over controls not if
    "Permission denied." command @ toupper .theme_tag_err .color_tell exit
  then

  M-CMD-AT_MAP-edit not if
    exit
  then
;

: main

  (* Comment this out if you're worried about lockups *)
  (* This was nessessary on Latitude MUCK because maps show at the same time as lots of other output (due to automatically displaying maps as you move).. and there's lots of map instructions to handle so the output would cut into the middle of the map. *)
  ( preempt )

  dup "#[^1-9]*" smatch if
    " " split swap

    "#position"  over stringpfx if pop cmd_position  exit then
    "#create"    over stringpfx if pop cmd_create    exit then
    "#wizcreate" over stringpfx if pop cmd_wizcreate exit then
    "#remove"    over stringpfx if pop cmd_remove    exit then
    "#edit"      over stringpfx if pop cmd_edit      exit then
    "#list"      over stringpfx if pop cmd_list      exit then
    "#show"      over stringpfx if pop cmd_show      exit then

    "Unknown #option." command @ toupper .theme_tag_err .color_tell exit
  then

  "Please specify an #option." command @ toupper .theme_tag_err .color_tell exit
;
.
c
q
!@register m-cmd-@map.muf=m/cmd/at_map
!@set $m/cmd/at_map=M3
!@set $m/cmd/at_map=W
!@set $m/cmd/at_map=L

