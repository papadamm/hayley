Hayley TODO (mostly "nice to have" things, in no specific order)

Hardware specific code, MCU/SoC specific or processor core specific:
- GPIO
- UART
- PINMUX
- PWM
- Timekeeping (accurate delay)
- EEPROM / FLASH
- Interrupts
- (perhaps target-specific radio interface for Eddystone BLE or similar)

Hardware support for various components that may be reused across boards:
- Sensors, LCDs, Ethernet, Ethernet PHY
- Audio capture, Camera capture

Software components / add-ons / example code:
- RTT logging
- na4 example integration (maybe with inline asm for BigInt)
- MCUBoot
- FreeRTOS
- vsprintf or maybe some partial string.h arrangement
- perhaps some kind of stdio syscall interface (on top of BIOS/DOS?)
- Softwire or similar software I2C on top of GPIO
- Software SPI on top of GPIO
- LWIP

Build system:
- Add #defines for MCU/SoC and processor core
- Consider using conditional filenames based on #defines
- Figure out how to map supported target system to example code
- Build and store objectfiles outside the example code directory
- Per target-system build, build all supported example code

Abstraction work:
- Consider breaking out code into separate components
- Add dependency handling and auto generate build order

Future potential target systems:
- Add board support for other ARM vendors (ST-Micro, NXP and others)
- 32-bit x86 support
- 16-bit x86 support, 8086 maybe potential MSDOS/FreeDOS target (COM files)
- 64-bit ARM systems (dust off those Cortex-A53 and Cortex-A57 targets)
- Sparc, PowerPC, 68K, SuperH (need to figure out the debugger situation)
- h8300, Microchip PIC

Test cases:
- TBD
