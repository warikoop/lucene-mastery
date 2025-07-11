#!/bin/bash

# Lab 8: Node Failure and Recovery
# This script simulates node failures to demonstrate cluster fault tolerance.

# --- Elasticsearch Node Failure Simulation ---
echo "--- Simulating Elasticsearch Node Failure ---"

# Stop one Elasticsearch node
echo "Stopping es-master-2..."
docker stop es-master-2

# Wait for the cluster to react
sleep 10

# Check cluster health (should be yellow)
echo "\nChecking cluster health (expecting yellow status):"
curl -s "http://localhost:9199/_cluster/health?pretty"

# Restart the node
echo "\nRestarting es-master-2..."
docker start es-master-2

# Wait for recovery
echo "Waiting 30 seconds for recovery..."
sleep 30

# Check cluster health again (should be green)
echo "\nChecking cluster health (expecting green status):"
curl -s "http://localhost:9199/_cluster/health?pretty"


# --- Solr Node Failure Simulation ---
echo "\n--- Simulating Solr Node Failure ---"

# Stop one Solr node
echo "Stopping solr2..."
docker stop solr2

# Wait for the cluster to react
sleep 10

# Check cluster status (should show one less live node)
echo "\nChecking cluster status (expecting 2 live nodes):"
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes

# Restart the node
echo "\nRestarting solr2..."
docker start solr2

# Wait for recovery
echo "Waiting 30 seconds for recovery..."
sleep 30

# Check cluster status again (should show all 3 live nodes)
echo "\nChecking cluster status (expecting 3 live nodes):"
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes

echo "\n✅ Lab 8 Complete: Node failure and recovery demonstrated."
