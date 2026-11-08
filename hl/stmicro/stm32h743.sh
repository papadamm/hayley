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
    get-extra-flags) hl_report_recurse -DSTM32H743 ;;
    get-flash-base) hl_report 0x08000000 ;;
    get-flash-size) hl_report 0x00200000 ;;
    get-memory-base) hl_report 0x24000000 ;; # AXI SRAM
    get-memory-size) hl_report 0x00060000 ;; # 384 KiB
    get-next) hl_report ../arm/arm-cortex-m7.sh ;;
  esac
}

hl_qry_default
