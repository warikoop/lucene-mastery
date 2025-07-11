# Lab 1: Verify Cluster Status

## 🎯 **Objective**

This lab verifies that the unified HA environment is running correctly. You will check the health and status of the Elasticsearch, Solr, and OpenSearch clusters using their HA endpoints.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-1-foundations/lab-1-verify-clusters
    ```

2.  **Make the script executable:**
    ```bash
    chmod +x run-lab.sh
    ```

3.  **Execute the lab script:**
    ```bash
    ./run-lab.sh
    ```

## ✅ **Expected Outcome**

The script will output the health status for each cluster. You should see a "green" status for Elasticsearch and OpenSearch, and a list of live nodes for Solr, confirming that the HA environment is fully operational.
