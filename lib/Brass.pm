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

any '/issue/?:id?' => require_any_role [qw(issue_read issue_read_all)] => sub {

    my $id      = param 'id';
    my $schema  = schema('issue');
    my $users   = Brass::Users->new(schema => schema); # Default schema
    my $issues  = Brass::Issues->new(schema => $schema, users => $users);

    my $params = {
        issues     => $issues->all,
        priorities => Brass::Issue::Priorities->new(schema => $schema)->all,
        statuses   => Brass::Issue::Statuses->new(schema => $schema)->all,
        types      => Brass::Issue::Types->new(schema => $schema)->all,
        projects   => Brass::Issue::Projects->new(schema => $schema)->all,
        page       => 'issue',
    };

    if ($id)
    {
        my $issue = Brass::Issue->new(id => $id, users => $users, schema => $schema);
        if (param 'save')
        {
            $issue->title(param 'title');
            $issue->description(param 'description');
            $issue->security(param 'security');
            $issue->set_type(param 'type');
            $issue->set_project(param 'project');
            $issue->set_status(param 'status');
            $issue->set_priority(param 'priority');
            $issue->write(logged_in_user->{id});
        }
        if (param 'comment_add')
        {
            $issue->comment_add(text => param('comment'), user_id => logged_in_user->{id});
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

    if (my $submit = param 'submit')
    {
        $doc->title(param 'title');
        $doc->set_topic(param 'topic');
        $doc->multiple(param 'multiple');
        $doc->write;
        redirect '/doc';
    }

    template 'doc_edit' => {
        doc    => $doc,
        topics => [$topics->all],
        page   => 'doc_edit',
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
        die "No permission to save draft"
            unless user_has_role('doc_save');
        $submit = 'draft' if $publish && $doctype ne 'binary';

        my $new_version_id = $submit eq 'save' && $doctype eq 'binary'
          ? $doc->file_save(request->upload('file'))
          : $publish && $doctype eq 'binary'
          ? param('binary_draft_id')
          : $submit eq 'save' && $doctype eq 'plain'
          ? $doc->plain_save(param 'text_content')
          : $submit eq 'save' && $doctype eq 'tex'
          ? $doc->tex_save(param 'text_content')
          : $submit eq 'draft' && $doctype eq 'binary'
          ? $doc->file_add(param 'text_content')
          : $submit eq 'draft' && $doctype eq 'plain'
          ? $doc->plain_add(param 'text_content')
          : $submit eq 'draft' && $doctype eq 'tex'
          ? $doc->tex_add(param 'text_content')
          : die "Invalid request";

        if ($publish)
        {
            my $user = Brass::User->new(schema => schema, id => logged_in_user->{id});
            $doc->publish($new_version_id, $user);
        }
        redirect '/doc';
    }

    template 'doc_content' => {
        doc  => $doc,
        page => 'doc_content',
    };
};

get '/doc/latest/:id' => require_role doc => sub {

    my $id     = param 'id';
    my $schema = schema('doc');
    my $doc    = Brass::Doc->new(
        id     => $id,
        schema => $schema,
    );

    redirect "/version/".$doc->published->id;
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
        $content     =~ s/%%thedate%%/$date/;
        $content     =~ s!%%thename%%!$title ($vinfo / $date / $reviewer / $approver / $classification)!;
        my $texdir   = config->{brass}->{tex};
        die "Tex build dir $texdir does not exist" unless -d $texdir;
        write_file("$texdir/$vinfo.tex", {binmode => ':utf8'}, $content);
        my $cmd = ["$texdir/xelatex", "-jobname=$vinfo", "-shell-escape", "$texdir/$vinfo.tex"];
        # run twice to ensure contents, page numbers etc are correct
        foreach my $i (1..2) {
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
