use strict;
use warnings;
use DateTime;
use DBIx::Class::Migration::RunScript;

migrate {
    my $schema = shift->schema;

    foreach my $issuetype ($schema->resultset('Issuetype')->all)
    {
        $schema->resultset('Type')->create({
            name => $issuetype->name,
        });
    }
};
