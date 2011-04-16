#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Service::DiffNotify';
}

diag "Testing Service::DiffNotify/$Service::DiffNotify::VERSION";
