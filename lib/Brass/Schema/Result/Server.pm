use utf8;
package Brass::Schema::Result::Server;

=head1 NAME

Brass::Schema::Result::Server

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<server>

=cut

__PACKAGE__->table("server");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 domain_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sudo

  data_type: 'text'
  is_nullable: 1

=head2 update_datetime

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 update_result

  data_type: 'text'
  is_nullable: 1

=head2 restart_required

  data_type: 'text'
  is_nullable: 1

=head2 os_version

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 backup_verify

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "domain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sudo",
  { data_type => "text", is_nullable => 1 },
  "update_datetime",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "update_result",
  { data_type => "text", is_nullable => 1 },
  "restart_required",
  { data_type => "text", is_nullable => 1 },
  "os_version",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "backup_verify",
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
  "is_production",
  { data_type => "smallint", is_nullable => 0, default_value => 0 },
  "local_ip",
  { data_type => "text", is_nullable => 1 },
  "metadata",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_UNIQUE>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_UNIQUE", ["name"]);

=head1 RELATIONS

=head2 domain

Type: belongs_to

Related object: L<Brass::Schema::Result::Domain>

=cut

__PACKAGE__->belongs_to(
  "domain",
  "Brass::Schema::Result::Domain",
  { id => "domain_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pws

Type: has_many

Related object: L<Brass::Schema::Result::Pw>

=cut

__PACKAGE__->has_many(
  "pws",
  "Brass::Schema::Result::Pw",
  { "foreign.server_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 server_certs

Type: has_many

Related object: L<Brass::Schema::Result::ServerCert>

=cut

__PACKAGE__->has_many(
  "server_certs",
  "Brass::Schema::Result::ServerCert",
  { "foreign.server_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 server_servertypes

Type: has_many

Related object: L<Brass::Schema::Result::ServerServertype>

=cut

__PACKAGE__->has_many(
  "server_servertypes",
  "Brass::Schema::Result::ServerServertype",
  { "foreign.server_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sites

Type: has_many

Related object: L<Brass::Schema::Result::Site>

=cut

__PACKAGE__->has_many(
  "sites",
  "Brass::Schema::Result::Site",
  { "foreign.server_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
