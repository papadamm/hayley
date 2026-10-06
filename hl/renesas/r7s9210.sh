#!/bin/sh
# HL - Hayley parameter query and build script

hl_qry ()
{
  case "$1" in
    get-flash-base) echo 0x80200000 ;; # "Large-Capacity On-Chip RAM"
    get-flash-size) echo 0x00100000 ;; # Page 3 (1024 KB) "
    get-memory-base) echo 0x80020000 ;;
    get-memory-size) echo 0x00002000 ;; # Half of Page 0 (16 KB)
    get-next) echo ../arm/arm-cortex-a9.sh ;;
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
