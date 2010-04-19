<?php
/*
 * Created on 08.03.2010
 *
 */

include_once 'pica2daia.php';

$doc = new DAIA_PICA(array($_REQUEST['ppn']));

switch ($_REQUEST['output']) {
    case 'xml': 
        // show as plain XML
        header('Content-Type: text/xml; charset=UTF-8');
        echo $doc->toXml();
        break;
    default:
        // Transform to HTML
        $_xml = new DomDocument;
        $_proc = new XSLTProcessor;
        $_xml->loadXml($doc->toXml());

        $_xslt = new DomDocument;
        $_xslt->load('../xslt/daia.xsl');
        $_proc->importStyleSheet($_xslt);

        echo $_proc->transformToXML($_xml);
}
?>
