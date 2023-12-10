use utf8;
package Brass::Schema::Result::CertLocationUse;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("cert_location_use");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cert_location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "use_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "cert_location",
  "Brass::Schema::Result::CertLocation",
  { id => "cert_location_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "use",
  "Brass::Schema::Result::CertUse",
  { id => "use_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
