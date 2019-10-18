#!/bin/sh
set -Ceuo pipefail

export LANG=en_US.UTF-8
PATH=/bin:/usr/bin

: ${datedir:?}
: ${nwp:?}

# logger --tag wxmon --id=$$ -p news.notice -- "nwp=$nwp datedir=$datedir"

: ${ruby:=/usr/bin/ruby}
: ${script:=${nwp}/bin/jmxscan.rb}

cd ${datedir}
if test -e lock-wxmon.ltsv ; then
  logger --tag wxmon --id=$$ -p news.err -- "rescue=EAGAIN"
  exit 11
fi
trap 'rm lock-wxmon.ltsv' 0
touch lock-wxmon.ltsv

ymd=$(basename ${datedir} .new)

kill=''
if [ -f jmx-index-${ymd}.ltsv ]; then
  kill="--kill=jmx-index-${ymd}.ltsv"
fi
db=''
if [ -f jmx-${ymd}.idx1 ]; then
  db="--db=jmx-${ymd}.idx1"
fi

rc=0 && $ruby ${script} ${kill} ${db} jmx-${ymd}.tar >> lock-wxmon.ltsv || rc=$?
case $rc in
0)
  : okay
  ;;
11)
  logger --tag wxmon --id=$$ -p news.err -- "jmxscan rc=$rc" ; exit $rc
  ;;
*)
  logger --tag wxmon --id=$$ -p news.err -s -- "jmxscan rc=$rc" ; exit $rc
  ;;
esac

cat lock-wxmon.ltsv >> jmx-index-${ymd}.ltsv
logger --tag wxmon --id=$$ -p news.info -- "jmx-index-${ymd}.ltsv updated"

exit 0

