=pod
Brass
Copyright (C) 2015 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package Brass::Issue::Types;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has schema => (
    is       => 'ro',
    required => 1,
);

has all => (
    is => 'lazy',
);

sub _build_all
{   my $self = shift;
    my $type_rs = $self->schema->resultset('Issuetype')->search;
    $type_rs->result_class('Brass::Issue::Type');
    my @all = $type_rs->all;
    \@all;
}

has grouped => (
    is => 'lazy',
);

sub _build_grouped
{   my $self = shift;
    my %groups = (
        vulnerability => [],
        breach        => [],
        audit         => [],
        general       => [],
        other         => [],
    );
    foreach my $type (@{$self->all})
    {
        push @{$groups{vulnerability}}, $type
            if $type->is_vulnerability;
        push @{$groups{breach}}, $type
            if $type->is_breach;
        push @{$groups{audit}}, $type
            if $type->is_audit;
        push @{$groups{general}}, $type
            if $type->is_general;
        push @{$groups{other}}, $type
            if $type->is_other_security;
    }

    [
        {
            name   => 'General issues',
            values => $groups{general},
        },
        {
            name   => 'Security Vulnerabilities',
            values => $groups{vulnerability},
        },
        {
            name   => 'Security Breaches (loss of CIA)',
            values => $groups{breach},
        },
        {
            name   => 'Security Audits',
            values => $groups{audit},
        },
        {
            name   => 'Other security-related issues',
            values => $groups{other},
        },
    ];
}

1;
