#!/usr/bin/php
<?php
$labels_file = fopen('./build/debug/main.labels.txt', 'r') or die('Failed to open file');

while ($line = fgets($labels_file))
{
    if (preg_match('/([0-9A-F]{4})\s{1}\.(.+)$/', $line, $matches)) {
        $symbol = $matches[2];
        $addr   = $matches[1];
        
        if (preg_match('/^__[A-Z]{1}/', $symbol)) {
            continue; // Skip symbols with a leading double underscore followed by an upper-case letter.
        }

        echo "\${$addr}#{$symbol}#\n";
    }
}

fclose($labels_file);
