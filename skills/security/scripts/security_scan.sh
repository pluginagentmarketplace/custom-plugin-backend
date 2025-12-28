#!/bin/bash
# Security Scanning Script
# Usage: ./security_scan.sh [scan_type]

set -e

SCAN_TYPE=${1:-"all"}

echo "Running security scans..."
echo "========================="

run_dependency_scan() {
    echo ""
    echo "Scanning dependencies..."
    if command -v snyk &> /dev/null; then
        snyk test || true
    elif [ -f "requirements.txt" ]; then
        pip-audit -r requirements.txt || true
    elif [ -f "package.json" ]; then
        npm audit || true
    fi
}

run_sast_scan() {
    echo ""
    echo "Running SAST scan..."
    if command -v semgrep &> /dev/null; then
        semgrep --config=auto . || true
    else
        echo "Install semgrep: pip install semgrep"
    fi
}

run_container_scan() {
    echo ""
    echo "Scanning container image..."
    if command -v trivy &> /dev/null; then
        trivy image --severity HIGH,CRITICAL backend-app:latest || true
    else
        echo "Install trivy for container scanning"
    fi
}

case $SCAN_TYPE in
    deps)
        run_dependency_scan
        ;;
    sast)
        run_sast_scan
        ;;
    container)
        run_container_scan
        ;;
    all)
        run_dependency_scan
        run_sast_scan
        run_container_scan
        ;;
    *)
        echo "Usage: $0 [deps|sast|container|all]"
        exit 1
        ;;
esac

echo ""
echo "Security scan complete!"
