#!/bin/bash

# Lab 4: Baseline Performance Measurement
# This script runs the concurrent load tester with default settings to establish a baseline.

echo "--- Running Baseline Performance Test ---"
echo "This will run for 60 seconds with 10 docs/sec indexing and 5 queries/sec."

# Navigate to the load tester directory from the lab's location
cd ../../../tools/concurrent-load-tester

# Run the Go-based load tester
go run lab5-concurrent-load-tester.go

echo "\n✅ Lab 4 Complete: Baseline performance measured."
