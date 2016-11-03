use utf8;
package Brass::Schema::Result::IssueStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Brass::Schema::Result::IssueStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<issue_status>

=cut

__PACKAGE__->table("issue_status");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 issue

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 datetime

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "issue",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "datetime",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 issue

Type: belongs_to

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->belongs_to(
  "issue",
  "Brass::Schema::Result::Issue",
  { id => "issue" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 status

Type: belongs_to

Related object: L<Brass::Schema::Result::Status>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Brass::Schema::Result::Status",
  { id => "status" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<Brass::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Brass::Schema::Result::User",
  { id => "user" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-06-26 23:58:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mAGWGGA1ymkrWx/sHGul4g

# Enable finding of latest status for an issue
__PACKAGE__->might_have(
    issuestatus_later => 'IssueStatus',
    sub {
        my $args = shift;

        return {
            "$args->{foreign_alias}.issue"  => { -ident => "$args->{self_alias}.issue" },
            "$args->{foreign_alias}.datetime" => { '>' => \"$args->{self_alias}.datetime" },
        };
    }
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
