package Brass::Schema::ResultSet::IssueStatus;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

sub visible
{   my $self = shift;
    $self->search({
        'status.visible' => 1,
    },{
        join => 'status',
    });
}

1;
