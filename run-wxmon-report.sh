#!/bin/bash
set -Ceuo pipefail

PATH=/bin:/usr/bin
TZ=UTC; export TZ

: ${nwp:=${HOME}/nwp-test}
: ${base:=${nwp}/p2}
: ${refhour:=$(date +'%Y-%m-%dT11Z')}

cd $base
if test -f stop ; then
  logger --tag wxmon --id=$$ -p news.err -- "report suspended - remove ${base}/stop"
  false
fi
jobwk=${base}/wk.${refhour}-wxmon.$$
mkdir $jobwk
cd $jobwk

cutoff=$(ruby -rtime -e 'puts((Time.parse(ARGV.first.sub(/Z/,":00Z")) - 86400).utc.strftime("%Y-%m-%dT%H:%MZ"))' $refhour)

ln -Tfs $nwp/p0/latest/jmx-index-2*.ltsv z.prev.ltsv
ln -Tfs $nwp/p0/latest/jmx-2*.tar z.prev.tar
ln -Tfs $nwp/p0/incomplete/jmx-index-2*.ltsv z.curr.ltsv
ln -Tfs $nwp/p0/incomplete/jmx-2*.tar z.curr.tar

TZ=JST-9 ruby $nwp/bin/report-jmxdaily.rb --cutoff=$cutoff z.prev.ltsv z.curr.ltsv > report.txt

case $nwp in
/nwp)
  bash /nwp/bin/mailjis.sh report.txt news updates
  ;;
esac

rm -rf z.*
cd $base
test ! -d ${refhour}-wxmon.bak || rm -rf ${refhour}-wxmon.bak
test ! -d ${refhour}-wxmon || mv -f ${refhour}-wxmon ${refhour}-wxmon.bak
mv $jobwk ${refhour}-wxmon
exit 0
