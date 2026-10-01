#!/bin/sh
# HL - Hayley parameter query and build script

hl_qry ()
{
  case "$1" in
    get-extra-flags) echo -DSPARKFUN_PRO_MICRO ;;
    get-memory-base) echo 0x20000000 ;;
    get-memory-size) echo 0x00042000 ;;
    get-flash-base) echo 0x10000000 ;;
    get-flash-size) echo 0x00010000 ;; # FIXME: this is incorrect
    get-next) echo ../arm/arm-cortex-m0plus.sh ;;
  esac
}

# Answer immediately and exit if we are able to
Q=`hl_qry "$1"`
if [ -n "$Q" ]; then echo "$Q"; exit 0; fi

# If not use get-next to query next script
abs_f () { echo "`cd $2 && /bin/pwd`/`basename $1`"; }
DIRNAME_ZERO=`dirname "$0"`
C=`abs_f "$0" "$DIRNAME_ZERO"`
if [ -z "$HL_TOP" ]; then export HL_TOP=$C; fi
for QN in `hl_qry get-next`
do
  DN=`dirname $QN`; DN2=`cd $DIRNAME_ZERO/$DN && /bin/pwd`
  N=`abs_f "$QN" "$DN2"`
  if [ -x "$N" ]; then $N $@; fi
done
