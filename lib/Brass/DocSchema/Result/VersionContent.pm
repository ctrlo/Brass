use utf8;
package Brass::DocSchema::Result::VersionContent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::DocSchema::Result::VersionContent

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

=head1 TABLE: C<version_content>

=cut

__PACKAGE__->table("version_content");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 content

  data_type: 'longtext'
  is_nullable: 1

=head2 content_blob

  data_type: 'longblob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "content",
  { data_type => "longtext", is_nullable => 1 },
  "content_blob",
  { data_type => "longblob", is_nullable => 1 },
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

Related object: L<Brass::DocSchema::Result::Version>

=cut

__PACKAGE__->belongs_to(
  "id",
  "Brass::DocSchema::Result::Version",
  { id => "id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-11 09:13:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xzg2IEPuFppzc8fxx9RN0g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
