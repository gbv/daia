#!/usr/bin/perl

use strict;

=head1 NAME

gvk - Simple DAIA server for the GVK union catalog of GBV

=cut

use CGI qw(param self_url);
use PICA::Record;
use PICA::Source;
use DAIA qw(0.27);

=head1 DESCRIPTION

This is a simple (somehow crippled) DAIA server wrapped around the GBV 
union catalog GVK (L<http://gso.gbv.de/DB=2.1/>). It delivers document
and item information but little availability information so far. 

Individual libraries are treated as departments of the GBV so you can
look up which libraries in the GBV hold a given publication. For example
try this query string: C<?id=gvk:ppn:48574418X>.

If you install L<URI::OpenURL> this script also tries to act as a very
simplistic OpenURL target that searches for books by given ISBN. Try this

C<?ctx_ver=Z39.88-2004&rft_val_fmt=info:ofi/fmt:kev:mtx:book&rft.isbn=0-471-38393-7>

=cut

# you may need to change this to the location of the files at your server
my $xsltclient = "http://ws.gbv.de/daia/daia.xsl";
my $cssurl = "http://ws.gbv.de/daia/daia.css";


my $response = DAIA::Response->new( 
  institution => {
    href    => "http://gso.gbv.de/",
    content => "Gemeinsamer Verbundkatalog (GVK)" 
} );



my $ppn = param('id') || "";

if ($ppn) {
    if ( $ppn =~ /^\s*(gvk:ppn:)?([0-9]*[0-9x])\s*$/i ) {
        $ppn = lc($2);
    } else {
        $response->addMessage("Not a valid and known identifier type: $ppn");
        $ppn = "";
    }
}

my $gvk = PICA::Source->new( SRU => "http://gso.gbv.de/sru/DB=2.1" );
my @records;

my $query = "";

if ($ppn) {
    my $record = $gvk->getPPN( $ppn );
    push @records, $record if $record;
    $query = "PPN $ppn";
} else { 
    eval("use URI::OpenURL;");
    if (!$@) {
        my $openurl = URI::OpenURL->new(self_url());
        my (%metadata) = $openurl->referent->metadata();
        if ($metadata{isbn}) {
            my $isbn = $metadata{isbn};
            $isbn =~ s/[^0-9-xX]//g; # avoid CQL injection
            $query = "ISBN $isbn";
            @records = $gvk->cqlQuery("pica.isb=$isbn")->records();
        } else {
            $response->addMessage( "You OpenURL does not contain an ISBN or GVK-PPN, sorry" );
        }
    }
}

#### create and serve DAIA response

# multiple holdings as one
sub itemcount {
    my $item = shift;
    my $count = $item->sf('209A(/..)?$e');
    return $count > 1 ? $count : 1;
}

sub standorte {
}

if (@records) { 
  foreach my $record (@records) {
    my $ppn = $record->ppn;
    my $document = document( id => "gvk:ppn:$ppn", href => "http://gso.gbv.de/DB=2.1/PPNSET?PPN=$ppn" );

    foreach my $holding ( $record->holdings  ) {
        my $iln = $holding->sf('101@$a');
        my $department = department( id => "gvk:iln:$iln" );

        foreach my $copy ( $holding->items ) {
            my $item = item( id => 'gvk:epn:' . $copy->epn );

            # get the library name as department
            if ( 1 ) { #not $department->content ) {
                my $name = $holding->sf('101@$d');
                utf8::encode($name);
                $department->content($name);
            }
            $item->department( $department );

            #my $label = $copy->sf('209A/..$a');
            #$item->label( $label ) if defined $label;
            #my $stor = $copy->sf('209A/..$f');
            #$item->storage( storage( $stor ) ) if defined $stor;

            #my $msg = $copy->sf('237A/..$a');
            #$item->message( 'de' => $msg ) if $msg;

            my ($presentation, $loan, $interloan, $openaccess);

            # Signatur
            $item->label( $pica->subfield('209A/..','a') );

            # Standorte
            my $f = $pica->sf('209A/..$f');
            my @standard = standorte($f);
            my @orte;
            if (@standard) {
                @orte = grep { $_->isa('DAIA::Department') or $_->isa('DAIA::Storage') } @standard;
                ($presentation) = grep { $_->isa('DAIA::Availability') and $_->service eq 'presentation' } @standard;
                ($loan) = grep { $_->isa('DAIA::Availability') and $_->service eq 'loan' } @standard;
                ($interloan) = grep { $_->isa('DAIA::Availability') and $_->service eq 'interloan' } @standard;
                ($openaccess) = grep { $_->isa('DAIA::Availability') and $_->service eq 'openaccess' } @standard;
            } else {
                @orte = message( "Unbekannter Standortcode: $b $j $f", errno => -1 );
            }

            $item->add( @orte );

            # Allgemeine Verfügbarkeit
            my $ind = $pica->sf('209A/..$b');
            my $link = $pica->subfield('201@/..','l');

            if ( $ind =~ /[aogz]/ ) {
                $presentation = unavailable( "presentation" );
                $loan         = unavailable( "loan" );
                $interloan    = unavailable( "interloan" );
                $openaccess   = unavailable( "openaccess" );
            } elsif ( $ind =~ /[if]/ ) {
                $loan         = unavailable( "loan" );
                $openaccess   = unavailable( "openaccess" );
                $interloan    = unavailable( "interloan" ) if $ind eq 'i';
            } elsif ( $ind eq 'c' ) {
                $interloan    = unavailable( "interloan" );
            }

            # in Beabeitung
            if ( $f =~ /.:pb/ ) { # Präsenzbestand
                # TODO: was wenn gerade nicht da ?
                $presentation = available("presentation", href => $link );
            }

            #if (not defined $interloan) { # kommt irgendwann wieder
            #    $interloan = unavailable( service => "interloan", "expected" => "unknown" );
            #}
            #$openaccess = unavailable( "openaccess" ); # erstmal rausnehmen

            #$d AUSLEIHINDIKATOR
            if ( not defined $presentation or not defined $loan ) {
                my $status = wraploan( $link );
                if (ref($status)) { 
                    use Data::Dumper;
                    $item->addMessage( Dumper( $status ) );
                    if ($status->{storage} and not $item->storage) {
                        $item->storage( $status->{storage} );
                    }
                    if ($status->{status} eq "-") {
                        $presentation = available("presentation") unless defined $presentation;
                        $loan = available("loan") unless defined $loan;
                        if ( $item->storage and $item->storage->content =~ /Magazin/ ) {
                            $presentation->delay('PT30M');
                            $loan->delay('PT30M'); # 30 minuten
                        }
                        $interloan = available("interloan") unless defined $interloan;
                    } elsif ($status->{status} =~ /Lent till (\d\d)-(\d\d)-(\d\d\d\d)/) {
                        $presentation = unavailable("presentation", expected => "$3-$2-$1");
                        $loan = unavailable("loan", expected => "$3-$2-$1");
                        if ( $status->{queue} > 0 ) {
                            $presentation->queue( $status->{queue} );
                            $loan->queue( $status->{queue} );
                        }
                    } elsif ($status->{status} =~ /shortend loan period/ ) {
                        $presentation = available("presentation", limitation => $status->{status} );
                        $loan = available("loan", limitation => $status->{status} );
                    }
                } else {
                    $item->addMessage( $status );
                }
            }

            $presentation->href( $link ) if $presentation and not $presentation->href;
            $loan->href( $link ) if $loan and not $loan->href;

            my $count = itemcount($copy);
            foreach (1..$count) { # Mehrfachexemplare
                $document->add( $item );
            }

            # TODO: add availability information

        }
    }

    $response->add( $document );

  }
} else {
    if ($ppn) {
        $response->addMessage( "en" => "No title found in GVK with $query!" );
        $response->addMessage( "de" => "Es wurde kein Titel mit $query im GVK gefunden!" );
    } else {
        $response->addMessage( "en" => "Please specify something to let me find a document!" );
    }
}

# serve as required
$response->serve( xslt => $xsltclient, pi => "cssurl $cssurl" );
