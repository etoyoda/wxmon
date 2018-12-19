<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:jmx="http://xml.kishou.go.jp/jmaxml1/" exclude-result-prefixes="jmx"
 xmlns:h="http://xml.kishou.go.jp/jmaxml1/informationBasis1/"
 xmlns:b="http://xml.kishou.go.jp/jmaxml1/body/meteorology1/"
 xmlns:e="http://xml.kishou.go.jp/jmaxml1/elementBasis1/"
 >

<xsl:output method="text" encoding="UTF-8"/>

<xsl:template match="/">
	<xsl:apply-templates select="jmx:Report" />
</xsl:template>

<xsl:template match="jmx:Report">
  <xsl:param name="rt" select="normalize-space(h:Head/h:ReportDateTime)" />
  <xsl:param name="rt9" select="translate($rt, '012345678', '999999999')" />
  <xsl:value-of select='concat("[", jmx:Control/jmx:PublishingOffice, " ",
    substring-before(substring-after($rt, "T"), ":00+"), "] ")' />
  <xsl:choose>
  <xsl:when test="normalize-space(h:Head/h:Headline/h:Text) != ''">
    <xsl:value-of select="normalize-space(h:Head/h:Headline/h:Text)"/>
  </xsl:when>
  <xsl:when test="b:Body//b:Item[b:Kind]/b:Station">
    <xsl:value-of select="concat(
      b:Body//b:Item/b:Station/b:Name, '&#x3067;',
      b:Body//b:Item/b:Kind/b:Name,
      b:Body//b:Item/b:Kind/b:Property/*/b:Temporary/*[local-name()!='WindDegree']/@description,
      b:Body//b:AdditionalInfo/b:ObservationAddition/b:Text
    )"/>
  </xsl:when>
  <xsl:when test="b:Body/b:Comment/b:Text">
    <xsl:value-of select="substring(normalize-space(b:Body/b:Comment/b:Text),1,140)"/>
  </xsl:when>
  <xsl:when test=".//b:PossibilityRankOfWarningPart">
    <xsl:variable name="tser">
      <xsl:apply-templates mode="keikano" select="b:Body/b:MeteorologicalInfos/
      b:TimeSeriesInfo[.//b:PossibilityRankOfWarningPart]/
      b:TimeDefines/b:TimeDefine">
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$tser = ''">===EMPTY===</xsl:if>
    <xsl:value-of select="$tser" />
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="concat('[',
      jmx:Control/jmx:Title, '|',
      jmx:Control/jmx:PublishingOffice, '|',
      jmx:Control/jmx:DateTime, ']'
    )"/>
  </xsl:otherwise>
  </xsl:choose>
  <xsl:value-of select='"&#10;"'/>

</xsl:template>

<xsl:template mode="keikano" match="b:TimeDefine">
  <xsl:param name="dt" select="b:DateTime" />
  <xsl:param name="du" select="b:Duration" />
  <xsl:variable name="dtv">
    <xsl:variable name="dt9" select="translate($dt,'012345678','999999999')" />
    <xsl:choose>
    <xsl:when test="$dt9 = '9999-99-99T99:99:99+99:99'">
      <xsl:value-of select="substring($dt,9,5)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$dt"/>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="iser">
    <xsl:apply-templates mode="keikano" select="../../b:Item">
      <xsl:with-param name="timeId" select="@timeId" />
    </xsl:apply-templates>
  </xsl:variable>
  <xsl:if test="$iser != ''">
    <xsl:value-of select="concat($dtv, '/', $du, ' ',
    translate(normalize-space($iser), ' ', ','), ' ')" />
  </xsl:if>
</xsl:template>

<xsl:template mode="keikano" match="b:Item">
  <xsl:param name="timeId" select="@timeId" />
  <xsl:variable name="kser">
    <xsl:for-each select="b:Kind/b:Property">
      <xsl:variable name="p"
      select="normalize-space(b:PossibilityRankOfWarningPart/
      e:PossibilityRankOfWarning)" />
      <xsl:choose>
      <xsl:when test="$p = '高'">
	<xsl:value-of select="concat(substring(b:Type, 1, 1), '!')" />
      </xsl:when>
      <xsl:when test="$p = '中'">
	<xsl:value-of select="concat(substring(b:Type, 1, 1), '?')" />
      </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:variable>
  <xsl:if test="$kser != ''">
    <xsl:value-of select="concat(b:Area/b:Name, ':', $kser, ' ')" />
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
