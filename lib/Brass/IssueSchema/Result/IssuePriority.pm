use utf8;
package Brass::IssueSchema::Result::IssuePriority;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::IssueSchema::Result::IssuePriority

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

=head1 TABLE: C<issue_priority>

=cut

__PACKAGE__->table("issue_priority");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 issue

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 priority

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 datetime

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 user

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "issue",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "priority",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "datetime",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "user",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 issue

Type: belongs_to

Related object: L<Brass::IssueSchema::Result::Issue>

=cut

__PACKAGE__->belongs_to(
  "issue",
  "Brass::IssueSchema::Result::Issue",
  { id => "issue" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 priority

Type: belongs_to

Related object: L<Brass::IssueSchema::Result::Priority>

=cut

__PACKAGE__->belongs_to(
  "priority",
  "Brass::IssueSchema::Result::Priority",
  { id => "priority" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-26 14:38:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NkaQTxfuLKg9bJJlJx1ZOQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
