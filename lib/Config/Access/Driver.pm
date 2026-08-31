#
# @author Bodo (Hugo) Barwich
# @version 2026-08-31
# @package Conig::Access::Driver
# @subpackage lib/Config/Access/Driver.pm

# This Module defines Classes to manage Data of an INI configuration section
#
#---------------------------------
# Requirements:
#
#---------------------------------
# Features:
#

use Config::Section::List;

#==============================================================================
# The Config::Access::Driver Package

package Config::Access::Driver;

#----------------------------------------------------------------------------
#Dependencies

use parent 'File::Access::Driver';

use Scalar::Util 'blessed';

use Data::Dump qw(dump);

#----------------------------------------------------------------------------
#Static Methods

sub readConfigSectionList {
    my $cfgfl = undef;

    my %hshprms = undef;

    #Return the Section List
    my $lstsecs = undef;

    if ( scalar(@_) > 1 ) {

        #Take the Method Parameters
        %hshprms = @_;
    }
    else {
        #One single Parameter
        %hshprms = ( 'filepath' => $_[0] );
    }

    $cfgfl = Config::Access::Driver::new( 'ConfigAccessDriver', %hshprms );

    $cfgfl->setFilePath( $hshprms{'filepath'} );

    $lstsecs = $cfgfl->readList;

    #Free the System Resources
    $cfgfl->freeResources;

    return $lstsecs;
}

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $class = ref( $_[0] ) || $_[0];
    my $self  = undef;

    #Pass through the Method Parameters
    $self = $class->SUPER::new( @_[ 1 .. $#_ ] );

    $self->{'_list_sections'} = undef;

    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub setList {
    my $self = $_[0];

    if ( scalar(@_) > 1 ) {
        $self->{'_list_sections'} = $_[1]
          if ( defined blessed $_[1] );

    }

    if ( defined $self->{'_list_sections'} ) {
        $self->{'_list_sections'} = undef
          unless ( $self->{'_list_sections'}->isa('ConfigSectionList') );

    }
}

sub Read {
    my $self      = $_[0];
    my $rarrcntnt = undef;
    my $irs       = 0;

    if ( defined $self->{'_list_sections'} ) {

        #Clean the Section List for new Content
        $self->{'_list_sections'}->clearList;
    }
    else {
        #Create a New Section List
        $self->{'_list_sections'} = new Config::Section::List::;
    }

    #Read the File Content into an Array
    $rarrcntnt = File::Access::Driver::readContentArray $self ;

    return if ( !defined $rarrcntnt
        || ref($rarrcntnt) ne 'ARRAY' );

    my $iln    = -1;
    my $ilncnt = scalar(@$rarrcntnt);

    return $irs if ( $ilncnt < 1 );

    my $cfgsec    = undef;
    my $scntntky  = "";
    my $scntntvl  = "";
    my $isqstrtps = -1;
    my $isqendps  = -1;
    my $ieqlps    = -1;
    my $icmtps    = -1;

    for ( $iln = 0 ; $iln < $ilncnt ; $iln++ ) {
        $icmtps = index( $rarrcntnt->[$iln], "#" );

        if ( $icmtps > 0 ) {

            #print "cmt hit: '$icmtps'\n";

            $rarrcntnt->[$iln] =
              substr( $rarrcntnt->[$iln], 0, $icmtps );

            #print "cmt cleaned: '" . $rarrcntnt->[$iln] . "'\n";
        }
        elsif ( $icmtps == 0 ) {

            #print "cmt skip: '" . $rarrcntnt->[$iln] . "'\n";
            $rarrcntnt->[$iln] = "";
        }

        $rarrcntnt->[$iln] =~ s/^[[:space:]]+//;
        $rarrcntnt->[$iln] =~ s/[[:space:]]+$//;

        if ( $rarrcntnt->[$iln] ne "" ) {
            $ieqlps    = index( $rarrcntnt->[$iln], "=" );
            $isqstrtps = index( $rarrcntnt->[$iln], "[" );
            $isqendps  = index( $rarrcntnt->[$iln], "]" );

            if (   $isqstrtps > -1
                && $isqendps > -1
                && !( $ieqlps > -1 && $isqstrtps > $ieqlps ) )
            {
                #It's a Section Header

                $rarrcntnt->[$iln] = substr(
                    $rarrcntnt->[$iln],
                    $isqstrtps + 1,
                    $isqendps - $isqstrtps - 1
                );

                $rarrcntnt->[$iln] =~ s/^[[:space:]]+//;
                $rarrcntnt->[$iln] =~ s/[[:space:]]+$//;

                $cfgsec = $self->{'_list_sections'}
                  ->getConfigSectionbyName( $rarrcntnt->[$iln] );

                #Create a New Section
                $cfgsec = $self->{'_list_sections'}->Add( $rarrcntnt->[$iln] )
                  unless ( defined $cfgsec );

            }
            else    #It's a Section Option Value
            {
                if ( $ieqlps > -1 ) {
                    $rarrcntnt->[$iln] =~ s/([[:space:]]+)=/=/;
                    $rarrcntnt->[$iln] =~ s/=([^\S\r\n]+)/=/;

                    ( $scntntky, $scntntvl ) =
                      split( /=/, $rarrcntnt->[$iln], 2 );

                    #print "opt - ky: '$scntntky'; vl: '$scntntvl'\n";
                }
                else    #It's an Array List
                {
                    $scntntky = "";
                    $scntntvl = $rarrcntnt->[$iln];
                }

                $scntntky = "" unless ( defined $scntntky );
                $scntntvl = "" unless ( defined $scntntvl );

                $cfgsec = $self->{"_list_sections"}->Add
                  unless ( defined $cfgsec );

                if ( defined $cfgsec ) {
                    if ( $scntntky ne "" ) {

                        #print "set '$scntntky' => '$scntntvl'\n";

                        $cfgsec->set( $scntntky, $scntntvl );
                    }
                    else    #It's an Array List
                    {
                        $cfgsec->add($scntntvl);
                    }
                }
            }    #if($isqstrtps > -1 && $isqendps > -1
                 # && !($ieqlps > -1 && $isqstrtps > $ieqlps))
        }    #if($rarrcntnt->[$iln] ne "")
    }    #for($iln = 0; $iln < $ilncnt; $iln++)

    return $irs;
}

sub readList {
    my $self = $_[0];

    #Read and Parse the Configuration File
    $self->Read;

    #Return the Parsed Section List
    return $self->getList;
}

sub Write {
    my $self   = $_[0];
    my $scntnt = "";
    my $irs    = 0;

    if ( defined $self->{'_list_sections'}
        && $self->{'_list_sections'}->isa('ConfigSectionList') )
    {
        my $cfgsec    = undef;
        my $scfgsecnm = '';
        my $scfgky    = '';
        my $scfgvl    = '';
        my $icfgsec   = -1;
        my $icfgky    = -1;
        my $icfgsecnt = $self->{'_list_sections'}->getMetaEntryCount;
        my $icfgkycnt = -1;

        for ( $icfgsec = 0 ; $icfgsec < $icfgsecnt ; $icfgsec++ ) {
            $cfgsec = $self->{'_list_sections'}->getMetaEntry($icfgsec);

            if ( defined $cfgsec ) {
                $scfgsecnm = $cfgsec->getName;

                if ( $scfgsecnm ne '' ) {
                    $scntnt .= "[" . $scfgsecnm . "]\n";
                }
                elsif ( $icfgsecnt > 1 ) {
                    $scntnt .= "[]\n";
                }    #if($scfgsecnm ne '')

                $icfgkycnt = $cfgsec->getKeyCount;

                for ( $icfgky = 0 ; $icfgky < $icfgkycnt ; $icfgky++ ) {
                    ( $scfgky, $scfgvl ) = $cfgsec->getKeyValue($icfgky);

                    if ( $scfgky ne '' ) {
                        $scntnt .= $scfgky . "=" . $scfgvl . "\n";
                    }
                    elsif ( $scfgvl ne '' ) {

                        #The Value does not have a Key
                        $scntnt .= $scfgvl . "\n";
                    }    #if($scfgky ne '')
                }    #for($icfgky = 0; $icfgky < $icfgkycnt; $icfgky++)
            }    #if(defined $cfgsec)
        }    #for($icfgsec = 0; $icfgsec < $icfgsecnt; $icfgsec++)
    }    #if(defined $self->{"_list_sections"}
         # && $self->{"_list_sections"}->isa("ConfigSectionList"))

    #print "cfg cntnt:\n" . $scntnt;

    #Write the Configuration Content to the File
    $irs = File::Access::Driver::writeContent $self, $scntnt;

    #Communicate the Result
    return $irs;
}

sub writeList {
    my $self = $_[0];
    my $irs  = 0;

    #Set the List
    $self->setList( $_[1] );

    #Write the Section List to the Configuration File
    $irs = $self->Write;

    #Communicate the Result
    return $irs;
}

sub Clear {
    my $self = $_[0];

    #Execute the Base Class Logic
    $self->SUPER::Clear;

    if ( defined $self->{'_list_sections'} ) {

        #Clear the Section List
        $self->{'_list_sections'}->clearList;
    }
}

sub freeResources {
    my $self = $_[0];

    #Execute the Base Class Logic
    $self->SUPER::freeResources;

    $self->{'_list_sections'} = undef;
}

#----------------------------------------------------------------------------
#Consultation Methods

sub getList {
    my $self = $_[0];

    #Create a new empty Section List
    $self->{'_list_sections'} = new Config::Section::List::
      unless ( defined $self->{'_list_sections'} );

    return $self->{'_list_sections'};
}

return 1;
