package Games::Traveller::UwpTools;

use 5.008003;
use Games::Traveller::UWP;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();
our $VERSION = '0.93';

###############################################################
#
#   Package Logic
#
###############################################################
{   
   srand (time ^ (($$ << 15) + $$));
   my @hex   = ( 0..9, 'A'..'H', 'J'..'N', 'P'..'Z' );
   my %hex2dec = ();
   for( my $i=0; $i<@hex; $i++ ) { $hex2dec{$hex[$i]} = "$i" ; }

   sub new { bless{}, shift; }
   
   sub dice 
   { 
      my $dm = shift || 0;
      return $dm + int(rand(6)+1) + int(rand(6)+1);
   }

   ############################################################################
   #
   #   Distance calculations
   #
   ############################################################################
   
   #
   #   Return the distance between two hexes
   #
   sub distance($$$)
   {
      my $self = shift;
      my $uwp1 = shift;
      my $uwp2 = shift;
      
      my ($row1, $col1) = ($uwp1->row, $uwp1->col);
      my ($row2, $col2) = ($uwp2->row, $uwp2->col);

      return _distance( $row1, $col1, $row2, $col2 );      
   }

   sub _distance
   {
      my ($row1, $col1, $row2, $col2) = @_;

      print "($row1 $col1) - ($row2 $col2)\n";
      
      my $a1 = ($row1 + int($col1/2));
      my $a2 = ($row2 + int($col2/2));
   
      my $d1 = abs( $a1 - $a2 );
      my $d2 = abs( $col1 - $col2 );
      my $d3 = abs( ($a1 - $col1) - ( $a2 - $col2 ) );
        
      return (reverse sort { $a <=> $b } ( $d1, $d2, $d3 ))[0];      
   }
   
   #
   #   Return the distance between two hexes in potentially different sectors
   #
   sub galacticDistance($$$$$)
   {
      my $self    = shift;
      my $uwp1    = shift;
      my $sector1 = shift;
      my $uwp2    = shift;
      my $sector2 = shift;
      
      my ($row1, $col1) = $self->getGalacticCoords( $uwp1, $sector1 );
      my ($row2, $col2) = $self->getGalacticCoords( $uwp2, $sector2 );
      
      $col1 -= 62833 if $col1 > 31415;
      $col2 -= 62833 if $col2 > 31415;
            
      return _distance( $row1, $col1, $row2, $col2 );
   }
   
   sub getGalacticCoords
   {
      my $self   = shift;
      my $uwp    = shift;
      my $sector = shift;
      
      my %ringray = 
      (
         'gvurrdon'        => [ 9880   ,  62704 ],
         'tuglikki'        => [ 9880   ,  62736 ],
         'spinward marches'=> [ 9920   ,  62704 ],
         'deneb'           => [ 9920   ,  62736 ],
         'corridor'        => [ 9920   ,  62768 ],
         'vland'           => [ 9920   ,  62800 ],
         'lishun'          => [ 9920   ,  62832 ],
         'antares'         => [ 9920   ,  62864 ],
         'trojan reaches'  => [ 9960   ,  62704 ],
         'reft'            => [ 9960   ,  62736 ],
         'gushemege'       => [ 9960   ,  62768 ],
         'dagudashaag'     => [ 9960   ,  62800 ],
         'core'            => [ 9960   ,  62832 ],
         'riftspan'        => [ 10000  ,  62704 ],
         'verge'           => [ 10000  ,  62736 ],
         'ilelish'         => [ 10000  ,  62768 ],
         'zarushagar'      => [ 10000  ,  62800 ],
         'massilia'        => [ 10000  ,  62832 ],
         'delphi'          => [ 10000  ,  62864 ],
         'reavers deep'    => [ 10040  ,  62768 ],
         'daibei'          => [ 10040  ,  62800 ],
         'diaspora'        => [ 10040  ,  62832 ],
         'old expanses'    => [ 10040  ,  62864 ],
         'dark nebula'     => [ 10080  ,  62768 ],
         'magyar'          => [ 10080  ,  62800 ],
         'solomani rim'    => [ 10080  ,  62832 ],
         'alpha crucis'    => [ 10080  ,  62864 ],
      );
      
      my ($ringoff, $rayoff) = @{$ringray{ lc $sector }};
            
      my ($ring, $ray) = ($ringoff + $uwp->row, 
                          $rayoff  + $uwp->col);
      
      $ray  -= 62832 if $ray  > 62832;      
            
      return ($ring, $ray);
   }

   ############################################################################
   #
   #   Generation methods
   #
   ############################################################################
  
   sub deeprift  { $_[0]->_sysgen( 0.008 ); }
   sub rift      { $_[0]->_sysgen( 0.027 ); }
   sub sparse    { $_[0]->_sysgen( 0.160 ); }
   sub scattered { $_[0]->_sysgen( 0.330 ); }
   sub standard  { $_[0]->_sysgen( 0.500 ); } 
   sub dense     { $_[0]->_sysgen( 0.667 ); }
   sub _sysgen
   {
      my $self = shift;
      my $p    = shift;
      return $self->generateSystem() if rand() < $p;
      undef;
   }

   sub generateSystem
   {
   	my $self    = shift;
      my $mwref   = $self->randomUWP();
      my $starref = $self->star( $mwref );
      
      return
      {
         'mainworld' => $mwref,
         'primary'   => $starref
      };
   }
         
   sub randomUwp
   { 
      my $self  = shift;
      my $uwp   = new Games::Traveller::UWP;
      my @belts = ( 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3 );
      my @ggs   = ( 0, 0, 0, 0, 1, 1, 2, 2, 3, 4, 5 );
 
      $uwp->name       = shift || '';
      $uwp->loc        = shift || '0000';
      $uwp->bases      = '';
      $uwp->codes      = '';
      $uwp->zone       = '';
      $uwp->popMult    = 0;
      $uwp->belts      = $belts[ rand(@belts) ];
      $uwp->ggs        = $ggs[ rand(@ggs) ];
      $uwp->allegiance = 'Un';
      $uwp->starData   = [[],[],[],[]];
    
      my @atmosDM = ( 0, (1) x 16 );
      my @hydroDM = (-4,-4, 0, 0, 0, 0, 0, 0, 0, 0,-4,-4,-4, 0, 0, 0, 0 );

      $uwp->starport      = 'E';
      $uwp->size          = dice(-2);
      $uwp->atmosphere    = dice(-10 + $uwp->size)
                                      * $atmosDM[$uwp->size];
      $uwp->atmosphere    = 0 if $uwp->atmosphere < 0;
      
      $uwp->hydrographics = dice(-7  + $uwp->atmosphere
                                      + $hydroDM[$uwp->atmosphere])
                                      * $atmosDM[$uwp->size];
      $uwp->hydrographics = 0 if $uwp->hydrographics < 0;
            
      my $dm = -2;
         $dm = -1 if $uwp->atmosphere =~ /[468]/;
      
      $uwp->popDigit      = dice($dm);
      $uwp->popMult       = int(rand(9)+1);
      $uwp->popMult       = 0 if $uwp->popDigit == 0;
      $uwp->government    = dice(-7 + $uwp->popDigit   );
      $uwp->government    = 0 if $uwp->government < 0;
      $uwp->law           = dice(-7 + $uwp->government );
      $uwp->law           = 0 if $uwp->law < 0;
      
      $uwp->tl            = int(rand($uwp->popDigit));
      $uwp->tl++    if $uwp->popDigit > 8;
      $uwp->tl++    if $uwp->size     < 4;
      $uwp->tl++    if $uwp->atmosphere =~ /[579]/;
      $uwp->tl += 3 if $uwp->atmosphere =~ /[0123ABC]/;
      $uwp->tl += 2 if $uwp->hydrographics =~ /[0A]/;
            
      if ( $uwp->tl =~ /[123456]/ )
      {
         $uwp->size      += 5 if $uwp->size < 3;
         $uwp->atmosphere = 7 if $uwp->atmosphere !~ /[456789A]/;
      }

      $uwp->size          = $hex[ $uwp->size ];
      $uwp->atmosphere    = $hex[ $uwp->atmosphere ];
      $uwp->hydrographics = $hex[ $uwp->hydrographics ];
      $uwp->popDigit      = $hex[ $uwp->popDigit ];
      $uwp->government    = $hex[ $uwp->government ];
      $uwp->law           = $hex[ $uwp->law ];      
      $uwp->tl            = $hex[ $uwp->tl ];
      
      $uwp->regenerateTradeCodes()->alphabetizeTradeCodes();
      
      $uwp->starData = $self->genStars( $uwp );
      
      return $uwp;   
   }

=pod                                                                                 
                                                                                     
       generateStars()                                                                    
                                                                                     
       This function returns the star types and relative positions                   
       for a system in an arrayref of four arrayrefs, each corresponding
       to the primary, near-companion stars, far primary, 
       and far near-companion stars. 
                                                                                     
       NOTE: The "primary" is here defined as the star that                           
       the mainworld is orbiting.                                                    
                                                                                     
=cut                                                                                 

   sub generateStars
   {
      my $self = shift;
      my $uwp  = shift;
      my @config = _getConfiguration($uwp);
               
      my @nears = _getTypeAndSize( $uwp, 'Prime' );
      for( 1..$config[1] )
      {
         push @nears, _getTypeAndSize( $uwp, 'Near' );
      }
      @nears = sort _byStar @nears;
 
      my @primary = shift @nears;
      push @primary, _getTypeAndSize( $uwp, 'Close' ) if $config[0] == 2;
      @primary  = sort _byStar @primary;
      $primary[0] =~ s/\*//;
           
      my @far = ();
      push @far, _getTypeAndSize( $uwp, 'Far'   ) if $config[2] > 0;
      push @far, _getTypeAndSize( $uwp, 'Close' ) if $config[2] == 2;
      @far = sort _byStar @far;
      
      my @farcomps = ();
      for( 1..$config[3] )
      {
         push @farcomps, _getTypeAndSize( $uwp, 'Near' );
      }
      @farcomps = sort _byStar @farcomps;
          
      $uwp->starData = [ \@primary, \@nears, \@far, \@farcomps ];
   }

   sub _getConfiguration
   {
      my %nice = 
      (
         0.6      => [ 1, 0, 0, 0 ],
         0.059    => [ 1, 0, 1, 0 ],
         0.00050  => [ 1, 0, 1, 1 ],
         0.00002  => [ 1, 0, 1, 2 ],
         0.00023  => [ 1, 0, 2, 0 ],
         0.000018 => [ 1, 0, 2, 1 ],
         0.000002 => [ 1, 0, 2, 2 ],

         0.311    => [ 1, 1, 0, 0 ],
         0.011    => [ 1, 1, 1, 0 ],
         0.00288  => [ 1, 1, 1, 1 ],
         0.00002  => [ 1, 1, 1, 2 ],
         0.0010   => [ 1, 1, 2, 0 ],
         0.00018  => [ 1, 1, 2, 1 ],
         0.00002  => [ 1, 1, 2, 2 ],

         0.014    => [ 1, 2, 0, 0 ],
         0.000800 => [ 1, 2, 1, 0 ],
         0.000180 => [ 1, 2, 1, 1 ],
         0.000020 => [ 1, 2, 1, 2 ],
         0.000016 => [ 1, 2, 2, 0 ],
         0.000003 => [ 1, 2, 2, 1 ],
         0.000001 => [ 1, 2, 2, 2 ],
      );
      
      my %ugly =
      (
         0.6      => [ 1, 0, 0, 0 ],
         0.0111   => [ 1, 0, 1, 0 ],
         0.00008  => [ 1, 0, 1, 1 ],
         0.00002  => [ 1, 0, 1, 2 ],
         0.00004  => [ 1, 0, 2, 0 ],
         0.000008 => [ 1, 0, 2, 1 ],
         0.000002 => [ 1, 0, 2, 2 ],

         0.33     => [ 1, 1, 0, 0 ],
         0.0098   => [ 1, 1, 1, 0 ],
         0.00180  => [ 1, 1, 1, 1 ],
         0.00020  => [ 1, 1, 1, 2 ],
         0.0009   => [ 1, 1, 2, 0 ],
         0.00008  => [ 1, 1, 2, 1 ],
         0.00002  => [ 1, 1, 2, 2 ],

         0.014    => [ 1, 2, 0, 0 ],
         0.0002   => [ 1, 2, 1, 0 ],
         0.00030  => [ 1, 2, 1, 1 ],
         0.00007  => [ 1, 2, 1, 2 ],
         0.000007 => [ 1, 2, 2, 0 ],
         0.000002 => [ 1, 2, 2, 1 ],
         0.000001 => [ 1, 2, 2, 2 ],

         0.029    => [ 2, 0, 0, 0 ],
         0.0013   => [ 2, 0, 1, 0 ],
         0.00032  => [ 2, 0, 1, 1 ],
         0.00002  => [ 2, 0, 1, 2 ],
         0.00013  => [ 2, 0, 2, 0 ],
         0.000008 => [ 2, 0, 2, 1 ],
         0.000002 => [ 2, 0, 2, 2 ],

         0.00063  => [ 2, 1, 0, 0 ],
         0.000005 => [ 2, 1, 1, 0 ],
         0.000005 => [ 2, 1, 1, 1 ],
         0.000004 => [ 2, 1, 1, 2 ],
         0.000003 => [ 2, 1, 2, 0 ],
         0.000002 => [ 2, 1, 2, 1 ],
         0.000001 => [ 2, 1, 2, 2 ],
         
         0.000700 => [ 2, 2, 0, 0 ],
         0.000090 => [ 2, 2, 1, 0 ],
         0.000008 => [ 2, 2, 1, 1 ],
         0.000002 => [ 2, 2, 1, 2 ],
         0.000090 => [ 2, 2, 2, 0 ],
         0.000008 => [ 2, 2, 2, 1 ],
         0.000002 => [ 2, 2, 2, 2 ],
      );

      my $uwp   = shift;
      my %table = ($uwp->isNice())? %nice : %ugly;
      
      my $num   = rand();
      my $total = 0;
      my $key   = '';
      
      foreach( sort keys %table )
      {
         $key    = $_;
         $total += $_;
         last if $total > $num;
      }
      
      return @{$table{$key}};
   }
      
   sub _getTypeAndSize
   {
      my @type   = qw/ B  B  A  M  M   M  M M M K G F K G G G G G G G G/;
      my @size   = qw/ I  VI D  II III IV V V V V V V V V V V V V V V V/;
      my $uwp  = shift;
      my $star = shift;
      
      #
      #  Primary star
      #
      
      return $type[ dice(+4) ] . ' ' . $size[ dice(+4) ] . '*'
         if $star eq 'Prime' && $uwp->isNice(); 
      
      #
      #  Companion stars
      #
         
      my $size = $size[ dice() ];
      my $type = $type[ dice() ];
      
      $size = 'V' if ($size eq 'D' || $size eq 'II' || $size eq 'III' )
                  && ($type eq 'A' || $type eq 'F'  || $type eq 'G' );
                  
      $size = 'V' if $size eq 'D' && $star eq 'Prime' && $uwp->isaRock();
      $size = 'V' if $type eq 'M' && $size eq 'IV';
      $size = 'V' if $type eq 'K' && $size eq 'IV';
      
      my $out = "$type $size";  # ($size eq 'D')? 'D' : 
      $out .= '*' if $star eq 'Prime';
      
      return $out;
   }
         
   my %ssz = 
   (
      'I'   => 100,
      'II'  => 200,
      'III' => 300,
      'IV'  => 400,
      'V'   => 500,
      'VI'  => 600,
      'D'   => 700,
   );
   
   my %styp =
   (
      'O' => 10,
      'B' => 20,
      'A' => 30,
      'F' => 40,
      'G' => 50,
      'K' => 60,
      'M' => 70,
   );
   
   sub _splitStar
   {
      return ( $1, $2, $3) if $_[0] =~ /(\w)(\d?) (\w+)/;
      return ('A','0','D') if $_[0] =~ /D/;
   }
   
   #
   #   Returns the comparison value of two stars.
   #
   sub _byStar
   {      
      my ($atype, $amag, $asize) = _splitStar($a);
      my ($btype, $bmag, $bsize) = _splitStar($b);
      
      $amag = 0 unless $amag;
      $bmag = 0 unless $bmag;
      
      return -1 if ! $ssz{$bsize} || ! $styp{$btype};
      return  1 if ! $ssz{$asize} || ! $styp{$atype};

      my $ak = $ssz{$asize} + $styp{$atype} + $amag;
      my $bk = $ssz{$bsize} + $styp{$btype} + $bmag;  
      
      return $ak <=> $bk;
   }
   
   ############################################################################
   #
   #   World classification
   #
   ############################################################################

   
   sub classifyWorld
   {
         my @worldtypes =
         (
         ['Molten'   ,'Mln' ,{ 'size' => '.',     'atm' => '[0BC]',  'hyd' => 'A', 'pri' => '.',     'orbit' => 'Close'    }],
         ['Metallic' ,'Mtc' ,{ 'size' => '.',     'atm' => '1',      'hyd' => '0', 'pri' => '[OBA]', 'orbit' => 'Close'    }],
         ['Metallic' ,'Mtc' ,{ 'size' => '.',     'atm' => '0',      'hyd' => '0', 'pri' => 'F',     'orbit' => 'Close'    }],
         ['Metallic' ,'Mtc' ,{ 'size' => '.',     'atm' => '[BC]',   'hyd' => '.', 'pri' => '.',     'orbit' => 'Warm'     }],
         ['Mercurial','Mrl' ,{ 'size' => '.',     'atm' => '0',      'hyd' => '0', 'pri' => '.',     'orbit' => 'Outer'    }],
         ['Mercurial','Mrl' ,{ 'size' => '.',     'atm' => '1',      'hyd' => '0', 'pri' => '.',     'orbit' => 'Close'    }],
         ['Lunar'    ,'Lnr' ,{ 'size' => '.',     'atm' => '0',      'hyd' => '0', 'pri' => '.',     'orbit' => 'Any'      }],
         ['Iceball'  ,'Icl' ,{ 'size' => '.',     'atm' => '[0-2]',  'hyd' => '[1-9]','pri' => '[^KM]', 'orbit' => 'Outer'    }],
         ['Iceball'  ,'Icl' ,{ 'size' => '.',     'atm' => '[0-2]',  'hyd' => '[1-9]','pri' => '[KM]',  'orbit' => 'Any'      }],
         ['Europan'  ,'Ern' ,{ 'size' => '.',     'atm' => '[01]',   'hyd' => '[1-9]','pri' => '.',     'orbit' => 'Warm'     }],
         ['Thalassic','Ptc' ,{ 'size' => '[A-F]', 'atm' => '[A-F]',  'hyd' => 'A', 'pri' => '.',     'orbit' => 'Snowline' }],
         ['Martian'  ,'Mrn' ,{ 'size' => '[1-4]', 'atm' => '[1234]', 'hyd' => '[012]','pri' => '[FGK]', 'orbit' => 'Snowline' }],
         ['Venus I'  ,'Vn1' ,{ 'size' => '.',     'atm' => '[A-F]',  'hyd' => '[01]', 'pri' => '[FG]',  'orbit' => 'Snowline' }],
         ['Venus II' ,'Vn2' ,{ 'size' => '.',     'atm' => '[A-F]',  'hyd' => '0', 'pri' => '[FG]',  'orbit' => 'Snowline' }],
         ['Terran Ia','T1a' ,{ 'size' => '.',     'atm' => '.',      'hyd' => '0', 'pri' => '.',     'orbit' => 'Snowline' }],
         ['Terran Ib','T1b' ,{ 'size' => '.',     'atm' => '[^0]',   'hyd' => '[^0]', 'pri' => '.',     'orbit' => 'Snowline' }],
         ['Terran II','Tr2' ,{ 'size' => '.',     'atm' => '[^012]', 'hyd' => '[^0]', 'pri' => '[FG]',  'orbit' => 'Hab-Zone' }],
         ['T Prime'  ,'Tpm' ,{ 'size' => '[6-9]', 'atm' => '[4-9]',  'hyd' => '[3-9]','pri' => '[FG]',  'orbit' => 'Hab-Zone' }],
         ['T Norm'   ,'Tnm' ,{ 'size' => '[789]', 'atm' => '[67]',   'hyd' => '[567]','pri' => '[FG]',  'orbit' => 'Hab-Zone' }],
         ['T Tundric','Tnd' ,{ 'size' => '[6-9]', 'atm' => '[4-9]',  'hyd' => '[3-9]','pri' => '[FG]',  'orbit' => 'Snowline' }],
         ['T Tundric','Tnd' ,{ 'size' => '[6-9]', 'atm' => '[4-9]',  'hyd' => '[3-9]','pri' => '[KM]',  'orbit' => 'Hab-Zone' }],
         ['Terran IV','Tr4' ,{ 'size' => '.',     'atm' => '[0-A]',  'hyd' => '[012]','pri' => '.',     'orbit' => 'Snowline' }],
         ['Terran IV','Tr4' ,{ 'size' => '.',     'atm' => '[0-A]',  'hyd' => '[012]','pri' => '[KM]',  'orbit' => 'Close'    }],
         ['T-form'   ,'Tfm' ,{ 'size' => '.',     'atm' => '[4-9]',  'hyd' => '[0-9]','pri' => '[KM]',  'orbit' => 'Hab-Zone' }],
         ['T-form'   ,'Tfm' ,{ 'size' => '.',     'atm' => '[4-9]',  'hyd' => '[0-9]','pri' => '[OBA]', 'orbit' => 'Snowline' }],
         );

   	 my $self = shift;
   	 my $uwp  = shift;
   	 
      my $wsize    = $uwp->size;
      my $watm     = $uwp->atmosphere;
      my $whyd     = $uwp->hydrographics;
      my $wprimary = $uwp->primary->[0];
      
      my @matches = ();
      
      my $source = $wsize . $watm . $whyd . ' ' . $wprimary;
      
      foreach my $type ( @worldtypes )
      {
         my $match = _matches( $source, $type );
         push @matches, $match if $match;      
      }
         
      push @matches, shift @matches if $watm =~ /[2468]/;
      push @matches, [ '', '', '' ] unless @matches;
      
      return @matches;
   }
   
   sub _matches
   {
      my $source = shift;
      my $type   = shift;
      
      my $size  = $$type[2]->{size};
      my $atm   = $$type[2]->{atm};
      my $hyd   = $$type[2]->{hyd};
      my $pri   = $$type[2]->{pri};
      my $orbit = $$type[2]->{orbit};
        
      my $pattern = $size . $atm . $hyd . ' '. $pri;
      
      return [ $$type[0], $$type[1], $orbit ] if $source =~ m/$pattern/; 
   } 
}
1;

__END__

=head1 NAME

Games::Traveller::UwpTools - Tools for Universal World Profile (UWP) manipulation for the Traveller role-playing game.

=head1 SYNOPSIS

   This package requires Games::Traveller::UWP.pm.
   
   my $uwp1 = new Games::Traveller::UWP;
   my $uwp2 = new Games::Traveller::UWP;
   
   my $ut   = new Games::Traveller::UwpTools;

   $uwp1->readUwp( 'Foodle   1910 A000000-0 M Ri In     023 Im K7 V' );
   $uwp2->readUwp( 'Blarney  0524 B123456-7             400 Im K7 V' );

   # distance calculations
      
   print $ut->distance( $uwp1, $uwp2 );
   print $ut->galacticDistance( $uwp1, 'spinward marches',
                                $uwp2, 'vland' );

 
   # random UWP
   
   $ut->randomUwp( $uwp );
   
   print $uwp->toString(), "\n";
   
   # revised stellar generation
   
   $ut->generateStars( $uwp );
   
   print $uwp->stars;
   
   # world classification
   
   my @cn = $ut->classifyWorld( $uwp );

   print $uwp->toString(), ' ', $cn[0]->[0], "\n";
                                   
   

=head1 DESCRIPTION

The UwpTools package is a utilitu module for UWP manipulation.  With it,
you can do distance calculation (even across sectors), random UWP generation,
Revised Stellar Generation, and World Classification.

=head1 OVERVIEW OF CLASS AND METHODS

To create an instance:

   my $ut = new Games::Traveller::UwpTools;

   The utility methods are: 

=over 3

   $ut->distance( $uwp1, $uwp2 )
   returns the number of parsecs between the two.
   
   $ut->galacticDistance( $uwp1, $sector1, $uwp2, $sector2 )
   returns the number of parsecs between the two.
   At least these sectors are currently supported:
   
      'gvurrdon'        
      'tuglikki'        
      'spinward marches'
      'deneb'           
      'corridor'        
      'vland'           
      'lishun'          
      'antares'         
      'trojan reaches'  
      'reft'            
      'gushemege'       
      'dagudashaag'     
      'core'            
      'riftspan'        
      'verge'           
      'ilelish'         
      'zarushagar'      
      'massilia'        
      'delphi'          
      'reavers deep'    
      'daibei'          
      'diaspora'        
      'old expanses'    
      'dark nebula'     
      'magyar'          
      'solomani rim'    
      'alpha crucis'    

   $ut->randomUwp() returns a new, random UWP

   $ut->generateStars( $uwp ) uses Malenfant's Revised Stellar 
   Generation System to generate the stars for this system.
   This method is slightly 'enhanced', in that it is (slightly)
   possible to generate more stars than Malenfant's system.
      
   $ut->classifyWorld( $uwp ) attempts to classify the potential
   world types this UWP would fit under.  The method returns
   an array of array references.  Each array reference contains
   the following elements:
   
   [ classification, abbreviation, orbit ]
   
   where
   
   classification is the string classification match,
   abbreviation is the abbreviation for the classification,
   and orbit is the orbit this classification requires.
   
=back
      
=head1 AUTHOR

  Pasuuli Immuguna

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN.

=cut
