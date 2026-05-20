use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {

    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $api_key ($schema->resultset('ApiKey')->all)
    {
        $api_key->user->update({ api_key => $api_key->key });
    }
};
