use utf8;
package Brass::DocSchema::Result::Version;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::DocSchema::Result::Version

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

=head1 TABLE: C<version>

=cut

__PACKAGE__->table("version");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 doc_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 major

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 minor

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 revision

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 signed

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 record

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 created

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 reviewer

  data_type: 'integer'
  is_nullable: 1

=head2 approver

  data_type: 'integer'
  is_nullable: 1

=head2 retired

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 blobext

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 mimetype

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "doc_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "major",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "minor",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "revision",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "signed",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "record",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "created",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "reviewer",
  { data_type => "integer", is_nullable => 1 },
  "approver",
  { data_type => "integer", is_nullable => 1 },
  "retired",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "blobext",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "mimetype",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "notes",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 doc

Type: belongs_to

Related object: L<Brass::DocSchema::Result::Doc>

=cut

__PACKAGE__->belongs_to(
  "doc",
  "Brass::DocSchema::Result::Doc",
  { id => "doc_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 version_content

Type: might_have

Related object: L<Brass::DocSchema::Result::VersionContent>

=cut

__PACKAGE__->might_have(
  "version_content",
  "Brass::DocSchema::Result::VersionContent",
  { "foreign.id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-01 10:57:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y18bQKfrouk/Uc+r/Pumcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
