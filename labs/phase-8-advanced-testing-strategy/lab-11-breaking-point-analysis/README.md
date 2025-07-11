# Lab 11: Breaking Point Analysis

## 🎯 **Objective**

This lab is designed to help you understand the capacity limits of your search clusters. You will incrementally increase the load on the systems until they start to show signs of stress (e.g., high error rates, increased latency). This is a common practice in production to determine when you need to scale your infrastructure.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-8-advanced-testing-strategy/lab-11-breaking-point-analysis
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

The script will run the concurrent load tester in a loop, increasing the indexing and query rates with each iteration. You should monitor the output for increasing error rates or a sharp rise in latency. The point at which the system can no longer handle the load is its approximate "breaking point" for the given hardware and configuration. This lab provides critical insights for capacity planning.
