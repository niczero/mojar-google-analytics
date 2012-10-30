package Mojar::Auth::Jwt;
use Mojo::Base -base;

our $VERSION = '0.001';

use Carp 'croak';
use Crypt::OpenSSL::RSA ();
use MIME::Base64 ();
use Mojo::JSON;

# ------------
# Attributes
# ------------

# JWT Header
has typ => 'JWT';
has alg => 'RS256';

# JWT Claim Set
has 'iss';
has scope => sub { q{https://www.googleapis.com/auth/analytics.readonly} };
has aud => q{https://accounts.google.com/o/oauth2/token};
has iat => sub { time };
has duration => 3500;  # ~ 1 hour
has exp => sub { time + $_[0]->duration };

# JWT Signature
has 'private_key';

# Mogrified chunks

sub header {
  my $self = shift;

  if (@_ == 0) {
    my @h = map +( ($_, $self->$_) ), qw( typ alg );
    return $self->{header} = $self->mogrify( { @h } );
  }
  else {
    %$self = ( %$self, @_ );
  }
  return $self;
}

sub body {
  my $self = shift;

  if (@_ == 0) {
    foreach (qw( iss scope )) {
      croak "Missing required field ($_)" unless defined $self->$_;
    }
    $self->{scope} = join ' ', @{$self->{scope}} if ref $self->{scope};
    my @c = map +( ($_, $self->$_) ), qw( iss scope aud exp iat );
    return $self->{body} = $self->mogrify( { @c } );
  }
  else {
    %$self = ( %$self, @_ );
  }
  return $self;
}

sub signature {
  my $self = shift;

  if (@_ == 0) {
    croak 'Unrecognised algorithm (not RS256)' unless $self->alg eq 'RS256';
    my $input = $self->header .q{.}. $self->body;

    return $self->{signature} = MIME::Base64::encode_base64url(
      $self->cipher->sign($input)
    );
  }
  else {
    %$self = ( %$self, @_ );
  }
  return $self;
}

has json => sub { Mojo::JSON->new };

has cipher => sub {
  my $self = shift;
  foreach (qw( private_key )) {
    croak qq{Missing required field ($_)} unless defined $self->$_;
  }

  my $cipher = Crypt::OpenSSL::RSA->new_private_key($self->private_key);
  $cipher->use_pkcs1_padding;
  $cipher->use_sha256_hash;  # Requires openssl v0.9.8+
  return $cipher;
};

# ------------
# Public methods
# ------------

sub reset {
  my ($self) = @_;
  delete @$self{qw( iat exp body signature )};
  return;
}

sub encode {
  my $self = shift;
  if (ref $self) {
    # Encoding an existing object
    %$self = ( %$self, @_ ) if @_;
  }
  else {
    # Class method => create object
    $self = $self->new(@_);
  }
  return join q{.}, $self->header, $self->body, $self->signature;
}

sub decode {
  my ($self, $triplet) = @_;
  my ($header, $body, $signature) = split /\./, $triplet;

  my %param = %{ $self->demogrify($header) };
  %param = ( %param, %{ $self->demogrify($body) } );
  return $self->new(%param);
}

sub verify_signature {
  my $self = shift;
  my $plaintext = $self->header .q{.}. $self->body;
  my $plainsign = MIME::Base64::decode_base64url( $self->signature );
  return $self->cipher->verify($plaintext, $plainsign);
}

sub mogrify {
  my ($self, $hashref) = @_;
  return '' unless ref $hashref && ref $hashref eq 'HASH';
  return MIME::Base64::encode_base64url($self->json->encode( $hashref ));
}

sub demogrify {
  my ($self, $safestring) = @_;
  return {} unless defined $safestring && length $safestring;
  return $self->json->decode(MIME::Base64::decode_base64url( $safestring ));
}

# ------------
# Private methods
# ------------

1;
__END__

=pod

=head1 Name

=head1 Synopsis

=head1 Description

This class implements JSON Web Token (JWT) authentication (v3) for accessing
L<googleapis.com> from a service application.  If your application impersonates
users (to access/manipulate their data) then you need something else instead.

=head1 Attributes

=head1 Methods

=head1 Diagnostics

=head1 Configuration and environment

=head1 Dependencies and incompatibilities

=head1 Bugs and limitations

=cut

