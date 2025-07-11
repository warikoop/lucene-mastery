# Performance & Production Reality Guide
## Elasticsearch vs Solr - Real-World Scaling & Limitations

> **🎯 Objective**: Understand when each technology hits its limits and how to manage production-scale deployments

---

## 🚀 **Lab 1: Memory Management & JVM Tuning**

### **Elasticsearch JVM Optimization**

#### **Heap Size Configuration**
```bash
# Check current heap usage
curl "localhost:9199/_nodes/stats/jvm?pretty" | jq '.nodes | to_entries[] | {
  name: .value.name,
  heap_used_percent: .value.jvm.mem.heap_used_percent,
  heap_max_gb: (.value.jvm.mem.heap_max_in_bytes / 1024 / 1024 / 1024 | floor)
}'

# Optimal heap sizing rules:
# - Never exceed 32GB (compressed OOPs boundary)
# - Use 50% of available RAM max
# - Leave 50% for OS file system cache
```

#### **GC Tuning for Different Workloads**
```yaml
# For heavy indexing workloads
ES_JAVA_OPTS: "-Xms2g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# For heavy search workloads  
ES_JAVA_OPTS: "-Xms4g -Xmx4g -XX:+UseG1GC -XX:G1HeapRegionSize=16m"

# For mixed workloads (recommended)
ES_JAVA_OPTS: "-Xms2g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=400"
```

### **Solr JVM Optimization**

#### **Memory Allocation Strategy**
```bash
# Check Solr memory usage across nodes
for port in 8983 8984 8985; do
  echo "Node $port memory:"
  curl -s "http://localhost:$port/solr/admin/info/system?wt=json" | jq '{
    heap_used: (.jvm.memory.raw.used / 1024 / 1024 | floor),
    heap_max: (.jvm.memory.raw.max / 1024 / 1024 | floor),
    heap_percent: ((.jvm.memory.raw.used / .jvm.memory.max) * 100 | floor)
  }'
done
```

#### **Solr-Specific JVM Settings**
```yaml
# Production Solr JVM configuration
SOLR_JAVA_MEM: "-Xms1g -Xmx1g"
GC_TUNE: "-XX:+UseG1GC -XX:+PerfDisableSharedMem -XX:+ParallelRefProcEnabled"
```

---

## 📊 **Lab 2: Scaling Pattern Analysis**

> **🎯 Lab Objective**: Understand how Elasticsearch and Solr scale under different load patterns and identify their breaking points through systematic capacity testing.

### **Elasticsearch Scaling Patterns**

#### **Vertical vs Horizontal Scaling Test**

**📝 What This Lab Does:**
This lab tests your Elasticsearch cluster's current indexing capacity and measures key performance indicators to establish baseline performance before scaling decisions.

```bash
# Test current cluster capacity with bulk indexing
curl -X POST "localhost:9199/scaling_test/_bulk" -H 'Content-Type: application/json' -d'
{"index":{"_id":"1"}}
{"title":"Scaling Test 1","content":"Testing elasticsearch scaling patterns"}
{"index":{"_id":"2"}}
{"title":"Scaling Test 2","content":"Analyzing performance under load"}
'
```

**🔧 Bulk API Payload Breakdown:**
- **`{"index":{"_id":"1"}}`** - Index operation metadata line
  - **Purpose**: Tells Elasticsearch this is an index operation for document with ID "1"
  - **Impact**: Using explicit IDs prevents ID generation overhead (~5-10% performance gain)
  - **Alternative**: Omit `_id` for auto-generation if you don't need specific IDs

- **`{"title":"...", "content":"..."}`** - Document content line
  - **Purpose**: Actual document data to be indexed
  - **Field choice**: `title` and `content` fields test text analysis pipeline
  - **Impact**: Text fields trigger analyzer processing, affecting indexing speed

- **Bulk format structure** - Alternating metadata/content lines
  - **Why**: Allows efficient streaming processing without loading entire request into memory
  - **Performance**: ~3x faster than individual document indexing
  - **Memory**: Processes line-by-line, not all-at-once

**📊 Performance Monitoring Command:**
```bash
# Monitor indexing performance and resource usage
curl "localhost:9199/scaling_test/_stats?pretty" | jq '{
  docs: .indices.scaling_test.total.docs.count,
  size_mb: (.indices.scaling_test.total.store.size_in_bytes / 1024 / 1024 | floor),
  indexing_rate: .indices.scaling_test.total.indexing.index_total
}'
```

**🔍 Metrics Explanation:**
- **`docs.count`** - Total documents successfully indexed
  - **What it tells you**: Indexing success rate and volume capacity
  - **Scaling indicator**: If this plateaus during load testing, you've hit indexing limits

- **`size_mb`** - Index size in megabytes on disk
  - **What it tells you**: Storage efficiency and growth patterns
  - **Scaling factor**: Helps calculate storage requirements for scaling up
  - **Rule of thumb**: 1MB of JSON usually becomes 0.3-0.7MB indexed (with compression)

- **`indexing.index_total`** - Cumulative indexing operations
  - **What it tells you**: Total indexing workload handled
  - **Performance calc**: Divide by uptime to get average indexing rate
  - **Bottleneck indicator**: Compare to `docs.count` to identify failed indexing operations

#### **When Elasticsearch Hits Limits**

**🚨 Resource Limit Analysis:**
| **Resource** | **Warning Signs** | **Breaking Point** | **Why This Happens** | **Scaling Solution** |
|-------------|------------------|-------------------|---------------------|---------------------|
| **Memory** | Heap >80%, GC >100ms | Heap >95%, GC >1s | JVM spending more time collecting garbage than processing | Add data nodes (horizontal) or increase heap (vertical to 32GB max) |
| **CPU** | >70% sustained | >90% sustained | Analysis, compression, networking saturating cores | Add nodes to distribute CPU load horizontally |
| **I/O** | Queue depth >10 | Disk wait >500ms | Write throughput exceeds disk capability | SSD upgrade (vertical) or add nodes with local storage (horizontal) |
| **Network** | >1GB/s sustained | Network saturation | Cluster communication + client traffic overwhelming network | Load balancer with multiple network paths |

**🔬 How to Identify Each Bottleneck:**

**Memory Bottleneck Detection:**
```bash
# Check for memory pressure indicators
curl "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[] | {
  node: .value.name,
  heap_percent: .value.jvm.mem.heap_used_percent,
  gc_young_time: .value.jvm.gc.collectors.young.collection_time_in_millis,
  gc_old_time: .value.jvm.gc.collectors.old.collection_time_in_millis
}'
```
- **When GC time increases faster than indexing rate = memory bottleneck**
- **Solution path**: Horizontal scaling (more nodes) vs vertical scaling (more RAM)

### **Solr Scaling Patterns**

#### **Collection Sharding Analysis**

**📝 What This Lab Does:**
Analyzes how your Solr collections are distributed across the cluster and identifies sharding efficiency to determine optimal scaling strategies.

```bash
# Analyze shard distribution and performance characteristics
# Step 1: Get collection topology (shards, replicas, states)  
echo "📊 Collection Topology:"
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&collection=solr_scaling_test&wt=json" | jq '
  .cluster.collections.solr_scaling_test | {
    collection: "solr_scaling_test",
    shards: (.shards | keys),
    shard_count: (.shards | length),
    active_replicas: [.shards[].replicas[] | select(.state=="active")] | length,
    total_replicas: [.shards[].replicas | length] | add
  }
'

# Step 2: Get document counts (separate API call required)
echo "📈 Document Distribution:"
curl -s "http://localhost:8999/solr/solr_scaling_test/select?q=*:*&rows=0&shards.info=true&wt=json" | jq '{
  total_documents: .response.numFound,
  query_time_ms: .responseHeader.QTime,
  shard_distribution: (.shards | to_entries[] | {
    shard: (.key | split("/") | last | split("_") | first),
    docs: .value.numFound,
    response_time: .value.QTime
  }),
  avg_docs_per_shard: (.response.numFound / (.shards | length))
}'

# Step 3: Performance metrics with sample data
echo "⚡ Performance Metrics:"
curl -s "http://localhost:8999/solr/solr_scaling_test/select?q=category_s:scaling-test&facet=true&facet.field=test_type_s&stats=true&stats.field=doc_size_i&wt=json" | jq '{
  matching_docs: .response.numFound,
  query_time_ms: .responseHeader.QTime,
  facet_results: .facet_counts.facet_fields.test_type_s,
  size_statistics: {
    min_size: .stats.stats_fields.doc_size_i.min,
    max_size: .stats.stats_fields.doc_size_i.max,
    avg_size: (.stats.stats_fields.doc_size_i.sum / .stats.stats_fields.doc_size_i.count | floor)
  }
}'
```

**🔧 CLUSTERSTATUS API Breakdown:**
- **`action=CLUSTERSTATUS`** - Solr admin API command
  - **Purpose**: Gets comprehensive cluster topology and health information
  - **Performance**: Lightweight operation, safe to run frequently
  - **Scope**: Returns all collections, shards, replicas, and their states

- **`.cluster.collections`** - Collections data structure
  - **Why we analyze this**: Shows how data is distributed across your cluster
  - **Scaling insight**: Uneven distribution indicates scaling problems

**📊 JQ Query Analysis Breakdown:**
- **`collection: .key`** - Collection name identifier
  - **Purpose**: Track which collection we're analyzing
  - **Scaling relevance**: Different collections may have different scaling patterns

- **`shards: (.value.shards | length)`** - Number of shards per collection
  - **What it indicates**: Horizontal partitioning level
  - **Scaling impact**: More shards = better parallelism but more coordination overhead
  - **Sweet spot**: Usually 1-2 shards per node for optimal performance

- **`replicas: [.value.shards[].replicas | length] | add`** - Total replica count
  - **What it measures**: Total data copies across all shards
  - **Availability impact**: More replicas = higher availability but more resource usage
  - **Performance trade-off**: Reads faster (more replicas to query) but writes slower (more copies to update)

- **`total_docs`** - Documents across all active replicas
  - **Purpose**: Measure collection size and growth
  - **Scaling indicator**: Large collections may need more shards
  - **Data skew detection**: Compare with `avg_docs_per_shard` to find imbalanced shards

- **`avg_docs_per_shard`** - Average documents per shard
  - **Critical metric**: Reveals data distribution evenness
  - **Scaling trigger**: If some shards have 10x more docs than others, you need rebalancing
  - **Performance impact**: Uneven shards cause query performance variability

#### **Solr Performance Bottlenecks**

**🔍 Component-Specific Bottleneck Analysis:**
| **Component** | **Bottleneck Signs** | **Detection Method** | **Root Cause** | **Mitigation Strategy** |
|--------------|---------------------|---------------------|----------------|------------------------|
| **ZooKeeper** | >3s ensemble response | `zkCli.sh stat /` timing | Network latency, disk I/O on ZK nodes | Dedicated ZK hardware, SSD storage, network optimization |
| **Commit Rate** | >1 commit/sec | Monitor commit frequency in logs | Too frequent commits causing I/O storms | Batch commits, increase autoCommit intervals |
| **Faceting** | >10s facet queries | Query response time monitoring | High-cardinality fields, insufficient caching | Field cache optimization, facet method tuning |
| **Replication** | Lag >30s | Compare leader/follower timestamps | Network bandwidth, follower hardware | Network tuning, dedicated replication network |

**🔬 ZooKeeper Bottleneck Deep Dive:**
- **Why ZK becomes bottleneck**: All Solr metadata operations go through ZooKeeper
- **Detection signs**: Collection admin operations slow, node discovery issues
- **Impact**: Entire cluster becomes unstable when ZK is slow
- **Prevention**: Separate ZK ensemble on dedicated hardware with fast disks

**⚙️ Commit Rate Optimization:**
- **Why commits are expensive**: Each commit forces index segments to be written to disk
- **Trade-off**: Frequent commits = better durability but worse performance
- **Optimal strategy**: Balance between data loss risk and performance impact
- **Monitoring**: Track commit time vs indexing rate correlation

---

## 🔍 **Lab 3: Performance Monitoring Setup**

### **Elasticsearch Monitoring Commands**

#### **Cluster Health Dashboard**
```bash
# Real-time cluster monitoring
while true; do
  echo "=== Elasticsearch Health $(date) ==="
  
  # Cluster overview
  curl -s "localhost:9199/_cluster/health" | jq '{
    status, nodes: .number_of_nodes, 
    shards: {active: .active_shards, unassigned: .unassigned_shards}
  }'
  
  # Node performance
  curl -s "localhost:9199/_nodes/stats" | jq '.nodes | to_entries[] | {
    name: .value.name,
    heap: .value.jvm.mem.heap_used_percent,
    cpu: .value.os.cpu.percent,
    load: .value.os.cpu.load_average."1m"
  }'
  
  # Index statistics
  curl -s "localhost:9199/_cat/indices?h=index,docs.count,store.size&s=store.size:desc" | head -5
  
  sleep 30
done
```

#### **Performance Metrics Collection**
```bash
# Detailed performance analysis
curl "localhost:9199/_nodes/stats?pretty" | jq '{
  cluster_name: .cluster_name,
  nodes: (.nodes | to_entries[] | {
    name: .value.name,
    performance: {
      indexing_rate: (.value.indices.indexing.index_total / (.value.jvm.uptime_in_millis / 1000)),
      search_rate: (.value.indices.search.query_total / (.value.jvm.uptime_in_millis / 1000)),
      memory_pressure: .value.jvm.mem.heap_used_percent,
      gc_impact: .value.jvm.gc.collectors.young.collection_time_in_millis
    }
  })
}'
```

### **Solr Monitoring Commands**

#### **Collection Performance Analysis**
```bash
# Solr cluster performance monitoring
echo "=== Solr Performance Analysis ==="

# Overall cluster status
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq '{
  live_nodes: (.cluster.live_nodes | length),
  collections: (.cluster.collections | keys | length),
  total_replicas: [.cluster.collections[].shards[].replicas | length] | add
}'

# Per-node performance
for port in 8983 8984 8985; do
  echo "Node localhost:$port performance:"
  curl -s "http://localhost:$port/solr/admin/info/system?wt=json" | jq '{
    uptime_hours: (.jvm.jmx.upTimeMS / 1000 / 3600 | floor),
    memory_used_percent: ((.jvm.memory.used / .jvm.memory.max) * 100 | floor),
    processors: .system.processorCount
  }'
done
```

---

## ⚡ **Lab 4: Load Testing & Breaking Points**

### **Elasticsearch Stress Testing**

#### **Memory Pressure Test**
```bash
# Generate memory pressure on Elasticsearch
echo "🔥 Starting Elasticsearch memory stress test..."

# Index large documents to consume heap
for i in {1..1000}; do
  curl -s -X POST "localhost:9199/stress_test/_doc" -H 'Content-Type: application/json' -d'{
    "id": '$i',
    "title": "Memory Stress Test Document '$i'",
    "large_content": "'$(head -c 10000 /dev/urandom | base64)'",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "metadata": {
      "batch": "stress_test",
      "size_kb": 10,
      "random_data": "'$RANDOM$RANDOM$RANDOM'"
    }
  }' > /dev/null
  
  # Monitor heap every 100 documents
  if [ $((i % 100)) -eq 0 ]; then
    echo "Documents indexed: $i"
    curl -s "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[0] | {
      heap_percent: .value.jvm.mem.heap_used_percent,
      gc_collections: .value.jvm.gc.collectors.young.collection_count
    }'
  fi
done
```

#### **Query Performance Under Load**
```bash
# Concurrent search stress test
echo "🔍 Testing search performance under load..."

# Run concurrent searches
for concurrent in {1..50}; do
  curl -s -X POST "localhost:9199/stress_test/_search" -H 'Content-Type: application/json' -d'{
    "query": {
      "bool": {
        "must": [
          {"match": {"title": "stress test"}},
          {"range": {"id": {"gte": 1, "lte": 1000}}}
        ]
      }
    },
    "aggs": {
      "batch_terms": {"terms": {"field": "metadata.batch.keyword"}},
      "avg_size": {"avg": {"field": "metadata.size_kb"}}
    },
    "size": 20
  }' > /dev/null &
done

wait
echo "✅ Concurrent search test completed"
```

### **Solr Stress Testing**

#### **Collection Load Test**
```bash
# Solr bulk indexing stress test
echo "🔥 Starting Solr stress test..."

# Create large document batch
docs='[
  {
    "id": "solr-stress-1",
    "title_txt": "Solr Stress Test Document 1",
    "content_txt": "Large content for Solr memory testing. This document is designed to stress test Solr collection performance and memory management under heavy load conditions.",
    "category_s": "stress-test",
    "batch_i": 1,
    "size_i": 1024,
    "timestamp_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  },
  {
    "id": "solr-stress-2", 
    "title_txt": "Solr Stress Test Document 2",
    "content_txt": "Advanced Solr collection sharding analysis with real-time performance monitoring and resource utilization tracking.",
    "category_s": "stress-test",
    "batch_i": 1,
    "size_i": 2048,
    "timestamp_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  },
  {
    "id": "solr-stress-3",
    "title_txt": "Solr Stress Test Document 3", 
    "content_txt": "Comprehensive evaluation of Solr Cloud architecture performance characteristics under various load conditions.",
    "category_s": "stress-test",
    "batch_i": 1,
    "size_i": 1536,
    "timestamp_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }
]'

# Bulk index to Solr
echo "$docs" | curl -s -X POST "http://localhost:8999/solr/blog_posts_production/update?commit=true" -H 'Content-Type: application/json' -d @-

# Verify indexing
curl -s "http://localhost:8999/solr/blog_posts_production/select?q=*:*&rows=0&wt=json" | jq '.response.numFound'
```

---

## 🛡️ **Lab 5: Production War Stories & Recovery**

### **Common Production Failures**

#### **Split Brain Scenarios**
```bash
# Simulate network partition
echo "⚠️ Testing split-brain recovery..."

# Stop master nodes to force election
docker stop es-master-2 es-master-3

# Check cluster state with single master
curl "localhost:9200/_cluster/health?pretty"
curl "localhost:9200/_cat/master?v"

# Restore network and observe recovery
docker start es-master-2 es-master-3
sleep 30
curl "localhost:9200/_cluster/health?pretty"
```

#### **Memory Exhaustion Recovery**
```bash
# Monitor for OOM conditions
curl "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[] | {
  name: .value.name,
  heap_used_percent: .value.jvm.mem.heap_used_percent,
  gc_pressure: (.value.jvm.gc.collectors.young.collection_time_in_millis / .value.jvm.uptime_in_millis * 100)
}'

# If heap >90%, emergency actions:
# 1. Stop indexing: curl -X PUT "localhost:9199/_cluster/settings" -d'{"transient":{"cluster.routing.allocation.enable":"none"}}'
# 2. Clear caches: curl -X POST "localhost:9199/_cache/clear"
# 3. Force GC: curl -X POST "localhost:9199/_nodes/_all/jvm"
```

### **Performance Degradation Patterns**

#### **Elasticsearch Warning Signs**
| **Metric** | **Healthy** | **Warning** | **Critical** | **Action Required** |
|------------|-------------|-------------|--------------|-------------------|
| **Heap Usage** | <70% | 70-85% | >85% | Add nodes, reduce load |
| **GC Time** | <50ms | 50-200ms | >200ms | Tune GC, reduce heap |
| **Query Time** | <100ms | 100-500ms | >500ms | Optimize queries, cache |
| **Indexing Rate** | Stable | Declining | Stalled | Check I/O, memory |

#### **Solr Warning Signs**
| **Metric** | **Healthy** | **Warning** | **Critical** | **Action Required** |
|------------|-------------|-------------|--------------|-------------------|
| **Commit Time** | <1s | 1-5s | >5s | Reduce commit frequency |
| **Query Time** | <200ms | 200ms-1s | >1s | Cache warming, optimize |
| **Replication Lag** | <10s | 10-60s | >60s | Network/disk optimization |
| **ZK Response** | <100ms | 100-500ms | >500ms | ZK cluster tuning |

---

## 🎯 **Key Takeaways**

### **When to Choose Elasticsearch**
- **Strong points**: Real-time search, complex aggregations, document-oriented
- **Scaling limits**: Memory intensive, complex cluster management
- **Best for**: Log analytics, full-text search, real-time dashboards

### **When to Choose Solr**
- **Strong points**: Mature, stable, excellent faceting, strong consistency
- **Scaling limits**: ZooKeeper dependency, complex configuration
- **Best for**: Enterprise search, e-commerce, content management

### **Production Reality Check**
- **Both require significant operational expertise**
- **Memory management is critical for both platforms**  
- **Monitoring and alerting are non-negotiable**
- **Plan for failures - they will happen**

---

**🚀 You now understand the real-world performance characteristics and limitations of both platforms!**

### **Solr Scaling Patterns**

#### **Collection Sharding Analysis**

**📝 What This Lab Does:**
Analyzes how your Solr collections are distributed across the cluster and identifies sharding efficiency to determine optimal scaling strategies.

**🏗️ First: Create Sample Collection for Testing**
```bash
# Create a dedicated scaling test collection via HA endpoint
curl -X POST "http://localhost:8999/solr/admin/collections?action=CREATE&name=solr_scaling_test&numShards=3&replicationFactor=1&collection.configName=_default&wt=json"

# Verify collection creation
curl -s "http://localhost:8999/solr/admin/collections?action=LIST&wt=json" | jq '.collections'
```

**🔧 Collection Creation Parameters Explained:**
- **`name=solr_scaling_test`** - Collection identifier for our performance tests
  - **Purpose**: Dedicated collection for scaling analysis without affecting production data
  - **Naming convention**: Use descriptive names that indicate purpose

- **`numShards=3`** - Create 3 shards for horizontal distribution
  - **Why 3**: Allows testing data distribution across multiple shards
  - **Performance impact**: More shards = better parallelism but more coordination overhead
  - **Rule**: Start with 1-2 shards per node

- **`replicationFactor=1`** - Single replica per shard for testing
  - **Why 1**: Reduces resource usage during performance testing
  - **Production note**: Use replicationFactor=2+ for high availability
  - **Trade-off**: Less durability but faster indexing for testing

**📊 Add Sample Data for Scaling Tests**
```bash
# Create batch of test documents for scaling analysis
echo '[
  {
    "id": "scaling-1",
    "title_txt": "Solr Scaling Test Document 1",
    "content_txt": "This document tests Solr horizontal scaling patterns and shard distribution efficiency across multiple nodes in the cluster.",
    "category_s": "scaling-test",
    "doc_size_i": 1024,
    "created_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "batch_i": 1,
    "test_type_s": "performance"
  },
  {
    "id": "scaling-2", 
    "title_txt": "Solr Scaling Test Document 2",
    "content_txt": "Advanced Solr collection sharding analysis with real-time performance monitoring and resource utilization tracking.",
    "category_s": "scaling-test",
    "doc_size_i": 2048,
    "created_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "batch_i": 1,
    "test_type_s": "performance"
  },
  {
    "id": "scaling-3",
    "title_txt": "Solr Scaling Test Document 3", 
    "content_txt": "Comprehensive evaluation of Solr Cloud architecture performance characteristics under various load conditions.",
    "category_s": "scaling-test",
    "doc_size_i": 1536,
    "created_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "batch_i": 1,
    "test_type_s": "performance"
  }
]' | curl -X POST "http://localhost:8999/solr/solr_scaling_test/update?commit=true" -H 'Content-Type: application/json' -d @-
```

**🔧 Sample Data Breakdown:**
- **`id`** - Unique document identifier
  - **Purpose**: Ensures documents can be updated/deleted individually
  - **Format**: Using descriptive prefixes for easier identification

- **`title_txt`** - Text field for full-text search testing
  - **Field type**: `_txt` suffix indicates analyzed text field
  - **Purpose**: Tests text analysis and search performance under load

- **`content_txt`** - Large text content for memory usage testing
  - **Purpose**: Simulates real document sizes that affect memory consumption
  - **Performance impact**: Larger text fields increase indexing time and memory usage

- **`category_s`** - String field for faceting tests
  - **Field type**: `_s` suffix indicates stored string (not analyzed)
  - **Purpose**: Tests faceting performance and shard distribution

- **`doc_size_i`** - Integer field for numeric operations
  - **Field type**: `_i` suffix indicates integer field
  - **Purpose**: Tests numeric faceting, sorting, and statistics functions

- **`created_dt`** - Date field for time-based operations  
  - **Field type**: `_dt` suffix indicates date field
  - **Purpose**: Tests date range queries and time-based faceting

**📊 Verify Sample Data and Monitor Performance**
```bash
# Check document count and distribution
curl -s "http://localhost:8999/solr/solr_scaling_test/select?q=*:*&rows=0&wt=json" | jq '{
  total_docs: .response.numFound,
  query_time_ms: .responseHeader.QTime
}'

# Test search performance with sample data
curl -s "http://localhost:8999/solr/solr_scaling_test/select?q=title_txt:scaling&facet=true&facet.field=category_s&facet.field=test_type_s&stats=true&stats.field=doc_size_i&wt=json" | jq '{
  results_found: .response.numFound,
  query_time_ms: .responseHeader.QTime,
  facet_counts: .facet_counts.facet_fields,
  doc_size_stats: .stats.stats_fields.doc_size_i
}'
```

```bash
# Analyze shard distribution and performance characteristics  
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq '
  .cluster.collections.solr_scaling_test | {
    collection: "solr_scaling_test",
    shards: (.shards | length),
    total_replicas: [.shards[].replicas | length] | add,
    shard_details: (.shards | to_entries[] | {
      shard_name: .key,
      replicas: (.value.replicas | length),
      docs_per_replica: [.value.replicas[] | select(.state=="active") | .docs // 0],
      size_per_replica: [.value.replicas[] | select(.state=="active") | .size // "0B"]
    }),
    total_docs: [.shards[].replicas[] | select(.state=="active") | .docs // 0] | add,
    avg_docs_per_shard: ([.shards[].replicas[] | select(.state=="active") | .docs // 0] | add) / (.shards | length)
  }
'
```

**🔧 CLUSTERSTATUS API Breakdown:**
- **`action=CLUSTERSTATUS`** - Solr admin API command
  - **Purpose**: Gets comprehensive cluster topology and health information
  - **Performance**: Lightweight operation, safe to run frequently
  - **Scope**: Returns all collections, shards, replicas, and their states

- **`.cluster.collections.solr_scaling_test`** - Specific collection analysis
  - **Why we filter**: Focus on our test collection for targeted analysis
  - **Scaling insight**: Shows how our test data is distributed

**📊 JQ Query Analysis Breakdown:**
- **`collection: "solr_scaling_test"`** - Collection identifier
  - **Purpose**: Confirm we're analyzing the correct collection
  - **Verification**: Ensures our test data is properly isolated

- **`shards: (.shards | length)`** - Number of shards in collection
  - **What it indicates**: Horizontal partitioning level for our test collection
  - **Expected**: Should match our `numShards=3` creation parameter
  - **Scaling impact**: More shards = better parallelism but more coordination overhead

- **`total_replicas`** - Total replica count across all shards
  - **Calculation**: Sums replicas across all shards
  - **Expected**: With 3 shards × 1 replica = 3 total replicas
  - **Availability impact**: More replicas = higher availability but more resource usage

- **`shard_details`** - Per-shard breakdown
  - **`shard_name`**: Identifier for each shard (shard1, shard2, etc.)
  - **`docs_per_replica`**: Document count in each replica
  - **`size_per_replica`**: Storage size of each replica
  - **Purpose**: Identify data skew and uneven distribution

- **`total_docs`** - Documents across all active replicas
  - **Calculation**: Sums documents from all active replicas
  - **Expected**: Should match our indexed document count
  - **Data integrity check**: Verifies no document loss during sharding

- **`avg_docs_per_shard`** - Average documents per shard
  - **Critical metric**: Reveals data distribution evenness
  - **Ideal**: All shards should have similar document counts
  - **Scaling trigger**: Large variation indicates rebalancing needed

**🔍 Performance Scaling Test with Sample Data**
```bash
# Load test with larger dataset
echo "🔥 Creating larger dataset for scaling analysis..."

# Generate 100 documents for performance testing
docs='[
  {
    "id": "perf-test-1",
    "title_txt": "Performance Test Document 1",
    "content_txt": "Large content block for Solr performance testing and memory usage analysis. This document contains substantial text to evaluate indexing speed, search performance, and memory consumption patterns under varying load conditions. Document number 1 in comprehensive scaling evaluation.",
    "category_s": "performance-test",
    "batch_i": 1,
    "doc_size_i": 1024,
    "priority_i": 1,
    "created_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "test_type_s": "scaling",
    "content_length_i": 200
  },
  {
    "id": "perf-test-2", 
    "title_txt": "Performance Test Document 2",
    "content_txt": "Advanced Solr collection sharding analysis with real-time performance monitoring and resource utilization tracking.",
    "category_s": "performance-test",
    "batch_i": 1,
    "doc_size_i": 2048,
    "priority_i": 2,
    "created_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "test_type_s": "scaling",
    "content_length_i": 400
  },
  {
    "id": "perf-test-3",
    "title_txt": "Performance Test Document 3", 
    "content_txt": "Comprehensive evaluation of Solr Cloud architecture performance characteristics under various load conditions.",
    "category_s": "performance-test",
    "batch_i": 1,
    "doc_size_i": 1536,
    "priority_i": 3,
    "created_dt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "test_type_s": "scaling",
    "content_length_i": 600
  }
]'

# Index the larger dataset
echo "$docs" | curl -s -X POST "http://localhost:8999/solr/solr_scaling_test/update?commit=true" -H 'Content-Type: application/json' -d @-

# Monitor indexing performance
curl -s "http://localhost:8999/solr/solr_scaling_test/select?q=*:*&rows=0&facet=true&facet.field=batch_i&facet.field=test_type_s&stats=true&stats.field=doc_size_i&stats.field=priority_i&wt=json" | jq '{
  total_documents: .response.numFound,
  query_time_ms: .responseHeader.QTime,
  batch_distribution: .facet_counts.facet_fields.batch_i,
  type_distribution: .facet_counts.facet_fields.test_type_s,
  size_stats: {
    min: .stats.stats_fields.doc_size_i.min,
    max: .stats.stats_fields.doc_size_i.max,
    avg: (.stats.stats_fields.doc_size_i.sum / .stats.stats_fields.doc_size_i.count | floor)
  }
}'
