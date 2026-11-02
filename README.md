# BitBridge

A planned transparent UART/CAN-to-Ethernet traffic and diagnostic gateway for
the STM32 NUCLEO-F767ZI.

## Current capabilities

Minimal bare-metal firmware with a Make-based WSL build using Arm GNU Toolchain
14.2.Rel1 and STM32CubeF7 v1.16.2 vendor components.

Hardware verification covers programming and image readback verification through
onboard ST-LINK, a GDB breakpoint at `main()`, and stepping through HAL, clock,
and GPIO initialization to the main loop. Standalone programming and verification
are exercised; green LD1 lights after startup and remains lit after B2 reset.
Clock frequencies have not been measured.

UART initialization and a startup transmit test are exercised on hardware: the
terminal displays `U` and a new line after startup and B2 reset, with HAL reporting
success. A one-byte polling receive/echo test is exercised through the terminal
with local echo disabled. These checks cover interactive low-rate traffic;
burst handling and raw-byte integrity have not been established. Ethernet, CAN,
native USB, traffic forwarding, and the host application are not implemented.

## Hardware

- NUCLEO-F767ZI (`MB1137-F767ZI-B01`), using its onboard ST-LINK USB connection for programming,
  debugging, and virtual COM port access.
- Ethernet cable from the board to a computer through a USB–Ethernet dongle.

Clock sources and UART-to-ST-LINK routing must be checked before use.

## Getting started

Build from the repository root in WSL:

```bash
make
```

Outputs are `build/BitBridge.elf` and `build/BitBridge.map`. The default toolchain
location and the build, flash, and debug procedures are documented in
[development procedures](docs/development.md). The
[project status](docs/project-status.md) records verified state and the next action.
Use the [standalone flash procedure](docs/development.md#flash-without-gdb)
to program and run the firmware without an interactive debugger.

## GDB quick reference

Run `make` after source changes. With ST-LINK attached to WSL, start one OpenOCD
server from the repository root in terminal 1:

```bash
openocd -f openocd.cfg
```

In terminal 2, also from the repository root:

```bash
~/tools/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gdb build/BitBridge.elf
```

Enter the following **inside GDB, in order**. Stop if programming or verification
fails. OpenOCD startup does not build or program the firmware.

| Command | Purpose |
|---|---|
| `target remote localhost:3333` | Connect GDB to OpenOCD. |
| `monitor reset halt` | Reset the MCU and keep it halted. |
| `load` | Program the ELF loaded in GDB onto the MCU. |
| `monitor verify_image build/BitBridge.elf` | Verify the programmed contents against the ELF. |
| `monitor reset halt` | Reset again before debugging the new image. |
| `tbreak main` | Set a breakpoint that removes itself when reached. |
| `continue` | Resume execution until a breakpoint or another debugger stop. |

Common commands once connected:

| Command | Purpose |
|---|---|
| Ctrl+C | Halt a running target and return to the GDB prompt. |
| `break Error_Handler` | Stop if the firmware enters its error handler. |
| `tbreak MX_ETH_Init` | Stop once at Ethernet initialization. |
| `next` (`n`) | Step one source line, running over function calls. |
| `step` (`s`) | Step one source line, entering function calls. |
| `finish` | Run until the current function returns; display its return value when available. |
| `print heth.State` | Inspect a variable or expression (`p` is shorthand). |
| `p/x rx_descriptors[0]` | Print a descriptor's fields in hexadecimal. |
| `p &rx_buffer[0][0]` | Inspect an object's address. |
| `x/8wx &rx_descriptors[0]` | Examine eight 32-bit words in hexadecimal. |
| `backtrace` (`bt`) | Show the current function-call stack. |
| `list` | Show source around the current location. |
| `info breakpoints` | List breakpoints and their numbers. |
| `delete 2` | Delete breakpoint number 2; substitute the number from the list. |
| `file build/BitBridge.elf` | Reload the ELF and symbols after rebuilding; does not program the MCU. |
| `disconnect`, then `quit` | End the GDB connection and exit; stop OpenOCD separately with Ctrl+C. |

Editing and rebuilding can happen while both tools remain open. After a rebuild,
halt the target, reload symbols with `file build/BitBridge.elf`, then repeat the
program/verify/reset/break/run sequence above. Keep source, GDB symbols and target
firmware matched. Prefer `finish` over stepping through time-sensitive initialization;
pausing while SysTick is active can affect timeout behavior.

See [interactive debug](docs/development.md#interactive-debug) for the full procedure.

## Roadmap

1. Completed: minimal firmware with a reproducible build, verified programming, breakpoint at
   `main()`, and an observable onboard LED change.
2. Completed initial UART transmit/receive verification through ST-LINK VCP
   at interactive rates; throughput and loss characterization remain future work.
3. Independent Ethernet connectivity and a minimal host application.
4. Known-byte forwarding from UART to the host, then the reverse direction.
5. Incremental diagnostics and Classical CAN forwarding as requirements justify them.
6. Optional native USB interface through the MCU's user USB connector, with
   USB CDC or diagnostic capture transfer as candidate uses. Select the role
   and requirements before implementation.

Future diagnostics include bounded buffering, timestamps, loss counters,
explicit overload behavior, and fault recovery.

## Scope and limitations

- Forward payloads without interpreting device-specific application meanings.
- Treat UART as a byte stream. Reads, packets, and pauses do not define application
  messages. Network transport and reconnect/buffering policies remain undecided.
- Keep debug text out of the forwarded UART stream.
- Use an isolated development connection. Remote transmission controls must not
  be exposed to an untrusted network.
