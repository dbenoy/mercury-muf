!@program m-cmd-@ooc.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@ooc.muf - $m/cmd/at_ooc                                            *)
(*   OOC command using $m/lib/emote                                          *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October 2019                             *)
(*      - Original implementation                                            *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2019 Daniel Benoy                                           *)
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
$NOTE    OOC message command.
$DOCCMD  @list __PROG__=2-30

$include $m/lib/emote
$include $m/lib/theme

$DEF .tag M-LIB-THEME-tag

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Communicate out-of-character."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop var! action_name
  {
    { action_name @ toupper " <message>" }join
    " "
    { "  Send an OOC message to others in the room. If your message starts with a : it will be treated as a 'pose' style message. For example, if your name is Igor and you type '" action_name @ tolower " I need to log off' you and others in the room will see:" }join
    "    [OOC] Igor: I need to log off."
    { "  Or if you type '" action_name @ tolower " :needs to log off':" }join
    "    [OOC] Igor needs to log off."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
  dup not if
    pop
    "Please specify a message." .tell
    exit
  then
  var highlight_ooc_style
  dup ":" instr 1 = if
    1 strcut swap pop
    me @ name
    over 1 strcut pop dup "-" = over ":" = or swap "," = or not if
      " " strcat
    then
    swap strcat
    "no" highlight_ooc_style !
  else
    me @ name ": " strcat swap strcat
    "yes" highlight_ooc_style !
  then
  { "from" me @ "message_format" "@1" "OOC" .tag "highlight_ooc_style" highlight_ooc_style @ }dict M-LIB-EMOTE-emote
;
.
c
q
!@register m-cmd-@ooc.muf=m/cmd/at_ooc
!@set $m/cmd/at_ooc=M3

