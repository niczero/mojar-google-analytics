package Mojar::Google::Analytics::Response;
use Mojo::Base -base;

our $VERSION = 0.011;

use Mojar::Util qw(snakecase dumper);

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

	if ($self->success) {
    $self->error(undef)->content(undef);
    my $j = $tx->res->json;
    $self->{snakecase($_)} = $j->{$_} for keys %$j;
  }
  else {
    $self->error($tx->error);
    if (not defined(my $res = $tx->res)) {
      $self->error->{message} = 'Possible timeout';
      $self->error->{advice} //= 408;
    }
    elsif (my $j = $res->json) {
      $self->content($j);
      if (exists $j->{message}) {
        $self->error->{message} = $j->{message};
      }
      elsif (exists $j->{error}) {
        $self->error->{message} = $j->{error};
      }
    }
  }
	return $self;
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
