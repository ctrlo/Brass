package Brass::Schema::ResultSet::Issuetype;
  
use strict;
use warnings;

use Log::Report;

use base qw(DBIx::Class::ResultSet);

my @types_vulnerability = (
    {
        identifier => 'code_review',
        name       => 'Code review',
    },
    {
        identifier => 'pentest',
        name       => 'Penetration test',
    },
    {
        identifier => 'scan',
        name       => 'Vulnerability scan',
    },
    {
        identifier => 'ext',
        name       => 'Other external reporter',
    },
    {
        identifier => 'patch',
        name       => 'Critical software patch',
    },
    {
        identifier => 'capacity_change',
        name       => 'Capacity change',
    },
    {
        identifier => 'other_software',
        name       => 'Other system or software failure, not impacting CIA',
    },
    {
        identifier => 'vulnerability_config',
        name       => 'Vulnerability caused by configuration error',
    },
    {
        identifier => 'process_compliance',
        name       => 'Process, procedure or related user compliance',
    },
    {
        identifier => 'risk',
        name       => 'Identified as part of risk assessment process',
    },
    {
        identifier => 'preventative_action',
        name       => 'Preventative action related to security breach',
    },
);

my @types_breach = (
    {
        identifier => 'ext_failure',
        name       => 'Failure within supply chain',
    },
    {
        identifier => 'capacity_fail',
        name       => 'Failure of capacity',
    },
    {
        identifier => 'bug',
        name       => 'Internal software bug',
    },
    {
        identifier => 'user',
        name       => 'Human error',
    },
    {
        identifier => 'vulnerability',
        name       => 'Vulnerability in external software',
    },
    {
        identifier => 'attack',
        name       => 'DoS/external attack',
    },
);

my @types_audit = (
    {
        identifier => 'nc_major',
        name       => 'Major non-conformance',
    },
    {
        identifier => 'nc_minor',
        name       => 'Minor non-conformance',
    },
    {
        identifier => 'obs',
        name       => 'Observation',
    },
);

my @types_other_security = (
    {
        identifier => 'isms_change',
        name       => 'ISMS Change',
    },
    {
        identifier => 'objective',
        name       => 'Objective',
    },
    {
        identifier => 'other_supplier',
        name       => 'Supplier issue related to security',
    },
    {
        identifier => 'bcp',
        name       => 'Business Continuity Plan',
    },
    {
        identifier => 'other_customer',
        name       => 'Customer security-related request',
    },
    {
        identifier => 'data_deletion',
        name       => 'Data deletion action',
    },
    {
        identifier => 'phishing',
        name       => 'Security threat of note (e.g. phishing)',
    },
);

# Populate predefined issue types
sub populate
{   my $self = shift;

    foreach my $type (@types_vulnerability)
    {
        my $existing = $self->_get($type->{identifier});
        $existing->update({
            name             => $type->{name},
            is_vulnerability => 1,
        });
    }

    foreach my $type (@types_breach)
    {
        my $existing = $self->_get($type->{identifier});
        $existing->update({
            name      => $type->{name},
            is_breach => 1,
        });
    }

    foreach my $type (@types_audit)
    {
        my $existing = $self->_get($type->{identifier});
        $existing->update({
            name     => $type->{name},
            is_audit => 1,
        });
    }

    foreach my $type (@types_other_security)
    {
        my $existing = $self->_get($type->{identifier});
        $existing->update({
            name              => $type->{name},
            is_other_security => 1,
        });
    }
}

sub _get
{   my ($self, $identifier) = @_;
    my $existing = $self->search({ identifier => $identifier })->next;
    $existing ||= $self->create({ identifier => $identifier });
}

1;
