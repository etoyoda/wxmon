#!/bin/sh

cd `dirname $0`

. .htconfig

sh ./mon2.sh > y2out.txt
rc=$?
case "$rc" in
0)
  sh mailjis.sh y2out.txt $mailfrom $mailto
  ;;
48)
  : simply empty result
  ;;
*)
  echo mon2 exit status=$rc
  ;;
esac
