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

sub keys
{   my $self = shift;
    $self->search_rs({
        api_key => { '!=' => undef },
    });
}

1;
