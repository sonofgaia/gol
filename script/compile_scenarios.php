#!/usr/bin/php
<?php
$scenarios_file = fopen('./src/scenarios.txt', 'r') or die('Failed to open file');

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

echo ".import _grid_buffer1\n\n";

foreach ($scenarios as $k => $scenario) {
    $scenarioNumber = $k + 1;
    echo ".export _scenario_{$scenarioNumber}\n\n";
    echo ".segment \"CODE\"\n";
    echo ".proc _scenario_{$scenarioNumber}\n";
    echo "    lda #1\n";

    foreach ($scenario['livingCells'] as $cell) {
        $offset = ($cell['y'] + $scenario['offsetY']) * 66 + ($cell['x'] + $scenario['offsetX']);
        echo "    sta _grid_buffer1 + {$offset}\n";
    }

    echo "    rts\n";
    echo ".endproc\n\n";
}
