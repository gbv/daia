<?php
/*
 * Created on 08.03.2010
 *
 */

include_once 'pica2daia.php';

$doc = new DAIA_PICA(array($_REQUEST['ppn']));

$outputFormat = null;

if ($_REQUEST['format']) {
	$outputFormat = $_REQUEST['format'];
}
if ($_REQUEST['output']) {
	$outputFormat = $_REQUEST['output'];
}

switch ($outputFormat) {
    case 'xml': 
        // show as plain XML
        header('Content-Type: text/xml; charset=UTF-8');
        echo $doc->toXml();
        break;
    default:
        // Transform to HTML
        $_xml = new DomDocument;
        $_proc = new XSLTProcessor;
        // use the namespaced XML version by calling toXml with parameter true
        $_xml->loadXml($doc->toXml(true));

        $_xslt = new DomDocument;
        $_xslt->load('daia.xsl');
        $_proc->importStyleSheet($_xslt);

        echo $_proc->transformToXML($_xml);
}
?>
