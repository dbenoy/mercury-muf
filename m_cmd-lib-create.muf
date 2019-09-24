@program cmd-lib-create.muf
1 99999 d
i
(*****************************************************************************)
(* cmd-lib-create.muf $cmd/lib-create                       Header: xx lines *)
(*    Commands which implement @dig, @open, @action, @create, and @xdig and  *)
(*    @quota for lib-create.muf.                                             *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*  o Attempts to replicate the behavior of the stock commands, but with the *)
(*    ability to tweak the behavior in MUF code                              *)
(*  o Adds optional quotas for maximum numbers of objects of given types on  *)
(*    per-user basis.                                                        *)
(*  o Adds #help options to the commands, which give accurate penny names    *)
(*    and values according to @tune.                                         *)
(*                                                                           *)
(* INSTALLATION:                                                             *)
(*                                                                           *)
(* USAGE:                                                                    *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*      - Original implementation                                            *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright {C} 2004  Daniel Benoy                                          *)
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
 
(* Begin user configurable options *)
 
 
(* End user configurable options *)
 
$include $lib/create
$include $lib/reflist
 
(*****************************************************************************)
(*                           Support Functions                               *)
(*****************************************************************************)
$define .getpennies ( s -- s )
  dup
  " " strcat
  swap atoi
  1 = if
    "penny" sysparm
  else
    "pennies" sysparm
  then
  strcat
$enddef
 
: registerObject[ ref:object str:regname ]
  regname @ prop-name-ok? not if
    { "Registry name '" regname @ "' is not valid" }join .tell
    exit
  then

  me @ "_reg/" regname @ strcat object @ setprop
  "Registered as $" regname @ strcat .tell
;

(*****************************************************************************)
(*                                cmdAction                                  *)
(*****************************************************************************)
: cmdActionHelp (  --  )
  "@ACTION <name>=<source>[,<destination>[; <destination2>; ... <destinationN>]] [=<regname>]" .tell
  " " .tell
  { "  Creates a new action and attaches it to the thing, room, or player specified. If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object. This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, etc. You may only attach actions you control to things you control. Creating an action costs " "exit_cost" sysparm .getpennies ". The action can then be linked with the command @LINK." }join .tell
;
 
: cmdAction ( s --  )
  "#help" over stringpfx if pop cmdActionHelp exit then
  
  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @action." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  "," split
  strip var! destination
  strip var! source
  strip var! exitname
  
  (* Create action *)
  source @ exitname @ CREATE-Action var! newAction
  newAction @ not if exit then
  
  (* Perform link *)
  destination @ if
    "Trying to link..." .tell
    "#" newAction @ intostr strcat destination @ CREATE-Link not if exit then
  then
  
  (* Register action *)
  regname @ if
    dup regname @ registerObject
  then
;
 
(*****************************************************************************)
(*                                cmdClone                                   *)
(*****************************************************************************)
: cmdCloneHelp (  --  )
  "@CLONE <object> [=<regname>]" .tell
  " " .tell
  "Clones the given object, including name, location, flags, and properties.  You must have control of the object, you may not clone rooms, exits, etc, and cloning may cost pennies.  If successful, the command prints the identifier of the new object.  Only a Builder may use this command." .tell
  " " .tell
  "Example:" .tell
  "  @clone some_object" .tell
  "Also see: @CREATE" .tell
;
 
: cmdClone ( s --  )
  "#help" over stringpfx if pop cmdCloneHelp exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @clone." .tell
    pop exit
  then

  "=" split
  strip var! regname
  strip var! thingname

  (* Clone thing *)
  thingname @ CREATE-Clone

  (* Register thing *)
  regname @ if
    dup regname @ registerObject
  then

  pop
;

(*****************************************************************************)
(*                                cmdCreate                                  *)
(*****************************************************************************)
: cmdCreateHelp (  --  )
  "@CREATE <object> [=<cost>[=<regname>]]" .tell
 
  { "  Creates a new object and places it in your inventory.  This costs at least " "exit_cost" sysparm .getpennies ".  If <cost> is specified, you are charged that many pennies, and in return, the object is endowed with a value according to the formula: " CREATE-EndowmentEquation ".  The maximum value of an object is " "max_object_endowment" sysparm .getpennies ", which would cost " "max_object_endowment" sysparm atoi CREATE-GetCost intostr .getpennies " to create. If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object.  This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, et cetera.  Only a builder may use this command." }join .tell
;
 
: cmdCreate ( s --  )
  "#help" over stringpfx if pop cmdCreateHelp exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @create." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  strip var! cost
  strip var! thingname

  (* Create thing *)
  thingname @ cost @ CREATE-Create
  dup not if
    pop
    exit
  then

  (* Register thing *)
  regname @ if
    dup regname @ registerObject
  then

  pop
;
 
(*****************************************************************************)
(*                                 cmdDig                                    *)
(*****************************************************************************)
: cmdDigHelp (  --  )
  "@DIG <room> [=<parent> [=<regname>]]" .tell
 
  { "  Creates a new room, sets its parent, and gives it a personal registered name.  If no parent is given, it defaults to the first ABODE room down the environment tree from the current room.  If it fails to find one, it sets the parent to " "default_room_parent" sysparm stod unparseobj ".  If no <regname> is given, then it doesn't register the object.  If one is given, then the object's dbref is recorded in the player's _reg/<regname> property, so that they can refer to the object later as $<regname>.  Digging a room costs " "room_cost" sysparm .getpennies ", and you must be able to link to the parent room if specified.  Only a builder may use this command." }join .tell
;
 
: cmdDig ( s --  )
  "#help" over stringpfx if pop cmdDigHelp exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @dig." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  strip var! parent
  strip var! roomname

  (* Create room *)
  roomname @ parent @ CREATE-Dig
  dup not if
    pop
    exit
  then

  (* Register room *)
  regname @ if
    dup regname @ registerObject
  then

  pop
;

(*****************************************************************************)
(*                               cmdExcavate                                 *)
(*****************************************************************************)
: cmdExcavateHelp (  --  )
  "@EXCAVATE <room>[=<exit to room>[=<backlink from room>]]" .tell
  " " .tell
  { "  Creates a new room and, optionally, an exit leading from your current location to the room, and/or an exit leading from the room to your current location. The room is automatically parented to the same position in the environment tree as your current location. Creating a room costs " "room_cost" sysparm .getpennies ".  Creating an exit costs " "exit_cost" sysparm .getpennies ". Only a builder may use this command." }join .tell
;
 
: cmdExcavate ( s --  )
  "#help" over stringpfx if pop cmdExcavateHelp exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @excavate." .tell
    pop exit
  then

  "=" split "=" split
  strip var! backexit
  strip var! foreexit
  strip var! roomname
  
  roomname @ "" CREATE-Dig dup not if pop exit then var! newroom
  
  foreexit @ if
    "Creating " foreexit @ strcat "..." strcat .tell
    { "#" loc @ intostr }join foreexit @ CREATE-Action dup not if pop exit then var! newforeexit
    "Trying to link..." .tell
    { "#" newforeexit @ intostr }join { "#" newroom @ intostr }join CREATE-Link not if exit then
  then
  
  backexit @ if
    "Creating " backexit @ strcat "..." strcat .tell
    { "#" newroom @ intostr }join backexit @ CREATE-Action dup not if pop exit then var! newbackexit
    "Trying to link..." .tell
    { "#" newbackexit @ intostr }join { "#" loc @ intostr }join CREATE-Link not if exit then
  then
;

(*****************************************************************************)
(*                                 cmdLink                                   *)
(*****************************************************************************)
: cmdLinkHelp (  --  )
  "@LINK <object1>=<object2> [; <object3>; ...  <objectn> ]" .tell
  " " .tell
  "  Links <object1> to <object2>, provided you control <object1>, and <object2> is either controlled by you or linkable.  Actions may be linked to more than one thing, specified in a list separated by semi-colons." .tell
  "Also see: @RELINK and @UNLINK" .tell
;
 
: cmdLink ( s --  )
  "#help" over stringpfx if pop cmdLinkHelp exit then
  
  "=" split
  strip var! destination
  strip var! exitname

  (* Perform link *)
  exitname @ destination @ CREATE-Link pop
;
 
(*****************************************************************************)
(*                                 cmdOpen                                   *)
(*****************************************************************************)
: cmdOpenHelp (  --  )
  "@OPEN <exit> [=<object> [; <object2>; ... <objectn> ] [=<regname>]]" .tell
 
  { "  Opens an exit in the current room, optionally attempting to link it simultaneously.  If a <regname> is specified, then the _reg/<regname> property on the player is set to the dbref of the new object.  This lets players refer to the object as $<regname> (ie: $mybutton) in @locks, @sets, etc.  Opening an exit costs " "exit_cost" sysparm .getpennies ", and " "link_cost" sysparm .getpennies " to link it, and you must control the room where it is being opened." }join .tell
;
 
: cmdOpen ( s --  )
  "#help" over stringpfx if pop cmdOpenHelp exit then

  "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
    "Only builders are allowed to @open." .tell
    pop exit
  then

  "=" split "=" split
  strip var! regname
  strip var! destination
  strip var! exitname
  
  (* Create action *)
  { "#" loc @ intostr }join exitname @ CREATE-Action var! newAction
  newAction @ not if exit then
  
  (* Perform link *)
  destination @ if
    "Trying to link..." .tell  
    { "#" newAction @ intostr }join destination @ CREATE-Link not if exit then
  then
  
  (* Register action *)
  regname @ if
    dup regname @ registerObject
  then
;
 
(*****************************************************************************)
(*                                  cmdQuota                                 *)
(*****************************************************************************)
: cmdQuotaHelp (  --  )
  "@QUOTA [<player>]" .tell
  " " .tell
  "Displays quota information and ownership totals." .tell
;

$def QUOTA_STRING dup -1 = if pop "---" else intostr then

: cmdQuota ( s --  )
  dup "#help" over stringpfx and if pop cmdQuotaHelp exit then

  dup not if
    pop "me"
  then

  dup if
    .pmatch
  else
    pop me @
  then

  dup #-1 = if
    "No such player." .tell
    pop exit
  then

  var! target

  me @ "WIZARD" flag? not target @ me @ != and if
    "Permission denied." .tell
    exit
  then

  "Owned"                           "Quota"                                          ""         "%12s%12s%12s" fmtstring .tell
  target @ "program" CREATE-GetUsage target @ "program" CREATE-GetQuota QUOTA_STRING "Programs" "%12s%12s%12i" fmtstring .tell
  target @ "thing" CREATE-GetUsage   target @ "thing" CREATE-GetQuota   QUOTA_STRING "Things"   "%12s%12s%12i" fmtstring .tell
  target @ "exit" CREATE-GetUsage    target @ "exit" CREATE-GetQuota    QUOTA_STRING "Exits"    "%12s%12s%12i" fmtstring .tell
  target @ "room" CREATE-GetUsage    target @ "room" CREATE-GetQuota    QUOTA_STRING "Rooms"    "%12s%12s%12i" fmtstring .tell
;

(*****************************************************************************)
(*                               cmdRecycle                                  *)
(*****************************************************************************)
: cmdRecycleHelp (  --  )
  "@RECYCLE <object>" .tell
  " " .tell
  "Destroy an object and remove all references to it within the database. The object is then added to a free list, and newly created objects are assigned from the pool of recycled objects first.  You *must* own the object being recycled, even wizards must use the @chown command to recycle someone else's belongings." .tell
;
 
: cmdRecycle ( s --  )
  "#help" over stringpfx if pop cmdRecycleHelp exit then

  "=" split
  pop
  strip var! objectname

  (* Perform unlink *)
  objectname @ 0 CREATE-Recycle pop
;

(*****************************************************************************)
(*                                cmdRelink                                  *)
(*****************************************************************************)
: cmdRelinkHelp (  --  )
  "@RELINK <object1>=<object2> [; <object3>; ...  <objectn> ]" .tell
  " " .tell
  "  Unlinks <object1>, then links it to <object2>, provided you control <object1>, and <object2> is either controlled by you or linkable. Actions may be linked to more than one thing, specified in a list separated by semi-colons." .tell
  "Also see: @LINK and @UNLINK" .tell
;
 
: cmdRelink ( s --  )
  "#help" over stringpfx if pop cmdRelinkHelp exit then
  
  "=" split
  strip var! destination
  strip var! exitname

  (* Unlink it, if it's an exit *)
  exitname @ match exit? if
    exitname @ CREATE-Unlink not if exit then
  then

  (* Perform link *)
  exitname @ destination @ CREATE-Link pop
;
 
(*****************************************************************************)
(*                                cmdUnlink                                  *)
(*****************************************************************************)
: cmdUnlinkHelp (  --  )
  "@UNLINK <exit>" .tell
  "@UNLINK here" .tell
  " " .tell
  "  Removes the link on the exit in the specified direction, or removes the drop-to on the room. Unlinked exits may be picked up and dropped elsewhere. Be careful, anyone can relink an unlinked exit, becoming its new owner (but you will be reimbursed your 1 penny)." .tell
  "Also see: @LINK and @RELINK" .tell
;
 
: cmdUnlink ( s --  )
  "#help" over stringpfx if pop cmdUnlinkHelp exit then

  "=" split
  pop
  strip var! exitname

  (* Perform unlink *)
  exitname @ CREATE-Unlink pop
;
 
(* ---------------------------------- main --------------------------------- *)
: main
  command @ case
    "@action"   swap stringpfx when cmdAction   end
    "@clone"    swap stringpfx when cmdClone    end
    "@create"   swap stringpfx when cmdCreate   end
    "@dig"      swap stringpfx when cmdDig      end
    "@excavate" swap stringpfx when cmdExcavate end
    "@xdig"     swap stringpfx when cmdExcavate end
    "@link"     swap stringpfx when cmdLink     end
    "@open"     swap stringpfx when cmdOpen     end
    "@quota"    swap stringpfx when cmdQuota    end
    "@recycle"  swap stringpfx when cmdRecycle  end
    "@relink"   swap stringpfx when cmdRelink   end
    "@unlink"   swap stringpfx when cmdUnlink   end
    default "Bad action name." .tell end
  endcase
  
  depth if "Stack depth at termination." abort then
;
.
c
q

