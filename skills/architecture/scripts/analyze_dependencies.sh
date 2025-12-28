#!/bin/bash
# Analyze code dependencies for architecture review
# Usage: ./analyze_dependencies.sh <source_directory>

set -e

SRC_DIR=${1:-"src"}

echo "Analyzing dependencies in: $SRC_DIR"
echo "================================"

# Count files by type
echo ""
echo "File counts:"
find "$SRC_DIR" -name "*.py" | wc -l | xargs echo "  Python files:"
find "$SRC_DIR" -name "*.js" -o -name "*.ts" | wc -l | xargs echo "  JS/TS files:"
find "$SRC_DIR" -name "*.go" | wc -l | xargs echo "  Go files:"

# Find circular imports (Python)
echo ""
echo "Checking for circular imports (Python)..."
if command -v pycycle &> /dev/null; then
    pycycle --here "$SRC_DIR" || echo "No circular imports found"
else
    echo "  Install pycycle for circular import detection: pip install pycycle"
fi

# Count lines of code
echo ""
echo "Lines of code:"
find "$SRC_DIR" -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" | xargs wc -l | tail -1

echo ""
echo "Analysis complete!"
