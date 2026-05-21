package Brass::Schema::Result::ApiKey;

use strict;
use warnings;
use utf8;

use base 'DBIx::Class::Core';

use Log::Report;

__PACKAGE__->load_components("InflateColumn::DateTime", "+Brass::DBIC");

__PACKAGE__->table("api_key");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "key",
  { data_type => "text", is_nullable => 1 },
  "kid",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "user",
  "Brass::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

# Allow the same user to have multiple keys. Because key IDs have to be unique
# (for Crypt::JWT), we need to provide another option other than using the
# user's username (the default).
sub key_id
{   my $self = shift;
    return $self->kid if $self->kid;
    $self->user->username;
}

1;
