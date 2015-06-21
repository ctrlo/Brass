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
        },
    ]);
};

