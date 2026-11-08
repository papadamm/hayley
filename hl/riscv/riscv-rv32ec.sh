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
    get-asmflags) hl_report -march=rv32ec -mabi=ilp32e ;;
    get-cflags) hl_report -march=rv32ec -mabi=ilp32e ;;
    get-next) hl_report riscv-32bit.sh ;;
  esac
}

hl_qry_default
