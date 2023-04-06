=pod
Brass
Copyright (C) 2023 Ctrl O Ltd

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

package Brass::Calendar;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;

use Brass::CurrentUser;
use Data::ICal               ();
use Data::ICal::Entry::Event ();
use Data::ICal::Entry::Alarm::Display;
use DateTime                 ();
use DateTime::Format::CLDR;
use DateTime::Format::ICal   ();
use DateTime::Duration       ();
use Mail::Message;
use Mail::Message::Body::String;
use Log::Report;

has start => (
    is     => 'rw',
);

has end => (
    is     => 'rw',
);

has description => (
    is  => 'rw',
    isa => Str,
);

has location => (
    is  => 'rw',
    isa => Str,
);

has attendees => (
    is  => 'rw',
    isa => Str,
);

sub send
{   my $self = shift;
    $self->start
        or error __"Please enter a start date";
    my $start = $self->parsedt($self->start)
        or error __"Invalid start date format";
    $self->end
        or error __"Please enter an end date";
    my $end = $self->parsedt($self->end)
        or error __"Invalid end date format";
    my $description = $self->description
        or error __"Please enter a description";
    my $location = $self->location
        or error __"Please enter a location";
    my %attendees = map { $_ => 1 } grep $_, split /\s+/, $self->attendees
        or error __"Please provide at least one attendee";
    my $me = Brass::CurrentUser->instance->user;
    $attendees{$me->email} = 1;
    my @attendees = keys %attendees;

    my $calendar = Data::ICal->new(auto_uid => 1);
    $calendar->add_property(method => 'REQUEST');

    my $now = DateTime->now;
    #my $begin = DateTime->new( year => 2023, month => 3, day => 31, hour => 14, time_zone => '-0400' );
    #my $end = DateTime->new( year => 2023, month => 3, day => 31, hour => 15, time_zone => '-0400' );
    my $event = Data::ICal::Entry::Event->new;
    $event->add_properties(
        summary     => $self->description,
        description => [$self->description, {LANGUAGE=>'en-US'} ],
        dtstart     => DateTime::Format::ICal->format_datetime($start),
        dtend       => DateTime::Format::ICal->format_datetime($end),
        dtstamp     => DateTime::Format::ICal->format_datetime($now),
        uid         => DateTime::Format::ICal->format_datetime($end) . '-other3',
        class       => 'PUBLIC',
        priority    => 5,
        transp      => 'OPAQUE',
        status      => 'CONFIRMED',
        sequence    => 0,
        #uid => '040000008200E00074C5B7101A82E00800000000111F9A623E63D9010000000000000000100000009C7D80CF03DA444E9BBCE6716F8853B4',
    );

    my $mailto = 'mailto:'.$me->email;
    $event->add_property(organizer => [ $mailto, { CN => $me->name } ] );
    $event->add_property(attendee => [ $mailto, { ROLE => 'REQ-PARTICIPANT', PARTSTAT => 'NEEDS-ACTION', RSVP => 'TRUE', CN => $me->name } ] );
    $event->add_property(attendee => [ "mailto:$_", {RSVP=>'TRUE', ROLE => 'REQ-PARTICIPANT', PARTSTAT => 'NEEDS-ACTION'}])
        foreach @attendees;

    $event->add_property(location     => [$self->location, { LANGUAGE => 'en-US' }]);
    $event->add_property('x-alt-desc' => ['<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 3.2//EN""><HTML><BODY>\n<a href="'.$self->location.'">Join meeting</a>\n</BODY></HTML>', {FMTTYPE=> 'text/html'}]);

    my $alarm = Data::ICal::Entry::Alarm::Display->new();
    $alarm->add_properties(
        description => "REMINDER",
        trigger     => [ "-PT15M", { RELATED => 'START' } ],
    );
    $event->add_entry($alarm);
    $calendar->add_entry($event);

    #open(my $fh, "<", "teams-invite.msg");
    #my $msg = Mail::Message->read($fh);
    #my ($plain, $html, $cal) = map $_->body->decoded->string, $msg->parts;

    my @parts;
    push @parts, Mail::Message::Body::String->new(
        mime_type   => 'text/plain',
        disposition => 'inline',
        data        => "This is the plain text",
    );

    push @parts, Mail::Message::Body::String->new(
        mime_type   => 'text/html',
        disposition => 'inline',
        data        => "This is the <b>html</b> text",
    );

    push @parts, Mail::Message::Body::String->new(
        mime_type => 'text/calendar; charset="utf-8"; method=REQUEST',
        data      => $calendar->as_string,
    )->encode(
        # Default quoted-printable breaks email addresses across lines which
        # Outlook doesn't like
        transfer_encoding => 'base64',
    );

    my $content_type = 'multipart/alternative';

    my %message = (
        From           => '"'.$me->name.'" <'.$me->email.'>',
        Subject        => $self->description,
        To             => join(', ', @attendees),
        'Content-Type' => $content_type,
        attach         => \@parts,
    );

    Mail::Message->build(
        %message,
    )->send(
        via              => 'sendmail',
        sendmail_options => [-f => $me->email],
    );
}

sub parsedt
{   my ($self, $in) = @_;
    $in or return;
    my $cldr = DateTime::Format::CLDR->new(
        pattern => 'yyyy-MM-dd HH:mm',
    );
    $cldr->parse_datetime($in);
};

1;


