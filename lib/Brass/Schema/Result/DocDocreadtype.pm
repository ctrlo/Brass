use utf8;
package Brass::Schema::Result::DocDocreadtype;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("doc_docreadtype");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "doc_id",
  { data_type => "integer", is_nullable => 0 },
  "docreadtype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "docreadtype",
  "Brass::Schema::Result::Docreadtype",
  { id => "docreadtype_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
