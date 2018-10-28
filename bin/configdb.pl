#!/usr/bin/perl

use strict;
use warnings;

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

use FindBin;
use lib "$FindBin::Bin/../lib";

use Brass::ConfigDB;
use Crypt::CBC;
use DateTime;
use String::Random;
use Getopt::Long;
use JSON qw/encode_json/;

sub randompw();

my ($server, $type, $action, $param, $use, %update);
my $namespace = $ENV{CDB_NAMESPACE};
GetOptions (
    'server=s'    => \$server,
    'namespace=s' => \$namespace,
    'type=s'      => \$type,
    'action=s'    => \$action,
    'param=s'     => \$param,
    'use=s'       => \$use,
    'update=s'    => \%update,
) or exit;

my $db = Brass::ConfigDB->new(namespace => $namespace);
my $sch = $db->sch;

$type or die "Please provide type of request with --type";
$action or die "Please specify action with --action";

if ($type eq 'pwd')
{

    my $passphrase = $ENV{CDB_PASSPHRASE}
        or die "Need CDB_PASSPHRASE to be set for retrieving and setting passwords";

    $server or die "Please specify server with --server";

    $action eq 'sqldb' || $action eq 'admonitor'
        or die "Invalid action: $action";

    $action eq 'sqldb' && !$param
        and die "Please specify required username with --param for SQL password";

    my ($username) = $sch->resultset('Pw')->search({
        'server.name' => $server,
        'me.username'     => $param,
    },{
        join => 'server',
    });

    my $cipher = Crypt::CBC->new(
        -key => $passphrase,
        -cipher => 'Blowfish'
    );

    if ($username)
    {
        print $cipher->decrypt($username->pwencrypt);
        exit;
    }

    my $pw = $cipher->encrypt(randompw);

    my $s = $sch->resultset('Server')->find_or_create({ name => $server });
    my $u = $sch->resultset('Pw')->create({ server_id => $s->id, username => $param, pwencrypt => $pw, type => $action });
    print $cipher->decrypt($u->pwencrypt);
}
elsif ($type eq 'cert')
{
    # configdb.pl --type cert --server gads.ctrlo.com --param postfix

    if ($action eq 'summary')
    {
        $server or die "Please specify server with --server";
        $param or die "Please specify certificate use with --param";

        my @certs = $sch->resultset('ServerCert')->search({
            'server.name' => $server,
            'use.name'     => $param,
        },{
            join     => ['server', 'use'],
            prefetch => 'cert',
        })->all;

        my %output;
        foreach my $cert (@certs)
        {
            my $filename = $cert->cert->filename;
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
        my @output = values %output;
        print encode_json \@output;
    }
    elsif ($action eq 'servers')
    {
        $param or die "Please specify certificate ID with --param";
        my @servers = $sch->resultset('Server')->search({
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
        my $output = {
            filename => $cert->filename,
            content  => $content,
            type     => $cert->type,
            servers  => \@server_names,
        };
        print encode_json $output;
    }
    else {
        die "Unknown action $action";
    }
}
elsif ($type eq 'server')
{
    if ($action eq 'summary')
    {
        my @types = $sch->resultset('Servertype')->search({},{
            prefetch => { server_servertypes => 'server' },
        })->all;

        foreach my $type (@types)
        {
            next unless $type->server_servertypes->count;
            print $type->name.":";
            my @servers;
            foreach my $server ($type->server_servertypes)
            {
                push @servers, $server->server->name;
            }
            print join ',', @servers;
            print "\n";
        }
    }
    elsif ($action eq 'domain')
    {
        $server or die "Please specify server with --server";
        my ($serv) = $sch->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        print $serv->domain->name;
    }
    elsif ($action eq 'is_production')
    {
        $server or die "Please specify server with --server";
        my ($serv) = $sch->resultset('Server')->search({
            'me.name' => $server,
        },{
            prefetch => 'domain',
        });
        print $serv->is_production;
    }
    elsif ($action eq 'sudo')
    {
        $server or die "Please specify server with --server";
        my ($serv) = $sch->resultset('Server')->search({
            'me.name' => $server,
        });
        print $serv->sudo if $serv->sudo;
    }
    elsif ($action eq 'update')
    {
        $server or die "Please specify server with --server";
        %update or die "Please specify --update option when using update";
        $update{result} or die "Please specify result with --update option";
        $update{restart_required} or die "Please specify restart_required with --update option";
        $update{os_version} or die "Please specify os_version with --update option";
        defined $update{backup_verify} or die "Please specify backup_verify with --update option";
        my ($serv) = $sch->resultset('Server')->search({
            'me.name' => $server,
        });
        $serv->update({
            update_datetime  => DateTime->now,
            update_result    => $update{result},
            restart_required => $update{restart_required},
            os_version       => $update{os_version},
            backup_verify    => $update{backup_verify},
        });
    }
    else {
        die "Unknown action $action";
    }
}
else
{
    die "Invalid request $type: should be pwd, server or cert";
}

sub randompw()
{   my $foo = new String::Random;
    $foo->{'A'} = [ 'A'..'Z', 'a'..'z', '0'..'9' ];
    scalar $foo->randpattern("AAAAAAAAAAAAAAAA");
}

