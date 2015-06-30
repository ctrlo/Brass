use utf8;
package Brass::ConfigSchema::Result::Domain;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::ConfigSchema::Result::Domain

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

=head1 TABLE: C<domain>

=cut

__PACKAGE__->table("domain");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 servers

Type: has_many

Related object: L<Brass::ConfigSchema::Result::Server>

=cut

__PACKAGE__->has_many(
  "servers",
  "Brass::ConfigSchema::Result::Server",
  { "foreign.domain_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-28 20:41:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YVXQxBEHKNvS+VfsDTILZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
