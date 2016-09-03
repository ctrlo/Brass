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

package Brass::Config::Server;

use Brass::Config::Domain;
use DateTime;
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

has update_datetime => (
    is      => 'ro',
    isa     => Maybe[DateAndTime],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->update_datetime; },
);

has update_result => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->update_result; },
);

has restart_required => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->restart_required; },
);

has os_version => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->os_version; },
);

has backup_verify => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->backup_verify; },
);

has notes => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->notes; },
);

has sites => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_rset or return [];
        my @sites = map { $_->name } $self->_rset->sites;
        \@sites;
    },
);

has set_sites => (
    is  => 'rw',
    isa => Str,
);

has domain => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $domain = $self->_rset && $self->_rset->domain
            or return;
        Brass::Config::Domain->new(
            id          => $domain->id,
            name        => $domain->name,
            schema      => $self->schema,
        );
    },
);

has types => (
    is      => 'rwp',
    isa     => HashRef,
    lazy    => 1,
    builder => 1,
);

sub set_types
{   my ($self, $new) = @_;
    $new = ref $new ? $new : [$new || ()];
    my %new = map { $_ => 1 } @$new;
    my @all = @{Brass::Config::Server::Types->new(schema => $self->schema)->all};
    @all = grep { exists $new{$_->id} } @all;
    my %types = map { $_->id => $_->name } @all;
    $self->_set_types(\%types);
}

has certs => (
    is      => 'rwp',
    isa     => HashRef,
    lazy    => 1,
    builder => 1,
);

sub _build_types
{   my $self = shift;
    my @types = $self->schema->resultset('ServerServertype')->search({
        server_id => $self->id,
    },{
        prefetch => 'servertype',
    })->all;
    my %types = map { $_->servertype->id => $_->servertype->name } @types;
    \%types;
}

sub _build_certs
{   my $self = shift;
    my $cert_rs = $self->schema->resultset('ServerCert')->search({
        server_id => $self->id,
    },{
        prefetch => ['cert', 'use'],
    });
    $cert_rs->result_class('Brass::Config::Server::Cert');
    my %all = map { $_->id => $_ } $cert_rs->all;
    \%all;
}

sub set_domain
{   my ($self, $id) = @_;
    $self->_set_domain(Brass::Config::Domain->new(id => $id, schema => $self->schema));
}

sub inflate_result {
    my $data   = $_[2];
    my $schema = $_[1]->schema;
    $_[0]->new(
        id             => $data->{id},
        name           => $data->{name},
        set_domain     => $data->{domain_id},
        schema         => $schema,
    );
}

sub _build__rset
{   my $self = shift;
    my ($server) = $self->schema->resultset('Server')->search({
        'me.id' => $self->id,
    })->all;
    $server;
}

sub write
{   my ($self, $user_id) = @_;
    my $guard = $self->schema->txn_scope_guard;
    my $values = {
        name        => $self->name,
        domain_id   => $self->domain->id,
        notes       => $self->notes,
    };
    if ($self->id)
    {
        $self->_rset->update($values);
    }
    else {
        $self->_set__rset($self->schema->resultset('Server')->create($values));
        $self->_set_id($self->_rset->id);
    }
    # Update all the server types.
    $self->schema->resultset('ServerServertype')->search({
        server_id => $self->id,
    })->delete;
    foreach my $t (keys %{$self->types})
    {
        $self->schema->resultset('ServerServertype')->create({
            server_id => $self->id,
            type_id   => $t,
        });
    }
    # Update all the sites
    $self->schema->resultset('Site')->search({
        server_id => $self->id,
    })->delete;
    foreach my $site (split "\n", $self->set_sites)
    {
        $self->schema->resultset('Site')->create({
            server_id => $self->id,
            name      => $site,
        });
    }
    $guard->commit;
}

sub delete
{   my $self = shift;
    my $guard = $self->schema->txn_scope_guard;
    $self->schema->resultset('ServerCert')->search({ server_id => $self->id })->delete;
    $self->schema->resultset('ServerServertype')->search({ server_id => $self->id })->delete;
    $self->schema->resultset('Pw')->search({ server_id => $self->id })->delete;
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

