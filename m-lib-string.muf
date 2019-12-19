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
(*     "tostring" ( ? -- s )                                                 *)
(*       This callback takes the custom string type variable, strips away    *)
(*       all metadata and turns it into a plain string. If the string has    *)
(*       special escapes that produce literals (Such as \~& for FB5 color    *)
(*       codes, for example) then those sequences should be resolved and the *)
(*       escaped version included in the string.                             *)
(*                                                                           *)
(*     "fromstring" ( s -- ? )                                               *)
(*       This callback takes a plain string and turns it into the custom     *)
(*       string type variable.                                               *)
(*                                                                           *)
(*     "strcut" ( ? i -- ? ? )                                               *)
(*       This callback works like the STRCUT primitive, cutting your custom  *)
(*       string type at the given character, splitting it into two custom    *)
(*       string types. Like tostring above, it should resolve any special    *)
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
(*     M-LIB-STRING-}cat_cb                                                  *)
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
(*     M-LIB-STRING-fromstring_cb                                            *)
(*     M-LIB-STRING-hex?_cb                                                  *)
(*     M-LIB-STRING-instr_cb                                                 *)
(*     M-LIB-STRING-instring_cb                                              *)
(*     M-LIB-STRING-midstr_cb                                                *)
(*     M-LIB-STRING-number?_cb                                               *)
(*     M-LIB-STRING-oxford_join_cb                                           *)
(*     M-LIB-STRING-regcarve_cb                                              *)
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
(*     M-LIB-STRING-tolower_cb                                               *)
(*     M-LIB-STRING-tostring_cb                                              *)
(*     M-LIB-STRING-toupper_cb                                               *)
(*     M-LIB-STRING-wordwrap_cb                                              *)
(*     M-LIB-STRING-xtoi_cb                                                  *)
(*     M-LIB-STRING-zeropad_cb                                               *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-STRING-carve_array ( s s -- Y )                                   *)
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
(*   M-LIB-STRING-oxford_join ( Y s -- s )                                   *)
(*     Similar to ", " array_join, but it inserts a coordinating conjunction *)
(*     and oxford comma as well, if applicable.                              *)
(*                                                                           *)
(*       { "a" } "nor" -> "a"                                                *)
(*       { "a" "b" } "and" -> "a and b"                                      *)
(*       { "a" "b" "c" } "or" -> "a, b, or c"                                *)
(*                                                                           *)
(*   M-LIB-STRING-regcarve ( s s i -- Y )                                    *)
(*     Like the REGSPLIT primitive, except separators are kept. They remain  *)
(*     at the beginning of their string. For example:                        *)
(*       "a b  c-- d" " |--" 0 M-LIB-STRING-regcarve                         *)
(*       Result: {"a", " b", " ", " c", "--", " d"}                          *)
(*                                                                           *)
(*     Each element starts with a separator except for the first. If the     *)
(*     source string starts with a separator then the first element will be  *)
(*     an empty string, so the number of elements will always be the number  *)
(*     of separators found, plus one.                                        *)
(*                                                                           *)
(*   M-LIB-STRING-regslice ( s s i -- Y )                                    *)
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
(*   M-LIB-STRING-slice_array ( s s -- Y )                                   *)
(*     Like the EXPLODE_ARRAY primitive, except the separators are kept. For *)
(*     example:                                                              *)
(*       "a b  c-- d" " " M-LIB-STRING-slice_array                           *)
(*       Result: {"a", " ", "b", " ", "", " ", "c--", " ", "d"}              *)
(*                                                                           *)
(*     The array will never begin or end with a separator, so it will always *)
(*     have an odd number of elements.                                       *)
(*                                                                           *)
(*   M-LIB-STRING-wordwrap[ s:source i:width_wrap x:opts --                  *)
(*                          y:lines ]                                        *)
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
$DOCCMD  @list __PROG__=2-229

(* ------------------------------------------------------------------------- *)

$PUBDEF :

: regexp_nozero[ s:text s:pattern i:flags -- Y:submatchvals Y:submatchidx ]
  text @ pattern @ flags @ regexp
  dup not if exit then
  dup 1 array_cut pop array_vals pop array_vals pop 0 = swap 1 = and if
    (* Matched at the beginning of the string, zero length, so fix it by removing the first character and trying again. *)
    pop pop
    text @ 1 strcut swap pop pattern @ flags @ regexp
    {
      swap foreach
        nip
        dup 0 [] ++ swap 0 ->[]
      repeat
    }list
  then
;

: regslice[ s:text s:pattern i:flags -- Y:results ]
  {
    text @ begin
      dup pattern @ flags @ regexp_nozero nip
      dup not if pop break then
      1 array_cut pop array_vals pop array_vals pop
      -rot -- strcut
      rot strcut
    repeat
  }list
;

: regcarve ( s s i - Y )
  regslice
  1 array_cut begin
    dup not if pop break then
    2 array_cut swap array_vals pop strcat rot []<- swap
  repeat
;

: carve_array ( s s -- Y )
  dup -rot explode_array
  1 array_cut foreach
    nip
    3 pick swap strcat swap []<-
  repeat
  nip
;

: slice_array ( s s -- Y )
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

: tostring_cb ( ? x -- s )
  2 try
    "tostring" [] execute
    depth 1 = not if "Unexpected number of results from 'tostring' callback." abort then
  catch
    abort
  endcatch
;

: fromstring_cb ( s x -- ? )
  2 try
    "fromstring" [] execute
    depth 1 = not if "Unexpected number of results from 'fromstring' callback." abort then
  catch
    abort
  endcatch
;

: strcut_cb ( ? i x -- ? ? )
  3 try
    "strcut" [] execute
    depth 2 = not if "Unexpected number of results from 'strcut' callback." abort then
  catch
    abort
  endcatch
;

: strcat_cb ( ? ? x -- ? )
  3 try
    "strcat" [] execute
    depth 1 = not if "Unexpected number of results from 'strcat' callback." abort then
  catch
    abort
  endcatch
;

: toupper_cb ( ? x -- ? )
  2 try
    "toupper" [] execute
    depth 1 = not if "Unexpected number of results from 'toupper' callback." abort then
  catch
    abort
  endcatch
;

: tolower_cb ( ? x -- ? )
  2 try
    "tolower" [] execute
    depth 1 = not if "Unexpected number of results from 'tolower' callback." abort then
  catch
    abort
  endcatch
;

: strlen_cb ( s x -- i )
  tostring_cb strlen
;

: instr_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  instr
;

: rinstr_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  rinstr
;

: instring_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  instring
;

: rinstring_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  rinstring
;

: einstr_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  einstr
;

: einstring_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  einstring
;

: erinstr_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  einstr
;

: erinstring_cb ( s s x -- i )
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  einstring
;

: striplead_cb ( s x -- s )
  var! cbs
  dup cbs @ strlen_cb over cbs @ tostring_cb striplead strlen -
  cbs @ strcut_cb swap pop
;

: striptail_cb ( s x -- s )
  var! cbs
  dup cbs @ tostring_cb striptail strlen
  cbs @ strcut_cb pop
;

: strip_cb ( s x -- s )
  var! cbs
  cbs @ striplead_cb cbs @ striptail_cb
;

: regslice_cb[ s:text s:pattern i:flags x:cbs -- y:results ]
  text @ cbs @ tostring_cb pattern @ flags @ regslice
  { text @ rot foreach nip strlen cbs @ strcut_cb repeat pop }list
;

: regcarve_cb[ s:text s:pattern i:flags x:cbs -- y:results ]
  text @ cbs @ tostring_cb pattern @ flags @ regcarve
  { text @ rot foreach nip strlen cbs @ strcut_cb repeat pop }list
;

: carve_array_cb[ s:source s:sep x:cbs -- y:result ]
  source @ cbs @ tostring_cb sep @ cbs @ tostring_cb carve_array
  { source @ rot foreach nip strlen cbs @ strcut_cb repeat pop }list
;

: slice_array_cb[ s:source s:sep x:cbs -- y:result ]
  source @ cbs @ tostring_cb sep @ cbs @ tostring_cb slice_array
  { source @ rot foreach nip strlen cbs @ strcut_cb repeat pop }list
;

: explode_array_cb[ s:source s:sep x:cbs -- y:result ]
  source @ cbs @ tostring_cb sep @ cbs @ tostring_cb explode_array
  sep @ strlen var! sep_len
  { source @ rot foreach nip strlen cbs @ strcut_cb sep_len @ cbs @ strcut_cb swap pop repeat pop }list
;

: subst_cb[ s:source s:to s:from y:cbs -- s:result ]
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

: array_join_cb ( y ? x -- ? )
  var! cbs
  swap 1 array_cut foreach nip 3 pick rot []<- []<- repeat swap pop
  "" swap foreach
    nip
    dup int? over dbref? or over float? or over lock? or if
      1 array_make "" array_join
    then
    cbs @ strcat_cb
  repeat
;

: array_interpret_cb ( y x -- ? )
  var! cbs
  "" swap foreach
    nip
    dup int? over dbref? or over float? or over lock? or if
      1 array_make array_interpret
    then
    cbs @ strcat_cb
  repeat
;

: wordwrap_cb[ ?:source i:width_wrap x:opts x:cbs -- y:lines ]
  { }list var! lines
  source @ "\r" explode_array var! source_lines
  source_lines @ foreach
    nip
    cbs @ striptail_cb " +" 0 cbs @ regcarve_cb
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
  repeat
  lines @
;

: oxford_join_cb ( Y ? x -- ? )
  var! cbs
  " " cbs @ tostring_cb var! space
  ", " cbs @ tostring_cb var! comma
  swap dup array_count 1 > if
    dup array_count 2 - array_cut
    array_vals pop
    4 rotate space @ cbs @ strcat_cb
    4 pick if
      comma @ swap cbs @ strcat_cb
    else
      space @ swap cbs @ strcat_cb
    then
    swap cbs @ strcat_cb cbs @ strcat_cb
    swap array_appenditem
  else
    swap pop
  then
  comma @ cbs @ array_join_cb
;

: std_cb_tostring ( s -- s ) ;
: std_cb_fromstring ( s -- s ) ;
: std_cb_strcut ( s i -- s1 s2 ) strcut ;
: std_cb_strcat ( s1 s2 -- s ) strcat ;
: std_cb_toupper ( s -- s ) toupper ;
: std_cb_tolower ( s -- s ) tolower ;
: std_cb ( -- a ) { "tostring" 'std_cb_tostring "fromstring" 'std_cb_fromstring "strcat" 'std_cb_strcat "strcut" 'std_cb_strcut "toupper" 'std_cb_toupper "tolower" 'std_cb_tolower }dict ;

(* Take the callback list in user supplied format and clean it up into the format expected by the internal code *)
: cbs_check[ x:cbs -- ]
  var cb
  { "tostring" "fromstring" "strcut" "strcat" "toupper" "tolower" }list foreach
    nip
    var! cb
    cbs @ cb @ [] address? not if { "String callback " cb @ " not found." }cat abort then
  repeat
;

(*****************************************************************************)
(*                      M-LIB-STRING-array_interpret_cb                      *)
(*****************************************************************************)
: M-LIB-STRING-array_interpret_cb ( y x -- ? )
  (* Permissions inherited *)
  "yx" checkargs
  dup cbs_check
  array_interpret_cb
;
PUBLIC M-LIB-STRING-array_interpret_cb
$LIBDEF M-LIB-STRING-array_interpret_cb

(*****************************************************************************)
(*                        M-LIB-STRING-array_join_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-array_join_cb ( y ? x -- ? )
  (* Permissions inherited *)
  "y?x" checkargs
  dup cbs_check
  array_join_cb
;
PUBLIC M-LIB-STRING-array_join_cb
$LIBDEF M-LIB-STRING-array_join_cb

(*****************************************************************************)
(*                           M-LIB-STRING-atoi_cb                            *)
(*****************************************************************************)
: M-LIB-STRING-atoi_cb ( ? x -- i )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  tostring_cb
  atoi
;
PUBLIC M-LIB-STRING-atoi_cb
$LIBDEF M-LIB-STRING-atoi_cb

(*****************************************************************************)
(*                         M-LIB-STRING-carve_array                          *)
(*****************************************************************************)
: M-LIB-STRING-carve_array ( s s -- Y )
  (* Permissions inherited *)
  "ss" checkargs
  carve_array
;
PUBLIC M-LIB-STRING-carve_array
$LIBDEF M-LIB-STRING-carve_array

(*****************************************************************************)
(*                        M-LIB-STRING-carve_array_cb                        *)
(*****************************************************************************)
: M-LIB-STRING-carve_array_cb ( ? ? x -- Y )
  (* Permissions inherited *)
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
  (* Permissions inherited *)
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
  (* Permissions inherited *)
  "ss" checkargs
  einstr
;
PUBLIC M-LIB-STRING-einstr
$LIBDEF M-LIB-STRING-einstr

(*****************************************************************************)
(*                          M-LIB-STRING-einstr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-einstr_cb ( ? ? x -- i )
  (* Permissions inherited *)
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
  (* Permissions inherited *)
  "ss" checkargs
  einstring
;
PUBLIC M-LIB-STRING-einstring
$LIBDEF M-LIB-STRING-einstring

(*****************************************************************************)
(*                         M-LIB-STRING-einstring_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-einstring_cb ( ? ? x -- i )
  (* Permissions inherited *)
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
  (* Permissions inherited *)
  "ss" checkargs
  erinstr
;
PUBLIC M-LIB-STRING-erinstr
$LIBDEF M-LIB-STRING-erinstr

(*****************************************************************************)
(*                          M-LIB-STRING-erinstr_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-erinstr_cb ( ? ? x -- i )
  (* Permissions inherited *)
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
  (* Permissions inherited *)
  "ss" checkargs
  erinstring
;
PUBLIC M-LIB-STRING-erinstring
$LIBDEF M-LIB-STRING-erinstring

(*****************************************************************************)
(*                        M-LIB-STRING-erinstring_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-erinstring_cb ( ? ? x -- i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  erinstring_cb
;
PUBLIC M-LIB-STRING-erinstring_cb
$LIBDEF M-LIB-STRING-erinstring_cb

(*****************************************************************************)
(*                          M-LIB-STRING-explode_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-explode_cb ( ? ? x -- ... i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  explode_array_cb array_vals
;
PUBLIC M-LIB-STRING-explode_cb
$LIBDEF M-LIB-STRING-explode_cb

(*****************************************************************************)
(*                       M-LIB-STRING-explode_array_cb                       *)
(*****************************************************************************)
: M-LIB-STRING-explode_array_cb ( ? ? x -- Y )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  explode_array_cb
;
PUBLIC M-LIB-STRING-explode_array_cb
$LIBDEF M-LIB-STRING-explode_array_cb

(*****************************************************************************)
(*                        M-LIB-STRING-fromstring_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-fromstring_cb ( s x -- ? )
  (* Permissions inherited *)
  "sx" checkargs
  dup cbs_check
  fromstring_cb
;
PUBLIC M-LIB-STRING-fromstring_cb
$LIBDEF M-LIB-STRING-fromstring_cb

(*****************************************************************************)
(*                             M-LIB-STRING-hex?                             *)
(*****************************************************************************)
: M-LIB-STRING-hex? ( s -- i )
  (* Permissions inherited *)
  "s" checkargs
  hex?
;
PUBLIC M-LIB-STRING-hex?
$LIBDEF M-LIB-STRING-hex?

(*****************************************************************************)
(*                           M-LIB-STRING-hex?_cb                            *)
(*****************************************************************************)
: M-LIB-STRING-hex?_cb ( ? x -- i )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  tostring_cb hex?
;
PUBLIC M-LIB-STRING-hex?_cb
$LIBDEF M-LIB-STRING-hex?_cb

(*****************************************************************************)
(*                           M-LIB-STRING-instr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-instr_cb ( ? ? x -- i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  instr_cb
;
PUBLIC M-LIB-STRING-instr_cb
$LIBDEF M-LIB-STRING-instr_cb

(*****************************************************************************)
(*                         M-LIB-STRING-instring_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-instring_cb ( ? ? x -- i )
  (* Permissions inherited *)
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
  (* Permissions inherited *)
  "i" checkargs
  itox
;
PUBLIC M-LIB-STRING-itox
$LIBDEF M-LIB-STRING-itox

(*****************************************************************************)
(*                          M-LIB-STRING-midstr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-midstr_cb ( ? i i x -- ? )
  (* Permissions inherited *)
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
: M-LIB-STRING-number?_cb ( ? x -- i )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  tostring_cb number?
;
PUBLIC M-LIB-STRING-number?_cb
$LIBDEF M-LIB-STRING-number?_cb

(*****************************************************************************)
(*                         M-LIB-STRING-oxford_join                          *)
(*****************************************************************************)
: M-LIB-STRING-oxford_join ( Y s -- s )
  (* Permissions inherited *)
  "Ys" checkargs
  std_cb oxford_join_cb
;
PUBLIC M-LIB-STRING-oxford_join
$LIBDEF M-LIB-STRING-oxford_join

(*****************************************************************************)
(*                        M-LIB-STRING-oxford_join_cb                        *)
(*****************************************************************************)
: M-LIB-STRING-oxford_join_cb ( Y s x -- s )
  (* Permissions inherited *)
  "Ysx" checkargs
  dup cbs_check
  oxford_join_cb
;
PUBLIC M-LIB-STRING-oxford_join_cb
$LIBDEF M-LIB-STRING-oxford_join_cb

(*****************************************************************************)
(*                           M-LIB-STRING-regslice                           *)
(*****************************************************************************)
: M-LIB-STRING-regslice ( s s i -- Y )
  (* Permissions inherited *)
  "ssi" checkargs
  regslice
;
PUBLIC M-LIB-STRING-regslice
$LIBDEF M-LIB-STRING-regslice

(*****************************************************************************)
(*                         M-LIB-STRING-regslice_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-regslice_cb ( ? ? i x -- Y )
  (* Permissions inherited *)
  "??ix" checkargs
  dup cbs_check
  regslice_cb
;
PUBLIC M-LIB-STRING-regslice_cb
$LIBDEF M-LIB-STRING-regslice_cb

(*****************************************************************************)
(*                           M-LIB-STRING-regcarve                           *)
(*****************************************************************************)
: M-LIB-STRING-regcarve ( s s i -- Y )
  (* Permissions inherited *)
  "ssi" checkargs
  regcarve
;
PUBLIC M-LIB-STRING-regcarve
$LIBDEF M-LIB-STRING-regcarve

(*****************************************************************************)
(*                         M-LIB-STRING-regcarve_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-regcarve_cb ( ? ? i x -- Y )
  (* Permissions inherited *)
  "??ix" checkargs
  dup cbs_check
  regcarve_cb
;
PUBLIC M-LIB-STRING-regcarve_cb
$LIBDEF M-LIB-STRING-regcarve_cb

(*****************************************************************************)
(*                          M-LIB-STRING-rinstr_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-rinstr_cb ( ? ? x -- i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  rinstr_cb
;
PUBLIC M-LIB-STRING-rinstr_cb
$LIBDEF M-LIB-STRING-rinstr_cb

(*****************************************************************************)
(*                         M-LIB-STRING-rinstring_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-rinstring_cb ( ? ? x -- i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  rinstring_cb
;
PUBLIC M-LIB-STRING-rinstring_cb
$LIBDEF M-LIB-STRING-rinstring_cb

(*****************************************************************************)
(*                          M-LIB-STRING-rsplit_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-rsplit_cb[ ?:source ?:sep x:cbs -- ?:result1 ?:result2 ]
  (* Permissions inherited *)
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
  (* Permissions inherited *)
  "s" checkargs
  single_space
;
PUBLIC M-LIB-STRING-single_space
$LIBDEF M-LIB-STRING-single_space

(*****************************************************************************)
(*                       M-LIB-STRING-single_space_cb                        *)
(*****************************************************************************)
: M-LIB-STRING-single_space_cb ( ? x -- ? )
  (* Permissions inherited *)
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
  (* Permissions inherited *)
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
: M-LIB-STRING-slice_array ( s s -- Y )
  (* Permissions inherited *)
  "ss" checkargs
  slice_array
;
PUBLIC M-LIB-STRING-slice_array
$LIBDEF M-LIB-STRING-slice_array

(*****************************************************************************)
(*                        M-LIB-STRING-slice_array_cb                        *)
(*****************************************************************************)
: M-LIB-STRING-slice_array_cb ( ? ? x -- Y )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  slice_array_cb
;
PUBLIC M-LIB-STRING-slice_array_cb
$LIBDEF M-LIB-STRING-slice_array_cb

(*****************************************************************************)
(*                           M-LIB-STRING-split_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-split_cb[ ?:source ?:sep x:cbs -- ?:result1 ?:result2 ]
  (* Permissions inherited *)
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
: M-LIB-STRING-strcat_cb ( ? ? x -- ? )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  strcat_cb
;
PUBLIC M-LIB-STRING-strcat_cb
$LIBDEF M-LIB-STRING-strcat_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strcmp_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strcmp_cb ( ? ? x -- i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  strcmp
;
PUBLIC M-LIB-STRING-strcmp_cb
$LIBDEF M-LIB-STRING-strcmp_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strcut_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strcut_cb ( ? i x -- ? ? )
  (* Permissions inherited *)
  "?ix" checkargs
  dup cbs_check
  strcut_cb
;
PUBLIC M-LIB-STRING-strcut_cb
$LIBDEF M-LIB-STRING-strcut_cb

(*****************************************************************************)
(*                         M-LIB-STRING-stringcmp_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-stringcmp_cb ( ? ? x -- i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  stringcmp
;
PUBLIC M-LIB-STRING-stringcmp_cb
$LIBDEF M-LIB-STRING-stringcmp_cb

(*****************************************************************************)
(*                         M-LIB-STRING-stringpfx_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-stringpfx_cb ( ? ? x -- i )
  (* Permissions inherited *)
  "??x" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  stringpfx
;
PUBLIC M-LIB-STRING-stringpfx_cb
$LIBDEF M-LIB-STRING-stringpfx_cb

(*****************************************************************************)
(*                           M-LIB-STRING-strip_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strip_cb ( ? x -- ? )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  strip_cb
;
PUBLIC M-LIB-STRING-strip_cb
$LIBDEF M-LIB-STRING-strip_cb

(*****************************************************************************)
(*                         M-LIB-STRING-striplead_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-striplead_cb ( ? x -- ? )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  striplead_cb
;
PUBLIC M-LIB-STRING-striplead_cb
$LIBDEF M-LIB-STRING-striplead_cb

(*****************************************************************************)
(*                         M-LIB-STRING-striptail_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-striptail_cb ( ? x -- ? )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  striptail_cb
;
PUBLIC M-LIB-STRING-striptail_cb
$LIBDEF M-LIB-STRING-striptail_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strlen_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strlen_cb ( ? x -- i )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  strlen_cb
;
PUBLIC M-LIB-STRING-strlen_cb
$LIBDEF M-LIB-STRING-strlen_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strncmp_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-strncmp_cb ( ? ? i x -- i )
  (* Permissions inherited *)
  "??ix" checkargs
  dup cbs_check
  var! cbs
  swap cbs @ tostring_cb swap
  cbs @ tostring_cb
  strncmp
;
PUBLIC M-LIB-STRING-strncmp_cb
$LIBDEF M-LIB-STRING-strncmp_cb

(*****************************************************************************)
(*                          M-LIB-STRING-strtof_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-strtof_cb ( ? x -- f )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  tostring_cb strtof
;
PUBLIC M-LIB-STRING-strtof_cb
$LIBDEF M-LIB-STRING-strtof_cb

(*****************************************************************************)
(*                           M-LIB-STRING-subst_cb                           *)
(*****************************************************************************)
: M-LIB-STRING-subst_cb ( ? ? ? x -- ? )
  (* Permissions inherited *)
  "???x" checkargs
  over not if "Empty string argument (3)" abort then
  dup cbs_check
  subst_cb
;
PUBLIC M-LIB-STRING-subst_cb
$LIBDEF M-LIB-STRING-subst_cb

(*****************************************************************************)
(*                          M-LIB-STRING-tolower_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-tolower_cb ( ? x -- i )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  tolower_cb
;
PUBLIC M-LIB-STRING-tolower_cb
$LIBDEF M-LIB-STRING-tolower_cb

(*****************************************************************************)
(*                         M-LIB-STRING-tostring_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-tostring_cb ( ? x -- s )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  tostring_cb
;
PUBLIC M-LIB-STRING-tostring_cb
$LIBDEF M-LIB-STRING-tostring_cb

(*****************************************************************************)
(*                          M-LIB-STRING-toupper_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-toupper_cb ( ? x -- i )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  toupper_cb
;
PUBLIC M-LIB-STRING-toupper_cb
$LIBDEF M-LIB-STRING-toupper_cb

(*****************************************************************************)
(*                          M-LIB-STRING-wordwrap_cb                         *)
(*****************************************************************************)
: M-LIB-STRING-wordwrap_cb[ ?:source i:width_wrap x:opts x:cbs -- Y:lines ]
  (* Permissions inherited *)
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
: M-LIB-STRING-wordwrap[ s:source i:width_wrap x:opts -- Y:lines ]
  (* Permissions inherited *)
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
  (* Permissions inherited *)
  "s" checkargs
  xtoi
;
PUBLIC M-LIB-STRING-xtoi
$LIBDEF M-LIB-STRING-xtoi

(*****************************************************************************)
(*                           M-LIB-STRING-xtoi_cb                            *)
(*****************************************************************************)
: M-LIB-STRING-xtoi_cb ( ? x -- i )
  (* Permissions inherited *)
  "?x" checkargs
  dup cbs_check
  tostring_cb
  xtoi
;
PUBLIC M-LIB-STRING-xtoi_cb
$LIBDEF M-LIB-STRING-xtoi_cb

(*****************************************************************************)
(*                           M-LIB-STRING-zeropad                            *)
(*****************************************************************************)
: M-LIB-STRING-zeropad ( s i -- i )
  (* Permissions inherited *)
  "si" checkargs
  over strlen - dup 0 > if "0" * swap strcat else pop then
;
PUBLIC M-LIB-STRING-zeropad
$LIBDEF M-LIB-STRING-zeropad

(*****************************************************************************)
(*                          M-LIB-STRING-zeropad_cb                          *)
(*****************************************************************************)
: M-LIB-STRING-zeropad_cb ( ? i x -- i )
  (* Permissions inherited *)
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
$PUBDEF M-LIB-STRING-}join_cb } swap over 0 swap - -- rotate -- array_make "" rot M-LIB-STRING-array_join_cb

(*****************************************************************************)
(*                             M-LIB-STRING-}cat                             *)
(*****************************************************************************)
$PUBDEF M-LIB-STRING-}cat_cb } swap over 0 swap - -- rotate -- array_make swap M-LIB-STRING-array_interpret_cb

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
!@set $m/lib/string=H
!@set $m/lib/string=S
!@set $m/lib/string=L

