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
#    target specific configuration, select toolchain and target board here
#    there should be one cross compiler and one target board selected	
#    when building pass this file to the makefile: "make HL=../local-sample.sh"
#
#    get-cross-compile) hl_report add-your-local-cross-compiler-prefix-here- ;;
#    get-next) hl_report nordic/pca10059.sh ;;
#    get-next) hl_report sparkfun/sparkfun-pro-micro.sh ;;
#    get-next) hl_report seeed-studio/seeeduino-nano.sh ;;
  esac
}

hl_qry_default
