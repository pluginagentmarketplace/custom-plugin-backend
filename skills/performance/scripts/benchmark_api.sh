#!/bin/bash
# API Benchmark Script using wrk or ab
# Usage: ./benchmark_api.sh <url> [duration] [threads] [connections]

URL=${1:-"http://localhost:8000/health"}
DURATION=${2:-"10s"}
THREADS=${3:-4}
CONNECTIONS=${4:-100}

echo "Benchmarking: $URL"
echo "Duration: $DURATION, Threads: $THREADS, Connections: $CONNECTIONS"
echo "================================"

if command -v wrk &> /dev/null; then
    echo "Using wrk..."
    wrk -t$THREADS -c$CONNECTIONS -d$DURATION "$URL"
elif command -v ab &> /dev/null; then
    echo "Using Apache Bench..."
    ab -n 1000 -c $CONNECTIONS "$URL"
else
    echo "Install wrk or ab for benchmarking:"
    echo "  brew install wrk"
    echo "  apt-get install apache2-utils"
    exit 1
fi

echo ""
echo "Benchmark complete!"
