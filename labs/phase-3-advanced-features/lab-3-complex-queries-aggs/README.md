# Lab 3: Complex Queries and Aggregations

## 🎯 **Objective**

This lab demonstrates how to perform complex queries and aggregations (or faceting in Solr) to analyze the data within your search index. You will see how each platform handles data summarization and analytics.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-3-advanced-features/lab-3-complex-queries-aggs
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

The script will execute an aggregation query on Elasticsearch and OpenSearch, and a faceting query on Solr. The output will be a JSON object from each platform that summarizes the data by category, providing a count of documents for each, demonstrating the powerful analytical capabilities of these search engines.
