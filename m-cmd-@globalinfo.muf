!@program m-cmd-@globalinfo.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@globalinfo.muf - $m/cmd/at_globalinfo                              *)
(*   Outputs information on a given global command.                          *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- October, 2019                            *)
(*     - Split from cmd-globals.muf and adapted for the Mercury MUF project. *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*     - Original implementation from Latitude MUCK.                         *)
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
$VERSION 1.001
$AUTHOR  Daniel Benoy
$NOTE    A help command for users.
$DOCCMD  @list __PROG__=2-30

(* Begin configurable options *)

$def .color-msg-error "bold,red"   (* Color for error messages. *)
$def .color-category  "bold,blue"  (* Color for category titles in detailed output *)

(* End configurable options *)

$INCLUDE $m/lib/help

: matches_action ( s1 s2 -- b ) (* if action name s1 would be triggered by command s2 *)
  1 array_make swap ";" explode_array array_intersect not not
;

: get_global ( s -- d )
  #0 exits
  begin
    dup while
    over over name swap matches_action if
      break
    then
    next
  repeat
  swap pop
;
 
: linked_program ( d -- d )
  getlinks_array foreach
    nip
    dup program? if
      exit
    then
    pop
  repeat
  #-1
;
 
(* Searches for dbref d2, in propdir s on object d1, and returns a string of *)
(* every one found, followed by the number found.                            *)
: find_dbref ( d1 s d2 -- s1..sn i )
 
  var! target
 
  { }list var! retval
 
  over swap "/" strcat nextprop
  begin
    dup while
    
    (* Check directories recursively *)
    over over propdir? if
      over over target @ find_dbref
      array_make 0 retval @ array_insertrange retval !
    then
    
    (* Check if this property matches target *)
    over over getprop
    
    dup dbref? if
      dup target @ = if
        over retval @ array_appenditem retval !
      then
    then  
    
    dup string? if
      dup stod target @ = if
        over retval @ array_appenditem retval !
      then
    then
 
    pop
    
    over swap nextprop
  repeat
  pop pop
  
  retval @ array_vals
;
 
: main ( s --  )
  dup not if
    "Please specify a global." .color-msg-error textattr .tell exit
  then

  (* Find the specified global *)
  get_global
  
  dup not if
    "No global by that name was found." .color-msg-error textattr .tell exit
  then
  
  me @ over controls not over "D" flag? and if
    "Permission denied.  This global is set DARK." .color-msg-error textattr .tell exit
  then
  
  "-------------------------------------------------------------------------------" .tell
  
  dup "$nothing" match = not if (* If it's linked to $nothing, then it's probably MPI *)
    me @ over locked? if
      "Note: You don't have access to run this action!\r" .color-msg-error textattr .tell
    then
  then
  
  (* Action Name *)
  dup M-LIB-HELP-command_get_name "Global Name:         " .color-category textattr swap strcat .tell
  
  (* Action Description *)
  dup M-LIB-HELP-command_get_desc dup if
    "Global Description:  " .color-category textattr swap strcat .tell
  else
    pop
  then
  
  " " .tell
  
  (* Action Owner *)
  "Action Owner:        " .color-category textattr over owner name strcat .tell
  
  (* Action Aliases *)
  dup name dup ";" instr if
    ", " ";" subst
    "Action Aliases:      " .color-category textattr swap tolower strcat .tell
  else
    pop
  then
  
  (* Output MUF information *)
  linked_program
  
  dup if
    (* Program Name *)
    "Program Name:        " .color-category textattr over name strcat .tell
    
    (* Program Owner *)
    dup owner #1 = not if
      "Program Owner:       " .color-category textattr over owner name strcat .tell
    then
    
    (* Program Author *)
    dup "_author" getpropstr dup if
      "Program Author:      " .color-category textattr swap strcat .tell
    else
      pop
    then
    
    (* Program Version *)
    dup "_version" getpropstr dup if
      "Program Version:     " .color-category textattr swap strcat .tell
    else
      pop
    then
    
    (* Program Note *)
    dup "_note" getpropstr dup if
      "Program Note:        " .color-category textattr swap strcat .tell
    else
      pop
    then
    
    (* Program Docs *)
    dup "L" flag? over "V" flag? or if
      dup "_docs" getpropstr if
        "@view #"
      else
        "@list #"
      then
      
      over intostr strcat
      
      "Program Docs:        " .color-category textattr swap strcat .tell
    then
    
    (* Program Registrations *)
    #0 "_reg" 3 pick find_dbref
    
    dup if
      array_make
      "Program Reg:         " .color-category textattr
      swap "\r                     " array_join "$" "_reg/" subst
      strcat .tell
    else
      pop
    then
    
    pop
  then
  
  "-------------------------------------------------------------------------------" .tell
;
.
c
q
!@register m-cmd-@globalinfo.muf=m/cmd/at_globalinfo
!@set $m/cmd/at_globalinfo=M3

