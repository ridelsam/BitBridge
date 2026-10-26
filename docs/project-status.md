# Project status

## Current milestone

Independent Ethernet bring-up: identify the direct host adapter and its current
network configuration before changing settings or implementing Ethernet firmware.
The build/debug/LED baseline and initial low-rate UART tests are complete.

## Verified state

- NUCLEO-F767ZI, board `MB1137-F767ZI-B01`, onboard ST-LINK attached to WSL.
- Make builds the Cortex-M7/hard-float firmware with Arm GNU 14.2.Rel1 and
  STM32CubeF7 v1.16.2. Startup was generated with CubeIDE 1.9.0/CubeMX 6.5.0;
  source configuration is now maintained manually. The `.ioc` was removed.
- OpenOCD programs and verifies the ELF over 1 MHz SWD. GDB reaches `main()`;
  initialization reaches the main loop. LD1 remains lit after B2 reset.
- Baseline commit: `a2e2100` (`STM32F767 build and debug baseline`).
- SB4/SB5/SB6/SB7 are visually fitted. ST-LINK VCP opens in WSL as
  `/dev/ttyACM0` using pySerial miniterm at 115200, 8N1, no flow control or local echo.
- USART3 uses PD8/PD9, AF7 push-pull, pull-ups, low GPIO speed. The project
  `HAL_UART_MspInit()` enables USART3/GPIOD clocks; its strong definition is linked.
- The file-private `huart3` handle and manual initializer select TX/RX at 115200,
  8N1, oversampling 16, majority-vote sampling, and no hardware flow control.
  Initialization failure enters `Error_Handler()`.
- A one-shot blocking transmit of a string initialized to `U\r\n` is implemented
  with a 100 ms timeout and checked status. LD1 lights only after success.
  Hardware observation confirms `U` and a new line on startup and B2 reset.
- Generator markers and empty sections were removed from `Core`; vendor notices
  remain. The comment cleanup produced an identical programming image.
- The one-byte polling receive/echo loop is exercised with terminal local echo
  disabled. Typed characters appear in the terminal, including the follow-up
  interactive check after the timeout discussion. The loop retries receive
  timeout, echoes successful reception, and checks transmit status.

## Limitations and open items

- The transmit count is corrected to `sizeof(data) - 1U`, selecting three bytes
  without the string initializer's trailing NUL. No raw-byte capture is recorded.
- No raw-byte capture, burst/overrun test, or clock-frequency
  measurement has been performed. Configured SYSCLK/HCLK/PCLK1/PCLK2 values are
  nominally 16/16/8/16 MHz.
- Linker warnings remain for no-OS `_close`, `_lseek`, `_read`, and `_write` stubs
  and an RWE Flash load segment. Standard-I/O retargeting is not implemented;
  ELF permission flags do not establish hardware memory permissions.
- Ethernet, CAN, native USB, forwarding, and the host application are unimplemented.

## Exact next action

Connect the board's RJ45 directly to the Windows-owned USB–Ethernet dongle.
Inspect Windows adapter identity, link status, addresses, and routes using
read-only commands. Choose addressing and the first Ethernet verification gate
before changing host settings, clocks, memory placement, or firmware dependencies.

## Later decisions

Transport, addressing, buffering, overload/reconnect policy, and host tool design
remain open. See the [roadmap](../README.md#roadmap) and
[development procedures](development.md).
