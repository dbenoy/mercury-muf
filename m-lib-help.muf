!@program m-lib-help.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-help.muf - $m/lib/help                                              *)
(*   Retrieves 'help text' and information from objects.                     *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PROPERTIES:                                                               *)
(*   "_help/~name"                                                           *)
(*     Place this property on an action to set the friendly name for the     *)
(*     command. Defaults to the first semicolon-alias for the command. Only  *)
(*     the first 20 characters are used.                                     *)
(*                                                                           *)
(*   "_help/desc"                                                            *)
(*     Place this property on an action to give a general description of the *)
(*     command. Only the first 50 characters are used. If this is not        *)
(*     present on the action, and the action is linked to a program, the     *)
(*     program is checked for this property instead. If the program also     *)
(*     does not have the property, the library will attepmt to ask the       *)
(*     program itself by calling the public function "M-HELP-desc" if it is  *)
(*     available, passing in the name of the action and expecting a string.  *)
(*                                                                           *)
(*   "_help/help"                                                            *)
(*     Place this 'list' type property on an action to set help and usage    *)
(*     information. If this is not present on the action, and the action is  *)
(*     linked to a program, the program is checked for this property         *)
(*     instead. If the program also does not have the property, the library  *)
(*     will attempt to ask the program itself by calling the public function *)
(*     "M-HELP-help" if it is available, passing in the name of the action   *)
(*     and expecting a list array of strings.                                *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-HELP-command_get_name[ ref:action -- str:result ]                 *)
(*     Get a friendly name string for the command. This can be used to       *)
(*     differentiate it from other help articles, or to describe multi-alias *)
(*     commands.                                                             *)
(*                                                                           *)
(*   M-LIB-HELP-command_get_desc[ ref:action -- str:result ]                 *)
(*     Get a short description, 50 characters or less, of the command.       *)
(*                                                                           *)
(*   M-LIB-HELP-command_get_help[ ref:action -- arr:result ]                 *)
(*     Get a long help and usage description of the command as an array of   *)
(*     strings.                                                              *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October, 2019                            *)
(*      - Original implementation.                                           *)
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
$NOTE    Gets help text.
$DOCCMD  @list __PROG__=2-30

(* ------------------------------------------------------------------------ *)

$def PROP_COMMAND_NAME "_help/~name"
$def PROP_COMMAND_DESC "_help/desc"
$def PROP_COMMAND_HELP "_help/help"
$def FUNC_COMMAND_DESC "M-HELP-desc"
$def FUNC_COMMAND_HELP "M-HELP-help"

$PUBDEF :

(* ------------------------------------------------------------------------ *)

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

: command_get_desc[ ref:action -- str:result ]
  action @ ok? not if "ERROR: Bad action." exit then
  (* Try to grab the property off the action directly. *)
  action @ PROP_COMMAND_DESC getpropstr
  dup if exit then pop
  (* Try grabbing examining the program we're linked to, instead. *)
  action @ linked_program var! prog
  prog @ ok? if
    (* Check for the same property here. *)
    prog @ PROP_COMMAND_DESC getpropstr
    dup if exit then pop
    (* No properties are set. Try asking the program itself. *)
    prog @ FUNC_COMMAND_DESC cancall? if
      0 try
        action @ name tolower
        prog @ "M-HELP-desc" call
        depth 1 != if "One result expected." abort then
        dup string? not if "String expected." abort then
      catch
        { "ERROR: (" FUNC_COMMAND_DESC ") " }join swap strcat
      endcatch
      exit
    then
  then
  (* No luck. Return a default. *)
  { "The " action @ name ";" split pop " command." }join
;

: command_get_help[ ref:action -- str:result ]
  action @ ok? not if { "ERROR: Bad action." }list exit then
  (* Try to grab the property off the action directly. *)
  action @ PROP_COMMAND_HELP array_get_proplist
  dup if exit then pop
  (* Try grabbing examining the program we're linked to, instead. *)
  action @ linked_program var! prog
  prog @ ok? if
    (* Check for the same property here. *)
    prog @ PROP_COMMAND_HELP array_get_proplist
    dup if exit then pop
    (* No properties are set. Try asking the program itself. *)
    prog @ FUNC_COMMAND_HELP cancall? if
      0 try
        action @ name tolower
        prog @ FUNC_COMMAND_HELP call
        depth 1 != if "One result expected." abort then
        dup array? not if "Array expected." abort then
        dup foreach
          nip string? not if "Array of strings expected." abort then
        repeat
      catch_detailed
        {
          { "ERROR in " FUNC_COMMAND_HELP }join
          rot foreach
            dup int? if intostr then
            dup dbref? if intostr "#" swap strcat then
            ": " swap strcat strcat
          repeat
        }list
      endcatch
      exit
    then
  then
  (* No luck. Return a default. *)
  { "No detailed help available." }list
;

(*****************************************************************************)
(*                        M-LIB-HELP-command_get_desc                        *)
(*****************************************************************************)
: M-LIB-HELP-command_get_desc[ ref:action -- str:result ]
  (* M1 OK *)
  action @ dbref? not if "Non-dbref argument (1)." abort then
  action @ command_get_desc
  50 strcut pop
;
PUBLIC M-LIB-HELP-command_get_desc
$LIBDEF M-LIB-HELP-command_get_desc

(*****************************************************************************)
(*                        M-LIB-HELP-command_get_help                        *)
(*****************************************************************************)
: M-LIB-HELP-command_get_help[ ref:action -- str:result ]
  (* M1 OK *)
  action @ dbref? not if "Non-dbref argument (1)." abort then
  action @ command_get_help
;
PUBLIC M-LIB-HELP-command_get_help
$LIBDEF M-LIB-HELP-command_get_help

(*****************************************************************************)
(*                        M-LIB-HELP-command_get_name                        *)
(*****************************************************************************)
: M-LIB-HELP-command_get_name[ ref:action -- str:result ]
  action @ PROP_COMMAND_NAME getpropstr
  dup not if
    pop
    action @ name tolower ";" split pop
  then
  20 strcut pop
;
PUBLIC M-LIB-HELP-command_get_name
$LIBDEF M-LIB-HELP-command_get_name

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-help.muf=m/lib/help
!@set $m/lib/help=M3
!@set $m/lib/help=W
!@set $m/lib/help=L

