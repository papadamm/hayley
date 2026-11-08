#!/bin/sh
# HL - Hayley parameter query and build script

HL_TOPDIR=..
__hl_fx() { echo "`cd $2 && /bin/pwd`/$1"; }
__hl_fy() { __hl_fx "$1" `dirname "$0"`; }
__hl_fz() { __hl_fy "${HL_TOPDIR}/hl_root.sh"; }
source `__hl_fz`

hl_qry ()
{
  case "$1" in
  get-next) hl_report ../hl_freestanding.sh ;;
  esac
}

hl_query_top ()
{
  if [ -x "$HL_TOP" ]; then
     $HL_TOP $@
  fi
}

emit_asm ()
{
if [ "`hl_query_top get-arm-vector-table-needed`" == "yes" ] ; then
cat <<EOF
  .syntax unified

  .global vector_table
vector_table:
  .long 0 /* Top of stack set to nothing since unused */
  .long _start
  .space 126 * 4
EOF
fi

cat <<EOF
  .syntax unified

  .align 1
  .global _start
  .type _start, %function
_start:
  /* copy .data from __etext to __data_start__ */
  ldr r1, =__etext
  ldr r2, =__data_start__
  ldr r3, =__data_end__
  subs r3, r3, r2
  ble data_copy_done

data_copy_repeat:
  subs r3, r3, #4
  ldr r0, [r1,r3]
  str r0, [r2,r3]
  bgt data_copy_repeat

data_copy_done:
  /* clear bss, from __bss_start__ to __bss_end__ */
  movs r0, #0
  ldr r2, =__bss_start__
  ldr r3, =__bss_end__
  subs r3, r3, r2
  ble bss_clear_done

bss_clear_repeat:
  subs r3, r3, #4
  str r0, [r2,r3]
  bgt bss_clear_repeat

bss_clear_done:
  ldr r1, =__stack
  mov sp, r1

  bl main

end:
  b end

  .align 2
  .pool
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
EOF

if [ "`hl_query_top get-arm-vector-table-needed`" == "yes" ] ; then
  echo "ENTRY(vector_table)"
else
  echo "ENTRY(_start)"
fi
cat <<EOF
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

handle_link_command ()
{
  OBJOUT=$1
  MAPOUT=$2
  shift; shift
  HL_CROSS_COMPILE=`hl_query_top get-cross-compile`
  HL_TARGET_FLAGS=`hl_query_top get-asmflags`

  # Probe for required software components
  for e in cat grep mktemp rm uudecode wc which ${HL_CROSS_COMPILE}gcc \
	     ${HL_CROSS_COMPILE}ld ${HL_CROSS_COMPILE}objcopy
  do
    if [ -z `which $e` ]; then
      echo "unable to detect required software component $e, exiting" >&2
      exit 1;
    fi
  done

  # Check that HL_CROSS_COMPILE actually points to a c compiler for ARM
  ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
		     -c /dev/null -o /dev/null 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Failed to detect ARM support in HL_CROSS_COMPILE, exiting" >&2
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

  if [ "${MAPOUT}" != /dev/null ]; then
    ${HL_CROSS_COMPILE}ld "-T${t2}" "${t1}" -Map=${MAPOUT} $@ -o "${t0}"
  else
    ${HL_CROSS_COMPILE}ld "-T${t2}" "${t1}" $@ -o "${t0}"
  fi

  if [ "${OBJOUT}" != /dev/null ]; then
    cp "${t0}" "${OBJOUT}"
  fi

  # add boot2 code as a prefix (this is needed for rp2040)
  hl_query_top get-boot2-code > "${t1}"
  if [ -n "`cat ${t1}`" ]; then
    cat "${t1}" | uudecode -o "${t2}"
    ${HL_CROSS_COMPILE}objcopy "${t0}" -O binary "${t1}"
    cat "${t2}" "${t1}" > "${t0}"
    ${HL_CROSS_COMPILE}objcopy -I binary "${t0}" -O ihex "${t1}"
  else
    ${HL_CROSS_COMPILE}objcopy "${t0}" -O ihex "${t1}"
  fi

  cat "${t1}" # the contents come out on stdout
}

# link command requires special handling

if [ "$1" == "link" ]; then
  shift
  handle_link_command /dev/null /dev/null $@
  exit 0
fi

if [ "$1" == "link-debug" ]; then
  shift
  handle_link_command debug.o debug.map $@
  echo "Notice: build debugging has been enabled with the link-debug command." >&2
  echo "Notice: asm-32bit.sh has generated files debug.o and debug.map." >&2
  exit 0
fi

hl_qry_default
