use utf8;
package Brass::ConfigSchema::Result::CertUse;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::ConfigSchema::Result::CertUse

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

=head1 TABLE: C<cert_use>

=cut

__PACKAGE__->table("cert_use");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 server_certs

Type: has_many

Related object: L<Brass::ConfigSchema::Result::ServerCert>

=cut

__PACKAGE__->has_many(
  "server_certs",
  "Brass::ConfigSchema::Result::ServerCert",
  { "foreign.use" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-30 09:42:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lMoH0ScxzsgyjY3UFZqj2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
