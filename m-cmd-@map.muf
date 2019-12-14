!@program m-cmd-@map.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@map.muf - $m/cmd/at_map                                            *)
(*    A command using $m/lib/map to modify and display maps.                 *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.2 -- Daniel Benoy -- October, 2019                            *)
(*     - Modified for inclusion in mercury-muf                               *)
(*   Version 1.1 -- Daniel Benoy -- May, 2004                                *)
(*     - Removed all jmap.muf code and replaced it with original code (to    *)
(*       change the license to GPLv2).                                       *)
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
$INCLUDE $m/lib/map
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/color
$INCLUDE $m/lib/theme

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .err M-LIB-THEME-err
$DEF .tag M-LIB-THEME-tag
$DEF .tag_err M-LIB-THEME-tag_err

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
    { "  " action_name @ tolower " #list ................... Display list of available maps" }cat
    { "  " action_name @ tolower " #show ................... Display your map" }cat
    { "  " action_name @ tolower " #show <map> ............. Display some other map" }cat
    { "  " action_name @ tolower " #create <env room>....... Create a map in the given environment room" }cat
    { "  " action_name @ tolower " #wizcreate <env room>.... Same as #create, but also add to the list of maps" }cat
    { "  " action_name @ tolower " #edit ................... Edit current map" }cat
    { "  " action_name @ tolower " #edit <map> ............. Edit some other map" }cat
    { "  " action_name @ tolower " #remove ................. Remove current map" }cat
    { "  " action_name @ tolower " #remove <map> ........... Remove some other map" }cat
    { "  " action_name @ tolower " #position ............... Set position of current room on its map" }cat
    { "  " action_name @ tolower " #position <map> ......... Set position of current room on another map" }cat
  }list
;
WIZCALL M-HELP-help

(* FIXME *)
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

    "Please enter 'Yes' or 'No'." command @ toupper .tag .tell
  repeat
;

: cmd_position ( s --  )
  dup if
    M-LIB-MAP-match

    dup #-2 = if
      pop pop "I don't know which one you mean!" command @ toupper .tag_err .tell exit
    then

    dup ok? not if
      pop pop "I can't find that map." command @ toupper .tag_err .tell exit
    then
  else
    pop "me" match location
  then

  M-LIB-MAP-env_get

  dup not if
    "Area unmapped." command @ toupper .tag .tell exit
  then

  "me" match over controls not if
    "Permission denied." command @ toupper .tag_err .tell exit
  then

  "me" match location M-LIB-MAP-position not if
    exit
  then
;

: cmd_show ( s --  )
  dup if
    M-LIB-MAP-match

    dup #-2 = if
      pop "I don't know which one you mean!" command @ toupper .tag_err .tell exit
    then

    dup ok? not if
      pop "I can't find that map." command @ toupper .tag_err .tell exit
    then
  else
    pop "me" match location
  then

  dup M-LIB-MAP-env_get not if
    "Area unmapped." command @ toupper .tag .tell exit
  then

  dup room? if
    (* If you're asking for the map of a room, show your position on that room's map *)
    "me" match location
  else
    (* Otherwise, show the position object on its own map. *)
    dup
  then

  M-LIB-MAP-display pop
;

: cmd_list ( s --  )
  M-LIB-MAP-reg_get
  dup not if
    pop "Sorry, no maps have been installed." command @ toupper .tag .tell exit
  then
  "Available maps:" command @ toupper .tag .tell
  foreach
    nip
    "    " swap strcat command @ toupper .tag .tell
  repeat
;

: cmd_remove ( s --  )
  dup if
    M-LIB-MAP-match

    dup #-2 = if
      pop pop "I don't know which one you mean!" command @ toupper .tag_err .tell exit
    then

    dup ok? not if
      pop pop "I can't find that map." command @ toupper .tag_err .tell exit
    then
  else
    pop "me" match location
  then

  dup M-LIB-MAP-env_get not if
    pop "There's no map to remove." command @ toupper .tag_err .tell exit
  then

  "me" match over M-LIB-MAP-env_get controls not if
    pop "Permission denied." command @ toupper .tag_err .tell exit
  then

  M-LIB-MAP-env_get

  dup #-1 M-LIB-MAP-display pop

  "Are you certian you want to remove this map? (y/n)" command @ toupper .tag .tell
  read_yes_no if
    dup M-LIB-MAP-remove if
      "Removed." command @ toupper .tag .tell
    else
      "Error removing map!" command @ toupper .tag .tell
    then
  else
    "Aborted!" command @ toupper .tag .tell exit
  then
;

: cmd_wizcreate ( s --  )
  "me" match "WIZARD" flag? not if
    pop "You have to be an administrator to use this command." command @ toupper .tag_err .tell exit
  then

  dup not if
    pop "Please specify an environment room." command @ toupper .tag_err .tell exit
  then

  M-LIB-MAP-match

  dup #-2 = if
    pop "I don't know which one you mean!" command @ toupper .tag_err .tell exit
  then

  dup ok? not if
    pop "I can't find that map." command @ toupper .tag_err .tell exit
  then

  dup "_map#" getpropstr number? if
    pop "Existing map found.  Try map #edit" command @ toupper .tag_err .tell exit
  then

  "me" match over controls not if (* Probably not needed *)
    "Permission denied." command @ toupper .tag_err .tell exit
  then

  "What is the name of this map?" command @ toupper .tag .tell
  "[Enter map name, or .abort to quit]" command @ toupper .tag .tell
  doRead strip
  dup chk_abort

  dup prop-name-ok? not
  over "/" instr or
  over "~" instr 1 = or
  over "@" instr 1 = or
  over "{here|home|me|nil}" smatch or
  if
    pop "Sorry, that's not a valid map name." command @ toupper .tag_err .tell exit
  then

  swap

  dup M-LIB-MAP-edit not if
    pop exit
  then

  M-LIB-MAP-reg_add not if
    "Could not register map!" command @ toupper .tag_err .tell exit
  then
;

: cmd_create ( s --  )
  dup not if
    pop "Please specify an environment room." command @ toupper .tag_err .tell exit
  then

  M-LIB-MAP-match

  dup #-2 = if
    pop "I don't know which one you mean!" command @ toupper .tag_err .tell exit
  then

  dup ok? not if
    pop "I can't find that map." command @ toupper .tag_err .tell exit
  then

  dup room? not if
    "Why would you want a map on that?" command @ toupper .tag_err .tell exit
  then

  dup "_map#" getpropstr number? if
    pop "Existing map found.  Try map #edit" command @ toupper .tag_err .tell exit
  then

  "me" match over controls not if
    "Permission denied." command @ toupper .tag_err .tell exit
  then

  dup "me" match location = if
    "WARNING: ENSURE YOU ARE RUNNING THIS COMMAND IN YOUR ENVIRONMENT ROOM." "bold,red" textattr .tell
    "         If not, type '.abort' now!"                                    "bold,red" textattr .tell
  then

  M-LIB-MAP-edit not if
    exit
  then
;

: cmd_edit ( s --  )
  dup if
    M-LIB-MAP-match

    dup #-2 = if
      pop pop "I don't know which one you mean!" command @ toupper .tag_err .tell exit
    then

    dup ok? not if
      pop pop "I can't find that map." command @ toupper .tag_err .tell exit
    then
  else
    "me" match location
  then

  M-LIB-MAP-env_get

  dup not if
    pop "Area unmapped." command @ toupper .tag .tell exit
  then

  "me" match over controls not if
    "Permission denied." command @ toupper .tag_err .tell exit
  then

  M-LIB-MAP-edit not if
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

    "Unknown #option." command @ toupper .tag_err .tell exit
  then

  "Please specify an #option." command @ toupper .tag_err .tell exit
;
.
c
q
!@register m-cmd-@map.muf=m/cmd/at_map
!@set $m/cmd/at_map=M3
!@set $m/cmd/at_map=W

