# Lab 6: High-Query Throughput Performance

## 🎯 **Objective**

This lab tests how the Elasticsearch, Solr, and OpenSearch clusters perform under a high-query throughput load. You will use the concurrent load tester to send a high rate of search queries to each platform and analyze the impact on query latency and system resources.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-4-performance-production/lab-6-high-query-throughput
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

The script will run the concurrent load tester with a high query rate (50 queries/sec) and no indexing. The output will be a performance report focused on read throughput. You should compare these results to the baseline from Lab 4 to understand how a heavy read load affects each system's query performance.
