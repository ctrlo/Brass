#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Brass::Doc;
use Brass::Docs;
use Brass::DocSchema;
use Brass::User;
use Fcntl ':mode'; # For file mode constants
use Fuse qw(fuse_get_context);
use HTML::Scrubber;
use Log::Report mode => 'DEBUG';
use Mail::Message;
use POSIX qw(ENOENT EISDIR EINVAL);
use YAML::Syck qw/LoadFile/;

my $config   = LoadFile("$FindBin::Bin/../config.yml"); # Dancer config file
my $dbconfig = $config->{plugins}->{DBIC}->{doc};
my $schema   = Brass::DocSchema->connect($dbconfig);

# Default template for a directory's details
my $dir_template = {
    type  => S_IFDIR,
    mode  => 0644,
};

# ID for "receipts" topic in Brass
my $topic_id = $schema->resultset('Topic')->search({
    name => 'Rcpt'
})->next->id;

# Only keep one object, but we will clear this when a refresh is needed
my $docs = Brass::Docs->new(schema => $schema);

# The errors message, if there was an error for the last file upload
my $errors = {};

# Buffers to allow the OS to write to a file in chunks
my $buffers = {};

# All the files in the topic
sub tree
{
    my $files = {
        map {
            my $title = $_->title;
            $title =~ s!/!-!g;
            my $published = $_->published;
            my $status = $errors->{$_->id}
                ? $errors->{$_->id}
                : $published
                ? 'Last uploaded '.$published->created
                : 'None published';
            $status .= ' ('.$published->notes.')'
                if !$errors->{$_->id} && $published && $published->notes;
            $title => {
                doc_id => $_->id,
                status => $status,
                %$dir_template,
            }
        } $docs->topic($topic_id)
    };
    $files->{'.'} = $dir_template;
    return $files;
}

# Strip leading / (always passed by FUSE)
sub to_relative
{   my $file = shift;
    $file =~ s,^/,,;
    $file ||= '.';
    return $file;
}

sub fileinfo
{   my $name = to_relative shift;
    my $files = tree();
    if ($name =~ m!^([^/].*)/([^/].*)$!)
    {
        # File within directory requested (can only ever be one deep)
        my $dir = $1;
        $files->{$dir} or return;
        return +{
            file   => $2,
            dir    => $dir,
        }
    }
    elsif ($files->{$name}) {
        # Directory requested
        return +{
            dir    => $name,
        }
    }
}

# Standard return for getattr etc
sub _stat
{   my $mode = shift;
    my $size = 0;
    my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0, 0, 0, 0, 0, 0, 1, 1024000);
    my ($atime, $ctime, $mtime);
    $atime = $ctime = $mtime = time;
    return ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks);
}

sub e_getattr
{   my $info = fileinfo(shift) or return -ENOENT(); # Requested path doesn't exist
    trace "Entering e_getattr";
    my $files = tree();
    if (!$info->{file})
    {
        # Path requested. Send some info back to allow new files to be created
        my $dir = $info->{dir};
        my $mode = $files->{$dir}->{type} + $files->{$dir}->{mode};
        return _stat($mode);
    }
    elsif ($files->{$info->{dir}}->{status} eq $info->{file})
    {
        # Path and file exists. This is normally the status
        my $mode = S_IFREG + 0444;
        return _stat($mode);
    }
    else {
        # Valid path but file doesn't exist. Probably about to be created
        return -ENOENT();
    }
}

sub e_getdir
{   my $path = shift;
    trace "Entering e_getdir";
    my $files = tree();
    return keys %$files, 0 if $path eq '/'; # Main directory listing
    my $f = to_relative $path;
    # Otherwise return status file
    my $status = $files->{$f}->{status};
    return $status, 0;
}

sub e_open {
    trace "Entering e_open";
    my $file = to_relative(shift);
    my $info = fileinfo($file) or return -ENOENT();
    return -EISDIR() if !$info->{file};
    return 0;
}

sub e_read {
    trace "Entering e_read";
    my $file = to_relative(shift);
    my $info = fileinfo($file) or return -ENOENT();
    my $content = ''; # Could add content to status file if needed
    my ($buf, $off, $fh) = @_;
    # Most of this will only be used if $content has text
    return -EINVAL() if $off > length $content;
    return $content;
    return 0 if $off == length $content;
    return substr($content, $off, $buf);
}

# A general error routine used when writing a new file
sub write_error
{   my ($doc_id, $message) = @_;
    $errors->{$doc_id} = $message;
    $docs->clear;
    return 0; # This actually means success. Maybe change to an error code?
}

# This is called for chunks of data by the OS.
# We just write to the buffer until closed.
sub e_write
{   my ($pathname, $buffer, $offset, $fh) = @_;
    trace "Entering e_write";
    my $files  = tree();
    my $info   = fileinfo($pathname) or return -ENOENT();
    my $doc_id = $files->{$info->{dir}}->{doc_id};
    $buffers->{$doc_id} ||= '';
    substr($buffers->{$doc_id}, $offset) = $buffer; 
    return length $buffer;
}

# File is being closed. Get all the data and process it.
sub e_release
{   my $pathname = shift;
    trace "Entering e_release";
    my $info = fileinfo($pathname) or return -ENOENT();

    my $files  = tree();
    my $doc_id = $files->{$info->{dir}}->{doc_id};
    my $buffer = $buffers->{$doc_id};

    my $msg = Mail::Message->read($buffer);

    return write_error($doc_id, "Failed to parse email")
        unless $msg->timestamp && $msg->subject;

    # Every part in the email. Strip out images.
    # (sigh, broken email clients sending images as application/octet-stream)
    my @parts = grep {
        (!$_->body->dispositionFilename || $_->body->dispositionFilename !~ /\.jpg$/)
        && $_->contentType !~ m!application/pgp-signature!
        && $_->contentType !~ /^image/
    } $msg->parts('RECURSE');

    # See if we recognise this. We are quite restrictive to prevent rubbish being written.
    my $to_save; my $notes;
    if (my @unknown = grep { $_->contentType !~ m!^(text/plain|text/html|application/pdf)$! } @parts)
    {
        # We have something other than normal text or PDF
        # Remove any slashes so that mimetype can be displayed in status as filename
        my $unrecognised = join ', ', map { $_->contentType =~ s!/!-!r } @unknown;
        return write_error($doc_id, "Error: unrecognised mime types: $unrecognised");
    }
    elsif (my @pdfs =  grep { $_->contentType eq 'application/pdf' } @parts)
    {
        # More than one PDF
        return write_error($doc_id, "Error: more than one PDF in file")
            if @pdfs > 1;
        my ($pdf) = @pdfs;
        $to_save = {
            mimetype => 'application_pdf',
            content  => $pdf->decoded->string,
            ext      => 'pdf',
        };
        $notes = $1
            if $pdf->body->dispositionFilename =~ /STATEMENT([0-9]+)/;
    }
    else {
        # Must be email with both/either plain/html parts.
        # Save the whole email
        $to_save = {
            mimetype => 'application/mbox',
            content  => $msg->string,
            ext      => 'mbox',
        };
    }

    my $doc = Brass::Doc->new(
        schema => $schema,
        id     => $doc_id,
    );

    my $subject = $msg->study('subject');

    $subject
        or return write_error($doc_id, "Error: message has no subject");
    my $notes_temp;
    if ($notes)
    {
        # Do nothing, already parsed
    }
    elsif ($subject =~ /receipt\h+#?([a-z0-9]+)(\h|\.|\z)+/i && ($notes_temp = $1) && $notes_temp =~ /[0-9]+/ && $notes_temp =~ /[a-z]+/i)
    {
        $notes = $notes_temp;
    }
    elsif ($subject =~ /invoice\h+#?([a-z0-9]+)(\h|\.|\z)+/i)
    {
        $notes = $1;
    }
    elsif (my ($text) = grep { $_->contentType eq 'text/plain' || $_->contentType eq 'text/html' } @parts)
    {
        my $scrubber = HTML::Scrubber->new(allow => [qw/br/]);
        my $plain;
        if ($text->contentType eq 'text/html')
        {
            $plain = $scrubber->scrub($text->decoded->string);
            # Convert BR to new lines. I thought there'd be a module to do this, but couldn't find one.
            # Hopefully this will catch everything.
            $plain =~ s,<\s*br\s*/?>,\n,gi;
        }
        else {
            $plain = $text->decoded;
        }
        if ($plain =~ /transaction id:\s*([a-z0-9]+)/i)
        {
            $notes = $1;
            if ($plain =~ /description:\h+(.*)/i)
            {
                $notes .= " - $1";
            }
            else {
                $notes .= " - $subject";
            }
        }
        elsif ($plain =~ /^service:\h*(.*)$/im)
        {
            $notes = $1;
        }
        $notes
            or return write_error($doc_id, "Error: failed to retrieve receipt details from email content");
    }
    else {
        return write_error($doc_id, "Error: failed to retrieve invoice or receipt number from subject");
    }

    delete $errors->{$doc_id}; # Clear any previous write errors
    delete $buffers->{$doc_id};
    my $user = Brass::User->new(schema => $schema, id => 1);
    $doc->record_save(
        file     => $to_save->{content},
        mimetype => $to_save->{mimetype},
        ext      => $to_save->{ext},
        user     => $user,
        notes    => $notes,
        datetime => DateTime->from_epoch(epoch => $msg->timestamp),
    );

    $docs->clear;

    return 0;
}

# Various functions. Most of these are needed to prevent errors but aren't actually used
sub e_create     { trace "Entering e_create"; return 0 }
sub e_statfs     { trace "Entering e_statfs";  return 255, 1, 1, 1, 10 * 1024 * 1024, 2 } # Allow 10MB files
sub e_init       { trace "Entering e_init"; 0 }
sub e_access     { trace "Entering e_access"; 0 }
sub e_opendir    { trace "Entering e_opendir"; 0 }
sub e_readdir    { trace "Entering e_readdir"; 0 }
sub e_releasedir { trace "Entering e_releasedir"; 0 }
sub e_fgetattr   { trace "Entering e_fgetattr"; return _stat(S_IFREG + 0444) }
sub e_mknod      { trace "Entering e_mknod"; 0 }
sub e_flush      { trace "Entering e_flush"; 0 }
sub e_truncate   { trace "Entering e_truncate"; 0 }
sub e_unlink     { trace "Entering e_unlink"; 0 }
sub e_fallocate  { trace "e_fallocate"; 0 }

@ARGV or error "Please specify mount point as first argument";
my $mountpoint = shift(@ARGV);

# Set up a loop to restart if fails, but report any failures
# A lot of functions are not used, but are kept here to catch
# if called and/or develop in the future
while (1)
{
    try {
        Fuse::main(
            mountpoint  =>$mountpoint,
            mountopts   => 'direct_io',
            getattr     =>"main::e_getattr",
            getdir      =>"main::e_getdir",
            open        =>"main::e_open",
            statfs      =>"main::e_statfs",
            read        =>"main::e_read",
            write       =>"main::e_write",
            create      =>"main::e_create",
            readlink    => 'main::e_readlink',
            mknod       => 'main::e_mknod',
            mkdir       => 'main::e_mkdir',
            unlink      => 'main::e_unlink',
            rmdir       => 'main::e_rmdir',
            symlink     => 'main::e_symlink',
            rename      => 'main::e_rename',
            link        => 'main::e_link',
        #    chmod      => 'main::e_chmod',
            chown       => 'main::e_chown',
            truncate    => 'main::e_truncate',
            utime       => 'main::e_utime',
        #    flush      => 'main::e_flush',
            release     => 'main::e_release',
            fsync       => 'main::e_fsync',
            setxattr    => 'main::e_setxattr',
        #    getxattr   => 'main::e_getxattr',
            listxattr   => 'main::e_listxattr',
            removexattr => 'main::e_removexattr',
        #    opendir    => 'main::e_opendir',
        #    readdir    => 'main::e_readdir',
        #    releasedir => 'main::e_releasedir',
            fsyncdir    => 'main::e_fsyncdir',
            init        => 'main::e_init',
            destroy     => 'main::e_destroy',
            access      => 'main::e_access',
            ftruncate   => 'main::e_ftruncate',
            fgetattr    => 'main::e_fgetattr',
        #    lock       => 'main::e_lock',
            utimens     => 'main::e_utimens',
            bmap        => 'main::e_bmap',
            ioctl       => 'main::e_ioctl',
            poll        => 'main::e_poll',
        #    write_buf  => 'main::e_write_buf',
        #    read_buf   => 'main::e_read_buf',
            flock       => 'main::e_flock',
            fallocate   => 'main::e_fallocate',
        );
    };
    $@->reportFatal(is_fatal => 0);
    sleep 10;
};

