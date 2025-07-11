#!/bin/bash

# Lab 11: Breaking Point Analysis
# This script incrementally increases the load to find the system's limits.

echo "--- Starting Breaking Point Analysis ---"
echo "This test will increase the load in rounds. Monitor for high error rates."

# Navigate to the load tester directory from the lab's location
cd ../../../tools/concurrent-load-tester

# Define the load testing rounds
ROUNDS=(
  "-indexRate 50 -queryRate 25"
  "-indexRate 100 -queryRate 50"
  "-indexRate 150 -queryRate 75"
  "-indexRate 200 -queryRate 100"
  "-indexRate 250 -queryRate 125"
)

# Loop through the rounds
for i in "${!ROUNDS[@]}"; do
  ROUND_NUM=$((i+1))
  PARAMS=${ROUNDS[$i]}
  
  echo "\n--- Round ${ROUND_NUM}: Running with params ${PARAMS} for 30s ---"
  
go run lab5-concurrent-load-tester.go -duration 30s ${PARAMS}
  
  # Optional: Add a sleep if you want to let the cluster cool down between rounds
  # sleep 10
done

echo "\n✅ Lab 11 Complete: Breaking point analysis finished."
