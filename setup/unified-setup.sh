#!/bin/bash
# 🎯 Unified Learning Environment Setup Script
# One-time setup for Elasticsearch + Solr + OpenSearch HA clusters
# Supports all learning phases from foundations to Senior Staff Engineer expertise

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# HA Endpoints
ELASTICSEARCH_HA="http://localhost:9199"
SOLR_HA="http://localhost:8999"
OPENSEARCH_HA="http://localhost:9399"

# Health check URLs
ES_HEALTH="$ELASTICSEARCH_HA/_cluster/health"
SOLR_HEALTH="$SOLR_HA/admin/collections?action=CLUSTERSTATUS"
OS_HEALTH="$OPENSEARCH_HA/_cluster/health"

echo -e "${CYAN}🎯 Lucene Ecosystem Learning Environment Setup${NC}"
echo -e "${BLUE}📚 Setting up Elasticsearch + Solr + OpenSearch HA clusters${NC}"
echo -e "${PURPLE}🎓 Target: Novice → Senior Staff Engineer expertise${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${CYAN}===============================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}===============================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for service health
wait_for_service() {
    local service_name="$1"
    local health_url="$2"
    local max_attempts="${3:-60}"
    local attempt=1
    
    echo -e "${YELLOW}⏳ Waiting for $service_name to be healthy...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$health_url" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is healthy!${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}   Attempt $attempt/$max_attempts - $service_name not ready yet...${NC}"
        sleep 10
        ((attempt++))
    done
    
    echo -e "${RED}❌ $service_name failed to become healthy after $((max_attempts * 10)) seconds${NC}"
    return 1
}

# Function to check cluster status
check_cluster_status() {
    local platform="$1"
    local health_url="$2"
    
    echo -e "${BLUE}🔍 Checking $platform cluster status...${NC}"
    
    if curl -s "$health_url" | jq . >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $platform cluster is responding with valid JSON${NC}"
        
        # Platform-specific status checks
        case $platform in
            "Elasticsearch"|"OpenSearch")
                local status=$(curl -s "$health_url" | jq -r '.status // "unknown"')
                local nodes=$(curl -s "$health_url" | jq -r '.number_of_nodes // 0')
                echo -e "${BLUE}   Status: $status, Nodes: $nodes${NC}"
                ;;
            "Solr")
                echo -e "${BLUE}   Solr cluster status retrieved successfully${NC}"
                ;;
        esac
        return 0
    else
        echo -e "${RED}❌ $platform cluster health check failed${NC}"
        return 1
    fi
}

# Step 1: Environment validation
print_section "🔍 Step 1: Environment Validation"

echo -e "${BLUE}Checking required tools...${NC}"

if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

if ! command_exists curl; then
    echo -e "${RED}❌ curl is not installed. Please install curl first.${NC}"
    exit 1
fi

if ! command_exists jq; then
    echo -e "${YELLOW}⚠️  jq is not installed. Installing jq for JSON parsing...${NC}"
    # Try to install jq (platform-specific)
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command_exists yum; then
        sudo yum install -y jq
    elif command_exists brew; then
        brew install jq
    else
        echo -e "${RED}❌ Please install jq manually for JSON parsing${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ All required tools are available${NC}"

# Check Docker daemon
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker daemon is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker daemon is running${NC}"

# Check available resources
echo -e "${BLUE}Checking system resources...${NC}"
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_MEM" -lt 8 ]; then
    echo -e "${YELLOW}⚠️  Warning: System has ${TOTAL_MEM}GB RAM. Recommended: 8GB+ for optimal performance${NC}"
else
    echo -e "${GREEN}✅ System has ${TOTAL_MEM}GB RAM - sufficient for HA clusters${NC}"
fi

# Step 2: Start all services
print_section "🚀 Step 2: Starting All Services"

echo -e "${BLUE}Starting unified HA environment...${NC}"
echo -e "${PURPLE}This will start:${NC}"
echo -e "${PURPLE}  • Elasticsearch 3-node HA cluster${NC}"
echo -e "${PURPLE}  • Solr 3-node HA cluster + Zookeeper ensemble${NC}"
echo -e "${PURPLE}  • OpenSearch 3-node HA cluster${NC}"
echo -e "${PURPLE}  • Nginx load balancer with HA endpoints${NC}"
echo -e "${PURPLE}  • Kibana and OpenSearch Dashboards${NC}"
echo ""

cd "$PROJECT_ROOT"

echo -e "${BLUE}Pulling latest images...${NC}"
docker-compose pull

echo -e "${BLUE}Starting services in background...${NC}"
docker-compose up -d

echo -e "${GREEN}✅ All services started in background${NC}"

# Step 3: Wait for cluster formation
print_section "⏳ Step 3: Waiting for Cluster Formation"

echo -e "${YELLOW}This may take 5-10 minutes for all clusters to form...${NC}"

# Wait for Zookeeper ensemble first (required for Solr)
echo -e "${BLUE}🐘 Waiting for Zookeeper ensemble...${NC}"
sleep 30  # Give Zookeeper time to start

# Wait for each service to be healthy
wait_for_service "Elasticsearch" "$ES_HEALTH" 60
wait_for_service "OpenSearch" "$OS_HEALTH" 60

# Wait longer for Solr (depends on Zookeeper)
echo -e "${BLUE}☀️ Waiting for Solr cluster (depends on Zookeeper)...${NC}"
sleep 60  # Additional time for SolrCloud formation
wait_for_service "Solr" "$SOLR_HA/admin/info/system" 60

# Wait for Nginx load balancer
wait_for_service "Nginx Load Balancer" "http://localhost:9199/health" 30

echo -e "${GREEN}✅ All clusters are healthy and ready!${NC}"

# Step 4: Verify cluster status
print_section "🔧 Step 4: Cluster Status Verification"

check_cluster_status "Elasticsearch" "$ES_HEALTH"
check_cluster_status "OpenSearch" "$OS_HEALTH"
check_cluster_status "Solr" "$SOLR_HEALTH"

# Step 5: Create initial configurations
print_section "⚙️ Step 5: Initial Configuration Setup"

echo -e "${BLUE}Setting up initial configurations...${NC}"

# Create index templates and mappings
echo -e "${YELLOW}📋 Creating index templates...${NC}"

# Elasticsearch index template for blog posts
curl -X PUT "$ELASTICSEARCH_HA/_index_template/blog_posts_template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["blog_posts*", "performance_*"],
    "template": {
      "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 1,
        "analysis": {
          "analyzer": {
            "blog_analyzer": {
              "type": "custom",
              "tokenizer": "standard",
              "filter": ["lowercase", "stop"]
            }
          }
        }
      },
      "mappings": {
        "properties": {
          "title": {"type": "text", "analyzer": "blog_analyzer"},
          "content": {"type": "text", "analyzer": "blog_analyzer"},
          "author": {"type": "keyword"},
          "category": {"type": "keyword"},
          "tags": {"type": "keyword"},
          "published_date": {"type": "date"},
          "view_count": {"type": "integer"},
          "like_count": {"type": "integer"}
        }
      }
    }
  }' >/dev/null 2>&1

# OpenSearch index template
curl -X PUT "$OPENSEARCH_HA/_index_template/blog_posts_template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["blog_posts*", "performance_*"],
    "template": {
      "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 1,
        "analysis": {
          "analyzer": {
            "blog_analyzer": {
              "type": "custom",
              "tokenizer": "standard",
              "filter": ["lowercase", "stop"]
            }
          }
        }
      },
      "mappings": {
        "properties": {
          "title": {"type": "text", "analyzer": "blog_analyzer"},
          "content": {"type": "text", "analyzer": "blog_analyzer"},
          "author": {"type": "keyword"},
          "category": {"type": "keyword"},
          "tags": {"type": "keyword"},
          "published_date": {"type": "date"},
          "view_count": {"type": "integer"},
          "like_count": {"type": "integer"}
        }
      }
    }
  }' >/dev/null 2>&1

echo -e "${GREEN}✅ Index templates created${NC}"

# Create Solr collections
echo -e "${YELLOW}☀️ Creating Solr collections...${NC}"

# Create blog_posts collection
curl -s "$SOLR_HA/admin/collections?action=CREATE&name=blog_posts&numShards=3&replicationFactor=2&collection.configName=_default" >/dev/null 2>&1

# Create performance collections
curl -s "$SOLR_HA/admin/collections?action=CREATE&name=performance_baseline&numShards=3&replicationFactor=2&collection.configName=_default" >/dev/null 2>&1

echo -e "${GREEN}✅ Solr collections created${NC}"

# Step 6: Load sample datasets
print_section "📊 Step 6: Loading Sample Datasets"

echo -e "${BLUE}Loading sample datasets for hands-on learning...${NC}"

# Create sample blog post data if it doesn't exist
BLOG_DATA_FILE="$PROJECT_ROOT/data/blog-posts/sample-blog-posts.json"
if [ ! -f "$BLOG_DATA_FILE" ]; then
    echo -e "${YELLOW}📝 Creating sample blog post dataset...${NC}"
    
    mkdir -p "$PROJECT_ROOT/data/blog-posts"
    
    cat > "$BLOG_DATA_FILE" << 'EOF'
{"index": {"_index": "blog_posts"}}
{"title": "Introduction to Elasticsearch", "content": "Elasticsearch is a distributed search and analytics engine built on Apache Lucene", "author": "tech_writer", "category": "technology", "tags": ["elasticsearch", "search", "lucene"], "published_date": "2024-01-01", "view_count": 150, "like_count": 25}
{"index": {"_index": "blog_posts"}}
{"title": "Understanding Apache Solr", "content": "Apache Solr is an open-source enterprise search platform built on Apache Lucene", "author": "search_expert", "category": "technology", "tags": ["solr", "search", "apache"], "published_date": "2024-01-02", "view_count": 120, "like_count": 18}
{"index": {"_index": "blog_posts"}}
{"title": "OpenSearch Deep Dive", "content": "OpenSearch is a community-driven, open-source search and analytics suite", "author": "dev_advocate", "category": "technology", "tags": ["opensearch", "analytics", "search"], "published_date": "2024-01-03", "view_count": 200, "like_count": 35}
{"index": {"_index": "blog_posts"}}
{"title": "Lucene Internals Explained", "content": "Apache Lucene provides powerful indexing and search features with segment-based architecture", "author": "lucene_guru", "category": "deep-tech", "tags": ["lucene", "internals", "segments"], "published_date": "2024-01-04", "view_count": 95, "like_count": 12}
{"index": {"_index": "blog_posts"}}
{"title": "Performance Tuning Search Engines", "content": "Optimizing search performance requires understanding of indexing strategies and query patterns", "author": "perf_engineer", "category": "performance", "tags": ["performance", "tuning", "optimization"], "published_date": "2024-01-05", "view_count": 180, "like_count": 30}
EOF
    
    echo -e "${GREEN}✅ Sample blog dataset created${NC}"
fi

# Load data into Elasticsearch
echo -e "${YELLOW}📥 Loading data into Elasticsearch...${NC}"
curl -s -X POST "$ELASTICSEARCH_HA/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary "@$BLOG_DATA_FILE" >/dev/null 2>&1

# Load data into OpenSearch
echo -e "${YELLOW}📥 Loading data into OpenSearch...${NC}"
curl -s -X POST "$OPENSEARCH_HA/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary "@$BLOG_DATA_FILE" >/dev/null 2>&1

echo -e "${GREEN}✅ Sample data loaded into all platforms${NC}"

# Step 7: Final verification
print_section "✅ Step 7: Final Verification"

echo -e "${BLUE}Running comprehensive health checks...${NC}"

# Check document counts
ES_DOC_COUNT=$(curl -s "$ELASTICSEARCH_HA/blog_posts/_count" | jq '.count // 0')
OS_DOC_COUNT=$(curl -s "$OPENSEARCH_HA/blog_posts/_count" | jq '.count // 0')
SOLR_DOC_COUNT=$(curl -s "$SOLR_HA/admin/collections?action=CLUSTERSTATUS" | jq '.cluster.collections.blog_posts.shards | to_entries[] | .value.replicas[] | .stats.numDocs // 0' | awk '{sum += $1} END {print sum+0}')

echo -e "${BLUE}📊 Document counts:${NC}"
echo -e "${BLUE}   Elasticsearch: $ES_DOC_COUNT documents${NC}"
echo -e "${BLUE}   OpenSearch: $OS_DOC_COUNT documents${NC}"
echo -e "${BLUE}   Solr: $SOLR_DOC_COUNT documents${NC}"

# Test HA endpoints
echo -e "${BLUE}🔗 Testing HA endpoints:${NC}"

if curl -s -f "$ELASTICSEARCH_HA/_cluster/health" >/dev/null; then
    echo -e "${GREEN}   ✅ Elasticsearch HA: $ELASTICSEARCH_HA${NC}"
else
    echo -e "${RED}   ❌ Elasticsearch HA endpoint failed${NC}"
fi

if curl -s -f "$SOLR_HA/admin/info/system" >/dev/null; then
    echo -e "${GREEN}   ✅ Solr HA: $SOLR_HA${NC}"
else
    echo -e "${RED}   ❌ Solr HA endpoint failed${NC}"
fi

if curl -s -f "$OPENSEARCH_HA/_cluster/health" >/dev/null; then
    echo -e "${GREEN}   ✅ OpenSearch HA: $OPENSEARCH_HA${NC}"
else
    echo -e "${RED}   ❌ OpenSearch HA endpoint failed${NC}"
fi

# Step 8: Success summary
print_section "🎉 Setup Complete!"

echo -e "${GREEN}✅ All systems ready for comprehensive learning journey!${NC}"
echo ""
echo -e "${CYAN}📋 Access Points:${NC}"
echo -e "${BLUE}   Elasticsearch HA: http://localhost:9199${NC}"
echo -e "${BLUE}   Solr HA: http://localhost:8999${NC}"
echo -e "${BLUE}   OpenSearch HA: http://localhost:9399${NC}"
echo -e "${BLUE}   Kibana: http://localhost:5601${NC}"
echo -e "${BLUE}   Solr Admin: http://localhost:8983/solr${NC}"
echo -e "${BLUE}   OpenSearch Dashboards: http://localhost:5602${NC}"
echo ""
echo -e "${CYAN}📚 Next Steps:${NC}"
echo -e "${PURPLE}   1. Start with: learning-materials/00-LEARNING-PATH-README.md${NC}"
echo -e "${PURPLE}   2. Follow sequential learning path: 01 → 02 → ... → 22${NC}"
echo -e "${PURPLE}   3. Execute labs independently from labs/ folders${NC}"
echo -e "${PURPLE}   4. Use scripts/ for specific technology operations${NC}"
echo ""
echo -e "${CYAN}🎯 Learning Journey:${NC}"
echo -e "${PURPLE}   Phase 1 (01-03): Lucene Foundations${NC}"
echo -e "${PURPLE}   Phase 2 (04-05): Environment Setup${NC}"
echo -e "${PURPLE}   Phase 3 (06-07): Core Concepts${NC}"
echo -e "${PURPLE}   Phase 4 (08-10): Search Fundamentals${NC}"
echo -e "${PURPLE}   Phase 5 (11-13): Advanced Scoring${NC}"
echo -e "${PURPLE}   Phase 6 (14-18): Performance & Production${NC}"
echo -e "${PURPLE}   Phase 7 (19-20): Production Reality${NC}"
echo -e "${PURPLE}   Phase 8 (21-22): Advanced Testing & Strategy${NC}"
echo ""
echo -e "${GREEN}🏆 GOAL: Transform from novice to Senior Staff Engineer expertise!${NC}"
echo -e "${GREEN}🚀 Happy Learning!${NC}"
echo ""
