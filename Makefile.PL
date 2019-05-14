use 5.8.8;
use strict;
use warnings FATAL => 'all';
#use ExtUtils::MakeMaker;
#
#WriteMakefile(
#    NAME               => 'Replay::EventSystem::AWSMQ',
#    AUTHOR             => q{David Ihnen <davidihnen@gmail.com>},
#    VERSION_FROM       => 'lib/Replay/EventSystem/AWSMQ.pm',
#    ABSTRACT           => 'Amazon Web Services MQ support for the Replay framework',
#    LICENSE            => 'Artistic_2_0',
#    PL_FILES           => {},
#    MIN_PERL_VERSION   => 5.8.8,
#    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
#    TEST_REQUIRES      => {
#        'Test::Most'        => 0.33,
#        'Test::Class' => 0,
#        'Test::Mock::Class' => 0,
#        'Test::Continuous'  => 0,
#        'Test::Pod::Coverage' => 1.08,
#        'Test::Pod' => 1.22,
#        'Replay' => 0.03,
#    },
#    PREREQ_PM => {
#        'Replay'                               => '0.03',
#        'Net::STOMP::Client'                   => '2.3',
#        'Carp'                                 => '1.3301',
#        'File::Slurp'                          => '0',
#        'File::Temp'                           => '0',
#        'Data::Dumper'                         => '2.121_08',
#        'Scalar::Util'                         => '1.46',
#        'YAML'                                 => '0',
#        'JSON'                                 => '2.53',
#        'JSON::Any'                            => '1.29',
#        'Moose'                                => '2.1209',
#        'Readonly'                             => '1.04',
#        'Scalar::Util'                         => '1.21',
#        'Try::Tiny'                            => '0.11',
#    },
#    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
#    clean => { FILES    => 'Replay-*' },
#);

use inc::Module::Install;
 
name        'Replay-EventSystem-AWSMQ';
abstract    'Amazon Web Services MQ support for the Replay framework';
author      'David Ihnen <davidihnen@gmail.com>';
include     'Module::AutoInstall';
license     'Artistic_2_0';
version_from 'lib/Replay/EventSystem/AWSMQ.pm';
 
requires     'Net::STOMP::Client';
requires     'Carp';
requires     'File::Slurp';
requires     'File::Temp';
requires     'Data::Dumper';
requires     'Scalar::Util';
requires     'YAML';
requires     'JSON';
requires     'JSON::Any';
requires     'Moose';
requires     'Readonly';
requires     'Scalar::Util';
requires     'Try::Tiny';

test_requires 'App::Prove::Watch';
test_requires 'Time::HiRes';
test_requires 'Test::Most';
test_requires 'Test::Class';
test_requires 'Test::Mock::Class';
test_requires 'Test::Continuous';
test_requires 'Test::Pod::Coverage';
test_requires 'Test::Pod';
test_requires 'File::Tempdir';
test_requires 'List::Util';
test_requires 'Replay';
 
#feature     'Feature1',
#    -default    => 0,
#    'Module2'   => '0.1';
# 
#feature     'Feature2',
#    -default    => 0,
#    'Module3'   => '1.0';
 
auto_install(
#    make_args   => '',   # option(s) for CPAN::Config
    force       => 1,           # pseudo-option to force install
#    do_once     => 1,           # skip previously failed modules
);
 
WriteAll;
