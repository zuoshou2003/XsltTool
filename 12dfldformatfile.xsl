<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"    
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt">

<!-- (c) 2016, Trimble Navigation Limited. All rights reserved.                                -->
<!-- Permission is hereby granted to use, copy, modify, or distribute this style sheet for any -->
<!-- purpose and without fee, provided that the above copyright notice appears in all copies   -->
<!-- and that both the copyright notice and the limited warranty and restricted rights notice  -->
<!-- below appear in all supporting documentation.                                             -->

<!-- TRIMBLE NAVIGATION LIMITED PROVIDES THIS STYLE SHEET "AS IS" AND WITH ALL FAULTS.         -->
<!-- TRIMBLE NAVIGATION LIMITED SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTY OF MERCHANTABILITY -->
<!-- OR FITNESS FOR A PARTICULAR USE. TRIMBLE NAVIGATION LIMITED DOES NOT WARRANT THAT THE     -->
<!-- OPERATION OF THIS STYLE SHEET WILL BE UNINTERRUPTED OR ERROR FREE.                        -->

<xsl:output method="text" omit-xml-declaration="yes" encoding="ISO-8859-1"/>

<!-- Set the numeric display details i.e. decimal point, thousands separator etc -->
<xsl:variable name="DecPt" select="'.'"/>    <!-- Change as appropriate for US/European -->
<xsl:variable name="GroupSep" select="','"/> <!-- Change as appropriate for US/European -->
<!-- Also change decimal-separator & grouping-separator in decimal-format below 
     as appropriate for US/European output -->
<xsl:decimal-format name="Standard" 
                    decimal-separator="."
                    grouping-separator=","
                    infinity="Infinity"
                    minus-sign="-"
                    NaN=""
                    percent="%"
                    per-mille="&#2030;"
                    zero-digit="0" 
                    digit="#" 
                    pattern-separator=";" />

<xsl:variable name="DecPl0" select="'#0'"/>
<xsl:variable name="DecPl1" select="concat('#0', $DecPt, '0')"/>
<xsl:variable name="DecPl2" select="concat('#0', $DecPt, '00')"/>
<xsl:variable name="DecPl3" select="concat('#0', $DecPt, '000')"/>
<xsl:variable name="DecPl4" select="concat('#0', $DecPt, '0000')"/>
<xsl:variable name="DecPl5" select="concat('#0', $DecPt, '00000')"/>
<xsl:variable name="DecPl6" select="concat('#0', $DecPt, '000000')"/>
<xsl:variable name="DecPl8" select="concat('#0', $DecPt, '00000000')"/>

<xsl:variable name="fileExt" select="'fld'"/>

<!-- User variable definitions - Appropriate fields are displayed on the       -->
<!-- Survey Controller screen to allow the user to enter specific values       -->
<!-- which can then be used within the style sheet definition to control the   -->
<!-- output data.                                                              -->
<!--                                                                           -->
<!-- All user variables must be identified by a variable element definition    -->
<!-- named starting with 'userField' (case sensitive) followed by one or more  -->
<!-- characters uniquely identifying the user variable definition.             -->
<!--                                                                           -->
<!-- The text within the 'select' field for the user variable description      -->
<!-- references the actual user variable and uses the '|' character to         -->
<!-- separate the definition details into separate fields as follows:          -->
<!-- For all user variables the first field must be the name of the user       -->
<!-- variable itself (this is case sensitive) and the second field is the      -->
<!-- prompt that will appear on the Survey Controller screen.                  -->
<!-- The third field defines the variable type - there are four possible       -->
<!-- variable types: Double, Integer, String and StringMenu.  These variable   -->
<!-- type references are not case sensitive.                                   -->
<!-- The fields that follow the variable type change according to the type of  -->
<!-- variable as follow:                                                       -->
<!-- Double and Integer: Fourth field = optional minimum value                 -->
<!--                     Fifth field = optional maximum value                  -->
<!--   These minimum and maximum values are used by the Survey Controller for  -->
<!--   entry validation.                                                       -->
<!-- String: No further fields are needed or used.                             -->
<!-- StringMenu: Fourth field = number of menu items                           -->
<!--             Remaining fields are the actual menu items - the number of    -->
<!--             items provided must equal the specified number of menu items. -->
<!--                                                                           -->
<!-- The style sheet must also define the variable itself, named according to  -->
<!-- the definition.  The value within the 'select' field will be displayed in -->
<!-- the Survey Controller as the default value for the item.                  -->
<xsl:variable name="userField1" select="'copyAlphaNames|Assign alpha-numeric names as Named points|StringMenu|2|Yes|No'"/>
<xsl:variable name="copyAlphaNames" select="'No'"/>  <!-- Variable to control whether or not alpha-numeric names are to be copied to the 12d 'Named point' field -->
<xsl:variable name="userField2" select="'codePtTextSep|Character separating point code and point text|stringMenu|2|Space char|*'"/>
<xsl:variable name="codePtTextSep" select="'Space char'"/>
<xsl:variable name="userField3" select="'includeGNSSQCAsAttributes|Include GNSS QC details as point attributes|stringMenu|2|Yes|No'"/>
<xsl:variable name="includeGNSSQCAsAttributes" select="'No'"/>
<xsl:variable name="userField4" select="'includeDateTimeAsAttributes|Include date and time as point attributes|stringMenu|2|Yes|No'"/>
<xsl:variable name="includeDateTimeAsAttributes" select="'No'"/>
<xsl:variable name="userField5" select="'includeTargetInstDetailsAsAttributes|Include target and instrument details as point attributes|stringMenu|2|Yes|No'"/>
<xsl:variable name="includeTargetInstDetailsAsAttributes" select="'No'"/>
<xsl:variable name="userField6" select="'includeQCDetails|Output QC details to file as comments|stringMenu|2|Yes|No'"/>
<xsl:variable name="includeQCDetails" select="'No'"/>

<xsl:variable name="codePtTextSeparator">
  <xsl:choose>
    <xsl:when test="$codePtTextSep = 'Space char'"><xsl:value-of select="' '"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="$codePtTextSep"/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="startArcCode">S</xsl:variable>
<xsl:variable name="endArcCode">E</xsl:variable>
<xsl:variable name="closeCode">C</xsl:variable>
<xsl:variable name="removeHtCode">RH</xsl:variable>

<!-- Define key to speed up search for target ht details -->
<xsl:key name="tgtID-search" match="/JOBFile/FieldBook/TargetRecord" use="@ID"/>
<xsl:key name="stnID-search" match="/JOBFile/FieldBook/StationRecord" use="@ID"/>
<xsl:key name="atmosID-search" match="/JOBFile/FieldBook/AtmosphereRecord" use="@ID"/>
<xsl:key name="bsID-search" match="/JOBFile/FieldBook/BackBearingRecord" use="@ID"/>
<xsl:key name="ptFromStn-search" match="/JOBFile/FieldBook/PointRecord" use="StationID"/>
<xsl:key name="instID-search" match="/JOBFile/FieldBook/InstrumentRecord" use="@ID"/>

<!-- **************************************************************** -->
<!-- Set global variables from the Environment section of JobXML file -->
<!-- **************************************************************** -->
<xsl:variable name="DistUnit"   select="/JOBFile/Environment/DisplaySettings/DistanceUnits" />
<xsl:variable name="AngleUnit"  select="/JOBFile/Environment/DisplaySettings/AngleUnits" />
<xsl:variable name="CoordOrder" select="/JOBFile/Environment/DisplaySettings/CoordinateOrder" />
<xsl:variable name="TempUnit"   select="/JOBFile/Environment/DisplaySettings/TemperatureUnits" />
<xsl:variable name="PressUnit"  select="/JOBFile/Environment/DisplaySettings/PressureUnits" />

<!-- Setup conversion factor for coordinate and distance values -->
<!-- Dist/coord values in JobXML file are always in metres -->
<xsl:variable name="DistConvFactor">
  <xsl:choose>
    <xsl:when test="$DistUnit='Metres'">1.0</xsl:when>
    <xsl:when test="$DistUnit='InternationalFeet'">3.280839895</xsl:when>
    <xsl:when test="$DistUnit='USSurveyFeet'">3.2808333333357</xsl:when>
    <xsl:otherwise>1.0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- Setup conversion factor for angular values -->
<!-- Angular values in JobXML file are always in decimal degrees -->
<xsl:variable name="AngleConvFactor">
  <xsl:choose>
    <xsl:when test="$AngleUnit='DMSDegrees'">1.0</xsl:when>
    <xsl:when test="$AngleUnit='Gons'">1.111111111111</xsl:when>
    <xsl:when test="$AngleUnit='Mils'">17.77777777777</xsl:when>
    <xsl:otherwise>1.0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- Setup boolean variable for coordinate order -->
<xsl:variable name="NECoords">
  <xsl:choose>
    <xsl:when test="$CoordOrder='North-East-Elevation'">true</xsl:when>
    <xsl:when test="$CoordOrder='X-Y-Z'">true</xsl:when>
    <xsl:otherwise>false</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- Setup conversion factor for pressure values -->
<!-- Pressure values in JobXML file are always in millibars (hPa) -->
<xsl:variable name="PressConvFactor">
  <xsl:choose>
    <xsl:when test="$PressUnit='MilliBar'">1.0</xsl:when>
    <xsl:when test="$PressUnit='InchHg'">0.029529921</xsl:when>
    <xsl:when test="$PressUnit='mmHg'">0.75006</xsl:when>
    <xsl:otherwise>1.0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>


<!-- **************************************************************** -->
<!-- ************************** Main Loop *************************** -->
<!-- **************************************************************** -->
<xsl:template match="/" >

  <xsl:text>{Version 6.0}</xsl:text>
  <xsl:call-template name="NewLine"/>

  <!-- Output a 'units' record to indicate the fixed units to be used in the file. -->
  <!-- We will simply use the units used to store data in the JobXML file.         -->
  <xsl:text>100&#09;&#09;degrees&#09;metres&#09;millibars&#09;celsius</xsl:text>
  <xsl:call-template name="NewLine"/>
  
  <xsl:text>//</xsl:text>
  <xsl:call-template name="NewLine"/>

  <!-- Select FieldBook node to process -->
  <xsl:apply-templates select="JOBFile/FieldBook"/>

</xsl:template>


<!-- **************************************************************** -->
<!-- ****************** FieldBook Node Processing ******************* -->
<!-- **************************************************************** -->
<xsl:template match="FieldBook">

  <!-- Output the required data -->
  <xsl:apply-templates select="*[((name() = 'PointRecord') and (Deleted = 'false') and (Classification != 'MTA')) or
                                 (name() = 'StationRecord') or (name() = 'TargetRecord') or
                                 (name() = 'NoteRecord')]"/>

  <!-- Output QC details if required -->
  <xsl:if test="$includeQCDetails = 'Yes'">
    <xsl:variable name="SSeriesInst" select="count(/JOBFile/FieldBook/InstrumentRecord[(Type = 'TrimbleSSeries') or (Type = 'TrimbleVXandSSeries')])"/>
    <xsl:variable name="RTKPoints" select="count(/JOBFile/FieldBook/PointRecord[Precision])"/>
    <xsl:if test="($SSeriesInst &gt; 0) or ($RTKPoints &gt; 0)">
      <xsl:call-template name="OutputQCDetails">
        <xsl:with-param name="instRecCount" select="$SSeriesInst"/>
        <xsl:with-param name="RTKPtCount" select="$RTKPoints"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:if>

</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* PointRecord Processing ********************* -->
<!-- **************************************************************** -->
<xsl:template match="StationRecord">

  <xsl:variable name="recID" select="@ID"/>
  <xsl:variable name="obsCount" select="count(following-sibling::PointRecord[(StationID = $recID) and (Deleted = 'false')])"/>
  
  <xsl:if test="$obsCount != 0">  <!-- There is at least 1 non-deleted observation from this station setup -->
    <!-- Output the station coordinates prior to the station record (Op code 3) -->
    <xsl:variable name="stnName" select="StationName"/>
    <xsl:for-each select="/JOBFile/Reductions/Point[Name = $stnName]">
      <xsl:variable name="ptRec">
        <xsl:element name="PointRecord">
          <xsl:copy-of select="Name"/>
          <xsl:copy-of select="Code"/>
          <xsl:copy-of select="Grid"/>
        </xsl:element>
      </xsl:variable>
      <xsl:apply-templates select="$ptRec/PointRecord"/>
    </xsl:for-each>

    <xsl:text>03&#09;&#09;</xsl:text>  <!-- Op code (new instrument point) and 2 tabs -->

    <!-- Get the point details for the station point from the Reductions section -->
    <xsl:for-each select="/JOBFile/Reductions/Point[Name = $stnName]">
      <xsl:variable name="pointDesc">
        <xsl:call-template name="PointDescriptionOutput">
          <xsl:with-param name="skipStringOutput">true</xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="$pointDesc/ptDesc"/>
    </xsl:for-each>
    <!-- Output the instrument height - default to 0 if null -->
    <xsl:variable name="instHt">
      <xsl:choose>
        <xsl:when test="string(number(TheodoliteHeight)) != 'NaN'">
          <xsl:value-of select="TheodoliteHeight"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="format-number($instHt, $DecPl8, 'Standard')"/>
    <xsl:call-template name="NewLine"/>

    <!-- It seems most logical to record the instrument details as attributes of the station. -->
    <!-- No idea whether 12d will handle this or not however, as it may only allow attributes -->
    <!-- to be associated with points and observations.                                       -->
    <xsl:if test="$includeTargetInstDetailsAsAttributes = 'Yes'">
      <!-- Fetch and output the instrument details -->
      <xsl:for-each select="key('instID-search', InstrumentID)">
        <xsl:variable name="instType">
          <xsl:call-template name="InstrumentType">
            <xsl:with-param name="type" select="Type"/>
          </xsl:call-template>
        </xsl:variable>

        <!-- Output the instrument type and model -->
        <xsl:text>73&#09;&#09;</xsl:text>  <!-- Op code (text attribute) and 2 tabs -->
        <xsl:text>Instrument</xsl:text>
        <xsl:text>&#09;</xsl:text>
        <xsl:value-of select="$instType"/>
        <xsl:value-of select="' '"/>
        <xsl:value-of select="Model"/>
        <xsl:call-template name="NewLine"/>

        <xsl:if test="Serial != ''">
          <xsl:text>73&#09;&#09;</xsl:text>  <!-- Op code (text attribute) and 2 tabs -->
          <xsl:text>Serial Number</xsl:text>
          <xsl:text>&#09;</xsl:text>
          <xsl:value-of select="Serial"/>
          <xsl:call-template name="NewLine"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>

    <!-- Output the station scale factor if not equal to 1 -->
    <xsl:if test="ScaleFactor != 1">
      <xsl:text>09&#09;&#09;</xsl:text>  <!-- Op code (scale factor for subsequent distances) and 2 tabs -->
      <xsl:value-of select="format-number(ScaleFactor, $DecPl8, 'Standard')"/>
      <xsl:call-template name="NewLine"/>
    </xsl:if>
  </xsl:if>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* PointRecord Processing ********************* -->
<!-- **************************************************************** -->
<xsl:template match="PointRecord">

  <xsl:choose>
    <xsl:when test="Grid">
      <!-- Output the point grid coordinates -->
      <xsl:text>02&#09;&#09;</xsl:text>  <!-- Op code (directly entered coordinate) and 2 tabs -->
      <xsl:variable name="pointDesc">
        <xsl:call-template name="PointDescriptionOutput">
          <xsl:with-param name="skipStringOutput">true</xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="$pointDesc/ptDesc"/>
      <!-- Output the east value -->
      <xsl:value-of select="format-number(Grid/East, $DecPl8, 'Standard')"/>
      <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
      <!-- Output the north value -->
      <xsl:value-of select="format-number(Grid/North, $DecPl8, 'Standard')"/>
      <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
      <!-- Output the elevation value -->
      <xsl:value-of select="format-number(Grid/Elevation, $DecPl8, 'Standard')"/>
      <xsl:call-template name="NewLine"/>

      <xsl:if test="$pointDesc/controlCode != ''">
        <xsl:call-template name="WriteControlCode">
          <xsl:with-param name="controlCode" select="$pointDesc/controlCode"/>
          <xsl:with-param name="ptDesc" select="$pointDesc/ptDesc"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:when>
    
    <xsl:when test="ECEFDeltas or ECEF">  <!-- RTK or VRS position -->
      <!-- Check if there are any averaged positions for this point and if so fetch  -->
      <!-- the appropriate PointRecord containing the averaged coordinates and write -->
      <!-- out the ComputedGrid coordinates from it, otherwise write out the         -->
      <!-- ComputedGrid coordinates from the current PointRecord.                    -->
      <xsl:variable name="ptName" select="Name"/>
      <xsl:variable name="ptCoords">
        <xsl:choose>
          <xsl:when test="count(/JOBFile/FieldBook/PointRecord[(Name = $ptName) and (Classification = 'Averaged') and (Deleted = 'false')]) != 0">
            <xsl:for-each select="/JOBFile/FieldBook/PointRecord[(Name = $ptName) and (Classification = 'Averaged') and (Deleted = 'false')][last()]">
              <north>
                <xsl:value-of select="ComputedGrid/North"/>
              </north>
              <east>
                <xsl:value-of select="ComputedGrid/East"/>
              </east>
              <elev>
                <xsl:value-of select="ComputedGrid/Elevation"/>
              </elev>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <north>
              <xsl:value-of select="ComputedGrid/North"/>
            </north>
            <east>
              <xsl:value-of select="ComputedGrid/East"/>
            </east>
            <elev>
              <xsl:value-of select="ComputedGrid/Elevation"/>
            </elev>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:text>02&#09;&#09;</xsl:text>  <!-- Op code (directly entered coordinate) and 2 tabs -->
      <xsl:variable name="pointDesc">
        <xsl:call-template name="PointDescriptionOutput"/>
      </xsl:variable>
      <xsl:value-of select="$pointDesc/ptDesc"/>
      <!-- Output the east value -->
      <xsl:value-of select="format-number($ptCoords/east, $DecPl8, 'Standard')"/>
      <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
      <!-- Output the north value -->
      <xsl:value-of select="format-number($ptCoords/north, $DecPl8, 'Standard')"/>
      <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
      <!-- Output the elevation value -->
      <xsl:value-of select="format-number($ptCoords/elev, $DecPl8, 'Standard')"/>
      <xsl:call-template name="NewLine"/>

      <xsl:if test="$pointDesc/controlCode != ''">
        <xsl:call-template name="WriteControlCode">
          <xsl:with-param name="controlCode" select="$pointDesc/controlCode"/>
          <xsl:with-param name="ptDesc" select="$pointDesc/ptDesc"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:when>

    <xsl:when test="Circle">
      <!-- Only want to output the first backsight observation as a backsight -->
      <xsl:variable name="firstBacksight">
        <xsl:if test="Classification = 'BackSight'">
          <xsl:variable name="stnID" select="StationID"/>
          <xsl:if test="count(preceding-sibling::PointRecord[(StationID = $stnID) and (Classification = 'BackSight')]) = 0">true</xsl:if>
        </xsl:if>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="(Classification = 'BackSight') and ($firstBacksight = 'true')">
          <xsl:text>04&#09;&#09;</xsl:text>  <!-- Op code (measurement to backsight) and 2 tab -->
          <xsl:variable name="pointDesc">
            <xsl:call-template name="PointDescriptionOutput">
              <xsl:with-param name="backsightObs">true</xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$pointDesc/ptDesc"/>
          <xsl:call-template name="CircleObservationOutput">
            <xsl:with-param name="skipNewLine">true</xsl:with-param>
          </xsl:call-template>
          <!-- Output the azimuth to the backsight - if there are no coordinates available for the backsight -->
          <xsl:variable name="ptName" select="Name"/>
          <xsl:if test="(string(number(/JOBFile/Reductions/Point[Name = $ptName]/Grid/North)) = 'NaN') or
                        (string(number(/JOBFile/Reductions/Point[Name = $ptName]/Grid/East))  = 'NaN')">
            <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
            <xsl:variable name="bsAzimuth">
              <xsl:call-template name="GetBacksightAzimuth"/>
            </xsl:variable>
            <xsl:value-of select="format-number($bsAzimuth, $DecPl8, 'Standard')"/>
          </xsl:if>
          <xsl:call-template name="NewLine"/>

          <xsl:if test="$pointDesc/controlCode != ''">
            <xsl:call-template name="WriteControlCode">
              <xsl:with-param name="controlCode" select="$pointDesc/controlCode"/>
              <xsl:with-param name="ptDesc" select="$pointDesc/ptDesc"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:when>
        
        <xsl:when test="Classification = 'Check'">
          <xsl:text>06&#09;&#09;</xsl:text>  <!-- Op code (check measurement) and 2 tabs -->
          <xsl:call-template name="PointDescriptionOutput"/>
          <xsl:call-template name="CircleObservationOutput"/>
        </xsl:when>

        <xsl:otherwise>
          <xsl:text>07&#09;&#09;</xsl:text>  <!-- Op code (measurement) and 2 tabs -->
          <xsl:call-template name="PointDescriptionOutput"/>
          <xsl:call-template name="CircleObservationOutput"/>

          <xsl:if test="Method = 'CircularObject'">
            <!-- There is a special op code (Circle Feature) for adding the resolved circle -->
            <xsl:text>18&#09;&#09;</xsl:text>  <!-- Op code (Circle feature) and 2 tabs -->
            <xsl:value-of select="format-number(CircularObject/Radius, $DecPl8, 'Standard')"/>
            <xsl:call-template name="NewLine"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
  </xsl:choose>
  
  <!-- Output any Descriptions or attached Notes as additional text for the point -->
  <xsl:if test="Description1 != ''">
    <xsl:text>41&#09;&#09;</xsl:text>  <!-- Op code (additional text) and 2 tabs -->
    <xsl:value-of select="Description1"/>
    <xsl:call-template name="NewLine"/>
  </xsl:if>

  <xsl:if test="Description2 != ''">
    <xsl:text>41&#09;&#09;</xsl:text>  <!-- Op code (additional text) and 2 tabs -->
    <xsl:value-of select="Description2"/>
    <xsl:call-template name="NewLine"/>
  </xsl:if>

  <xsl:for-each select="Notes/Note[. != '']">
    <xsl:text>41&#09;&#09;</xsl:text>  <!-- Op code (additional text) and 2 tabs -->
    <xsl:value-of select="."/>
    <xsl:call-template name="NewLine"/>
  </xsl:for-each>

  <!-- Now output any Attributes from Feature elements assigned to the point -->
  <xsl:for-each select="Features/Feature/Attribute[Value != '']">
    <xsl:choose>
      <xsl:when test="(Type = 'Text') or (Type = 'Menu') or (Type = 'File') or
                      (Type = 'Photo') or (Type = 'Date') or (Type = 'Time')">
        <xsl:text>73&#09;&#09;</xsl:text>  <!-- Op code (text attribute) and 2 tabs -->
        <xsl:value-of select="Name"/>
        <xsl:text>&#09;</xsl:text>
        <xsl:value-of select="Value"/>
        <xsl:call-template name="NewLine"/>
      </xsl:when>
      
      <xsl:when test="(Type = 'Numeric') and contains(Value, '.')">
        <xsl:text>72&#09;&#09;</xsl:text>  <!-- Op code (real number attribute) and 2 tabs -->
        <xsl:value-of select="Name"/>
        <xsl:text>&#09;</xsl:text>
        <xsl:value-of select="Value"/>
        <xsl:call-template name="NewLine"/>
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:text>71&#09;&#09;</xsl:text>  <!-- Op code (integer number attribute) and 2 tabs -->
        <xsl:value-of select="Name"/>
        <xsl:text>&#09;</xsl:text>
        <xsl:value-of select="Value"/>
        <xsl:call-template name="NewLine"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
  
  <!-- Now output any extra attributes requested -->
  <xsl:if test="($includeGNSSQCAsAttributes = 'Yes') and QualityControl1">
    <!-- Output PDOP value -->
    <xsl:text>72&#09;&#09;</xsl:text>  <!-- Op code (real number attribute) and 2 tabs -->
    <xsl:text>PDOP</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="format-number(QualityControl1/PDOP, $DecPl1, 'Standard')"/>
    <xsl:call-template name="NewLine"/>

    <!-- Output number of statellites -->
    <xsl:text>71&#09;&#09;</xsl:text>  <!-- Op code (integer number attribute) and 2 tabs -->
    <xsl:text>Nbr of satellites</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="QualityControl1/NumberOfSatellites"/>
    <xsl:call-template name="NewLine"/>

    <!-- Output number of positions used -->
    <xsl:text>71&#09;&#09;</xsl:text>  <!-- Op code (integer number attribute) and 2 tabs -->
    <xsl:text>Positions used</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="QualityControl1/NumberOfPositionsUsed"/>
    <xsl:call-template name="NewLine"/>

    <!-- Output horizontal precision value -->
    <xsl:text>72&#09;&#09;</xsl:text>  <!-- Op code (real number attribute) and 2 tabs -->
    <xsl:text>Hz precision</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="format-number(Precision/Horizontal, $DecPl3, 'Standard')"/>
    <xsl:call-template name="NewLine"/>

    <!-- Output vertical precision value -->
    <xsl:text>72&#09;&#09;</xsl:text>  <!-- Op code (real number attribute) and 2 tabs -->
    <xsl:text>Hz precision</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="format-number(Precision/Vertical, $DecPl3, 'Standard')"/>
    <xsl:call-template name="NewLine"/>
  </xsl:if>
  
  <xsl:if test="($includeDateTimeAsAttributes = 'Yes') and (@TimeStamp != '') and (QualityControl1 or TargetID)">
    <!-- Output the date for the point record -->
    <xsl:text>73&#09;&#09;</xsl:text>  <!-- Op code (text attribute) and 2 tabs -->
    <xsl:text>Date</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="substring-before(@TimeStamp, 'T')"/>
    <xsl:call-template name="NewLine"/>

    <!-- Output the time for the point record -->
    <xsl:text>73&#09;&#09;</xsl:text>  <!-- Op code (text attribute) and 2 tabs -->
    <xsl:text>Time</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="substring-after(@TimeStamp, 'T')"/>
    <xsl:call-template name="NewLine"/>
  </xsl:if>
  
  <xsl:if test="($includeTargetInstDetailsAsAttributes = 'Yes') and TargetID">
    <!-- Output target height value -->
    <xsl:text>72&#09;&#09;</xsl:text>  <!-- Op code (real number attribute) and 2 tabs -->
    <xsl:text>Target height</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="format-number(key('tgtID-search', TargetID)[1]/TargetHeight, $DecPl3, 'Standard')"/>
    <xsl:call-template name="NewLine"/>

    <!-- Output prism constant value -->
    <xsl:text>72&#09;&#09;</xsl:text>  <!-- Op code (real number attribute) and 2 tabs -->
    <xsl:text>Prism constant</xsl:text>
    <xsl:text>&#09;</xsl:text>
    <xsl:value-of select="format-number(key('tgtID-search', TargetID)[1]/PrismConstant * 1000.0, $DecPl1, 'Standard')"/>
    <xsl:text>mm</xsl:text>
    <xsl:call-template name="NewLine"/>
  </xsl:if>
</xsl:template>


<!-- **************************************************************** -->
<!-- ****************** Output special control code ***************** -->
<!-- **************************************************************** -->
<xsl:template name="WriteControlCode">
  <xsl:param name="controlCode"/>
  <xsl:param name="ptDesc"/>
  
  <xsl:choose>
    <xsl:when test="$controlCode = 'startArc'">61</xsl:when>
    <xsl:when test="$controlCode = 'endArc'">62</xsl:when>
    <xsl:when test="$controlCode = 'close'">
      <xsl:text>20&#09;&#09;</xsl:text>
      <xsl:value-of select="$ptDesc"/>
    </xsl:when>
    <xsl:when test="$controlCode = 'removeHeight'">30</xsl:when>
  </xsl:choose>
  <xsl:call-template name="NewLine"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* TargetRecord Processing ******************** -->
<!-- **************************************************************** -->
<xsl:template match="TargetRecord">

<xsl:variable name="tgtHt">
  <xsl:choose>
    <xsl:when test="string(number(TargetHeight)) != 'NaN'">
      <xsl:value-of select="TargetHeight"/>
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>   <!-- If target height is null default to a target height of 0 -->
  </xsl:choose>
  </xsl:variable>
  <xsl:text>05&#09;&#09;</xsl:text>  <!-- Op code (target height) and 2 tabs -->
  <xsl:value-of select="format-number($tgtHt, $DecPl8, 'Standard')"/>
  <xsl:call-template name="NewLine"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******************** NoteRecord Processing ********************* -->
<!-- **************************************************************** -->
<xsl:template match="NoteRecord">

  <xsl:for-each select="Notes/Note[. != '']">
    <xsl:text>29&#09;&#09;</xsl:text>  <!-- Op code (Note or memo) and 2 tabs -->
    <xsl:value-of select="."/>
    <xsl:call-template name="NewLine"/>
  </xsl:for-each>
</xsl:template>


<!-- **************************************************************** -->
<!-- **************** Output the point description ****************** -->
<!-- **************************************************************** -->
<xsl:template name="PointDescriptionOutput">
  <xsl:param name="skipStringOutput">false</xsl:param>
  <xsl:param name="backsightObs">false</xsl:param>

  <!-- First split the point code field into a code, a string number and   -->
  <!-- point text if possible.  The portion of the point code prior to the -->
  <!-- first space in the point code is to be used for the code.  The      -->
  <!-- portion after the first space is to be used for the point text.  If -->
  <!-- the code ends with a number then this is the string number so split -->
  <!-- this off from the code.                                             -->
  <xsl:variable name="codeFields">
    <xsl:variable name="code">
      <xsl:choose>
        <xsl:when test="contains(Code, $codePtTextSeparator)">
          <xsl:value-of select="substring-before(Code, $codePtTextSeparator)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="Code"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Take the portion of the Code (if any) after the codePtTextSeparator and place in the pointText element  -->
    <!-- First check to see if the string after the separator matches the $startArcCode, $endArcCode, $closeCode -->
    <!-- or $removeHtCode and if it does set the appropriate flag element otherwise add to pointText element.    -->
    <xsl:variable name="upperCaseStrAfter" select="translate(substring-after(Code, $codePtTextSeparator),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    <xsl:choose>
      <xsl:when test="$upperCaseStrAfter = $startArcCode">
        <xsl:element name="controlCode" namespace="">startArc</xsl:element>
      </xsl:when>
      <xsl:when test="$upperCaseStrAfter = $endArcCode">
        <xsl:element name="controlCode" namespace="">endArc</xsl:element>
      </xsl:when>
      <xsl:when test="$upperCaseStrAfter = $closeCode">
        <xsl:element name="controlCode" namespace="">close</xsl:element>
      </xsl:when>
      <xsl:when test="$upperCaseStrAfter = $removeHtCode">
        <xsl:element name="controlCode" namespace="">removeHeight</xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="pointText" namespace="">
          <xsl:value-of select="substring-after(Code, $codePtTextSeparator)"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:choose>
      <xsl:when test="(string(number(substring($code, string-length($code), 1))) != 'NaN') and ($skipStringOutput = 'false')">
        <!-- The last character in the $code variable is a number - remove all the alpha characters -->
        <xsl:variable name="stringNbr" select="translate($code, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ~!@#$%^&amp;*()_+={}[]\|:;&lt;&gt;,/?', '')"/>
        <xsl:variable name="codeStr" select="translate($code, '-0123456789.', '')"/>
        <xsl:choose>
          <xsl:when test="$codeStr != ''">  <!-- There was an alpha portion to code -->
            <xsl:element name="code" namespace="">
              <xsl:value-of select="$codeStr"/>
            </xsl:element>
            <xsl:element name="stringNumber" namespace="">
              <xsl:value-of select="$stringNbr"/>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>   <!-- Numeric only code so presumably not a 'string' code -->
            <xsl:element name="code" namespace="">
              <xsl:value-of select="$code"/>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="code" namespace="">
          <xsl:value-of select="$code"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Output the extracted code -->
  <xsl:element name="ptDesc" namespace="">
    <xsl:value-of select="$codeFields/code"/>
    <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
    <!-- Output the extracted string number -->
    <xsl:value-of select="$codeFields/stringNumber"/>
    <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
    <xsl:value-of select="Name"/>     <!-- Point number (Name) -->
    <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
    <!-- Point name - output here if non-numeric point name and user has selected option -->
    <xsl:if test="$copyAlphaNames != 'No'">
      <xsl:variable name="isNumericPtNbr" select="string(number(Name))"/>
      <xsl:if test="($isNumericPtNbr = 'NaN') or ($backsightObs != 'false')">
        <!-- Non-numeric point name -->
        <xsl:value-of select="Name"/>
      </xsl:if>
    </xsl:if>
    <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
    <!-- Output the extracted point text -->
    <xsl:value-of select="$codeFields/pointText"/>
    <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
  </xsl:element>
  <xsl:element name="controlCode" namespace="">
    <xsl:if test="$codeFields/controlCode != ''">
      <xsl:value-of select="$codeFields/controlCode"/>
    </xsl:if>
  </xsl:element>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************* Output the circle observation values ************* -->
<!-- **************************************************************** -->
<xsl:template name="CircleObservationOutput">
  <xsl:param name="skipNewLine" select="'false'"/>

  <xsl:choose>
    <xsl:when test="Method = 'DistanceOffset'">
      <!-- Note: NewLine cannot be skipped for DistanceOffset output -->
      <xsl:call-template name="DistanceOffsetOutput"/>
    </xsl:when>

    <xsl:otherwise>
      <!-- Output the horizontal observation -->
      <xsl:value-of select="format-number(Circle/HorizontalCircle, $DecPl8, 'Standard')"/>
      <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
      <!-- Output the vertical observation -->
      <xsl:value-of select="format-number(Circle/VerticalCircle, $DecPl8, 'Standard')"/>
      <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
      <!-- Output the slope distance - apply prism constant and atmospheric corrections. -->
      <!-- There doesn't appear to be anywhere in the 12d fld file format to record the  -->
      <!-- prism constant and atmospheric ppm values so it will not be possible to       -->
      <!-- properly apply these corrections at a later stage.                            -->
      <xsl:variable name="correctedSlopeDist">
        <xsl:call-template name="CorrectedSlopeDistance">
          <xsl:with-param name="dist" select="Circle/EDMDistance"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="format-number($correctedSlopeDist, $DecPl8, 'Standard')"/>
      
      <xsl:if test="$skipNewLine = 'false'">
        <xsl:call-template name="NewLine"/>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******** Determine the azimuth to the backsight point ********** -->
<!-- **************************************************************** -->
<xsl:template name="GetBacksightAzimuth">

  <xsl:variable name="bkBrgID" select="BackBearingID"/>
  <xsl:for-each select="/JOBFile/FieldBook/BackBearingRecord[@ID = $bkBrgID]">
    <xsl:choose>
      <xsl:when test="string(number(Face1HorizontalCircle)) != 'NaN'">     <!-- There is a F1 observation value -->
        <xsl:call-template name="NormalisedAngle">
          <xsl:with-param name="angle" select="Face1HorizontalCircle + OrientationCorrection"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="(string(number(Face1HorizontalCircle)) = 'NaN') and (string(number(Face2HorizontalCircle)) != 'NaN')">  <!-- There is no F1 obs value but there is a F2 value -->
        <xsl:call-template name="NormalisedAngle">
          <xsl:with-param name="angle" select="Face2HorizontalCircle - 180.0 + OrientationCorrection"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="OrientationCorrection"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************* Compute the corrected slope distance ************* -->
<!-- **************************************************************** -->
<xsl:template name="CorrectedSlopeDistance">
  <xsl:param name="dist"/>
  
  <!-- This routine will compute the corrected slope distance using the    -->
  <!-- supplied dist parameter and grab the prism constant and atmospheric -->
  <!-- ppm values using the record ID references from the current context  -->
  <!-- PointRecord.                                                        -->
  <xsl:variable name="prismConst">
    <xsl:variable name="pc">
      <xsl:for-each select="key('tgtID-search', TargetID)[1]">
        <xsl:value-of select="PrismConstant"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string(number($pc)) = 'NaN'">0</xsl:when>  <!-- In case of null value set to zero -->
      <xsl:otherwise>
        <xsl:value-of select="$pc"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="atmosppm">
    <xsl:variable name="ppm">
      <xsl:for-each select="key('stnID-search', StationID)">
        <xsl:for-each select="key('atmosID-search', AtmosphereID)">
          <xsl:value-of select="PPM"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string(number($ppm))='NaN'">0</xsl:when>  <!-- In case of null value set to zero -->
      <xsl:otherwise>
        <xsl:value-of select="$ppm"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Apply the prism constant and atmospheric ppm correction to the slope dist -->
  <xsl:value-of select="$dist + $prismConst + $atmosppm div 1000000.0 * $dist"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Output distance offset obs and offsets ************ -->
<!-- **************************************************************** -->
<xsl:template name="DistanceOffsetOutput">

  <!-- Output the originally measured horizontal observation -->
  <xsl:value-of select="format-number(DistanceOffset/RawObservation/HorizontalCircle, $DecPl8, 'Standard')"/>
  <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
  <!-- Output the vertical observation -->
  <xsl:value-of select="format-number(DistanceOffset/RawObservation/VerticalCircle, $DecPl8, 'Standard')"/>
  <xsl:text>&#09;</xsl:text>        <!-- Tab field separator -->
  <!-- Output the slope distance - apply prism constant and atmospheric corrections. -->
  <!-- There doesn't appear to be anywhere in the 12d fld file format to record the  -->
  <!-- prism constant and atmospheric ppm values so it will not be possible to       -->
  <!-- properly apply these corrections at a later stage.                            -->
  <xsl:variable name="correctedSlopeDist">
    <xsl:call-template name="CorrectedSlopeDistance">
      <xsl:with-param name="dist" select="DistanceOffset/RawObservation/EDMDistance"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:value-of select="format-number($correctedSlopeDist, $DecPl8, 'Standard')"/>
  <!-- Start a new line here so that the distance offset values can be written out -->
  <xsl:call-template name="NewLine"/>
  
  <!-- Now output the offset value details -->
  <xsl:choose>
    <xsl:when test="DistanceOffset/Direction">  <!-- This has the old style single offset details -->
      <xsl:choose>
        <xsl:when test="(DistanceOffset/Direction = 'Right') or (DistanceOffset/Direction = 'Left')">
          <xsl:text>43&#09;&#09;</xsl:text>  <!-- Op code (tangential offset) and 2 tabs -->
          <xsl:if test="(DistanceOffset/Direction = 'Right')">-</xsl:if>
          <xsl:value-of select="format-number(DistanceOffset/Distance, $DecPl8, 'Standard')"/>
        </xsl:when>
        <xsl:otherwise>  <!-- Direction must be In or Out -->
          <xsl:text>42&#09;&#09;</xsl:text>  <!-- Op code (radial offset) and 2 tabs -->
          <xsl:if test="(DistanceOffset/Direction = 'In')">-</xsl:if>
          <xsl:value-of select="format-number(DistanceOffset/Distance, $DecPl8, 'Standard')"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="NewLine"/>
    </xsl:when>

    <xsl:otherwise>              <!-- This is the newer style offset details -->
      <xsl:if test="DistanceOffset/LeftRightOffset != 0">  <!-- There is a left/right offset -->
        <xsl:text>43&#09;&#09;</xsl:text>  <!-- Op code (tangential offset) and 2 tabs -->
        <xsl:value-of select="format-number(DistanceOffset/LeftRightOffset, $DecPl8, 'Standard')"/>
        <xsl:call-template name="NewLine"/>
      </xsl:if>

      <xsl:if test="DistanceOffset/InOutOffset != 0">  <!-- There is an in/out offset -->
        <xsl:text>42&#09;&#09;</xsl:text>  <!-- Op code (radial offset) and 2 tabs -->
        <xsl:value-of select="format-number(DistanceOffset/InOutOffset, $DecPl8, 'Standard')"/>
        <xsl:call-template name="NewLine"/>
      </xsl:if>

      <xsl:if test="DistanceOffset/DownUpOffset != 0">  <!-- There is a down/up offset -->
        <xsl:text>44&#09;&#09;</xsl:text>  <!-- Op code (height offset) and 2 tabs -->
        <xsl:value-of select="format-number(DistanceOffset/DownUpOffset, $DecPl8, 'Standard')"/>
        <xsl:call-template name="NewLine"/>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


<!-- **************************************************************** -->
<!-- ******************* Return instrument type ********************* -->
<!-- **************************************************************** -->
<xsl:template name="InstrumentType">
  <xsl:param name="type"/>

  <xsl:choose>
    <xsl:when test="$type = 'TrimbleTTS'">Trimble TTS</xsl:when>
    <xsl:when test="$type = 'Trimble3300'">Trimble 3300</xsl:when>
    <xsl:when test="$type = 'Trimble3600Elta'">Trimble 3600 Elta</xsl:when>
    <xsl:when test="$type = 'Trimble3600GDM'">Trimble </xsl:when>
    <xsl:when test="$type = 'Trimble5600'">Trimble </xsl:when>
    <xsl:when test="$type = 'TrimbleSSeries'">Trimble </xsl:when>
    <xsl:when test="$type = 'TrimbleVXandSSeries'">Trimble </xsl:when>
    <xsl:when test="($type = 'SETBasic') or ($type = 'SETEnhanced')">Sokkia SET</xsl:when>
    <xsl:when test="$type = 'Geodimeter400'">Geodimeter 400</xsl:when>
    <xsl:when test="$type = 'Geodimeter500Servo'">Geodimeter 500 Servo</xsl:when>
    <xsl:when test="$type = 'Geodimeter600'">Geodimeter 600</xsl:when>
    <xsl:when test="$type = 'Geodimeter600Servo'">Geodimeter 600 Servo</xsl:when>
    <xsl:when test="$type = 'Geodimeter600Robotic'">Geodimeter 600 Robotic</xsl:when>
    <xsl:when test="$type = 'Geodimeter4000'">Geodimeter 4000</xsl:when>
    <xsl:when test="$type = 'LeicaTC300'">Leica TC300</xsl:when>
    <xsl:when test="$type = 'LeicaTC500'">Leica TC500</xsl:when>
    <xsl:when test="$type = 'LeicaTC800'">Leica TC800</xsl:when>
    <xsl:when test="($type = 'LeicaT1000_6') or ($type = 'LeicaT1000_14')">Leica T1000</xsl:when>
    <xsl:when test="$type = 'LeicaTC1100'">Leica TC1100</xsl:when>
    <xsl:when test="$type = 'LeicaTC1100ServoGeoCom'">Leica TC1100 Servo</xsl:when>
    <xsl:when test="$type = 'LeicaTC1100RoboticGeoCom'">Leica TC1100 Robotic</xsl:when>
    <xsl:when test="$type = 'LeicaTC1600'">Leica TC1600</xsl:when>
    <xsl:when test="$type = 'LeicaTC2000'">Leica TC2000</xsl:when>
    <xsl:when test="$type = 'Nikon'">Nikon</xsl:when>
    <xsl:when test="$type = 'Pentax'">Pentax</xsl:when>
    <xsl:when test="$type = 'TopconGeneric'">Topcon</xsl:when>
    <xsl:when test="$type = 'Topcon500'">Topcon 500</xsl:when>
    <xsl:when test="$type = 'ZeissElta2'">Zeiss Elta2</xsl:when>
    <xsl:when test="$type = 'ZeissElta3'">Zeiss Elta3</xsl:when>
    <xsl:when test="$type = 'ZeissElta4'">Zeiss Elta4</xsl:when>
    <xsl:when test="$type = 'ZeissEltaC'">Zeiss EltaC</xsl:when>
    <xsl:when test="$type = 'ZeissRecEltaE'">Zeiss RecEltaE</xsl:when>
    <xsl:when test="$type = 'ZeissRSeries'">Zeiss R Series</xsl:when>
    <xsl:when test="$type = 'Manual'">Manual</xsl:when>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********** Output QC (Collimation & check obs) details ********* -->
<!-- **************************************************************** -->
<xsl:template name="OutputQCDetails">
  <xsl:param name="instRecCount"/>
  <xsl:param name="RTKPtCount"/>

  <!-- First output the collimation details for the instrument(s) used -->
  <!-- Output all the details as comment lines so that it is still a valid 12d fld file -->
  <xsl:text>//</xsl:text>
  <xsl:call-template name="NewLine"/>

  <xsl:if test="$instRecCount != 0">
    <xsl:text>// ------------------------------------------------------------------------</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:text>// Instrument Collimation Report</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:text>// ------------------------------------------------------------------------</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:for-each select="/JOBFile/FieldBook/InstrumentRecord">
      <xsl:variable name="hzColl" select="InstrumentAppliedHorizontalCollimation"/>
      <xsl:variable name="vtColl" select="InstrumentAppliedVerticalCollimation"/>

      <xsl:if test="(string(number($hzColl)) != 'NaN') and (string(number($vtColl)) != 'NaN') and
                    ((position() = 1) or
                     (preceding-sibling::InstrumentRecord[1]/InstrumentAppliedHorizontalCollimation != $hzColl) or
                     (preceding-sibling::InstrumentRecord[1]/InstrumentAppliedVerticalCollimation != $vtColl))">
        <xsl:text>// Instrument details recorded at:                     </xsl:text>
        <xsl:call-template name="FormatDate">
          <xsl:with-param name="timeStamp" select="@TimeStamp"/>
          <xsl:with-param name="formatStr" select="'dddd,dd MMMM yyyy'"/>
        </xsl:call-template>
        <!-- Add the time -->
        <xsl:value-of select="' '"/>
        <xsl:value-of select="substring-after(@TimeStamp, 'T')"/>
        <xsl:call-template name="NewLine"/>

        <xsl:text>// Instrument:                                         Trimble </xsl:text>
        <xsl:value-of select="Model"/>
        <xsl:call-template name="NewLine"/>

        <xsl:text>// Serial #:                                           </xsl:text>
        <xsl:value-of select="Serial"/>
        <xsl:call-template name="NewLine"/>

        <xsl:text>// Horizontal collimation set in instrument:          </xsl:text>
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="10"/>
          <xsl:with-param name="theString">
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="InstrumentAppliedHorizontalCollimation"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="NewLine"/>

        <xsl:text>// Vertical collimation set in instrument:            </xsl:text>
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="10"/>
          <xsl:with-param name="theString">
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="InstrumentAppliedVerticalCollimation"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="NewLine"/>

        <xsl:text>// Trunion axis tilt correction:                      </xsl:text>
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="10"/>
          <xsl:with-param name="theString">
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="TrunionAxisTiltCorrection"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="NewLine"/>

        <xsl:text>// Autolock horizontal collimation set in instrument: </xsl:text>
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="10"/>
          <xsl:with-param name="theString">
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="InstrumentAppliedAutolockHorizontalCollimation"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="NewLine"/>

        <xsl:text>// Autolock vertical collimation set in instrument:   </xsl:text>
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="10"/>
          <xsl:with-param name="theString">
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="InstrumentAppliedAutolockVerticalCollimation"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="NewLine"/>

        <!-- Separating line -->
        <xsl:text>//</xsl:text>
        <xsl:call-template name="NewLine"/>
      </xsl:if>
    </xsl:for-each>

    <!-- Now output a check shot report if any check observations have been made -->
    <xsl:if test="count(/JOBFile/FieldBook/PointRecord[(Classification = 'Check') and Circle]) != 0">
      <!-- Separating line -->
      <xsl:text>//</xsl:text>
      <xsl:call-template name="NewLine"/>

      <xsl:text>// ------------------------------------------------------------------------</xsl:text>
      <xsl:call-template name="NewLine"/>

      <xsl:text>// Check Shot Report</xsl:text>
      <xsl:call-template name="NewLine"/>

      <xsl:text>// ------------------------------------------------------------------------</xsl:text>
      <xsl:call-template name="NewLine"/>

      <!-- Heading line -->
      <xsl:text>// Station         Point               dHz Obs       dHoriz       dVert</xsl:text>
      <xsl:call-template name="NewLine"/>

      <xsl:text>// -------         -----               -------       ------       -----</xsl:text>
      <xsl:call-template name="NewLine"/>

      <xsl:for-each select="/JOBFile/FieldBook/PointRecord[(Classification = 'Check') and Circle]">
        <xsl:variable name="NameStr" select="Name"/>
        <xsl:variable name="BSID" select="BackBearingID"/>

        <xsl:variable name="BSStr">
          <xsl:for-each select="key('bsID-search', BackBearingID)">
            <xsl:choose>
              <xsl:when test="$NameStr = BackSight"> (BS)</xsl:when>
              <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="Face" select="Circle/Face"/>

        <!-- Get the backsight hz observation if a backsight check -->
        <xsl:variable name="BSObs">
          <xsl:if test="$BSStr != ''">
            <xsl:for-each select="key('bsID-search', BackBearingID)">
              <xsl:if test="$Face = 'Face1' or $Face = 'FaceNull'">
                <xsl:value-of select="Face1HorizontalCircle"/>
              </xsl:if>
              <xsl:if test="$Face = 'Face2'">
                <xsl:value-of select="Face2HorizontalCircle"/>
              </xsl:if>
            </xsl:for-each>
          </xsl:if>
        </xsl:variable>

        <xsl:variable name="DeltaAngle">
          <xsl:choose>
            <xsl:when test="($BSStr != '') and (string(number($BSObs)) != 'NaN')">  <!-- This is a backsight check and we have a backsight hz obs -->
              <xsl:value-of select="$BSObs - Circle/HorizontalCircle"/>  <!-- Report delta from current obs to BS -->
            </xsl:when>

            <xsl:otherwise>  <!-- This is a check on a non-backsight point -->
              <xsl:variable name="OrigPtObs">
                <!-- Locate all the observations that have the same station and backsight -->
                <!-- references, are not deleted, are to the same point name, are not     -->
                <!-- check observations and are on the same face                          -->
                <xsl:for-each select="key('ptFromStn-search', StationID)">
                  <xsl:if test="(Deleted = 'false') and ($BSID = BackBearingID) and
                                ($NameStr = Name) and (Classification != 'Check') and
                                ($Face = Circle/Face)">
                    <xsl:element name="obs">
                      <xsl:value-of select="Circle/HorizontalCircle"/>
                    </xsl:element>
                  </xsl:if>
                </xsl:for-each>
              </xsl:variable>
              <!-- Now get the first observation - this will ensure         -->
              <!-- that we only have a single angle value left to work with -->
              <xsl:value-of select="$OrigPtObs/obs[1] - Circle/HorizontalCircle"/>  <!-- Report delta from current obs to Orig obs -->
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="deltaHzObs">
          <xsl:variable name="absDeltaAngle" select="concat(substring('-',2 - ($DeltaAngle &lt; 0)), '1') * $DeltaAngle"/>
          <xsl:choose>
            <xsl:when test="$absDeltaAngle &gt; 350">  <!-- Have a value close to 360 deg -->
              <xsl:choose>
                <xsl:when test="$DeltaAngle &gt; 0">
                  <xsl:value-of select="$DeltaAngle - 360.0"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$DeltaAngle + 360.0"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$DeltaAngle"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="deltaHzObsStr">
          <xsl:if test="string(number($deltaHzObs)) != 'NaN'">
            <xsl:call-template name="FormatAngle">
              <xsl:with-param name="theAngle" select="$deltaHzObs"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>

        <xsl:text>// </xsl:text>
        <!-- Output the station name -->
        <xsl:call-template name="PadRight">
          <xsl:with-param name="stringWidth" select="16"/>
          <xsl:with-param name="theString">
            <xsl:for-each select="key('stnID-search', StationID)">
              <xsl:value-of select="StationName"/>
            </xsl:for-each>
          </xsl:with-param>
        </xsl:call-template>

        <!-- Output the point name -->
        <xsl:call-template name="PadRight">
          <xsl:with-param name="stringWidth" select="16"/>
          <xsl:with-param name="theString" select="concat(Name, $BSStr)"/>
        </xsl:call-template>

        <!-- Output the deltaHzObsStr -->
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="12"/>
          <xsl:with-param name="theString" select="$deltaHzObsStr"/>
        </xsl:call-template>

        <!-- Output the delta horizontal distance if available -->
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="12"/>
          <xsl:with-param name="theString">
            <xsl:if test="string(number(ObservationPolarDeltas/HorizontalDistance)) != 'NaN'">
              <xsl:value-of select="format-number(ObservationPolarDeltas/HorizontalDistance, $DecPl3, 'Standard')"/>
            </xsl:if>
          </xsl:with-param>
        </xsl:call-template>

        <!-- Output the delta vertical distance if available -->
        <xsl:call-template name="PadLeft">
          <xsl:with-param name="stringWidth" select="12"/>
          <xsl:with-param name="theString">
            <xsl:if test="string(number(ObservationPolarDeltas/VerticalDistance)) != 'NaN'">
              <xsl:value-of select="format-number(ObservationPolarDeltas/VerticalDistance, $DecPl3, 'Standard')"/>
            </xsl:if>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="NewLine"/>
      </xsl:for-each>
    </xsl:if>   <!-- There are conventional check observations -->
  </xsl:if>     <!-- There are S Series instrument records -->

  <xsl:if test="$RTKPtCount != 0">
    <xsl:text>// -----------------------------------------------------------------------------</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:text>// RTK Point Details Report</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:text>// -----------------------------------------------------------------------------</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:text>// Point            Hz Prec Vt Prec     RMS PDOP Sats</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:text>// -----            ------- -------     --- ---- ----</xsl:text>
    <xsl:call-template name="NewLine"/>

    <xsl:for-each select="/JOBFile/FieldBook/PointRecord[Precision and (Deleted = 'false')]">
      <xsl:text>// </xsl:text>
      <!-- Output name -->
      <xsl:call-template name="PadRight">
        <xsl:with-param name="stringWidth" select="16"/>
        <xsl:with-param name="theString" select="Name"/>
      </xsl:call-template>

      <!-- Output horizontal precision -->
      <xsl:call-template name="PadLeft">
        <xsl:with-param name="stringWidth" select="8"/>
        <xsl:with-param name="theString" select="format-number(Precision/Horizontal, $DecPl3, 'Standard')"/>
      </xsl:call-template>

      <!-- Output vertical precision -->
      <xsl:call-template name="PadLeft">
        <xsl:with-param name="stringWidth" select="8"/>
        <xsl:with-param name="theString" select="format-number(Precision/Vertical, $DecPl3, 'Standard')"/>
      </xsl:call-template>

      <!-- Output the RMS in distance terms -->
      <xsl:variable name="receiverFWVer" select="/JOBFile/FieldBook/GPSEquipmentRecord[(ReceiverFirmwareVersion != '') and (ReceiverFirmwareVersion != 0)][last()]/ReceiverFirmwareVersion"/>
      <xsl:variable name="rmsAsDist">
        <!-- RMS is stored in millicycles - divide by 1000 to get cycles then multiply by 0.19 (the L1 wavelength) -->
        <xsl:value-of select="QualityControl1/RMS div 1000.0 * 0.19"/>
      </xsl:variable>
      <xsl:call-template name="PadLeft">
        <xsl:with-param name="stringWidth" select="8"/>
        <xsl:with-param name="theString" select="format-number($rmsAsDist, $DecPl3, 'Standard')"/>
      </xsl:call-template>

      <!-- Output PDOP -->
      <xsl:call-template name="PadLeft">
        <xsl:with-param name="stringWidth" select="5"/>
        <xsl:with-param name="theString" select="format-number(QualityControl1/PDOP, $DecPl1, 'Standard')"/>
      </xsl:call-template>

      <!-- Output number of satellites -->
      <xsl:call-template name="PadLeft">
        <xsl:with-param name="stringWidth" select="5"/>
        <xsl:with-param name="theString" select="QualityControl1/NumberOfSatellites"/>
      </xsl:call-template>
      <xsl:call-template name="NewLine"/>
    </xsl:for-each>
  </xsl:if>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Output Angle in Appropriate Format **************** -->
<!-- **************************************************************** -->
<xsl:template name="FormatAngle">
  <xsl:param name="theAngle"/>
  <xsl:param name="secDecPlaces" select="0"/>
  <xsl:param name="DMSOutput" select="'false'"/>  <!-- Can be used to force DMS output -->
  <xsl:param name="useSymbols" select="'true'"/>
  <xsl:param name="impliedDecimalPt" select="'false'"/>
  <xsl:param name="gonsDecPlaces" select="5"/>    <!-- Decimal places for gons output -->
  <xsl:param name="decDegDecPlaces" select="5"/>  <!-- Decimal places for decimal degrees output -->
  <xsl:param name="outputAsMilligonsOrSecs" select="'false'"/>
  <xsl:param name="outputAsMilligonsOrSecsSqrd" select="'false'"/>
  <xsl:param name="dmsSymbols">&#0176;'"</xsl:param>

  <xsl:variable name="gonsDecPl">
    <xsl:choose>
      <xsl:when test="$gonsDecPlaces = 1"><xsl:value-of select="$DecPl1"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 2"><xsl:value-of select="$DecPl2"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 3"><xsl:value-of select="$DecPl3"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 4"><xsl:value-of select="$DecPl4"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 5"><xsl:value-of select="$DecPl5"/></xsl:when>
      <xsl:when test="$gonsDecPlaces = 6"><xsl:value-of select="$DecPl6"/></xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="decDegDecPl">
    <xsl:choose>
      <xsl:when test="$decDegDecPlaces = 1"><xsl:value-of select="$DecPl1"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 2"><xsl:value-of select="$DecPl2"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 3"><xsl:value-of select="$DecPl3"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 4"><xsl:value-of select="$DecPl4"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 5"><xsl:value-of select="$DecPl5"/></xsl:when>
      <xsl:when test="$decDegDecPlaces = 6"><xsl:value-of select="$DecPl6"/></xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <!-- Null angle value -->
    <xsl:when test="string(number($theAngle))='NaN'">
      <xsl:value-of select="format-number($theAngle, $DecPl3, 'Standard')"/> <!-- Use the defined null format output -->
    </xsl:when>
    <!-- There is an angle value -->
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="($AngleUnit = 'DMSDegrees') or not($DMSOutput = 'false')">
          <xsl:choose>
            <xsl:when test="$outputAsMilligonsOrSecs != 'false'">
              <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 3600.0, '00.0', 'Standard')"/>
            </xsl:when>            
            <xsl:when test="$outputAsMilligonsOrSecsSqrd != 'false'">
              <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 3600.0 * 3600.0, '00.000', 'Standard')"/>
            </xsl:when>            
            <xsl:otherwise>
              <xsl:call-template name="FormatDMSAngle">
                <xsl:with-param name="decimalAngle" select="$theAngle"/>
                <xsl:with-param name="secDecPlaces" select="$secDecPlaces"/>
                <xsl:with-param name="useSymbols" select="$useSymbols"/>
                <xsl:with-param name="impliedDecimalPt" select="$impliedDecimalPt"/>
                <xsl:with-param name="dmsSymbols" select="$dmsSymbols"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>  
        </xsl:when>

        <xsl:otherwise>
          <xsl:variable name="fmtAngle">
            <xsl:choose>
              <xsl:when test="($AngleUnit = 'Gons') and ($DMSOutput = 'false')">
                <xsl:choose>
                  <xsl:when test="$outputAsMilligonsOrSecs != 'false'">
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 1000.0, $DecPl2, 'Standard')"/>
                  </xsl:when>
                  <xsl:when test="$outputAsMilligonsOrSecsSqrd != 'false'">
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor * 1000.0 * 1000.0, $DecPl4, 'Standard')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="$secDecPlaces &gt; 0">  <!-- More accurate angle output required -->
                        <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl8, 'Standard')"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $gonsDecPl, 'Standard')"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>

              <xsl:when test="($AngleUnit = 'Mils') and ($DMSOutput = 'false')">
                <xsl:choose>
                  <xsl:when test="$secDecPlaces &gt; 0">  <!-- More accurate angle output required -->
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl6, 'Standard')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl4, 'Standard')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>

              <xsl:when test="($AngleUnit = 'DecimalDegrees') and ($DMSOutput = 'false')">
                <xsl:choose>
                  <xsl:when test="$secDecPlaces &gt; 0">  <!-- More accurate angle output required -->
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $DecPl8, 'Standard')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="format-number($theAngle * $AngleConvFactor, $decDegDecPl, 'Standard')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>
          
          <xsl:choose>
            <xsl:when test="$impliedDecimalPt != 'true'">
              <xsl:value-of select="$fmtAngle"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="translate($fmtAngle, '.', '')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- *********** Pad a string to the right with spaces ************** -->
<!-- **************************************************************** -->
<xsl:template name="PadRight">
  <xsl:param name="stringWidth"/>
  <xsl:param name="theString"/>
  <xsl:choose>
    <xsl:when test="$stringWidth = '0'">
      <xsl:value-of select="normalize-space($theString)"/> <!-- Function return value -->
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="paddedStr" select="concat($theString, '                                                                                          ')"/>
      <xsl:value-of select="substring($paddedStr, 1, $stringWidth)"/> <!-- Function return value -->
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- *********** Pad a string to the left with spaces *************** -->
<!-- **************************************************************** -->
<xsl:template name="PadLeft">
  <xsl:param name="stringWidth"/>
  <xsl:param name="theString"/>
  <xsl:choose>
    <xsl:when test="$stringWidth = '0'">
      <xsl:value-of select="normalize-space($theString)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="paddedStr" select="concat('                                                            ', $theString)"/>
      <xsl:value-of select="substring($paddedStr, string-length($paddedStr) - $stringWidth + 1)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********************** New Line Output ************************* -->
<!-- **************************************************************** -->
<xsl:template name="NewLine">
  <xsl:text>&#10;</xsl:text>
</xsl:template>


<!-- **************************************************************** -->
<!-- ***** Return Angle between 0 and 360 or -180 to 180 degrees **** -->
<!-- **************************************************************** -->
<xsl:template name="NormalisedAngle">
  <xsl:param name="angle"/>
  <xsl:param name="plusMinus180" select="'false'"/>

  <xsl:variable name="fullCircleAngle">
    <xsl:choose>
      <xsl:when test="$angle &lt; 0">
        <xsl:variable name="newAngle">
          <xsl:value-of select="$angle + 360.0"/>
        </xsl:variable>
        <xsl:call-template name="NormalisedAngle">
          <xsl:with-param name="angle" select="$newAngle"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="$angle &gt;= 360.0">
        <xsl:variable name="newAngle">
          <xsl:value-of select="$angle - 360.0"/>
        </xsl:variable>
        <xsl:call-template name="NormalisedAngle">
          <xsl:with-param name="angle" select="$newAngle"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:value-of select="$angle"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$plusMinus180 = 'false'">
      <xsl:value-of select="$fullCircleAngle"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$fullCircleAngle &lt;= 180.0">
          <xsl:value-of select="$fullCircleAngle"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$fullCircleAngle - 360.0"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********** Format date according to specified format *********** -->
<!-- **************************************************************** -->
<xsl:template name="FormatDate">
  <xsl:param name="timeStamp"/>
  <xsl:param name="formatStr"/>

  <!-- The supported format characters are as described below:
       Character(s)              Description
       M                         Months as 1-12
       MM                        Months as 01-12
       MMM                       Months as Jan-Dec
       MMMM                      Months as January-December
       d                         Days as 1-31
       dd                        Days as 01-31
       ddd                       Days as Sun-Sat
       dddd                      Days as Sunday-Saturday
       y                         Years as 1,2 …,99
       yy                        Years as 00-99
       yyyy                      Years as 1900-9999       -->

  <xsl:variable name="dateFormat">
    <xsl:call-template name="GetMonthPatterns">
      <xsl:with-param name="formatStr" select="$formatStr"/>
      <xsl:with-param name="timeStamp" select="$timeStamp"/>
    </xsl:call-template>

    <xsl:call-template name="GetDayPatterns">
      <xsl:with-param name="formatStr" select="$formatStr"/>
      <xsl:with-param name="timeStamp" select="$timeStamp"/>
    </xsl:call-template>

    <xsl:call-template name="GetYearPatterns">
      <xsl:with-param name="formatStr" select="$formatStr"/>
      <xsl:with-param name="timeStamp" select="$timeStamp"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="sortedDateFormat">
    <xsl:for-each select="$dateFormat/item">
      <xsl:sort select="startPos" data-type="number" order="ascending"/>
      <xsl:copy-of select="."/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:for-each select="$sortedDateFormat/item">
    <xsl:value-of select="string"/>
    <xsl:if test="position() != last()">  <!-- Output the separating character(s) -->
      <xsl:variable name="sepStrStart" select="startPos + length"/>
      <xsl:variable name="sepStrEnd" select="following-sibling::item/startPos - 1"/>
      <xsl:value-of select="substring($formatStr, $sepStrStart, $sepStrEnd - $sepStrStart + 1)"/>
    </xsl:if>
  </xsl:for-each>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********************** Format a DMS Angle ********************** -->
<!-- **************************************************************** -->
<xsl:template name="FormatDMSAngle">
  <xsl:param name="decimalAngle"/>
  <xsl:param name="secDecPlaces" select="0"/>
  <xsl:param name="useSymbols" select="'true'"/>
  <xsl:param name="impliedDecimalPt" select="'false'"/>
  <xsl:param name="dmsSymbols">&#0176;'"</xsl:param>

  <xsl:variable name="degreesSymbol">
    <xsl:choose>
      <xsl:when test="$useSymbols = 'true'"><xsl:value-of select="substring($dmsSymbols, 1, 1)"/></xsl:when>  <!-- Degrees symbol ° -->
      <xsl:otherwise>
        <xsl:if test="$impliedDecimalPt != 'true'">.</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="minutesSymbol">
    <xsl:choose>
      <xsl:when test="$useSymbols = 'true'"><xsl:value-of select="substring($dmsSymbols, 2, 1)"/></xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="secondsSymbol">
    <xsl:choose>
      <xsl:when test="$useSymbols = 'true'"><xsl:value-of select="substring($dmsSymbols, 3, 1)"/></xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="sign">
    <xsl:if test="$decimalAngle &lt; '0.0'">-1</xsl:if>
    <xsl:if test="$decimalAngle &gt;= '0.0'">1</xsl:if>
  </xsl:variable>

  <xsl:variable name="posDecimalDegrees" select="number($decimalAngle * $sign)"/>

  <xsl:variable name="positiveDecimalDegrees">  <!-- Ensure an angle very close to 360° is treated as 0° -->
    <xsl:choose>
      <xsl:when test="(360.0 - $posDecimalDegrees) &lt; 0.00001">
        <xsl:value-of select="0"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$posDecimalDegrees"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="decPlFmt">
    <xsl:choose>
      <xsl:when test="$secDecPlaces = 0"><xsl:value-of select="''"/></xsl:when>
      <xsl:when test="$secDecPlaces = 1"><xsl:value-of select="'.0'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 2"><xsl:value-of select="'.00'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 3"><xsl:value-of select="'.000'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 4"><xsl:value-of select="'.0000'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 5"><xsl:value-of select="'.00000'"/></xsl:when>
      <xsl:when test="$secDecPlaces = 6"><xsl:value-of select="'.000000'"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="degrees" select="floor($positiveDecimalDegrees)"/>
  <xsl:variable name="decimalMinutes" select="number(number($positiveDecimalDegrees - $degrees) * 60 )"/>
  <xsl:variable name="minutes" select="floor($decimalMinutes)"/>
  <xsl:variable name="seconds" select="number(number($decimalMinutes - $minutes)*60)"/>

  <xsl:variable name="partiallyNormalisedMinutes">
    <xsl:if test="number(format-number($seconds, concat('00', $decPlFmt))) = 60"><xsl:value-of select="number($minutes + 1)"/></xsl:if>
    <xsl:if test="not(number(format-number($seconds, concat('00', $decPlFmt))) = 60)"><xsl:value-of select="$minutes"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="normalisedSeconds">
    <xsl:if test="number(format-number($seconds, concat('00', $decPlFmt))) = 60"><xsl:value-of select="0"/></xsl:if>
    <xsl:if test="not(number(format-number($seconds, concat('00', $decPlFmt))) = 60)"><xsl:value-of select="$seconds"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="partiallyNormalisedDegrees">
    <xsl:if test="format-number($partiallyNormalisedMinutes, '0') = '60'"><xsl:value-of select="number($degrees + 1)"/></xsl:if>
    <xsl:if test="not(format-number($partiallyNormalisedMinutes, '0') = '60')"><xsl:value-of select="$degrees"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="normalisedDegrees">
    <xsl:if test="format-number($partiallyNormalisedDegrees, '0') = '360'"><xsl:value-of select="0"/></xsl:if>
    <xsl:if test="not(format-number($partiallyNormalisedDegrees, '0') = '360')"><xsl:value-of select="$partiallyNormalisedDegrees"/></xsl:if>
  </xsl:variable>

  <xsl:variable name="normalisedMinutes">
    <xsl:if test="format-number($partiallyNormalisedMinutes, '00') = '60'"><xsl:value-of select="0"/></xsl:if>
    <xsl:if test="not(format-number($partiallyNormalisedMinutes, '00') = '60')"><xsl:value-of select="$partiallyNormalisedMinutes"/></xsl:if>
  </xsl:variable>

  <xsl:if test="$sign = -1">-</xsl:if>
  <xsl:value-of select="format-number($normalisedDegrees, '0')"/>
  <xsl:value-of select="$degreesSymbol"/>
  <xsl:value-of select="format-number($normalisedMinutes, '00')"/>
  <xsl:value-of select="$minutesSymbol"/>
  <xsl:choose>
    <xsl:when test="$useSymbols = 'true'">
      <xsl:value-of select="format-number($normalisedSeconds, concat('00', $decPlFmt))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="translate(format-number($normalisedSeconds, concat('00', $decPlFmt)), '.', '')"/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:value-of select="$secondsSymbol"/>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********* Get all month patterns from specified format ********* -->
<!-- **************************************************************** -->
<xsl:template name="GetMonthPatterns">
  <xsl:param name="formatStr"/>
  <xsl:param name="timeStamp"/>
  <xsl:param name="startPos" select="1"/>

  <xsl:variable name="start">
    <xsl:call-template name="FindFirstChar">
      <xsl:with-param name="inStr" select="$formatStr"/>
      <xsl:with-param name="matchChar" select="'M'"/>
      <xsl:with-param name="startPos" select="$startPos"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="end">
    <xsl:call-template name="FindLastChar">
      <xsl:with-param name="inStr" select="$formatStr"/>
      <xsl:with-param name="matchChar" select="'M'"/>
      <xsl:with-param name="startPos" select="$start"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="($start != 0) and ($end != 0)">
    <xsl:element name="item" namespace="">
      <xsl:element name="startPos" namespace="">
        <xsl:value-of select="$start"/>
      </xsl:element>

      <xsl:element name="length" namespace="">
        <xsl:value-of select="$end - $start + 1"/>
      </xsl:element>

      <xsl:element name="string" namespace="">
        <xsl:call-template name="MonthString">
          <xsl:with-param name="timeStamp" select="$timeStamp"/>
          <xsl:with-param name="identifierLength" select="$end - $start + 1"/>
        </xsl:call-template>
      </xsl:element>
    </xsl:element>

    <xsl:call-template name="GetMonthPatterns">   <!-- Recurse function in case of another month definition -->
      <xsl:with-param name="formatStr" select="$formatStr"/>
      <xsl:with-param name="timeStamp" select="$timeStamp"/>
      <xsl:with-param name="startPos" select="$end + 1"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********** Get all day patterns from specified format ********** -->
<!-- **************************************************************** -->
<xsl:template name="GetDayPatterns">
  <xsl:param name="formatStr"/>
  <xsl:param name="timeStamp"/>
  <xsl:param name="startPos" select="1"/>

  <xsl:variable name="start">
    <xsl:call-template name="FindFirstChar">
      <xsl:with-param name="inStr" select="$formatStr"/>
      <xsl:with-param name="matchChar" select="'d'"/>
      <xsl:with-param name="startPos" select="$startPos"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="end">
    <xsl:call-template name="FindLastChar">
      <xsl:with-param name="inStr" select="$formatStr"/>
      <xsl:with-param name="matchChar" select="'d'"/>
      <xsl:with-param name="startPos" select="$start"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="($start != 0) and ($end != 0)">
    <xsl:element name="item" namespace="">
      <xsl:element name="startPos" namespace="">
        <xsl:value-of select="$start"/>
      </xsl:element>

      <xsl:element name="length" namespace="">
        <xsl:value-of select="$end - $start + 1"/>
      </xsl:element>

      <xsl:element name="string" namespace="">
        <xsl:call-template name="DayString">
          <xsl:with-param name="timeStamp" select="$timeStamp"/>
          <xsl:with-param name="identifierLength" select="$end - $start + 1"/>
        </xsl:call-template>
      </xsl:element>
    </xsl:element>

    <xsl:call-template name="GetDayPatterns">   <!-- Recurse function in case of another day definition -->
      <xsl:with-param name="formatStr" select="$formatStr"/>
      <xsl:with-param name="timeStamp" select="$timeStamp"/>
      <xsl:with-param name="startPos" select="$end + 1"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********** Get all year patterns from specified format ********* -->
<!-- **************************************************************** -->
<xsl:template name="GetYearPatterns">
  <xsl:param name="formatStr"/>
  <xsl:param name="timeStamp"/>
  <xsl:param name="startPos" select="1"/>

  <xsl:variable name="start">
    <xsl:call-template name="FindFirstChar">
      <xsl:with-param name="inStr" select="$formatStr"/>
      <xsl:with-param name="matchChar" select="'y'"/>
      <xsl:with-param name="startPos" select="$startPos"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="end">
    <xsl:call-template name="FindLastChar">
      <xsl:with-param name="inStr" select="$formatStr"/>
      <xsl:with-param name="matchChar" select="'y'"/>
      <xsl:with-param name="startPos" select="$start"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="($start != 0) and ($end != 0)">
    <xsl:element name="item" namespace="">
      <xsl:element name="startPos" namespace="">
        <xsl:value-of select="$start"/>
      </xsl:element>

      <xsl:element name="length" namespace="">
        <xsl:value-of select="$end - $start + 1"/>
      </xsl:element>

      <xsl:element name="string" namespace="">
        <xsl:call-template name="YearString">
          <xsl:with-param name="timeStamp" select="$timeStamp"/>
          <xsl:with-param name="identifierLength" select="$end - $start + 1"/>
        </xsl:call-template>
      </xsl:element>
    </xsl:element>

    <xsl:call-template name="GetYearPatterns">   <!-- Recurse function in case of another year definition -->
      <xsl:with-param name="formatStr" select="$formatStr"/>
      <xsl:with-param name="timeStamp" select="$timeStamp"/>
      <xsl:with-param name="startPos" select="$end + 1"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<!-- **************************************************************** -->
<!-- *********** Find first occurrence of char in string ************ -->
<!-- **************************************************************** -->
<xsl:template name="FindFirstChar">
  <xsl:param name="inStr"/>
  <xsl:param name="matchChar"/>
  <xsl:param name="startPos" select="1"/>

  <xsl:choose>
    <xsl:when test="$startPos &gt; string-length($inStr)">0</xsl:when>
    <xsl:when test="substring($inStr, $startPos, 1) = $matchChar">
      <xsl:value-of select="$startPos"/>
    </xsl:when>
    <xsl:otherwise>   <!-- Recurse function incrementing startPos -->
      <xsl:call-template name="FindFirstChar">
        <xsl:with-param name="inStr" select="$inStr"/>
        <xsl:with-param name="matchChar" select="$matchChar"/>
        <xsl:with-param name="startPos" select="$startPos + 1"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Find last occurrence of char in string ************ -->
<!-- **************************************************************** -->
<xsl:template name="FindLastChar">
  <xsl:param name="inStr"/>
  <xsl:param name="matchChar"/>
  <xsl:param name="startPos" select="1"/>

  <xsl:choose>
    <xsl:when test="$startPos &gt; string-length($inStr)">0</xsl:when>
    <xsl:when test="substring($inStr, $startPos, 1) = $matchChar">
      <xsl:choose>
        <xsl:when test="$startPos = string-length($inStr)">  <!-- At end of string and character matches -->
          <xsl:value-of select="$startPos"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="FindLastChar">   <!-- Recurse function incrementing startPos -->
            <xsl:with-param name="inStr" select="$inStr"/>
            <xsl:with-param name="matchChar" select="$matchChar"/>
            <xsl:with-param name="startPos" select="$startPos + 1"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>   <!-- Current char doesn't match $matchChar so return prior position -->
      <xsl:value-of select="$startPos - 1"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********** Format date according to specified format *********** -->
<!-- **************************************************************** -->
<xsl:template name="MonthString">
  <xsl:param name="timeStamp"/>    <!-- In time stamp format -->
  <xsl:param name="identifierLength"/>

  <xsl:choose>
    <xsl:when test="$identifierLength = 1">
      <xsl:variable name="month" select="substring($timeStamp, 6, 2)"/>
      <xsl:choose>
        <xsl:when test="number($month) &lt; 10">
          <xsl:value-of select="substring($month, 2, 1)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$month"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <xsl:when test="$identifierLength = 2">
      <xsl:value-of select="substring($timeStamp, 6, 2)"/>
    </xsl:when>

    <xsl:when test="$identifierLength = 3">
      <xsl:variable name="month" select="substring($timeStamp, 6, 2)"/>
      <xsl:choose>
        <xsl:when test="number($month) = 1">Jan</xsl:when>
        <xsl:when test="number($month) = 2">Feb</xsl:when>
        <xsl:when test="number($month) = 3">Mar</xsl:when>
        <xsl:when test="number($month) = 4">Apr</xsl:when>
        <xsl:when test="number($month) = 5">May</xsl:when>
        <xsl:when test="number($month) = 6">Jun</xsl:when>
        <xsl:when test="number($month) = 7">Jul</xsl:when>
        <xsl:when test="number($month) = 8">Aug</xsl:when>
        <xsl:when test="number($month) = 9">Sep</xsl:when>
        <xsl:when test="number($month) = 10">Oct</xsl:when>
        <xsl:when test="number($month) = 11">Nov</xsl:when>
        <xsl:when test="number($month) = 12">Dec</xsl:when>
      </xsl:choose>
    </xsl:when>

    <xsl:when test="$identifierLength = 4">
      <xsl:variable name="month" select="substring($timeStamp, 6, 2)"/>
      <xsl:choose>
        <xsl:when test="number($month) = 1">January</xsl:when>
        <xsl:when test="number($month) = 2">February</xsl:when>
        <xsl:when test="number($month) = 3">March</xsl:when>
        <xsl:when test="number($month) = 4">April</xsl:when>
        <xsl:when test="number($month) = 5">May</xsl:when>
        <xsl:when test="number($month) = 6">June</xsl:when>
        <xsl:when test="number($month) = 7">July</xsl:when>
        <xsl:when test="number($month) = 8">August</xsl:when>
        <xsl:when test="number($month) = 9">September</xsl:when>
        <xsl:when test="number($month) = 10">October</xsl:when>
        <xsl:when test="number($month) = 11">November</xsl:when>
        <xsl:when test="number($month) = 12">December</xsl:when>
      </xsl:choose>
    </xsl:when>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ********* Return the day according to specified format ********* -->
<!-- **************************************************************** -->
<xsl:template name="DayString">
  <xsl:param name="timeStamp"/>     <!-- In time stamp format -->
  <xsl:param name="identifierLength"/>

  <xsl:choose>
    <xsl:when test="$identifierLength = 1">
      <xsl:variable name="day" select="substring($timeStamp, 9, 2)"/>
      <xsl:choose>
        <xsl:when test="number($day) &lt; 10">
          <xsl:value-of select="substring($day, 2, 1)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$day"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <xsl:when test="$identifierLength = 2">
      <xsl:value-of select="substring($timeStamp, 9, 2)"/>
    </xsl:when>

    <xsl:when test="$identifierLength &gt; 2">
      <xsl:variable name="year" select="number(substring($timeStamp, 1, 4))"/>
      <xsl:variable name="month" select="number(substring($timeStamp, 6, 2))"/>
      <xsl:variable name="day" select="number(substring($timeStamp, 9, 2))"/>

      <!-- Get julian day -->
      <xsl:variable name="julianDay">
        <xsl:call-template name="DateToJulianDay">
          <xsl:with-param name="year" select="$year"/>
          <xsl:with-param name="month" select="$month"/>
          <xsl:with-param name="day" select="$day"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="dayOfWeek0" select="$julianDay mod 10227"/>
      <xsl:variable name="dayOfWeek" select="($dayOfWeek0 mod 7) + 1"/>

      <!-- Return as named day -->
      <xsl:choose>
        <xsl:when test="$dayOfWeek = 1">
          <xsl:choose>
            <xsl:when test="$identifierLength = 3">Mon</xsl:when>
            <xsl:otherwise>Monday</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$dayOfWeek = 2">
          <xsl:choose>
            <xsl:when test="$identifierLength = 3">Tue</xsl:when>
            <xsl:otherwise>Tuesday</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$dayOfWeek = 3">
          <xsl:choose>
            <xsl:when test="$identifierLength = 3">Wed</xsl:when>
            <xsl:otherwise>Wednesday</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$dayOfWeek = 4">
          <xsl:choose>
            <xsl:when test="$identifierLength = 3">Thu</xsl:when>
            <xsl:otherwise>Thursday</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$dayOfWeek = 5">
          <xsl:choose>
            <xsl:when test="$identifierLength = 3">Fri</xsl:when>
            <xsl:otherwise>Friday</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$dayOfWeek = 6">
          <xsl:choose>
            <xsl:when test="$identifierLength = 3">Sat</xsl:when>
            <xsl:otherwise>Saturday</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$dayOfWeek = 7">
          <xsl:choose>
            <xsl:when test="$identifierLength = 3">Sun</xsl:when>
            <xsl:otherwise>Sunday</xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </xsl:when>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ******** Return the year according to specified format ********* -->
<!-- **************************************************************** -->
<xsl:template name="YearString">
  <xsl:param name="timeStamp"/>     <!-- In time stamp format -->
  <xsl:param name="identifierLength"/>

  <xsl:choose>
    <xsl:when test="$identifierLength = 1">
      <xsl:variable name="year" select="substring($timeStamp, 3, 2)"/>
      <xsl:choose>
        <xsl:when test="number($year) &lt; 10">
          <xsl:value-of select="substring($year, 2, 1)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$year"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <xsl:when test="$identifierLength = 2">
      <xsl:value-of select="substring($timeStamp, 3, 2)"/>
    </xsl:when>

    <xsl:when test="$identifierLength &gt; 2">
      <xsl:value-of select="substring($timeStamp, 1, 4)"/>
    </xsl:when>
  </xsl:choose>
</xsl:template>


<!-- **************************************************************** -->
<!-- ************ Return the Julian day the given date ************** -->
<!-- **************************************************************** -->
<xsl:template name="DateToJulianDay">
  <xsl:param name="year"/>
  <xsl:param name="month"/>
  <xsl:param name="day"/>

  <xsl:variable name="j0" select="ceiling(($month - 14) div 12)"/>
  <xsl:variable name="j1" select="floor((1461 * ($year + 4800 + $j0)) div 4)"/>
  <xsl:variable name="j2" select="floor((367 * ($month - 2 - (12 * $j0))) div 12)"/>
  <xsl:variable name="j3" select="floor((3 * floor(($year + 4900 + $j0) div 100)) div 4)"/>

  <!-- final calc -->
  <xsl:value-of select="$j1 + $j2 - $j3 + $day - 32075"/>
</xsl:template>


</xsl:stylesheet>
