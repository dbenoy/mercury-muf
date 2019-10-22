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
(*   M-LIB-MATCH-match[ str:name dict:opts -- ref:dbref ]                    *)
(*     Takes a name string and searches for an object dbref using the MATCH  *)
(*     primitive. If nothing is found, it returns #-1. If ambiguous, it      *)
(*     returns #-2. If HOME, it returns #-3. If NIL it returns #-4. Requires *)
(*     M3.                                                                   *)
(*                                                                           *)
(*     quiet: Don't display failure messages to users.                       *)
(*     absolute: Accept dbref strings in the form of #<number>               *)
(*     nohome: Never return #-3, and notify player if noisy.                 *)
(*     nonil: Never return #-4, and notify player if noisy.                  *)
(*                                                                           *)
(*   M-LIB-MATCH-register_object[ ref:object str:regname ]                   *)
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
$DOCCMD  @list __PROG__=2-51

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/program

$PUBDEF :

(*****************************************************************************)
(*                             M-LIB-MATCH-match                             *)
(*****************************************************************************)
: M-LIB-MATCH-match[ str:name dict:opts -- ref:dbref ]
  .needs_mlev3

  opts @ "quiet" [] "yes" stringcmp not var! quiet
  opts @ "absolute" [] "yes" stringcmp not var! absolute
  opts @ "nohome" [] "yes" stringcmp not var! nohome
  opts @ "nonil" [] "yes" stringcmp not var! nonil

  name @ string? not if "Non-string argument (1)." abort then

  name @ 1 strcut number? swap "#" = and absolute @ and if
    name @ 1 strcut swap pop stod
  else
    name @ match
  then
  var! matchResult

  matchResult @ case
    -4 < when (* In case any more special dbrefs are created *)
      "Unrecognized match result" abort
    end
    #-1 = when (* Invalid *)
      quiet @ not if { "I don't understand '" name @ "'." }join .tell then
    end
    #-2 = when (* Ambiguous *)
      quiet @ not if { "I don't know which '" name @ "' you mean!" }join .tell then
    end
    #-3 = when (* HOME *)
      nohome @ if
        quiet @ not if { "I don't understand '" name @ "'." }join .tell then
        #-1 matchResult !
      then
    end
    #-4 = when (* NIL *)
      nonil @ if
        quiet @ not if { "I don't understand '" name @ "'." }join .tell then
        #-1 matchResult !
      then
    end
    ok? not when (* Garbage *)
      quiet @ not if { "I don't understand '" name @ "'." }join .tell then
      #-1 matchResult !
    end
  endcase

  matchResult @
;
PUBLIC M-LIB-MATCH-match
$LIBDEF M-LIB-MATCH-match

(*****************************************************************************)
(*                        M-LIB-MATCH-register_object                        *)
(*****************************************************************************)
: M-LIB-MATCH-register_object[ ref:object str:regname ]
  .needs_mlev3

  object @ dbref? not if "Non-dbref argument (1)." abort then
  regname @ string? not if "Non-string argument (2)." abort then

  regname @ prop-name-ok? not if
    { "Registry name '" regname @ "' is not valid" }join .tell
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
!@set $m/lib/match=L
!@set $m/lib/match=M3

