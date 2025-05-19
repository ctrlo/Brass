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

package Brass::Issue::Status;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

has id => (
    is  => 'rwp',
    isa => Maybe[Int],
);

has _rset => (
    is => 'lazy',
);

has name => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->name; },
);

has user => (
    is => 'rw',
);

has datetime => (
    is  => 'rw',
    isa => Maybe[DateAndTime],
);

sub is_approved
{   my $self = shift;
    my $identifier = $self->_rset->identifier
        or return;
    $identifier eq 'approved';
}

sub _build__rset
{   my $self = shift;
    $self->schema->resultset('Status')->find($self->id);
}

sub as_string
{   my $self = shift;
    $self->name;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

sub inflate_result {
    my $data = $_[2];
    $_[0]->new(
        id          => $data->{id},
        name        => $data->{name},
        schema      => $_[1]->schema,
    );
}

1;

