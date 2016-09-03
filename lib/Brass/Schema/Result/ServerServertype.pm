use utf8;
package Brass::Schema::Result::ServerServertype;

=head1 NAME

Brass::Schema::Result::ServerServertype

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

=head1 TABLE: C<server_type>

=cut

__PACKAGE__->table("server_servertype");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 server_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 servertype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "server_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "servertype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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

=head2 servertype

Type: belongs_to

Related object: L<Brass::Schema::Result::Servertype>

=cut

__PACKAGE__->belongs_to(
  "servertype",
  "Brass::Schema::Result::Servertype",
  { id => "servertype_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
