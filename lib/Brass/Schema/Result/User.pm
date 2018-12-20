use utf8;
package Brass::Schema::Result::User;

=head1 NAME

Brass::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 deleted

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 pwchanged

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 pwresetcode

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 lastlogin

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "deleted",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "pwchanged",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "pwresetcode",
  { data_type => "char", is_nullable => 1, size => 32 },
  "lastlogin",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 comments

Type: has_many

Related object: L<Brass::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "Brass::Schema::Result::Comment",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_approvers

Type: has_many

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issue_approvers",
  "Brass::Schema::Result::Issue",
  { "foreign.approver" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_authors

Type: has_many

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issue_authors",
  "Brass::Schema::Result::Issue",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_owners

Type: has_many

Related object: L<Brass::Schema::Result::Issue>

=cut

__PACKAGE__->has_many(
  "issue_owners",
  "Brass::Schema::Result::Issue",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_priorities

Type: has_many

Related object: L<Brass::Schema::Result::IssuePriority>

=cut

__PACKAGE__->has_many(
  "issue_priorities",
  "Brass::Schema::Result::IssuePriority",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 issue_statuses

Type: has_many

Related object: L<Brass::Schema::Result::IssueStatus>

=cut

__PACKAGE__->has_many(
  "issue_statuses",
  "Brass::Schema::Result::IssueStatus",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_permissions

Type: has_many

Related object: L<Brass::Schema::Result::UserPermission>

=cut

__PACKAGE__->has_many(
  "user_permissions",
  "Brass::Schema::Result::UserPermission",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_projects

Type: has_many

Related object: L<Brass::Schema::Result::UserProject>

=cut

__PACKAGE__->has_many(
  "user_projects",
  "Brass::Schema::Result::UserProject",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_servertypes

Type: has_many

Related object: L<Brass::Schema::Result::UserServertype>

=cut

__PACKAGE__->has_many(
  "user_servertypes",
  "Brass::Schema::Result::UserServertype",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_pws

Type: has_many

Related object: L<Brass::Schema::Result::Pw>

=cut

__PACKAGE__->has_many(
  "pws",
  "Brass::Schema::Result::Pw",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_topics

Type: has_many

Related object: L<Brass::Schema::Result::UserTopic>

=cut

__PACKAGE__->has_many(
  "user_topics",
  "Brass::Schema::Result::UserTopic",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub name
{   my $self = shift;
    return $self->firstname." ".$self->surname;
}

sub update_permissions
{   my ($self, @permission_ids) = @_;
    $self->user_permissions->delete; # lazy - should search first
    foreach my $permission_id (@permission_ids)
    {
        $self->create_related('user_permissions', {permission => $permission_id});
    }
}

sub update_projects
{   my ($self, @project_ids) = @_;
    $self->user_projects->delete; # lazy
    foreach my $project_id (@project_ids)
    {
        $self->create_related('user_projects', {project => $project_id});
    }
}

sub update_servertypes
{   my ($self, @servertype_ids) = @_;
    $self->user_servertypes->delete; # lazy
    foreach my $servertype_id (@servertype_ids)
    {
        $self->create_related('user_servertypes', {servertype => $servertype_id});
    }
}

sub update_topics
{   my ($self, %params) = @_;
    $self->user_topics->delete; # lazy

    use Data::Dumper; say STDERR Dumper \%params;
    foreach my $topic_id (@{$params{doc}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
    foreach my $topic_id (@{$params{doc_publish}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc_publish',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
    foreach my $topic_id (@{$params{doc_save}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc_save',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
    foreach my $topic_id (@{$params{doc_record}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc_record',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
}

sub has_permission
{   my ($self, $permission) = @_;
    (grep { $_->permission->name eq $permission } $self->user_permissions) ? 1 : 0;
}

sub has_project
{   my ($self, $project_id) = @_;
    (grep { $_->project->id == $project_id } $self->user_projects) ? 1 : 0;
}

sub has_servertype
{   my ($self, $servertype_id) = @_;
    (grep { $_->servertype->id == $servertype_id } $self->user_servertypes) ? 1 : 0;
}

sub has_topic_permission
{   my ($self, $topic_id, $permission) = @_;
    my @user_topics = $self->user_topics
        or return 1; # If not limited, user will have no topics
    (grep { $_->topic == $topic_id && $_->permission->name eq $permission } @user_topics) ? 1 : 0;
}

sub issue_permissions
{   my $self = shift;
    my @perms = grep { $_->permission->name =~ /issue_/ } $self->user_permissions;
    join ', ', map { $_->permission->description } @perms;
}

1;
