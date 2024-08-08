use utf8;
package Brass::Schema::Result::Cert;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Log::Report;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("cert");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "content",
  { data_type => "text", is_nullable => 1 },
  "cn",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "expiry",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "usedby",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "filename",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "file_user",
  { data_type => "text", is_nullable => 1 },
  "file_group",
  { data_type => "text", is_nullable => 1 },
  "content_cert",
  { data_type => "text", is_nullable => 1 },
  "content_key",
  { data_type => "text", is_nullable => 1 },
  "content_ca",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "server_certs",
  "Brass::Schema::Result::ServerCert",
  { "foreign.cert_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "cert_locations",
  "Brass::Schema::Result::CertLocation",
  { "foreign.cert_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub delete_cert
{   my $self = shift;
    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->server_certs->delete;
    $_->purge foreach $self->cert_locations;
    $self->cert_locations->delete;
    $self->delete;
    $guard->commit;
}

# A single use and associated location
sub as_hash_single
{   my $self = shift;

    my $hash = $self->_as_hash;

    foreach my $location ($self->cert_locations)
    {
        error __"More uses than expected for this certificate"
            if $location->cert_location_uses > 1;
        error __"No use defined for this certificate"
            if !$location->cert_location_uses;

        my $use = $location->cert_location_uses->next->use;

        $hash->{locations} ||= [];

        push @{$hash->{locations}}, {
            use           => $use->name,
            filename_cert => $location->filename_cert,
            filename_key  => $location->filename_key,
            filename_ca   => $location->filename_ca,
            file_user     => $location->file_user,
            file_group    => $location->file_group,
        }
    }

    $hash;
}

# All the locations and uses of this certificate
sub as_hash_multiple
{   my $self = shift;

    my $hash = $self->_as_hash;

    my %servers;
    foreach my $sc ($self->server_certs)
    {
        $servers{$sc->server_id} ||= {
            name => $sc->server->name,
        };

        # All uses for this certificate for this server
        $servers{$sc->server_id}->{uses}->{$sc->use->name} = 1;

        # All locations it needs to be saved
        my $cl = $self->result_source->schema->resultset('CertLocation')->search({
            'me.cert_id'                => $self->id,
            'cert_location_uses.use_id' => $sc->get_column('use'),
        },{
            join => 'cert_location_uses',
        });
        $cl->count
            or error __x"No locations defined for use {use} of certificate ID {id}",
                use => $sc->use->name, id => $self->id;
        foreach my $location ($cl->all)
        {
            $servers{$sc->server_id}->{locations}->{$location->id} = {
                filename_cert => $location->filename_cert,
                filename_key  => $location->filename_key,
                filename_ca   => $location->filename_ca,
                file_user     => $location->file_user,
                file_group    => $location->file_group,
            };
        }
    }

    $hash->{servers} = [];

    foreach my $server (values %servers)
    {
        push @{$hash->{servers}}, {
            name => $server->{name},
            uses => [keys %{$server->{uses}}],
            locations => [values %{$server->{locations}}],
        };
    }

    $hash;
}

sub _as_hash
{   my $self = shift;
    +{
        # Make sure cert content ends with newline
        content_cert  => $self->content_cert =~ s/(.+)\v*$/$1\n/r,
        content_key   => $self->content_key  =~ s/(.+)\v*$/$1\n/r,
        content_ca    => $self->content_ca   =~ s/(.+)\v*$/$1\n/r,
    };
}

1;
