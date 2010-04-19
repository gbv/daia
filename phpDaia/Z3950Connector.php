<?php
/*
 * Created on 09.03.2010
 * 
 * Singleton holding the instance of a Z3950 connection
 */

class Z3950Connector {

    private $user="999";
    private $passwd="abc";
    private $host="z3950.gbv.de:20012/harb_opc"; // host port database
    private $con;
    
    private static $instanceFile = '/tmp/z3950php.tmp';
	
	private function __construct() {
		$connection = yaz_connect( $this->host, array( "user" =>$this->user , "password" =>$this->passwd , "persistent" => true ));
		yaz_wait();
		$this->con = $connection;
		print_r($this);
		if ($this->con === '0') {
			echo "Connection failed!";
		}
	}
	
	public static function getInstance() {
		if (file_exists(self::$instanceFile) === true) {
			$inst = implode('', file(self::$instanceFile));
			$instance = unserialize($inst);
		}
		else {
			try {
				$instance = new Z3950Connector();
			}
			catch (Exception $e) {
				throw $e;
				return $instance;
			}
			$inst = fopen(self::$instanceFile, 'w');
			fwrite($inst, serialize($instance));
			fclose($inst);
		}
		return $instance;
	}

	public function getConnection() {
	    $conn = yaz_connect( $this->host, array( "user" =>$this->user , "password" =>$this->passwd , "persistent" => true ));
		return $conn;
	}
}
?>
