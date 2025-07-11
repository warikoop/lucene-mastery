# 📈 **Performance Progressive Labs Guide**

## 🎯 **Overview**
This guide provides a series of progressive labs to test and understand the performance characteristics of Elasticsearch, Solr, and OpenSearch. We will start with a baseline and incrementally add complexity, measuring the impact at each stage. All labs use our unified HA environment.

## ✅ **Prerequisites**

### **1. Environment Setup**
Ensure the unified HA environment is running:

```bash
# Navigate to project root
cd /path/to/elastic-search

# Start unified HA environment
./setup/unified-setup.sh

# Verify all clusters are healthy
./setup/verify-setup.sh
```

### **2. Load Testing Tool**
These labs use a Go-based concurrent load tester. Ensure you have Go installed (`go version 1.18` or higher).

---

## 🚀 **Lab 1: Baseline Performance**

### **Step 1: Establish a Baseline**

First, let's measure the baseline indexing and query performance with the data loaded by the setup script.

```bash
# Run the concurrent load tester with default settings
# This will run for 60 seconds, with 10 docs/sec indexing and 5 queries/sec
cd tools/concurrent-load-tester
go run lab5-concurrent-load-tester.go
```

Record the output, which includes average latency, throughput, and error rates for each platform.

---

## 🔬 **Lab 2: High-Volume Indexing**

### **Step 1: Test High-Volume Indexing**

Let's increase the indexing rate to see how the systems handle a higher write load.

```bash
# Run with a higher indexing rate (50 docs/sec) and no querying
go run lab5-concurrent-load-tester.go -duration 60s -indexRate 50 -queryRate 0
```

Compare the results with the baseline. Look for changes in indexing latency and CPU/memory usage.

---

## 💡 **Lab 3: High-Query Throughput**

### **Step 1: Test High-Query Load**

Now, let's test how the systems perform under a high query load with no indexing.

```bash
# Run with a higher query rate (50 queries/sec) and no indexing
go run lab5-concurrent-load-tester.go -duration 60s -indexRate 0 -queryRate 50
```

Analyze the query latency and throughput. Note any differences between the platforms.

---

## ⚖️ **Lab 4: Concurrent Read/Write Load**

### **Step 1: Simulate Production Load**

This lab simulates a more realistic production scenario with both reading and writing happening concurrently.

```bash
# Run with both high indexing and high query rates
go run lab5-concurrent-load-tester.go -duration 120s -indexRate 20 -queryRate 20
```

Observe how the systems handle resource contention. Do query latencies increase during heavy indexing? How does this compare across platforms?

---

## 💣 **Lab 5: Breaking Point Analysis**

### **Step 1: Find the Limits**

In this lab, we will incrementally increase the load until the systems start to fail. This helps us understand their capacity limits.

```bash
# Start with a high load and increase it every 30 seconds
# This is a conceptual example; you would script this for a real test.

# Round 1
go run lab5-concurrent-load-tester.go -duration 30s -indexRate 100 -queryRate 50

# Round 2
go run lab5-concurrent-load-tester.go -duration 30s -indexRate 150 -queryRate 75

# Round 3
go run lab5-concurrent-load-tester.go -duration 30s -indexRate 200 -queryRate 100
```

Monitor the output for errors (e.g., HTTP 429 Too Many Requests, timeouts). The point at which errors begin to appear consistently is the system's approximate breaking point under these conditions.

---

## 🚀 **Congratulations!**

You have completed the progressive performance labs. You now have a much deeper understanding of how Elasticsearch, Solr, and OpenSearch perform under various load conditions. This knowledge is crucial for making informed decisions about scaling, capacity planning, and performance tuning in a production environment.
