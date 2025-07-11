#!/bin/bash

# Lab 5: High-Volume Indexing Performance
# This script runs the concurrent load tester with a high indexing rate.

echo "--- Running High-Volume Indexing Performance Test ---"
echo "This will run for 60 seconds with 50 docs/sec indexing and no querying."

# Navigate to the load tester directory from the lab's location
cd ../../../tools/concurrent-load-tester

# Run the Go-based load tester
go run lab5-concurrent-load-tester.go -duration 60s -indexRate 50 -queryRate 0

echo "\n✅ Lab 5 Complete: High-volume indexing performance measured."
