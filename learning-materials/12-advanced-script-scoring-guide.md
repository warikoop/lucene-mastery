# 🧮 **Advanced Script Scoring Deep Dive**

> **🎯 Objective**: Master script-based relevance tuning for sophisticated search scenarios
> **Builds on**: Function scoring fundamentals and platform-specific scoring knowledge
> **Focus**: Custom scripting, dynamic scoring logic, and advanced relevance algorithms

---

## 🔬 **Script Scoring Fundamentals**

### **When Script Scoring is Essential**
Script scoring becomes **critical** when you need:
- **Dynamic business logic** that changes based on user context
- **Complex mathematical operations** beyond simple field boosts
- **Real-time personalization** based on user behavior
- **A/B testing** with sophisticated scoring variants
- **Machine learning integration** with custom algorithms

**⚠️ Performance Trade-off**: Script scoring is powerful but **computationally expensive** - use strategically!

---

## 🔵 **Elasticsearch Script Scoring**

### **🧪 Painless Script Language**

Elasticsearch uses **Painless** - a secure, fast scripting language designed for Elasticsearch.

#### **📊 Basic Script Scoring Example:**
```bash
# Real-world e-commerce example: Boost products based on dynamic factors
curl -X POST "localhost:9199/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "title": "laptop"
        }
      },
      "functions": [
        {
          "script_score": {
            "script": {
              "source": """
                // Dynamic scoring based on multiple business factors
                double baseScore = _score;
                
                // Inventory pressure (promote items with high stock)
                double inventoryBoost = doc['inventory_count'].value > 10 ? 1.2 : 0.8;
                
                // Seasonal relevance (promote items with seasonal tags)
                String currentSeason = params.season;
                double seasonalBoost = doc['tags'].contains(currentSeason) ? 1.5 : 1.0;
                
                // Price competitiveness (promote items in sweet spot)
                double price = doc['price'].value;
                double priceBoost = price >= 800 && price <= 1500 ? 1.3 : 1.0;
                
                // Margin optimization (subtle boost for higher margin items)
                double marginBoost = doc['profit_margin'].value > 0.3 ? 1.1 : 1.0;
                
                // Time-based urgency (promote flash sale items)
                long currentTime = System.currentTimeMillis();
                long saleEndTime = doc['sale_end_timestamp'].value;
                double urgencyBoost = (saleEndTime - currentTime) < 86400000 ? 1.4 : 1.0;
                
                return baseScore * inventoryBoost * seasonalBoost * priceBoost * marginBoost * urgencyBoost;
              """,
              "params": {
                "season": "winter"
              }
            }
          }
        }
      ],
      "boost_mode": "replace"
    }
  }
}'
```

#### **🎯 Advanced Personalization Script:**
```bash
# User behavior-based personalization
curl -X POST "localhost:9199/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {
        "multi_match": {
          "query": "smartphone",
          "fields": ["title^2", "description", "brand"]
        }
      },
      "functions": [
        {
          "script_score": {
            "script": {
              "source": """
                double baseScore = _score;
                
                // User preference analysis
                String userBrandPref = params.user_brand_preference;
                double brandBoost = doc['brand'].value.equals(userBrandPref) ? 1.8 : 1.0;
                
                // Price range affinity
                double userMaxBudget = params.user_max_budget;
                double price = doc['price'].value;
                double budgetBoost = price <= userMaxBudget ? 1.2 : 0.7;
                
                // Category affinity based on past purchases
                Set userCategories = new HashSet(params.user_preferred_categories);
                Set productCategories = new HashSet(doc['categories']);
                boolean hasCommonCategory = !Collections.disjoint(userCategories, productCategories);
                double categoryBoost = hasCommonCategory ? 1.4 : 1.0;
                
                // Recency preference (user likes newer products)
                long productAge = System.currentTimeMillis() - doc['release_date'].value;
                double ageBoost = productAge < 15552000000L ? 1.3 : 1.0; // 6 months
                
                // Review quality preference
                double avgRating = doc['average_rating'].value;
                int reviewCount = doc['review_count'].value;
                double reviewBoost = (avgRating >= 4.0 && reviewCount >= 10) ? 1.25 : 1.0;
                
                return baseScore * brandBoost * budgetBoost * categoryBoost * ageBoost * reviewBoost;
              """,
              "params": {
                "user_brand_preference": "apple",
                "user_max_budget": 1200,
                "user_preferred_categories": ["electronics", "mobile", "accessories"]
              }
            }
          }
        }
      ]
    }
  }
}'
```

#### **🏆 Machine Learning Integration Script:**
```bash
# Custom ML model integration for relevance scoring
curl -X POST "localhost:9199/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "description": "gaming laptop"
        }
      },
      "functions": [
        {
          "script_score": {
            "script": {
              "source": """
                // Custom ML model implementation (simplified example)
                double baseScore = _score;
                
                // Feature extraction for ML model
                double[] features = new double[8];
                features[0] = doc['price'].value / 1000.0;           // Normalized price
                features[1] = doc['cpu_score'].value / 100.0;        // CPU performance
                features[2] = doc['gpu_score'].value / 100.0;        // GPU performance  
                features[3] = doc['ram_gb'].value / 32.0;            // RAM capacity
                features[4] = doc['storage_gb'].value / 1000.0;      // Storage
                features[5] = doc['average_rating'].value / 5.0;     // User rating
                features[6] = doc['review_count'].value / 1000.0;    // Review volume
                features[7] = doc['brand_reputation_score'].value / 10.0; // Brand score
                
                // Simple linear model (in production, use pre-trained weights)
                double[] weights = params.ml_weights;
                double mlScore = 0.0;
                for (int i = 0; i < features.length; i++) {
                  mlScore += features[i] * weights[i];
                }
                
                // Apply sigmoid activation for probability-like score
                double activatedScore = 1.0 / (1.0 + Math.exp(-mlScore));
                
                // Combine with base text relevance
                return baseScore * (1.0 + activatedScore);
              """,
              "params": {
                "ml_weights": [0.15, 0.25, 0.30, 0.12, 0.08, 0.18, 0.10, 0.20]
              }
            }
          }
        }
      ]
    }
  }
}'
```

---

## 🟡 **Solr Script Scoring**

### **🧪 JavaScript and Custom Functions**

Solr supports multiple scripting approaches including **JavaScript expressions** and **custom function queries**.

#### **📊 JavaScript Expression Example:**
```bash
# Dynamic business logic scoring in Solr
curl "http://localhost:8999/solr/products/select" \
  -G \
  -d "q=laptop" \
  -d "fl=id,title,price,inventory_count,average_rating,score" \
  -d "sort=score desc" \
  -d "bf=javascript:inventory_boost" \
  -d "defType=edismax" \
  --data-urlencode "javascript.inventory_boost=
    // Complex inventory and demand scoring
    var inventory = doc.inventory_count;
    var price = doc.price;
    var rating = doc.average_rating;
    var reviewCount = doc.review_count;
    
    // Inventory pressure calculation  
    var inventoryBoost = inventory > 50 ? 1.0 : (inventory > 10 ? 1.2 : 1.5);
    
    // Price competitiveness
    var priceBoost = (price >= 500 && price <= 1500) ? 1.3 : 1.0;
    
    // Quality signal
    var qualityBoost = (rating >= 4.0 && reviewCount >= 20) ? 1.4 : 1.0;
    
    // Seasonal demand (simplified)
    var currentMonth = new Date().getMonth();
    var seasonalBoost = (currentMonth >= 10 || currentMonth <= 2) ? 1.2 : 1.0; // Holiday season
    
    return inventoryBoost * priceBoost * qualityBoost * seasonalBoost;
  "
```

#### **🎯 Function Query Approach:**
```bash
# Solr function query with custom scoring logic
curl "http://localhost:8999/solr/products/select" \
  -G \
  -d "q={!func}sum(
        product(
          query(\$textQuery),
          if(gt(inventory_count,10), 1.2, 0.8),
          if(and(gte(price,800),lte(price,1500)), 1.3, 1.0),
          if(gt(average_rating,4.0), 1.25, 1.0),
          if(lt(div(sub(ms(NOW),release_date),86400000),180), 1.15, 1.0)
        ),
        scale(profit_margin, 0, 1, 1.0, 1.5)
      )" \
  -d "textQuery=title:laptop OR description:laptop" \
  -d "fl=id,title,price,score" \
  -d "sort=score desc"
```

#### **🏆 Advanced Solr Custom Scoring:**
```bash
# Multi-factor personalization scoring  
curl "http://localhost:8999/solr/products/select" \
  -G \
  -d "q={!func}product(
        query(\$q1),
        sum(
          product(
            if(eq(brand,apple), 1.8, 1.0),        // Brand preference
            if(lte(price,1200), 1.2, 0.7),        // Budget fit
            scale(average_rating, 1, 5, 0.5, 1.5), // Rating boost
            if(gt(review_count,10), 1.1, 1.0)     // Review confidence
          ),
          if(exists(query(\$categoryMatch)), 1.4, 1.0) // Category affinity
        )
      )" \
  -d "q1=title:smartphone OR description:smartphone" \
  -d "categoryMatch=categories:(electronics OR mobile)" \
  -d "fl=id,title,brand,price,average_rating,score" \
  -d "sort=score desc"
```

---

## 🔄 **OpenSearch Script Scoring**

### **🧪 Painless Scripts (ES Compatible)**

OpenSearch maintains **Elasticsearch compatibility** for Painless scripts with some extensions.

#### **📊 OpenSearch Enhanced Script Example:**
```bash
# OpenSearch script with additional context
curl -X POST "localhost:9200/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "title": "laptop"
        }
      },
      "functions": [
        {
          "script_score": {
            "script": {
              "source": """
                double baseScore = _score;
                
                // OpenSearch specific: Enhanced context awareness
                String searchContext = params.search_context; // 'work', 'gaming', 'student'
                double contextBoost = 1.0;
                
                if (searchContext.equals('gaming')) {
                  contextBoost *= doc['gpu_score'].value > 80 ? 1.5 : 1.0;
                  contextBoost *= doc['ram_gb'].value >= 16 ? 1.3 : 1.0;
                } else if (searchContext.equals('work')) {
                  contextBoost *= doc['cpu_score'].value > 75 ? 1.4 : 1.0;
                  contextBoost *= doc['battery_hours'].value >= 8 ? 1.2 : 1.0;
                } else if (searchContext.equals('student')) {
                  contextBoost *= doc['price'].value <= 800 ? 1.6 : 1.0;
                  contextBoost *= doc['weight_kg'].value <= 2.0 ? 1.3 : 1.0;
                }
                
                // Geographic relevance
                String userRegion = params.user_region;
                double regionBoost = doc['available_regions'].contains(userRegion) ? 1.2 : 0.9;
                
                return baseScore * contextBoost * regionBoost;
              """,
              "params": {
                "search_context": "gaming",
                "user_region": "us-west"
              }
            }
          }
        }
      ]
    }
  }
}'
```

---

## ⚡ **Performance Optimization Strategies**

### **🔧 Script Performance Best Practices**

#### **Elasticsearch/OpenSearch Optimization:**
```bash
echo "⚡ SCRIPT PERFORMANCE OPTIMIZATION:"
echo ""
echo "🎯 COMPILED SCRIPTS:"
echo "   - Store frequently used scripts as stored scripts"
echo "   - Use script compilation caching"
echo "   - Minimize script complexity in loops"
echo ""
echo "📊 EFFICIENT FIELD ACCESS:"
echo "   - Use doc values for numeric/keyword fields"
echo "   - Avoid _source field access in scripts"
echo "   - Cache expensive calculations"
echo ""
echo "🏆 MEMORY MANAGEMENT:"
echo "   - Limit array operations and object creation"
echo "   - Use primitive types where possible"
echo "   - Monitor script execution time"

# Store script for reuse and performance
curl -X PUT "localhost:9199/_scripts/advanced_product_scoring" -H 'Content-Type: application/json' -d'
{
  "script": {
    "lang": "painless",
    "source": """
      double baseScore = _score;
      double inventoryBoost = doc['inventory_count'].value > params.inventory_threshold ? params.high_inventory_boost : params.low_inventory_boost;
      double priceBoost = (doc['price'].value >= params.min_price && doc['price'].value <= params.max_price) ? params.price_boost : 1.0;
      return baseScore * inventoryBoost * priceBoost;
    """
  }
}'

# Use stored script in queries (much faster)
curl -X POST "localhost:9199/products/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {"match": {"title": "laptop"}},
      "functions": [
        {
          "script_score": {
            "script": {
              "id": "advanced_product_scoring",
              "params": {
                "inventory_threshold": 10,
                "high_inventory_boost": 1.2,
                "low_inventory_boost": 0.8,
                "min_price": 800,
                "max_price": 1500,
                "price_boost": 1.3
              }
            }
          }
        }
      ]
    }
  }
}'
```

#### **Solr Performance Optimization:**
```bash
echo "🟡 SOLR SCRIPT OPTIMIZATION:"
echo ""
echo "🎯 FUNCTION QUERY EFFICIENCY:"
echo "   - Use function queries instead of JavaScript when possible"
echo "   - Cache complex calculations in function queries"
echo "   - Minimize field access in loops"
echo ""
echo "📊 JAVASCRIPT OPTIMIZATION:"
echo "   - Precompile JavaScript expressions"
echo "   - Use local variables to cache field values"
echo "   - Avoid complex object operations"

# Optimized Solr function query
curl "http://localhost:8999/solr/products/select" \
  -G \
  -d "q=*:*" \
  -d "fq=title:laptop" \
  -d "fl=id,title,price,score" \
  -d "sort=score desc" \
  -d "bf=sum(
        if(gt(inventory_count,10),1.2,0.8),
        scale(average_rating,1,5,0,1),
        if(and(gte(price,800),lte(price,1500)),0.3,0)
      )"
```

---

## 🧪 **Testing and Debugging Scripts**

### **🔍 Script Debugging Techniques**

#### **Elasticsearch Script Debugging:**
```bash
# Debug script execution with explain API
curl -X POST "localhost:9199/products/_explain/1" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {"match": {"title": "laptop"}},
      "functions": [
        {
          "script_score": {
            "script": {
              "source": """
                // Debug logging in script
                double baseScore = _score;
                double inventoryBoost = doc['inventory_count'].value > 10 ? 1.2 : 0.8;
                
                // Log intermediate values (visible in explain)
                Debug.log('Base score: ' + baseScore);
                Debug.log('Inventory count: ' + doc['inventory_count'].value);
                Debug.log('Inventory boost: ' + inventoryBoost);
                
                return baseScore * inventoryBoost;
              """
            }
          }
        }
      ]
    }
  }
}'

# Script validation before deployment
curl -X POST "localhost:9199/_scripts/painless/_execute" -H 'Content-Type: application/json' -d'
{
  "script": {
    "source": """
      double price = doc['price'].value;
      return price > 1000 ? 1.5 : 1.0;
    """,
    "params": {}
  },
  "context": "score",
  "context_setup": {
    "index": "products",
    "document": {
      "price": 1200
    }
  }
}'
```

### **📊 A/B Testing Script Variants**

```bash
# A/B testing different scoring approaches
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
                String variant = params.test_variant;
                
                if (variant.equals('A')) {
                  // Conservative scoring
                  return baseScore * (doc['average_rating'].value / 5.0) * 1.2;
                } else if (variant.equals('B')) {
                  // Aggressive personalization
                  double personalScore = doc['price'].value <= params.user_budget ? 1.5 : 0.8;
                  return baseScore * personalScore * (doc['average_rating'].value / 5.0);
                } else {
                  // Control group - no additional scoring
                  return baseScore;
                }
              """,
              "params": {
                "test_variant": "B",
                "user_budget": 1500
              }
            }
          }
        }
      ]
    }
  },
  "_source": ["title", "price", "average_rating"],
  "track_scores": true
}'
```

---

## 🎯 **Production Implementation Guidelines**

### **📋 Script Scoring Deployment Checklist**

```bash
echo "📋 PRODUCTION SCRIPT SCORING CHECKLIST:"
echo ""
echo "✅ DEVELOPMENT PHASE:"
echo "   □ Validate script logic with test data"
echo "   □ Performance test with production data volume"
echo "   □ Compare results with existing scoring"
echo "   □ Test edge cases and error handling"
echo ""
echo "✅ DEPLOYMENT PHASE:"
echo "   □ Use stored scripts for performance"
echo "   □ Implement gradual rollout (A/B testing)"
echo "   □ Monitor query performance impact"
echo "   □ Set up alerting for scoring errors"
echo ""
echo "✅ MONITORING PHASE:"
echo "   □ Track search result relevance metrics"
echo "   □ Monitor script execution time"
echo "   □ Analyze business impact (CTR, conversions)"
echo "   □ Regular script performance review"
```

**🧮 Script scoring unlocks sophisticated relevance tuning but requires careful performance management and thorough testing!**

**Next: Let's dive into ML Model Setup for Learning-to-Rank implementation!** 🤖
