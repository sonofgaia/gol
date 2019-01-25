#!/usr/bin/php
<?php
define('TABLE_KEY_BITS', 16);

function table_keys_generator()
{
    $maxVal = pow(2, TABLE_KEY_BITS) - 1;

    for ($i = 0; $i <= $maxVal; $i++) {
        yield $i;
    }
}

function get_cell_values_from_key($key)
{
    $cellValues = [];

    for ($i = 0; $i < TABLE_KEY_BITS; $i++) {
        $cellValues[$i] = ($key >> $i) & 0x1;
    }

    return $cellValues;
}

function get_new_cell_value($neighborCount, $oldValue)
{
    if ($oldValue == 0) {
        if ($neighborCount == 3)
            return 1;
        else
            return 0;
    }

    if ($neighborCount == 2 || $neighborCount == 3)
        return 1;
    else
        return 0;
}

function get_new_cell_values_for_key($key)
{
    $cv = get_cell_values_from_key($key);

    /**
     *  0  1  2  3
     *  4  5  6  7
     *  8  9 10 11
     * 12 13 14 15
     */
    $neighborCount1 = $cv[0] + $cv[1] + $cv[2] + $cv[4] + $cv[6] + $cv[8] + $cv[9] + $cv[10];
    $neighborCount2 = $cv[1] + $cv[2] + $cv[3] + $cv[5] + $cv[7] + $cv[9] + $cv[10] + $cv[11];
    $neighborCount3 = $cv[4] + $cv[5] + $cv[6] + $cv[8] + $cv[10] + $cv[12] + $cv[13] + $cv[14];
    $neighborCount4 = $cv[5] + $cv[6] + $cv[7] + $cv[9] + $cv[11] + $cv[13] + $cv[14] + $cv[15];

    $newValue1 = get_new_cell_value($neighborCount1, $cv[5]);
    $newValue2 = get_new_cell_value($neighborCount2, $cv[6]);
    $newValue3 = get_new_cell_value($neighborCount3, $cv[9]);
    $newValue4 = get_new_cell_value($neighborCount4, $cv[10]);

    return $newValue4 | ($newValue3 << 1) | ($newValue2 << 2) | ($newValue1 << 3);
}

$fp = fopen('php://stdout', 'w+');

$tableKeys = table_keys_generator();

foreach ($tableKeys as $tableKey) {
    fwrite($fp, pack('C', get_new_cell_values_for_key($tableKey)), 1);
}

fclose($fp);
