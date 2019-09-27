@program m-cmd-@recycle.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@recycle.muf - $m/cmd/at_recycle                                    *)
(*   A replacement for the built-in @recycle command which tries to mimic    *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o #help argument for usage information.                                 *)
(*   o Can act as a library for other objects to recycle objects with proper *)
(*     permission checks, penny refunds, etc.                                *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_RECYCLE-Recycle[ str:thing int:confirmation -- bool:success? ] *)
(*     Attempts to recycle an object as though the current player ran the    *)
(*     @recycle command, including all the same message output, permission   *)
(*     checks, penny manipulation, etc. M3 required.                         *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*      - Split from lib-create.muf and cmd-lib-create.muf into mercury-muf  *)
(*        project                                                            *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*      - Original implementation for Latitude MUCK                          *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004-2019 Daniel Benoy                                      *)
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
$NOTE    @recycle command with more features.
$DOCCMD  @list __PROG__=2-45

: doRecycle ( d -- s )
  1 try
    recycle "" exit
  catch
    exit
  endcatch
;

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/match

$DEF NEEDSM2 trig caller = not caller mlevel 2 < and if "Requires MUCKER level 2 or above." abort then
$DEF NEEDSM3 trig caller = not caller mlevel 3 < and if "Requires MUCKER level 3 or above." abort then
$DEF NEEDSM4 trig caller = not caller "WIZARD" flag? not and if "Requires MUCKER level 4 or above." abort then

$PUBDEF :

(*****************************************************************************)
(*                        M-CMD-AT_RECYCLE-Recycle                           *)
(*****************************************************************************)
: M-CMD-AT_RECYCLE-Recycle[ str:thing int:confirmation -- bool:success? ]
  NEEDSM3

  thing @ 1 1 1 1 M-LIB-MATCH-Match thing !

  thing @ not if
    #-1 exit
  then

  "me" match thing @ owner = not if
    "me" match "WIZARD" flag? thing @ ok? not if
      "That's already garbage!" .tell
    else
      "Permission denied." .tell
    then
    exit
  then
  
  thing @ player? if
    "You can't recycle a player!" .tell exit
  then
  
  thing @ ok? not if
    "That's already garbage!" .tell exit
  then
    
  thing @ owner "me" match owner = not if
    "Permission denied." .tell exit
  then
    
  thing @ room? if
    thing @ "player_start" sysparm stod = thing @ #0 = or if
      "This room may not be recycled (is either player start or the global environment)." .tell exit
    then
  then
  
  thing @ exit? if
    "me" match location thing @ location = not if
      "You can't do that to an exit in another room." .tell exit
    then
  then
  
  confirmation @ if
    "Are you certian you want to permanently recycle " thing @ unparseobj strcat "? (Type 'YES' in full to recycle, anything else to abort.)" strcat .tell
    read "yes" stringcmp if
      "Aborted!" .tell exit
    then
  then
  
  thing @ thing? if
    (* DB: This actually is the behavior of the built-in @recycle command.  I didn't make it up. *)
    thing @ "me" match = if
      thing @ name "'s owner commands it to kill itself.  It blinks a few times in shock, and says, \"But.. but.. WHY?\"  It suddenly clutches it's heart, grimacing with pain..  Staggers a few steps before falling to it's knees, then plops down on it's face.  *thud*  It kicks it's legs a few times, with weakening force, as it suffers a seizure.  It's color slowly starts changing to purple, before it explodes with a fatal *POOF*!" strcat
      dup .otell
      
      thing @ owner location thing @ location = not if
        thing @ owner swap notify
      else
        pop
      then
      
      thing @ owner "Now don't you feel guilty?" notify
    then
  then
  
  (* NOTE: The MUF recycle primitive is actually returning your pennies to
     you, so I don't have to do that here.
     See: https://github.com/fuzzball-muck/fuzzball/issues/456
  *)
  thing @ unparseobj var! unparsedName
  thing @ doRecycle dup if
    .tell
    0
  else
    pop { "Thank you for recycling " unparsedName @ "." }join .tell
    1
  then
;
PUBLIC M-CMD-AT_RECYCLE-Recycle
$LIBDEF M-CMD-AT_RECYCLE-Recycle

(*****************************************************************************)
(*                               cmdRecycle                                  *)
(*****************************************************************************)
: help (  --  )
  "@RECYCLE <object>" .tell
  " " .tell
  "Destroy an object and remove all references to it within the database. The object is then added to a free list, and newly created objects are assigned from the pool of recycled objects first.  You *must* own the object being recycled, even wizards must use the @chown command to recycle someone else's belongings." .tell
;
 
: main ( s --  )
  "#help" over stringpfx if pop help exit then

  "=" split
  pop
  strip var! objectname

  (* Perform unlink *)
  objectname @ 0 M-CMD-AT_RECYCLE-Recycle pop
;

.
c
q
@register m-cmd-@recycle.muf=m/cmd/at_recycle
@set $m/cmd/at_recycle=L
@set $m/cmd/at_recycle=M3
@set $m/cmd/at_recycle=W


