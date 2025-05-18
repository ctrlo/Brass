use utf8;
package Brass::Schema::Result::Config;

use strict;
use warnings;

use Log::Report;
use Net::CIDR;
use Moo;

extends 'DBIx::Class::Core';
with 'Brass::Role::MonitoringHosts';

sub BUILDARGS { $_[2] || {} }

__PACKAGE__->load_components("+Brass::DBIC");

__PACKAGE__->table("config");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "internal_networks",
  { data_type => "text", is_nullable => 1 },
  "smtp_relayhost",
  { data_type => "text", is_nullable => 1 },
  "wazuh_manager",
  { data_type => "text", is_nullable => 1 },
  "monitoring_hosts",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

sub internal_networks_all
{   my $self = shift;
    split /[\s,]+/, $self->internal_networks;
}

sub validate
{   my $self = shift;

    foreach my $range ($self->internal_networks_all)
    {
        Net::CIDR::cidrvalidate($range)
            or error __x"Invalid IP range restriction: {range}", range => $range;
    }

    $self->validate_monitoring_hosts;
}

1;
