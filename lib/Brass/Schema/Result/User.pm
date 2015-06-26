use utf8;
package Brass::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 deleted

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 pwchanged

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 pwresetcode

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 lastlogin

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "deleted",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "pwchanged",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "pwresetcode",
  { data_type => "char", is_nullable => 1, size => 32 },
  "lastlogin",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
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

=head2 issue_priorities

Type: has_many

Related object: L<Brass::Schema::Result::IssuePriority>

=cut

__PACKAGE__->has_many(
  "issue_priorities",
  "Brass::Schema::Result::IssuePriority",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_statuses

Type: has_many

Related object: L<Brass::Schema::Result::IssueStatus>

=cut

__PACKAGE__->has_many(
  "issue_statuses",
  "Brass::Schema::Result::IssueStatus",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_permissions

Type: has_many

Related object: L<Brass::Schema::Result::UserPermission>

=cut

__PACKAGE__->has_many(
  "user_permissions",
  "Brass::Schema::Result::UserPermission",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-06-26 23:58:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fK0ft2ne8LdfFv53o4J3Pg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
