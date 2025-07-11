# Lab 4: Baseline Performance Measurement

## 🎯 **Objective**

This lab establishes a baseline performance measurement for the Elasticsearch, Solr, and OpenSearch clusters. You will use the Go-based concurrent load tester to apply a default level of indexing and query load, and record the results as a baseline for future performance comparisons.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-4-performance-production/lab-4-baseline-performance
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

The script will run the concurrent load tester for 60 seconds with a default load (10 docs/sec indexing, 5 queries/sec). The output will be a detailed performance report for each platform, including average latency, throughput, and error rates. This report serves as the baseline for all subsequent performance labs.
