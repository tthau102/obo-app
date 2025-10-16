#!/bin/bash
#
# Script: install-dependencies.sh
# Description: Install all required dependencies for local development
# Usage: ./scripts/setup/install-dependencies.sh
#

set -e

echo "========================================="
echo "Installing OBO App Dependencies"
echo "========================================="

# Check if running on macOS or Linux
OS="$(uname -s)"
echo "Detected OS: $OS"

# Install Java 11 if not present
if ! command -v java &> /dev/null; then
    echo "Java not found. Installing Java 11..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install openjdk@11
    elif [[ "$OS" == "Linux" ]]; then
        sudo apt-get update
        sudo apt-get install -y openjdk-11-jdk
    fi
else
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    echo "Java $JAVA_VERSION is already installed"
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker manually:"
    echo "  macOS: https://docs.docker.com/desktop/install/mac-install/"
    echo "  Linux: https://docs.docker.com/engine/install/"
    exit 1
else
    echo "Docker $(docker --version) is installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing..."
    if [[ "$OS" == "Linux" ]]; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Please install Docker Compose manually from: https://docs.docker.com/compose/install/"
        exit 1
    fi
else
    echo "Docker Compose $(docker-compose --version) is installed"
fi

# Install kubectl if not present (for K8s deployment)
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Installing..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install kubectl
    elif [[ "$OS" == "Linux" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi
else
    echo "kubectl $(kubectl version --client --short 2>/dev/null) is installed"
fi

# Make Maven wrapper executable
chmod +x ./mvnw

echo ""
echo "✅ All dependencies installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env and configure your environment"
echo "  2. Start MySQL: docker-compose up -d mysql"
echo "  3. Run application: ./mvnw spring-boot:run"
echo ""
