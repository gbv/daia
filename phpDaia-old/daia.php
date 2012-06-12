<?php
/**
 * PHP-Library to build DAIA-Documents
 *
 * @author Oliver Marahrens <o.marahrens@tu-harburg.de>
 *
 */

require_once 'pica2daia.php';
require_once 'daia_xml.php';
require_once 'Z3950Connector.php';

class DAIA_Document {
    public $id;
    public $holdingHref = null;
    private $message = array();
    private $items = array();
    
    public function __construct($id, $href = null) {
        $this->id = $id;
        $this->holdingHref = $href;
    }

    public function setMessage($message) {
        $this->message[] = $message;
    }

    public function getMessage() {
        return $this->message;
    }

    public function getItems() {
        return $this->items;
    }

    public function setItems($items) {
        $this->items = $items;
    }

    public function setItem($item) {
        $this->items[] = $item;
    }
}

class DAIA_Availability {
    protected $service;
    protected $href = null;
    protected $messages = array();
    protected $limitations = array();
    
    public function setHref($href) {
    	$this->href = $href;
    }

    public function getHref() {
    	return $this->href;
    }

    public function setMessage($message) {
    	$this->messages[] = $message;
    }

    public function getMessages() {
    	return $this->messages;
    }

    public function setLimitation($limit) {
    	$this->limitations[] = $limit;
    }

    public function getLimitations() {
    	return $this->limitations;
    }
}

class DAIA_Available extends DAIA_Availability {
    protected $delay = null;
    
    public function getDelay() {
    	return $this->delay;
    }
    
    public function setDelay($delay) {
    	$this->delay = $delay;
    }
}

class DAIA_Unavailable extends DAIA_Availability {
    protected $expected = null;
    protected $queue = null;

    public function getExpected() {
    	return $this->expected;
    }
    
    public function setExpected($expected) {
    	$this->expected = $expected;
    }

    public function getQueue() {
    	return $this->queue;
    }
    
    public function setQueue($queue) {
    	$this->queue = $queue;
    }
}


class DAIA_Item {
    public $id;
    public $href;
    public $fragment;
    private $message = array();
    private $label = null;
    private $department;
    private $storage = null;
    protected $availabilities = array();

    public function isAvailable($service) {
        if (array_key_exists($service, $this->availabilities) === true) {
            if (get_class($this->availabilities[$service]) === 'DAIA_Available') {
                return true;
            }
            else if (get_class($this->availabilities[$service]) === 'DAIA_Unavailable') {
                return false;
            }
        }
        return null;
    }

    public function getAvailability($service) {
        return $this->availabilities[$service];
    }
    
    public function hasAvailabilities() {
    	if (count($this->availabilities) > 0) return true;
        return false;
    }

    public function setAvailability($service, $value) {
        if ($value === true) {
            $this->availabilities[$service] = new DAIA_Available();
        }
        else if ($value === false){
            $this->availabilities[$service] = new DAIA_Unavailable();
        }
        else {
        	// unknown Availability, so set Availability to null
        	$this->availabilities[$service] = null;
        }
    }

    public function setMessage($message) {
        $this->message[] = $message;
    }

    public function getMessage() {
        return $this->message;
    }

    public function setLabel($content) {
        $this->label = $content;
    }

    public function getLabel() {
        return $this->label;
    }

    public function getDepartment() {
        return null;
    }

    public function setStorage($storage) {
        $this->storage = $storage;
    }

    public function getStorage() {
        return $this->storage;
    }

}

class DAIA_Message {
    public $lang;
    public $errno;
    public $content;

    public function __construct($content, $lang = 'unknown', $errno = null) {
        $this->lang = $lang;
        $this->errno = $errno;
        $this->content = $content;
    }
}

class DAIA_Element {
    private $id;
    private $href;
    private $content;

    public function __construct($content, $id = null, $href = null) {
        $this->id = $id;
        $this->href = $href;
        $this->content = $content;
    }
    
    public function getHref() {
    	return $this->href;
    }
    
    public function getId() {
    	return $this->id;
    }
    
    public function getContent() {
    	return $this->content;
    }
}

class DAIA {

    protected $daiaVersion = '0.5';

    protected $documents = array();
    
    protected $institution;
    
    protected $message = array();

    public function __construct($docs = null) {
        foreach ($docs as $docId) {
            $this->documents[] = new DAIA_Document($docId);
        }
    }

    public function getVersion() {
        return $this->daiaVersion;
    }

    public function getTimestamp() {
        return date('c');
    }

    public function getDocuments() {
        return $this->documents;
    }

    public function getInstitution() {
        return $this->institution;
    }
    
    public function setInstitution($institution) {
    	$this->institution = $institution;
    }

    public function setMessage($message) {
        $this->message[] = $message;
    }

    public function getMessage() {
        return $this->message;
    }

    /**
     * get the XML representation of DAIA data
     * 
     * @param boolean $namespaced (optional) get the normal XML string or a version with different namespaces (defaults to false for non-namespaced XML)
     * @return string XML-Document as plain text string
     */
    public function toXml($namespaced = false) {
        $xml = new DAIA_XML($this);
        if ($namespaced === true) {
        	return $xml->createNamespacedXml()->saveXml();
        }
        return $xml->createXml()->saveXml();
    }

    public function toJson() {
        // TODO implement it
        return 'not yet implemented';
        /* not yet implemented
        $json = new DAIA_JSON($this);
        return $json->createJson();
        */
    }
}
?>
