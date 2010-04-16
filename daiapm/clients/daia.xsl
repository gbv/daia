<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:d="http://ws.gbv.de/daia/"
>
  <!--
    XSLT client for DAIA. Developer version

    Recent changes:

      2008-11-06: adopted schema version 0.4
      2008-11-05: included parts of hebis
      2008-11-11: better support messages, css in a file
      2008-11-12: added limitation/fragment
      2008-11-24: special case of no items

    TODO:
      - i18n of messages
      - check whether "Gesamtstatus" is only limited/fragmented

  -->
  <xsl:import href="xmlverbatim.xsl"/>
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- URL of CSS file -->
  <xsl:param name="stylesheet">daia.css</xsl:param>

  <!-- prefered language to show messages in -->
  <xsl:param name="language">de</xsl:param>


  <!-- root -->
  <xsl:template match="/">
    <xsl:apply-templates select="d:daia"/>
  </xsl:template>

  <xsl:template match="d:daia">
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Document Availability Information API</title>
        <xsl:if test="$stylesheet">
          <link rel="stylesheet" type="text/css" href="{$stylesheet}"/>
        </xsl:if>
      </head>
      <body>
        <h1>Document Availability Information (DAIA)</h1>
        <div id="meta">
          Timestamp: <xsl:value-of select="@timestamp"/><br/>
          DAIA version: <xsl:value-of select="@version"/>
        </div>
        <xsl:apply-templates select="d:message"/>
        <xsl:apply-templates select="d:institution"/>
        <xsl:variable name="items" select="d:document/d:item"/>
        <xsl:if test="$items">
          <h2>Exemplare</h2>
          <p>
            <table border="1">
              <tr>
                <th>Dokument</th>
                <th>Exemplar</th>
                <th>Standortinformationen</th>
                <th>Präsenz<br/>(vor Ort<br/>einsehbar?)</th>
                <th>Ausleihe<br/>(extern<br/>einsehbar?)</th>
                <th>Fernleihe<br/>(für externe<br/>einsehbar?)</th>
                <th>Frei Verfügbar<br/>(Open Access?)</th>
                <th>Hinweis(e)</th>
              </tr>
              <xsl:apply-templates select="$items"/>
              <xsl:if test="count($items) &gt; 1">
                <xsl:call-template name="summary"/>
              </xsl:if>
            </table>
          </p>
          <p align="right" style="padding-top: 0.5em">
              <xsl:text>Legende: </xsl:text>
              <xsl:call-template name="status">
                <xsl:with-param name="value" select="1"/>
                <xsl:with-param name="legend" select="true()"/>
              </xsl:call-template>
              <xsl:text> </xsl:text>
              <xsl:call-template name="status">
                <xsl:with-param name="value" select="2"/>
                <xsl:with-param name="legend" select="true()"/>
              </xsl:call-template>
              <xsl:text> </xsl:text>
              <xsl:call-template name="status">
                <xsl:with-param name="value" select="3"/>
                <xsl:with-param name="legend" select="true()"/>
              </xsl:call-template>
              <xsl:text> </xsl:text>
              <xsl:call-template name="status">
                <xsl:with-param name="value" select="0"/>
                <xsl:with-param name="legend" select="true()"/>
              </xsl:call-template>
              <div class="limited">
                <xsl:text>Eingeschränkt: </xsl:text>
                <xsl:call-template name="status">
                  <xsl:with-param name="value" select="1"/>
                </xsl:call-template>
                <xsl:call-template name="status">
                  <xsl:with-param name="value" select="3"/>
                </xsl:call-template>
              </div>
          </p>
        </xsl:if>
        <xsl:if test="not(d:item) and d:document"> <!-- no items -->
          <h2>Dokumente</h2>
          <table>
            <xsl:for-each select="d:document">
              <tr><td>
                <xsl:apply-templates select="."/>
                <xsl:apply-templates select="d:message"/>
              </td></tr>
          </xsl:for-each>
          </table>
        </xsl:if>
        <h2>Raw XML response (this document)</h2>
        <xsl:apply-templates select="/" mode="xmlverb" />
        <div id="about">
          See <a href="http://purl.org/NET/DAIA">http://purl.org/NET/DAIA</a>
          for more information about DAIA.
        </div>
      </body>
    </html>
  </xsl:template>


  <xsl:template name="status">
    <xsl:param name="value"/>
    <xsl:param name="legend"/>
    <span>
      <xsl:choose>
        <xsl:when test="$value = 1">
          <xsl:attribute name="class">available</xsl:attribute>
          <xsl:text>&#xA0;</xsl:text>
          <xsl:if test="$legend">verfügbar</xsl:if>
        </xsl:when>
        <xsl:when test="$value = 2">
          <xsl:attribute name="class">status2</xsl:attribute>
          <xsl:text>&#xA0;</xsl:text>
          <xsl:if test="$legend">nicht verfügbar</xsl:if>
        </xsl:when>
        <xsl:when test="$value = 3">
          <xsl:attribute name="class">status3</xsl:attribute>
          <xsl:text>&#xA0;</xsl:text>
          <xsl:if test="$legend">derzeit nicht verfügbar</xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="class">status0</xsl:attribute>
          <xsl:text>&#xA0;</xsl:text>
          <xsl:if test="$legend">unbekannt</xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </span>
    <xsl:if test="@href">
      <a href="{@href}">LINK</a>
    </xsl:if>
  </xsl:template>


  <xsl:template match="d:item">
    <xsl:variable name="status" select="d:available|d:unavailable"/>
    <tr>
      <xsl:if test="@fragment='true' or @fragment='1'">
        <xsl:attribute name="class">fragment</xsl:attribute>
      </xsl:if>
      <td>
        <xsl:if test="position() = 1">
          <xsl:apply-templates select="parent::d:document"/>
          <xsl:apply-templates select="parent::d:document/d:message"/>
        </xsl:if>
        <xsl:if test="@fragment='true' or @fragment='1'">(teilweise)</xsl:if>
      </td>
      <td>
        <xsl:call-template name="content-with-optional-href">
          <xsl:with-param name="content" select="label" />
        </xsl:call-template>
      </td>
      <td>
        <xsl:apply-templates select="d:department"/>
        <xsl:if test="d:department and d:storage"><br/></xsl:if>
        <xsl:apply-templates select="d:storage"/>
      </td>
      <td class="status">
        <xsl:if test="not($status[@service='presentation'])">
          <xsl:call-template name="status">
            <xsl:with-param name="value" select="0"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="$status[@service='presentation']"/>
      </td>
      <td class="status">
        <xsl:if test="not($status[@service='loan'])">
          <xsl:call-template name="status">
            <xsl:with-param name="value" select="0"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="$status[@service='loan']"/>
      </td>
      <td class="status">
        <xsl:if test="not($status[@service='interloan'])">
          <xsl:call-template name="status">
            <xsl:with-param name="value" select="0"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="$status[@service='interloan']"/>
      </td>
      <td class="status">
        <xsl:if test="not($status[@service='openaccess'])">
          <xsl:call-template name="status">
            <xsl:with-param name="value" select="0"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="$status[@service='openaccess']"/>
      </td>
      <td>
        <xsl:apply-templates select="d:message"/>
      </td>
    </tr>
  </xsl:template>


  <xsl:template name="summary">
    <xsl:variable name="items" select="d:document/d:item"/>
    <xsl:variable name="avail" select="$items/d:available"/>
    <xsl:variable name="unavail" select="$items/d:unavailable"/>
    <xsl:variable name="status" select="$avail|$unavail"/>
    <tr>
      <th colspan="2">
        <xsl:value-of select="count($items)"/>&#xA0;Exemplare,
        <xsl:value-of select="count(d:document)"/>&#xA0;Dokumente
      </th>
      <th align="right">Gesamtstatus</th>
      <td class="status">
        <xsl:call-template name="show-status">
          <xsl:with-param name="availability" select="$status[@service='presentation']"/>
        </xsl:call-template>
      </td><td class="status">
        <xsl:call-template name="show-status">
          <xsl:with-param name="availability" select="$status[@service='loan']"/>
        </xsl:call-template>
      </td><td class="status">
        <xsl:call-template name="show-status">
          <xsl:with-param name="availability" select="$status[@service='interloan']"/>
        </xsl:call-template>
      </td><td class="status">
        <xsl:call-template name="show-status">
          <xsl:with-param name="availability" select="$status[@service='openaccess']"/>
        </xsl:call-template>
      </td>
    </tr>
  </xsl:template>


  <xsl:template match="d:unavailable">
    <xsl:if test="d:limitation">
      <xsl:attribute name="class">limited</xsl:attribute>
    </xsl:if>
    <!--div-->
      <xsl:choose>
        <xsl:when test="@expected">
          <xsl:call-template name="status">
            <xsl:with-param name="value" select="3"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="status">
              <xsl:with-param name="value" select="2"/>
            </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="d:limitation">(eingeschränkt)</xsl:if>
      <xsl:if test="@queue">[<xsl:value-of select="@queue"/>]</xsl:if>
      <xsl:if test="@expected">
        <div class="time">
          <xsl:value-of select="@expected"/>
        </div>
      </xsl:if>
      <xsl:apply-templates select="d:limitation"/>
      <xsl:apply-templates select="d:message"/>
    <!--/div-->
  </xsl:template>

  <xsl:template match="d:available">
    <!--div-->
      <xsl:if test="d:limitation">
        <xsl:attribute name="class">limited</xsl:attribute>
      </xsl:if>
      <!-- TODO: only for known services -->
      <xsl:attribute name="class"><xsl:value-of select="@service"/></xsl:attribute>
      <xsl:call-template name="status">
        <xsl:with-param name="value" select="1"/>
      </xsl:call-template>
      <xsl:if test="d:limitation">(eingeschränkt)</xsl:if>
      <xsl:if test="@delay">
        <div class="time">
          <xsl:value-of select="@delay"/>
        </div>
      </xsl:if>
      <xsl:apply-templates select="d:limitation"/>
      <xsl:apply-templates select="d:message"/>
    <!--/div-->
  </xsl:template>

  <!-- show only the status without details -->
  <xsl:template name="show-status">
    <xsl:param name="availability"/>
    <xsl:call-template name="status">
      <xsl:with-param name="value">
        <xsl:choose>
          <xsl:when test="$availability[name()='d:available']">1</xsl:when>
          <xsl:when test="$availability[name()='d:unavailable'][@expected]">3</xsl:when>
          <xsl:when test="$availability[name()='d:unavailable']">2</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- print a message or an error. -->
  <xsl:template match="d:message">
    <xsl:if test="not($language) or @lang=$language or not(../d:message[@lang=$language])">
    <div>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="@errno and @errno != '0'">error</xsl:when>
          <xsl:otherwise>messsage</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="@errno and @errno != '0'">
        <span class="errno">[<xsl:value-of select="@errno"/>] </span></xsl:if>
      <xsl:value-of select="."/>
    </div>
    </xsl:if>
  </xsl:template>

  <!-- show a limitation -->
  <xsl:template match="d:limitation">
    <div class="limitation">
      <xsl:call-template name="content-with-optional-href"/>
    </div>
  </xsl:template>


  <!-- print information about an institution -->
  <xsl:template match="d:institution">
    <h2>Institution</h2>
    <p><xsl:call-template name="content-with-optional-href"/></p>
  </xsl:template>


  <!-- print information about a document -->
  <xsl:template match="d:document">
    <xsl:call-template name="content-with-optional-href">
      <xsl:with-param name="content"/>
    </xsl:call-template>
  </xsl:template>


  <!-- print information about a department -->
  <xsl:template match="d:department">
    <b>Abt: </b>
    <xsl:call-template name="content-with-optional-href"/>
  </xsl:template>


  <!-- print information about a storage -->
  <xsl:template match="d:storage">
    <b>Ort: </b>
    <xsl:call-template name="content-with-optional-href"/>
  </xsl:template>


  <!--
    Print the content of an element and optionally
    create a link (@href) and add an id (@id).
  -->
  <xsl:template name="content-with-optional-href">
    <xsl:param name="content" select="normalize-space(.)" />
    <xsl:param name="href" select="@href" />
    <xsl:param name="id" select="@id" />
    <xsl:param name="default">link</xsl:param>
    <xsl:choose>
      <xsl:when test="$content and $href">
        <a href="{$href}"><xsl:value-of select="$content"/></a>
      </xsl:when>
      <xsl:when test="$content">
        <xsl:value-of select="$content"/>
      </xsl:when>
      <xsl:when test="$id and $href">
        <a href="{$href}" class="id"><xsl:value-of select="$id"/></a>
      </xsl:when>
      <xsl:when test="$id and $href">
        <span class="id"><xsl:value-of select="$id"/></span>
      </xsl:when>
      <xsl:when test="$href">
        <a href="{@href}"><xsl:value-of select="$default"/></a>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="$content and $id">
      <xsl:text>&#xA0;[</xsl:text>
        <span class="id"><xsl:value-of select="$id"/></span>
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
