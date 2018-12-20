package Brass::Schema::ResultSet::Servertype;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

sub active_users
{   my $self = shift;

    $self->search({
        'user.deleted' => undef,
    },{
        prefetch => {
            user_servertypes => 'user',
        },
    })->all;
}

1;
