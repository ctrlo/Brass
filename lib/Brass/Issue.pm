=pod
Brass
Copyright (C) 2015 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package Brass::Issue;

use Brass::Issue::Comment;
use Brass::Issue::Priority;
use Brass::Issue::Project;
use Brass::Issue::Status;
use Brass::Issue::Type;
use Brass::User;
use Brass::Users;
use Carp;
use DateTime;
use Mail::Message;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

# All system users. Must be populated before doing any user calls
has users => (
    is => 'rw',
);

has id => (
    is  => 'rwp',
    isa => Maybe[Int],
);

has _rset => (
    is      => 'rwp',
    lazy    => 1,
    builder => 1,
);

has title => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->title; },
);

has description => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->description; },
);

has security_considerations => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->security_considerations; },
);

has rca => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->rca; },
);

has corrective_action => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->corrective_action; },
);

has target_date => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->target_date; },
);

has resources_required => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->resources_required; },
);

has success_description => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->success_description; },
);

has reference => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->reference; },
);

has set_owner => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0] || undef }, # Allow empty strings from form
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('owner'); },
);

has set_author => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0] || undef }, # Allow empty strings from form
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('author'); },
);

has set_approver => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    coerce  => sub { $_[0] || undef }, # Allow empty strings from form
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('approver'); },
);

has set_related_issue => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('related_issue_id'); },
);

sub related_issues
{   my $self = shift;
    $self->_rset->related_issues;
}

has set_tags => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has type => (
    is      => 'rwp',
    isa     => sub { !defined($_[0]) || ref $_[0] eq 'Brass::Issue::Type' or confess "Invalid type: $_[0]"; },
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $type = $self->_rset && $self->_rset->type
            or return;
        Brass::Issue::Type->new(
            id          => $type->id,
            name        => $type->name,
            schema      => $self->schema,
        );
    },
);

has project => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $project = $self->_rset && $self->_rset->project
            or return;
        Brass::Issue::Project->new(
            id          => $project->id,
            name        => $project->name,
            schema      => $self->schema,
        );
    },
);

has opened => (
    is => 'lazy',
);

sub _build_opened
{   my $self = shift;
    my ($status) = $self->schema->resultset('IssueStatus')->search({
        issue => $self->id,
    },{
        rows     => 1,
        order_by => { -asc => 'datetime' },
    })->all
        or return;
    $status->datetime;
}

has status => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my ($status) = $self->schema->resultset('IssueStatus')->search({
            issue => $self->id,
        },{
            rows     => 1,
            order_by => { -desc => 'datetime' },
        })->all
            or return;
        Brass::Issue::Status->new(
            id          => $status->status->id,
            name        => $status->status->name,
            schema      => $self->schema,
        );
    },
);

has set_status => (
    is  => 'rw',
    isa => Maybe[Int],
    trigger => sub {
        my ($self, $value) = @_;
        $self->_set_status_changed(1)
            if ($self->status xor $value) || $self->status != $value;
        my $s = $value && Brass::Issue::Status->new(
            id          => $value,
            schema      => $self->schema,
        );
        $self->_set_status($s);
    },
    coerce => sub { $_[0] || undef }, # Allow empty strings from form
);

has status_changed => (
    is  => 'rwp',
    isa => Bool,
);

has status_history => (
    is => 'lazy',
);

sub _build_status_history
{   my $self = shift;
    my @statuses = $self->schema->resultset('IssueStatus')->search({
        issue => $self->id,
    },{
        order_by => 'datetime',
    })->all;
    my @s = map {
        my $s = Brass::Issue::Status->new(
            id          => $_->get_column('status'),
            datetime    => $_->datetime,
            user        => $self->users->user($_->get_column('user')),
            schema      => $self->schema,
        );
    } @statuses;
    \@s;
}

has priority => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my ($priority) = $self->schema->resultset('IssuePriority')->search({
            issue => $self->id,
        },{
            rows     => 1,
            order_by => { -desc => 'datetime' },
        })->all
            or return;
        Brass::Issue::Priority->new(
            id          => $priority->priority->id,
            name        => $priority->priority->name,
            schema      => $self->schema,
        );
    },
);

has set_priority => (
    is  => 'rw',
    isa => Maybe[Int],
    trigger => sub {
        my ($self, $value) = @_;
        $self->_set_priority_changed(1)
            if ($self->priority xor $value) || (($self->priority && $value) && $self->priority != $value);
        my $s = $value && Brass::Issue::Priority->new(
            id          => $value,
            schema      => $self->schema,
        );
        $self->_set_priority($s);
    },
    coerce => sub { $_[0] || undef }, # Allow empty strings from form
);

has priority_changed => (
    is  => 'rwp',
    isa => Bool,
);

has comments => (
    is  => 'lazy',
    isa => ArrayRef,
);

has files => (
    is  => 'lazy',
    isa => ArrayRef,
);

has priority_history => (
    is  => 'lazy',
    isa => ArrayRef,
);

sub _build_priority_history
{   my $self = shift;
    my @history = $self->schema->resultset('IssuePriority')->search({
        issue => $self->id,
    },{
        order_by => { -desc => 'datetime' },
    })->all;
    # Shift one off, which will be the current status
    shift @history;
    [ map {
        Brass::Issue::Priority->new(
            id          => $_->get_column('priority'),
            datetime    => $_->datetime,
            user        => $self->users->user($_->get_column('user')),
            schema      => $self->schema,
        )
    } @history ];
}

sub user_can_read
{   my ($self, $user) = @_;
    return 1 if $user->has_permission('issue_read_all');
    return 1 if ($user->has_permission('issue_read') || $user->has_permission('issue_read_project')) && !$self->id; # New issue
    return 1 if $user->has_permission('issue_read_project') && $user->has_project($self->project->id);
    return 1 if $user->has_permission('issue_read') &&
        ($self->owner == $user->id || $self->author == $user->id || $self->approver == $user->id);
}

sub user_can_write
{   my ($self, $user) = @_;
    return 1 if $user->has_permission('issue_write_all');
    return 1 if ($user->has_permission('issue_write') || $user->has_permission('issue_write_project')) && !$self->id; # New issue
    return 1 if $user->has_permission('issue_write_project') && $user->has_project($self->project->id);
    return 1 if $user->has_permission('issue_write') &&
        ($self->owner == $user->id || $self->author == $user->id || $self->approver == $user->id);
}

sub owner
{   my $self = shift;
    $self->users->user($self->set_owner);
}

sub author
{   my $self = shift;
    $self->users->user($self->set_author);
}

sub approver
{   my $self = shift;
    $self->users->user($self->set_approver);
}

sub related_issue
{   my $self = shift;
    $self->_rset && $self->_rset->related_issue;
}

sub set_type
{   my ($self, $id) = @_;
    $id ||= undef; # Allow empty string from form
    $self->_set_type($id && Brass::Issue::Type->new(id => $id, schema => $self->schema));
}

sub set_project
{   my ($self, $id) = @_;
    $self->_set_project(Brass::Issue::Project->new(id => $id, schema => $self->schema));
}

sub has_tag
{   my ($self, $tag_id) = @_;
    $self->schema->resultset('IssueTag')->search({
        issue => $self->id,
        tag   => $tag_id,
    })->count;
}

sub _build_comments
{   my $self = shift;
    my $comments_rs = $self->schema->resultset('Comment')->search({
        issue => $self->id,
    },{
        order_by => 'me.datetime',
    });
    $comments_rs->result_class('Brass::Issue::Comment');
    my @all = $comments_rs->all;
    $_->users($self->users) foreach @all;
    \@all;
}

sub _build_files
{   my $self = shift;
    my @files = $self->schema->resultset('File')->search({
        issue => $self->id,
    })->all;
    \@files;
}

sub comment_add
{   my ($self, %options) = @_;
    $self->schema->resultset('Comment')->create({
        text     => $options{text},
        author   => $options{user_id},
        issue    => $self->id,
        datetime => DateTime->now,
    });
}

sub send_notifications
{   my ($self, %options) = @_;
    my $id = $self->id;

    # Avoid duplicates
    my %to_send = map { $_->id => $_ } grep { $_ } ($self->author, $self->owner, $self->approver);

    if ($options{is_new})
    {
        my $users = Brass::Users->new(schema => $self->schema);
        $to_send{$_->id} = $_
            foreach @{$users->all(role => 'new_issue_alert')};
    }

    foreach my $person (values %to_send)
    {
        next if $person == $options{logged_in_user_id};

        next if !$person || $person->deleted;

        my $msg = Mail::Message->build(
            To             => $person->email,
            'Content-Type' => 'text/plain',
            Subject        => $options{is_new} ? 'New ticket created' : 'Ticket updated',
            data           => <<__PLAIN,
A ticket that you are involved in has been updated:

$options{uri_base}/issue/$id
__PLAIN
        )->send(via => 'sendmail');
    }
}

sub inflate_result {
    my $data     = $_[2];
    my $schema   = $_[1]->schema;
    my $prefetch = $_[3];

    my $pri      = $prefetch->{issue_priorities}->[0]->[1]->{priority}->[0];
    my $priority = Brass::Issue::Priority->new(
        id          => $pri->{id},
        name        => $pri->{name},
        schema      => $schema,
    );

    my $stat   = $prefetch->{issue_statuses}->[0]->[1]->{status}->[0];
    my $status = Brass::Issue::Status->new(
        id          => $stat->{id},
        name        => $stat->{name},
        schema      => $schema,
    );

    my $project = Brass::Issue::Project->new(
        id          => $prefetch->{project}->[0]->{id},
        name        => $prefetch->{project}->[0]->{name},
        schema      => $schema,
    );

    $_[0]->new(
        id                      => $data->{id},
        title                   => $data->{title},
        description             => $data->{description},
        security_considerations => $data->{security_considerations},
        rca                     => $data->{rca},
        corrective_action       => $data->{corrective_action},
        target_date             => $data->{target_date},
        resources_required      => $data->{resources_required},
        success_description     => $data->{success_description},
        reference               => $data->{reference},
        set_type                => $data->{type},
        set_owner               => $data->{owner},
        set_author              => $data->{author},
        set_approver            => $data->{approver},
        set_related_issue       => $data->{related_issue_id},
        priority                => $priority,
        status                  => $status,
        project                 => $project,
        schema                  => $schema,
    );
}

sub _build__rset
{   my $self = shift;
    my ($issue) = $self->schema->resultset('Issue')->search({
        'me.id' => $self->id,
    })->all;
    $issue;
}

sub write
{   my ($self, $user_id) = @_;
    my $values = {
        title                   => $self->title,
        description             => $self->description,
        security_considerations => $self->security_considerations,
        rca                     => $self->rca,
        corrective_action       => $self->corrective_action,
        target_date             => $self->target_date || undef,
        resources_required      => $self->resources_required,
        success_description     => $self->success_description,
        reference               => $self->reference,
        type                    => ($self->type && $self->type->id),
        project                 => $self->project->id,
        owner                   => $self->set_owner,
        author                  => $self->set_author,
        approver                => $self->set_approver,
        related_issue_id        => $self->set_related_issue,
    };
    if ($self->id)
    {
        $self->_rset->update($values);
    }
    else {
        $self->_set__rset($self->schema->resultset('Issue')->create($values));
        $self->_set_id($self->_rset->id);
    }
    if ($self->status_changed)
    {
        # Status changed, write
        $self->schema->resultset('IssueStatus')->create({
            issue    => $self->id,
            status   => $self->set_status,
            user     => $user_id,
            datetime => DateTime->now,
        });
    }
    if ($self->priority_changed)
    {
        # Priority changed, write
        $self->schema->resultset('IssuePriority')->create({
            issue    => $self->id,
            priority => $self->set_priority,
            user     => $user_id,
            datetime => DateTime->now,
        });
    }
    my %has_tags = map { $_ => 1 } @{$self->set_tags};
    foreach my $tag ($self->schema->resultset('Tag')->all)
    {
        if ($has_tags{$tag->id})
        {
            $self->schema->resultset('IssueTag')->find_or_create({
                issue => $self->id,
                tag   => $tag->id,
            });
        }
        else {
            $self->schema->resultset('IssueTag')->search({
                issue => $self->id,
                tag   => $tag->id,
            })->delete;
        }
    }
}

sub as_string
{   my $self = shift;
    $self->title;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

1;

