use utf8;
package Brass::Schema::Result::Status;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("status");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "visible",
  { data_type => "smallint", is_nullable => 0, default_value => 1 },
  "identifier",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "issue_statuses",
  "Brass::Schema::Result::IssueStatus",
  { "foreign.status" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
