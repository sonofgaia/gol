BINFILE=main.nes
LINKER_CFG_FILE=linker.cfg
LIB_DIR=/usr/local/share/cc65/lib

INCLUDES = -I /usr/local/share/cc65/asminc \
		  -I /usr/local/share/cc65/include \
		  -I src/core/include \
		  -I src

OBJ = build/obj/core/asm_gamepad.o \
	  build/obj/core/asm_init.o \
	  build/obj/core/asm_ppu.o \
	  build/obj/core/asm_oam.o \
	  build/obj/core/asm_lib.o \
	  build/obj/core/asm_nmi_task_list.o \
	  build/obj/core/asm_mmc3.o \
	  build/obj/core/c_nmi_task_list.o \
	  build/obj/core/c_ppu.o \
	  build/obj/core/c_oam.o \
	  build/obj/core/c_mmc3.o \
	  build/obj/c_main.o \
	  build/obj/c_grid.o \
	  build/obj/asm_grid.o \
	  build/obj/c_grid_draw.o \
	  build/obj/asm_grid_draw.o \
	  build/obj/asm_lookup_table_algo.o \
	  build/obj/scenarios.o

.SECONDARY:
all: build/bin/main.nes build/bin/main.nes.0.nl build/bin/lookup_table_test

build/obj/scenarios.o: build/asm/scenarios.s src/scenarios.txt
	ca65 $(INCLUDES) $< -g -o $@

build/obj/core/asm_%.o: src/core/%.asm
	ca65 $(INCLUDES) $< -g -o $@ 

build/obj/asm_lookup_table_algo.o: src/lookup_table_algo.asm build/bin/lookup_table.bin
	ca65 $(INCLUDES) $< -g -o $@ 

build/obj/core/asm_init.o: src/core/init.asm chr/Alpha.chr
	ca65 $(INCLUDES) $< -g -o $@

build/obj/asm_%.o: src/%.asm
	ca65 $(INCLUDES) $< -g -o $@ 

build/asm/core/c_nmi_task_list.s: src/core/nmi_task_list.c src/core/include/nmi_task_list.h
	cc65 -Oir $(INCLUDES) $< -g -o $@ 

build/asm/core/c_%.s: src/core/%.c
	cc65 -Oir $(INCLUDES) $< -g -o $@ 

build/asm/c_%.s: src/%.c
	cc65 -Oir $(INCLUDES) $< -g -o $@ 

build/obj/core/c_%.o: build/asm/core/c_%.s
	ca65 $(INCLUDES) $< -g -o $@ 

build/obj/c_%.o: build/asm/c_%.s
	ca65 $(INCLUDES) $< -g -o $@ 

build/bin/main.nes.0.nl: build/bin/main.nes build/debug/main.labels.txt
	./script/create_nl.php > build/bin/main.nes.0.nl

build/debug/main.labels.txt: build/bin/main.nes

build/bin/lookup_table.bin: script/create_lookup_table.php
	./script/create_lookup_table.php > build/bin/lookup_table.bin

build/asm/scenarios.s: script/compile_scenarios.php src/scenarios.txt
	./script/compile_scenarios.php > build/asm/scenarios.s

build/bin/main.nes: $(OBJ) lib/nes.lib
	ld65 -Ln build/debug/main.labels.txt -C $(LINKER_CFG_FILE) --dbgfile build/debug/main.nes.dbg -m build/debug/main.map.txt -o build/bin/$(BINFILE) $^

clean:
	- rm -rf build/*
	- mkdir -p build/debug
	- mkdir -p build/bin
	- mkdir -p build/obj/core
	- mkdir -p build/asm/core

build/bin/lookup_table_test: tests/lookup_table_test.c
	gcc tests/lookup_table_test.c -o build/bin/lookup_table_test

