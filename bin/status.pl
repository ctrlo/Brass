#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Brass::Config::Certs;
use Brass::Config::Servers;
use Brass::Users;
use Mail::Message;
use String::Print;

use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;

my $schema = schema;

my $output .= "SSL certificate observations\n";
$output .= "============================\n";
my $certs = Brass::Config::Certs->new(schema => $schema);
my @messages;
foreach my $cert (@{$certs->all})
{
    $cert->expiry or next;
    if ($cert->expiry < DateTime->now)
    {
        push @messages, sprinti "Certificate {name} has now expired",
            name => $cert->cn;
    }
    elsif ($cert->expiry < DateTime->now->add(days => 7))
    {
        push @messages, sprinti "Certificate {name} expires in less than 7 days on {date}",
            name => $cert->cn, date => $cert->expiry->ymd;
    }
}
$output .= "$_\n" foreach @messages;
$output .= "Nothing to report\n" if !@messages;

$output .= "\n";

my $servers = Brass::Config::Servers->new(schema => $schema);

$output .= "Server backup observations:\n";
$output .= "===========================\n";
@messages = ();
foreach my $server (@{$servers->all})
{
    next unless $server->has_type('backup');
    if ($server->backup_status ne 'Identical' || !$server->backup_verify_time)
    {
        push @messages, sprinti "Server {name} most recent backup unsuccessful",
            name => $server->name;
    }
    elsif ($server->backup_verify_time < DateTime->now->subtract(days => 5))
    {
        push @messages, sprinti "Last backup verification of server {name} was {date}",
            name => $server->name, date => $server->backup_verify_time;
    }
}
$output .= "$_\n" foreach @messages;
$output .= "Nothing to report\n" if !@messages;

my $users = Brass::Users->new(schema => $schema);

foreach my $user (@{$users->all(role => 'config')})
{
    my $msg = Mail::Message->build(
        To             => $user->email,
#        From           => 'me@example.com',
        Subject        => "Daily Brass status report",
        data           => $output,
    );
    $msg->send(via => 'postfix');
}
