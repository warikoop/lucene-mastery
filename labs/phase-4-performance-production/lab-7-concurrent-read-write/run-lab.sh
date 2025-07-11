#!/bin/bash

# Lab 7: Concurrent Read/Write Performance
# This script runs the concurrent load tester with both a high indexing and query rate.

echo "--- Running Concurrent Read/Write Performance Test ---"
echo "This will run for 120 seconds with 20 docs/sec indexing and 20 queries/sec."

# Navigate to the load tester directory from the lab's location
cd ../../../tools/concurrent-load-tester

# Run the Go-based load tester
go run lab5-concurrent-load-tester.go -duration 120s -indexRate 20 -queryRate 20

echo "\n✅ Lab 7 Complete: Concurrent read/write performance measured."
