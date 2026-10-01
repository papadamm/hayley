# HAYLEY (C and Assembly build environment for tiny embedded systems)
HAYLEY is a build environment based on a set of shell scripts together with example code for a couple of microcontrollers. At this point the programming languages C and Assembly for the ARM and AVR architectures are somewhat supported. There is no library support included, so more or less everything has to be created from scratch. What is included however, is linker script and initial ARM code to clear the memory and setup the data segment and stack, so the main() function may be reached after power-on-reset. This is tested on pca10059. There is no interrupt support.

The repository contains some degree of support for the following MCU/SoC (CPU core) [Instruction set]:
- Microchip atmega328p (AVR)
- Nordic nRF52840 (ARM Cortex-M4)
- Raspberry Pi RP2040 (ARM Cortex-M0+)

As a brief tutorial, start by trying to build the example blink code:
```console
% cd examples/blink
% make
Makefile:2: *** Unable to parse HL environment variable.  Stop.
% cd ../..
```

That's right, we need to select a target board and provide cross compiler information before build is possible:
```console
% cd hl
% # make a copy of the sample file and change it to reflect pca10059
% cp local-sample.sh local-pca10059.sh
% # edit local-pca10059.sh and select nordic/pca10059.sh as target board
% # also add cross compiler prefix to local-pca10059.sh
%
% # when done, use the script to query information to double check that all is well
% ./local-pca10059.sh get-next
nordic/pca10059.sh
% ./local-pca10059.sh get-cross-compile
arm-none-eabi-
# check that the correct flash start address is output from nordic/pca10059.sh
% ./local-pca10059.sh get-flash-base
0x00001000
% # yes all looks good
% # this is by the way how the Makefile and linker script retrieve information
% cd ..
```

If you wanted to build for another ARM platform, you could probably use the same cross toolchain but select a different board like sparkfun/sparkfun-pro-micro.sh. Having a bunch of different local files for a range of target systems would make sense here. Have a look at the the different get-asmflags and get-flags for ARM Cortex M4 and ARM Cortex-M0plus in the arm/ directory if you want details.

Retry building the blink code (now with HL):
```console
% cd examples/blink
% make HL=../../hl/local-sample.sh
gcc   -Wall -c main.c -o main.o
gcc   -E led-nordic-pca10059.S | as  - -o led-nordic-pca10059.o
gcc   -E led-sparkfun-pro-micro.S | as  - -o led-sparkfun-pro-micro.o
gcc   -E led-seeeduino-nano.S | as  - -o led-seeeduino-nano.o
../../hl/local-sample.sh link main.o led-nordic-pca10059.o led-sparkfun-pro-micro.o led-seeeduino-nano.o > file.hex
% file file.hex
file.hex: empty
% # ooops the wrong HL file was used which resulted in build with the host gcc
% # clean the generated files
% make HL=../../hl/local-sample.sh clean
rm -f main.o led-nordic-pca10059.o led-sparkfun-pro-micro.o led-seeeduino-nano.o file.hex
```

Practice makes perfect, try again (now with correct HL):
```console
% cd examples/blink
% make HL=../../hl/local-pca10059.sh
arm-none-eabi-gcc -march=armv7e-m -mlittle-endian -DPCA10059 -Wall -c main.c -o main.o
arm-none-eabi-gcc -march=armv7e-m -mlittle-endian -DPCA10059 -E led-nordic-pca10059.S | arm-none-eabi-as -march=armv7e-m -mlittle-endian - -o led-nordic-pca10059.o
arm-none-eabi-gcc -march=armv7e-m -mlittle-endian -DPCA10059 -E led-sparkfun-pro-micro.S | arm-none-eabi-as -march=armv7e-m -mlittle-endian - -o led-sparkfun-pro-micro.o
arm-none-eabi-gcc -march=armv7e-m -mlittle-endian -DPCA10059 -E led-seeeduino-nano.S | arm-none-eabi-as -march=armv7e-m -mlittle-endian - -o led-seeeduino-nano.o
../../hl/local-pca10059.sh link main.o led-nordic-pca10059.o led-sparkfun-pro-micro.o led-seeeduino-nano.o > file.hex
% # now you have a hex file ready for upload to the target
```

For instructions how to upload the code to the pca10059 target, have a look at
https://github.com/papadamm/teeensy/blob/main/teeensy-nordic-pca10059-nrf52840.sh
