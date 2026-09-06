#
# @author Bodo (Hugo) Barwich
# @version 2026-08-31
# @package Conig::Access::Driver
# @subpackage lib/Config/Section/List.pm

# This Module defines Classes to manage Data of an INI configuration section
#
#---------------------------------
# Requirements:
#
#---------------------------------
# Features:
#

use Config::Section;


#==============================================================================
# The Config::Section::List Package

package Config::Section::List;

=head1 NAME

Config::Section::List - Indexed collection of Config::Section objects

=head1 DESCRIPTION

Maintains ordered configuration sections and indexes them by section name.

=head1 METHODS

=over 4

=item new

Create a section list with a name index.

=item Add

Add an existing section or create one from a name and key/value pairs.

=item getConfigSectionbyName

Return a section by its name, or undef when it is absent.

=back

=cut

#----------------------------------------------------------------------------
#Dependencies

use parent Object::Meta::List;

use Scalar::Util 'blessed';

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $class = ref( $_[0] ) || $_[0];
    my $self  = undef;

    $self = $class->SUPER::new( @_[ 1 .. $#_ ] );

    #Index the Section Name Meta Field
    Object::Meta::List::createIndex( $self,
        ( 'checkfield' => 'sectionname', 'meta' => 1 ) );

    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub Add {
    my $self   = $_[0];
    my $cfgsec = undef;

    if ( scalar(@_) > 1 ) {
        if ( defined blessed $_[1] ) {

            #The Second Parameter is an Object
            $cfgsec = $_[1];
        }
        else    #Parameter is not an Object
        {
            if ( scalar(@_) > 2 ) {

                #Create the new ConfigSection Object from the given Parameters
                $cfgsec = Config::Section::->new( @_[ 1 .. $#_ ] );
            }
            else    #Only 1 Scalar Parameter
            {
                #Create the new ConfigSection Object with the Parameter as Name
                $cfgsec = Config::Section::->new( ( 'name' => $_[1] ) );
            }
        }
    }    #if(scalar(@_) > 1)

    if ( defined $cfgsec ) {
        unless ( $cfgsec->isa('Config::Section') ) {
            $cfgsec = undef;
        }
    }

    #Create an empty ConfigSection Object
    $cfgsec = Config::Section::->new
      unless ( defined $cfgsec );

    #Execute the Base Logic
    Object::Meta::List::Add( $self, $cfgsec );

    return $cfgsec;
}

#----------------------------------------------------------------------------
#Consultation Methods

sub getConfigSectionbyName {
    my ( $self, $sname ) = @_;
    my $cfgsec = undef;

    if ( defined $sname
        && $sname ne "" )
    {
        #print "nm: '$sname'; hsh: '" . md5_hex($sname) . "'\n";

        $cfgsec =
          Object::Meta::List::getIdxMetaObject( $self, 'sectionname', $sname );
    }

    return $cfgsec;
}

return 1;
