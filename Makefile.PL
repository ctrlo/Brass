use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'Brass',
    AUTHOR              => q{Ctrl O <info@ctrlo.com>},
    VERSION_FROM        => 'lib/Brass.pm',
    ABSTRACT            => 'Ctrl-O Management System',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'agpl_3')
      : ()),
    # Install configdb.pl so that external scripts can use it.
    EXE_FILES           => [ 'bin/configdb.pl' ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Config::IniFiles'           => 0,
        'CtrlO::Crypt::XkcdPassword' => 0,
        'Crypt::CBC'                 => 0,
        'Crypt::JWT'                 => 0,
        'DateTime'                   => 0,
        'File::HomeDir'              => 0,
        'Getopt::Long'               => 0,
        'JSON'                       => 0,
        'Log::Report'                => 0,
        'LWP::Protocol::https'       => 0,
        'LWP::UserAgent'             => 0,
        'Term::ReadKey'              => 0,
        'Test::More'                 => 0,
        'Text::Markdown'             => 0,
        'URI'                        => 0,
        'URI::QueryParam'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Brass-*' },
);
