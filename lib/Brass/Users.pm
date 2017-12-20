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

package Brass::Users;

use Brass::User;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has _index => (
    is => 'lazy',
);

has _all => (
    is => 'lazy',
);

sub _build__all
{   my $self = shift;
    my $users_rs = $self->schema->resultset('User')->search({}, {
        order_by => ['me.surname', 'me.firstname'],
    });
    $users_rs->result_class('Brass::User');
    [ $users_rs->all ];
}

sub all
{   my ($self, %options) = @_;
    my @all = @{$self->_all};
    @all = grep { !$_->deleted } @all
        unless $options{include_deleted};
    @all = grep { $_->has_role($options{role}) } @all
        if $options{role};
    \@all;
}

sub _build__index
{   my $self = shift;
    my %index = map { $_->id => $_ } @{$self->_all};
    \%index;
}

sub user
{   my ($self, $id) = @_;
    my $index = $self->_index;
    $index->{$id};
}

1;

