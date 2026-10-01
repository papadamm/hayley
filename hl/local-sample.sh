#!/bin/sh
# HL - Hayley parameter query and build script

hl_qry ()
{
    case "$1" in
#    target specific configuration, select toolchain and target board here
#    there should be one cross compiler and one target board selected	
#    when building pass this file to the makefile: "make HL=../local-sample.sh"
#
#    get-cross-compile) echo add-your-local-cross-compiler-prefix-here- ;;
#    get-next) echo nordic/pca10059.sh ;;
#    get-next) echo sparkfun/sparkfun-pro-micro.sh ;;
#    get-next) echo seeed-studio/seeeduino-nano.sh ;;
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
