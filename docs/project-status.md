# Project status

## Current milestone

Establish a minimal reproducible firmware baseline: build, program with
verification, stop at `main()`, then verify one onboard LED change.

## Current state

- Hardware identified as NUCLEO-F767ZI, board `MB1137-F767ZI-B01`.
- Linux compiler/debugger executables run; Make and OpenOCD are available.
- Windows CubeIDE 1.9.0 confirmed; ST-LINK attachment to WSL confirmed.
- Windows staging folder contains a generated STM32Cube executable project
  targeting STM32F767ZITx/NUCLEO-F767ZI, with `.ioc` configuration, startup
  assembly, linker scripts, HAL, and CMSIS device sources. Project folder,
  configuration filename, and project identifiers are normalized to `BitBridge`.
- Generated clock code selects HSI, AHB /1, APB1 /2, and APB2 /1, matching
  the configuration editor's nominal 16/16/8/16 MHz values. Not target-verified.
- Saved `.ioc` reserves PA13/PA14 for Serial Wire. Generated GPIO code does
  not reconfigure those pins. After pin cleanup, `MX_GPIO_Init()` configures
  only the three onboard LED outputs; communication and button GPIO setup is absent.
- Generated `Core/`, `Drivers/`, `.ioc`, and Flash linker script imported into
  the canonical repository; all 76 imported files match the staging source
  byte-for-byte. Vendor licenses and header directories are included.
- Host application implementation has not started.
- Make compiles eight baseline C sources and the startup assembly using Arm GCC
  14.2.1 with Cortex-M7/hard-float settings, with no reported warnings or errors.
  Incremental compilation was exercised. Linking produces `build/BitBridge.elf`
  and its map: 4624 B Flash and 1584 B RAM region allocation.
- ELF inspection confirms ARM hard-float executable format, no unresolved
  symbols, a Flash vector table, initial MSP `0x20080000`, and reset vector
  `0x08000e29` pointing to the linked Thumb reset handler.
- Matching board manual reviewed for onboard debug, external clock input, and
  USART3 routing; physical configuration checks remain pending.

- OpenOCD connects through ST-LINK V2J39M27 over 1 MHz SWD, identifies a
  Cortex-M7 r1p0 with eight breakpoints/four watchpoints, and listens for GDB
  on port 3333. Probe-reported target voltage is approximately 3.228 V.

- GDB reaches the temporary `main()` breakpoint at `Core/Src/main.c:72`,
  before `HAL_Init()`. Target execution through startup to application entry is
  verified. OpenOCD verifies 4624 bytes against the ELF.
- Stepping over HAL, clock, and GPIO initialization reaches the main loop at
  line 93. This confirms the calls return; clock frequency is not measured.

Observable LED behavior remains unverified.
RAM allocation includes linker heap/stack allowances, not measured runtime use.

## Open items

- Verify the first observable LED change. Clock frequency remains unmeasured.
- The generated linker script produces an ELF Flash load segment marked RWE;
  review segment permissions separately. These flags do not establish hardware
  memory permissions.

## Exact next action

Add a single LD1 output-high call after GPIO initialization, rebuild, reload
and verify the ELF, then step through initialization and observe the green LED.

## Later decisions

UART routing verification, network addressing, transport choice, host tool,
buffering, and reconnect policy remain open. See the [roadmap](../README.md#roadmap).
