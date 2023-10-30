package Brass::Actions;

use strict;
use warnings;

my @allowed_action = (
    {
        name     => 'admonitor',
        username => 0,
    },
    {
        name     => 'backups-gpg',
        username => 1,
    },
    {
        name     => 'backups-s3',
        username => 1,
    },
    {
        name     => 'disk',
        username => 0,
    },
    {
        name     => 'sqldb',
        username => 1,
    },
    {
        name     => 'system',
        username => 1,
    },
    {
        name     => 'wazuh',
        username => 1,
    },
);

sub allowed_actions {
    return map $_->{name}, @allowed_action;
}

my %requires_username = map { $_->{name} => $_->{username} } @allowed_action;

sub is_allowed_action {
    my $action_name = $_[0];
    return exists $requires_username{$action_name};
}

sub action_requires_pwd {
    my $action_name = $_[0];
    return $requires_username{$action_name};
}

1;
