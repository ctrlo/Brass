use utf8;
package Brass::Schema::Result::Docreadtype;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("docreadtype");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "user_docreadtypes",
  "Brass::Schema::Result::UserDocreadtype",
  { "foreign.docreadtype_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "doc_docreadtypes",
  "Brass::Schema::Result::DocDocreadtype",
  { "foreign.docreadtype_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
