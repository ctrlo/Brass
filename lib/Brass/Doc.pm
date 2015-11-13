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

package Brass::Doc;

use DateTime;
use Brass::Classification;
use Brass::Topic;
use Log::Report;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;
use Text::Diff::FormattedHTML;

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

has id => (
    is  => 'rwp',
    isa => Maybe[Int],
);

has _rset => (
    is => 'lazy',
);

has title => (
    is      => 'rw',
    isa     => Maybe[Str],
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->title; },
);

has topic => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $topic = $self->_rset && $self->_rset->topic
            or return;
        Brass::Topic->new(
            id          => $topic->id,
            name        => $topic->name,
            description => $topic->description,
            schema      => $self->schema,
        );
    },
);

has owner => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->owner },
);

has classification => (
    is      => 'rwp',
    lazy    => 1,
    builder => sub {
        my $self = shift;
        my $classification = $self->_rset && $self->_rset->classification
            or return;
        Brass::Classification->new(
            id          => $classification->id,
            name        => $classification->name,
            schema      => $self->schema,
        );
    },
);

has multiple => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->multiple },
    coerce  => sub { $_[0] ? 1 : 0 },
);

# Database review field date. Manual override for calculated review_due field
has review => (
    is      => 'rw',
    isa     => Maybe[DateAndTime],
    lazy    => 1,
    clearer => 1,
    builder => sub { $_[0]->_rset && $_[0]->_rset->review; },
);

has review_due => (
    is      => 'lazy',
    clearer => 1,
);

has review_due_warning => (
    is      => 'lazy',
    clearer => 1,
);

has draft_for_review => (
    is      => 'lazy',
    clearer => 1,
);

has signed => (
    is      => 'lazy',
    clearer => 1,
);

has published => (
    is      => 'lazy',
    clearer => 1,
);

has published_all => (
    is      => 'lazy',
    clearer => 1,
);

has published_all_retired => (
    is      => 'lazy',
    clearer => 1,
);

has published_all_live => (
    is      => 'lazy',
    clearer => 1,
);

has draft => (
    is      => 'lazy',
    clearer => 1,
);

has latest => (
    is      => 'lazy',
    clearer => 1,
);

# Diff between latest draft and latest published
has diff => (
    is => 'lazy',
);

sub inflate_result {
    my $data   = $_[2];
    my $schema = $_[1]->schema;
    my $db_parser = $schema->storage->datetime_parser;
    my $review = $data->{review} ? $db_parser->parse_date($data->{review}) : undef;
    $_[0]->new(
        id                 => $data->{id},
        title              => $data->{title},
        set_topic          => $data->{topic_id},
        review             => $review,
        set_owner          => $data->{owner},
        set_classification => $data->{classification},
        multiple           => $data->{multiple},
        schema             => $_[1]->schema,
    );
}

has set_topic => (
    is      => 'rw',
    trigger => sub {
        my ($self, $id) = @_;
        $self->_set_topic(Brass::Topic->new(id => $id, schema => $self->schema));
    },
);

has set_classification => (
    is      => 'rw',
    trigger => sub {
        my ($self, $id) = @_;
        $self->_set_classification(Brass::Classification->new(id => $id, schema => $self->schema));
    },
);

sub set_owner
{   my ($self, $id) = @_;
    # $self->topic(Brass::Topic->new(id => $id, schema => $self->schema));
}

sub _build_review_due
{   my $self = shift;
    $self->review
      or $self->published && $self->published->created->clone->add(years => 1);
}

sub _build_review_due_warning
{   my $self = shift;
    my $review_due = $self->review_due
        or return;
      DateTime->compare(DateTime->now, $review_due) == 1
    ? 'red'
    : DateTime->compare(DateTime->now->add(months => 1), $review_due) == 1
    ? 'amber'
    : 'green';
}

sub _build__rset
{   my $self = shift;
    my ($doc) = $self->schema->resultset('Doc')->search({
        'me.id' => $self->id,
    })->all;
    $doc;
}

# Should only be 3 versions in the resultset: one published, one signed and one draft
sub _build_signed
{   my $self = shift;
    my ($signed) = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
        signed => 1,
    },{
        rows     => 1,
        order_by => { -desc => ['major', 'minor'] },
    })->all;
    $signed;
}

sub _build_published
{   my $self = shift;
    my ($published) = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
        minor  => 0,
        signed => 0,
    },{
        rows     => 1,
        order_by => { -desc => 'major' },
    })->all;
    $published;
}

sub _build_published_all
{   my $self = shift;
    my @published = $self->schema->resultset('Version')->search({
        doc_id  => $self->id,
        minor   => 0,
    },{
        order_by => { -desc => 'major' },
    })->all;
    \@published;
}

sub _build_published_all_retired
{   my $self = shift;
    my @published = $self->schema->resultset('Version')->search({
        doc_id  => $self->id,
        minor   => 0,
        retired => { '!=' => undef },
    },{
        order_by => { -desc => 'major' },
    })->all;
    \@published;
}

sub _build_published_all_live
{   my $self = shift;
    my @published = $self->schema->resultset('Version')->search({
        doc_id  => $self->id,
        minor   => 0,
        retired => undef,
    },{
        order_by => { -desc => 'major' },
    })->all;
    \@published;
}

sub _build_draft
{   my $self = shift;
    my ($draft) = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
        minor  => { '!=' => 0 },
    },{
        rows     => 1,
        order_by => { -desc => [qw/major minor revision/] },
    })->all;
    $draft;
}

sub _build_latest
{   my $self = shift;
    my $draft = $self->draft;
    my $published = $self->published;
    return unless $draft || $published; # No docs yet
    return $draft || $published if $draft xor $published; # Only one exists
    _version_compare($draft, $published) > 0
    ? $draft
    : $published;
}

sub _build_draft_for_review
{   my $self = shift;
    $self->draft && !$self->published
        and return 1;
    $self->published && $self->draft
        or return;
    _version_compare($self->draft, $self->published) > 0;
}

sub _build_diff
{   my $self = shift;
    $self->draft_for_review or return;
    my $draft = $self->draft && $self->draft->version_content->content
        or return;
    my $published = $self->published && $self->published->version_content->content
        or return;
    diff_strings($published, $draft);
}

sub _latest
{   my $self = shift;
    my ($latest) = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
        signed => 0,
    },{
        rows     => 1,
        order_by => { -desc => [qw/major minor revision/] },
    });
    $latest;
}

sub _version_add
{   my ($self, %options) = @_;
    # Start transaction
    my $guard = $self->schema->txn_scope_guard;
    my $latest = $self->_latest;

    my ($mimetype, $ext, $content, $content_blob);
    if ($options{text})
    {
        $options{content} =~ s/\r\n/\n/g;
        $options{content} =~ s/\r/\n/g;
        # Do not create new version if content hasn't changed
        $options{new} = 0 if $latest && $options{content} eq $latest->version_content->content;
        $mimetype = $options{tex} ? 'application/x-tex' : 'text/plain';
        $content  = $options{content};
    }
    else {
        $mimetype     = $options{file}->type;
        $content_blob = $options{file}->content;
        $options{file}->basename =~ /.*\.([a-z0-9]+)/i;
        $ext = $1;
    }

    # Never save over a published document. draft_for_review
    # will be false if the latest document is published.published
    $options{new} = 1 if !$self->draft_for_review;

    # Don't allow saving of signed unless something published
    my $signed = $options{signed} && $self->published ? 1 : 0;

    my $version_new;
    if ($options{new})
    {
        my $major = $signed
                  ? $self->published->major
                  : $latest
                  ? $latest->major
                  : 0;
        my $minor = $signed
                  ? $self->published->minor
                  : $latest
                  ? $latest->minor + 1
                  : 1;
        $version_new = $self->schema->resultset('Version')->create({
            doc_id   => $self->id,
            major    => $major,
            minor    => $minor,
            signed   => $signed,
            revision => 0,
            created  => DateTime->now,
            blobext  => $ext,
            mimetype => $mimetype,
        });
        $self->schema->resultset('VersionContent')->create({
            id           => $version_new->id,
            content      => $content,
            content_blob => $content_blob,
        });
        $version_new->update({
            reviewer => $options{user}->id,
            approver => $options{user}->id,
        }) if $signed; # No formal publishing
    }
    else {
        $latest->update({
            created  => DateTime->now,
            mimetype => $mimetype,
        });
        $latest->version_content->update({
            content      => $content,
            content_blob => $content_blob,
        });
        $version_new = $latest;
    }

    # Force rebuild
    $self->clear_draft_for_review;
    $self->clear_review_due;
    $self->clear_review;
    $self->clear_review_due_warning;
    $self->clear_signed;
    $self->clear_published;
    $self->clear_published_all;
    $self->clear_published_all_retired;
    $self->clear_published_all_live;
    $self->clear_draft;
    $self->clear_latest;

    $guard->commit;
    $version_new->id;
}

sub publish
{   my ($self, $id, $user) = @_;
    my $guard   = $self->schema->txn_scope_guard;
    my $latest  = $self->_latest;
    my $version = $self->schema->resultset('Version')->find($id);
    $version->update({
        major    => $latest->major + 1,
        minor    => 0,
        revision => 0,
        reviewer => $user->id,
        approver => $user->id,
    });
    $self->_rset->update({review => undef});
    $guard->commit;
}

sub retire
{   my $self = shift;
    $self->_rset->update({retired => DateTime->now});
}

sub retire_version
{   my ($self, $version_id) = @_;
    my @versions = @{$self->published_all};
    my ($version) = grep { $_->id == $version_id } @versions
        or error __x"Version {id} not found in document {docid}",
            id => $version_id, docid => $self->id;
    $version->update({retired => DateTime->now});
}

sub file_save
{   my ($self, $file) = @_;
    my %options = (
        file => $file,
    );
    $self->_version_add(%options);
}

sub signed_save
{   my ($self, $file, $user) = @_;
    my %options = (
        file   => $file,
        signed => 1,
        user   => $user,
    );
    $self->_version_add(%options);
}

sub plain_save
{   my ($self, $text) = @_;
    my %options = (
        text    => 1,
        content => $text,
    );
    $self->_version_add(%options);
}

sub tex_save
{   my ($self, $text) = @_;
    my %options = (
        tex     => 1,
        text    => 1,
        content => $text,
    );
    $self->_version_add(%options);
}

sub file_add
{   my ($self, $file) = @_;
    my %options = (
        file => $file,
        new  => 1,
    );
    $self->_version_add(%options);
}

sub plain_add
{   my ($self, $text) = @_;
    my %options = (
        text    => 1,
        content => $text,
        new     => 1,
    );
    $self->_version_add(%options);
}

sub tex_add
{   my ($self, $text) = @_;
    my %options = (
        tex     => 1,
        text    => 1,
        content => $text,
        new     => 1,
    );
    $self->_version_add(%options);
}

sub write
{   my $self = shift;
    my $values = {
        title          => $self->title,
        topic_id       => $self->topic->id,
        classification => $self->classification->id,
        multiple       => $self->multiple,
        review         => $self->review,
    };
    if ($self->id)
    {
        $self->_rset->update($values);
    }
    else {
        $self->schema->resultset('Doc')->create($values);
    }
}

sub as_string
{   my $self = shift;
    $self->surname.", ".$self->firstname;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

sub _version_compare
{   my ($a, $b) = @_;
    return 0
        if $a->major == $b->major
        && $a->minor == $b->minor
        && $a->revision == $b->revision;
    return 1
        if $a->major > $b->major
        || ($a->major == $b->major && $a->minor > $b->minor)
        || ($a->major == $b->major && $a->minor == $b->minor && $a->revision > $b->revision);
    return -1;
}

1;

