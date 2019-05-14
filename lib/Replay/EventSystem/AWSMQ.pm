package Replay::EventSystem::AWSMQ;

use Moose;

our $VERSION = '0.02';

with 'Replay::Role::EventSystem';

use Replay::Message;

use Carp qw/carp croak confess/;

use Perl::Version;
use IO::Socket::SSL;
use Net::STOMP::Client;
use Data::Dumper;
use Try::Tiny;
use Data::UUID;
use JSON;
use Scalar::Util qw/blessed/;
use Carp qw/confess/;

has purpose => ( is => 'ro', isa => 'Str', required => 1, );
has subscribers => ( is => 'ro', isa => 'ArrayRef', default => sub { [] }, );

has config => ( is => 'ro', isa => 'HashRef[Item]', required => 1 );

has client => (
    is      => 'ro',
    isa     => 'Net::STOMP::Client',
    builder => '_build_client',
    lazy    => 1,
);

has connection => (
    is        => 'ro',
    isa       => 'Net::STOMP::Client',
    builder   => '_build_connection',
    predicate => 'has_connection',
    lazy      => 1,
);

has topicName =>
    ( is => 'ro', isa => 'Str', builder => '_build_topic_name', lazy => 1, );

has stompEndpoint => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_stomp_endpoint',
    lazy    => 1
);

has stompUsername => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_stomp_username',
    lazy    => 1
);

has stompPassword => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_stomp_password',
    lazy    => 1
);

has queue => (
    is      => 'ro',
    isa     => 'Net::STOMP::Client',
    builder => '_build_queue',
    lazy    => 1
);

has queueName =>
    ( is => 'ro', isa => 'Str', builder => '_build_queue_name', lazy => 1 );

sub emit {
    my ( $self, $message ) = @_;

    if ( !blessed $message) {
        $message = Replay::Message->new($message);
    }

    # THIS MUST DOES A Replay::Role::Envelope
    if ( !$message->does('Replay::Role::Envelope') ) {
        confess 'Can only emit Replay::Role::Envelope consumer';
    }
    my $uuid = $message->UUID;

    $self->connection->send(
        destination => $self->topicName,
        body        => to_json $message->marshall
    ) or return;

    return $uuid;
}

sub poll {
    my ($self) = @_;
    my $handled = 0;

    # only check the channels if we have been shown an interest in
    return $handled if not scalar( @{ $self->subscribers } );
    foreach my $message ( $self->_receive() ) {
        $handled++;

        foreach my $subscriber ( @{ $self->subscribers } ) {
            try {
                $subscriber->($message);
            }
            catch {
                carp
                    q(There was an exception while processing message through subscriber )
                    . $_;
            };
        }
    }
    return $handled;
}

sub subscribe {
    my ( $self, $callback ) = @_;
    croak 'callback must be code' if 'CODE' ne ref $callback;
    push @{ $self->subscribers }, $callback;
    return;
}

sub _acknowledge {
    my ( $self, @frames ) = @_;
    $self->client->ack( frame => $_) foreach (@frames);
}

sub _receive {
    my ($self) = @_;
    my @payloads;
    $self->queue->wait_for_frames(
        callback => sub {
            my ( $self, $frame ) = @_;
            if ( $frame->command() eq "MESSAGE" ) {
                try {
                    my $message_body = from_json $frame->body();
                    my $innermessage = $message_body->{Message};
                    push @payloads,
                        { message => $message_body, frame => $frame };
                }
                catch {
                    carp
                        q(There was an exception while processing message through _receive )
                        . 'message='
                        . Dumper( $frame->body() )
                        . $_;
                    exit;
                }
            }
        },
        timeout => 0
    );
    return if not scalar @payloads;
    $self->_acknowledge(map { $_->{frame} } @payloads);
    return map { $_->{message} } @payloads;
}

sub done {
    my $self = shift;
    return;
}

sub DEMOLISH {
    my ($self) = @_;
    if ( $self->has_connection && $self->mode eq 'fanout' ) {
        $self->connection->disconnect();
    }

    return;
}

sub _build_topic_name {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my ($self) = @_;
    confess q(No purpose) if not $self->purpose;
    return join q(_), $self->config->{stage}, 'replay', $self->purpose;
}

sub _build_queue_name {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    my $ug   = Data::UUID->new;
    return join q(_), $self->config->{stage}, 'replay', $self->purpose,
        ( $self->mode eq 'fanout' ? $ug->to_string( $ug->create ) : () );
}

sub _build_client {
    my $self = shift;
    return Net::STOMP::Client->new( uri => $self->stompEndpoint );
}

sub _build_connection {
    my $self = shift;
    return $self->client->connect(
        login    => $self->stompUsername,
        passcode => $self->stompPassword,
    );
}

sub _build_queue {
    my $self = shift;
    return $self->connection->subscribe(
        destination => $self->topicName,
        id          => Data::UUID->new,
        ack         => "client",           # client side acknowledgment
    );
}

sub _build_stomp_endpoint {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    return $self->config->{EventSystem}->{mqEndpoint};
}

sub _build_stomp_username {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    return $self->config->{EventSystem}->{mqUsername};
}

sub _build_stomp_password {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    return $self->config->{EventSystem}->{mqPassword};
}

1;

__END__

=pod

=head1 NAME

Replay::EventSystem::AWSQueue - AWS Topic/Queue implementation

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This is an Event System implementation module targeting the AWS services
of MQ.  If you were to instantiate it independently, it might 
look like this.

Replay::EventSystem::AWSQueue->new(
    purpose => $purpose,
    config  => {
        stage       => 'test',
        EventSystem => {
            awsIdentity => {
                access => 'AKIAILL6EOKUCA3BDO5A',
                secret => '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',
            },
            mqEndpoint => 'https://sns.us-east-1.amazonaws.com',
            mqUsername => 'doggiedoggie',
            mqPassword => 'doggiedoggie',
        },
    }
);

=head1 DESCRIPTION

Utilizers should expect the object instance to be a singleton per each $purpose.

The account provided is expected to have the permissions to create topics and queues.

It will create SNS topic for the indicated purpose named <stage>-replay-<purpose>

It will create distinct SQS queues for the instance, named <stage>-replay-<purpose>-<uuid>

It will also subscribe the queue to the topic.

=head1 SUBROUTINES/METHODS

=head2 subscribe( sub { my $message = shift; ... } )

each code reference supplied is called with each message received, each time
the message is received.  This is how applications insert their hooks into 
the channel to get notified of the arrival of messages.

=head2 emit( $message )

Send the specified message on the topic for this channel

=head2 poll()

Gets new messages and calls the subscribed hooks with them

=head2 DEMOLISH

Makes sure to properly clean up and disconnect from queues

=head1 AUTHOR

David Ihnen, C<< <davidihnen at gmail.com> >>

=head1 CONFIGURATION AND ENVIRONMENT

Implied by context

=head1 DIAGNOSTICS

nothing to say here

=head1 DEPENDENCIES

Nothing outside the normal Replay world

=head1 INCOMPATIBILITIES

Nothing to report

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-replay at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Replay>.  I will be notified, and then you'

        ll automatically be notified of progress on your bug as I make changes .

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Replay


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Replay>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Replay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Replay>

=item * Search CPAN

L<http://search.cpan.org/dist/Replay/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 David Ihnen.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
