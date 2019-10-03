#!/usr/bin/perl
use strict;

my %pos_to_val = (
  0 => 0,
  1 => 95,
  2 => 135,
  3 => 175,
  4 => 215,
  5 => 255,
);

my $color_num;

for (my $red = 0; $red < 6; $red++) {
  for (my $green = 0; $green < 6; $green++) {
    for (my $blue = 0; $blue < 6; $blue++) {
      $color_num = 16 + 36 * $red + 6 * $green + $blue;
      printf("%-3d #%02X%02X%02X\n", $color_num, $pos_to_val{$red}, $pos_to_val{$green}, $pos_to_val{$blue});
    }
  }
}

for (my $grey = 0; $grey < 24; $grey++) {
  $color_num = 232 + $grey;
  my $lightness = 8 + 10 * $grey;
  printf("%-3d #%02X%02X%02X\n", $color_num, $lightness, $lightness, $lightness);
}

print "\n\n";

print '      "       +------------------------ ANSI-8BIT ---------------------------+       "' . "\n";
for (my $red = 0; $red < 6; $red++) {
  for (my $green = 0; $green < 6; $green++) {
    unless ($green % 2) {
      print("      \"       | ");
    }
    for (my $blue = 0; $blue < 6; $blue++) {
      $color_num = 16 + 36 * $red + 6 * $green + $blue;
      #printf("%d -> %d, %d, %d\n", $color_num, $pos_to_val{$red}, $pos_to_val{$green}, $pos_to_val{$blue});
      printf("#MCC-B-%02X%02X%02X %-3d ", $pos_to_val{$red}, $pos_to_val{$green}, $pos_to_val{$blue}, $color_num);
    }
    if ($green % 2) {
      print("#MCC-X-000000 |       \" ansi_type @ mcc_convert\n");
    }
  }
  #print '      "' . ' ' x 64 . '"' . "\n";
}

print("      \"       | ");
for (my $grey = 0; $grey < 24; $grey++) {
  $color_num = 232 + $grey;
  my $lightness = 8 + 10 * $grey;
  #printf("%d -> %d, %d, %d\n", $color_num, $lightness, $lightness, $lightness);
  printf("#MCC-B-%02X%02X%02X %-3d ", $lightness, $lightness, $lightness, $color_num);
  if ($grey == 11) {
    print("#MCC-X-000000 |       \" ansi_type @ mcc_convert\n      \"       | ");
  }
}
print("#MCC-X-000000 |       \" ansi_type @ mcc_convert\n");

print '      "       +--------------------------------------------------------------+       "' . "\n";

print "\n\n";

print '      "     +--------------------------- ANSI-24BIT ---------------------------+     "' . "\n";
for (my $color = 0; $color < 3; $color++) {
  for (my $row = 0; $row < 4; $row++) {
    print '      "     | ';
    for (my $column = 0; $column < 64; $column++) {
      my $intensity = $row + ($column * 4);
      if ($color == 0) {
        printf('#MCC-B-%02X0000 ', "$intensity ");
      } elsif ($color == 1) {
        printf('#MCC-B-00%02X00 ', "$intensity ");
      } else {
        printf('#MCC-B-0000%02X ', "$intensity ");
      }
    }
    print "#MCC-X-000000 |     \" ansi_type @ mcc_convert\n";
  }
  #print '      "' . ' ' x 64 . '"' . "\n";
}
print '      "     +-' . '-' x 64 . '-+     "' . "\n";
