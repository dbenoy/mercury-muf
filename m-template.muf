!@program m-<--FILENAME-->
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-<--FILENAME--> - $m/<--REGISTRATION-->                                  *)
(*   <description>                                                           *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* USAGE:                                                                    *)
(*   <Basic usage information, if required>                                  *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   <routine name> <arguments>                                              *)
(*     <description>                                                         *)
(*                                                                           *)
(*   <routine name> <arguments>                                              *)
(*     <description>                                                         *)
(*                                                                           *)
(* TECHNICAL NOTES:                                                          *)
(*   <if nessessary>                                                         *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version X.X -- <name> -- <month>, <year>                                *)
(*      -<note>                                                              *)
(*      -<note>                                                              *)
(*   Version 1.0 -- <name> -- <month>, <year>                                *)
(*      -<note>                                                              *)
(*      -<note>                                                              *)
(*****************************************************************************)
(* Copyright Notice:                                                         *)
(*                                                                           *)
(* Copyright (C) <year(s)>                                                   *)
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
$VERSION <version in floating point format>
$AUTHOR  <your name>
$NOTE    <short description>
$DOCCMD  @list __PROG__=2-<last header line>

(* ------------------------------------------------------------------------ *)

: M-HELP-desc ( s -- s )
  pop
  "<--SHORT HELP DESC-->"
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- Y )
  name ";" split pop toupper var! action_name
  {
    { action_name @ " <--ARGS-->" }cat
    " "
    "  <--HELP-->"
  }list
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------ *)

: main ( s --  )
;
.
c
q
!@register m-<--FILENAME-->=m/<--REGISTRATION-->
!@set $m/<--REGISTRATION-->=<--FLAG-->

