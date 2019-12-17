!@program m-cmd-@help.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@help.muf - $m/cmd/at_help                                          *)
(*   Provides user help and command usage information. In addition to other  *)
(*   help topics, it will attempt to automatically grab information from     *)
(*   installed globals and use it to generate help text. See m-lib-help.muf  *)
(*   for more information on generating help text from commands.             *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*   PROPERTIES:                                                             *)
(*     See m-lib-help.muf for information on how to put help properties on   *)
(*     commands/programs.                                                    *)
(*                                                                           *)
(*     "_at_help/entries/<topic>/listed"                                     *)
(*     "_at_help/entries/<topic>/aliases"                                    *)
(*     "_at_help/entries/<topic>/help"                                       *)
(*       On this program object: Use these properties to add a custom help   *)
(*       entry. If 'listed' is set to 'no', this entry will not appear in    *)
(*       topic listings. 'aliases' is a semicolon-separated list of alias    *)
(*       names that can also be used to pull up this help entry. 'help' is a *)
(*       list-type property for the help text itself. If available, MCC      *)
(*       color codes can be used in the help text.                           *)
(*                                                                           *)
(*  TECHNICAL NOTES:                                                         *)
(*    If two entries are generated with the same name, then to avoid         *)
(*    collisions, some entries may be renamed so that they're suffixed with  *)
(*    a '2', '3', '4', etc.                                                  *)
(*                                                                           *)
(*    Manually added topics take first priority over commands, but not       *)
(*    necessarily over built-in topics like 'alpha' or 'globals'.            *)
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
$DOCCMD  @list __PROG__=2-57

(* Begin configurable options *)

$DEF OUTPUT_TAG "HELP"
$DEF OUTPUT_WRAP 72

(* End configurable options *)

$INCLUDE $m/lib/string
$INCLUDE $m/lib/help
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/notify
$INCLUDE $m/lib/color

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .err M-LIB-THEME-err
$DEF .tag M-LIB-THEME-tag

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "View help documentation."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " [<topic>]" }cat
    " "
    "Outputs documentation to help players. If you're lost, you can start here."
    "You can optionally specify a help topic such as the name of a global command, otherwise a list of topics will be displayed."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: cb_color_strcat M-LIB-COLOR-strcat ;
: cb_color_strcut M-LIB-COLOR-strcut ;
: cb_color_strplain M-LIB-COLOR-strip ;
: cb_color_toupper M-LIB-COLOR-toupper ;
: cb_color_tolower M-LIB-COLOR-tolower ;
: cb_color ( -- a ) { "strcat" 'cb_color_strcat "strcut" 'cb_color_strcut "strplain" 'cb_color_strplain "toupper" 'cb_color_toupper "tolower" 'cb_color_tolower }dict ;

: help_page_main[ x:topics -- Y:lines ]
  {
    { "Welcome to " "muckname" sysparm "! To get help, try the following commands:" }cat
    { "  " command @ " alpha .... Get an alphabetical listing of all help topics." }cat
    { "  " command @ " globals .. List information on available commands." }cat
  }list
;

: globals_get[  -- Y:globals ]
  {
    #0 exits_array foreach
      nip
      dup getlink not if (* Unlinked global exit! *)
        me @ "TRUEWIZARD" flag? if
          { "WARNING: Unlinked global exit: " 3 pick unparseobj }cat .err .tell
        then
        pop continue
      then
      (* Test if this user can access this command *)
      dup "$nothing" match = over #-4 = or not if (* If it's linked to $nothing or NIL, then it's probably MPI, so always show it *)
        me @ over locked? if
          pop continue (* Users don't need to see what they can't access. *)
        then
      then
      (* Don't show dark actions *)
      dup "DARK" flag? if
        pop continue
      then
    repeat
  }list
;

$DEF .color_fillfield rot M-LIB-COLOR-strlen - dup 1 < if pop pop "" else * then
: help_page_globals[ x:topics -- Y:lines ]
  { }list var! lines
  { }list var! entries
  globals_get foreach
    nip
    var! global_exit
    {
      "   "
      (* Name *)
      { "[#5555FF]" global_exit @ M-LIB-HELP-command_get_name }cat dup " " 21 .color_fillfield M-LIB-COLOR-strcat
      (* Short Description *)
      { "[#55FFFF]" global_exit @ M-LIB-HELP-command_get_desc }cat dup " " 51 .color_fillfield M-LIB-COLOR-strcat
      "[!FFFFFF]   "
    }cat
    entries @ array_appenditem entries !
  repeat
  {
    "   [#0000AA]Global               [#00AAAA]Description                                        [!FFFFFF]   "
    "-" OUTPUT_WRAP *
    entries @ SORTTYPE_CASEINSENS array_sort array_vals pop
  }list
;

: help_page_command[ x:topics d:command_exit -- Y:lines ]
  command_exit @ M-LIB-HELP-command_get_help
;

: help_page_listing[ x:topics -- Y:lines ]
  { }list var! lines
  "" var! line
  "" var! prev_letter
  {
    topics @ foreach
      "listed" [] not if
        pop
      else
        tolower
      then
    repeat
  }list SORTTYPE_CASE_ASCEND array_sort foreach
    nip
    var! topic
    "" var! this_letter
    topic @ begin
      dup not if
        pop break
      then
      1 strcut swap
      this_letter @ over strcat this_letter !
      "[0-9a-z]" smatch if
        pop break
      then
    repeat
    this_letter @ prev_letter @ stringcmp if
      line @ if
        line @ lines @ []<- lines ! "" line !
      then
      lines @ if
        " " lines @ []<- lines !
      then
      this_letter @ toupper lines @ []<- lines !
      this_letter @ prev_letter !
    then
    line @ { "  " topic @ }cat strcat line !
  repeat
  line @ if
    line @ lines @ []<- lines !
  then
  lines @
;

: help_page_custom[ x:topics s:custom_topic_name ]
  prog { "_at_help/entries/" custom_topic_name @ "/help" }cat array_get_proplist
;

(* Like array_setitem but if there's already an entry with that key it will add it under a different key. *)
: array_setitem_redundant ( ? x @ -- x )
  begin
    over over [] if
      (* Strip off any number that may be on the end *)
      "" var! key_end_number
      begin
        dup strlen -- strcut
        dup number? if
          key_end_number @ strcat key_end_number !
        else
          strcat break
        then
      repeat
      (* Increment the number and add it back on *)
      key_end_number @ atoi ++ dup 2 < if pop 2 then intostr strcat
    else
      break
    then
  repeat
  array_setitem
;

(* Like array_setitem but won't override something that exists with that key *)
: array_setitem_unless_exists ( ? x @ -- x )
  over over [] if
    pop swap pop exit
  then
  array_setitem
;

: topics_get[  -- x:topic_list ]
  { }dict var! topic_list
  globals_get var! global_exits
  (* 'alpha' *)
  { "listed" 1 "args" { }list "func" 'help_page_listing }dict topic_list @ "alpha" array_setitem_redundant topic_list !
  { "listed" 0 "args" { }list "func" 'help_page_listing }dict topic_list @ "alphabetical" array_setitem_redundant topic_list !
  (* 'globals' *)
  { "listed" 1 "args" { }list "func" 'help_page_globals }dict topic_list @ "globals" array_setitem_redundant topic_list !
  { "listed" 0 "args" { }list "func" 'help_page_globals }dict topic_list @ "commands" array_setitem_redundant topic_list !
  (* Manual topics from properties, primary name *)
  prog "_at_help/entries/" array_get_propdirs foreach
    nip
    var! custom_topic_name
    prog { "_at_help/entries/" custom_topic_name @ "/listed" }cat getpropstr "no" stringcmp not not var! custom_topic_listed
    { "listed" custom_topic_listed @ "args" { custom_topic_name @ }list "func" 'help_page_custom }dict topic_list @ custom_topic_name @ array_setitem_redundant topic_list !
  repeat
  (* TODO: Some built-in help topics, especially ones that benefit from being auto-generated like describing penny costs for things *)
  (* Global command entries, friendly names *)
  global_exits @ foreach
    nip
    var! global_exit
    (* Add entries for each alias *)
    { "listed" 1 "func" 'help_page_command "args" { global_exit @ }list }dict topic_list @ global_exit @ M-LIB-HELP-command_get_name array_setitem_redundant topic_list !
  repeat
  (* Manual topics from properties, aliases *)
  prog "_at_help/entries/" array_get_propdirs foreach
    nip
    var! custom_topic_name
    prog { "_at_help/entries/" custom_topic_name @ "/aliases" }cat getpropstr
    dup not if pop continue then
    ";" explode_array foreach
      nip
      var! custom_topic_alias
      { "listed" 0 "args" { custom_topic_name @ }list "func" 'help_page_custom }dict topic_list @ custom_topic_alias @ array_setitem_unless_exists topic_list !
    repeat
  repeat
  (* Global command entries, all aliases *)
  global_exits @ foreach
    nip
    var! global_exit
    { "listed" 0 "func" 'help_page_command "args" { global_exit @ }list }dict
    global_exit @ name ";" explode_array foreach
      nip
      over swap topic_list @ swap array_setitem_unless_exists topic_list !
    repeat
    pop
  repeat
  (* Return list *)
  topic_list @
;

: array_getitem_partial ( x @ -- ? )
  over over array_getitem dup if
    exit
  else
    pop
    (* Search for a partial match *)
    var! requested_key
    {
      over
      foreach
        pop
        dup requested_key @ stringpfx not if
          pop
        then
      repeat
    }list
    dup array_count 1 = if
      0 [] [] exit
    then
    pop pop 0 exit
  then
;

(*****************************************************************************)
(                                   main                                      )
(*****************************************************************************)
: main
  var! requested_topic
  (* Produce a list-of-strings object for this help page *)
  var entry
  topics_get var! topics
  requested_topic @ if
    topics @ requested_topic @ array_getitem_partial
    dup if
      entry !
      topics @ entry @ "args" [] array_vals pop entry @ "func" [] execute
    else
      pop
      {
        { "There is no entry for '" requested_topic @ "'. See '" command @ " alpha' for a listing of available help topics." }cat .err
      }list
    then
  else
    topics @ help_page_main
  then
  (* Handle empty help entries *)
  dup not if
    pop
    {
      "Help topic data missing." .err
    }list
  then
  (* Word wrap the result *)
  {
    over foreach
      nip
      OUTPUT_WRAP { }dict cb_color M-LIB-STRING-wordwrap_cb array_vals pop
    repeat
  }list
  (* Determine the maximum width in order to draw decorations *)
  0 var! width_max
  dup foreach
    nip
    M-LIB-COLOR-strlen
    dup width_max @ > if
      dup width_max !
    then
    pop
  repeat
  (* Draw decorations, and apply theme tags *)
  {
    "-" width_max @ * OUTPUT_TAG .tag
    rot foreach
      nip
      OUTPUT_TAG .tag
    repeat
    "-" width_max @ * OUTPUT_TAG .tag
  }list
  (* Output processed lines *)
  { me @ }list M-LIB-NOTIFY-array_notify_color
;
.
c
q
!@register m-cmd-@help.muf=m/cmd/at_help
!@set $m/cmd/at_help=M3
!@set $m/cmd/at_help=W

