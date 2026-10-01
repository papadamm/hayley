#!/bin/sh
# HL - Hayley parameter query and build script

hl_qry ()
{
  case "$1" in
    get-extra-flags) echo -DPCA10059 ;;
    get-flash-base) echo 0x00001000 ;; # override default 0x0
    get-flash-size) echo 0x0007f000 ;;
    get-next) echo nrf52840.sh ;;
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
