#!/bin/bash

# Lab 3: Complex Queries and Aggregations
# This script demonstrates how to run analytical queries on each platform.

# --- Elasticsearch ---
echo "--- Elasticsearch: Running Aggregation Query ---"
curl -s -X POST "http://localhost:9199/blog_posts/_search" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "posts_per_category": {
      "terms": { "field": "category" }
    }
  }
}' | jq .aggregations
echo "\n"

# --- Solr ---
echo "--- Solr: Running Faceting Query ---"
curl -s "http://localhost:8999/solr/blog_posts/select?q=*:*&rows=0&facet=true&facet.field=category_s&wt=json&indent=true" | jq .facet_counts
echo "\n"

# --- OpenSearch ---
echo "--- OpenSearch: Running Aggregation Query ---"
curl -s -X POST "http://localhost:9399/blog_posts/_search" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "posts_per_category": {
      "terms": { "field": "category" }
    }
  }
}' | jq .aggregations
echo "\n"

echo "✅ Lab 3 Complete: Complex queries and aggregations demonstrated."
