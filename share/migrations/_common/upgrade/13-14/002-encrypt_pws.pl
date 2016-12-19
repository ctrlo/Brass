use strict;
use warnings;

use Crypt::CBC;
use DBIx::Class::Migration::RunScript;
 
migrate {

    my $passphrase = $ENV{CDB_PASSPHRASE}
        or die "Need CDB_PASSPHRASE to be set in order to encrypt passwords during upgrade";

    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    my $cipher = Crypt::CBC->new(
        -key    => $passphrase,
        -cipher => 'Blowfish',
    );

    # Copy data from old type table to new issuetype table
    foreach my $row (
        $schema->resultset('Pw')->all
    )
    {
        $row->update({
            pwencrypt => $cipher->encrypt($row->password),
            password  => undef,
        });
    }
};
