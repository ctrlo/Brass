use utf8;
package Brass::Schema::Result::App;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("app");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "status_last_run",
  { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 }
);

__PACKAGE__->set_primary_key("id");

1;
