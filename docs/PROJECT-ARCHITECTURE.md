# 🗺️ Project Architecture & Dependency Graph

This document provides a visual representation of the project's architecture. The main diagram below shows the high-level components. **Click on a component to jump to its detailed diagram.**

## Master Architecture Diagram

```mermaid
graph TD
    subgraph "Orchestration"
        A[Core Infrastructure]:::core
        B[Scripts]:::scripts
    end

    subgraph "Assets"
        C[Configuration Files]:::configs
        D[Data]:::data
        E[Tools]:::tools
    end

    subgraph "Learning Content"
        F[Hands-On Labs]:::labs
        G[Documentation]:::docs
    end

    A -- "Mounts" --> C
    B -- "Executes" --> A
    B -- "Applies" --> C
    B -- "Loads" --> D
    F -- "Uses" --> B
    F -- "Uses" --> E
    G -- "Explains" --> A & B & C & D & E & F

    click A "#core-infrastructure-detail" "View Core Infrastructure Details"
    click B "#scripts-detail" "View Scripts Details"
    click C "#configuration-files-detail" "View Configuration Details"
    click D "#data-detail" "View Data Details"
    click E "#tools-detail" "View Tools Details"
    click F "#labs-detail" "View Labs Details"
    click G "#documentation-detail" "View Documentation Details"

    classDef core fill:#f9f,stroke:#333,stroke-width:2px;
    classDef scripts fill:#ccf,stroke:#333,stroke-width:2px;
    classDef configs fill:#ffc,stroke:#333,stroke-width:2px;
    classDef data fill:#fec,stroke:#333,stroke-width:2px;
    classDef tools fill:#cff,stroke:#333,stroke-width:2px;
    classDef labs fill:#cfc,stroke:#333,stroke-width:2px;
    classDef docs fill:#e6e6fa,stroke:#333,stroke-width:2px;
```

---

## Detailed Diagrams

### Core Infrastructure Detail
<a id="core-infrastructure-detail"></a>

```mermaid
graph TD
    A[docker-compose.yml] --> B[configs/nginx]
    A --> C[configs/elasticsearch]
    A --> D[configs/solr]
    A --> E[configs/opensearch]

    style A fill:#f9f
```

### Scripts Detail
<a id="scripts-detail"></a>

```mermaid
graph TD
    A[scripts/unified-setup.sh] --> B[scripts/elasticsearch/setup-es-ha.sh]
    A --> C[scripts/solr/setup-solr-ha.sh]
    A --> D[scripts/opensearch/setup-os-ha.sh]
    E[scripts/common/*] --> F[tools/*]
    E --> G[data/*]

    style A fill:#ccf
    style E fill:#ccf
```

### Configuration Files Detail
<a id="configuration-files-detail"></a>

```mermaid
graph TD
    A[configs] --> B[nginx]
    A --> C[elasticsearch]
    A --> D[solr]
    A --> E[opensearch]
    C --> F[index-templates]
    D --> G[collections]
    E --> H[index-templates]

    style A fill:#ffc
```

### Data Detail
<a id="data-detail"></a>

```mermaid
graph TD
    A[data] --> B[blog-posts]
    A --> C[e-commerce]
    A --> D[logs]
    B --> E[20k-blog-dataset.json]
    B --> F[blog-mapping.json]
    B --> G[blog-schema.xml]

    style A fill:#fec
```

### Tools Detail
<a id="tools-detail"></a>

```mermaid
graph TD
    A[tools] --> B[concurrent-load-tester]
    A --> C[data-generators]
    A --> D[monitoring]
    C -- "Generates" --> E[data/*]
    B -- "Tests" --> F[Core Infrastructure]

    style A fill:#cff
```

### Labs Detail
<a id="labs-detail"></a>

```mermaid
graph TD
    A[labs] --> B[Phase 1-8]
    B -- "Execute" --> C[scripts/*]
    B -- "Interact with" --> D[Core Infrastructure]
    B -- "Use" --> E[tools/*]

    style A fill:#cfc
```

### Documentation Detail
<a id="documentation-detail"></a>

```mermaid
graph TD
    A[docs] --> B[*.md]
    C[learning-materials] --> D[*.md]
    E[root] --> F[00-MASTER-LEARNING-GUIDE.md]
    B & D & F -- "Explain" --> G[All Other Components]

    style A fill:#e6e6fa
    style C fill:#e6e6fa
    style E fill:#e6e6fa
```
