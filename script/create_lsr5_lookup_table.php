#!/usr/bin/php
<?php

echo ".segment \"CODE\"\n";
echo "lsr5_lookup_table:\n";

for ($i = 0; $i < 256; $i++) {
    echo sprintf(".byte $%x\n", $i >> 5);
}
