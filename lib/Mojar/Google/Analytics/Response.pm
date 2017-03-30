package Mojar::Google::Analytics::Response;
use Mojo::Base -base;

our $VERSION = 1.001;

use Mojar::Util 'snakecase';

# Attributes

has [qw(content error success)];

has start_index => 1;
has contains_sampled_data => !!0;
has column_headers => sub {[]};
has total_results => 0;
has rows => sub {[]};
has [qw(items_per_page profile_info next_link totals_for_all_results)];

# Public methods

sub parse {
  my ($self, $res) = @_;

  if ($res->is_success) {
    delete @$self{qw(content error)};
    my $j = $res->json;
    $self->{snakecase($_)} = $j->{$_} for keys %$j;
    return $self->success(1);
  }
  else {
    # Got a transaction-level error
    $self->error({
      code => $res->code || 408,
      message => $res->message // 'Possible timeout'
    });

    if ($res and my $j = $res->json) {
      # Got JSON body in response
      $self->content($j);
      my $m = ref($j->{error}) ? $j->{error} : {message => $j->{error} // ''};

      # Got message record
      $self->{error}{code} = $m->{code} || $self->{error}{code} // 0;
      # Take note of headline error
      my $msg = ($m->{message} // $j->{message}) ."\n";

      for my $e (@{$m->{errors} // []}) {
        # Take note of next listed error
        $msg .= sprintf "%s at %s\n%s\n",
            $e->{reason}, ($e->{location} // $e->{domain}), $e->{message};
      }
      $self->{error}{message} = $msg;
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

Reported total quantity of records available.  (Can fluctuate from one
response to the next.)

=item rows

Array ref containing the result set.

=item totals_for_all_results

Overall totals for your requested metrics.

=back

=head1 METHODS

=over 4

=item parse

  $success = $res->parse($tx->res)

Populates the Response using the supplied transaction response, returning
a boolean denoting whether the transaction was successful.

=back

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Net::Google::Analytics> is similar, main differences being dependencies and
means of getting tokens.
