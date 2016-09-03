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

use Brass::Schema;
use Config::IniFiles;
use File::HomeDir;

sub new($%)
{   my ($class, %options) = @_;
    my $self      = bless {}, $class;
    my $cfile     = File::HomeDir->my_home . "/.configdb";
    my $cfg       = Config::IniFiles->new( -file => $cfile );
    my @sections  = $cfg->Sections;
    my $namespace = $options{namespace} || $sections[0];

    $self->{dbuser} = $cfg->val($namespace, 'username') or die "username not defined";
    $self->{dbpass} = $cfg->val($namespace, 'password') or die "password not defined";
    $self->{dbname} = $cfg->val($namespace, 'dbname')   or die "dbname not defined";
    my $dbhost      = $cfg->val($namespace, 'dbhost')   or die "dbhost not defined";
    my $certdir     = $cfg->val($namespace, 'certdir')  or die "certdir not defined";
    $self->{dbhost} = "$dbhost;mysql_ssl=1;mysql_ssl_client_key=$certdir/client-key.pem;mysql_ssl_client_cert=$certdir/client-cert.pem;mysql_ssl_ca_file=$certdir/ca-cert.pem;";
    $self;
}

sub connect()
{   my $self   = shift;
    my $dbname = $self->{dbname};

    $self->{sch} = Brass::Schema->connect(
      "dbi:mysql:database=$dbname;mysql_enable_utf8=1;host=".$self->{dbhost}, $self->{dbuser}, $self->{dbpass}
     , {RaiseError => 1, AutoCommit => 1, mysql_enable_utf8 => 1, quote_names => 1}
    ) or die "unable to connect to database {name}: {err}"
           , name => $dbname, err => $DBI::errstr;

#    $self->{sch}->storage->debug(1);

    return $self->{sch};
}

sub sch() {my $s = shift; $s->{sch} || $s->connect }


1;

