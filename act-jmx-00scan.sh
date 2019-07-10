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

if $ruby -e 'exit(15) if (File.stat(ARGV[1]).mtime - File.stat(ARGV[0]).mtime) > 3600.0' \
  jmx-index-${ymd}.ltsv jmx-${ymd}.tar 
then
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

