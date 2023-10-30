package Brass::Actions;

use strict;
use warnings;

my @allowed_action = qw(
    admonitor
    backups-gpg
    backups-s3
    disk
    sqldb
    system
    wazuh
);
sub allowed_actions {
    return @allowed_action;
}

my %is_allowed_action = map { $_ => undef } @allowed_action;
sub is_allowed_action {
    my $action_name = $_[0];
    return exists $is_allowed_action{$action_name};
}

1;
