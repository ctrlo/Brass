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

package Brass::Config::Pwd;

use IPC::ShellCmd;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

# All UADs. Must be populated before doing any UAD calls
has uads => (
    is => 'rw',
);

# All servers. Must be populated before doing any server calls
has all_servers => (
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

has type => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->type; },
);

has publickey => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->publickey; },
);

sub fingerprint
{   my $self = shift;
    my $pk = $self->publickey or return;
    my $isc = IPC::ShellCmd->new(['ssh-keygen','-lf','-']);
    $isc->stdin($pk);
    $isc->run;
    my $fp = $isc->stdout;
    $fp =~ /^[0-9]+ ([\S]*)( .*)?$/;
    return $1;
}

has username => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->username; },
);

has user_id => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->user_id; },
);

has set_uad => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('uad_id'); },
    coerce  => sub { $_[0] || undef }, # empty string from form
);

has set_server => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->get_column('server_id'); },
    coerce  => sub { $_[0] || undef }, # empty string from form
);

has last_changed => (
    is      => 'rw',
    isa     => Maybe[DateAndTime],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->last_changed; },
);

sub inflate_result {
    my $data   = $_[2];
    my $schema = $_[1]->schema;
    my $db_parser = $schema->storage->datetime_parser;
    my $last_changed = $data->{last_changed} ? $db_parser->parse_datetime($data->{last_changed}) : undef;
    $_[0]->new(
        id             => $data->{id},
        type           => $data->{type},
        publickey      => $data->{publickey},
        username       => $data->{username},
        user_id        => $data->{user_id},
        set_uad        => $data->{uad_id},
        set_server     => $data->{server_id},
        last_changed   => $last_changed,
        schema         => $schema,
    );
}

sub _build__rset
{   my $self = shift;
    my ($pwd) = $self->schema->resultset('Pw')->search({
        'me.id' => $self->id,
    })->all;
    $pwd;
}

sub uad
{   my $self = shift;
    return unless $self->set_uad;
    $self->uads->uad($self->set_uad);
}

sub server
{   my $self = shift;
    return unless $self->set_server;
    $self->all_servers->server($self->set_server);
}

sub write
{   my $self = shift;
    my $guard = $self->schema->txn_scope_guard;
    my $values = {
        type         => $self->type,
        publickey    => $self->publickey,
        username     => $self->username,
        user_id      => $self->user_id,
        uad_id       => $self->set_uad,
        server_id    => $self->set_server,
        last_changed => $self->last_changed,
    };
    if ($self->id)
    {
        $self->_rset->update($values);
    }
    else {
        $self->_set__rset($self->schema->resultset('Pw')->create($values));
        $self->_set_id($self->_rset->id);
    }
    # Update all the servers
    $self->schema->resultset('ServerPw')->search({
        pw_id => $self->id,
    })->delete;
    foreach my $s (keys %{$self->servers})
    {
        $self->schema->resultset('ServerPw')->create({
            pw_id     => $self->id,
            server_id => $s,
        });
    }
    $guard->commit;
}

sub delete
{   my $self = shift;
    my $guard = $self->schema->txn_scope_guard;
    $self->schema->resultset('ServerPw')->search({
        pw_id => $self->id,
    })->delete;
    $self->_rset->delete;
    $guard->commit;
}

sub as_string
{   my $self = shift;
    $self->type;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

has servers => (
    is      => 'rwp',
    isa     => HashRef,
    lazy    => 1,
    builder => 1,
);

sub set_servers
{   my ($self, $new) = @_;
    $new = ref $new ? $new : [$new || ()];
    my %new = map { $_ => 1 } @$new;
    my @all = @{Brass::Config::Servers->new(schema => $self->schema)->all};
    @all = grep { exists $new{$_->id} } @all;
    my %servers = map { $_->id => $_->name } @all;
    $self->_set_servers(\%servers);
}

sub _build_servers
{   my $self = shift;
    my @servers = $self->schema->resultset('ServerPw')->search({
        pw_id     => $self->id,
        server_id => { '!=' => undef },
    },{
        prefetch => 'server',
    })->all;
    my %servers = map { $_->server->id => $_->server->name } @servers;
    \%servers;
}

1;

