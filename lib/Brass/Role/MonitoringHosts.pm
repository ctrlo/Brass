package Brass::Role::MonitoringHosts;

use strict;
use warnings;

use Data::Validate::IP qw/is_ipv4/;
use Log::Report;
use Moo::Role;

sub monitoring_hosts_all
{   my $self = shift;
    split /[\s,]+/, $self->monitoring_hosts;
}

sub validate_monitoring_hosts
{   my $self = shift;
    foreach my $ip ($self->monitoring_hosts_all)
    {
        is_ipv4($ip)
            or error __x"Invalid monitoring IP address: {ip}", ip => $ip;
    }
}

1;
