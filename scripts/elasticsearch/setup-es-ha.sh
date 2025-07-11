#!/bin/bash
# 🎯 Elasticsearch HA Setup Script
# Configures Elasticsearch cluster for optimal learning environment
# Uses standardized HA endpoint: http://localhost:9199

set -e

# Configuration
ELASTICSEARCH_HA="http://localhost:9199"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 Elasticsearch HA Setup${NC}"
echo -e "${BLUE}Endpoint: $ELASTICSEARCH_HA${NC}"
echo ""

# Function to wait for Elasticsearch
wait_for_elasticsearch() {
    echo -e "${YELLOW}⏳ Waiting for Elasticsearch cluster...${NC}"
    local attempt=1
    local max_attempts=30
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$ELASTICSEARCH_HA/_cluster/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Elasticsearch cluster is ready!${NC}"
            return 0
        fi
        echo -e "${YELLOW}   Attempt $attempt/$max_attempts...${NC}"
        sleep 5
        ((attempt++))
    done
    
    echo -e "${RED}❌ Elasticsearch cluster not ready after $((max_attempts * 5)) seconds${NC}"
    return 1
}

# Wait for cluster
wait_for_elasticsearch

# Check cluster health
echo -e "${BLUE}🏥 Checking cluster health...${NC}"
HEALTH=$(curl -s "$ELASTICSEARCH_HA/_cluster/health")
STATUS=$(echo "$HEALTH" | jq -r '.status')
NODES=$(echo "$HEALTH" | jq -r '.number_of_nodes')

echo -e "${BLUE}   Status: $STATUS${NC}"
echo -e "${BLUE}   Nodes: $NODES${NC}"

# Create index templates for learning
echo -e "${BLUE}📋 Creating learning index templates...${NC}"

# Blog posts template
curl -X PUT "$ELASTICSEARCH_HA/_index_template/blog_posts_template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["blog_posts*", "performance_*", "learning_*"],
    "template": {
      "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 1,
        "analysis": {
          "analyzer": {
            "blog_analyzer": {
              "type": "custom",
              "tokenizer": "standard",
              "filter": ["lowercase", "stop", "snowball"]
            },
            "search_analyzer": {
              "type": "custom", 
              "tokenizer": "standard",
              "filter": ["lowercase", "stop"]
            }
          }
        }
      },
      "mappings": {
        "properties": {
          "title": {
            "type": "text",
            "analyzer": "blog_analyzer",
            "search_analyzer": "search_analyzer",
            "fields": {
              "keyword": {"type": "keyword"}
            }
          },
          "content": {
            "type": "text",
            "analyzer": "blog_analyzer",
            "search_analyzer": "search_analyzer"
          },
          "author": {"type": "keyword"},
          "category": {"type": "keyword"},
          "tags": {"type": "keyword"},
          "published_date": {"type": "date"},
          "view_count": {"type": "integer"},
          "like_count": {"type": "integer"},
          "score_boost": {"type": "float", "value": 1.0}
        }
      }
    }
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Blog posts template created${NC}"

# Performance testing template
curl -X PUT "$ELASTICSEARCH_HA/_index_template/performance_template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["performance_*", "benchmark_*", "load_test_*"],
    "template": {
      "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 1,
        "refresh_interval": "5s"
      },
      "mappings": {
        "properties": {
          "timestamp": {"type": "date"},
          "operation": {"type": "keyword"},
          "duration_ms": {"type": "integer"},
          "success": {"type": "boolean"},
          "thread_id": {"type": "keyword"},
          "batch_size": {"type": "integer"}
        }
      }
    }
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Performance template created${NC}"

# Create component templates for advanced learning
curl -X PUT "$ELASTICSEARCH_HA/_component_template/scoring_settings" \
  -H "Content-Type: application/json" \
  -d '{
    "template": {
      "settings": {
        "similarity": {
          "custom_bm25": {
            "type": "BM25",
            "k1": 1.5,
            "b": 0.75
          },
          "custom_dfr": {
            "type": "DFR",
            "basic_model": "g",
            "after_effect": "l",
            "normalization": "h2",
            "normalization.h2.c": "3.0"
          }
        }
      }
    }
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Scoring component template created${NC}"

# Setup index aliases for easy management
curl -X POST "$ELASTICSEARCH_HA/_aliases" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      {
        "add": {
          "index": "blog_posts*",
          "alias": "learning_content"
        }
      },
      {
        "add": {
          "index": "performance_*",
          "alias": "performance_tests"
        }
      }
    ]
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Index aliases created${NC}"

# Verify setup
echo -e "${BLUE}🔍 Verifying setup...${NC}"

# List templates
TEMPLATES=$(curl -s "$ELASTICSEARCH_HA/_index_template" | jq -r '.index_templates[].name' | grep -E "(blog|performance)" | wc -l)
echo -e "${BLUE}   Index templates: $TEMPLATES${NC}"

# List component templates  
COMPONENT_TEMPLATES=$(curl -s "$ELASTICSEARCH_HA/_component_template" | jq -r '.component_templates[].name' | grep -E "scoring" | wc -l)
echo -e "${BLUE}   Component templates: $COMPONENT_TEMPLATES${NC}"

echo -e "${GREEN}✅ Elasticsearch HA setup complete!${NC}"
echo -e "${BLUE}Ready for learning phases 1-22${NC}"
