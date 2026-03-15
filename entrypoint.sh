#!/bin/bash
set -e

echo "=========================================="
echo "    OpenCB Stack - Initialization"
echo "=========================================="

OPENCGA_HOME=${OPENCGA_HOME:-/opt/opencga}

echo "[$(date)] Waiting for MongoDB..."
for i in {1..30}; do
  if nc -z mongodb 27017 2>/dev/null; then
    echo "[$(date)] MongoDB is ready"
    break
  fi
  echo "[$(date)] MongoDB not ready (attempt $i/30), waiting..."
  sleep 2
done

echo "[$(date)] Waiting for OpenSearch..."
for i in {1..30}; do
  if curl -s http://opensearch:9200 >/dev/null 2>&1; then
    echo "[$(date)] OpenSearch is ready"
    break
  fi
  echo "[$(date)] OpenSearch not ready (attempt $i/30), waiting..."
  sleep 2
done

echo "[$(date)] Initializing OpenCGA..."
mkdir -p ${OPENCGA_HOME}/logs

echo "[$(date)] Starting OpenCGA REST server..."
cd ${OPENCGA_HOME}
exec ./bin/opencga.sh server rest --rest-port 8080
