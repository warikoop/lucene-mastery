# Advanced Features Hands-On Practice Guide
## Unified HA Environment for Production-Ready Learning

## 🎯 **Overview**
This is your **practical laboratory** for experimenting with enterprise-level search configurations using our unified HA environment. All labs use the centralized setup with consistent HA endpoints across Elasticsearch, Solr, and OpenSearch.

## ✅ **Prerequisites**

### **1. Environment Setup**
Before starting these labs, ensure you have the unified HA environment running:

```bash
# Navigate to project root
cd /path/to/elastic-search

# Start unified HA environment (one-time setup)
./setup/unified-setup.sh

# Verify all clusters are healthy
./setup/verify-setup.sh
```

### **2. HA Endpoints Reference**
- **🔍 Elasticsearch HA**: `http://localhost:9199` (3-node cluster with load balancing)
- **☀️ Solr HA**: `http://localhost:8999` (3-node SolrCloud + Zookeeper)
- **🔎 OpenSearch HA**: `http://localhost:9399` (3-node cluster with load balancing)
- **📊 Admin Interfaces**: Kibana (5601), Solr Admin (8983), OpenSearch Dashboards (5602)

### **3. System Requirements**
- **RAM**: 8GB+ (HA clusters are optimized for learning)
- **Docker**: Latest version with Docker Compose
- **Disk Space**: 10GB free space recommended

---

## 🚀 **Lab 1: Elasticsearch HA Advanced Features**

### **Step 1: Verify HA Cluster Status**

Our unified setup provides a production-ready 3-node Elasticsearch cluster with load balancing:

```bash
# Check cluster health via HA endpoint
curl "http://localhost:9199/_cluster/health?pretty"

# View cluster nodes and roles
curl "http://localhost:9199/_cat/nodes?v&h=name,node.role,master,heap.percent,ram.percent"

# Check load balancer health
curl "http://localhost:9199/health"
```

---

## 🏗️ **Lab 2: Elasticsearch Advanced Index Templates & ILM**

Our unified setup already created a comprehensive index template (`blog_posts_template`) and an ILM policy (`blog_policy`). You can review them and experiment with creating new ones.

### **Step 1: Review Existing Index Template**

```bash
# Get the existing index template created by the setup script
curl "http://localhost:9199/_index_template/blog_posts_template?pretty"
```

### **Step 2: Review Existing ILM Policy**

```bash
# Get the existing ILM policy
curl "http://localhost:9199/_ilm/policy/blog_policy?pretty"
```

### **Step 3: Test Index Creation & Rollover**

The setup script has already created the initial index. You can add more documents to test the rollover functionality.

```bash
# Add sample documents to trigger rollover
for i in {1..50}; do
  curl -X POST "http://localhost:9199/blog_posts/_doc" -H 'Content-Type: application/json' -d'{
    "title": "Advanced Elasticsearch Tutorial '"$i"'",
    "content": "This is a comprehensive guide to Elasticsearch with detailed examples and practical demonstrations. Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "category": "elasticsearch",
    "tags": ["search", "database", "analytics"],
    "popularity_score": '$((RANDOM % 10))'.5,
    "engagement_score": '$((RANDOM % 8))'.2,
    "indexed_at": "2024-01-15T10:30:00Z",
    "published_at": "2024-01-09T12:00:00Z"
  }'
done

# Check index status to see if rollover occurred
curl "http://localhost:9199/_cat/indices/blog_posts*?v&s=creation.date:desc"
```

---

## 🔄 **Lab 3: Elasticsearch Advanced Sharding & Routing**

### **Step 1: Create a New Index with Custom Routing**

Let's create a new index to experiment with custom routing without affecting the main `blog_posts` index.

```bash
# Create index with custom routing
curl -X PUT "http://localhost:9199/user_specific_data" -H 'Content-Type: application/json' -d'{
  "settings": {
    "number_of_shards": 6,
    "number_of_replicas": 1
  },
  "mappings": {
    "_routing": {
      "required": true
    },
    "properties": {
      "title": {"type": "text"},
      "content": {"type": "text"},
      "user_id": {"type": "keyword"}
    }
  }
}'
```

### **Step 2: Test Custom Routing**

When indexing, you must provide the `routing` parameter.

```bash
# Index documents with custom routing keys
curl -X POST "http://localhost:9199/user_specific_data/_doc?routing=user123" -H 'Content-Type: application/json' -d'{
  "title": "My Personal Document",
  "content": "This content is for user 123.",
  "user_id": "user123"
}'

curl -X POST "http://localhost:9199/user_specific_data/_doc?routing=user456" -H 'Content-Type: application/json' -d'{
  "title": "Another User Document",
  "content": "This content is for user 456.",
  "user_id": "user456"
}'

# To search, you must also provide the routing key
curl "http://localhost:9199/user_specific_data/_search?routing=user123&pretty" -H 'Content-Type: application/json' -d'{
  "query": {
    "match": {
      "user_id": "user123"
    }
  }
}'
```

### **Step 3: Monitor Shard Distribution**

```bash
# Check shard allocation for the new index
curl "http://localhost:9199/_cat/shards/user_specific_data?v"
```

---

## ☀️ **Lab 4: SolrCloud HA Advanced Features**

### **Step 1: Verify HA Cluster Status**

Our unified setup provides a production-ready 3-node SolrCloud cluster with Zookeeper and load balancing. Use the HA endpoint `http://localhost:8999` for all operations.

```bash
# Check cluster status via HA endpoint
curl "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq

# View live nodes in the cluster
curl "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes

# Check load balancer health
curl "http://localhost:8999/health"
```

### **Step 2: Create a New Production Config Set**

The unified setup already provides a default config set. Let's create a new one for our production blog posts.

```bash
# Create advanced config set from the default
curl -X POST "http://localhost:8999/solr/admin/configs?action=CREATE&name=blog_production_config&baseConfigSet=_default"

# Add advanced schema fields to the new config set
curl -X POST "http://localhost:8999/solr/blog_production_config/schema" -H 'Content-Type: application/json' -d'{
  "add-field-type": [
    {
      "name": "text_general_edge_ngram",
      "class": "solr.TextField",
      "positionIncrementGap": "100",
      "analyzer": {
        "type": "index",
        "tokenizer": {"class": "solr.StandardTokenizerFactory"},
        "filters": [
          {"class": "solr.LowerCaseFilterFactory"},
          {"class": "solr.EdgeNGramFilterFactory", "minGramSize": "2", "maxGramSize": "15"}
        ]
      },
      "queryAnalyzer": {
        "tokenizer": {"class": "solr.StandardTokenizerFactory"},
        "filters": [{"class": "solr.LowerCaseFilterFactory"}]
      }
    }
  ],
  "add-field": [
    {"name": "title_txt", "type": "text_general", "stored": true, "indexed": true},
    {"name": "title_suggest", "type": "text_general_edge_ngram", "stored": false, "indexed": true},
    {"name": "content_txt", "type": "text_general", "stored": true, "indexed": true},
    {"name": "category_s", "type": "string", "stored": true, "indexed": true},
    {"name": "popularity_score_f", "type": "pfloat", "stored": true, "indexed": true}
  ],
  "add-copy-field": [
    {"source": "title_txt", "dest": "title_suggest"},
    {"source": "title_txt", "dest": "_text_"},
    {"source": "content_txt", "dest": "_text_"}
  ]
}'
```

### **Step 3: Create a New Sharded Collection**

```bash
# Create production collection with the new config set and advanced sharding
curl "http://localhost:8999/solr/admin/collections?action=CREATE&name=blog_posts_production&configName=blog_production_config&numShards=3&replicationFactor=2&maxShardsPerNode=2&router.name=compositeId&router.field=category_s"

# Verify collection creation
curl "http://localhost:8999/solr/admin/collections?action=COLSTATUS&collection=blog_posts_production&wt=json"
```

---

## 🔬 **Lab 5: OpenSearch & Cross-Platform Comparison**

### **Step 1: Verify OpenSearch HA Cluster Status**

```bash
# Check OpenSearch cluster health via HA endpoint
curl "http://localhost:9399/_cluster/health?pretty"

# View cluster nodes
curl "http://localhost:9399/_cat/nodes?v"
```

### **Step 2: Cross-Platform Monitoring Script**

Create a script `monitor_all.sh` to see the health of all clusters at once.

```bash
#!/bin/bash

echo "=== ELASTICSEARCH CLUSTER STATUS ==="
curl -s "http://localhost:9199/_cluster/health?pretty"

echo -e "\n=== SOLR CLUSTER STATUS ==="
curl -s "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq '.cluster.live_nodes'

echo -e "\n=== OPENSEARCH CLUSTER STATUS ==="
curl -s "http://localhost:9399/_cluster/health?pretty"

echo -e "\n=== MEMORY USAGE ==="
docker stats --no-stream --format \"table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\" | grep -E 'es-|solr|opensearch|zoo|nginx'
```

Make it executable and run:

```bash
chmod +x monitor_all.sh
./monitor_all.sh
```

---

## 💣 **Lab 6: HA Failure Scenarios & Recovery**

### **Step 1: Elasticsearch Node Failure Simulation**

```bash
# Stop one Elasticsearch node
docker stop es-master-2

# Check cluster health (should be yellow)
curl "http://localhost:9199/_cluster/health?pretty"

# Check shard allocation
curl "http://localhost:9199/_cat/shards?v&h=index,shard,prirep,state,node"

# Restart the node
docker start es-master-2

# Wait and check recovery
sleep 30
curl "http://localhost:9199/_cluster/health?pretty"
```

### **Step 2: Solr Node Failure Simulation**

```bash
# Stop one Solr node
docker stop solr2

# Check cluster status (should show one less live node)
curl "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes

# Restart the node
docker start solr2

# Wait and check recovery
sleep 30
curl "http://localhost:8999/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq .cluster.live_nodes
```

---

## 🧹 **Cleanup**

When you're done experimenting, use the unified teardown script.

```bash
# This will stop and remove all containers, networks, and volumes.
./setup/teardown.sh
```

---

## 🚀 **Congratulations!**

You now have hands-on experience with:
- ✅ **Production HA Architecture** - Multi-node clusters with load balancing
- ✅ **Advanced index templates** and lifecycle management  
- ✅ **Custom sharding and routing** strategies
- ✅ **Real-time monitoring** via HA endpoints
- ✅ **Failure simulation** and recovery procedures
- ✅ **Production-ready configurations** with proper endpoint management

**You've mastered enterprise-level search deployments with true high availability!** 🎯

This practical HA experience gives you the confidence to design and manage production search clusters that can handle real-world traffic and failures. Keep experimenting and scaling up your deployments!
