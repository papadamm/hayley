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
    get-extra-flags) hl_report_recurse -DCH32V003 ;;
    get-flash-base) hl_report 0x00000000 ;;
    get-flash-size) hl_report 0x00004000 ;; # 16 KiB FLASH
    get-memory-base) hl_report 0x20000000 ;;
    get-memory-size) hl_report 0x00000800 ;; # 2 KiB RAM
    get-next) hl_report ../riscv/riscv-rv32ec.sh ;;
  esac
}

hl_qry_default
