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
(* EXAMPLES:                                                                 *)
(*   "[#7FFF00]Chartreuse!" "MCC" "ANSI-24BIT" M-LIB-COLOR-Transcode .tell   *)
(*   "[#7FFF00]Charclose!" "MCC" "ANSI-8BIT" M-LIB-COLOR-Transcode .tell     *)
(*   "[#7FFF00]Green :/" "MCC" "ANSI-4BIT-VGA" M-LIB-COLOR-Transcode .tell   *)
(*                                                                           *)
(*   "[#7FFF00]Chartreuse?" .color_tell (Uses player color setting prop)     *)
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
(*     Any sequence matching the patern [SXXXXXX], where S is a symbol and   *)
(*     XXXXXX are six capitalized hexadecimal digits and replaced with a     *)
(*     control sequence when converted to a displayable encoding, or an      *)
(*     error message if the code is invalid.                                 *)
(*                                                                           *)
(*       [#XXXXXX] - Foreground color in RGB format (Like HTML codes)        *)
(*       [*XXXXXX] - Background color in RGB format (Like HTML codes)        *)
(*                                                                           *)
(*       [>DDDDXX] - Take foreground color XX (in hex) from the XTERM256     *)
(*                   palette and place it in front of character DDDD (in     *)
(*                   decimal) in the string.                                 *)
(*       [<DDDDXX] - Like above, but for the background color.               *)
(*                                                                           *)
(*       [!000000] - This is removed and replaced with nothing.              *)
(*       [!000001] - This becomes a '[' character                            *)
(*       [!000002] - This becomes a ']' character                            *)
(*       [!FFFFFF] - 'Reset' the colors and formatting back to default       *)
(*                                                                           *)
(*       These symbols are reserved for future use:                          *)
(*         " $ % & ' (  ) + , -  . / : ; = ? @ [ \ ] ^ _ ` { | } ~           *)
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
(*   0  Black              [#000000]                                         *)
(*   1  Red                [#800000]                                         *)
(*   2  Green              [#008000]                                         *)
(*   3  Yellow             [#808000]                                         *)
(*   4  Blue               [#000080]                                         *)
(*   5  Magenta            [#800080]                                         *)
(*   6  Cyan               [#008080]                                         *)
(*   7  White              [#C0C0C0]                                         *)
(*   8  Bright Black       [#808080]                                         *)
(*   9  Bright Red         [#FF0000]                                         *)
(*   10 Bright Green       [#00FF00]                                         *)
(*   11 Bright Yellow      [#FFFF00]                                         *)
(*   12 Bright Blue        [#0000FF]                                         *)
(*   13 Bright Magenta     [#FF00FF]                                         *)
(*   14 Bright Cyan        [#00FFFF]                                         *)
(*   15 Bright White       [#FFFFFF]                                         *)
(*                                                                           *)
(*   VGA Palette:                                                            *)
(*   0  Black              [#000000]                                         *)
(*   1  Red                [#AA0000]                                         *)
(*   2  Green              [#00AA00]                                         *)
(*   3  Yellow (Brown)     [#AA5500]                                         *)
(*   4  Blue               [#0000AA]                                         *)
(*   5  Magenta            [#AA00AA]                                         *)
(*   6  Cyan               [#00AAAA]                                         *)
(*   7  White              [#AAAAAA]                                         *)
(*   8  Bright Black       [#555555]                                         *)
(*   9  Bright Red         [#FF5555]                                         *)
(*   10 Bright Green       [#55FF55]                                         *)
(*   11 Bright Yellow      [#FFFF55]                                         *)
(*   12 Bright Blue        [#5555FF]                                         *)
(*   13 Bright Magenta     [#FF55FF]                                         *)
(*   14 Bright Cyan        [#55FFFF]                                         *)
(*   15 Bright White       [#FFFFFF]                                         *)
(*                                                                           *)
(*   XTERM256 Palette:                                                       *)
(*   16  Black             [#000000]                                         *)
(*   17  NavyBlue          [#00005F]                                         *)
(*   18  DarkBlue          [#000087]                                         *)
(*   19  Blue3             [#0000AF]                                         *)
(*   20  Blue3             [#0000D7]                                         *)
(*   21  Blue1             [#0000FF]                                         *)
(*   22  DarkGreen         [#005F00]                                         *)
(*   23  DeepSkyBlue4      [#005F5F]                                         *)
(*   24  DeepSkyBlue4      [#005F87]                                         *)
(*   25  DeepSkyBlue4      [#005FAF]                                         *)
(*   26  DodgerBlue3       [#005FD7]                                         *)
(*   27  DodgerBlue2       [#005FFF]                                         *)
(*   28  Green4            [#008700]                                         *)
(*   29  SpringGreen4      [#00875F]                                         *)
(*   30  Turquoise4        [#008787]                                         *)
(*   31  DeepSkyBlue3      [#0087AF]                                         *)
(*   32  DeepSkyBlue3      [#0087D7]                                         *)
(*   33  DodgerBlue1       [#0087FF]                                         *)
(*   34  Green3            [#00AF00]                                         *)
(*   35  SpringGreen3      [#00AF5F]                                         *)
(*   36  DarkCyan          [#00AF87]                                         *)
(*   37  LightSeaGreen     [#00AFAF]                                         *)
(*   38  DeepSkyBlue2      [#00AFD7]                                         *)
(*   39  DeepSkyBlue1      [#00AFFF]                                         *)
(*   40  Green3            [#00D700]                                         *)
(*   41  SpringGreen3      [#00D75F]                                         *)
(*   42  SpringGreen2      [#00D787]                                         *)
(*   43  Cyan3             [#00D7AF]                                         *)
(*   44  DarkTurquoise     [#00D7D7]                                         *)
(*   45  Turquoise2        [#00D7FF]                                         *)
(*   46  Green1            [#00FF00]                                         *)
(*   47  SpringGreen2      [#00FF5F]                                         *)
(*   48  SpringGreen1      [#00FF87]                                         *)
(*   49  MediumSpringGreen [#00FFAF]                                         *)
(*   50  Cyan2             [#00FFD7]                                         *)
(*   51  Cyan1             [#00FFFF]                                         *)
(*   52  DarkRed           [#5F0000]                                         *)
(*   53  DeepPink4         [#5F005F]                                         *)
(*   54  Purple4           [#5F0087]                                         *)
(*   55  Purple4           [#5F00AF]                                         *)
(*   56  Purple3           [#5F00D7]                                         *)
(*   57  BlueViolet        [#5F00FF]                                         *)
(*   58  Orange4           [#5F5F00]                                         *)
(*   59  Grey37            [#5F5F5F]                                         *)
(*   60  MediumPurple4     [#5F5F87]                                         *)
(*   61  SlateBlue3        [#5F5FAF]                                         *)
(*   62  SlateBlue3        [#5F5FD7]                                         *)
(*   63  RoyalBlue1        [#5F5FFF]                                         *)
(*   64  Chartreuse4       [#5F8700]                                         *)
(*   65  DarkSeaGreen4     [#5F875F]                                         *)
(*   66  PaleTurquoise4    [#5F8787]                                         *)
(*   67  SteelBlue         [#5F87AF]                                         *)
(*   68  SteelBlue3        [#5F87D7]                                         *)
(*   69  CornflowerBlue    [#5F87FF]                                         *)
(*   70  Chartreuse3       [#5FAF00]                                         *)
(*   71  DarkSeaGreen4     [#5FAF5F]                                         *)
(*   72  CadetBlue         [#5FAF87]                                         *)
(*   73  CadetBlue         [#5FAFAF]                                         *)
(*   74  SkyBlue3          [#5FAFD7]                                         *)
(*   75  SteelBlue1        [#5FAFFF]                                         *)
(*   76  Chartreuse3       [#5FD700]                                         *)
(*   77  PaleGreen3        [#5FD75F]                                         *)
(*   78  SeaGreen3         [#5FD787]                                         *)
(*   79  Aquamarine3       [#5FD7AF]                                         *)
(*   80  MediumTurquoise   [#5FD7D7]                                         *)
(*   81  SteelBlue1        [#5FD7FF]                                         *)
(*   82  Chartreuse2       [#5FFF00]                                         *)
(*   83  SeaGreen2         [#5FFF5F]                                         *)
(*   84  SeaGreen1         [#5FFF87]                                         *)
(*   85  SeaGreen1         [#5FFFAF]                                         *)
(*   86  Aquamarine1       [#5FFFD7]                                         *)
(*   87  DarkSlateGray2    [#5FFFFF]                                         *)
(*   88  DarkRed           [#870000]                                         *)
(*   89  DeepPink4         [#87005F]                                         *)
(*   90  DarkMagenta       [#870087]                                         *)
(*   91  DarkMagenta       [#8700AF]                                         *)
(*   92  DarkViolet        [#8700D7]                                         *)
(*   93  Purple            [#8700FF]                                         *)
(*   94  Orange4           [#875F00]                                         *)
(*   95  LightPink4        [#875F5F]                                         *)
(*   96  Plum4             [#875F87]                                         *)
(*   97  MediumPurple3     [#875FAF]                                         *)
(*   98  MediumPurple3     [#875FD7]                                         *)
(*   99  SlateBlue1        [#875FFF]                                         *)
(*   100 Yellow4           [#878700]                                         *)
(*   101 Wheat4            [#87875F]                                         *)
(*   102 Grey53            [#878787]                                         *)
(*   103 LightSlateGrey    [#8787AF]                                         *)
(*   104 MediumPurple      [#8787D7]                                         *)
(*   105 LightSlateBlue    [#8787FF]                                         *)
(*   106 Yellow4           [#87AF00]                                         *)
(*   107 DarkOliveGreen3   [#87AF5F]                                         *)
(*   108 DarkSeaGreen      [#87AF87]                                         *)
(*   109 LightSkyBlue3     [#87AFAF]                                         *)
(*   110 LightSkyBlue3     [#87AFD7]                                         *)
(*   111 SkyBlue2          [#87AFFF]                                         *)
(*   112 Chartreuse2       [#87D700]                                         *)
(*   113 DarkOliveGreen3   [#87D75F]                                         *)
(*   114 PaleGreen3        [#87D787]                                         *)
(*   115 DarkSeaGreen3     [#87D7AF]                                         *)
(*   116 DarkSlateGray3    [#87D7D7]                                         *)
(*   117 SkyBlue1          [#87D7FF]                                         *)
(*   118 Chartreuse1       [#87FF00]                                         *)
(*   119 LightGreen        [#87FF5F]                                         *)
(*   120 LightGreen        [#87FF87]                                         *)
(*   121 PaleGreen1        [#87FFAF]                                         *)
(*   122 Aquamarine1       [#87FFD7]                                         *)
(*   123 DarkSlateGray1    [#87FFFF]                                         *)
(*   124 Red3              [#AF0000]                                         *)
(*   125 DeepPink4         [#AF005F]                                         *)
(*   126 MediumVioletRed   [#AF0087]                                         *)
(*   127 Magenta3          [#AF00AF]                                         *)
(*   128 DarkViolet        [#AF00D7]                                         *)
(*   129 Purple            [#AF00FF]                                         *)
(*   130 DarkOrange3       [#AF5F00]                                         *)
(*   131 IndianRed         [#AF5F5F]                                         *)
(*   132 HotPink3          [#AF5F87]                                         *)
(*   133 MediumOrchid3     [#AF5FAF]                                         *)
(*   134 MediumOrchid      [#AF5FD7]                                         *)
(*   135 MediumPurple2     [#AF5FFF]                                         *)
(*   136 DarkGoldenrod     [#AF8700]                                         *)
(*   137 LightSalmon3      [#AF875F]                                         *)
(*   138 RosyBrown         [#AF8787]                                         *)
(*   139 Grey63            [#AF87AF]                                         *)
(*   140 MediumPurple2     [#AF87D7]                                         *)
(*   141 MediumPurple1     [#AF87FF]                                         *)
(*   142 Gold3             [#AFAF00]                                         *)
(*   143 DarkKhaki         [#AFAF5F]                                         *)
(*   144 NavajoWhite3      [#AFAF87]                                         *)
(*   145 Grey69            [#AFAFAF]                                         *)
(*   146 LightSteelBlue3   [#AFAFD7]                                         *)
(*   147 LightSteelBlue    [#AFAFFF]                                         *)
(*   148 Yellow3           [#AFD700]                                         *)
(*   149 DarkOliveGreen3   [#AFD75F]                                         *)
(*   150 DarkSeaGreen3     [#AFD787]                                         *)
(*   151 DarkSeaGreen2     [#AFD7AF]                                         *)
(*   152 LightCyan3        [#AFD7D7]                                         *)
(*   153 LightSkyBlue1     [#AFD7FF]                                         *)
(*   154 GreenYellow       [#AFFF00]                                         *)
(*   155 DarkOliveGreen2   [#AFFF5F]                                         *)
(*   156 PaleGreen1        [#AFFF87]                                         *)
(*   157 DarkSeaGreen2     [#AFFFAF]                                         *)
(*   158 DarkSeaGreen1     [#AFFFD7]                                         *)
(*   159 PaleTurquoise1    [#AFFFFF]                                         *)
(*   160 Red3              [#D70000]                                         *)
(*   161 DeepPink3         [#D7005F]                                         *)
(*   162 DeepPink3         [#D70087]                                         *)
(*   163 Magenta3          [#D700AF]                                         *)
(*   164 Magenta3          [#D700D7]                                         *)
(*   165 Magenta2          [#D700FF]                                         *)
(*   166 DarkOrange3       [#D75F00]                                         *)
(*   167 IndianRed         [#D75F5F]                                         *)
(*   168 HotPink3          [#D75F87]                                         *)
(*   169 HotPink2          [#D75FAF]                                         *)
(*   170 Orchid            [#D75FD7]                                         *)
(*   171 MediumOrchid1     [#D75FFF]                                         *)
(*   172 Orange3           [#D78700]                                         *)
(*   173 LightSalmon3      [#D7875F]                                         *)
(*   174 LightPink3        [#D78787]                                         *)
(*   175 Pink3             [#D787AF]                                         *)
(*   176 Plum3             [#D787D7]                                         *)
(*   177 Violet            [#D787FF]                                         *)
(*   178 Gold3             [#D7AF00]                                         *)
(*   179 LightGoldenrod3   [#D7AF5F]                                         *)
(*   180 Tan               [#D7AF87]                                         *)
(*   181 MistyRose3        [#D7AFAF]                                         *)
(*   182 Thistle3          [#D7AFD7]                                         *)
(*   183 Plum2             [#D7AFFF]                                         *)
(*   184 Yellow3           [#D7D700]                                         *)
(*   185 Khaki3            [#D7D75F]                                         *)
(*   186 LightGoldenrod2   [#D7D787]                                         *)
(*   187 LightYellow3      [#D7D7AF]                                         *)
(*   188 Grey84            [#D7D7D7]                                         *)
(*   189 LightSteelBlue1   [#D7D7FF]                                         *)
(*   190 Yellow2           [#D7FF00]                                         *)
(*   191 DarkOliveGreen1   [#D7FF5F]                                         *)
(*   192 DarkOliveGreen1   [#D7FF87]                                         *)
(*   193 DarkSeaGreen1     [#D7FFAF]                                         *)
(*   194 Honeydew2         [#D7FFD7]                                         *)
(*   195 LightCyan1        [#D7FFFF]                                         *)
(*   196 Red1              [#FF0000]                                         *)
(*   197 DeepPink2         [#FF005F]                                         *)
(*   198 DeepPink1         [#FF0087]                                         *)
(*   199 DeepPink1         [#FF00AF]                                         *)
(*   200 Magenta2          [#FF00D7]                                         *)
(*   201 Magenta1          [#FF00FF]                                         *)
(*   202 OrangeRed1        [#FF5F00]                                         *)
(*   203 IndianRed1        [#FF5F5F]                                         *)
(*   204 IndianRed1        [#FF5F87]                                         *)
(*   205 HotPink           [#FF5FAF]                                         *)
(*   206 HotPink           [#FF5FD7]                                         *)
(*   207 MediumOrchid1     [#FF5FFF]                                         *)
(*   208 DarkOrange        [#FF8700]                                         *)
(*   209 Salmon1           [#FF875F]                                         *)
(*   210 LightCoral        [#FF8787]                                         *)
(*   211 PaleVioletRed1    [#FF87AF]                                         *)
(*   212 Orchid2           [#FF87D7]                                         *)
(*   213 Orchid1           [#FF87FF]                                         *)
(*   214 Orange1           [#FFAF00]                                         *)
(*   215 SandyBrown        [#FFAF5F]                                         *)
(*   216 LightSalmon1      [#FFAF87]                                         *)
(*   217 LightPink1        [#FFAFAF]                                         *)
(*   218 Pink1             [#FFAFD7]                                         *)
(*   219 Plum1             [#FFAFFF]                                         *)
(*   220 Gold1             [#FFD700]                                         *)
(*   221 LightGoldenrod2   [#FFD75F]                                         *)
(*   222 LightGoldenrod2   [#FFD787]                                         *)
(*   223 NavajoWhite1      [#FFD7AF]                                         *)
(*   224 MistyRose1        [#FFD7D7]                                         *)
(*   225 Thistle1          [#FFD7FF]                                         *)
(*   226 Yellow1           [#FFFF00]                                         *)
(*   227 LightGoldenrod1   [#FFFF5F]                                         *)
(*   228 Khaki1            [#FFFF87]                                         *)
(*   229 Wheat1            [#FFFFAF]                                         *)
(*   230 Cornsilk1         [#FFFFD7]                                         *)
(*   231 Grey100           [#FFFFFF]                                         *)
(*   232 Grey3             [#080808]                                         *)
(*   233 Grey7             [#121212]                                         *)
(*   234 Grey11            [#1C1C1C]                                         *)
(*   235 Grey15            [#262626]                                         *)
(*   236 Grey19            [#303030]                                         *)
(*   237 Grey23            [#3A3A3A]                                         *)
(*   238 Grey27            [#444444]                                         *)
(*   239 Grey30            [#4E4E4E]                                         *)
(*   240 Grey35            [#585858]                                         *)
(*   241 Grey39            [#626262]                                         *)
(*   242 Grey42            [#6C6C6C]                                         *)
(*   243 Grey46            [#767676]                                         *)
(*   244 Grey50            [#808080]                                         *)
(*   245 Grey54            [#8A8A8A]                                         *)
(*   246 Grey58            [#949494]                                         *)
(*   247 Grey62            [#9E9E9E]                                         *)
(*   248 Grey66            [#A8A8A8]                                         *)
(*   249 Grey70            [#B2B2B2]                                         *)
(*   250 Grey74            [#BCBCBC]                                         *)
(*   251 Grey78            [#C6C6C6]                                         *)
(*   252 Grey82            [#D0D0D0]                                         *)
(*   253 Grey85            [#DADADA]                                         *)
(*   254 Grey89            [#E4E4E4]                                         *)
(*   255 Grey93            [#EEEEEE]                                         *)
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
$DOCCMD  @list __PROG__=2-462

(* Begin configurable options *)

$def ENCODING_DEFAULT "ANSI-8BIT"
$def ENCODING_PROP "_config/color/type"
 
(* End configurable options *)

$def CODE_TYPE_FOREGROUND "#"
$def CODE_TYPE_BACKGROUND "*"
$def CODE_TYPE_FOREGROUND_AT ">"
$def CODE_TYPE_BACKGROUND_AT "<"
$def CODE_TYPE_SPECIAL "!"

$define CODE_TYPE_VALID
{
  (* Defined *)
  CODE_TYPE_FOREGROUND
  CODE_TYPE_BACKGROUND
  CODE_TYPE_SPECIAL
  CODE_TYPE_FOREGROUND_AT
  CODE_TYPE_BACKGROUND_AT

  (* Reserved *)
  "\"" "$" "%" "&" "'" "(" ")" "*" "+" "," "-" "." "/" ":" ";" "=" "?" "@" "[" "\\" "]" "^" "_" "`" "{" "|" "}" "~"
}list
$enddef

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

: array_hasval ( ? a -- b )
  foreach
    nip
    over = if
      pop 1 exit
    then
  repeat
  pop 0
;

(* Convert an integer into a single hex 0-9 A-F character *)
: itox1 ( i -- s )
  dup 16 >= over 0 < or if
    "Only converts one hexadecimal digit." abort
  then

  dup 10 < if
    intostr
  else
    10 - "A" ctoi + itoc
  then
;

(* Convert a one-byte integer into a hex string *)
: itox2 ( i -- s )
  dup 256 >= over 0 < or if
    "Only converts one byte values into hex." abort
  then

  dup 16 / itox1 swap 16 % itox1 strcat
;

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
  code_type @ CODE_TYPE_BACKGROUND = code_type @ CODE_TYPE_FOREGROUND = or if
    "" var! retval
    to_type @ "NOCOLOR" = if
      "" exit
    then
    to_type @ "ANSI-3BIT-VGA" = if
      { "\[[" to_type @ code_value @ ansi3_nearest_vga code_type @ CODE_TYPE_BACKGROUND = if 10 + then intostr "m" }join exit
    then
    to_type @ "ANSI-3BIT-XTERM" = if
      { "\[[" to_type @ code_value @ ansi3_nearest_xterm code_type @ CODE_TYPE_BACKGROUND = if 10 + then intostr "m" }join exit
    then
    to_type @ "ANSI-4BIT-VGA" = if
      code_type @ CODE_TYPE_FOREGROUND = if
        { "\[[" to_type @ code_value @ ansi4_nearest_vga intostr "m" }join exit
      else
        { "\[[" to_type @ code_value @ ansi3_nearest_vga 10 + intostr "m" }join exit
      then
    then
    to_type @ "ANSI-4BIT-XTERM" = if
      code_type @ CODE_TYPE_FOREGROUND = if
        { "\[[" to_type @ code_value @ ansi4_nearest_xterm intostr "m" }join exit
      else
        { "\[[" to_type @ code_value @ ansi3_nearest_xterm 10 + intostr "m" }join exit
      then
    then
    to_type @ "ANSI-8BIT" = if
      { code_type @ CODE_TYPE_FOREGROUND = if "\[[38;5;" else "\[[48;5;" then to_type @ code_value @ ansi8_nearest intostr "m" }join exit
    then
    to_type @ "ANSI-24BIT" = if
      code_value @
      2 strcut swap xtoi var! r
      2 strcut swap xtoi var! g
      2 strcut swap xtoi var! b
      pop
      { code_type @ CODE_TYPE_FOREGROUND = if "\[[38;2;" else "\[[48;2;" then r @ intostr ";" g @ intostr ";" b @ intostr "m" }join exit
    then
    "Invalid ANSI type" abort
  then
  code_type @ CODE_TYPE_BACKGROUND_AT = code_type @ CODE_TYPE_FOREGROUND_AT = or if
  then
  code_type @ CODE_TYPE_SPECIAL = if
    code_value @ "FFFFFF" = if
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
    code_value @ "000000" = if
      "" exit
    then
    code_value @ "000001" = if
      "[" exit
    then
    code_value @ "000002" = if
      "]" exit
    then
    { "[INVALID MCC V" .version " CODE - UNKNOWN '" code_type @ "' VALUE ]" }join exit
  then
  { "[INVALID MCC V" .version " CODE - UNKNOWN TYPE '" code_type @ "' ]" }join
;

(* Take an MCC code sequence tag at the start of a string and parse it. *)
: mcc_tagparse[ str:check_string -- str:code_type str:code_value str:post_code ]
  check_string @
  1 strcut swap var! code_openbracket
  1 strcut swap var! code_type
  6 strcut swap var! code_value
  1 strcut swap var! code_closebracket
  var! post_code
  code_openbracket @ "[" = code_type @ CODE_TYPE_VALID array_hasval and code_value @ hex? and code_closebracket @ "]" = and if
    code_type @ code_value @ post_code @ exit
  else
    "" "" "" exit
  then
;

(* Splits a string, ignoring MCC codes when deciding where to split *)
: mcc_strcut[ str:source_string str:split_point bool:keep_color -- str:result_string ]
  source_string @ "[" instr not if
    source_string @ split_point @ strcut exit
  then

  "" var! foreground_code
  "" var! background_code
  0 var! place_in_string
  0 var! place_in_string_without_codes
  begin
    source_string @ place_in_string @ strcut nip var! remaining_string
    remaining_string @ "[" instr 1 = if
      remaining_string @ mcc_tagparse var! post_code var! code_value var! code_type
      code_type @ code_value @ and if
        (* We're currently at the start of a code. Take note of the code and advance our position to the end of the code. *)
        code_type @ CODE_TYPE_FOREGROUND = code_type @ CODE_TYPE_BACKGROUND = or if
          { "[" code_type @ code_value @ "]" }join
          code_type @ CODE_TYPE_FOREGROUND = if
            foreground_code !
          else
            background_code !
          then
        then
        source_string @ strlen post_code @ strlen - place_in_string !
      else
        (* '[' without being an actual code. Ignore it and move on. *)
        place_in_string ++
        place_in_string_without_codes ++
      then
    else
      (* We're not currently in a code. Check how long this span will be until the next potential code, and see if we're ready to cut. *)
      remaining_string @ "[" instr
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
  keep_color @ if
    foreground_code @ swap strcat
    background_code @ swap strcat
  then
;

(* Splits a string, ignoring MCC codes when deciding where to split *)
: mcc_strlen[ str:check_string -- int:length ]
  0 var! length
  begin
    (* Are we at a tag? *)
    check_string @ "[" instr 1 = if
      check_string @ mcc_tagparse -rot and if
        (* We are. Drop the tag and continue. *)
        check_string !
      else
        pop
        (* We are at a '[' without being at an actual tag. Skip it and move on. *)
        length ++
        check_string @ 1 strcut swap pop check_string !
      then
    else
      (* Find the next potential tag and count the number of characters skipped. *)
      check_string @ "[" instr
      dup not if
        (* We hit the end of the string. Add the length and bail. *)
        pop
        length @ check_string @ strlen + length !
        break
      then
      --
      length @ over + length !
      check_string @ swap strcut swap pop check_string !
    then
    check_string @ not
  until
  length @
;

(* Convert an entire MCC sequence to another encoding *)
: mcc_convert[ str:source_string str:to_type -- str:result_string ]
  source_string @ "[" instr not if
    source_string @ exit
  then

  var retval

  (* Preprocessing *)
  source_string @ mcc_strlen var! source_string_length
  var pre_insert_pos
  var pre_insert_color
  { }list var! pre_inserts
  source_string @ "[" split swap retval !
  "[" explode_array foreach
    nip
    "[" swap strcat
    dup mcc_tagparse var! post_code var! code_value var! code_type
    code_type @ CODE_TYPE_FOREGROUND_AT = code_type @ CODE_TYPE_BACKGROUND_AT = or code_value @ and if
      pop
      code_value @ 4 strcut
      pre_insert_color !
      pre_insert_pos !
      (* Parse the insert position *)
      pre_insert_pos @ number? not if
        { retval @ "[INVALID MCC V" .version " CODE - INVALID '" code_type @ "' POSITION VALUE ]" post_code @ }join retval !
        continue
      then
      pre_insert_pos @ atoi pre_insert_pos !
      pre_insert_pos @ source_string_length @ >= if
        { retval @ "[INVALID MCC V" .version " CODE - '" code_type @ "' POSITION VALUE BIGGER THAN STRING ]" post_code @ }join retval !
        continue
      then
      (* Parse the insert color *)
      pre_insert_color @ xtoi pre_insert_color !
      pre_insert_color @ 16 < if
        { retval @ "[INVALID MCC V" .version " CODE - INVALID '" code_type @ "' COLOR VALUE ]" post_code @ }join retval !
        continue
      then
        ansi_table_8bit_rgb pre_insert_color @ array_getitem pre_insert_color !
        { pre_insert_color @ 0 [] itox2 pre_insert_color @ 1 [] itox2 pre_insert_color @ 2 [] itox2 }join pre_insert_color !
      (* Store the insert for later *)
      code_type @ CODE_TYPE_FOREGROUND_AT = if
        { "[#" pre_insert_color @ "]" }join
      else
        { "[*" pre_insert_color @ "]" }join
      then
      pre_insert_color !
      { pre_insert_pos @ pre_insert_color @ }list pre_inserts @ array_appenditem pre_inserts !
      (* Store the string with this code stripped out *)
      retval @ post_code @ strcat retval !
    else
      retval @ swap strcat retval !
    then
  repeat
  (* Preprocessing - Update the source string now that the pre-processing codes have been stripped out *)
  retval @ source_string !
  (* Preprocessing - Modify the source string with the stored inserts *)
  pre_inserts @ foreach
    nip
    array_vals pop
    pre_insert_color !
    pre_insert_pos !
    source_string @ pre_insert_pos @ 0 mcc_strcut pre_insert_color @ swap strcat strcat source_string !
  repeat

  (* Main sequence decoding *)
  source_string @ "[" split swap retval !
  "[" explode_array foreach
    nip
    "[" swap strcat
    dup mcc_tagparse var! post_code var! code_value var! code_type
    code_type @ code_value @ and if
      pop { retval @ to_type @ code_type @ code_value @ mcc_seq post_code @ }join retval !
    else
      retval @ swap strcat retval !
    then
  repeat

  (* Return the result, automatically resetting before and after *)
  to_type @ CODE_TYPE_SPECIAL "FFFFFF" mcc_seq var! color_reset
  { color_reset @ retval @ color_reset @ }join
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
    source_string @ split_point @ 1 mcc_strcut exit
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
      "     | [*000000] [*040000] [*080000] [*0C0000] [*100000] [*140000] [*180000] [*1C0000] [*200000] [*240000] [*280000] [*2C0000] [*300000] [*340000] [*380000] [*3C0000] [*400000] [*440000] [*480000] [*4C0000] [*500000] [*540000] [*580000] [*5C0000] [*600000] [*640000] [*680000] [*6C0000] [*700000] [*740000] [*780000] [*7C0000] [*800000] [*840000] [*880000] [*8C0000] [*900000] [*940000] [*980000] [*9C0000] [*A00000] [*A40000] [*A80000] [*AC0000] [*B00000] [*B40000] [*B80000] [*BC0000] [*C00000] [*C40000] [*C80000] [*CC0000] [*D00000] [*D40000] [*D80000] [*DC0000] [*E00000] [*E40000] [*E80000] [*EC0000] [*F00000] [*F40000] [*F80000] [*FC0000] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*010000] [*050000] [*090000] [*0D0000] [*110000] [*150000] [*190000] [*1D0000] [*210000] [*250000] [*290000] [*2D0000] [*310000] [*350000] [*390000] [*3D0000] [*410000] [*450000] [*490000] [*4D0000] [*510000] [*550000] [*590000] [*5D0000] [*610000] [*650000] [*690000] [*6D0000] [*710000] [*750000] [*790000] [*7D0000] [*810000] [*850000] [*890000] [*8D0000] [*910000] [*950000] [*990000] [*9D0000] [*A10000] [*A50000] [*A90000] [*AD0000] [*B10000] [*B50000] [*B90000] [*BD0000] [*C10000] [*C50000] [*C90000] [*CD0000] [*D10000] [*D50000] [*D90000] [*DD0000] [*E10000] [*E50000] [*E90000] [*ED0000] [*F10000] [*F50000] [*F90000] [*FD0000] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*020000] [*060000] [*0A0000] [*0E0000] [*120000] [*160000] [*1A0000] [*1E0000] [*220000] [*260000] [*2A0000] [*2E0000] [*320000] [*360000] [*3A0000] [*3E0000] [*420000] [*460000] [*4A0000] [*4E0000] [*520000] [*560000] [*5A0000] [*5E0000] [*620000] [*660000] [*6A0000] [*6E0000] [*720000] [*760000] [*7A0000] [*7E0000] [*820000] [*860000] [*8A0000] [*8E0000] [*920000] [*960000] [*9A0000] [*9E0000] [*A20000] [*A60000] [*AA0000] [*AE0000] [*B20000] [*B60000] [*BA0000] [*BE0000] [*C20000] [*C60000] [*CA0000] [*CE0000] [*D20000] [*D60000] [*DA0000] [*DE0000] [*E20000] [*E60000] [*EA0000] [*EE0000] [*F20000] [*F60000] [*FA0000] [*FE0000] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*030000] [*070000] [*0B0000] [*0F0000] [*130000] [*170000] [*1B0000] [*1F0000] [*230000] [*270000] [*2B0000] [*2F0000] [*330000] [*370000] [*3B0000] [*3F0000] [*430000] [*470000] [*4B0000] [*4F0000] [*530000] [*570000] [*5B0000] [*5F0000] [*630000] [*670000] [*6B0000] [*6F0000] [*730000] [*770000] [*7B0000] [*7F0000] [*830000] [*870000] [*8B0000] [*8F0000] [*930000] [*970000] [*9B0000] [*9F0000] [*A30000] [*A70000] [*AB0000] [*AF0000] [*B30000] [*B70000] [*BB0000] [*BF0000] [*C30000] [*C70000] [*CB0000] [*CF0000] [*D30000] [*D70000] [*DB0000] [*DF0000] [*E30000] [*E70000] [*EB0000] [*EF0000] [*F30000] [*F70000] [*FB0000] [*FF0000] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000000] [*000400] [*000800] [*000C00] [*001000] [*001400] [*001800] [*001C00] [*002000] [*002400] [*002800] [*002C00] [*003000] [*003400] [*003800] [*003C00] [*004000] [*004400] [*004800] [*004C00] [*005000] [*005400] [*005800] [*005C00] [*006000] [*006400] [*006800] [*006C00] [*007000] [*007400] [*007800] [*007C00] [*008000] [*008400] [*008800] [*008C00] [*009000] [*009400] [*009800] [*009C00] [*00A000] [*00A400] [*00A800] [*00AC00] [*00B000] [*00B400] [*00B800] [*00BC00] [*00C000] [*00C400] [*00C800] [*00CC00] [*00D000] [*00D400] [*00D800] [*00DC00] [*00E000] [*00E400] [*00E800] [*00EC00] [*00F000] [*00F400] [*00F800] [*00FC00] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000100] [*000500] [*000900] [*000D00] [*001100] [*001500] [*001900] [*001D00] [*002100] [*002500] [*002900] [*002D00] [*003100] [*003500] [*003900] [*003D00] [*004100] [*004500] [*004900] [*004D00] [*005100] [*005500] [*005900] [*005D00] [*006100] [*006500] [*006900] [*006D00] [*007100] [*007500] [*007900] [*007D00] [*008100] [*008500] [*008900] [*008D00] [*009100] [*009500] [*009900] [*009D00] [*00A100] [*00A500] [*00A900] [*00AD00] [*00B100] [*00B500] [*00B900] [*00BD00] [*00C100] [*00C500] [*00C900] [*00CD00] [*00D100] [*00D500] [*00D900] [*00DD00] [*00E100] [*00E500] [*00E900] [*00ED00] [*00F100] [*00F500] [*00F900] [*00FD00] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000200] [*000600] [*000A00] [*000E00] [*001200] [*001600] [*001A00] [*001E00] [*002200] [*002600] [*002A00] [*002E00] [*003200] [*003600] [*003A00] [*003E00] [*004200] [*004600] [*004A00] [*004E00] [*005200] [*005600] [*005A00] [*005E00] [*006200] [*006600] [*006A00] [*006E00] [*007200] [*007600] [*007A00] [*007E00] [*008200] [*008600] [*008A00] [*008E00] [*009200] [*009600] [*009A00] [*009E00] [*00A200] [*00A600] [*00AA00] [*00AE00] [*00B200] [*00B600] [*00BA00] [*00BE00] [*00C200] [*00C600] [*00CA00] [*00CE00] [*00D200] [*00D600] [*00DA00] [*00DE00] [*00E200] [*00E600] [*00EA00] [*00EE00] [*00F200] [*00F600] [*00FA00] [*00FE00] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000300] [*000700] [*000B00] [*000F00] [*001300] [*001700] [*001B00] [*001F00] [*002300] [*002700] [*002B00] [*002F00] [*003300] [*003700] [*003B00] [*003F00] [*004300] [*004700] [*004B00] [*004F00] [*005300] [*005700] [*005B00] [*005F00] [*006300] [*006700] [*006B00] [*006F00] [*007300] [*007700] [*007B00] [*007F00] [*008300] [*008700] [*008B00] [*008F00] [*009300] [*009700] [*009B00] [*009F00] [*00A300] [*00A700] [*00AB00] [*00AF00] [*00B300] [*00B700] [*00BB00] [*00BF00] [*00C300] [*00C700] [*00CB00] [*00CF00] [*00D300] [*00D700] [*00DB00] [*00DF00] [*00E300] [*00E700] [*00EB00] [*00EF00] [*00F300] [*00F700] [*00FB00] [*00FF00] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000000] [*000004] [*000008] [*00000C] [*000010] [*000014] [*000018] [*00001C] [*000020] [*000024] [*000028] [*00002C] [*000030] [*000034] [*000038] [*00003C] [*000040] [*000044] [*000048] [*00004C] [*000050] [*000054] [*000058] [*00005C] [*000060] [*000064] [*000068] [*00006C] [*000070] [*000074] [*000078] [*00007C] [*000080] [*000084] [*000088] [*00008C] [*000090] [*000094] [*000098] [*00009C] [*0000A0] [*0000A4] [*0000A8] [*0000AC] [*0000B0] [*0000B4] [*0000B8] [*0000BC] [*0000C0] [*0000C4] [*0000C8] [*0000CC] [*0000D0] [*0000D4] [*0000D8] [*0000DC] [*0000E0] [*0000E4] [*0000E8] [*0000EC] [*0000F0] [*0000F4] [*0000F8] [*0000FC] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000001] [*000005] [*000009] [*00000D] [*000011] [*000015] [*000019] [*00001D] [*000021] [*000025] [*000029] [*00002D] [*000031] [*000035] [*000039] [*00003D] [*000041] [*000045] [*000049] [*00004D] [*000051] [*000055] [*000059] [*00005D] [*000061] [*000065] [*000069] [*00006D] [*000071] [*000075] [*000079] [*00007D] [*000081] [*000085] [*000089] [*00008D] [*000091] [*000095] [*000099] [*00009D] [*0000A1] [*0000A5] [*0000A9] [*0000AD] [*0000B1] [*0000B5] [*0000B9] [*0000BD] [*0000C1] [*0000C5] [*0000C9] [*0000CD] [*0000D1] [*0000D5] [*0000D9] [*0000DD] [*0000E1] [*0000E5] [*0000E9] [*0000ED] [*0000F1] [*0000F5] [*0000F9] [*0000FD] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000002] [*000006] [*00000A] [*00000E] [*000012] [*000016] [*00001A] [*00001E] [*000022] [*000026] [*00002A] [*00002E] [*000032] [*000036] [*00003A] [*00003E] [*000042] [*000046] [*00004A] [*00004E] [*000052] [*000056] [*00005A] [*00005E] [*000062] [*000066] [*00006A] [*00006E] [*000072] [*000076] [*00007A] [*00007E] [*000082] [*000086] [*00008A] [*00008E] [*000092] [*000096] [*00009A] [*00009E] [*0000A2] [*0000A6] [*0000AA] [*0000AE] [*0000B2] [*0000B6] [*0000BA] [*0000BE] [*0000C2] [*0000C6] [*0000CA] [*0000CE] [*0000D2] [*0000D6] [*0000DA] [*0000DE] [*0000E2] [*0000E6] [*0000EA] [*0000EE] [*0000F2] [*0000F6] [*0000FA] [*0000FE] [!FFFFFF] |     " ansi_type @ mcc_convert
      "     | [*000003] [*000007] [*00000B] [*00000F] [*000013] [*000017] [*00001B] [*00001F] [*000023] [*000027] [*00002B] [*00002F] [*000033] [*000037] [*00003B] [*00003F] [*000043] [*000047] [*00004B] [*00004F] [*000053] [*000057] [*00005B] [*00005F] [*000063] [*000067] [*00006B] [*00006F] [*000073] [*000077] [*00007B] [*00007F] [*000083] [*000087] [*00008B] [*00008F] [*000093] [*000097] [*00009B] [*00009F] [*0000A3] [*0000A7] [*0000AB] [*0000AF] [*0000B3] [*0000B7] [*0000BB] [*0000BF] [*0000C3] [*0000C7] [*0000CB] [*0000CF] [*0000D3] [*0000D7] [*0000DB] [*0000DF] [*0000E3] [*0000E7] [*0000EB] [*0000EF] [*0000F3] [*0000F7] [*0000FB] [*0000FF] [!FFFFFF] |     " ansi_type @ mcc_convert
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
      "       | [*000000] 16  [*00005F] 17  [*000087] 18  [*0000AF] 19  [*0000D7] 20  [*0000FF] 21  [*005F00] 22  [*005F5F] 23  [*005F87] 24  [*005FAF] 25  [*005FD7] 26  [*005FFF] 27  [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*008700] 28  [*00875F] 29  [*008787] 30  [*0087AF] 31  [*0087D7] 32  [*0087FF] 33  [*00AF00] 34  [*00AF5F] 35  [*00AF87] 36  [*00AFAF] 37  [*00AFD7] 38  [*00AFFF] 39  [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*00D700] 40  [*00D75F] 41  [*00D787] 42  [*00D7AF] 43  [*00D7D7] 44  [*00D7FF] 45  [*00FF00] 46  [*00FF5F] 47  [*00FF87] 48  [*00FFAF] 49  [*00FFD7] 50  [*00FFFF] 51  [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*5F0000] 52  [*5F005F] 53  [*5F0087] 54  [*5F00AF] 55  [*5F00D7] 56  [*5F00FF] 57  [*5F5F00] 58  [*5F5F5F] 59  [*5F5F87] 60  [*5F5FAF] 61  [*5F5FD7] 62  [*5F5FFF] 63  [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*5F8700] 64  [*5F875F] 65  [*5F8787] 66  [*5F87AF] 67  [*5F87D7] 68  [*5F87FF] 69  [*5FAF00] 70  [*5FAF5F] 71  [*5FAF87] 72  [*5FAFAF] 73  [*5FAFD7] 74  [*5FAFFF] 75  [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*5FD700] 76  [*5FD75F] 77  [*5FD787] 78  [*5FD7AF] 79  [*5FD7D7] 80  [*5FD7FF] 81  [*5FFF00] 82  [*5FFF5F] 83  [*5FFF87] 84  [*5FFFAF] 85  [*5FFFD7] 86  [*5FFFFF] 87  [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*870000] 88  [*87005F] 89  [*870087] 90  [*8700AF] 91  [*8700D7] 92  [*8700FF] 93  [*875F00] 94  [*875F5F] 95  [*875F87] 96  [*875FAF] 97  [*875FD7] 98  [*875FFF] 99  [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*878700] 100 [*87875F] 101 [*878787] 102 [*8787AF] 103 [*8787D7] 104 [*8787FF] 105 [*87AF00] 106 [*87AF5F] 107 [*87AF87] 108 [*87AFAF] 109 [*87AFD7] 110 [*87AFFF] 111 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*87D700] 112 [*87D75F] 113 [*87D787] 114 [*87D7AF] 115 [*87D7D7] 116 [*87D7FF] 117 [*87FF00] 118 [*87FF5F] 119 [*87FF87] 120 [*87FFAF] 121 [*87FFD7] 122 [*87FFFF] 123 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*AF0000] 124 [*AF005F] 125 [*AF0087] 126 [*AF00AF] 127 [*AF00D7] 128 [*AF00FF] 129 [*AF5F00] 130 [*AF5F5F] 131 [*AF5F87] 132 [*AF5FAF] 133 [*AF5FD7] 134 [*AF5FFF] 135 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*AF8700] 136 [*AF875F] 137 [*AF8787] 138 [*AF87AF] 139 [*AF87D7] 140 [*AF87FF] 141 [*AFAF00] 142 [*AFAF5F] 143 [*AFAF87] 144 [*AFAFAF] 145 [*AFAFD7] 146 [*AFAFFF] 147 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*AFD700] 148 [*AFD75F] 149 [*AFD787] 150 [*AFD7AF] 151 [*AFD7D7] 152 [*AFD7FF] 153 [*AFFF00] 154 [*AFFF5F] 155 [*AFFF87] 156 [*AFFFAF] 157 [*AFFFD7] 158 [*AFFFFF] 159 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*D70000] 160 [*D7005F] 161 [*D70087] 162 [*D700AF] 163 [*D700D7] 164 [*D700FF] 165 [*D75F00] 166 [*D75F5F] 167 [*D75F87] 168 [*D75FAF] 169 [*D75FD7] 170 [*D75FFF] 171 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*D78700] 172 [*D7875F] 173 [*D78787] 174 [*D787AF] 175 [*D787D7] 176 [*D787FF] 177 [*D7AF00] 178 [*D7AF5F] 179 [*D7AF87] 180 [*D7AFAF] 181 [*D7AFD7] 182 [*D7AFFF] 183 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*D7D700] 184 [*D7D75F] 185 [*D7D787] 186 [*D7D7AF] 187 [*D7D7D7] 188 [*D7D7FF] 189 [*D7FF00] 190 [*D7FF5F] 191 [*D7FF87] 192 [*D7FFAF] 193 [*D7FFD7] 194 [*D7FFFF] 195 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*FF0000] 196 [*FF005F] 197 [*FF0087] 198 [*FF00AF] 199 [*FF00D7] 200 [*FF00FF] 201 [*FF5F00] 202 [*FF5F5F] 203 [*FF5F87] 204 [*FF5FAF] 205 [*FF5FD7] 206 [*FF5FFF] 207 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*FF8700] 208 [*FF875F] 209 [*FF8787] 210 [*FF87AF] 211 [*FF87D7] 212 [*FF87FF] 213 [*FFAF00] 214 [*FFAF5F] 215 [*FFAF87] 216 [*FFAFAF] 217 [*FFAFD7] 218 [*FFAFFF] 219 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*FFD700] 220 [*FFD75F] 221 [*FFD787] 222 [*FFD7AF] 223 [*FFD7D7] 224 [*FFD7FF] 225 [*FFFF00] 226 [*FFFF5F] 227 [*FFFF87] 228 [*FFFFAF] 229 [*FFFFD7] 230 [*FFFFFF] 231 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*080808] 232 [*121212] 233 [*1C1C1C] 234 [*262626] 235 [*303030] 236 [*3A3A3A] 237 [*444444] 238 [*4E4E4E] 239 [*585858] 240 [*626262] 241 [*6C6C6C] 242 [*767676] 243 [!FFFFFF] |       " ansi_type @ mcc_convert
      "       | [*808080] 244 [*8A8A8A] 245 [*949494] 246 [*9E9E9E] 247 [*A8A8A8] 248 [*B2B2B2] 249 [*BCBCBC] 250 [*C6C6C6] 251 [*D0D0D0] 252 [*DADADA] 253 [*E4E4E4] 254 [*EEEEEE] 255 [!FFFFFF] |       " ansi_type @ mcc_convert
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
      "| [*AAAAAA][#000000]Black[!FFFFFF]        [*000000][#555555]Dark Grey[!FFFFFF]    |  | 3  | Yellow         | #AA5500 | 170  85   0 |" ansi_type @ mcc_convert
      "| [*000000][#AA0000]Dim Red[!FFFFFF]      [*000000][#FF5555]Pale Red[!FFFFFF]     |  | 4  | Blue           | #0000AA |   0   0 170 |" ansi_type @ mcc_convert
      "| [*000000][#00AA00]Dim Green[!FFFFFF]    [*000000][#55FF55]Pale Green[!FFFFFF]   |  | 5  | Magenta        | #AA00AA | 170   0 170 |" ansi_type @ mcc_convert
      "| [*000000][#AA5500]Dim Brown[!FFFFFF]    [*000000][#FFFF55]Pale Yellow[!FFFFFF]  |  | 6  | Cyan           | #00AAAA |   0 170 170 |" ansi_type @ mcc_convert
      "| [*000000][#0000AA]Dim Blue[!FFFFFF]     [*000000][#5555FF]Pale Blue[!FFFFFF]    |  | 7  | White          | #AAAAAA | 170 170 170 |" ansi_type @ mcc_convert
      "| [*000000][#AA00AA]Dim Magenta[!FFFFFF]  [*000000][#FF55FF]Pale Magenta[!FFFFFF] |  | 8  | Bright Black   | #555555 |  85  85  85 |" ansi_type @ mcc_convert
      "| [*000000][#00AAAA]Dim Cyan[!FFFFFF]     [*000000][#55FFFF]Pale Cyan[!FFFFFF]    |  | 9  | Bright Red     | #FF5555 | 255  85  85 |" ansi_type @ mcc_convert
      "| [*000000][#AAAAAA]White[!FFFFFF]        [*000000][#FFFFFF]White[!FFFFFF]        |  | 10 | Bright Green   | #55FF55 |  85 255  85 |" ansi_type @ mcc_convert
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
      "|  [*AAAAAA][#000000]Black[!FFFFFF]    [*000000][#808080]Dark Grey[!FFFFFF]       |  | 3  | Yellow         | #808000 | 128 128   0 |" ansi_type @ mcc_convert
      "|  [*000000][#800000]Red[!FFFFFF]      [*000000][#FF0000]Bright Red[!FFFFFF]      |  | 4  | Blue           | #000080 |   0   0 128 |" ansi_type @ mcc_convert
      "|  [*000000][#008000]Green[!FFFFFF]    [*000000][#00FF00]Bright Green[!FFFFFF]    |  | 5  | Magenta        | #800080 | 128   0 128 |" ansi_type @ mcc_convert
      "|  [*000000][#808000]Yellow[!FFFFFF]   [*000000][#FFFF00]Bright Yellow[!FFFFFF]   |  | 6  | Cyan           | #008080 |   0 128 128 |" ansi_type @ mcc_convert
      "|  [*000000][#000080]Blue[!FFFFFF]     [*000000][#0000FF]Bright Blue[!FFFFFF]     |  | 7  | White          | #C0C0C0 | 192 192 192 |" ansi_type @ mcc_convert
      "|  [*000000][#800080]Magenta[!FFFFFF]  [*000000][#FF00FF]Bright Magenta[!FFFFFF]  |  | 8  | Bright Black   | #808080 | 128 128 128 |" ansi_type @ mcc_convert
      "|  [*000000][#008080]Cyan[!FFFFFF]     [*000000][#00FFFF]Bright Cyan[!FFFFFF]     |  | 9  | Bright Red     | #FF0000 | 255   0   0 |" ansi_type @ mcc_convert
      "|  [*000000][#C0C0C0]White[!FFFFFF]    [*000000][#FFFFFF]White[!FFFFFF]           |  | 10 | Bright Green   | #00FF00 |   0 255   0 |" ansi_type @ mcc_convert
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
      "    |       [*AAAAAA][#000000]Black[!FFFFFF]       |      | 0  | Black          | #000000 |   0   0   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#AA0000]Red[!FFFFFF]         |      | 1  | Red            | #AA0000 | 170   0   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#00AA00]Green[!FFFFFF]       |      | 2  | Green          | #00AA00 |   0 170   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#AA5500]Brown[!FFFFFF]       |      | 3  | Yellow         | #AA5500 | 170  85   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#0000AA]Blue[!FFFFFF]        |      | 4  | Blue           | #0000AA |   0   0 170 |" ansi_type @ mcc_convert
      "    |       [*000000][#AA00AA]Magenta[!FFFFFF]     |      | 5  | Magenta        | #AA00AA | 170   0 170 |" ansi_type @ mcc_convert
      "    |       [*000000][#00AAAA]Cyan[!FFFFFF]        |      | 6  | Cyan           | #00AAAA |   0 170 170 |" ansi_type @ mcc_convert
      "    |       [*000000][#AAAAAA]White[!FFFFFF]       |      | 7  | White          | #AAAAAA | 170 170 170 |" ansi_type @ mcc_convert
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
      "    |       [*C0C0C0][#000000]Black[!FFFFFF]       |      | 0  | Black          | #000000 |   0   0   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#800000]Red[!FFFFFF]         |      | 1  | Red            | #800000 | 128   0   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#008000]Green[!FFFFFF]       |      | 2  | Green          | #008000 |   0 128   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#808000]Brown[!FFFFFF]       |      | 3  | Yellow         | #808000 | 128 128   0 |" ansi_type @ mcc_convert
      "    |       [*000000][#000080]Blue[!FFFFFF]        |      | 4  | Blue           | #000080 |   0   0 128 |" ansi_type @ mcc_convert
      "    |       [*000000][#800080]Magenta[!FFFFFF]     |      | 5  | Magenta        | #800080 | 128   0 128 |" ansi_type @ mcc_convert
      "    |       [*000000][#008080]Cyan[!FFFFFF]        |      | 6  | Cyan           | #008080 |   0 128 128 |" ansi_type @ mcc_convert
      "    |       [*000000][#C0C0C0]White[!FFFFFF]       |      | 7  | White          | #C0C0C0 | 192 192 192 |" ansi_type @ mcc_convert
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
      source_string @ "[!000001]" "[" subst exit
      source_string @ "[!000002]" "]" subst exit
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

