use 5.8.2;
use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME            => 'DAIA',
    DISTNAME        => 'DAIA',
    VERSION_FROM    => 'lib/DAIA.pm',
    ABSTRACT_FROM   => 'lib/DAIA.pm',
    AUTHOR          => 'Jakob Voss <jakob.voss@gbv.de>',
    PREREQ_PM       => {
        # core modules
        'Carp' => 0,
        'CGI' => '3.0',
        'IO::File' => 0, 
        # additional modules
        'Carp::Clan' => '5.0',
        'DateTime' => '0.50',
        'DateTime::Duration' => '0',
        'DateTime::Format::Duration' => '1.03',
        'Data::Validate::URI' => '0.05',
        'IO::Scalar' => '1.126',
        'LWP::Simple' => '1.4',
        'JSON' => '2.15',
        'URI' => '1.35',
        'XML::Simple' => '2.14',
    },
    EXE_FILES       => [ 
        'clients/daia', 
    ],
    depend          => {
        Makefile => '$(VERSION_FROM)'
    },
    dist => {
        TARFLAGS => 'cvhf' # additional 'h' to dereference symlinks
    },
    META_MERGE => {
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://purl.org/NET/DAIA',
            repository => 'http://daia.sourceforge.net/',
        }
    }
);
