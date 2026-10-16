#!/bin/sh
# HL - Hayley parameter query and build script

hl_qry ()
{
  case "$1" in
  esac
}

# Answer immediately and exit if we are able to
Q=`hl_qry "$1"`
if [ -n "$Q" ]; then echo "$Q"; exit 0; fi

# If not use get-next to query next script
abs_f () { echo "`cd $2 && /bin/pwd`/`basename $1`"; }
DIRNAME_ZERO=`dirname "$0"`

hl_query_top ()
{
  if [ -x "$HL_TOP" ]; then
     $HL_TOP $@
  fi
}

emit_asm ()
{
cat <<EOF
  .text
  .global vector_table
  .type vector_table, %function
vector_table:
  rjmp _start

local_setup_data:
  .word __data_end__
  .word __data_start__
  .word __etext
  .word __bss_end__
  .word __bss_start__
  .word __StackTop

_start:
  /* r1 is fixed zero */
  eor r1, r1

  /* copy .data from __etext to __data_start__ */
  clr r31 /* clear Z high byte */
  ldi r30, 0x02 /* (local_setup_data) Z low byte */

  lpm r24, Z+ /* __data_end__ (low) */
  lpm r25, Z+ /* __data_end__ + 1 (high) */
  lpm r26, Z+ /* __data_start__ (low X) */
  lpm r27, Z+ /* __data_start__ + 1 (high X) */
  lpm r28, Z+ /* __etext (low Y) */
  lpm r29, Z+ /* __etext + 1 (high Y) */

  mov r20, r30 /* save Z for use later when clearing bss */
  mov r21, r31

  mov r30, r28 /* for now use Z for __etext */
  mov r31, r29

  sub r24, r26
  sbc r25, r27
  breq data_finished

data_next:
  lpm r0, Z+
  st X+, r0
  sbiw r24, 1
  brne data_next

data_finished:

  mov r30, r20 /* restore Z */
  mov r31, r21

  /* clear bss, from __bss_start__ to __bss_end__ */
  lpm r24, Z+ /* __bss_end__ (low) */
  lpm r25, Z+ /* __bss_end__ + 1 (high) */
  lpm r26, Z+ /* __bss_start__ (low X) */
  lpm r27, Z+ /* __bss_start__ + 1 (high X) */

  sub r24, r26
  sbc r25, r27
  breq bss_finished

bss_next:
  st X+, r1
  sbiw r24, 1
  brne bss_next

bss_finished:

  /* deal with stack */
  lpm r24, Z+ /* __StackTop (low) */
  lpm r25, Z+ /* __StackTop + 1 (high) */
  sbiw r24, 0x02 /* 16-bit PC assumed, 22-bit PC not supported */
  out 0x3d, r24 /* SPL (low) */
  out 0x3e, r25 /* SPH (high) */
  rcall main

end:
  rjmp end
EOF
}

emit_ldscript ()
{
cat <<EOF
SEARCH_DIR(.)

MEMORY
{
  FLASH (rx) : ORIGIN = $1, LENGTH = $2
  RAM (rwx) :  ORIGIN = $3, LENGTH = $4
}

ENTRY(vector_table)

SECTIONS
{
    .text :
    {
        *(.text*)
        *(.rodata*)
    } > FLASH

    . = ALIGN(4);
    __etext = .;

    .data : AT (__etext)
    {
        __data_start__ = .;
        *(.data*)
	__data_end__ = .;
    } > RAM

    .bss :
    {
        . = ALIGN(4);
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = .;
    } > RAM

    __StackTop = ORIGIN(RAM) + LENGTH(RAM);
    PROVIDE(__stack = __StackTop);
}
EOF
}

# link command requires special handling

if [ "$1" == "link" ]; then
  HL_CROSS_COMPILE=`hl_query_top get-cross-compile`
  HL_TARGET_FLAGS=`hl_query_top get-asmflags`

  # Probe for required software components
  for e in cat grep mktemp rm wc which ${HL_CROSS_COMPILE}gcc \
	     ${HL_CROSS_COMPILE}ld ${HL_CROSS_COMPILE}objcopy
  do
    if [ -z `which $e` ]; then
      echo "unable to detect required software component $e, exiting" >&2
      exit 1;
    fi
  done

  # Check that HL_CROSS_COMPILE actually points to a c compiler for AVR
  ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
		     -c /dev/null -o /dev/null 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Failed to detect AVR support in HL_CROSS_COMPILE, exiting" >&2
    exit 1;
  fi

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

  FLASH_BASE=`hl_query_top get-flash-base`
  FLASH_SIZE=`hl_query_top get-flash-size`
  MEMORY_BASE=`hl_query_top get-memory-base`
  MEMORY_SIZE=`hl_query_top get-memory-size`

  if [ "${FLASH_BASE}" != 0x00004000 ]; then
      echo "Warning: FLASH_BASE assumed to be 0x4000 for Data space" >&2
  fi

  emit_asm | ${HL_CROSS_COMPILE}gcc -E - > "${t0}"
  cat "${t0}" | ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
                                 -x assembler -c - -o "${t1}"
  emit_ldscript $FLASH_BASE $FLASH_SIZE $MEMORY_BASE $MEMORY_SIZE > "${t2}"

  shift
  ${HL_CROSS_COMPILE}ld "-T${t2}" "${t1}" $@ -o "${t0}"
  cp "${t0}" debug.o
  ${HL_CROSS_COMPILE}objcopy --change-section-address=.text=0 "${t0}" -O ihex "${t1}"
  cat "${t1}" # the contents come out on stdout
  exit 0 # done with link command
fi

# If not use get-next to query next script
C=`abs_f "$0" "$DIRNAME_ZERO"`
if [ -z "$HL_TOP" ]; then export HL_TOP=$C; fi
for QN in `hl_qry get-next`
do
  DN=`dirname $QN`; DN2=`cd $DIRNAME_ZERO/$DN && /bin/pwd`
  N=`abs_f "$QN" "$DN2"`
  if [ -x "$N" ]; then $N $@; fi
done
