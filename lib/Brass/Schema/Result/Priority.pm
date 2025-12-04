use utf8;
package Brass::Schema::Result::Priority;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("priority");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "alert_frequency",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "issue_priorities",
  "Brass::Schema::Result::IssuePriority",
  { "foreign.priority" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
