package Test::Replay::AWSMQ::Memory::Filesystem;

use base qw/Replay::Test Test::Class/;
use JSON;
use YAML;
use File::Slurp;
use Test::Most;
our $REPLAY_TEST_CONFIG = $ENV{REPLAY_TEST_CONFIG};

sub t_environment_reset : Test(startup => 2) {
    my $self = shift;

    my $replay = $self->{replay};
    ok -f $self->{idfile};
}

sub a_replay_config : Test(startup) {
    my $self = shift;
    unless ($REPLAY_TEST_CONFIG) {
        $self->SKIP_ALL('REPLAY_TEST_CONFIG Env var not present ');
    }
    $self->{awsconfig} = YAML::LoadFile($REPLAY_TEST_CONFIG);
    ok exists $self->{awsconfig}->{Replay}->{awsIdentity}->{access};
    ok exists $self->{awsconfig}->{Replay}->{awsIdentity}->{secret};
    ok exists $self->{awsconfig}->{Replay}->{mqService};
    ok exists $self->{awsconfig}->{Replay}->{mqUsername};
    ok exists $self->{awsconfig}->{Replay}->{mqPassword};
    $self->{idfile} = $REPLAY_TEST_CONFIG;
    $self->{config} = {
        timeout       => 400,
        stage         => 'testscript-03-' . $ENV{USER},
        StorageEngine => { Mode => 'Memory' },
        EventSystem   => {
            Mode        => 'AWSMQ',
            awsIdentity => $self->{awsconfig}->{Replay}->{awsIdentity},
            snsService  => $self->{awsconfig}->{Replay}->{snsService},
            sqsService  => $self->{awsconfig}->{Replay}->{sqsService},
            mqUsername  => $self->{awsconfig}->{Replay}->{mqUsername},
            mqPassword  => $self->{awsconfig}->{Replay}->{mqPassword},
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
