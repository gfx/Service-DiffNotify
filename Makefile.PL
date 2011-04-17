use strict;
use warnings;

BEGIN { require 5.008_001; }

use ExtUtils::MakeMaker 6.31;

my $all_from = 'lib/Service/DiffNotify.pm';
my %WriteMakefileArgs = (
  'AUTHOR' => 'Fuji, Goro (gfx) <gfuji@cpan.org>',
  'VERSION_FROM' => $all_from,
  'ABSTRACT_FROM' => $all_from,

  'BUILD_REQUIRES' => {
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Service-DiffNotify',
  'EXE_FILES' => ['script/niff.pl'],
  'LICENSE' => 'perl',
  'NAME' => 'Service::DiffNotify',
  'PREREQ_PM' => {
    'Mouse'                   => '0.90',
    'Growl::Any'              => '0.07',
    'Log::Minimal'            => '0.04',
    'Filesys::Notify::Simple' => '0.07',
    'Algorithm::Diff'         => '1.19',
    'Text::Extract::Word'     => '0.02',
  },
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

