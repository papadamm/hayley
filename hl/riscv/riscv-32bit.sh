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
  .global _start
  .type _start, %function
_start:
  /* copy .data from __etext to __data_start__ */
  la a1, __etext
  la a2, __data_start__
  la a3, __data_end__
  sub a4, a3, a2
  beqz a4, data_copy_done

data_copy_repeat:
  lb t0, 0(a1) /* one byte at a time -> slow */
  sb t0, 0(a2)
  addi a1, a1, 1
  addi a2, a2, 1
  bltu a2, a3, data_copy_repeat

data_copy_done:
  /* clear bss, from __bss_start__ to __bss_end__ */
  la a2, __bss_start__
  la a3, __bss_end__
  sub a4, a3, a2
  beqz a4, bss_clear_done

bss_clear_repeat:
  sb zero, 0(a2) /* one byte at a time -> slow */
  addi a2, a2, 1
  bltu a2, a3, bss_clear_repeat

bss_clear_done:
  la sp, __stack

  call main

end:
  j end
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

ENTRY(_start)

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
  for e in cat grep mktemp rm uudecode wc which ${HL_CROSS_COMPILE}gcc \
	     ${HL_CROSS_COMPILE}ld ${HL_CROSS_COMPILE}objcopy
  do
    if [ -z `which $e` ]; then
      echo "unable to detect required software component $e, exiting" >&2
      exit 1;
    fi
  done

  # Check that HL_CROSS_COMPILE actually points to a c compiler for RISCV
  ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
		     -c /dev/null -o /dev/null 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Failed to detect RISCV support in HL_CROSS_COMPILE, exiting" >&2
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
