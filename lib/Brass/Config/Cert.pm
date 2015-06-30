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

package Brass::Config::Cert;

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

has content => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->content; },
);

has cn => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->cn; },
);

has type => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->type; },
);

has expiry => (
    is      => 'rw',
    isa     => Maybe[DateAndTime],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->expiry; },
);

has usedby => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->usedby; },
);

has filename => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->filename; },
);

sub _build__rset
{   my $self = shift;
    $self->schema->resultset('Cert')->find($self->id);
}

sub as_string
{   my $self = shift;
    $self->cn;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

sub inflate_result {
    my $data = $_[2];
    my $schema = $_[1]->schema;
    my $db_parser = $schema->storage->datetime_parser;
    my $expiry = $data->{expiry} ? $db_parser->parse_date($data->{expiry}) : undef;
    $_[0]->new(
        id          => $data->{id},
        content     => $data->{content},
        cn          => $data->{cn},
        type        => $data->{type},
        expiry      => $expiry,
        usedby      => $data->{usedby},
        filename    => $data->{filename},
        schema      => $_[1]->schema,
    );
}

1;

