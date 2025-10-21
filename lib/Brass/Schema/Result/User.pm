use utf8;
package Brass::Schema::Result::User;

use strict;
use warnings;
use utf8;

use base 'DBIx::Class::Core';

use Authen::OATH;
use Brass::Context;
use Convert::Base32 qw/encode_base32 decode_base32/;
use Cpanel::JSON::XS;
use HTTP::Request::Common;
use Imager::Color;
use Imager::QRCode;
use Log::Report;
use LWP::UserAgent;
use MIME::Base64 qw/decode_base64 encode_base64/;
use URI::Escape qw/uri_escape/;

__PACKAGE__->load_components("InflateColumn::DateTime", "+Brass::DBIC");

__PACKAGE__->table("user");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "deleted",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "pwchanged",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "pwresetcode",
  { data_type => "char", is_nullable => 1, size => 32 },
  "lastlogin",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "lastfail",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "failcount",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "api_key",
  { data_type => "text", is_nullable => 1 },
  # All the following for MFA
  "mfa_type",
  { data_type => "char", is_nullable => 1, size => 3 },
  "mobile",
  { data_type => "text", is_nullable => 1 },
  "mobile_verified",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "mfa_secret",
  { data_type => "text", is_nullable => 1 },
  "mfa_sms_token",
  { data_type => "text", is_nullable => 1 },
  "mfa_sms_created",
  {data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "mfa_token_previous",
  { data_type => "text", is_nullable => 1 },
  "mfa_token_previous_used",
  {data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "mfa_token_previous_key",
  { data_type => "text", is_nullable => 1 },
  "mfa_lastfail",
  {data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "mfa_failcount",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "comments",
  "Brass::Schema::Result::Comment",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "issue_approvers",
  "Brass::Schema::Result::Issue",
  { "foreign.approver" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "issue_authors",
  "Brass::Schema::Result::Issue",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "issue_owners",
  "Brass::Schema::Result::Issue",
  { "foreign.owner" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "issue_priorities",
  "Brass::Schema::Result::IssuePriority",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "issue_statuses",
  "Brass::Schema::Result::IssueStatus",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "docreads",
  "Brass::Schema::Result::UserDocread",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_docreadtypes",
  "Brass::Schema::Result::UserDocreadtype",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_permissions",
  "Brass::Schema::Result::UserPermission",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_projects",
  "Brass::Schema::Result::UserProject",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_servertypes",
  "Brass::Schema::Result::UserServertype",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "pws",
  "Brass::Schema::Result::Pw",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "user_topics",
  "Brass::Schema::Result::UserTopic",
  { "foreign.user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub name
{   my $self = shift;
    return $self->firstname." ".$self->surname;
}

sub update_permissions
{   my ($self, @permission_ids) = @_;
    $self->user_permissions->delete; # lazy - should search first
    foreach my $permission_id (@permission_ids)
    {
        $self->create_related('user_permissions', {permission => $permission_id});
    }
}

sub update_projects
{   my ($self, @project_ids) = @_;
    $self->user_projects->delete; # lazy
    foreach my $project_id (@project_ids)
    {
        $self->create_related('user_projects', {project => $project_id});
    }
}

sub update_docreadtypes
{   my ($self, @docreadtype_ids) = @_;
    $self->user_docreadtypes->delete; # lazy
    foreach my $docreadtype_id (@docreadtype_ids)
    {
        $self->create_related('user_docreadtypes', {docreadtype_id => $docreadtype_id});
    }
}

sub update_servertypes
{   my ($self, @servertype_ids) = @_;
    $self->user_servertypes->delete; # lazy
    foreach my $servertype_id (@servertype_ids)
    {
        $self->create_related('user_servertypes', {servertype => $servertype_id});
    }
}

sub update_topics
{   my ($self, %params) = @_;
    $self->user_topics->delete; # lazy

    foreach my $topic_id (@{$params{doc}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
    foreach my $topic_id (@{$params{doc_publish}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc_publish',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
    foreach my $topic_id (@{$params{doc_save}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc_save',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
    foreach my $topic_id (@{$params{doc_record}})
    {
        my $permission = $self->result_source->schema->resultset('Permission')->search({
            name => 'doc_record',
        })->next;
        $self->create_related('user_topics', {topic => $topic_id, permission => $permission->id});
    }
}

sub has_permission
{   my ($self, $permission) = @_;
    (grep { $_->permission->name eq $permission } $self->user_permissions) ? 1 : 0;
}

sub has_project
{   my ($self, $project_id) = @_;
    (grep { $_->project->id == $project_id } $self->user_projects) ? 1 : 0;
}

sub has_docreadtype
{   my ($self, $docreadtype_id) = @_;
    (grep { $_->docreadtype_id == $docreadtype_id } $self->user_docreadtypes) ? 1 : 0;
}

sub must_read_doc
{   my ($self, $doc_id) = @_;
    (grep { $_->docreadtype->doc_docreadtypes->search({doc_id => $doc_id})->count } $self->user_docreadtypes) ? 1 : 0;
}

sub servertypes_as_string
{   my $self = shift;
    join ', ', map $_->servertype->name, $self->user_servertypes->all;
}

sub has_servertype
{   my ($self, $servertype_id) = @_;
    (grep { $_->servertype->id == $servertype_id } $self->user_servertypes) ? 1 : 0;
}

sub has_doc_any
{   my $self = shift;
    !!grep { $self->has_permission($_) } qw/doc doc_publish doc_save doc_record/;
}

sub has_topic_permission
{   my ($self, $topic_id, $permission) = @_;
    return 0 if !$self->has_doc_any;
    my @user_topics = $self->user_topics
        or return 1; # If not limited, user will have no topics
    (grep { $_->topic == $topic_id && $_->permission->name eq $permission } @user_topics) ? 1 : 0;
}

sub issue_permissions
{   my $self = shift;
    my @perms = grep { $_->permission->name =~ /issue_/ } $self->user_permissions;
    join ', ', map { $_->permission->description } @perms;
}

# All the following for MFA

sub need_mfa
{   my $self = shift;
    !! $self->mfa_type;
}

sub seed_key
{   my $self = shift;
    my $len_secret_bytes = 26;
    open my $RNG, '<', '/dev/urandom'
        or panic "Cannot open /dev/urandom for reading";
    sysread $RNG, my $secret_bytes, $len_secret_bytes
        or panic "Cannot read $len_secret_bytes from /dev/urandom";
    close $RNG
        or panic "Cannot close /dev/urandom";
    encode_base32($secret_bytes);
}

sub key_qr_base64
{   my ($self, $key) = @_;
    my $qrcode = Imager::QRCode->new(
        size          => 10,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
    );
    my $uri = "otpauth://totp/Brass".uri_escape($self->username)."?secret=".uri_escape($key || $self->mfa_secret)."&issuer=Brass";
    my $img = $qrcode->plot($uri);
    my $string;
    open my $fh, ">", \$string;
    $img->write(fh => $fh, type => 'png')
        or panic "Failed to write QR image";
    encode_base64 $string;
}

sub check_token
{   my ($self, $token, $secret) = @_;
    if ($self->mfa_type eq 'sms')
    {
        return 0 if !$self->mfa_sms_token; # Safety check in case both blank
        return 0 if $self->mfa_sms_created < DateTime->now->subtract(minutes => 15);
        return $token eq $self->mfa_sms_token;
    }
    else {
        my $oath = Authen::OATH->new;
        my $otp = $oath->totp(decode_base32 ($self->mfa_secret || $secret));
        return $otp eq $token;
    }
}

# Whether the user has recently verified MFA
sub recent_mfa
{   my ($self, $key_from_cookie) = @_;
    return 0 unless $key_from_cookie
        && $self->mfa_token_previous_used
        && ("$key_from_cookie" eq $self->mfa_token_previous_key);

    return 1 if $self->mfa_token_previous_used > DateTime->now->subtract(days => 7);
    return 0;
}

sub send_mfa_sms
{   my $self = shift;

    my $code = Session::Token->new(alphabet => [0..9], length => 6)->get;
    $self->update({ mfa_sms_token => $code, mfa_sms_created => DateTime->now });
    # Force utf-8 in SMS message - needed to route Chinese SMS via correct
    # route (advised by Twilio)
    my $message = __x"“{code}” is your Brass access code", code => $code;

    send_sms($self->mobile, $message);
}

sub need_mfa_setup
{   my $self = shift;
    return 0 if ($self->mfa_type eq 'otp' && $self->mfa_secret)
        || ($self->mfa_type eq 'sms' && $self->mobile && $self->mobile_verified);
    return 1;
}

sub need_mobile_verification
{   my $self = shift;
    # Need to use validate_mobile() here, otherwise this object may be used
    # when it has an invalid mobile number (following an unsuccessful
    # submission and validate error)
    if ($self->mobile && validate_mobile($self->mobile) && !$self->mobile_verified)
    {
        $self->send_mfa_sms;
        return 1;
    }
    return 0;
}

sub verify_mobile
{   my ($self, $token) = @_;
    if ($token eq $self->mfa_sms_token)
    {
        $self->update({ mobile_verified => 1 });
        return 1;
    }
    else {
        $self->update({ mobile => undef });
        return 0;
    }
}

sub reset_mfa
{   my $self = shift;
    $self->update({
        mobile                  => undef,
        mfa_secret              => undef,
        mfa_sms_token           => undef,
        mfa_sms_created         => undef,
        mfa_token_previous      => undef,
        mfa_token_previous_used => undef,
        mfa_token_previous_key  => undef,
        mfa_failcount           => 0,
    });
}

sub validate_mobile
{   my $mobile = shift;
    $mobile =~ /^\+[0-9]{4,}$/;
}

sub send_sms
{   my ($to, $body) = @_;

    my $sms_config = Brass::Context->sms_config;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $json = Cpanel::JSON::XS->new->utf8->encode({
        from     => $sms_config->{from},
        to       => $to,
        body     => "$body",
        encoding => 'UNICODE',
    });
    my $request = POST $sms_config->{url}, 'Content-Type' => 'application/json', Content => $json;

    $request->authorization_basic($sms_config->{username}, $sms_config->{password});

    my $response = $ua->request($request);

    my $return = try { decode_json $response->decoded_content };

    $return
        or panic "Failed to send SMS message - unknown response";

    # Assume that hash return means failed sending (success should return array
    # for each message status, see below)
    panic __x"Failed to send SMS message: {title} ({err})",
        title => $return->{title}, err => $return->{detail}
            if ref $return eq 'HASH';

    # See https://www.bulksms.com/developer/json/v1/#tag/Message%2Fpaths%2F~1messages%2Fpost
    # (type should be ACCEPTED on submission and will subsequently change)
    # Status of the first message
    $return->[0]->{status}->{type} eq 'ACCEPTED'
        or panic __"Failed to send SMS message - unknown reason";
}

sub validate
{   my $self = shift;

    !$self->mobile || validate_mobile($self->mobile)
        or error __x"The mobile number {number} is invalid. Please enter as international format (e.g. +1444555666)",
            number => $self->mobile;
}

1;
