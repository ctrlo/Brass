use utf8;
package Brass::Schema::Result::CertUse;

=head1 NAME

Brass::Schema::Result::CertUse

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

Related object: L<Brass::Schema::Result::ServerCert>

=cut

__PACKAGE__->has_many(
  "server_certs",
  "Brass::Schema::Result::ServerCert",
  { "foreign.use" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
