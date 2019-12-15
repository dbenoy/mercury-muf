!@program m-lib-match.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-match.muf - $m/lib/match                                            *)
(*   A library for enhanced 'match' functionality. Used to find object dbref *)
(*   values based on names.                                                  *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-MATCH-match[ s:name x:opts -- d:dbref ]                           *)
(*     Takes a name string and searches for an object dbref using the MATCH  *)
(*     primitive. If nothing is found, it returns #-1. If ambiguous, it      *)
(*     returns #-2. If HOME, it returns #-3. If NIL it returns #-4.          *)
(*                                                                           *)
(*     opts:                                                                 *)
(*       "quiet" ("yes"/"no")                                                *)
(*         Don't display failure messages to the player.                     *)
(*                                                                           *)
(*       "tag"                                                               *)
(*         Tag any output with this string.                                  *)
(*                                                                           *)
(*       "match_absolute" ("yes"/"no"/"builders"/"wizards")                  *)
(*         Allow #dbref matching.                                            *)
(*                                                                           *)
(*       "match_player" ("yes"/"no"/"builders"/"wizards")                    *)
(*         Allow *player matching.                                           *)
(*                                                                           *)
(*       "match_registered" ("yes"/"no"/"builders"/"wizards")                *)
(*         Allow $name registered object matching.                           *)
(*                                                                           *)
(*       "match_me" ("yes"/"no"/"builders"/"wizards")                        *)
(*         Allow "ME" matching.                                              *)
(*                                                                           *)
(*       "match_here" ("yes"/"no"/"builders"/"wizards")                      *)
(*         Allow "HERE" matching.                                            *)
(*                                                                           *)
(*       "match_home" ("yes"/"no"/"builders"/"wizards")                      *)
(*         Allow "HOME" matching.                                            *)
(*                                                                           *)
(*       "match_nil" ("yes"/"no"/"builders"/"wizards")                       *)
(*         Allow "NIL" matching.                                             *)
(*                                                                           *)
(*   M-LIB-MATCH-pmatch[ s:name x:opts -- d:dbref ]                          *)
(*     Searches for a player object by name. If nothing is found, it returns *)
(*     #-1. If ambiguous, it returns #-2.                                    *)
(*                                                                           *)
(*     opts:                                                                 *)
(*       "quiet" ("yes"/"no")                                                *)
(*         Don't display failure messages to the player.                     *)
(*                                                                           *)
(*       "tag"                                                               *)
(*         Tag any output with this string.                                  *)
(*                                                                           *)
(*       "match_me" ("yes"/"no")                                             *)
(*         Allow "ME" matching.                                              *)
(*                                                                           *)
(*       "match_start" ("no"/"online")                                       *)
(*         If this is set to "online" then it will check for an exact player *)
(*         match first, and if there are no matches, it will check the       *)
(*         list of connected players and try matching the beginning of       *)
(*         player names.                                                     *)
(*                                                                           *)
(*         Exact matches never return #-2                                    *)
(*                                                                           *)
(*   M-LIB-MATCH-register_object[ d:object s:regname ]                       *)
(*     Registers the specified object on the current player using the given  *)
(*     name (for $ notation registered name matching).                       *)
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
$NOTE    Find object dbrefs based on names.
$DOCCMD  @list __PROG__=2-94

(* Begin configurable options *)

(* Comment out to remove dependency on $m/lib/theme and $m/lib/color *)
$DEF M_LIB_THEME

(* End configurable options *)

$IFDEF M_LIB_THEME
  $INCLUDE $m/lib/theme
  $INCLUDE $m/lib/notify
  $INCLUDE $m/lib/color
  $DEF .tell M-LIB-NOTIFY-tell_color
  $DEF .err M-LIB-THEME-err
  $DEF .tag_err M-LIB-THEME-tag_err
$ELSE
  $DEF .tell tell
  $DEF .err
  $DEF .tag_err ": " strcat swap strcat
$ENDIF

$PUBDEF :

: match_opts_process[ x:opts_in -- x:opts_out ]
  var opt
  (* Set defaults *)
  {
    "quiet"            "yes"
    "tag"              ""
    "match_absolute"   "wizards"
    "match_player"     "wizards"
    "match_registered" "yes"
    "match_me"         "yes"
    "match_here"       "yes"
    "match_home"       "yes"
    "match_nil"        "yes"
  }dict var! opts_out
  (* Handle strings *)
  { "tag" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] opts_out @ opt @ ->[] opts_out !
  repeat
  (* Handle yes/no options *)
  { "quiet" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] "{yes|no}" smatch not if continue then
    opts_in @ opt @ [] "yes" stringcmp not opts_out @ opt @ ->[] opts_out !
  repeat
  (* Handle yes/no/builders/wizards options *)
  { "match_absolute" "match_player" "match_registered" "match_me" "match_here" "match_home" "match_nil" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] "{yes|no|builders|wizards}" smatch not if continue then
    opts_in @ opt @ []
    dup "wizards" stringcmp not if
      pop "me" match "WIZARD" flag?
    else dup "builders" stringcmp not if
      pop "me" match "WIZARD" flag? "me" match "BUILDER" flag? or
    else
      "yes" stringcmp not
    then then
    opts_out @ opt @ ->[] opts_out !
  repeat
  (* Return result *)
  opts_out @
;

: pmatch_opts_process[ x:opts_in -- x:opts_out ]
  var opt
  (* Set defaults *)
  {
    "quiet"            "yes"
    "tag"              ""
    "match_start"      "no"
    "match_me"         "no"
  }dict var! opts_out
  (* Handle strings *)
  { "tag" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] opts_out @ opt @ ->[] opts_out !
  repeat
  (* Handle yes/no options *)
  { "quiet" "match_me" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] "{yes|no}" smatch not if continue then
    opts_in @ opt @ [] "yes" stringcmp not opts_out @ opt @ ->[] opts_out !
  repeat
  (* Handle "match_start" *)
  { "match_start" }list foreach
    nip
    opt !
    opts_in @ opt @ [] string? not if continue then
    opts_in @ opt @ [] "{no|online}" smatch not if continue then
    opts_in @ opt @ []
    dup "online" stringcmp not if
      pop 2
    else
      "yes" stringcmp not
    then
    opts_out @ opt @ ->[] opts_out !
  repeat
  (* Return result *)
  opts_out @
;

(*****************************************************************************)
(*                             M-LIB-MATCH-match                             *)
(*****************************************************************************)
: M-LIB-MATCH-match[ s:name x:opts -- d:dbref ]
  (* Permissions inherited *)
  name @ string? not if "Non-string argument (1)." abort then
  opts @ array? not if "Non-array argument (2)." abort then
  opts @ match_opts_process opts !
  (* Perform the search *)
  name @ not if
    #-1
  else name @ "#" instr 1 = if
    opts @ "match_absolute" [] if
      name @ 1 strcut swap pop stod
    else
      #-1
    then
  else name @ "*" instr 1 = if
    opts @ "match_player" [] if
      name @ 1 strcut swap pop pmatch
    else
      #-1
    then
  else name @ "$" instr 1 = opts @ "match_registered" [] not and if
    #-1
  else name @ "me" stringcmp not opts @ "match_me" [] not and if
    #-1
  else name @ "here" stringcmp not opts @ "match_here" [] not and if
    #-1
  else name @ "home" stringcmp not opts @ "match_home" [] not and if
    #-1
  else name @ "nil" stringcmp not opts @ "match_nil" [] not and if
    #-1
  else
    name @ match
  then then then then then then then then
  var! match_result
  (* In case any more special dbrefs are created *)
  match_result @ -4 < if
    "Unrecognized match result" abort
  then
  (* Output to user *)
  opts @ "quiet" [] not if
    match_result @ #-1 = if (* Invalid *)
      { "'" name @ "' not found." }cat
    else match_result @ #-2 = if (* Ambiguous *)
      { "Which '" name @ "'?" }cat
    else
      ""
    then then
    dup if
      opts @ "tag" [] dup if
        .tag_err
      else
        pop .err
      then
      .tell
    else
      pop
    then
  then
  (* Return match *)
  match_result @
;
PUBLIC M-LIB-MATCH-match
$LIBDEF M-LIB-MATCH-match

(*****************************************************************************)
(*                            M-LIB-MATCH-pmatch                             *)
(*****************************************************************************)
: M-LIB-MATCH-pmatch[ s:name x:opts -- d:dbref ]
  (* Permissions inherited *)
  name @ string? not if "Non-string argument (1)." abort then
  opts @ array? not if "Non-array argument (2)." abort then
  opts @ pmatch_opts_process opts !
  (* Perform the search *)
  name @ not if
    #-1
  else
    name @ "me" stringcmp not opts @ "match_me" [] not and if
      #-1
    else
      name @ pmatch
    then
    dup not opts @ "match_start" [] 2 = and if
      pop name @ part_pmatch
    then
  then
  var! match_result
  (* Output to user *)
  opts @ "quiet" [] not if
    match_result @ #-1 = if (* Invalid *)
      { "Player '" name @ "' not found." }cat
    else match_result @ #-2 = if (* Ambiguous *)
      { "Which '" name @ "'?" }cat
    else
      ""
    then then
    dup if
      opts @ "tag" [] dup if
        .tag_err
      else
        pop .err
      then
      .tell
    else
      pop
    then
  then
  (* Return match *)
  match_result @
;
PUBLIC M-LIB-MATCH-pmatch
$LIBDEF M-LIB-MATCH-pmatch

(*****************************************************************************)
(*                        M-LIB-MATCH-register_object                        *)
(*****************************************************************************)
: M-LIB-MATCH-register_object[ d:object s:regname ]
  (* Permissions inherited *)

  object @ dbref? not if "Non-dbref argument (1)." abort then
  regname @ string? not if "Non-string argument (2)." abort then

  regname @ prop-name-ok? not if
    { "Registry name '" regname @ "' is not valid" }cat .tell
    exit
  then

  me @ "_reg/" regname @ strcat object @ setprop
  "Registered as $" regname @ strcat .tell
;
PUBLIC M-LIB-MATCH-register_object
$LIBDEF M-LIB-MATCH-register_object

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-match.muf=m/lib/match
!@set $m/lib/notify=M2
!@set $m/lib/notify=H
!@set $m/lib/notify=S
!@set $m/lib/notify=L

