package Mojar::Google::Analytics;
use Mojo::Base -base;

our $VERSION = 1.053;

use 5.014001;  # For MIME::Base64::encode_base64url
use Carp 'croak';
use IO::Socket::SSL 1.75;
use Mojar::Auth::Jwt;
use Mojar::Google::Analytics::Request;
use Mojar::Google::Analytics::Response;
use Mojo::UserAgent;

# Attributes

# Analytics request
has api_url => 'https://www.googleapis.com/analytics/v3/data/ga';
has ua => sub {
  Mojo::UserAgent->new->max_redirects(2)->inactivity_timeout(shift->timeout)
};
has 'profile_id';
has timeout => 60;

sub req {
  my $self = shift;
  return $self->{req} unless @_;
  if (@_ == 1) {
    $self->{req} = $_[0];
  }
  else {
    $self->{req} //= Mojar::Google::Analytics::Request->new;
    %{$self->{req}} = ( %{$self->{req}},
      ids => $self->{profile_id},
      @_
    );
  }
  return $self;
}

has res => sub { Mojar::Google::Analytics::Response->new };

# Authentication token
has 'auth_user';
has grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer';
has 'private_key';
has jwt   => sub {
  my $self = shift;
  my %param = map +($_ => $self->$_), qw( private_key );
  $param{iss} = $self->auth_user;
  Mojar::Auth::Jwt->new(
    iss => $self->auth_user,
    private_key => $self->private_key
  )
};
has validity_margin => 10;  # Too close to expiry (seconds)
has token => sub { $_[0]->_request_token };

# Public methods

sub fetch {
  my ($self) = @_;
  croak 'Failed to see a built request' unless my $req = $self->req;

  # Validate params
  $self->renew_token unless $self->has_valid_token;
  defined $self->$_ or croak "Missing required field ($_)"
    for qw(token);
  $req->access_token($self->token);
  defined $req->$_ or croak "Missing required field ($_)"
    for qw(access_token ids);

  my $res = Mojar::Google::Analytics::Response->new;
  my $tx = $self->ua->get(
    $self->api_url .'?'. $req->params,
    { 'User-Agent' => 'MojarGA', Authorization => 'Bearer '. $self->token }
  );
  if (my $response = $tx->success) {
    return $self->res($res->success(1)->parse($tx))->res;
  }
  else {
    $self->res($res->success(0)->parse($tx));
    return undef;
  }
}

sub has_valid_token {
  my ($self) = @_;
  return undef unless my $token = $self->token;
  return undef unless my $jwt = $self->jwt;
  return undef unless time < $jwt->exp - $self->validity_margin;
  # Currently not too late
  return 1;
}

sub renew_token {
  my ($self) = @_;
  # Delete anything not reusable
  delete $self->{token};
  $self->jwt->reset;
  # Build a new one
  return $self->token;
}

# Private methods

sub _request_token {
  my $self = shift;
  my $jwt = $self->jwt;
  my $tx = $self->ua->post($jwt->aud,
    { 'User-Agent' => 'MojarGA' }, form => {
    grant_type => $self->grant_type,
    assertion => $jwt->encode
  });
  if (my $r = $tx->success) {
    my $j = $r->json;
    return undef unless ref $j eq 'HASH'
        and exists $j->{expires_in} and $j->{expires_in};
    return $j->{access_token};
  }
  else {
    my $res = Mojar::Google::Analytics::Response->new;
    $res->success(0)->parse($tx);
    my $code = $res->error->{advice} // 'Connection';
    croak "$code error: ${\ $res->error->{message}}";
  }
}

1;
__END__

=head1 NAME

Mojar::Google::Analytics - Fetch Google Analytics reporting data

=head1 SYNOPSIS

  use Mojar::Google::Analytics;
  $analytics = Mojar::Google::Analytics->new(
    auth_user => q{1234@developer.gserviceaccount.com},
    private_key => $pk,
    profile_id => q{5678}
  );
  $analytics->req(
    dimensions => [qw( pagePath )],
    metrics => [qw( visitors pageviews )],
    sort => 'pagePath',
    start_index => $start,
    max_results => $max_resultset
  );
  my $rs = $analytics->fetch;

=head1 DESCRIPTION

Google Analytics provide an API for retrieving reporting data and there are
recommended client libraries for several languages but not Perl.  This class
provides an interface to v3 of the Core Reporting API.

=head1 ATTRIBUTES

=over 4

=item api_url

Currently the only supported value is
C<https://www.googleapis.com/analytics/v3/data/ga>.

=item ua

An instance of the user agent to use.  Defaults to a Mojo::UserAgent.

=item timeout

  $analytics = Mojar::Google::Analytics->new(
    auth_user => q{1234@developer.gserviceaccount.com},
    private_key => $pk,
    profile_id => q{5678},
    timeout => 120
  );

The inactivity timeout for the user agent.  Any change from the default (60 sec)
must be applied before the first use of the user agent, and so is best done when
creating your analytics object.

=item profile_id

The profile within your GA account you want to use.

=item req

The current request object to use.  First set C<profile_id> then set C<req> with
your parameters.

  $ga->profile_id(...)->req(...);

=item res

The current result object.

=item auth_user

The user GA generated for you when you registered your application.  Should
end in C<@developer.gserviceaccount.com>.

=item grant_type

Currently the only supported value is
C<urn:ietf:params:oauth:grant-type:jwt-bearer>.

=item private_key

Your account's private key.

=item jwt

The JWT object.  Defaults to

  Mojar::Auth::Jwt->new(
    iss => $self->auth_user,
    private_key => $self->private_key
  )

=item validity_margin

How close (in seconds) to the expiry time should the current token be replaced.
Defaults to 10 seconds.

=item token

The current access token.

=back

=head1 METHODS

=over 4

=item new

Sets the credentials for access.

  $analytics = Mojar::Google::Analytics->new(
    auth_user => q{1234@developer.gserviceaccount.com},
    private_key => $pk,
    profile_id => q{5678}
  );

=item fetch

Fetches first/next batch of results based on set credentials and the C<req>
object.  Automatically checks/renews the access token.

  $result = $analytics->fetch  # replaces $analytics->res

=item has_valid_token

Check if the current token is still valid (and not too close to expiry).  (See
C<validity_margin>.)

  unless ($analytics->has_valid_token) { ... }

=item renew_token

Force obtaining a fresh token.

  $token = $analytics->renew_token  # replaces $analytics->token

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
