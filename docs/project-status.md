# Project status

## Current milestone

Independent Ethernet bring-up: host discovery is complete. Bare-metal lwIP with
DHCP and ping as the first IP verification gate is agreed. The prerequisite
64 MHz HSI/PLL clock change builds; the user reports existing behavior remains
working, and GDB reports `SystemCoreClock = 64000000` after clock initialization.
The matching Ethernet HAL files are imported, enabled and compiled. The
initialization helper, LAN8742A configuration and Ethernet MSP clocks/pins are
implemented. On target, HAL initialization returns `HAL_OK` and reports a
100 Mbps full-duplex link. PHY ID readback matches LAN8742A revision 1.
Next is reviewing DMA descriptors, frame buffers and their memory requirements.
The build/debug/LED baseline and initial low-rate UART tests are complete.

## Verified state

- User-supplied Windows output identifies the Realtek USB GbE dongle as Ethernet,
  interface index 30, Up at 100 Mbps, with address `192.168.137.1/24` and an
  on-link route for `192.168.137.0/24`. Link LEDs are reported lit at both ends.
  Wi-Fi has the default route through `10.0.0.1`; the user confirms Wi-Fi Internet
  Connection Sharing targets Ethernet. No board DHCP exchange is verified.
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
- Ethernet HAL source/header match the CubeF7 v1.16.2 originals byte for byte.
  `HAL_ETH_MODULE_ENABLED` is enabled and the source is in the Make inputs;
  its object exists and the build passes. lwIP integration is not implemented.
- Source review confirms a private Ethernet handle and six-byte MAC array
  (`02:00:00:00:00:01`), an `MX_ETH_Init()` configuration helper using
  auto-negotiation, RMII, polling and software checksums, and LAN8742A management
  address/status definitions matching the vendor board example. These changes
  are now exercised through HAL initialization on hardware.
- `HAL_ETH_MspInit()` enables GPIO A/B/C/G and Ethernet clocks, then configures
  PA1/PA2/PA7, PB13, PC1/PC4/PC5 and PG11/PG13 as AF11, push-pull, no-pull,
  very-high-speed. Source review and Make build pass; successful HAL initialization
  exercises the hook on target. The user confirms JP6/JP7 are fitted.
- `main()` now calls `MX_ETH_Init()` after UART initialization. The helper checks
  `HAL_ETH_Init(&heth)` and enters `Error_Handler()` on non-success. Build passes;
  the linked ELF contains the project MSP hook as a strong symbol. User-supplied
  GDB output records `HAL_OK`, `HAL_ETH_STATE_READY`, speed `0x4000` (100 Mbps)
  and duplex `0x800` (full duplex). This establishes the exercised initialization
  and negotiation path, not frame transfer or IP connectivity. The vendor source reports an
  unused handle parameter in `ETH_MACAddressConfig()`.
- Checked PHY identifier reads after initialization store registers 2/3 into
  private `uint32_t` variables `phy_id1`/`phy_id2`. Source review and build pass.
  User-supplied GDB output gives `0x0007` and `0xC131`, matching the LAN8742A
  manufacturer/model identifier and silicon revision 1 in the
  [PHY datasheet](https://www.microchip.com/content/dam/mchp/documents/OTH/ProductDocuments/DataSheets/DS_LAN8742_00001989A.pdf).

## Limitations and open items

- VS Code IntelliSense configuration now mirrors the Makefile's Arm compiler,
  target flags, defines and include paths. Compiler syntax checks using that
  configuration pass for main, MSP and Ethernet HAL sources; editor navigation
  still needs an interactive F12 check in a WSL-connected VS Code window.
- The transmit count is corrected to `sizeof(data) - 1U`, selecting three bytes
  without the string initializer's trailing NUL. No raw-byte capture is recorded.
- No raw-byte capture, burst/overrun test, or clock-frequency measurement has been
  performed. Previously exercised SYSCLK/HCLK/PCLK1/PCLK2 settings were nominally
  16/16/8/16 MHz. The new HSI/PLL configuration (M=16, N=128, P=2, Q=4, R=2)
  selects nominal 64/64/32/64 MHz with voltage scale 3 and two Flash wait states.
  Source review and Make build pass. The user reports existing behavior remains
  working after the requested programming/startup/UART checks. GDB stopped at
  `MX_GPIO_Init()` and printed `SystemCoreClock = 64000000`. This confirms the
  software-calculated HCLK, not a measured frequency. Existing linker warnings remain.
- Linker warnings remain for no-OS `_close`, `_lseek`, `_read`, and `_write` stubs
  and an RWE Flash load segment. Standard-I/O retargeting is not implemented;
  ELF permission flags do not establish hardware memory permissions.
- Ethernet frame transfer and lwIP/IP connectivity, CAN, native USB, forwarding,
  and the host application are unimplemented.
- Ethernet requires a higher HCLK than the previously exercised 16 MHz configuration; see
  [RM0410](https://www.st.com/resource/en/reference_manual/rm0410-stm32f7-series.pdf).

## Exact next action

Review `ETH_DMADescTypeDef`, the HAL TX/RX descriptor-list initialization APIs,
and the frame-buffer requirements. Check STM32F767 DMA memory accessibility,
alignment, linker placement and actual cache enable state before allocating
resources or enabling frame transfer. Then continue to bare-metal lwIP integration.
The board PHY supplies the 50 MHz RMII reference; the vendor RTOS example's IRQ
and MCO setup should not be imported into this polling design.
Continue toward frame transfer, a DHCP lease, then Windows ping replies.

## Later decisions

Transport, static-address configuration, buffering, overload/reconnect policy, and
host tool design remain open. See the [roadmap](../README.md#roadmap) and
[development procedures](development.md).
