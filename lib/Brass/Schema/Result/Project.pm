use utf8;
package Brass::Schema::Result::Project;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::Schema::Result::Project

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

=head1 TABLE: C<project>

=cut

__PACKAGE__->table("project");

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
  { "foreign.project" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_projects

Type: has_many

Related object: L<Brass::Schema::Result::UserProject>

=cut

__PACKAGE__->has_many(
  "user_projects",
  "Brass::Schema::Result::UserProject",
  { "foreign.project" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-06-27 15:25:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R3/6MHD++m/AZR12MY2VPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
