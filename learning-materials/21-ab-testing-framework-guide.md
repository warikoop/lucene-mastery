# 🧪 **A/B Testing Framework: Scoring Effectiveness**

> **🎯 Objective**: Systematically test and compare scoring effectiveness across platforms
> **Builds on**: Performance benchmarking and all scoring implementation knowledge
> **Focus**: Statistical analysis, production A/B testing, and business impact measurement

---

## 🔬 **A/B Testing Fundamentals**

### **Why A/B Test Search Scoring?**
A/B testing search scoring is **critical** because:
- **Performance metrics** don't always correlate with **business outcomes**
- **User behavior** is the ultimate measure of search relevance
- **Statistical significance** is needed to make confident decisions
- **Incremental improvements** compound over time for major business impact

**Key Testing Areas:**
- **Algorithm Comparison** - Function vs Script vs ML scoring
- **Platform Performance** - Elasticsearch vs Solr vs OpenSearch
- **Feature Impact** - Individual scoring factors effectiveness
- **User Segmentation** - Different scoring for different user types

---

## 📊 **A/B Testing Design Framework**

### **🎯 Experimental Design Principles**

#### **Test Structure Design:**
```bash
echo "🎯 A/B TESTING DESIGN FRAMEWORK:"
echo ""
echo "📊 EXPERIMENTAL STRUCTURE:"
echo "   - Control Group (A): Current scoring algorithm"
echo "   - Test Group (B): New scoring algorithm"
echo "   - Split Ratio: 90/10 or 80/20 for safety"
echo "   - Minimum Sample Size: Statistical power calculation"
echo "   - Test Duration: Account for weekly/seasonal patterns"
echo ""
echo "🔍 KEY VARIABLES TO CONTROL:"
echo "   - User demographics and behavior"
echo "   - Query types and complexity"
echo "   - Time of day and seasonality"
echo "   - Geographic distribution"
echo "   - Device types (mobile/desktop)"
echo ""
echo "📈 SUCCESS METRICS HIERARCHY:"
echo "   1. Business Metrics (Revenue, Conversion)"
echo "   2. Engagement Metrics (CTR, Time on site)"
echo "   3. Search Metrics (Query success, Refinement rate)"
echo "   4. Technical Metrics (Response time, Error rate)"
```

### **📋 Hypothesis Framework**

#### **Structured Hypothesis Development:**
```bash
# A/B Test Hypothesis Template
echo "📋 A/B TEST HYPOTHESIS FRAMEWORK:"
echo ""
echo "HYPOTHESIS STRUCTURE:"
echo "   IF we implement [specific scoring change]"
echo "   THEN we expect [specific metric improvement]"
echo "   BECAUSE [theoretical reasoning]"
echo ""
echo "EXAMPLE HYPOTHESES:"
echo ""
echo "H1: FUNCTION VS SCRIPT SCORING"
echo "   IF: We replace function scoring with script-based personalization"
echo "   THEN: User engagement (CTR) will increase by 5-15%"
echo "   BECAUSE: Personalized results better match user intent"
echo ""
echo "H2: PLATFORM PERFORMANCE"
echo "   IF: We migrate from Elasticsearch to Solr for faceted search"
echo "   THEN: Page load time will decrease by 20-30%"
echo "   BECAUSE: Solr's native faceting is more efficient"
echo ""
echo "H3: ML MODEL IMPACT"
echo "   IF: We implement Learning-to-Rank models"
echo "   THEN: Conversion rate will increase by 10-25%"
echo "   BECAUSE: ML models better predict user purchase intent"
```

---

## 🔵 **Elasticsearch A/B Testing Implementation**

### **🚀 Traffic Splitting Strategy**

#### **Index-Based A/B Testing:**
```bash
echo "🔵 ELASTICSEARCH A/B TESTING IMPLEMENTATION:"

# Method 1: Query-time scoring variation
# Control query (existing function scoring)
curl -X POST "localhost:9199/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {"match": {"title": "laptop"}},
      "functions": [
        {
          "field_value_factor": {
            "field": "popularity_score",
            "factor": 1.5,
            "modifier": "log1p"
          }
        }
      ]
    }
  },
  "size": 20,
  "_source": ["id", "title", "price", "popularity_score"]
}'

# Test query (enhanced script scoring)
curl -X POST "localhost:9199/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {"match": {"title": "laptop"}},
      "functions": [
        {
          "script_score": {
            "script": {
              "source": """
                double baseScore = _score;
                double popularityBoost = Math.log(doc['popularity_score'].value + 1) * 1.5;
                double recencyBoost = doc['days_since_release'].value < 30 ? 1.3 : 1.0;
                double priceBoost = doc['price'].value <= params.user_budget ? 1.2 : 0.9;
                return baseScore * (1.0 + popularityBoost * 0.3) * recencyBoost * priceBoost;
              """,
              "params": {
                "user_budget": 1500
              }
            }
          }
        }
      ]
    }
  },
  "size": 20,
  "_source": ["id", "title", "price", "popularity_score"]
}'
```

#### **🎯 User Segmentation for Testing:**
```bash
# User-based A/B testing with consistent assignment
echo "🎯 USER SEGMENTATION FOR A/B TESTING:"

# Consistent user assignment based on user ID hash
curl -X POST "localhost:9199/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {"match": {"category": "electronics"}},
      "functions": [
        {
          "script_score": {
            "script": {
              "source": """
                // Consistent A/B test assignment
                int userGroup = (params.user_id.hashCode() & 0x7fffffff) % 100;
                double baseScore = _score;
                
                if (userGroup < 20) {
                  // Test Group B (20% of users) - Enhanced scoring
                  double personalizedScore = doc['category_affinity_score'].value * 1.4;
                  double behaviorScore = doc['user_behavior_score'].value * 1.6;
                  return baseScore * (1.0 + personalizedScore + behaviorScore);
                } else {
                  // Control Group A (80% of users) - Standard scoring  
                  double standardScore = doc['popularity_score'].value * 1.2;
                  return baseScore * (1.0 + standardScore * 0.5);
                }
              """,
              "params": {
                "user_id": "user123456"
              }
            }
          }
        }
      ]
    }
  },
  "size": 20
}'
```

### **📊 Elasticsearch Metrics Collection**

#### **Search Analytics Integration:**
```bash
# Custom search analytics for A/B testing
echo "📊 ELASTICSEARCH A/B TEST METRICS COLLECTION:"

# Log search interactions with test variant information
curl -X POST "localhost:9199/search_analytics/_doc" -H 'Content-Type: application/json' -d'
{
  "timestamp": "2023-11-20T10:30:00Z",
  "user_id": "user123456",
  "session_id": "session789",
  "query": "gaming laptop",
  "test_variant": "script_scoring_v2",
  "test_group": "B",
  "results_shown": 20,
  "clicks": [
    {
      "position": 1,
      "product_id": "laptop001",
      "click_timestamp": "2023-11-20T10:30:15Z"
    },
    {
      "position": 3,
      "product_id": "laptop003", 
      "click_timestamp": "2023-11-20T10:30:45Z"
    }
  ],
  "conversions": [
    {
      "product_id": "laptop001",
      "conversion_timestamp": "2023-11-20T10:45:00Z",
      "revenue": 1299.99
    }
  ],
  "search_metadata": {
    "response_time_ms": 85,
    "total_hits": 1547,
    "max_score": 8.52
  }
}'

# Aggregate A/B test results
curl -X POST "localhost:9199/search_analytics/_search" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "query": {
    "range": {
      "timestamp": {
        "gte": "now-7d"
      }
    }
  },
  "aggs": {
    "test_variants": {
      "terms": {
        "field": "test_variant.keyword"
      },
      "aggs": {
        "avg_ctr": {
          "avg": {
            "script": {
              "source": "doc['clicks'].size() / (double) doc['results_shown'].value"
            }
          }
        },
        "conversion_rate": {
          "avg": {
            "script": {
              "source": "doc['conversions'].size() > 0 ? 1 : 0"
            }
          }
        },
        "avg_revenue": {
          "avg": {
            "field": "conversions.revenue"
          }
        },
        "avg_response_time": {
          "avg": {
            "field": "search_metadata.response_time_ms"
          }
        }
      }
    }
  }
}'
```

---

## 🟡 **Solr A/B Testing Implementation**

### **🚀 Solr A/B Testing Strategies**

#### **Request Handler Based Testing:**
```bash
echo "🟡 SOLR A/B TESTING IMPLEMENTATION:"

# Configure multiple request handlers for A/B testing in solrconfig.xml
echo "<!-- Solr A/B Testing Request Handlers -->"
echo "<requestHandler name=\"/select_control\" class=\"solr.SearchHandler\">"
echo "  <lst name=\"defaults\">"
echo "    <str name=\"defType\">edismax</str>"
echo "    <str name=\"qf\">title^2 description</str>"
echo "    <str name=\"bf\">log(sum(popularity_score,1))</str>"
echo "  </lst>"
echo "</requestHandler>"
echo ""
echo "<requestHandler name=\"/select_test\" class=\"solr.SearchHandler\">"
echo "  <lst name=\"defaults\">"
echo "    <str name=\"defType\">edismax</str>"
echo "    <str name=\"qf\">title^3 description^1.5 tags</str>"
echo "    <str name=\"bf\">sum(log(sum(popularity_score,1)),if(gt(recency_score,0.8),1.5,1.0))</str>"
echo "  </lst>"
echo "</requestHandler>"

# Control group query
curl "http://localhost:8999/solr/products/select_control" \
  -G \
  -d "q=gaming laptop" \
  -d "fl=id,title,score" \
  -d "rows=20"

# Test group query  
curl "http://localhost:8999/solr/products/select_test" \
  -G \
  -d "q=gaming laptop" \
  -d "fl=id,title,score" \
  -d "rows=20"
```

#### **🎯 Dynamic Parameter A/B Testing:**
```bash
# Dynamic A/B testing based on user segmentation
echo "🎯 SOLR DYNAMIC A/B TESTING:"

# Function to determine test group assignment
get_test_group() {
  local user_id="$1"
  local hash=$(echo -n "$user_id" | md5sum | cut -c1-8)
  local decimal=$((16#$hash))
  local group=$((decimal % 100))
  
  if [ $group -lt 20 ]; then
    echo "test"
  else
    echo "control"
  fi
}

# Example usage with different scoring based on group
USER_ID="user123456"
TEST_GROUP=$(get_test_group "$USER_ID")

if [ "$TEST_GROUP" = "test" ]; then
  # Enhanced scoring for test group
  curl "http://localhost:8999/solr/products/select" \
    -G \
    -d "q=smartphone" \
    -d "bf=sum(
          product(log(sum(popularity_score,1)),1.8),
          if(gt(user_rating,4.0),1.4,1.0),
          if(lt(price,1000),1.2,1.0)
        )" \
    -d "fl=id,title,price,score" \
    -d "rows=20"
else
  # Standard scoring for control group
  curl "http://localhost:8999/solr/products/select" \
    -G \
    -d "q=smartphone" \
    -d "bf=log(sum(popularity_score,1))" \
    -d "fl=id,title,price,score" \
    -d "rows=20"
fi
```

### **📊 Solr A/B Test Analytics**

#### **Search Event Logging:**
```bash
# Log search events for A/B test analysis
echo "📊 SOLR A/B TEST EVENT LOGGING:"

# Create analytics collection for storing test results
curl "http://localhost:8999/solr/admin/collections?action=CREATE" \
  -G \
  -d "name=search_analytics" \
  -d "numShards=2" \
  -d "replicationFactor=1"

# Log search interaction
curl -X POST "http://localhost:8999/solr/search_analytics/update/json" \
  -H 'Content-Type: application/json' -d'
{
  "add": {
    "doc": {
      "id": "search_001",
      "timestamp": "2023-11-20T10:30:00Z",
      "user_id": "user123456",
      "query": "wireless headphones",
      "test_variant": "enhanced_scoring",
      "test_group": "B",
      "handler_used": "/select_test",
      "results_count": 847,
      "response_time_ms": 45,
      "clicked_positions": [1, 3, 7],
      "converted_items": ["headphone001"],
      "revenue": 199.99
    }
  }
}'

# Commit the changes
curl "http://localhost:8999/solr/search_analytics/update?commit=true"
```

---

## 🔄 **OpenSearch A/B Testing**

### **🚀 OpenSearch A/B Testing (ES Compatible)**

```bash
echo "🔄 OPENSEARCH A/B TESTING:"
echo ""
echo "📊 A/B testing approach identical to Elasticsearch:"
echo "   - Same query-time scoring variations"
echo "   - Same user segmentation strategies"
echo "   - Same metrics collection patterns"
echo "   - Same statistical analysis methods"
echo ""
echo "🔍 OpenSearch-Specific Considerations:"
echo "   - No X-Pack analytics (use open source alternatives)"
echo "   - Custom analytics dashboards with OpenSearch Dashboards"
echo "   - Potential performance differences to measure"
echo "   - Community-driven A/B testing tools"
echo ""
echo "💡 Implementation Strategy:"
echo "   - Adapt Elasticsearch examples to OpenSearch endpoints"
echo "   - Use same scoring logic with OpenSearch features"
echo "   - Leverage OpenSearch ML capabilities for advanced tests"
echo "   - Monitor for OpenSearch-specific optimizations"
```

---

## 📈 **Statistical Analysis Framework**

### **🔬 Statistical Significance Testing**

#### **Sample Size Calculation:**
```bash
echo "🔬 STATISTICAL ANALYSIS FRAMEWORK:"

# Sample size calculation for A/B tests
echo "📊 SAMPLE SIZE CALCULATION:"
echo ""
echo "PARAMETERS NEEDED:"
echo "   - Baseline Conversion Rate (e.g., 3.2%)"
echo "   - Minimum Detectable Effect (e.g., +0.5%)"
echo "   - Statistical Power (typically 80%)"
echo "   - Significance Level (typically 5%)"
echo ""
echo "CALCULATION EXAMPLE:"
echo "   Baseline CTR: 3.2%"
echo "   Target CTR: 3.7% (+15% relative improvement)"
echo "   Required sample size per group: ~8,000 users"
echo "   Test duration: 2-4 weeks (depending on traffic)"
echo ""
echo "💡 ONLINE CALCULATORS:"
echo "   - Optimizely Sample Size Calculator"
echo "   - Evan Miller A/B Test Calculator"
echo "   - Google Analytics Intelligence"
```

#### **Statistical Test Implementation:**
```bash
# Python script for A/B test statistical analysis
echo "🧮 STATISTICAL ANALYSIS IMPLEMENTATION:"

# Create analysis script template
cat << 'EOF'
# A/B Test Statistical Analysis Script
import scipy.stats as stats
import numpy as np
from math import sqrt

def ab_test_analysis(control_conversions, control_visitors, 
                    test_conversions, test_visitors, alpha=0.05):
    """
    Perform statistical analysis of A/B test results
    """
    # Calculate conversion rates
    control_rate = control_conversions / control_visitors
    test_rate = test_conversions / test_visitors
    
    # Calculate relative improvement
    relative_improvement = (test_rate - control_rate) / control_rate * 100
    
    # Perform z-test for proportions
    pooled_rate = (control_conversions + test_conversions) / (control_visitors + test_visitors)
    pooled_se = sqrt(pooled_rate * (1 - pooled_rate) * (1/control_visitors + 1/test_visitors))
    
    z_score = (test_rate - control_rate) / pooled_se
    p_value = 2 * (1 - stats.norm.cdf(abs(z_score)))
    
    # Calculate confidence interval
    se_diff = sqrt((control_rate * (1 - control_rate) / control_visitors) + 
                   (test_rate * (1 - test_rate) / test_visitors))
    margin_error = stats.norm.ppf(1 - alpha/2) * se_diff
    ci_lower = (test_rate - control_rate) - margin_error
    ci_upper = (test_rate - control_rate) + margin_error
    
    return {
        'control_rate': control_rate,
        'test_rate': test_rate,
        'relative_improvement': relative_improvement,
        'z_score': z_score,
        'p_value': p_value,
        'is_significant': p_value < alpha,
        'confidence_interval': (ci_lower, ci_upper)
    }

# Example usage
results = ab_test_analysis(
    control_conversions=256,
    control_visitors=8000,
    test_conversions=312,
    test_visitors=8000
)

print(f"Control conversion rate: {results['control_rate']:.3%}")
print(f"Test conversion rate: {results['test_rate']:.3%}")
print(f"Relative improvement: {results['relative_improvement']:.1f}%")
print(f"P-value: {results['p_value']:.4f}")
print(f"Statistically significant: {results['is_significant']}")
EOF
```

### **📊 Advanced Analytics**

#### **Multi-Metric Analysis:**
```bash
echo "📊 MULTI-METRIC A/B TEST ANALYSIS:"

# Query to analyze multiple metrics simultaneously
curl -X POST "localhost:9199/search_analytics/_search" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "query": {
    "range": {
      "timestamp": {
        "gte": "now-14d"
      }
    }
  },
  "aggs": {
    "test_variants": {
      "terms": {
        "field": "test_variant.keyword"
      },
      "aggs": {
        "metrics": {
          "scripted_metric": {
            "init_script": "state.sessions = [:]",
            "map_script": """
              String sessionId = doc['session_id'].value;
              if (!state.sessions.containsKey(sessionId)) {
                state.sessions[sessionId] = [
                  clicks: 0,
                  conversions: 0,
                  revenue: 0.0,
                  queries: 0
                ];
              }
              state.sessions[sessionId].clicks += doc['clicks'].size();
              state.sessions[sessionId].conversions += doc['conversions'].size();
              state.sessions[sessionId].revenue += doc['conversions.revenue'].value ?: 0;
              state.sessions[sessionId].queries += 1;
            """,
            "combine_script": "return state.sessions",
            "reduce_script": """
              Map combined = [:];
              for (state in states) {
                for (entry in state.entrySet()) {
                  String sessionId = entry.getKey();
                  Map sessionData = entry.getValue();
                  if (!combined.containsKey(sessionId)) {
                    combined[sessionId] = sessionData;
                  } else {
                    combined[sessionId].clicks += sessionData.clicks;
                    combined[sessionId].conversions += sessionData.conversions;
                    combined[sessionId].revenue += sessionData.revenue;
                    combined[sessionId].queries += sessionData.queries;
                  }
                }
              }
              
              int totalSessions = combined.size();
              double totalRevenue = 0;
              int totalClicks = 0;
              int totalConversions = 0;
              int totalQueries = 0;
              
              for (session in combined.values()) {
                totalRevenue += session.revenue;
                totalClicks += session.clicks;
                totalConversions += session.conversions;
                totalQueries += session.queries;
              }
              
              return [
                sessions: totalSessions,
                avg_ctr: totalClicks / (double) totalQueries,
                conversion_rate: totalConversions / (double) totalSessions,
                avg_revenue_per_session: totalRevenue / totalSessions
              ];
            """
          }
        }
      }
    }
  }
}'
```

---

## 🎯 **Production A/B Testing Best Practices**

### **📋 A/B Testing Implementation Checklist**

```bash
echo "📋 PRODUCTION A/B TESTING CHECKLIST:"
echo ""
echo "✅ PRE-TEST PLANNING:"
echo "   □ Clear hypothesis with measurable outcomes"
echo "   □ Minimum sample size calculated"
echo "   □ Success metrics defined and measurable"
echo "   □ Test duration planned (account for seasonality)"
echo "   □ Rollback plan prepared"
echo ""
echo "✅ TEST IMPLEMENTATION:"
echo "   □ Consistent user assignment (sticky sessions)"
echo "   □ Equal traffic distribution verification"
echo "   □ Performance impact monitoring"
echo "   □ Real-time metrics collection"
echo "   □ Statistical analysis automation"
echo ""
echo "✅ TEST MONITORING:"
echo "   □ Daily metrics review"
echo "   □ Performance regression monitoring"
echo "   □ Statistical significance tracking"
echo "   □ User experience feedback"
echo "   □ Business stakeholder updates"
echo ""
echo "✅ TEST CONCLUSION:"
echo "   □ Statistical significance achieved"
echo "   □ Business impact validated"
echo "   □ Implementation decision documented"
echo "   □ Lessons learned captured"
echo "   □ Next test iteration planned"
```

### **⚠️ Common A/B Testing Pitfalls**

```bash
echo "⚠️  A/B TESTING PITFALLS TO AVOID:"
echo ""
echo "❌ STATISTICAL PITFALLS:"
echo "   - Stopping tests early (p-hacking)"
echo "   - Insufficient sample sizes"
echo "   - Multiple testing without correction"
echo "   - Ignoring confidence intervals"
echo ""
echo "❌ IMPLEMENTATION PITFALLS:"  
echo "   - Inconsistent user assignment"
echo "   - Performance bias between variants"
echo "   - Seasonal confounding effects"
echo "   - Cache invalidation issues"
echo ""
echo "❌ BUSINESS PITFALLS:"
echo "   - Testing too many variants simultaneously"
echo "   - Focusing only on short-term metrics"
echo "   - Ignoring segment-specific effects"
echo "   - Poor stakeholder communication"
```

### **🚀 Advanced A/B Testing Strategies**

#### **Multi-Armed Bandit Testing:**
```bash
echo "🚀 ADVANCED A/B TESTING STRATEGIES:"
echo ""
echo "🎰 MULTI-ARMED BANDIT APPROACH:"
echo "   - Dynamic traffic allocation based on performance"
echo "   - Faster convergence than traditional A/B testing"
echo "   - Reduced opportunity cost of inferior variants"
echo "   - Suitable for continuous optimization"
echo ""
echo "🎯 BAYESIAN A/B TESTING:"
echo "   - Probabilistic interpretation of results"
echo "   - Earlier stopping decisions possible"
echo "   - Better handling of multiple metrics"
echo "   - More intuitive result interpretation"
echo ""
echo "📊 FACTORIAL TESTING:"
echo "   - Test multiple factors simultaneously"
echo "   - Identify interaction effects"
echo "   - More efficient than sequential testing"
echo "   - Complex analysis requirements"
```

---

## 🎓 **A/B Testing Success Stories**

### **🏆 Real-World A/B Testing Examples**

```bash
echo "🏆 SEARCH A/B TESTING SUCCESS STORIES:"
echo ""
echo "🛒 E-COMMERCE PERSONALIZATION TEST:"
echo "   Platform: Elasticsearch with ML scoring"
echo "   Test: Generic vs Personalized product ranking"
echo "   Duration: 4 weeks, 50K users per group"
echo "   Results: +18% conversion rate, +23% revenue per user"
echo "   Key Learning: Personalization impact varies by product category"
echo ""
echo "📚 CONTENT DISCOVERY OPTIMIZATION:"
echo "   Platform: Solr with enhanced function queries"
echo "   Test: Popularity vs Freshness scoring weight"
echo "   Duration: 6 weeks, 100K users per group"
echo "   Results: +12% user engagement, +8% session duration"
echo "   Key Learning: Time-based scoring requires user segment consideration"
echo ""
echo "🔍 ENTERPRISE SEARCH RELEVANCE:"
echo "   Platform: OpenSearch with semantic search"
echo "   Test: Keyword vs Neural search ranking"
echo "   Duration: 8 weeks, 25K employees"
echo "   Results: +35% search success rate, +20% user satisfaction"
echo "   Key Learning: Semantic search excels for complex queries"
```

**🧪 A/B testing transforms search optimization from guesswork into data-driven decision making, ensuring every change delivers measurable business value!**

---

## 🎯 **A/B Testing Framework Summary**

With this comprehensive A/B testing framework, you can now:

✅ **Design rigorous experiments** with proper statistical foundations
✅ **Implement platform-specific testing** across Elasticsearch, Solr, and OpenSearch  
✅ **Collect and analyze metrics** with statistical significance
✅ **Make data-driven decisions** about scoring algorithm improvements
✅ **Measure business impact** of technical search optimizations

**🎉 CONGRATULATIONS! All deferred advanced scoring sections are now complete!** 

You've achieved comprehensive search relevance mastery covering:
- **Function Scoring** - Platform-native scoring approaches
- **Script Scoring** - Custom algorithmic implementations  
- **ML Models** - Learning-to-Rank implementations
- **Performance Benchmarking** - Quantitative performance analysis
- **A/B Testing** - Production effectiveness measurement

**This completes your transformation to senior-level search platform expertise!** 🚀
