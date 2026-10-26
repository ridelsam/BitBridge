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
