package Mojar::Google::Analytics::Response;
use Mojo::Base -base;

our $VERSION = 0.021;

use Mojar::Util qw(dumper snakecase);

# Attributes

has 'success';
has 'error';
has 'content';

has start_index => 1;
has 'items_per_page';
has 'next_link';
has contains_sampled_data => !!0;
has 'profile_info';
has column_headers => sub {[]};
has total_results => 0;
has rows => sub {[]};
has 'totals_for_all_results';

# Public methods

sub parse {
  my ($self, $tx) = @_;

  if ($tx->success) {
    $self->error(undef)->content(undef);
    my $j = $tx->res->json;
    $self->{snakecase($_)} = $j->{$_} for keys %$j;
    return $self;
  }
  else {
    # Got a transaction-level error
    $self->error($tx->error);
    $self->error->{code} ||= 408;
    $self->error->{message} //= 'Possible timeout';

    if ($tx->res and my $j = $tx->res->json) {
      # Got JSON body in response
      $self->content($j);

      if (my $m = ($j->{error} // $j->{message})) {
        # Got message record
        $self->error->{code} = $m->{code} if $m->{code};
        # Take note of headline error
        my $msg = $m->{message} ."\n";

        for my $e (@{$m->{errors} // []}) {
          # Take note of next listed error
          $msg .= sprintf "%s at %s\n%s\n",
              $e->{reason}, ($e->{location} // $e->{domain}), $e->{message};
        }
        $self->error->{message} = $msg;
      }
    }
    return undef;
  }
}

1;
__END__

=head1 NAME

Mojar::Google::Analytics::Response - Response object from GA reporting.

=head1 SYNOPSIS

  use Mojar::Google::Analytics::Response;
  $response = Mojar::Google::Analytics::Response->new(
    auth_user => q{1234@developer.gserviceaccount.com},
    private_key => $pk,
    profile_id => q{5678}
  );

=head1 DESCRIPTION

Container object returned from Google Analytics Core Reporting.

=head1 ATTRIBUTES

=over 4

=item success

Boolean result status.

=item code

Error code.

=item reason

Error reason.

=item message

Error message.

=item domain

Defaults to C<global>.

=item error

String.  Concatenation of C<code>, C<reason>, C<message>.

=item start_index

Reported start index; should match your request.

=item items_per_page

Reported result set size; should match your request.

=item contains_sampled_data

Boolean.

=item profile_info

Summary of profile.

=item column_headers

Arrayref of headers records, including titles and types.

=item total_results

Reported total quantity of records available.  (Can fluctuate from first
response to the next.)

=item rows

Array ref containing the result set.

=item totals_for_all_results

Overall totals for your requested metrics.

=back

=head1 METHODS

=over 4

=item *

=back

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Net::Google::Analytics> is similar, main differences being dependencies and
means of getting tokens.
