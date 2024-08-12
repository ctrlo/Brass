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

sub docread
{   my $self = shift;
    $self->search_rs({
        'user_docreadtypes.id' => { '!=' => undef },
    },{
        join     => 'user_docreadtypes',
        collapse => 1,
    });
}

sub keys
{   my $self = shift;
    $self->search_rs({
        api_key => { '!=' => undef },
    });
}

1;
