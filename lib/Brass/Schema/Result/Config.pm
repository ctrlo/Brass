use utf8;
package Brass::Schema::Result::Config;

use strict;
use warnings;

use Log::Report;
use Net::CIDR;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("+Brass::DBIC");

__PACKAGE__->table("config");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "internal_networks",
  { data_type => "text", is_nullable => 1 },
  "smtp_relayhost",
  { data_type => "text", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

sub validate
{   my $self = shift;

    foreach my $range (split /[\s,]+/, $self->internal_networks)
    {
        Net::CIDR::cidrvalidate($range)
            or error __x"Invalid IP range restriction: {range}", range => $range;
    }
}

1;
