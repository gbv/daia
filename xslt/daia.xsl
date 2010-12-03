<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:d="http://ws.gbv.de/daia/"
><!--
    DAIA XSLT client

    Recent changes:

      2010-11-30: fixed msg display in documents and added grouping
      2010-04-26: refactored
      2008-11-06: adopted schema version 0.4
      2008-11-05: included parts of hebis
      2008-11-11: better support messages, css in a file
      2008-11-12: added limitation/fragment
      2008-11-24: special case of no items

    TODO:
      - i18n of messages
      - improve overall summary (might also be limited, fragmented)
  -->
  <xsl:import href="xmlverbatim.xsl"/>
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- URL of CSS file. You can use the <?cssurl $URL ?> processing instruction -->
  <xsl:param name="stylesheet">
    <xsl:choose>
      <xsl:when test="/processing-instruction('cssurl')">
        <xsl:value-of select="normalize-space(/processing-instruction('cssurl'))"/>
      </xsl:when>
      <xsl:otherwise>daia.css</xsl:otherwise>
    </xsl:choose>
  </xsl:param>

  <!-- prefered language to show messages in (TODO: test) -->
  <xsl:param name="language"></xsl:param>

  <!-- root -->
  <xsl:template match="/">
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Document Availability Information</title>
        <xsl:if test="$stylesheet">
          <link rel="stylesheet" type="text/css" href="{$stylesheet}"/>
        </xsl:if>
      </head>
      <body>
        <!-- preambel -->
        <h1>Document Availability Information</h1>
        <!-- content -->
        <xsl:apply-templates select="d:daia"/>
        <!-- source -->
        <h2 id='rawxml'>XML source of this document</h2>
        <xsl:apply-templates select="/" mode="xmlverb" />
        <!-- footer -->
        <div id="footer">
          See <a href="http://purl.org/NET/DAIA">http://purl.org/NET/DAIA</a>
          for more information about DAIA.
        </div>
      </body>
    </html>    
  </xsl:template>

  <xsl:template match="d:daia">
    <p> 
      This page displays a 
      <a href="http://purl.org/NET/DAIA">DAIA</a>
      response to report availability information of documents.
      <xsl:if test="@timestamp or @version">
        <xsl:text>The response </xsl:text>
        <xsl:if test="@timestamp">
          has timestamp 
          <b><xsl:value-of select="@timestamp"/></b>
          <xsl:if test="@version"> and it </xsl:if>
        </xsl:if>
        <xsl:if test="@version">
          is encoded in
          DAIA/XML <b>version <xsl:value-of select="@version"/></b>
        </xsl:if>
        <xsl:text>.</xsl:text>
      </xsl:if>
      The full XML source is <a href="#rawxml">shown below</a>.
      You can also get the DAIA response in DAIA/JSON and
      in DAIA/RDF.
    </p>

    <!-- content -->
    <xsl:apply-templates select="d:message"/>
    <xsl:apply-templates select="d:institution"/>

    <!-- show documents -->
    <xsl:variable name="docs" select="d:document"/>

    <xsl:if test="$docs">
      <xsl:choose>
        <xsl:when test="count($docs) = 1">
          <h2>Document</h2>
          <xsl:apply-templates select="d:document"/>
        </xsl:when>
        <xsl:otherwise>
          <h2>Documents (<xsl:value-of select="count($docs)"/>)</h2>
          <xsl:for-each select="d:document">
            <div class='document'>
              <h3>Document</h3>
              <xsl:apply-templates select="."/>
            </div>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- show items and availability -->
    <xsl:variable name="items" select="d:document/d:item"/>

    <xsl:if test="$items">
      <h2>Availability</h2>
      <p>
        <table>
          <tr>
            <th><div class="document-icon">document</div></th>
            <th><div class="location-icon">location</div></th>
            <th><div class="item-icon">item</div></th>
            <th><div class="loan-icon">loan</div></th>
            <th><div class="presentation-icon">presentation</div></th>
            <th><div class="openaccess-icon">open access</div></th>
            <th><div class="interloan-icon">interloan</div></th>
            <xsl:if test="$items[d:message]">
              <th>message</th>
            </xsl:if>
          </tr>
          <xsl:apply-templates select="d:document" mode="itemtable"/>
        </table>
      </p>

      <!-- TODO: fix this -->
      <!--xsl:if test="count($items) &gt; 1">
        <h3>Summary</h3>
        <p><xsl:call-template name="summary"/></p>
      </xsl:if-->

    </xsl:if>
  </xsl:template>

  <xsl:template match="d:document" mode="itemtable">
    <xsl:variable name="items_without_depid" select="d:item[not(d:department/@id)]"/>
    <xsl:for-each select="$items_without_depid">
      <xsl:sort select="d:label"/>
      <xsl:sort select="d:storage"/>
      <xsl:apply-templates select=".">
        <xsl:with-param name="item_position" select="1"/>
        <xsl:with-param name="department_position" select="position()"/>
      </xsl:apply-templates>
    </xsl:for-each>
    

    <xsl:for-each select="d:item[d:department/@id and not( d:department/@id = preceding-sibling::d:item/d:department/@id )]">
      <xsl:sort select="d:department/@id" order="descending"/>
      <xsl:variable name="item_position">
        <xsl:if test="count($items_without_depid)"><xsl:value-of select="position()+1"/></xsl:if>
        <xsl:if test="not(count($items_without_depid))"><xsl:value-of select="position()"/></xsl:if>
      </xsl:variable>
      <xsl:variable name="depid" select="d:department/@id"/>
      <xsl:for-each select="../d:item[ d:department/@id = $depid ]">
	<xsl:sort select="d:department"/>
	<xsl:sort select="d:label"/>
	<xsl:sort select="d:storage"/>
        <xsl:apply-templates select=".">
          <xsl:with-param name="item_position" select="$item_position"/>
          <xsl:with-param name="department_position" select="position()"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="d:document">
    <p>
      <xsl:if test="d:item">
        <xsl:text>The response contains information about </xsl:text>
        <b>
          <xsl:value-of select="count(d:item)"/>
          <xsl:text> item</xsl:text>
          <xsl:if test="count(d:item) &gt; 1">s</xsl:if>
        </b>
        <xsl:text> of document </xsl:text>
        <xsl:apply-templates select="." mode="about"/>
        <xsl:text>.</xsl:text>
      </xsl:if>
    </p>
    <xsl:if test="not(d:item)">
      <xsl:apply-templates select="d:message"/>
    </xsl:if>
  </xsl:template>

  <!-- show the general status (available|unavailable|cur-unavail) -->
  <xsl:template name="status">
    <xsl:param name="status"/>
    <xsl:param name="href" select="@href"/>
    <xsl:variable name="element">
      <xsl:choose>
        <xsl:when test="@href">a</xsl:when>
        <xsl:otherwise>span</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$element}">
      <xsl:attribute name="class">status</xsl:attribute>
      <xsl:if test="$href">
        <xsl:attribute name="href"><xsl:value-of select="$href"/></xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$status = 'available'">
          <xsl:attribute name="class">available</xsl:attribute>
          <xsl:text>available</xsl:text>
        </xsl:when>
        <xsl:when test="$status = 'unavailable'">
          <xsl:attribute name="class">unavailable</xsl:attribute>
          <xsl:text>unavailable</xsl:text>
        </xsl:when>
        <xsl:when test="$status = 'cur-unavail'">
          <xsl:attribute name="class">cur-unavail</xsl:attribute>
          <xsl:text>unavailable</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <!-- show a row in the availability table -->
  <xsl:template match="d:item">
    <xsl:param name="item_position"/>
    <xsl:param name="department_position"/> 
    <xsl:variable name="status" select="d:available|d:unavailable"/>
    <tr>
      <xsl:if test="$department_position = 1">
        <xsl:attribute name="class">newdepartment</xsl:attribute>
        <xsl:if test="$item_position = 1">
          <td rowspan="{count(../d:item)}" valign="top">
            <xsl:apply-templates select="parent::d:document" mode="about"/>
            <xsl:apply-templates select="parent::d:document/d:message"/>        
          </td>
        </xsl:if>
      </xsl:if>
      <td>
        <!--xsl:value-of select="$item_position"/>_
        <xsl:value-of select="$department_position"/-->
        <xsl:apply-templates select="d:department"/>
        <xsl:apply-templates select="d:storage"/>
      </td>
      <td>
        <xsl:if test="@fragment='true' or @fragment='1'">
          <span class='limitation'>only partial!</span>
        </xsl:if>
        <div>
          <xsl:if test="d:label">
            <xsl:attribute name="title">label</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="content-with-optional-href">
            <xsl:with-param name="content" select="d:label" />
          </xsl:call-template>
        </div>
      </td>
      <td title="loan">
        <xsl:apply-templates select="$status[@service='loan']"/>
      </td>
      <td title="presentation">
        <xsl:apply-templates select="$status[@service='presentation']"/>
      </td>
      <td title="openaccess">
        <xsl:apply-templates select="$status[@service='openaccess']"/>
      </td>
      <td title="interloan">
        <xsl:apply-templates select="$status[@service='interloan']"/>
      </td>
      <!-- TODO: show additional services -->
      <xsl:if test="//d:item[d:message]">
        <td>
          <xsl:apply-templates select="d:message"/>
        </td>
      </xsl:if>
    </tr>
  </xsl:template>

  <!-- TODO: fix this -->
  <xsl:template name="summary">
    <xsl:variable name="items" select="d:document/d:item"/>
    <xsl:variable name="avail" select="$items/d:available"/>
    <xsl:variable name="unavail" select="$items/d:unavailable"/>
    <xsl:variable name="status" select="$avail|$unavail"/>
    <table>
      <tr>
        <th><div class="presentation-icon"/></th>
        <th><div class="loan-icon"/></th>
        <th><div class="openaccess-icon"/></th>
        <th><div class="interloan-icon"/></th>
      </tr>
      <tr>
        <td>
          <xsl:call-template name="show-status">
            <xsl:with-param name="availability" select="$status[@service='presentation']"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="show-status">
            <xsl:with-param name="availability" select="$status[@service='loan']"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="show-status">
            <xsl:with-param name="availability" select="$status[@service='interloan']"/>
          </xsl:call-template>
        </td>
        <td>
          <xsl:call-template name="show-status">
            <xsl:with-param name="availability" select="$status[@service='openaccess']"/>
          </xsl:call-template>
        </td>
      </tr>
    </table>
  </xsl:template>

  <!-- show one available element -->
  <xsl:template match="d:available">
    <!--div-->
      <xsl:call-template name="status">
        <xsl:with-param name="status" select="'available'"/>
      </xsl:call-template>
      <xsl:if test="@delay">
        <div class="time">
          <xsl:value-of select="@delay"/>
        </div>
      </xsl:if>
      <xsl:apply-templates select="d:limitation"/>
      <xsl:apply-templates select="d:message"/>
    <!--/div-->
  </xsl:template>

  <!-- show one unavailable element -->
  <xsl:template match="d:unavailable">
    <!--div-->
      <xsl:choose>
        <xsl:when test="@expected">
          <xsl:call-template name="status">
            <xsl:with-param name="status" select="'cur-unavail'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="status">
              <xsl:with-param name="status" select="'unavailable'"/>
            </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:apply-templates select="@queue"/> 

      <xsl:if test="@expected">
        <div class="date" title="expected">
          <xsl:value-of select="@expected"/>
        </div>
      </xsl:if>
      <xsl:apply-templates select="d:limitation"/>
      <xsl:apply-templates select="d:message"/>
    <!--/div-->
  </xsl:template>


  <xsl:template match="@queue">
    <span class="queue">
      <xsl:value-of select="."/> 
      <xsl:choose>
        <xsl:when test=". &lt; 1"> person waiting</xsl:when>
        <xsl:when test=". &gt;= 1"> people waiting</xsl:when>
      </xsl:choose>      
    </span>
  </xsl:template>


  <!-- show only the status without details -->
  <xsl:template name="show-status">
    <xsl:param name="availability"/>
    <xsl:variable name="status">
      <xsl:choose>
        <xsl:when test="$availability[name()='d:available']">available</xsl:when>
        <xsl:when test="$availability[name()='d:unavailable'][@expected]">cur-unavail</xsl:when>
        <xsl:when test="$availability[name()='d:unavailable']">unavailable</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$status">
      <xsl:call-template name="status">
        <xsl:with-param name="value" select="$status"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- print a message or an error -->
  <xsl:template match="d:message">
    <xsl:if test="not($language) or @lang=$language or not(../d:message[@lang=$language])">
    <div title="message">
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="@errno and @errno != '0'">error</xsl:when>
          <xsl:otherwise>messsage</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="@errno and @errno != '0'">
        <span class="errno">
          <xsl:value-of select="@errno"/> 
          <xsl:if test="normalize-space(.)">: </xsl:if>
        </span>
      </xsl:if>
      <xsl:value-of select="."/>
    </div>
    </xsl:if>
  </xsl:template>

  <!-- ignore empty messages -->
  <xsl:template match="d:message[not(@errno or normalize-space(.))]"/>

  <!-- show a limitation -->
  <xsl:template match="d:limitation">
    <div class="limitation" title="limitation">
      <xsl:call-template name="content-with-optional-href">
        <xsl:with-param name="default">limitation</xsl:with-param>
      </xsl:call-template>
    </div>
  </xsl:template>


  <!-- print information about an institution -->
  <xsl:template match="d:institution">
    <h2>Institution</h2>
    <p><xsl:call-template name="content-with-optional-href"/></p>
  </xsl:template>


  <!-- print information about a document -->
  <xsl:template match="d:document" mode="about">
    <xsl:call-template name="content-with-optional-href">
      <xsl:with-param name="content"/>
      <!-- @id is required -->
      <xsl:with-param name="id">
        <xsl:if test="normalize-space(@id)">
          <xsl:value-of select="@id"/>
        </xsl:if>
        <xsl:if test="not(normalize-space(@id))">?</xsl:if>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>


  <!-- print information about a department -->
  <xsl:template match="d:department">
    <div class='department' title="department">
      <xsl:call-template name="content-with-optional-href"/>
    </div>
  </xsl:template>


  <!-- print information about a storage -->
  <xsl:template match="d:storage">
    <div class='storage' title="storage">
      <xsl:call-template name="content-with-optional-href"/>
    </div>
  </xsl:template>


  <!--
    Print the content of an element and optionally
    create a link (@href) and add an id (@id).
  -->
  <xsl:template name="content-with-optional-href">
    <xsl:param name="content" select="normalize-space(.)" />
    <xsl:param name="href" select="@href" />
    <xsl:param name="default"/>
    <xsl:param name="id" select="normalize-space(@id)" />

    <xsl:variable name="nid" select="normalize-space($id)" />

    <xsl:choose>
      <xsl:when test="$content and $href">
        <a href="{$href}"><xsl:value-of select="$content"/></a>
      </xsl:when>
      <xsl:when test="$content">
        <span><xsl:value-of select="$content"/></span>
      </xsl:when>
      <xsl:when test="$nid and $href">
        <a href="{$href}" class="id"><xsl:call-template name="id"/></a>
      </xsl:when>
      <xsl:when test="$nid">
        <span class="id"><xsl:call-template name="id"/></span>
      </xsl:when>
      <xsl:when test="$href">
        <!-- TODO: use other default content instead of $href -->
        <a href="{$href}"><xsl:value-of select="$href"/></a>
      </xsl:when>
      <xsl:otherwise>
        <span><xsl:value-of select="$default"/></span>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$content and $nid">
      <xsl:text>&#xA;</xsl:text>
        <div class="id"><xsl:call-template name="id"/></div>
    </xsl:if>
  </xsl:template>

  <!-- Show @id attribute or '?!' for missing id  -->
  <xsl:template name="id">
    <xsl:choose>
      <!-- minimal URI check -->
      <xsl:when test="substring-before(@id,':')">
        <xsl:value-of select="@id"/>
      </xsl:when>
      <xsl:when test="normalize-space(@id)">
        <span class='invalid-id'><xsl:value-of select="@id"/></span>
      </xsl:when>
      <xsl:otherwise>
        <span class='invalid-id'>?!</span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
