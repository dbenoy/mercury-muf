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
(* CUSTOM STRING TYPE ROUTINES:                                              *)
(*   You can define your own custom string types. Typically you would use    *)
(*   this for color-coded strings, but you can use it to include other kinds *)
(*   of metadata in strings as well. To do so, you define a dictionary       *)
(*   object, and provide the following callback function pointers:           *)
(*                                                                           *)
(*     "strstrip" ( ? -- s )                                                 *)
(*       This callback takes the custom string type variable, strips away    *)
(*       all metadata and turns it into a plain string. If the string has    *)
(*       special escapes that produce literals (Such as \~& for FB5 color    *)
(*       codes, for example) then those sequences should be resolved and the *)
(*       escaped version included in the string.                             *)
(*                                                                           *)
(*     "strcut" ( ? i -- ? ? )                                               *)
(*       This callback works like the STRCUT primitive, cutting your custom  *)
(*       string type at the given character, splitting it into two custom    *)
(*       string types. Like strstrip above, it should resolve any special    *)
(*       escape sequences that produce literals, and count those characters  *)
(*       when deciding where to cut. Any metadata can be preserved as you    *)
(*       see fit.                                                            *)
(*                                                                           *)
(*     "strcat" ( ? ? -- ? )                                                 *)
(*       Like the STRCAT primitive, concatenate two custom string type       *)
(*       variables to produce one. Any metadata can be preserved as you see  *)
(*       fit.                                                                *)
(*                                                                           *)
(*     "toupper" ( ? -- ? )                                                  *)
(*       Like the TOUPPER primitive, change all characters in your custom    *)
(*       string type to uppercase.                                           *)
(*                                                                           *)
(*     "tolower" ( ? -- ? )                                                  *)
(*       Like the TOLOWER primitive, change all characters in your custom    *)
(*       string type to lowercase.                                           *)
(*                                                                           *)
(*   Functions ending in _cb should work equivalently to their non-_cb       *)
(*   counterparts, but you pass in the callback dictionary as the last       *)
(*   parameter. The following _cb routines are available:                    *)
(*     M-LIB-STRING-array_interpret_cb                                       *)
(*     M-LIB-STRING-}join_cb                                                 *)
(*     M-LIB-STRING-array_join_cb                                            *)
(*     M-LIB-STRING-}cat_cb                                                  *)
(*     M-LIB-STRING-atoi_cb                                                  *)
(*     M-LIB-STRING-carve_array_cb                                           *)
(*     M-LIB-STRING-einstr_cb                                                *)
(*     M-LIB-STRING-einstring_cb                                             *)
(*     M-LIB-STRING-erinstr_cb                                               *)
(*     M-LIB-STRING-erinstring_cb                                            *)
(*     M-LIB-STRING-explode_array_cb                                         *)
(*     M-LIB-STRING-explode_cb                                               *)
(*     M-LIB-STRING-hex?_cb                                                  *)
(*     M-LIB-STRING-instr_cb                                                 *)
(*     M-LIB-STRING-instring_cb                                              *)
(*     M-LIB-STRING-midstr_cb                                                *)
(*     M-LIB-STRING-number?_cb                                               *)
(*     M-LIB-STRING-regslice_cb                                              *)
(*     M-LIB-STRING-rinstr_cb                                                *)
(*     M-LIB-STRING-rinstring_cb                                             *)
(*     M-LIB-STRING-rsplit_cb                                                *)
(*     M-LIB-STRING-single_space_cb                                          *)
(*     M-LIB-STRING-slice_array_cb                                           *)
(*     M-LIB-STRING-split_cb                                                 *)
(*     M-LIB-STRING-strcat_cb                                                *)
(*     M-LIB-STRING-strcmp_cb                                                *)
(*     M-LIB-STRING-strcut_cb                                                *)
(*     M-LIB-STRING-stringcmp_cb                                             *)
(*     M-LIB-STRING-stringpfx_cb                                             *)
(*     M-LIB-STRING-strip_cb                                                 *)
(*     M-LIB-STRING-striplead_cb                                             *)
(*     M-LIB-STRING-striptail_cb                                             *)
(*     M-LIB-STRING-strlen_cb                                                *)
(*     M-LIB-STRING-strncmp_cb                                               *)
(*     M-LIB-STRING-strtof_cb                                                *)
(*     M-LIB-STRING-subst_cb                                                 *)
(*     M-LIB-STRING-toupper_cb                                               *)
(*     M-LIB-STRING-tolower_cb                                               *)
(*     M-LIB-STRING-wordwrap_cb                                              *)
(*     M-LIB-STRING-xtoi_cb                                                  *)
(*     M-LIB-STRING-zeropad_cb                                               *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-STRING-carve_array ( s s -- a )                                   *)
(*     Like the EXPLODE_ARRAY primitive, except the separators are kept.     *)
(*     They remain at the beginning of their string. For example:            *)
(*       "a b  c-- d" " " M-LIB-STRING-carve_array                           *)
(*       Result: {"a", " b", " ", " c--", " d"}                              *)
(*                                                                           *)
(*     Each element starts with a separator except for the first. If the     *)
(*     source string starts with a separator then the first element will be  *)
(*     an empty string, so the number of elements will always be the number  *)
(*     of separators found, plus one.                                        *)
(*                                                                           *)
(*   M-LIB-STRING-command_parse ( s -- s s s )                               *)
(*     '$lib/strings style' command string parsing.                          *)
(*       Before: " #option  tom dick  harry = message "                      *)
(*       After:  "option" "tom dick harry" " message "                       *)
(*                                                                           *)
(*   M-LIB-STRING-einstr ( s s -- i )                                        *)
(*   M-LIB-STRING-einstring ( s s -- i )                                     *)
(*   M-LIB-STRING-erinstr ( s s -- i )                                       *)
(*   M-LIB-STRING-erinstring ( s s -- i )                                    *)
(*     These e- prefixed versions work like their equivalent built-in        *)
(*     primitives, except they return a character number starting at 0. If   *)
(*     the substring is not found, it returns one character past the end of  *)
(*     the string. This is suitable for use with STRCUT if you want to cut   *)
(*     just before the found instance of the substring.                      *)
(*                                                                           *)
(*   M-LIB-STRING-hex? ( s -- i )                                            *)
(*     This is like the NUMBER? primitive for unsigned hexadecimal numbers.  *)
(*     It will return true if the string contains only 0 to 9, A to F. It is *)
(*     case insensitive.                                                     *)
(*                                                                           *)
(*   M-LIB-STRING-itox ( i -- s )                                            *)
(*     Convert an integer into a hexadecimal string. This works bit-by-bit   *)
(*     so negative numbers will appear in their two's compliment form.       *)
(*                                                                           *)
(*   M-LIB-STRING-regslice ( s s i -- a )                                    *)
(*     Like the REGSPLIT primitive, except separators are kept. For example: *)
(*       "a b  c-- d" " |--" 0 M-LIB-STRING-regslice                         *)
(*       Result: {"a", " ", "b", " ", "", " ", "c", "--", "", " ", "d"}      *)
(*                                                                           *)
(*     The array will never begin or end with a separator, so it will always *)
(*     have an odd number of elements.                                       *)
(*                                                                           *)
(*   M-LIB-STRING-single_space ( s -- s )                                    *)
(*     Removes every series of multiple spaces in a row and replaces them    *)
(*     each with a single space.                                             *)
(*                                                                           *)
(*   M-LIB-STRING-sitox ( i -- s )                                           *)
(*     Like M-LIB-STRING-itox but it will return negative hexadecimal        *)
(*     numbers.                                                              *)
(*                                                                           *)
(*   M-LIB-STRING-slice_array ( s s -- a )                                   *)
(*     Like the EXPLODE_ARRAY primitive, except the separators are kept. For *)
(*     example:                                                              *)
(*       "a b  c-- d" " " M-LIB-STRING-slice_array                           *)
(*       Result: {"a", " ", "b", " ", "", " ", "c--", " ", "d"}              *)
(*                                                                           *)
(*     The array will never begin or end with a separator, so it will always *)
(*     have an odd number of elements.                                       *)
(*                                                                           *)
(*   M-LIB-STRING-wordwrap[ str:source int:width_wrap dict:opts --           *)
(*                          arr:lines ]                                      *)
(*     Takes a string and wraps it into multiple lines at the given wrapping *)
(*     width. If a single word exceeds the wrapping with, then the line will *)
(*     exceed the wrapping width. 'opts' is reserved for future use and      *)
(*     should be an empty dictionary.                                        *)
(*                                                                           *)
(*   M-LIB-STRING-xtoi ( s -- i )                                            *)
(*     Convert a hexadecimal string to an integer. MUF uses 32-bit signed    *)
(*     integers so this may result in a negative number. Like the ATOI       *)
(*     primitive, 0 is returned if the string is not a valid hexadecimal     *)
(*     number.                                                               *)
(*                                                                           *)
(*   M-LIB-STRING-zeropad ( s i -- s )                                       *)
(*     Pad string s out with zeros to i characters.                          *)
(*                                                                           *)
(*   The standard $lib/strings definitions are also available.               *)
(*                                                                           *)
(*  TECHNICAL NOTES:                                                         *)
(*    Callback versions of some string primitives are missing. They may be   *)
(*    added at some point.                                                   *)
(*      array_fmtstrings                                                     *)
(*      fmtstring                                                            *)
(*      pronoun_sub                                                          *)
(*      regexp                                                               *)
(*      regsplit                                                             *)
(*      regsplit_noempty                                                     *)
(*      regsub                                                               *)
(*      smatch                                                               *)
(*      tokensplit                                                           *)
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
$DOCCMD  @list __PROG__=2-212

(* ------------------------------------------------------------------------- *)

$PUBDEF :

: regslice[ str:text str:pattern int:flags -- list:results ]
  {
    text @ begin
      dup pattern @ flags @ regexp nip
      dup not if pop break then
      1 array_cut pop array_vals pop array_vals pop
      -rot -- strcut
      rot strcut
    repeat
  }list
;

: carve_array ( s s -- a )
  dup -rot explode_array
  1 array_cut foreach
    nip
    3 pick swap strcat swap []<-
  repeat
  nip
;

: slice_array ( s s -- a )
  dup -rot explode_array
  1 array_cut foreach
    nip
    3 pick rot []<- []<-
  repeat
  nip
;

: einstr ( s s -- i )
  over swap instr dup not if pop strlen else nip -- then
;

: einstring ( s s -- i )
  over swap instring dup not if pop strlen else nip -- then
;

: erinstr ( s s -- i )
  over swap rinstr dup not if pop strlen else nip -- then
;

: erinstring ( s s -- i )
  over swap rinstring dup not if pop strlen else nip -- then
;

: single_space ( s -- s )
  " +" " " REG_ALL regsub
;

: hex? ( s -- i )
  "^[0-9A-F]+$" REG_ICASE regexp pop not not
;

: xtoi ( s -- i )
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
  toupper
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

: itox ( i -- s )
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

: strstrip_cb ( ? a -- ? )
  2 try
    "strstrip" [] execute
    depth 1 = not if "Unexpected number of results from 'strstrip' callback." abort then
  catch
    abort
  endcatch
;

: strcut_cb ( ? i cbs -- ? ? )
  3 try
    "strcut" [] execute
    depth 2 = not if "Unexpected number of results from 'strcut' callback." abort then
  catch
    abort
  endcatch
;

: strcat_cb ( ? ? cbs -- ? )
  3 try
    "strcat" [] execute
    depth 1 = not if "Unexpected number of results from 'strcat' callback." abort then
  catch
    abort
  endcatch
;

: toupper_cb ( ? cbs -- ? )
  2 try
    "toupper" [] execute
    depth 1 = not if "Unexpected number of results from 'toupper' callback." abort then
  catch
    abort
  endcatch
;

: tolower_cb ( ? cbs -- ? )
  2 try
    "tolower" [] execute
    depth 1 = not if "Unexpected number of results from 'tolower' callback." abort then
  catch
    abort
  endcatch
;

: strlen_cb ( s a -- i )
  strstrip_cb strlen
;

: instr_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  instr
;

: rinstr_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  rinstr
;

: instring_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  instring
;

: rinstring_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  rinstring
;

: einstr_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  einstr
;

: einstring_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  einstring
;

: erinstr_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  einstr
;

: erinstring_cb ( s s a -- i )
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  einstring
;

: striplead_cb ( s a -- s )
  var! cbs
  dup cbs @ strlen_cb over cbs @ strstrip_cb striplead strlen -
  cbs @ strcut_cb swap pop
;

: striptail_cb ( s a -- s )
  var! cbs
  dup cbs @ strstrip_cb striptail strlen
  cbs @ strcut_cb pop
;

: strip_cb ( s a -- s )
  var! cbs
  cbs @ striplead_cb cbs @ striptail_cb
;

: regslice_cb[ str:text str:pattern int:flags dict:cbs -- arr:results ]
  text @ cbs @ strstrip_cb pattern @ flags @ regslice
  { text @ rot foreach nip strlen cbs @ strcut_cb repeat pop }list
;

: carve_array_cb[ str:source str:sep dict:cbs -- arr:result ]
  source @ cbs @ strstrip_cb sep @ cbs @ strstrip_cb carve_array
  { source @ rot foreach nip strlen cbs @ strcut_cb repeat pop }list
;

: slice_array_cb[ str:source str:sep dict:cbs -- arr:result ]
  source @ cbs @ strstrip_cb sep @ cbs @ strstrip_cb slice_array
  { source @ rot foreach nip strlen cbs @ strcut_cb repeat pop }list
;

: explode_array_cb[ str:source str:sep dict:cbs -- arr:result ]
  source @ cbs @ strstrip_cb sep @ cbs @ strstrip_cb explode_array
  sep @ strlen var! sep_len
  { source @ rot foreach nip strlen cbs @ strcut_cb sep_len @ cbs @ strcut_cb swap pop repeat pop }list
;

: subst_cb[ str:source str:to str:from arr:cbs -- str:result ]
  source @ from @ cbs @ slice_array_cb
  1 array_cut swap array_vals pop var! result
  begin
    dup not if pop break then
    2 array_cut swap array_vals pop
    nip
    result @ to @ cbs @ strcat_cb swap cbs @ strcat_cb result !
  repeat
  result @
;

: wordwrap_cb[ any:source int:width_wrap dict:opts dict:cbs -- arr:lines ]
  { }list var! lines
  (* FIXME: Split \r into separate lines. *)
  source @ cbs @ striptail_cb " " cbs @ carve_array_cb
  1 array_cut swap array_vals pop var! line
  foreach
    nip
    dup cbs @ strlen_cb line @ cbs @ strlen_cb + width_wrap @ > if
      line @ lines @ []<- lines !
      "" line !
      cbs @ striplead_cb
    then
    line @ swap cbs @ strcat_cb line !
  repeat
  line @ if
    line @ lines @ []<- lines !
  then
  lines @
;

: std_cb_strstrip ( s -- s ) ;
: std_cb_strcut ( s i -- s1 s2 ) strcut ;
: std_cb_strcat ( s1 s2 -- s ) strcat ;
: std_cb_toupper ( s -- s ) toupper ;
: std_cb_tolower ( s -- s ) tolower ;
: std_cb ( -- a ) { "strcat" 'std_cb_strcat "strcut" 'std_cb_strcut "strstrip" 'std_cb_strstrip "toupper" 'std_cb_toupper "tolower" 'std_cb_tolower }dict ;

(* Take the callback list in user supplied format and clean it up into the format expected by the internal code *)
: cbs_check[ dict:cbs -- ]
  var cb
  { "strstrip" "strcut" "strcat" "toupper" "tolower" }list foreach
    nip
    var! cb
    cbs @ cb @ [] address? not if { "String callback " cb @ " not found." }join abort then
  repeat
;

(*****************************************************************************)
(*                      M-LIB-STRING-array_interpret_cb                      *)
(*****************************************************************************)
: M-LIB-STRING-array_interpret_cb ( a a -- ? )
  (* M1 OK *)
  "yx" checkargs
  dup cbs_check
  var! cbs
  "" swap foreach
    nip
    1 array_make array_interpret cbs @ strcat_cb
  repeat
;
PUBLIC M-LIB-STRING-array_interpret_cb
$LIBDEF M-LIB-STRING-array_interpret_cb

(*****************************************************************************)
(*                        M-LIB-STRING-array_join_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-array_join_cb ( a ? a -- ? )
  (* M1 OK *)
  "y?x" checkargs
  dup cbs_check
  var! cbs
  swap 1 array_cut foreach nip 3 pick rot []<- []<- repeat swap pop
  "" swap foreach
    nip
    1 array_make "" array_join cbs @ strcat_cb
  repeat
;
PUBLIC M-LIB-STRING-array_join_cb
$LIBDEF M-LIB-STRING-array_join_cb

(*****************************************************************************)
(*                           M-LIB-STRING-atoi_cb                            *)
(*****************************************************************************)
: M-LIB-STRING-atoi_cb ( ? cbs -- i )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  strstrip_cb
  atoi
;
PUBLIC M-LIB-STRING-atoi_cb
$LIBDEF M-LIB-STRING-atoi_cb

(*****************************************************************************)
(*                         M-LIB-STRING-carve_array                          *)
(*****************************************************************************)
: M-LIB-STRING-carve_array ( s s -- a )
  (* M1 OK *)
  "ss" checkargs
  carve_array
;
PUBLIC M-LIB-STRING-carve_array
$LIBDEF M-LIB-STRING-carve_array

(*****************************************************************************)
(*                        M-LIB-STRING-carve_array_cb                        *)
(*****************************************************************************)
: M-LIB-STRING-carve_array_cb ( ? ? cbs -- a )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  carve_array_cb
;
PUBLIC M-LIB-STRING-carve_array_cb
$LIBDEF M-LIB-STRING-carve_array_cb

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
  single_space
  rot
;
PUBLIC M-LIB-STRING-command_parse
$LIBDEF M-LIB-STRING-command_parse

(*****************************************************************************)
(*                            M-LIB-STRING-einstr                            *)
(*****************************************************************************)
: M-LIB-STRING-einstr ( s s -- i )
  (* M1 OK *)
  "ss" checkargs
  einstr
;
PUBLIC M-LIB-STRING-einstr
$LIBDEF M-LIB-STRING-einstr

(*****************************************************************************)
(*                          M-LIB-STRING-einstr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-einstr_cb ( ? ? a -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  einstr_cb
;
PUBLIC M-LIB-STRING-einstr_cb
$LIBDEF M-LIB-STRING-einstr_cb

(*****************************************************************************)
(*                          M-LIB-STRING-einstring                           *)
(*****************************************************************************)
: M-LIB-STRING-einstring ( s s -- i )
  (* M1 OK *)
  "ss" checkargs
  einstring
;
PUBLIC M-LIB-STRING-einstring
$LIBDEF M-LIB-STRING-einstring

(*****************************************************************************)
(*                         M-LIB-STRING-einstring_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-einstring_cb ( ? ? a -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  einstring_cb
;
PUBLIC M-LIB-STRING-einstring_cb
$LIBDEF M-LIB-STRING-einstring_cb

(*****************************************************************************)
(*                           M-LIB-STRING-erinstr                            *)
(*****************************************************************************)
: M-LIB-STRING-erinstr ( s s -- i )
  (* M1 OK *)
  "ss" checkargs
  erinstr
;
PUBLIC M-LIB-STRING-erinstr
$LIBDEF M-LIB-STRING-erinstr

(*****************************************************************************)
(*                          M-LIB-STRING-erinstr_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-erinstr_cb ( ? ? a -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  erinstr_cb
;
PUBLIC M-LIB-STRING-erinstr_cb
$LIBDEF M-LIB-STRING-erinstr_cb

(*****************************************************************************)
(*                          M-LIB-STRING-erinstring                          *)
(*****************************************************************************)
: M-LIB-STRING-erinstring ( s s -- i )
  (* M1 OK *)
  "ss" checkargs
  erinstring
;
PUBLIC M-LIB-STRING-erinstring
$LIBDEF M-LIB-STRING-erinstring

(*****************************************************************************)
(*                        M-LIB-STRING-erinstring_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-erinstring_cb ( ? ? a -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  erinstring_cb
;
PUBLIC M-LIB-STRING-erinstring_cb
$LIBDEF M-LIB-STRING-erinstring_cb

(*****************************************************************************)
(*                          M-LIB-STRING-explode_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-explode_cb ( ? ? cbs -- ... i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  explode_array_cb array_vals
;
PUBLIC M-LIB-STRING-explode_cb
$LIBDEF M-LIB-STRING-explode_cb

(*****************************************************************************)
(*                       M-LIB-STRING-explode_array_cb                       *)
(*****************************************************************************)
: M-LIB-STRING-explode_array_cb ( ? ? cbs -- a )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  explode_array_cb
;
PUBLIC M-LIB-STRING-explode_array_cb
$LIBDEF M-LIB-STRING-explode_array_cb

(*****************************************************************************)
(*                             M-LIB-STRING-hex?                             *)
(*****************************************************************************)
: M-LIB-STRING-hex? ( s -- i )
  (* M1 OK *)
  "s" checkargs
  hex?
;
PUBLIC M-LIB-STRING-hex?
$LIBDEF M-LIB-STRING-hex?

(*****************************************************************************)
(*                           M-LIB-STRING-hex?_cb                            *)
(*****************************************************************************)
: M-LIB-STRING-hex?_cb ( ? cbs -- i )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  strstrip_cb hex?
;
PUBLIC M-LIB-STRING-hex?_cb
$LIBDEF M-LIB-STRING-hex?_cb

(*****************************************************************************)
(*                           M-LIB-STRING-instr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-instr_cb ( ? ? cbs -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  instr_cb
;
PUBLIC M-LIB-STRING-instr_cb
$LIBDEF M-LIB-STRING-instr_cb

(*****************************************************************************)
(*                         M-LIB-STRING-instring_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-instring_cb ( ? ? cbs -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  instring_cb
;
PUBLIC M-LIB-STRING-instring_cb
$LIBDEF M-LIB-STRING-instring_cb

(*****************************************************************************)
(*                             M-LIB-STRING-itox                             *)
(*****************************************************************************)
: M-LIB-STRING-itox ( i -- s )
  (* M1 OK *)
  "i" checkargs
  itox
;
PUBLIC M-LIB-STRING-itox
$LIBDEF M-LIB-STRING-itox

(*****************************************************************************)
(*                          M-LIB-STRING-midstr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-midstr_cb ( ? i i cbs -- ? )
  (* M1 OK *)
  "?iix" checkargs
  dup cbs_check
  var! cbs
  over 1 < if "Data must be a positive integer. (2)" abort then
  -rot -- cbs @ strcut_cb swap pop swap cbs @ strcut_cb pop
;
PUBLIC M-LIB-STRING-midstr_cb
$LIBDEF M-LIB-STRING-midstr_cb

(*****************************************************************************)
(*                          M-LIB-STRING-number?_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-number?_cb ( ? cbs -- i )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  strstrip_cb number?
;
PUBLIC M-LIB-STRING-number?_cb
$LIBDEF M-LIB-STRING-number?_cb

(*****************************************************************************)
(*                           M-LIB-STRING-regslice                           *)
(*****************************************************************************)
: M-LIB-STRING-regslice ( s s i -- a )
  (* M1 OK *)
  "ssi" checkargs
  regslice
;
PUBLIC M-LIB-STRING-regslice
$LIBDEF M-LIB-STRING-regslice

(*****************************************************************************)
(*                         M-LIB-STRING-regslice_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-regslice_cb ( ? ? i cbs -- a )
  (* M1 OK *)
  "??ix" checkargs
  dup cbs_check
  regslice_cb
;
PUBLIC M-LIB-STRING-regslice_cb
$LIBDEF M-LIB-STRING-regslice_cb

(*****************************************************************************)
(*                          M-LIB-STRING-rinstr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-rinstr_cb ( ? ? cbs -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  rinstr_cb
;
PUBLIC M-LIB-STRING-rinstr_cb
$LIBDEF M-LIB-STRING-rinstr_cb

(*****************************************************************************)
(*                         M-LIB-STRING-rinstring_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-rinstring_cb ( ? ? cbs -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  rinstring_cb
;
PUBLIC M-LIB-STRING-rinstring_cb
$LIBDEF M-LIB-STRING-rinstring_cb

(*****************************************************************************)
(*                          M-LIB-STRING-rsplit_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-rsplit_cb[ any:source any:sep arr:cbs -- any:result1 any:result2 ]
  (* M1 OK *)
  cbs @ dictionary? not if "Non-dictionary argument (3)." abort then
  cbs @ cbs_check
  source @ source @ sep @ cbs @ erinstr_cb cbs @ strcut_cb
  sep @ cbs @ strlen_cb cbs @ strcut_cb swap pop
;
PUBLIC M-LIB-STRING-rsplit_cb
$LIBDEF M-LIB-STRING-rsplit_cb

(*****************************************************************************)
(*                         M-LIB-STRING-single_space                         *)
(*****************************************************************************)
: M-LIB-STRING-single_space ( s -- s )
  (* M1 OK *)
  "s" checkargs
  single_space
;
PUBLIC M-LIB-STRING-single_space
$LIBDEF M-LIB-STRING-single_space

(*****************************************************************************)
(*                       M-LIB-STRING-single_space_cb                        *)
(*****************************************************************************)
: M-LIB-STRING-single_space_cb ( ? cbs -- ? )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  var! cbs
  begin " " "  " cbs @ subst_cb
    dup "  " cbs @ instr_cb not
  until
;
PUBLIC M-LIB-STRING-single_space_cb
$LIBDEF M-LIB-STRING-single_space_cb

(*****************************************************************************)
(*                            M-LIB-STRING-sitox                             *)
(*****************************************************************************)
: M-LIB-STRING-sitox ( i -- s )
  (* M1 OK *)
  "i" checkargs
  dup 0 < if
    abs "-" swap itox strcat
  else
    itox
  then
;
PUBLIC M-LIB-STRING-sitox
$LIBDEF M-LIB-STRING-sitox

(*****************************************************************************)
(*                         M-LIB-STRING-slice_array                          *)
(*****************************************************************************)
: M-LIB-STRING-slice_array ( s s -- a )
  (* M1 OK *)
  "ss" checkargs
  slice_array
;
PUBLIC M-LIB-STRING-slice_array
$LIBDEF M-LIB-STRING-slice_array

(*****************************************************************************)
(*                        M-LIB-STRING-slice_array_cb                        *)
(*****************************************************************************)
: M-LIB-STRING-slice_array_cb ( ? ? cbs -- a )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  slice_array_cb
;
PUBLIC M-LIB-STRING-slice_array_cb
$LIBDEF M-LIB-STRING-slice_array_cb

(*****************************************************************************)
(*                           M-LIB-STRING-split_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-split_cb[ any:source any:sep arr:cbs -- any:result1 any:result2 ]
  (* M1 OK *)
  cbs @ dictionary? not if "Non-dictionary argument (3)." abort then
  cbs @ cbs_check
  source @ source @ sep @ cbs @ einstr_cb cbs @ strcut_cb
  sep @ cbs @ strlen_cb cbs @ strcut_cb swap pop
;
PUBLIC M-LIB-STRING-split_cb
$LIBDEF M-LIB-STRING-split_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strcat_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strcat_cb ( ? ? cbs -- ? )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  strcat_cb
;
PUBLIC M-LIB-STRING-strcat_cb
$LIBDEF M-LIB-STRING-strcat_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strcmp_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strcmp_cb ( ? ? cbs -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  strcmp
;
PUBLIC M-LIB-STRING-strcmp_cb
$LIBDEF M-LIB-STRING-strcmp_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strcut_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strcut_cb ( ? i cbs -- ? ? )
  (* M1 OK *)
  "?ix" checkargs
  dup cbs_check
  strcut_cb
;
PUBLIC M-LIB-STRING-strcut_cb
$LIBDEF M-LIB-STRING-strcut_cb

(*****************************************************************************)
(*                         M-LIB-STRING-stringcmp_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-stringcmp_cb ( ? ? cbs -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  stringcmp
;
PUBLIC M-LIB-STRING-stringcmp_cb
$LIBDEF M-LIB-STRING-stringcmp_cb

(*****************************************************************************)
(*                         M-LIB-STRING-stringpfx_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-stringpfx_cb ( ? ? cbs -- i )
  (* M1 OK *)
  "??x" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  stringpfx
;
PUBLIC M-LIB-STRING-stringpfx_cb
$LIBDEF M-LIB-STRING-stringpfx_cb

(*****************************************************************************)
(*                           M-LIB-STRING-strip_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strip_cb ( ? cbs -- ? )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  strip_cb
;
PUBLIC M-LIB-STRING-strip_cb
$LIBDEF M-LIB-STRING-strip_cb

(*****************************************************************************)
(*                         M-LIB-STRING-striplead_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-striplead_cb ( ? cbs -- ? )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  striplead_cb
;
PUBLIC M-LIB-STRING-striplead_cb
$LIBDEF M-LIB-STRING-striplead_cb

(*****************************************************************************)
(*                         M-LIB-STRING-striptail_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-striptail_cb ( ? cbs -- ? )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  striptail_cb
;
PUBLIC M-LIB-STRING-striptail_cb
$LIBDEF M-LIB-STRING-striptail_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strlen_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strlen_cb ( ? cbs -- i )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  strlen_cb
;
PUBLIC M-LIB-STRING-strlen_cb
$LIBDEF M-LIB-STRING-strlen_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strncmp_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-strncmp_cb ( ? ? i cbs -- i )
  (* M1 OK *)
  "??ix" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ strstrip_cb swap
  cbs @ strstrip_cb
  strncmp
;
PUBLIC M-LIB-STRING-strncmp_cb
$LIBDEF M-LIB-STRING-strncmp_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strtof_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strtof_cb ( ? cbs -- f )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  strstrip_cb strtof
;
PUBLIC M-LIB-STRING-strtof_cb
$LIBDEF M-LIB-STRING-strtof_cb

(*****************************************************************************)
(*                           M-LIB-STRING-subst_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-subst_cb ( ? ? ? cbs -- ? )
  (* M1 OK *)
  "???x" checkargs
  over not if "Empty string argument (3)" abort then
  dup cbs_check
  subst_cb
;
PUBLIC M-LIB-STRING-subst_cb
$LIBDEF M-LIB-STRING-subst_cb

(*****************************************************************************)
(*                          M-LIB-STRING-toupper_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-toupper_cb ( ? cbs -- i )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  toupper_cb
;
PUBLIC M-LIB-STRING-toupper_cb
$LIBDEF M-LIB-STRING-toupper_cb

(*****************************************************************************)
(*                          M-LIB-STRING-tolower_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-tolower_cb ( ? cbs -- i )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  tolower_cb
;
PUBLIC M-LIB-STRING-tolower_cb
$LIBDEF M-LIB-STRING-tolower_cb

(*****************************************************************************)
(*                          M-LIB-STRING-wordwrap_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-wordwrap_cb[ any:source int:width_wrap dict:opts dict:cbs -- arr:lines ]
  (* M1 OK *)
  width_wrap @ int? not if "Non-integer argument (2)." abort then
  opts @ dictionary? not if "Non-dictionary argument (3)." abort then
  cbs @ dictionary? not if "Non-dictionary argument (4)." abort then
  cbs @ cbs_check
  source @ width_wrap @ opts @ cbs @ wordwrap_cb
;
PUBLIC M-LIB-STRING-wordwrap_cb
$LIBDEF M-LIB-STRING-wordwrap_cb

(*****************************************************************************)
(*                           M-LIB-STRING-wordwrap                           *)
(*****************************************************************************)
: M-LIB-STRING-wordwrap[ str:source int:width_wrap dict:opts -- arr:lines ]
  (* M1 OK *)
  source @ string? not if "Non-string argument (1)." abort then
  width_wrap @ int? not if "Non-integer argument (2)." abort then
  opts @ dictionary? not if "Non-dictionary argument (3)." abort then
  source @ width_wrap @ opts @ std_cb wordwrap_cb
;
PUBLIC M-LIB-STRING-wordwrap
$LIBDEF M-LIB-STRING-wordwrap

(*****************************************************************************)
(*                             M-LIB-STRING-xtoi                             *)
(*****************************************************************************)
: M-LIB-STRING-xtoi ( s -- i )
  (* M1 OK *)
  "s" checkargs
  xtoi
;
PUBLIC M-LIB-STRING-xtoi
$LIBDEF M-LIB-STRING-xtoi

(*****************************************************************************)
(*                           M-LIB-STRING-xtoi_cb                            *)
(*****************************************************************************)
: M-LIB-STRING-xtoi_cb ( ? cbs -- i )
  (* M1 OK *)
  "?x" checkargs
  dup cbs_check
  strstrip_cb
  xtoi
;
PUBLIC M-LIB-STRING-xtoi_cb
$LIBDEF M-LIB-STRING-xtoi_cb

(*****************************************************************************)
(*                           M-LIB-STRING-zeropad                            *)
(*****************************************************************************)
: M-LIB-STRING-zeropad ( s i -- i )
  (* M1 OK *)
  "si" checkargs
  over strlen - dup 0 > if "0" * swap strcat else pop then
;
PUBLIC M-LIB-STRING-zeropad
$LIBDEF M-LIB-STRING-zeropad

(*****************************************************************************)
(*                          M-LIB-STRING-zeropad_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-zeropad_cb ( ? i a -- i )
  (* M1 OK *)
  "?ix" checkargs
  dup cbs_check
  var! cbs
  over cbs @ strlen_cb - dup 0 > if "0" * swap cbs @ strcat_cb else pop then
;
PUBLIC M-LIB-STRING-zeropad_cb
$LIBDEF M-LIB-STRING-zeropad_cb

(*****************************************************************************)
(*                            M-LIB-STRING-}join                             *)
(*****************************************************************************)
$PUBDEF M-LIB-STRING-}join_cb "" M-LIB-STRING-array_join_cb

(*****************************************************************************)
(*                             M-LIB-STRING-}cat                             *)
(*****************************************************************************)
$PUBDEF M-LIB-STRING-}cat_cb M-LIB-STRING-array_interpret_cb

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

