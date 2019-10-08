!@program m-cmd-@help.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@help.muf - $m/cmd/at_help                                          *)
(*   Provides user help and command usage information. It automatically      *)
(*   grabs information on installed globals and gets help text from its      *)
(*   properties.                                                             *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*   TODO: Custom help articles.                                             *)
(*                                                                           *)
(*   PROPERTIES:                                                             *)
(*     See m-lib-help.muf for information on properties.                     *)
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
$VERSION 1.000
$AUTHOR  Daniel Benoy
$NOTE    A help command for users.
$DOCCMD  @list __PROG__=2-<last header line>

(* Begin configurable options *)
  $def .color-body-cmd    "bold,blue"   (* Color of commands shown in the listing *)
  $def .color-body-desc   "bold,cyan"   (* Color of short descriptions shown in the listing *)
  $def .color-body-help   "bold,white" (* Color of the help commands shown in the listing *)
  $def .color-body-nohelp "dim,red" (* Color of the help commands shown in the listing *)
  
  $def .color-head-cmd  "dim,blue"   (* Color of 'Global' shown above the listing *)
  $def .color-head-desc "dim,cyan"   (* Color of 'Description' shown above the listing *)
  $def .color-head-help "dim,white" (* Color of 'Help Info' shown above the listing *)
  
  $def .color-msg-error "bold,red"   (* Color for error messages. *)
  
  $def .color-category  "bold,blue"  (* Color for category titles in detailed output *)

(* End configurable options *)
 
$include $m/lib/string
$include $m/lib/help
 
$def .ldisplay begin dup 0 > while dup 1 + rotate .tell 1 - repeat pop

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
 
: topic_info ( s -- )
  (* Find the specified global *)
  get_global
  
  dup not if
    "No global by that name was found." .color-msg-error textattr .tell exit
  then
  
  me @ over controls not over "D" flag? and if
    "Permission denied.  This global is set DARK." .color-msg-error textattr .tell exit
  then

  M-LIB-HELP-command_get_help { me @ }list array_notify
;

: topic_list ( s --  )
  pop
  
  { }list
  var! entries
 
  #0 exits
  begin
    dup while
    
    dup getlink not if (* Unlinked global exit! *)
      me @ "TRUEWIZARD" flag? not if
        next continue (* Don't show users this stuff *)
      else
        "WARNING: Unlinked global exit: " over name strcat .color-msg-error textattr .tell
      then
    then
    
    (* Test if this user can access this command *)
    dup "$nothing" match = not if (* If it's linked to $nothing, then it's probably MPI *)
      me @ over locked? if
        next continue (* Users don't need to see what they can't access. *)
      then
    then
    
    (* Don't show dark actions *)
    dup "D" flag? if
      next continue
    then
    
    (* We made it this far.  Add it to the list of globals to display. *)
    
    (* Short Description *)
    dup M-LIB-HELP-command_get_desc 50 strcut pop .color-body-desc textattr
    
    (* Name *)
    over M-LIB-HELP-command_get_name .color-body-cmd textattr

    "|  %- 21s%- 51s  |" fmtstring
    
    entries @ array_appenditem entries !
    
    next
  repeat
  pop

  (* Show header *)

  {
    "------------------------------------------------------------------------------"
    "Description" .color-head-desc textattr
    "Global" .color-head-cmd textattr
    "|  %- 21s%- 51s  |" fmtstring
    "|----------------------------------------------------------------------------|"
    entries @ SORTTYPE_CASEINSENS array_sort array_vals pop
    "------------------------------------------------------------------------------"
    { "Use '" command @ " <name>' for more information" }join
  }tell
;

(*****************************************************************************)
(                                   main                                      )
(*****************************************************************************)
: main
  dup if topic_info exit then
  topic_list

  ( Get a list of help topics and their associated function pointer )

  ( Manually add 'globals' )

  ( Manually add a topic that reveals MUCK settings like penny costs? )

  ( List all the #0 globals and throw them in )

  ( Grab all the manually added topics )

  ( Find the closest match for the requested topic and call its function )

  ( If nothing was specified just print out the list of topics )
;
.
c
q
!@register m-cmd-@help.muf=m/cmd/at_help
!@set $m/cmd/at_help=M3
!@set $m/cmd/at_help=W

