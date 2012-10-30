use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojar::Google::Analytics',
  VERSION_FROM => 'lib/Mojar::Google::Analytics.pm',
  ABSTRACT     => 'Fetch Google Analytics reporting data',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {
      perl => '5.010001',
      Mojolicious => '3.49',
      IO::Socket::SSL => '1.75',
      Crypt::OpenSSL::RSA => '0.28'
    },
    resources => {
      homepage    => 'http://niczero.github.com/mojar-google-analytics/',
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/niczero/mojar-google-analytics',
      bugtracker  => 'http://github.com/niczero/mojar-google-analytics/issues'
    },
    no_index => {directory => ['test']}
  },
  test => {TESTS => 'test/*.t'}
);
