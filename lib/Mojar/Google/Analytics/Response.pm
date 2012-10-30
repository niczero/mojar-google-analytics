package Mojar::Google::Analytics::Response;
use Mojo::Base -base;

our $VERSION = '0.001';

# ------------
# Attributes
# ------------

has 'success';
has 'code';
has 'reason';
has 'message';
has domain => 'global';

has error => sub { join ':', @{$_[0]}{qw( code reason message )} };

has start_index => 1;
has items_per_page => 10_000;
has contains_sampled_data => !!0;
has 'profile_info';
has column_headers => sub {[]};
has total_results => 0;
has rows => sub {[]};
has 'totals_for_all_results';


# ------------
# Public methods
# ------------

# ------------
# Private methods
# ------------

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

