use strict;
use warnings;
use DBIx::Class::Migration::RunScript;

migrate {

    my $schema = shift->schema;

    my $permission_rs = $schema->resultset('Permission');

    $permission_rs->populate
    ([
        {
            name        => 'doc',
            description => 'User can view documents',
        },{
            name        => 'doc_publish',
            description => 'User can publish documents',
        },{
            name        => 'doc_save',
            description => 'User can save drafts',
        },{
            name        => 'issue_read',
            description => 'User can view own issues',
        },{
            name        => 'issue_read_all',
            description => 'User can view all issues',
        },{
            name        => 'issue_write',
            description => 'User can write to new and own issues',
        },{
            name        => 'issue_write_all',
            description => 'User can write to all issues',
        },{
            name        => 'issue_read_project',
            description => 'User can view all issues for certain projects',
        },
    ]);
};

