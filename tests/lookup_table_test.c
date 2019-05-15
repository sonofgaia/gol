#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>

void load_cells_for_key(uint32_t key, bool *arr);
bool get_new_cell_value(uint8_t neighbor_count, bool old_value);
uint8_t get_new_cell_values_for_key(uint32_t key);
void display_results(uint32_t key, uint8_t values);

bool cells[16];
uint8_t lookup_table[65536];

int main(int argc, char **argv)
{
    uint32_t key;
    uint32_t last_key = (uint32_t)(pow(2, 16) - 1);
    uint8_t new_values, lookup_values;
    FILE *fp;

    fp = fopen("../build/bin/lookup_table.bin", "r");
    fread(lookup_table, 65536, 1, fp);
    fclose(fp);

    for (key = 0; key <= last_key; key++) {
        new_values = get_new_cell_values_for_key(key);
        lookup_values = lookup_table[key];

        if (new_values != lookup_values) {
            printf("Lookup table is corrupted\n");
            exit(1);
        }

        display_results(key, new_values);
    }

    printf("All good\n");
    exit(0);
}

void load_cells_for_key(uint32_t key, bool *arr)
{
    for (int i = 0; i < 16; i++) {
        arr[i] = (key >> i) & 0x1;
    }
}

bool get_new_cell_value(uint8_t neighbor_count, bool old_value)
{
    if (old_value == 0) {
        if (neighbor_count == 3)
            return true;
        else
            return false;        
    }

    if (neighbor_count == 2 || neighbor_count == 3)
        return true;
    else
        return false;
}

uint8_t get_new_cell_values_for_key(uint32_t key)
{
    load_cells_for_key(key, cells);

    /**
     * 15 11 07 03
     * 14 10 06 02
     * 13 09 05 01
     * 12 08 04 00
     */
    uint8_t neighbor_count1 = cells[5] + cells[6] + cells[7] + cells[9] + cells[11] + cells[13] + cells[14] + cells[15];
    uint8_t neighbor_count2 = cells[4] + cells[5] + cells[6] + cells[8] + cells[10] + cells[12] + cells[13] + cells[14];
    uint8_t neighbor_count3 = cells[1] + cells[2] + cells[3] + cells[5] + cells[7] + cells[9] + cells[10] + cells[11];
    uint8_t neighbor_count4 = cells[0] + cells[1] + cells[2] + cells[4] + cells[6] + cells[8] + cells[9] + cells[10];

    bool new_value1 = get_new_cell_value(neighbor_count1, cells[10]);
    bool new_value2 = get_new_cell_value(neighbor_count2, cells[9]);
    bool new_value3 = get_new_cell_value(neighbor_count3, cells[6]);
    bool new_value4 = get_new_cell_value(neighbor_count4, cells[5]);

    return new_value1 | (new_value2 << 1) | (new_value3 << 2) | (new_value4 << 3);
}


void display_results(uint32_t key, uint8_t values)
{
    load_cells_for_key(key, cells);
    uint8_t v1, v2, v3, v4;

    v1 = values & 0x1;
    v2 = (values >> 1) & 0x1;
    v3 = (values >> 2) & 0x1;
    v4 = (values >> 3) & 0x1;
    
    printf("%i %i %i %i\n", cells[15], cells[11], cells[7], cells[3]);
    printf("%i %i %i %i        => %i %i\n", cells[14], cells[10], cells[6], cells[2], v1, v3);
    printf("%i %i %i %i           %i %i\n", cells[13], cells[9], cells[5], cells[1], v2, v4);
    printf("%i %i %i %i\n\n", cells[12], cells[8], cells[4], cells[0]);
}
