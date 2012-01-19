<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns="http://www.w3.org/2005/Atom"
    xmlns:daia="http://ws.gbv.de/daia/"
    xmlns:dcterms="http://purl.org/dc/terms/" 
    xmlns:opds="http://opds-spec.org/"
><!--

This XSLT script transforms a DAIA/XML response into an aquisition feed
conforming to the Open Publication Distribution System (OPDS).

  -->
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- URL to the resulting feed -->
  <xsl:param name="self"/>

  <xsl:template match="/daia:daia">
    <feed>
        <title>TODO</title> <!-- TODO: just copy dc:title -->
        <id>TODO</id>

        <updated><xsl:value-of select="/*/@timestamp"/></updated>
        <xsl:if test="$self">
            <link rel="self" href="{$self}"
                type="application/atom+xml;profile=opds-catalog;kind=acquisition" />
        </xsl:if>

        <xsl:apply-templates select="daia:institution"/>
        <xsl:apply-templates select="daia:document"/>
    </feed>
  </xsl:template>

  <!-- The institution can be seen as 'author' of the feed -->
  <xsl:template match="daia:institution">
    <xsl:variable name="name" select="normalize-space(.)"/>
    <xsl:variable name="url"  select="normalize-space(@id)"/>
    <xsl:if test="$name or $url">
      <author>
        <xsl:if test="$name">
          <name><xsl:value-of select="$name"/></name>
        </xsl:if>
        <xsl:if test="$url">
          <uri><xsl:value-of select="$url"/></uri>
        </xsl:if>
      </author>
    </xsl:if>
  </xsl:template>
 
  <xsl:template match="daia:document">
    <entry>
        <title>TODO</title>
        <id><xsl:value-of select="@id"/></id>

        <!-- when the entry itself was updated -->
        <updated><xsl:value-of select="/*/@timestamp"/></updated>

        <!-- We could add <dc:issued>original date</dc:issued> --> 

        <!-- TODO: every element MUST have a link, so sort out if not given! -->
        <xsl:if test="@href">
          <link href="{@href}" type="text/html"/>
        </xsl:if>
        
        <xsl:apply-templates select="daia:item/daia:available" />
    </entry>
  </xsl:template>

  <!-- TODO: what about <available service="presentation"> without @href? -->

  <xsl:template match="daia:available[@href]">
    <xsl:variable name="service"> <!-- select="substring-after(@service,':')" -->
      <xsl:choose>
        <xsl:when test="@service = 'loan'">
          <xsl:text>http://purl.org/ontology/daia/Service/Loan</xsl:text>
        </xsl:when>
        <xsl:when test="@service = 'presentation'">
          <xsl:text>http://purl.org/ontology/daia/Service/Presentation</xsl:text>
        </xsl:when>
       <xsl:when test="@service = 'interloan'">
          <xsl:text>http://purl.org/ontology/daia/Service/Interloan</xsl:text>
        </xsl:when>
        <xsl:when test="@service = 'openaccess'">
          <xsl:text>http://purl.org/ontology/daia/Service/Openaccess</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@service" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- TODO: maybe opds:indirectAcquisition is a better choice? -->
    <xsl:choose>
      <xsl:when test="$service = 'http://purl.org/ontology/daia/Service/Loan'">
        <link href="{@href}" rel="http://opds-spec.org/acquisition/borrow">
          <opds:indirectAcquisition/> <!-- TOOD: type? -->
        </link>
      </xsl:when>
      <xsl:when test="$service = 'http://purl.org/ontology/daia/Service/Interloan'">
        <!-- ignore interloan -->
      </xsl:when>
      <xsl:when test="$service = 'http://purl.org/ontology/daia/Service/Openaccess'">
        <link href="{@href}" rel="http://opds-spec.org/acquisition/open-access"/>
      </xsl:when>
      <xsl:otherwise>
        <link href="{@href}" rel="http://opds-spec.org/acquisition">
          <xsl:comment><xsl:value-of select="$service"/></xsl:comment>
        </link>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*"/>
</xsl:stylesheet>
