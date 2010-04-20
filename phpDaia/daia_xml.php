<?php
/**
 * Delivers a DAIA document in XML
 *
 * @author Oliver Marahrens <o.marahrens@tu-harburg.de>
 *
 */

class DAIA_XML {
    
    private $xml;
    
    private $daia;
    
    public function __construct($daia) {
        $this->daia = $daia;
    }
    
    public function createXml() {
        $xml = new DOMDocument('1.0', 'utf-8');
        $xml->formatOutput = true;
        $this->xml = $xml;

        $daiaRoot = $xml->createElement('daia');
        $daiaRoot->createAttributeNS('http://ws.gbv.de/daia/');
        $daiaRoot->setAttribute('version', $this->daia->getVersion());
        $daiaRoot->setAttribute('timestamp', $this->daia->getTimestamp());
        /*$daiaRoot->appendChild($this->getMessage(array()));*/
        $daiaRoot->appendChild($this->getInstitution($this->daia->getInstitution()));
        $xml->appendChild($daiaRoot);

        foreach ($this->daia->getDocuments() as $holding) {
            $node = $this->getHoldingInformation($holding);
            $daiaRoot->appendChild($node);
        }
        
        return $xml;
    }
    
    /**
     * gets the XML-representation of DAIA_Document
     *
     * @return DOMElement daia/document in XML
     **/
    public function getHoldingInformation($doc) {
        $element = $this->xml->createElement('document');
        $element->setAttribute('id', $doc->id);
        if ($doc->holdingHref !== null) $element->setAttribute('href', $doc->holdingHref);
        $items = $doc->getItems();
        if (count($doc->getMessage()) > 0) {
            foreach($doc->getMessage() as $message) {
                $element->appendChild($this->getMessage($message));
            }
        }
        foreach ($doc->getItems() as $it) {
            $item = $this->getItemInformation($it);
            $element->appendChild($item);
        }
        return $element;
    }

    /**
     * parses the returned page from PICA
     *
     * @return DOMNode document in DAIA format
     **/
    public function getItemInformation($item) {
        $itemElement = $this->xml->createElement('item');
        if (empty($item->id) === false) $itemElement->setAttribute('id', $item->id);
        if (empty($item->href) === false) $itemElement->setAttribute('href', $item->href);
        if (empty($item->fragment) === false) $itemElement->setAttribute('fragment', $item->fragment);
        if (count($item->getMessage()) > 0) {
            foreach($item->getMessage() as $message) {
                $itemElement->appendChild($this->getMessage($message));
            }
        }
        if ($item->getLabel() !== null) $itemElement->appendChild($this->getLabel($item->getLabel()));
        if ($item->getDepartment() !== null) $itemElement->appendChild($this->getDepartment());
        if ($item->getStorage() !== null) $itemElement->appendChild($this->getStorage($item->getStorage()));
        $availability = $this->getAvailabilityInformation($item, 'presentation');
        $itemElement->appendChild($availability);
        $availability = $this->getAvailabilityInformation($item, 'loan');
        $itemElement->appendChild($availability);
        /* not set yet
        $availability = $this->getAvailabilityInformation($item, 'openaccess');
        $item->appendChild($availability);
        $availability = $this->getAvailabilityInformation($item, 'interloan');
        $item->appendChild($availability);
        */
        return $itemElement;
    }
    
    public function getAvailabilityInformation($item, $service) {
        if ($item->isAvailable($service) === true) {
            $availabilityType = 'available';
        }
        else {
            $availabilityType = 'unavailable';
        }
        $availability = $this->xml->createElement($availabilityType);
        $availability->setAttribute('service', $service);
        if (is_object($item->getAvailability($service)) === true) {
            if ($item->getAvailability($service)->getHref() !== null) $availability->setAttribute('href', $item->getAvailability($service)->getHref());
            if (count($item->getAvailability($service)->getMessages()) > 0) {
            	foreach ($item->getAvailability($service)->getMessages() as $message) {
            	    $availability->appendChild($this->getMessage($message));
            	}
            } 
            if (count($item->getAvailability($service)->getLimitations()) > 0) {
            	foreach ($item->getAvailability($service)->getLimitations() as $limit) { 
            		$availability->appendChild($this->getLimitation($limit));
            	}
            }
            if ($availabilityType === 'available') {
                if ($item->getAvailability($service)->getDelay() !== null) {
                    $availability->setAttribute('delay', $item->getAvailability($service)->getDelay());
                }
            }
            else {
                if ($item->getAvailability($service)->getExpected() !== null) {
                	$availability->setAttribute('expected', $item->getAvailability($service)->getExpected());
                }
                if ($item->getAvailability($service)->getQueue() !== null) {
                    $availability->setAttribute('queue', $item->getAvailability($service)->getQueue());
                }
            }
        }
        return $availability;
    }

    public function getMessage($message) {
        $node = $this->xml->createElement('message');
        $node->setAttribute('lang', $message->lang);
        if (empty($message->errno) !== true) $node->setAttribute('errno', $message->errno);
        $node->nodeValue = $message->content;
        return $node;
    }

    public function getInstitution($institution) {
        $node = $this->xml->createElement('institution');
        if ($institution->getId() !== null) $node->setAttribute('id', $institution->getId());
        if ($institution->getHref() !== null) $node->setAttribute('href', $institution->getHref());
        $node->nodeValue = $institution->getContent();
        return $node;
    }
    public function getDepartment($department) {
        $node = $this->xml->createElement('department');
        if ($department->getId() !== null) $node->setAttribute('id', $department->getId());
        if ($department->getHref() !== null) $node->setAttribute('href', $department->getHref());
        $node->nodeValue = $department->getContent();
        return $node;
    }

    public function getStorage($storage) {
        $node = $this->xml->createElement('storage');
        if ($storage->getId() !== null) $node->setAttribute('id', $storage->getId());
        if ($storage->getHref() !== null) $node->setAttribute('href', $storage->getHref());
        $node->nodeValue = $storage->getContent();
        return $node;
    }

    public function getLimitation($limit) {
        $node = $this->xml->createElement('limitation');
        if ($limit->getId() !== null) $node->setAttribute('id', $limit->getId());
        if ($limit->getHref() !== null) $node->setAttribute('href', $limit->getHref());
        $node->nodeValue = $limit->getContent();
        return $node;
    }

    public function getLabel($content) {
        $node = $this->xml->createElement('label');
        $node->nodeValue = $content;
        return $node;
    }
}
?>
