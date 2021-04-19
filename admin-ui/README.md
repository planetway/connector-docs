CONNEQT Connector Admin UI
==========================

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

### Connector Admin API [conneqt/connector-admin-api](https://hub.docker.com/r/conneqt/connector-admin-api)

Connector Admin API is the web site backend that provides APIs to Connector Admin UI.  
Please visit [conneqt/connector-admin-api](https://hub.docker.com/r/conneqt/connector-admin-api) for details.

### Connector Admin UI [conneqt/connector-admin-ui](https://hub.docker.com/r/conneqt/connector-admin-ui)

Connector Admin UI is the web site frontend of Connector Admin API that provides the interface to administrators.  

## How to use Connector Admin UI?

Connector Admin UI is used together with Connector Admin API [conneqt/connector-admin-api](https://hub.docker.com/r/conneqt/connector-admin-api).
Please see [Connector Admin API documents](https://hub.docker.com/r/conneqt/connector-admin-api) for details.
