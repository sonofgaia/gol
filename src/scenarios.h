#ifndef _SCENARIOS_H_
#define _SCENARIOS_H_

#include <stdint.h>
#include "grid.h"

#define SCENARIO_ARRAY_BYTES (GRID_COLS * GRID_ROWS / 8)

typedef uint8_t scenario_t[SCENARIO_ARRAY_BYTES];

void scenarios__load(uint8_t *scenario);

extern scenario_t scenario_01;

#endif
