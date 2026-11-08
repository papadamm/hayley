#!/bin/sh
# HL - Hayley parameter query and build script

ARGS_IN=$@
if [ -z "$HL_TOP" ]; then export HL_TOP=$0; fi
__hl_abs_f () { echo "`cd $2 && /bin/pwd`/`basename $1`"; }
__hl_next()
{
  __HL_DIRNAME_ZERO=`dirname "$0"`
  C=`__hl_abs_f "$0" "$__HL_DIRNAME_ZERO"`
  #if [ -z "$HL_TOP" ]; then export HL_TOP=$C; fi
  QN=`$C get-next`
  if [ -n "$QN" ]; then
    DN=`dirname $QN`; DN2=`cd $__HL_DIRNAME_ZERO/$DN && /bin/pwd`
    N=`__hl_abs_f "$QN" "$DN2"`
    if [ -x "$N" ]; then shift; $N $ARGS_IN; fi
  fi
}
__hl_output()
{
  if [ -n "$1" ]; then /bin/echo -n "$1"; fi; if [ -n "$2" ]; then
  if [ -n "$1" ]; then /bin/echo -n " "; fi; /bin/echo "$2"; fi
}
hl_report () { __hl_output "$@"; }
hl_recurse_report () { __hl_output "$@" "`__hl_next`"; }
hl_report_recurse () { __hl_output "`__hl_next`" "$@"; }
hl_qry_default ()
{
  Q=`hl_qry "$ARGS_IN"`; if [ -n "$Q" ]; then echo "$Q"; exit 0; fi
  N=`hl_qry get-next`; if [ -n "$N" ]; then __hl_next; fi
}
