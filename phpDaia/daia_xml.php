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

        $daiaRoot = $xml->createElementNS('http://ws.gbv.de/daia/', 'daia');
        $daiaRoot->setAttribute('version', $this->daia->getVersion());
        $daiaRoot->setAttribute('timestamp', $this->daia->getTimestamp());
        $daiaRoot->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance/');
        $daiaRoot->setAttributeNS('http://www.w3.org/2001/XMLSchema-instance/', 'xsi:schemaLocation', 'http://ws.gbv.de/daia/ http://ws.gbv.de/daia/daia.xsd');
        /*$daiaRoot->appendChild($this->getMessage(array()));*/
        $daiaRoot->appendChild($this->getInstitution($this->daia->getInstitution()));
        $xml->appendChild($daiaRoot);

        foreach ($this->daia->getDocuments() as $holding) {
            $node = $this->getHoldingInformation($holding);
            $daiaRoot->appendChild($node);
        }

        return $xml;
    }

    public function createNamespacedXml() {
        $xml = new DOMDocument('1.0', 'utf-8');
        $xml->formatOutput = true;
        $this->xml = $xml;
        
        $daiaRoot = $xml->createElementNS('http://ws.gbv.de/daia/', 'd:daia');
        $daiaRoot->setAttribute('version', $this->daia->getVersion());
        $daiaRoot->setAttribute('timestamp', $this->daia->getTimestamp());
        $daiaRoot->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:s', 'http://www.w3.org/2001/XMLSchema-instance/');
        $daiaRoot->setAttributeNS('http://www.w3.org/2001/XMLSchema-instance/', 's:schemaLocation', 'http://ws.gbv.de/daia/ http://ws.gbv.de/daia/daia.xsd');
        /*$daiaRoot->appendChild($this->getMessage(array()));*/
        $daiaRoot->appendChild($this->getInstitution($this->daia->getInstitution()));
        $xml->appendChild($daiaRoot);

        foreach ($this->daia->getDocuments() as $holding) {
            $node = $this->getHoldingInformation($holding, true);
            $daiaRoot->appendChild($node);
        }
        
        return $xml;
    }
    
    /**
     * gets the XML-representation of DAIA_Document
     *
     * @return DOMElement daia/document in XML
     **/
    public function getHoldingInformation($doc, $namespaced = false) {
        if ($namespaced === true) {
        	$element = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:document');
        }
        else {
        	$element = $this->xml->createElement('document');
        }
        
        $element->setAttribute('id', $doc->id);
        if ($doc->holdingHref !== null) $element->setAttribute('href', $doc->holdingHref);
        $items = $doc->getItems();
        if (count($doc->getMessage()) > 0) {
            foreach($doc->getMessage() as $message) {
                $element->appendChild($this->getMessage($message));
            }
        }
        foreach ($doc->getItems() as $it) {
            if ($it !== null) {
                $item = $this->getItemInformation($it, $namespaced);
                if ($item !== null) {                
                    $element->appendChild($item);
                }
            }
        }
        return $element;
    }

    /**
     * parses the returned page from PICA
     *
     * @return DOMNode document in DAIA format
     **/
    public function getItemInformation($item, $namespaced = false) {
         if ($namespaced === true) {
         	$itemElement = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:item');
         }
         else {
         	$itemElement = $this->xml->createElement('item');
         }
        if (empty($item->id) === false) $itemElement->setAttribute('id', $item->id);
        if (empty($item->href) === false) $itemElement->setAttribute('href', $item->href);
        if (empty($item->fragment) === false) $itemElement->setAttribute('fragment', $item->fragment);
        if (count($item->getMessage()) > 0) {
            foreach($item->getMessage() as $message) {
                $itemElement->appendChild($this->getMessage($message, $namespaced));
            }
        }
        if ($item->getLabel() !== null) $itemElement->appendChild($this->getLabel($item->getLabel(), $namespaced));
        if ($item->getDepartment() !== null) $itemElement->appendChild($this->getDepartment($item->getDepartment(), $namespaced));
        if ($item->getStorage() !== null) $itemElement->appendChild($this->getStorage($item->getStorage(), $namespaced));
        $availability = $this->getAvailabilityInformation($item, 'presentation', $namespaced);
        if ($availability !== null) $itemElement->appendChild($availability);
        $availability = $this->getAvailabilityInformation($item, 'loan', $namespaced);
        if ($availability !== null) $itemElement->appendChild($availability);
        $availability = $this->getAvailabilityInformation($item, 'openaccess', $namespaced);
        if ($availability !== null) $itemElement->appendChild($availability);
        $availability = $this->getAvailabilityInformation($item, 'interloan', $namespaced);
        if ($availability !== null) $itemElement->appendChild($availability);
        return $itemElement;
    }
    
    public function getAvailabilityInformation($item, $service, $namespaced = false) {
        if ($item->isAvailable($service) === true) {
            $availabilityType = 'available';
        }
        else if ($item->isAvailable($service) === false) {
            $availabilityType = 'unavailable';
        }
        else {
        	return null;
        }
        if ($namespaced === true) {
        	$availability = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:' . $availabilityType);
        }
        else {
        	$availability = $this->xml->createElement($availabilityType);
        }
        $availability->setAttribute('service', $service);
        if (is_object($item->getAvailability($service)) === true) {
            if ($item->getAvailability($service)->getHref() !== null) $availability->setAttribute('href', $item->getAvailability($service)->getHref());
            if (count($item->getAvailability($service)->getMessages()) > 0) {
            	foreach ($item->getAvailability($service)->getMessages() as $message) {
            	    $availability->appendChild($this->getMessage($message, $namespaced));
            	}
            } 
            if (count($item->getAvailability($service)->getLimitations()) > 0) {
            	foreach ($item->getAvailability($service)->getLimitations() as $limit) { 
            		$availability->appendChild($this->getLimitation($limit, $namespaced));
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

    public function getMessage($message, $namespaced = false) {
        if ($namespaced === true) {
        	$node = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:message', $message->content);
        }
        else {
        	$node = $this->xml->createElement('message');
        	$node->nodeValue = $message->content;
        }
        $node->setAttribute('lang', $message->lang);
        if (empty($message->errno) !== true) $node->setAttribute('errno', $message->errno);
        return $node;
    }

    public function getInstitution($institution, $namespaced = false) {
        if ($namespaced === true) {
        	$node = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:institution', $institution->getContent());
        }
        else {
        	$node = $this->xml->createElement('institution');
        	$node->nodeValue = $institution->getContent();
        }
        if ($institution->getId() !== null) $node->setAttribute('id', $institution->getId());
        if ($institution->getHref() !== null) $node->setAttribute('href', $institution->getHref());
        return $node;
    }
    public function getDepartment($department, $namespaced = false) {
        if ($namespaced === true) {
        	$node = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:department', $department->getContent());
        }
        else {
        	$node = $this->xml->createElement('department');
        	$node->nodeValue = $department->getContent();
        }
        if ($department->getId() !== null) $node->setAttribute('id', $department->getId());
        if ($department->getHref() !== null) $node->setAttribute('href', $department->getHref());
        return $node;
    }

    public function getStorage($storage, $namespaced = false) {
        if ($namespaced === true) {
        	$node = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:storage', $storage->getContent());
        }
        else {
        	$node = $this->xml->createElement('storage');
        	$node->nodeValue = $storage->getContent();
        }
        if ($storage->getId() !== null) $node->setAttribute('id', $storage->getId());
        if ($storage->getHref() !== null) $node->setAttribute('href', $storage->getHref());
        return $node;
    }

    public function getLimitation($limit, $namespaced = false) {
        if ($namespaced === true) {
        	$node = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:limitation', $limit->getContent());
        }
        else {
        	$node = $this->xml->createElement('limitation');
        	$node->nodeValue = $limit->getContent();
        }
        if ($limit->getId() !== null) $node->setAttribute('id', $limit->getId());
        if ($limit->getHref() !== null) $node->setAttribute('href', $limit->getHref());
        return $node;
    }

    public function getLabel($content, $namespaced = false) {
        if ($namespaced === true) {
        	$node = $this->xml->createElementNS('http://ws.gbv.de/daia/', 'd:label', $content);
        }
        else {
        	$node = $this->xml->createElement('label');
        	$node->nodeValue = $content;
        }
        return $node;
    }
}
?>
