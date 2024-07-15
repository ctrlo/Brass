=pod
Brass
Copyright (C) 2014 Ctrl O Ltd

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

package Brass;

use Brass::Classifications;
use Brass::Config::Domains;
use Brass::Config::Pwd;
use Brass::Config::Pwds;
use Brass::Config::Server;
use Brass::Config::Servers;
use Brass::Config::Server::Types;
use Brass::Config::UAD;
use Brass::Config::UADs;
use Brass::CurrentUser;
use Brass::Docs;
use Brass::DocDB;
use Brass::Image;
use Brass::Issue::Priorities;
use Brass::Issue::Projects;
use Brass::Issue::Statuses;
use Brass::Issue::Types;
use Brass::Issues;
use Brass::Topics;
use Brass::User;
use Brass::Users;
use CtrlO::Crypt::XkcdPassword;
use File::Slurp;
use File::Temp ();
use IPC::ShellCmd;
use LaTeX::Encode qw/latex_encode/;
use Lingua::EN::Numbers::Ordinate;
use Log::Report::DBIC::Profiler;
use Session::Token;
use Sys::Hostname;
use Text::Markdown qw/markdown/;
use URI::Escape qw/uri_escape_utf8 uri_unescape/;

use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::LogReport;

use Brass::API;

our $VERSION = '0.1';

schema->storage->debugobj(new Log::Report::DBIC::Profiler);
schema->storage->debug(1);

Brass::CurrentUser->instance; # This singleton class always contains the current user making the request

my $password_generator = CtrlO::Crypt::XkcdPassword->new;

schema->resultset('Issuetype')->populate;

sub _update_csrf_token
{   session csrf_token => Session::Token->new(length => 32)->get;
}

hook before => sub {

    return if param 'error';

    if (!session 'csrf_token')
    {
        _update_csrf_token();
    }

    if (request->is_post)
    {
        # Protect against CSRF attacks
        panic __x"csrf-token missing for path {path}", path => request->path
            if !param 'csrf_token';
        error __x"Suspected attack: CSRF token does not match that in the session"
            if param('csrf_token') ne session('csrf_token');

        # If it's a potential login, change the token
        _update_csrf_token()
            if request->path eq '/login';
    }

    # Hack to prevent Host Header Injection attacks. Ideally the host name
    # would be overridden, but this is not too easy as DPAE extracts it
    # directly from the submitted host for the password reset email
    error __x"Requested host name {host} does not match server name {server}",
        host => request->base->host, server => hostname
            if hostname ne request->base->host;

    my $user = Brass::CurrentUser->instance;
    $user->user(logged_in_user);

    header "X-Frame-Options" => "DENY"; # Prevent clickjacking

    my $db = Brass::DocDB->new(schema => schema('doc'));
    $db->setup;

    if ($user->user && $user->user->has_permission('user_admin'))
    {
        my $app = schema->resultset('App')->next;
        my $last_run = $app && $app->status_last_run;
        if ($last_run)
        {
            report WARNING => __x"Nightly cron status.pl has not run since {date}", date => $last_run
                if $last_run < DateTime->now->subtract(days => 2);
        }
        else {
            report WARNING => __"Nightly cron status.pl has not yet run";
        }
    }
};

hook before_template => sub {
    my $tokens = shift;
    $tokens->{user}       = logged_in_user;
    $tokens->{csrf_token} = session 'csrf_token';
};

get '/' => sub {
    template 'index' => {
        page        => 'index'
    };
};

post '/login/?:code?' => sub {

    my $username = body_parameters->get('username');

    if (body_parameters->get('submit_reset'))
    {
        if (my $username = param('username_reset'))
        {
            my $result = password_reset_send(username => $username);
            defined $result
                ? success(__('If the email address was valid then an email has been sent to it with a link to reset your password'))
                : report({is_fatal => 0}, ERROR => 'Failed to send a password reset link. Did you enter a valid email address?');
            redirect '/';
        }
    }

    if (body_parameters->get('confirm_reset')) {
        my $randompw = $password_generator->xkcd(words => 3, digits => 2);
        user_password code => route_parameters->get('code'), new_password => $randompw;
        return forward '/login', { new_password => $randompw }, { method => 'GET' };
    }

    # Check whether login limit reached
    my $lastfail  = DateTime->now->subtract(minutes => 15);
    my $lastfailf = schema->storage->datetime_parser->format_datetime($lastfail);
    my $fail      = schema->resultset('User')->search({
        username  => $username,
        failcount => { '>=' => 5 },
        lastfail  => { '>' => $lastfailf },
    })->count;

    my ($success, $realm);
    if (!$fail)
    {
        ($success, $realm) = authenticate_user(
            $username, body_parameters->get('password')
        );
    }
    if ($success) {
        app->change_session_id;
        session logged_in_user => params->{username};
        session logged_in_user_realm => $realm;
        schema->resultset('User')->find(logged_in_user->id)->update({
            failcount => 0,
            lastfail  => undef,
        });
        my $return_url = query_parameters->get('return_url') || '/';
        $return_url = uri_unescape($return_url);
        my $uri = URI->new($return_url);
        # Construct a URL using uri_for, which ensures that the correct base domain
        # is used (preventing open URL redirection attacks). The query needs to be
        # parsed and passed as an option, otherwise it is not encoded properly
        redirect request->uri_for($uri->path, $uri->query_form_hash);
    } else {

        my ($user) = schema->resultset('User')->search({
            username => $username,
        })->all;
        if ($user)
        {
            $user->update({
                failcount => $user->failcount + 1,
                lastfail  => DateTime->now,
            });
        }

        report {is_fatal=>0}, ERROR => "The username or password entered is incorrect";
        redirect '/login';
    }
};

get '/logout' => sub {
    app->destroy_session;
    forwardHome();
};

any ['get', 'post'] => '/upload' => sub {

    if (param 'submit')
    {
        my $file = request->upload('file');
        $file->copy_to(config->{brass}->{file_upload}."/".$file->filename)
            or error __"File upload has failed";
        forwardHome({ success => "Thank you, the file has been sent"});
    }

    template 'upload' => {
        company => config->{brass}->{company},
        page    => 'upload',
    };
};

get '/myip' => sub {

    template 'myip' => {
        address     => request->address,
        page        => 'myip',
    };
};

get '/users' => require_role 'user_admin' => sub {

    my $schema  = schema;

    template 'users' => {
        users => [$schema->resultset('User')->active->all],
        page  => 'user',
    };
};

get '/user_report' => require_role 'user_admin' => sub {

    my $schema     = schema;
    my $schema_doc = schema('doc');

    template 'user_report' => {
        users          => [$schema->resultset('User')->active->all],
        permissions    => [$schema->resultset('Permission')->active_users],
        servertypes    => [$schema->resultset('Servertype')->active_users],
        projects       => [$schema->resultset('Project')->active_users],
        topics         => [$schema_doc->resultset('Topic')->all],
        user_topics_rs => $schema->resultset('UserTopic'),
        page           => 'user',
    };
};

any ['get', 'post'] => '/user/:id' => require_role 'user_admin' => sub {

    my $id         = param 'id';
    my $schema     = schema;
    my $schema_doc = schema('doc');

    my $user = $id
        ? $schema->resultset('User')->active->find($id)
        : $schema->resultset('User')->new({});

    if (body_parameters->get('save'))
    {
        my $guard = $schema->txn_scope_guard;

        $user->firstname(body_parameters->get('firstname'));
        $user->surname(body_parameters->get('surname'));
        $user->username(body_parameters->get('username'));
        $user->email(body_parameters->get('username'));

        $user->insert_or_update;

        $user->update_permissions(body_parameters->get_all('permissions'));
        $user->update_projects(body_parameters->get_all('projects'));
        $user->update_servertypes(body_parameters->get_all('servertypes'));
        $user->update_docreadtypes(body_parameters->get_all('docreadtypes'));
        $user->update_topics(
            doc         => [body_parameters->get_all('doc')],
            doc_publish => [body_parameters->get_all('doc_publish')],
            doc_save    => [body_parameters->get_all('doc_save')],
            doc_record  => [body_parameters->get_all('doc_record')],
        );

        $guard->commit;

        logged_in_user->discard_changes if logged_in_user->id == $user->id; # Update for template
    }

    if (body_parameters->get('delete') && $id)
    {
        $user->update({
            deleted => DateTime->now,
        });
        redirect '/users';
    }

    template 'user' => {
        u            => $user,
        permissions  => [$schema->resultset('Permission')->all],
        projects     => [$schema->resultset('Project')->all],
        servertypes  => [$schema->resultset('Servertype')->all],
        docreadtypes => [$schema->resultset('Docreadtype')->all],
        topics       => [$schema_doc->resultset('Topic')->all],
        page         => 'user',
    };
};

any ['get', 'post'] => '/config/server/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema;

    my $params = {
        servers   => Brass::Config::Servers->new(schema => $schema)->all,
        domains   => Brass::Config::Domains->new(schema => $schema)->all,
        types     => Brass::Config::Server::Types->new(schema => $schema)->all,
        certs     => $schema->resultset('Cert'),
        cert_uses => $schema->resultset('CertUse'),
        page      => 'config/server',
    };

    if (defined $id)
    {
        my $server = Brass::Config::Server->new(id => $id, schema => $schema);
        if (param 'update_server_cert')
        {
            die "No permission to update server"
                unless user_has_role 'config_write';
            my $cert = $server->certs->{param 'server_cert_id'}
                || Brass::Config::Server::Cert->new(schema => $schema, server_id => $server->id);
            $cert->set_cert_id(param 'cert_id');
            $cert->set_use_id(param 'use_id');
            $cert->write;
            $server->certs->{$cert->id} = $cert; # In case it's new
        }
        if (param 'delete_server_cert')
        {
            die "No permission to update server"
                unless user_has_role 'config_write';
            my $cert = delete $server->certs->{param 'server_cert_id'};
            $cert->delete;
        }
        if (param 'save')
        {
            die "No permission to update server"
                unless user_has_role 'config_write';
            $server->name(param 'name');
            $server->set_domain(param 'domain');
            $server->sudo(param 'sudo');
            $server->metadata(param 'metadata');
            $server->set_types(param 'type');
            $server->set_sites(param 'sites');
            $server->notes(param 'notes');
            $server->local_ip(param 'local_ip');
            $server->is_production(param('is_production') ? 1 : 0);
            $server->write;
            redirect '/config/server';
        }
        if (param 'delete')
        {
            die "No permission to update server"
                unless user_has_role 'config_write';
            $server->delete;
            redirect '/config/server';
        }
        $params->{server} = $server;
    }

    template 'config/server' => $params;
};

any ['get', 'post'] => '/config/uad/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema;
    my $users   = Brass::Users->new(schema => schema); # Default schema

    my $params = {
        uads   => Brass::Config::UADs->new(schema => $schema, users => $users)->all,
        page   => 'config/uad',
    };

    if (defined $id)
    {
        my $uad = Brass::Config::UAD->new(
            id     => $id,
            schema => $schema,
            users  => $users,
        );
        if (param 'save')
        {
            die "No permission to update UAD"
                unless user_has_role 'config_write';
            $uad->name(param 'name');
            $uad->set_owner(param 'owner');
            $uad->purchased(param 'purchased');
            $uad->serial(param 'serial');
            $uad->write;
            redirect '/config/uad';
        }
        if (param 'delete')
        {
            die "No permission to update UAD"
                unless user_has_role 'config_write';
            $uad->delete;
            redirect '/config/uad';
        }
        $params->{uad}   = $uad;
        $params->{users} = $users->all;
    }

    template 'config/uad' => $params;
};

any ['get', 'post'] => '/config/pwd/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema;
    my $users   = Brass::Users->new(schema => schema); # Default schema
    my $uads    = Brass::Config::UADs->new(schema => $schema, users => $users);
    my $servers = Brass::Config::Servers->new(schema => $schema);

    my $params = {
        pwds   => Brass::Config::Pwds->new(
            schema      => $schema,
            all_servers => $servers,
            uads        => $uads,
        )->all,
        users => $users,
        page  => 'config/pwd',
    };

    if (defined $id)
    {
        my $pwd = Brass::Config::Pwd->new(
            id          => $id,
            schema      => $schema,
            uads        => $uads,
            all_servers => $servers,
        );
        if (param 'save')
        {
            die "No permission to update password details"
                unless user_has_role 'config_write';
            my $strp = DateTime::Format::Strptime->new(
                pattern   => '%F',
            );
            $pwd->type(param 'type');
            $pwd->user_id(param('user_id') || undef);
            $pwd->publickey(param 'publickey');
            $pwd->last_changed($strp->parse_datetime(param 'last_changed'));
            $pwd->set_uad(param 'uad');
            $pwd->servertypes([body_parameters->get_all('servertypes')]);
            $pwd->write;
            redirect '/config/pwd';
        }
        if (param 'delete')
        {
            die "No permission to update password details"
                unless user_has_role 'config_write';
            $pwd->delete;
            redirect '/config/pwd';
        }
        $params->{pwd}         = $pwd;
        $params->{uads}        = $uads->all;
        $params->{servers}     = $servers->all;
        $params->{servertypes} = [$schema->resultset('Servertype')->all];
    }

    template 'config/pwd' => $params;
};

any ['get', 'post'] => '/config/customer/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema;
    my $users   = Brass::Users->new(schema => schema); # Default schema

    my $params = {
        customers => [rset('Customer')->all],
        page      => 'config/customer',
    };

    if (defined $id)
    {
        my $customer = $id ? rset('Customer')->find($id) : rset('Customer')->new({});

        if (param 'save')
        {
            die "No permission to update customer details"
                unless user_has_role 'config_write';
            $customer->name(param 'name');
            $customer->authnames(param 'authnames');
            $customer->updated(DateTime->now);
            $customer->updated_by(logged_in_user->id);
            $customer->update_or_insert;
            forwardHome({ success => "The customer has been updated successfully" }, "config/customer" );
        }
        if (param 'delete')
        {
            die "No permission to update password details"
                unless user_has_role 'config_write';
            $customer->delete;
            forwardHome({ success => "The customer has been deleted successfully" }, "config/customer" );
        }
        $params->{customer} = $customer;
    }

    template 'config/customer' => $params;
};

any ['get', 'post'] => '/config/cert/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema;

    my $params = {
        certs     => [$schema->resultset('Cert')->all],
        page      => 'config/cert',
    };

    if (defined $id)
    {
        my $cert = $id ? $schema->resultset('Cert')->find($id)
            : $schema->resultset('Cert')->new({});
        if (param 'save')
        {
            die "No permission to save certificate"
                unless user_has_role 'config_write';
            $cert->cn(param 'cn');
            $cert->type(param 'type');
            $cert->expiry(param('expiry') || undef);
            $cert->description(param 'description');
            $cert->filename(param 'filename');
            $cert->file_user(param 'file_user');
            $cert->file_group(param 'file_group');
            $cert->content_cert(param 'content_cert');
            $cert->content_key(param 'content_key');
            $cert->content_ca(param 'content_ca');
            $cert->update_or_insert;
            redirect '/config/cert';
        }
        if (param 'delete')
        {
            die "No permission to save certificate"
                unless user_has_role 'config_write';
            $cert->delete_cert;
            redirect '/config/cert';
        }
        $params->{cert} = $cert;
    }

    template 'config/cert' => $params;
};

any ['get'] => '/calendar/' => require_any_role [qw(config)] => sub {

    my $schema  = schema;

    my $calendar = schema->resultset('Calendar')->search_rs({ user_id => logged_in_user->id});

    template 'calendars' => {
        calendar => $calendar,
        page     => 'calendar',
    };
};

any ['get', 'post'] => '/calendar/:id/' => require_any_role [qw(config)] => sub {

    my $schema  = schema;
    my $users   = Brass::Users->new(schema => schema); # Default schema

    my $id = route_parameters->get('id');

    my $calendar = $id
        ? schema->resultset('Calendar')->find($id)
        : schema->resultset('Calendar')->new({});

    if (body_parameters->get('send'))
    {
        $calendar->start(body_parameters->get('start'));
        $calendar->end(body_parameters->get('end'));
        $calendar->description(body_parameters->get('description'));
        $calendar->location(body_parameters->get('location'));
        $calendar->attendees(body_parameters->get('attendees'));
        $calendar->html(body_parameters->get('html'));
        $calendar->user_id(logged_in_user->id);
        # Go back to same page with invite details, in case wanting to send again
        forwardHome({ success => "The invite was sent successfully" }, "calendar/" )
            if process sub { $calendar->update_or_insert; $calendar->send };
    }

    template 'calendar' => {
        calendar => $calendar,
        page     => 'calendar',
    };
};

any ['get', 'post'] => '/issue/?:id?' => require_any_role [qw(issue_read issue_read_project issue_read_all)] => sub {

    my $id      = param 'id';
    my $schema  = schema;
    my $users   = Brass::Users->new(schema => schema); # Default schema
    my $issues  = Brass::Issues->new(schema => $schema, users => $users);

    my $statuses = Brass::Issue::Statuses->new(schema => $schema);
    my $default  = [ map { $_->id } grep { $_->name =~ /(new|open)/i } @{$statuses->all} ];

    # Always copy the filtering session, to stop it being a cache for
    # user and project filtering
    my $filtering = { %{session('filtering') || { status => $default }} };
    if (param 'submit_filtering')
    {
        my @tags     = body_parameters->get_all('filtering_tag');
        my @statuses = body_parameters->get_all('filtering_status');
        $filtering = {
            project  => param('filtering_project'),
            security => param('filtering_security'),
            type     => param('filtering_type'),
            owner    => param('filtering_owner'),
        };
        $filtering->{tag}    = [@tags] if @tags;
        $filtering->{status} = [@statuses] if @statuses;
        my $copy = { %$filtering };
        session 'filtering' => $copy;
    }

    if (my $sort = param('sort'))
    {
        session 'sort' => $sort;
    }

    if (user_has_role 'issue_read_all')
    {
        # No further filtering needed
    }
    elsif (user_has_role 'issue_read_project')
    {
        # Only show issues for user's projects
        $filtering->{project_user_id} = logged_in_user->id;
    }
    else {
        # Only show own issues
        $filtering->{user_id} = logged_in_user->id;
    }
    $issues->filtering($filtering);
    $issues->sort(session 'sort');

    my $params = {
        issues     => $issues->all,
        tags       => [rset('Tag')->all],
        filtering  => $filtering,
        priorities => Brass::Issue::Priorities->new(schema => $schema)->all,
        statuses   => $statuses->all,
        types      => Brass::Issue::Types->new(schema => $schema)->grouped,
        projects   => Brass::Issue::Projects->new(schema => $schema, user_id => logged_in_user->id)->all,
        users      => $users->all,
        page       => 'issue',
    };

    if (defined $id)
    {
        my $issue = Brass::Issue->new(id => $id, users => $users, schema => $schema);
        # Check user can read. Not sure that user would ever be writing
        # to an issue that they can't read, so stop here regardless
        die "No access to this issue"
            unless $issue->user_can_read(logged_in_user);
        if (param 'save')
        {
            die "No write access to this issue"
                unless $issue->user_can_write(logged_in_user);
            $issue->title(param 'title');
            $issue->description(param 'description');
            $issue->security_considerations(param 'security_considerations');
            $issue->rca(param 'rca');
            $issue->corrective_action(param 'corrective_action');
            $issue->target_date(param 'target_date');
            $issue->resources_required(param 'resources_required');
            $issue->success_description(param 'success_description');
            $issue->set_project(param 'project');
            $issue->set_priority(param 'priority');
            $issue->set_type(param 'type');

            if (param 'ajax')
            {
                $issue->set_related_issue(param 'related_issue');
                my $type = schema->resultset('Issuetype')->search({ identifier => 'preventative_action' })->next
                    or panic "Type missing";
                $issue->set_type($type->id);
            }

            if (user_has_role('issue_write_all') || user_has_role('issue_write_project'))
            {
                # Can only write to these fields if write_all
                $issue->set_status(param 'status');
                $issue->set_author(param('author') || logged_in_user->id);
                $issue->set_owner(param 'owner');
                $issue->set_approver(param 'approver');
                $issue->set_tags([body_parameters->get_all('tag')]);
            }
            else {
                if ($id)
                {
                    my $status = param 'status';
                    $status == 1 || $status == 3
                        or error "Invalid status for this user";
                    $issue->set_status($status);
                }
                else { # New and no proper write permissions
                    $issue->set_author(logged_in_user->id); # Default to current user
                    $issue->set_status(1); # Always new when user cannot set it themselves
                }
            }
            $issue->write(logged_in_user->id);
            $issue->send_notifications(
                is_new            => !$id,
                uri_base          => request->uri_base,
                logged_in_user_id => logged_in_user->id,
            );
            my $action = $id ? 'updated' : 'created';
            $id = $issue->id;
            return $issue->id if param 'ajax';
            forwardHome({ success => "The issue has been $action successfully" }, "issue/$id" );
        }
        if (param 'comment_add')
        {
            # Allow any reader to add a comment
            $issue->comment_add(text => param('comment'), user_id => logged_in_user->id);
            $issue->send_notifications(
                uri_base          => request->uri_base,
                logged_in_user_id => logged_in_user->id,
            );
        }
        if (param 'attach')
        {
            # Allow any user to attach a file
            my $file = request->upload('newattach')
                or error "Please select a file to upload";
            my $attach = {
                name        => $file->basename,
                issue       => $id,
                content     => $file->content,
                mimetype    => $file->type,
                datetime    => DateTime->now,
                uploaded_by => logged_in_user->id,
            };

            if (process sub { rset('File')->create($attach) })
            {
                forwardHome({ success => "The file has been attached successfully" }, "issue/$id" );
            }
        }
        $params->{issue} = $issue;
    }

    template 'issue' => $params;
};

get '/file/:file' => require_login sub {

    my $file = rset('File')->find(param 'file')
        or error __x"File ID {id} not found", id => param('file');

    my $issue_id = $file->get_column('issue');
    my $users    = Brass::Users->new(schema => schema);
    my $issue    = Brass::Issue->new(id => $issue_id, users => $users, schema => schema);

    if ($issue->user_can_read(logged_in_user))
    {
        my $data = $file->content;
        send_file( \$data, content_type => $file->mimetype, filename => $file->name );
    } else {
        forwardHome(
            { danger => 'You do not have permission to view this file' } );
    }
};

any ['get', 'post'] => '/docread' => require_role doc => sub {

    my $schema    = schema;
    my $docschema = schema('doc');

    if (my $doc_id = param('have_read_doc'))
    {
        my $read = {
            user_id    => logged_in_user->id,
            doc_id     => $doc_id,
            datetime   => DateTime->now,
            ip_address => request->remote_address,
        };
        if (process sub { $schema->resultset('UserDocread')->create($read) })
        {
            forwardHome({ success => "The document reading has been registered successfully" }, "docread" )
        }
    }

    my @doc_ids = map $_->doc_id, $schema->resultset('DocDocreadtype')->search({
        'user_docreadtypes.user_id' => logged_in_user->id,
    },{
        join => {
            docreadtype => 'user_docreadtypes',
        },
    })->all;
    my $docs    = $docschema->resultset('Doc')->search({
        id      => \@doc_ids,
        retired => undef,
    });
    template 'docread' => {
        docs        => [$docs->all],
        page        => 'docread',
    };
};

get '/doc' => require_role doc => sub {

    my $schema  = schema('doc');
    my $docs    = Brass::Docs->new(schema => $schema);
    my @topics  = Brass::Topics->new(schema => $schema)->all;
    my $topic_id = param('topic') || session('topic') || $topics[0]->id;
    session 'topic', $topic_id;
    template 'doc' => {
        docs        => [$docs->topic($topic_id)],
        topic_id    => $topic_id,
        topics      => \@topics,
        page        => 'doc',
    };
};

any ['get', 'post'] => '/doc/view/:id' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id     => $id,
        schema => $schema,
    );

    $doc->user_can('read')
        or error "Sorry, you do not have access to this documentation topic";

    if (param 'retire')
    {
        error "Retiring a document requires the publishing permission"
            unless $doc->user_can('publish');
        $doc->retire;
        redirect '/doc';
    }

    if (my $version_id = param 'retire_version')
    {
        error "Retiring a document requires the publishing permission"
            unless $doc->user_can('publish');
        $doc->retire_version($version_id);
        redirect '/doc';
    }

    if (param 'review')
    {
        error "Setting review date requires the publishing permission"
            unless $doc->user_can('publish');
        $doc->review(DateTime->now->add(months => 12));
        $doc->write;
        redirect '/doc';
    }

    template 'doc_view' => {
        doc  => $doc,
        page => 'doc_view',
    };
};

any ['get', 'post'] => '/doc/send/:id' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id           => $id,
        schema       => $schema,
        schema_brass => schema,
    );

    error "You do not have permission to view this document"
        unless $doc->user_can('read');

    if (param 'send')
    {
        $doc->send(to => param('email'), from => config->{brass}->{email}->{from}, uri_base => request->uri_base);
        forwardHome({ success => "Thank you, a link to the file has been sent via email" }, "doc/view/$id");
    }

    template 'doc_send' => {
        doc  => $doc,
        page => 'doc_send',
    };
};

any ['get', 'post'] => '/doc/download/:code' => sub {

    my $code = param 'code';

    my $from = schema->storage->datetime_parser
        ->format_datetime(DateTime->now->subtract(days => 1));
    my $docsend = schema->resultset('Docsend')->search({
        code    => $code,
        created => { '>' => $from }, # Only last 24 hours
    })->next
        or error "Document not found";

    $docsend->download_time
        and error "This document has already been downloaded";

    my $doc    = Brass::Doc->new(
        id     => $docsend->doc_id,
        schema => schema('doc'),
    );

    if (param 'download')
    {
        $docsend->update({
            download_time       => DateTime->now,
            download_ip_address => request->remote_address,
        });

        my $version_id = $doc->signed
            ? $doc->signed->id
            : $doc->published
            ? $doc->published->id
            : $doc->draft->id;
        my $version    = schema('doc')->resultset('Version')->find($version_id);

        _send_doc($doc, $version);
    }

    template 'doc_download' => {
        doc  => $doc,
        page => 'doc_download',
    };
};

any ['get', 'post'] => '/doc/edit/:id' => require_role doc => sub {

    my $id        = param 'id';
    my $schema    = schema;
    my $docschema = schema('doc');
    my $doc       = Brass::Doc->new(
        id           => $id,
        schema       => $docschema,
        schema_brass => $schema,
    );

    !$id || $doc->user_can('read')
        or error "Sorry, you do not have access to this documentation topic";

    my $topics = Brass::Topics->new(schema => $docschema);
    my $classifications = Brass::Classifications->new(schema => $docschema);

    if (my $submit = param 'submit')
    {
        error "Editing a document's properties requires the document save permission"
            unless !$id || $doc->user_can('save');
        $doc->title(param 'title');
        $doc->set_topic(param 'topic');
        $doc->set_classification(param 'classification');
        $doc->docreadtypes([body_parameters->get_all('docreadtypes')]);
        $doc->multiple(param 'multiple');
        $doc->write;
        redirect '/doc';
    }

    template 'doc_edit' => {
        doc             => $doc,
        topics          => [$topics->all],
        classifications => [$classifications->all],
        docreadtypes    => [$schema->resultset('Docreadtype')->all],
        page            => 'doc_edit',
    };
};

any ['get', 'post'] => '/doc/content/:id' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id     => $id,
        schema => $schema,
    );

    # First check for read
    $doc->user_can('read')
        or error "Sorry, you do not have access to this documentation topic";

    if (my $submit = param 'submit')
    {
        my $doctype = param 'doctype';
        my $user    = logged_in_user;

        if ($submit eq 'publish')
        {
            error "No permission to review document"
                if !$doc->user_can('publish');
            $doc->publish($user);
            redirect '/doc';
        }
        elsif ($submit eq 'revert')
        {
            error "No permission to revert document"
                if !$doc->user_can('publish');
            $doc->revert($user);
            redirect '/doc';
        }

        # Always set new option on publish. If the content
        # is exactly the same, a new one won't actually be created
        my $publish = $submit eq 'review' ? 1 : 0;
        error "No permission to publish document"
            if $publish && !$doc->user_can('publish');
        error "No permission to publish signed copy"
            if $doctype eq 'signed' && !$doc->user_can('publish');
        error "No permission to publish record"
            if $doctype eq 'record' && !$doc->user_can('record');
        error "No permission to save draft"
            if $doctype ne 'record' && !$doc->user_can('save');
        $submit = 'draft' if $publish && $doctype ne 'binary';

        my $notes = param 'notes';

        my $new_version_id = $submit eq 'save' && $doctype eq 'binary'
          ? $doc->file_save(upload => request->upload('file'), user => $user, notes => $notes)
          : $doctype eq 'signed'
          ? $doc->signed_save(upload => request->upload('file'), user => $user, notes => $notes)
          : $doctype eq 'record'
          ? $doc->record_save(upload => request->upload('file'), user => $user, notes => $notes)
          : $publish && $doctype eq 'binary'
          ? param('binary_draft_id')
          : $submit eq 'save' && $doctype eq 'plain'
          ? $doc->plain_save(text => param('text_content'), user => $user, notes => $notes)
          : $submit eq 'save' && $doctype eq 'tex'
          ? $doc->tex_save(text => param('text_content'), user => $user, notes => $notes)
          : $submit eq 'save' && $doctype eq 'markdown'
          ? $doc->markdown_save(text => param('text_content'), user => $user, notes => $notes)
          : $submit eq 'draft' && $doctype eq 'binary'
          ? $doc->file_add(text => param('text_content'), user => $user, notes => $notes)
          : $submit eq 'draft' && $doctype eq 'plain'
          ? $doc->plain_add(text => param('text_content'), user => $user, notes => $notes)
          : $submit eq 'draft' && $doctype eq 'tex'
          ? $doc->tex_add(text => param('text_content'), user => $user, notes => $notes)
          : $submit eq 'draft' && $doctype eq 'markdown'
          ? $doc->markdown_add(text => param('text_content'), user => $user, notes => $notes)
          : die "Invalid request";

        $doc->submit_review($user)
            if $publish;
        redirect '/doc';
    }

    template 'doc_content' => {
        doc  => $doc,
        page => 'doc_content',
    };
};

get '/doc/latest/:id' => require_role doc => sub {

    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id     => param('id'),
        schema => $schema,
    );

    my $id = $doc->current->id;

    # No need to check permissions here - will be done after redirect
    redirect "/version/".$id;
};

any ['get', 'post'] => '/doc/image/:id?' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $image;
    my $images;
    my $new = 1 if defined $id && $id == 0;
    if ($id)
    {
        $image = $schema->resultset('Image')->find($id);
    }
    elsif(!$new) {
        $images = [$schema->resultset('Image')->search({},{
            select => [qw/id doc_id title filename/]
        })->all];
    }

    if (defined param('download'))
    {
        return send_file(
            \$image->content,
            content_type => $image->mimetype,
            filename     => $image->filename,
        );
    }

    if (param 'submit')
    {
        my $i = {
            doc_id   => param('doc_id') || undef,
            title    => param('title'),
        };
        if (my $upload = request->upload('file'))
        {
            $i->{filename} = $upload->filename;
            $i->{mimetype} = $upload->type;
            $i->{content}  = $upload->content;
        }
        if ($image)
        {
            $image->update($i);
        }
        else {
            $schema->resultset('Image')->create($i);
        }
        redirect '/doc/image/';
    }

    template 'doc/image' => {
        new    => $new,
        image  => $image,
        images => $images,
        page   => 'doc/image',
    };
};

get '/version/:id' => require_role doc => sub {

    my $schema    = schema('doc');
    my ($version) = $schema->resultset('Version')->find(param 'id');

    my $doc    = Brass::Doc->new(
        id     => $version->doc->id,
        schema => $schema,
    );

    $doc->user_can('read')
        or error "Sorry, you do not have access to this documentation topic";

    _send_doc($doc, $version);
};

sub _send_doc
{   my ($doc, $version) = @_;

    my $schema    = schema('doc');
    my $classification = $version->doc->classification->name;
    $classification    =~ s/\s/\_/;
    my $vinfo     = $version->doc->topic->name
              . "-" . $version->doc->id
              . "-" . $version->major
              . "." . $version->minor
              . "." . $version->revision;
    my $filecore = "$vinfo-$classification";
    if ($version->version_content->content_blob)
    {
        my $mimetype = $version->mimetype;
        $mimetype = 'application/pdf' if $mimetype eq 'application/x-tex'; # Blob so must now be converted PDF
        return send_file(
            \$version->version_content->content_blob,
            content_type => $mimetype,
            filename     => $filecore.".".$version->blobext,
        );
    }
    elsif ($version->mimetype && $version->mimetype eq 'application/x-tex') {

        my $filename = "$filecore.pdf";
        my $title    = $version->doc->title;
        my $reviewer = $version->reviewer ? Brass::User->new(schema => schema, id => $version->reviewer) : "Not reviewed";
        my $approver = $version->approver ? Brass::User->new(schema => schema, id => $version->approver) : "Not approved";
        my $classification = $version->doc->classification->name;
        my $date     = $version->created->strftime("%e %B %Y");
        $date        =~ s/(\d+)/ordinate($1)/e;
        my $content  = $version->version_content->content;
        $content     =~ s/%%thedate%%/$date/g;
        my $setname  = latex_encode "$title ($vinfo / $date / $reviewer / $approver / $classification)";
        $content     =~ s!%%thename%%!$setname!g;
        $content     =~ s!%%thereference%%!$vinfo!g;
        # Escape any hashes not already escaped, unless document
        # defines not to do so
        $content     =~ s/(?<!\\)#/\\#/g
            unless $content =~ s/%%no_hash_escape%%//;
        my @images;
        while ($content =~ /%%image\.([0-9]+)(\[.*\])?%%/)
        {
            my $id = $1;
            my $options = $2;
            my $image = $schema->resultset('Image')->find($id);
            my ($ext) = $image->filename =~ /(\.[^.]+)$/;
            my $tempfile = File::Temp->new(SUFFIX => $ext);
            print $tempfile $image->content;
            push @images, $tempfile; # Stop temp file going out of scope immediately and being deleted
            $content =~ s/%%image\.$id\Q$options%%/\\includegraphics${options}{$tempfile}/g;
        }
        $content     =~ s/(?<!\\)%/\\%/g;
        my $texdir   = config->{brass}->{tex};
        die "Tex build dir $texdir does not exist" unless -d $texdir;
        write_file("$texdir/$filecore.tex", {binmode => ':utf8'}, $content);

        # xelatex and xdvipdfmx need to be in the texdir:
        # ln -s ../../../../usr/bin/xdvipdfmx
        # ln -s ../../../../usr/bin/xelatex
        my $xelatex = "$texdir/xelatex";
        -e $xelatex or panic "xelatex link is not correctly configured";
        my $cmd = ["$texdir/xelatex", "-jobname=$filecore", "-shell-escape", "$texdir/$filecore.tex"];
        # run twice to ensure contents, page numbers etc are correct
        my $failed;
        foreach my $i (1..3) {
            next if $failed;
            my $isc = IPC::ShellCmd->new($cmd);
            $isc->working_dir("$texdir");
            # Strange things happen with the formatting when using STDIN
            # $isc->stdin($content);
            $isc->run;
            $failed = $isc->status;
        }
        my $file_full = "$texdir/$filename";
        my $logfile   = "$texdir/$filecore.log";
        if ($failed || ! -e $file_full)
        {
            my $log = read_file($logfile);
            unlink glob("$texdir/$filecore.*");
            return template 'texerror' => {
                texlog => $log,
            };
        }
        my $pdf_content = read_file($file_full);
        $version->update({
            blobext      => 'pdf',
        });
        $version->version_content->update({
            content_blob => $pdf_content,
        });
        # Delete all temp files
        unlink glob("$texdir/$filecore.*");
        return send_file(
            \$version->version_content->content_blob,
            content_type => 'application/pdf',
            filename     => $filename,
        );
    }
    elsif ($version->mimetype && $version->mimetype eq 'text/markdown')
    {
        return template 'doc_markdown' => {
            doc       => $version->doc,
            markdown => markdown($version->version_content->content),
            page     => 'doc_markdown'
        };
    }
    else {
        my $txt = $version->version_content->content;
        utf8::encode($txt); # Strings cannot be passed to send_file with utf-8 chars
        return send_file(
            \$txt,
            content_type => 'text/plain; charset=utf-8',
            filename     => $version->id.".txt",
        );
    }
};

sub forwardHome {
    my ($message, $page, %options) = @_;

    if ($message)
    {
        my ($type) = keys %$message;
        my $lroptions = {};
        # Check for option to only display to user (e.g. passwords)
        $lroptions->{to} = 'error_handler' if $options{user_only};

        if ($type eq 'danger')
        {
            $lroptions->{is_fatal} = 0;
            report $lroptions, ERROR => $message->{$type};
        }
        else {
            report $lroptions, NOTICE => $message->{$type}, _class => 'success';
        }
    }
    $page ||= '';
    redirect "/$page";
}

true;
