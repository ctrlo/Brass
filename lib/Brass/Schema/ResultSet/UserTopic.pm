package Brass::Schema::ResultSet::UserTopic;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

sub topic
{   my ($self, $topic_id) = @_;

    $self->search({
        'me.topic'     => $topic_id,
        'user.deleted' => undef,
    },{
        join => 'user',
    });
}

1;
