use utf8;
package Brass::IssueSchema::Result::Comment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::IssueSchema::Result::Comment

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

=head1 TABLE: C<comment>

=cut

__PACKAGE__->table("comment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 text

  data_type: 'text'
  is_nullable: 1

=head2 author

  data_type: 'integer'
  is_nullable: 1

=head2 issue_id

  data_type: 'integer'
  is_nullable: 1

=head2 datetime

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "text",
  { data_type => "text", is_nullable => 1 },
  "author",
  { data_type => "integer", is_nullable => 1 },
  "issue_id",
  { data_type => "integer", is_nullable => 1 },
  "datetime",
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

=head2 id

Type: belongs_to

Related object: L<Brass::IssueSchema::Result::Issue>

=cut

__PACKAGE__->belongs_to(
  "id",
  "Brass::IssueSchema::Result::Issue",
  { id => "id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-26 10:14:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dyu44h6dnEleZxzDXfvEOA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
