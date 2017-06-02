use utf8;
package Brass::Schema::Result::Tag;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("tag");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);

__PACKAGE__->set_primary_key("id");

1;
