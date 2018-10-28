use utf8;
package Brass::Schema::Result::Pw;

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("pw");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "server_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "uad_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "pwencrypt",
  { data_type => "blob", is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "last_changed",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "publickey",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "server",
  "Brass::Schema::Result::Server",
  { id => "server_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "uad",
  "Brass::Schema::Result::Uad",
  { id => "uad_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "user",
  "Brass::Schema::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

1;
