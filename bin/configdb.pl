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

use Brass::Actions ();
use Brass::ConfigDB;
use Brass::Schema;
use Getopt::Long;
use YAML qw/LoadFile/;
use Term::ReadKey;

my ($server, $type, $action, $param, $use, %update, $namespace, $pass);
GetOptions (
    'server=s'    => \$server,
    'namespace=s' => \$namespace,
    'type=s'      => \$type,
    'pass=s'      => \$pass,
    'action=s'    => \$action,
    'param=s'     => \$param,
    'use=s'       => \$use,
    'update=s'    => \%update,
) or exit;

# Stop here when loaded by a test script
return 1 if caller();

# Assume this is running on the same server as the brass database if the web
# server directory exists
my $is_local = -d '/srv/Brass';

my $sshpass = $ENV{SSHPASS};
if (!$is_local && !defined $sshpass)
{
    # Get passphrase of user's SSH key, do not echo
    my $sshpass = _get_passphrase("Please enter the passphrase of the local SSH key:");
    $ENV{SSHPASS} = $sshpass;
}

my ($pwdpass, $schema);
if ($is_local && $type eq 'pwd')
{
    # If we are running directly on the server, get passphrase to
    # ecnrypt/decrypt passwords (this is kept locally in /.configdb if
    # accessing the database remotely)
    $pwdpass = _get_passphrase("Please enter the passphrase for password encyrption and decryption:");

    # Get direct connection from database - not needed for running on remote
    # server
    my $config_file = '/srv/Brass/config.yml';
    -f $config_file
        or error __x"Unable to find config file {file}", file => $config_file;
    my $config = LoadFile $config_file;
    my $db_config = $config->{plugins}->{DBIC}->{default};
    my @connect = ($db_config->{dsn}, $db_config->{user}, $db_config->{password}, $db_config->{options});

    $schema = Brass::Schema->connect(@connect);
}

my $cdb = Brass::ConfigDB->new(is_local => $is_local, schema => $schema);

my $ret = $cdb->run(
    server    => $server,
    namespace => $namespace,
    type      => $type,
    pass      => $pass,
    action    => $action,
    param     => $param,
    use       => $use,
    update    => \%update,
    sshpass   => $sshpass,
    pwdpass   => $pwdpass,
);

print "$ret\n";

sub _get_passphrase
{   my $prompt = shift;
    ReadMode ('noecho');
    print "$prompt\n";
    $sshpass = <STDIN>;
    chomp $sshpass;
    ReadMode ('normal');
    $sshpass;
}
