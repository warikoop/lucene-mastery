# 💾 **Memory Management: JVM Tuning Mastery**

> **🎯 Objective**: Master JVM tuning and memory optimization for production search platforms
> **Builds on**: Scaling patterns and performance lab insights
> **Focus**: Platform-specific memory tuning and garbage collection optimization

---

## 🧠 **Memory Management Fundamentals**

### **The Memory Reality**
Search platforms are **memory-intensive applications**. Poor memory management leads to:
- **GC pauses** that freeze query processing
- **OutOfMemoryErrors** that crash nodes
- **Performance degradation** as heap pressure increases
- **Cluster instability** from memory-related failures

**Key Memory Areas:**
- **JVM Heap** - Primary application memory
- **Off-Heap** - Direct memory, compressed OOPs
- **Operating System** - File system cache, kernel buffers
- **Native Memory** - Lucene segments, network buffers

---

## 🔵 **Elasticsearch Memory Management**

### **🎯 Elasticsearch JVM Heap Sizing**

#### **📊 Current Memory Analysis:**
```bash
echo "🔵 Elasticsearch Memory Analysis:"

# Comprehensive memory breakdown
curl -s "localhost:9199/_nodes/stats/jvm,os" | jq '.nodes | to_entries[] | {
  node: .value.name,
  # JVM Heap Analysis
  heap_used_mb: (.value.jvm.mem.heap_used_in_bytes / 1024 / 1024 | floor),
  heap_max_mb: (.value.jvm.mem.heap_max_in_bytes / 1024 / 1024 | floor),
  heap_utilization_percent: .value.jvm.mem.heap_used_percent,
  heap_pressure: (if .value.jvm.mem.heap_used_percent > 85 then "CRITICAL" 
                  elif .value.jvm.mem.heap_used_percent > 75 then "HIGH" 
                  elif .value.jvm.mem.heap_used_percent > 65 then "MODERATE" 
                  else "NORMAL" end),
  
  # Off-Heap Memory  
  non_heap_used_mb: (.value.jvm.mem.non_heap_used_in_bytes / 1024 / 1024 | floor),
  non_heap_max_mb: (.value.jvm.mem.non_heap_committed_in_bytes / 1024 / 1024 | floor),
  
  # Direct Memory (Off-heap buffers)
  direct_max_mb: (.value.jvm.mem.pools."direct" // 0 | if type == "object" then .max_in_bytes / 1024 / 1024 else 0 end | floor),
  
  # System Memory Context
  system_mem_total_mb: (.value.os.mem.total_in_bytes / 1024 / 1024 | floor),
  system_mem_free_mb: (.value.os.mem.free_in_bytes / 1024 / 1024 | floor),
  system_mem_used_percent: (((.value.os.mem.total_in_bytes - .value.os.mem.free_in_bytes) / .value.os.mem.total_in_bytes) * 100 | floor)
}'

# Garbage Collection Analysis
curl -s "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[] | {
  node: .value.name,
  # Young Generation GC
  young_gc_collections: .value.jvm.gc.collectors.young.collection_count,
  young_gc_time_ms: .value.jvm.gc.collectors.young.collection_time_in_millis,
  young_gc_avg_ms: (.value.jvm.gc.collectors.young.collection_time_in_millis / .value.jvm.gc.collectors.young.collection_count | floor),
  
  # Old Generation GC  
  old_gc_collections: .value.jvm.gc.collectors.old.collection_count,
  old_gc_time_ms: .value.jvm.gc.collectors.old.collection_time_in_millis,
  old_gc_avg_ms: (if .value.jvm.gc.collectors.old.collection_count > 0 
                  then (.value.jvm.gc.collectors.old.collection_time_in_millis / .value.jvm.gc.collectors.old.collection_count | floor) 
                  else 0 end),
  
  # GC Overhead Analysis
  total_uptime_ms: .value.jvm.uptime_in_millis,
  gc_overhead_percent: (((.value.jvm.gc.collectors.young.collection_time_in_millis + .value.jvm.gc.collectors.old.collection_time_in_millis) / .value.jvm.uptime_in_millis) * 100 | floor),
  gc_health: (if (((.value.jvm.gc.collectors.young.collection_time_in_millis + .value.jvm.gc.collectors.old.collection_time_in_millis) / .value.jvm.uptime_in_millis) * 100) > 10 
              then "UNHEALTHY - High GC overhead" 
              elif (((.value.jvm.gc.collectors.young.collection_time_in_millis + .value.jvm.gc.collectors.old.collection_time_in_millis) / .value.jvm.uptime_in_millis) * 100) > 5 
              then "SUBOPTIMAL - Monitor GC closely" 
              else "HEALTHY" end)
}'
```

#### **⚙️ Elasticsearch Memory Configuration Strategies:**

##### **🎯 Heap Sizing Rules (The 50% Rule)**
```bash
echo "🎯 Elasticsearch Heap Sizing Analysis:"

# Get system memory
system_memory_gb=$(free -g | awk 'NR==2{printf "%.0f", $2}')
recommended_heap_gb=$((system_memory_gb / 2))

# But never exceed 32GB (compressed OOPs limit)
if [ $recommended_heap_gb -gt 32 ]; then
  recommended_heap_gb=32
fi

echo "System Memory: ${system_memory_gb}GB"
echo "Recommended ES Heap: ${recommended_heap_gb}GB"
echo ""
echo "🔧 Heap Sizing Principles:"
echo "   1. Never exceed 50% of system RAM"
echo "   2. Never exceed ~32GB (compressed OOPs boundary)"
echo "   3. Leave memory for OS file system cache"
echo "   4. Account for off-heap usage (aggregations, Lucene)"
echo ""

current_heap_gb=$(curl -s "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[0].value.jvm.mem.heap_max_in_bytes / 1024 / 1024 / 1024 | floor')
echo "Current ES Heap: ${current_heap_gb}GB"

if [ $current_heap_gb -ne $recommended_heap_gb ]; then
  echo "⚠️  HEAP SIZE MISMATCH DETECTED"
  echo "   Current: ${current_heap_gb}GB"
  echo "   Recommended: ${recommended_heap_gb}GB"
  echo "   Action: Update jvm.options or ES_JAVA_OPTS"
fi
```

##### **🗑️ Elasticsearch Garbage Collection Tuning:**

```bash
echo "🗑️ Elasticsearch GC Tuning Analysis:"

# Analyze current GC settings and performance
curl -s "localhost:9199/_nodes/jvm" | jq '.nodes | to_entries[] | {
  node: .value.name,
  jvm_version: .value.version,
  jvm_vendor: .value.vm_vendor,
  
  # GC Configuration Detection
  gc_collectors: [.value.gc_collectors[]],
  memory_pools: [.value.memory_pools[] | .name],
  
  # Recommended GC based on heap size
  heap_size_gb: (.value.mem.heap_max_in_bytes / 1024 / 1024 / 1024 | floor),
  recommended_gc: (if (.value.mem.heap_max_in_bytes / 1024 / 1024 / 1024) < 8 
                   then "G1GC (default for small heaps)" 
                   elif (.value.mem.heap_max_in_bytes / 1024 / 1024 / 1024) < 32 
                   then "G1GC (balanced performance)" 
                   else "Consider ZGC or Shenandoah for very large heaps" end)
}'

echo ""
echo "🔧 Elasticsearch GC Recommendations by Heap Size:"
echo ""
echo "📊 Small Heaps (< 8GB):"
echo "   -XX:+UseG1GC"
echo "   -XX:G1HeapRegionSize=16m"
echo "   -XX:MaxGCPauseMillis=200"
echo ""
echo "📊 Medium Heaps (8-32GB):"
echo "   -XX:+UseG1GC"
echo "   -XX:G1HeapRegionSize=32m"  
echo "   -XX:MaxGCPauseMillis=200"
echo "   -XX:G1NewSizePercent=30"
echo "   -XX:G1MaxNewSizePercent=40"
echo ""
echo "📊 Large Heaps (>32GB - if unavoidable):"
echo "   Consider ZGC: -XX:+UseZGC"
echo "   Or Shenandoah: -XX:+UseShenandoahGC"
echo "   Both offer low-latency collection"
```

##### **📈 Elasticsearch Memory Pool Analysis:**

```bash
echo "📈 Elasticsearch Memory Pool Breakdown:"

# Detailed memory pool analysis
curl -s "localhost:9199/_nodes/stats/jvm" | jq '.nodes | to_entries[] | {
  node: .value.name,
  memory_pools: (.value.jvm.mem.pools | to_entries | map({
    pool_name: .key,
    used_mb: (.value.used_in_bytes / 1024 / 1024 | floor),
    max_mb: (if .value.max_in_bytes then (.value.max_in_bytes / 1024 / 1024 | floor) else "unlimited" end),
    utilization_percent: (if .value.max_in_bytes and .value.max_in_bytes > 0 
                         then ((.value.used_in_bytes / .value.max_in_bytes) * 100 | floor) 
                         else null end),
    pool_health: (if .value.max_in_bytes and .value.max_in_bytes > 0
                  then (if ((.value.used_in_bytes / .value.max_in_bytes) * 100) > 90 
                        then "CRITICAL" 
                        elif ((.value.used_in_bytes / .value.max_in_bytes) * 100) > 80 
                        then "HIGH" 
                        else "NORMAL" end)
                  else "N/A" end)
  }))
}'
```

---

## 🟡 **Solr Memory Management**

### **🎯 Solr JVM Heap Sizing**

#### **📊 Current Solr Memory Analysis:**
```bash
echo "🟡 Solr Memory Analysis:"

# Solr JVM memory metrics
curl -s "http://localhost:8999/solr/admin/metrics?group=jvm&wt=json" | jq '{
  # Heap Memory Analysis
  heap_used_mb: (.metrics."solr.jvm"."memory.heap.used" / 1024 / 1024 | floor),
  heap_committed_mb: (.metrics."solr.jvm"."memory.heap.committed" / 1024 / 1024 | floor),
  heap_max_mb: (.metrics."solr.jvm"."memory.heap.max" / 1024 / 1024 | floor),
  heap_utilization_percent: ((.metrics."solr.jvm"."memory.heap.used" / .metrics."solr.jvm"."memory.heap.max") * 100 | floor),
  
  # Non-Heap Memory (Method area, compressed class space, etc.)
  non_heap_used_mb: (.metrics."solr.jvm"."memory.non-heap.used" / 1024 / 1024 | floor),
  non_heap_committed_mb: (.metrics."solr.jvm"."memory.non-heap.committed" / 1024 / 1024 | floor),
  
  # Memory Pressure Assessment
  memory_pressure: (if ((.metrics."solr.jvm"."memory.heap.used" / .metrics."solr.jvm"."memory.heap.max") * 100) > 85 
                    then "CRITICAL - Immediate action needed" 
                    elif ((.metrics."solr.jvm"."memory.heap.used" / .metrics."solr.jvm"."memory.heap.max") * 100) > 75 
                    then "HIGH - Plan scaling/tuning" 
                    elif ((.metrics."solr.jvm"."memory.heap.used" / .metrics."solr.jvm"."memory.heap.max") * 100) > 65 
                    then "MODERATE - Monitor closely" 
                    else "NORMAL" end),
  
  # JVM Uptime for context
  uptime_hours: (.metrics."solr.jvm".uptime / 1000 / 3600 | floor)
}'

# Solr GC Analysis  
curl -s "http://localhost:8999/solr/admin/metrics?group=jvm&wt=json" | jq '{
  # Extract GC metrics (naming varies by GC algorithm)
  gc_metrics: [.metrics."solr.jvm" | to_entries[] | select(.key | startswith("gc.")) | {
    gc_name: .key,
    value: .value,
    metric_type: (if (.key | contains("time")) then "time_ms" 
                  elif (.key | contains("count")) then "collections" 
                  else "other" end)
  }],
  
  # Calculate total GC overhead
  total_gc_time: ([.metrics."solr.jvm" | to_entries[] | select(.key | startswith("gc.") and (.key | contains("time"))) | .value] | add // 0),
  uptime_ms: .metrics."solr.jvm".uptime,
  gc_overhead_percent: (([.metrics."solr.jvm" | to_entries[] | select(.key | startswith("gc.") and (.key | contains("time"))) | .value] | add // 0) / .metrics."solr.jvm".uptime * 100 | floor),
  
  gc_health: (if (([.metrics."solr.jvm" | to_entries[] | select(.key | startswith("gc.") and (.key | contains("time"))) | .value] | add // 0) / .metrics."solr.jvm".uptime * 100) > 15 
              then "UNHEALTHY - Excessive GC overhead" 
              elif (([.metrics."solr.jvm" | to_entries[] | select(.key | startswith("gc.") and (.key | contains("time"))) | .value] | add // 0) / .metrics."solr.jvm".uptime * 100) > 8 
              then "SUBOPTIMAL - GC tuning needed" 
              else "HEALTHY" end)
}'
```

#### **⚙️ Solr Memory Configuration Strategies:**

##### **🎯 Solr Heap Sizing (Similar to Elasticsearch)**
```bash
echo "🎯 Solr Heap Sizing Analysis:"

# Solr follows similar heap sizing principles to Elasticsearch
system_memory_gb=$(free -g | awk 'NR==2{printf "%.0f", $2}')
recommended_solr_heap_gb=$((system_memory_gb / 2))

if [ $recommended_solr_heap_gb -gt 32 ]; then
  recommended_solr_heap_gb=32
fi

echo "System Memory: ${system_memory_gb}GB"
echo "Recommended Solr Heap: ${recommended_solr_heap_gb}GB"
echo ""
echo "🔧 Solr-Specific Heap Considerations:"
echo "   1. Faceting and grouping are memory-intensive"
echo "   2. Large result sets require more heap"
echo "   3. SolrCloud coordination uses heap memory"
echo "   4. Caching (filterCache, queryResultCache) uses heap"
echo ""

current_solr_heap_mb=$(curl -s "http://localhost:8999/solr/admin/metrics?group=jvm&wt=json" | jq '.metrics."solr.jvm"."memory.heap.max" / 1024 / 1024 | floor')
current_solr_heap_gb=$((current_solr_heap_mb / 1024))

echo "Current Solr Heap: ${current_solr_heap_gb}GB"

if [ $current_solr_heap_gb -ne $recommended_solr_heap_gb ]; then
  echo "⚠️  SOLR HEAP SIZE MISMATCH DETECTED"
  echo "   Current: ${current_solr_heap_gb}GB"
  echo "   Recommended: ${recommended_solr_heap_gb}GB"
  echo "   Action: Update SOLR_HEAP in solr.in.sh or docker environment"
fi
```

##### **🗑️ Solr GC Tuning (Platform Differences):**

```bash
echo "🗑️ Solr GC Tuning Recommendations:"
echo ""
echo "🔧 Solr GC Configuration by Use Case:"
echo ""
echo "📊 Real-time Search (Low Latency Priority):"
echo "   -XX:+UseG1GC"
echo "   -XX:MaxGCPauseMillis=100"
echo "   -XX:G1HeapRegionSize=16m"
echo "   # Optimize for consistent response times"
echo ""
echo "📊 Batch Processing (Throughput Priority):"
echo "   -XX:+UseParallelGC"
echo "   -XX:ParallelGCThreads=<CPU_CORES>"
echo "   # Better for bulk indexing operations"
echo ""
echo "📊 Large Collections (Memory Intensive):"
echo "   -XX:+UseG1GC"
echo "   -XX:G1HeapRegionSize=32m"
echo "   -XX:MaxGCPauseMillis=200"
echo "   -XX:G1NewSizePercent=20"
echo "   -XX:G1MaxNewSizePercent=30"
echo ""
echo "💡 Solr-Specific GC Considerations:"
echo "   - Faceting creates many temporary objects"
echo "   - Large facet results can cause GC pressure"
echo "   - SolrCloud replication affects GC patterns"
echo "   - Commit frequency impacts GC behavior"
```

##### **📊 Solr Memory Pool and Cache Analysis:**

```bash
echo "📊 Solr Cache Memory Analysis:"

# Analyze Solr's cache usage
curl -s "http://localhost:8999/solr/performance_baseline/admin/mbeans?stats=true&wt=json" | jq '{
  cache_stats: {
    # Filter Cache (most important for memory)
    filterCache: (.["solr-mbeans"][1].CACHE."/performance_baseline".filterCache | {
      size: .stats.size,
      maxSize: .stats.maxSize,
      evictions: .stats.evictions,
      hits: .stats.lookups - .stats.inserts,
      hit_ratio: ((.stats.lookups - .stats.inserts) / .stats.lookups * 100 | floor),
      memory_pressure: (if (.stats.size / .stats.maxSize * 100) > 90 
                        then "HIGH - Consider increasing maxSize" 
                        elif (.stats.evictions > (.stats.lookups * 0.1)) 
                        then "MODERATE - High eviction rate" 
                        else "NORMAL" end)
    }),
    
    # Query Result Cache
    queryResultCache: (.["solr-mbeans"][1].CACHE."/performance_baseline".queryResultCache | {
      size: .stats.size,
      maxSize: .stats.maxSize,
      evictions: .stats.evictions,
      hits: .stats.lookups - .stats.inserts,
      hit_ratio: ((.stats.lookups - .stats.inserts) / .stats.lookups * 100 | floor)
    }),
    
    # Document Cache
    documentCache: (.["solr-mbeans"][1].CACHE."/performance_baseline".documentCache | {
      size: .stats.size,
      maxSize: .stats.maxSize,
      evictions: .stats.evictions,
      hits: .stats.lookups - .stats.inserts,
      hit_ratio: ((.stats.lookups - .stats.inserts) / .stats.lookups * 100 | floor)
    })
  }
}'

echo ""
echo "💡 Solr Cache Tuning Guidelines:"
echo "   - filterCache: Most memory-intensive, tune size carefully"
echo "   - Hit ratios > 80% indicate good cache effectiveness"
echo "   - High eviction rates suggest undersized caches"
echo "   - Monitor cache sizes vs available heap memory"
```

---

## 🔄 **OpenSearch Memory Management**

### **🎯 OpenSearch Memory (Nearly Identical to Elasticsearch)**

```bash
echo "🔄 OpenSearch Memory Management:"
echo ""
echo "📊 OpenSearch inherits Elasticsearch memory patterns:"
echo "   - Same JVM heap sizing rules (50% of RAM, max 32GB)"
echo "   - Same GC algorithms and tuning approaches"
echo "   - Same off-heap memory considerations"
echo "   - Same memory pool structures"
echo ""
echo "🔍 Key Differences:"
echo "   - Open source licensing (no X-Pack memory features)"  
echo "   - Different default configurations in some versions"
echo "   - AWS OpenSearch Service has managed memory tuning"
echo "   - Community-driven performance optimizations"
echo ""

# If OpenSearch is running, use same commands as Elasticsearch
# but replace the endpoint
echo "📋 Use same memory analysis commands as Elasticsearch:"
echo "   Replace 'localhost:9199' with OpenSearch endpoint"
echo "   All JVM tuning parameters apply identically"
```

---

## 📊 **Memory Management Comparison Matrix**

### **🎯 Platform-Specific Memory Characteristics**

| Aspect | Elasticsearch | Solr | OpenSearch |
|--------|---------------|------|------------|
| **Heap Sizing** | 50% rule, max 32GB | Same principles | Same as ES |
| **GC Algorithm** | G1GC default | G1GC recommended | G1GC default |
| **Off-Heap Usage** | Aggregations, Lucene | Caches, Lucene | Same as ES |
| **Memory Pools** | Standard JVM pools | Standard + Solr caches | Same as ES |
| **Cache Types** | Query, filter, field data | Filter, query, document | Same as ES |
| **Memory Monitoring** | Rich APIs | JMX + Admin APIs | Same as ES |

### **💾 Memory Optimization Strategies**

#### **🔧 Universal Memory Best Practices:**

```bash
echo "🔧 Universal Memory Optimization Checklist:"
echo ""
echo "✅ HEAP SIZING:"
echo "   □ Never exceed 50% of system RAM"
echo "   □ Stay below 32GB for compressed OOPs"
echo "   □ Leave memory for OS file system cache"
echo "   □ Account for off-heap usage"
echo ""
echo "✅ GARBAGE COLLECTION:"
echo "   □ Use G1GC for most workloads"
echo "   □ Set reasonable pause targets (100-200ms)"
echo "   □ Monitor GC overhead (< 5% ideal)"
echo "   □ Tune based on actual workload patterns"
echo ""
echo "✅ MONITORING:"
echo "   □ Track heap utilization trends"
echo "   □ Monitor GC frequency and duration"
echo "   □ Watch for memory leaks"
echo "   □ Set up alerting for memory pressure"
echo ""
echo "✅ OPTIMIZATION:"
echo "   □ Optimize queries to reduce memory usage"
echo "   □ Tune cache sizes appropriately"
echo "   □ Use efficient data structures"
echo "   □ Regular memory profiling"
```

#### **⚠️ Common Memory Problems and Solutions:**

```bash
echo "⚠️  Common Memory Issues and Solutions:"
echo ""
echo "🚨 OutOfMemoryError:"
echo "   Symptoms: Node crashes, cluster instability"
echo "   Solutions: Increase heap, optimize queries, add nodes"
echo ""
echo "🚨 High GC Overhead:"
echo "   Symptoms: Slow responses, CPU spikes"
echo "   Solutions: Tune GC settings, reduce heap pressure"
echo ""
echo "🚨 Memory Leaks:"
echo "   Symptoms: Gradual memory increase, eventual OOM"
echo "   Solutions: Profile with tools, fix application bugs"
echo ""
echo "🚨 Cache Thrashing:"
echo "   Symptoms: High eviction rates, poor hit ratios"
echo "   Solutions: Increase cache sizes, optimize access patterns"
echo ""
echo "🚨 Off-Heap Pressure:"
echo "   Symptoms: System memory exhaustion despite heap headroom"
echo "   Solutions: Monitor direct memory, tune off-heap limits"
```

---

## 🎯 **Memory Tuning Action Plan**

### **📋 Production Memory Optimization Workflow:**

```bash
echo "📋 Memory Optimization Action Plan:"
echo ""
echo "PHASE 1: BASELINE MEASUREMENT"
echo "□ Document current memory usage patterns"
echo "□ Identify peak usage scenarios"
echo "□ Measure GC overhead and frequency"
echo "□ Profile off-heap memory usage"
echo ""
echo "PHASE 2: IDENTIFY BOTTLENECKS"
echo "□ Analyze heap utilization trends"
echo "□ Identify GC tuning opportunities"
echo "□ Assess cache effectiveness"
echo "□ Find memory-intensive queries/operations"
echo ""
echo "PHASE 3: IMPLEMENT OPTIMIZATIONS"
echo "□ Adjust heap sizes based on analysis"
echo "□ Tune GC algorithms and parameters"
echo "□ Optimize cache configurations"
echo "□ Refactor memory-intensive operations"
echo ""
echo "PHASE 4: VALIDATE & MONITOR"
echo "□ Measure performance improvements"
echo "□ Set up continuous memory monitoring"
echo "□ Establish alerting thresholds"
echo "□ Document configuration changes"
```

**🚀 With this memory management mastery, you can optimize JVM performance across all search platforms!**

**Next up: Monitoring - Native tools vs third-party solutions for each platform!** 📊
