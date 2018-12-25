#!/bin/bash
set -Ceuo pipefail

PATH=/bin:/usr/bin
TZ=UTC; export TZ

# taken from run-prep0.sh
: ${base:?} ${reftime:?} ${yesterday:?}

cd $base
if test -f stop ; then
  logger --tag wxmon --id=$$ -p news.err -- "report suspended - remove ${base}/stop"
  false
fi

if ! mkdir wk.wxmon-report ; then
  logger --tag wxmon --id=$$ -s -p news.err -- "report dup - ${base}/wk.wxmon-report found"
  false
fi
cd wk.wxmon-report

uptime=$(ruby -e 'puts((Time.now - 86400).strftime("%Y-%m-%dT%H"))')


cd $base
rm -rf wk.wxmon-report
exit 0
