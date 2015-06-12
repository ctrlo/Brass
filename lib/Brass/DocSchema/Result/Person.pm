use utf8;
package Brass::DocSchema::Result::Person;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::DocSchema::Result::Person

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

=head1 TABLE: C<person>

=cut

__PACKAGE__->table("person");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 docs

Type: has_many

Related object: L<Brass::DocSchema::Result::Doc>

=cut

__PACKAGE__->has_many(
  "docs",
  "Brass::DocSchema::Result::Doc",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 version_approvers

Type: has_many

Related object: L<Brass::DocSchema::Result::Version>

=cut

__PACKAGE__->has_many(
  "version_approvers",
  "Brass::DocSchema::Result::Version",
  { "foreign.approver" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 version_reviewers

Type: has_many

Related object: L<Brass::DocSchema::Result::Version>

=cut

__PACKAGE__->has_many(
  "version_reviewers",
  "Brass::DocSchema::Result::Version",
  { "foreign.reviewer" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-10 21:24:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JsmsPnnKZG0NM5F/pTXsiw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
