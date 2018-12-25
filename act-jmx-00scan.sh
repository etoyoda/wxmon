#!/bin/sh
set -Ceuo pipefail

PATH=/bin:/usr/bin

: ${phase:?} ${base:?} ${reftime:?} ${datedir:?} ${prefix:?}

# logger --tag wxmon --id=$$ -p news.notice -- "prefix=$prefix datedir=$datedir phase=$phase base=$base reftime=$reftime"

: ${ruby:=/usr/bin/ruby}
: ${script:=${prefix}/bin/jmxscan.rb}

cd ${datedir}
test ! -e tmp.ltsv || rm -f tmp.ltsv
ymd=$(basename ${datedir} .new)

if test jmx-index-${ymd}.ltsv -nt jmx-${ymd}.tar ; then
  logger --tag wxmon --id=$$ -p news.info -- "jmx-index-${ymd}.ltsv up to date"
  exit 0
fi

rc=0 && $ruby ${script} jmx-${ymd}.tar > tmp.ltsv || rc=$?
if (( $rc != 0 )) ; then
  logger --tag wxmon --id=$$ -p news.err -s -- "jmxscan rc=$rc"
  exit $rc
fi

mv -f tmp.ltsv jmx-index-${ymd}.ltsv
logger --tag wxmon --id=$$ -p news.info -- "jmx-index-${ymd}.ltsv updated"

exit 0

