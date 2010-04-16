<?php

error_reporting (E_ALL ^ E_NOTICE );

/**
 * Simple test runner based on SimpleTest.
 *
 * By default runs all tests in directory ./test. 
 *
 * You can select specific of these tests as command line arguments.
 *
 * @author Jakob Voss
 */

$testdir = dirname(__FILE__)."/test";

if ($argv) {
    array_shift($argv);
    foreach($argv as $name) {
        $name = preg_replace('/^test[_]?|\.php$/','',$name);
        $testonly[$name] = true;
    }
}

$dir = dir($testdir);
while ($file = $dir->read()) {
    if (!preg_match('/^([^.].*)\.php$/',$file,$match)) continue;
    if ($testonly) {
        $name = preg_replace('/^test[_]?|/','',$match[1]);
        if (!$testonly[$name]) continue;
    }
    $testfiles[] = "$testdir/$file";
}
$dir->close();


$testname = $testonly ? "All tests" : "Selected tests";

if (!$testfiles) {
    print "Nothing to test in directory $testdir!\n";
    exit;
}

// first try SimpleTest which is old but slim
if(@include_once('simpletest/autorun.php')) {
    $suite = &new TestSuite($testname);

    class MyUnitTest extends UnitTestCase { }

    foreach ($testfiles as $file)
        $suite->addFile($file);

    $suite->run(new DefaultReporter());
} elseif(@include_once('PHPUnit/Framework.php')) {
    # TODO: switch to PHPUnit
    print "PHPUnit is not supported yet!\n";
} else {
    print "All tests are skipped due to lack of a testing framework!\n";
}

?>