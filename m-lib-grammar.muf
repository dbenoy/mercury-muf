!@program m-lib-grammar.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-grammar.muf - $m/lib/grammar                                        *)
(*   A library for handling natural language strings. This library handles   *)
(*   MGC (Mercury Grammar Code) substitution, which is very similar to and   *)
(*   largely backward compatible with the built in PRONOUN_SUB primitive.    *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* EXAMPLES:                                                                 *)
(*   "%N gets out of %2i and locks %2o behind %o."                           *)
(*   { me @ vehicle @ }list { }dict M-LIB-GRAMMAR-sub                        *)
(*   > "Mercury gets out of a time machine and locks it behind him."         *)
(*                                                                           *)
(*   { "Lions" "tigers" "bears" }list                                        *)
(*   "and" M-LIB-GRAMMAR-oxford_join                                         *)
(*   "! Oh my!" strcat M-LIB-GRAMMAR-oxford_join                             *)
(*   > "Lions, tigers, and bears! Oh my!"                                    *)
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
(*     On any object: Definite article name.                                 *)
(*                                                                           *)
(*     This is the object's name and its definite article (the), if          *)
(*     applicable. Capitalization may be preserved, so capitalize proper     *)
(*     nouns only.                                                           *)
(*                                                                           *)
(*     Example objects:                                                      *)
(*       the golden ticket, the honarary degree, The Crown of England, C3P0. *)
(*     Example rooms:                                                        *)
(*       the dark cave, the evil lair, the hospital, Fluttershy's House      *)
(*                                                                           *)
(*   "%i"                                                                    *)
(*     On any object: Indefinite/definite article name.                      *)
(*                                                                           *)
(*     This is the object's name and its most typical article (a/an/the), if *)
(*     applicable. Capitalization may be preserved, so capitalize proper     *)
(*     nouns only.                                                           *)
(*                                                                           *)
(*     Example objects:                                                      *)
(*       a golden ticket, an honarary degree, The Crown of England, C3P0.    *)
(*     Example rooms:                                                        *)
(*       a dark cave, an evil lair, the hospital, Fluttershy's House         *)
(*                                                                           *)
(*   "%n"                                                                    *)
(*     On any object: The object's name. Like %d and %i this may have an     *)
(*     article on it.                                                        *)
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
(*     On any object: Subjective pronoun. (he/she/it)                        *)
(*                                                                           *)
(*   "%t"                                                                    *)
(*     On any object: (typically a room): The object's prepositional phrase, *)
(*     when treated as a location. (in the king's house, behind the          *)
(*     waterfall, beyond the rainbow, somewhere in the forest, etc.)         *)
(*                                                                           *)
(*   "%v"                                                                    *)
(*     On any object (typically an exit): This object's verb. (eat, go east) *)
(*                                                                           *)
(*   "%w"                                                                    *)
(*     On any object (typically an exit): This object's verb in present      *)
(*     indicative form. (eats, goes east)                                    *)
(*                                                                           *)
(*   "%x"                                                                    *)
(*     On any object (typically an exit): This object's verb in past tense.  *)
(*     (ate, went east)                                                      *)
(*                                                                           *)
(*   "%y"                                                                    *)
(*     On any object (typically an exit): This object's particple verb.      *)
(*     (eating, going east)                                                  *)
(*                                                                           *)
(*   "%z"                                                                    *)
(*     On any object (typically an exit): This object's participle verb in   *)
(*     past tense. (i.e. eaten, gone east)                                   *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-GRAMMAR-sex_category[ s:sex -- s:category ]                       *)
(*     Take a given sex string, and return the closest matching value from   *)
(*     the following list:                                                   *)
(*       "female"                                                            *)
(*       "hermaphrodite"                                                     *)
(*       "male"                                                              *)
(*       "neuter"                                                            *)
(*       "nonbinary"                                                         *)
(*       "unknown"                                                           *)
(*                                                                           *)
(*   M-LIB-GRAMMAR-sub[ s:template Y:objects x:opts -- s:name ]              *)
(*     This works like the PRONOUN_SUB primitive. It takes a string, a list  *)
(*     of objects, and a dictionary list of options, and replaces "%" codes  *)
(*     in the string with the object's pronouns or name. These codes can be  *)
(*     overridden by setting properties on the object. See the PROPERTIES    *)
(*     section above for a list of codes.                                    *)
(*                                                                           *)
(*     The string can also optionally specify a number character between the *)
(*     % and the code character to choose which object from the list to use. *)
(*     The count starts at 1 and if omitted, the first object is used.       *)
(*                                                                           *)
(*     Options:                                                              *)
(*       "name_match" ( Default "YES" )                                      *)
(*         If this is set to "YES" then the %d, %i, and %n values on the     *)
(*         object must match the actual name of the object.                  *)
(*           - If the name has an article in it, it is stripped off before   *)
(*             it's compared to %i and %d.                                   *)
(*           - %i must either match the base name, or start with 'a/an/the'. *)
(*           - %d must either match the base name, or start with 'the'.      *)
(*           - Underscores can be replaced with spaces and vice versa.       *)
(*           - $m/lib/color MCC color codes are ignored when comparing.      *)
(*                                                                           *)
(*       "name_theme" ( Default "NO" )                                       *)
(*         If this is set to "YES" then the %d, %i, and %n substitutions     *)
(*         will use $m/lib/theme modifications, and may be returned with     *)
(*         additional characters and color codes.                            *)
(*                                                                           *)
(*       "color" ( Default "YES" )                                           *)
(*         Determines whether MCC color safe operations should be used. If   *)
(*         enabled, color codes in in the template string will apply, and    *)
(*         any MCC color codes found in the substitutions will be escaped.   *)
(*         If any color codes are added by "name_theme", they will not be    *)
(*         escaped.                                                          *)
(*                                                                           *)
(*   M-LIB-GRAMMAR-oxford_join ( Y s -- s )                                  *)
(*     Similar to ", " array_join, but it inserts a coordinating conjunction *)
(*     and oxford comma as well, if applicable.                              *)
(*                                                                           *)
(*       { "a" } "nor" -> "a"                                                *)
(*       { "a" "b" } "and" -> "a and b"                                      *)
(*       { "a" "b" "c" } "or" -> "a, b, or c"                                *)
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
$NOTE    Natural language strings.
$DOCCMD  @list __PROG__=2-167

(* ====================== BEGIN CONFIGURABLE OPTIONS ====================== *)

(* Comment this out to remove the dependency on $m/lib/color *)
$DEF M_LIB_COLOR

(* Comment this out to remove the dependency on $m/lib/theme *)
$DEF M_LIB_THEME

(* Default pronouns for object types and sexes. Empty string for "Name's" / "Name" *)
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

(* Direct mappings from the sex property values on object into their recognized sex *)
lvar g_sex_table
: sex_table
  g_sex_table @ if g_sex_table @ exit then
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
  }dict dup g_sex_table !
;

(* These tests apply if the sex is not in the above table. They use smatch syntax. *)
(* If it generates contradictory results, 'nonbinary' will be used. *)
lvar g_sex_table2
: sex_table2
  g_sex_table2 @ if g_sex_table2 @ exit then
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
  }list dup g_sex_table2 !
;

(* And finally, if the sex is not in any of the above tables, smatch through this table. *)
(* This table takes the first hit from top to bottom. *)
lvar g_sex_table3
: sex_table3
  g_sex_table2 @ if g_sex_table2 @ exit then
  {
    { "*ish"         "nonbinary" }list
    { "*[ -]like"    "nonbinary" }list
    { "gender*"      "nonbinary" }list
    { "*gender"      "nonbinary" }list
    { "*gendered"    "nonbinary" }list
  }list dup g_sex_table3 !
;

(* ======================= END CONFIGURABLE OPTIONS ======================= *)

$INCLUDE $m/lib/array
$INCLUDE $m/lib/string

$IFDEF M_LIB_COLOR
  $INCLUDE $m/lib/color
$ENDIF

$IFDEF M_LIB_THEME
  $INCLUDE $m/lib/theme
$ENDIF

$PUBDEF :

(* ------------------------------------------------------------------------- *)

: cb_plain_tostring ;
: cb_plain_fromstring ;
: cb_plain_strcut \strcut ;
: cb_plain_strcat \strcat ;
: cb_plain_toupper \toupper ;
: cb_plain_tolower \tolower ;
: cb_plain ( -- a ) { "tostring" 'cb_plain_tostring "fromstring" 'cb_plain_fromstring "strcat" 'cb_plain_strcat "strcut" 'cb_plain_strcut "toupper" 'cb_plain_toupper "tolower" 'cb_plain_tolower }dict ;

$IFDEF M_LIB_COLOR
  : cb_color_tostring M-LIB-COLOR-strip ;
  : cb_color_fromstring M-LIB-COLOR-escape ;
  : cb_color_strcat M-LIB-COLOR-strcat_hard ;
  : cb_color_strcut M-LIB-COLOR-strcut ;
  : cb_color_toupper M-LIB-COLOR-toupper ;
  : cb_color_tolower M-LIB-COLOR-tolower ;
  : cb_color ( -- x ) { "tostring" 'cb_color_tostring "fromstring" 'cb_color_fromstring "strcat" 'cb_color_strcat "strcut" 'cb_color_strcut "toupper" 'cb_color_toupper "tolower" 'cb_color_tolower }dict ;
$ELSE
  $DEF cb_color cb_plain
$ENDIF

: sex_category[ s:sex -- s:category ]
  "" var! category
  var sex_test
  (* Table 1, direct matches *)
  sex_table sex @ [] category !
  category @ if category @ exit then
  (* Table 2, smatch with 'nonbinary' for ambiguous *)
  sex_table2 foreach
    nip
    sex_test !
    sex @ sex_test @ 0 [] smatch if
      category @ if
        sex_test @ 1 [] category @ = not if
          "nonbinary" exit
        then
      else
        sex_test @ 1 [] category !
      then
    then
  repeat
  category @ if category @ exit then
  (* Table 3, smatch, taking the first hit *)
  sex_table3 foreach
    nip
    sex_test !
    sex @ sex_test @ 0 [] smatch if
      sex_test @ 1 [] category !
      break
    then
  repeat
  category @ if category @ exit then
  (* No match *)
  ""
;

: get_sex[ d:object -- s:result ]
  object @ "gender_prop" sysparm getpropstr var! sex
  sex @ sex_category
  dup if exit else pop then
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

: base_names ( d -- Y )
  dup name
  swap exit? if
    ";" explode_array
  else
    1 array_make
  then
  {
    swap
    foreach
      nip
      dup "a[_ ]*" smatch if
        2 strcut swap pop continue
      then
      dup "an[_ ]*" smatch if
        3 strcut swap pop continue
      then
      dup "the[_ ]*" smatch if
        4 strcut swap pop continue
      then
    repeat
  }list
;

: base_name ( d -- s )
  base_names 0 []
;

: caps_strcat ( s s -- s )
  dup 1 strcut pop
  dup toupper = if 
    swap 1 strcut swap toupper swap strcat
  else
    swap tolower swap
  then
;

: strip_article ( s -- s )
  dup "a[_ ]*" smatch if
    2 strcut swap pop
  else dup "an[_ ]*" smatch if
    3 strcut swap pop
  else dup "the[_ ]*" smatch if
    4 strcut swap pop
  then then then
;

(* Checks whether an object's name should be assumed a proper noun *)
: proper_noun ( d -- i )
  dup thing? over "ZOMBIE" flag? not and swap program? or not
;

: default_n[ d:object -- s:result ]
  object @ name
  object @ exit? if ";" split pop then
  object @ proper_noun not if
    tolower
  then
;

: default_d[ d:object -- s:result ]
  object @ name
  object @ exit? if ";" split pop then
  object @ proper_noun not if
    tolower
    strip_article
    "the " swap strcat
  then
;

: default_i[ d:object -- s:result ]
  object @ name "the[_ ]*" smatch if
    object @ default_d exit
  then
  object @ name
  object @ exit? if ";" split pop then
  object @ proper_noun not if
    tolower
    strip_article
    dup 1 strcut pop "[aeiou]" smatch if
      "an " swap strcat
    else
      "a " swap strcat
    then
  then
;

: default_a ( d -- s )
  default_n "'s" strcat
;

: default_o ( d -- s )
  default_n
;

: default_p ( d -- s )
  default_n "'s" strcat
;

: default_r ( d -- s )
  default_n
;

: default_s ( d -- s )
  default_n
;

: default_v ( d -- s )
  dup default_n
  swap exit? if
    tolower
  then
;

: default_w ( d -- s )
  default_v
  dup strlen -- strcut
  dup "y" stringcmp not if
    pop "ie" strcat
  else
    strcat
  then
  "s" strcat
;

: default_x ( d -- s )
  default_v
  dup strlen -- strcut
  dup "e" stringcmp not if
    pop
  else dup "y" stringcmp not if
    pop "i" strcat
  else
    strcat
  then then
  "ed" strcat
;

: default_y ( d -- s )
  default_v
  dup strlen -- strcut
  dup "e" stringcmp not if
    pop
  else
    strcat
  then
  "ing" strcat
;

: default_z ( d -- s )
  default_v
  dup strlen -- strcut
  dup "e" stringcmp not if
    pop
  else dup "y" stringcmp not if
    pop "i" strcat
  else
    strcat
  then then
  "ed" strcat
;

: default_t ( d -- s )
  dup player? if
    "in " swap default_n strcat "'s pocket" strcat 
  else
    "in " swap default_i strcat
  then
;

: get_substitutions[ d:object -- x:result ]
  (* Grab the default values *)
  pronoun_defaults object @ get_sex [] var! substitutions
  (* Now override them with object properties, if present *)
  { "%a" "%o" "%p" "%r" "%s" "%d" "%i" "%n" "%v" "%w" "%x" "%y" "%z" "%t" }list foreach
    nip
    object @ over getpropstr dup if
      swap substitutions @ swap ->[] substitutions !
    else
      pop pop
    then
  repeat
  (* Set fallback defaults *)
  (* %a *)
  substitutions @ "%a" [] not if
    object @ default_a substitutions @ "%a" ->[] substitutions !
  then
  (* %o *)
  substitutions @ "%o" [] not if
    object @ default_o substitutions @ "%o" ->[] substitutions !
  then
  (* %p *)
  substitutions @ "%p" [] not if
    object @ default_p substitutions @ "%p" ->[] substitutions !
  then
  (* %r *)
  substitutions @ "%r" [] not if
    object @ default_r substitutions @ "%r" ->[] substitutions !
  then
  (* %s *)
  substitutions @ "%s" [] not if
    object @ default_s substitutions @ "%s" ->[] substitutions !
  then
  (* %d *)
  substitutions @ "%d" [] not if
    object @ default_d substitutions @ "%d" ->[] substitutions !
  then
  (* %i *)
  substitutions @ "%i" [] not if
    object @ default_i substitutions @ "%i" ->[] substitutions !
  then
  (* %n *)
  substitutions @ "%n" [] not if
    object @ default_n substitutions @ "%n" ->[] substitutions !
  then
  (* %v *)
  substitutions @ "%v" [] not if
    object @ default_v substitutions @ "%v" ->[] substitutions !
  then
  (* %w *)
  substitutions @ "%w" [] not if
    object @ default_w substitutions @ "%w" ->[] substitutions !
  then
  (* %x *)
  substitutions @ "%x" [] not if
    object @ default_x substitutions @ "%x" ->[] substitutions !
  then
  (* %y *)
  substitutions @ "%y" [] not if
    object @ default_y substitutions @ "%y" ->[] substitutions !
  then
  (* %z *)
  substitutions @ "%z" [] not if
    object @ default_z substitutions @ "%z" ->[] substitutions !
  then
  (* %t *)
  substitutions @ "%t" [] not if
    object @ default_t substitutions @ "%t" ->[] substitutions !
  then
  (* Return *)
  substitutions @
;

: sub_fix[ Y:substitutions d:object x:opts -- Y:substitutitons ]
  opts @ "name_match" [] dup not if pop "" then "no" stringcmp if
    object @ name "_" " " subst tolower var! object_name
    object @ base_names { swap foreach nip "_" " " subst tolower repeat }list var! object_base_names
    substitutions @ "%n" [] "_" " " subst tolower var! opt_n
    substitutions @ "%d" [] "_" " " subst tolower var! opt_d
    substitutions @ "%i" [] "_" " " subst tolower var! opt_i
    opt_n @ object_name @ stringcmp if
      object @ default_n substitutions @ "%n" ->[] substitutions !
    then
    opt_d @ object_base_names @ M-LIB-ARRAY-hasval not
    opt_d @ object_base_names @ { swap foreach nip "the_" swap strcat repeat }list M-LIB-ARRAY-hasval not
    and if
      object @ default_d substitutions @ "%d" ->[] substitutions !
    then
    opt_i @ object_base_names @ M-LIB-ARRAY-hasval not
    opt_i @ object_base_names @ { swap foreach nip "a_" swap strcat repeat }list M-LIB-ARRAY-hasval not
    opt_i @ object_base_names @ { swap foreach nip "an_" swap strcat repeat }list M-LIB-ARRAY-hasval not
    opt_i @ object_base_names @ { swap foreach nip "the_" swap strcat repeat }list M-LIB-ARRAY-hasval not
    and and and if
      object @ default_i substitutions @ "%i" ->[] substitutions !
    then
  then
$IFDEF M_LIB_COLOR
  opts @ "color" [] dup not if pop "" then "no" stringcmp if
    substitutions @ foreach
      M-LIB-COLOR-escape
      substitutions @ rot ->[] substitutions !
    repeat
  then
$ENDIF
$IFDEF M_LIB_THEME
  opts @ "name_theme" [] dup not if pop "" then "yes" stringcmp not if
    substitutions @ "%n" [] if
      substitutions @ "%n" []
      1 array_make object @ M-LIB-THEME-format_obj_type M-LIB-THEME-format
      substitutions @ "%n" ->[] substitutions !
    then
    substitutions @ "%d" [] if
      substitutions @ "%d" []
      dup "the[_ ]*" smatch if
        4 strcut
      else
        "" swap
      then
      1 array_make object @ M-LIB-THEME-format_obj_type M-LIB-THEME-format
      strcat
      substitutions @ "%d" ->[] substitutions !
    then
    substitutions @ "%i" [] if
      substitutions @ "%i" []
      dup "the[_ ]*" smatch if
        4 strcut
      else dup "an[_ ]*" smatch if
        3 strcut
      else dup "a[_ ]*" smatch if
        2 strcut
      else
        "" swap
      then then then
      1 array_make object @ M-LIB-THEME-format_obj_type M-LIB-THEME-format
      strcat
      substitutions @ "%i" ->[] substitutions !
    then
  then
$ENDIF
  substitutions @
;

: sub_code[ s:codestr Y:substitutions x:cb -- s:result ]
  codestr @ cb @ M-LIB-STRING-tostring_cb "%([0-9]?)([adinoprstvwxyz])" REG_ICASE regexp pop array_vals pop rot pop var! code var! obj_id
  obj_id @ if
    obj_id @ atoi obj_id !
  else
    1 obj_id !
  then
  obj_id @ substitutions @ array_count > if
    codestr @ exit
  then
  substitutions @ obj_id @ -- [] "%" code @ strcat []
  dup not if
    pop
    codestr @ exit
  then
  code @ code @ toupper = if
     1 cb @ M-LIB-STRING-strcut_cb swap toupper swap strcat
  then
;

: sub[ s:template Y:objects x:opts -- s:name ]
  var cb
  opts @ "color" [] dup not if pop "" then "yes" stringcmp not if
    cb_color cb !
  else
    cb_plain cb !
  then
  { }list var! substitutions
  objects @ foreach
    nip
    var! object
    object @ get_substitutions object @ opts @ sub_fix substitutions @ []<- substitutions !
  repeat
  template @ "%[0-9]?[adinoprstvwxyz]" REG_ICASE cb @ M-LIB-STRING-regslice_cb
  1 array_cut begin
    dup not if pop break then
    2 array_cut swap array_vals pop
    (code, plain)
    swap cb @ M-LIB-STRING-tostring_cb substitutions @ cb @ sub_code
    4 rotate []<- []<-
    swap
  repeat
  cb @ M-LIB-STRING-array_interpret_cb
;

(*****************************************************************************)
(*                        M-LIB-GRAMMAR-sex_category                         *)
(*****************************************************************************)
: M-LIB-GRAMMAR-sex_category[ s:sex -- s:category ]
  (* Permissions inherited *)
  sex @ string? not if "Non-string argument (1)." abort then
  sex @ sex_category
  dup if exit else pop then
  "unknown"
;
PUBLIC M-LIB-GRAMMAR-sex_category
$LIBDEF M-LIB-GRAMMAR-sex_category

(*****************************************************************************)
(*                         M-LIB-GRAMMAR-oxford_join                         *)
(*****************************************************************************)
: M-LIB-GRAMMAR-oxford_join ( Y s -- s )
  (* Permissions inherited *)
  "Ys" checkargs
  swap dup array_count 1 > if
    dup array_count 2 - array_cut
    array_vals pop
    4 rotate " " strcat
    4 pick if
      ", " swap strcat
    else
      " " swap strcat
    then
    swap strcat strcat
    swap array_appenditem
  else
    swap pop
  then
  ", " array_join
;
PUBLIC M-LIB-GRAMMAR-oxford_join
$LIBDEF M-LIB-GRAMMAR-oxford_join

(*****************************************************************************)
(*                             M-LIB-GRAMMAR-sub                             *)
(*****************************************************************************)
: M-LIB-GRAMMAR-sub[ s:template Y:objects x:opts -- s:name ]
  (* Permissions inherited *)
  template @ string? not if "Non-string argument (1)." abort then
  objects @ array? not if "Non-array argument (2)." abort then
  objects @ dictionary? if "Non-list argument (2)." abort then
  objects @ array_count not if "Empty array (2)." abort then
  objects @ foreach nip dbref? not if "Array of dbrefs expected (2)." abort then repeat
  opts @ dictionary? not if "Non-dictionary argument (3)." abort then
  template @ objects @ opts @ sub
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

