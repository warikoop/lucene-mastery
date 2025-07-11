#!/bin/bash

# Lab 6: High-Query Throughput Performance
# This script runs the concurrent load tester with a high query rate.

echo "--- Running High-Query Throughput Performance Test ---"
echo "This will run for 60 seconds with 50 queries/sec and no indexing."

# Navigate to the load tester directory from the lab's location
cd ../../../tools/concurrent-load-tester

# Run the Go-based load tester
go run lab5-concurrent-load-tester.go -duration 60s -indexRate 0 -queryRate 50

echo "\n✅ Lab 6 Complete: High-query throughput performance measured."
