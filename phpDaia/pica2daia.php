<?php
/**
 * PHP-Library to get DAIA-information from PICA
 *
 * @author Oliver Marahrens <o.marahrens@tu-harburg.de>
 *
 */

require_once 'daia.php';

/**
 * Class to build DAIA objects from PICA using PICAplus
 */
class DAIA_PICA extends DAIA {

    /**
     * Defines the basic URL to get one title in the catalog
     * 
     * @var string URL to get one title from the catalog by PPN
     */
    protected $basicUrl;

    /**
     * @var string URL to get PICAplus for one PPN
     */
    protected $picaPlusUrl;
    
    /**
     * @var string URL to reserve ordered books by EPN
     */
    protected $reservationUrl;

    /**
     * @var string Pica-Record as a Pica-Plus string
     */
    private $picaRecord;

    /**
     * Constructor
     * 
     * @param array [$docs] (optional) Array with PPNs for the DAIA Document
     * @return void
     */
    public function __construct($docs = null) {
    	$iniArray = parse_ini_file("daia.ini");

        $this->setInstitution(new DAIA_Element($iniArray['name'], $iniArray['sigel'], $iniArray['infoUrl']));
        
        $this->basicUrl = $iniArray['basicUrl'];
        $this->picaPlusUrl = $iniArray['picaPlusUrl'];
        $this->reservationUrl = $iniArray['reservationUrl'];
        
        foreach ($docs as $docId) {
            $this->documents[] = $this->getDocument($docId);
        }
    }

     /**
     * Get a document from PICA by its PPN
     * recieves a PICA-plus fieldset
     * 
     * @param string $id PPN of the document
     * @param string $method Method to get the document
     * Valid methods are
     * http - Get the PicaPlus content via HTTP
     * z3950 - Get the PicaPlus content via Z39.50
     * @return DAIA_Document Document in DAIA format
     */
    public function getDocument($id, $method = 'http') {
        if ($method === 'z3950') {
            $this->picaRecord = $this->getRecordsByZ3950($id);
        }
        else {
            $this->picaRecord = $this->getRecordsByHTTP($id);
        }

        $doc = new DAIA_Document($id, $this->basicUrl . $id);

        if (count($this->picaRecord) === 0) {
            $doc->setMessage(new DAIA_Message("PPN not found!", 'en', 100));
        }

        foreach($this->picaRecord as $record) {
            //$doc->setMessage(new DAIA_Message(htmlentities($record), 'pica'));
            // In Z39.50 the exploding character is Ÿ (urlencoded %9F)
            if ($method === 'z3950') {
            	$explodingChar = '%9F';
            }
            // in HTTP output its $ (urlencoded %24)
            else {
            	$explodingChar = '%24';
            }
           	$doc->setItems($this->getItemsFromPicaPlus($record, $explodingChar));
        }

        return $doc;
    }

    /**
     * Parses items from PICA-plus input
     * 
     * @param string $record PICA-plus input string
     * @param string $explodingChar Character to seperate subfields in PicaPlus fields, must be specified as urlencoded character (%XY)
     * @return array Array of DAIA_Items 
     */
    protected function getItemsFromPicaPlus($record, $explodingChar) {
        $items = array();
       	$lines = explode("\n", $record);
        $documentType = null;
        
        foreach ($lines as $line) {
        	$href = null;
            if (substr($line, 0, 4) === '002@') {
                $textToCheck = substr($line, 0);
                $textToExplode = urlencode(html_entity_decode(substr($line, 0)));
                $fields = explode($explodingChar, $textToExplode);
            	foreach ($fields as $field) {
            	    // get the medium type of this document
            	    if (substr($field, 0, 1) === '0') {
            	    	$documentType = substr($field, 1, 1);
            	    }
            	}
            }
            else if (substr($line, 0, 4) === '201@') {
                $textToCheck = substr($line, 0);
                $textToExplode = urlencode(html_entity_decode(substr($line, 0)));
                $fields = explode($explodingChar, $textToExplode);
                $item = new DAIA_Item();
                $usage = null;
                foreach ($fields as $field) {
                	// URLs should not be urlencoded completely, so decode : and /
                	// otherwise they cannot get called...
                	// all URL-Paramters should be still urlencoded
                	$field = str_replace("%3A", ":", $field);
                	$field = str_replace("%2F", "/", $field);
                	$item->setMessage(new DAIA_Message($field, 'pica'));
                	// l contains the link to the item directly
                    // LOGIN=ANONYMOUS should be added to avoid naked login screen
                	if (substr($field, 0, 1) === 'l') {
                		$item->href = substr($field, 1) . '&LOGIN=ANONYMOUS';
                		$href = $item->href;
                	}
                	// e contains epn, the ID of the item
                	if (substr($field, 0, 1) === 'e') {
                		$item->id = substr($field, 1);
                	}
                	// u contains holding information
                	if (substr($field, 0, 1) === 'u') {
                		$usage = urldecode(substr($field, 1));
                	}
                	// v contains availability information
                	if (substr($field, 0, 1) === 'v') {
                		$avail = substr($field, 1);
                	}
                }
                switch ($usage) {
                    case 'Beim Buchhandel bestellt': 
                        $item->setAvailability('presentation', false);
                        $item->setAvailability('loan', false);
                        // The item is only currently not available,
                        // but PICA does not tell us, when it is expected...
                        $item->getAvailability('loan')->setExpected('unknown');
                        $item->getAvailability('presentation')->setExpected('unknown');
                        $href = $this->reservationUrl . $item->id;
                        $item->href = $href;
                        break;
                    case 'nur Lesesaalnutzung': 
                        $item->setAvailability('presentation', true);
                        $item->setAvailability('loan', false);
                        break;
                    case 'Ausleihbestand':
                        if (substr($avail, 0, 4) === 'verf') {
                	        $item->setAvailability('loan', true);
                            $item->setAvailability('presentation', true);
                        }
                        else if ($avail === 'entliehen') {
                            $item->setAvailability('loan', false);
                            $item->setAvailability('presentation', false);
                            // The item is only currently not available,
                            // but PICA does not tell us, when it is expected...
                            $item->getAvailability('loan')->setExpected($this->getDuedate($href));
                            $item->getAvailability('presentation')->setExpected($this->getDuedate($href));
                        }
                        else if (substr($avail, -9) === 'entnehmen') {
                            $item->setAvailability('loan', true);
                            $item->setAvailability('presentation', true);
                        }
                        else if ($documentType === 'O') {
                            $item->setAvailability('loan', true);
                            $item->setAvailability('presentation', true);
                        }
                        break;
                    case 'Nicht ausleihbar (Sonderstandort)':
                        $item->setAvailability('loan', false);
                        if ($documentType === 'O') {
                        	$item->setAvailability('presentation', true);
                        }
                        break;
                    default:
                    	// set Availability to Unavailable
                    	$item->setAvailability('loan', false);
                        $item->setAvailability('presentation', false);
                }
                if (is_object($item->getAvailability('loan')) === true) {
                	$item->getAvailability('loan')->setHref($href);
                }
                if (is_object($item->getAvailability('presentation')) === true) {
                	$item->getAvailability('presentation')->setHref($href);
                }
                if ($documentType === 'O') {
                    $item->setStorage(new DAIA_Element('Internet'));
                }
                $items[] = $item;
            }
            else if (substr($line, 0, 4) === '209A') {
            	$textToCheck = substr($line, 0);
            	$textToExplode = urlencode(html_entity_decode(substr($line, 0)));
            	$fields = explode($explodingChar, $textToExplode);
                foreach ($fields as $field) {
                	// URLs should not be urlencoded completely, so decode : and /
                	// otherwise they cannot get called...
                	// all URL-Paramters should be still urlencoded
                	$field = str_replace("%3A", ":", $field);
                    $field = str_replace("%2F", "/", $field);
                	//$item->setMessage(new DAIA_Message(htmlentities($field), 'pica'));
                	// 209A $a holds the signature(s)
                	if (substr($field, 0, 1) === 'a') {
                		// only get the first signature, thats the one containing the real signature (and not the barcode)
                		// TODO: check if this is REALLY the correct signature
                		if ($item->getLabel() === null) {
                		    //$label = substr($field, 1) . " " . $item->getLabel();
                		//}
                		//else {
                			$label = substr($field, 1);
                		}
                		$item->setLabel($label);
                	}
                	// 209A $e holds the number of exemples for this item
                	if (substr($field, 0, 1) === 'e') {
                		$item->setMessage(new DAIA_Message(substr($field, 1) . " Exemplare, bitte manuell am Regal prüfen", 'de'));
                	}
                    // 209A $f holds the storage information
                    if (substr($field, 0, 1) === 'f') {
                    	$storageCode = substr($field, 1);
                    	$storage = $storageCode;
                    	if (is_numeric($storageCode) === true) { $storage = "Magazin"; }
                    	else if ($storageCode === "Ei") { $storage = "-"; }
                    	else { $storage = "Lesesaal " . $storageCode; }
                    	$stor_id = null; // TODO: get barcode as ID
                    	$stor_href = null; // TODO: get location href from file
                    	// get the real storage location from translation table
                    	$locations = file('/drbd/www/SST_TUHH.txt');
                    	foreach ($locations as $locLine) {
                    		$l = explode(';', $locLine);
                    		if ($l[0] === $storageCode) {
                    			$storage = $l[1];
                    			$stor_href = $l[3];
                    		}
                    	}
                        $item->setStorage(new DAIA_Element($storage, $stor_id, $stor_href));
                    }
                }
            }
            else if (substr($line, 0, 4) === '209G') {
            	$textToCheck = substr($line, 0);
            	$textToExplode = html_entity_decode(substr($line, 0));
            	$readPos = strpos($textToExplode, "\$a");
                $storage = $item->getStorage();
                $item->setStorage(new DAIA_Element($storage->getContent(), substr($textToExplode, $readPos+2) , $storage->getHref()));
            }
            else if (substr($line, 0, 4) === '237A') {
            	$textToCheck = substr($line, 0);
            	$textToExplode = urlencode(html_entity_decode(substr($line, 0)));
            	$fields = explode($explodingChar, $textToExplode);
                foreach ($fields as $field) {
                	// URLs should not be urlencoded completely, so decode : and /
                	// otherwise they cannot get called...
                	// all URL-Paramters should be still urlencoded
                	$field = str_replace("%3A", ":", $field);
                    $field = str_replace("%2F", "/", $field);
                	//$item->setMessage(new DAIA_Message(htmlentities($field), 'pica'));
                	// 237A $a holds the limitation message
                	if (substr($field, 0, 1) === 'a') {
              		    $label = substr($field, 1);
                		$item->getAvailability('loan')->setLimitation(new DAIA_Element(utf8_encode(urldecode($label))));
                	}
                }
            } 
        }
        return $items;
    }
    
    /**
     * Gets the items for this document by parsing the PSI-XML-output
     *
     * This does not work properly! Parsing this XML-output is not effective.
     * 
     * @param string $id PPN of the document that should be parsed
     * @return array Array of DAIA_Items
    **/
    protected function getItemsFromXml($id) {
        $items = array();
        $katurl= $this->basicUrl . $id;

        if (!($fp = fopen("$katurl", "r"))) {
            return new DAIA_Message("could not open XML Shorttitle input", 'en', 100);
        }

        $a = file_get_contents($katurl);
        // Request info suchen
        $itemCount = substr_count($a, 'Request info');
        
        $itemPosition = 0;
        for ($counter = 0; $itemCount > $counter; $counter++) {
            $itemPosition = strpos($a, 'Request info', $itemPosition+1);
            // if there are more items found with Request info, only read until the next item
            if ($itemCount > $counter+1) {
                $nextItemPosition = strpos($a, 'Request info', $itemPosition+1);
                $textlength = $nextItemPosition-$itemPosition;
                $textToCheck = substr($a, $itemPosition, $textlength);
            }
            else {
                $textToCheck = substr($a, $itemPosition);
            }
            $item = new DAIA_Item();
            // find EPN and put it into id field
            $item->id = $this->getEpn();
            $item->setMessage(new DAIA_Message($textToCheck, 'en'));
            if (strstr($textToCheck, 'reading room use only') !== false) {
                $item->setAvailability('presentation', true);
            }
            if (strstr($textToCheck, 'Lendable Holding') !== false && strstr($textToCheck, 'available') !== false) {
                $item->setAvailability('loan', true);
            }
            if (strstr($textToCheck, 'Lendable Holding') !== false && strstr($textToCheck, 'lent') !== false) {
                $item->setAvailability('loan', false);
            }
            $items[] = $item;
        }
        return $items;
    }
    
    /**
     * Gets a Pica-plus record from Pica using HTTP
     * 
     * @param string $ppn PPN of the recor
     * @return array Array of records as strings for each search result
     */
    private function getDuedate($url) {
	    $duedate = 'unknown';
	    if (!($fp = fopen("$url", "r"))) {
            return $duedate;
        }

        $a = file_get_contents($url);
        $position = strpos($a, '<td width="100%" class="plain" nowrap>Lent till');
        $duedate = substr($a, $position+48, 10);
	    return $duedate;
    }

    /**
     * Gets a Pica-plus record from Pica using HTTP
     * 
     * @param string $ppn PPN of the recor
     * @return array Array of records as strings for each search result
     */
    private function getRecordsByHTTP($ppn) {
	    $katurl = $this->picaPlusUrl . $ppn;
	    if (!($fp = fopen("$katurl", "r"))) {
            return new DAIA_Message("could not open PICA+ input", 'en', 100);
        }

        $a = file_get_contents($katurl);
        
        $return = str_replace('<TD>', '', $a);
        $return = str_replace('<TR>', '', $return);
        $return = str_replace('</TR>', '', $return);
        $return = str_replace('</TD>', '', $return);
        
	    return array($return);
    }

    /**
     * Gets a Pica-plus record from Pica using Z39.50
     * 
     * @param string $ppn PPN of the recor
     * @return array Array of records as strings for each search result
     */
    private function getRecordsByZ3950($ppn) {
        $syntax="string"; // marc21 sutrs, usmarc, grs1, xml, opac?
        $saveas="xml"; // xml raw string opac?
        $con = Z3950Connector::getInstance()->getConnection();
        yaz_syntax( $con, $this->syntax );
        //yaz_range( $con, 1, 10 );
        yaz_search( $con, "rpn",  "@attr 1=12 $ppn"  );
        yaz_wait();
        $error = yaz_error($con);
        $rec = array();
        if (!empty($error)) {
            echo "Error: $error";
        } else {
            $hits = yaz_hits ( $con );

            for ($p = 1; $p <= $hits; $p++) {
                $rec[] = yaz_record( $con, $p, "$saveas" ) ;
            }
        }
        yaz_close($con);
        return $rec;
    }	
}
?>
