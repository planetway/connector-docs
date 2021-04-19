CONNEQT Connector Admin API
===========================

CONNEQT Connector is a software solution to create REST JSON APIs or SOAP services from relational databases.

CONNEQT Connector consists of 3 components.

```
                           HTTP Client                                  Browser

                           |        ^                                  |       ^
                           |        |                                  |       |
                           |        |                                  |       |
                           |        | HTTP Client calls                |       | Administrator interacts with Admin UI
                           |        | REST JSON APIs or                |       | to generate the services configuration file
                           |        | SOAP services                    |       |
                      +----v--------+----+                      +------v-------+------+
                      |                  |                      |                     |
                      | Connector Proxy  |                      | Connector Admin UI  |
                      |                  |                      |                     |
                      +-----+---^---^----+                      +------+-------^------+
                            |   |   |                                  |       |
Proxy connects to RDB,      |   |   |                                  |       | Admin UI calls Admin API
sends queries, fetches data,|   |   | Proxy reads the                  |       |
and converts to             |   |   | services configuration    +------v-------+------+
HTTP responses              |   |   | file                      |                     |
                            |   |   |                           | Connector Admin API |
                            |   |   |                           |                     |
                            |   |   +------------------------+  +--+---^---+----------+
                            |   |                            |     |   |   |
                            |   |        +-------------------+-----+   |   |  Admin API connects to RDB,
                            |   |        |                   |         |   |  sends queries, fetches data,
                            |   |        |   +---------------+---------+   |  and writes the services configuration file
                            |   |        |   |               |             |
                            |   |        |   |               |             |
                         +--v---+--------v---+--+         +--+-------------v------------+
                         |                      |         |                             |
                         | Relational Databases |         | Services Configuration File |
                         |                      |         |                             |
                         +----------------------+         +-----------------------------+
```

## Connector Components

### Connector Proxy [conneqt/connector-proxy](https://hub.docker.com/r/conneqt/connector-proxy)

Connector Proxy is a HTTP server that provides REST JSON APIs and SOAP services to HTTP clients.  
Connector Proxy reads a services configuration file which Connector Admin API generates, to determine it's behavior.  
Please visit [conneqt/connector-proxy](https://hub.docker.com/r/conneqt/connector-proxy) for details.

### Connector Admin UI [conneqt/connector-admin-ui](https://hub.docker.com/r/conneqt/connector-admin-ui)

Connector Admin UI is the web site frontend of Connector Admin API that provides the interface to administrators.  
Please visit [conneqt/connector-admin-ui](https://hub.docker.com/r/conneqt/connector-admin-ui) for details.

### Connector Admin API [conneqt/connector-admin-api](https://hub.docker.com/r/conneqt/connector-admin-api)

Connector Admin API is the web site backend that provides APIs to Connector Admin UI.  

## Connector Admin Features

Connector Admin consists of the API backend and UI.  
Connector Admin has following features.

* Connects to MySQL, PostgreSQL, Oracle database, IBM DB2, MSSQL and SQLite.
* Depending on the user input in Admin UI, Admin API generates a "Services configuration file", which is read by Connector Proxy.
* User enters the database endpoints, credentials and necessary configuration, SQLs that takes arguments in the Admin UI, which is saved into the services configuration file.

## How to use Connector Admin?

Here's an example setup of Connector Admin, using docker-compose.  
Create a file docker-compose.yml with following content.

```
version: "3.7"
services:
  admin-api:
    image: conneqt/connector-admin-api
    environment:
      CONNECTOR_ADMIN_USERNAME: admin
      CONNECTOR_ADMIN_PASSWORD: password
    ports:
      - 8082:8082
    volumes:
      - "./services.json:/etc/conneqt/connector/services.json"

  admin-ui:
    image: conneqt/connector-admin-ui
    environment:
      CONNECTOR_ADMIN_API_HOST: admin-api
      CONNECTOR_ADMIN_API_PORT: 8082
    ports:
      - 8443:443
    depends_on:
      - admin-api

  mysql:
    image: mysql
    environment:
      MYSQL_USER: user
      MYSQL_PASSWORD: password
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: connector
    volumes:
      - ./0_create.sql:/docker-entrypoint-initdb.d/0_create.sql
      - ./mysql:/var/lib/mysql
    ports:
      - 3306:3306
```

Launch the Docker containers and open the Admin UI in a modern browser.

```
% docker-compose up
% open https://localhost:8443/
```

### Login

![login](https://github.com/planetway/connector-docs/raw/master/admin-api/login.png)

Use the username and password set in `CONNECTOR_ADMIN_USERNAME` and `CONNECTOR_ADMIN_PASSWORD` environment variables to login.

![dashboard](https://github.com/planetway/connector-docs/raw/master/admin-api/empty-dashboard.png)

You'll see the empty dashboard.

### Create a Data Source

Create a "Data Source". A data source represents a relational database.  
Click the "+ New Data Source" button on top to add a data source.

![new data source](https://github.com/planetway/connector-docs/raw/master/admin-api/add-data-source.png)

### Create a Service

Create a "Service". A service represents an API endpoint. A data source can have multiple services.  
Enter a alpha-numeric name in the "Service Name" field and choose the data source you created.

Enter a SQL query. SQL queries can have parameters, prefixed with a ":", as seen in the screenshot.  

![add service](https://github.com/planetway/connector-docs/raw/master/admin-api/add-service.png)

Given a SQL query `SELECT * FROM example WHERE id = :id`, Connector creates a service that accepts a request parameter "id" and responds with all the columns' values that the SQL returns.

Click "Test query" and "Save", to update the services configuration file.

This creates a yml file `/etc/conneqt/connector/services.json` which will be then used by [conneqt/connector-proxy](https://hub.docker.com/r/conneqt/connector-proxy) to provide the APIs.

The services configuration file for this example SQL and MySQL database looks like this.

```
{
  "name" : "All",
  "dbSources" : [ {
    "id" : "d2483e4e-8d3f-4b2e-9478-78ae4efd270a",
    "displayName" : "mysql",
    "databaseType" : "MYSQL",
    "databaseName" : "connector",
    "host" : "mysql",
    "port" : 3306,
    "username" : "user",
    "password" : "password",
    "dbServices" : [ {
      "id" : "634ae3ad-93ff-463f-9e17-3d7ef0062b12",
      "name" : "selectExample",
      "sqlTemplate" : "SELECT * FROM example WHERE id = :id",
      "status" : "VALID",
      "params" : [ {
        "name" : "id",
        "type" : "STRING"
      } ],
      "result" : [ {
        "name" : "id",
        "xsdType" : "LONG",
        "oasType" : "INT64"
      }, {
        "name" : "col_1",
        "xsdType" : "STRING",
        "oasType" : "STRING"
      }, {
        "name" : "col_2",
        "xsdType" : "STRING",
        "oasType" : "STRING"
      } ],
      "queryTimeout" : 5
    } ],
    "maximumPoolSize" : null,
    "minimumIdle" : null,
    "idleTimeout" : null,
    "maxLifetime" : null,
    "connectionTimeout" : null,
    "params" : null,
    "jdbcUrl" : ""
  } ]
}
```

## Configuration

Connector Admin API can be configured using following environment variables.

* `CONNECTOR_ADMIN_USERNAME` and `CONNECTOR_ADMIN_PASSWORD` are used to provide the credentials to login from the Admin UI.

### Logging

Logging is done using logback.
Configure logging by overriding a file at `/etc/conneqt/connector/admin-logback.xml`.

The default admin-logback.xml looks like this.

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <contextName>Connector Admin</contextName>
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

    <root level="INFO">
      <appender-ref ref="STDOUT"/>
    </root>
</configuration>
```

## How to ...

### Use in Production

For production use, please contact [Technical support](#technical-support)

## Technical Support

Contact us for technical support.

* Using this Form https://planetway.com/contact/
* In Conneqt Community https://join.slack.com/t/conneqt-community/shared_invite/zt-ng88s0jn-UiXAIJz~XBxIn1xaF8pFNw

## License, Terms of Use

By downloading the Docker image, you represent that you have read, understood and agreed to be bound by the [Secure DX CONNEQT 利用規約](https://secure-dx.biz/terms.html).

The files in this repository are licensed under [MIT License](LICENSE).
