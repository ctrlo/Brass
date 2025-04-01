package Brass::Schema::ResultSet::Calendar;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

sub active
{   my $self = shift;
    $self->search({ cancelled => undef });
}

1;
