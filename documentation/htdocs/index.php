<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"> 
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"> 
  <head> 
    <meta http-equiv="content-type" content="text/html; charset=utf-8" /> 
    <meta name="description" content="The Document Availability Information data model (DAIA) describes the current availability of documents in libraries and similar institutions. Availability can be expressed in terms of specific services." />
    <title>Document Availability Information (DAIA) Sourceforge project</title> 
    <style type="text/css"> 
body { font-family: sans-serif; }
a { text-decoration: none; }
a:hover { text-decoration: underline; }
/*#main { float:left; }*/
#sidebar { float: right;  width: 40%; padding-left: 1em; background: #fff; border-left: 1px solid #666; }
#footer { border-top: 1px solid #666; padding-top: 5px; }
.rss { background:transparent url(rss14x14.png) center left no-repeat; width: 14px; height: 14px; text-indent: -7000em; }
    </style>
  <body>
<h1>Document Availability Information (DAIA) Sourceforge project</h1>
<?php

function show_feed( $url, $title, $link ) {
  if ($xml = simplexml_load_file($url,'SimpleXMLElement',LIBXML_NOCDATA)) {
    echo "<h3><a href='$link'>$title</a>&#xA0;&#xA0;<a alt='subscribe' class='rss' href='$url'>&#xA0;&#xA0;&#xA0;</a></h3>";
    foreach ( $xml->channel->item as $item ) {
        $title = $item->title;
        $link = htmlspecialchars($item->link);
        $date = htmlspecialchars($item->pubDate);
        $description = $item->description;
//var_dump($item);
        print "<div><a href='$link' class='title'>" . htmlspecialchars($title) . "</a> ";
        if ( "$title" != "$description" )
 echo "<p>$description</p>";
        print "<span class='date'>$date</span>\n";
        print "</div>\n";
    }
  }
}

echo "<div id='sidebar'>";
show_feed(
  "https://sourceforge.net/api/file/index/project-id/317073/mtime/desc/rss",
  "Latest releases","https://sourceforge.net/projects/daia/files/"
);

show_feed(
  "http://sourceforge.net/export/rss2_projnews.php?group_id=317073",
  "Latest News",""
);  
?>
</div>
<div id="main">
<p>
  The Document Availability Information data model (DAIA) describes the current 
  availability of documents in libraries and similar institutions. 
  Availability can be expressed in terms of specific services.
<p>
<ul>
  <li><a href="http://sourceforge.net/projects/daia/">daia project page</a></li>
<li>
  DAIA data model
  <ul>
    <li><a href="http://purl.org/NET/DAIA">Specification</a></li>
    <li><a href="http://daia.svn.sourceforge.net/viewvc/daia/trunk/schemas/daia.xsd">XML Schema</a></li>
    <li><a href="http://purl.org/ontology/daia">OWL Ontology</a> (<a href="http://daia.svn.sourceforge.net/viewvc/daia/trunk/schemas/daia.owl.n3">RDF/N3</a>)</li>
  </ul>
</li>
  <li>Join the <a href="https://sourceforge.net/mailarchive/forum.php?forum_name=daia-devel">Mailing list</a></li>
  <li>Browse the <a href="http://daia.svn.sourceforge.net/viewvc/daia/trunk">SVN-repository</a> - always the current development</li>
  <li><a href="http://sourceforge.net/projects/daia/support">Get support</a></li> 
  <li>read <a href="http://www.gbv.de/wikis/cls/Verf%C3%BCgbarkeitsrecherche_mit_DAIA">a German introduction to DAIA</a></li>
  <li>Tools
    <ul><li><a href="http://ws.gbv.de/daia/validator/">DAIA validator</a></li></ul>
  </li>
  <li>
   <a href="http://wiki.code4lib.org/index.php/DAIA">DAIA extensions</a> - open discussion and collection if the Code4Lib wiki
  </li>
</ul> 
</p>
<p>
  DAIA in other projects:
  <a href="https://sourceforge.net/projects/vufind/">VuFind</a> contains
  <a href="http://vufind.svn.sourceforge.net/viewvc/vufind/trunk/web/Drivers/DAIA.php?view=markup">a DAIA driver</a>.
</p>
<p>
  To join this project, please contact the project administrators of this project, 
  as shown on the <a href="http://sourceforge.net/projects/daia/develop">project develop page</a>.
</p> 
<!--
TODO:
* Better Introduction
* The model (speficiation + schemas)
* links and literature: bibSonomy-Account
* Mailing list: latest entries
* show examples (DAIA notifyer,DAIA proxy (incl. logging)  etc.)
* show SVN commits
-->
</div>
<p id='footer'>
  This project is kindly hosted <a href="http://sourceforge.net/projects/daia">at SourceForge</a> since Apr 16, 2010.<br /> 
  <a href="http://sourceforge.net/projects/daia"><img src="http://sflogo.sourceforge.net/sflogo.php?group_id=317073&amp;type=13" width="120" height="30" alt="Get daia at SourceForge.net. Fast, secure and Free Open Source software downloads" /></a>
</p>
</body>
</html>
