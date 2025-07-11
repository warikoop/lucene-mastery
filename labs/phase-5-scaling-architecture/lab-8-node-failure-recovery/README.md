# Lab 8: Node Failure and Recovery

## 🎯 **Objective**

This lab demonstrates the high-availability and fault-tolerance features of the clusters. You will simulate a node failure by stopping a container and observe how the cluster reacts and recovers once the node is brought back online.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-5-scaling-architecture/lab-8-node-failure-recovery
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

The script will stop one node from each of the Elasticsearch and Solr clusters. It will then show the cluster status, which should indicate a degraded state (e.g., "yellow" status in Elasticsearch, one less live node in Solr). After restarting the nodes, the script will show the cluster returning to a healthy, fully operational state, demonstrating the self-healing capabilities of the HA setup.
