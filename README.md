# BitBridge

A planned transparent UART/CAN-to-Ethernet traffic and diagnostic gateway for
the STM32 NUCLEO-F767ZI.

## Current capabilities

Minimal bare-metal firmware with a Make-based WSL build using Arm GNU Toolchain
14.2.Rel1 and STM32CubeF7 v1.16.2 vendor components.

Hardware verification covers programming and image readback verification through
onboard ST-LINK, a GDB breakpoint at `main()`, and stepping through HAL, clock,
and GPIO initialization to the main loop. An observable LED change remains to
be verified. Clock frequencies have not been measured.

UART, Ethernet, CAN, native USB, and traffic forwarding are not implemented.
No host application is implemented.

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

## Roadmap

1. Minimal firmware: reproducible build, verified programming, breakpoint at
   `main()`, and an observable onboard LED change.
2. Independent UART transmit/receive verification through ST-LINK VCP.
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
