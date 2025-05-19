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

package Brass::Issue::Statuses;

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
    my $status_rs = $self->schema->resultset('Status')->visible;
    $status_rs->result_class('Brass::Issue::Status');
    my @all = $status_rs->all;
    \@all;
}

has approved => (
    is => 'lazy',
);

sub _build_approved
{   my $self = shift;
    $self->schema->resultset('Status')->search({ identifier => 'approved' })->next;
}

1;
