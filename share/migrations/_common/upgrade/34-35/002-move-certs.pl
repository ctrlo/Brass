use strict;
use warnings;

use DBIx::Class::Migration::RunScript;
 
migrate {

    my $schema = shift->schema;
    # dbic_connect_attrs is ignored, so quote_names needs to be forced
    $schema->storage->connect_info(
        [sub {$schema->storage->dbh}, { quote_names => 1 }]
    );

    foreach my $cert ($schema->resultset('Cert')->all)
    {
        # Different aspects of certs are now all combined in the one database
        # row. Manual intervention will be required to combine the existing
        # separate ones, but so that we don't lose any data during the upgrade,
        # copy all the existing data into the new fields
        $cert->update({
            description   => $cert->usedby,
            content_cert  => $cert->content,
            content_key   => $cert->content,
            content_ca    => $cert->content,
        });

        foreach my $filename (split /[\s,]+/, $cert->filename)
        {
            $schema->resultset('CertLocation')->create({
                cert_id       => $cert->id,
                filename_cert => $filename,
                filename_key  => $filename,
                filename_ca   => $filename,
                file_user     => $cert->file_user,
                file_group    => $cert->file_group,
            });
        }
    }
};
