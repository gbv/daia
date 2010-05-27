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
        'DateTime' => '0.52',
        'DateTime::Duration' => '0',
        'DateTime::Format::Duration' => '1.03',
        'Data::Validate::URI' => '0.05',
        'JSON' => '2.15',
        'LWP::Simple' => '1.4',
        'CGI' => '3.0',
        'URI' => '1.35',
        'XML::Simple' => '2.14',
        'IO::File' => 0,
        'IO::Scalar' => '1.126',
        'Carp::Clan' => '5.0',
    },
    EXE_FILES       => [ 
        'clients/daia', 
    ],
    depend          => {
        Makefile => '$(VERSION_FROM)'
    },
    dist => {
        TARFLAGS => 'cvhf' # additional 'h' to dereference symlinks
    }
);
