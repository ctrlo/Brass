use utf8;
package Brass::Schema::Result::Servertype;

=head1 NAME

Brass::Schema::Result::Servertype

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

=head1 TABLE: C<type>

=cut

__PACKAGE__->table("servertype");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 server_servertypes

Servertype: has_many

Related object: L<Brass::Schema::Result::ServerServertype>

=cut

__PACKAGE__->has_many(
  "server_servertypes",
  "Brass::Schema::Result::ServerServertype",
  { "foreign.servertype_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
