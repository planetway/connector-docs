CONNEQT Connector Proxy
=======================

CONNEQT Connector is a software solution to create REST JSON APIs or SOAP services from relational database SQL queries.

CONNEQT Connector consists of 3 components.

```
                           HTTP Client                                  Browser

                           |        ^                                  |       ^
                           |        |                                  |       |
                           |        |                                  |       |
                           |        | HTTP Client calls                |       | Administrator interacts with Admin UI
                           |        | REST JSON APIs or                |       | to generate the services configuration file
                           |        | SOAP services                    |       |
                           |        |                           +------v-------+------+
                           |        |                           |                     |
                           |        |                           | Connector Admin UI  |
                           |        |                           |                     |
                           |        |      Admin optionally     +------+-------^------+
                           |        |      accesses Proxy's actuator   |       |
                           |        |      to restart Proxy and        |       |  Admin UI calls Admin API
                           |        |      read Proxy's configuration. |       |
                      +----v--------+----+                      +------v-------+------+
                      |                  <- - - - - - - - - - - +                     |
                      | Connector Proxy  |                      | Connector Admin API |
                      |                  +- - - - - - - - - - - >                     |
                      +-----+---^---^----+                      +--+---^---+----------+
                            |   |   |                              |   |   |
Proxy connects to RDB,      |   |   |                              |   |   |
sends queries, fetches data,|   |   | Proxy reads the              |   |   |
and converts to             |   |   | services configuration       |   |   | 
HTTP responses              |   |   | file                         |   |   | 
                            |   |   |                              |   |   | 
                            |   |   |                              |   |   | 
                            |   |   +------------------------+     |   |   |
                            |   |                            |     |   |   |
                            |   |        +-------------------------+   |   |  Admin API connects to RDB,
                            |   |        |                   |         |   |  sends queries, fetches data,
                            |   |        |   +-------------------------+   |  and writes the services configuration file
                            |   |        |   |               |             |
                            |   |        |   |               |             |
                         +--v---+--------v---+--+         +--+-------------v------------+
                         |                      |         |                             |
                         | Relational Databases |         | Services Configuration File |
                         |                      |         |                             |
                         +----------------------+         +-----------------------------+
```

## Connector Components

### Connector Admin UI [conneqt/connector-admin-ui](https://hub.docker.com/r/conneqt/connector-admin-ui)

Connector Admin UI is the web site frontend of Connector Admin API that provides the interface to administrators.  
Please visit [conneqt/connector-admin-ui](https://hub.docker.com/r/conneqt/connector-admin-ui) for details.

### Connector Admin API [conneqt/connector-admin-api](https://hub.docker.com/r/conneqt/connector-admin-api)

Connector Admin API is the web site backend that provides APIs to Connector Admin UI.  
Please visit [conneqt/connector-admin-api](https://hub.docker.com/r/conneqt/connector-admin-api) for details.

### Connector Proxy

Connector Proxy is a HTTP server that provides REST JSON APIs and SOAP services to HTTP clients.  
Connector Proxy reads a services configuration file which Connector Admin API generates, to determine it's behavior.

## Connector Proxy Features

Connector Proxy has following features.

* Connects to MySQL, PostgreSQL, Oracle database, IBM DB2, MSSQL and SQLite
* Generates and serves REST JSON APIs and SOAP services from a "Services configuration file", which includes database endpoints, credentials, SQL queries and parameters
* Provides OpenAPI v3 and WSDL documents that describe the REST JSON APIs and SOAP services
* X-Road support

## How to use Connector Proxy?

Here's an example setup of Connector Proxy, using docker-compose.  
Create a file docker-compose.yml with following content.

```
version: "3.7"
services:
  proxy:
    image: conneqt/connector-proxy
    ports:
      - 8085:8085
    volumes:
      - "./services.json:/etc/conneqt/connector/services.json"

  mysql:
    image: mysql
    environment:
      MYSQL_USER: user
      MYSQL_PASSWORD: password
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: connector
    volumes:
      - ./0_create.sql:/docker-entrypoint-initdb.d/0_create.sql
    ports:
      - 3306:3306
```

Create a file services.json in the same directory as the docker-compose.yml as follows.

```
{
  "name": "connector",
  "dbSources": [
    {
      "id": "f94b0ecd-4cae-42d9-a701-806bd2fb484e",
      "displayName": "mysql database",
      "databaseType": "MYSQL",
      "databaseName": "connector",
      "host": "mysql",
      "port": 3306,
      "username": "user",
      "password": "password",
      "minimumIdle": 600,
      "idleTimeout": 600,
      "maximumPoolSize": 10,
      "dbServices": [
        {
          "id": "d81696e2-8dc4-4de4-9618-dde1d8edd9d1",
          "name": "selectExample",
          "status": "VALID",
          "sqlTemplate": "SELECT * FROM example WHERE id = :id",
          "params": [
            {
              "name": "id",
              "type": "STRING"
            }
          ]
        }
      ]
    }
  ]
}
```

and a 0_create.sql file in the same directory as follows.

```
CREATE TABLE example (
  id BIGINT NOT NULL AUTO_INCREMENT,
  col_1 VARCHAR(255),
  col_2 VARCHAR(255),
  PRIMARY KEY (id)
);

INSERT INTO example (id, col_1, col_2) VALUES (1, 'col_1_row_1', 'col_2_row_1');
```

After you run `docker-compose up`, these files will do:

1. MySQL to create a database named `connector`, create a table `example` and insert a row
1. Connector Proxy to connect to MySQL and create a `selectExample` "service".

Let's try it out using curl.

```
% curl "http://localhost:8085/api/service/selectExample" -X POST -H "Content-Type: application/json" -d '{"id":1}' | jq .
{
  "rows": [
    {
      "id": 1,
      "col_1": "col_1_row_1",
      "col_2": "col_2_row_1"
    }
  ]
}
```

An OpenAPIv3 document is also available for all of the services Connector Proxy serves, as follows.

```
% curl "http://localhost:8085/api/openapi.json"
{"openapi":"3.0.1","info":{"title":"Connector openapi document.","version":"v1"},"servers":[{"url":"http://localhost:8085/api/service"}],"paths":{"/selectExample":{"post":{"operationId":"selectExample","requestBody":{"content":{"application/json;charset=UTF-8":{"schema":{"$ref":"#/components/schemas/selectExample"}}}},"responses":{"200":{"description":"Service ok response.","content":{"application/json;charset=UTF-8":{"schema":{"$ref":"#/components/schemas/selectExampleResponse"}}}}}}}},"components":{"schemas":{"selectExample":{"type":"object","properties":{"id":{"type":"string"}}},"selectExampleResponse":{"type":"object","properties":{"rows":{"type":"array","items":{"$ref":"#/components/schemas/selectExampleRow"}}}},"selectExampleRow":{"type":"object","properties":{"col_2":{"type":"string","nullable":true},"col_1":{"type":"string","nullable":true},"id":{"type":"integer","format":"int64","nullable":true}}}}}}
```

The WSDL document is available as follows.

```
% curl "http://localhost:8085/wsdl/services.wsdl"
<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:tns="http://producer.x-road.eu" xmlns:xrd="http://x-road.eu/xsd/xroad.xsd" xmlns:px="http://xsd.planetcross.net/planetcross.xsd" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:ref="http://ws-i.org/profiles/basic/1.1/xsd" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" targetNamespace="http://producer.x-road.eu"><wsdl:types><schema xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="http://producer.x-road.eu"><import namespace="http://x-road.eu/xsd/xroad.xsd" schemaLocation="http://x-road.eu/xsd/xroad.xsd"/><import namespace="http://xsd.planetcross.net/planetcross.xsd" schemaLocation="http://xsd.planetcross.net/planetcross.xsd"/><xs:element name="selectExample"><xs:complexType><xs:sequence><xs:element name="id" type="xs:string"/></xs:sequence></xs:complexType></xs:element><xs:element name="selectExampleResponse"><xs:complexType><xs:sequence><xs:element name="row" maxOccurs="unbounded"><xs:complexType><xs:sequence><xs:element name="id" minOccurs="0" type="xs:long"/><xs:element name="col_1" minOccurs="0" type="xs:string"/><xs:element name="col_2" minOccurs="0" type="xs:string"/></xs:sequence></xs:complexType></xs:element></xs:sequence></xs:complexType></xs:element></schema></wsdl:types><wsdl:portType name="connector"><wsdl:operation name="selectExample"><wsdl:input name="selectExample" message="tns:selectExample"/><wsdl:output name="selectExampleResponse" message="tns:selectExampleResponse"/></wsdl:operation></wsdl:portType><wsdl:binding name="connectorHTTP" type="tns:connector"><soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/><wsdl:operation name="selectExample"><soap:operation soapAction="" style="document"/><xrd:version>v1</xrd:version><wsdl:input name="selectExample"><soap:body use="literal"/><soap:header use="literal" message="tns:requestHeader" part="client"/><soap:header use="literal" message="tns:requestHeader" part="service"/><soap:header use="literal" message="tns:requestHeader" part="id"/><soap:header use="literal" message="tns:requestHeader" part="userId"/><soap:header use="literal" message="tns:requestHeader" part="targetUserId"/><soap:header use="literal" message="tns:requestHeader" part="issue"/><soap:header use="literal" message="tns:requestHeader" part="protocolVersion"/></wsdl:input><wsdl:output name="selectExampleResponse"><soap:body use="literal"/><soap:header use="literal" message="tns:requestHeader" part="client"/><soap:header use="literal" message="tns:requestHeader" part="service"/><soap:header use="literal" message="tns:requestHeader" part="id"/><soap:header use="literal" message="tns:requestHeader" part="userId"/><soap:header use="literal" message="tns:requestHeader" part="targetUserId"/><soap:header use="literal" message="tns:requestHeader" part="issue"/><soap:header use="literal" message="tns:requestHeader" part="protocolVersion"/></wsdl:output></wsdl:operation></wsdl:binding><wsdl:message name="requestHeader"><wsdl:part name="client" element="xrd:client"/><wsdl:part name="service" element="xrd:service"/><wsdl:part name="id" element="xrd:id"/><wsdl:part name="userId" element="xrd:userId"/><wsdl:part name="targetUserId" element="px:targetUserId"/><wsdl:part name="issue" element="xrd:issue"/><wsdl:part name="protocolVersion" element="xrd:protocolVersion"/></wsdl:message><wsdl:message name="selectExample"><wsdl:part name="selectExample" element="tns:selectExample"/></wsdl:message><wsdl:message name="selectExampleResponse"><wsdl:part name="selectExampleResponse" element="tns:selectExampleResponse"/></wsdl:message><wsdl:service name="connector"><wsdl:port name="connectorHTTP" binding="tns:connectorHTTP"><soap:address location="http://localhost:8085/ws/action.soap"/></wsdl:port></wsdl:service></wsdl:definitions>
```

Call the SOAP service as follows.

```
% curl "http://localhost:8085/ws/action.soap" -X POST -H "Content-Type: text/xml" --data-binary @- <<\
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
<?xml version='1.0' encoding='UTF-8'?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:px="http://xsd.planetcross.net/planetcross.xsd" xmlns:xro="http://x-road.eu/xsd/xroad.xsd" xmlns:iden="http://x-road.eu/xsd/identifiers" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ns5="http://producer.x-road.eu"><SOAP-ENV:Header><xro:id>c87e72c77f97581af1a7108b4f9d96b5e860a7f6</xro:id><xro:protocolVersion>4.0</xro:protocolVersion><xro:userId>JP111111111</xro:userId><xro:service iden:objectType="SERVICE"><iden:xRoadInstance>JP-TEST</iden:xRoadInstance><iden:memberClass>COM</iden:memberClass><iden:memberCode>0170121212121</iden:memberCode><iden:subsystemCode>SS</iden:subsystemCode><iden:serviceCode>selectExample</iden:serviceCode><iden:serviceVersion>v1</iden:serviceVersion></xro:service><xro:client iden:objectType="SUBSYSTEM"><iden:xRoadInstance>JP-TEST</iden:xRoadInstance><iden:memberClass>COM</iden:memberClass><iden:memberCode>0170121212121</iden:memberCode><iden:subsystemCode>misp2</iden:subsystemCode></xro:client></SOAP-ENV:Header><SOAP-ENV:Body><ns5:selectExampleResponse><row><id type="xs:long">1</id><col_1 type="xs:string">col_1_row_1</col_1><col_2 type="xs:string">col_2_row_1</col_2></row></ns5:selectExampleResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
```

## Configuration

Connector Proxy can be configured using following files.  
To provide the files to the Docker container, you can mount from host, use Docker volume or build a new image from Connector Proxy image and COPY the configuration file in the image.

#### Services Configuration File

Services configuration file is generated by Connector Admin API, and Connector Proxy consumes it.  
Path of the services configuration file is set in the proxy configuration file, and is by default `/etc/conneqt/connector/services.json`.  
The services configuration file contains enough information for Proxy to be able to create REST and SOAP services.

#### Logging

Logging is done using logback.
Configure logging by overriding a file at `/etc/conneqt/connector/proxy-logback.xml`.

The default proxy-logback.xml looks like this.

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <contextName>Connector Proxy</contextName>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder">
            <layout class="ch.qos.logback.contrib.json.classic.JsonLayout">
                <timestampFormat>yyyy-MM-dd'T'HH:mm:ss.SSSX</timestampFormat>
                <timestampFormatTimezoneId>Etc/UTC</timestampFormatTimezoneId>
                <jsonFormatter class="ch.qos.logback.contrib.jackson.JacksonJsonFormatter" />
                <appendLineSeparator>true</appendLineSeparator>
            </layout>
        </encoder>
    </appender>

    <logger name="com.planetway" level="INFO"/>
    <logger name="org.springframework.web.filter.CommonsRequestLoggingFilter" level="INFO"/>
    <logger name="org.springframework.web" level="WARN"/>
    <logger name="org.springframework.security" level="WARN"/>

    <root level="INFO">
        <appender-ref ref="STDOUT"/>
    </root>
    <logger name="SQL" level="ALL" additivity="FALSE">
        <appender-ref ref="STDOUT"/>
    </logger>
    <logger name="SOAP_ALL" level="ALL" additivity="FALSE">
        <appender-ref ref="STDOUT"/>
    </logger>
    <logger name="SOAP_HEADER" level="ALL" additivity="FALSE">
        <appender-ref ref="STDOUT"/>
    </logger>
    <logger name="HTTP_ACCESS" level="ALL" additivity="FALSE">
        <appender-ref ref="STDOUT"/>
    </logger>
</configuration>
```

## How to ...

### Use HTTPS

To use HTTPS between the HTTP client and Connector Proxy, insert a HTTPS reverse proxy server like nginx.

An example docker-compose.yml setup using nginx can look like following.

```
version: "3.7"
services:
  proxy:
    image: conneqt/connector-proxy
    ports:
      - 8085:8085
    volumes:
      - "./services.json:/etc/conneqt/connector/services.json"

  mysql:
    image: mysql
    environment:
      MYSQL_USER: user
      MYSQL_PASSWORD: password
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: connector
    volumes:
      - ./0_create.sql:/docker-entrypoint-initdb.d/0_create.sql
    ports:
      - 3306:3306

  nginx:
    build: ./nginx
    ports:
      - "8443:443"
    environment:
      CONNECTOR_PROXY_HOST: proxy
      CONNECTOR_PROXY_PORT: 8085
    depends_on:
      - proxy
```

And files in ./nginx directory.

```
.
├── Dockerfile
├── docker-entrypoint.d
│   └── 99-generate-ssl-certificates.sh
├── nginx.conf
└── nginx.default.conf.template
```

Dockerfile

```
FROM nginx:stable-alpine

RUN apk --update upgrade && \
    apk add openssl && \
    rm -rf /var/cache/apk/*

COPY nginx.conf   /etc/nginx/nginx.conf
COPY nginx.default.conf.template /etc/nginx/templates/default.conf.template

COPY docker-entrypoint.d/* /docker-entrypoint.d/
```

nginx.conf

```
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format main '[$time_local] $remote_addr $remote_user "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" $upstream_addr $upstream_response_time';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
    include /etc/nginx/conf.d/*.conf;
}
```

nginx.default.conf.template

```
gzip on;
gzip_proxied any;
gzip_types text/plain text/css application/javascript application/json;
gzip_min_length 1000;

server {
  listen 80;
  server_name _;
  location / {
    return 301 https://$host$request_uri;
  }
}

server {
  listen 443 ssl;
  server_name  _;

  ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
  ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256;
  ssl_prefer_server_ciphers on;
  ssl_session_timeout  10m;
  ssl_session_cache shared:SSL:10m;
  add_header Strict-Transport-Security "max-age=63072000;includeSubDomains;preload" always;
  client_max_body_size 500m;

  location / {
    proxy_pass http://${CONNECTOR_PROXY_HOST}:${CONNECTOR_PROXY_PORT};
    proxy_read_timeout 300s;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

docker-entrypoint.d/99-generate-ssl-certificates.sh

```
#!/bin/ash

set -e

ipaddr=`ip addr | grep 'scope global' | tr '/' ' ' | awk '{print $2}'`
answers() {
  echo --
  echo SomeState
  echo SomeCity
  echo SomeOrganization
  echo SomeOrganizationalUnit
  echo $ipaddr
  echo root@$ipaddr
}

create_snakeoil() {
  echo "Generating temporary snakeoil certificates for Conneqt Connector v5 Proxy"
  mkdir -p /etc/ssl/private/
  answers | /usr/bin/openssl req -newkey rsa:2048 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -nodes -x509 -days 365 -out /etc/ssl/certs/ssl-cert-snakeoil.pem 2> /dev/null
}

if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ] || [ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]; then
  create_snakeoil
else
  echo "Snakeoil certificate exists"
fi
```

This setup will create a self issued certificate for nginx, and configure nginx to proxy to Connector Proxy. You might also want to use client certificate based authentication when the HTTP client is a X-Road Security Server.

### Use in Production

For production use, please contact [Technical support](#technical-support)

## Technical Support

Contact us for technical support.

* Using this Form https://planetway.com/contact/
* In Conneqt Community https://join.slack.com/t/conneqt-community/shared_invite/zt-ng88s0jn-UiXAIJz~XBxIn1xaF8pFNw

## License, Terms of Use

By downloading the Docker image, you represent that you have read, understood and agreed to be bound by the [Secure DX CONNEQT 利用規約](https://secure-dx.biz/terms.html).

The files in this repository are licensed under [MIT License](LICENSE).
