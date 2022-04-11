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
use Getopt::Long;
use Term::ReadKey;

my ($server, $type, $action, $param, $use, %update, $namespace);
GetOptions (
    'server=s'    => \$server,
    'namespace=s' => \$namespace,
    'type=s'      => \$type,
    'action=s'    => \$action,
    'param=s'     => \$param,
    'use=s'       => \$use,
    'update=s'    => \%update,
) or exit;

my $sshpass = $ENV{SSHPASS};
if (!$sshpass)
{
    # Get passphrase of user's SSH key, do not echo
    ReadMode ('noecho');
    print "Please enter the passphrase:\n";
    $sshpass = <STDIN>;
    chomp $sshpass;
    $ENV{SSHPASS} = $sshpass;
    ReadMode ('normal');
}

my $cdb = Brass::ConfigDB->new;

my $ret = $cdb->run(
    server    => $server,
    namespace => $namespace,
    type      => $type,
    action    => $action,
    param     => $param,
    use       => $use,
    update    => \%update,
    sshpass   => $sshpass,
);

print "$ret\n";
