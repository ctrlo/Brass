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

has completion_time => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->completion_time; },
);

has reference => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->reference; },
);

has security => (
    is      => 'rw',
    isa     => Bool,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub { $_[0]->_rset && $_[0]->_rset->security; },
);

has set_owner => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('owner'); },
);

has set_author => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('author'); },
);

has set_approver => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('approver'); },
    coerce  => sub { $_[0] || undef }, # Allow empty strings from form
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
            if ($self->priority xor $value) || $self->priority != $value;
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
    return 1 if $user->{permission}->{issue_read_all};
    return 1 if ($user->{permission}->{issue_read} || $user->{permission}->{issue_read_project}) && !$self->id; # New issue
    return 1 if $user->{permission}->{issue_read_project} && $self->users->user($user->{id})->has_project($self->project->id);
    return 1 if $user->{permission}->{issue_read} &&
        ($self->owner == $user->{id} || $self->author == $user->{id} || $self->approver == $user->{id});
}

sub user_can_write
{   my ($self, $user) = @_;
    return 1 if $user->{permission}->{issue_write_all};
    return 1 if ($user->{permission}->{issue_write} || $user->{permission}->{issue_write_project}) && !$self->id; # New issue
    return 1 if $user->{permission}->{issue_write_project} && $self->users->user($user->{id})->has_project($self->project->id);
    return 1 if $user->{permission}->{issue_write} &&
        ($self->owner == $user->{id} || $self->author == $user->{id} || $self->approver == $user->{id});
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

sub set_type
{   my ($self, $id) = @_;
    $id ||= undef; # Allow empty string from form
    $self->_set_type($id && Brass::Issue::Type->new(id => $id, schema => $self->schema));
}

sub set_project
{   my ($self, $id) = @_;
    $self->_set_project(Brass::Issue::Project->new(id => $id, schema => $self->schema));
}

sub _build_comments
{   my $self = shift;
    my $comments_rs = $self->schema->resultset('Comment')->search({
        issue => $self->id,
    });
    $comments_rs->result_class('Brass::Issue::Comment');
    my @all = $comments_rs->all;
    $_->users($self->users) foreach @all;
    \@all;
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
    if ($self->author == $options{logged_in_user_id})
    {
        # Author editing. Send to admin
        my $msg = Mail::Message->build(
            To             => 'root',
            'Content-Type' => 'text/plain',
            Subject        => 'Ticket updated',
            data           => <<__PLAIN,
A ticket that you are the author of has been updated:

$options{uri_base}/issue/$id
__PLAIN
        )->send(via => 'sendmail');
    }
    else {
        # Otherwise update original author
        my $msg = Mail::Message->build(
            To             => $self->author->email,
            'Content-Type' => 'text/plain',
            Subject        => 'Ticket updated',
            data           => <<__PLAIN,
A ticket has been updated:

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
        id              => $data->{id},
        title           => $data->{title},
        description     => $data->{description},
        completion_time => $data->{completion_time},
        reference       => $data->{reference},
        security        => $data->{security},
        set_type        => $data->{type},
        set_owner       => $data->{owner},
        set_author      => $data->{author},
        set_approver    => $data->{approver},
        priority        => $priority,
        status          => $status,
        project         => $project,
        schema          => $schema,
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
        title           => $self->title,
        description     => $self->description,
        completion_time => $self->completion_time,
        reference       => $self->reference,
        security        => $self->security,
        type            => ($self->type && $self->type->id),
        project         => $self->project->id,
        owner           => $self->set_owner,
        author          => $self->set_author,
        approver        => $self->set_approver,
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

