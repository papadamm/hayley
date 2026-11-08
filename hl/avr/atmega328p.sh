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
    get-asmflags) hl_report_recurse -mmcu=atmega328p ;;
    get-cflags) hl_report_recurse -mmcu=atmega328p ;;
    get-flash-base) hl_report 0x00000000 ;;
    get-flash-size) hl_report 0x00008000 ;;
    get-memory-base) hl_report 0x00000100 ;;
    get-memory-size) hl_report 0x00000800 ;;
    get-next) hl_report avr.sh ;;
  esac
}

hl_qry_default
