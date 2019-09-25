@program m-lib-ansi.muf
1 99999 d
i
$pragma comment_recurse
(*****************************************************************************)
(* m-lib-ansi.muf - $m/lib/ansi                                              *)
(*   Fuzzball 7 library for old 'tilde' style ANSI color codes.              *)
(*                                                                           *)
(*   This is a drop-in replacement for the standard lib-ansi-free.muf        *)
(*   library, including aliases for alternative names for the same routines. *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   ansi? ( d -- i )                                                        *)
(*     Checks if ansi color is enabled for a given player.                   *)
(*                                                                           *)
(*   ansi-codecheck ( s -- i )                                               *)
(*     Checks a string to see if it's a valid 3-number ANSI code             *)
(*                                                                           *)
(*   ansi-connotify ( i s -- )                                               *)
(*     Like connotify, but with ANSI support.                                *)
(*                                                                           *)
(*   ansify_string ( s -- s )                                                *)
(*     Changes ANSI 'tilde' style code to real ANSI code.                    *)
(*                                                                           *)
(*   ansi-strip  ( s -- s )                                                  *)
(*     Removes all ANSI codes from the string.                               *)
(*                                                                           *)
(*   ansi-strlen ( s -- i )                                                  *)
(*     Returns the string length of a string, minus the length of any ANSI   *)
(*     codes it might contain.                                               *)
(*                                                                           *)
(*   ansi-notify ( d s -- )                                                  *)
(*     Like notify, but with ANSI support.                                   *)
(*                                                                           *)
(*   ansi-notify-except ( d d s -- )                                         *)
(*     Like notify_except, but with ANSI support.                            *)
(*                                                                           *)
(*   ansi-notify-exclude ( d dn ... d1 n s -- )                              *)
(*     Like notify-exclude with ANSI support.                                *)
(*                                                                           *)
(*   ansi-otell ( s -- )                                                     *)
(*     Like .otell, but with ANSI support.                                   *)
(*                                                                           *)
(*   ansi-strcut ( s i -- s1 s2 )                                            *)
(*     Like strcut, but ignores ANSI codes.                                  *)
(*                                                                           *)
(*   ansi-tell ( s -- )                                                      *)
(*     Like .tell, but with ANSI support                                     *)
(*                                                                           *)
(*   ansi-value ( s -- s )                                                   *)
(*     Turns stuff like "blue" or "lightgreen" into colour values like "04"  *)
(*     and "12".                                                             *)
(*                                                                           *)
(*   ansi-version ( -- i )                                                   *)
(*     Returns version number as 3-digit integer.                            *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   Tidle ansi color is primarily for backwards compatibility if you don't  *)
(*   care about backwards compatibility with pre-fuzzball 6 lib-ansi systems *)
(*   you should see 'man textattr' or 'mpi attr'.                            *)
(*                                                                           *)
(*   Info about tidle ansi escapes:                                          *)
(*    Color can be changed with an escape of the form: ~&<A><F><B>           *)
(*    <A> is the attribute, one of:                                          *)
(*      1 => bold                                                            *)
(*      2 => reverse                                                         *)
(*      3 => bold and reverse                                                *)
(*      4 => underline [ in theory ]                                         *)
(*      5 => flash                                                           *)
(*      8 => also reverse                                                    *)
(*      - => no change from what it was before                               *)
(*                                                                           *)
(*    <F> is the foreground, one of:                                         *)
(*      0 => black                                                           *)
(*      1 => red                                                             *)
(*      2 => green                                                           *)
(*      3 => yellow                                                          *)
(*      4 => blue                                                            *)
(*      5 => magenta                                                         *)
(*      6 => cyan                                                            *)
(*      7 => white                                                           *)
(*      - => no change from what it was before                               *)
(*                                                                           *)
(*    <B> is the background, one of:                                         *)
(*      0 => black                                                           *)
(*      1 => red                                                             *)
(*      2 => green                                                           *)
(*      3 => yellow                                                          *)
(*      4 => blue                                                            *)
(*      5 => magenta                                                         *)
(*      6 => cyan                                                            *)
(*      7 => white                                                           *)
(*      - => no change from what it was before.                              *)
(*                                                                           *)
(*    Other codes supported:                                                 *)
(*     ~&R -- to reset colors...                                             *)
(*                                                                           *)
(*    Other notes:                                                           *)
(*     \~& or ~&~& will put a literal ~& without doing ansi codes...         *)
(*                                                                           *)
(*    Semi-bugs:                                                             *)
(*     ansi-strcut will NOT preserve \~& exactly; in the results they will   *)
(*     be replaced with ~&~&, except when ansi_strcut is returning anot      *)
(*     string for either of it's return values.                              *)
(*                                                                           *)
(*    NOTE:                                                                  *)
(*      ansi-version will return '200' for this library.                     *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 3.0 -- Daniel Benoy -- Sep 25 2019                              *)
(*     - Modified to match conventions of mercury-muf and added to Git       *)
(*       repository.                                                         *)
(*     - Removed setup routine and put the setup commands in the source      *)
(*       file.                                                               *)
(*     - Tidied code.                                                        *)
(*   Version 2.0a -- Charles "Wog" Reiss <car@cs.brown.edu> -- Apr 12 2001   *)
(*     - Added some nice _defs and used Natty's ansi-strcut routine from     *)
(*     lib-ansi-burn. (Which works, I hope.)                                 *)
(*   Version 2.0 -- Charles "Wog" Reiss <car@cs.brown.edu> -- May 20 2000    *)
(*     - Used ANSI codes directly, rather then textattr, so - works as       *)
(*     expected. Actaully wrote own ansi_strcut routine, fixing problems     *)
(*     that would be suffered with old one. Also added public routines for   *)
(*     any program that might try calling lib-ansi directly. (as in          *)
(*     "$lib/ansi" match "ansi-tell" call), rather than using this libraries *)
(*     _defs.                                                                *)
(*   Version 1.02 -- Charles "Wog" Reiss <car@cs.brown.edu> -- Mar 31 2000   *)
(*     - Enhanced setup script a bit.                                        *)
(*   Version 1.01 -- Charles "Wog" Reiss <car@cs.brown.edu> -- Feb 25 2000   *)
(*     - Modified _defs/ansi-codecheck to deal with - in escape codes.       *)
(*   Version 1.0 -- Charles "Wog" Reiss <car@cs.brown.edu> -- Feb 24 2000    *)
(*     - Assignment of version number to programs.                           *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2000-2001 Charles "Wog" Reiss <car@cs.brown.edu>            *)
(* Copyright (C) 2000-2019 Daniel Benoy and contributors                     *)
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
$VERSION 3.00
$AUTHOR  Daniel Benoy
$NOTE    Legacy ANSI code parsing
$DOCCMD  @list $<registration>=2,<last header line>

(* Begin configurable options *)

(* End configurable options *)

$pubdef :

(For the benefit of those reading this code who aren't aware of this, 
  in FB6 \[ represents the escape charactor in strings. 
  That's ASCII code 27 decimal, and this convient table is provided if
  you want it in another base. <;
  (Yes! I do have too much time!)
Base      Number  Base      Number  Base      Number
  2        11011    3         1000    4          123
  5          102    6           43    7           36
  8           33    9           30   10           27
 11           25   12           23   13           21
 14           1D   15           1C   16           1B
 17           1A   18           19   19           18
 20           17   21           16   22           15
 23           14   24           13   25           12
 26           11   27           10   28            R
 29            R   30            R   31            R
 32            R   33            R   34            R
 35            R   36            R
)

(Protect strings should be 2 chars long since ~& is for ansi_strcut.)
$def PROTECT_STR "\[\["
 
( s   -- s'  )
$define _protect
  PROTECT_STR "\\~&" subst
  PROTECT_STR "~&~&" subst
$enddef
 
( s'  -- s'' )
$define _end_protect
  "~&" PROTECT_STR subst
$enddef
 
( s' -- s  ) ( * almost; \~& will be replaced with ~&~&. )
$define _cut_end_protect
  "~&~&" PROTECT_STR subst
$enddef
 
( This can be changed if you don't want black on white to be the default
  color. )
$def RESET_CODE "\[[0;37;40m"

: tCodeData ( s -- s )
  (Generate like:
    070 -> "\[[0;37;40m"
    --- -> ""
    8-- -> "\[[8m"
  )
  dup  "---" strcmp not if pop "" exit then
  ( ^^ Special Case ^^ )
  "\[["
  ( We add 1 to the string so - turns into -1, not 0, for us to not touch in the case statment. )
  swap 
  ("\[[" AFB)
  1 strcut
  ( "\[[" A FB )
  over "-" strcmp not if (Attribute)
  ( "\[[" A FB )
    swap pop
  else
    rot rot
  ( FB "\[[" A )
    strcat ";" strcat swap 
  then
  ( "\[[..." FB )
  1 strcut
  ( ... F B )
  over "-" strcmp not if (Forground)
    swap pop ( "\[[" B )
  else
    rot "3" strcat rot strcat ";" strcat swap
  then
  ("\[[" B)
  
  dup "-" strcmp not if
    pop
    dup strlen 1 - strcut pop
  else
    swap "4" strcat swap strcat
  then
  "m" strcat
;
 
(Returns length of ansi code following ~&. 
 As in you can give it 06-Cyan!
 Or RResetted.., etc. as an argument.
)
: code-length ( s -- i )
  dup 1 strcut pop "R" stringcmp not if pop 3 exit then
  3 strcut pop
  "[-0-9][-0-9][-0-9]" smatch if 5 else 0 exit then
;
 
(*****************************************************************************)
(* ansify-string *)
(*****************************************************************************)
: ansify-string
  var data
  var oddness
  var append

  dup not if exit then
 
  "" data !
  _protect
  dup "~&" instr not if
    _end_protect exit
  then
  RESET_CODE "~&R" subst
  RESET_CODE "~&r" subst
  dup "~&" instr 1 = oddness !
  "~&" explode
  oddness @ not if
     swap append ! 1 - 
  else
     "" append !
  then
  begin 
    dup while
    dup 1 + rotate
    dup if
      dup "[-0-9][-0-9][-0-9]*" smatch if
        3 strcut swap tCodeData 
     swap strcat 
      then
    then
    data @ strcat data !
    1 -
  repeat
  pop
  append @ data @ strcat
  _end_protect
;
PUBLIC ansify-string
$libdef ansify-string
$pubdef ansify_string ansify-string
 
(*****************************************************************************)
(* ansi? *)
(*****************************************************************************)
: ansi? ( d -- i )
  owner "C" flag?
;
PUBLIC ansi?
$libdef ansi?

(*****************************************************************************)
(* ansi-strip *)
(*****************************************************************************)
: ansi-strip ( s -- s' )
  var data

  _protect
  "" "~&R" subst
  "" "~&r" subst
  dup "~&" instr not if _end_protect exit then
  "" data !
  "~&" explode
  begin
    dup while
    dup 1 + rotate
    dup if
      dup "[-0-9][-0-9][-0-9]*" smatch if ( We allow up to nine, just because. )
        3 strcut swap pop
      then
    then
    data @ strcat data !
    1 -
  repeat
  pop
  data @ _end_protect
;
PUBLIC ansi-strip
$libdef ansi-strip
$pubdef ansi_strip ansi-strip
 
(*****************************************************************************)
(* ansi-strcut *)
(*****************************************************************************)
: ansi-strcut ( s i -- s1 s2 ; like strcut, but ignores ANSI codes. )
  var numtocut
  var strcut_s1
  var strcut_s2
  var numcutsofar
  numtocut !
  dup "~&" instr 0 = if
   numtocut @ \strcut exit
  then
  0 numcutsofar !
  "" strcut_s1 !
  numtocut @ 0 = if "" swap exit then
  numtocut @ over "~&" instr > not if numtocut @ \strcut exit then
  strcut_s2 !
  begin
  strcut_s2 @
  dup "~&" instr 0 = if
   dup strlen numcutsofar @ + numtocut @ > if ( I see enuff slicables! )
     numtocut @ numcutsofar @ - \strcut swap
     numtocut @ numcutsofar !
     strcut_s1 @ swap strcat strcut_s1 !
     strcut_s2 !
   else
     numtocut @ numcutsofar !
     strcut_s1 @ swap strcat strcut_s1 !
     "" strcut_s2 !
   then
  else
  dup "~&" instr 1 = if
   dup "~&R" stringpfx over "~&C" stringpfx or if
     3
   else
     5
   then
   \strcut swap strcut_s1 @ swap strcat strcut_s1 ! strcut_s2 !
  else
   dup "~&" instr 1 -
   dup numcutsofar @ + numtocut @ < if ( If I dun see enuff cuttable chars
                                         to satisfy my base desire..mrowr! )
  ( Top of stack here contains how many cuttable chars I can get. )
     numcutsofar @ over + numcutsofar !
     \strcut swap strcut_s1 @ swap strcat strcut_s1 ! strcut_s2 !
   else ( Else..if you have a long stretch of cuttable chars.. )
     pop
     numtocut @ numcutsofar @ - \strcut swap
     numtocut @ numcutsofar !
     strcut_s1 @ swap strcat strcut_s1 !
     strcut_s2 !
   then
  then then
  strcut_s2 @ not
  numcutsofar @ numtocut @ = or until
  strcut_s1 @ strcut_s2 @
;
PUBLIC ansi-strcut
$libdef ansi-strcut
$pubdef ansi_strcut ansi-strcut
 
(*****************************************************************************)
(* ansi-codecheck *)
(*****************************************************************************)
: ansi-codecheck
  "{r|R|[-0-9][-0-9][-0-9]}" smatch
;
PUBLIC ansi-codecheck
$libdef ansi-codecheck
$pubdef ansi_codecheck ansi-codecheck

(*****************************************************************************)
(* ansi-notify *)
(*****************************************************************************)
: ansi-notify
  ansify-string \notify
;
PUBLIC ansi-notify
$libdef ansi-notify
$pubdef ansi_notify ansi-notify

(*****************************************************************************)
(* ansi-notify-except *)
(*****************************************************************************)
: ansi-notify-except
  ansify-string 1 swap \notify_exclude
;
PUBLIC ansi-notify-except
$libdef ansi-notify-except
$pubdef ansi_notify-except ansi-notify-except

(*****************************************************************************)
(* ansi-notify-exclude *)
(*****************************************************************************)
: ansi-notify-exclude
  ansify-string \notify_exclude
;
PUBLIC ansi-notify-exclude
$libdef ansi-notify-exclude
$pubdef ansi_notify-exclude ansi-notify-exclude

(*****************************************************************************)
(* ansi-tell *)
(*****************************************************************************)
: ansi-tell
  ansify-string .tell
;
PUBLIC ansi-tell
$libdef ansi-tell
$pubdef ansi_tell ansi-tell

(*****************************************************************************)
(* ansi-otell *)
(*****************************************************************************)
: ansi-otell
  ansify-string .otell
;
PUBLIC ansi-otell
$libdef ansi-otell
$pubdef ansi_otell ansi-otell

(*****************************************************************************)
(* ansi-strlen *)
(*****************************************************************************)
: ansi-strlen
  ansi-strip \strlen
;
PUBLIC ansi-strlen
$libdef ansi-strlen
$pubdef ansi_strlen ansi-strlen

(*****************************************************************************)
(* ansi-connotify *)
(*****************************************************************************)
: ansi-connotify
  ansify-string \connotify
;
PUBLIC ansi-connotify
$libdef ansi-connotify
$pubdef ansi_connotify ansi-connotify

(*****************************************************************************)
(* ansi-version *)
(*****************************************************************************)
$pubdef ansi-version 200 (* Emulate lib-ansi-free with extra feeps! *)
$pubdef ansi_version ansi-version

(*****************************************************************************)
(* ansi-value *)
(*****************************************************************************)
: ansi-value ( s -- s )
  case
    "BLACK" stringcmp 0 = when "0" end
    "RED" stringcmp 0 = when "1" end
    "GREEN" stringcmp 0 = when "2" end
    "YELLOW" stringcmp 0 = when "3" end
    "BLUE" stringcmp 0 = when "4" end
    "MAGENTA" stringcmp 0 = when "5" end
    "CYAN" stringcmp 0 = when "6" end
    dup "LIGHTGREY" stringcmp 0 = swap "LIGHTGRAY" stringcmp 0 = or when "7" end
    dup "DARKGREY" stringcmp 0 = swap "DARKGRAY" stringcmp 0 = or when "10" end
    "LIGHTRED" stringcmp 0 = when "11" end
    "LIGHTGREEN" stringcmp 0 = when "12" end
    "LIGHTYELLOW" stringcmp 0 = when "13" end
    "LIGHTBLUE" stringcmp 0 = when "14" end
    "LIGHTMAGENTA" stringcmp 0 = when "15" end
    "LIGHTCYAN" stringcmp 0 = when "16" end
    "DARK" stringcmp 0 = when "17" end
    default "" end
  endcase
;
PUBLIC ansi-value
$libdef ansi-value
$pubdef ansi_value ansi-value

: main
"Library called as command." abort
;
.
c
q
@register m-lib-ansi.muf=m/lib/ansi
@set $m/lib/ansi=M2
@set $m/lib/ansi=L

