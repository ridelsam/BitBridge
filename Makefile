TOOLCHAIN_DIR ?= $(HOME)/tools/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi
CC := $(TOOLCHAIN_DIR)/bin/arm-none-eabi-gcc

TARGET_FLAGS := -mcpu=cortex-m7 -mthumb \
                -mfpu=fpv5-d16 -mfloat-abi=hard

CPPFLAGS := -DSTM32F767xx -DUSE_HAL_DRIVER \
            -ICore/Inc \
            -IDrivers/STM32F7xx_HAL_Driver/Inc \
            -IDrivers/CMSIS/Device/ST/STM32F7xx/Include \
            -IDrivers/CMSIS/Include

CFLAGS := $(TARGET_FLAGS) -std=gnu11 -Og -g3 -Wall -Wextra \
          -MMD -MP

CFLAGS += --specs=nano.specs -ffunction-sections -fdata-sections

LINKER_SCRIPT := STM32F767ZITX_FLASH.ld

LDFLAGS := $(TARGET_FLAGS) \
           --specs=nano.specs --specs=nosys.specs \
           -T$(LINKER_SCRIPT) \
           -Wl,--gc-sections,-Map=build/BitBridge.map,--print-memory-usage

C_SOURCES := \
    Core/Src/main.c \
    Core/Src/system_stm32f7xx.c \
    Core/Src/stm32f7xx_it.c \
    Core/Src/stm32f7xx_hal_msp.c \
    Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal.c \
    Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_cortex.c \
    Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_gpio.c \
    Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_rcc.c \
    Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_uart.c \
    Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_uart_ex.c

ASM_SOURCE := Core/Startup/startup_stm32f767zitx.s

OBJECTS := $(addprefix build/,$(C_SOURCES:.c=.o)) \
           $(addprefix build/,$(ASM_SOURCE:.s=.o))

.DEFAULT_GOAL := all

.PHONY: all
all: build/BitBridge.elf

build/BitBridge.elf: $(OBJECTS) $(LINKER_SCRIPT) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

build/%.o: %.c Makefile
	mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

build/%.o: %.s Makefile
	mkdir -p $(@D)
	$(CC) $(TARGET_FLAGS) -g3 -c $< -o $@

-include $(OBJECTS:.o=.d)