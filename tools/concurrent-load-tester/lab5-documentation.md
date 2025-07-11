## 🔄 **Lab 5: Concurrent Read/Write Performance Testing**

> **🎯 Lab Objective**: Simulate production-like conditions with continuous document indexing and querying running simultaneously
> **Builds on**: Lab 4 dataset (16,000 documents + breaking point analysis)
> **Adds**: Realistic concurrent read/write workload simulation with configurable rates

### **What This Lab Tests:**

This lab addresses the most critical real-world performance scenario: **simultaneous read and write operations**. Unlike previous labs that tested indexing and querying in isolation, this lab simulates production conditions where:

- **Documents are continuously indexed** at a configurable rate (default: 10 docs/sec)
- **Queries are continuously executed** at a configurable rate (default: 5 QPS)
- **Both operations compete for system resources** (CPU, memory, I/O, network)
- **Performance interference** is measured and analyzed

### **Step 1: Compile and Configure the Go Load Tester**

```bash
echo "🔄 Lab 5: Concurrent Read/Write Performance Testing"
echo "📋 Setting up Go-based concurrent load tester..."

# Navigate to test directory
cd /path/to/your/elasticsearch/directory

# Compile the Go load tester
go mod init lab5-concurrent-tester
go mod tidy
go build -o concurrent-load-tester lab5-concurrent-load-tester.go

# Verify compilation
ls -la concurrent-load-tester
echo "✅ Go load tester compiled successfully"
```

### **Step 2: Pre-Test System State Capture**

```bash
echo "📊 Capturing pre-test system state..."

# Run comprehensive monitoring before concurrent test
./performance_monitor.sh

# Document current dataset sizes
echo "📈 Current Dataset State:"
curl -s "localhost:9199/performance_baseline/_count" | jq '{
  elasticsearch_docs: .count,
  message: "Pre-concurrent test document count"
}'

curl -s "http://localhost:8999/solr/performance_baseline/select?q=*:*&rows=0&wt=json" | jq '{
  solr_docs: .response.numFound,
  message: "Pre-concurrent test document count"
}'

# Check system resource baseline
echo "💾 System Resource Baseline:"
curl -s "localhost:9199/_nodes/stats/jvm,os" | jq '.nodes | to_entries[] | {
  node: .value.name,
  heap_used_percent: .value.jvm.mem.heap_used_percent,
  cpu_percent: .value.os.cpu.percent,
  load_average: .value.os.cpu.load_average."1m"
}'
```

### **Step 3: Run Concurrent Load Test (Default Configuration)**

```bash
echo "🚀 Starting concurrent read/write load test..."
echo "⚙️  Default configuration: 10 docs/sec indexing, 5 QPS querying, 60-second test"

# Run the concurrent load tester
./concurrent-load-tester

# The Go program will output real-time statistics every 10 seconds
# Expected output format:
# 📊 Stats @ 10s: Indexed=100 (10.0/s), Queries=50 (5.0/s), Errors: Index=0, Query=0
# 📊 Stats @ 20s: Indexed=200 (10.0/s), Queries=100 (5.0/s), Errors: Index=0, Query=0
# ...
# 🎯 ===== CONCURRENT READ/WRITE PERFORMANCE REPORT =====
```

### **Step 4: Custom Configuration Testing**

```bash
echo "⚙️  Testing different load configurations..."

# Test high indexing load with low query load
echo "🔥 High Indexing Load Test (20 docs/sec, 2 QPS):"
# Modify the Go code config or create command-line flags:
# config.IndexingRate = 20
# config.QueryRate = 2
# config.TestDuration = 30

# Test high query load with low indexing load  
echo "🔍 High Query Load Test (5 docs/sec, 15 QPS):"
# config.IndexingRate = 5
# config.QueryRate = 15
# config.TestDuration = 30

# Test balanced heavy load
echo "⚡ Balanced Heavy Load Test (15 docs/sec, 10 QPS):"
# config.IndexingRate = 15
# config.QueryRate = 10  
# config.TestDuration = 45
```

### **Step 5: Performance Analysis and Comparison**

```bash
echo "📊 Analyzing concurrent operation performance impact..."

# Post-test system state analysis
echo "🔍 Post-Concurrent Test Analysis:"

# Check for performance degradation
echo "⚡ Query Performance After Concurrent Load:"
time curl -s "localhost:9199/performance_baseline/_search" -H 'Content-Type: application/json' -d'{
  "query": {
    "bool": {
      "must": [
        {"match": {"content": "concurrent"}},
        {"range": {"doc_size": {"gte": 2000}}}
      ]
    }
  },
  "aggs": {
    "lab_phases": {"terms": {"field": "lab_phase"}},
    "performance_timeline": {
      "date_histogram": {
        "field": "created_timestamp",
        "calendar_interval": "hour"
      }
    }
  },
  "size": 100
}' | jq '{
  total_hits: .hits.total.value,
  query_time_ms: .took,
  lab_phases: [.aggregations.lab_phases.buckets[] | {phase: .key, docs: .doc_count}],
  performance_impact: (if .took > 500 then "degraded" elif .took > 200 then "moderate" else "good" end)
}'

# Memory pressure analysis after concurrent operations
echo "💾 Memory Pressure After Concurrent Operations:"
curl -s "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[] | {
  node: .value.name,
  heap_used_percent: .value.jvm.mem.heap_used_percent,
  gc_young_collections: .value.jvm.gc.collectors.young.collection_count,
  gc_young_time_ms: .value.jvm.gc.collectors.young.collection_time_in_millis,
  memory_pressure: (if .value.jvm.mem.heap_used_percent > 80 then "high" elif .value.jvm.mem.heap_used_percent > 60 then "moderate" else "normal" end)
}'

# Document growth verification
echo "📈 Document Growth During Concurrent Test:"
curl -s "localhost:9199/performance_baseline/_search" -H 'Content-Type: application/json' -d'{
  "query": {"term": {"lab_phase": "concurrent_readwrite"}},
  "aggs": {
    "docs_by_category": {"terms": {"field": "category"}},
    "indexing_timeline": {
      "date_histogram": {
        "field": "created_timestamp", 
        "calendar_interval": "minute"
      }
    }
  },
  "size": 0
}' | jq '{
  concurrent_docs: .hits.total.value,
  categories: .aggregations.docs_by_category.buckets,
  indexing_pattern: [.aggregations.indexing_timeline.buckets[] | {time: .key_as_string, docs: .doc_count}]
}'
```

### **Step 6: Resource Contention Analysis**

```bash
echo "🔄 Analyzing resource contention and interference patterns..."

# Compare isolated vs concurrent performance
echo "📊 Performance Comparison Analysis:"

# Single query baseline (no concurrent indexing)
echo "🔍 Isolated Query Performance:"
start_time=$(date +%s%N)
curl -s "localhost:9199/performance_baseline/_search" -H 'Content-Type: application/json' -d'{
  "query": {"match": {"category": "concurrent_load"}},
  "size": 50
}' > /dev/null
end_time=$(date +%s%N)
isolated_query_ms=$(((end_time - start_time) / 1000000))
echo "Isolated query latency: ${isolated_query_ms}ms"

# Single indexing operation baseline (no concurrent querying)
echo "📥 Isolated Indexing Performance:"
start_time=$(date +%s%N)
curl -s -X POST "localhost:9199/performance_baseline/_doc" -H 'Content-Type: application/json' -d'{
  "doc_id": 99999,
  "title": "Isolated Performance Test",
  "content": "Single document indexing performance baseline",
  "category": "performance_baseline",
  "lab_phase": "isolated_test"
}' > /dev/null
end_time=$(date +%s%N)
isolated_index_ms=$(((end_time - start_time) / 1000000))
echo "Isolated indexing latency: ${isolated_index_ms}ms"

# Calculate interference impact from Go load tester results
echo "🔄 Resource Contention Impact (from Go load tester report):"
echo "- Compare concurrent vs isolated latencies"
echo "- Analyze throughput efficiency percentages"
echo "- Identify performance degradation patterns"
```

### **Step 7: Production Insights and Recommendations**

```bash
echo "💡 Generating production recommendations based on concurrent test results..."

# System stability assessment
heap_usage=$(curl -s "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[0].value.jvm.mem.heap_used_percent')
cluster_health=$(curl -s "localhost:9199/_cluster/health" | jq -r '.status')

echo "🏥 System Health Assessment:"
echo "- Heap usage: ${heap_usage}%"
echo "- Cluster status: $cluster_health"

# Performance recommendations based on results
if (( $(echo "$heap_usage > 75" | bc -l) )); then
  echo "⚠️  HIGH MEMORY PRESSURE DETECTED"
  echo "   Recommendations:"
  echo "   - Reduce concurrent indexing rate or batch size"
  echo "   - Implement query rate limiting during heavy indexing"
  echo "   - Consider adding more nodes for horizontal scaling"
fi

echo "📋 Concurrent Load Testing Best Practices:"
echo "1. Monitor memory pressure during mixed workloads"
echo "2. Implement backpressure mechanisms for indexing"
echo "3. Use separate thread pools for indexing vs search"
echo "4. Configure refresh intervals based on real-time requirements"
echo "5. Test with realistic document sizes and query complexity"
```

**🎯 Lab 5 Results Recording:**
```bash
# Record Lab 5 completion and insights
final_doc_count=$(curl -s "localhost:9199/performance_baseline/_count" | jq '.count')

curl -X POST "localhost:9199/performance_baseline/_doc/lab5_completion" -H 'Content-Type: application/json' -d'{
  "lab_name": "Lab 5 - Concurrent Read/Write Performance Testing",
  "completion_timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  "final_dataset_size": '$final_doc_count',
  "lab_phase": "concurrent_readwrite",
  "test_configuration": {
    "default_indexing_rate": "10 docs/sec",
    "default_query_rate": "5 QPS", 
    "test_duration": "60 seconds",
    "technology": "Go-based concurrent load tester"
  },
  "production_insights": {
    "resource_contention_measured": true,
    "performance_interference_analyzed": true,
    "production_recommendations_generated": true
  },
  "performance_engineering_journey_complete": true
}'

echo "✅ Lab 5 Complete - Concurrent read/write performance testing finished"
echo "🎯 Production-grade performance engineering journey complete!"
echo "📊 You now understand real-world performance patterns under concurrent load"
```

---

## 🎯 **Lab 5 Key Insights:**

### **🔄 Production-Reality Simulation:**
- **Simultaneous operations** - Real-world conditions where indexing and querying compete
- **Resource contention analysis** - Understanding performance interference patterns
- **Configurable load patterns** - Testing different scenarios (heavy indexing, heavy querying, balanced)

### **📊 Advanced Performance Metrics:**
- **Throughput efficiency** - Expected vs actual performance under concurrent load
- **Latency analysis** - Isolated vs concurrent operation timing
- **Error rate monitoring** - System stability under mixed workloads
- **Resource utilization** - Memory, CPU impact of concurrent operations

### **💡 Production Engineering Insights:**
- **Performance trade-offs** - Indexing speed vs query performance balance
- **System limits identification** - When concurrent operations cause degradation
- **Scaling strategies** - Horizontal vs vertical scaling for concurrent workloads
- **Monitoring requirements** - Key metrics for production concurrent load monitoring

**🚀 This completes your comprehensive performance engineering journey from baseline through production-like concurrent testing!**
