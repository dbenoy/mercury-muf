!@program m-lib-color.muf
1 99999 d
i
$PRAGMA comment_recurse
(*****************************************************************************)
(* m-lib-color - $m/lib/color                                                *)
(*   A text color library that converts HTML style color codes into color    *)
(*   text output depending on your terminal type. For example:               *)
(*                                                                           *)
(* "#MCC-F-7FFF00Chartreuse!" "MCC" "ANSI-24BIT" M-LIB-COLOR-Transcode .tell *)
(* "#MCC-F-7FFF00Charclose!" "MCC" "ANSI-8BIT" M-LIB-COLOR-Transcode .tell   *)
(* "#MCC-F-7FFF00Green :/" "MCC" "ANSI-4BIT-VGA" M-LIB-COLOR-Transcode .tell *)
(*                                                                           *)
(*   GitHub: https://github.com/dbenoy/mercury-muf (See for install info)    *)
(*                                                                           *)
(* PUBLIC ROUTINES:                                                          *)
(*   M-LIB-COLOR-transcode[ str:source_string str:from_type str:to_type      *)
(*                          -- str:result_string ]                           *)
(*     Converts from one encoding type to another. At present, you can only  *)
(*     convert from MCC to ANSI or NOCOLOR. If a color can't be precicely    *)
(*     produced for a given type, it will be approximated by trying to pick  *)
(*     the closest available color. See ENCODING TYPES for more details.     *)
(*                                                                           *)
(*     Use 'AUTO' for to_type to use the value from M-LIB-COLOR-encoding_get *)
(*     on the current player.                                                *)
(*                                                                           *)
(*   M-LIB-COLOR-strcut[ str:source_string int:split_point str:type          *)
(*                      -- str:string1 str:string2 ]                         *)
(*     Works like the STRCUT primitive, but it ignores color codes when      *)
(*     finding its cut position. It also ensures the foreground and          *)
(*     background color are set at the beginning of the second string to     *)
(*     match what it was at the end of the first string. Currently only the  *)
(*     MCC encoding type is supported.                                       *)
(*                                                                           *)
(*   M-LIB-COLOR-testpattern[ str:ansi_type -- arr:strings ]                 *)
(*     Returns an array of strings formatted for the given ANSI encoding     *)
(*     type that demonstrate the ANSI mode. This is useful to help players   *)
(*     determine which ANSI mode they should be using to match their client. *)
(*                                                                           *)
(*   M-LIB-COLOR-encoding_default[ -- str:type ]                             *)
(*     Returns the default encoding.                                         *)
(*                                                                           *)
(*   M-LIB-COLOR-encoding_get[ ref:object -- str:type ]                      *)
(*     Get a player's currently set ANSI encoding type. This value is used   *)
(*     for the 'AUTO' encoding type, and represents the player's preferred   *)
(*     encoding. If a player has no COLOR flag, then this will return        *)
(*     'NOCOLOR'. At present, this will only allow you to use ANSI           *)
(*     encodings. If no encoding is set, the default encoding is returned.   *)
(*                                                                           *)
(*   M-LIB-COLOR-encoding_set[ ref:object str:type -- ]                      *)
(*     Alter a player's currently set ANSI encoding type. This value is used *)
(*     by some convenience '.color-' convenience calls, and represents the   *)
(*     player's preferred encoding. If a player has no COLOR flag, then this *)
(*     will return 'NOCOLOR'. At present, this will only allow you to use    *)
(*     ANSI encodings.                                                       *)
(*                                                                           *)
(*   M-LIB-COLOR-encoding_player_valid[ -- list:options ]                    *)
(*     Returns a list of valid encodings for with M-LIB-COLOR-encoding_set   *)
(*     in order of quality from best to worst.                               *)
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
(*   Also, the color space conversion can be a (relatively) slow operation,  *)
(*   so for large graphics, unless it's important to you, you may want to    *)
(*   limit your color selections to ones from the XTERM256 palette. Colors   *)
(*   that are re-used during the same program run will be converted from     *)
(*   cache, and will also be fast.                                           *)
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
(*   XTERM256 Palette:                                                       *)
(*   16  Black             #MCC-F-000000                                     *)
(*   17  NavyBlue          #MCC-F-00005F                                     *)
(*   18  DarkBlue          #MCC-F-000087                                     *)
(*   19  Blue3             #MCC-F-0000AF                                     *)
(*   20  Blue3             #MCC-F-0000D7                                     *)
(*   21  Blue1             #MCC-F-0000FF                                     *)
(*   22  DarkGreen         #MCC-F-005F00                                     *)
(*   23  DeepSkyBlue4      #MCC-F-005F5F                                     *)
(*   24  DeepSkyBlue4      #MCC-F-005F87                                     *)
(*   25  DeepSkyBlue4      #MCC-F-005FAF                                     *)
(*   26  DodgerBlue3       #MCC-F-005FD7                                     *)
(*   27  DodgerBlue2       #MCC-F-005FFF                                     *)
(*   28  Green4            #MCC-F-008700                                     *)
(*   29  SpringGreen4      #MCC-F-00875F                                     *)
(*   30  Turquoise4        #MCC-F-008787                                     *)
(*   31  DeepSkyBlue3      #MCC-F-0087AF                                     *)
(*   32  DeepSkyBlue3      #MCC-F-0087D7                                     *)
(*   33  DodgerBlue1       #MCC-F-0087FF                                     *)
(*   34  Green3            #MCC-F-00AF00                                     *)
(*   35  SpringGreen3      #MCC-F-00AF5F                                     *)
(*   36  DarkCyan          #MCC-F-00AF87                                     *)
(*   37  LightSeaGreen     #MCC-F-00AFAF                                     *)
(*   38  DeepSkyBlue2      #MCC-F-00AFD7                                     *)
(*   39  DeepSkyBlue1      #MCC-F-00AFFF                                     *)
(*   40  Green3            #MCC-F-00D700                                     *)
(*   41  SpringGreen3      #MCC-F-00D75F                                     *)
(*   42  SpringGreen2      #MCC-F-00D787                                     *)
(*   43  Cyan3             #MCC-F-00D7AF                                     *)
(*   44  DarkTurquoise     #MCC-F-00D7D7                                     *)
(*   45  Turquoise2        #MCC-F-00D7FF                                     *)
(*   46  Green1            #MCC-F-00FF00                                     *)
(*   47  SpringGreen2      #MCC-F-00FF5F                                     *)
(*   48  SpringGreen1      #MCC-F-00FF87                                     *)
(*   49  MediumSpringGreen #MCC-F-00FFAF                                     *)
(*   50  Cyan2             #MCC-F-00FFD7                                     *)
(*   51  Cyan1             #MCC-F-00FFFF                                     *)
(*   52  DarkRed           #MCC-F-5F0000                                     *)
(*   53  DeepPink4         #MCC-F-5F005F                                     *)
(*   54  Purple4           #MCC-F-5F0087                                     *)
(*   55  Purple4           #MCC-F-5F00AF                                     *)
(*   56  Purple3           #MCC-F-5F00D7                                     *)
(*   57  BlueViolet        #MCC-F-5F00FF                                     *)
(*   58  Orange4           #MCC-F-5F5F00                                     *)
(*   59  Grey37            #MCC-F-5F5F5F                                     *)
(*   60  MediumPurple4     #MCC-F-5F5F87                                     *)
(*   61  SlateBlue3        #MCC-F-5F5FAF                                     *)
(*   62  SlateBlue3        #MCC-F-5F5FD7                                     *)
(*   63  RoyalBlue1        #MCC-F-5F5FFF                                     *)
(*   64  Chartreuse4       #MCC-F-5F8700                                     *)
(*   65  DarkSeaGreen4     #MCC-F-5F875F                                     *)
(*   66  PaleTurquoise4    #MCC-F-5F8787                                     *)
(*   67  SteelBlue         #MCC-F-5F87AF                                     *)
(*   68  SteelBlue3        #MCC-F-5F87D7                                     *)
(*   69  CornflowerBlue    #MCC-F-5F87FF                                     *)
(*   70  Chartreuse3       #MCC-F-5FAF00                                     *)
(*   71  DarkSeaGreen4     #MCC-F-5FAF5F                                     *)
(*   72  CadetBlue         #MCC-F-5FAF87                                     *)
(*   73  CadetBlue         #MCC-F-5FAFAF                                     *)
(*   74  SkyBlue3          #MCC-F-5FAFD7                                     *)
(*   75  SteelBlue1        #MCC-F-5FAFFF                                     *)
(*   76  Chartreuse3       #MCC-F-5FD700                                     *)
(*   77  PaleGreen3        #MCC-F-5FD75F                                     *)
(*   78  SeaGreen3         #MCC-F-5FD787                                     *)
(*   79  Aquamarine3       #MCC-F-5FD7AF                                     *)
(*   80  MediumTurquoise   #MCC-F-5FD7D7                                     *)
(*   81  SteelBlue1        #MCC-F-5FD7FF                                     *)
(*   82  Chartreuse2       #MCC-F-5FFF00                                     *)
(*   83  SeaGreen2         #MCC-F-5FFF5F                                     *)
(*   84  SeaGreen1         #MCC-F-5FFF87                                     *)
(*   85  SeaGreen1         #MCC-F-5FFFAF                                     *)
(*   86  Aquamarine1       #MCC-F-5FFFD7                                     *)
(*   87  DarkSlateGray2    #MCC-F-5FFFFF                                     *)
(*   88  DarkRed           #MCC-F-870000                                     *)
(*   89  DeepPink4         #MCC-F-87005F                                     *)
(*   90  DarkMagenta       #MCC-F-870087                                     *)
(*   91  DarkMagenta       #MCC-F-8700AF                                     *)
(*   92  DarkViolet        #MCC-F-8700D7                                     *)
(*   93  Purple            #MCC-F-8700FF                                     *)
(*   94  Orange4           #MCC-F-875F00                                     *)
(*   95  LightPink4        #MCC-F-875F5F                                     *)
(*   96  Plum4             #MCC-F-875F87                                     *)
(*   97  MediumPurple3     #MCC-F-875FAF                                     *)
(*   98  MediumPurple3     #MCC-F-875FD7                                     *)
(*   99  SlateBlue1        #MCC-F-875FFF                                     *)
(*   100 Yellow4           #MCC-F-878700                                     *)
(*   101 Wheat4            #MCC-F-87875F                                     *)
(*   102 Grey53            #MCC-F-878787                                     *)
(*   103 LightSlateGrey    #MCC-F-8787AF                                     *)
(*   104 MediumPurple      #MCC-F-8787D7                                     *)
(*   105 LightSlateBlue    #MCC-F-8787FF                                     *)
(*   106 Yellow4           #MCC-F-87AF00                                     *)
(*   107 DarkOliveGreen3   #MCC-F-87AF5F                                     *)
(*   108 DarkSeaGreen      #MCC-F-87AF87                                     *)
(*   109 LightSkyBlue3     #MCC-F-87AFAF                                     *)
(*   110 LightSkyBlue3     #MCC-F-87AFD7                                     *)
(*   111 SkyBlue2          #MCC-F-87AFFF                                     *)
(*   112 Chartreuse2       #MCC-F-87D700                                     *)
(*   113 DarkOliveGreen3   #MCC-F-87D75F                                     *)
(*   114 PaleGreen3        #MCC-F-87D787                                     *)
(*   115 DarkSeaGreen3     #MCC-F-87D7AF                                     *)
(*   116 DarkSlateGray3    #MCC-F-87D7D7                                     *)
(*   117 SkyBlue1          #MCC-F-87D7FF                                     *)
(*   118 Chartreuse1       #MCC-F-87FF00                                     *)
(*   119 LightGreen        #MCC-F-87FF5F                                     *)
(*   120 LightGreen        #MCC-F-87FF87                                     *)
(*   121 PaleGreen1        #MCC-F-87FFAF                                     *)
(*   122 Aquamarine1       #MCC-F-87FFD7                                     *)
(*   123 DarkSlateGray1    #MCC-F-87FFFF                                     *)
(*   124 Red3              #MCC-F-AF0000                                     *)
(*   125 DeepPink4         #MCC-F-AF005F                                     *)
(*   126 MediumVioletRed   #MCC-F-AF0087                                     *)
(*   127 Magenta3          #MCC-F-AF00AF                                     *)
(*   128 DarkViolet        #MCC-F-AF00D7                                     *)
(*   129 Purple            #MCC-F-AF00FF                                     *)
(*   130 DarkOrange3       #MCC-F-AF5F00                                     *)
(*   131 IndianRed         #MCC-F-AF5F5F                                     *)
(*   132 HotPink3          #MCC-F-AF5F87                                     *)
(*   133 MediumOrchid3     #MCC-F-AF5FAF                                     *)
(*   134 MediumOrchid      #MCC-F-AF5FD7                                     *)
(*   135 MediumPurple2     #MCC-F-AF5FFF                                     *)
(*   136 DarkGoldenrod     #MCC-F-AF8700                                     *)
(*   137 LightSalmon3      #MCC-F-AF875F                                     *)
(*   138 RosyBrown         #MCC-F-AF8787                                     *)
(*   139 Grey63            #MCC-F-AF87AF                                     *)
(*   140 MediumPurple2     #MCC-F-AF87D7                                     *)
(*   141 MediumPurple1     #MCC-F-AF87FF                                     *)
(*   142 Gold3             #MCC-F-AFAF00                                     *)
(*   143 DarkKhaki         #MCC-F-AFAF5F                                     *)
(*   144 NavajoWhite3      #MCC-F-AFAF87                                     *)
(*   145 Grey69            #MCC-F-AFAFAF                                     *)
(*   146 LightSteelBlue3   #MCC-F-AFAFD7                                     *)
(*   147 LightSteelBlue    #MCC-F-AFAFFF                                     *)
(*   148 Yellow3           #MCC-F-AFD700                                     *)
(*   149 DarkOliveGreen3   #MCC-F-AFD75F                                     *)
(*   150 DarkSeaGreen3     #MCC-F-AFD787                                     *)
(*   151 DarkSeaGreen2     #MCC-F-AFD7AF                                     *)
(*   152 LightCyan3        #MCC-F-AFD7D7                                     *)
(*   153 LightSkyBlue1     #MCC-F-AFD7FF                                     *)
(*   154 GreenYellow       #MCC-F-AFFF00                                     *)
(*   155 DarkOliveGreen2   #MCC-F-AFFF5F                                     *)
(*   156 PaleGreen1        #MCC-F-AFFF87                                     *)
(*   157 DarkSeaGreen2     #MCC-F-AFFFAF                                     *)
(*   158 DarkSeaGreen1     #MCC-F-AFFFD7                                     *)
(*   159 PaleTurquoise1    #MCC-F-AFFFFF                                     *)
(*   160 Red3              #MCC-F-D70000                                     *)
(*   161 DeepPink3         #MCC-F-D7005F                                     *)
(*   162 DeepPink3         #MCC-F-D70087                                     *)
(*   163 Magenta3          #MCC-F-D700AF                                     *)
(*   164 Magenta3          #MCC-F-D700D7                                     *)
(*   165 Magenta2          #MCC-F-D700FF                                     *)
(*   166 DarkOrange3       #MCC-F-D75F00                                     *)
(*   167 IndianRed         #MCC-F-D75F5F                                     *)
(*   168 HotPink3          #MCC-F-D75F87                                     *)
(*   169 HotPink2          #MCC-F-D75FAF                                     *)
(*   170 Orchid            #MCC-F-D75FD7                                     *)
(*   171 MediumOrchid1     #MCC-F-D75FFF                                     *)
(*   172 Orange3           #MCC-F-D78700                                     *)
(*   173 LightSalmon3      #MCC-F-D7875F                                     *)
(*   174 LightPink3        #MCC-F-D78787                                     *)
(*   175 Pink3             #MCC-F-D787AF                                     *)
(*   176 Plum3             #MCC-F-D787D7                                     *)
(*   177 Violet            #MCC-F-D787FF                                     *)
(*   178 Gold3             #MCC-F-D7AF00                                     *)
(*   179 LightGoldenrod3   #MCC-F-D7AF5F                                     *)
(*   180 Tan               #MCC-F-D7AF87                                     *)
(*   181 MistyRose3        #MCC-F-D7AFAF                                     *)
(*   182 Thistle3          #MCC-F-D7AFD7                                     *)
(*   183 Plum2             #MCC-F-D7AFFF                                     *)
(*   184 Yellow3           #MCC-F-D7D700                                     *)
(*   185 Khaki3            #MCC-F-D7D75F                                     *)
(*   186 LightGoldenrod2   #MCC-F-D7D787                                     *)
(*   187 LightYellow3      #MCC-F-D7D7AF                                     *)
(*   188 Grey84            #MCC-F-D7D7D7                                     *)
(*   189 LightSteelBlue1   #MCC-F-D7D7FF                                     *)
(*   190 Yellow2           #MCC-F-D7FF00                                     *)
(*   191 DarkOliveGreen1   #MCC-F-D7FF5F                                     *)
(*   192 DarkOliveGreen1   #MCC-F-D7FF87                                     *)
(*   193 DarkSeaGreen1     #MCC-F-D7FFAF                                     *)
(*   194 Honeydew2         #MCC-F-D7FFD7                                     *)
(*   195 LightCyan1        #MCC-F-D7FFFF                                     *)
(*   196 Red1              #MCC-F-FF0000                                     *)
(*   197 DeepPink2         #MCC-F-FF005F                                     *)
(*   198 DeepPink1         #MCC-F-FF0087                                     *)
(*   199 DeepPink1         #MCC-F-FF00AF                                     *)
(*   200 Magenta2          #MCC-F-FF00D7                                     *)
(*   201 Magenta1          #MCC-F-FF00FF                                     *)
(*   202 OrangeRed1        #MCC-F-FF5F00                                     *)
(*   203 IndianRed1        #MCC-F-FF5F5F                                     *)
(*   204 IndianRed1        #MCC-F-FF5F87                                     *)
(*   205 HotPink           #MCC-F-FF5FAF                                     *)
(*   206 HotPink           #MCC-F-FF5FD7                                     *)
(*   207 MediumOrchid1     #MCC-F-FF5FFF                                     *)
(*   208 DarkOrange        #MCC-F-FF8700                                     *)
(*   209 Salmon1           #MCC-F-FF875F                                     *)
(*   210 LightCoral        #MCC-F-FF8787                                     *)
(*   211 PaleVioletRed1    #MCC-F-FF87AF                                     *)
(*   212 Orchid2           #MCC-F-FF87D7                                     *)
(*   213 Orchid1           #MCC-F-FF87FF                                     *)
(*   214 Orange1           #MCC-F-FFAF00                                     *)
(*   215 SandyBrown        #MCC-F-FFAF5F                                     *)
(*   216 LightSalmon1      #MCC-F-FFAF87                                     *)
(*   217 LightPink1        #MCC-F-FFAFAF                                     *)
(*   218 Pink1             #MCC-F-FFAFD7                                     *)
(*   219 Plum1             #MCC-F-FFAFFF                                     *)
(*   220 Gold1             #MCC-F-FFD700                                     *)
(*   221 LightGoldenrod2   #MCC-F-FFD75F                                     *)
(*   222 LightGoldenrod2   #MCC-F-FFD787                                     *)
(*   223 NavajoWhite1      #MCC-F-FFD7AF                                     *)
(*   224 MistyRose1        #MCC-F-FFD7D7                                     *)
(*   225 Thistle1          #MCC-F-FFD7FF                                     *)
(*   226 Yellow1           #MCC-F-FFFF00                                     *)
(*   227 LightGoldenrod1   #MCC-F-FFFF5F                                     *)
(*   228 Khaki1            #MCC-F-FFFF87                                     *)
(*   229 Wheat1            #MCC-F-FFFFAF                                     *)
(*   230 Cornsilk1         #MCC-F-FFFFD7                                     *)
(*   231 Grey100           #MCC-F-FFFFFF                                     *)
(*   232 Grey3             #MCC-F-080808                                     *)
(*   233 Grey7             #MCC-F-121212                                     *)
(*   234 Grey11            #MCC-F-1C1C1C                                     *)
(*   235 Grey15            #MCC-F-262626                                     *)
(*   236 Grey19            #MCC-F-303030                                     *)
(*   237 Grey23            #MCC-F-3A3A3A                                     *)
(*   238 Grey27            #MCC-F-444444                                     *)
(*   239 Grey30            #MCC-F-4E4E4E                                     *)
(*   240 Grey35            #MCC-F-585858                                     *)
(*   241 Grey39            #MCC-F-626262                                     *)
(*   242 Grey42            #MCC-F-6C6C6C                                     *)
(*   243 Grey46            #MCC-F-767676                                     *)
(*   244 Grey50            #MCC-F-808080                                     *)
(*   245 Grey54            #MCC-F-8A8A8A                                     *)
(*   246 Grey58            #MCC-F-949494                                     *)
(*   247 Grey62            #MCC-F-9E9E9E                                     *)
(*   248 Grey66            #MCC-F-A8A8A8                                     *)
(*   249 Grey70            #MCC-F-B2B2B2                                     *)
(*   250 Grey74            #MCC-F-BCBCBC                                     *)
(*   251 Grey78            #MCC-F-C6C6C6                                     *)
(*   252 Grey82            #MCC-F-D0D0D0                                     *)
(*   253 Grey85            #MCC-F-DADADA                                     *)
(*   254 Grey89            #MCC-F-E4E4E4                                     *)
(*   255 Grey93            #MCC-F-EEEEEE                                     *)
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
$DOCCMD  @list __PROG__=2-443

(* Begin configurable options *)

$def ENCODING_DEFAULT "ANSI-8BIT"
$def ENCODING_PROP "_config/color/type"
 
(* End configurable options *)

(* TODO: A check to see if colors can be exactly represented on a given ANSI type? *)
(* TODO: More 'color code' encodings for compatibility with other MUCK software. *)

$PUBDEF :

$DEF NEEDSM2 trig caller = not caller mlevel 2 < and if "Requires MUCKER level 2 or above." abort then
$DEF NEEDSM3 trig caller = not caller mlevel 3 < and if "Requires MUCKER level 3 or above." abort then
$DEF NEEDSM4 trig caller = not caller "WIZARD" flag? not and if "Requires MUCKER level 4 or above." abort then

$DEF .version prog "_version" getpropstr begin dup strlen 1 - over ".0" rinstr = not while dup ".0" instr while "." ".0" subst repeat
$DEF .author prog "_author" getpropstr

(* ------------------------------------------------------------------------ *)

$def SUPPORTED_TYPES_ANSI { "ANSI-24BIT" "ANSI-8BIT" "ANSI-4BIT-VGA" "ANSI-4BIT-XTERM" "ANSI-3BIT-VGA" "ANSI-3BIT-XTERM" }list
$def SUPPORTED_TYPES_CODE { "MCC" "NOCOLOR" }list
$def SUPPORTED_TYPES SUPPORTED_TYPES_ANSI SUPPORTED_TYPES_CODE array_union

(* 8-BIT ANSI PALLATTE TABLE - RGB *)
lvar g_ansi_table_8bit_rgb
: ansi_table_8bit_rgb ( -- a )
  g_ansi_table_8bit_rgb @ not if
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
    }dict g_ansi_table_8bit_rgb !
  then
  g_ansi_table_8bit_rgb @
;

(* 4-BIT VGA ANSI PALLATTE TABLE - RGB *)
lvar g_ansi_table_4bit_vga_rgb
: ansi_table_4bit_vga_rgb ( -- a )
  g_ansi_table_4bit_vga_rgb @ not if
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
    }dict g_ansi_table_4bit_vga_rgb !
  then
  g_ansi_table_4bit_vga_rgb @
;

(* 4-BIT XTERM ANSI PALLATTE TABLE - RGB *)
lvar g_ansi_table_4bit_xterm_rgb
: ansi_table_4bit_xterm_rgb ( -- a )
  g_ansi_table_4bit_xterm_rgb @ not if
    {
      30 { 0 0 0 }list
      31 { 128 0 0 }list
      32 { 0 128 0 }list
      33 { 128 128 0 }list
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
    }dict g_ansi_table_4bit_xterm_rgb !
  then
  g_ansi_table_4bit_xterm_rgb @
;

(* ------------------------------------------------------------------------ *)

(* Convert a single hex 0-9 A-F character to an integer *)
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

(* Check if a string is made of 0-9 A-F characters, and is between 1 and 7 characters *)
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

(* Convert a hexadecimal string between 1 and 7 characters into an integer *)
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

(* Get the highest float in an array of floats *)
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

(* Get the lowest float in an array of floats *)
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

(* Convert RGB color space to HSL color space *)
: rgb2hsl ( a -- a )
  (* http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c *)
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

(* Convert RGB color space to HCL color space *)
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

(* Plot a color position in a biconal color space *)
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

(* Determine the distance between two points in 3-space *)
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

(* Given a target color, find the closest approximate color in a color palette table *)
: closest_color[ str:target_rgb dict:color_table_rgb -- int:closest_key ]
  (* Convert target_rgb into a list of integer components *)
  target_rgb @
  2 strcut swap xtoi var! r
  2 strcut swap xtoi var! g
  2 strcut swap xtoi var! b
  pop
  { r @ g @ b @ }list target_rgb !
  (* Look for exact matches *)
  color_table_rgb @ foreach
    target_rgb @ array_compare not if exit then
    pop
  repeat
  (* Check for the nearest color using a color space algorithm *)
  target_rgb @ rgb2bicone var! target_bicone
  inf var! closest_dist
  var closest_key
  color_table_rgb @ foreach
    rgb2bicone target_bicone @ distance3 var! current_dist
    var! current_key
    current_dist @ closest_dist @ < if
      current_key @ closest_key !
      current_dist @ closest_dist !
    then
  repeat   
  closest_key @
;

(* Wraps closest_color with a cache of color matches *)
: closest_color_cached[ str:target_rgb dict:color_table_rgb var:match_cache -- int:closest_key ]
  match_cache @ @ target_rgb @ array_getitem dup if
    exit
  else
    pop
  then
  target_rgb @ color_table_rgb @ closest_color
  dup match_cache @ @ target_rgb @ array_setitem match_cache @ !
;

(* RGB to ANSI color code conversion routines *)
lvar ansi8_nearest_cache
: ansi8_nearest[ str:ansi_type str:target_rgb -- int:color8 ]
  ansi8_nearest_cache @ not if
    { }dict ansi8_nearest_cache !
  then
  target_rgb @ ansi_table_8bit_rgb ansi8_nearest_cache closest_color_cached
;

lvar ansi4_nearest_vga_cache
: ansi4_nearest_vga[ str:ansi_type str:target_rgb -- int:color4 ]
  ansi4_nearest_vga_cache @ not if
    { }dict ansi4_nearest_vga_cache !
  then
  ansi_table_4bit_vga_rgb var! color_table_rgb
  { 172 172 172 }list color_table_rgb @ 37 array_setitem color_table_rgb ! (* 170->172 so that XTerm 'dark gray' will be recognized VGA 'dark gray' and not VGA 'gray' *)
  target_rgb @ color_table_rgb @ ansi4_nearest_vga_cache closest_color_cached
;

lvar ansi4_nearest_xterm_cache
: ansi4_nearest_xterm[ str:ansi_type str:target_rgb -- int:color4 ]
  ansi4_nearest_xterm_cache @ not if
    (* Add some precalculated values *)
    { }dict ansi4_nearest_xterm_cache !
  then
  ansi_table_4bit_xterm_rgb var! color_table_rgb
  { 128 127 0 }list color_table_rgb @ 33 array_setitem color_table_rgb ! (* 128->127 so that VGA 'brown' will be recognized as yellow and not red *)
  target_rgb @ color_table_rgb @ ansi4_nearest_xterm_cache closest_color_cached
;

lvar ansi_table_3bit_vga_rgb
: ansi3_nearest_vga[ str:ansi_type str:target_rgb -- int:color4 ]
  ansi_type @ target_rgb @ ansi4_nearest_vga
  dup 90 = if pop 37 then
  dup 91 >= if 60 - then
;

lvar ansi_table_3bit_xterm_rgb
: ansi3_nearest_xterm[ str:ansi_type str:target_rgb -- int:color4 ]
  ansi_type @ target_rgb @ ansi4_nearest_xterm
  dup 90 = if pop 37 then
  dup 91 >= if 60 - then
;

(* Convert an individual MCC code sequence tag to ANSI *)
: mcc_seq[ str:to_type str:code_type int:code_value -- str:ansi_seq ]
  code_type @ "B" = code_type @ "F" = or if
    "" var! retval
    to_type @ "NOCOLOR" = if
      "" exit
    then
    to_type @ "ANSI-3BIT-VGA" = if
      { "\[[" to_type @ code_value @ ansi3_nearest_vga code_type @ "B" = if 10 + then intostr "m" }join exit
    then
    to_type @ "ANSI-3BIT-XTERM" = if
      { "\[[" to_type @ code_value @ ansi3_nearest_xterm code_type @ "B" = if 10 + then intostr "m" }join exit
    then
    to_type @ "ANSI-4BIT-VGA" = if
      code_type @ "F" = if
        { "\[[" to_type @ code_value @ ansi4_nearest_vga intostr "m" }join exit
      else
        { "\[[" to_type @ code_value @ ansi3_nearest_vga 10 + intostr "m" }join exit
      then
    then
    to_type @ "ANSI-4BIT-XTERM" = if
      code_type @ "F" = if
        { "\[[" to_type @ code_value @ ansi4_nearest_xterm intostr "m" }join exit
      else
        { "\[[" to_type @ code_value @ ansi3_nearest_xterm 10 + intostr "m" }join exit
      then
    then
    to_type @ "ANSI-8BIT" = if
      { code_type @ "F" = if "\[[38;5;" else "\[[48;5;" then to_type @ code_value @ ansi8_nearest intostr "m" }join exit
    then
    to_type @ "ANSI-24BIT" = if
      code_value @
      2 strcut swap xtoi var! r
      2 strcut swap xtoi var! g
      2 strcut swap xtoi var! b
      pop
      { code_type @ "F" = if "\[[38;2;" else "\[[48;2;" then r @ intostr ";" g @ intostr ";" b @ intostr "m" }join exit
    then
    "Invalid ANSI type" abort
  then
  code_type @ "X" = if
    code_value @ "000000" = if
      to_type @ "NOCOLOR" = if
        "" exit
      then
      to_type @ "ANSI-3BIT-VGA" = to_type @ "ANSI-3BIT-XTERM" = or to_type @ "ANSI-4BIT-VGA" = or to_type @ "ANSI-4BIT-XTERM" = or if
        "\[[37m\[[40m\[[0m" exit
      then
      to_type @ "ANSI-8BIT" = if
        "\[[38;5;7m\[[48;5;0m\[[0m" exit
      then
      to_type @ "ANSI-24BIT" = if
        "\[[38;2;170;170;170m\[[38;2;0;0;0m\[[0m" exit
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

(* Take an MCC code sequence tag at the start of a string and parse it. *)
: mcc_tagparse[ str:check_string -- str:code_type str:code_value str:post_code ]
  check_string @
  5 strcut swap var! code_mcc
  1 strcut swap var! code_type
  1 strcut swap var! code_dash
  6 strcut swap var! code_value
  var! post_code
  code_mcc @ "#MCC-" = code_type @ ctoi "A" ctoi >= and code_type @ ctoi "Z" ctoi <= and code_dash @ "-" = and code_value @ strlen 6 = and code_value @ hex? and if
    code_type @ code_value @ post_code @ exit
  else
    "" "" "" exit
  then
;

(* Convert an entire MCC sequence to another encoding *)
: mcc_convert[ str:source_string str:to_type -- str:result_string ]
  to_type @ "X" "000000" mcc_seq var! color_reset

  source_string @ "#MCC-" instr not if
    source_string @ exit
  then

  source_string @ "#MCC-" split swap var! retval
  "#MCC-" explode_array foreach
    nip
    "#MCC-" swap strcat
    dup mcc_tagparse var! post_code var! code_value var! code_type
    code_type @ code_value @ and if
      pop { retval @ to_type @ code_type @ code_value @ mcc_seq post_code @ }join retval !
    else
      retval @ swap strcat retval !
    then
  repeat

  { color_reset @ retval @ color_reset @ }join
;

: mcc_strcut[ str:source_string str:split_point -- str:result_string ]
  source_string @ "#MCC-" instr not if
    source_string @ split_point @ strcut exit
  then

  "" var! foreground_code
  "" var! background_code
  0 var! place_in_string
  0 var! place_in_string_without_codes
  begin
    source_string @ place_in_string @ strcut nip var! remaining_string
    remaining_string @ mcc_tagparse var! post_code var! code_value var! code_type
    code_type @ code_value @ and if
      (* We're currently at the start of a code. Take note of the code and advance our position to the end of the code. *)
      code_type @ "F" = code_type @ "B" = or if
        { "#MCC-" code_type @ "-" code_value @ }join
        code_type @ "F" = if
          foreground_code !
        else
          background_code !
        then
      then
      source_string @ strlen post_code @ strlen - place_in_string !
    else
      (* We're not currently in a code. Check how long this span will be until the next code, and see if we're ready to cut. *)
      remaining_string @ "#MCC-" instr
      dup if
        --
      else
        pop remaining_string @ strlen
      then
      place_in_string @ over + place_in_string !
      place_in_string_without_codes @ swap + place_in_string_without_codes !
      place_in_string_without_codes @ split_point @ >= if
        (* We've passed the split point. Roll the counters back to the place where the split happens. *)
        place_in_string_without_codes @ split_point @ -
        place_in_string @ over - place_in_string !
        place_in_string_without_codes @ swap - place_in_string_without_codes !
        break
      then
    then
    place_in_string @ source_string @ strlen >=
  until
  (* We've worked out the spot in the string where the split will happen, perform the split, and duplicate the color state at the point of the split. *)
  source_string @ place_in_string @ strcut
  foreground_code @ swap strcat
  background_code @ swap strcat
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
(*                        M-LIB-COLOR-encoding_default                       *)
(*****************************************************************************)
: M-LIB-COLOR-encoding_default[ -- str:type ]
  ENCODING_DEFAULT
;
PUBLIC M-LIB-COLOR-encoding_default
$LIBDEF M-LIB-COLOR-encoding_default

(*****************************************************************************)
(*                          M-LIB-COLOR-encoding_get                         *)
(*****************************************************************************)
: M-LIB-COLOR-encoding_get[ ref:object -- str:type ]
  (* M1 OK *)

  object @ dbref? not if "Non-dbref argument (1)." abort then

  object @ player? not if
    object @ owner M-LIB-COLOR-encoding_get exit
  then

  object @ "COLOR" flag? not if
    "NOCOLOR" exit
  then

  object @ ENCODING_PROP getpropstr

  dup not if
    pop M-LIB-COLOR-encoding_default exit
  then

  dup SUPPORTED_TYPES array_hasval not if
    pop ENCODING_DEFAULT exit
  then

  dup "ANSI-" instr 1 = not if
    pop "NOCOLOR" exit
  then
;
PUBLIC M-LIB-COLOR-encoding_get
$LIBDEF M-LIB-COLOR-encoding_get

(*****************************************************************************)
(*                          M-LIB-COLOR-encoding_set                         *)
(*****************************************************************************)
: M-LIB-COLOR-encoding_set[ ref:object str:type -- ]
  NEEDSM3

  object @ dbref? not if "Non-dbref argument (1)." abort then
  object @ player? not if "Object must be a player (1)." abort then
  type @ string? not if "Non-string argument (2)." abort then
  type @ SUPPORTED_TYPES array_hasval not if "Encoding type not recognized (2)." abort then
  type @ "ANSI-" instr 1 = not if "Only ANSI encodings are supported right now. Use the COLOR flag to set NOCOLOR. (2)" abort then

  object @ ENCODING_PROP type @ setprop
;
PUBLIC M-LIB-COLOR-encoding_set
$LIBDEF M-LIB-COLOR-encoding_set

(*****************************************************************************)
(*                     M-LIB-COLOR-encoding_player_valid                     *)
(*****************************************************************************)
: M-LIB-COLOR-encoding_player_valid[ -- list:options ]
  SUPPORTED_TYPES_ANSI
;
PUBLIC M-LIB-COLOR-encoding_player_valid
$LIBDEF M-LIB-COLOR-encoding_player_valid

(*****************************************************************************)
(*                            M-LIB-COLOR-strcut                             *)
(*****************************************************************************)
: M-LIB-COLOR-strcut[ str:source_string int:split_point str:type -- str:string1 str:string2 ]
  (* M1 OK *)

  source_string @ string? not if "Non-string argument (1)." abort then
  split_point @ int? not if "Non-integer argument (2)." abort then
  split_point @ 0 < if "Argument must be a positive integer (2)." abort then
  type @ string? not if "Non-string argument (3)." abort then

  type @ SUPPORTED_TYPES array_hasval not if "type not recognized (3)." abort then

  type @ "NOCOLOR" = if
    source_string @ split_point @ strcut exit
  then

  type @ "MCC" = if
    source_string @ split_point @ mcc_strcut exit
  then

  type @ "ANSI-" instr 1 = if
    "Splitting ANSI strings is not yet supported." abort
  then

  { "String splitting type " type @ " is not yet supported." }join abort
;
PUBLIC M-LIB-COLOR-strcut
$LIBDEF M-LIB-COLOR-strcut

(* TODO: Produce test string output for users to look at to see if they support a given ANSI type *)
(*****************************************************************************)
(*                          M-LIB-COLOR-testpattern                          *)
(*****************************************************************************)
: M-LIB-COLOR-testpattern[ str:ansi_type -- arr:strings ]
  ansi_type @ "ANSI-24BIT" = if
    {
      "                                  ANSI-24BIT                                  "
      "                                                                              "
      "This is True-Color ANSI mode, and represents the full gamut of colors         "
      "available on modern displays. Sadly, this encoding is not well supported by   "
      "MUD clients, but it's the ultimate color accuracy option and is recommended   "
      "if available.                                                                 "
      "                                                                              "
      "The box below contains three bands of color, representing a small fraction of "
      "the colors available in this mode, which appear as a smooth gradient with dark"
      "on the left, and bright on the right. It should not contain any 'banding' of  "
      "colors where there are sharp changes in hue or intensity. If it does, or your "
      "client doesn't display it correctly at all, then you are not using true 24-bit"
      "color mode, and you should select a different encoding.                       "
      "                                                                              "
      "     +--------------------------- ANSI-24BIT ---------------------------+     "
      "     | #MCC-B-000000 #MCC-B-040000 #MCC-B-080000 #MCC-B-0C0000 #MCC-B-100000 #MCC-B-140000 #MCC-B-180000 #MCC-B-1C0000 #MCC-B-200000 #MCC-B-240000 #MCC-B-280000 #MCC-B-2C0000 #MCC-B-300000 #MCC-B-340000 #MCC-B-380000 #MCC-B-3C0000 #MCC-B-400000 #MCC-B-440000 #MCC-B-480000 #MCC-B-4C0000 #MCC-B-500000 #MCC-B-540000 #MCC-B-580000 #MCC-B-5C0000 #MCC-B-600000 #MCC-B-640000 #MCC-B-680000 #MCC-B-6C0000 #MCC-B-700000 #MCC-B-740000 #MCC-B-780000 #MCC-B-7C0000 #MCC-B-800000 #MCC-B-840000 #MCC-B-880000 #MCC-B-8C0000 #MCC-B-900000 #MCC-B-940000 #MCC-B-980000 #MCC-B-9C0000 #MCC-B-A00000 #MCC-B-A40000 #MCC-B-A80000 #MCC-B-AC0000 #MCC-B-B00000 #MCC-B-B40000 #MCC-B-B80000 #MCC-B-BC0000 #MCC-B-C00000 #MCC-B-C40000 #MCC-B-C80000 #MCC-B-CC0000 #MCC-B-D00000 #MCC-B-D40000 #MCC-B-D80000 #MCC-B-DC0000 #MCC-B-E00000 #MCC-B-E40000 #MCC-B-E80000 #MCC-B-EC0000 #MCC-B-F00000 #MCC-B-F40000 #MCC-B-F80000 #MCC-B-FC0000 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-010000 #MCC-B-050000 #MCC-B-090000 #MCC-B-0D0000 #MCC-B-110000 #MCC-B-150000 #MCC-B-190000 #MCC-B-1D0000 #MCC-B-210000 #MCC-B-250000 #MCC-B-290000 #MCC-B-2D0000 #MCC-B-310000 #MCC-B-350000 #MCC-B-390000 #MCC-B-3D0000 #MCC-B-410000 #MCC-B-450000 #MCC-B-490000 #MCC-B-4D0000 #MCC-B-510000 #MCC-B-550000 #MCC-B-590000 #MCC-B-5D0000 #MCC-B-610000 #MCC-B-650000 #MCC-B-690000 #MCC-B-6D0000 #MCC-B-710000 #MCC-B-750000 #MCC-B-790000 #MCC-B-7D0000 #MCC-B-810000 #MCC-B-850000 #MCC-B-890000 #MCC-B-8D0000 #MCC-B-910000 #MCC-B-950000 #MCC-B-990000 #MCC-B-9D0000 #MCC-B-A10000 #MCC-B-A50000 #MCC-B-A90000 #MCC-B-AD0000 #MCC-B-B10000 #MCC-B-B50000 #MCC-B-B90000 #MCC-B-BD0000 #MCC-B-C10000 #MCC-B-C50000 #MCC-B-C90000 #MCC-B-CD0000 #MCC-B-D10000 #MCC-B-D50000 #MCC-B-D90000 #MCC-B-DD0000 #MCC-B-E10000 #MCC-B-E50000 #MCC-B-E90000 #MCC-B-ED0000 #MCC-B-F10000 #MCC-B-F50000 #MCC-B-F90000 #MCC-B-FD0000 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-020000 #MCC-B-060000 #MCC-B-0A0000 #MCC-B-0E0000 #MCC-B-120000 #MCC-B-160000 #MCC-B-1A0000 #MCC-B-1E0000 #MCC-B-220000 #MCC-B-260000 #MCC-B-2A0000 #MCC-B-2E0000 #MCC-B-320000 #MCC-B-360000 #MCC-B-3A0000 #MCC-B-3E0000 #MCC-B-420000 #MCC-B-460000 #MCC-B-4A0000 #MCC-B-4E0000 #MCC-B-520000 #MCC-B-560000 #MCC-B-5A0000 #MCC-B-5E0000 #MCC-B-620000 #MCC-B-660000 #MCC-B-6A0000 #MCC-B-6E0000 #MCC-B-720000 #MCC-B-760000 #MCC-B-7A0000 #MCC-B-7E0000 #MCC-B-820000 #MCC-B-860000 #MCC-B-8A0000 #MCC-B-8E0000 #MCC-B-920000 #MCC-B-960000 #MCC-B-9A0000 #MCC-B-9E0000 #MCC-B-A20000 #MCC-B-A60000 #MCC-B-AA0000 #MCC-B-AE0000 #MCC-B-B20000 #MCC-B-B60000 #MCC-B-BA0000 #MCC-B-BE0000 #MCC-B-C20000 #MCC-B-C60000 #MCC-B-CA0000 #MCC-B-CE0000 #MCC-B-D20000 #MCC-B-D60000 #MCC-B-DA0000 #MCC-B-DE0000 #MCC-B-E20000 #MCC-B-E60000 #MCC-B-EA0000 #MCC-B-EE0000 #MCC-B-F20000 #MCC-B-F60000 #MCC-B-FA0000 #MCC-B-FE0000 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-030000 #MCC-B-070000 #MCC-B-0B0000 #MCC-B-0F0000 #MCC-B-130000 #MCC-B-170000 #MCC-B-1B0000 #MCC-B-1F0000 #MCC-B-230000 #MCC-B-270000 #MCC-B-2B0000 #MCC-B-2F0000 #MCC-B-330000 #MCC-B-370000 #MCC-B-3B0000 #MCC-B-3F0000 #MCC-B-430000 #MCC-B-470000 #MCC-B-4B0000 #MCC-B-4F0000 #MCC-B-530000 #MCC-B-570000 #MCC-B-5B0000 #MCC-B-5F0000 #MCC-B-630000 #MCC-B-670000 #MCC-B-6B0000 #MCC-B-6F0000 #MCC-B-730000 #MCC-B-770000 #MCC-B-7B0000 #MCC-B-7F0000 #MCC-B-830000 #MCC-B-870000 #MCC-B-8B0000 #MCC-B-8F0000 #MCC-B-930000 #MCC-B-970000 #MCC-B-9B0000 #MCC-B-9F0000 #MCC-B-A30000 #MCC-B-A70000 #MCC-B-AB0000 #MCC-B-AF0000 #MCC-B-B30000 #MCC-B-B70000 #MCC-B-BB0000 #MCC-B-BF0000 #MCC-B-C30000 #MCC-B-C70000 #MCC-B-CB0000 #MCC-B-CF0000 #MCC-B-D30000 #MCC-B-D70000 #MCC-B-DB0000 #MCC-B-DF0000 #MCC-B-E30000 #MCC-B-E70000 #MCC-B-EB0000 #MCC-B-EF0000 #MCC-B-F30000 #MCC-B-F70000 #MCC-B-FB0000 #MCC-B-FF0000 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000000 #MCC-B-000400 #MCC-B-000800 #MCC-B-000C00 #MCC-B-001000 #MCC-B-001400 #MCC-B-001800 #MCC-B-001C00 #MCC-B-002000 #MCC-B-002400 #MCC-B-002800 #MCC-B-002C00 #MCC-B-003000 #MCC-B-003400 #MCC-B-003800 #MCC-B-003C00 #MCC-B-004000 #MCC-B-004400 #MCC-B-004800 #MCC-B-004C00 #MCC-B-005000 #MCC-B-005400 #MCC-B-005800 #MCC-B-005C00 #MCC-B-006000 #MCC-B-006400 #MCC-B-006800 #MCC-B-006C00 #MCC-B-007000 #MCC-B-007400 #MCC-B-007800 #MCC-B-007C00 #MCC-B-008000 #MCC-B-008400 #MCC-B-008800 #MCC-B-008C00 #MCC-B-009000 #MCC-B-009400 #MCC-B-009800 #MCC-B-009C00 #MCC-B-00A000 #MCC-B-00A400 #MCC-B-00A800 #MCC-B-00AC00 #MCC-B-00B000 #MCC-B-00B400 #MCC-B-00B800 #MCC-B-00BC00 #MCC-B-00C000 #MCC-B-00C400 #MCC-B-00C800 #MCC-B-00CC00 #MCC-B-00D000 #MCC-B-00D400 #MCC-B-00D800 #MCC-B-00DC00 #MCC-B-00E000 #MCC-B-00E400 #MCC-B-00E800 #MCC-B-00EC00 #MCC-B-00F000 #MCC-B-00F400 #MCC-B-00F800 #MCC-B-00FC00 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000100 #MCC-B-000500 #MCC-B-000900 #MCC-B-000D00 #MCC-B-001100 #MCC-B-001500 #MCC-B-001900 #MCC-B-001D00 #MCC-B-002100 #MCC-B-002500 #MCC-B-002900 #MCC-B-002D00 #MCC-B-003100 #MCC-B-003500 #MCC-B-003900 #MCC-B-003D00 #MCC-B-004100 #MCC-B-004500 #MCC-B-004900 #MCC-B-004D00 #MCC-B-005100 #MCC-B-005500 #MCC-B-005900 #MCC-B-005D00 #MCC-B-006100 #MCC-B-006500 #MCC-B-006900 #MCC-B-006D00 #MCC-B-007100 #MCC-B-007500 #MCC-B-007900 #MCC-B-007D00 #MCC-B-008100 #MCC-B-008500 #MCC-B-008900 #MCC-B-008D00 #MCC-B-009100 #MCC-B-009500 #MCC-B-009900 #MCC-B-009D00 #MCC-B-00A100 #MCC-B-00A500 #MCC-B-00A900 #MCC-B-00AD00 #MCC-B-00B100 #MCC-B-00B500 #MCC-B-00B900 #MCC-B-00BD00 #MCC-B-00C100 #MCC-B-00C500 #MCC-B-00C900 #MCC-B-00CD00 #MCC-B-00D100 #MCC-B-00D500 #MCC-B-00D900 #MCC-B-00DD00 #MCC-B-00E100 #MCC-B-00E500 #MCC-B-00E900 #MCC-B-00ED00 #MCC-B-00F100 #MCC-B-00F500 #MCC-B-00F900 #MCC-B-00FD00 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000200 #MCC-B-000600 #MCC-B-000A00 #MCC-B-000E00 #MCC-B-001200 #MCC-B-001600 #MCC-B-001A00 #MCC-B-001E00 #MCC-B-002200 #MCC-B-002600 #MCC-B-002A00 #MCC-B-002E00 #MCC-B-003200 #MCC-B-003600 #MCC-B-003A00 #MCC-B-003E00 #MCC-B-004200 #MCC-B-004600 #MCC-B-004A00 #MCC-B-004E00 #MCC-B-005200 #MCC-B-005600 #MCC-B-005A00 #MCC-B-005E00 #MCC-B-006200 #MCC-B-006600 #MCC-B-006A00 #MCC-B-006E00 #MCC-B-007200 #MCC-B-007600 #MCC-B-007A00 #MCC-B-007E00 #MCC-B-008200 #MCC-B-008600 #MCC-B-008A00 #MCC-B-008E00 #MCC-B-009200 #MCC-B-009600 #MCC-B-009A00 #MCC-B-009E00 #MCC-B-00A200 #MCC-B-00A600 #MCC-B-00AA00 #MCC-B-00AE00 #MCC-B-00B200 #MCC-B-00B600 #MCC-B-00BA00 #MCC-B-00BE00 #MCC-B-00C200 #MCC-B-00C600 #MCC-B-00CA00 #MCC-B-00CE00 #MCC-B-00D200 #MCC-B-00D600 #MCC-B-00DA00 #MCC-B-00DE00 #MCC-B-00E200 #MCC-B-00E600 #MCC-B-00EA00 #MCC-B-00EE00 #MCC-B-00F200 #MCC-B-00F600 #MCC-B-00FA00 #MCC-B-00FE00 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000300 #MCC-B-000700 #MCC-B-000B00 #MCC-B-000F00 #MCC-B-001300 #MCC-B-001700 #MCC-B-001B00 #MCC-B-001F00 #MCC-B-002300 #MCC-B-002700 #MCC-B-002B00 #MCC-B-002F00 #MCC-B-003300 #MCC-B-003700 #MCC-B-003B00 #MCC-B-003F00 #MCC-B-004300 #MCC-B-004700 #MCC-B-004B00 #MCC-B-004F00 #MCC-B-005300 #MCC-B-005700 #MCC-B-005B00 #MCC-B-005F00 #MCC-B-006300 #MCC-B-006700 #MCC-B-006B00 #MCC-B-006F00 #MCC-B-007300 #MCC-B-007700 #MCC-B-007B00 #MCC-B-007F00 #MCC-B-008300 #MCC-B-008700 #MCC-B-008B00 #MCC-B-008F00 #MCC-B-009300 #MCC-B-009700 #MCC-B-009B00 #MCC-B-009F00 #MCC-B-00A300 #MCC-B-00A700 #MCC-B-00AB00 #MCC-B-00AF00 #MCC-B-00B300 #MCC-B-00B700 #MCC-B-00BB00 #MCC-B-00BF00 #MCC-B-00C300 #MCC-B-00C700 #MCC-B-00CB00 #MCC-B-00CF00 #MCC-B-00D300 #MCC-B-00D700 #MCC-B-00DB00 #MCC-B-00DF00 #MCC-B-00E300 #MCC-B-00E700 #MCC-B-00EB00 #MCC-B-00EF00 #MCC-B-00F300 #MCC-B-00F700 #MCC-B-00FB00 #MCC-B-00FF00 #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000000 #MCC-B-000004 #MCC-B-000008 #MCC-B-00000C #MCC-B-000010 #MCC-B-000014 #MCC-B-000018 #MCC-B-00001C #MCC-B-000020 #MCC-B-000024 #MCC-B-000028 #MCC-B-00002C #MCC-B-000030 #MCC-B-000034 #MCC-B-000038 #MCC-B-00003C #MCC-B-000040 #MCC-B-000044 #MCC-B-000048 #MCC-B-00004C #MCC-B-000050 #MCC-B-000054 #MCC-B-000058 #MCC-B-00005C #MCC-B-000060 #MCC-B-000064 #MCC-B-000068 #MCC-B-00006C #MCC-B-000070 #MCC-B-000074 #MCC-B-000078 #MCC-B-00007C #MCC-B-000080 #MCC-B-000084 #MCC-B-000088 #MCC-B-00008C #MCC-B-000090 #MCC-B-000094 #MCC-B-000098 #MCC-B-00009C #MCC-B-0000A0 #MCC-B-0000A4 #MCC-B-0000A8 #MCC-B-0000AC #MCC-B-0000B0 #MCC-B-0000B4 #MCC-B-0000B8 #MCC-B-0000BC #MCC-B-0000C0 #MCC-B-0000C4 #MCC-B-0000C8 #MCC-B-0000CC #MCC-B-0000D0 #MCC-B-0000D4 #MCC-B-0000D8 #MCC-B-0000DC #MCC-B-0000E0 #MCC-B-0000E4 #MCC-B-0000E8 #MCC-B-0000EC #MCC-B-0000F0 #MCC-B-0000F4 #MCC-B-0000F8 #MCC-B-0000FC #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000001 #MCC-B-000005 #MCC-B-000009 #MCC-B-00000D #MCC-B-000011 #MCC-B-000015 #MCC-B-000019 #MCC-B-00001D #MCC-B-000021 #MCC-B-000025 #MCC-B-000029 #MCC-B-00002D #MCC-B-000031 #MCC-B-000035 #MCC-B-000039 #MCC-B-00003D #MCC-B-000041 #MCC-B-000045 #MCC-B-000049 #MCC-B-00004D #MCC-B-000051 #MCC-B-000055 #MCC-B-000059 #MCC-B-00005D #MCC-B-000061 #MCC-B-000065 #MCC-B-000069 #MCC-B-00006D #MCC-B-000071 #MCC-B-000075 #MCC-B-000079 #MCC-B-00007D #MCC-B-000081 #MCC-B-000085 #MCC-B-000089 #MCC-B-00008D #MCC-B-000091 #MCC-B-000095 #MCC-B-000099 #MCC-B-00009D #MCC-B-0000A1 #MCC-B-0000A5 #MCC-B-0000A9 #MCC-B-0000AD #MCC-B-0000B1 #MCC-B-0000B5 #MCC-B-0000B9 #MCC-B-0000BD #MCC-B-0000C1 #MCC-B-0000C5 #MCC-B-0000C9 #MCC-B-0000CD #MCC-B-0000D1 #MCC-B-0000D5 #MCC-B-0000D9 #MCC-B-0000DD #MCC-B-0000E1 #MCC-B-0000E5 #MCC-B-0000E9 #MCC-B-0000ED #MCC-B-0000F1 #MCC-B-0000F5 #MCC-B-0000F9 #MCC-B-0000FD #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000002 #MCC-B-000006 #MCC-B-00000A #MCC-B-00000E #MCC-B-000012 #MCC-B-000016 #MCC-B-00001A #MCC-B-00001E #MCC-B-000022 #MCC-B-000026 #MCC-B-00002A #MCC-B-00002E #MCC-B-000032 #MCC-B-000036 #MCC-B-00003A #MCC-B-00003E #MCC-B-000042 #MCC-B-000046 #MCC-B-00004A #MCC-B-00004E #MCC-B-000052 #MCC-B-000056 #MCC-B-00005A #MCC-B-00005E #MCC-B-000062 #MCC-B-000066 #MCC-B-00006A #MCC-B-00006E #MCC-B-000072 #MCC-B-000076 #MCC-B-00007A #MCC-B-00007E #MCC-B-000082 #MCC-B-000086 #MCC-B-00008A #MCC-B-00008E #MCC-B-000092 #MCC-B-000096 #MCC-B-00009A #MCC-B-00009E #MCC-B-0000A2 #MCC-B-0000A6 #MCC-B-0000AA #MCC-B-0000AE #MCC-B-0000B2 #MCC-B-0000B6 #MCC-B-0000BA #MCC-B-0000BE #MCC-B-0000C2 #MCC-B-0000C6 #MCC-B-0000CA #MCC-B-0000CE #MCC-B-0000D2 #MCC-B-0000D6 #MCC-B-0000DA #MCC-B-0000DE #MCC-B-0000E2 #MCC-B-0000E6 #MCC-B-0000EA #MCC-B-0000EE #MCC-B-0000F2 #MCC-B-0000F6 #MCC-B-0000FA #MCC-B-0000FE #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     | #MCC-B-000003 #MCC-B-000007 #MCC-B-00000B #MCC-B-00000F #MCC-B-000013 #MCC-B-000017 #MCC-B-00001B #MCC-B-00001F #MCC-B-000023 #MCC-B-000027 #MCC-B-00002B #MCC-B-00002F #MCC-B-000033 #MCC-B-000037 #MCC-B-00003B #MCC-B-00003F #MCC-B-000043 #MCC-B-000047 #MCC-B-00004B #MCC-B-00004F #MCC-B-000053 #MCC-B-000057 #MCC-B-00005B #MCC-B-00005F #MCC-B-000063 #MCC-B-000067 #MCC-B-00006B #MCC-B-00006F #MCC-B-000073 #MCC-B-000077 #MCC-B-00007B #MCC-B-00007F #MCC-B-000083 #MCC-B-000087 #MCC-B-00008B #MCC-B-00008F #MCC-B-000093 #MCC-B-000097 #MCC-B-00009B #MCC-B-00009F #MCC-B-0000A3 #MCC-B-0000A7 #MCC-B-0000AB #MCC-B-0000AF #MCC-B-0000B3 #MCC-B-0000B7 #MCC-B-0000BB #MCC-B-0000BF #MCC-B-0000C3 #MCC-B-0000C7 #MCC-B-0000CB #MCC-B-0000CF #MCC-B-0000D3 #MCC-B-0000D7 #MCC-B-0000DB #MCC-B-0000DF #MCC-B-0000E3 #MCC-B-0000E7 #MCC-B-0000EB #MCC-B-0000EF #MCC-B-0000F3 #MCC-B-0000F7 #MCC-B-0000FB #MCC-B-0000FF #MCC-X-000000 |     " ansi_type @ mcc_convert
      "     +------------------------------------------------------------------+     "
    }list exit
  then
  ansi_type @ "ANSI-8BIT" = if
    {
      "                                 ANSI-8BIT                                    "
      "                                                                              "
      "This is the ANSI 256 color mode, and it's largely well supported by MUD       "
      "clients. For color accuracy reasons, the first 16 colors are not used, so     "
      "there are 240 possible colors.                                                "
      "                                                                              "
      "The box below contains every available color. You should see that each one of "
      "them is a different color, distinct from any of the others.                   "
      "                                                                              "
      "       +------------------------ ANSI-8BIT ---------------------------+       "
      "       | #MCC-B-000000 16  #MCC-B-00005F 17  #MCC-B-000087 18  #MCC-B-0000AF 19  #MCC-B-0000D7 20  #MCC-B-0000FF 21  #MCC-B-005F00 22  #MCC-B-005F5F 23  #MCC-B-005F87 24  #MCC-B-005FAF 25  #MCC-B-005FD7 26  #MCC-B-005FFF 27  #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-008700 28  #MCC-B-00875F 29  #MCC-B-008787 30  #MCC-B-0087AF 31  #MCC-B-0087D7 32  #MCC-B-0087FF 33  #MCC-B-00AF00 34  #MCC-B-00AF5F 35  #MCC-B-00AF87 36  #MCC-B-00AFAF 37  #MCC-B-00AFD7 38  #MCC-B-00AFFF 39  #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-00D700 40  #MCC-B-00D75F 41  #MCC-B-00D787 42  #MCC-B-00D7AF 43  #MCC-B-00D7D7 44  #MCC-B-00D7FF 45  #MCC-B-00FF00 46  #MCC-B-00FF5F 47  #MCC-B-00FF87 48  #MCC-B-00FFAF 49  #MCC-B-00FFD7 50  #MCC-B-00FFFF 51  #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-5F0000 52  #MCC-B-5F005F 53  #MCC-B-5F0087 54  #MCC-B-5F00AF 55  #MCC-B-5F00D7 56  #MCC-B-5F00FF 57  #MCC-B-5F5F00 58  #MCC-B-5F5F5F 59  #MCC-B-5F5F87 60  #MCC-B-5F5FAF 61  #MCC-B-5F5FD7 62  #MCC-B-5F5FFF 63  #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-5F8700 64  #MCC-B-5F875F 65  #MCC-B-5F8787 66  #MCC-B-5F87AF 67  #MCC-B-5F87D7 68  #MCC-B-5F87FF 69  #MCC-B-5FAF00 70  #MCC-B-5FAF5F 71  #MCC-B-5FAF87 72  #MCC-B-5FAFAF 73  #MCC-B-5FAFD7 74  #MCC-B-5FAFFF 75  #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-5FD700 76  #MCC-B-5FD75F 77  #MCC-B-5FD787 78  #MCC-B-5FD7AF 79  #MCC-B-5FD7D7 80  #MCC-B-5FD7FF 81  #MCC-B-5FFF00 82  #MCC-B-5FFF5F 83  #MCC-B-5FFF87 84  #MCC-B-5FFFAF 85  #MCC-B-5FFFD7 86  #MCC-B-5FFFFF 87  #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-870000 88  #MCC-B-87005F 89  #MCC-B-870087 90  #MCC-B-8700AF 91  #MCC-B-8700D7 92  #MCC-B-8700FF 93  #MCC-B-875F00 94  #MCC-B-875F5F 95  #MCC-B-875F87 96  #MCC-B-875FAF 97  #MCC-B-875FD7 98  #MCC-B-875FFF 99  #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-878700 100 #MCC-B-87875F 101 #MCC-B-878787 102 #MCC-B-8787AF 103 #MCC-B-8787D7 104 #MCC-B-8787FF 105 #MCC-B-87AF00 106 #MCC-B-87AF5F 107 #MCC-B-87AF87 108 #MCC-B-87AFAF 109 #MCC-B-87AFD7 110 #MCC-B-87AFFF 111 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-87D700 112 #MCC-B-87D75F 113 #MCC-B-87D787 114 #MCC-B-87D7AF 115 #MCC-B-87D7D7 116 #MCC-B-87D7FF 117 #MCC-B-87FF00 118 #MCC-B-87FF5F 119 #MCC-B-87FF87 120 #MCC-B-87FFAF 121 #MCC-B-87FFD7 122 #MCC-B-87FFFF 123 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-AF0000 124 #MCC-B-AF005F 125 #MCC-B-AF0087 126 #MCC-B-AF00AF 127 #MCC-B-AF00D7 128 #MCC-B-AF00FF 129 #MCC-B-AF5F00 130 #MCC-B-AF5F5F 131 #MCC-B-AF5F87 132 #MCC-B-AF5FAF 133 #MCC-B-AF5FD7 134 #MCC-B-AF5FFF 135 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-AF8700 136 #MCC-B-AF875F 137 #MCC-B-AF8787 138 #MCC-B-AF87AF 139 #MCC-B-AF87D7 140 #MCC-B-AF87FF 141 #MCC-B-AFAF00 142 #MCC-B-AFAF5F 143 #MCC-B-AFAF87 144 #MCC-B-AFAFAF 145 #MCC-B-AFAFD7 146 #MCC-B-AFAFFF 147 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-AFD700 148 #MCC-B-AFD75F 149 #MCC-B-AFD787 150 #MCC-B-AFD7AF 151 #MCC-B-AFD7D7 152 #MCC-B-AFD7FF 153 #MCC-B-AFFF00 154 #MCC-B-AFFF5F 155 #MCC-B-AFFF87 156 #MCC-B-AFFFAF 157 #MCC-B-AFFFD7 158 #MCC-B-AFFFFF 159 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-D70000 160 #MCC-B-D7005F 161 #MCC-B-D70087 162 #MCC-B-D700AF 163 #MCC-B-D700D7 164 #MCC-B-D700FF 165 #MCC-B-D75F00 166 #MCC-B-D75F5F 167 #MCC-B-D75F87 168 #MCC-B-D75FAF 169 #MCC-B-D75FD7 170 #MCC-B-D75FFF 171 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-D78700 172 #MCC-B-D7875F 173 #MCC-B-D78787 174 #MCC-B-D787AF 175 #MCC-B-D787D7 176 #MCC-B-D787FF 177 #MCC-B-D7AF00 178 #MCC-B-D7AF5F 179 #MCC-B-D7AF87 180 #MCC-B-D7AFAF 181 #MCC-B-D7AFD7 182 #MCC-B-D7AFFF 183 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-D7D700 184 #MCC-B-D7D75F 185 #MCC-B-D7D787 186 #MCC-B-D7D7AF 187 #MCC-B-D7D7D7 188 #MCC-B-D7D7FF 189 #MCC-B-D7FF00 190 #MCC-B-D7FF5F 191 #MCC-B-D7FF87 192 #MCC-B-D7FFAF 193 #MCC-B-D7FFD7 194 #MCC-B-D7FFFF 195 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-FF0000 196 #MCC-B-FF005F 197 #MCC-B-FF0087 198 #MCC-B-FF00AF 199 #MCC-B-FF00D7 200 #MCC-B-FF00FF 201 #MCC-B-FF5F00 202 #MCC-B-FF5F5F 203 #MCC-B-FF5F87 204 #MCC-B-FF5FAF 205 #MCC-B-FF5FD7 206 #MCC-B-FF5FFF 207 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-FF8700 208 #MCC-B-FF875F 209 #MCC-B-FF8787 210 #MCC-B-FF87AF 211 #MCC-B-FF87D7 212 #MCC-B-FF87FF 213 #MCC-B-FFAF00 214 #MCC-B-FFAF5F 215 #MCC-B-FFAF87 216 #MCC-B-FFAFAF 217 #MCC-B-FFAFD7 218 #MCC-B-FFAFFF 219 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-FFD700 220 #MCC-B-FFD75F 221 #MCC-B-FFD787 222 #MCC-B-FFD7AF 223 #MCC-B-FFD7D7 224 #MCC-B-FFD7FF 225 #MCC-B-FFFF00 226 #MCC-B-FFFF5F 227 #MCC-B-FFFF87 228 #MCC-B-FFFFAF 229 #MCC-B-FFFFD7 230 #MCC-B-FFFFFF 231 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-080808 232 #MCC-B-121212 233 #MCC-B-1C1C1C 234 #MCC-B-262626 235 #MCC-B-303030 236 #MCC-B-3A3A3A 237 #MCC-B-444444 238 #MCC-B-4E4E4E 239 #MCC-B-585858 240 #MCC-B-626262 241 #MCC-B-6C6C6C 242 #MCC-B-767676 243 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       | #MCC-B-808080 244 #MCC-B-8A8A8A 245 #MCC-B-949494 246 #MCC-B-9E9E9E 247 #MCC-B-A8A8A8 248 #MCC-B-B2B2B2 249 #MCC-B-BCBCBC 250 #MCC-B-C6C6C6 251 #MCC-B-D0D0D0 252 #MCC-B-DADADA 253 #MCC-B-E4E4E4 254 #MCC-B-EEEEEE 255 #MCC-X-000000 |       " ansi_type @ mcc_convert
      "       +--------------------------------------------------------------+       "
    }list exit
  then
  ansi_type @ "ANSI-4BIT-VGA" = if
    {
      "                                ANSI-4BIT-VGA                                 "
      "                                                                              "
      "This is the oldest and most compatible color encoding standard, 16 available  "
      "colors. The ANSI standard does not specify palette information, only color    "
      "names, and on most clients you are free to set whatever palette you want for  "
      "these colors, so for the purposes of color conversion on this server, you     "
      "should select the ANSI palette that matches the one used in your MUD client.  "
      "                                                                              "
      "This palette matches VGA graphics adapters popularized by early IBM PCs. They "
      "are the most iconic ANSI colors, and are still considered the standard by ANSI"
      "artists to this day.                                                          "
      "                                                                              "
      "In the box below, you will see 2 columns of 8 colors. On the left are the     "
      "'normal' versions, and on the right are the 'bright' versions. Both the       "
      "'nomal' and the 'bright' colors should have the same font weight. Some clients"
      "will display the brighter colors as bold text. This behavior should be        "
      "disabled in your client settings.                                             "
      "                                                                              "
      "If you are using the VGA palette, the 'normal' versions of colors will appear "
      "dim but vivid. They will be saturated and clear in their color, but they will "
      "not be very brightly lit.                                                     "
      "                                                                              "
      "The 'bright' versions of colors appear less saturated and more pale. 'normal' "
      "yellow is unusual in particular, as it appears brown on the VGA palette.      "
      "                                                                              "
      "Ensure that you can see all 16 colors, and that they match this description.  "
      "                                                                              "
      "If your client supports it, you can use the values on the color table below to"
      "change your output to match the ANSI VGA color palette.                       "
      "                               _______________________________________________"
      "                               | ID |     Color      |   Hex   |  R   G   B  |"
      "                               | 0  | Black          | #000000 |   0   0   0 |"
      "                               | 1  | Red            | #AA0000 | 170   0   0 |"
      "/------ ANSI-4BIT-VGA ------\\  | 2  | Green          | #00AA00 |   0 170   0 |"
      "| #MCC-B-AAAAAA#MCC-F-000000Black#MCC-X-000000        #MCC-B-000000#MCC-F-555555Dark Grey#MCC-X-000000    |  | 3  | Yellow         | #AA5500 | 170  85   0 |" ansi_type @ mcc_convert
      "| #MCC-B-000000#MCC-F-AA0000Dim Red#MCC-X-000000      #MCC-B-000000#MCC-F-FF5555Pale Red#MCC-X-000000     |  | 4  | Blue           | #0000AA |   0   0 170 |" ansi_type @ mcc_convert
      "| #MCC-B-000000#MCC-F-00AA00Dim Green#MCC-X-000000    #MCC-B-000000#MCC-F-55FF55Pale Green#MCC-X-000000   |  | 5  | Magenta        | #AA00AA | 170   0 170 |" ansi_type @ mcc_convert
      "| #MCC-B-000000#MCC-F-AA5500Dim Brown#MCC-X-000000    #MCC-B-000000#MCC-F-FFFF55Pale Yellow#MCC-X-000000  |  | 6  | Cyan           | #00AAAA |   0 170 170 |" ansi_type @ mcc_convert
      "| #MCC-B-000000#MCC-F-0000AADim Blue#MCC-X-000000     #MCC-B-000000#MCC-F-5555FFPale Blue#MCC-X-000000    |  | 7  | White          | #AAAAAA | 170 170 170 |" ansi_type @ mcc_convert
      "| #MCC-B-000000#MCC-F-AA00AADim Magenta#MCC-X-000000  #MCC-B-000000#MCC-F-FF55FFPale Magenta#MCC-X-000000 |  | 8  | Bright Black   | #555555 |  85  85  85 |" ansi_type @ mcc_convert
      "| #MCC-B-000000#MCC-F-00AAAADim Cyan#MCC-X-000000     #MCC-B-000000#MCC-F-55FFFFPale Cyan#MCC-X-000000    |  | 9  | Bright Red     | #FF5555 | 255  85  85 |" ansi_type @ mcc_convert
      "| #MCC-B-000000#MCC-F-AAAAAAWhite#MCC-X-000000        #MCC-B-000000#MCC-F-FFFFFFWhite#MCC-X-000000        |  | 10 | Bright Green   | #55FF55 |  85 255  85 |" ansi_type @ mcc_convert
      "\\---------------------------/  | 11 | Bright Yellow  | #FFFF55 | 255 255  85 |"
      "                               | 12 | Bright Blue    | #5555FF |  85  85 255 |"
      "                               | 13 | Bright Magenta | #FF55FF | 255  85 255 |"
      "                               | 14 | Bright Cyan    | #55FFFF |  85 255 255 |"
      "                               | 15 | Bright White   | #FFFFFF | 255 255 255 |"
      "                               -----------------------------------------------"
    }list exit
  then
  ansi_type @ "ANSI-4BIT-XTERM" = if
    {
      "                               ANSI-4BIT-XTERM                                "
      "                                                                              "
      "This is the oldest and most compatible color encoding standard, 16 available  "
      "colors. The ANSI standard does not specify palette information, only color    "
      "names, and on most clients you are free to set whatever palette you want for  "
      "these colors, so for the purposes of color conversion on this server, you     "
      "should select the ANSI palette that matches the one used in your MUD client.  "
      "                                                                              "
      "This palette matches the XTerm colors, and is arguably the most common color  "
      "palette for MUD clients. It was popularized with the advent of X11 GUIs, and  "
      "has more vibrant colors than the standard VGA color palette.                  "
      "                                                                              "
      "In the box below, you will see 2 columns of 8 colors. On the left are the     "
      "'normal' versions, and on the right are the 'bright' versions. Both the       "
      "'nomal' and the 'bright' colors should have the same font weight. Some clients"
      "will display the brighter colors as bold text. This behavior should be        "
      "disabled in your client settings.                                             "
      "                                                                              "
      "If you are using the XTerm palette in your client, the 'normal' versions of   "
      "colors will have medium brightness, and be vivid. They are saturated and clear"
      "in their color. Yellow will appear yellow, rather than brown. The 'bright'    "
      "versions will be the same intense saturation as the 'dim' versions, but will  "
      "be much more brightly lit.                                                    "
      "                                                                              "
      "Ensure that you can see all 16 colors, and that they match this description.  "
      "                                                                              "
      "If your client supports it, you can use the values on the color table below to"
      "change your output to match the ANSI XTerm color palette.                     "
      "                               _______________________________________________"
      "                               | ID |     Color      |   Hex   |  R   G   B  |"
      "                               | 0  | Black          | #000000 |   0   0   0 |"
      "                               | 1  | Red            | #800000 | 128   0   0 |"
      "/----- ANSI-4BIT-XTERM -----\\  | 2  | Green          | #008000 |   0 128   0 |"
      "|  #MCC-B-AAAAAA#MCC-F-000000Black#MCC-X-000000    #MCC-B-000000#MCC-F-808080Dark Grey#MCC-X-000000       |  | 3  | Yellow         | #808000 | 128 128   0 |" ansi_type @ mcc_convert
      "|  #MCC-B-000000#MCC-F-800000Red#MCC-X-000000      #MCC-B-000000#MCC-F-FF0000Bright Red#MCC-X-000000      |  | 4  | Blue           | #000080 |   0   0 128 |" ansi_type @ mcc_convert
      "|  #MCC-B-000000#MCC-F-008000Green#MCC-X-000000    #MCC-B-000000#MCC-F-00FF00Bright Green#MCC-X-000000    |  | 5  | Magenta        | #800080 | 128   0 128 |" ansi_type @ mcc_convert
      "|  #MCC-B-000000#MCC-F-808000Yellow#MCC-X-000000   #MCC-B-000000#MCC-F-FFFF00Bright Yellow#MCC-X-000000   |  | 6  | Cyan           | #008080 |   0 128 128 |" ansi_type @ mcc_convert
      "|  #MCC-B-000000#MCC-F-000080Blue#MCC-X-000000     #MCC-B-000000#MCC-F-0000FFBright Blue#MCC-X-000000     |  | 7  | White          | #C0C0C0 | 192 192 192 |" ansi_type @ mcc_convert
      "|  #MCC-B-000000#MCC-F-800080Magenta#MCC-X-000000  #MCC-B-000000#MCC-F-FF00FFBright Magenta#MCC-X-000000  |  | 8  | Bright Black   | #808080 | 128 128 128 |" ansi_type @ mcc_convert
      "|  #MCC-B-000000#MCC-F-008080Cyan#MCC-X-000000     #MCC-B-000000#MCC-F-00FFFFBright Cyan#MCC-X-000000     |  | 9  | Bright Red     | #FF0000 | 255   0   0 |" ansi_type @ mcc_convert
      "|  #MCC-B-000000#MCC-F-C0C0C0White#MCC-X-000000    #MCC-B-000000#MCC-F-FFFFFFWhite#MCC-X-000000           |  | 10 | Bright Green   | #00FF00 |   0 255   0 |" ansi_type @ mcc_convert
      "\\---------------------------/  | 11 | Bright Yellow  | #FFFF55 | 255 255   0 |"
      "                               | 12 | Bright Blue    | #0000FF |   0   0 255 |"
      "                               | 13 | Bright Magenta | #FF00FF | 255   0 255 |"
      "                               | 14 | Bright Cyan    | #00FFFF |   0 255 255 |"
      "                               | 15 | Bright White   | #FFFFFF | 255 255 255 |"
      "                               -----------------------------------------------"
    }list exit
  then
  ansi_type @ "ANSI-3BIT-VGA" = if
    {
      "                                ANSI-3BIT-VGA                                 "
      "                                                                              "
      "This is the oldest and most compatible color encoding standard, 16 available  "
      "colors. The ANSI standard does not specify palette information, only color    "
      "names, and on most clients you are free to set whatever palette you want for  "
      "these colors, so for the purposes of color conversion on this server, you     "
      "should select the ANSI palette that matches the one used in your MUD client.  "
      "                                                                              "
      "This palette matches VGA graphics adapters popularized by early IBM PCs. They "
      "are the most iconic ANSI colors, and are still considered the standard by ANSI"
      "artists to this day.                                                          "
      "                                                                              "
      "In the box below, there are see 8 colors. Their color should be vibrantly     "
      "saturated but dimly lit. If your client is using the VGA palette, the         "
      "normally 'yellow' color will appear to be brown.                              "
      "                                                                              "
      "Ensure that all 8 colors are visible and match this description.              "
      "                                                                              "
      "This mode is available for compatibility but should generally be avoided, as  "
      "almost all clients support ANSI-4BIT color codes.                             "
      "                                                                              "
      "If your client supports it, you can use the values on the color table below to"
      "change your output to match the ANSI VGA color palette.                       "
      "                               _______________________________________________"
      "    /-- ANSI-3BIT-VGA --\\      | ID |     Color      |   Hex   |  R   G   B  |"
      "    |       #MCC-B-AAAAAA#MCC-F-000000Black#MCC-X-000000       |      | 0  | Black          | #000000 |   0   0   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-AA0000Red#MCC-X-000000         |      | 1  | Red            | #AA0000 | 170   0   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-00AA00Green#MCC-X-000000       |      | 2  | Green          | #00AA00 |   0 170   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-AA5500Brown#MCC-X-000000       |      | 3  | Yellow         | #AA5500 | 170  85   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-0000AABlue#MCC-X-000000        |      | 4  | Blue           | #0000AA |   0   0 170 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-AA00AAMagenta#MCC-X-000000     |      | 5  | Magenta        | #AA00AA | 170   0 170 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-00AAAACyan#MCC-X-000000        |      | 6  | Cyan           | #00AAAA |   0 170 170 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-AAAAAAWhite#MCC-X-000000       |      | 7  | White          | #AAAAAA | 170 170 170 |" ansi_type @ mcc_convert
      "    \\-------------------/      -----------------------------------------------"
    }list exit
  then
  ansi_type @ "ANSI-3BIT-XTERM" = if
    {
      "                                ANSI-3BIT-VGA                                 "
      "                                                                              "
      "This is the oldest and most compatible color encoding standard, 16 available  "
      "colors. The ANSI standard does not specify palette information, only color    "
      "names, and on most clients you are free to set whatever palette you want for  "
      "these colors, so for the purposes of color conversion on this server, you     "
      "should select the ANSI palette that matches the one used in your MUD client.  "
      "                                                                              "
      "This palette matches the XTerm colors, and is arguably the most common color  "
      "palette for MUD clients. It was popularized with the advent of X11 GUIs, and  "
      "has more vibrant colors than the standard VGA color palette.                  "
      "                                                                              "
      "In the box below, you will see 8 colors. Their color should be vibrantly      "
      "saturated but dimly lit. If your client is using the XTerm color palette,     "
      "yellow will not appear to be brown.                                           "
      "                                                                              "
      "Ensure that all 8 colors are visible and match this description.              "
      "                                                                              "
      "This mode is available for compatibility but should generally be avoided, as  "
      "almost all clients support ANSI-4BIT color codes.                             "
      "                                                                              "
      "If your client supports it, you can use the values on the color table below to"
      "change your output to match the ANSI VGA color palette.                       "
      "                               _______________________________________________"
      "    /-- ANSI-3BIT-VGA --\\      | ID |     Color      |   Hex   |  R   G   B  |"
      "    |       #MCC-B-C0C0C0#MCC-F-000000Black#MCC-X-000000       |      | 0  | Black          | #000000 |   0   0   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-800000Red#MCC-X-000000         |      | 1  | Red            | #800000 | 128   0   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-008000Green#MCC-X-000000       |      | 2  | Green          | #008000 |   0 128   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-808000Brown#MCC-X-000000       |      | 3  | Yellow         | #808000 | 128 128   0 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-000080Blue#MCC-X-000000        |      | 4  | Blue           | #000080 |   0   0 128 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-800080Magenta#MCC-X-000000     |      | 5  | Magenta        | #800080 | 128   0 128 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-008080Cyan#MCC-X-000000        |      | 6  | Cyan           | #008080 |   0 128 128 |" ansi_type @ mcc_convert
      "    |       #MCC-B-000000#MCC-F-C0C0C0White#MCC-X-000000       |      | 7  | White          | #C0C0C0 | 192 192 192 |" ansi_type @ mcc_convert
      "    \\-------------------/      -----------------------------------------------"
    }list exit
  then
  "Invalid ANSI type." abort
;
PUBLIC M-LIB-COLOR-testpattern
$LIBDEF M-LIB-COLOR-testpattern

(*****************************************************************************)
(*                           M-LIB-COLOR-transcode                           *)
(*****************************************************************************)
: M-LIB-COLOR-transcode[ str:source_string str:from_type str:to_type -- str:result_string ]
  (* M1 OK *)

  from_type @ string? not if "Non-string argument (1)." abort then
  to_type @ string? not if "Non-string argument (2)." abort then
  source_string @ string? not if "Non-string argument (3)." abort then
  from_type @ SUPPORTED_TYPES array_hasval not if "from_type not recognized (2)." abort then
  to_type @ SUPPORTED_TYPES array_hasval not to_type @ "AUTO" = not and if "to_type not recognized (3)." abort then

  to_type @ "AUTO" = if
    "me" match M-LIB-COLOR-encoding_get to_type !
  then

  from_type @ to_type @ = if
    source_string @ exit
  then

  from_type @ "MCC" = if
    to_type @ "ANSI-" instr 1 = to_type @ "NOCOLOR" = or if
      source_string @ to_type @ mcc_convert exit
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
PUBLIC M-LIB-COLOR-transcode
$LIBDEF M-LIB-COLOR-transcode

(*****************************************************************************)
(*                           Convenience Routines                            *)
(*****************************************************************************)
$PUBDEF .color_tell me @ swap "MCC" "AUTO" M-LIB-COLOR-transcode notify
$PUBDEF .color_otell loc @ contents begin over over swap "MCC" 3 pick M-LIB-COLOR-encoding_get M-LIB-COLOR-transcode notify next dup not until pop pop
$PUBDEF .color_notify "MCC" 3 pick M-LIB-COLOR-encoding_get M-LIB-COLOR-transcode notify
$PUBDEF .color_transcode "MCC" "AUTO" M-LIB-COLOR-transcode
$PUBDEF .color_escape "NOCOLOR" "MCC" M-LIB-COLOR-transcode
$PUBDEF .color_strip "MCC" "NOCOLOR" M-LIB-COLOR-transcode
$PUBDEF .color_strlen "MCC" "NOCOLOR" M-LIB-COLOR-transcode strlen
$PUBDEF .color_strcut "MCC" M-LIB-COLOR-strcut

(* ------------------------------------------------------------------------ *)

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

