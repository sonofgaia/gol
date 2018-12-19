#!/usr/bin/php
<?php
$labels_file = fopen('./build/debug/main.labels.txt', 'r') or die('Failed to open file');

while ($line = fgets($labels_file))
{
    if (preg_match('/([0-9A-F]{4})\s{1}\.(.+)$/', $line, $matches)) {
        $symbol = $matches[2];
        $addr   = $matches[1];
        
        if (substr($symbol, 0, 2) == '__') {
            continue; // Skip symbols with a leading double underscore.
        }

        echo "\${$addr}#{$symbol}#\n";
    }
}

fclose($labels_file);
