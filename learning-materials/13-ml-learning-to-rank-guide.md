# 🤖 **Machine Learning Model Setup: Learning-to-Rank**

## 🎯 **Overview**
This guide details how to set up and use Learning-to-Rank (LTR) with Elasticsearch, Solr, and OpenSearch in our unified HA environment. LTR allows you to use machine-learning models to re-rank search results for higher precision.

## ✅ **Prerequisites**

### **1. Environment Setup**
Ensure the unified HA environment is running:

```bash
# Navigate to project root
cd /path/to/elastic-search

# Start unified HA environment
./setup/unified-setup.sh

# Verify all clusters are healthy
./setup/verify-setup.sh
```

### **2. LTR Plugin/Feature**
The LTR feature is pre-installed or enabled in the Docker images used in our unified setup, so no additional installation is required.

---

## 🚀 **Lab 1: Elasticsearch Learning-to-Rank**

### **Step 1: Enable the LTR Feature**

First, you need to enable the LTR feature store. This is a one-time setup.

```bash
# Create the .ltr feature store index
curl -XPUT 'http://localhost:9199/.ltr/'
```

### **Step 2: Define a Feature Set**

Features are measurable aspects of your documents that the model will use to score them. Let's define a simple feature set.

```bash
# Create a feature set named 'blog_features'
curl -XPOST 'http://localhost:9199/.ltr/_featureset/blog_features' -H 'Content-Type: application/json' -d '{
    "featureset": {
        "name": "blog_features",
        "features": [
            {
                "name": "title_match",
                "params": [
                    "keywords"
                ],
                "template": {
                    "match": {
                        "title": "{{keywords}}"
                    }
                }
            },
            {
                "name": 'content_match',
                "params": [
                    "keywords"
                ],
                "template": {
                    "match": {
                        "content": "{{keywords}}"
                    }
                }
            },
            {
                "name": "popularity_score",
                "template": {
                    "function_score": {
                        "functions": [
                            {
                                "field_value_factor": {
                                    "field": "popularity_score",
                                    "missing": 0
                                }
                            }
                        ],
                        "query": {
                            "match_all": {}
                        }
                    }
                }
            }
        ]
    }
}'
```

### **Step 3: Upload a Model**

For this lab, we'll use a simple linear model. In a real-world scenario, you would train this model offline with a tool like RankyMcRankFace.

```bash
# Upload a RankNet model
curl -XPOST 'http://localhost:9199/.ltr/_featureset/blog_features/_createmodel' -H 'Content-Type: application/json' -d '{
    "model": {
        "name": "blog_ranknet_model",
        "model": {
            "type": "model/ranknet",
            "definition": {
                "inputs": [
                    {"name": "title_match"},
                    {"name": "content_match"},
                    {"name": "popularity_score"}
                ],
                "layers": [
                    {"dense": {"inputs": 3, "outputs": 1, "activation": "linear"}}
                ],
                "weights": [1.0, 0.5, 2.0] 
            }
        }
    }
}'
```

### **Step 4: Use the LTR Model in a Query**

Now, you can use the `sltr` (scripted LTR) query to re-rank your search results.

```bash
# Search using the LTR model
curl -XPOST 'http://localhost:9199/blog_posts/_search' -H 'Content-Type: application/json' -d '{
    "query": {
        "match": {
            "content": "elasticsearch"
        }
    },
    "rescore": {
        "window_size": 100,
        "query": {
            "rescore_query": {
                "sltr": {
                    "params": {
                        "keywords": "elasticsearch"
                    },
                    "model": "blog_ranknet_model"
                }
            }
        }
    }
}'
```

---

## ☀️ **Lab 2: Solr Learning-to-Rank**

Solr's LTR implementation is similar but uses a different API.

### **Step 1: Upload Feature and Model Configuration**

Solr's LTR requires you to upload your feature definitions and model as part of the managed resources.

```bash
# Upload features to the blog_posts collection
curl -XPUT 'http://localhost:8999/solr/blog_posts/schema/feature-store' -H 'Content-Type:application/json' --data-binary @- <<EOF
[
  {"name": "titleMatch", "class": "org.apache.solr.ltr.feature.SolrFeature", "params":{"q":"{!dismax qf=title}${query}"}},
  {"name": "contentMatch", "class": "org.apache.solr.ltr.feature.SolrFeature", "params":{"q":"{!dismax qf=content}${query}"}},
  {"name": "popularityScore", "class": "org.apache.solr.ltr.feature.FieldValueFeature", "params":{"field":"popularity_score"}}
]
EOF

# Upload a linear model
curl -XPUT 'http://localhost:8999/solr/blog_posts/schema/model-store' -H 'Content-Type:application/json' --data-binary @- <<EOF
{
  "name":"blog_linear_model",
  "class":"org.apache.solr.ltr.model.LinearModel",
  "features":[
    {"name":"titleMatch"},
    {"name":"contentMatch"},
    {"name":"popularityScore"}
  ],
  "params":{
    "weights":{
      "titleMatch":1.0,
      "contentMatch":0.5,
      "popularityScore":2.0
    }
  }
}
EOF
```

### **Step 2: Use the LTR Model in a Query**

Use the `[features]` and `rq` parameters to apply the LTR model.

```bash
# Search using the LTR model
curl 'http://localhost:8999/solr/blog_posts/select?q=content:solr&fl=title,score&rq={!ltr model=blog_linear_model reRankDocs=100 efi.query=solr}'
```

---

## 🔬 **Lab 3: OpenSearch Learning-to-Rank**

OpenSearch's LTR plugin is nearly identical to Elasticsearch's original implementation.

### **Step 1: Enable the LTR Feature Store**

```bash
# Create the .ltr feature store index
curl -XPUT 'http://localhost:9399/.ltr/'
```

### **Step 2: Define a Feature Set**

```bash
# Create a feature set
curl -XPOST 'http://localhost:9399/.ltr/_featureset/blog_features' -H 'Content-Type: application/json' -d '{
    "featureset": {
        "name": "blog_features",
        "features": [
            {
                "name": "title_match",
                "params": ["keywords"],
                "template": {"match": {"title": "{{keywords}}"}}
            },
            {
                "name": "popularity_score",
                "template": {
                    "function_score": {
                        "functions": [{"field_value_factor": {"field": "popularity_score", "missing": 0}}],
                        "query": {"match_all": {}}
                    }
                }
            }
        ]
    }
}'
```

### **Step 3: Upload a Model**

```bash
# Upload a RankNet model
curl -XPOST 'http://localhost:9399/.ltr/_featureset/blog_features/_createmodel' -H 'Content-Type: application/json' -d '{
    "model": {
        "name": "blog_ranknet_model",
        "model": {
            "type": "model/ranknet",
            "definition": {
                "inputs": [{"name": "title_match"}, {"name": "popularity_score"}],
                "layers": [{"dense": {"inputs": 2, "outputs": 1, "activation": "linear"}}],
                "weights": [1.0, 2.0]
            }
        }
    }
}'
```

### **Step 4: Use the LTR Model in a Query**

```bash
# Search using the LTR model
curl -XPOST 'http://localhost:9399/blog_posts/_search' -H 'Content-Type: application/json' -d '{
    "query": {
        "match": {
            "content": "opensearch"
        }
    },
    "rescore": {
        "window_size": 100,
        "query": {
            "rescore_query": {
                "sltr": {
                    "params": {
                        "keywords": "opensearch"
                    },
                    "model": "blog_ranknet_model"
                }
            }
        }
    }
}'
```

---

## 🚀 **Congratulations!**

You have successfully set up and used Learning-to-Rank across all three platforms. You can now experiment with more complex feature sets and models to further improve your search relevance.
