=pod
Brass
Copyright (C) 2014 Ctrl O Ltd

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

package Brass::DB;

use Log::Report;
use Moo;

has schema => (
    is       => 'ro',
    required => 1,
);

sub setup
{   my $self = shift;
    # Enable finding of latest status for an issue
    my $issue_class = $self->schema->class('IssueStatus');
    $issue_class->might_have(
        issuestatus_later => 'IssueStatus',
        sub {
            my $args = shift;

            return {
                "$args->{foreign_alias}.issue"  => { -ident => "$args->{self_alias}.issue" },
                "$args->{foreign_alias}.datetime" => { '>' => \"$args->{self_alias}.datetime" },
            };
        }
    );
    $self->schema->unregister_source('IssueStatus');
    $self->schema->register_class(IssueStatus => $issue_class);
}

1;

