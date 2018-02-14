use utf8;
package Brass::Schema::Result::Docsend;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("docsend");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "doc_id",
  { data_type => "integer", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 1 },
  "code",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "created",
  { data_type => "datetime", is_nullable => 1, datetime_undef_if_invalid => 1 },
  "download_time",
  { data_type => "datetime", is_nullable => 1, datetime_undef_if_invalid => 1 },
  "download_ip_address",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("docsend_ux_code", ["code"]);

1;
