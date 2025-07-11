# Lab 7: Concurrent Read/Write Performance

## 🎯 **Objective**

This lab simulates a realistic production environment where indexing (writes) and querying (reads) happen simultaneously. You will use the concurrent load tester to apply both a write and read load to the clusters and analyze how they handle resource contention.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-4-performance-production/lab-7-concurrent-read-write
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

The script will run the concurrent load tester with both a significant indexing rate (20 docs/sec) and query rate (20 queries/sec). The output will be a performance report that shows how each platform's read and write performance is affected by the concurrent load. This is a crucial test for understanding real-world performance characteristics.
