# Lab 5: High-Volume Indexing Performance

## 🎯 **Objective**

This lab tests how the Elasticsearch, Solr, and OpenSearch clusters perform under a high-volume indexing load. You will use the concurrent load tester to send a high rate of documents to each platform and analyze the impact on indexing latency and system resources.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-4-performance-production/lab-5-high-volume-indexing
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

The script will run the concurrent load tester with a high indexing rate (50 docs/sec) and no querying. The output will be a performance report focused on write throughput. You should compare these results to the baseline from Lab 4 to understand how a heavy write load affects each system.
