package Brass::Schema::ResultSet::Status;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

my @types = (
    {
        identifier => 'approved',
        name       => 'Approved',
    },
);

# Populate predefined issue types
sub populate
{   my $self = shift;

    foreach my $type (@types)
    {
        my $existing = $self->_get($type->{identifier});
        $existing->update({
            name    => $type->{name},
            visible => 0,
        });
    }
}

sub _get
{   my ($self, $identifier) = @_;
    my $existing = $self->search({ identifier => $identifier })->next;
    $existing ||= $self->create({ identifier => $identifier });
}

sub visible
{   my $self = shift;
    $self->search({ visible => 1 });
}

1;
