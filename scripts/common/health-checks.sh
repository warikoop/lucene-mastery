#!/bin/bash

# health-checks.sh
# A unified script to check the health of all clusters in the learning environment.

echo "--- 🩺 Running Unified Health Checks ---"

# --- Elasticsearch ---
echo "\n--- Elasticsearch Cluster Status ---"
curl -s "http://localhost:9199/_cluster/health?pretty"
if [ $? -ne 0 ]; then
    echo "Error: Could not connect to Elasticsearch on port 9199."
fi

# --- Solr ---
echo "\n--- SolrCloud Cluster Status ---"
echo "Live Nodes:"
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes
if [ $? -ne 0 ]; then
    echo "Error: Could not connect to Solr on port 8999. Is jq installed?"
fi

# --- OpenSearch ---
echo "\n--- OpenSearch Cluster Status ---"
curl -s "http://localhost:9399/_cluster/health?pretty"
if [ $? -ne 0 ]; then
    echo "Error: Could not connect to OpenSearch on port 9399."
fi

echo "\n--- ✅ Health Checks Complete ---"
