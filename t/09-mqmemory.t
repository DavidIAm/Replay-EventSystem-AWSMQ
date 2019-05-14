package Test::Replay::AWSMQ::Memory::Filesystem;

use lib './t/lib';
use lib './lib';
use lib './inc';
use Replay::Test;
use Replay::EventSystem::AWSMQ;
use base qw/Replay::Test Test::Class/;
use JSON;
use YAML;
use File::Slurp;
use File::Tempdir;
use Test::Most;
our $REPLAY_TEST_CONFIG = $ENV{REPLAY_TEST_CONFIG};

my $tempdir = File::Tempdir->new();
sub tempdir {
  return $tempdir->name;
}

sub t_environment_reset : Test(startup => 2) {
    my $self = shift;

    my $replay = $self->{replay};
    ok -f $self->{idfile};
}

sub a_replay_config : Test(startup => 5) {
    my $self = shift;
    unless ($REPLAY_TEST_CONFIG) {
        $self->SKIP_ALL('REPLAY_TEST_CONFIG Env var not present ');
    }
    $self->{awsconfig} = YAML::LoadFile($REPLAY_TEST_CONFIG);
    ok exists $self->{awsconfig}->{Replay}->{awsIdentity}->{access};
    ok exists $self->{awsconfig}->{Replay}->{awsIdentity}->{secret};
    ok exists $self->{awsconfig}->{Replay}->{mq}->{Endpoint};
    ok exists $self->{awsconfig}->{Replay}->{mq}->{Username};
    ok exists $self->{awsconfig}->{Replay}->{mq}->{Password};
    $self->{idfile} = $REPLAY_TEST_CONFIG;
    $self->{config} = {
        timeout       => 400,
        stage         => 'testscript-09-' . $ENV{USER},
        StorageEngine => { Mode => 'Memory' },
        WORM  => { 'Directory' => tempdir },
        EventSystem   => {
            Mode        => 'AWSMQ',
            awsIdentity => $self->{awsconfig}->{Replay}->{awsIdentity},
            mqEndpoint  => $self->{awsconfig}->{Replay}->{mq}->{Endpoint},
            mqUsername  => $self->{awsconfig}->{Replay}->{mq}->{Username},
            mqPassword  => $self->{awsconfig}->{Replay}->{mq}->{Password},
        },
        Defaults      => { ReportEngine => 'Filesystemtest' },
        ReportEngines => [
            {   Mode   => 'Filesystem',
                Root   => tempdir,
                Name   => 'Filesystemtest',
                Access => 'public'
            }
            ]

    };
}

sub alldone : Test(teardown) {
}

Test::Class->runtests();
