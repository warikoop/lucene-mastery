#!/bin/bash

# Lab 9: Learning-to-Rank (LTR)
# This script demonstrates the LTR workflow in Elasticsearch.

echo "--- Setting up Elasticsearch Learning-to-Rank ---"

# Step 1: Create the LTR feature store index
echo "\nStep 1: Creating the .ltr feature store..."
curl -s -XPUT 'http://localhost:9199/.ltr/'

# Step 2: Define a feature set
echo "\nStep 2: Defining the 'blog_features' feature set..."
curl -s -XPOST 'http://localhost:9199/.ltr/_featureset/blog_features' -H 'Content-Type: application/json' -d '{
    "featureset": {
        "name": "blog_features",
        "features": [
            {
                "name": "title_match",
                "params": ["keywords"],
                "template": {"match": {"title": "{{keywords}}"}}
            },
            {
                "name": "content_match",
                "params": ["keywords"],
                "template": {"match": {"content": "{{keywords}}"}}
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

# Step 3: Upload a model
echo "\n\nStep 3: Uploading the 'blog_ranknet_model'..."
curl -s -XPOST 'http://localhost:9199/.ltr/_featureset/blog_features/_createmodel' -H 'Content-Type: application/json' -d '{
    "model": {
        "name": "blog_ranknet_model",
        "model": {
            "type": "model/ranknet",
            "definition": {
                "inputs": [{"name": "title_match"},{"name": "content_match"},{"name": "popularity_score"}],
                "layers": [{"dense": {"inputs": 3, "outputs": 1, "activation": "linear"}}],
                "weights": [1.0, 0.5, 2.0]
            }
        }
    }
}'

# Step 4: Use the LTR model in a query
echo "\n\nStep 4: Running a search query with LTR re-ranking..."
sleep 2 # Allow model to be fully available
curl -s -XPOST 'http://localhost:9199/blog_posts/_search?pretty' -H 'Content-Type: application/json' -d '{
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

echo "\n\n✅ Lab 9 Complete: Learning-to-Rank workflow demonstrated."
