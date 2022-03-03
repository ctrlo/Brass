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

use Config::IniFiles;
use Crypt::CBC;
use Crypt::JWT qw(encode_jwt);
use DateTime;
use File::HomeDir;
use Getopt::Long;
use JSON qw(decode_json encode_json);
use LWP::UserAgent;
use String::Random;
use Term::ReadKey;
use URI;
use URI::QueryParam;

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

my $sshfile = File::HomeDir->my_home."/.ssh/id_ecdsa";

my $sshpass = $ENV{SSHPASS};
if (!$sshpass)
{
    # Get passphrase of user's SSH key, do not echo
    ReadMode ('noecho');
    print "Please enter the passphrase for $sshfile:\n";
    $sshpass = <STDIN>;
    chomp $sshpass;
    $ENV{SSHPASS} = $sshpass;
    ReadMode ('normal');
}

# Use this to generate required SSH key format
# ssh-keygen -t ecdsa -b 521 -m pem
my $sshkey = Crypt::PK::ECC->new($sshfile, $sshpass);

$type or die "Please provide type of request with --type";
$action or die "Please specify action with --action";

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
    if ($action =~ /^(summary|domain|is_production|sshkeys|sudo)$/)
    {
    }
    elsif ($action eq 'update')
    {
        $server or die "Please specify server with --server";
        %update or die "Please specify --update option when using update";
        $update{result} or die "Please specify result with --update option";
        $update{restart_required} or die "Please specify restart_required with --update option";
        $update{os_version} or die "Please specify os_version with --update option";
        defined $update{backup_verify} or die "Please specify backup_verify with --update option";
        $data = encode_json {
            update_datetime  => DateTime->now->epoch,
            update_result    => $update{result},
            restart_required => $update{restart_required},
            os_version       => $update{os_version},
            backup_verify    => $update{backup_verify},
        };
    }
    else {
        die "Unknown action $action";
    }
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
die $decoded->{message} if $decoded->{is_error};
print $decoded->{result};

sub randompw()
{   my $foo = new String::Random;
    $foo->{'A'} = [ 'A'..'Z', 'a'..'z', '0'..'9' ];
    scalar $foo->randpattern("AAAAAAAAAAAAAAAA");
}

