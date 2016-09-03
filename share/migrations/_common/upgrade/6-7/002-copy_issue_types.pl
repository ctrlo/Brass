use strict;
use warnings;
use DBIx::Class::Migration::RunScript;
 
migrate {
    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    # Copy data from old type table to new issuetype table
    foreach my $row (
        $schema->resultset('Type')->all
    )
    {
        $schema->resultset('Issuetype')->create({
            name => $row->name,
        });
    }
};
