#!/bin/bash
# 🎯 Solr HA Setup Script
# Configures SolrCloud cluster for optimal learning environment
# Uses standardized HA endpoint: http://localhost:8999

set -e

# Configuration
SOLR_HA="http://localhost:8999"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}☀️ Solr HA Setup${NC}"
echo -e "${BLUE}Endpoint: $SOLR_HA${NC}"
echo ""

# Function to wait for Solr
wait_for_solr() {
    echo -e "${YELLOW}⏳ Waiting for SolrCloud cluster...${NC}"
    local attempt=1
    local max_attempts=30
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$SOLR_HA/admin/info/system" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ SolrCloud cluster is ready!${NC}"
            return 0
        fi
        echo -e "${YELLOW}   Attempt $attempt/$max_attempts...${NC}"
        sleep 5
        ((attempt++))
    done
    
    echo -e "${RED}❌ SolrCloud cluster not ready after $((max_attempts * 5)) seconds${NC}"
    return 1
}

# Wait for cluster
wait_for_solr

# Check cluster status
echo -e "${BLUE}🏥 Checking cluster status...${NC}"
CLUSTER_STATUS=$(curl -s "$SOLR_HA/admin/collections?action=CLUSTERSTATUS")
LIVE_NODES=$(echo "$CLUSTER_STATUS" | jq -r '.cluster.live_nodes | length')

echo -e "${BLUE}   Live nodes: $LIVE_NODES${NC}"

# Create collections for learning
echo -e "${BLUE}📚 Creating learning collections...${NC}"

# Blog posts collection
echo -e "${YELLOW}   Creating blog_posts collection...${NC}"
curl -s "$SOLR_HA/admin/collections?action=CREATE&name=blog_posts&numShards=3&replicationFactor=2&collection.configName=_default" >/dev/null 2>&1

# Performance testing collection
echo -e "${YELLOW}   Creating performance_baseline collection...${NC}"
curl -s "$SOLR_HA/admin/collections?action=CREATE&name=performance_baseline&numShards=3&replicationFactor=2&collection.configName=_default" >/dev/null 2>&1

# Load testing collection
echo -e "${YELLOW}   Creating load_test collection...${NC}"
curl -s "$SOLR_HA/admin/collections?action=CREATE&name=load_test&numShards=3&replicationFactor=2&collection.configName=_default" >/dev/null 2>&1

# Benchmark collection
echo -e "${YELLOW}   Creating benchmark collection...${NC}"
curl -s "$SOLR_HA/admin/collections?action=CREATE&name=benchmark&numShards=3&replicationFactor=2&collection.configName=_default" >/dev/null 2>&1

echo -e "${GREEN}✅ Learning collections created${NC}"

# Configure schema for blog_posts collection
echo -e "${BLUE}📋 Configuring blog_posts schema...${NC}"

# Add field definitions
curl -X POST "$SOLR_HA/api/cores/blog_posts_shard1_replica_n1/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": [
      {
        "name": "title",
        "type": "text_general",
        "stored": true,
        "indexed": true
      },
      {
        "name": "content", 
        "type": "text_general",
        "stored": true,
        "indexed": true
      },
      {
        "name": "author",
        "type": "string",
        "stored": true,
        "indexed": true
      },
      {
        "name": "category",
        "type": "string", 
        "stored": true,
        "indexed": true
      },
      {
        "name": "tags",
        "type": "strings",
        "stored": true,
        "indexed": true
      },
      {
        "name": "published_date",
        "type": "pdate",
        "stored": true,
        "indexed": true
      },
      {
        "name": "view_count",
        "type": "pint",
        "stored": true,
        "indexed": true
      },
      {
        "name": "like_count",
        "type": "pint",
        "stored": true,
        "indexed": true
      },
      {
        "name": "score_boost",
        "type": "pfloat",
        "stored": true,
        "indexed": true,
        "default": 1.0
      }
    ]
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Blog posts schema configured${NC}"

# Configure schema for performance collections
echo -e "${BLUE}📊 Configuring performance schema...${NC}"

curl -X POST "$SOLR_HA/api/cores/performance_baseline_shard1_replica_n1/schema" \
  -H "Content-Type: application/json" \
  -d '{
    "add-field": [
      {
        "name": "timestamp",
        "type": "pdate",
        "stored": true,
        "indexed": true
      },
      {
        "name": "operation",
        "type": "string",
        "stored": true,
        "indexed": true
      },
      {
        "name": "duration_ms",
        "type": "pint",
        "stored": true,
        "indexed": true
      },
      {
        "name": "success",
        "type": "boolean",
        "stored": true,
        "indexed": true
      },
      {
        "name": "thread_id",
        "type": "string",
        "stored": true,
        "indexed": true
      },
      {
        "name": "batch_size",
        "type": "pint",
        "stored": true,
        "indexed": true
      }
    ]
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Performance schema configured${NC}"

# Create collection aliases for easy management
echo -e "${BLUE}🔗 Creating collection aliases...${NC}"

curl -s "$SOLR_HA/admin/collections?action=CREATEALIAS&name=learning_content&collections=blog_posts" >/dev/null 2>&1

curl -s "$SOLR_HA/admin/collections?action=CREATEALIAS&name=performance_tests&collections=performance_baseline,load_test,benchmark" >/dev/null 2>&1

echo -e "${GREEN}✅ Collection aliases created${NC}"

# Configure request handlers for advanced scoring
echo -e "${BLUE}🎯 Configuring advanced scoring handlers...${NC}"

# Add function scoring request handler
curl -X POST "$SOLR_HA/api/cores/blog_posts_shard1_replica_n1/config" \
  -H "Content-Type: application/json" \
  -d '{
    "add-requesthandler": {
      "name": "/function_score",
      "class": "solr.SearchHandler",
      "defaults": {
        "defType": "edismax",
        "qf": "title^2.0 content^1.0",
        "pf": "title^3.0 content^1.5",
        "bf": "sum(like_count,view_count)",
        "boost": "if(exists(score_boost),score_boost,1.0)"
      }
    }
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Function scoring handler configured${NC}"

# Verify setup
echo -e "${BLUE}🔍 Verifying setup...${NC}"

# List collections
COLLECTIONS=$(curl -s "$SOLR_HA/admin/collections?action=LIST" | jq -r '.collections | length')
echo -e "${BLUE}   Collections: $COLLECTIONS${NC}"

# List aliases
ALIASES=$(curl -s "$SOLR_HA/admin/collections?action=LISTALIASES" | jq -r '.aliases | length')
echo -e "${BLUE}   Aliases: $ALIASES${NC}"

# Check cluster health
CLUSTER_HEALTH=$(curl -s "$SOLR_HA/admin/collections?action=CLUSTERSTATUS" | jq -r '.cluster.live_nodes | length')
echo -e "${BLUE}   Healthy nodes: $CLUSTER_HEALTH${NC}"

echo -e "${GREEN}✅ SolrCloud HA setup complete!${NC}"
echo -e "${BLUE}Ready for learning phases 1-22${NC}"
