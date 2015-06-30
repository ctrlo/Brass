use utf8;
package Brass::ConfigSchema::Result::Server;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::ConfigSchema::Result::Server

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "domain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

Related object: L<Brass::ConfigSchema::Result::Domain>

=cut

__PACKAGE__->belongs_to(
  "domain",
  "Brass::ConfigSchema::Result::Domain",
  { id => "domain_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 server_certs

Type: has_many

Related object: L<Brass::ConfigSchema::Result::ServerCert>

=cut

__PACKAGE__->has_many(
  "server_certs",
  "Brass::ConfigSchema::Result::ServerCert",
  { "foreign.server_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 server_types

Type: has_many

Related object: L<Brass::ConfigSchema::Result::ServerType>

=cut

__PACKAGE__->has_many(
  "server_types",
  "Brass::ConfigSchema::Result::ServerType",
  { "foreign.server_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sqldbs

Type: has_many

Related object: L<Brass::ConfigSchema::Result::Sqldb>

=cut

__PACKAGE__->has_many(
  "sqldbs",
  "Brass::ConfigSchema::Result::Sqldb",
  { "foreign.server_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-28 20:41:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PN3qfTwJo4DpSZ4oiHsVlw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
