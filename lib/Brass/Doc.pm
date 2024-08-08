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
use Mail::Message;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::Types::MooseLike::DateTime qw/DateAndTime/;
use Session::Token;
use Text::Diff::FormattedHTML;

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

has schema_brass => (
    is => 'ro',
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

# Current live document (signed or published)
has current => (
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

has docreadtypes => (
    is  => 'rw',
    isa => ArrayRef,
);

sub has_docreadtype
{   my ($self, $docreadtype_id) = @_;
    !! $self->schema_brass->resultset('DocDocreadtype')->search({
        doc_id         => $self->id,
        docreadtype_id => $docreadtype_id,
    })->count;
}

sub set_owner
{   my ($self, $id) = @_;
    # $self->topic(Brass::Topic->new(id => $id, schema => $self->schema));
}

sub _build_review_due
{   my $self = shift;
    $self->review
      or $self->current && $self->current->created->clone->add(years => 1);
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

sub _build_current
{   my $self = shift;

    $self->published or return undef;

    return $self->published if !$self->signed;

    return $self->signed && $self->signed->major == $self->published->major
        ? $self->signed : $self->published;
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
    my $draft = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
        minor  => { '!=' => 0 },
    },{
        rows     => 1,
        order_by => { -desc => [qw/major minor revision/] },
    })->next or return undef;
    return undef if $self->published && $draft->major < $self->published->major;
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
        $options{text} =~ s/\r\n/\n/g;
        $options{text} =~ s/\r/\n/g;
        # Do not create new version if content hasn't changed
        $options{new} = 0 if $latest && $options{text} eq $latest->version_content->content;
        $mimetype = $options{tex}
            ? 'application/x-tex'
            : $options{markdown}
            ? 'text/markdown'
            : 'text/plain';
        $content  = $options{text};
    }
    elsif ($options{upload}) {
        $mimetype     = $options{upload}->type;
        $content_blob = $options{upload}->content;
        $options{upload}->basename =~ /.*\.([a-z0-9]+)/i;
        $ext = $1;
    }
    else {
        $mimetype     = $options{mimetype} or die "Missing mimetype";
        $content_blob = $options{file} or die "Missing file content";
        $ext          = $options{ext} or die "Missing file extension";
    }

    # Never save over a published document. draft_for_review
    # will be false if the latest document is published.published
    $options{new} = 1 if !$self->draft_for_review;

    # Don't allow saving of signed unless something published
    die "Unable to save a signed file when no existing published doc exists"
        if $options{signed} && !$self->published;
    my $signed = $options{signed} ? 1 : 0;
    my $record = $options{record} ? 1 : 0;
    my $notes  = $options{notes};

    if ($signed)
    {
        # See if there is an existing signed copy for the currently published
        # version. We don't use $self->signed, as this may be an older copy.
        my ($existing_signed) = $self->schema->resultset('Version')->search({
            doc_id => $self->id,
            signed => 1,
            major  => $self->published->major,
            minor  => 0,
        })->all;
        # If so, update that instead
        if ($existing_signed)
        {
            $options{new} = 0;
            $latest = $existing_signed;
        }
    }

    my $version_new;
    if ($options{new})
    {
        my $major = $signed
                  ? $self->published->major
                  : $record
                  ? ($latest ? $latest->major + 1 : 1)
                  : $latest
                  ? $latest->major
                  : 0;
        my $minor = $signed
                  ? $self->published->minor
                  : $record
                  ? 0
                  : $latest
                  ? $latest->minor + 1
                  : 1;
        $self->_rset->update({
            review => undef, # Remove previous review date if publishing new
        }) if $minor == 0;
        $version_new = $self->schema->resultset('Version')->create({
            doc_id   => $self->id,
            major    => $major,
            minor    => $minor,
            signed   => $signed,
            record   => $record,
            revision => 0,
            notes    => $notes,
            drafter  => $options{user}->id,
            created  => $options{datetime} || DateTime->now,
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
            notes    => $notes,
        }) if $signed || $record; # No formal publishing
    }
    else {
        $latest->update({
            created  => DateTime->now,
            mimetype => $mimetype,
            notes    => $notes,
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

sub revert
{   my ($self, $user) = @_;
    my $guard   = $self->schema->txn_scope_guard;
    my $latest  = $self->_latest;
    error __x"Can only revert review documents"
        unless !$latest->is_published && $latest->reviewer;
    $latest->update({
        reviewer => undef,
    });
    $guard->commit;
}

sub submit_review
{   my ($self, $user) = @_;
    my $guard   = $self->schema->txn_scope_guard;
    my $latest  = $self->_latest;
    error __x"Can only review draft documents"
        unless $latest->is_draft;
    $latest->update({
        reviewer => $user->id,
    });
    # Ensure PDF is regenerated with reviewer info if Latex doc
    $latest->version_content->update({
        content_blob => undef,
    }) if $latest->mimetype eq 'application/x-tex';
    $self->_rset->update({review => undef});
    $guard->commit;
}

sub publish
{   my ($self, $user) = @_;
    my $guard   = $self->schema->txn_scope_guard;
    my $latest  = $self->_latest;
    error __x"Cannot publish unreviewed document"
        unless $latest->reviewer;
    error __x"Document already published"
        if $latest->is_published;
    $latest->update({
        major    => $latest->major + 1,
        minor    => 0,
        revision => 0,
        approver => $user->id,
    });
    # Ensure PDF is regenerated with reviewer info if Latex doc
    $latest->version_content->update({
        content_blob => undef,
    }) if $latest->mimetype eq 'application/x-tex';
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
{   my ($self, %options) = @_;
    $self->_version_add(%options);
}

sub signed_save
{   my ($self, %options) = @_;
    $options{signed} = 1;
    $self->_version_add(%options);
}

sub record_save
{   my ($self, %options) = @_;
    $options{record} = 1;
    $options{new} = 1; # Always save as new file
    $self->_version_add(%options);
}

sub plain_save
{   my ($self, %options) = @_;
    $self->_version_add(%options);
}

sub tex_save
{   my ($self, %options) = @_;
    $options{tex}     = 1;
    $self->_version_add(%options);
}

sub markdown_save
{   my ($self, %options) = @_;
    $options{markdown} = 1;
    $self->_version_add(%options);
}

sub file_add
{   my ($self, %options) = @_;
    $options{new}  = 1;
    $self->_version_add(%options);
}

sub plain_add
{   my ($self, %options) = @_;
    $options{new}     = 1;
    $self->_version_add(%options);
}

sub tex_add
{   my ($self, %options) = @_;
    $options{tex}     = 1;
    $options{new}     = 1;
    $self->_version_add(%options);
}

sub markdown_add
{   my ($self, %options) = @_;
    $options{markdown} = 1;
    $options{new}      = 1;
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
    if ($self->docreadtypes)
    {
        $self->schema_brass->resultset('DocDocreadtype')->search({
            doc_id => $self->id,
        })->delete;
        foreach my $docreadtype_id (@{$self->docreadtypes})
        {
            $self->schema_brass->resultset('DocDocreadtype')->create({
                doc_id         => $self->id,
                docreadtype_id => $docreadtype_id,
            });
        }
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

sub user_can
{   my ($self, $permission) = @_;
    my $user = Brass::CurrentUser->instance->user
        or panic "logged_in_user not set for user_can";
    $permission =~ /^(read|publish|save|record)$/
        or panic "Invalid permission $permission passed to user_can";
    # First check for required global permission
    $permission = $permission eq 'read' ? 'doc' : "doc_$permission";
    $user->has_permission($permission)
        or return 0;
    # Now check for access to this topic
    $user->has_topic_permission($self->topic->id, $permission);
}

sub send
{   my ($self, %params) = @_;

    my $email = $params{to}
        or error "Please supply an email address";

    my $code = Session::Token->new( length => 32 )->get;

    # code has unique constraint so will bork if duplicate
    $self->schema_brass->resultset('Docsend')->create({
        doc_id  => $self->id,
        email   => $email,
        code    => $code,
        created => DateTime->now,
    });

    my $user = Brass::CurrentUser->instance->user;
    my $name = $user->firstname.' '.$user->surname;
    my $from = $params{from}
        or error "Sender email address not configured";

    Mail::Message->build(
        To             => $email,
        From           => $from,
        'Content-Type' => 'text/plain',
        Subject        => 'A document has been sent: '.$self->title,
        data           => <<__PLAIN,
$name has sent you a document via a link.

The link is valid for 24 hours and can only be used once:

$params{uri_base}/doc/download/$code
__PLAIN
    )->send(
        via              => 'sendmail',
        sendmail_options => [-f => $from],
    );
}

1;

