#!/bin/bash

curl -v "http://localhost:8085/ws/action.soap" -X POST -H "Content-Type: text/xml" --data-binary @- <<\
EOF
<SOAP-ENV:Envelope xmlns:xforms="http://www.w3.org/2002/xforms"
  xmlns:xtee="http://x-tee.riik.ee/xsd/xtee.xsd"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:xrd="http://x-road.eu/xsd/xroad.xsd"
  xmlns:xxforms="http://orbeon.org/oxf/xml/xforms"
  xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:exf="http://www.exforms.org/exf/1-0"
  xmlns:iden="http://x-road.eu/xsd/identifiers"
  xmlns:tns="http://producer.x-road.eu"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
  xmlns:events="http://www.w3.org/2001/xml-events">
  <SOAP-ENV:Header>
    <xrd:protocolVersion>4.0</xrd:protocolVersion>
    <xrd:id>c87e72c77f97581af1a7108b4f9d96b5e860a7f6</xrd:id>
    <xrd:userId>JP111111111</xrd:userId>
    <xrd:issue/>
    <xrd:service iden:objectType="SERVICE">
      <iden:xRoadInstance>JP-TEST</iden:xRoadInstance>
      <iden:memberClass>COM</iden:memberClass>
      <iden:memberCode>0170121212121</iden:memberCode>
      <iden:subsystemCode>SS</iden:subsystemCode>
      <iden:serviceCode>selectExample</iden:serviceCode>
      <iden:serviceVersion>v1</iden:serviceVersion>
    </xrd:service>
    <xrd:client iden:objectType="SUBSYSTEM">
      <iden:xRoadInstance>JP-TEST</iden:xRoadInstance>
      <iden:memberClass>COM</iden:memberClass>
      <iden:memberCode>0170121212121</iden:memberCode>
      <iden:subsystemCode>misp2</iden:subsystemCode>
    </xrd:client>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <ns5:selectExample xmlns:ns5="http://producer.x-road.eu">
      <id>1</id>
    </ns5:selectExample>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
