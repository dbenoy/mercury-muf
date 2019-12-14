!@program m-lib-morph.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-morph.muf - $m/lib/morph                                            *)
(*   Load saved alternative description presets.                             *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-MORPH-save[ ref:object str:morph_name bool:quiet                  *)
(*                           -- bool:success? ]                              *)
(*   M-LIB-MORPH-load[ ref:object str:morph_name bool:quiet                  *)
(*                           -- bool:success? ]                              *)
(*   M-LIB-MORPH-delete[ ref:object str:morph_name bool:quiet                *)
(*                       -- bool:success? ]                                  *)
(*     Save, load, or delete a specified morph. If quiet is true, then only  *)
(*     error messages will be displayed.                                     *)
(*                                                                           *)
(*   M-LIB-MORPH-list[ ref:object --  ]                                      *)
(*     Outputs a list of available morphs.                                   *)
(*                                                                           *)
(*   M-LIB-MORPH-mesg_get[ ref:object str:morph_name bool:quiet              *)
(*                         -- str:mesg ]                                     *)
(*   M-LIB-MORPH-mesg_set[ str:new_mesg ref:object str:morph_name bool:quiet *)
(*                         -- bool:success? ]                                *)
(*     Get or set the 'morph message' for a specified morph. This message    *)
(*     may be spoofed to the room when a morph is loaded. This library       *)
(*     doesn't do that automatically. It's optional and up to the command    *)
(*     how and if it sends the spoof.                                        *)
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

(* ====================== BEGIN CONFIGURABLE OPTIONS ======================= *)

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

(* ======================= END CONFIGURABLE OPTIONS ======================== *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/string
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/notify

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .tag M-LIB-THEME-tag
$DEF .tag_err M-LIB-THEME-tag_err

(* ------------------------------------------------------------------------- *)

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

: morph_delete[ ref:object str:morph_name bool:quiet -- bool:success? ]
  morph_name @ fix_morph_name morph_name !

  "_morph/morphs/" morph_name @ strcat var! morph_dir

  object @ morph_dir @ propdir? if
    object @ morph_dir @ remove_prop
    object @ "_morph/mesg/" morph_name @ strcat remove_prop
    quiet @ not if { "Morph '" morph_name @ "' deleted." }cat command @ toupper .tag .tell then
  else
    quiet @ not if { "Morph '" morph_name @ "' not found." }cat command @ toupper .tag_err .tell then
  then
  1
;

: morph_mesg_set[ str:new_mesg ref:object str:morph_name bool:quiet -- bool:success? ]
  morph_name @ fix_morph_name morph_name !
  object @ "_morph/morphs/" morph_name @ strcat propdir? not if
    quiet @ not if { "Morph '" morph_name @ "' not found." }cat command @ toupper .tag_err .tell then
    0 exit
  then
  new_mesg @ if
    object @ "_morph/mesg/" morph_name @ strcat new_mesg @ setprop
    quiet @ not if { "Morph message set for '" morph_name @ "'." }cat command @ toupper .tag .tell then
  else
    object @ "_morph/mesg/" morph_name @ strcat remove_prop
    quiet @ not if { "Morph message cleared for '" morph_name @ "'." }cat command @ toupper .tag .tell then
  then
  1
;

: morph_mesg_get[ ref:object str:morph_name bool:quiet -- str:mesg ]
  morph_name @ fix_morph_name morph_name !
  object @ "_morph/morphs/" morph_name @ strcat propdir? not if
    quiet @ not if { "Morph '" morph_name @ "' not found." }cat command @ toupper .tag_err .tell then
    "" exit
  then
  object @ "_morph/mesg/" morph_name @ strcat getpropstr
  dup not if
    pop { object @ name 1 strcut swap toupper swap strcat " morphs into a " morph_name @ tolower " " "_" subst M-LIB-STRING-single_space "." }cat
  then
;

: morph_list[ ref:object --  ]
  object @ "/_morph/morphs" propdir? if
    "Saved morphs:" command @ toupper .tag .tell
    object @ "/_morph/morphs/" nextprop
    begin
      dup while
      object @ over propdir? if
        dup "/" rsplit swap pop "  " swap strcat command @ toupper .tag .tell
      then
      object @ swap nextprop
    repeat
    pop
  else
    "No saved morphs." command @ toupper .tag .tell
  then
;

: morph[ ref:object str:morph_name bool:save bool:quiet -- bool:success? ]
  morph_name @ fix_morph_name morph_name !

  "_morph/morphs/" morph_name @ strcat var! morph_dir

  save @ if
    object @ morph_dir @ propdir? if
      quiet @ not if "Clearing existing morph..." command @ toupper .tag .tell then
      object @ morph_dir @ remove_prop
      quiet @ not if "Saving morph..." command @ toupper .tag .tell then
    else
      quiet @ not if "Creating new morph..." command @ toupper .tag .tell then
    then
  else
    object @ morph_dir @ propdir? if
      quiet @ not if "Loading morph..." command @ toupper .tag .tell then
    else
      { "Morph '" morph_name @ "' not found." }cat command @ toupper .tag_err .tell
      0 exit
    then
  then

  morph_props foreach
    var! properties
    var! name
    var property

    save @ if
      quiet @ not if { "  Saving '" name @ "'..." }cat command @ toupper .tag .tell then
      properties @ foreach
        nip
        property !
        object @ property @ propdir? object @ property @ getpropstr or if
          object @ property @ object @ { morph_dir @ "/" property @ }cat copy_props
        then
      repeat
    else
      quiet @ not if { "  Loading '" name @ "'..." }cat command @ toupper .tag .tell then
      properties @ foreach
        nip
        property !
        object @ { morph_dir @ "/" property @ }cat propdir? object @ { morph_dir @ "/" property @ }cat getpropstr or if
          object @ { morph_dir @ "/" property @ }cat object @ property @ copy_props
        then
      repeat
    then
  repeat

  object @ "/_morph/current" morph_name @ setprop
  1
;

(* ------------------------------------------------------------------------- *)

(*****************************************************************************)
(*                             M-LIB-MORPH-load                              *)
(*****************************************************************************)
: M-LIB-MORPH-load[ ref:object str:morph_name bool:quiet -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ 0 quiet @ morph
;
PUBLIC M-LIB-MORPH-load
$LIBDEF M-LIB-MORPH-load

(*****************************************************************************)
(*                             M-LIB-MORPH-save                              *)
(*****************************************************************************)
: M-LIB-MORPH-save[ ref:object str:morph_name bool:quiet -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ 1 quiet @ morph
;
PUBLIC M-LIB-MORPH-save
$LIBDEF M-LIB-MORPH-save

(*****************************************************************************)
(*                            M-LIB-MORPH-delete                             *)
(*****************************************************************************)
: M-LIB-MORPH-delete[ ref:object str:morph_name bool:quiet -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ quiet @ morph_delete
;
PUBLIC M-LIB-MORPH-delete
$LIBDEF M-LIB-MORPH-delete

(*****************************************************************************)
(*                             M-LIB-MORPH-list                              *)
(*****************************************************************************)
: M-LIB-MORPH-list[ ref:object --  ]
  M-LIB-PROGRAM-needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  object @ morph_list
;
PUBLIC M-LIB-MORPH-list
$LIBDEF M-LIB-MORPH-list

(*****************************************************************************)
(*                           M-LIB-MORPH-mesg_get                            *)
(*****************************************************************************)
: M-LIB-MORPH-mesg_get[ ref:object str:morph_name bool:quiet -- str:mesg ]
  M-LIB-PROGRAM-needs_mlev3
  object @ dbref? not if "Non-dbref argument (1)." abort then
  morph_name @ string? not if "Non-string argument (2)." abort then
  morph_name @ not if "Empty morph name (2)." abort then
  object @ morph_name @ quiet @ morph_mesg_get
;
PUBLIC M-LIB-MORPH-mesg_get
$LIBDEF M-LIB-MORPH-mesg_get

(*****************************************************************************)
(*                           M-LIB-MORPH-mesg_set                            *)
(*****************************************************************************)
: M-LIB-MORPH-mesg_set[ str:new_mesg ref:object str:morph_name bool:quiet -- bool:success? ]
  M-LIB-PROGRAM-needs_mlev3
  new_mesg @ string? not if "Non-string argument (1)." abort then
  object @ dbref? not if "Non-dbref argument (2)." abort then
  morph_name @ string? not if "Non-string argument (3)." abort then
  morph_name @ not if "Empty morph name (3)." abort then
  new_mesg @ object @ morph_name @ quiet @ morph_mesg_set
;
PUBLIC M-LIB-MORPH-mesg_set
$LIBDEF M-LIB-MORPH-mesg_set

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-morph.muf=m/lib/morph
!@set $m/lib/morph=M2
!@set $m/lib/morph=H
!@set $m/lib/morph=S
!@set $m/lib/morph=L

