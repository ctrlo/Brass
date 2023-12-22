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

package Brass::Issues;

use Brass::Issue;
use DateTime;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has users => (
    is       => 'ro',
    required => 1,
);

has all => (
    is => 'lazy',
);

has filtering => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
    coerce  => sub {
        my $in = shift;
        my $return = {};

        if (my $sec = $in->{security})
        {
            # Legacy security
            $return->{'me.security'} = 1
                if $sec eq 'yes';
            $return->{'me.security'} = 0
                if $sec eq 'no';

            # Updated security
            $return->{'type.is_breach'} = 1
                if $sec eq 'security_incident';
            $return->{'type.is_breach'} = 1
                if $sec eq 'corrective_action';
            $return->{'type.is_vulnerability'} = 1
                if $sec eq 'vulnerability';
            $return->{'type.identifier'} = 'patch'
                if $sec eq 'patch';
            $return->{'type.identifier'} = 'code_review'
                if $sec eq 'code_review';
            $return->{'type.identifier'} = 'pentest'
                if $sec eq 'pentest';
            $return->{'type.identifier'} = ['capacity_change', 'capacity_fail']
                if $sec eq 'capacity';
            $return->{'type.is_audit'} = 1
                if $sec eq 'audit';
        }

        # Other
        $return->{'me.project'} = $in->{project}
            if $in->{project};
        $return->{'issue_statuses.status'} = $in->{status}
            if $in->{status};
        $return->{'issue_priorities.priority'} = $in->{priority}
            if $in->{priority};
        $return->{'me.type'} = $in->{type}
            if $in->{type};
        $return->{'issue_tags.tag'} = $in->{tag}
            if $in->{tag};
        $return->{'-or'} = {
            owner    => $in->{user_id},
            author   => $in->{user_id},
            approver => $in->{user_id},
        } if $in->{user_id};
        $return->{'owner'} = $in->{owner}
            if $in->{owner};
        $return->{'user_projects.user'} = $in->{project_user_id}
            if $in->{project_user_id};
        $return;
    },
);

has sort => (
    is => 'rw',
);

sub _build_all
{   my $self = shift;
    my $search = $self->filtering;
    $search->{'issuestatus_later.datetime'} = undef;
    $search->{'issuepriority_later.datetime'} = undef;
    my $sort = $self->sort && $self->sort eq 'opened'
             ? 'me.id' # Sort after build
             : $self->sort && $self->sort eq 'id'
             ? 'me.id'
             : $self->sort && $self->sort eq 'priority'
             ? 'priority.id'
             : 'me.title';
    my $issues_rs = $self->schema->resultset('Issue')->search(
        $search
    ,{
        join => [
            'type',
            'issue_tags',
            {
                project => 'user_projects',
            },
        ],
        prefetch => [
            'project',
            {
                issue_statuses => [
                    'status', 'issuestatus_later',
                ],
            },
            {
                issue_priorities => [
                    'priority', 'issuepriority_later',
                ],
            },
        ],
        order_by => $sort,
    });
    $issues_rs->result_class('Brass::Issue');
    my @all = $issues_rs->all;
    $_->users($self->users) foreach @all;
    @all = sort { DateTime->compare($a->opened, $b->opened) } @all if $self->sort && $self->sort eq 'opened';
    \@all;
}

1;

