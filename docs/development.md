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
| USB forwarding | Windows usbipd; ST-LINK attachment to WSL confirmed; MCU debug access pending |

Compiler tools are installed outside the repository and are not currently on
the inspected shell's PATH. Record explicit selection in the eventual build setup.
Vendor firmware package version and provenance have not yet been established.

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

The intended workflow uses Windows CubeIDE to generate vendor foundations and
WSL tools to build, flash, and debug the canonical source. Generation/export
procedure and source placement must be agreed before project creation.

The Ethernet dongle is intended to remain owned by Windows. Placement of the
host application and serial terminal will be confirmed during bring-up.
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

## Build

From the repository root in WSL:

```bash
make
```

The Makefile selects Arm GNU Toolchain 14.2.Rel1 from
`~/tools/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi`. Override its location
with `make TOOLCHAIN_DIR=/path/to/toolchain`. This selects a location; it does
not automatically validate the installed toolchain's version.

The current target compiles eight C files and one startup assembly file for
Cortex-M7, FPv5-D16, hard-float ABI, using `-Og -g3`. It links against the
installed Newlib-nano runtime and no-OS syscall stubs with
`STM32F767ZITX_FLASH.ld`. Outputs are `build/BitBridge.elf` and
`build/BitBridge.map`; no separate binary image is needed to program the ELF.

The `.ioc` records STM32CubeF7 v1.16.2. It is not an input to compilation;
configuration changes require deliberately regenerating/importing code or
maintaining that code manually. Builds do not enable a debug print channel.

Compilation, linking, programming, image verification, and the breakpoint at
`main()` have been exercised. Stepping through initialization reaches the main
loop; observable LED behavior is the next check. See [project status](project-status.md).

## Flash and debug

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

Not yet executed in this project:

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
