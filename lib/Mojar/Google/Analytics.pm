package Mojar::Google::Analytics;
use Mojo::Base -base;

our $VERSION = '0.001';

use Carp 'croak';
use IO::Socket::SSL 1.75;
use Mojar::Auth::Jwt;
use Mojar::Google::Analytics::Request;
use Mojar::Google::Analytics::Response;
use Mojo::UserAgent;
use Mojo::Util 'decamelize';

# ------------
# Attributes
# ------------

# Analytics request
has api_url => 'https://www.googleapis.com/analytics/v3/data/ga';
has ua => sub { Mojo::UserAgent->new->max_redirects(3) };
has 'profile_id';

sub req {
  my $self = shift;
  return $self->{req} unless @_;
  if (@_ == 1) {
    $self->{req} = $_[0];
  }
  else {
    $self->{req} ||= Mojar::Google::Analytics::Request->new;
    %{$self->{req}} = ( %{$self->{req}},
      ids => $self->{profile_id},
      @_
    );
  }
  return $self;
}

has 'res';  # Analytics response

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

# ------------
# Public methods
# ------------

sub fetch {
  my $self = shift;
  croak 'Failed to see a built request' unless my $req = $self->req;

  # Validate params
  $self->renew_token unless $self->has_valid_token;
  foreach (qw( token )) {
    croak "Missing required field ($_)" unless defined $self->$_;
  }
  $req->access_token($self->token);
  foreach (qw( access_token ids )) {
    croak "Missing required field ($_)" unless defined $req->$_;
  }

  my $res = Mojar::Google::Analytics::Response->new;
  my $tx = $self->ua->get(
    $self->api_url .'?'. $req->params,
    { Authorization => 'Bearer '. $self->token }
  );
  if (my $response = $tx->success) {
    my $r = $response->json;
    %$res = map +((substr decamelize('Q'. $_), 1) => $r->{$_}), keys %$r;
    $res->success(1);
    return $self->{res} = bless $res => 'Mojar::Google::Analytics::Response';
  }
  else {
    my ($err, $code) = $tx->error;
    $res->code($code)
        ->message($err);
#TODO: Capture errors from response body
    $self->{res} = $res->success(0);
    return undef;
  }
}

sub has_valid_token {
  my $self = shift;
  return undef unless my $token = $self->token;
  return undef unless my $jwt = $self->jwt;
  return undef unless time < $jwt->exp - $self->validity_margin;
  # Currently not too late
  return 1;
}

sub renew_token {
  my $self = shift;
  # Delete anything not reusable
  delete $self->{token};
  $self->jwt->reset;
  # Build a new one
  return $self->token;
}

# ------------
# Private methods
# ------------

sub _request_token {
  my $self = shift;
  my $jwt = $self->jwt;
  my $tx = $self->ua->post_form($jwt->aud, 'UTF-8', {
    grant_type => $self->grant_type,
    assertion => $jwt->encode
  });
  if (my $response = $tx->success) {
    my $r = $response->json;
    return undef unless ref $r eq 'HASH'
        && exists $r->{expires_in} && $r->{expires_in};
    return $r->{access_token};
  }
  else {
    my ($err, $code) = $tx->error;
    my $error = $code ? "$code response: $err" : "Connection error: $err";
    croak $error;
  }
}

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

