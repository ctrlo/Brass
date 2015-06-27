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

package Brass::User;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

has id => (
    is  => 'rwp',
    isa => Int,
);

has _rset => (
    is => 'lazy',
);

has email => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->email },
);

has surname => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->surname },
);

has firstname => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->firstname },
);

sub _build__rset
{   my $self = shift;
    $self->schema->resultset('User')->find($self->id);
}

sub has_project
{   my ($self, $project_id) = @_;
    $self->schema->resultset('UserProject')->search({
        project => $project_id,
        user    => $self->id,
    })->count;
}

sub inflate_result {
    my $data   = $_[2];
    my $schema = $_[1]->schema;
    $_[0]->new(
        id             => $data->{id},
        email          => $data->{title},
        surname        => $data->{surname},
        firstname      => $data->{firstname},
        schema         => $schema,
    );
}

sub as_string
{   my $self = shift;
    $self->surname.", ".$self->firstname;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

1;

