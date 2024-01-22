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

package Brass::Issue::Type;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

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

has identifier => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->identifier; },
);

has is_vulnerability => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->is_vulnerability; },
);

has is_breach => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->is_breach; },
);

has is_audit => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->is_audit; },
);

has is_other_security => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->is_other_securityt; },
);

has is_objective => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->identifier eq 'objective'; },
);

has is_nc => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->identifier =~ /nc_major|nc_minor/; },
);

has is_general => (
    is => 'lazy',
);

sub _build_is_general
{   my $self = shift;
    ! ($self->is_vulnerability || $self->is_breach || $self->is_audit || $self->is_other_security);
}

sub _build__rset
{   my $self = shift;
    $self->schema->resultset('Issuetype')->find($self->id);
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
        id                => $data->{id},
        name              => $data->{name},
        schema            => $_[1]->schema,
        identifier        => $data->{identifier},
        is_vulnerability  => $data->{is_vulnerability},
        is_breach         => $data->{is_breach},
        is_audit          => $data->{is_audit},
        is_other_security => $data->{is_other_security},
    );
}

1;

