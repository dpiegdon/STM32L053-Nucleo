#######################################################################
# Makefile for STM32L053R8T6 projects
#
# STM32L053R8T6 has 8KB RAM

PROJECT = main
CUBE_PATH ?= STM32CubeL0
OPENOCD_SCRIPT_DIR ?= /usr/share/openocd/scripts
HEAP_SIZE = 0x100

################
# Sources

SOURCES_S = ${CUBE_PATH}/Drivers/CMSIS/Device/ST/STM32L0xx/Source/Templates/gcc/startup_stm32l053xx.s

SOURCES_C = src/main.c

SOURCES_C += sys/stubs.c sys/_sbrk.c
SOURCES_C += ${CUBE_PATH}/Drivers/CMSIS/Device/ST/STM32L0xx/Source/Templates/system_stm32l0xx.c
SOURCES_C += ${CUBE_PATH}/Drivers/BSP/STM32L0xx_Nucleo/stm32l0xx_nucleo.c
SOURCES_C += ${CUBE_PATH}/Drivers/STM32L0xx_HAL_Driver/Src/stm32l0xx_hal_gpio.c

SOURCES_CPP =

SOURCES = $(SOURCES_S) $(SOURCES_C) $(SOURCES_CPP)
OBJS = $(SOURCES_S:.s=.o) $(SOURCES_C:.c=.o) $(SOURCES_CPP:.cpp=.o)

################
# Includes and Defines

INCLUDES += -I src
INCLUDES += -I ${CUBE_PATH}/Drivers/CMSIS/Include
INCLUDES += -I ${CUBE_PATH}/Drivers/CMSIS/Device/ST/STM32L0xx/Include
INCLUDES += -I ${CUBE_PATH}/Drivers/STM32L0xx_HAL_Driver/Inc
INCLUDES += -I ${CUBE_PATH}/Drivers/BSP/STM32L0xx_Nucleo

DEFINES = -DSTM32 -DSTM32L0 -DSTM32L053xx

################
# Compiler/Assembler/Linker/etc

PREFIX = arm-none-eabi

CC = $(PREFIX)-gcc
AS = $(PREFIX)-as
AR = $(PREFIX)-ar
LD = $(PREFIX)-gcc
NM = $(PREFIX)-nm
OBJCOPY = $(PREFIX)-objcopy
OBJDUMP = $(PREFIX)-objdump
READELF = $(PREFIX)-readelf
SIZE = $(PREFIX)-size
GDB = $(PREFIX)-gdb
RM = rm -f
OPENOCD=openocd

################
# Compiler options

MCUFLAGS = -mcpu=cortex-m0plus -mlittle-endian
MCUFLAGS += -mfloat-abi=soft
MCUFLAGS += -mthumb

DEBUG_OPTIMIZE_FLAGS = -O0 -g -ggdb3
#DEBUG_OPTIMIZE_FLAGS = -O2

CFLAGS = -std=c11
CFLAGS += -Wall -Wextra --pedantic
# generate listing files
CFLAGS += -Wa,-aghlms=$(<:%.c=%.lst)
CFLAGS += -DHEAP_SIZE=$(HEAP_SIZE)
CFLAGS += -fstack-usage

CFLAGS_EXTRA = -nostartfiles -nodefaultlibs -nostdlib
CFLAGS_EXTRA += -fdata-sections -ffunction-sections

CFLAGS += $(DEFINES) $(MCUFLAGS) $(DEBUG_OPTIMIZE_FLAGS) $(CFLAGS_EXTRA) $(INCLUDES)

LDFLAGS = -static $(MCUFLAGS)
LDFLAGS += -Wl,--start-group -lgcc -lm -lc -lg -lstdc++ -lsupc++ -Wl,--end-group
LDFLAGS += -Wl,--gc-sections -Wl,--print-gc-sections -Wl,--cref,-Map=$(@:%.elf=%.map)
LDFLAGS += -Wl,--print-memory-usage
LDFLAGS += -L ${CUBE_PATH}/Projects/NUCLEO-L053R8/Templates/SW4STM32/STM32L053R8_NUCLEO/ -T STM32L053R8Tx_FLASH.ld

################
# phony rules

.PHONY: all clean flash erase

all: $(PROJECT).bin $(PROJECT).hex $(PROJECT).asm

clean:
	$(RM) $(OBJS) $(OBJS:$.o=$.lst) $(OBJS:$.o=$.su) $(PROJECT).elf $(PROJECT).bin $(PROJECT).hex $(PROJECT).map $(PROJECT).asm

BMP_DEVICE ?= /dev/ttyACM0
JLINK_CPUNAME ?= STM32L053R8
flash-bmp: $(PROJECT).elf
	# assuming:
	#  * Black Magic Probe connected to $(BMP_DEVICE)
	#  * compatible Nordic MCU connected via SWD
	$(GDB) $(PROJECT).elf \
		-ex 'set confirm off' \
		-ex 'target extended-remote $(BMP_DEVICE)' \
		-ex 'mon hard_srst' \
		-ex 'mon swdp_scan' \
		-ex 'attach 1' \
		-ex 'load' \
		-ex 'compare-sections' \
		-ex 'quit'

flash-jlink: $(PROJECT).bin
	# assuming:
	#  * any type of Segger JLINK that is usable with an nRF52 CPU
	#    (e.g. the embedded jlink on the DK)
	#  * compatible Nordic MCU connected via SWD
	#  * installed JLink Software
	printf "erase\nloadfile $<\nr\nq\n" | JLinkExe -nogui 1 -autoconnect 1 -device $(JLINK_CPUNAME) -if swd -speed 4000

erase-jlink:
	printf "erase\nr\nq\n" | JLinkExe -nogui 1 -autoconnect 1 -device $(JLINK_CPUNAME) -if swd -speed 4000

################
# dependency graphs for wildcard rules

$(PROJECT).elf: $(OBJS)

################
# wildcard rules

%.elf:
	$(LD) $(OBJS) $(LDFLAGS) -o $@
	$(SIZE) -A $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.hex: %.elf
	$(OBJCOPY) -O ihex $< $@

%.asm: %.elf
	$(OBJDUMP) -dgCxwsSh --show-raw-insn $< > $@

# EOF
