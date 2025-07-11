package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net/http"
	"sync"
	"sync/atomic"
	"time"
)

// Configuration struct
type Config struct {
	IndexingRate    int    // documents per second
	QueryRate       int    // queries per second  
	TestDuration    int    // seconds
	ESEndpoint      string
	SolrEndpoint    string
	BulkSize        int    // documents per bulk request
	EnableStats     bool
	StatsInterval   int    // seconds between stats output
}

// Performance metrics
type Metrics struct {
	// Indexing metrics
	TotalIndexed     int64
	IndexingErrors   int64
	IndexingLatency  []time.Duration
	IndexingThroughput float64
	
	// Query metrics  
	TotalQueries     int64
	QueryErrors      int64
	QueryLatency     []time.Duration
	QueryThroughput  float64
	
	// System metrics
	StartTime        time.Time
	EndTime          time.Time
	
	// Concurrent operation metrics
	ConcurrentIndexingAvg time.Duration
	ConcurrentQueryAvg    time.Duration
	InterferenceImpact    float64 // percentage degradation
	
	mu sync.RWMutex
}

// Document structure for testing
type TestDocument struct {
	DocID         int    `json:"doc_id"`
	Title         string `json:"title"`
	Content       string `json:"content"`
	Category      string `json:"category"`
	DocSize       int    `json:"doc_size"`
	BatchNumber   int    `json:"batch_number"`
	Timestamp     string `json:"created_timestamp"`
	LabPhase      string `json:"lab_phase"`
}

// Solr document structure
type SolrDocument struct {
	ID            string `json:"id"`
	DocID         int    `json:"doc_id_i"`
	Title         string `json:"title_txt"`
	Content       string `json:"content_txt"`
	Category      string `json:"category_s"`
	DocSize       int    `json:"doc_size_i"`
	BatchNumber   int    `json:"batch_number_i"`
	Timestamp     string `json:"created_timestamp_dt"`
	LabPhase      string `json:"lab_phase_s"`
}

var metrics = &Metrics{
	IndexingLatency: make([]time.Duration, 0),
	QueryLatency:    make([]time.Duration, 0),
}

func main() {
	config := Config{
		IndexingRate:  10,  // 10 docs/sec default
		QueryRate:     5,   // 5 QPS default  
		TestDuration:  60,  // 1 minute test
		ESEndpoint:    "http://localhost:9199",
		SolrEndpoint:  "http://localhost:8999",
		BulkSize:      10,
		EnableStats:   true,
		StatsInterval: 10,
	}
	
	fmt.Println("🚀 Lab 5: Concurrent Read/Write Performance Testing")
	fmt.Printf("📊 Configuration: %d docs/sec indexing, %d QPS querying, %d second test\n", 
		config.IndexingRate, config.QueryRate, config.TestDuration)
	
	metrics.StartTime = time.Now()
	
	// Create context for graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(config.TestDuration)*time.Second)
	defer cancel()
	
	var wg sync.WaitGroup
	
	// Start concurrent indexing for Elasticsearch
	wg.Add(1)
	go func() {
		defer wg.Done()
		runElasticsearchIndexing(ctx, config)
	}()
	
	// Start concurrent querying for Elasticsearch  
	wg.Add(1)
	go func() {
		defer wg.Done()
		runElasticsearchQuerying(ctx, config)
	}()
	
	// Start concurrent indexing for Solr
	wg.Add(1)
	go func() {
		defer wg.Done()
		runSolrIndexing(ctx, config)
	}()
	
	// Start concurrent querying for Solr
	wg.Add(1)
	go func() {
		defer wg.Done()
		runSolrQuerying(ctx, config)
	}()
	
	// Start stats reporting
	if config.EnableStats {
		wg.Add(1)
		go func() {
			defer wg.Done()
			runStatsReporting(ctx, config)
		}()
	}
	
	// Wait for all goroutines to complete
	wg.Wait()
	metrics.EndTime = time.Now()
	
	// Generate final report
	generateFinalReport(config)
}

func runElasticsearchIndexing(ctx context.Context, config Config) {
	indexingTicker := time.NewTicker(time.Second / time.Duration(config.IndexingRate))
	defer indexingTicker.Stop()
	
	batchCounter := 0
	docID := 20000 // Start after existing test data
	
	fmt.Println("🔵 Starting Elasticsearch concurrent indexing...")
	
	for {
		select {
		case <-ctx.Done():
			return
		case <-indexingTicker.C:
			start := time.Now()
			
			// Create bulk request
			var bulkData bytes.Buffer  
			for i := 0; i < config.BulkSize; i++ {
				doc := TestDocument{
					DocID:       docID,
					Title:       fmt.Sprintf("Concurrent Load Document %d", docID),
					Content:     generateRandomContent(docID),
					Category:    "concurrent_load",
					DocSize:     rand.Intn(5000) + 2000,
					BatchNumber: batchCounter,
					Timestamp:   time.Now().UTC().Format(time.RFC3339),
					LabPhase:    "concurrent_readwrite",
				}
				
				// Bulk format
				bulkData.WriteString(fmt.Sprintf(`{"index":{"_id":"%d"}}`, docID))
				bulkData.WriteString("\n")
				
				docBytes, _ := json.Marshal(doc)
				bulkData.Write(docBytes)
				bulkData.WriteString("\n")
				
				docID++
			}
			
			// Send bulk request
			resp, err := http.Post(
				config.ESEndpoint+"/performance_baseline/_bulk",
				"application/x-ndjson",
				&bulkData,
			)
			
			latency := time.Since(start)
			
			if err != nil {
				atomic.AddInt64(&metrics.IndexingErrors, 1)
				log.Printf("ES indexing error: %v", err)
			} else {
				resp.Body.Close()
				atomic.AddInt64(&metrics.TotalIndexed, int64(config.BulkSize))
				
				metrics.mu.Lock()
				metrics.IndexingLatency = append(metrics.IndexingLatency, latency)
				metrics.mu.Unlock()
			}
			
			batchCounter++
		}
	}
}

func runElasticsearchQuerying(ctx context.Context, config Config) {
	queryTicker := time.NewTicker(time.Second / time.Duration(config.QueryRate))
	defer queryTicker.Stop()
	
	queries := []string{
		`{"query":{"match":{"category":"concurrent_load"}},"size":50}`,
		`{"query":{"range":{"doc_size":{"gte":2000,"lte":5000}}},"size":30}`,
		`{"query":{"bool":{"must":[{"match":{"content":"concurrent"}},{"term":{"lab_phase":"concurrent_readwrite"}}]}},"size":20}`,
		`{"query":{"match_all":{}},"aggs":{"category_breakdown":{"terms":{"field":"category"}}},"size":0}`,
	}
	
	fmt.Println("🔵 Starting Elasticsearch concurrent querying...")
	
	for {
		select {
		case <-ctx.Done():
			return
		case <-queryTicker.C:
			query := queries[rand.Intn(len(queries))]
			start := time.Now()
			
			resp, err := http.Post(
				config.ESEndpoint+"/performance_baseline/_search",
				"application/json",
				bytes.NewBufferString(query),
			)
			
			latency := time.Since(start)
			
			if err != nil {
				atomic.AddInt64(&metrics.QueryErrors, 1)
				log.Printf("ES query error: %v", err)
			} else {
				resp.Body.Close()
				atomic.AddInt64(&metrics.TotalQueries, 1)
				
				metrics.mu.Lock()
				metrics.QueryLatency = append(metrics.QueryLatency, latency)
				metrics.mu.Unlock()
			}
		}
	}
}

func runSolrIndexing(ctx context.Context, config Config) {
	indexingTicker := time.NewTicker(time.Second / time.Duration(config.IndexingRate))
	defer indexingTicker.Stop()
	
	batchCounter := 0
	docID := 25000 // Different range for Solr
	
	fmt.Println("🟡 Starting Solr concurrent indexing...")
	
	for {
		select {
		case <-ctx.Done():
			return
		case <-indexingTicker.C:
			start := time.Now()
			
			// Create document batch
			docs := make([]SolrDocument, config.BulkSize)
			for i := 0; i < config.BulkSize; i++ {
				docs[i] = SolrDocument{
					ID:          fmt.Sprintf("solr-concurrent-%d", docID),
					DocID:       docID,
					Title:       fmt.Sprintf("Solr Concurrent Load Document %d", docID),
					Content:     generateRandomContent(docID),
					Category:    "concurrent_load",
					DocSize:     rand.Intn(5000) + 2000,
					BatchNumber: batchCounter,
					Timestamp:   time.Now().UTC().Format(time.RFC3339),
					LabPhase:    "concurrent_readwrite",
				}
				docID++
			}
			
			docsBytes, _ := json.Marshal(docs)
			
			// Send to Solr
			resp, err := http.Post(
				config.SolrEndpoint+"/solr/performance_baseline/update?commit=true",
				"application/json",
				bytes.NewBuffer(docsBytes),
			)
			
			latency := time.Since(start)
			
			if err != nil {
				atomic.AddInt64(&metrics.IndexingErrors, 1)
				log.Printf("Solr indexing error: %v", err)
			} else {
				resp.Body.Close()
				atomic.AddInt64(&metrics.TotalIndexed, int64(config.BulkSize))
				
				metrics.mu.Lock()
				metrics.IndexingLatency = append(metrics.IndexingLatency, latency)
				metrics.mu.Unlock()
			}
			
			batchCounter++
		}
	}
}

func runSolrQuerying(ctx context.Context, config Config) {
	queryTicker := time.NewTicker(time.Second / time.Duration(config.QueryRate))
	defer queryTicker.Stop()
	
	queries := []string{
		"/solr/performance_baseline/select?q=category_s:concurrent_load&rows=50",
		"/solr/performance_baseline/select?q=doc_size_i:[2000 TO 5000]&rows=30",
		"/solr/performance_baseline/select?q=content_txt:concurrent AND lab_phase_s:concurrent_readwrite&rows=20",
		"/solr/performance_baseline/select?q=*:*&facet=true&facet.field=category_s&rows=0",
	}
	
	fmt.Println("🟡 Starting Solr concurrent querying...")
	
	for {
		select {
		case <-ctx.Done():
			return
		case <-queryTicker.C:
			query := queries[rand.Intn(len(queries))]
			start := time.Now()
			
			resp, err := http.Get(config.SolrEndpoint + query)
			
			latency := time.Since(start)
			
			if err != nil {
				atomic.AddInt64(&metrics.QueryErrors, 1)
				log.Printf("Solr query error: %v", err)
			} else {
				resp.Body.Close()
				atomic.AddInt64(&metrics.TotalQueries, 1)
				
				metrics.mu.Lock()
				metrics.QueryLatency = append(metrics.QueryLatency, latency)
				metrics.mu.Unlock()
			}
		}
	}
}

func runStatsReporting(ctx context.Context, config Config) {
	statsTicker := time.NewTicker(time.Duration(config.StatsInterval) * time.Second)
	defer statsTicker.Stop()
	
	for {
		select {
		case <-ctx.Done():
			return
		case <-statsTicker.C:
			elapsed := time.Since(metrics.StartTime).Seconds()
			
			indexed := atomic.LoadInt64(&metrics.TotalIndexed)
			queries := atomic.LoadInt64(&metrics.TotalQueries)
			indexErrors := atomic.LoadInt64(&metrics.IndexingErrors)
			queryErrors := atomic.LoadInt64(&metrics.QueryErrors)
			
			fmt.Printf("📊 Stats @ %.0fs: Indexed=%d (%.1f/s), Queries=%d (%.1f/s), Errors: Index=%d, Query=%d\n",
				elapsed, indexed, float64(indexed)/elapsed, queries, float64(queries)/elapsed, indexErrors, queryErrors)
		}
	}
}

func generateRandomContent(docID int) string {
	templates := []string{
		"This is concurrent load testing content for document %d. The system is under simultaneous read and write pressure to simulate production conditions.",
		"Document %d contains performance testing data designed to stress both indexing and search operations running concurrently in realistic scenarios.",
		"Advanced concurrent testing document %d with substantial content to evaluate system behavior under mixed read-write workloads and resource contention.",
	}
	
	return fmt.Sprintf(templates[docID%len(templates)], docID)
}

func calculateStats() {
	metrics.mu.RLock()
	defer metrics.mu.RUnlock()
	
	duration := metrics.EndTime.Sub(metrics.StartTime).Seconds()
	
	// Calculate throughput
	metrics.IndexingThroughput = float64(atomic.LoadInt64(&metrics.TotalIndexed)) / duration
	metrics.QueryThroughput = float64(atomic.LoadInt64(&metrics.TotalQueries)) / duration
	
	// Calculate average latencies
	if len(metrics.IndexingLatency) > 0 {
		var total time.Duration
		for _, lat := range metrics.IndexingLatency {
			total += lat
		}
		metrics.ConcurrentIndexingAvg = total / time.Duration(len(metrics.IndexingLatency))
	}
	
	if len(metrics.QueryLatency) > 0 {
		var total time.Duration
		for _, lat := range metrics.QueryLatency {
			total += lat
		}
		metrics.ConcurrentQueryAvg = total / time.Duration(len(metrics.QueryLatency))
	}
}

func generateFinalReport(config Config) {
	calculateStats()
	
	fmt.Println("\n🎯 ===== CONCURRENT READ/WRITE PERFORMANCE REPORT =====")
	fmt.Printf("Test Duration: %.1f seconds\n", metrics.EndTime.Sub(metrics.StartTime).Seconds())
	fmt.Printf("Configuration: %d docs/sec indexing, %d QPS querying\n\n", config.IndexingRate, config.QueryRate)
	
	// Indexing Performance
	fmt.Println("📥 INDEXING PERFORMANCE:")
	fmt.Printf("  Total Documents Indexed: %d\n", atomic.LoadInt64(&metrics.TotalIndexed))
	fmt.Printf("  Indexing Throughput: %.2f docs/sec\n", metrics.IndexingThroughput)
	fmt.Printf("  Average Indexing Latency: %v\n", metrics.ConcurrentIndexingAvg)
	fmt.Printf("  Indexing Errors: %d\n", atomic.LoadInt64(&metrics.IndexingErrors))
	
	// Query Performance
	fmt.Println("\n🔍 QUERY PERFORMANCE:")
	fmt.Printf("  Total Queries Executed: %d\n", atomic.LoadInt64(&metrics.TotalQueries))
	fmt.Printf("  Query Throughput: %.2f QPS\n", metrics.QueryThroughput)
	fmt.Printf("  Average Query Latency: %v\n", metrics.ConcurrentQueryAvg)
	fmt.Printf("  Query Errors: %d\n", atomic.LoadInt64(&metrics.QueryErrors))
	
	// Performance Analysis
	fmt.Println("\n⚡ CONCURRENT OPERATION ANALYSIS:")
	expectedIndexing := float64(config.IndexingRate * config.TestDuration)
	expectedQueries := float64(config.QueryRate * config.TestDuration)
	
	indexingEfficiency := (metrics.IndexingThroughput * metrics.EndTime.Sub(metrics.StartTime).Seconds()) / expectedIndexing * 100
	queryingEfficiency := (metrics.QueryThroughput * metrics.EndTime.Sub(metrics.StartTime).Seconds()) / expectedQueries * 100
	
	fmt.Printf("  Indexing Efficiency: %.1f%% (expected vs actual)\n", indexingEfficiency)
	fmt.Printf("  Querying Efficiency: %.1f%% (expected vs actual)\n", queryingEfficiency)
	
	// Resource Contention Analysis
	fmt.Println("\n🔄 RESOURCE CONTENTION IMPACT:")
	if indexingEfficiency < 95 || queryingEfficiency < 95 {
		fmt.Println("  ⚠️  Performance degradation detected - resource contention likely")
		fmt.Printf("  Indexing impact: %.1f%% degradation\n", 100-indexingEfficiency)
		fmt.Printf("  Query impact: %.1f%% degradation\n", 100-queryingEfficiency)
	} else {
		fmt.Println("  ✅ Minimal resource contention - system handling concurrent load well")
	}
	
	// Recommendations
	fmt.Println("\n💡 PERFORMANCE RECOMMENDATIONS:")
	if metrics.ConcurrentIndexingAvg > 500*time.Millisecond {
		fmt.Println("  - Consider optimizing bulk size or indexing rate")
	}
	if metrics.ConcurrentQueryAvg > 200*time.Millisecond {
		fmt.Println("  - Consider query optimization or caching strategies")  
	}
	if atomic.LoadInt64(&metrics.IndexingErrors) > 0 || atomic.LoadInt64(&metrics.QueryErrors) > 0 {
		fmt.Println("  - Investigate error patterns and system stability")
	}
	
	fmt.Println("\n✅ Concurrent Read/Write Performance Test Complete!")
}
