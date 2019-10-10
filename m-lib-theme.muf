!@program m-lib-theme.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-theme.muf - $m/lib/theme                                            *)
(*   A central place for your MUCK's look and feel. You can edit properties  *)
(*   on this program object to change the colors and highlighting from many  *)
(*   programs at once.                                                       *)
(*                                                                           *)
(*   Safe for use with $m/lib/color MCC color codes, but not directly with   *)
(*   ansi strings.                                                           *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* EXAMPLES:                                                                 *)
(*   @set m-lib-theme.muf=_theme/fmt_obj_exit=[#AAAAAA]!%1!                  *)
(*   @action Test;t=here                                                     *)
(*   @muf $INCLUDE $m/lib/theme "t" match M-LIB-THEME-name .color_tell       *)
(*     > (In grey) !Test;t!                                                  *)
(*                                                                           *)
(*   @set m-lib-theme.muf=_theme/fmt_obj_exit=[#0000AA]{%1}                  *)
(*   @set m-lib-theme.muf=_theme/fmt_obj_exit_highlight=[#FFFFFF][%1]        *)
(*   @action Test;t=here                                                     *)
(*   @muf $INCLUDE $m/lib/theme "t" match M-LIB-THEME-fancy_exit .color_tell *)
(*     > (In blue with bright white [T]) {[T]est}                            *)
(*                                                                           *)
(*   @set m-lib-theme.muf=_theme/fmt_msg_tagged:[#00AA00](%1) %2             *)
(*   @muf $INCLUDE $m/lib/theme "Does not compute." "SYSTEM" .theme_tag_tell *)
(*     > (In green) (SYSTEM) Does not compute.                               *)
(*                                                                           *)
(* PROPERTIES:                                                               *)
(*   "_theme/fmt_obj_exit"                                                   *)
(*     On this program object: Format the names of exits. %1 is replaced by  *)
(*     the name itself.                                                      *)
(*                                                                           *)
(*   "_theme/fmt_obj_exit_highlight"                                         *)
(*     On this progrom object. This is used by M-LIB-THEME-exit_name for     *)
(*     when a component of the exit gets highlighted. %1 is replaced by the  *)
(*     text being highlighted.                                               *)
(*                                                                           *)
(*   "_theme/fmt_obj_player_awake"                                           *)
(*     On this program object: Format the names of non-wizard players who    *)
(*     are currently logged in. %1 is replaced by the name itself.           *)
(*                                                                           *)
(*   "_theme/fmt_obj_player_asleep"                                          *)
(*     On this program object: Format the names of non-wizard players who    *)
(*     are currently not logged in. %1 is replaced by the name itself.       *)
(*                                                                           *)
(*   "_theme/fmt_obj_player_wawake"                                          *)
(*     On this program object: Format the names of unquelled wizard players  *)
(*     who are currently logged in. %1 is replaced by the name itself.       *)
(*                                                                           *)
(*   "_theme/fmt_obj_player_wasleep"                                         *)
(*     On this program object: Format the names of unquelled wizard players  *)
(*     who are currently not logged in. %1 is replaced by the name           *)
(*     itself.                                                               *)
(*                                                                           *)
(*   "_theme/fmt_obj_program"                                                *)
(*     On this program object: Format the names of program objects. %1 is    *)
(*     replaced by the name itself.                                          *)
(*                                                                           *)
(*   "_theme/fmt_obj_room"                                                   *)
(*     On this program object: Format the names of room objects. %1 is       *)
(*     replaced by the name itself.                                          *)
(*                                                                           *)
(*   "_theme/fmt_obj_thing"                                                  *)
(*     On this program object: Format the names of non-puppet thing objects. *)
(*     %1 is replaced by the name itself.                                    *)
(*                                                                           *)
(*   "_theme/fmt_obj_thing_pawake"                                           *)
(*     On this program object: Format the names of puppet objects whose      *)
(*     owner is currently logged in. %1 is replaced by the name itself.      *)
(*                                                                           *)
(*   "_theme/fmt_obj_thing_pasleep"                                          *)
(*     On this program object: Format the names of puppet objects whose      *)
(*     owner is not currently logged in. %1 is replaced by the name          *)
(*     itself.                                                               *)
(*                                                                           *)
(*   "_theme/fmt_obj_flagref"                                                *)
(*     On this program object: Format the dbref-and-flags component of the   *)
(*     M-LIB-THEME-unparseobj call. %1 is replaced by the dbref and %2 is    *)
(*     replaced by the flags.                                                *)
(*                                                                           *)
(*   "_theme/fmt_msg_tagged"                                                 *)
(*     The format for 'tagged' messages used by M-LIB-THEME-tag_line. %1 is  *)
(*     replaced by the message text, and %2 is replaced by the tag.          *)
(*                                                                           *)
(*   "_theme/fmt_msg_error"                                                  *)
(*     The format for 'error' messages used by M-LIB-THEME-err_line. %1      *)
(*     is replaced by the message text.                                      *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-THEME-fancy_exit[ ref:exit -- str:name ]                          *)
(*     Generate a name for an exit that takes the first alias of an exit and *)
(*     highlights it using information from the remaining aliases. For       *)
(*     example, Test;t becomes something like (T)est and South East;se       *)
(*     becomes something like (S)outh (E)ast.                                *)
(*                                                                           *)
(*     The exact results should be considered black magic and subject to     *)
(*     change in future versions, but if you have any () or [] tags entered  *)
(*     into the first alias, then the function will treat this as a manual   *)
(*     override and highlight those characters only, replacing the brackets. *)
(*                                                                           *)
(*   M-LIB-THEME-line_err[ str:msg -- str:line ]                             *)
(*     Creates an error message from the given string using the theme.       *)
(*     For example:                                                          *)
(*       Not enough pennies.                                                 *)
(*     might become something like one of these:                             *)
(*       ERROR: Not enough pennies.                                          *)
(*       Not enough pennies. See @help for more information.                 *)
(*       ---~~!! Not enough pennies. !!~~---                                 *)
(*                                                                           *)
(*   M-LIB-THEME-line_tag[ str:msg str:tag -- str:line ]                     *)
(*     Creates a 'tagged' message from the given strings using the theme.    *)
(*     For example:                                                          *)
(*       OOC" "I have to leave                                               *)
(*     might become something like one of these:                             *)
(*       [OOC] I have to leave                                               *)
(*       OOC - I have to leave                                               *)
(*       #OOC ( I have to leave )                                            *)
(*                                                                           *)
(*   M-LIB-THEME-name[ ref:object -- str:name ]                              *)
(*     Like the NAME primitive, but using the theme.                         *)
(*                                                                           *)
(*   M-LIB-THEME-unparseobj[ ref:object -- str:name ]                        *)
(*     Like the UNPARSEOBJ primitive, but using the theme.                   *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October, 2019                            *)
(*      - Original implementation.                                           *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) <year(s)>                                                   *)
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
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    Color coding and theming.
$DOCCMD  @list __PROG__=2-148

(* Begin configurable options *)

$DEFINE DEFAULT_THEME
  {
    "fmt_obj_exit"            "%1"
    "fmt_obj_exit_highlight"  "(%1)"
    "fmt_obj_program"         "%1"
    "fmt_obj_player_awake"    "%1"
    "fmt_obj_player_asleep"   "%1"
    "fmt_obj_player_wawake"   "%1"
    "fmt_obj_player_wasleep"  "%1"
    "fmt_obj_room"            "%1"
    "fmt_obj_thing"           "%1"
    "fmt_obj_thing_pawake"    "%1"
    "fmt_obj_thing_pasleep"   "%1"
    "fmt_obj_flagref"         "(%1%2)"
    "fmt_msg_tagged"          "%2: %1"
    "fmt_msg_error"           "ERROR: %1"
  }dict
$ENDDEF

(* End configurable options *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/color

$PUBDEF :

(* ------------------------------------------------------------------------- *)
: theme_get ( s -- s )
  prog "_theme/" 3 pick strcat getpropstr
  dup if
    nip
  else
    pop
    DEFAULT_THEME swap []
    dup string? not if pop "" then
  then
;

: arg_sub[ str:source arr:args -- str:result ]
  source @ "%" explode_array
  1 array_cut swap array_vals pop var! result
  foreach
    nip
    dup 1 strcut pop number? if
      1 strcut swap atoi --
      args @ swap [] dup not if pop "" then
      swap strcat
    else
      "%" swap strcat
    then
    result @ swap strcat result !
  repeat
  result @
;

(* ------------------------------------------------------------------------ *)

: name_prop ( d -- s )
  dup exit? if
    "fmt_obj_exit" exit
  then
  dup player? if
    dup "WIZARD" flag? if
      dup awake? if
        "fmt_obj_player_wawake" exit
      else
        "fmt_obj_player_wasleep" exit
      then
    else
      dup awake? if
        "fmt_obj_player_awake" exit
      else
        "fmt_obj_player_asleep" exit
      then
    then
  then
  dup program? if
    "fmt_obj_program" exit
  then
  dup room? if
    "fmt_obj_room" exit
  then
  dup thing? if
    dup "ZOMBIE" flag? if
      dup awake? if
        "fmt_obj_thing_pawake" exit
      else
        "fmt_obj_thing_pasleep" exit
      then
    else
      "fmt_obj_thing" exit
    then
  then
;

(* Get the aliases of an exit sorted from shortest to longest *)
: sorted_aliases[ ref:exit -- arr:aliases ]
  {
    exit @ name ";" explode_array 1 array_cut swap pop foreach
      nip
      var! alias
      {
        "name" alias @
        "length" alias @ strlen
      }dict
    repeat
  }list
  SORTTYPE_CASE_ASCEND "length" array_sort_indexed
  {
    swap foreach
      nip
      "name" []
    repeat
  }list
;

(* Highlight splits: first string represents non-highlighted, then highlighted next, and so on, alternating. *)

(* Given an exit, if its name already has brackets highlighting certain characters, split on those. *)
: exit_highsplit_existing[ str:exit_name -- arr:splits ]
  (* Find the locations of existing bracket highlights, if any *)
  { }list var! found_highlights
  "" var! bracket_expect
  0 var! bracket_start
  0 var! at_char
  exit_name @ begin
    1 strcut swap
    (* Deal with bracket start *)
    dup "[" = over "(" = or if
      (* Bail if we find a nested bracket. *)
      bracket_expect @ if
        pop pop
        { }list exit
      then
      (* Add this to the found highlights list. *)
      at_char @ bracket_start !
      dup "[" = if
        "]" bracket_expect !
      else
        ")" bracket_expect !
      then
    then
    (* Deal with bracket end *)
    dup "]" = over ")" = or if
      (* Bail if we're not currently in the matching bracket, or if there's nothing between them *)
      dup bracket_expect @ != at_char @ -- bracket_start @ <= or if
        pop pop
        { }list exit
      then
      (* Store the result and reset the bracket tracker. *)
      { "start" bracket_start @ "length" at_char @ bracket_start @ - ++ }dict found_highlights @ array_appenditem found_highlights !
      "" bracket_expect !
    then
    (* Bail if a space appears between the brackets *)
    dup " " = bracket_expect @ and if
      pop pop
      { }list exit
    then
    (* Finished with this character *)
    pop
    at_char ++
    dup not
  until
  pop
  found_highlights @ not if
    { }list exit
  then
  (* if the entire thing is brackets that also doesn't count. *)
  found_highlights @ array_count 1 = if
    found_highlights @ 0 [] "start" [] 1 = found_highlights @ 0 [] "length" [] exit_name @ strlen = and if
      { }list exit
    then
  then
  (* Perform the split *)
  { }list var! splits
  found_highlights @ SORTTYPE_CASE_DESCEND "start" array_sort_indexed foreach
    nip
    var! highlight
    exit_name @ highlight @ "start" [] strcut highlight @ "length" [] strcut
    splits @ 0 array_insertitem splits !
    1 strcut swap pop
    dup strlen -- strcut pop
    splits @ 0 array_insertitem splits !
    exit_name !
  repeat
  exit_name @ splits @ 0 array_insertitem splits !
  splits @
;

: exit_highsplit_startswith[ str:exit_name str:alias -- arr:splits ]
  exit_name @ alias @ stringpfx if
    { "" exit_name @ alias @ strlen strcut }list
  else
    { }list
  then
;

$DEF EINSTRING over swap instring dup not if pop strlen else nip -- then
: exit_highsplit_startwords[ str:exit_name str:alias bool:fullonly -- arr:splits ]
  { "" }list var! splits
  alias @ begin
    1 strcut swap
    exit_name @ over stringpfx not if
      pop pop
      { }list exit
    then
    splits @ array_appenditem splits !
    exit_name @ exit_name @ " " EINSTRING ++ strcut swap
    1 strcut swap pop splits @ array_appenditem splits !
    exit_name !
    dup not
  until
  pop
  exit_name @ if
    fullonly @ if
      { }list exit
    then
      splits @ splits @ array_count -- []
      exit_name @ strcat
      splits @ splits @ array_count -- ->[] splits !
  then
  splits @
;

: exit_highsplit[ ref:exitobj -- arr:splits ]
  exitobj @ name ";" split pop var! exit_name
  (* Check for manually placed highlights *)
  exit_name @ exit_highsplit_existing
  dup if exit else pop then
  (* If the exit name has brackets in it, but we were unable to find the highlights, then just give up. *)
  var alias
  exitobj @ sorted_aliases var! aliases
  (* First priority checks *)
  aliases @ foreach
    nip
    alias !
    (* See if this alias matches the first letter of each word, starting from the beginning. *)
    exit_name @ alias @ 1 exit_highsplit_startwords
    dup if exit else pop then
  repeat
  (* Second priority checks *)
  aliases @ foreach
    nip
    alias !
    (* See if this alias matches the beginning of the string *)
    exit_name @ alias @ exit_highsplit_startswith
    dup if exit else pop then
    (* See if this alias matches the first letter of the first few words, starting from the beginning *)
    exit_name @ alias @ 0 exit_highsplit_startwords
    dup if exit else pop then
  repeat
  (* No dice *)
  { exit_name @ }list
;

: fmt_fancy_exit[ ref:exitobj -- str:result ]
  "" var! result
  0 var! highlight_me
  exitobj @ exit_highsplit foreach
    nip
    highlight_me @ if
      "fmt_obj_exit_highlight" theme_get swap 1 array_make arg_sub
    then
    result @ swap strcat result !
    highlight_me @ not highlight_me !
  repeat
  result @
;

(*****************************************************************************)
(*                          M-LIB-THEME-fancy_exit                           *)
(*****************************************************************************)
: M-LIB-THEME-fancy_exit[ ref:exitobj -- str:name ]
  (* M1 OK *)
  exitobj @ dbref? not if "Non-dbref argument (1)." abort then
  exitobj @ fmt_fancy_exit
;
PUBLIC M-LIB-THEME-fancy_exit
$LIBDEF M-LIB-THEME-fancy_exit

(*****************************************************************************)
(*                             M-LIB-THEME-name                              *)
(*****************************************************************************)
: M-LIB-THEME-name[ ref:object -- str:name ]
  (* M1 OK *)
  object @ dbref? not if "Non-dbref argument (1)." abort then
  object @ name_prop theme_get { object @ name }list arg_sub
;
PUBLIC M-LIB-THEME-name
$LIBDEF M-LIB-THEME-name

(*****************************************************************************)
(*                           M-LIB-THEME-line_err                            *)
(*****************************************************************************)
: M-LIB-THEME-line_err[ str:msg -- str:line ]
  (* M1 OK *)
  msg @ string? not if "Non-string argument (1)." abort then
  "fmt_msg_error" theme_get { msg @ }list arg_sub
;
PUBLIC M-LIB-THEME-line_err
$LIBDEF M-LIB-THEME-line_err

(*****************************************************************************)
(*                           M-LIB-THEME-line_tag                            *)
(*****************************************************************************)
: M-LIB-THEME-line_tag[ str:msg str:tag -- str:line ]
  (* M1 OK *)
  msg @ string? not if "Non-string argument (1)." abort then
  tag @ string? not if "Non-string argument (2)." abort then
  "fmt_msg_tagged" theme_get { msg @ tag @ }list arg_sub
;
PUBLIC M-LIB-THEME-line_tag
$LIBDEF M-LIB-THEME-line_tag

(*****************************************************************************)
(*                          M-LIB-THEME-unparseobj                           *)
(*****************************************************************************)
: M-LIB-THEME-unparseobj[ ref:object -- str:name ]
  (* M1 OK *)
  object @ dbref? not if "Non-dbref argument (1)." abort then
  object @ name_prop theme_get { object @ name }list arg_sub var! namestr
  object @ intostr "#" swap strcat var! refstr
  object @ unparseobj object @ name strlen refstr @ strlen + ++ strcut nip dup strlen -- strcut pop var! flagstr
  namestr @ "fmt_obj_flagref" theme_get { refstr @ flagstr @ }list arg_sub .color_strcat
;
PUBLIC M-LIB-THEME-unparseobj
$LIBDEF M-LIB-THEME-unparseobj

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-theme.muf=m/lib/theme
!@set $m/lib/theme=M2
!@set $m/lib/theme=L
!@set $m/lib/theme=S
!@set $m/lib/theme=H

