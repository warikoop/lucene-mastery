# Performance Tuning Guide

This guide provides high-level strategies for tuning the performance of your search clusters. For detailed, hands-on labs, please refer to the labs in `labs/phase-4-performance-production/`.

## 1. **JVM Heap Size**

- **Concept**: The most critical performance setting. The JVM heap is the memory allocated to the Java process running Elasticsearch, Solr, or OpenSearch.
- **Best Practice**:
  - Set the initial (`-Xms`) and maximum (`-Xmx`) heap size to the **same value** to prevent the JVM from resizing the heap at runtime, which is a costly process.
  - Do not allocate more than **50% of your system's RAM** to the heap, as the other 50% is needed for the operating system's file system cache (Lucene's best friend).
  - Do not exceed a heap size of **~30-32 GB**. Due to Java's use of compressed ordinary object pointers (oops), going above this threshold can lead to less efficient memory usage.
- **Configuration**: Edit the `jvm.options` file for the respective service.

## 2. **Indexing Performance**

- **Bulk Requests**: Always use bulk APIs for indexing. Sending documents one by one is extremely inefficient.
- **Refresh Interval**: The `refresh_interval` setting controls how often a new segment is created and made available for search. For heavy indexing loads, increase this value (e.g., `30s` or `-1` to disable) to reduce the overhead of segment creation. You can then manually refresh when needed.
- **Number of Replicas**: Set the number of replicas to `0` during the initial data load and then increase it afterward. This avoids the overhead of replicating every document as it's indexed.
- **Use Multiple Threads**: Use multiple client-side threads to send bulk requests to the cluster to take full advantage of its processing power.

## 3. **Query Performance**

- **Filter Context**: For yes/no questions (e.g., `status: "published"`), always use the `filter` context in Elasticsearch/OpenSearch instead of the `query` context. Filters are cached and are much faster.
- **Shard Sizing**: Shards that are too large or too small can hurt performance. A general guideline is to keep shard size between **10GB and 50GB**.
- **Caching**: Understand and leverage the different caches (filter cache, query cache, request cache). Ensure your hardware has enough RAM for the OS file system cache.
- **Profile API**: Use the Profile API (`"profile": true`) to get a detailed breakdown of how query time was spent. This is invaluable for identifying bottlenecks in slow queries.

## 4. **Hardware Considerations**

- **RAM**: More RAM is almost always better, especially for the OS file system cache.
- **Storage**: Use SSDs. They provide a massive performance improvement over spinning disks for I/O-intensive search workloads.
- **CPU**: A modern multi-core CPU is essential. Search is often CPU-bound, especially during heavy indexing and complex aggregations.
