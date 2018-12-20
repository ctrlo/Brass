package Brass::Schema::ResultSet::Project;
  
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
            user_projects => 'user',
        },
    })->all;
}

1;
