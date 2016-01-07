use strict;
use warnings;
use DBIx::Class::Migration::RunScript;

migrate {

    my $schema = shift->schema;

    my $permission_rs = $schema->resultset('Permission');

    $permission_rs->populate
    ([
        {
            id          => 1,
            name        => 'doc',
            description => 'User can view documents',
        },{
            id          => 2,
            name        => 'doc_publish',
            description => 'User can publish documents',
        },{
            id          => 3,
            name        => 'doc_save',
            description => 'User can save drafts',
        },{
            id          => 4,
            name        => 'doc_record',
            description => 'User can save records',
        },{
            id          => 5,
            name        => 'issue_read',
            description => 'User can view own issues',
        },{
            id          => 6,
            name        => 'issue_read_all',
            description => 'User can view all issues',
        },{
            id          => 7,
            name        => 'issue_write',
            description => 'User can write to new and own issues',
        },{
            id          => 8,
            name        => 'issue_write_all',
            description => 'User can write to all issues',
        },{
            id          => 9,
            name        => 'issue_read_project',
            description => 'User can view all issues for certain projects',
        },{
            id          => 10,
            name        => 'config',
            description => 'User can view configuration information',
        },{
            id          => 11,
            name        => 'config_write',
            description => 'User can write configuration information',
        },
    ]);
};

