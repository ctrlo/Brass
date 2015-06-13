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
use Brass::User;
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

    my $output  = template 'myip' => {
        messages    => session('messages'),
        address     => request->address,
        page        => 'myip',
    };
    session 'messages' => [];
    $output;
};

get '/doc' => require_role doc => sub {

    my $schema  = schema('doc');
    my $docs    = Brass::Docs->new(schema => $schema);
    my $output  = template 'doc' => {
        docs        => $docs->all,
        messages    => session('messages'),
        page        => 'doc',
    };
    session 'messages' => [];
    $output;
};

get '/doc/latest/:id' => require_role doc => sub {

    my $schema = schema('doc');
    my ($doc) = $schema->resultset('Doc')->search({
        'me.id'                    => param('id'),
        'latest_published.created' => undef,
        'versions.record'          => 1,
    },{
        prefetch => [
            { versions => 'latest_published' },
        ],
    })->all;
    my ($version) = $doc->versions->all;

    redirect "/version/".$version->id;
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
    elsif ($version->mimetype eq 'application/x-tex') {

        my $filename = "$vinfo.pdf";
        my $title    = $version->doc->title;
        my $reviewer = Brass::User->new(schema => schema, id => $version->reviewer);
        my $approver = Brass::User->new(schema => schema, id => $version->approver);
        my $date     = $version->created->strftime("%e %B %Y");
        $date        =~ s/(\d+)/ordinate($1)/e;
        my $content  = $version->version_content->content;
        $content     =~ s/%%thedate%%/$date/;
        $content     =~ s!%%thename%%!$title ($vinfo / $date / $reviewer / $approver)!;
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
                $file_full,
                content_type => 'application/pdf',
                filename     => $filename,
                system_path  => 1,
            );
        }
        else
        {
            die "Failed to create tex output file";
        }


    }
    else {
        return send_file(
            \$version->version_content->content,
            content_type => 'text/plain',
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
