use utf8;
package Brass::Schema::Result::Servertype;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("servertype");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "server_servertypes",
  "Brass::Schema::Result::ServerServertype",
  { "foreign.servertype_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_servertypes",
  "Brass::Schema::Result::UserServertype",
  { "foreign.servertype" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
