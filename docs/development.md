# Development

## Environment discovered

| Component | Observed state |
|---|---|
| Source location | Linux filesystem under WSL2 |
| Project generation | Windows STM32CubeIDE 1.9.0; version confirmed in About dialog |
| Compiler | Linux Arm GNU Toolchain 14.2.Rel1, GCC 14.2.1; executable checked |
| Debugger | Bundled Linux Arm GDB; executable checked |
| Build utility | GNU Make 4.4.1 |
| Debug server | OpenOCD 0.12.0; ST-LINK and STM32F7 configuration files present |
| USB forwarding | Windows usbipd; ST-LINK attachment and MCU debug access through WSL verified |

Compiler tools are installed outside the repository and selected explicitly by
the Makefile. Initial generation used STM32CubeIDE 1.9.0, integrated CubeMX
6.5.0 (database DB.6.0.50), and STM32CubeF7 v1.16.2. These versions were recorded
from the IDE and original configuration before removing the `.ioc`.

## Implementation approach

Begin with a bare-metal design using suitable vendor components and lwIP when
Ethernet is introduced. Add interrupts, queues, UART DMA, timers, an RTOS, and
other mechanisms only when a concrete requirement or observed limitation warrants
them. Ethernet uses DMA independently of any later decision to use UART DMA.

## Board reference

The board is `MB1137-F767ZI-B01`. Consult
[ST UM1974 Rev 11](https://www.st.com/resource/en/user_manual/dm00244518-stm32-nucleo-144-boards-mb1137-stmicroelectronics.pdf).

- Section 7.3.3: both CN4 jumpers connect ST-LINK to the onboard target.
- Section 7.8.1: the documented default external clock input is an 8 MHz
  signal from ST-LINK MCO, rather than a populated target HSE crystal.
- Section 7.9 and Table 9: USART3 uses PD8 (TX) and PD9 (RX); SB5/SB6
  provide the ST-LINK VCP path. Inspect the actual bridges before UART bring-up.

These are documentation findings; physical configuration and clock frequency
have not been verified in this project.

## Windows and WSL boundary

Windows CubeIDE generated the vendor foundations in a separate staging folder.
The inspected `Core/`, `Drivers/`, and Flash linker script were copied
into this repository. WSL tools build, flash, and debug the canonical source.
Make source edits here; later CubeIDE regeneration requires explicit review
and import rather than assuming both copies remain synchronized.

The `Core` sources and headers are maintained manually, with generator
`USER CODE` markers and empty template sections removed. The `.ioc` has been
removed from this repository; the original remains in Git history. Source code
is authoritative for clock, pin, and peripheral configuration. Preserve vendor
notices and review any later generated changes before incorporating them.

The Ethernet dongle and initial network client are intended to remain owned by
Windows. Use a WSL serial terminal so ST-LINK can remain attached to WSL for
programming, debugging, and VCP access.
Attaching the composite ST-LINK device to WSL transfers its VCP along with the
debug interface; do not assume a Windows terminal can use it simultaneously.

Existing firmware projects are read-only references. Do not copy their clock
configuration without checking the physical board and generated settings.

## USB verification

In Windows PowerShell:

```powershell
usbipd list
usbipd attach --wsl --busid <BUSID>
```

Use the bus ID from the current listing. Attachment requires the device to have
been shared already. In WSL:

```bash
lsusb
```

An ST-LINK entry establishes USB enumeration, not target debug communication.
Reference: [Microsoft USB access in WSL](https://learn.microsoft.com/en-us/windows/wsl/connect-usb).

## Serial terminal setup

SB4/SB5/SB6/SB7 are visually confirmed fitted. SB5/SB6 provide the ST-LINK
UART path; SB4/SB7 also connect the pins to the expansion headers. Leave the
header pins unconnected during this test. Startup transmission and one-byte
polling receive/echo are exercised through the terminal at interactive rates.

WSL enumerates the VCP as `/dev/ttyACM0` with a link under `/dev/serial/by-id/`.
The numbered device may change after reconnecting; use the by-ID link to identify
the correct port. Its observed permissions are `0660`, owned by `root:plugdev`.

pySerial miniterm is available in the inspected Python environment. Exercised
UART settings are 115200 baud, eight data bits, no parity, one stop bit,
with hardware/software flow control and local echo disabled:

```bash
python3 -m serial.tools.miniterm --parity N /dev/ttyACM0 115200
```

Exit with Ctrl+]. Opening the terminal at these settings is verified. Report an
access error before changing permissions or installing tools. Open the terminal
before programming, or press B2 after opening it, to observe the one-shot startup
transmission. The terminal displays `U` followed by a new line; LD1 lights after
the HAL transmit call reports success. This is not a raw-byte capture. The saved
count is `sizeof(data) - 1U`, excluding the string initializer's NUL terminator
from the intended three-byte payload.

For the receive test, type individual ASCII characters with local echo off;
the firmware receives one byte and transmits that byte back. The terminal's
displayed characters establish the exercised round trip. Test again after an
idle pause; ordinary 100 ms receive timeouts retry rather than halt the loop.
This test is not a raw-byte comparison or a burst/overrun characterization.

## Build

From the repository root in WSL:

```bash
make
```

The Makefile selects Arm GNU Toolchain 14.2.Rel1 from
`~/tools/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi`. Override its location
with `make TOOLCHAIN_DIR=/path/to/toolchain`. This selects a location; it does
not automatically validate the installed toolchain's version.

The current target compiles ten C files and one startup assembly file for
Cortex-M7, FPv5-D16, hard-float ABI, using `-Og -g3`. It links against the
installed Newlib-nano runtime and no-OS syscall stubs with
`STM32F767ZITX_FLASH.ld`. Outputs are `build/BitBridge.elf` and
`build/BitBridge.map`; no separate binary image is needed to program the ELF.

Configuration changes are maintained manually in the source. CubeMX is not
required to build, flash, or debug this repository. Builds do not enable a
debug print channel.

Compilation, linking, programming, image verification, and the breakpoint at
`main()` have been exercised. Stepping through initialization reaches the main
loop. The LD1 output-high change is hardware-verified after standalone
programming and B2 reset. See [project status](project-status.md).

## VS Code code navigation

Open the repository as a folder in a WSL-connected VS Code window, with the
Microsoft C/C++ extension enabled in WSL. The checked-in
[IntelliSense configuration](../.vscode/c_cpp_properties.json) mirrors the
Makefile's compiler, target flags, C standard, defines and include directories.
Keep it synchronized when these build inputs change; if the toolchain is moved,
update `compilerPath` as well.

With a C source file open, select `STM32F767ZI (WSL)` through
`C/C++: Select a Configuration` in the Command Palette. Test F12 on
`HAL_UART_Init` in `Core/Src/main.c`; it should navigate to the HAL source.
Use the context menu's Go to Declaration to visit its header declaration.
If navigation remains stale, run `C/C++: Reset IntelliSense Database`, then
`Developer: Reload Window`. `C/C++: Log Diagnostics` shows the compiler,
include paths and defines actually selected by the extension.

## Flash without GDB

This standalone command and the interactive programming/verification sequence
below have been exercised on the board.

First end any GDB session (`disconnect`, then `quit`) and stop its OpenOCD server
with Ctrl+C in the server terminal. Only one process may own the probe.

With ST-LINK attached to WSL, run from the repository root:

```bash
make && openocd -f openocd.cfg -c "program build/BitBridge.elf verify reset exit"
```

`&&` starts programming only if the build succeeds. OpenOCD initializes the
target, erases/programs the necessary Flash sectors, verifies the image, resets
the MCU to run the firmware, and exits. GDB and breakpoints are not involved;
the programmer still uses the SWD hardware connection.

Expect programming and verification success, followed by reset and shutdown.
Stop and inspect any error. For the current LD1 change, verify that the green
user LED turns on and remains on; repeat with B2 reset to check startup again.

Reference: [OpenOCD flash programming](https://openocd.org/doc-release/html/Flash-Programming.html).

## Interactive debug

Target connection, image verification, and the breakpoint at `main()` have been
exercised using this sequence.

In WSL terminal 1, from the repository root:

```bash
openocd -f openocd.cfg
```

The configuration selects ST-LINK, SWD, STM32F7, and a 1 MHz debug clock.
OpenOCD identifies the target and serves GDB on port 3333. Run only one server
for this probe.

In WSL terminal 2, from the repository root:

```bash
~/tools/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gdb build/BitBridge.elf
```

At the GDB prompt, execute one command at a time:

```gdb
target remote localhost:3333
monitor reset halt
load
monitor verify_image build/BitBridge.elf
monitor reset halt
tbreak main
continue
```

Starting GDB with the ELF reads its symbols on the host; `load` programs its
loadable contents into target memory, erasing the necessary Flash sectors.
OpenOCD's `verify_image` checks target contents against the ELF. Stop if any
connection, programming, or verification step fails.

After reset, `tbreak main` installs a temporary breakpoint, and `continue` lets
startup run until it reaches that breakpoint. This verifies entry to `main()`,
not completion of HAL, clock, or GPIO initialization. Rebuilds require loading
the matching ELF into both GDB and the target before interpreting source lines.

## Baseline acceptance procedure

Acceptance criteria; see project status for completed checks and remaining work:

1. Identify board revision and verify relevant clock/debug connections against
   the matching ST documentation.
2. Generate a minimal project and record generator/vendor package versions,
   startup code, linker script, clock settings, and build inputs.
3. Build from a documented command and identify the resulting ELF and map file.
4. Program the matching ELF with verification, reset, and stop at `main()` using
   that ELF's symbols. Record the target result separately from build success.
5. Make one small onboard LED change, predict its behavior, rebuild/reflash,
   and record the observed result.

Only then begin independent UART verification. Debug communication must not
contaminate the future forwarded UART stream.
