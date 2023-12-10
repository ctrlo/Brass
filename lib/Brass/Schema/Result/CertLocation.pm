use utf8;
package Brass::Schema::Result::CertLocation;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("cert_location");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cert_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "filename_cert",
  { data_type => "text", is_nullable => 1 },
  "filename_key",
  { data_type => "text", is_nullable => 1 },
  "filename_ca",
  { data_type => "text", is_nullable => 1 },
  "file_user",
  { data_type => "text", is_nullable => 1 },
  "file_group",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "cert",
  "Brass::Schema::Result::Cert",
  { id => "cert_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->has_many(
  "cert_location_uses",
  "Brass::Schema::Result::CertLocationUse",
  { "foreign.cert_location_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
