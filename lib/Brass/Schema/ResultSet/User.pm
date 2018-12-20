package Brass::Schema::ResultSet::User;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

sub active
{   my ($self, %search) = @_;

    $self->search({
        deleted         => undef,
        %search,
    },{
        order_by => 'me.surname'
    });
}

1;
