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
  /* r1 is fixed zero */
  eor r1, r1

  /* copy .data from __etext to __data_start__ */
  lds r26, local_etext
  lds r27, local_etext + 1
  lds r28, local_data_start
  lds r29, local_data_start + 1
  lds r30, local_data_end
  lds r31, local_data_end + 1

  /* Z - Y */
  sub r30, r28
  sbc r31, r29
  breq data_finished

data_next:
  ld r0, X+
  st Y+, r0
  sbiw r30, 1
  brne data_next

data_finished:
  /* clear bss, from __bss_start__ to __bss_end__ */

  lds r28, local_bss_start
  lds r29, local_bss_start + 1
  lds r30, local_bss_end
  lds r31, local_bss_end + 1

  /* Z - Y */
  sub r30, r28
  sbc r31, r29
  breq bss_finished

bss_next:
  st Y+, r1
  sbiw r30, 1
  brne bss_next

bss_finished:
  /* deal with stack */
  lds r28, local_stack_top
  lds r29, local_stack_top + 1
  sbiw r28, 0x02 /* 16-bit PC assumed, 22-bit PC not supported */
  out 0x3d, r28
  out 0x3e, r29
  call main

end:
  rjmp end

  .align 2
local_etext:
  .word __etext
local_data_start:
  .word __data_start__
local_data_end:
  .word __data_end__
local_bss_start:
  .word __bss_start__
local_bss_end:
  .word __bss_end__
local_stack_top:
  .word __StackTop
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

  emit_asm | ${HL_CROSS_COMPILE}gcc -E - > "${t0}"
  cat "${t0}" | ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
                                 -x assembler -c - -o "${t1}"
  emit_ldscript $FLASH_BASE $FLASH_SIZE $MEMORY_BASE $MEMORY_SIZE > "${t2}"

  shift
  ${HL_CROSS_COMPILE}ld "-T${t2}" "${t1}" $@ -o "${t0}"
  ${HL_CROSS_COMPILE}objcopy "${t0}" -O ihex "${t1}"
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
