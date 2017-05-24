use utf8;
package Brass::Schema::Result::Event;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("event");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "from",
  { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "to",
  { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "editor_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "eventtype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "customer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "editor",
  "Brass::Schema::Result::User",
  { id => "editor_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "eventtype",
  "Brass::Schema::Result::Eventtype",
  { id => "eventtype_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->belongs_to(
  "customer",
  "Brass::Schema::Result::Customer",
  { id => "customer_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "event_people",
  "Brass::Schema::Result::EventPerson",
  { "foreign.event_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
