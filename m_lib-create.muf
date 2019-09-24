@program lib-create.muf
1 99999 d
i
(*****************************************************************************)
(* lib/create.muf $lib/create                               Header: xx lines *)
(*    A library which allows programs to create objects, with checks for     *)
(*    permissions and proper penny charges.  {TODO: And quota support}       *)
(*                                                                           *)
(* FEATURES:                                                                 *)
(*  o Create objects and manage links in ways that mirror the stock creation *)
(*    commands, including permission checks and managing penny costs, which  *)
(*    normally requires a wizbit.                                            *)
(*                                                                           *)
(* PUBLIC PROCEDURES:                                                        *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   I've endevored to make this code function identically to the built-in   *)
(*   Fuzzball MUCK object creation routines as possible, but the behavior of *)
(*   some fb6 primitives {relating to spending and reclaiming pennies} won't *)
(*   allow this. So this library only officially supports fb7 and above,     *)
(*   although it can work on fb6 and possibly lower.                         *)
(*   primitives do not allow it.                                             *)
(*                                                                           *)
(*   https://github.com/fuzzball-muck/fuzzball/issues/457                    *)
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
 
$define DEFAULT_QUOTA
{
  "thing" -1
  "room" -1
  "exit" -1
  "program" -1
}dict
$enddef

(* End user configurable options *)

$def ENDOWMENT_EQUATION        5 / --               (* Equation for pennies spent into object value *)
$def ENDOWMENT_EQUATION_STRING "((<cost> / 5) - 1)" (* The above equation in human readable form *)
$def COST_EQUATION             ++ 5 *               (* Inverse of ENDOWMENT_EQUATION. Desired object value into pennies required *)

(*****************************************************************************)
(*                           Support Functions                               *)
(*****************************************************************************)
: chkPerms (  -- b )
  caller mlevel 3 < if
    "Requires MUCKER level 3 or above." abort
  then
;
 
: chkPayFor ( i -- b )
  "me" match "WIZARD" flag? if (* Wizards have a sideways 8 in their pockets. *)
    pop 1 exit
  then
  
  "me" match pennies <=
;
 
: doPayFor ( i --  )
  "me" match "WIZARD" flag? if
    pop exit
  then
  
  dup chkPayFor not if
    "Not enough pennies!" abort
  then
  
  "me" match owner swap -1 * addpennies
;
 
 (* Error trapped creation functions *)
: doSetLinksArray ( d1 a -- s )
  2 try
    setlinks_array "" exit
  catch
    exit
  endcatch
;
 
: doNewObject ( d s -- d s )
  2 try
    newobject "" exit
  catch
    #-1 swap exit
  endcatch
;
 
: doNewRoom ( d s -- d s )
  2 try
    newroom "" exit
  catch
    #-1 swap exit
  endcatch
;
 
: doNewExit ( d s -- d s )
  2 try
    newexit "" exit
  catch
    #-1 swap exit
  endcatch
;
 
: doRecycle ( d -- s )
  1 try
    recycle "" exit
  catch
    exit
  endcatch
;

: absNameMatch ( s -- d )
  dup "#" 1 strncmp not if
    1 strcut swap pop
    dup number? not if
      pop #-1 exit
    then
    stod exit
  then
  
  match
;
 
: noisyMatchResults[ str:name bool:nohome bool:nonil -- ref:dbref ] ( s -- d )
  name @ absNameMatch var! matchResult
  
  matchResult @ case
    -4 < when (* In case any more special dbrefs are created *)
      "Unrecognized match result" abort
    end
    #-1 = when (* Invalid *)
      { "I don't understand '" name @ "'." }join .tell
    end  
    #-2 = when (* Ambiguous *)
      { "I don't know which '" name @ "' you mean!" }join .tell
    end  
    #-3 = when (* HOME *)
      nohome @ if
        { "I don't understand '" name @ "'." }join .tell
        #-1 matchResult !
      then
    end
    #-4 = when (* NIL *)
      nonil @ if
        { "I don't understand '" name @ "'." }join .tell
        #-1 matchResult !
      then
    end  
    ok? not when (* Garbage *)
      { "I don't understand '" name @ "'." }join .tell
      #-1 matchResult !
    end
  endcase

  matchResult @
;

: noisyMatchResults_array ( a -- a' )
  { }list var! retval
 
  foreach
    swap pop
    strip
    noisyMatchResults
    
    dup not if
      pop continue
    then
    
    retval @ array_appenditem retval !
  repeat
  
  retval @
;

: controls_ok ( d1 d2 -- i )
  (* Replicate the behavior of the built in C 'controls' function. This is needed to handle things like #-3 'HOME' *)
  dup ok? not if
    pop pop 0 exit
  then

  controls
;

(*****************************************************************************)
(*                            Public Functions                               *)
(*****************************************************************************)
$pubdef :

(*****************************************************************************)
(*                            CREATE-GetQuota                                *)
(*****************************************************************************)
: CREATE-GetQuota[ ref:player str:type -- int:quota ]
  chkPerms

  { type @ }list { "thing" "exit" "room" "program" }list array_intersect not if "Quota type not recognized." abort then

  player @ "@/quota/" type @ strcat getpropstr number? if
    player @ "@/quota/" type @ strcat getpropstr atoi
    dup -1 >= if exit then
    pop
  then

  prog "@/quota/" type @ strcat getpropstr number? if
    prog "@/quota/" type @ strcat getpropstr atoi
    dup -1 >= if exit then
    pop
  then

  DEFAULT_QUOTA type @ []
;
PUBLIC CREATE-GetQuota
$libdef CREATE-GetQuota

(*****************************************************************************)
(*                            CREATE-GetUsage                                *)
(*****************************************************************************)
: CREATE-GetUsage[ ref:player str:type -- int:usage ]
  chkPerms

  player @ ok? not if exit 0 then
  player @ player? not if exit 0 then

  var statsPos
  type @ case
    "room" = when
      1 statsPos !
    end
    "exit" = when
      2 statsPos !
    end
    "thing" = when
      3 statsPos !
    end
    "program" = when
      4 statsPos !
    end
    default
      "Quota usage type not recognized." abort
    end
  endcase

  { player @ stats }array statsPos @ []
;
PUBLIC CREATE-GetUsage
$libdef CREATE-GetUsage

(*****************************************************************************)
(*                        CREATE-NoisyQuotaCheck                             *)
(*****************************************************************************)
: CREATE-NoisyQuotaCheck[ str:type -- bool:hasanyroom? ]
  "me" match "WIZARD" flag? not if
    "me" match type @ CREATE-GetQuota
    dup -1 != if
      "me" match type @ CREATE-GetUsage swap >= if
        { "You already have too many '" type @ "' objects. See @quota." }join .tell
        0 exit
      then
    else
      pop
    then
  then
  1
;
PUBLIC CREATE-NoisyQuotaCheck
$libdef CREATE-NoisyQuotaCheck

(*****************************************************************************)
(*                       CREATE-EndowmentEquation                            *)
(*****************************************************************************)
: CREATE-EndowmentEquation ( -- s )
  chkPerms
  
  ENDOWMENT_EQUATION_STRING
;
PUBLIC CREATE-EndowmentEquation
$libdef CREATE-EndowmentEquation

(*****************************************************************************)
(*                          CREATE-GetEndowment                              *)
(*****************************************************************************)
: CREATE-GetEndowment ( i -- i )
  chkPerms
  "i" checkargs
  
  ENDOWMENT_EQUATION
;
PUBLIC CREATE-GetEndowment
$libdef CREATE-GetEndowment

(*****************************************************************************)
(*                             CREATE-GetCost                                *)
(*****************************************************************************)
: CREATE-GetCost ( i -- i )
  chkPerms
  "i" checkargs
  
  COST_EQUATION
;
PUBLIC CREATE-GetCost
$libdef CREATE-GetCost

(*****************************************************************************)
(*                             CREATE-Link                                   *)
(*****************************************************************************)
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

: CREATE-Link[ str:thing str:links -- bool:success? ]
  chkPerms

  "link_cost" sysparm atoi var! tp_link_cost
  "exit_cost" sysparm atoi var! tp_exit_cost
  
  thing @ 1 1 noisyMatchResults thing !

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
        tp_link_cost @ tp_exit_cost @ + chkPayFor not if
          { "It costs " tp_link_cost @ tp_exit_cost @ + " " "pennies" sysparm " to link this exit."  }join .tell
          0 exit
        then
      else
        "me" match "BUILDER" flag? "me" match "WIZARD" flag? or not if
          "Only authorized builders may seize exits." .tell
           0 exit
        then
        tp_link_cost @ chkPayFor not if
          { "It costs " tp_link_cost @ " " "pennies" sysparm " to link this exit."  }join .tell
          0 exit
        then
      then
      (* Link has been validated, start looking up destinations *)
      0 var! alreadySeenPR
      { }array var! linkRefs
      links @ foreach
        swap pop
        0 0 noisyMatchResults var! thisLinkRef

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
        "me" match 0 tp_link_cost @ - addpennies
      else
        "me" match 0 tp_link_cost @ tp_exit_cost @ + - addpennies
        thing @ owner tp_exit_cost @ addpennies
        thing @ "me" match setown
      then
    end
    dup player? swap thing? or when (*** Players / Things ***)
      links @ 0 [] 1 1 noisyMatchResults var! newHome
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
      links @ 0 [] 0 1 noisyMatchResults var! newDropto
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
PUBLIC CREATE-Link
$libdef CREATE-Link

(*****************************************************************************)
(*                            CREATE-Unlink                                  *)
(*****************************************************************************)
: controlsLink[ ref:who ref:thing -- bool:success? ]
  thing @ ok? not if
    0 exit
  then

  thing @ program? if
    0 exit
  then

  thing @ getlinks array_make foreach
    swap pop
    dup ok? if
      who @ swap controls if 1 exit then
    else
      pop
    then
  repeat
  0 exit
;

: CREATE-Unlink[ str:thing -- bool:success? ]
  chkPerms

  "link_cost" sysparm atoi var! tp_link_cost
  "player_start" sysparm match var! tp_player_start
  
  thing @ 1 1 noisyMatchResults thing !

  thing @ not if
    0 exit
  then

  "me" match thing @ controls "me" match thing @ controlsLink or not if
    "Permission denied. (You don't control the exit or its link)" .tell
    0 exit
  then

  thing @ case
    exit? when
      thing @ getlink var! doRefund
      thing @ #-1 setlink
      "Unlinked." .tell
      doRefund @ if
        "me" match tp_link_cost @ addpennies
      then
      thing @ mlevel if
        thing @ "!mucker" set
        "Action priority Level reset to 0." .tell
      then
    end
    room? when
      thing @ #-1 setlink
      "Dropto removed." .tell
    end
    thing? when
      thing @ thing @ owner setlink
      "Thing's home reset to owner." .tell
    end
    player? when
      thing @ tp_player_start setlink
      "Player's home reset to default player start room." .tell
    end
    default
      "You can't unlink that!" .tell
    end
  endcase
  1
;
PUBLIC CREATE-Unlink
$libdef CREATE-Unlink

(*****************************************************************************)
(*                             CREATE-Clone                                  *)
(*****************************************************************************)
: CREATE-Clone[ str:thingname -- ref:thing ]
  chkPerms

  "thing" CREATE-NoisyQuotaCheck not if #-1 exit then

  "max_object_endowment" sysparm atoi var! tp_max_endowment
  "object_cost" sysparm atoi var! tp_object_cost

  thingname @ not if
    "Clone what?" .tell
    0 exit
  then

  thingname @ 1 1 noisyMatchResults var! thing

  thing @ not if
    0 exit
  then

  thing @ thing? not if
    "That is not a cloneable object." .tell
    0 exit
  then

  thing @ name "thing" ext-name-ok? not if
    "You cannot clone an object with this name." .tell
    0 exit
  then

  "me" match thing @ controls not if
    "Permission denied. (you can't clone this)"
    0 exit
  then

  thing @ pennies CREATE-GetCost var! cost

  cost @ tp_object_cost @ < if
    tp_object_cost @ cost !
  then

  cost @ chkPayFor not if
    { "Sorry, you don't have enough " "pennies" sysparm "." }join .tell
    #-1 exit
  then

  thing @ copyobj var! newThing
  newThing @ thing @ location moveto

  { "Object " thing @ unparseobj " cloned as " newThing @ unparseobj "." }join .tell

  (* Endow the object *)
  cost @ doPayFor
  thing @ pennies tp_max_endowment @ > if
    newThing @ tp_max_endowment @ addpennies
  else
    newThing @ thing @ pennies addpennies
  then
;
PUBLIC CREATE-Clone
$libdef CREATE-Clone

(*****************************************************************************)
(*                             CREATE-Create                                 *)
(*****************************************************************************)
: CREATE-Create[ str:thingname str:payment -- ref:thing ]
  chkPerms

  "thing" CREATE-NoisyQuotaCheck not if #-1 exit then

  "max_object_endowment" sysparm atoi var! tp_max_endowment
  "object_cost" sysparm atoi var! tp_object_cost

  thingname @ not if
    "Please specify a valid name for this thing." .tell
    #-1 exit
  then

  thingname @ name-ok? not if
    "Please specify a valid name for this thing." .tell
    #-1 exit
  then
  
  payment @ atoi payment !
  payment @ 0 < if
    "You can't create an object for less than nothing!" .tell
    #-1 exit
  then

  payment @ tp_object_cost @ < if
    tp_object_cost @ payment !
  then
  
  payment @ chkPayFor not if
    { "Sorry, you don't have enough " "pennies" sysparm "." }join .tell
    #-1 exit
  then
  
  (* Create the object *)
  "me" match thingname @ doNewObject
  dup if .tell pop #-1 exit else pop then
  
  "Object " over name strcat " (#" strcat over intostr strcat ") created." strcat .tell
  
  (* Endow the object *)
  payment @ doPayFor
  payment @ CREATE-GetEndowment var! thingValue
  thingValue @ tp_max_endowment @ > if tp_max_endowment @ thingValue ! then
  thingValue @ 0 < if 0 thingValue ! then
  dup thingValue @ addpennies
;
PUBLIC CREATE-Create
$libdef CREATE-Create
 
(*****************************************************************************)
(*                              CREATE-Dig                                   *)
(*****************************************************************************)
: CREATE-Dig[ str:roomname str:parent -- ref:dbref ]
  chkPerms

  "room" CREATE-NoisyQuotaCheck not if #-1 exit then

  roomname @ not if
    "You must specify a name for the room." .tell
    #-1 exit
  then
  
  roomname @ name-ok? not if
    "That's a silly name for a room!" .tell
    #-1 exit
  then
 
  "room_cost" sysparm atoi var! cost
  
  cost @ chkPayFor not if
    { "Sorry, you don't have enough " "pennies" sysparm " to dig a room." }join .tell
    #-1 exit
  then
  
  (* Find default parent and create room *)
  "me" match location begin
    dup while
    
    dup "ABODE" flag? if
      break
    then
    
    location
  repeat
  
  dup not if
    pop "default_room_parent" sysparm stod
  then
  
  roomname @ doNewRoom
  dup if .tell pop #-1 exit else pop then
  var! newroom
  
  "Room " newroom @ name strcat " (#" strcat newroom @ intostr strcat ") created." strcat .tell
  
  cost @ doPayFor
  
  parent @ if
    "Trying to set parent..." .tell

    parent @ 1 1 noisyMatchResults parent !

    parent @ ok? parent @ #-3 = or not if
      "Parent set to default." .tell
    else
      "me" match parent @ controls not parent @ "ABODE" flag? not and parent @ newroom @ = not and if
        "Permission denied. Parent set to default" .tell
      else
        newroom @ parent @ moveto
        "Parent set to " parent @ unparseobj strcat "." strcat .tell
      then
    then
  then

  newroom @
;
PUBLIC CREATE-Dig
$libdef CREATE-Dig
 
(*****************************************************************************)
(*                              CREATE-Action                                *)
(*****************************************************************************)
: CREATE-Action[ str:source str:exitname -- ref:room ]
  chkPerms

  "exit" CREATE-NoisyQuotaCheck not if #-1 exit then

  "exit_cost" sysparm atoi var! cost
  
  exitname @ not if
    "You must specify a direction or action name to open." .tell
    #-1 exit
  then
  
  exitname @ name-ok? not if
    "That's a strange name for an exit!" .tell
    #-1 exit
  then
  
  source @ not if
    "You must specify a source object." .tell
    #-1 exit
  then

  source @ 1 1 noisyMatchResults source !

  source @ not if
    #-1 exit
  then

  "me" match source @ controls not if
    "Permission denied. (you don't control the attachment point)" .tell
    #-1 exit
  then
  
  source @ exit? if
    "You can't attach an action to an action." .tell
    #-1 exit
  then
  
  source @ program? if
    "You can't attach an action to a program." .tell
    #-1 exit
  then
  
  cost @ chkPayFor not if
    { "Sorry, you don't have enough " "pennies" sysparm " to create an action/exit." }join .tell
    #-1 exit
  then
  
  source @ exitname @ doNewExit
  dup if .tell pop #-1 exit else pop then
  
  cost @ doPayFor
  
  "Action " over name strcat " (#" strcat over intostr strcat ") created." strcat .tell
;
PUBLIC CREATE-Action
$libdef CREATE-Action
 
(*****************************************************************************)
(*                             CREATE-Recycle                                *)
(*****************************************************************************)
: CREATE-Recycle[ str:thing int:confirmation -- bool:success? ]
  chkPerms

  thing @ 1 1 noisyMatchResults thing !

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
PUBLIC CREATE-Recycle
$libdef CREATE-Recycle
 
: main
  pop
;
.
c
q
@register lib-create.muf=lib/create
@set $lib/create=L
@set $lib/create=M3
@set $lib/create=W

