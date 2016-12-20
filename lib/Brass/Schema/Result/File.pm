use utf8;
package Brass::Schema::Result::File;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("file");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "uploaded_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "issue",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "datetime",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "mimetype",
  { data_type => "text", is_nullable => 1 },
  "content",
  { data_type => "longblob", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "uploaded_by",
  "Brass::Schema::Result::User",
  { id => "uploaded_by" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "issue",
  "Brass::Schema::Result::Issue",
  { id => "issue" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
