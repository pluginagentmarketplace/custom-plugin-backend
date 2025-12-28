#!/bin/bash
# Language Development Environment Setup Script
# Usage: ./setup_environment.sh <language>

set -e

LANGUAGE=${1:-""}

usage() {
    echo "Usage: $0 <language>"
    echo ""
    echo "Supported languages:"
    echo "  node     - Node.js (JavaScript/TypeScript)"
    echo "  python   - Python 3"
    echo "  go       - Go"
    echo "  java     - Java (OpenJDK)"
    echo "  rust     - Rust"
    exit 1
}

setup_node() {
    echo "Setting up Node.js environment..."
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js via nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        source ~/.nvm/nvm.sh
        nvm install --lts
    fi
    echo "Node.js $(node --version) installed"
    echo "npm $(npm --version) installed"

    # Create package.json if not exists
    if [ ! -f package.json ]; then
        npm init -y
        echo "package.json created"
    fi
}

setup_python() {
    echo "Setting up Python environment..."
    if ! command -v python3 &> /dev/null; then
        echo "Please install Python 3 manually"
        exit 1
    fi
    echo "Python $(python3 --version) installed"

    # Create virtual environment
    if [ ! -d venv ]; then
        python3 -m venv venv
        echo "Virtual environment created"
    fi
    echo "Activate with: source venv/bin/activate"
}

setup_go() {
    echo "Setting up Go environment..."
    if ! command -v go &> /dev/null; then
        echo "Please install Go from https://golang.org/dl/"
        exit 1
    fi
    echo "Go $(go version) installed"

    # Initialize module
    if [ ! -f go.mod ]; then
        read -p "Enter module name: " module_name
        go mod init "$module_name"
        echo "Go module initialized"
    fi
}

setup_rust() {
    echo "Setting up Rust environment..."
    if ! command -v rustc &> /dev/null; then
        echo "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        source ~/.cargo/env
    fi
    echo "Rust $(rustc --version) installed"

    # Initialize project
    if [ ! -f Cargo.toml ]; then
        cargo init
        echo "Cargo project initialized"
    fi
}

case $LANGUAGE in
    node|nodejs|javascript|js)
        setup_node
        ;;
    python|py)
        setup_python
        ;;
    go|golang)
        setup_go
        ;;
    rust)
        setup_rust
        ;;
    *)
        usage
        ;;
esac

echo ""
echo "Environment setup complete!"
