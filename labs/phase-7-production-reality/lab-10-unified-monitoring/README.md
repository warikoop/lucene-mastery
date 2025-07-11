# Lab 10: Unified Monitoring

## 🎯 **Objective**

This lab provides a single script to monitor the health and status of all three clusters (Elasticsearch, Solr, and OpenSearch) at once. This is a fundamental practice in a production environment where you need a consolidated view of your entire search infrastructure.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-7-production-reality/lab-10-unified-monitoring
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

The script will output a series of health checks, one for each platform. You will see the cluster status for Elasticsearch and OpenSearch, and the list of live nodes for Solr, providing a quick, unified overview of the entire learning environment's health.
