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
	  build/obj/core/c_nmi_task_list.o \
	  build/obj/core/c_ppu.o \
	  build/obj/core/c_oam.o \
	  build/obj/c_main.o \
	  build/obj/c_grid.o

.SECONDARY:
build/obj/core/asm_%.o: src/core/%.asm
	ca65 $(INCLUDES) $< -g -o $@ 

build/asm/core/c_%.s: src/core/%.c
	cc65 -Oi $(INCLUDES) $< -g -o $@ 

build/asm/c_%.s: src/%.c
	cc65 -Oi $(INCLUDES) $< -g -o $@ 

build/obj/core/c_%.o: build/asm/core/c_%.s
	ca65 $(INCLUDES) $< -g -o $@ 

build/obj/c_%.o: build/asm/c_%.s
	ca65 $(INCLUDES) $< -g -o $@ 

#all: bin/main.nes debug_syms
all: build/bin/main.nes

build/bin/main.nes: $(OBJ) lib/nes.lib
	ld65 -Ln build/debug/main.labels.txt -C $(LINKER_CFG_FILE) --dbgfile build/debug/main.nes.dbg -m build/debug/main.map.txt -o build/bin/$(BINFILE) $^

#build/bin/grid_test: src/tests/grid_test.c src/grid.c src/grid.h
#	gcc -D_DEBUG_ -I src -I src/core/include src/tests/grid_test.c src/grid.c -o build/bin/grid_test

#debug_syms: bin/main.nes.0.nl bin/main.nes.1.nl bin/main.nes.ram.nl

#bin/main.nes.ram.nl: debug/main.labels.txt
#	python3 bin/main_fceux_symbols.py
#bin/main.nes.0.nl: debug/main.labels.txt
#	python3 bin/main_fceux_symbols.py
#bin/main.nes.1.nl: debug/main.labels.txt
#	python3 bin/main_fceux_symbols.py

clean:
	- rm -rf build/*
	- mkdir -p build/debug
	- mkdir -p build/bin
	- mkdir -p build/obj/core
	- mkdir -p build/asm/core
