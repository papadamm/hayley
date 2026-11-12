#!/bin/sh
# HL - Hayley parameter query and build script

HL_TOPDIR=.
__hl_fx() { echo "`cd $2 && /bin/pwd`/$1"; }
__hl_fy() { __hl_fx "$1" `dirname "$0"`; }
__hl_fz() { __hl_fy "${HL_TOPDIR}/hl_root.sh"; }
source `__hl_fz`

hl_qry ()
{
  case "$1" in
    get-cflags) hl_report_recurse -ffreestanding -O0 ;;
    get-ldflags) hl_report_recurse -nostdlib ;;
  esac
}

hl_query_top ()
{
  if [ -x "$HL_TOP" ]; then
     $HL_TOP $@
  fi
}

emit_c ()
{
    cat <<EOF
#include <stdint.h>

__attribute__((weak)) \
__attribute__((optimize("no-tree-loop-distribute-patterns"))) \
void *memset(void *b, int c, int len)
{
  uint8_t *dst = b;
  int k;

  for (k = 0; k < len; k++) {
    dst[k] = c;
  }

  return b;
}

__attribute__((weak)) \
__attribute__((optimize("no-tree-loop-distribute-patterns"))) \
void *memcpy(void *dst, void *src, int n)
{
  uint8_t *dst8 = dst;
  uint8_t *src8 = src;
  int k;

  for (k = 0; k < n; k++) {
    dst8[k] = src8[k];
  }

  return dst;
}

__attribute__((weak)) \
__attribute__((optimize("no-tree-loop-distribute-patterns"))) \
int memcmp(void *dst, void *src, int n)
{
  uint8_t *dst8 = dst;
  uint8_t *src8 = src;
  int k;

  for (k = 0; k < n; k++) {
    if (dst8[k] != src8[k]) {
      return dst8[k] - src8[k];
    }
  }

  return 0;
}
EOF
}

if [ "$1" == "get-str-code" ]; then
  cleanup() {
    rm -f "${t0}" "${t1}" 2>/dev/null
  }

  trap cleanup EXIT
  t0=$(mktemp)
  t1=$(mktemp)
  for e in "${t0}" "${t1}"
  do
    if [ -z "${e}" ]; then
      echo "Failed to create temporary file, exiting" >&2
      exit 1;
    fi
  done

  # turn on break-on-failure
  set -e

  HL_CROSS_COMPILE=`hl_query_top get-cross-compile`
  HL_TARGET_FLAGS=`hl_query_top get-cflags`

  # build the c code into the default object file
  emit_c | ${HL_CROSS_COMPILE}gcc ${HL_TARGET_FLAGS} \
			      -x c -c - -o "${t1}"

  # output base64 encoded data on stdout
  cat "${t1}" | uuencode -m -
  exit 0; # success
fi

hl_qry_default
