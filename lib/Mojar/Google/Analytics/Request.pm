package Mojar::Google::Analytics::Request;
use Mojo::Base -base;

our $VERSION = '0.001';

use Mojo::Parameters;
use Mojo::Util 'url_escape';
use POSIX 'strftime';

# Attributes

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
has max_results => 10_000;

# Public methods

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

# Private methods

sub _today { strftime '%F', localtime }

1;
__END__

=head1 NAME

Mojar::Google::Analytics::Request - Request object for GA reporting data.

=head1 SYNOPSIS

  use Mojar::Google::Analytics::Request;
  $req = Mojar::Google::Analytics::Request->new
    ->dimensions([qw( pagePath )])
    ->metrics([qw( visitors pageviews )])
    ->sort('pagePath')
    ->max_results($max_resultset);

=head1 DESCRIPTION

Provides a container object with convenience methods.

=head1 ATTRIBUTES

=over 4

=item access_token

Access token, obtained via JWT.

=item ids

Profile ID (from your GA account) you want to use.

=item dimensions

Arrayref to list of desired dimensions.

=item metrics

Arrayref to list of desired metrics.

=item segment

String containing desired segment.

=item filters

Arrayref to list of desired filters.

=item sort

Specification of column sorting; either a single name (string) or a list
(arrayref).

=item start_date

Defaults to today.

=item end_date

Defaults to today.

=item start_index

Defaults to 1.

=item max_results

Defaults to 10,000.

=back

=head1 METHODS

=over 4

=item new

Constructor.

  $req = Mojar::Google::Analytics::Request->new(
    dimensions => [qw( pagePath )],
    metrics => [qw( visitors pageviews )],
    sort => 'pagePath',
    start_index => $start,
    max_results => $max_resultset
  );

=item params

String of request parameters.

  $url .= q{?}. $req->params;

=back

=head1 CONFIGURATION AND ENVIRONMENT

You need to create a low-privilege user within your GA account, granting them
access to an appropriate profile.  Then register your application for unattended
access.  That results in a username and private key that your application uses
for access.

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Net::Google::Analytics> is similar, main differences being dependencies and
means of getting tokens.
