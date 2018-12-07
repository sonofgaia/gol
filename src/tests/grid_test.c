#include "grid.h"
#include <stdio.h>
#include <unistd.h>

int main(int argc, char** argv)
{
    grid_set_cell(20, 10, CELL_OCCUPIED);
    grid_set_cell(21, 10, CELL_OCCUPIED);
//    grid_set_cell(20, 21, CELL_OCCUPIED);
//    grid_set_cell(21, 21, CELL_OCCUPIED);
    grid_set_cell(22, 10, CELL_OCCUPIED);
    grid_set_cell(23, 10, CELL_OCCUPIED);
    grid_set_cell(24, 10, CELL_OCCUPIED);

    while (1) {
        grid_display_on_stdout('+', ' ');
        grid_apply_rules(); 
        printf("---------------------------------\n");
        sleep(1);
    }

    return 0;
}
