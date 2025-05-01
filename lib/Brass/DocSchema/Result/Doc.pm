use utf8;
package Brass::DocSchema::Result::Doc;

use strict;
use warnings;

use Moo;

extends 'DBIx::Class::Core';

sub BUILDARGS { $_[2] || {} };

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("doc");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "topic_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "review",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "owner",
  { data_type => "integer", is_nullable => 1 },
  "classification",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "multiple",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "retired",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "classification",
  "Brass::DocSchema::Result::Classification",
  { id => "classification" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "images",
  "Brass::DocSchema::Result::Image",
  { "foreign.doc_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "topic",
  "Brass::DocSchema::Result::Topic",
  { id => "topic_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

__PACKAGE__->has_many(
  "versions",
  "Brass::DocSchema::Result::Version",
  { "foreign.doc_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

has published => (
    is => 'lazy',
);

sub _build_published
{   my $self = shift;
    my ($published) = $self->versions->search({
        doc_id => $self->id,
        minor  => 0,
        signed => 0,
    },{
        rows     => 1,
        order_by => { -desc => 'major' },
    })->all or return;
    $published->created;
}
# Last read date for a particular user
sub last_read
{   my ($self, $user) = @_;
    my $lr = $user->docreads->search({
        doc_id => $self->id,
    },{
        order_by => { -desc => 'me.datetime' },
        rows     => 1,
    })->next
        or return;
    my $dt = $lr->datetime;
    my $expiry = DateTime->now->subtract(years => 1);
    my $published = $self->published;
    my $status = $dt > $published && $dt > $expiry ? 'success'
        : $dt > $expiry ? 'warning'
        : 'danger';
    {
        date   => $dt,
        status => $status,
    }
}

1;
