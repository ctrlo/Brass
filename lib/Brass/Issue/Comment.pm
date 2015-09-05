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

package Brass::Issue::Comment;

use HTML::FromText;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

# All system users. Must be populated before doing any user calls
has users => (
    is => 'rw',
);

has id => (
    is  => 'ro',
    isa => Int,
);

has text => (
    is  => 'ro',
    isa => Str,
);

has set_author => (
    is => 'ro',
);

has datetime => (
    is  => 'ro',
    isa => Maybe[DateAndTime],
);

sub author
{   my $self = shift;
    $self->users->user($self->set_author);
}

sub inflate_result {
    my $data = $_[2];
    my $schema = $_[1]->schema;
    my $db_parser = $schema->storage->datetime_parser;
    my $datetime = $data->{datetime} && $data->{datetime} ne '0000-00-00 00:00:00'
        ? $db_parser->parse_datetime($data->{datetime})
        : undef;

    $_[0]->new(
        id          => $data->{id},
        text        => $data->{text},
        set_author  => $data->{author},
        datetime    => $datetime,
    );
}

sub text_html_links
{   my $self = shift;
    my $text = $self->text;
    text2html(
        $text,
        urls      => 1,
        email     => 1,
        metachars => 1,
        paras     => 1,
    );
}

1;

