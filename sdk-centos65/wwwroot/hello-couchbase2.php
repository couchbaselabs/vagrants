<?php

// Connect to Couchbase Server

$cluster = new CouchbaseCluster('http://10.4.2.121:8091');
$bucket = $cluster->openBucket('beer-sample');

// Retrieve a document

$result = $bucket->get('aass_brewery-juleol');
echo "After get()\n";
echo "Class of result is: " . get_class($result) . "\n";
// echo 'Result: '.$result."\n";

var_dump($result);
echo '<br>';

$james = json_decode($result->value);
var_dump($james);
echo '<br>';

$doc = $result->value;
echo 'Doc: '.$doc."\n";
echo "Class of doc is: " . get_class($doc) . "\n";

// var_dump($doc);

echo $james->name . ', ABV: ' . $doc->abv . "\n";

// Store a document
//$doc->comment = 'Random beer from Norway';
//$result = $bucket->replace('aass_brewery-juleol', $doc);
// var_dump($result);

?>

