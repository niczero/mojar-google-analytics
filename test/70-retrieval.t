# ============
# retrieval.t
# ============
use Mojo::Base -strict;
use Test::More;

use Mojar::Google::Analytics;
use Mojo::Util 'slurp';

plan skip_all => 'set TEST_ACCESS to enable this test (developer only!)'
  unless $ENV{TEST_ACCESS};

my ($user, $pk, $profile);

subtest q{Setup} => sub {
  $user = slurp 'data/auth_user.txt' and chomp $user;
  ok $user, 'user';
  $pk = slurp 'data/privatekey.pem';
  ok $pk, 'pk';
  $profile = slurp 'data/profile.txt' and chomp $profile;
  ok $profile, 'profile';
};

my ($analytics, $res);

subtest q{Basics} => sub {
  ok $analytics = Mojar::Google::Analytics->new(
    auth_user => $user,
    private_key => $pk,
    profile_id => $profile
  ), 'new(profile_id => ..)';

  ok $analytics->req(
    metrics => [qw(visits)]
  ), 'req(..)';
};

subtest q{token} => sub {
  eval {
    ok $analytics->has_valid_token, 'has_valid_token';
  }
  or do {
    my $e = $@;
    diag sprintf "user: [%s]\npk: [%s]\nprofile: [%s]\nerror: %s",
        $user, $pk, $profile, $e;
  };
  ok $analytics->renew_token, 'renew_token';
};

subtest q{fetch} => sub {
  eval {
    ok $res = $analytics->fetch, 'fetch';
  }
  or diag sprintf "profile: [%s]\nerror: %s",
      $profile, $analytics->res->error->{message} // '';
  diag $res->success;
  ok $res->success, 'success';
};

subtest q{Result set} => sub {
  ok $analytics->req(
    dimensions => [qw( pagePath )],
    metrics => [qw(visitors newVisits visits bounces timeOnSite entrances
        pageviews uniquePageviews timeOnPage exits)],
    metrics => [qw(uniquePageviews)],
    sort => 'pagePath',
    start_index => 1,
    max_results => 5
  ), 'req(..)';
  ok $res = $analytics->fetch, 'fetch';
  ok $res->success, 'success';

  ok $analytics->req(
    start_index => 6,
    max_results => 5
  ), 'req(..)';
  ok $res = $analytics->fetch, 'fetch';
  ok $res->success, 'success';
};

done_testing();
