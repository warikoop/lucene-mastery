#!/bin/bash

# generate-test-data.sh
# A script to run all Python data generators.

# Ensure we are running from the script's directory
cd "$(dirname "$0")"

DATA_GENERATOR_DIR="../../tools/data-generators"

echo "--- ģ Generating All Test Datasets ---"

# Check if python is available
if ! command -v python &> /dev/null
then
    echo "Error: python could not be found. Please install Python to run the data generators."
    exit 1
fi

# Generate Blog Post Dataset
echo "\nGenerating 20k blog posts..."
python "${DATA_GENERATOR_DIR}/blog-dataset-generator.py"

# Generate E-commerce Dataset
echo "\nGenerating 5k e-commerce products..."
python "${DATA_GENERATOR_DIR}/e-commerce-generator.py"

# Generate Log Data
echo "\nGenerating 10k log entries..."
python "${DATA_GENERATOR_DIR}/log-data-generator.py"

echo "\n--- ✅ All Datasets Generated Successfully ---"
