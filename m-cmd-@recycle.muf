!@program m-cmd-@recycle.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-@recycle.muf - $m/cmd/at_recycle                                    *)
(*   A replacement for the built-in @recycle command which tries to mimic    *)
(*   stock behavior while adding features.                                   *)
(*                                                                           *)
(*   The business itself is taken care of by m-lib-@recycle.muf, so that the *)
(*   command can more easily be run from other programs like automated       *)
(*   building programs, but still retain proper message output, permission   *)
(*   checks, penny handling, etc.                                            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.1 -- Daniel Benoy -- September, 2019                          *)
(*      - Split from lib-create.muf and cmd-lib-create.muf into mercury-muf  *)
(*        project                                                            *)
(*   Version 1.0 -- Daniel Benoy -- April, 2004                              *)
(*      - Original implementation for Latitude MUCK                          *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) 2004-2019 Daniel Benoy                                      *)
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
$VERSION 1.001
$AUTHOR  Daniel Benoy
$NOTE    @recycle command with more features.
$DOCCMD  @list __PROG__=2-45

: doRecycle ( d -- s )
  1 try
    recycle "" exit
  catch
    exit
  endcatch
;

(* Begin configurable options *)

(* End configurable options *)

$INCLUDE $m/lib/at_recycle

$PUBDEF :

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( d -- s )
  pop
  "Destroy an object."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <object>" }cat
    " "
    "Destroy an object and remove all references to it within the database. The object is then added to a free list, and newly created objects are assigned from the pool of recycled objects first.  You *must* own the object being recycled, even wizards must use the @chown command to recycle someone else's belongings."
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: main ( s --  )
  "=" split
  pop
  strip var! objectname

  (* Perform unlink *)
  objectname @ 0 M-LIB-AT_RECYCLE-recycle pop
;

.
c
q
!@register m-cmd-@recycle.muf=m/cmd/at_recycle
!@set $m/cmd/at_recycle=M3
!@set $m/cmd/at_recycle=W

