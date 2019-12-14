!@program m-cmd-huh.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-cmd-huh.muf - $m/cmd/huh                                                *)
(*   A generic 'huh?' handler for use with Mercury MUF commands.             *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(*****************************************************************************)
(* Revision History:                                                         *)
(*   Version 1.0 -- Daniel Benoy -- November, 2019                           *)
(*     - Original implementation                                             *)
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
$NOTE    Generic 'huh?' handler.
$DOCCMD  @list __PROG__=2-<last header line>

(* Begin configurable options *)

(* Lists of aliases that are active if a prop is set to 'yes' on the player *)
lvar g_prop_aliases
: prop_aliases
  g_prop_aliases @ if g_prop_aliases @ exit then
  {
    (* Normally Built-in MUCK commands -> Mercury MUF commands *)
    (* Some commands are not yet implemented in the Mercury MUF project and are marked as 'TODO' *)
    "cmd_only_overrides" sysparm "yes" stringcmp not if
      "_config/huh/muck_builtin"
      {
                                     "@ac;@act;@acti;@actio=@action"
                                               "@armageddon=!@armageddon"
                                     "@at;@att;@atta;@attac=@attach"
                                     "@bl;@ble;@bles;@bless=!@bless"
                                            "@bo;@boo;@boot=!@boot"
                                       ( "@chl;@chlo;@chloc=@chlock" *TODO* )
                                              ( "@cho;@chow=@chown" *TODO* )
                   ( "@chown_;@chown_l;@chown_lo;@chown_loc=@chown_lock" *TODO* )
                                            "@cl;@clo;@clon=@clone"
                                    ( "@conl;@conlo;@conloc=@conlock" *TODO* )
                           ( "@cont;@conte;@conten;@content=@contents" *TODO )
                                     "@cr;@cre;@crea;@creat=@create"
                                                ( "@credits=@credits" *TODO* )
                                                    "@debug=!@debug"
                  ( "@de;@des;@desc;@descr;@descri;@describ=@describe" *TODO* )
                                                       "@di=@dig"
                                          ( "@do;@doi;@doin=@doing" *TODO* )
                                                ( "@dr;@dro=@drop" *TODO* )
                                            "@du;@dum;@dump=!@dump"
                                                ( "@ed;@edi=@edit" *TODO* )
        ( "@en;@ent;@entr;@entra;@entran;@entranc;@entrance=@entrances" *TODO* )
                             "@ex;@exa;@exam;@exami;@examin=!@examine"
                                                ( "@fa;@fai=@fail" *TODO* )
                                                ( "@fi;@fin=@find" *TODO* )
                                          ( "@fl;@flo;@floc=@flock" *TODO* )
                                          ( "@fo;@for;@forc=@force" *TODO* )
                   ( "@force_;@force_l;@force_lo;@force_loc=@force_lock" *TODO* )
           ( "@i;@id;@ide;@idesc;@idescr;@idescri;@idescrib=@idescribe" *TODO* )
                                             ( "@k;@ki;@kil=@kill" *TODO* )
                                                      "@lin=@link"
                                        ( "@linklo;@linkloc=@linklock" *TODO* )
                                                    ( "@lis=@list" *TODO* )
                                                ( "@lo;@loc=@lock" *TODO* )
                           ( "@mc;@mcp;@mcpe;@mcped;@mcpedi=@mcpedit" *TODO* )
      ( "@mcpp;@mcppr;@mcppro;@mcpprog;@mcpprogr;@mcpprogra=@mcpprogram" *TODO* )
                             "@me;@mem;@memo;@memor;@memory=!@memory"
                    "@mp;@mpi;@mpit;@mpito;@mpitop;@mpitops=!@mpitops"
                    "@mu;@muf;@muft;@mufto;@muftop;@muftops=!@muftops"
                                                ( "@na;@nam=@name" *TODO* )
                                              "@newpassword=!@newpassword"
                                          ( "@od;@odr;@odro=@odrop" *TODO* )
                                          ( "@oe;@oec;@oech=@oecho" *TODO* )
                                          ( "@of;@ofa;@ofai=@ofail" *TODO* )
                                                  "@op;@ope=@open"
                  ( "@os;@osu;@osuc;@osucc;@osucce;@osucces=@osuccess" *TODO* )
                                          ( "@ow;@own;@owne=@owned" *TODO* )
                                    ( "@ownl;@ownlo;@ownloc=@ownlock" *TODO* )
                  ( "@pa;@pas;@pass;@passw;@passwo;@passwor=@password" *TODO* )
                    "@pc;@pcr;@pcre;@pcrea;@pcreat;@pcreate=!@pcreate"
                                          ( "@pe;@pec;@pech=@pecho" *TODO* )
                           ( "@pr;@pro;@prog;@progr;@progra=@program" *TODO* )
                                    ( "@prop;@props;@propse=@propset" *TODO* )
                                                     ( "@ps=@ps" *TODO* )
                      ( "@rea;@read;@readl;@readlo;@readloc=@readlock" *TODO* )
                                 "@rec;@recy;@recyc;@recycl=@recycle"
                                           "@reconfiguressl=!@reconfiguressl"
                      ( "@reg;@regi;@regis;@regist;@registe=@register" *TODO* )
                                         "@rel;@reli;@relin=@relink"
                                                  "@restart=!@restart"
                                                 "@restrict=!@restrict"
                                                   "@sanity=!@sanity"
                                                "@sanchange=!@sanchange"
                                                   "@sanfix=!@sanfix"
                                                     ( "@se=@set" *TODO* )
                                                 "@shutdown=!@shutdown"
                                          ( "@st;@sta;@stat=@stats" *TODO* )
                           ( "@su;@suc;@succ;@succe;@succes=@success" *TODO* )
                                          ( "@sw;@swe;@swee=@sweep" *TODO* )
                  ( "@te;@tel;@tele;@telep;@telepo;@telepor=@teleport" *TODO* )
                                                     "@toad=!@toad"
                                                     "@tops=!@tops"
                                          ( "@tr;@tra;@trac=@trace" *TODO* )
                                            "@tu;@tun;@tune=!@tune"
                        "@unb;@unbl;@unble;@unbles;@unbless=!@unbless"
              "@uncom;@uncomp;@uncompi;@uncompil;@uncompile=!@uncompile"
                                              "@unli;@unlin=@unlink"
                                            ( "@unlo;@unloc=@unlock" *TODO* )
                                     "@us;@usa;@usag;@usage=!@usage"
                        ( "@v;@ve;@ver;@vers;@versi;@versio=@version" *TODO* )
                                                     "@wall=!@wall"
               ( "di;dis;dise;disem;disemb;disemba;disembar=disembark" *TODO* )
                                                  ( "dr;dro=drop" *TODO* )
                              ( "e;ex;exa;exam;exami;examin=examine" *TODO* )
                                                      ( "ge=get" *TODO* )
                                                  ( "gi;giv=give" *TODO* )
                                                  ( "go;got=goto" *TODO* )
                                                   ( "gripe=gripe" *TODO* )
                                                    ( "hand=hand" *TODO* )
                                                "h;hel;help=@help"
                                                      "info=@help"
             ( "i;in;inv;inve;inven;invent;invento;inventor=inventory" *TODO* )
                                             ( "le;lea;leav=leave" *TODO* )
                                                  "l;lo;loo=look"
                                                       "man=@help"
                                                    ( "motd=motd" *TODO* )
                                                       "mpi=@help"
                                                ( "n;ne;new=news" *TODO* )
                                               "pa;pag;page=@page"
                                                    "po;pos=pose"
                                                      ( "pu=put" *TODO* )
                                                    "re;rea=read"
                                                        "sa=say"
                                             ( "sc;sco;scor=score" *TODO* )
                                                  ( "ta;tak=take" *TODO* )
                                             ( "th;thr;thro=throw" *TODO* )
                                     ( "u;up;upt;upti;uptim=uptime" *TODO* )
                                "w;wh;whi;whis;whisp;whispe=whisper"
                                                       "who=@who"
      }list
    then
    (* Common commands found on many MUCKs -> Mercury MUF commands *)
    "_config/huh/muck_common"
    {
      "whereis;where;find=@whereis"
      "whereare;wa=@whereare"
      "whospecies;whospec;ws=@who #room"
      "playeredit;editplayer=@setup"
      "roomedit;editroom=@editobject here"
      "morph=@morph"
      "review=@review"
      "globals=@help globals"
    }list
  }dict dup g_prop_aliases !
;

(* Never alias to one of these commands, but still recommend it *)
lvar g_active_never
: active_never
  g_active_never @ if g_active_never @ exit then
  {
    (* Block built-in commands that disallow FORCE *)
    "!@bless"
     "@bless"
    "!@flock"
     "@flock"
    "!@force_lock"
     "@force_lock"
    "!@ownlock"
     "@ownlock"
    "!@readlock"
     "@readlock"
    "!@sanchange"
     "@sanchange"
    "!@sanfix"
     "@sanfix"
    "!@toad"
     "@toad"
    "!@unbless"
     "@unbless"
  }list dup g_active_never !
;

(* End configurable options *)

(* ------------------------------------------------------------------------- *)

$INCLUDE $m/lib/program
$INCLUDE $m/lib/theme
$INCLUDE $m/lib/notify

$DEF .tell M-LIB-NOTIFY-tell_color
$DEF .err M-LIB-THEME-err

(* ------------------------------------------------------------------------- *)

: M-HELP-desc ( s -- s )
  pop
  "Handle invalid commands."
;
WIZCALL M-HELP-desc

: M-HELP-help ( d -- a )
  "The 'huh?' command is executed automatically when you enter an invalid command. You don't need to use it manually."
;
WIZCALL M-HELP-help

(* ------------------------------------------------------------------------- *)

: aliases_add[ dict:alias_dict str:alias_line -- dict:alias_dict ]
  alias_line @ "=" split
  var! alias_to
  var! aliases_from
  aliases_from @ alias_to @ and not if
    "Invalid alias line: " alias_line @ strcat abort
  then
  alias_dict @
  aliases_from @ ";" explode_array foreach
    nip
    over over [] if
      "Duplicate alias: " swap strcat abort
    then
    alias_to @ -rot ->[]
  repeat
;

: aliases_all[  -- dict:alias_dict ]
  { }dict
  prop_aliases foreach
    var! alias_list
    var! prop
    alias_list @ foreach
      nip
      aliases_add
    repeat
  repeat
;

: aliases_active[  -- dict:alias_dict ]
  { }dict
  prop_aliases foreach
    var! alias_list
    var! prop
    "me" match owner prop @ getpropstr "yes" stringcmp not if
      alias_list @ foreach
        nip
        aliases_add
      repeat
    then
  repeat
  {
    swap foreach
      var! alias_to
      var! alias_from
      { alias_from @ " " split pop }list active_never array_intersect not if
        alias_from @ alias_to @
      then
    repeat
  }dict
;

: alias_match[ str:cmd dict:alias_dict -- str:new_cmd ]
  cmd @ " " split
  var! cmd_args
  var! cmd_cmd
  alias_dict @ cmd_cmd @ [] dup not if pop "" then var! new_cmd
  new_cmd @ if
    (* If there is no space in the new command, then append the user supplied arguments. Otherwise, leave it verbatim. *)
    new_cmd @ " " instr not if
      cmd_args @ if
        new_cmd @ " " strcat cmd_args @ strcat new_cmd !
      then
    then
  then
  new_cmd @
;

: main ( s --  )
  var! huh_cmd
  huh_cmd @ aliases_active alias_match dup if
    "me" match swap force
  else
    pop
    huh_cmd @ aliases_all alias_match dup if
      "Did you mean '" swap strcat "'?" strcat .err .tell
    else
      pop
      "huh_mesg" sysparm .err .tell
    then
  then
;
.
c
q
!@register m-cmd-huh.muf=m/cmd/huh
!@set $m/cmd/huh=M3
!@set $m/cmd/huh=W

