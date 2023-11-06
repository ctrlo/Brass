package Brass::Actions;

use strict;
use warnings;

my %allowed_action = (
    admonitor => {
        username => 0,
    },
    'backups-gpg' => {
        username => 1,
    },
    'backups-s3' => {
        username => 1,
    },
    disk => {
        username => 0,
    },
    sqldb => {
        username => 1,
    },
    system => {
        username => 1,
    },
    wazuh => {
        username => 1,
    },
);

sub allowed_actions {
    return keys %allowed_action;
}

sub is_allowed_action {
    my $action_name = $_[0];
    return exists $allowed_action{$action_name};
}

sub action_requires_pwd {
    my $action_name = $_[0];
    return exists $allowed_action{$action_name}
        && $allowed_action{$action_name}{username};
}

1;
