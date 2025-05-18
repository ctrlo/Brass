use utf8;
package Brass::Schema::Result::Servertype;

use strict;
use warnings;

use Log::Report;

use Moo;

extends 'DBIx::Class::Core';
with 'Brass::Role::MonitoringHosts';

sub BUILDARGS { $_[2] || {} }

__PACKAGE__->load_components("InflateColumn::DateTime", "+Brass::DBIC");

__PACKAGE__->table("servertype");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "monitoring_hosts",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "server_servertypes",
  "Brass::Schema::Result::ServerServertype",
  { "foreign.servertype_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_servertypes",
  "Brass::Schema::Result::UserServertype",
  { "foreign.servertype" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub for_api
{   my $self = shift;
    +{
        name             => $self->name,
        monitoring_hosts => [$self->monitoring_hosts_all],
    }
}

sub validate
{   my $self = shift;

    $self->validate_monitoring_hosts;
}

1;
