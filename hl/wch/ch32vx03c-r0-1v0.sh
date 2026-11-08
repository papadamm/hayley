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
    get-extra-flags) hl_report_recurse -DCH32V203C8T6_R0_1V0 ;;
    get-next) hl_report ch32v203x8.sh ;;
  esac
}

hl_qry_default
