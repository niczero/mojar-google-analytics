package Mojar::Google::Analytics::Request;
use Mojo::Base -base;

our $VERSION = '0.001';

# ------------
# Attributes
# ------------

has 'ids';
has 'dimensions';
has 'metrics';
has 'segment';
has 'filters';
has 'sort';
has 'start_date';
has 'end_date';

# ------------
# Public methods
# ------------

sub params { 
  my $self = shift;
  return { map { ($a = $_) =~ s/_/-/; $a => $self->{$_} } keys %$self };
}

# ------------
# Private methods
# ------------

1;
__END__
# $Id: $

=pod

=head1 Name

=head1 Synopsis

=head1 Description

=head1 Attributes

=head1 Methods

=head1 Diagnostics

=head1 Configuration and environment

=head1 Dependencies and incompatibilities

=head1 Bugs and limitations

=cut

