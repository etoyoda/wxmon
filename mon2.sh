#!/bin/sh
:
export LANG=en_US.UTF-8
export TZ=JST-9
:
items="
%E6%B4%A5%E6%B3%A2%E8%AD%A6%E5%A0%B1%E3%83%BB%E6%B3%A8%E6%84%8F%E5%A0%B1%E3%83%BB%E4%BA%88%E5%A0%B1%61
%E6%B0%97%E8%B1%A1%E7%89%B9%E5%88%A5%E8%AD%A6%E5%A0%B1%E5%A0%B1%E7%9F%A5
%E6%B4%A5%E6%B3%A2%E6%83%85%E5%A0%B1%61
%E5%85%A8%E8%88%AC%E6%B0%97%E8%B1%A1%E6%83%85%E5%A0%B1
%E5%9C%B0%E6%96%B9%E6%B0%97%E8%B1%A1%E6%83%85%E5%A0%B1
%E5%BA%9C%E7%9C%8C%E6%B0%97%E8%B1%A1%E6%83%85%E5%A0%B1
%E6%8C%87%E5%AE%9A%E6%B2%B3%E5%B7%9D%E6%B4%AA%E6%B0%B4%E4%BA%88%E5%A0%B1
%E5%9C%9F%E7%A0%82%E7%81%BD%E5%AE%B3%E8%AD%A6%E6%88%92%E6%83%85%E5%A0%B1
%E8%AD%A6%E5%A0%B1%E7%B4%9A%E3%81%AE%E5%8F%AF%E8%83%BD%E6%80%A7%EF%BC%88%E6%98%8E%E6%97%A5%E3%81%BE%E3%81%A7%EF%BC%89
%E8%AD%A6%E5%A0%B1%E7%B4%9A%E3%81%AE%E5%8F%AF%E8%83%BD%E6%80%A7%EF%BC%88%E6%98%8E%E5%BE%8C%E6%97%A5%E4%BB%A5%E9%99%8D%EF%BC%89
%E5%85%A8%E8%88%AC%E5%8F%B0%E9%A2%A8%E6%83%85%E5%A0%B1%EF%BC%88%E5%AE%9A%E5%9E%8B%EF%BC%89
%E8%A8%98%E9%8C%B2%E7%9A%84%E7%9F%AD%E6%99%82%E9%96%93%E5%A4%A7%E9%9B%A8%E6%83%85%E5%A0%B1
%E7%AB%9C%E5%B7%BB%E6%B3%A8%E6%84%8F%E6%83%85%E5%A0%B1%EF%BC%88%E7%9B%AE%E6%92%83%E6%83%85%E5%A0%B1%E4%BB%98%E3%81%8D%EF%BC%89
%E7%89%B9%E6%AE%8A%E6%B0%97%E8%B1%A1%E5%A0%B1
%E5%AD%A3%E7%AF%80%E8%A6%B3%E6%B8%AC
%E5%99%B4%E7%81%AB%E8%AD%A6%E5%A0%B1%E3%83%BB%E4%BA%88%E5%A0%B1
%E9%99%8D%E7%81%B0%E4%BA%88%E5%A0%B1%EF%BC%88%E8%A9%B3%E7%B4%B0%EF%BC%89
%E7%94%9F%E7%89%A9%E5%AD%A3%E7%AF%80%E8%A6%B3%E6%B8%AC
%E9%9C%87%E5%BA%A6%E9%80%9F%E5%A0%B1
%E7%95%B0%E5%B8%B8%E5%A4%A9%E5%80%99%E6%97%A9%E6%9C%9F%E8%AD%A6%E6%88%92%E6%83%85%E5%A0%B1
%E5%9C%B0%E6%96%B9%E9%AB%98%E6%B8%A9%E6%B3%A8%E6%84%8F%E6%83%85%E5%A0%B1
%E5%BA%9C%E7%9C%8C%E6%BD%AE%E4%BD%8D%E6%83%85%E5%A0%B1
%E3%82%B9%E3%83%A2%E3%83%83%E3%82%B0%E6%B0%97%E8%B1%A1%E6%83%85%E5%A0%B1
%E5%9C%B0%E6%96%B9%E5%A4%A9%E5%80%99%E6%83%85%E5%A0%B1
%E5%9C%B0%E9%9C%87%E3%81%AE%E6%B4%BB%E5%8B%95%E7%8A%B6%E6%B3%81%E7%AD%89%E3%81%AB%E9%96%A2%E3%81%99%E3%82%8B%E6%83%85%E5%A0%B1
%E5%9C%B0%E6%96%B9%EF%BC%91%E3%81%8B%E6%9C%88%E4%BA%88%E5%A0%B1
%E5%9C%B0%E6%96%B9%EF%BC%93%E3%81%8B%E6%9C%88%E4%BA%88%E5%A0%B1
	"
smry=''
for item in $items
do
  url="http://toyoda-eizi.net/pshbjmx/m1/${item}"
  z=z2
  :
  wget -q -O${z}list.html $url
  xsltproc tlistupd.xsl ${z}list.html > ${z}list.tsv
  ruby -e 'puts((Time.now - 86500).localtime.strftime("%Y-%m-%d %H:00:00\tstop"))' >> ${z}list.tsv
  sort -r ${z}list.tsv > ${z}lists.tsv
  kitem=$(echo "$item" | ruby -rcgi -e "puts CGI.unescape(STDIN.gets)")
  echo "= $kitem"
  n=0
  while read date time url
  do
    test X"$url" = X"stop" && break
    let n+=1
    xml=${z}msg${n}.xml
    wget -q -O${xml} "$url"
    msg=$(xsltproc theadline.xsl ${xml})
    case $msg in
    *===EMPTY===*)
      let n-=1
      ;;
    *)
      test $n -ne 1 || echo ''
      echo $msg
      echo $url
      ;;
    esac
    test -f z.keep || rm -f ${xml}
  done < ${z}lists.tsv
  if test $n -eq 0 ; then
    echo "ありません。"
  else
    kitemh=$(echo $kitem | cut -c1-4)
    smry="$smry, ${n}x${kitemh}"
    echo ''
  fi
  test -f z.keep || rm -f ${z}*
done
test X"$smry" != X"" || exit 48
echo "~s 電文モニタ$smry"
