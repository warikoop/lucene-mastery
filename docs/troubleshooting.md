# Troubleshooting Guide

This guide provides solutions to common problems you might encounter while working with the unified learning environment.

## 1. **502 Bad Gateway from Nginx**

- **Symptom**: `curl` commands to HA endpoints (`:9199`, `:8999`, `:9399`) fail with a 502 error.
- **Cause**: This usually means the backend service (e.g., an Elasticsearch node) is not running or is unhealthy.
- **Solution**:
  1.  Run `docker ps` to check if all `es-`, `solr-`, and `opensearch-` containers are `Up`.
  2.  Check the logs of the down container for errors: `docker logs <container_name>`.
  3.  Ensure the Docker network `search_net` is running correctly.

## 2. **Elasticsearch/OpenSearch Cluster is Yellow or Red**

- **Symptom**: The cluster health endpoint (`/_cluster/health`) shows a `yellow` or `red` status.
- **Cause**:
  - **Yellow**: Primary shards are allocated, but one or more replica shards are not. This often happens if a node has just left the cluster.
  - **Red**: One or more primary shards are unallocated. The cluster is not fully functional.
- **Solution**:
  1.  Check the `/_cat/shards` endpoint to see which shards are `UNASSIGNED`.
  2.  Use the Cluster Allocation Explain API for a detailed reason: `GET /_cluster/allocation/explain`.
  3.  Common causes include insufficient disk space, incorrect data tier routing, or not enough nodes to satisfy the replica count.

## 3. **`docker-compose up` fails with memory errors**

- **Symptom**: Containers fail to start, with logs mentioning memory allocation issues or `bootstrap checks failed`.
- **Cause**: Elasticsearch and OpenSearch require a specific `vm.max_map_count` setting on the host machine.
- **Solution**: On your host machine (not inside a container), run:
  ```bash
  # For Linux
  sudo sysctl -w vm.max_map_count=262144

  # To make it permanent, add the following line to /etc/sysctl.conf:
  # vm.max_map_count=262144
  ```
  For Windows/macOS with Docker Desktop, this is usually configured automatically, but may need adjustment in the Docker Desktop settings under Resources > Advanced.

## 4. **Permission Denied when running `.sh` scripts**

- **Symptom**: Executing a lab script (`./run-lab.sh`) results in a `permission denied` error.
- **Cause**: The script does not have execute permissions.
- **Solution**: Add execute permissions to the script:
  ```bash
  chmod +x <script_name>.sh
  ```
