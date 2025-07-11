#!/bin/bash
# 🎯 OpenSearch HA Setup Script
# Configures OpenSearch cluster for optimal learning environment
# Uses standardized HA endpoint: http://localhost:9399

set -e

# Configuration
OPENSEARCH_HA="http://localhost:9399"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 OpenSearch HA Setup${NC}"
echo -e "${BLUE}Endpoint: $OPENSEARCH_HA${NC}"
echo ""

# Function to wait for OpenSearch
wait_for_opensearch() {
    echo -e "${YELLOW}⏳ Waiting for OpenSearch cluster...${NC}"
    local attempt=1
    local max_attempts=30
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$OPENSEARCH_HA/_cluster/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ OpenSearch cluster is ready!${NC}"
            return 0
        fi
        echo -e "${YELLOW}   Attempt $attempt/$max_attempts...${NC}"
        sleep 5
        ((attempt++))
    done
    
    echo -e "${RED}❌ OpenSearch cluster not ready after $((max_attempts * 5)) seconds${NC}"
    return 1
}

# Wait for cluster
wait_for_opensearch

# Check cluster health
echo -e "${BLUE}🏥 Checking cluster health...${NC}"
HEALTH=$(curl -s "$OPENSEARCH_HA/_cluster/health")
STATUS=$(echo "$HEALTH" | jq -r '.status')
NODES=$(echo "$HEALTH" | jq -r '.number_of_nodes')

echo -e "${BLUE}   Status: $STATUS${NC}"
echo -e "${BLUE}   Nodes: $NODES${NC}"

# Create index templates for learning
echo -e "${BLUE}📋 Creating learning index templates...${NC}"

# Blog posts template
curl -X PUT "$OPENSEARCH_HA/_index_template/blog_posts_template" \
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
curl -X PUT "$OPENSEARCH_HA/_index_template/performance_template" \
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
curl -X PUT "$OPENSEARCH_HA/_component_template/scoring_settings" \
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
curl -X POST "$OPENSEARCH_HA/_aliases" \
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

# Configure OpenSearch-specific features
echo -e "${BLUE}🚀 Configuring OpenSearch-specific features...${NC}"

# Create index state management policy for log rotation
curl -X PUT "$OPENSEARCH_HA/_plugins/_ism/policies/learning_policy" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "description": "Learning environment log rotation policy",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "actions": [],
          "transitions": [
            {
              "state_name": "warm",
              "conditions": {
                "min_index_age": "7d"
              }
            }
          ]
        },
        {
          "name": "warm",
          "actions": [
            {
              "replica_count": {
                "number_of_replicas": 0
              }
            }
          ],
          "transitions": [
            {
              "state_name": "delete",
              "conditions": {
                "min_index_age": "30d"
              }
            }
          ]
        },
        {
          "name": "delete",
          "actions": [
            {
              "delete": {}
            }
          ]
        }
      ]
    }
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Index state management policy created${NC}"

# Setup alerting for learning environment
curl -X POST "$OPENSEARCH_HA/_plugins/_alerting/monitors" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "monitor",
    "name": "cluster_health_monitor",
    "monitor_type": "query_level_monitor",
    "enabled": true,
    "schedule": {
      "period": {
        "interval": 5,
        "unit": "MINUTES"
      }
    },
    "inputs": [
      {
        "search": {
          "indices": [".opendistro-alerting-config"],
          "query": {
            "size": 0,
            "query": {
              "match_all": {}
            }
          }
        }
      }
    ],
    "triggers": [
      {
        "query_level_trigger": {
          "id": "cluster_health_trigger",
          "name": "Cluster Health Alert",
          "severity": "1",
          "condition": {
            "script": {
              "source": "ctx.results[0].hits.total.value > 0",
              "lang": "painless"
            }
          },
          "actions": []
        }
      }
    ]
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Health monitoring configured${NC}"

# Configure search templates for common learning queries
echo -e "${BLUE}📝 Creating search templates...${NC}"

# Basic search template
curl -X PUT "$OPENSEARCH_HA/_scripts/basic_search" \
  -H "Content-Type: application/json" \
  -d '{
    "script": {
      "lang": "mustache",
      "source": {
        "query": {
          "bool": {
            "must": [
              {
                "multi_match": {
                  "query": "{{query_string}}",
                  "fields": ["title^2", "content"],
                  "type": "best_fields"
                }
              }
            ],
            "filter": [
              {
                "range": {
                  "published_date": {
                    "gte": "{{start_date||}now-1y}}"
                  }
                }
              }
            ]
          }
        },
        "size": "{{size||10}}",
        "from": "{{from||0}}"
      }
    }
  }' >/dev/null 2>&1

# Function scoring template
curl -X PUT "$OPENSEARCH_HA/_scripts/function_score_search" \
  -H "Content-Type: application/json" \
  -d '{
    "script": {
      "lang": "mustache",
      "source": {
        "query": {
          "function_score": {
            "query": {
              "multi_match": {
                "query": "{{query_string}}",
                "fields": ["title^2", "content"]
              }
            },
            "functions": [
              {
                "field_value_factor": {
                  "field": "view_count",
                  "factor": "{{view_factor||0.1}}",
                  "modifier": "log1p",
                  "missing": 0
                }
              },
              {
                "field_value_factor": {
                  "field": "like_count", 
                  "factor": "{{like_factor||0.2}}",
                  "modifier": "log1p",
                  "missing": 0
                }
              }
            ],
            "boost_mode": "multiply",
            "score_mode": "sum"
          }
        },
        "size": "{{size||10}}",
        "from": "{{from||0}}"
      }
    }
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Search templates created${NC}"

# Verify setup
echo -e "${BLUE}🔍 Verifying setup...${NC}"

# List templates
TEMPLATES=$(curl -s "$OPENSEARCH_HA/_index_template" | jq -r '.index_templates[].name' | grep -E "(blog|performance)" | wc -l)
echo -e "${BLUE}   Index templates: $TEMPLATES${NC}"

# List component templates  
COMPONENT_TEMPLATES=$(curl -s "$OPENSEARCH_HA/_component_template" | jq -r '.component_templates[].name' | grep -E "scoring" | wc -l)
echo -e "${BLUE}   Component templates: $COMPONENT_TEMPLATES${NC}"

# List search templates
SEARCH_TEMPLATES=$(curl -s "$OPENSEARCH_HA/_scripts" | jq -r 'keys[]' | grep -E "(search|score)" | wc -l)
echo -e "${BLUE}   Search templates: $SEARCH_TEMPLATES${NC}"

# Check ISM policies
ISM_POLICIES=$(curl -s "$OPENSEARCH_HA/_plugins/_ism/policies" | jq -r '.policies[].id' | wc -l)
echo -e "${BLUE}   ISM policies: $ISM_POLICIES${NC}"

echo -e "${GREEN}✅ OpenSearch HA setup complete!${NC}"
echo -e "${BLUE}Ready for learning phases 1-22${NC}"
