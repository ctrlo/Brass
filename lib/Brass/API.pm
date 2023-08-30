=pod
Brass
Copyright (C) 2021 Ctrl O Ltd

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

package Brass::API;

use strict; use warnings;

use Crypt::Blowfish;
use Crypt::CBC;
use Crypt::JWT qw(decode_jwt);
use Crypt::PK::ECC;
use Dancer2 appname => 'Brass';
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use CtrlO::Crypt::XkcdPassword;
use Data::Password::Check;

# Special error handler for JSON requests (as used in API)
fatal_handler sub {
    my ($dsl, $msg, $reason) = @_;
    return unless $dsl && $dsl->app->request && $dsl->app->request->uri =~ m!^/api/!i;
    my $is_exception = $reason eq 'PANIC';
    status $is_exception ? 'Internal Server Error' : 'Bad Request';
    $dsl->send_as(JSON => {
        is_error => \1,
        message  => $is_exception ? 'An unexexpected error has occurred' : $msg->toString },
    { content_type => 'application/json; charset=UTF-8' });
};

hook before => sub {
    (my $request_token = request->header('Authorization')) =~ s/^Bearer\s+(.*)/$1/;

    return unless request->uri =~ m!^/api/!i;

    # Apache requires following config to passthrough auth header:
    # SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1
    $request_token
        or error __"No authorization header";

    # Load all available keys
    my @keys;
    foreach my $key (schema->resultset('User')->keys->all)
    {
        my $pubkey = Crypt::PK::ECC->new(\$key->api_key);
        my $jwk_hash = $pubkey->export_key_jwk('public', 1);
        $jwk_hash->{kid} = $key->username;
        push @keys, $jwk_hash;
    }

    my $keylist = {
        keys => \@keys
    };

    my ($header, $client);
    try { ($header, $client) = decode_jwt(token => $request_token, kid_keys => $keylist, decode_header => 1) };
    if ($@)
    {
        my $err = $@->wasFatal->message->toString;
        error __x"Unable to authenticate: {err}", err => $err;
    }

    var api_user => schema->resultset('User')->keys->search({ username => $header->{kid} })->next;
    var payload  => $client;
};

sub randompw()
{   my $pwgen = CtrlO::Crypt::XkcdPassword->new;
    $pwgen->xkcd( words => 3, digits => 2 );
}

get 'api/pwd/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $schema = schema;

    my $passphrase = var('payload')->{passphrase}
        or error __"Need passphrase for retrieving and setting passwords";

    my $server = query_parameters->get('server')
        or error __"Please specify server";

    my $action = query_parameters->get('action')
        or error __"Need required action";

    $action eq 'sqldb' || $action eq 'admonitor' || $action eq 'system' || $action eq 'wazuh'
        or error __x"Invalid action: {action}", action => $action;

    my $param = query_parameters->get('param');
    $action eq 'sqldb' && !$param
        and error __"Please specify required username for SQL password";
    $action eq 'system' && !$param
        and error __"Please specify required username for system password";
    $action eq 'wazuh' && !$param
        and error __"Please specify required username for wazuh password";

    my ($username) = $schema->resultset('Pw')->search({
        'server.name' => $server,
        'me.username' => $param,
        'me.type'     => $action,
    },{
        join => 'server',
    });

    my $cipher = Crypt::CBC->new(
        -key => $passphrase,
        -cipher => 'Blowfish'
    );

    my $pass = query_parameters->get('pass');
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
      $pass //= randompw;
      my $pw = $cipher->encrypt($pass);
      my $s = $schema->resultset('Server')->find_or_create({ name => $server });
      my $u = $schema->resultset('Pw')->create({ server_id => $s->id, username => $param, pwencrypt => $pw, type => $action });
      $pass = $cipher->decrypt($u->pwencrypt);
    }
    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => $pass,
    });
};

get 'api/cert/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $schema = schema;

    my $action = query_parameters->get('action')
        or error __"Need required action";
    my $server = query_parameters->get('server');
    my $param  = query_parameters->get('param');

    my $output;
    if ($action eq 'summary')
    {
        $server or error __"Please specify server";
        $param or error __"Please specify certificate";

        my @certs = $schema->resultset('ServerCert')->search({
            'server.name' => $server,
            'use.name'    => $param,
        },{
            join     => ['server', 'use'],
            prefetch => 'cert',
        })->all;

        my %output;
        foreach my $cert (@certs)
        {
            my $full_filename = $cert->cert->filename;
            my @filenames = split /\s*,\s*/, $full_filename;
            foreach my $filename (@filenames) {
                # Add final newline if it doesn't exist
                my $content = $cert->cert->content;
                $content .= "\n" unless $content =~ /\n$/;
                if ($output{$filename})
                {
                    $output{$filename}->{content} .= $content;
                }
                else {
                    $output{$filename} = {
                        type       => $cert->cert->type,
                        filename   => $filename,
                        content    => $content,
                        file_user  => $cert->cert->file_user,
                        file_group => $cert->cert->file_group,
                    };
                }
            }
        }
        $output = [values %output];
    }
    elsif ($action eq 'servers')
    {
        $param or error __"Please specify certificate ID";
        my @servers = $schema->resultset('Server')->search({
            'cert.id' => $param,
        },{
            prefetch => {
                server_certs => 'cert' ,
            },
        })->all;

        my ($server_cert) = $servers[0]->server_certs;
        my $cert = $server_cert->cert;
        # Add final newline if it doesn't exist
        my $content = $cert->content;
        $content .= "\n" unless $content =~ /\n$/;
        my @server_names = map { $_->name } @servers;
        $output = {
            filename => $cert->filename,
            content  => $content,
            type     => $cert->type,
            servers  => \@server_names,
        };
    }
    else {
        error __x"Unknown action {action}", action => $action;
    }

    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => encode_json($output),
    });
};

get 'api/server/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $schema = schema;

    my $action = query_parameters->get('action')
        or error __"Need required action";
    my $server = query_parameters->get('server');
    my $param  = query_parameters->get('param');

    my $output = '';
    if ($action eq 'summary')
    {
        my @types = $schema->resultset('Servertype')->search({},{
            prefetch => { server_servertypes => 'server' },
        })->all;

        foreach my $type (@types)
        {
            next unless $type->server_servertypes->count;
            $output .= $type->name.":";
            my @servers;
            foreach my $server ($type->server_servertypes)
            {
                push @servers, $server->server->name;
            }
            $output .= join ',', @servers;
            $output .= "\n";
        }
    }
    elsif ($action eq 'domain')
    {
        $server or error __"Please specify server";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        $output .= $serv->domain->name;
    }
    elsif ($action eq 'is_production')
    {
        $server or error __"Please specify server";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        $output .= $serv->is_production;
    }
    elsif ($action eq 'metadata')
    {
        $server or error __"Please specify server";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        $output .= ($serv->metadata || '{}');
    }
    elsif ($action eq 'sshkeys')
    {
        $server or error __"Please specify server";
        my ($serv) = $schema->resultset('Server')->search({
            'me.name'      => $server,
            'user.deleted' => undef,
        },{
            prefetch => {
                server_servertypes => {
                    servertype => {
                        user_servertypes => {
                            user => 'pws',
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
        $output .= "$_\n" foreach keys %keys;
    }
    elsif ($action eq 'sudo')
    {
        $server or error __"Please specify server";
        my $serv = $schema->resultset('Server')->search({
            'me.name' => $server,
        })->next
            or error __x"Server {server} not found", server => $server;
        $output .= $serv->sudo if $serv->sudo;
    }
    elsif ($action eq 'update')
    {
        $server or error "Please specify server";
        my $update = 
        my $data = request->body;
        # Valid?
        my $decoded;
        try { $decoded = decode_json $data };
        error "Unable to decode request body data as JSON: $@"
            if $@;

        my %update;
        $update{update_result} = $decoded->{update_result}
            or error __"Please specify update result";
        $update{update_datetime} = $decoded->{update_datetime}
            or error __"Update datetime required";
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
            update_datetime  => DateTime->from_epoch(epoch => $update{update_datetime}),
            update_result    => $update{update_result},
            restart_required => $update{restart_required},
            os_version       => $update{os_version},
            backup_verify    => $update{backup_verify},
        });
    }
    else {
        die "Unknown action $action";
    }

    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => $output,
    });
};

