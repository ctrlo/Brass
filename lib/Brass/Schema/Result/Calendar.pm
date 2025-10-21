use utf8;
package Brass::Schema::Result::Calendar;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Data::ICal               ();
use Data::ICal::Entry::Event ();
use Data::ICal::Entry::Alarm::Display;
use DateTime                 ();
use DateTime::Format::ICal   ();
use DateTime::Duration       ();
use HTML::FormatText;
use Mail::Message;
use Mail::Message::Body::String;
use Log::Report;
use Sys::Hostname;

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("calendar");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "start",
  { data_type => "datetime", datetime_undef_if_invalid => 0, is_nullable => 1 },
  "end",
  { data_type => "datetime", datetime_undef_if_invalid => 0, is_nullable => 1 },
  "sequence",
  { data_type => "integer", is_nullable => 0, default_value => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "location",
  { data_type => "text", is_nullable => 1 },
  "attendees",
  { data_type => "text", is_nullable => 1 },
  "html",
  { data_type => "text", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "cancelled",
  { data_type => "datetime", datetime_undef_if_invalid => 0, is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "user",
  "Brass::Schema::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

sub cancel
{   my $self = shift;
    $self->update({ cancelled => DateTime->now });
    $self->send;
}

sub send
{   my $self = shift;

    my $tz = DateTime::TimeZone->new(name => 'Europe/London');

    my $is_cancelled = defined $self->cancelled;

    my $start = $self->start
        or error __"Please enter a start date";
    my $offset = sprintf("%+05d", $tz->offset_for_datetime($start) / 3600 * 100);
    $start->set_time_zone($offset);
    my $end = $self->end
        or error __"Please enter an end date";
    $offset = sprintf("%+05d", $tz->offset_for_datetime($end) / 3600 * 100);
    $end->set_time_zone($offset);
    my $description = $self->description
        or error __"Please enter a description";
    my $location = $self->location
        or error __"Please enter a location";
    my %attendees = map { $_ => 1 } grep $_, split /\s+/, $self->attendees
        or error __"Please provide at least one attendee";
    my $me = $self->user;

    $self->update({ sequence => $self->sequence + 1 });

    $attendees{$me->email} = 1;
    my @attendees = keys %attendees;

    my $calendar = Data::ICal->new(auto_uid => 1);
    my $method   = $is_cancelled ? 'CANCEL' : 'REQUEST';
    $calendar->add_property(method => $method);

    my $now = DateTime->now;
    my $event = Data::ICal::Entry::Event->new;
    # Try and create unique UID that can be reused
    my $uid   = hostname . "-BRASS-" . $self->id;
    $event->add_properties(
        summary     => $self->description,
        description => [$self->description, {LANGUAGE=>'en-US'} ],
        dtstart     => DateTime::Format::ICal->format_datetime($start),
        dtend       => DateTime::Format::ICal->format_datetime($end),
        dtstamp     => DateTime::Format::ICal->format_datetime($now),
        uid         => $uid,
        class       => 'PUBLIC',
        priority    => 5,
        transp      => 'OPAQUE',
        status      => $is_cancelled ? 'CANCELLED' : 'CONFIRMED',
        sequence    => $self->sequence,
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

    my @parts;
    # Find out if the HTML is blank (need to strip tags)
    my $html = $is_cancelled ? '<p>This meeting has been canceled</p>' : $self->html;
    my $plain = HTML::FormatText->format_string($html);
    $plain =~ s/^\s+$//;
    $html = '<a href="'.$self->location.'">Click here to join the meeting</a>'
        if !$plain;

    $plain ||= "Join the meeting here: ".$self->location;

    push @parts, Mail::Message::Body::String->new(
        mime_type   => 'text/plain',
        disposition => 'inline',
        data        => $plain,
    );

    push @parts, Mail::Message::Body::String->new(
        mime_type   => 'text/html',
        disposition => 'inline',
        data        => $html,
    );

    push @parts, Mail::Message::Body::String->new(
        mime_type => qq(text/calendar; charset="utf-8"; method=$method),
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

1;
