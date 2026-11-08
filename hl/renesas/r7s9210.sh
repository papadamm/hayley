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
    get-flash-base) hl_report 0x80200000 ;; # "Large-Capacity On-Chip RAM"
    get-flash-size) hl_report 0x00100000 ;; # Page 3 (1024 KB) "
    get-memory-base) hl_report 0x80020000 ;;
    get-memory-size) hl_report 0x00002000 ;; # Half of Page 0 (16 KB)
    get-next) hL_report ../arm/arm-cortex-a9.sh ;;
  esac
}

hl_qry_default
