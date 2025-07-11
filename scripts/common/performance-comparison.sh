#!/bin/bash

# performance-comparison.sh
# Runs a series of standardized load tests to compare platform performance.

# Ensure we are running from the script's directory
cd "$(dirname "$0")"

LOAD_TESTER_SCRIPT="./load-testing.sh"
DURATION="30s"

# --- Test Scenarios ---
SCENARIOS=(
  "Write-Heavy:-i 100 -q 10"
  "Read-Heavy:-i 10 -q 100"
  "Balanced-Load:-i 50 -q 50"
)

# --- Run Comparison ---
echo "--- 📊 Starting Performance Comparison ---"

for scenario in "${SCENARIOS[@]}"; do
    # Split scenario name and parameters
    IFS=':' read -r NAME PARAMS <<< "$scenario"

    echo "\n=================================================="
    echo "  Scenario: ${NAME}"
    echo "=================================================="

    # Run the load tester with the specified parameters
    bash "${LOAD_TESTER_SCRIPT}" -d "${DURATION}" ${PARAMS}

    echo "\nWaiting 15 seconds for clusters to stabilize..."
    sleep 15
done

echo "\n--- ✅ Performance Comparison Complete ---"
