#!/bin/bash

# load-testing.sh
# A wrapper script for the Go-based concurrent load tester.

# --- Default Parameters ---
DURATION="60s"
INDEX_RATE=10
QUERY_RATE=5

# --- Parse Command-Line Arguments ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--duration)
            DURATION="$2"
            shift # past argument
            shift # past value
            ;;
        -i|--indexRate)
            INDEX_RATE="$2"
            shift # past argument
            shift # past value
            ;;
        -q|--queryRate)
            QUERY_RATE="$2"
            shift # past argument
            shift # past value
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# --- Run the Load Tester ---
LOAD_TESTER_DIR="../../tools/concurrent-load-tester"

echo "--- 🚀 Starting Load Test ---"
echo "Duration: ${DURATION}"
echo "Indexing Rate: ${INDEX_RATE} docs/sec"
echo "Query Rate: ${QUERY_RATE} QPS"
echo "---------------------------"

# Check if Go is available
if ! command -v go &> /dev/null
then
    echo "Error: go could not be found. Please install Go to run the load tester."
    exit 1
fi

# Execute the Go program with the specified parameters
(cd "${LOAD_TESTER_DIR}" && go run lab5-concurrent-load-tester.go -duration "${DURATION}" -indexRate ${INDEX_RATE} -queryRate ${QUERY_RATE})

echo "\n--- ✅ Load Test Complete ---"
