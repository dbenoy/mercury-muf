!@program m-cmd-@morph.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@morph.muf - $m/cmd/at_morph                                        *)
(*   Load saved alternative description presets.                             *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- September, 2019                          *)
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
$NOTE    Manage morphs.
$DOCCMD  @list __PROG__=2-30

(* ====================== BEGIN CONFIGURABLE OPTIONS ====================== *)

lvar g_morph_props
: morph_props
  g_morph_props @ if g_morph_props @ exit then
  {
    "Appearance"          { "_/de" "_/dl/appearance#" }list
    "Scent"               { "_/scent" "_/dl/scent#" }list
    "Texture"             { "_/texture" "_/dl/texture#" }list
    "Flavor"              { "_/flavor" "_/dl/flavor#" }list
    "Aura"                { "_/aura" "_/dl/aura#" }list
    "Sound"               { "_/sound" "_/dl/sound#" }list
    "Writing"             { "_/writing" "_/dl/writing#" }list
    "Image URL"           { "_/image" }list
    "Pronouns/Names"      { "%a" "%d" "%i" "%n" "%o" "%p" "%r" "%s" "%w" "%x" "%y" "%z" }list 
    "Species"             { "_/species" }list
    "Sex"                 { "gender_prop" sysparm }list
    "Emote Configuration" { "_config/emote" }list
  }dict dup g_morph_props !
;

(* ======================= END CONFIGURABLE OPTIONS ======================= *)

$INCLUDE $m/lib/morph
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/notify

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .tag M-LIB-THEME-tag
$DEF .tag_err M-LIB-THEME-tag_err

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Manage morphs."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop var! action_name
  {
    action_name @ toupper
    "  Lists your available morphs."
    "  Morphs are a preset collection of your description text and other cosmetic details."
    " "
    { action_name @ toupper " <morph name>=<save/load/delete>" }cat
    "  Manages your morphs."
    "  Saving will create or overwrite a given morph with your current descriptions and cosmetic settings. Loading will overwrite your current descriptions and cosmetic settings."
    " "
    { action_name @ toupper " <morph name>=mesg<:message>" }cat
    "  Sets a morph message."
    { "  Morph messages are 'spoofed' from you automatically when loading a morph. Loading your morphs with '" action_name @ tolower " <morph>=load' will not send this spoof, but more 'in character' morphing commands will, such as the 'morph' command on most servers. If you don't supply a message, it will be reset to default. It defaults to '<name> morphs into a <morph name>.'" }cat
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  dup strip not if
    pop
    me @ M-LIB-MORPH-list
    exit
  then
  "=" split
  strip var! operation
  strip var! morph_name
  morph_name @ not if
    "Please specify a morph name." command @ toupper .tag_err .tell exit
  then
  operation @ not if
    "Please specify an operation." command @ toupper .tag_err .tell exit
  then
  operation @ "save" stringcmp not if
    me @ morph_name @ 0 M-LIB-MORPH-save pop exit
  then
  operation @ "load" stringcmp not if
    me @ morph_name @ 0 M-LIB-MORPH-load pop exit
    exit
  then
  operation @ "delete" stringcmp not if
    me @ morph_name @ 0 M-LIB-MORPH-delete pop exit
    exit
  then
  operation @ ":" split
  var! argument
  operation !
  operation @ "mesg" stringcmp not if
    argument @ me @ morph_name @ 0 M-LIB-MORPH-mesg_set pop exit
  then
  { "Invalid operation '" operation @ "'." }cat command @ toupper .tag_err .tell
;
.
c
q
!@register m-cmd-@morph.muf=m/cmd/at_morph
!@set $m/cmd/at_morph=M3

