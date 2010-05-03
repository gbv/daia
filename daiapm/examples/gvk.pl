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
            $response->addMessage( "You OpenURL does not contain an ISBN, sorry" );
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

if (@records) { 
  foreach my $record (@records) {
    my $ppn = $record->ppn;
    my $document = document( id => "gvk:ppn:$ppn", href => "http://gso.gbv.de/DB=2.1/PPNSET?PPN=$ppn" );

    foreach my $holding ( $record->holdings  ) {
        my $iln = $holding->sf('101@$a');
        my $department = department( id => "gvk:iln:$iln" );

        foreach my $copy ( $holding->items ) {

            # get the library name as department
            if ( 1 ) { #not $department->content ) {
                my $name = $holding->sf('101@$d');
                utf8::encode($name);
                $department->content($name);
            }

            my $epn = $copy->epn;
            my $item = item( id => "gvk:epn:$epn", department => $department );

            #my $label = $copy->sf('209A/..$a');
            #$item->label( $label ) if defined $label;
            #my $stor = $copy->sf('209A/..$f');
            #$item->storage( storage( $stor ) ) if defined $stor;

            #my $msg = $copy->sf('237A/..$a');
            #$item->message( 'de' => $msg ) if $msg;

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
