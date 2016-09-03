use utf8;
package Brass::Schema::Result::ServerCert;

=head1 NAME

Brass::Schema::Result::ServerCert

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

=head1 TABLE: C<server_cert>

=cut

__PACKAGE__->table("server_cert");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 server_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cert_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 use

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "server_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cert_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "use",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 cert

Type: belongs_to

Related object: L<Brass::Schema::Result::Cert>

=cut

__PACKAGE__->belongs_to(
  "cert",
  "Brass::Schema::Result::Cert",
  { id => "cert_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 server

Type: belongs_to

Related object: L<Brass::Schema::Result::Server>

=cut

__PACKAGE__->belongs_to(
  "server",
  "Brass::Schema::Result::Server",
  { id => "server_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 use

Type: belongs_to

Related object: L<Brass::Schema::Result::CertUse>

=cut

__PACKAGE__->belongs_to(
  "use",
  "Brass::Schema::Result::CertUse",
  { id => "use" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

1;
