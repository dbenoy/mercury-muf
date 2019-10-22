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
(* PUBLIC ROUTINES:                                                          *)
(*   M-CMD-AT_EDITOBJECT-save_morph[ str:morph_name bool:quiet               *)
(*                                  -- bool:success? ]                       *)
(*   M-CMD-AT_EDITOBJECT-load_morph[ str:morph_name bool:quiet               *)
(*                                  -- bool:success? ]                       *)
(*     Save or load a specified morph. If quiet is true, then only error     *)
(*     messages will be displayed.                                           *)
(*                                                                           *)
(*   M-CMD-AT_EDITOBJECT-list_morphs[  --  ]                                 *)
(*     Outputs a list of available morphs to the player.                     *)
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

$INCLUDE $m/lib/program
$INCLUDE $m/lib/string
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/color

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Manage morphs."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop var! action_name
  {
    action_name @ toupper
    "  Lists your available morphs."
    "  Morphs are a preset collection of your description text and other cosmetic details."
    " "
    { action_name @ toupper " <morph name>=<save/load/delete>" }join
    "  Manages your morphs."
    "  Saving will create or overwrite a given morph with your current descriptions and cosmetic settings. Loading will overwrite your current descriptions and cosmetic settings."
    " "
    { action_name @ toupper " <morph name>=mesg<:message>" }join
    "  Sets a morph message."
    { "  Morph messages are 'spoofed' from you automatically when loading a morph. Loading your morphs with '" action_name @ tolower " <morph>=load' will not send this spoof, but more 'in character' morphing commands will, such as the 'morph' command on most servers. If you don't supply a message, it will be reset to default. It defaults to '<name> morphs into a <morph name>.'" }join
  }list
;
WIZCALL M-HELP-help

: copy_props[ ref:from str:fromprop ref:to str:toprop -- ]

  to @ toprop @ propdir? toprop @ strlen toprop @ "#" instr = and if (* If it's a list type prop and it exists, destroy it before copying contents in *)
    to @ toprop @ remove_prop
  then

  to @ toprop @ from @ fromprop @ getprop setprop

  (* If it's a propdir, recursively descend the tree *)
  from @ fromprop @ propdir? if
    fromprop @ "/" strcat fromprop !
    from @ fromprop @ nextprop
    begin
      dup while

      from @   (* from stays the same *)
      over     (* The curently iterated item is the new fromprop *)
      to @     (* to stays the same *)
      toprop @ 5 pick "/" rsplit "/" swap strcat swap pop strcat (* The new toprop is the old toprop, plus the relitive name of the currently iterated item. *)
      copy_props

      from @ swap nextprop
    repeat
    pop
  then
;

: fix_morph_name[ str:source -- str:result ]
  1 var! caps_next
  "" source @
  begin
    1 strcut swap
    caps_next @ if
      toupper
      0 caps_next !
    then
    dup "[a-z0-9_]" smatch not if
      pop "_"
      1 caps_next !
    then
    rot swap strcat swap
    dup not
  until
  pop
  dup not if
    pop "_"
  then
;

: morph_delete[ ref:object str:morph_name bool:quiet --  ]
  morph_name @ fix_morph_name morph_name !

  "_morph/morphs/" morph_name @ strcat var! morph_dir

  object @ morph_dir @ propdir? if
    object @ morph_dir @ remove_prop
    object @ "_morph/mesg/" morph_name @ strcat remove_prop
    quiet @ not if { "Morph '" morph_name @ "' deleted." }join command @ toupper .theme_tag .color_tell then
  else
    quiet @ not if { "Morph '" morph_name @ "' not found." }join command @ toupper .theme_tag_err .color_tell then
  then
;

: morph_mesg_set[ str:new_mesg ref:object str:morph_name bool:quiet -- bool:success? ]
  morph_name @ fix_morph_name morph_name !
  object @ "_morph/morphs/" morph_name @ strcat propdir? not if
    quiet @ not if { "Morph '" morph_name @ "' not found." }join command @ toupper .theme_tag_err .color_tell then
    0 exit
  then
  new_mesg @ if
    object @ "_morph/mesg/" morph_name @ strcat new_mesg @ setprop
    quiet @ not if { "Morph message set for '" morph_name @ "'." }join command @ toupper .theme_tag .color_tell then
  else
    object @ "_morph/mesg/" morph_name @ strcat remove_prop
    quiet @ not if { "Morph message cleared for '" morph_name @ "'." }join command @ toupper .theme_tag .color_tell then
  then
  1
;

: morph_mesg_get[ ref:object str:morph_name bool:quiet -- str:mesg ]
  morph_name @ fix_morph_name morph_name !
  object @ "_morph/morphs/" morph_name @ strcat propdir? not if
    quiet @ not if { "Morph '" morph_name @ "' not found." }join command @ toupper .theme_tag_err .color_tell then
    "" exit
  then
  object @ "_morph/mesg/" morph_name @ strcat getpropstr
  dup not if
    pop { object @ name 1 strcut swap toupper swap strcat " morphs into a " morph_name @ tolower " " "_" subst .sms "." }join
  then
;

: morph_list[ ref:object --  ]
  object @ "/_morph/morphs" propdir? if
    "Saved morphs:" command @ toupper .theme_tag .color_tell
    object @ "/_morph/morphs/" nextprop
    begin
      dup while
      object @ over propdir? if
        dup "/" rsplit swap pop "  " swap strcat command @ toupper .theme_tag .color_tell
      then
      object @ swap nextprop
    repeat
    pop
  else
    "No saved morphs." command @ toupper .theme_tag .color_tell
  then
;

: morph[ ref:object str:morph_name bool:save bool:quiet -- bool:success? ]
  morph_name @ fix_morph_name morph_name !

  "_morph/morphs/" morph_name @ strcat var! morph_dir

  save @ if
    object @ morph_dir @ propdir? if
      quiet @ not if "Clearing existing morph..." command @ toupper .theme_tag .color_tell then
      object @ morph_dir @ remove_prop
      quiet @ not if "Saving morph..." command @ toupper .theme_tag .color_tell then
    else
      quiet @ not if "Creating new morph..." command @ toupper .theme_tag .color_tell then
    then
  else
    object @ morph_dir @ propdir? if
      quiet @ not if "Loading morph..." command @ toupper .theme_tag .color_tell then
    else
      { "Morph '" morph_name @ "' not found." }join command @ toupper .theme_tag_err .color_tell
      0 exit
    then
  then

  morph_props foreach
    var! properties
    var! name
    var property

    save @ if
      quiet @ not if { "  Saving '" name @ "'..." }join command @ toupper .theme_tag .color_tell then
      properties @ foreach
        nip
        property !
        object @ property @ propdir? object @ property @ getpropstr or if
          object @ property @ object @ { morph_dir @ "/" property @ }join copy_props
        then
      repeat
    else
      quiet @ not if { "  Loading '" name @ "'..." }join command @ toupper .theme_tag .color_tell then
      properties @ foreach
        nip
        property !
        object @ { morph_dir @ "/" property @ }join propdir? object @ { morph_dir @ "/" property @ }join getpropstr or if
          object @ { morph_dir @ "/" property @ }join object @ property @ copy_props
        then
      repeat
    then
  repeat

  object @ "/_morph/current" morph_name @ setprop
  1
;

(* ------------------------------------------------------------------------- *)

(*****************************************************************************)
(*                            M-CMD-AT_MORPH-load                            *)
(*****************************************************************************)
: M-CMD-AT_MORPH-load[ ref:object str:morph_name bool:quiet -- bool:success? ]
  .needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ 0 quiet @ morph
;
PUBLIC M-CMD-AT_MORPH-load
$LIBDEF M-CMD-AT_MORPH-load

(*****************************************************************************)
(*                            M-CMD-AT_MORPH-save                            *)
(*****************************************************************************)
: M-CMD-AT_MORPH-save[ ref:object str:morph_name bool:quiet -- bool:success? ]
  .needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ 1 quiet @ morph
;
PUBLIC M-CMD-AT_MORPH-save
$LIBDEF M-CMD-AT_MORPH-save

(*****************************************************************************)
(*                           M-CMD-AT_MORPH-delete                           *)
(*****************************************************************************)
: M-CMD-AT_MORPH-delete[ ref:object str:morph_name bool:quiet -- bool:success? ]
  .needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ quiet @ morph_delete
;
PUBLIC M-CMD-AT_MORPH-delete
$LIBDEF M-CMD-AT_MORPH-delete

(*****************************************************************************)
(*                            M-CMD-AT_MORPH-list                            *)
(*****************************************************************************)
: M-CMD-AT_MORPH-list[ ref:object --  ]
  .needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  object @ morph_list
;
PUBLIC M-CMD-AT_MORPH-list
$LIBDEF M-CMD-AT_MORPH-list

(*****************************************************************************)
(*                          M-CMD-AT_MORPH-mesg_get                          *)
(*****************************************************************************)
: M-CMD-AT_MORPH-mesg_get[ ref:object str:morph_name bool:quiet -- str:mesg ]
  .needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ quiet @ morph_mesg_get
;
PUBLIC M-CMD-AT_MORPH-mesg_get
$LIBDEF M-CMD-AT_MORPH-mesg_get

(*****************************************************************************)
(*                          M-CMD-AT_MORPH-mesg_set                          *)
(*****************************************************************************)
: M-CMD-AT_MORPH-mesg_set[ str:new_mesg ref:object str:morph_name bool:quiet -- bool:success? ]
  .needs_mlev3
  new_mesg @ string? not if "Non-string argument (1)." abort then
  object @ dbref? not if "Non-dbref argument (2)." abort then
  morph_name @ string? not if "Non-string argument (3)." abort then
  morph_name @ not if "Empty morph name (3)." abort then
  new_mesg @ object @ morph_name @ quiet @ morph_mesg_set
;
PUBLIC M-CMD-AT_MORPH-mesg_set
$LIBDEF M-CMD-AT_MORPH-mesg_set

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  dup strip not if
    pop
    me @ morph_list
    exit
  then
  "=" split
  strip var! operation
  strip var! morph_name
  morph_name @ not if
    "Please specify a morph name." command @ toupper .theme_tag_err .color_tell exit
  then
  operation @ not if
    "Please specify an operation." command @ toupper .theme_tag_err .color_tell exit
  then
  operation @ "save" stringcmp not if
    me @ morph_name @ 1 0 morph
    exit
  then
  operation @ "load" stringcmp not if
    me @ morph_name @ 0 0 morph
    exit
  then
  operation @ "delete" stringcmp not if
    me @ morph_name @ 0 morph_delete
    exit
  then
  operation @ ":" split
  var! argument
  operation !
  operation @ "mesg" stringcmp not if
    argument @ me @ morph_name @ 0 morph_mesg_set pop
    exit
  then
  { "Invalid operation '" operation @ "'." }join command @ toupper .theme_tag_err .color_tell
;
.
c
q
!@register m-cmd-@morph.muf=m/cmd/at_morph
!@set $m/cmd/at_morph=M3
!@set $m/cmd/at_morph=L

