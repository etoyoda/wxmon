#!/bin/sh
set -Ceuo pipefail

PATH=/bin:/usr/bin

: ${datedir:?}
: ${nwp:?}

# logger --tag wxmon --id=$$ -p news.notice -- "nwp=$nwp datedir=$datedir"

: ${ruby:=/usr/bin/ruby}
: ${script:=${nwp}/bin/jmxscan.rb}

cd ${datedir}
test ! -e tmp.ltsv || rm -f tmp.ltsv
ymd=$(basename ${datedir} .new)

kill=''
if [ -f jmx-index-${ymd}.ltsv ]; then
  kill="--kill=jmx-index-${ymd}.ltsv"
fi

rc=0 && $ruby ${script} ${kill} jmx-${ymd}.tar > tmp.ltsv || rc=$?
if (( $rc != 0 )) ; then
  logger --tag wxmon --id=$$ -p news.err -s -- "jmxscan rc=$rc"
  exit $rc
fi

cat tmp.ltsv >> jmx-index-${ymd}.ltsv
logger --tag wxmon --id=$$ -p news.info -- "jmx-index-${ymd}.ltsv updated"

exit 0

