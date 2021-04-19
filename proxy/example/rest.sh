#!/bin/bash

curl -v "http://localhost:8085/api/service/selectExample" -X POST -H "Content-Type: application/json" -d '{"id":1}'
