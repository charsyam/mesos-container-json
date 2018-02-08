#!/bin/bash
curl -X POST -H "Content-Type: application/json" http://172.31.1.11:8080/v2/apps -d @$1
