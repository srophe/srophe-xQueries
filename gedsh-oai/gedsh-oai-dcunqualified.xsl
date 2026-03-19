<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output method='xml'/>
    
    <xsl:template match="/">
        
      <record xmlns="http://www.openarchives.org/OAI/2.0/" >
        <header>
            <identifier>
                <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:idno[@type='URI']"/>
            </identifier>
            <datestamp>
                <xsl:value-of select="substring(normalize-space(/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date), 1, 10)"/>
            </datestamp>
            <!-- Set Spec -->
        </header>
        <metadata>
            <oai_dc:dc
                xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" 
                xmlns:dc="http://purl.org/dc/elements/1.1/" 
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ 
                http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
                <dc:title>
                    <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title"/>
                </dc:title>
                <xsl:for-each select="/tei:TEI/tei:text/tei:body/tei:div/tei:byline/tei:persName">
                    <dc:creator>
                            <xsl:value-of select="normalize-space(.)"/>
                    </dc:creator>
                </xsl:for-each>
                <dc:description>
                    <xsl:value-of select="normalize-space(/tei:TEI/tei:text/tei:body/tei:div/tei:ab/tei:note[@type='abstract'])"/>
                </dc:description>
                <dc:identifier>
                    <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:idno[@type='URI']"/>
                </dc:identifier>
                <dc:date>
                    <xsl:value-of select="normalize-space(/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:date)"/>
                </dc:date>
                <xsl:for-each select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:authority">
                    <dc:publisher>
                        <xsl:value-of select="normalize-space(.)"/>
                    </dc:publisher>
                </xsl:for-each>
                <dc:rights>
                    <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:p"/>. <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/tei:p"/>
                </dc:rights>
                <dc:rights>
                    <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:licence/@target"/>
                </dc:rights>
                <dc:source>
                    <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:idno[@type='syriaca-bibl']"/>
                </dc:source>
                <!-- dc:source for formatted bibl string? -->
                <xsl:if test="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:idno[@type='subject']">
                    <dc:subject>
                        <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:idno[@type='subject']"/>
                    </dc:subject>
                </xsl:if>
                <dc:subject>
                    <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/tei:head"/>
                </dc:subject>
                <xsl:if test="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:note[@type='type']/text() = 'place'">
                    <xsl:if test="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:idno[@type='subject']">
                        <dc:coverage>
                            <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/tei:ab[@type='idnos']/tei:idno[@type='subject']"/>
                        </dc:coverage>
                    </xsl:if>
                    <dc:coverage>
                        <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/tei:head"/>
                    </dc:coverage>
                </xsl:if>
                <dc:type>Text</dc:type>
                <dc:language>en</dc:language>
                <dc:format>application/tei+xml</dc:format>
                <!-- 
                - dc:contributor (use the respStmts? use the editors?)
                - dc:relation ?? use cases?
                -->
            </oai_dc:dc>
        </metadata>
     </record>
    </xsl:template>
</xsl:stylesheet>