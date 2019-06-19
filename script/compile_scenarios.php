#!/usr/bin/php
<?php
define('BANK_BYTES', 8192);

$scenarios_file          = fopen('./src/scenarios.txt', 'r') or die('Failed to open file');
$scenarios_asm_file      = fopen('./build/asm/scenarios.s', 'w+') or die('Failed to open file for write');
$scenarios_c_header_file = fopen('./build/include/scenarios.h', 'w+') or die('Failed to open file for write');

$scenario = [
    'name'        => '',
    'offsetX'     => 0,
    'offsetY'     => 0,
    'lines'       => [],
    'livingCells' => []
];

$scenarios = [];

function closeScenario()
{
    global $scenario;
    global $scenarios;

    if (!$scenario['name']) return; // No scenarios loaded.

    $scenarios[] = $scenario;
}

while ($line = fgets($scenarios_file)) {
    if (preg_match('/\[(?P<pattern_name>.+?)\],(?P<offset_x>\d+),(?P<offset_y>\d+)/', $line, $matches)) {
        // Close currently opened scenario
        closeScenario();

        $scenario['name']        = $matches['pattern_name'];
        $scenario['offsetX']     = $matches['offset_x'];
        $scenario['offsetY']     = $matches['offset_y'];
        $scenario['lines']       = [];
        $scenario['livingCells'] = [];
    } else {
        // Read a scenario row.
        if (!trim($line)) continue; // Skip whitespace

        for ($i = 0; $i < strlen($line); $i++) {
            if ($line[$i] == 'O') {
                $scenario['livingCells'][] = ['x' => $i, 'y' => count($scenario['lines'])];
            }
        }

        $scenario['lines'][] = $line;
    }
}

closeScenario();

fclose($scenarios_file);

fwrite($scenarios_asm_file, ".import _grid_buffer1\n\n");

fwrite($scenarios_c_header_file, "#ifndef _SCENARIOS_H_\n");
fwrite($scenarios_c_header_file, "#define _SCENARIOS_H_\n");

foreach ($scenarios as $k => $scenario) {
    $scenarioNumber = $k + 1;

    fwrite($scenarios_c_header_file, "extern void scenario_{$scenarioNumber}(void);\n");
}

fwrite($scenarios_c_header_file, "\n");
fwrite($scenarios_c_header_file, "typedef struct {\n");
fwrite($scenarios_c_header_file, "    uint8_t bank_number;\n");
fwrite($scenarios_c_header_file, "    void (*scenario_ptr)(void);\n");
fwrite($scenarios_c_header_file, "} scenario_load_settings_t;\n");
fwrite($scenarios_c_header_file, "\n");
fwrite($scenarios_c_header_file, "const scenario_load_settings_t const scenario_settings[] = {\n");

$spaceLeft = BANK_BYTES;
$bankNumber = 8;

foreach ($scenarios as $k => $scenario) {
    $scenarioNumber = $k + 1;
    $sizeBytes = count($scenario['livingCells']) * 3 + 3;

    if ($sizeBytes > $spaceLeft) {
        $bankNumber++;
        $spaceLeft = BANK_BYTES;
    }

    $spaceLeft -= $sizeBytes;

    $sep = ($k + 1) < count($scenarios) ? ',' : '';
    fwrite($scenarios_c_header_file, "  {{$bankNumber}, scenario_{$scenarioNumber}}{$sep}\n");

    fwrite($scenarios_asm_file, ".export _scenario_{$scenarioNumber}\n\n");
    fwrite($scenarios_asm_file, ".segment \"SCENARIOS_BANK_{$bankNumber}\"\n");
    fwrite($scenarios_asm_file, ".proc _scenario_{$scenarioNumber}\n");
    fwrite($scenarios_asm_file, "    lda #1\n");

    foreach ($scenario['livingCells'] as $cell) {
        $offset = ($cell['y'] + $scenario['offsetY']) * 64 + ($cell['x'] + $scenario['offsetX']);
        fwrite($scenarios_asm_file, "    sta _grid_buffer1 + {$offset}\n");
    }

    fwrite($scenarios_asm_file, "    rts\n");
    fwrite($scenarios_asm_file, ".endproc\n\n");
}

fwrite($scenarios_c_header_file, "};\n");

fwrite($scenarios_c_header_file, "#endif\n");

fclose($scenarios_asm_file);
fclose($scenarios_c_header_file);
