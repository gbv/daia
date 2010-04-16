#!/usr/local/php/bin/php
<?php
include_once 'daia.php';

class DAIATest extends MyUnitTest {

    function staticMethods() {
        $daia = new DAIA();
        $this->assertTrue($daia);
    }
}
?>
