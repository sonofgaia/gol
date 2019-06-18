#!/usr/bin/php
<?php

echo ".segment \"CODE\"\n";
echo "and1f_or80_lookup_table:\n";

for ($i = 0; $i < 256; $i++) {
    echo sprintf(".byte $%x\n", $i & 0x1f | 0x80);
}
