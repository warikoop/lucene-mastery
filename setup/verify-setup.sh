#!/bin/bash
# 🔍 Environment Verification Script
# Verifies that all components of the learning environment are properly set up
# Uses standardized HA endpoints for comprehensive health checks

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ELASTICSEARCH_HA="http://localhost:9199"
SOLR_HA="http://localhost:8999"
OPENSEARCH_HA="http://localhost:9399"

# Admin interfaces
KIBANA_URL="http://localhost:5601"
SOLR_ADMIN_URL="http://localhost:8983/solr"
OPENSEARCH_DASHBOARDS_URL="http://localhost:5602"

echo -e "${CYAN}🔍 Learning Environment Verification${NC}"
echo -e "${BLUE}📋 Comprehensive health checks for all components${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${CYAN}===============================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}===============================================${NC}"
}

# Function to check HTTP endpoint
check_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    echo -e "${YELLOW}🔗 Checking $name...${NC}"
    
    if curl -s -f -o /dev/null "$url"; then
        echo -e "${GREEN}✅ $name is accessible at $url${NC}"
        return 0
    else
        echo -e "${RED}❌ $name is not accessible at $url${NC}"
        return 1
    fi
}

# Function to check cluster health
check_cluster_health() {
    local platform="$1"
    local health_url="$2"
    
    echo -e "${YELLOW}🏥 Checking $platform cluster health...${NC}"
    
    local response=$(curl -s "$health_url" 2>/dev/null)
    if [ $? -eq 0 ] && echo "$response" | jq . >/dev/null 2>&1; then
        case $platform in
            "Elasticsearch"|"OpenSearch")
                local status=$(echo "$response" | jq -r '.status // "unknown"')
                local nodes=$(echo "$response" | jq -r '.number_of_nodes // 0')
                local data_nodes=$(echo "$response" | jq -r '.number_of_data_nodes // 0')
                echo -e "${GREEN}✅ $platform cluster is healthy${NC}"
                echo -e "${BLUE}   Status: $status${NC}"
                echo -e "${BLUE}   Total nodes: $nodes${NC}"
                echo -e "${BLUE}   Data nodes: $data_nodes${NC}"
                ;;
            "Solr")
                local live_nodes=$(echo "$response" | jq -r '.cluster.live_nodes | length // 0' 2>/dev/null || echo "0")
                echo -e "${GREEN}✅ $platform cluster is healthy${NC}"
                echo -e "${BLUE}   Live nodes: $live_nodes${NC}"
                ;;
        esac
        return 0
    else
        echo -e "${RED}❌ $platform cluster health check failed${NC}"
        return 1
    fi
}

# Function to check data availability
check_data_availability() {
    local platform="$1"
    local endpoint="$2"
    local index_name="$3"
    
    echo -e "${YELLOW}📊 Checking $platform data availability...${NC}"
    
    case $platform in
        "Elasticsearch"|"OpenSearch")
            local count_url="$endpoint/$index_name/_count"
            local response=$(curl -s "$count_url" 2>/dev/null)
            if [ $? -eq 0 ]; then
                local count=$(echo "$response" | jq -r '.count // 0' 2>/dev/null || echo "0")
                if [ "$count" -gt 0 ]; then
                    echo -e "${GREEN}✅ $platform has $count documents in $index_name${NC}"
                else
                    echo -e "${YELLOW}⚠️  $platform has no documents in $index_name${NC}"
                fi
            else
                echo -e "${RED}❌ Cannot check $platform data availability${NC}"
            fi
            ;;
        "Solr")
            local query_url="$endpoint/$index_name/select?q=*:*&rows=0"
            local response=$(curl -s "$query_url" 2>/dev/null)
            if [ $? -eq 0 ]; then
                local count=$(echo "$response" | jq -r '.response.numFound // 0' 2>/dev/null || echo "0")
                if [ "$count" -gt 0 ]; then
                    echo -e "${GREEN}✅ $platform has $count documents in $index_name${NC}"
                else
                    echo -e "${YELLOW}⚠️  $platform has no documents in $index_name${NC}"
                fi
            else
                echo -e "${RED}❌ Cannot check $platform data availability${NC}"
            fi
            ;;
    esac
}

# Step 1: Check Docker environment
print_section "🐳 Step 1: Docker Environment Check"

echo -e "${BLUE}Checking Docker installation...${NC}"
if command -v docker >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker is installed${NC}"
    DOCKER_VERSION=$(docker --version)
    echo -e "${BLUE}   Version: $DOCKER_VERSION${NC}"
else
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

echo -e "${BLUE}Checking Docker Compose installation...${NC}"
if command -v docker-compose >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker Compose is installed${NC}"
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${BLUE}   Version: $COMPOSE_VERSION${NC}"
else
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

echo -e "${BLUE}Checking Docker daemon...${NC}"
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    exit 1
fi

# Step 2: Check running containers
print_section "📦 Step 2: Container Status Check"

echo -e "${BLUE}Checking running containers...${NC}"
RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(es-master|solr|opensearch|zoo|nginx|kibana)" || true)

if [ -n "$RUNNING_CONTAINERS" ]; then
    echo -e "${GREEN}✅ Learning environment containers are running:${NC}"
    echo "$RUNNING_CONTAINERS"
else
    echo -e "${YELLOW}⚠️  No learning environment containers are running${NC}"
    echo -e "${BLUE}Run 'docker-compose up -d' to start the environment${NC}"
fi

# Step 3: Check HA endpoints
print_section "🔗 Step 3: HA Endpoint Accessibility"

check_endpoint "Elasticsearch HA" "$ELASTICSEARCH_HA/_cluster/health"
check_endpoint "Solr HA" "$SOLR_HA/admin/info/system"
check_endpoint "OpenSearch HA" "$OPENSEARCH_HA/_cluster/health"

# Step 4: Check load balancer health
print_section "⚖️ Step 4: Load Balancer Health"

check_endpoint "Elasticsearch Load Balancer" "http://localhost:9199/health"
check_endpoint "Solr Load Balancer" "http://localhost:8999/health"
check_endpoint "OpenSearch Load Balancer" "http://localhost:9399/health"

# Step 5: Check cluster health
print_section "🏥 Step 5: Cluster Health Verification"

check_cluster_health "Elasticsearch" "$ELASTICSEARCH_HA/_cluster/health"
check_cluster_health "OpenSearch" "$OPENSEARCH_HA/_cluster/health"
check_cluster_health "Solr" "$SOLR_HA/admin/collections?action=CLUSTERSTATUS"

# Step 6: Check admin interfaces
print_section "🖥️ Step 6: Admin Interface Accessibility"

check_endpoint "Kibana" "$KIBANA_URL/api/status"
check_endpoint "Solr Admin" "$SOLR_ADMIN_URL/admin/info/system"
check_endpoint "OpenSearch Dashboards" "$OPENSEARCH_DASHBOARDS_URL/api/status"

# Step 7: Check data availability
print_section "📊 Step 7: Sample Data Verification"

check_data_availability "Elasticsearch" "$ELASTICSEARCH_HA" "blog_posts"
check_data_availability "OpenSearch" "$OPENSEARCH_HA" "blog_posts"
check_data_availability "Solr" "$SOLR_HA" "blog_posts"

# Step 8: Check file structure
print_section "📁 Step 8: File Structure Verification"

echo -e "${BLUE}Checking learning environment structure...${NC}"

REQUIRED_DIRS=("learning-materials" "labs" "scripts" "tools" "data" "configs" "setup" "docs")
MISSING_DIRS=()

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $dir/ directory exists${NC}"
    else
        echo -e "${RED}❌ $dir/ directory missing${NC}"
        MISSING_DIRS+=("$dir")
    fi
done

if [ ${#MISSING_DIRS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All required directories are present${NC}"
else
    echo -e "${YELLOW}⚠️  Missing directories: ${MISSING_DIRS[*]}${NC}"
fi

# Step 9: Final summary
print_section "📋 Step 9: Verification Summary"

echo -e "${BLUE}Environment verification complete!${NC}"
echo ""
echo -e "${CYAN}📊 Access Points:${NC}"
echo -e "${BLUE}   Elasticsearch HA: $ELASTICSEARCH_HA${NC}"
echo -e "${BLUE}   Solr HA: $SOLR_HA${NC}"
echo -e "${BLUE}   OpenSearch HA: $OPENSEARCH_HA${NC}"
echo -e "${BLUE}   Kibana: $KIBANA_URL${NC}"
echo -e "${BLUE}   Solr Admin: $SOLR_ADMIN_URL${NC}"
echo -e "${BLUE}   OpenSearch Dashboards: $OPENSEARCH_DASHBOARDS_URL${NC}"
echo ""
echo -e "${CYAN}📚 Next Steps:${NC}"
echo -e "${PURPLE}   1. Review 00-MASTER-LEARNING-GUIDE.md for learning path${NC}"
echo -e "${PURPLE}   2. Start with learning-materials/00-LEARNING-PATH-README.md${NC}"
echo -e "${PURPLE}   3. Execute labs from labs/ directories${NC}"
echo -e "${PURPLE}   4. Use scripts/ for platform-specific operations${NC}"
echo ""
echo -e "${GREEN}🎯 Ready for novice → Senior Staff Engineer transformation!${NC}"
