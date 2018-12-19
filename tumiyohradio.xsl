<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:jmx="http://xml.kishou.go.jp/jmaxml1/" exclude-result-prefixes="jmx"
 xmlns:h="http://xml.kishou.go.jp/jmaxml1/informationBasis1/"
 xmlns:b="http://xml.kishou.go.jp/jmaxml1/body/meteorology1/"
 >

<xsl:output method="text" encoding="UTF-8"/>

<xsl:param name="ikind" select="'地方海上予報'"/>

<xsl:template match="/">
  <xsl:apply-templates select="jmx:Report" />
</xsl:template>

<xsl:template match="jmx:Report">
  <xsl:if test="normalize-space(h:Head/h:InfoKind/text()) != $ikind">
    <xsl:message terminate="yes">
      <xsl:value-of select="concat('InfoKind != ', $ikind)"/>
    </xsl:message>
  </xsl:if>
  <xsl:for-each select='b:Body/b:MeteorologicalInfos[@type="観測実況"]
  /b:MeteorologicalInfo/b:Item'>
    <xsl:value-of select="concat(b:Station/b:Name/text(), 'では、')"/>

    <xsl:choose>
    <xsl:when test="b:Kind/b:Condition/text() = '通常'">
      <xsl:value-of select="concat(b:Kind//b:WindDirectionPart/*/text(), 'の風、')"/>
      <xsl:value-of select="concat('風速',
      b:Kind//b:WindSpeedPart/*/@description, '、')"/>
      <xsl:value-of select="concat('天気 ',
      b:Kind//b:WeatherPart/*/text(), '、')"/>
      <xsl:value-of select="concat('気圧',
      b:Kind//b:PressurePart/*/@description, '、')"/>
      <xsl:value-of select="concat('気温',
      b:Kind//b:TemperaturePart/*/@description, '。')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat(b:Kind/b:Condition/text(), '。')"/>
    </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select='"&#10;"'/>
    <xsl:value-of select='"&#10;"'/>
  </xsl:for-each>
</xsl:template>
</xsl:stylesheet>

