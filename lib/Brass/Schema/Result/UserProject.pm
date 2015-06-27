use utf8;
package Brass::Schema::Result::UserProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::Schema::Result::UserProject

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

=head1 TABLE: C<user_project>

=cut

__PACKAGE__->table("user_project");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 project

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "project",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 project

Type: belongs_to

Related object: L<Brass::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Brass::Schema::Result::Project",
  { id => "project" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<Brass::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Brass::Schema::Result::User",
  { id => "user" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-06-27 15:25:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:riMZ7xwpNT6JWyalYnRGQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
