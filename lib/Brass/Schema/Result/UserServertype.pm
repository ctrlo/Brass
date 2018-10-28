use utf8;
package Brass::Schema::Result::UserServertype;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("user_servertype");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "servertype",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "servertype",
  "Brass::Schema::Result::Servertype",
  { id => "servertype" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "user",
  "Brass::Schema::Result::User",
  { id => "user" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
