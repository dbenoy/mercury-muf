!@program m-lib-grammar.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-grammar.muf - $m/lib/grammar                                        *)
(*   A library for generating text based on language grammar rules. It has   *)
(*   a more advanced implementation of the built-in pronoun substitution, as *)
(*   well as definite/indefinite article support.                            *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* EXAMPLES:                                                                 *)
(*                                                                           *)
(* PROPERTIES:                                                               *)
(*   Note: You're free to set anything you'd like for the substitution       *)
(*   properties for some very creative results. For example, you could take  *)
(*   an exit called "303" and set its %d to "the rusty door to room 303",    *)
(*   but depending on the options used by any given program, certain values  *)
(*   may be ignored if they do not closely match the actual name of the      *)
(*   object, or other restrictions.                                          *)
(*                                                                           *)
(*   "%a"                                                                    *)
(*     On any object: Absolute posessive pronoun. (his/hers/its)             *)
(*                                                                           *)
(*   "%d"                                                                    *)
(*     On any object: Like %i, but always preferring the definite article.   *)
(*     As with %i, capitalization may be preserved, so capitalize proper     *)
(*     nouns only.                                                           *)
(*                                                                           *)
(*     Example objects:                                                      *)
(*       the golden ticket, the honarary degree, The Crown of England, C3P0. *)
(*     Example rooms:                                                        *)
(*       the dark cave, the evil lair, the hospital, Fluttershy's House      *)
(*                                                                           *)
(*   "%i"                                                                    *)
(*     On any object: The object's name, with its most typical article.      *)
(*     Capitalization may be preserved, so capitalize proper nouns only.     *)
(*                                                                           *)
(*     Example objects:                                                      *)
(*       a golden ticket, an honarary degree, The Crown of England, C3P0.    *)
(*     Example rooms:                                                        *)
(*       a dark cave, an evil lair, the hospital, Fluttershy's House         *)
(*                                                                           *)
(*   "%n"                                                                    *)
(*     On any object: The object's name.                                     *)
(*                                                                           *)
(*   "%o"                                                                    *)
(*     On any object: Objective pronoun. (him/her/it)                        *)
(*                                                                           *)
(*   "%p"                                                                    *)
(*     On any object: Posessive pronoun. (his/her/it)                        *)
(*                                                                           *)
(*   "%r"                                                                    *)
(*     On any object: Reflexive pronoun. (himself/herself/itself)            *)
(*                                                                           *)
(*   "%s"                                                                    *)
(*     On any obeject: Subjective pronoun. (he/she/it)                       *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-GRAMMAR-sub[ str:template ref:object dict:opts -- str:name ]      *)
(*     Like the PRONOUN_SUB primitive, this takes a string, and substitutes  *)
(*     % codes for the % properties mentioned above, with the opts argument  *)
(*     dictionary array used to supply special options:                      *)
(*                                                                           *)
(*       "match_name"                                                        *)
(*         If this is set to "YES" then the %d, %i, and %n values on the     *)
(*         object must match the actual name of the object, plus their       *)
(*         respective definite/indefinite articles (See PROPERTIES above),   *)
(*         excluding differences in capitalization, underscores being        *)
(*         replaced by spaces, and $m/lib/color MCC color codes.             *)
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
$NOTE    Language grammar routines.
$DOCCMD  @list __PROG__=2-92

(* ====================== BEGIN CONFIGURABLE OPTIONS ====================== *)

(* Comment this out to remove the dependency on $m/lib/color *)
$DEF M_LIB_COLOR

(* Default pronouns for object types and genders. Empty string for "Name's" / "Name" *)
lvar g_pronoun_defaults
: pronoun_defaults
  g_pronoun_defaults @ if g_pronoun_defaults @ exit then
  {
    "female"          { "%a" "hers" "%o" "her" "%p" "her" "%r" "herself" "%s" "she" }dict
    "hermaphrodite"   { "%a" "hirs" "%o" "hir" "%p" "hir" "%r" "hirself" "%s" "sie" }dict
    "male"            { "%a" "his"  "%o" "him" "%p" "his" "%r" "himself" "%s" "he"  }dict
    "neuter"          { "%a" "its"  "%o" "it"  "%p" "its" "%r" "itself"  "%s" "it"  }dict
    "nonbinary"       { "%a" ""     "%o" ""    "%p" ""    "%r" ""        "%s" ""    }dict
    "unknown_exit"    { "%a" "its"  "%o" "it"  "%p" "its" "%r" "itself"  "%s" "it"  }dict
    "unknown_player"  { "%a" ""     "%o" ""    "%p" ""    "%r" ""        "%s" ""    }dict
    "unknown_program" { "%a" "its"  "%o" "it"  "%p" "its" "%r" "itself"  "%s" "it"  }dict
    "unknown_room"    { "%a" "its"  "%o" "it"  "%p" "its" "%r" "itself"  "%s" "it"  }dict
    "unknown_thing"   { "%a" "its"  "%o" "it"  "%p" "its" "%r" "itself"  "%s" "it"  }dict
  }dict dup g_pronoun_defaults !
;

(* Direct mappings from the gender property values on object into their recognized gender *)
lvar g_gender_table
: gender_table
  g_gender_table @ if g_gender_table @ exit then
  {
    (* Basic *)
    "female"        "female"
    "hermaphrodite" "hermaphrodite"
    "male"          "male"
    "neuter"        "neuter"
    "nonbinary"     "nonbinary"
    (* Common *)
    "girl"          "female"
    "boy"           "male"
    "woman"         "female"
    "man"           "male"
    "lady"          "female"
    "gentleman"     "male"
    "she"           "female"
    "he"            "male"
    "her"           "female"
    "him"           "male"
    "thing"         "neuter"
    "none"          "neuter"
    "it"            "neuter"
    "ungendered"    "neuter"
    "herm"          "hermaphrodite"
    "futa"          "hermaphrodite"
    "futanari"      "hermaphrodite"
    "agender"       "nonbinary"
    "enby"          "nonbinary"
    "nb"            "nonbinary"
    "androgynous"   "nonbinary"
    "trap"          "nonbinary"
    (* Colloquial *)
    "gal"           "female"
    "guy"           "male"
    "chick"         "female"
    "dude"          "male"
    "bird"          "female"
    "bloke"         "male"
    "chap"          "male"
    "femme"         "female"
    (* Animal - Anserine *)
    "gander"        "female"
    "pen"           "female"
    "drake"         "male"
    "cob"           "male"
    (* Animal - Asinine *)
    "jenny"         "female"
    "molly"         "female"
    "jack"          "male"
    "jackass"       "male"
    "john"          "male"
    (* Animal - Bovine *)
    "cow"           "female"
    "bull"          "male"
    (* Animal - Canine *)
    "bitch"         "female"
    "dog"           "male"
    (* Animal - Cervine *)
    "doe"           "female"
    "buck"          "male"
    "stag"          "male"
    "hart"          "male"
    (* Animal - Equine *)
    "mare"          "female"
    "dam"           "female"
    "filly"         "female"
    "stallion"      "male"
    "stud"          "male"
    "colt"          "male"
    (* Animal - Feline *)
    "pussy"         "female"
    "queen"         "female"
    "leopardess"    "female"
    "lioness"       "female"
    "tigress"       "female"
    "tom"           "male"
    "tomcat"        "male"
    (* Animal - Galline *)
    "chicken"       "female"
    "hen"           "female"
    "pullet"        "female"
    "rooster"       "male"
    "cock"          "male"
    "cockerel"      "male"
    (* Animal - Hircine *)
    "nanny"         "female"
    "nannygoat"     "female"
    "nanny goat"    "female"
    "billy"         "male"
    "billygoat"     "male"
    "billy goat"    "male"
    (* Animal - Macropodidine *)
    "flyer"         "female"
    "boomer"        "male"
    (* Animal - Musteline *)
    "jill"          "female"
    "jack"          "male"
    "hob"           "male"
    (* Animal - Ovine *)
    "ewe"           "female"
    "ram"           "male"
    (* Animal - Porcine *)
    "sow"           "female"
    "boar"          "male"
    (* Animal - Vulpine *)
    "vixen"         "female"
    "tod"           "male"
    "renard"        "male"
    "reynard"       "male"
  }dict dup g_gender_table !
;

(* These tests apply if the gender is not in the above table. They use smatch syntax. *)
(* If it generates contradictory results, 'nonbinary' will be used. *)
lvar g_gender_table2
: gender_table2
  g_gender_table2 @ if g_gender_table2 @ exit then
  {
    { "she[ -]*"     "female"    }list
    { "he[ -]*"      "male"      }list
    { "girl*"        "female"    }list
    { "*girl"        "female"    }list
    { "boy*"         "male"      }list
    { "*boy"         "male"      }list
    { "woman*"       "female"    }list
    { "*woman"       "female"    }list
    { "man*"         "male"      }list
    { "*[^w][^o]man" "male"      }list
    { "lady*"        "female"    }list
    { "*lady"        "female"    }list
    { "fem*"         "female"    }list
    { "*fem"         "female"    }list
    { "*ess"         "female"    }list
    { "*ette"        "female"    }list
  }list dup g_gender_table2 !
;

(* And finally, if the gender is not in any of the above tables, smatch through this table. *)
(* This table takes the first hit from top to bottom. *)
lvar g_gender_table3
: gender_table3
  g_gender_table2 @ if g_gender_table2 @ exit then
  {
    { "*ish"         "nonbinary" }list
    { "*[ -]like"    "nonbinary" }list
    { "gender*"      "nonbinary" }list
    { "*gender"      "nonbinary" }list
    { "*gendered"    "nonbinary" }list
  }list dup g_gender_table3 !
;

(* ======================= END CONFIGURABLE OPTIONS ======================= *)

$INCLUDE $m/lib/program
$IFDEF M_LIB_COLOR
  $INCLUDE $m/lib/color
$ENDIF

$IFDEF M_LIB_COLOR
  $DEF COLOR_STRIP .color_strip
$ELSE
  $DEF COLOR_STRIP
$ENDIF

$PUBDEF :

(* ------------------------------------------------------------------------- *)

: indefinite_article ( s -- s )
  1 strcut pop "[aeiou]" smatch if "an " else "a " then
;

: get_gender[ ref:object -- str:result ]
  object @ "gender_prop" sysparm getpropstr var! gender
  "" var! match
  var gender_test
  (* Table 1, direct matches *)
  gender_table gender @ [] match !
  match @ if match @ exit then
  (* Table 2, smatch with 'nonbinary' for ambiguous *)
  gender_table2 foreach
    nip
    gender_test !
    gender @ gender_test @ 0 [] smatch if
      { "DEBUG Hit: " gender_test @ 0 [] }join .tell
      match @ if
        gender_test @ 1 [] match @ = not if
          "nonbinary" exit
        then
      else
        gender_test @ 1 [] match !
      then
    then
  repeat
  match @ if match @ exit then
  (* Table 3, smatch, taking the first hit *)
  gender_table3 foreach
    nip
    gender_test !
    gender @ gender_test @ 0 [] smatch if
      { "DEBUG Hit2: " gender_test @ 0 [] }join .tell
      gender_test @ 1 [] match !
      break
    then
  repeat
  match @ if match @ exit then
  (* No matches, use the 'unknown' defaults *)
  object @ exit? if
    "unknown_exit" exit
  then
  object @ player? if
    "unknown_player" exit
  then
  object @ program? if
    "unknown_program" exit
  then
  object @ room? if
    "unknown_room" exit
  then
  "unknown_thing" exit
;

: get_substitutions[ ref:object -- dict:result ]
  object @ name var! object_name
  (* Grab the default values *)
  pronoun_defaults object @ get_gender [] var! substitutions
  (* Set fallback defaults *)
  (* %a *)
  substitutions @ "%a" [] not if
    object_name @ "'s" strcat substitutions @ "%a" ->[] substitutions !
  then
  (* %o *)
  substitutions @ "%o" [] not if
    object_name @ substitutions @ "%o" ->[] substitutions !
  then
  (* %p *)
  substitutions @ "%p" [] not if
    object_name @ "'s" strcat substitutions @ "%p" ->[] substitutions !
  then
  (* %r *)
  substitutions @ "%r" [] not if
    object_name @ substitutions @ "%r" ->[] substitutions !
  then
  (* %s *)
  substitutions @ "%s" [] not if
    object_name @ substitutions @ "%s" ->[] substitutions !
  then
  (* %d *)
  substitutions @ "%d" [] not if
    object @ player? if "" else "the " then
    object_name @ strcat substitutions @ "%d" ->[] substitutions !
  then
  (* %i *)
  substitutions @ "%i" [] not if
    object @ player? if "" else object_name @ indefinite_article " " strcat then
    object_name @ strcat substitutions @ "%i" ->[] substitutions !
  then
  (* %n *)
  substitutions @ "%n" [] not if
    object_name @ substitutions @ "%n" ->[] substitutions !
  then
  (* Now override them with object properties, if present *)
  substitutions @ foreach
    pop
    object @ over getpropstr dup if
      swap substitutions @ swap ->[] substitutions !
    else
      pop pop
    then
  repeat
  (* Return *)
  substitutions @
;

: fix_substitutions[ arr:substitutions ref:object arr:opts -- arr:substitutitons ]
  opts @ "match_name" [] "yes" stringcmp not if
    object @ name var! object_name
    substitutions @ "%n" [] COLOR_STRIP "_" " " subst var! opt_n
    substitutions @ "%d" [] COLOR_STRIP "_" " " subst var! opt_d
    substitutions @ "%i" [] COLOR_STRIP "_" " " subst var! opt_i
    opt_n @ object_name @ stringcmp if
      object_name @ substitutions @ "%n" ->[] substitutions !
    then
    opt_d @ object_name @ stringcmp
    opt_d @ "the_" object_name @ strcat stringcmp
    and if
      object @ player? if "" else "the " then
      object_name @ strcat substitutions @ "%d" ->[] substitutions !
    then
    opt_i @ object_name @ stringcmp
    opt_i @ "a_" object_name @ strcat stringcmp
    opt_i @ "an_" object_name @ strcat stringcmp
    opt_i @ "the_" object_name @ strcat stringcmp
    and and and if
      object @ player? if "" else object_name @ indefinite_article " " strcat then
      object_name @ strcat substitutions @ "%i" ->[] substitutions !
    then
  then
  substitutions @
;

: sub[ str:template ref:object dict:opts -- str:name ]
  object @ get_substitutions object @ opts @ fix_substitutions var! substitutions
  template @ "%" explode_array
  1 array_cut swap array_vals pop var! result
  foreach
    nip
    dup 1 strcut pop "[adinoprs]" smatch if
      1 strcut swap var! code
      substitutions @ "%" code @ strcat []
      code @ code @ toupper = if
        1 strcut swap toupper swap strcat
      then
      swap strcat
    else
      "%" swap strcat
    then
    result @ swap strcat result !
  repeat
  result @
;

(*****************************************************************************)
(*                             M-LIB-GRAMMAR-sub                             *)
(*****************************************************************************)
: M-LIB-GRAMMAR-sub[ str:template ref:object dict:opts -- str:name ]
  (* M1 OK *)
  template @ string? not if "Non-string argument (1)." abort then
  object @ dbref? not if "Non-dbref argument (2)." abort then
  opts @ dictionary? not if "Non-dictionary argument (3)." abort then
  template @ object @ opts @ sub
;
PUBLIC M-LIB-GRAMMAR-sub
$LIBDEF M-LIB-GRAMMAR-sub

: main
  "Library called as command." abort
;
.
c
q
!@register m-lib-grammar.muf=m/lib/grammar
!@set $m/lib/grammar=M2
!@set $m/lib/grammar=L
!@set $m/lib/grammar=S
!@set $m/lib/grammar=H

