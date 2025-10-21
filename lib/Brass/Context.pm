package Brass::Context;

use strict;
use warnings;

use Log::Report;

use Moo;

with 'MooX::Singleton';

has dancer_config => (
    is       => 'lazy',
    required => 1,
);

sub sms_config
{   my $self = shift;

    my $sms_config = $self->dancer_config;

    my $username = $sms_config->{username}
        or panic "SMS username not defined";
    my $password = $sms_config->{password}
        or panic "SMS password not defined";
    my $senders = $sms_config->{from}
        or panic "SMS sender configuration not defined";
    ref $senders eq 'HASH'
        or panic "SMS sender configuration not an object";
    # Can add other sender options later if required
    my $from = $senders->{default}
        or panic "SMS default sender missing";

    +{
        from     => $from,
        password => $password,
        url      => "https://api.bulksms.com/v1/messages",
        username => $username,
    };
}

has current_user => (
    is => 'rw',
);

1;
