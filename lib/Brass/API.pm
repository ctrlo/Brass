=pod
Brass
Copyright (C) 2021 Ctrl O Ltd

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

package Brass::API;

use strict; use warnings;

use Brass::Actions ();
use Brass::ConfigDB;
use Crypt::Blowfish;
use Crypt::JWT qw(decode_jwt);
use Crypt::PK::ECC;
use Dancer2 appname => 'Brass';
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use CtrlO::Crypt::XkcdPassword;
use Data::Password::Check;

# Special error handler for JSON requests (as used in API)
fatal_handler sub {
    my ($dsl, $msg, $reason) = @_;
    return unless $dsl && $dsl->app->request && $dsl->app->request->uri =~ m!^/api/!i;
    my $is_exception = $reason eq 'PANIC';
    status $is_exception ? 'Internal Server Error' : 'Bad Request';
    $dsl->send_as(JSON => {
        is_error => \1,
        message  => $is_exception ? 'An unexexpected error has occurred' : $msg->toString },
    { content_type => 'application/json; charset=UTF-8' });
};

hook before => sub {
    (my $request_token = request->header('Authorization')) =~ s/^Bearer\s+(.*)/$1/;

    return unless request->uri =~ m!^/api/!i;

    # Apache requires following config to passthrough auth header:
    # SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1
    $request_token
        or error __"No authorization header";

    # Load all available keys
    my @keys;
    foreach my $key (schema->resultset('User')->keys->all)
    {
        my $pubkey = Crypt::PK::ECC->new(\$key->api_key);
        my $jwk_hash = $pubkey->export_key_jwk('public', 1);
        $jwk_hash->{kid} = $key->username;
        push @keys, $jwk_hash;
    }

    my $keylist = {
        keys => \@keys
    };

    my ($header, $client);
    try { ($header, $client) = decode_jwt(token => $request_token, kid_keys => $keylist, decode_header => 1) };
    if ($@)
    {
        my $err = $@->wasFatal->message->toString;
        error __x"Unable to authenticate: {err}", err => $err;
    }

    var api_user => schema->resultset('User')->keys->search({ username => $header->{kid} })->next;
    var payload  => $client;
};

my $cdb = Brass::ConfigDB->new(is_local => 1, schema => schema);

get 'api/pwd/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $passphrase = var('payload')->{passphrase}
        or error __"Need passphrase for retrieving and setting passwords";

    my $pass = $cdb->run_pwd(
        server    => query_parameters->get('server'),
        pass      => query_parameters->get('pass'),
        action    => query_parameters->get('action'),
        param     => query_parameters->get('param'),
        pwdpass   => $passphrase,
    );

    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => $pass,
    });
};

get 'api/cert/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $return = $cdb->run_cert(
        server    => query_parameters->get('server'),
        action    => query_parameters->get('action'),
        param     => query_parameters->get('param'),
    );

    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => encode_json($return),
    });
};

get 'api/server/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $data = request->body;

    # Valid?
    my $decoded;
    if ($data)
    {
        try { $decoded = decode_json $data };
        error "Unable to decode request body data as JSON: $@"
            if $@;
    }

    my $return = $cdb->run_server(
        server  => query_parameters->get('server'),
        action  => query_parameters->get('action'),
        param   => query_parameters->get('param'),
        update  => $decoded,
    );

    $return = encode_json $return
        if ref $return;

    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => $return,
    });
};

get 'api/servertype/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $return = $cdb->run_servertype(
        action => query_parameters->get('action'),
        name   => query_parameters->get('name'),
    );

    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => encode_json($return),
    });
};

get 'api/site/' => sub {
    my $user = var 'api_user'
        or error __"Authentication required";

    my $return = $cdb->run_site(
        action => query_parameters->get('action'),
    );

    content_type 'application/json';
    encode_json({
        "is_error" => 0,
        "result"   => encode_json($return),
    });
};

