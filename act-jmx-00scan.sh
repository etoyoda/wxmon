#!/bin/sh
set -Ceuo pipefail

PATH=/bin:/usr/bin

: ${phase:?} ${base:?} ${reftime:?} ${datedir:?} ${prefix:?}

: ${ruby:=/usr/bin/ruby}
: ${script:=${prefix}/bin/jmxscan.rb}

cd ${datedir}
test ! -e tmp.ltsv || rm -f tmp.ltsv
ymd=$(basename ${datedir} .new)

if ! test jmx-${ymd}.tar -nt jmx-index-${ymd}.ltsv ; then
  logger --tag wxmon --id=$$ -p news.err -s -- "jmx-index-${ymd}.ltsv up to date"
  exit 0
fi

rc=0 && $ruby ${script} jmx-2???-??-??.tar > tmp.ltsv || rc=$?
if (( $rc != 0 )) ; then
  logger --tag wxmon --id=$$ -p news.err -s -- "jmxscan rc=$rc"
  exit $rc
fi

mv -f tmp.ltsv jmx-index-${ymd}.ltsv

exit 0

