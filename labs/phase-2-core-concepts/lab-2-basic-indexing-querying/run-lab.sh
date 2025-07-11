#!/bin/bash

# Lab 2: Basic Indexing and Querying
# This script indexes a single document into each platform and then retrieves it.

DOC_ID="lab2-doc-$(date +%s)"

# --- Elasticsearch ---
echo "--- Elasticsearch: Indexing and Querying ---_"

# Index a document
curl -s -X POST "http://localhost:9199/blog_posts/_doc/${DOC_ID}" -H 'Content-Type: application/json' -d'{
  "title": "ES Test Document for Lab 2",
  "content": "This demonstrates basic indexing in Elasticsearch.",
  "category": "testing"
}'

# Wait for indexing to complete
sleep 2

# Query for the document
echo "\nQuerying Elasticsearch for the new document:"
curl -s -X GET "http://localhost:9199/blog_posts/_search?q=title:\"ES Test Document for Lab 2\"&pretty"
echo "\n"

# --- Solr ---
echo "--- Solr: Indexing and Querying ---"

# Index a document
curl -s -X POST "http://localhost:8999/solr/blog_posts/update/json?commit=true" -H 'Content-Type: application/json' -d'[
  {
    "id": "'"$DOC_ID"'",
    "title": "Solr Test Document for Lab 2",
    "content_txt": "This demonstrates basic indexing in Solr.",
    "category_s": "testing"
  }
]'

# Query for the document
echo "\nQuerying Solr for the new document:"
curl -s "http://localhost:8999/solr/blog_posts/select?q=title:\"Solr Test Document for Lab 2\"&wt=json&indent=true"
echo "\n"

# --- OpenSearch ---
echo "--- OpenSearch: Indexing and Querying ---"

# Index a document
curl -s -X POST "http://localhost:9399/blog_posts/_doc/${DOC_ID}" -H 'Content-Type: application/json' -d'{
  "title": "OpenSearch Test Document for Lab 2",
  "content": "This demonstrates basic indexing in OpenSearch.",
  "category": "testing"
}'

# Wait for indexing to complete
sleep 2

# Query for the document
echo "\nQuerying OpenSearch for the new document:"
curl -s -X GET "http://localhost:9399/blog_posts/_search?q=title:\"OpenSearch Test Document for Lab 2\"&pretty"
echo "\n"

echo "✅ Lab 2 Complete: Basic indexing and querying demonstrated on all platforms."
