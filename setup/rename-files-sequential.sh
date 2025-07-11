#!/bin/bash

# 🎓 Lucene Ecosystem Mastery: File Renaming Script
# Purpose: Rename all learning materials with 2-digit prefixes for sequential learning path
# Usage: ./rename-files-sequential.sh

echo "🎯 Starting file renaming for sequential learning path..."
echo "📚 Organizing 22 files into 8 progressive phases"
echo ""

# Function to safely rename files (checks if source exists)
safe_rename() {
    local old_name="$1"
    local new_name="$2"
    local phase="$3"
    
    if [ -f "$old_name" ]; then
        mv "$old_name" "$new_name"
        echo "✅ $phase: $old_name → $new_name"
    else
        echo "⚠️  WARNING: $old_name not found (skipping)"
    fi
}

echo "🏗️ PHASE 1: Lucene Foundations (01-03)"
echo "Time Investment: 45-60 minutes | Focus: Core architecture and data structures"
safe_rename "lucene-architecture-deep-dive.md" "01-lucene-architecture-deep-dive.md" "01"
safe_rename "fst-vs-trie-comparison.md" "02-fst-vs-trie-comparison.md" "02"
safe_rename "fst-construction-algorithm.md" "03-fst-construction-algorithm.md" "03"
echo ""

echo "🐳 PHASE 2: Environment Setup (04-05)"
echo "Time Investment: 30-45 minutes | Focus: Multi-platform development environment"
safe_rename "advanced-features-hands-on-practice.md" "04-advanced-features-hands-on-practice.md" "04"
safe_rename "admin-interface-comparison.md" "05-admin-interface-comparison.md" "05"
echo ""

echo "📋 PHASE 3: Core Concepts (06-07)"
echo "Time Investment: 60-75 minutes | Focus: Schema management and query languages"
safe_rename "advanced-features-cross-analysis.md" "06-advanced-features-cross-analysis.md" "06"
safe_rename "query-language-comparison.md" "07-query-language-comparison.md" "07"
echo ""

echo "🔍 PHASE 4: Search Fundamentals (08-10)"
echo "Time Investment: 90-120 minutes | Focus: Core search functionality and basic relevance"
safe_rename "scoring-relevance-comparison.md" "08-scoring-relevance-comparison.md" "08"
safe_rename "aggregations-vs-faceting-comparison.md" "09-aggregations-vs-faceting-comparison.md" "09"
safe_rename "step2-function-scoring-implementation.md" "10-step2-function-scoring-implementation.md" "10"
echo ""

echo "🧮 PHASE 5: Advanced Scoring (11-13)"
echo "Time Investment: 120-150 minutes | Focus: Sophisticated scoring algorithms and ML"
safe_rename "solr-function-scoring-fixes.md" "11-solr-function-scoring-fixes.md" "11"
safe_rename "advanced-script-scoring-guide.md" "12-advanced-script-scoring-guide.md" "12"
safe_rename "ml-learning-to-rank-guide.md" "13-ml-learning-to-rank-guide.md" "13"
echo ""

echo "⚡ PHASE 6: Performance & Production (14-18)"
echo "Time Investment: 180-240 minutes | Focus: Production optimization and operational excellence"
safe_rename "performance-progressive-labs.md" "14-performance-progressive-labs.md" "14"
safe_rename "performance-benchmarking-guide.md" "15-performance-benchmarking-guide.md" "15"
safe_rename "scaling-patterns.md" "16-scaling-patterns.md" "16"
safe_rename "memory-management.md" "17-memory-management.md" "17"
safe_rename "monitoring-solutions.md" "18-monitoring-solutions.md" "18"
echo ""

echo "🔥 PHASE 7: Production Reality (19-20)"
echo "Time Investment: 90-120 minutes | Focus: Real-world scenarios and comprehensive production knowledge"
safe_rename "production-war-stories.md" "19-production-war-stories.md" "19"
safe_rename "performance-and-production-reality.md" "20-performance-and-production-reality.md" "20"
echo ""

echo "🧪 PHASE 8: Advanced Testing & Strategy (21-22)"
echo "Time Investment: 120-150 minutes | Focus: Production testing and strategic decision-making"
safe_rename "ab-testing-framework-guide.md" "21-ab-testing-framework-guide.md" "21"
safe_rename "technology-selection-decision-tree.md" "22-technology-selection-decision-tree.md" "22"
echo ""

echo "🎉 FILE RENAMING COMPLETED!"
echo "📚 All 22 learning materials now organized with sequential 2-digit prefixes"
echo ""
echo "📖 NEXT STEPS:"
echo "1. Start with: 00-LEARNING-PATH-README.md (Master Guide)"
echo "2. Follow sequential order: 01 → 02 → 03 → ... → 22"
echo "3. Each file builds on previous knowledge"
echo "4. Complete hands-on exercises in your Docker environment"
echo ""
echo "🎯 LEARNING PATH SUMMARY:"
echo "   Phase 1 (01-03): Lucene Foundations"
echo "   Phase 2 (04-05): Environment Setup"
echo "   Phase 3 (06-07): Core Concepts"
echo "   Phase 4 (08-10): Search Fundamentals"
echo "   Phase 5 (11-13): Advanced Scoring"
echo "   Phase 6 (14-18): Performance & Production"
echo "   Phase 7 (19-20): Production Reality"
echo "   Phase 8 (21-22): Advanced Testing & Strategy"
echo ""
echo "🏆 GOAL: Transform from novice to Senior Staff Engineer level expertise!"
echo "🚀 Happy learning!"

# List the renamed files to verify
echo ""
echo "📋 VERIFICATION: Listing all numbered learning files..."
ls -la [0-9][0-9]-*.md 2>/dev/null | wc -l | xargs echo "Total numbered files:"
echo ""
echo "📁 Complete file list:"
ls -1 [0-9][0-9]-*.md 2>/dev/null || echo "Note: Run this script to see the renamed files"
