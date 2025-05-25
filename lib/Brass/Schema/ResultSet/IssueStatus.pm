package Brass::Schema::ResultSet::IssueStatus;
  
use strict;
use warnings;

use DBIx::Class::Helper::ResultSet::CorrelateRelationship 2.034000;
use Log::Report;

use base qw(DBIx::Class::ResultSet);

__PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

sub visible
{   my $self = shift;
    $self->search({
        'status.visible' => 1,
    },{
        join => 'status',
    });
}

1;
