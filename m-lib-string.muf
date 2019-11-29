!@program m-lib-string.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-string.muf - $m/lib/string                                          *)
(*   String manipulation routines. This is a drop-in replacement for         *)
(*   $lib/strings with additional features.                                  *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-STRING-command_parse ( s -- s s s )                               *)
(*     '$lib/strings style' command string parsing.                          *)
(*       Before: " #option  tom dick  harry = message "                      *)
(*       After:  "option" "tom dick harry" " message "                       *)
(*                                                                           *)
(*   M-LIB-STRING-itox ( i -- s )                                            *)
(*     Convert an integer into a hexadecimal string. This works bit-by-bit   *)
(*     so negative numbers will appear in their two's compliment form.       *)
(*                                                                           *)
(*   M-LIB-STRING-xtoi ( s -- i )                                            *)
(*     Convert a hexadecimal string to an integer. MUF uses 32-bit signed    *)
(*     integers so this may result in a negative number. Like the atoi       *)
(*     primitive, 0 is returned if the string is not a valid hexadecimal     *)
(*     number.                                                               *)
(*                                                                           *)
(*   M-LIB-STRING-single_space ( s -- s )                                    *)
(*     Removes every series of multiple spaces in a row and replaces them    *)
(*     each with a single space.                                             *)
(*                                                                           *)
(*   M-LIB-STRING-join ( ... i s -- s )                                      *)
(*     The inverse of the EXPLODE primitive.                                 *)
(*                                                                           *)
(*   M-LIB-STRING-sito ( i -- s )                                            *)
(*     Like M-LIB-STRING-itox but it will return negative hexadecimal        *)
(*     numbers.                                                              *)
(*                                                                           *)
(*   M-LIB-STRING-zeropad ( s i -- s' )                                      *)
(*     Pad string s out with zeros to i characters.                          *)
(*                                                                           *)
(*   The standard $lib/strings definitions are also available.               *)
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
$NOTE    String manipulation routines.
$DOCCMD  @list __PROG__=2-61

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/array

$PUBDEF :

(* ------------------------------------------------------------------------- *)

(* Iterate over a string, separating it whenever anything inside a given array is found and producing an array of all the elements *)
(* "01x2345y67" { "x" "y" }list -> { "01" "x" "2345" "y" "67" }list *)
: dice_array[ str:source arr:sep -- arr:result ]
  { }list var! result
  begin
    (* Find the next match for each separator and keep the closest one *)
    "" var! min_sep
    inf var! min_pos
    sep @ foreach
      nip
      var! this_sep
      source @ this_sep @ instring var! this_pos
      this_pos @ if
        this_pos @ -- this_pos ! (* We want to cut just before the separator *)
        this_pos @ min_pos @ < if
          this_pos @ min_pos !
          this_sep @ min_sep !
        then
      then
    repeat
    (* If we found no separator, we're done. *)
    min_sep @ not if
      source @ result @ array_appenditem result !
      break
    then
    (* Slice off everything up to the next separator, and the separator *)
    source @ min_pos @ strcut source ! result @ array_appenditem result !
    source @ min_sep @ strlen strcut source ! result @ array_appenditem result !
  repeat
  (* Return result *)
  result @
;

: carve_array ( s1 s2 -- a )
  dup -rot explode_array
  1 array_cut foreach
    nip
    3 pick swap strcat swap []<-
  repeat
  nip
;

: slice_array ( s1 s2 -- a )
  dup -rot explode_array
  1 array_cut foreach
    nip
    3 pick rot []<- []<-
  repeat
  nip
;

: einstring ( s s1 -- i )
  over swap instring dup not if pop strlen else nip -- then
;

: cb_strstrip ( s a -- s )
  2 try
    "strstrip" [] execute
    depth 1 = not if "Unexpected number of results from custom 'strstrip' call." abort then
  catch
    abort
  endcatch
;

: cb_strcut ( s i a -- s1 s2 )
  3 try
    "strcut" [] execute
    depth 2 = not if "Unexpected number of results from custom 'strcut' call." abort then
  catch
    abort
  endcatch
;

: cb_strcat ( s1 s2 a -- s )
  3 try
    "strcat" [] execute
    depth 1 = not if "Unexpected number of results from custom 'strcat' call." abort then
  catch
    abort
  endcatch
;

: cb_strlen ( s a -- i )
  var! cbs
  cbs @ cb_strstrip
  strlen
;

: cb_instr ( s s1 a -- i )
  var! cbs
  swap cbs @ cb_strstrip swap
  cbs @ cb_strstrip
  instr
;

: cb_rinstr ( s s1 a -- i )
  var! cbs
  swap cbs @ cb_strstrip swap
  cbs @ cb_strstrip
  rinstr
;

: cb_instring ( s s1 a -- i )
  var! cbs
  swap cbs @ cb_strstrip swap
  cbs @ cb_strstrip
  instring
;

: cb_rinstring ( s s1 a -- i )
  var! cbs
  swap cbs @ cb_strstrip swap
  cbs @ cb_strstrip
  rinstring
;

: cb_einstring ( s s1 a -- i )
  var! cbs
  swap cbs @ cb_strstrip swap
  cbs @ cb_strstrip
  einstring
;

: cb_striplead ( s a -- s )
  var! cbs
  dup cbs @ cb_strlen over cbs @ cb_strstrip striplead strlen -
  cbs @ cb_strcut swap pop
;

: cb_striptail ( s a -- s )
  var! cbs
  dup cbs @ cb_strstrip striptail strlen
  cbs @ cb_strcut pop
;

: cb_strip ( s a -- s )
  var! cbs
  cbs @ cb_striplead cbs @ cb_striptail
;

: cb_dice_array[ str:source arr:sep dict:cbs -- arr:result ]
  source @ cbs @ cb_strstrip var! source_stripped
  { sep @ foreach nip cbs @ cb_strstrip repeat }list var! sep_stripped
  source_stripped @ sep_stripped @ dice_array
  {
    swap foreach
      nip
      source @ swap strlen cbs @ cb_strcut source !
    repeat
  }list
;

: cb_carve_array[ str:source str:sep dict:cbs -- arr:result ]
  source @ cbs @ cb_strstrip sep @ cbs @ cb_strstrip carve_array
  { source @ rot foreach nip strlen cbs @ cb_strcut repeat }list
;

: cb_slice_array[ str:source str:sep dict:cbs -- arr:result ]
  source @ cbs @ cb_strstrip sep @ cbs @ cb_strstrip slice_array
  { source @ rot foreach nip strlen cbs @ cb_strcut repeat }list
;

: cb_explode_array[ str:source str:sep dict:cbs -- arr:result ]
  source @ cbs @ cb_strstrip sep @ cbs @ cb_strstrip explode_array
  { source @ rot foreach nip strlen cbs @ cb_strcut 1 cbs @ cb_strcut swap pop repeat }list
;

: sms ( s -- s )
  begin
    " " "  " subst
    dup "  " instr not
  until
;

: hex? ( s -- i )
  begin
    1 strcut swap
    dup number? not swap ctoi dup "A" ctoi < swap "F" ctoi > or and if (* expects caps *)
      pop 0 exit
    then
    dup not
  until
  pop 1
;

: standard_strstrip ( s -- s ) ;
: standard_strcut ( s i -- s1 s2 ) strcut ;
: standard_strcat ( s1 s2 -- s ) strcat ;

(* Take the callback list in user supplied format and clean it up into the format expected by the internal code *)
: string_cbs_process[ dict:cbs_in -- dict:cbs_out ]
  var cb
  (* Set defaults *)
  {
    "strstrip" 'standard_strstrip
    "strcut" 'standard_strcut
    "strcat" 'standard_strcat
  }dict var! cbs_out
  (* Handle function pointers *)
  { "strstrip" "strcut" "strcat" }list foreach
    nip
    cb !
    cbs_in @ cb @ [] address? not if continue then
    cbs_in @ cb @ [] cbs_out @ cb @ ->[] cbs_out !
  repeat
  (* Return result *)
  cbs_out @
;

(*****************************************************************************)
(*                         M-LIB-STRING-command_parse                        *)
(*****************************************************************************)
: M-LIB-STRING-command_parse ( s -- s s s )
  (* M1 OK *)
  "s" checkargs
  "=" rsplit swap
  striplead dup "#" instr 1 = if
    1 strcut nip
    " " split
  else
    "" swap
  then
  strip
  sms
  rot
;
PUBLIC M-LIB-STRING-command_parse
$LIBDEF M-LIB-STRING-command_parse

(*****************************************************************************)
(*                          M-LIB-STRING-carve_array                         *)
(*****************************************************************************)
: M-LIB-STRING-carve_array[ str:source str:sep dict:cbs -- arr:result ]
  (* M1 OK *)
  source @ string? not if "Non-string argument (1)." abort then
  sep @ string? not if "Non-string argument (2)." abort then
  cbs @ dictionary? not if "Non-dictionary argument (3)." abort then
  cbs @ string_cbs_process cbs !
  source @ sep @ cbs @ cb_carve_array
;
PUBLIC M-LIB-STRING-carve_array
$LIBDEF M-LIB-STRING-carve_array

(*****************************************************************************)
(*                          M-LIB-STRING-dice_array                          *)
(*****************************************************************************)
: M-LIB-STRING-dice_array[ str:source arr:sep dict:cbs -- arr:result ]
  (* M1 OK *)
  source @ string? not if "Non-string argument (1)." abort then
  sep @ array? not if "Non-array argument (2)." abort then
  cbs @ dictionary? not if "Non-dictionary argument (3)." abort then
  cbs @ string_cbs_process cbs !
  source @ sep @ cbs @ cb_dice_array
;
PUBLIC M-LIB-STRING-dice_array
$LIBDEF M-LIB-STRING-dice_array

(*****************************************************************************)
(*                             M-LIB-STRING-hex?                             *)
(*****************************************************************************)
: M-LIB-STRING-hex? ( s -- i )
  (* M1 OK *)
  "s" checkargs
  toupper hex?
;
PUBLIC M-LIB-STRING-hex?
$LIBDEF M-LIB-STRING-hex?

(*****************************************************************************)
(*                             M-LIB-STRING-itox                             *)
(*****************************************************************************)
: M-LIB-STRING-itox ( i -- s )
  (* M1 OK *)
  "i" checkargs
  "" var! retval
  8 begin
    swap
    dup 15 bitand
    dup 10 < if
      intostr
    else
      10 - "A" ctoi + itoc
    then
    retval @ strcat retval !
    -4 bitshift
    swap
    --
    over over and not
  until
  pop pop
  retval @
;
PUBLIC M-LIB-STRING-itox
$LIBDEF M-LIB-STRING-itox

(*****************************************************************************)
(*                         M-LIB-STRING-single_space                         *)
(*****************************************************************************)
: M-LIB-STRING-single_space ( s -- s )
  (* M1 OK *)
  "s" checkargs
  sms
;
PUBLIC M-LIB-STRING-single_space
$LIBDEF M-LIB-STRING-single_space

(*****************************************************************************)
(*                           M-LIB-STRING-wordwrap                           *)
(*****************************************************************************)
: M-LIB-STRING-wordwrap[ str:source int:width_wrap dict:cbs -- arr:lines ]
  (* M1 OK *)
  source @ string? not if "Non-string argument (1)." abort then
  source @ "\r" instr if "Newlines in word wrap strings not yet supported." abort then
  width_wrap @ int? not if "Non-integer argument (2)." abort then
  cbs @ dictionary? not if "Non-dictionary argument (3)." abort then
  cbs @ string_cbs_process cbs !
  { }list var! lines
  (* Dice an array with space separators, but leave the spaces attached in front of the saparated words *)
  source @ cbs @ cb_strstrip var! source_stripped
  {
    ""
    source_stripped @ striptail { " " }list dice_array foreach
      nip
      over strip not if strcat then
    repeat
  }list
  {
    swap foreach
      nip
      source @ swap strlen cbs @ cb_strcut source !
    repeat
  }list
  1 array_cut swap array_vals pop var! line
  foreach
    nip
    dup cbs @ cb_strlen line @ cbs @ cb_strlen + width_wrap @ > if
      line @ lines @ []<- lines !
      "" line !
      cbs @ cb_striplead
    then
    line @ swap cbs @ cb_strcat line !
  repeat
  line @ if
    line @ lines @ []<- lines !
  then
  lines @
;
PUBLIC M-LIB-STRING-wordwrap
$LIBDEF M-LIB-STRING-wordwrap

(*****************************************************************************)
(*                             M-LIB-STRING-xtoi                             *)
(*****************************************************************************)
: M-LIB-STRING-xtoi ( s -- i )
  (* M1 OK *)
  "s" checkargs
  toupper
  (* Return 0 if there are any invalid characters *)
  dup hex? not if
    pop 0 exit
  then
  (* Truncate to 32-bits worth of hexadecimal *)
  dup strlen
  8 - dup 0 <= if
    pop
  else
    strcut nip
  then
  (* Convert and return*)
  0 var! retval
  begin
    1 strcut swap
    dup number? if
      atoi
    else
      ctoi
      "A" ctoi - 10 +
    then
    retval @ 4 bitshift swap + retval !
    dup not
  until
  pop
  retval @
;
PUBLIC M-LIB-STRING-xtoi
$LIBDEF M-LIB-STRING-xtoi

(*****************************************************************************)
(*                             M-LIB-STRING-join                             *)
(*****************************************************************************)
$PUBDEF M-LIB-STRING-join    over 2 + 0 swap - rotate array_make swap array_join

(*****************************************************************************)
(*                            M-LIB-STRING-sxtoi                             *)
(*****************************************************************************)
$PUBDEF M-LIB-STRING-sitox   dup 0 < if abs "-" swap M-LIB-STRING-itox strcat else M-LIB-STRING-itox then

(*****************************************************************************)
(*                           M-LIB-STRING-zeropad                            *)
(*****************************************************************************)
$PUBDEF M-LIB-STRING-zeropad over strlen - dup 0 > if "0" * swap strcat else pop then

(* -------------------- Compatibility with $lib/strings -------------------- *)
$PUBDEF .asc           ctoi
$PUBDEF .blank?        striplead not
$PUBDEF .center        "%|*s" fmtstring
$PUBDEF .chr           itoc dup not if pop "." then
$PUBDEF .command_parse M-LIB-STRING-command_parse
$PUBDEF .fillfield     rot strlen - dup 1 < if pop pop "" else * then
$PUBDEF .left          "%-*s" fmtstring
$PUBDEF .right         "%*s" fmtstring
$PUBDEF .rsplit        rsplit
$PUBDEF .singlespace   M-LIB-STRING-single_space
$PUBDEF .sls           striplead
$PUBDEF .sms           M-LIB-STRING-single_space
$PUBDEF .split         split
$PUBDEF .strip         strip
$PUBDEF .stripspaces   strip
$PUBDEF .sts           striptail
$PUBDEF STRasc         .asc
$PUBDEF STRblank?      .blank?
$PUBDEF STRcenter      .center
$PUBDEF STRchr         .chr
$PUBDEF STRfillfield   .fillfield
$PUBDEF STRleft        .left
$PUBDEF STRright       .right
$PUBDEF STRrsplit      .rsplit
$PUBDEF STRsinglespace .singlespace
$PUBDEF STRsls         .striplead
$PUBDEF STRsms         .singlespace
$PUBDEF STRsplit       .split
$PUBDEF STRstrip       .strip
$PUBDEF STRsts         .sts
(* ------------------------------------------------------------------------- *)

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-string.muf=m/lib/string
!@set $m/lib/string=M2
!@set $m/lib/string=L
!@set $m/lib/string=S
!@set $m/lib/string=H

