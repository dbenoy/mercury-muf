!@program m-lib-string.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-string.muf - $m/lib/string                                          *)
(*   String manipulation routines.                                           *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-STRING-xtoi ( s -- i )                                            *)
(*     Convert a hexadecimal string to an integer. MUF uses 32-bit signed    *)
(*     integers so this may result in a negative number. Like the atoi       *)
(*     primitive, 0 is returned if the string is not a valid hexadecimal     *)
(*     number.                                                               *)
(*                                                                           *)
(*   M-LIB-STRING-itox ( i -- s )                                            *)
(*     Convert an integer into a hexadecimal string. This works bit-by-bit   *)
(*     so negative numbers will appear in their two's compliment form.       *)
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
$DOCCMD  @list __PROG__=2-30

$PUBDEF :
$PUBDEF .xtoi M-LIB-STRING-xtoi
$PUBDEF .itox M-LIB-STRING-itox
$PUBDEF .sitox dup 0 < if abs "-" swap M-LIB-STRING-itox strcat else M-LIB-STRING-itox then

(*****************************************************************************)
(*                             M-LIB-STRING-xtoi                             *)
(*****************************************************************************)
: M-LIB-STRING-xtoi ( s -- i )
  (* M1 OK *)
  "s" checkargs

  toupper
  (* Return 0 if there are any invalid characters *)
  dup begin
    1 strcut swap
    dup number? not swap ctoi dup "A" ctoi < swap "F" ctoi > or and if
      pop pop 0 exit
    then
    dup not
  until
  pop
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

