# Lab 9: Learning-to-Rank (LTR)

## 🎯 **Objective**

This lab demonstrates how to set up and use Learning-to-Rank (LTR) to improve search relevance. You will define a feature set, upload a simple machine learning model, and use it to re-rank search results in Elasticsearch.

## 🚀 **How to Run**

1.  **Navigate to the lab directory:**
    ```bash
    cd labs/phase-6-ml-advanced-search/lab-9-learning-to-rank
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

The script will perform the full LTR workflow in Elasticsearch: create a feature store, define a feature set, upload a model, and execute a search query that uses the model to re-rank the results. The final output will be the re-ranked search results, demonstrating the power of LTR in action.
