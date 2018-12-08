#include "grid.h"
#include <stdio.h>
#include <unistd.h>
#include <time.h>

int main(int argc, char** argv)
{
    struct timespec ts1, ts2;

    ts1.tv_sec = 0;
    ts1.tv_nsec = 500000000;

    grid_set_cell(20, 10, CELL_OCCUPIED);
    grid_set_cell(21, 10, CELL_OCCUPIED);
    grid_set_cell(21, 11, CELL_OCCUPIED);
    grid_set_cell(22, 11, CELL_OCCUPIED);
    grid_set_cell(22, 12, CELL_OCCUPIED);
    grid_set_cell(23, 12, CELL_OCCUPIED);

    grid_set_cell(20, 30, CELL_OCCUPIED);
    grid_set_cell(21, 30, CELL_OCCUPIED);
    grid_set_cell(22, 30, CELL_OCCUPIED);
    grid_set_cell(23, 30, CELL_OCCUPIED);
    grid_set_cell(24, 30, CELL_OCCUPIED);

    while (1) {
        grid_display_on_stdout('+', ' ');
        grid_apply_rules(); 
        printf("---------------------------------\n");
        nanosleep(&ts1, &ts2);
    }

    return 0;
}
