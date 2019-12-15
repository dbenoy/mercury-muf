!@program m-lib-map.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-map.muf - $m/lib/map                                                *)
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
(*   M-LIB-MAP-display[ ref:map_room ref:mark_room -- bool:success? ]        *)
(*     Shows the map of map_room (Its closest environment map). mark_room is *)
(*     which room will receieve the X marker on that map. Use #-1 to not     *)
(*     show a marker.                                                        *)
(*                                                                           *)
(*   M-LIB-MAP-edit[ ref:env_room -- bool:success? ]                         *)
(*     Shows an editing dialog for the map of env_room.                      *)
(*                                                                           *)
(*   M-LIB-MAP-env_get[ ref:map_room -- ref:env_room ]                       *)
(*     Given an object, find which environment room has its map. #-1 if no   *)
(*     map is available.                                                     *)
(*                                                                           *)
(*   M-LIB-MAP-match[ str:map_name -- ref:object ]                           *)
(*     Like the MATCH primitive, but it takes the object that matches, and   *)
(*     returns the environment room of that object's map. You must control   *)
(*     the object that maps in order to see its environment room, unless the *)
(*     match is for a global map registered with M-LIB-MAP-reg_add.          *)
(*                                                                           *)
(*   M-LIB-MAP-position[ ref:env_room ref:mark_room -- bool:success? ]       *)
(*     Shows an editing dialog for you to mark the position of mark_room on  *)
(*     the map in env_room.                                                  *)
(*                                                                           *)
(*   M-LIB-MAP-reg_add[ str:map_name ref:env_room -- bool:success? ]         *)
(*     Registers a map name globally. Registered map names can be listed,    *)
(*     and can always be viewed with @map <name>.                            *)
(*                                                                           *)
(*   M-LIB-MAP-reg_del[ ref:env_room -- bool:success? ]                      *)
(*     Removes the map in env_room from the list of registered names created *)
(*     by M-LIB-MAP-reg_add.                                                 *)
(*                                                                           *)
(*   M-LIB-MAP-reg_get[ -- dict:global_maps ]                                *)
(*     Returns a dict of registered names created by M-LIB-MAP-reg_add,      *)
(*     keyed by dbrefs of the environment room for each name in string form. *)
(*                                                                           *)
(*   M-LIB-MAP-remove[ ref:map_room -- bool:success? ]                       *)
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
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/color
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/lsedit

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .err M-LIB-THEME-err
$DEF .tag M-LIB-THEME-tag
$DEF .tag_err M-LIB-THEME-tag_err

(* ------------------------------------------------------------------------- *)

: chk_abort ( s --  )
  ".abort" stringpfx if
    "Aborted!" command @ .tag .tell
    pid kill
  then
;

: doRead  (  -- s )
  begin
    read
    dup if
      dup "{\"|:|say |pose }*" smatch if
        "me" match swap force
        continue
      then
    then
    break
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
(*                             M-LIB-MAP-display                             *)
(*****************************************************************************)
: M-LIB-MAP-display[ ref:map_room ref:mark_room -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev1
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
    mark_room @ "_mapx/" map_room @ intostr strcat envpropstr atoi my_x ! pop
    mark_room @ "_mapy/" map_room @ intostr strcat envpropstr atoi my_y ! pop
    my_x @ my_y @ and if
      1 my_is_marked !
    then
  then

  map_room @ "_map#" getpropstr atoi
  1 begin
    over over >= while
    "_map#/" over intostr strcat map_room @ swap getpropstr

    my_is_marked @ if (* Show marker if applicable *)
      over my_y @ = if
        my_x @ M-LIB-COLOR-strcut
        swap dup M-LIB-COLOR-strlen -- M-LIB-COLOR-strcut pop marker_get M-LIB-COLOR-strcat swap
        M-LIB-COLOR-strcat
      then
    then

    .tell
    ++
  repeat
  pop pop

  1
;
PUBLIC M-LIB-MAP-display
$LIBDEF M-LIB-MAP-display

(*****************************************************************************)
(*                              M-LIB-MAP-edit                               *)
(*****************************************************************************)
: M-LIB-MAP-edit[ ref:env_room -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
  env_room @ dbref? not if "Non-dbref argument (1)." abort then

  { "You are now editing the map in environment room " env_room @ unparseobj "." }cat command @ toupper .tag .tell
  "You can get help by entering '.h' on a line by itself." command @ toupper .tag .tell
  "'.end' will save and exit." command @ toupper .tag .tell
  "'.abort' will abort any changes." command @ toupper .tag .tell
  "To save changes and continue editing, use '.save'." command @ toupper .tag .tell
  env_room @ "_map" M-LIB-LSEDIT-listedit
  dup not if
    "Aborted!" command @ toupper .tag .tell
  then
;
PUBLIC M-LIB-MAP-edit
$LIBDEF M-LIB-MAP-edit

(*****************************************************************************)
(*                            M-LIB-MAP-positiion                            *)
(*****************************************************************************)
: M-LIB-MAP-position[ ref:env_room ref:mark_room -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
  env_room @ dbref? not if "Non-dbref argument (1)." abort then
  mark_room @ dbref? not if "Non-dbref argument (2)." abort then

  (* TODO: Draw upper guide *)
  0 var! max_x
  0 var! max_y

  env_room @ "_map#" getpropstr atoi dup max_y !
  1 begin
    over over >= while
    "_map#/" over intostr strcat env_room @ swap getpropstr

    dup M-LIB-COLOR-strlen max_x @ > if
      dup M-LIB-COLOR-strlen max_x !
    then

    over intostr "   " over strlen strcut swap pop swap strcat " " strcat swap M-LIB-COLOR-strcat .tell
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
    "What is this room's column number on the map?" command @ toupper .tag .tell
    "[Enter column number, or .abort to quit]" command @ toupper .tag .tell
    doRead strip
    dup chk_abort
    dup number? not if
      "Sorry, that's not a number." command @ toupper .tag .tell
      pop continue
    then
    atoi
    dup 0 <= over max_x @ > or if
      "Invalid entry: the column number must be between 1 and " max_x @ intostr strcat "." strcat command @ toupper .tag .tell
      pop continue
    then
    mark_room @ "_mapx/" env_room @ intostr strcat rot intostr setprop break
  repeat

  begin
    "What is this room's row number on the map?" command @ toupper .tag .tell
    "[Enter column number, or .abort to quit]" command @ toupper .tag .tell
    doRead strip
    dup chk_abort
    dup number? not if
      "Sorry, that's not a number." command @ toupper .tag .tell
      pop continue
    then
    atoi
    dup 0 <= over max_y @ > or if
      "Invalid entry: the column number must be between 1 and " max_y @ intostr strcat "." strcat command @ toupper .tag .tell
      pop continue
    then
    mark_room @ "_mapy/" env_room @ intostr strcat rot intostr setprop break
  repeat

  "Set." command @ toupper .tag .tell
  1
;
PUBLIC M-LIB-MAP-position
$LIBDEF M-LIB-MAP-position

(*****************************************************************************)
(*                             M-LIB-MAP-env_get                             *)
(*****************************************************************************)
: M-LIB-MAP-env_get[ ref:map_room -- ref:env_room ]
  M-LIB-PROGRAM-needs_mlev1
  map_room @ dbref? not if "Non-dbref argument (1)." abort then
  map_room @ map_env_get
;
PUBLIC M-LIB-MAP-env_get
$LIBDEF M-LIB-MAP-env_get

(*****************************************************************************)
(*                              M-LIB-MAP-match                              *)
(*****************************************************************************)
: M-LIB-MAP-match[ str:map_name -- ref:object ]
  M-LIB-PROGRAM-needs_mlev1
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
PUBLIC M-LIB-MAP-match
$LIBDEF M-LIB-MAP-match

(*****************************************************************************)
(*                             M-LIB-MAP-reg_add                             *)
(*****************************************************************************)
: M-LIB-MAP-reg_add[ str:map_name ref:env_room -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
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
PUBLIC M-LIB-MAP-reg_add
$LIBDEF M-LIB-MAP-reg_add

(*****************************************************************************)
(*                             M-LIB-MAP-reg_del                             *)
(*****************************************************************************)
: M-LIB-MAP-reg_del[ ref:env_room -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
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
PUBLIC M-LIB-MAP-reg_del
$LIBDEF M-LIB-MAP-reg_del

(*****************************************************************************)
(*                             M-LIB-MAP-reg_get                             *)
(*****************************************************************************)
: M-LIB-MAP-reg_get[ -- dict:global_maps ]
  M-LIB-PROGRAM-needs_mlev1
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
PUBLIC M-LIB-MAP-reg_get
$LIBDEF M-LIB-MAP-reg_get

(*****************************************************************************)
(*                             M-LIB-MAP-remove                              *)
(*****************************************************************************)
: M-LIB-MAP-remove[ ref:env_room -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
  env_room @ dbref? not if "Non-dbref argument (1)." abort then

  env_room @ not if
    0 exit
  then

  prog "_maps/" env_room @ intostr strcat remove_prop
  env_room @ "_map#" remove_prop

  1
;
PUBLIC M-LIB-MAP-remove
$LIBDEF M-LIB-MAP-remove

(* ------------------------------------------------------------------------- *)

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-map.muf=m/lib/map
!@set $m/lib/map=M3
!@set $m/lib/map=W
!@set $m/lib/map=L

