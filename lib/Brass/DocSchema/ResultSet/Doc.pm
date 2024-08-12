package Brass::DocSchema::ResultSet::Doc;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

sub active
{   my $self = shift;

    $self->search_rs({
        retired => undef,
    },{
        order_by => 'me.title',
    });
}

sub required_reading
{   my $self = shift;
    $self->active->search_rs({
    });
}

1;
