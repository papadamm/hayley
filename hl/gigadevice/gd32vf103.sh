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
    get-extra-flags) hl_report_recurse -DGD32VF103 ;;
    get-flash-base) hl_report 0x00000000 ;;
    get-flash-size) hl_report 0x00004000 ;; # assume 16 KiB FLASH
    get-memory-base) hl_report 0x20000000 ;;
    get-memory-size) hl_report 0x00001800 ;; # assume 6 KiB RAM
    get-next) hl_report ../riscv/riscv-rv32imac.sh ;;
  esac
}

hl_qry_default
