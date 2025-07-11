# Production Deployment Guide

This guide outlines critical considerations for deploying and managing a search cluster in a production environment.

## 1. **Cluster Sizing and Capacity Planning**

- **Don't Guess, Test**: Use the performance testing labs in this project as a template. Run tests that simulate your expected production load to determine the appropriate hardware and node count.
- **Start with 3 Master Nodes**: For high availability, you need a minimum of three dedicated master-eligible nodes to avoid split-brain scenarios.
- **Data Nodes**: The number of data nodes depends on your data volume, indexing rate, and query load. Scale out horizontally by adding more data nodes as your needs grow.
- **Monitoring is Key**: Continuously monitor key metrics (CPU, heap usage, disk space, query latency) to know when it's time to scale.

## 2. **Security**

- **Enable Security Features**: In our learning environment, security is disabled for convenience. In production, you **must** enable the native security features of Elasticsearch/OpenSearch or use an external authentication/authorization system.
- **Network Security**: Run your cluster in a private network (VPC). Do not expose your data nodes directly to the public internet. Use a firewall to restrict access to known IP addresses.
- **Use HTTPS**: Encrypt all communication to and from the cluster using TLS/SSL.
- **Role-Based Access Control (RBAC)**: Create roles with the minimum required permissions for different users and applications. Avoid using a single superuser for everything.

## 3. **Backup and Disaster Recovery**

- **Snapshot and Restore**: Regularly take snapshots of your cluster. This is the primary mechanism for backing up your data.
- **Automate Snapshots**: Use the Snapshot Lifecycle Management (SLM) feature in Elasticsearch/OpenSearch to automate the process.
- **Store Snapshots Remotely**: Store your snapshots in a separate, durable location like Amazon S3, Google Cloud Storage, or Azure Blob Storage.
- **Test Your Recovery Process**: A backup is useless if you can't restore from it. Regularly test your disaster recovery plan to ensure you can bring your cluster back online within your required RTO (Recovery Time Objective).

## 4. **Monitoring and Alerting**

- **Monitor Everything**: Set up a robust monitoring solution (like the Prometheus/Grafana stack outlined in the `tools` directory) to track cluster health, performance metrics, and resource utilization.
- **Key Metrics to Watch**:
  - JVM Heap Usage (should stay below 75-80%)
  - CPU Utilization
  - Disk Space (especially important)
  - Indexing and Query Latency
  - Cluster Status (Green, Yellow, Red)
- **Set Up Alerting**: Configure alerts for critical events, such as a cluster turning red, a node going down, or disk space exceeding a threshold. Use the `alerting-rules.yml` as a starting point.
