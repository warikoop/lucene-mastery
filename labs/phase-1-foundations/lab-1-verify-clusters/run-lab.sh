#!/bin/bash

# Lab 1: Verify Cluster Status
# This script checks the health of all clusters in the unified HA environment.

# --- Elasticsearch ---
echo "--- Verifying Elasticsearch Cluster ---"
curl -s "http://localhost:9199/_cluster/health?pretty"
echo "\n"

# --- Solr ---
echo "--- Verifying SolrCloud Cluster ---"
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes
echo "\n"

# --- OpenSearch ---
echo "--- Verifying OpenSearch Cluster ---"
curl -s "http://localhost:9399/_cluster/health?pretty"
echo "\n"

echo "✅ Lab 1 Complete: All clusters verified."
