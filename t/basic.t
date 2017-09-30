#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::Mojo;
use Test::More;

use FindBin;
require "$FindBin::Bin/../script/wordfinder";

my $t = Test::Mojo->new;

# Perform GET requests and look at the responses
$t->get_ok('/ping')
    ->status_is(200)
    ->content_is('');

$t->get_ok('/wordfinder')
    ->status_is(404);

$t->get_ok('/wordfinder/dog')
    ->status_is(200)
    ->json_is(["do","dog","go","god","od"]);

done_testing();
