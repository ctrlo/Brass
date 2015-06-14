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
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Text::Diff ();

use overload 'bool' => sub { 1 }, '""'  => 'as_string', '0+' => 'as_integer', fallback => 1;

has schema => (
    is       => 'ro',
    required => 1,
);

has id => (
    is  => 'rwp',
    isa => Int,
);

has _rset => (
    is => 'lazy',
);

has title => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->title; },
);

has owner => (
    is      => 'rw',
    lazy    => 1,
    builder => sub { $_[0]->_rset->owner },
);

has review_due => (
    is => 'lazy',
);

has review_due_warning => (
    is => 'lazy',
);

has draft_for_review => (
    is => 'lazy',
);

has published => (
    is => 'lazy',
);

has draft => (
    is => 'lazy',
);

has latest => (
    is => 'lazy',
);

# Diff between latest draft and latest published
has diff => (
    is => 'lazy',
);

sub _build_review_due
{   my $self = shift;
    $self->published && $self->published->created->clone->add(years => 1);
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

# Should only be 2 versions in the resultset: one published and one draft
sub _build_published
{   my $self = shift;
    my ($published) = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
        minor  => 0,
    },{
        rows     => 1,
        order_by => { -desc => 'major' },
    })->all;
    $published;
}

sub _build_draft
{   my $self = shift;
    my ($draft) = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
        minor  => { '!=' => 0 },
    },{
        rows     => 1,
        order_by => { -desc => [qw/major minor/] },
    })->all;
    $draft;
}

sub _build_latest
{   my $self = shift;
    my $draft = $self->draft;
    my $published = $self->published;
    return $draft || $published if $draft xor $published; # Only one exists
    DateTime->compare($draft->created, $published->created) > 0
    ? $draft
    : $published;
}

sub _build_draft_for_review
{   my $self = shift;
    $self->published && $self->draft
        or return;
    DateTime->compare($self->draft->created, $self->published->created) > 0;
}

sub _build_diff
{   my $self = shift;
    $self->draft_for_review or return;
    my $draft = $self->draft->version_content->content
        or return;
    my $published = $self->published->version_content->content
        or return;
    Text::Diff::diff(\$draft, \$published);
}

sub _version_add
{   my ($self, %options) = @_;
    # Start transaction
    my $guard = $self->schema->txn_scope_guard;
    my ($latest) = $self->schema->resultset('Version')->search({
        doc_id => $self->id,
    },{
        rows     => 1,
        order_by => { -desc => [qw/major minor revision/] },
    });

    my ($mimetype, $ext, $content, $content_blob);
    if ($options{text})
    {
        $options{content} =~ s/\r\n/\n/g;
        $options{content} =~ s/\r/\n/g;
        return if $options{content} eq $latest->version_content->content;
        $mimetype = $options{tex} ? 'application/x-tex' : 'text/plain';
        $content  = $options{content};
    }
    else {
        $mimetype     = $options{file}->type;
        $content_blob = $options{file}->content;
        $options{file}->basename =~ /.*\.([a-z0-9]+)/i;
        $ext = $1;
    }

    my $version = $self->schema->resultset('Version')->create({
        doc_id   => $self->id,
        major    => $latest->major,
        minor    => $latest->minor + 1,
        revision => 0,
        created  => DateTime->now,
        blobext  => $ext,
        mimetype => $mimetype,
    });
    $self->schema->resultset('VersionContent')->create({
        id           => $version->id,
        content      => $content,
        content_blob => $content_blob,
    });
    $guard->commit;
}

sub file_add
{   my ($self, $file) = @_;
    my %options = (
        file => $file,
    );
    $self->_version_add(%options);
}

sub plain_add
{   my ($self, $text) = @_;
    my %options = (
        text    => 1,
        content => $text,
    );
    $self->_version_add(%options);
}

sub tex_add
{   my ($self, $text) = @_;
    my %options = (
        tex     => 1,
        text    => 1,
        content => $text,
    );
    $self->_version_add(%options);
}

sub as_string
{   my $self = shift;
    $self->surname.", ".$self->firstname;
}

sub as_integer
{   my $self = shift;
    $self->id;
}

1;

