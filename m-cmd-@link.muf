@program m-cmd-@link.muf
1 99999 d
i
$pragma comment_recurse
(*****************************************************************************)
(* m-cmd-@link.muf - $m/cmd/at_link                                          *)
(*   A replacement for the built-in @link command which tries to mimic stock *)
(*   behavior while adding features.                                         *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*   o #help argument for usage information.                                 *)
(*   o Can act as a library for other objects to link objects with proper    *)
(*     permission checks, penny charges, etc.                                *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_LINK-Link[ str:thing str:links -- bool:success? ]              *)
(*     Attempts to perform a linkas though the current player ran the @link  *)
(*     command, including all the same message output, permission checks,    *)
(*     penny manipulation, etc. M3 required.                                 *)
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
$NOTE    @link command with more features.
$DOCCMD  @list $m/cmd/at_link=2-45

(* Begin configurable options *)

(* End configurable options *)

$include $m/lib/match
$include $m/lib/pennies

$def NEEDSM2 trig caller = not caller mlevel 2 < and if "Requires MUCKER level 2 or above." abort then
$def NEEDSM3 trig caller = not caller mlevel 3 < and if "Requires MUCKER level 3 or above." abort then
$def NEEDSM4 trig caller = not caller mlevel 4 < and if "Requires MUCKER level 4 or above." abort then

$pubdef :

: doSetLinksArray ( d1 a -- s )
  2 try
    setlinks_array "" exit
  catch
    exit
  endcatch
;

$def LINKABLE dup room? over thing? or dup 3 pick "ABODE" flag? and swap not 3 pick "LINK_OK" flag? and or over #-3 = or swap pop
$def TESTLOCKPROP getprop dup lock? if testlock else pop pop 1 then

: canLinkTo[ ref:who ref:what ref:where -- bool:success? ]
  (* Can always link to HOME *)
  #-3 where @ = if
    1 exit
  then

  (* Exits can be linked to NIL *)
  #-4 where @ = what @ exit? and if
    1 exit
  then

  (* Can't link to an invalid dbref *)
  where @ ok? not if
    0 exit
  then

  what @ case
    exit? when
      who @ where @ controls if 1 exit then
      where @ "LINK_OK" flag? "me" match where @ "_/lklk" TESTLOCKPROP and if 1 exit then
    end
    player? when
      where @ room? not if 0 exit then
      who @ where @ controls if 1 exit then
      where @ LINKABLE "me" match where @ "_/lklk" TESTLOCKPROP and if 1 exit then
    end
    room? when
      where @ room? where @ thing? or not if 0 exit then
      who @ where @ controls if 1 exit then
      where @ LINKABLE "me" match where @ "_/lklk" TESTLOCKPROP and if 1 exit then
    end
    thing? when
      where @ room? where @ thing? or where @ player? or not if 0 exit then
      who @ where @ controls if 1 exit then
      where @ LINKABLE "me" match where @ "_/lklk" TESTLOCKPROP and if 1 exit then
    end
  endcase

  0
;

: exitLoopCheck[ ref:source ref:dest -- bool:success? ]
  source @ dest @ = if 1 exit then
  dest @ ok? not if 0 exit then
  dest @ exit? if
    dest @ getlinks array_make foreach
      swap pop
      var! current
      current @ exit? if
        source @ current @ exitLoopCheck if 1 exit then
      then
    repeat
  then
  0 exit
;

(*****************************************************************************)
(*                            M-CMD-AT_LINK-Link                             *)
(*****************************************************************************)
: M-CMD-AT_LINK-Link[ str:thing str:links -- bool:success? ]
  NEEDSM3

  "link_cost" sysparm atoi var! tp_link_cost
  "exit_cost" sysparm atoi var! tp_exit_cost
  
  thing @ 1 1 1 1 M-LIB-MATCH-Match thing !

  thing @ not if
    0 exit
  then

  links @ ";" explode_array links !

  thing @ exit? not if
    links @ array_count 1 > if
      "Only actions and exits can be linked to multiple destinations." .tell
      0 exit
    then
  then

  thing @ case
    exit? when (*** Exits ***)
      (* Fail on an existing link, unless you own it and it's NIL. *)
      (* No existing link means anyone can link it, which is a little silly, but that's how it works in the built-in commands *)
      thing @ getlink if
        "me" match thing @ controls if
          thing @ getlink #-4 = not if
            "That exit is already linked." .tell
            0 exit
          then
        else
          "Permission denied. (you don't control the exit to relink)" .tell
          0 exit
        then
      then
      (* Check for sufficient pennies *)
      thing @ owner "me" match owner = if
        tp_link_cost @ tp_exit_cost @ + M-LIB-PENNIES-ChkPayFor not if
          { "It costs " tp_link_cost @ tp_exit_cost @ + " " "pennies" sysparm " to link this exit."  }join .tell
          0 exit
        then
      else
        "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
          "Only authorized builders may seize exits." .tell
           0 exit
        then
        tp_link_cost @ M-LIB-PENNIES-ChkPayFor not if
          { "It costs " tp_link_cost @ " " "pennies" sysparm " to link this exit."  }join .tell
          0 exit
        then
      then
      (* Link has been validated, start looking up destinations *)
      0 var! alreadySeenPR
      { }array var! linkRefs
      links @ foreach
        swap pop
        1 1 0 0 M-LIB-MATCH-Match var! thisLinkRef

        thisLinkRef @ not if
          continue
        then

        thisLinkRef @ player? "teleport_to_player" sysparm "no" = and if
          { "You can't link to players. Destination " thisLinkRef @ unparseobj " ignored." }join .tell
          continue
        then

        "me" match thing @ thisLinkRef @ canLinkTo not if
          { "You can't link to " thisLinkRef @ unparseobj "." }join .tell
          continue
        then

        thisLinkRef @ player? thisLinkRef @ room? or thisLinkRef @ program? or if
          alreadySeenPR @ if
            { "Only one player, room, or program destination allowed. Destination " thisLinkRef @ unparseobj " ignored." }join .tell
            continue
          then
          1 alreadySeenPR !
        then

        thisLinkRef @ exit? if
          thing @ thisLinkRef @ exitLoopCheck if
            { "Destination " thisLinkRef @ unparseobj " would create a loop, ignored." }join .tell
          then
        then

        thisLinkRef @ linkRefs @ array_appenditem linkRefs !
        linkRefs @ array_count 50 >= if
          "Too many destinations, rest ignored." .tell
          break
        then
      repeat

      linkRefs @ array_count not if
        "No destinations linked." .tell
        0 exit
      then
    
      thing @ linkRefs @ doSetLinksArray
      dup if .tell 0 exit else pop then
 
      linkRefs @ foreach
        swap pop
        "Linked to " swap unparseobj strcat "." strcat .tell
      repeat
      (* Charge pennies and change ownership if appropriate *)
      thing @ owner "me" match owner = if
        "me" match tp_link_cost @ M-LIB-PENNIES-DoPayFor
      else
        "me" match tp_link_cost @ tp_exit_cost @ + M-LIB-PENNIES-DoPayFor
        thing @ owner tp_exit_cost @ addpennies
        thing @ "me" match setown
      then
    end
    dup player? swap thing? or when (*** Players / Things ***)
      links @ 0 [] 1 1 1 1 M-LIB-MATCH-Match var! newHome
      newHome @ not if 0 exit then

      "me" match newHome @ controls not "me" match thing @ newHome @ canLinkTo not and if
        "Permission denied. (you don't control the thing, or you can't link to dest)" .tell
        0 exit
      then

      thing @ { newHome @ }array doSetLinksArray
      dup if .tell 0 exit else pop then

      "Home set." .tell
    end
    room? when (*** Rooms ***)
      links @ 0 [] 1 1 0 1 M-LIB-MATCH-Match var! newDropto
      newDropto @ not if 0 exit then

      #-3 newDropto @ = not if
        "me" match newDropto @ controls not "me" match thing @ newDropto @ canLinkTo not and thing @ newDropto @ = or if
          "Permission denied. (you don't control the thing, or you can't link to the dropto)" .tell
          0 exit
        then
      then

      thing @ { newDropto @ }array doSetLinksArray
      dup if .tell 0 exit else pop then

      "Dropto set." .tell
    end
    program? when (*** Programs ***)
      "You can't link programs to things!" .tell
      0 exit
    end
  endcase

  1
;
PUBLIC M-CMD-AT_LINK-Link
$libdef M-CMD-AT_LINK-Link

(*****************************************************************************)
(*                                 cmdLink                                   *)
(*****************************************************************************)
: help (  --  )
  "@LINK <object1>=<object2> [; <object3>; ...  <objectn> ]" .tell
  " " .tell
  "  Links <object1> to <object2>, provided you control <object1>, and <object2> is either controlled by you or linkable.  Actions may be linked to more than one thing, specified in a list separated by semi-colons." .tell
  "Also see: @RELINK and @UNLINK" .tell
;
 
: main ( s --  )
  "#help" over stringpfx if pop help exit then
  
  "=" split
  strip var! destination
  strip var! exitname

  (* Perform link *)
  exitname @ destination @ M-CMD-AT_LINK-Link pop
;
.
c
q
@register m-cmd-@link.muf=m/cmd/at_link
@set $m/cmd/at_link=L
@set $m/cmd/at_link=M3
@set $m/cmd/at_link=W

