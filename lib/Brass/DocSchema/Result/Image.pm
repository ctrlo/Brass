use utf8;
package Brass::DocSchema::Result::Image;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::DocSchema::Result::Image

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

=head1 TABLE: C<image>

=cut

__PACKAGE__->table("image");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 doc_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 filename

  data_type: 'text'
  is_nullable: 1

=head2 mimetype

  data_type: 'text'
  is_nullable: 1

=head2 content

  data_type: 'longblob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "doc_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "filename",
  { data_type => "text", is_nullable => 1 },
  "mimetype",
  { data_type => "text", is_nullable => 1 },
  "content",
  { data_type => "longblob", is_nullable => 1 },
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
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-06-23 06:55:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tz3xt13otP12yuCLXRZgUw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
