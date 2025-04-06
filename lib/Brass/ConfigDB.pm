=pod
Copyright (C) 2013 A Beverley

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

package Brass::ConfigDB;

use Brass::Actions;
use Brass::Schema;
use Config::IniFiles;
use Crypt::CBC;
use Crypt::JWT qw(encode_jwt);
use DateTime;
use File::HomeDir;
use JSON qw(decode_json encode_json);
use Log::Report;
use LWP::UserAgent;
use Moo;
use CtrlO::Crypt::XkcdPassword;
use URI;
use URI::QueryParam;
use YAML qw/LoadFile/;

has is_local => (
    is => 'lazy',
);

sub _build_is_local
{   my $self = shift;
    -d '/srv/Brass';
}

has schema => (
    is => 'lazy',
);

sub _build_schema
{   my $self = shift;
    panic "Schema needs to be defined"
        if ! $self->is_local;
    my $config_file = '/srv/Brass/config.yml';
    -f $config_file
        or error __x"Unable to find config file {file}", file => $config_file;
    my $config = LoadFile $config_file;
    my $db_config = $config->{plugins}->{DBIC}->{default};
    my @connect = ($db_config->{dsn}, $db_config->{user}, $db_config->{password}, $db_config->{options});
    Brass::Schema->connect(@connect);
}

sub run
{   my ($self, %params) = @_;

    return $self->_run_local(%params)
        if $self->is_local;

    $self->_run_remote(%params);
}

sub _run_local
{   my ($self, %params) = @_;

    my $type = delete $params{type}
        or error __"Please provide type of request with --type";

    if ($type eq 'pwd')
    {
        $self->run_pwd(%params);
    }
    elsif ($type eq 'cert')
    {
        $self->run_cert(%params);
    }
    elsif ($type eq 'server')
    {
        $self->run_server(%params);
    }
    elsif ($type eq 'site')
    {
        $self->run_site(%params);
    }
    else {
        error __x"Unknown type: {type}", type => $type;
    }
}

sub _run_remote
{   my ($self, %params) = @_;

    my $server    = $params{server};
    my $namespace = $params{namespace} || $ENV{CDB_NAMESPACE};
    my $type      = $params{type};
    my $action    = $params{action};
    my $param     = $params{param};
    my $pass      = $params{pass};
    my $use       = $params{use};
    my $update    = $params{update};
    my $sshpass   = $params{sshpass} || $ENV{SSHPASS};

    # configdb config
    my $cfile     = File::HomeDir->my_home . "/.configdb";
    my $cfg       = Config::IniFiles->new( -file => $cfile );
    my @sections  = $cfg->Sections;
    my %options;
    $namespace ||= $sections[0];
    my $passphrase = $cfg->val($namespace, 'passphrase');
    my $host       = $cfg->val($namespace, 'dbhost');
    my $email      = $cfg->val($namespace, 'email')
        or die "Email config parameter missing";

    error __"smtp parameter type has been replaced by site type"
        if $type eq 'smtp';

    $type or error __"Please provide type of request with --type";
    $action or error __"Please specify action with --action";

    my $sshfile = File::HomeDir->my_home."/.ssh/id_ecdsa";
    # Use this to generate required SSH key format
    # ssh-keygen -t ecdsa -b 521 -m pem
    # Use this to convert existing SSH key to PEM:
    # ssh-keygen -p -f path/to/your/key -m pem
    my $sshkey = Crypt::PK::ECC->new($sshfile, $sshpass);

    my $jws_token = encode_jwt(
        payload => {
            passphrase => $passphrase,
        },
        alg => 'ES256',
        key => $sshkey,
        extra_headers => {
            kid => $email,
        }
    );

    my $ua = LWP::UserAgent->new;
    $ua->default_header(Authorization => "Bearer $jws_token");

    my $url = URI->new("https://$host");
    my @path = ('', 'api');
    my @query; my $data;

    if ($type eq 'pwd')
    {
        push @path, 'pwd';
        push @query, (server => $server, action => $action, param => $param);
        push(@query, pass => $pass) if ($pass);
    }
    elsif ($type eq 'cert')
    {
        # configdb.pl --type cert --server gads.ctrlo.com --param postfix

        push @path, 'cert';
        push @query, (server => $server, action => $action, param => $param);
    }
    elsif ($type eq 'server')
    {
        push @path, 'server';
        push @query, (server => $server, action => $action, param => $param);
        if ($action =~ /^(summary|domain|is_production|sshkeys|sudo|metadata|metasearch)$/)
        {
        }
        elsif ($action eq 'update')
        {
            $server or die "Please specify server with --server";
            $update or die "Please specify --update option when using update";
            $update->{update_result} or die "Please specify update_result with --update option";
            $update->{restart_required} or die "Please specify restart_required with --update option";
            $update->{os_version} or die "Please specify os_version with --update option";
            defined $update->{backup_verify} or die "Please specify backup_verify with --update option";
            $data = encode_json {
                update_result    => $update->{update_result},
                restart_required => $update->{restart_required},
                os_version       => $update->{os_version},
                backup_verify    => $update->{backup_verify},
            };
        }
        else {
            die "Unknown action $action";
        }
    }
    elsif ($type eq 'site')
    {
        push @path, 'site';
        push @query, (action => $action);
    }
    else
    {
        die "Invalid request $type: should be pwd, server or cert";
    }

    $url->path_segments(@path, '');
    while (@query)
    {
        $url->query_param(shift @query, shift @query);
    }
    my %content;
    %content = (
        'Content-type' => 'application/json',
        Content        => $data,
    ) if $data;
    my $response = $ua->get($url, %content);

    my $decoded = decode_json $response->decoded_content;
    error $decoded->{message} if $decoded->{is_error};
    if ($action eq 'metadata' || $action eq 'summary') # double-encoded
    {
        return undef if !$decoded->{result}; # No metadata
        return decode_json $decoded->{result};
    }
    else {
        return $decoded->{result};
    }
}

sub run_pwd
{   my ($self, %params) = @_;

    my $server = $params{server}
        or error __"Please specify server";

    my $action = $params{action}
        or error __"Need required action";

    Brass::Actions::is_allowed_action($action)
        or error __x"Invalid action: {action}", action => $action;

    my $param = $params{param};

    !Brass::Actions::action_requires_pwd($action) || $param
        or error __x"Please specify required username for {action} password",
            action => $action;

    my $pwdpass = $params{pwdpass}
        or error __"Please provide the password encryption passphrase";

    my ($username) = $self->schema->resultset('Pw')->search({
        'server.name' => $server,
        'me.username' => $param,
        'me.type'     => $action,
    },{
        join => 'server',
    });

    my $cipher = Crypt::CBC->new(
        -key    => $pwdpass,
        -cipher => 'Blowfish'
    );

    my $pass = $params{pass};
    if (defined $pass) {
      # check password is strong
      my $pwcheck = Data::Password::Check->check({
                                                  password => $pass,
                                                  tests => [qw(length silly repeated)]
                                                 });
      if ($pwcheck->has_errors) {
        error __"Please use a secure password, provided password is not secure : " .
          join(',', @{ $pwcheck->error_list });
      }
    }
    if ($username) {
      # update password if new one provided
      if ($pass) {
        my $pw = $cipher->encrypt($pass);
        $username->pwencrypt($pw);
        $username->update();
      }
      else {
        $pass = $cipher->decrypt($username->pwencrypt);
      }
    }
    else {
      $pass //= randompw();
      my $pw = $cipher->encrypt($pass);
      my $s = $self->schema->resultset('Server')->find_or_create({ name => $server });
      my $u = $self->schema->resultset('Pw')->create({ server_id => $s->id, username => $param, pwencrypt => $pw, type => $action });
      $pass = $cipher->decrypt($u->pwencrypt);
    }

    return $pass;
}

sub run_cert
{   my ($self, %params) = @_;

    my $server = $params{server};
    my $param  = $params{param};
    my $action = $params{action}
        or error __"Need required action";

    my $return;

    if ($action eq 'summary')
    {
        $server or error __"Please specify server";
        $param or error __"Please specify certificate use";

        my @certs;
        my @uses = $self->schema->resultset('ServerCert')->search({
            'server.name' => $server,
            'use.name'    => $param,
        },{
            join => ['use', 'server'],
        })->all;

        error __x"Certificate use {use} not found for server {name}",
            use => $param, name => $server
                if !@uses;

        foreach my $use (@uses)
        {
            my $cert = $self->schema->resultset('Cert')->search({
                'me.id'                     => $use->cert_id,
                'cert_location_uses.use_id' => $use->get_column('use'),
            },{
                prefetch => {
                    cert_locations => 'cert_location_uses',
                },
            });

            error __x"More than one location configured for use \"{use}\" of certificate {id}",
                use => $use->use->name, id => $use->cert_id
                    if $cert->count > 1;

            error __x"Location information not configured for use \"{use}\" of certificate {id}",
                use => $use->use->name, id => $use->cert_id
                    if !$cert->count;

            push @certs, $cert->next->as_hash_single;
        }

        return \@certs;
    }
    elsif ($action eq 'servers')
    {
        $param or error __"Please specify certificate ID";

        my $cert = $self->schema->resultset('Cert')->find($param)
            or error __x"Certificate ID {id} not found", id => $param;

        my @servers = $self->schema->resultset('Server')->search({
            'cert.id' => $param,
        },{
            prefetch => {
                server_certs => 'cert' ,
            },
        })->all;

        return $cert->as_hash_multiple;
    }
    else {
        error __x"Unknown action {action}", action => $action;
    }
}

sub run_server
{   my ($self, %params) = @_;

    my $schema = $self->schema;
    my $server = $params{server};
    my $param  = $params{param};
    my $action = $params{action}
        or error __"Need required action";

    if ($action eq 'summary')
    {
        my $rs = $schema->resultset('Servertype')->search({},{
            prefetch => { server_servertypes => 'server' },
        });

        $rs = $rs->search({ 'me.name' => $param })
            if $param;

        my @types = $rs->all;

        my %return;
        foreach my $type (@types)
        {
            next unless $type->server_servertypes->count;
            $return{$type->name} ||= [];
            foreach my $server ($type->server_servertypes)
            {
                push @{$return{$type->name}}, $server->server->name;
            }
        }
        return \%return;
    }
    elsif ($action eq 'metasearch')
    {
        $param =~ /^.+=.*$/
            or error "Supply search with --param=key=value";
        my ($key, $value) = split /=/, $param;
        my @servers;
        foreach my $server ($schema->resultset('Server')->all)
        {
            $server->metadata or next;
            my $meta = decode_json $server->metadata;
            push @servers, $server->name
                if $meta->{$key} && $meta->{$key} eq $value;
        }
        return \@servers;
    }
    elsif ($action eq 'domain')
    {
        $server or error __"Please specify server";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        return $serv->domain->name;
    }
    elsif ($action eq 'is_production')
    {
        $server or error __"Please specify server";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        return $serv->is_production;
    }
    elsif ($action eq 'metadata')
    {
        $server or error __"Please specify server";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        return $serv->metadata || '{}';
    }
    elsif ($action eq 'sshkeys')
    {
        $server or error __"Please specify server";
        my $server_rs = $schema->resultset('Server')->by_name($server)
            or error __"Server not found";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name'                      => $server,
            'user.deleted'                 => undef,
            # Restrict keys to either ones without a servertype restriction, or
            # ones that match the servertype of this server
            'pw_servertypes.servertype_id' => [undef, map { $_->servertype_id } $server_rs->server_servertypes],
        },{
            prefetch => {
                server_servertypes => {
                    servertype => {
                        user_servertypes => {
                            user => {
                                pws => 'pw_servertypes',
                            },
                        },
                    },
                },
            },
        });
        my %keys;
        foreach my $st ($serv->server_servertypes)
        {
            foreach my $ust ($st->servertype->user_servertypes)
            {
                foreach my $pw ($ust->user->pws)
                {
                    my $key = $pw->publickey or next;
                    $key =~ s/\s+$//; # May or may not have trailing space
                    $keys{$key} = 1 if $key;
                }
            }
        }
        return join("\n", keys %keys);
    }
    elsif ($action eq 'sudo')
    {
        $server or error __"Please specify server";
        my $serv = $schema->resultset('Server')->search({
            'me.name' => $server,
        })->next
            or error __x"Server {server} not found", server => $server;
        return $serv->sudo;
    }
    elsif ($action eq 'update')
    {
        $server or error "Please specify server";
        my $decoded = $params{update}
            or panic "Update data missing";

        my %update;
        $update{update_result} = $decoded->{update_result}
            or error __"Please specify update result";
        $update{restart_required} = $decoded->{restart_required}
            or error __"Please specify update restart_required";
        $update{os_version} = $decoded->{os_version}
            or error __"Please specify update os_version";
        $update{backup_verify} = $decoded->{backup_verify};
        defined $update{backup_verify}
            or error __"Please specify update backup_verify";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name' => $server,
        });
        $serv->update({
            update_datetime  => DateTime->now,
            update_result    => $update{update_result},
            restart_required => $update{restart_required},
            os_version       => $update{os_version},
            backup_verify    => $update{backup_verify},
        });
        return 1;
    }
    else {
        die "Unknown action $action";
    }
}

sub run_site
{   my ($self, %params) = @_;

    my $schema = $self->schema;
    my $action = $params{action}
        or error __"Need required action";

    my $config = $schema->resultset('Config')->next
        or error __x"Configuration information not defined. Please define in Brass in the Config => Site menu";

    if ($action eq 'smtp')
    {
        return [$config->smtp_relayhost];
    }
    elsif ($action eq 'internal_networks')
    {
        return [$config->internal_networks_all];
    }
    elsif ($action eq 'wazuh_manager')
    {
        return [$config->wazuh_manager];
    }
    else {
        error __x"Unknown action {action}", action => $action;
    }
}

sub randompw()
{   my $pwgen = CtrlO::Crypt::XkcdPassword->new;
    $pwgen->xkcd( words => 3, digits => 2 );
}

1;

