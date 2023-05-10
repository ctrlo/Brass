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

package Brass::Config::UAD;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

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

has name => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->name; },
);

has purchased => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->purchased; },
);

has serial => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->serial; },
);

has set_owner => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('owner'); },
);

sub inflate_result {
    my $data   = $_[2];
    my $schema = $_[1]->schema;
    $_[0]->new(
        id        => $data->{id},
        name      => $data->{name},
        purchased => $data->{purchased},
        serial    => $data->{serial},
        set_owner => $data->{owner},
        schema    => $schema,
    );
}

sub _build__rset
{   my $self = shift;
    my ($uad) = $self->schema->resultset('Uad')->search({
        'me.id' => $self->id,
    })->all;
    $uad;
}

sub owner
{   my $self = shift;
    $self->users->user($self->set_owner);
}

sub write
{   my $self = shift;
    my $guard = $self->schema->txn_scope_guard;
    my $values = {
        name      => $self->name,
        purchased => $self->purchased,
        serial    => $self->serial,
        owner     => $self->set_owner,
    };
    if ($self->id)
    {
        $self->_rset->update($values);
    }
    else {
        $self->_set__rset($self->schema->resultset('Uad')->create($values));
        $self->_set_id($self->_rset->id);
    }
    $guard->commit;
}

sub delete
{   my $self = shift;
    my $guard = $self->schema->txn_scope_guard;
    $self->_rset->delete;
    $guard->commit;
}

sub as_string
{   my $self = shift;
    $self->name;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

1;

