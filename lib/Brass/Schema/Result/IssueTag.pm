use utf8;
package Brass::Schema::Result::IssueTag;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("issue_tag");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "issue",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tag",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "issue",
  "Brass::Schema::Result::Issue",
  { id => "issue" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

__PACKAGE__->belongs_to(
  "tag",
  "Brass::Schema::Result::Tag",
  { id => "tag" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
