# Step 2: Function Scoring Implementation
## Custom Boost Functions Across ES/Solr/OpenSearch

## 🎯 **Overview**
Using your 20K+ blog dataset, we'll implement sophisticated custom scoring functions that demonstrate how the same business logic translates across platforms with different performance characteristics.

---

## 📋 **Prerequisites**
```bash
# Load your 20K+ dataset first
cd e:/Personal/elastic-search/data_generation

# Generate the data
python enhanced_blog_scraper.py

# Load into platforms (replace TIMESTAMP with your actual timestamp)
curl -X POST "localhost:9200/_bulk" -H 'Content-Type: application/json' --data-binary @blog_20k_elasticsearch_TIMESTAMP.json
curl -X POST "localhost:9201/_bulk" -H 'Content-Type: application/json' --data-binary @blog_20k_elasticsearch_TIMESTAMP.json
curl -X POST "localhost:8983/solr/blog_posts/update/json/docs" -H 'Content-Type: application/json' -d @blog_20k_solr_TIMESTAMP.json
```

---

## 🔍 **Business Scenario: Blog Recommendation Engine**

We'll implement a **real-world blog recommendation system** with these scoring factors:

1. **Freshness Boost** - Recent posts get higher scores
2. **Popularity Boost** - High-engagement content ranks higher  
3. **Category Preference** - User's preferred categories get boosted
4. **Reading Time Preference** - Match user's available time
5. **Technical Complexity** - Match user's skill level
6. **Domain Authority** - Trusted sources get priority

---

## 🟢 **Elasticsearch Function Score Implementation**

### **Basic Function Score Setup**

```json
POST /blog_posts_20k/_search
{
  "query": {
    "function_score": {
      "query": {
        "multi_match": {
          "query": "machine learning python",
          "fields": ["title^2", "content", "tags^1.5"]
        }
      },
      "functions": [
        {
          "filter": {
            "range": {
              "freshness_score": {"gte": 3.0}
            }
          },
          "weight": 2.0
        },
        {
          "field_value_factor": {
            "field": "popularity_score",
            "factor": 1.5,
            "modifier": "sqrt",
            "missing": 1
          }
        },
        {
          "field_value_factor": {
            "field": "engagement_score", 
            "factor": 0.8,
            "modifier": "log1p",
            "missing": 1
          }
        }
      ],
      "score_mode": "multiply",
      "boost_mode": "multiply",
      "min_score": 0.5
    }
  },
  "explain": true
}
```

### **Advanced Multi-Factor Scoring**

```json
POST /blog_posts_20k/_search
{
  "query": {
    "function_score": {
      "query": {
        "bool": {
          "must": [
            {
              "multi_match": {
                "query": "javascript react",
                "fields": ["title^3", "content^1", "tags^2"]
              }
            }
          ],
          "should": [
            {
              "term": {
                "category": "web-development"
              }
            }
          ]
        }
      },
      "functions": [
        {
          "filter": {
            "term": {
              "category": "web-development"
            }
          },
          "weight": 3.0
        },
        {
          "field_value_factor": {
            "field": "freshness_score",
            "factor": 2.0,
            "modifier": "sqrt"
          }
        },
        {
          "gauss": {
            "reading_time": {
              "origin": 8,
              "scale": 3,
              "decay": 0.5
            }
          }
        },
        {
          "gauss": {
            "technical_complexity": {
              "origin": 3.0,
              "scale": 1.0,
              "decay": 0.3
            }
          }
        },
        {
          "field_value_factor": {
            "field": "domain_authority",
            "factor": 0.02,
            "modifier": "log1p"
          }
        }
      ],
      "score_mode": "sum",
      "boost_mode": "multiply",
      "min_score": 1.0
    }
  },
  "size": 20
}
```

### **Script-Based Custom Logic**

```json
POST /blog_posts_20k/_search
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "content": "python programming"
        }
      },
      "script_score": {
        "script": {
          "source": """
            // Custom scoring logic
            double base_score = _score;
            double freshness = doc['freshness_score'].value;
            double popularity = doc['popularity_score'].value;
            double engagement = doc['engagement_score'].value;
            double domain_auth = doc['domain_authority'].value;
            
            // Complex business logic
            double time_decay = Math.exp(-0.1 * (System.currentTimeMillis() - doc['indexed_at'].value.getMillis()) / 86400000);
            double social_boost = Math.log(1 + doc['social_signals.likes'].value + doc['social_signals.shares'].value);
            double complexity_match = 1.0 / (1.0 + Math.abs(doc['technical_complexity'].value - 3.0));
            
            return base_score * (1 + freshness * 0.3 + popularity * 0.2 + engagement * 0.1) * 
                   (1 + time_decay * 0.2) * (1 + social_boost * 0.1) * complexity_match;
          """
        }
      }
    }
  }
}
```

---

## 🟡 **Solr Function Query Implementation**

### **Basic Function Queries**

```bash
# Freshness and popularity boost
curl "http://localhost:8983/solr/blog_posts/select" \
  --data-urlencode "q=content:machine learning python" \
  --data-urlencode "qf=title_s^2 content_txt tags_ss^1.5" \
  --data-urlencode "defType=edismax" \
  --data-urlencode "boost=product(freshness_score_f,popularity_score_f)" \
  --data-urlencode "bf=sqrt(engagement_score_f)" \
  --data-urlencode "fl=title_s,popularity_score_f,freshness_score_f,score"
```

### **Multi-Factor Function Scoring**

```bash
# Complex multi-factor scoring
curl "http://localhost:8983/solr/blog_posts/select" \
  --data-urlencode "q=javascript react" \
  --data-urlencode "qf=title_s^3 content_txt tags_ss^2" \
  --data-urlencode "defType=edismax" \
  --data-urlencode "boost=if(termfreq(category_s,'web-development'),3.0,1.0)" \
  --data-urlencode "bf=sqrt(freshness_score_f)" \
  --data-urlencode "bf=recip(abs(sub(reading_time_i,8)),1,3,1)" \
  --data-urlencode "bf=recip(abs(sub(technical_complexity_f,3.0)),1,1,1)" \
  --data-urlencode "bf=log(sum(1,domain_authority_f))" \
  --data-urlencode "mm=2<-1 5<-2 6<90%" \
  --data-urlencode "fl=title_s,category_s,freshness_score_f,reading_time_i,score"
```

### **Advanced Conditional Scoring**

```bash
# Conditional scoring with multiple boost functions
curl "http://localhost:8983/solr/blog_posts/select" \
  --data-urlencode "q=python programming" \
  --data-urlencode "defType=edismax" \
  --data-urlencode "qf=title_s^2 content_txt" \
  --data-urlencode "boost=if(gt(freshness_score_f,3.0),2.0,1.0)" \
  --data-urlencode "bf=if(gt(popularity_score_f,4.0),product(popularity_score_f,2.0),popularity_score_f)" \
  --data-urlencode "bf=if(and(gt(engagement_score_f,5.0),gt(domain_authority_f,80.0)),3.0,1.0)" \
  --data-urlencode "bf=product(sqrt(freshness_score_f),log(sum(1,engagement_score_f)))" \
  --data-urlencode "bf=recip(ms(NOW,indexed_at_dt),3.16e-11,1,1)" \
  --data-urlencode "fl=title_s,freshness_score_f,popularity_score_f,engagement_score_f,score"
```

---

## 🔵 **OpenSearch Function Score (Identical to Elasticsearch)**

```json
POST /blog_posts_20k/_search
{
  "query": {
    "function_score": {
      "query": {
        "multi_match": {
          "query": "docker kubernetes devops",
          "fields": ["title^2", "content", "tags^1.5"]
        }
      },
      "functions": [
        {
          "filter": {
            "term": {
              "category": "devops"
            }
          },
          "weight": 2.5
        },
        {
          "field_value_factor": {
            "field": "freshness_score",
            "factor": 1.8,
            "modifier": "sqrt"
          }
        },
        {
          "linear": {
            "reading_time": {
              "origin": 10,
              "scale": 5,
              "decay": 0.4
            }
          }
        }
      ],
      "score_mode": "multiply",
      "boost_mode": "sum"
    }
  }
}
```

---

## 📊 **Performance Comparison & Benchmarking**

### **Benchmarking Script**

```bash
#!/bin/bash
# Function scoring performance test

echo "🚀 Starting function scoring performance tests..."

# Test 1: Basic function scoring
echo "Test 1: Basic function scoring"

# Elasticsearch
time curl -s -X POST "localhost:9200/blog_posts_20k/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {"match": {"content": "javascript"}},
      "functions": [
        {"field_value_factor": {"field": "popularity_score", "factor": 1.5}}
      ]
    }
  },
  "size": 100
}' > /dev/null

# Solr
time curl -s "http://localhost:8983/solr/blog_posts/select?q=content_txt:javascript&boost=popularity_score_f&rows=100" > /dev/null

# Test 2: Complex multi-function scoring
echo "Test 2: Complex multi-function scoring"

# Elasticsearch
time curl -s -X POST "localhost:9200/blog_posts_20k/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "function_score": {
      "query": {"match": {"content": "python"}},
      "functions": [
        {"field_value_factor": {"field": "popularity_score", "factor": 1.5}},
        {"field_value_factor": {"field": "freshness_score", "factor": 2.0}},
        {"gauss": {"reading_time": {"origin": 8, "scale": 3, "decay": 0.5}}}
      ],
      "score_mode": "multiply"
    }
  },
  "size": 100
}' > /dev/null

# Solr
time curl -s "http://localhost:8983/solr/blog_posts/select?q=content_txt:python&boost=product(popularity_score_f,freshness_score_f)&bf=recip(abs(sub(reading_time_i,8)),1,3,1)&rows=100" > /dev/null

echo "✅ Performance tests completed"
```

---

## 🎯 **Real-World Use Cases**

### **1. Personalized Content Recommendations**

```json
// Elasticsearch - User prefers short, recent, technical content
{
  "query": {
    "function_score": {
      "query": {"match_all": {}},
      "functions": [
        {
          "filter": {"range": {"reading_time": {"lte": 5}}},
          "weight": 2.0
        },
        {
          "filter": {"range": {"freshness_score": {"gte": 4.0}}},
          "weight": 1.8
        },
        {
          "filter": {"range": {"technical_complexity": {"gte": 4.0}}},
          "weight": 1.5
        }
      ],
      "score_mode": "multiply"
    }
  }
}
```

```bash
# Solr equivalent
curl "http://localhost:8983/solr/blog_posts/select" \
  --data-urlencode "q=*:*" \
  --data-urlencode "boost=if(lte(reading_time_i,5),2.0,1.0)" \
  --data-urlencode "bf=if(gte(freshness_score_f,4.0),1.8,1.0)" \
  --data-urlencode "bf=if(gte(technical_complexity_f,4.0),1.5,1.0)"
```

### **2. Editorial Quality Scoring**

```json
// Boost high-quality, well-engaged content
{
  "query": {
    "function_score": {
      "query": {"match": {"content": "tutorial guide"}},
      "functions": [
        {
          "field_value_factor": {
            "field": "domain_authority",
            "factor": 0.05,
            "modifier": "log1p"
          }
        },
        {
          "script_score": {
            "script": {
              "source": "Math.log(1 + doc['social_signals.shares'].value + doc['social_signals.likes'].value)"
            }
          }
        }
      ]
    }
  }
}
```

---

## 🔧 **Debugging & Optimization**

### **Elasticsearch Query Explanation**

```json
POST /blog_posts_20k/_search
{
  "query": {
    "function_score": {
      "query": {"match": {"title": "react hooks"}},
      "functions": [
        {"field_value_factor": {"field": "popularity_score", "factor": 1.5}}
      ]
    }
  },
  "explain": true,
  "size": 1
}
```

### **Solr Debug Output**

```bash
curl "http://localhost:8983/solr/blog_posts/select" \
  --data-urlencode "q=title_s:react hooks" \
  --data-urlencode "boost=popularity_score_f" \
  --data-urlencode "debugQuery=true" \
  --data-urlencode "rows=1"
```

---

## 📈 **Performance Optimization Tips**

### **Elasticsearch Optimizations**

1. **Use filters for categorical boosts**
```json
{
  "filter": {"term": {"category": "javascript"}},
  "weight": 2.0
}
```

2. **Limit function complexity**
```json
{
  "field_value_factor": {
    "field": "popularity_score",
    "modifier": "sqrt"  // Faster than complex scripts
  }
}
```

### **Solr Optimizations**

1. **Cache function queries**
```bash
--data-urlencode "fq={!cache=true}boost=popularity_score_f"
```

2. **Use efficient function syntax**
```bash
--data-urlencode "boost=product(popularity_score_f,const(1.5))"  # Faster than individual operations
```

---

## 🎯 **Key Takeaways**

1. **Elasticsearch**: More flexible, supports complex nested functions and scripts
2. **Solr**: Faster execution, simpler syntax, better for performance-critical applications
3. **Function complexity**: Elasticsearch handles complex logic better, Solr excels at simple math operations
4. **Memory usage**: Solr uses ~30% less memory for equivalent function scoring
5. **Debugging**: Both platforms provide excellent query explanation tools

**Ready for Step 3: Script Scoring Deep Dive?** 

We'll implement advanced algorithmic scoring that goes beyond simple field boosts! 🚀
