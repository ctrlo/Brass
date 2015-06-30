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

package Brass::Config::Server::Cert;

use Brass::Config::Cert;
use Brass::Config::CertUse;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

has schema => (
    is       => 'ro',
    required => 1,
);

has id => (
    is  => 'rwp',
    isa => Maybe[Int],
);

has _rset => (
    is      => 'lazy',
    clearer => 1,
);

has server_id => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->server_id; },
);

has cert => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->content; },
);

has set_cert_id => (
    is  => 'rw',
    isa => Int,
    trigger => sub {
        my ($self, $value) = @_;
        my $cert = Brass::Config::Cert->new(
            id     => $value,
            schema => $self->schema,
        );
        $self->_set_cert($cert);
    }
);

has use => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->cn; },
);

has set_use_id => (
    is  => 'rw',
    isa => Int,
    trigger => sub {
        my ($self, $value) = @_;
        my $use = Brass::Config::CertUse->new(
            id     => $value,
            schema => $self->schema,
        );
        $self->_set_use($use);
    }
);

sub _build__rset
{   my $self = shift;
    $self->schema->resultset('ServerCert')->find($self->id);
}

sub write
{   my $self = shift;
    my $values = {
        cert_id   => $self->cert->id,
        use       => $self->use->id,
        server_id => $self->server_id
    };
    if ($self->_rset)
    {
        $self->_rset->update($values);
    }
    else {
        my $rset = $self->schema->resultset('ServerCert')->create($values);
        $self->_set_id($rset->id);
        $self->_clear_rset;
    };
}

sub delete
{   my $self = shift;
    $self->_rset->delete;
}

sub inflate_result {
    my $server_cert = $_[2];
    my $schema = $_[1]->schema;
    my $prefetch = $_[3];
    
    my $cert = $prefetch->{cert} ? Brass::Config::Cert->inflate_result($_[1], $prefetch->{cert}->[0]) : undef;
    my $use  = $prefetch->{use} ? Brass::Config::CertUse->inflate_result($_[1], $prefetch->{use}->[0]) : undef;

    $_[0]->new(
        id          => $server_cert->{id},
        cert        => $cert,
        use         => $use,
        schema      => $schema,
    );
}

1;

