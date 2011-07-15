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
     * @var absolute path to a (CSV-based text) file which contains a table to translate location codes into human readable strings
     */
    protected $locationsFile;

    /**
     * @var string Pica-Record as a Pica-Plus string
     */
    private $picaRecord;

     /**
     * @var string Pica-Plus-Contents of PPNs as an array
     */
    private $picaPlusContent = array();

    private $duedateContent = array();

    private $detailsContent = array();

    private $prefixPPN;

    private $prefixEPN;

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
        $this->catalogPostfix = $iniArray['catalogPostfix'];
        
        $this->prefixPPN = $iniArray['documentIdPrefix'];
        $this->prefixEPN = $iniArray['itemIdPrefix'];

        $this->locationsFile = $iniArray['locationsFile'];
        
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

        $doc = new DAIA_Document($this->prefixPPN . $id, $this->basicUrl . $id);

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
       	$item = null;
        $documentType = null;
        $limitation237A = null;
        $itemRegistered = false;
        $lineCounter = 0;
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
                // if this is not the first item and it does not have any availabilities, so get availabilities from the last one.
                if ($item !== null && $item->hasAvailabilities() === false) {
                	$item = $this->getAvailabilities($item, $generalAvailability, $usage, $avail, $documentType, $limitation237A);
                }
                $textToCheck = substr($line, 0);
                $textToExplode = urlencode(html_entity_decode(substr($line, 0)));
                $fields = explode($explodingChar, $textToExplode);
                $item = new DAIA_Item();
                // The item can be added to the return array, before the content gets loaded into it...
                $items[] = $item;
                $itemRegistered = true;
                $usage = null;
                $generalAvailability = null;
                $avail = null;
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
                		$item->href = urldecode(substr($field, 1)) . $this->catalogPostfix;
                		$href = $item->href;
                	}
                    // e contains epn, the ID of the item
                	if (substr($field, 0, 1) === 'e') {
                		$item->id = $this->prefixEPN . substr($field, 1);
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
                if ($documentType === 'O') {
                    $item->setStorage(new DAIA_Element('Internet'));
                }
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
                		$item->setLabel(urldecode($label));
                	}
                	// d contains encoded general availabilty
                	if (substr($field, 0, 1) === 'd') {
                		$generalAvailability = substr($field, 1);
                	}                 	
                	// 209A $e holds the number of exemples for this item, just for information
                	// a message is not necessary anymore, since those group of examples is handled like a catalog entry with seperate examples
                	if (substr($field, 0, 1) === 'e') {
                		//$item->setMessage(new DAIA_Message(substr($field, 1) . " Exemplare, bitte manuell am Regal prüfen", 'de'));
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
                    	$locations = file($this->locationsFile);
                    	foreach ($locations as $locLine) {
                    		$l = explode(';', html_entity_decode(stripslashes($locLine), ENT_COMPAT, 'UTF-8'));
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
            	$textToExplode = html_entity_decode(substr($line, 0));
            	$itemArray = explode("\$a", $textToExplode);
                $storage = $item->getStorage();
                // if more than one item is inside one PPN, items should get expanded to seperate items
                $counter = 0;
                // only execute this, when there is more then one sample inside this PPN/EPN...
                if (count($itemArray) > 2) {
                    foreach ($itemArray as $i) {
                	    $itemCopy = new DAIA_Item;
                        if ($counter === 1) {
                            $item->setStorage(new DAIA_Element($storage->getContent(), $i, $storage->getHref()));
                    	    if ($item->href !== null) {
                    		    $item = $this->checkSubHoldingsAvailabilities($item, $i);
                    	    }
                        }
                        if ($counter > 0) {
                            $itemCopy->setStorage(new DAIA_Element($storage->getContent(), $i, $storage->getHref()));
                    	    $itemCopy->href = $item->href;
                    	    $itemCopy->setLabel($item->getLabel());
                    	    if ($item->href !== null) {
                    		    $itemCopy = $this->checkSubHoldingsAvailabilities($itemCopy, $i);
                    	    }
                        }
                        // The first item has already been added to items array
                        // so start at the second
                        if ($counter > 1) {
                        	$items[] = $itemCopy;
                        }
                        $counter++;
                    }
                }
            }
            else if (substr($line, 0, 4) === '209R') {
            	$textToCheck = substr($line, 0);
            	$textToExplode = urlencode(html_entity_decode(substr($line, 0)));
            	$fields = explode($explodingChar, $textToExplode);
                foreach ($fields as $field) {
                	// 209R $a contains the link to an eBook
                	if (substr($field, 0, 1) === 'a') {
                		$storage = $item->getStorage();
                		$storageYet = '';
                		if (is_object($storage) === true) {
                			$storageYet = $storage->getContent();
                		}
                		$item->setStorage(new DAIA_Element($storageYet, urldecode(substr($field, 1)), urldecode(substr($field, 1))));
                	}
                }            	
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
              		    $limitation237A = substr($field, 1);
                	}
                }
            }
            $lineCounter++;
            if ($storageCode !== "Ei" && $itemRegistered === true && $lineCounter === count($lines)) {
            	$item = $this->getAvailabilities($item, $generalAvailability, $usage, $avail, $documentType, $limitation237A);
            }
        }
        return $items;
    }
    
    private function getAvailabilities($item, $generalAvailability = null, $usage = null, $avail = null, $documentType = null, $limitation237A = null) {
        //$item->setMessage(new DAIA_Message("Indikator generelle Verfügbarkeit: " . $generalAvailability, 'de'));
        // get general availability
        switch ($generalAvailability) {
            case 'u':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', true);
                $item->setAvailability('interloan', true);
                break;
            case 'b':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', true);
                $item->setAvailability('interloan', true);
                $item->getAvailability('loan')->setLimitation(new DAIA_Element('verkürzte Ausleihfrist'));
              	$item->getAvailability('interloan')->setLimitation(new DAIA_Element('verkürzte Ausleihfrist'));
                break;
            case 'c':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', true);
                $item->setAvailability('interloan', false);
                break;
            case 's':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', true);
                $item->setAvailability('interloan', true);
                $item->getAvailability('loan')->setLimitation(new DAIA_Element('Besondere Zustimmung erforderlich'));
               	$item->getAvailability('interloan')->setLimitation(new DAIA_Element('nur Kopie'));
                break;
            case 'd':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', true);
                $item->setAvailability('interloan', true);
                break;
            case 'i':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', false);
                $item->setAvailability('interloan', false);
                $item->setAvailability('openaccess', false);
                break;
            case 'f':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', false);
                $item->setAvailability('interloan', true);
                $item->getAvailability('interloan')->setLimitation(new DAIA_Element('nur Kopie'));
               	$item->setAvailability('openaccess', false);
                break;
            case 'f':
                $item->setAvailability('presentation', true);
                $item->setAvailability('loan', false);
                $item->setAvailability('interloan', true);
               	$item->getAvailability('interloan')->setLimitation(new DAIA_Element('nur Kopie'));
                $item->setAvailability('openaccess', false);
                break;
            case 'a':
                $item->setAvailability('presentation', false);
                $item->setAvailability('loan', false);
                $item->setAvailability('interloan', false);
                $item->setAvailability('openaccess', false);
                $item->getAvailability('loan')->setExpected('unknown');
                $item->getAvailability('presentation')->setExpected('unknown');
                $item->getAvailability('interloan')->setExpected('unknown');
                break;
            case 'o':
                $item->setAvailability('presentation', false);
                $item->setAvailability('loan', false);
                $item->setAvailability('interloan', false);
                $item->setAvailability('openaccess', false);
                break;
            case 'g':
                $item->setAvailability('presentation', false);
                $item->setAvailability('loan', false);
                $item->setAvailability('interloan', false);
                $item->setAvailability('openaccess', false);
                break;
            case 'z':
                $item->setAvailability('presentation', false);
                $item->setAvailability('loan', false);
                $item->setAvailability('interloan', false);
                $item->setAvailability('openaccess', false);
                break;
        }
        //$item->setMessage(new DAIA_Message("Indikator momentane Verfügbarkeit: " . $usage . "/" . $avail, 'de'));
        // get current availability
        switch ($usage) {
            case 'Beim Buchhandel bestellt': 
                $item->setAvailability('presentation', false);
                $item->setAvailability('loan', false);
                // The item is only currently not available,
                // but PICA does not tell us, when it is expected...
                $item->getAvailability('loan')->setExpected('unknown');
                $item->getAvailability('presentation')->setExpected('unknown');
                if ($item->getAvailability('interloan') !== null) {
                  	$item->setAvailability('interloan', false);
                    $item->getAvailability('interloan')->setExpected('unknown');
                }
                // only show reservation link if reservation is active
                if ($this->reservationUrl) {
                    $href = $this->reservationUrl . $item->id;
                    $item->href = $href;
                }
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
                else if (strtolower($avail) === 'entliehen') {
                    $item->setAvailability('loan', false);
                    $item->setAvailability('presentation', false);
                    // The item is only currently not available,
                    // look when it shall be back
                    $item->getAvailability('loan')->setExpected($this->getDuedate($item->href));
                    $item->getAvailability('presentation')->setExpected($this->getDuedate($item->href));
                    if ($item->getAvailability('interloan') !== null) {
                    	$item->setAvailability('interloan', false);
                        $item->getAvailability('interloan')->setExpected($this->getDuedate($item->href));
                    }
                }
                else if (substr($avail, -9) === 'entnehmen') {
                    $item->setAvailability('loan', true);
                    $item->setAvailability('presentation', true);
                }
                else if (substr($avail, -9) === 'ausleihen') {
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
                else {
                	$item->setAvailability('presentation', false);
                }
        }
        if (is_object($item->getAvailability('loan')) === true) {
           	$item->getAvailability('loan')->setHref($item->href);
            if ($limitation237A !== null) {
                $item->getAvailability('loan')->setLimitation(new DAIA_Element(utf8_encode(urldecode($limitation237A))));
            }
        }
        if (is_object($item->getAvailability('presentation')) === true) {
           	$item->getAvailability('presentation')->setHref($item->href);
        }
        if (is_object($item->getAvailability('interloan')) === true) {
           	$item->getAvailability('interloan')->setHref($item->href);
        }
        return $item;
    }

    /**
     * Gets a duedate from Pica using HTTP
     * 
     * @param string $url URL of the record
     * @return string duedate as a string
     */
    private function getDuedate($url) {
	    $duedate = 'unknown';

        if ($this->duedateContent[$url] === null) {
        	$this->duedateContent[$url] = file_get_contents(html_entity_decode(urldecode($url)));
        }
        
	    if (empty($this->duedateContent[$url]) === true) {
            return $duedate;
        }                
        
        $position = strpos($this->duedateContent[$url], '<td width="100%" class="plain" nowrap>Lent till');
        $duedate = substr($this->duedateContent[$url], $position+48, 10);
	    // reformat duedate, its coming in dd-mm-yyyy and should be yyyy-mm-dd
	    $duedateArray = explode('-', $duedate);
	    $duedate = $duedateArray[2].'-'.$duedateArray[1].'-'.$duedateArray[0];
	    return $duedate;
    }

    /**
     * Gets a Pica-plus record from Pica using HTTP
     * 
     * @param string $ppn PPN of the record
     * @return array Array of records as strings for each search result
     */
    private function getRecordsByHTTP($ppn) {
	    $katurl = $this->picaPlusUrl . $ppn;

        if ($this->picaPlusContent[$ppn] === null) {
        	$this->picaPlusContent[$ppn] = file_get_contents($katurl);
        }
        
	    if (empty($this->picaPlusContent[$ppn]) === true) {
            return new DAIA_Message("could not open PICA+ input", 'en', 100);
        }        
        
        $return = str_replace('<TD>', '', $this->picaPlusContent[$ppn]);
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
    
    private function checkSubHoldingsAvailabilities($item, $barcode) {
	    if ($item->href === null) return $item;

        if ($this->detailsContent[$item->href] === null) {
        	$this->detailsContent[$item->href] = file_get_contents(urldecode($item->href) . $this->catalogPostfix);
        }
        
        // Look for barcode in document
        // if it has been found, this item is on loan, now look for the duedate
        // if it has not been found, this item is presumably available
        $barcodePosition = strrpos($this->detailsContent[$item->href], 'VBAR='.$barcode);
        if ($barcodePosition !== false) {
            $position = strpos($this->detailsContent[$item->href], '<td class="table" nowrap>&nbsp;Lent till', $barcodePosition);
            $duedate = substr($this->detailsContent[$item->href], $position+41, 10);
            $item->setAvailability('loan', false);
            $item->setAvailability('presentation', false);
            if ($position !== false) {
                // The item is only currently not available,
                $item->getAvailability('loan')->setExpected($duedate);
                $item->getAvailability('presentation')->setExpected($duedate);
                $item->getAvailability('presentation')->setHref($item->href);
                $item->getAvailability('loan')->setHref($item->href);
            }
            return $item;
        }
        // if it has not been found, this item is presumably available
        $item->setAvailability('loan', true);
        $item->setAvailability('presentation', true);

    	return $item;
    }
}
?>
