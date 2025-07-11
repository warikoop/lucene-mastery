#!/bin/bash

# Lab 10: Unified Monitoring
# This script provides a consolidated health check for all clusters.

echo "--- Unified Cluster Health Monitoring ---"

# --- Elasticsearch ---
echo "\n--- Elasticsearch Cluster Status ---"
curl -s "http://localhost:9199/_cluster/health?pretty"

# --- Solr ---
echo "\n--- SolrCloud Cluster Status ---"
echo "Live Nodes:"
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes

# --- OpenSearch ---
echo "\n--- OpenSearch Cluster Status ---"
curl -s "http://localhost:9399/_cluster/health?pretty"


echo "\n✅ Lab 10 Complete: Unified monitoring check performed."
