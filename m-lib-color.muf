!@program m-lib-color.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-color - $m/lib/color                                                *)
(*   A text color library that converts HTML style color codes into color    *)
(*   text output depending on your terminal type.                            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-COLOR-Transcode[ str:from_type str:to_type str:source_string      *)
(*                          -- str:result_string ]                           *)
(*     Converts from one encoding type to another. At present, you can only  *)
(*     convert from MCC to ANSI or NOCOLOR. If a color can't be precicely    *)
(*     produced for a given type, it will be approximated by trying to pick  *)
(*     the closest available color. See ENCODING TYPES for more details.     *)
(*                                                                           *)
(* ENCODING TYPES:                                                           *)
(*   MCC                                                                     *)
(*     Any sequence matching the patern #MCC-L-HHHHHH, where L is a capital  *)
(*     letter and HHHHHH are six capitalized hexadecimal digits and replaced *)
(*     with a control sequence when converted to a displayable encoding, or  *)
(*     an error message if the code is invalid.                              *)
(*       #MCC-F-HHHHHH - Foreground color in RGB format (Like HTML codes)    *)
(*       #MCC-B-HHHHHH - Background color in RGB format (Like HTML codes)    *)
(*       #MCC-X-000000 - 'Reset' colors back to default                      *)
(*       #MCC-X-000000 - #MCC-X-FFFFFF This becomes a literal '#' character  *)
(*                                                                           *)
(*   NOCOLOR                                                                 *)
(*     This encoding has no color information.                               *)
(*                                                                           *)
(*     Convert a string from another encoding into NOCOLOR to 'strip' out    *)
(*     all color codes (Except 'escape' codes that produce string literals,  *)
(*     and error messages. Those still convert an usual.)                    *)
(*                                                                           *)
(*     Convert a string from NOCOLOR into another encoding to 'escape' all   *)
(*     special charcters in a string for that type of encoding.              *)
(*                                                                           *)
(*   ANSI-3BIT-VGA                                                           *)
(*   ANSI-3BIT-XTERM                                                         *)
(*   ANSI-4BIT-VGA                                                           *)
(*   ANSI-4BIT-XTERM                                                         *)
(*     This is the oldest and most compatible ANSI encoding standard, with a *)
(*     16 color palette.                                                     *)
(*                                                                           *)
(*     The ANSI standard does not specify palette information, only color    *)
(*     names, and on most clients you are free to set whatever palette you   *)
(*     want for these colors, so for the purposes of converting colors to    *)
(*     their nearest match, a palette template must be provided that matches *)
(*     whichever client the player is using, or else color matching will be  *)
(*     inaccurate.                                                           *)
(*                                                                           *)
(*     The XTERM palette is perhaps the most popular with MUD clients, with  *)
(*     more vibrant colors.                                                  *)
(*                                                                           *)
(*     The VGA palette represents the standard colors popularized on early   *)
(*     IBM computers and are the most iconic ANSI colors, and is still       *)
(*     considered the standard by ANSI artists. This palette is also used by *)
(*     the raw Linux console and may be referred to as 'Linux Colors' in     *)
(*     terminals and MUD clients.                                            *)
(*                                                                           *)
(*     Other palettes are not supported at this time. Users with other       *)
(*     clients should alter their settings to use one of the above palettes. *)
(*     (See TECHNICAL NOTES for RGB color information for these palettes)    *)
(*                                                                           *)
(*     4BIT is the standard for this mode, where the ANSI signal for 'bold'  *)
(*     is interpreted as selecting brighter colors from the color palette.   *)
(*     However, some clients vary from this interpretation and will actually *)
(*     make the font bolder, sometimes without modifying the color at all.   *)
(*     Some clients will do both, and some will perplexingly do both with    *)
(*     the exception of 'bright black' which still shows black.              *)
(*                                                                           *)
(*     For these clients 3BIT may be preferable. With 3BIT, you are limited  *)
(*     to 8 colors. Color matching happens as usual, but the 'bright'        *)
(*     boldness information is stripped out. These clients are not           *)
(*     recommended and using no colors at all may be preferable.             *)
(*                                                                           *)
(*     Due to the way the codes work, background colors are always 3BIT,     *)
(*     whether you specify a 4BIT encoding or not. This may change in the    *)
(*     future, because there is an 'inverted color' option that can work     *)
(*     around this limitation, albeit in inconsistent and probably ugly      *)
(*     ways.                                                                 *)
(*                                                                           *)
(*   ANSI-8BIT                                                               *)
(*     This is ANSI 256 color mode, and is largely well supported by MUD     *)
(*     clients. The first 16 color codes of the ANSI 256 color standard use  *)
(*     the same user-defined unspecified palette as the 16 color codes, so   *)
(*     for maximum color accuracy, these color codes are never produced.     *)
(*                                                                           *)
(*   ANSI-24BIT                                                              *)
(*     This is True-Color ANSI mode, and represents the full gamut of colors *)
(*     available on modern displays. Sadly, this encoding is not well        *)
(*     supported by MUD clients, but it is the ultimate color accuracy       *)
(*     option and is recommended if available.                               *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   Some tweaks were made to the code that finds the closest color match so *)
(*   that if you try to match the VGA RGB values (such as VGA brown #FF5500) *)
(*   into the XTERM pallate, or vice versa, it will always generate the same *)
(*   ANSI codes.                                                             *)
(*                                                                           *)
(*   That way it's up to you whether you prefer the XTERM or the VGA color   *)
(*   palette when you're creating your MCC strings. Just use the color codes *)
(*   you want from the list below, and older clients of both types of client *)
(*   should still see the full gamut of 16 colors.                           *)
(*                                                                           *)
(*   XTERM Palette:                                                          *)
(*   0  Black          #MCC-F-000000                                         *)
(*   1  Red            #MCC-F-800000                                         *)
(*   2  Green          #MCC-F-008000                                         *)
(*   3  Yellow         #MCC-F-808000                                         *)
(*   4  Blue           #MCC-F-000080                                         *)
(*   5  Magenta        #MCC-F-800080                                         *)
(*   6  Cyan           #MCC-F-008080                                         *)
(*   7  White          #MCC-F-C0C0C0                                         *)
(*   8  Bright Black   #MCC-F-808080                                         *)
(*   9  Bright Red     #MCC-F-FF0000                                         *)
(*   10 Bright Green   #MCC-F-00FF00                                         *)
(*   11 Bright Yellow  #MCC-F-FFFF00                                         *)
(*   12 Bright Blue    #MCC-F-0000FF                                         *)
(*   13 Bright Magenta #MCC-F-FF00FF                                         *)
(*   14 Bright Cyan    #MCC-F-00FFFF                                         *)
(*   15 Bright White   #MCC-F-FFFFFF                                         *)
(*                                                                           *)
(*   VGA Palette:                                                            *)
(*   0  Black          #MCC-F-000000                                         *)
(*   1  Red            #MCC-F-AA0000                                         *)
(*   2  Green          #MCC-F-00AA00                                         *)
(*   3  Yellow (Brown) #MCC-F-AA5500                                         *)
(*   4  Blue           #MCC-F-0000AA                                         *)
(*   5  Magenta        #MCC-F-AA00AA                                         *)
(*   6  Cyan           #MCC-F-00AAAA                                         *)
(*   7  White          #MCC-F-AAAAAA                                         *)
(*   8  Bright Black   #MCC-F-555555                                         *)
(*   9  Bright Red     #MCC-F-FF5555                                         *)
(*   10 Bright Green   #MCC-F-55FF55                                         *)
(*   11 Bright Yellow  #MCC-F-FFFF55                                         *)
(*   12 Bright Blue    #MCC-F-5555FF                                         *)
(*   13 Bright Magenta #MCC-F-FF55FF                                         *)
(*   14 Bright Cyan    #MCC-F-55FFFF                                         *)
(*   15 Bright White   #MCC-F-FFFFFF                                         *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- October, 2019                            *)
(*      - Original implementation.                                           *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2019                                                        *)
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
$VERSION 1.0
$AUTHOR  Daniel Benoy
$NOTE    Text color library.
$DOCCMD  @list __PROG__=2-164

(* Begin configurable options *)
 
(* End configurable options *)

(* TODO: A check to see if colors can be exactly represented on a given ANSI type? *)
(* TODO: Produce test string output for users to look at to see if they support a given ANSI type *)
(* TODO: More 'color code' encodings for compatibility with other MUCK software *)

$PUBDEF :

$DEF .version prog "_version" getpropstr begin dup strlen 1 - over ".0" rinstr = not while dup ".0" instr while "." ".0" subst repeat

: list_max ( a -- f )
  dup 0 array_getitem
  swap foreach
    nip
    over over > if
      pop
    else
      nip
    then
  repeat
;

: list_min ( a -- f )
  dup 0 array_getitem
  swap foreach
    nip
    over over < if
      pop
    else
      nip
    then
  repeat
;

: rgb2hsl ( a -- a )
  array_vals
  pop
  255.0 / var! b
  255.0 / var! g
  255.0 / var! r
  { r @ g @ b @ }list list_max var! max
  { r @ g @ b @ }list list_min var! min
  max @ min @ + 2.0 / var! l
  var h
  var s
  max @ min @ = if (* Achromatic *)
    0.0 h !
    0.0 s !
  else
    max @ min @ - var! d
    l @ 0.5 > if
      d @ 2.0 max @ - min @ - /
    else
      d @ max @ min @ + /
    then
    s !
    max @ case
      r @ = when
        g @ b @ - d @ / g @ b @ < if 6.0 else 0.0 then + h !
      end
      g @ = when
        b @ r @ - d @ / 2.0 + h !
      end
      b @ = when
        r @ g @ - d @ / 4.0 + h !
      end
    endcase
    h @ 6.0 / h !
  then

  { h @ s @ l @ }list
;

: rgb2hcl ( a -- a )
  dup array_vals
  pop
  255.0 / var! b
  255.0 / var! g
  255.0 / var! r
  rgb2hsl array_vals
  pop
  var! l
  var! s
  var! h
  { r @ g @ b @ }list list_max var! max
  { r @ g @ b @ }list list_min var! min
  max @ min @ - var! c
  { h @ c @ l @ }list  
;

: rgb2bicone ( a -- a )
  (* https://stackoverflow.com/questions/4057475/rounding-colour-values-to-the-nearest-of-a-small-set-of-colours *)
  rgb2hcl
  array_vals
  pop
  var! l
  var! c
  var! h
  h @ 2.0 * h !
  l @ 0.5 - 2.0 * l !
  h @ pi * cos c @ * var! x
  h @ pi * sin c @ * var! y
  l @ var! z
  { x @ y @ z @ }list
;

: distance3[ arr:first arr:second -- float:distance ]
  first @
  array_vals
  pop
  var! z1
  var! y1
  var! x1
  second @
  array_vals
  pop
  var! z2
  var! y2
  var! x2

  x1 @ x2 @ - dup *
  y1 @ y2 @ - dup *
  z1 @ z2 @ - dup *
  + +
  sqrt
;

: closest_color[ list:target_rgb dict:color_table -- int:closest_key ]
  target_rgb @ rgb2bicone var! target_bicone
  inf var! closest_dist
  var closest_key
  color_table @ foreach
    rgb2bicone target_bicone @ distance3 var! current_dist
    var! current_key
    current_dist @ closest_dist @ < if
      current_key @ closest_key !
      current_dist @ closest_dist !
    then
  repeat   
  closest_key @
;

lvar ansi_table_8bit_rgb
: ansi8_nearest[ str:ansi_type list:target_rgb -- int:color8 ]
  ansi_table_8bit_rgb @ not if
    {
      16 { 0 0 0 }list
      17 { 0 0 95 }list
      18 { 0 0 135 }list
      19 { 0 0 175 }list
      20 { 0 0 215 }list
      21 { 0 0 255 }list
      22 { 0 95 0 }list
      23 { 0 95 95 }list
      24 { 0 95 135 }list
      25 { 0 95 175 }list
      26 { 0 95 215 }list
      27 { 0 95 255 }list
      28 { 0 135 0 }list
      29 { 0 135 95 }list
      30 { 0 135 135 }list
      31 { 0 135 175 }list
      32 { 0 135 215 }list
      33 { 0 135 255 }list
      34 { 0 175 0 }list
      35 { 0 175 95 }list
      36 { 0 175 135 }list
      37 { 0 175 175 }list
      38 { 0 175 215 }list
      39 { 0 175 255 }list
      40 { 0 215 0 }list
      41 { 0 215 95 }list
      42 { 0 215 135 }list
      43 { 0 215 175 }list
      44 { 0 215 215 }list
      45 { 0 215 255 }list
      46 { 0 255 0 }list
      47 { 0 255 95 }list
      48 { 0 255 135 }list
      49 { 0 255 175 }list
      50 { 0 255 215 }list
      51 { 0 255 255 }list
      52 { 95 0 0 }list
      53 { 95 0 95 }list
      54 { 95 0 135 }list
      55 { 95 0 175 }list
      56 { 95 0 215 }list
      57 { 95 0 255 }list
      58 { 95 95 0 }list
      59 { 95 95 95 }list
      60 { 95 95 135 }list
      61 { 95 95 175 }list
      62 { 95 95 215 }list
      63 { 95 95 255 }list
      64 { 95 135 0 }list
      65 { 95 135 95 }list
      66 { 95 135 135 }list
      67 { 95 135 175 }list
      68 { 95 135 215 }list
      69 { 95 135 255 }list
      70 { 95 175 0 }list
      71 { 95 175 95 }list
      72 { 95 175 135 }list
      73 { 95 175 175 }list
      74 { 95 175 215 }list
      75 { 95 175 255 }list
      76 { 95 215 0 }list
      77 { 95 215 95 }list
      78 { 95 215 135 }list
      79 { 95 215 175 }list
      80 { 95 215 215 }list
      81 { 95 215 255 }list
      82 { 95 255 0 }list
      83 { 95 255 95 }list
      84 { 95 255 135 }list
      85 { 95 255 175 }list
      86 { 95 255 215 }list
      87 { 95 255 255 }list
      88 { 135 0 0 }list
      89 { 135 0 95 }list
      90 { 135 0 135 }list
      91 { 135 0 175 }list
      92 { 135 0 215 }list
      93 { 135 0 255 }list
      94 { 135 95 0 }list
      95 { 135 95 95 }list
      96 { 135 95 135 }list
      97 { 135 95 175 }list
      98 { 135 95 215 }list
      99 { 135 95 255 }list
      100 { 135 135 0 }list
      101 { 135 135 95 }list
      102 { 135 135 135 }list
      103 { 135 135 175 }list
      104 { 135 135 215 }list
      105 { 135 135 255 }list
      106 { 135 175 0 }list
      107 { 135 175 95 }list
      108 { 135 175 135 }list
      109 { 135 175 175 }list
      110 { 135 175 215 }list
      111 { 135 175 255 }list
      112 { 135 215 0 }list
      113 { 135 215 95 }list
      114 { 135 215 135 }list
      115 { 135 215 175 }list
      116 { 135 215 215 }list
      117 { 135 215 255 }list
      118 { 135 255 0 }list
      119 { 135 255 95 }list
      120 { 135 255 135 }list
      121 { 135 255 175 }list
      122 { 135 255 215 }list
      123 { 135 255 255 }list
      124 { 175 0 0 }list
      125 { 175 0 95 }list
      126 { 175 0 135 }list
      127 { 175 0 175 }list
      128 { 175 0 215 }list
      129 { 175 0 255 }list
      130 { 175 95 0 }list
      131 { 175 95 95 }list
      132 { 175 95 135 }list
      133 { 175 95 175 }list
      134 { 175 95 215 }list
      135 { 175 95 255 }list
      136 { 175 135 0 }list
      137 { 175 135 95 }list
      138 { 175 135 135 }list
      139 { 175 135 175 }list
      140 { 175 135 215 }list
      141 { 175 135 255 }list
      142 { 175 175 0 }list
      143 { 175 175 95 }list
      144 { 175 175 135 }list
      145 { 175 175 175 }list
      146 { 175 175 215 }list
      147 { 175 175 255 }list
      148 { 175 215 0 }list
      149 { 175 215 95 }list
      150 { 175 215 135 }list
      151 { 175 215 175 }list
      152 { 175 215 215 }list
      153 { 175 215 255 }list
      154 { 175 255 0 }list
      155 { 175 255 95 }list
      156 { 175 255 135 }list
      157 { 175 255 175 }list
      158 { 175 255 215 }list
      159 { 175 255 255 }list
      160 { 215 0 0 }list
      161 { 215 0 95 }list
      162 { 215 0 135 }list
      163 { 215 0 175 }list
      164 { 215 0 215 }list
      165 { 215 0 255 }list
      166 { 215 95 0 }list
      167 { 215 95 95 }list
      168 { 215 95 135 }list
      169 { 215 95 175 }list
      170 { 215 95 215 }list
      171 { 215 95 255 }list
      172 { 215 135 0 }list
      173 { 215 135 95 }list
      174 { 215 135 135 }list
      175 { 215 135 175 }list
      176 { 215 135 215 }list
      177 { 215 135 255 }list
      178 { 215 175 0 }list
      179 { 215 175 95 }list
      180 { 215 175 135 }list
      181 { 215 175 175 }list
      182 { 215 175 215 }list
      183 { 215 175 255 }list
      184 { 215 215 0 }list
      185 { 215 215 95 }list
      186 { 215 215 135 }list
      187 { 215 215 175 }list
      188 { 215 215 215 }list
      189 { 215 215 255 }list
      190 { 215 255 0 }list
      191 { 215 255 95 }list
      192 { 215 255 135 }list
      193 { 215 255 175 }list
      194 { 215 255 215 }list
      195 { 215 255 255 }list
      196 { 255 0 0 }list
      197 { 255 0 95 }list
      198 { 255 0 135 }list
      199 { 255 0 175 }list
      200 { 255 0 215 }list
      201 { 255 0 255 }list
      202 { 255 95 0 }list
      203 { 255 95 95 }list
      204 { 255 95 135 }list
      205 { 255 95 175 }list
      206 { 255 95 215 }list
      207 { 255 95 255 }list
      208 { 255 135 0 }list
      209 { 255 135 95 }list
      210 { 255 135 135 }list
      211 { 255 135 175 }list
      212 { 255 135 215 }list
      213 { 255 135 255 }list
      214 { 255 175 0 }list
      215 { 255 175 95 }list
      216 { 255 175 135 }list
      217 { 255 175 175 }list
      218 { 255 175 215 }list
      219 { 255 175 255 }list
      220 { 255 215 0 }list
      221 { 255 215 95 }list
      222 { 255 215 135 }list
      223 { 255 215 175 }list
      224 { 255 215 215 }list
      225 { 255 215 255 }list
      226 { 255 255 0 }list
      227 { 255 255 95 }list
      228 { 255 255 135 }list
      229 { 255 255 175 }list
      230 { 255 255 215 }list
      231 { 255 255 255 }list
      232 { 8 8 8 }list
      233 { 18 18 18 }list
      234 { 28 28 28 }list
      235 { 38 38 38 }list
      236 { 48 48 48 }list
      237 { 58 58 58 }list
      238 { 68 68 68 }list
      239 { 78 78 78 }list
      240 { 88 88 88 }list
      241 { 98 98 98 }list
      242 { 108 108 108 }list
      243 { 118 118 118 }list
      244 { 128 128 128 }list
      245 { 138 138 138 }list
      246 { 148 148 148 }list
      247 { 158 158 158 }list
      248 { 168 168 168 }list
      249 { 178 178 178 }list
      250 { 188 188 188 }list
      251 { 198 198 198 }list
      252 { 208 208 208 }list
      253 { 218 218 218 }list
      254 { 228 228 228 }list
      255 { 238 238 238 }list
    }dict ansi_table_8bit_rgb !
  then
  target_rgb @ ansi_table_8bit_rgb @ closest_color
;

lvar ansi_table_4bit_vga_rgb
: ansi4_nearest_vga[ str:ansi_type list:target_rgb -- int:color4 ]
  ansi_table_4bit_vga_rgb @ not if
    {
      30 { 0 0 0 }list
      31 { 170 0 0 }list
      32 { 0 170 0 }list
      33 { 170 85 0 }list
      34 { 0 0 170 }list
      35 { 170 0 170 }list
      36 { 0 170 170 }list
      37 { 170 170 170 }list
      90 { 85 85 85 }list
      91 { 255 85 85 }list
      92 { 85 255 85 }list
      93 { 255 255 85 }list
      94 { 85 85 255 }list
      95 { 255 85 255 }list
      96 { 85 255 255 }list
      97 { 255 255 255 }list
    }dict ansi_table_4bit_vga_rgb !
  then
  target_rgb @ { 128 128 128 }list array_compare 0 = if { 127 127 127 }list target_rgb ! then (* So that XTerm 'dark gray' will be recognized VGA 'dark gray' and not VGA 'gray' *)
  target_rgb @ ansi_table_4bit_vga_rgb @ closest_color
;

lvar ansi_table_4bit_xterm_rgb
: ansi4_nearest_xterm[ str:ansi_type list:target_rgb -- int:color4 ]
  ansi_table_4bit_xterm_rgb @ not if
    {
      30 { 0 0 0 }list
      31 { 128 0 0 }list
      32 { 0 128 0 }list
      33 { 128 127 0 }list (* 127 so that VGA 'brown' will be recognized as yellow and not red *)
      34 { 0 0 128 }list
      35 { 128 0 128 }list
      36 { 0 128 128 }list
      37 { 192 192 192 }list
      90 { 128 128 128 }list
      91 { 255 0 0 }list
      92 { 0 255 0 }list
      93 { 255 255 0 }list
      94 { 0 0 255 }list
      95 { 255 0 255 }list
      96 { 0 255 255 }list
      97 { 255 255 255 }list
    }dict ansi_table_4bit_xterm_rgb !
  then
  target_rgb @ ansi_table_4bit_xterm_rgb @ closest_color
;

lvar ansi_table_3bit_vga_rgb
: ansi3_nearest_vga[ str:ansi_type list:target_rgb -- int:color4 ]
  ansi_type @ target_rgb @ ansi4_nearest_xterm
  dup 90 = if pop 37 then
  dup 91 >= if 60 - then
;

lvar ansi_table_3bit_xterm_rgb
: ansi3_nearest_xterm[ str:ansi_type list:target_rgb -- int:color4 ]
  ansi_type @ target_rgb @ ansi4_nearest_xterm
  dup 90 = if pop 37 then
  dup 91 >= if 60 - then
;

: xtoi1 ( s -- i )
  dup string? not if
    pop -1 exit
  then

  dup strlen 1 = not if
    pop -1 exit
  then

  dup number? if
    atoi exit
  then

  ctoi "A" ctoi - 10 +

  dup 10 < over 15 > or if
    pop -1 exit
  then
;

: hex? ( s -- b )
  dup string? not if
    pop 0 exit
  then

  dup strlen dup 1 >= swap 7 <= and not if
    pop 0 exit
  then

  begin
    dup while
    1 strcut swap
    dup number? not over ctoi "A" ctoi < and swap ctoi "F" ctoi > or if
      pop 0 exit
    then
  repeat

  pop 1 exit
;

: xtoi ( s -- i )
  dup hex? not if
    pop -1 exit
  then

  0 var! retval
  1 var! expfact

  begin
    dup while
    dup strlen 1 - strcut
    xtoi1
    dup 0 >= over 16 < and not if
      pop pop -1 exit
    then
    retval @ swap expfact @ * + retval !
    expfact @ 16 * expfact !
  repeat
  pop

  retval @
;

: mcc_seq[ str:to_type str:code_type int:code_value -- str:ansi_seq ]
  code_type @ "B" = code_type @ "F" = or if
    code_value @
    2 strcut swap xtoi var! r
    2 strcut swap xtoi var! g
    2 strcut swap xtoi var! b
    "" var! retval
    to_type @ "NOCOLOR" = if
      "" exit
    then
    to_type @ "ANSI-3BIT-VGA" = if
      { "\[[" to_type @ { r @ g @ b @ }list ansi3_nearest_vga code_type @ "B" = if 10 + then intostr "m" }join exit
    then
    to_type @ "ANSI-3BIT-XTERM" = if
      { "\[[" to_type @ { r @ g @ b @ }list ansi3_nearest_xterm code_type @ "B" = if 10 + then intostr "m" }join exit
    then
    to_type @ "ANSI-4BIT-VGA" = if
      code_type @ "F" = if
        { "\[[" to_type @ { r @ g @ b @ }list ansi4_nearest_vga intostr "m" }join exit
      else
        { "\[[" to_type @ { r @ g @ b @ }list ansi3_nearest_vga 10 + intostr "m" }join exit
      then
    then
    to_type @ "ANSI-4BIT-XTERM" = if
      code_type @ "F" = if
        { "\[[" to_type @ { r @ g @ b @ }list ansi4_nearest_xterm intostr "m" }join exit
      else
        { "\[[" to_type @ { r @ g @ b @ }list ansi3_nearest_xterm 10 + intostr "m" }join exit
      then
    then
    to_type @ "ANSI-8BIT" = if
      { code_type @ "F" = if "\[[38;5;" else "\[[48;5;" then to_type @ { r @ g @ b @ }list ansi8_nearest intostr "m" }join exit
    then
    to_type @ "ANSI-24BIT" = if
      { code_type @ "F" = if "\[[38;2;" else "\[[48;2;" then r @ intostr ";" g @ intostr ";" b @ intostr "m" }join exit
    then
    "Invalid ANSI type" abort
  then
  code_type @ "X" = if
    code_value @ "000000" = if
      to_type @ "NOCOLOR" = if
        "" exit
      then
      to_type @ "ANSI-" instr 1 = if
        "\[[0;37;40m" exit
      then
      "Invalid ANSI type" abort
    then
    code_value @ "FFFFFF" = if
      "#" exit
    then
    { "[INVALID #MCC V" .version " CODE - UNKNOWN X VALUE ]" }join exit
  then
  { "[INVALID #MCC V" .version " CODE - UNKNOWN TYPE " code_type @ " ]" }join
;

: mcc_convert[ str:to_type str:source_string -- str:result_string ]
  to_type @ "X" "000000" mcc_seq var! color_reset

  source_string @ "#MCC-" instr not if
    source_string @ exit
  then

  source_string @ "#MCC-" split swap var! retval
  "#MCC-" explode_array foreach
    nip
    1 strcut swap var! code_type
    1 strcut swap var! code_dash
    6 strcut swap var! code_value
    var! post_code
    code_type @ ctoi "A" ctoi >= code_type @ ctoi "Z" ctoi <= and code_dash @ "-" = and code_value @ strlen 6 = and code_value @ hex? and if
      { retval @ to_type @ code_type @ code_value @ mcc_seq post_code @ }join retval !
    else
      { retval @ "#MCC-" code_type @ code_dash @ code_value @ post_code @ }join retval !
    then
  repeat

  { color_reset @ retval @ color_reset @ }join
;

: array_hasval ( ? a -- b )
  foreach
    nip
    over = if
      pop 1 exit
    then
  repeat
  pop 0
;

(*****************************************************************************)
(*                           M-LIB-COLOR-Transcode                           *)
(*****************************************************************************)
: M-LIB-COLOR-Transcode[ str:from_type str:to_type str:source_string -- str:result_string ]
  (* M1 OK *)

  from_type @ string? not if "Non-string argument (1)." abort then
  to_type @ string? not if "Non-string argument (2)." abort then
  source_string @ string? not if "Non-string argument (3)." abort then

  { "MCC" "NOCOLOR" "ANSI-3BIT-VGA" "ANSI-3BIT-XTERM" "ANSI-4BIT-VGA" "ANSI-4BIT-XTERM" "ANSI-8BIT" "ANSI-24BIT" }list var! supported_types

  from_type @ supported_types @ array_hasval not if "from_type not recognized (1)." abort then
  to_type @ supported_types @ array_hasval not if "to_type not recognized (2)." abort then

  from_type @ to_type @ = if
    source_string @ exit
  then

  from_type @ "MCC" = if
    to_type @ "ANSI-" instr 1 = to_type @ "NOCOLOR" = or if
      to_type @ source_string @ mcc_convert exit
    then
  then

  from_type @ "NOCOLOR" = if
    to_type @ "MCC" = if
      source_string @ "#MCC-X-FFFFFF" "#" subst exit
    then
  then

  from_type @ "ANSI-" instr 1 = if
    "Decoding ANSI strings is not yet supported." abort
  then

  { "Transcoding from " from_type @ " to " to_type @ " is not yet supported." }join abort
;
PUBLIC M-LIB-COLOR-Transcode
$LIBDEF M-LIB-COLOR-Transcode

: main ( s --  )
  "Library called as command." abort
;
.
c
q
!@register m-lib-color.muf=m/lib/color
!@set $m/lib/color=M2
!@set $m/lib/color=L
!@set $m/lib/color=S
!@set $m/lib/color=H

