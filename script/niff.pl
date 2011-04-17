#!perl -w
use strict;
#use lib::xi;
use Service::DiffNotify;

Service::DiffNotify->new(dir => shift(@ARGV) || '.')->run();

