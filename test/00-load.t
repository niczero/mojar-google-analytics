use Mojo::Base -strict;
use Test::More;

BEGIN {
	use_ok('Mojar::Google::Analytics');
}

diag "Testing Mojar::Google::Analytics $Mojar::Google::Analytics::VERSION, Perl $], $^X";

done_testing();
