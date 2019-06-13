#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>

#define LOOKUP_TABLE_SIZE_BYTES 65536
#define LOOKUP_TABLE_FILE_PATH  "./lookup_table.bin"

struct lookup_key_cells_struct {
    uint16_t c00 :1;
    uint16_t c01 :1;
    uint16_t c02 :1;
    uint16_t c03 :1;
    uint16_t c04 :1;
    uint16_t c05 :1;
    uint16_t c06 :1;
    uint16_t c07 :1;
    uint16_t c08 :1;
    uint16_t c09 :1;
    uint16_t c10 :1;
    uint16_t c11 :1;
    uint16_t c12 :1;
    uint16_t c13 :1;
    uint16_t c14 :1;
    uint16_t c15 :1;
};

typedef union {
    uint32_t value;
    struct lookup_key_cells_struct cells;
} lookup_key_t;

struct lookup_result_cells_struct {
    uint8_t upper_left  :1;
    uint8_t lower_left  :1;
    uint8_t upper_right :1;
    uint8_t lower_right :1;
    uint8_t unused      :4;
};

typedef union {
    uint8_t value;
    struct lookup_result_cells_struct cells;
} lookup_result_t;

void lookup_result_init(lookup_result_t *result)
{
    result->value = 0;
}

typedef lookup_result_t lookup_table_t[LOOKUP_TABLE_SIZE_BYTES]; 

bool lookup_table_load(const char *path, lookup_table_t *table_buf);
bool get_new_cell_value(uint8_t neighbor_count, bool old_value);
lookup_result_t get_new_cell_values_for_key(lookup_key_t key);
void display_results(lookup_key_t key, lookup_result_t values);


int main(int argc, char **argv)
{
    lookup_table_t  lookup_table;
    lookup_key_t    key, last_key;
    lookup_result_t calculated_result, lookup_result;

    last_key.value = pow(2, 16) - 1;

    lookup_table_load(LOOKUP_TABLE_FILE_PATH, &lookup_table);

    for (key.value = 0; key.value <= last_key.value; key.value++) {
        lookup_result     = lookup_table[key.value];
        lookup_result.value = lookup_result.value >> 4; // Format of lookup table has been changed..
        calculated_result = get_new_cell_values_for_key(key);

        if (calculated_result.value != lookup_result.value) {
            printf("%d != %d\n", calculated_result.value, lookup_result.value);
            printf("Calculated :\n");
            display_results(key, calculated_result);
            printf("Lookup     :\n");
            display_results(key, lookup_result);

            return -1;
        }
    }

    printf("Lookup table file is valid\n");

    return 0;
}

bool lookup_table_load(const char *path, lookup_table_t *table_buf)
{
    FILE *fp;

    fp = fopen(path, "r");
    fread(table_buf, LOOKUP_TABLE_SIZE_BYTES, 1, fp);
    fclose(fp);

    return true;
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

lookup_result_t get_new_cell_values_for_key(lookup_key_t key)
{
    lookup_result_t result;
    uint8_t neighbor_count1, neighbor_count2, neighbor_count3, neighbor_count4;
    struct lookup_key_cells_struct *c = &key.cells;

    lookup_result_init(&result);

    /**
     * 15 11 07 03
     * 14 10 06 02
     * 13 09 05 01
     * 12 08 04 00
     */
    neighbor_count1 = c->c05 + c->c06 + c->c07 + c->c09 + c->c11 + c->c13 + c->c14 + c->c15;
    neighbor_count2 = c->c04 + c->c05 + c->c06 + c->c08 + c->c10 + c->c12 + c->c13 + c->c14;
    neighbor_count3 = c->c01 + c->c02 + c->c03 + c->c05 + c->c07 + c->c09 + c->c10 + c->c11;
    neighbor_count4 = c->c00 + c->c01 + c->c02 + c->c04 + c->c06 + c->c08 + c->c09 + c->c10;

    result.cells.upper_left  = get_new_cell_value(neighbor_count1, c->c10);
    result.cells.lower_left  = get_new_cell_value(neighbor_count2, c->c09);
    result.cells.upper_right = get_new_cell_value(neighbor_count3, c->c06);
    result.cells.lower_right = get_new_cell_value(neighbor_count4, c->c05);

    return result;
}


void display_results(lookup_key_t key, lookup_result_t result)
{
    struct lookup_key_cells_struct    *k = &key.cells;
    struct lookup_result_cells_struct *r = &result.cells;
    
    printf("%i %i %i %i           \n", k->c15, k->c11, k->c07, k->c03);
    printf("%i %i %i %i   => %i %i\n", k->c14, k->c10, k->c06, k->c02, r->upper_left, r->upper_right);
    printf("%i %i %i %i      %i %i\n", k->c13, k->c09, k->c05, k->c01, r->lower_left, r->lower_right);
    printf("%i %i %i %i         \n\n", k->c12, k->c08, k->c04, k->c00);
}
