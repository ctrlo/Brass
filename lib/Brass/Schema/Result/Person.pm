use utf8;
package Brass::Schema::Result::Person;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::Schema::Result::Person

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

=head2 comments

Type: has_many

Related object: L<Brass::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "Brass::Schema::Result::Comment",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_approvers

Type: has_many

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issue_approvers",
  "Brass::Schema::Result::Issue",
  { "foreign.approver" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_authors

Type: has_many

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issue_authors",
  "Brass::Schema::Result::Issue",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_owners

Type: has_many

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issue_owners",
  "Brass::Schema::Result::Issue",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-10-01 11:03:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mgWB7Q4qJcJBor6C9DquWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
