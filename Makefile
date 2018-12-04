BINFILE=main.nes
LINKER_CFG_FILE=linker.cfg
LIB_DIR=/usr/local/share/cc65/lib

INCLUDES = -I /usr/local/share/cc65/asminc \
		  -I /usr/local/share/cc65/include \
		  -I src/core/include

OBJ = build/obj/core/asm_gamepad.o \
	  build/obj/core/asm_init.o \
	  build/obj/core/asm_ppu.o \
	  build/obj/core/c_ppu.o \
	  build/obj/c_main.o

.SECONDARY:
build/obj/core/asm_%.o: src/core/%.asm
	ca65 $(INCLUDES) -v $< -g -o $@ 

build/asm/core/c_%.s: src/core/%.c
	cc65 $(INCLUDES) -v $< -g -o $@ 

build/asm/c_%.s: src/%.c
	cc65 $(INCLUDES) -v $< -g -o $@ 

build/obj/core/c_%.o: build/asm/core/c_%.s
	ca65 $(INCLUDES) -v $< -g -o $@ 

build/obj/c_%.o: build/asm/c_%.s
	ca65 $(INCLUDES) -v $< -g -o $@ 

#all: bin/main.nes debug_syms
all: build/bin/main.nes

build/bin/main.nes: $(OBJ) nes.lib
	ld65 -Ln build/debug/main.labels.txt -C $(LINKER_CFG_FILE) --dbgfile build/debug/main.nes.dbg -m build/debug/main.map.txt -o build/bin/$(BINFILE) $^

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
