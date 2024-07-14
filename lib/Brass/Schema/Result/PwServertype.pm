use utf8;
package Brass::Schema::Result::PwServertype;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("pw_servertype");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "servertype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pw_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "servertype",
  "Brass::Schema::Result::Servertype",
  { id => "servertype_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "pw",
  "Brass::Schema::Result::Pw",
  { id => "pw_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

1;
