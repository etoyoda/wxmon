#!/bin/sh
set -Ceuo pipefail

PATH=/bin:/usr/bin

: ${phase:?} ${base:?} ${reftime:?} ${datedir:?} ${prefix:?}

: ${ruby:=/usr/bin/ruby}
: ${script:=${prefix}/bin/jmxscan.rb}

cd ${datedir}
test ! -e tmp.ltsv || rm -f tmp.ltsv

rc=0 && $ruby ${script} upstream/jmx-2*.tar > tmp.ltsv || rc=$?
if (( $rc != 0 )) ; then
  logger --tag wxmon --id=$$ -p news.err -s -- "jmxscan rc=$rc"
  exit $rc
fi

mv -f tmp.ltsv jmx-index.ltsv

exit 0

