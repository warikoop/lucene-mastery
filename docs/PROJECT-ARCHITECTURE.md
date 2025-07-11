# 🗺️ Project Architecture & Dependency Graph

This document provides a visual representation of the project's architecture. It shows how the different components, from the core Docker configuration to the individual labs and documentation files, are interconnected.

```mermaid
graph TD
    subgraph "📍 Core Infrastructure"
        A[docker-compose.yml]:::core
    end

    subgraph "🔧 Configuration Files (configs)"
        B(nginx/nginx.conf) --> C(nginx/upstream-config.conf)
        D(elasticsearch/elasticsearch.yml + jvm.options)
        E(solr/solr.xml + solrconfig.xml)
        F(opensearch/opensearch.yml + jvm.options)
        G(elasticsearch/index-templates/blog_posts_template.json)
        H(solr/collections/blog_posts_schema.json)
    end

    subgraph "🚀 Setup & Orchestration (setup)"
        I[unified-setup.sh]:::setup
        J(elasticsearch/setup-es-ha.sh)
        K(solr/setup-solr-ha.sh)
        L(opensearch/setup-os-ha.sh)
    end

    subgraph "🧪 Hands-On Labs (labs)"
        M(Phase 1-3: Foundations & Core Concepts) --> A
        N(Phase 4: Performance Testing) --> O[tools/concurrent-load-tester]
        P(Phase 5: Scaling & Architecture) --> A
        Q(Phase 6-8: Advanced Topics) --> A
    end

    subgraph "🧰 Utilities (tools)"
        O --> R{Go Environment}
        S(data-generators/*.py) --> T[data/*/*.json]
        U(monitoring/*.yml) --> V((External: Prometheus/Grafana))
    end

    subgraph "📚 Documentation (docs, learning-materials, root)"
        W[00-MASTER-LEARNING-GUIDE.md]:::docs
        X[REORGANIZATION-GUIDE.md]:::docs
        Y[learning-materials/*.md]:::docs
        Z[docs/*.md]:::docs
    end

    %% --- Define Relationships ---

    %% Docker <> Configs
    A -- "Mounts Volume" --> B
    A -- "Mounts Volume & Defines Env" --> D
    A -- "Mounts Volume & Defines Env" --> E
    A -- "Mounts Volume & Defines Env" --> F

    %% Setup <> Configs & Data
    I -- "Executes" --> J & K & L
    J -- "Applies Template" --> G
    K -- "Applies Schema" --> H
    L -- "Applies Template" --> G
    J & K & L -- "Indexes Sample Data" --> T

    %% Labs <> Infrastructure & Tools
    M -- "Indexes & Queries Data"
    N -- "Executes Load Tester"
    P -- "Stops/Starts Containers"
    Q -- "Runs Advanced Queries"

    %% Documentation <> Everything
    W -- "Links to" --> Y
    Y -- "Explains Concepts for" --> M & N & P & Q
    Z -- "Provides Reference for" --> A & J & K & L
    X -- "Defines Structure of" --> A & B & D & E & F & I & M & O & S & T & U & W & Y & Z

    %% Style Definitions
    classDef core fill:#f9f,stroke:#333,stroke-width:2px;
    classDef setup fill:#ccf,stroke:#333,stroke-width:2px;
    classDef docs fill:#cfc,stroke:#333,stroke-width:2px;

```

### **How to Read the Graph**

-   **Boxes** represent files or groups of files.
-   **Arrows** indicate a dependency or relationship (e.g., "Mounts Volume", "Executes", "Explains Concepts for").
-   The graph is organized into **subgraphs** that correspond to the main directories in the project.
-   This visualization should make it clear how a change in one part of the project (like a configuration file) might affect other parts (like the setup scripts or the Docker environment).
