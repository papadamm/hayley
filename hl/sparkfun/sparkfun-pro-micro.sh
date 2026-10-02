#!/bin/sh
# HL - Hayley parameter query and build script

hl_qry ()
{
  case "$1" in
    get-extra-flags) echo -DSPARKFUN_PRO_MICRO ;;
    get-memory-base) echo 0x20000000 ;;
    get-memory-size) echo 0x00042000 ;;
    get-flash-base) echo 0x10000000 ;;
    get-flash-size) echo 0x00010000 ;; # FIXME: this is incorrect
    get-arm-vector-table-needed) echo yes ;; # needed by rp2040 boot stack
    get-next) echo ../arm/arm-cortex-m0plus.sh ;;
  esac
}

# Answer immediately and exit if we are able to
Q=`hl_qry "$1"`
if [ -n "$Q" ]; then echo "$Q"; exit 0; fi

# If not handle special cases and use get-next to query next script
abs_f () { echo "`cd $2 && /bin/pwd`/`basename $1`"; }
DIRNAME_ZERO=`dirname "$0"`

hl_query_top ()
{
  if [ -x "$HL_TOP" ]; then
     $HL_TOP $@
  fi
}

# code for "get-boot2-code" generated from
# https://github.com/papadamm/random/tree/main/rp2040-boot2-xip-test
emit_base64 ()
{
  cat <<EOF
begin-base64 644 -
ALUMSwAhmWAEIVlhCkkZYApJC0gBYAAhWWABIZlgAbwAKADQAEcHSAdJCGADyIDzCIgIRwAAABgA
Ax8AGAIAA/QAABgAAQAQCO0A4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALOwhDQ==
====
EOF
}

# assembly code to implement "get-boot2-code"
# see https://github.com/papadamm/random/tree/main/rp2040-boot2-xip-test
emit_asm ()
{
  cat <<EOF
  .syntax unified
  .cpu cortex-m0plus
  .text

  .global boot2_start
  .type boot2_start, %function
boot2_start:

#define XIP_BASE 0x10000000
#define XIP_SSI_BASE 0x18000000

#define CTRLR0_XIP 0x001f0300
#define SPI_CTRLR0_XIP 0x03000218
#define PICO_FLASH_SPI_CLKDIV 4

#define SSI_SSIENR_OFFSET 0x00000008
#define SSI_BAUDR_OFFSET 0x00000014
#define SSI_CTRLR0_OFFSET 0x00000000
#define SSI_CTRLR1_OFFSET 0x00000004
#define SSI_SPI_CTRLR0_OFFSET 0x000000f4

#define PPB_BASE 0xe0000000
#define M0PLUS_VTOR_OFFSET 0x0000ed08

  push {lr}

  ldr r3, =XIP_SSI_BASE
  movs r1, #0
  str r1, [r3, #SSI_SSIENR_OFFSET]
  movs r1, #PICO_FLASH_SPI_CLKDIV
  str r1, [r3, #SSI_BAUDR_OFFSET]
  ldr r1, =(CTRLR0_XIP)
  str r1, [r3, #SSI_CTRLR0_OFFSET]
  ldr r1, =(SPI_CTRLR0_XIP)
  ldr r0, =(XIP_SSI_BASE + SSI_SPI_CTRLR0_OFFSET)
  str r1, [r0]
  movs r1, #0x0
  str r1, [r3, #SSI_CTRLR1_OFFSET]
  movs r1, #1
  str r1, [r3, #SSI_SSIENR_OFFSET]

  pop {r0}
  cmp r0, #0
  beq vector_into_flash
  bx r0
vector_into_flash:
  ldr r0, =(XIP_BASE + 0x100)
  ldr r1, =(PPB_BASE + M0PLUS_VTOR_OFFSET)
  str r0, [r1]
  ldmia r0, {r0, r1}
  msr msp, r0
  bx r1

  .align 2
  .pool
EOF
}

if [ "$1" == "get-boot2-code" ]; then

  # boot2 on rp2040 is a required component of the rp2040 boot stack
  #
  # when the uC boots it reads the first 256 bytes into memory and
  # executes it, which is the code that is being generated here.
  # such code is responsible for setting up the flash XIP mode and
  # that is needed to be able to read out the rest of the software
  # from the flash memory. without this the code will not boot.
  # exactly what parameters to use highly depends on what kind of
  # external flash that is mounted which makes this board dependent.
  #
  # this particular code seems to work on sparkfun-pro-micro.
  # however there is probably room for performance improvements.

  cleanup() {
    rm -f "${t0}" "${t1}" "${t2}" 2>/dev/null
  }

  trap cleanup EXIT
  t0=$(mktemp)
  t1=$(mktemp)
  t2=$(mktemp)
  for e in "${t0}" "${t1}" "${t2}"
  do
    if [ -z "${e}" ]; then
      echo "Failed to create temporary file, exiting" >&2
      exit 1;
    fi
  done

  # turn on break-on-failure
  set -e

  HL_CROSS_COMPILE=`hl_query_top get-cross-compile`
  HL_TARGET_FLAGS="-march=armv6s-m -mlittle-endian"

  # rp2040 needs the first 256 bytes with a checksum, use this tool
  # ~/git/pico-sdk/src/rp2040/boot_stage2/pad_checksum -s 0xffffffff
  
  HL_RP2040_PAD_CHECKSUM=`hl_query_top get-rp2040-pad-checksum`
  if [ -z "${HL_RP2040_PAD_CHECKSUM}" ]; then
    emit_base64
    exit 0
  fi
  
  # first build the assembly code and make a binary out of it
  emit_asm | ${HL_CROSS_COMPILE}gcc -E - > "${t0}"
  cat "${t0}" | ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
                                 -x assembler -c - -o "${t1}"
  ${HL_CROSS_COMPILE}objcopy "${t1}" -O binary "${t0}"

  # run the pad_checksum tool on the binary which will generate assembly
  ${HL_RP2040_PAD_CHECKSUM} -s 0xffffffff "${t0}" "${t1}"

  # build the generated assembly code and make a binary out of it
  cat "${t1}" | ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
                                 -x assembler -c - -o "${t0}"
  ${HL_CROSS_COMPILE}objcopy "${t0}" -O binary "${t1}"

  # output base64 encoded data on stdout
  cat "${t1}" | uuencode -m -
  exit 0; # success
fi
    
C=`abs_f "$0" "$DIRNAME_ZERO"`
if [ -z "$HL_TOP" ]; then export HL_TOP=$C; fi
for QN in `hl_qry get-next`
do
  DN=`dirname $QN`; DN2=`cd $DIRNAME_ZERO/$DN && /bin/pwd`
  N=`abs_f "$QN" "$DN2"`
  if [ -x "$N" ]; then $N $@; fi
done
