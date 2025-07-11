#!/bin/bash
# 🧹 Environment Teardown Script
# Safely cleans up the learning environment with data preservation options
# Provides multiple cleanup levels from graceful shutdown to complete reset

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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

echo -e "${CYAN}🧹 Learning Environment Teardown${NC}"
echo -e "${BLUE}📋 Safe cleanup with multiple options${NC}"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${CYAN}===============================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}===============================================${NC}"
}

# Function to confirm action
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    echo -e "${YELLOW}⚠️  $message${NC}"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Operation cancelled.${NC}"
        return 1
    fi
    return 0
}

# Display teardown options
print_section "🎯 Teardown Options"

echo -e "${BLUE}Choose teardown level:${NC}"
echo -e "${GREEN}1) Graceful Stop${NC} - Stop services, preserve all data"
echo -e "${YELLOW}2) Stop & Remove Containers${NC} - Remove containers, preserve volumes"
echo -e "${PURPLE}3) Complete Reset${NC} - Remove everything including data"
echo -e "${RED}4) Nuclear Option${NC} - Remove everything + Docker cleanup"
echo ""

read -p "Select option (1-4): " -n 1 -r OPTION
echo ""

case $OPTION in
    1)
        # Graceful Stop
        print_section "🛑 Graceful Stop - Preserving All Data"
        
        echo -e "${BLUE}Stopping all services gracefully...${NC}"
        cd "$PROJECT_ROOT"
        docker-compose stop
        
        echo -e "${GREEN}✅ All services stopped gracefully${NC}"
        echo -e "${BLUE}💾 All data preserved in Docker volumes${NC}"
        echo -e "${CYAN}📋 To restart: docker-compose start${NC}"
        ;;
        
    2)
        # Stop & Remove Containers
        print_section "📦 Stop & Remove Containers - Preserving Volumes"
        
        if confirm_action "This will remove all containers but preserve data volumes"; then
            echo -e "${BLUE}Stopping and removing containers...${NC}"
            cd "$PROJECT_ROOT"
            docker-compose down
            
            echo -e "${GREEN}✅ Containers removed successfully${NC}"
            echo -e "${BLUE}💾 Data volumes preserved${NC}"
            echo -e "${CYAN}📋 To restart: docker-compose up -d${NC}"
        fi
        ;;
        
    3)
        # Complete Reset
        print_section "🔄 Complete Reset - Removing All Data"
        
        if confirm_action "This will remove ALL containers and data volumes. This cannot be undone!"; then
            echo -e "${RED}⚠️  Performing complete reset...${NC}"
            cd "$PROJECT_ROOT"
            
            # Stop and remove everything
            docker-compose down -v --remove-orphans
            
            # Remove any remaining project-specific volumes
            echo -e "${BLUE}Cleaning up any remaining volumes...${NC}"
            docker volume ls -q | grep -E "(es-data|solr-data|opensearch-data|zoo.*-data)" | xargs -r docker volume rm || true
            
            echo -e "${GREEN}✅ Complete reset performed${NC}"
            echo -e "${RED}💥 All data permanently deleted${NC}"
            echo -e "${CYAN}📋 To restart: ./setup/unified-setup.sh${NC}"
        fi
        ;;
        
    4)
        # Nuclear Option
        print_section "💥 Nuclear Option - Complete Docker Cleanup"
        
        echo -e "${RED}⚠️  WARNING: This will affect your entire Docker environment!${NC}"
        echo -e "${RED}This will remove:${NC}"
        echo -e "${RED}  • All learning environment containers and volumes${NC}"
        echo -e "${RED}  • All unused Docker networks${NC}"
        echo -e "${RED}  • All unused Docker images${NC}"
        echo -e "${RED}  • Docker build cache${NC}"
        echo ""
        
        if confirm_action "Proceed with nuclear cleanup? This affects your entire Docker environment!"; then
            echo -e "${RED}💥 Performing nuclear cleanup...${NC}"
            cd "$PROJECT_ROOT"
            
            # Stop learning environment
            docker-compose down -v --remove-orphans || true
            
            # Remove project-specific resources
            docker volume ls -q | grep -E "(lucene-learning|es-data|solr-data|opensearch-data|zoo.*-data)" | xargs -r docker volume rm || true
            docker network ls -q | grep -E "lucene.*network" | xargs -r docker network rm || true
            
            # System-wide cleanup
            echo -e "${BLUE}Cleaning unused containers...${NC}"
            docker container prune -f || true
            
            echo -e "${BLUE}Cleaning unused images...${NC}"
            docker image prune -f || true
            
            echo -e "${BLUE}Cleaning unused networks...${NC}"
            docker network prune -f || true
            
            echo -e "${BLUE}Cleaning unused volumes...${NC}"
            docker volume prune -f || true
            
            echo -e "${BLUE}Cleaning build cache...${NC}"
            docker builder prune -f || true
            
            echo -e "${GREEN}✅ Nuclear cleanup completed${NC}"
            echo -e "${RED}💥 All Docker resources cleaned${NC}"
            echo -e "${CYAN}📋 To restart: ./setup/unified-setup.sh${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}❌ Invalid option selected${NC}"
        exit 1
        ;;
esac

# Display final status
print_section "📊 Teardown Complete"

echo -e "${BLUE}Checking remaining containers...${NC}"
REMAINING_CONTAINERS=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(es-master|solr|opensearch|zoo|nginx|kibana)" || true)

if [ -n "$REMAINING_CONTAINERS" ]; then
    echo -e "${YELLOW}⚠️  Some containers still exist:${NC}"
    echo "$REMAINING_CONTAINERS"
else
    echo -e "${GREEN}✅ No learning environment containers remaining${NC}"
fi

echo -e "${BLUE}Checking remaining volumes...${NC}"
REMAINING_VOLUMES=$(docker volume ls -q | grep -E "(lucene-learning|es-data|solr-data|opensearch-data|zoo.*-data)" || true)

if [ -n "$REMAINING_VOLUMES" ]; then
    echo -e "${BLUE}💾 Data volumes preserved:${NC}"
    docker volume ls | head -1
    for vol in $REMAINING_VOLUMES; do
        docker volume ls | grep "$vol"
    done
else
    echo -e "${GREEN}✅ No data volumes remaining${NC}"
fi

echo ""
echo -e "${CYAN}📚 Teardown Options Summary:${NC}"
echo -e "${GREEN}  Option 1${NC} - Quick stop, easy restart"
echo -e "${YELLOW}  Option 2${NC} - Clean containers, keep data"
echo -e "${PURPLE}  Option 3${NC} - Fresh start, lose data"
echo -e "${RED}  Option 4${NC} - Nuclear option, clean everything"
echo ""
echo -e "${BLUE}🎯 Choose the right option for your needs!${NC}"
