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
    get-extra-flags) hl_report_recurse -DPCA10059 ;;
    get-flash-base) hl_report 0x00001000 ;; # override default 0x0
    get-flash-size) hl_report 0x0007f000 ;;
    get-next) hl_report nrf52840.sh ;;
  esac
}

hl_qry_default
