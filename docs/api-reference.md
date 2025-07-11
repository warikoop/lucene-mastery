# API Reference

This document provides a detailed reference for the most common API endpoints for Elasticsearch, Solr, and OpenSearch, including what they do and when to use them.

## **Elasticsearch & OpenSearch**

*These platforms share a very similar API for core functionalities.*

| Endpoint | What it does | Use Case |
| :--- | :--- | :--- |
| `GET /_cluster/health?pretty` | Provides a quick overview of the cluster's health (status, nodes, shards). | Your first stop for troubleshooting. Quickly check if the cluster is operational. |
| `GET /_cat/nodes?v` | Lists all nodes and their key stats (heap, RAM, CPU, role). | Check resource utilization on each node or identify the current master. |
| `GET /_cat/indices?v` | Lists all indices and their stats (health, doc count, size). | Get a quick overview of your indices, their size, and document counts. |
| `PUT /my-index` | Creates a new index. Can include mappings/settings in the body. | Create an index before indexing. Best practice is to define mappings at creation. |
| `POST /my-index/_doc/{id}` | Adds or updates a document (upsert). | The fundamental operation for adding data to your search engine. |
| `GET /my-index/_doc/{id}` | Retrieves a single document by its unique ID. | Fetch a specific piece of data when you already know its ID. |
| `POST /my-index/_search` | The main endpoint for all search operations (queries, aggs, sorting). | The core search functionality for everything from simple searches to complex analytics. |
| `DELETE /my-index` | Permanently deletes an entire index and all of its data. | Use with caution. For permanently removing data you no longer need. |
| `POST /_bulk` | Performs multiple index, update, or delete operations in a single request. | Essential for efficient indexing. Always use for high-throughput data ingestion. |

---

## **Solr**

| Endpoint | What it does | Use Case |
| :--- | :--- | :--- |
| `GET /solr/admin/collections?action=CLUSTERSTATUS` | Provides a comprehensive overview of the SolrCloud cluster (nodes, shards, replicas). | The primary endpoint for checking the overall health and topology of your SolrCloud cluster. |
| `GET /solr/admin/collections?action=LIST` | Lists the names of all collections in the cluster. | A quick way to see which collections exist in your cluster. |
| `GET /solr/admin/collections?action=CREATE...` | Creates a new collection with a specified configuration (name, shards, replicas). | The first step to setting up a new search application in Solr. |
| `POST /solr/{coll}/update/json?commit=true` | Adds or updates one or more documents. `commit=true` makes them searchable. | Standard way to add JSON documents. Omit commit for bulk loads and commit separately. |
| `GET /solr/{coll}/get?id=1` | Retrieves a single document by its unique ID. | Fetch a specific document when you know its ID. |
| `GET /solr/{coll}/select?q=...` | The main endpoint for querying, supporting a rich query language via URL params. | The core of Solr's search functionality. Used for all search, faceting, and highlighting. |
| `GET /solr/admin/collections?action=DELETE...` | Permanently deletes an entire collection. | Use with caution to remove a collection and all its associated data. |
| `POST /solr/{coll}/update/json` | The same update handler can be used for bulk operations by sending an array of documents. | The most efficient way to index large amounts of data in Solr. |

