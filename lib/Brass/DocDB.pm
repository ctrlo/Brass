=pod
Brass - Ctrl O management system
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

package Brass::DocDB;

use Log::Report;
use Moo;

has schema => (
    is       => 'ro',
    required => 1,
);

sub setup
{   my $self = shift;

    my $schema = $self->schema;
    # Enable finding of latest file for a document

    my $version_class = $schema->class('Version');
    $version_class->might_have(
        latest_published => 'Version',
        sub {
            my $args = shift;

            return {
                "$args->{foreign_alias}.doc_id"  => { -ident => "$args->{self_alias}.doc_id" },
                "$args->{foreign_alias}.created" => undef,
                "$args->{foreign_alias}.record"  => 1,
            };
        }
    );
    $schema->unregister_source('Version');
    $schema->register_class(Version => $version_class);

    $version_class = $schema->class('Version');
    $version_class->might_have(
        latest_draft => 'Version',
        sub {
            my $args = shift;

            return {
                "$args->{foreign_alias}.doc_id"  => { -ident => "$args->{self_alias}.doc_id" },
                "$args->{foreign_alias}.created" => undef,
                "$args->{foreign_alias}.record"  => 0,
            };
        }
    );
    $schema->unregister_source('Version');
    $schema->register_class(Version => $version_class);
}

1;

