#!/bin/bash
set -Ceuo pipefail
export LANG=en_US.utf8
PATH=/bin:/usr/bin

: ${nwp:?}
: ${ruby:=/usr/bin/ruby}
: ${wkdir:=${nwp}/p0/latest}


logger --tag wxmon-housekeep --id=$$ -p news.notice -- "nwp=$nwp wkdir=$wkdir"
trap 'logger --tag wxmon-housekeep --id=$$ -p news.err -- "exitcode=$? phase=$st"' 0

st=chdir
# this must not fail, otherwise stderr message to be emailed
cd ${wkdir}

st=init
test ! -f z.$$ || rm -f z.$$

st=pull
${ruby} ${nwp}/bin/tdif-pull.rb jmx-index-2*.ltsv > z.$$
mv z.$$ tdif-pull.txt
test ! -d logs || ln -f tdif-pull.txt logs/tdif-pull.txt

st=push
${ruby} ${nwp}/bin/tdif-push.rb pshb.db jmx-index-2*.ltsv > z.$$
mv z.$$ tdif-push.txt
test ! -d logs || ln -f tdif-push.txt logs/tdif-push.txt

trap 0
logger --tag wxmon-housekeep --id=$$ -p news.notice -- "done"

