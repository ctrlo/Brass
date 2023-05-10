use utf8;
package Brass::Schema::Result::Uad;

=head1 NAME

Brass::Schema::Result::Uad

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

=head1 TABLE: C<uad>

=cut

__PACKAGE__->table("uad");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 owner

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "owner",
  { data_type => "integer", is_nullable => 1 },
  "serial",
  { data_type => "text", is_nullable => 1 },
  "purchased",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 pws

Type: has_many

Related object: L<Brass::Schema::Result::Pw>

=cut

__PACKAGE__->has_many(
  "pws",
  "Brass::Schema::Result::Pw",
  { "foreign.uad_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
