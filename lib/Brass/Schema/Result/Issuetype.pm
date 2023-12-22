use utf8;
package Brass::Schema::Result::Issuetype;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("issuetype");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "identifier",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "is_vulnerability",
  { data_type => "smallint", is_nullable => 0, default_value => 0 },
  "is_breach",
  { data_type => "smallint", is_nullable => 0, default_value => 0 },
  "is_audit",
  { data_type => "smallint", is_nullable => 0, default_value => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "issues",
  "Brass::Schema::Result::Issue",
  { "foreign.type" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
