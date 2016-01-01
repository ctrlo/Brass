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
use Brass::Config::Certs;
use Brass::Config::CertUses;
use Brass::Config::Domains;
use Brass::Config::Pwd;
use Brass::Config::Pwds;
use Brass::Config::Server;
use Brass::Config::Servers;
use Brass::Config::Server::Types;
use Brass::Config::UAD;
use Brass::Config::UADs;
use Brass::DB;
use Brass::Docs;
use Brass::DocDB;
use Brass::Issue::Priorities;
use Brass::Issue::Projects;
use Brass::Issue::Statuses;
use Brass::Issue::Types;
use Brass::Issues;
use Brass::Topics;
use Brass::User;
use Brass::Users;
use File::Slurp;
use IPC::ShellCmd;
use Lingua::EN::Numbers::Ordinate;

use Dancer2;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Auth::Extensible;

our $VERSION = '0.1';

schema('doc')->storage->debug(1);

hook before => sub {

    # Static content
    return if request->uri =~ m!^/(error|js|css|login|images|fonts)!;
    return if param 'error';

    my $db = Brass::DocDB->new(schema => schema('doc'));
    $db->setup;
    $db = Brass::DB->new(schema => schema);
    $db->setup;
};

hook before_template => sub {
    my $tokens = shift;
    $tokens->{user}     = logged_in_user;
    $tokens->{messages} = session('messages');
    session 'messages' => [];
};

get '/' => sub {
    template 'index' => {
        page        => 'index'
    };
};

any '/upload' => sub {

    if (param 'submit')
    {
        my $file = request->upload('file');
        $file->copy_to(config->{brass}->{file_upload}."/".$file->filename);
        forwardHome({ success => "Thank you, the file has been sent"});
    }

    template 'upload' => {
        page        => 'upload'
    };
};

get '/myip' => sub {

    template 'myip' => {
        address     => request->address,
        page        => 'myip',
    };
};

any '/config/server/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema('config');

    my $params = {
        servers   => Brass::Config::Servers->new(schema => $schema)->all,
        domains   => Brass::Config::Domains->new(schema => $schema)->all,
        types     => Brass::Config::Server::Types->new(schema => $schema)->all,
        certs     => Brass::Config::Certs->new(schema => $schema)->all,
        cert_uses => Brass::Config::CertUses->new(schema => $schema)->all,
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
            $server->set_types(param 'type');
            $server->set_sites(param 'sites');
            $server->notes(param 'notes');
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

any '/config/uad/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema('config');
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

any '/config/pwd/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema('config');
    my $users   = Brass::Users->new(schema => schema); # Default schema
    my $uads    = Brass::Config::UADs->new(schema => $schema, users => $users);
    my $servers = Brass::Config::Servers->new(schema => $schema);

    my $params = {
        pwds   => Brass::Config::Pwds->new(
            schema  => $schema,
            servers => $servers,
            uads    => $uads,
        )->all,
        page   => 'config/pwd',
    };

    if (defined $id)
    {
        my $pwd = Brass::Config::Pwd->new(
            id      => $id,
            schema  => $schema,
            uads    => $uads,
            servers => $servers,
        );
        if (param 'save')
        {
            die "No permission to update password details"
                unless user_has_role 'config_write';
            my $strp = DateTime::Format::Strptime->new(
                pattern   => '%F',
            );
            $pwd->type(param 'type');
            $pwd->username(param 'username');
            $pwd->last_changed($strp->parse_datetime(param 'last_changed'));
            $pwd->set_uad(param 'uad');
            $pwd->set_server(param 'server');
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
        $params->{pwd}     = $pwd;
        $params->{uads}    = $uads->all;
        $params->{servers} = $servers->all;
    }

    template 'config/pwd' => $params;
};

any '/config/cert/?:id?' => require_role 'config' => sub {

    my $id      = param 'id';
    my $schema  = schema('config');

    my $params = {
        certs     => Brass::Config::Certs->new(schema => $schema)->all,
        page      => 'config/cert',
    };

    if (defined $id)
    {
        my $cert = Brass::Config::Cert->new(id => $id, schema => $schema);
        if (param 'save')
        {
            die "No permission to save certificate"
                unless user_has_role 'config_write';
            $cert->cn(param 'cn');
            $cert->type(param 'type');
            $cert->set_expiry(param 'expiry');
            $cert->usedby(param 'usedby');
            $cert->filename(param 'filename');
            $cert->content(param 'content');
            $cert->write;
            redirect '/config/cert';
        }
        if (param 'delete')
        {
            die "No permission to save certificate"
                unless user_has_role 'config_write';
            $cert->delete;
            redirect '/config/cert';
        }
        $params->{cert} = $cert;
    }

    template 'config/cert' => $params;
};

any '/issue/?:id?' => require_any_role [qw(issue_read issue_read_project issue_read_all)] => sub {

    my $id      = param 'id';
    my $schema  = schema;
    my $users   = Brass::Users->new(schema => schema); # Default schema
    my $issues  = Brass::Issues->new(schema => $schema, users => $users);

    # Always copy the filtering session, to stop it being a cache for
    # user and project filtering
    my $filtering = { %{session('filtering') || {}} };
    if (param 'submit_filtering')
    {
        $filtering = {
            project  => param('filtering_project'),
            status   => param('filtering_status'),
            security => param('filtering_security'),
            type     => param('filtering_type'),
        };
        my $copy = { %$filtering };
        session 'filtering' => $copy;
    }

    if (user_has_role 'issue_read_all')
    {
        # No further filtering needed
    }
    elsif (user_has_role 'issue_read_project')
    {
        # Only show issues for user's projects
        $filtering->{project_user_id} = logged_in_user->{id};
    }
    else {
        # Only show own issues
        $filtering->{user_id} = logged_in_user->{id};
    }
    $issues->filtering($filtering);

    my $params = {
        issues     => $issues->all,
        filtering  => $filtering,
        priorities => Brass::Issue::Priorities->new(schema => $schema)->all,
        statuses   => Brass::Issue::Statuses->new(schema => $schema)->all,
        types      => Brass::Issue::Types->new(schema => $schema)->all,
        projects   => Brass::Issue::Projects->new(schema => $schema)->all,
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
            $issue->set_project(param 'project');
            $issue->set_priority(param 'priority');
            if (user_has_role 'issue_write_all')
            {
                # Can only write to these fields if write_all
                $issue->security(param 'security');
                $issue->set_type(param 'type');
                $issue->set_status(param 'status');
                $issue->set_author(param('author') || logged_in_user->{id});
                $issue->set_owner(param 'owner');
                $issue->set_approver(param 'approver');
            }
            else {
                $issue->set_author(logged_in_user->{id})
                    if !$id; # New
            }
            $issue->write(logged_in_user->{id});
            $issue->send_notifications(
                uri_base          => request->uri_base,
                logged_in_user_id => logged_in_user->{id},
            );
            redirect '/issue';
        }
        if (param 'comment_add')
        {
            # Allow any reader to add a comment
            $issue->comment_add(text => param('comment'), user_id => logged_in_user->{id});
            $issue->send_notifications(
                uri_base          => request->uri_base,
                logged_in_user_id => logged_in_user->{id},
            );
        }
        $params->{issue} = $issue;
    }

    template 'issue' => $params;
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

any '/doc/view/:id' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id     => $id,
        schema => $schema,
    );

    if (param 'retire')
    {
        die "Retiring a document requires the publishing permission"
            unless user_has_role('doc_publish');
        $doc->retire;
        redirect '/doc';
    }

    if (my $version_id = param 'retire_version')
    {
        die "Retiring a document requires the publishing permission"
            unless user_has_role('doc_publish');
        $doc->retire_version($version_id);
        redirect '/doc';
    }

    if (param 'review')
    {
        die "Setting review date requires the publishing permission"
            unless user_has_role('doc_publish');
        $doc->review(DateTime->now->add(months => 12));
        $doc->write;
        redirect '/doc';
    }

    template 'doc_view' => {
        doc  => $doc,
        page => 'doc_view',
    };
};

any '/doc/edit/:id' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id     => $id,
        schema => $schema,
    );

    my $topics = Brass::Topics->new(schema => $schema);
    my $classifications = Brass::Classifications->new(schema => $schema);

    if (my $submit = param 'submit')
    {
        $doc->title(param 'title');
        $doc->set_topic(param 'topic');
        $doc->set_classification(param 'classification');
        $doc->multiple(param 'multiple');
        $doc->write;
        redirect '/doc';
    }

    template 'doc_edit' => {
        doc             => $doc,
        topics          => [$topics->all],
        classifications => [$classifications->all],
        page            => 'doc_edit',
    };
};

any '/doc/content/:id' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id     => $id,
        schema => $schema,
    );

    if (my $submit = param 'submit')
    {
        my $doctype = param 'doctype';

        # Always set new option on publish. If the content
        # is exactly the same, a new one won't actually be created
        my $publish = $submit eq 'publish' ? 1 : 0;
        die "No permission to publish document"
            if $publish && !user_has_role('doc_publish');
        die "No permission to publish signed copy"
            if $doctype eq 'signed' && !user_has_role('doc_publish');
        die "No permission to publish record"
            if $doctype eq 'record' && !user_has_role('doc_record');
        die "No permission to save draft"
            unless user_has_role('doc_save');
        $submit = 'draft' if $publish && $doctype ne 'binary';

        my $user = Brass::User->new(schema => schema, id => logged_in_user->{id});
        my $notes = param 'notes';

        my $new_version_id = $submit eq 'save' && $doctype eq 'binary'
          ? $doc->file_save(upload => request->upload('file'), notes => $notes)
          : $doctype eq 'signed'
          ? $doc->signed_save(upload => request->upload('file'), user => $user, notes => $notes)
          : $doctype eq 'record'
          ? $doc->record_save(upload => request->upload('file'), user => $user, notes => $notes)
          : $publish && $doctype eq 'binary'
          ? param('binary_draft_id')
          : $submit eq 'save' && $doctype eq 'plain'
          ? $doc->plain_save(text => param('text_content'), notes => $notes)
          : $submit eq 'save' && $doctype eq 'tex'
          ? $doc->tex_save(text => param('text_content'), notes => $notes)
          : $submit eq 'draft' && $doctype eq 'binary'
          ? $doc->file_add(text => param('text_content'), notes => $notes)
          : $submit eq 'draft' && $doctype eq 'plain'
          ? $doc->plain_add(text => param('text_content'), notes => $notes)
          : $submit eq 'draft' && $doctype eq 'tex'
          ? $doc->tex_add(text => param('text_content'), notes => $notes)
          : die "Invalid request";

        $doc->publish($new_version_id, $user)
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

    my $id = $doc->signed ? $doc->signed->id : $doc->published->id;

    redirect "/version/".$id;
};

get '/version/:id' => require_role doc => sub {

    my $schema    = schema('doc');
    my ($version) = $schema->resultset('Version')->find(param 'id');
    my $vinfo     = $version->doc->topic->name
              . "-" . $version->doc->id
              . "-" . $version->major
              . "." . $version->minor
              . "." . $version->revision;
    if ($version->version_content->content_blob)
    {
        return send_file(
            \$version->version_content->content_blob,
            content_type => $version->mimetype,
            filename     => $vinfo.".".$version->blobext,
        );
    }
    elsif ($version->mimetype && $version->mimetype eq 'application/x-tex') {

        my $filename = "$vinfo.pdf";
        my $title    = $version->doc->title;
        my $reviewer = $version->reviewer ? Brass::User->new(schema => schema, id => $version->reviewer) : "Not reviewed";
        my $approver = $version->approver ? Brass::User->new(schema => schema, id => $version->approver) : "Not approved";
        my $classification = $version->doc->classification->name;
        my $date     = $version->created->strftime("%e %B %Y");
        $date        =~ s/(\d+)/ordinate($1)/e;
        my $content  = $version->version_content->content;
        $content     =~ s/%%thedate%%/$date/g;
        $content     =~ s!%%thename%%!$title ($vinfo / $date / $reviewer / $approver / $classification)!g;
        $content     =~ s!%%thereference%%!$vinfo!g;
        my $texdir   = config->{brass}->{tex};
        die "Tex build dir $texdir does not exist" unless -d $texdir;
        write_file("$texdir/$vinfo.tex", {binmode => ':utf8'}, $content);
        my $cmd = ["$texdir/xelatex", "-jobname=$vinfo", "-shell-escape", "$texdir/$vinfo.tex"];
        # run twice to ensure contents, page numbers etc are correct
        foreach my $i (1..3) {
            my $isc = IPC::ShellCmd->new($cmd);
            $isc->working_dir("$texdir");
            # Strange things happen with the formatting when using STDIN
            # $isc->stdin($content);
            $isc->run;
        }
        my $file_full = "$texdir/$filename";
        if (-e $file_full)
        {
            my $pdf_content = read_file($file_full);
            $version->update({
                blobext      => 'pdf',
            });
            $version->version_content->update({
                content_blob => $pdf_content,
            });
            # Delete all temp files
            unlink glob("$texdir/$vinfo.*");
            return send_file(
                \$version->version_content->content_blob,
                content_type => 'application/pdf',
                filename     => $filename,
            );
        }
        else
        {
            die "Failed to create tex output file";
        }


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
    if (my $message = shift)
    {
        my $text = ( values %$message )[0];
        my $type = ( keys %$message )[0];

        messageAdd($message);
    }
    my $page = shift || '';
    redirect "/$page";
}

sub messageAdd($) {
    my $message = shift;
    my $text    = ( values %$message )[0];
    my $type    = ( keys %$message )[0];
    my $msgs    = session 'messages';
    push @$msgs, { text => $text, type => $type };
    session 'messages' => $msgs;
}

true;
