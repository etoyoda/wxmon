wget -Oz1list.html 'http://toyoda-eizi.net/pshbjmx/m2/%E5%85%A8%E8%88%AC%E6%B5%B7%E4%B8%8A%E8%AD%A6%E5%A0%B1%EF%BC%88%E5%AE%9A%E6%99%82%EF%BC%89/%E6%B0%97%E8%B1%A1%E5%BA%81%E6%9C%AC%E5%BA%81'
rtime=`xmllint --xpath 'string(//td[@id="Xrtime"])' z1list.html`
if test ! -f y1time.txt ; then
  TZ=JST-9 date +'%Y-%m-%d %H:%M:%S' > y1time.txt
fi
btime=`cat y1time.txt`
earlier=`(echo $btime; echo $rtime) | sort | head -1`
if test X"$earlier" = X"$btime" ; then
  url=`xmllint --xpath 'string(//a[@class="JMX"]/@href)' z1list.html`
  wget -Oz1data.xml "$url"
fi
