package Brass::Schema::ResultSet::Server;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

sub by_name
{   my ($self, $name) = @_;

    $self->search({
        'me.name' => $name,
    })->next;
}

1;
