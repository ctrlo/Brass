use utf8;
package Brass::Schema::Result::Cert;

=head1 NAME

Brass::Schema::Result::Cert

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

=head1 TABLE: C<cert>

=cut

__PACKAGE__->table("cert");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 content

  data_type: 'text'
  is_nullable: 1

=head2 cn

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 expiry

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 usedby

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 filename

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 file_user

  data_type: 'text'
  is_nullable: 1

=head2 file_group

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 1 },
  "cn",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "expiry",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "usedby",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "filename",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "file_user",
  { data_type => "text", is_nullable => 1 },
  "file_group",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 server_certs

Type: has_many

Related object: L<Brass::Schema::Result::ServerCert>

=cut

__PACKAGE__->has_many(
  "server_certs",
  "Brass::Schema::Result::ServerCert",
  { "foreign.cert_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
