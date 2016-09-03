use utf8;
package Brass::Schema::Result::Issuetype;

=head1 NAME

Brass::Schema::Result::Type

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<type>

=cut

__PACKAGE__->table("issuetype");

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

=head2 issues

Type: has_many

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issues",
  "Brass::Schema::Result::Issue",
  { "foreign.type" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
