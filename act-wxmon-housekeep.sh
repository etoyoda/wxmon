#!/bin/bash
set -Ceuo pipefail
PATH=/bin:/usr/bin

: ${nwp:?}
: ${ruby:=/usr/bin/ruby}
: ${datedir:=latest}

logger --tag wxmon-housekeep --id=$$ -p news.notice -- "nwp=$nwp datedir=$datedir"

test -d ${nwp}/p0/${datedir} || exit 0
cd ${nwp}/p0/${datedir}

${ruby} ${nwp}/bin/tdif-pull.rb jmx-index-2*.ltsv > z.$$
mv z.$$ tdif-pull.txt
${ruby} ${nwp}/bin/tdif-push.rb pshb.db jmx-index-2*.ltsv > z.$$
mv z.$$ tdif-push.txt
if test -d logs; then
  ln -f tdif-pull.txt logs/tdif-pull.txt
  ln -f tdif-push.txt logs/tdif-push.txt
fi
