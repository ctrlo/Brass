#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Brass::Config::Certs;
use Brass::Config::Servers;
use Brass::Issue::Priorities;
use Brass::Issue::Statuses;
use Brass::Issues;
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

my $users            = Brass::Users->new(schema => $schema);
my $issues           = Brass::Issues->new(schema => $schema, users => $users);
my $statuses         = Brass::Issue::Statuses->new(schema => $schema);
my $priorities       = Brass::Issue::Priorities->new(schema => $schema);
my @filter_status    = map { $_->id } grep { $_->name =~ /(new|open)/i } @{$statuses->all};
my @filter_priority  = map { $_->id } grep { $_->alert_frequency && $_->alert_frequency == 1 } @{$priorities->all};
push @filter_priority, map { $_->id } grep { $_->alert_frequency && $_->alert_frequency == 7 } @{$priorities->all}
    if DateTime->now->day_of_week == 1;
my $filtering = {
    status   => \@filter_status,
    priority => \@filter_priority,
};
$issues->filtering($filtering);
$output .= "Ticket observations:\n";
$output .= "===========================\n";
@messages = ();
foreach my $issue (@{$issues->all})
{
    push @messages, sprinti "{priority} issue {id} ({title}) is still outstanding",
        priority => $issue->priority->name, id => $issue->id, title => $issue->title;
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
    if (!$server->update_datetime)
    {
        push @messages, sprinti "No update of server {name}",
            name => $server->name;
    }
    elsif ($server->update_datetime < DateTime->now->subtract(days => 9))
    {
        push @messages, sprinti "Last update of server {name} was {date}",
            name => $server->name, date => $server->update_datetime->ymd;
    }
}
$output .= "$_\n" foreach @messages;
$output .= "Nothing to report\n" if !@messages;

foreach my $user (@{$users->all(role => 'reports')})
{
    my $msg = Mail::Message->build(
        To             => $user->email,
#        From           => 'me@example.com',
        Subject        => "Daily Brass status report",
        data           => $output,
    );
    $msg->send(via => 'postfix');
}

my $app = schema->resultset('App')->next || schema->resultset('App')->create({});
$app->update({ status_last_run => DateTime->now });
