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
use Brass::Issue::Status;
use Brass::Issue::Type;
use Brass::User;
use DateTime;
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
    is => 'lazy',
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
    builder => sub { $_[0]->_rset && $_[0]->_rset->owner; },
);

has set_author => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->author; },
);

has set_approver => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->approver; },
);

has type => (
    is      => 'rwp',
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
    isa => Int,
    trigger => sub {
        my ($self, $value) = @_;
        $self->_set_status_changed(1)
            if $self->status != $value;
        my $s = Brass::Issue::Status->new(
            id          => $value,
            schema      => $self->schema,
        );
        $self->_set_status($s);
    },
);

has status_changed => (
    is  => 'rwp',
    isa => Bool,
);

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
    isa => Int,
    trigger => sub {
        my ($self, $value) = @_;
        $self->_set_priority_changed(1)
            if $self->priority != $value;
        my $s = Brass::Issue::Priority->new(
            id          => $value,
            schema      => $self->schema,
        );
        $self->_set_priority($s);
    },
);

has priority_changed => (
    is  => 'rwp',
    isa => Bool,
);

has comments => (
    is  => 'lazy',
    isa => ArrayRef,
);

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
    $self->_set_type(Brass::Issue::Type->new(id => $id, schema => $self->schema));
}

sub _build_comments
{   my $self = shift;
    my $comments_rs = $self->schema->resultset('Comment')->search({
        issue_id => $self->id,
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
        issue_id => $self->id,
        datetime => DateTime->now,
    });
}

sub inflate_result {
    my $data   = $_[2];
    my $schema = $_[1]->schema;
    $_[0]->new(
        id             => $data->{id},
        title          => $data->{title},
        description    => $data->{description},
        reference      => $data->{reference},
        set_type       => $data->{type_id},
        set_owner      => $data->{owner},
        set_author     => $data->{author},
        set_approver   => $data->{approver},
        schema         => $schema,
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
        title       => $self->title,
        description => $self->description,
        reference   => $self->reference,
        type_id     => $self->type->id,
        owner       => $self->set_owner,
        author      => $self->set_author,
        approver    => $self->set_approver,
    };
    if ($self->id)
    {
        $self->_rset->update($values);
    }
    else {
        $self->schema->resultset('Issue')->create($values);
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

