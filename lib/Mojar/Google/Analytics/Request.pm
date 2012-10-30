package Mojar::Google::Analytics::Request;
use Mojo::Base -base;

our $VERSION = '0.001';

use Mojo::Parameters;
use Mojo::Util 'url_escape';
use POSIX 'strftime';

# ------------
# Attributes
# ------------

has 'access_token';
has 'ids';
has dimensions => sub {[]};
has metrics => sub {[]};
has 'segment';
has filters => sub {[]};
has sort => sub {[]};
has start_date => &_today;
has end_date   => &_today;
has start_index => 1;
has max_results => 10000;

# ------------
# Public methods
# ------------

sub params {
  my $self = shift;
  my %param = (%$self, @_);
  my $p = Mojo::Parameters->new;

  # Absorb driver params, using defaults if necessary
  foreach (qw( start_date end_date start_index max_results )) {
    my ($k, $v) = ($_, $self->$_);
    delete $param{$_};
    $k =~ s/_/-/;
    $p = $p->append($k => $v);
  }

  # Absorb everything else
  foreach (keys %param) {
    my ($k, $v) = ($_, $param{$_});
    $k =~ s/_/-/;
    if (ref $v) {
      # Array ref
      $v = join q{,}, map +('ga:'. $_), @$v;
    }
    else {
      # Scalar
      my $descending = 0;
      $k eq 'sort' and $v =~ s/^-// and $descending = 1;
      $v = ($descending ? '-ga:' : 'ga:') . $v if defined $v;
    }
    $p = $p->append($k => $v);
  }
  return $p->to_string;
}

# ------------
# Private methods
# ------------

sub _today { strftime '%F', localtime }

1;
__END__

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

