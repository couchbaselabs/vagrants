<?php

// Connect to Couchbase Server

$cluster = new CouchbaseCluster('http://10.4.2.121:8091');
$bucket = $cluster->openBucket('beer-sample');

// Retrieve a document

$result = $bucket->get('aass_brewery-juleol');
$doc = $result->value;

echo $doc->name . ', ABV: ' . $doc->abv . "\n";

// Store a document

$doc->comment = 'Random beer from Norway';

$result = $bucket->replace('aass_brewery-juleol', $doc);

var_dump($result);

?>

