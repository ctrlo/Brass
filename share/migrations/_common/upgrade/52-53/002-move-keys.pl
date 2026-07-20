use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {

    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $user ($schema->resultset('User')->search({ api_key => { '!=' => undef } })->all)
    {
        $schema->resultset('ApiKey')->create({
            user_id => $user->id,
            key     => $user->api_key,
        });
    }
};
