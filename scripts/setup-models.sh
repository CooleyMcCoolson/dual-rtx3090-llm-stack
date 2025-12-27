#!/bin/bash
# setup-models.sh - Download recommended models for dual RTX 3090 setup
#
# Usage: ./scripts/setup-models.sh [minimal|standard|full]
#
# Profiles:
#   minimal  - Just essentials (~45GB)
#   standard - Recommended set (~80GB) [default]
#   full     - Everything (~120GB)

set -e

PROFILE="${1:-standard}"

echo "=== Dual RTX 3090 LLM Stack - Model Setup ==="
echo "Profile: $PROFILE"
echo ""

# Check if Ollama is accessible
if ! docker exec ollama ollama list &>/dev/null; then
    echo "Error: Cannot connect to Ollama container"
    echo "Make sure the stack is running: docker compose up -d"
    exit 1
fi

pull_model() {
    local model=$1
    echo "Pulling: $model"
    docker exec ollama ollama pull "$model"
    echo ""
}

# Essential models (always installed)
echo "=== Essential Models ==="
pull_model "nomic-embed-text"  # Required for RAG

case $PROFILE in
    minimal)
        echo "=== Minimal Profile ==="
        pull_model "qwen2.5:32b-instruct-q5_K_M"  # Good quality, fits single GPU
        ;;

    standard)
        echo "=== Standard Profile ==="
        pull_model "qwen2.5:72b-instruct-q4_K_M"  # Best quality (uses both GPUs)
        pull_model "qwen2.5:32b-instruct-q5_K_M"  # Fast daily driver
        pull_model "qwen2.5-coder:32b-instruct-q4_K_M"  # Coding specialist
        ;;

    full)
        echo "=== Full Profile ==="
        pull_model "qwen2.5:72b-instruct-q4_K_M"  # Best quality
        pull_model "qwen2.5:32b-instruct-q5_K_M"  # Fast daily driver
        pull_model "qwen2.5-coder:32b-instruct-q4_K_M"  # Coding specialist
        pull_model "llama3.3:70b-instruct-q4_K_M"  # Alternative 70B
        pull_model "deepseek-r1:32b"  # Reasoning specialist
        pull_model "llama3.2-vision:11b"  # Vision capability
        ;;

    *)
        echo "Unknown profile: $PROFILE"
        echo "Usage: $0 [minimal|standard|full]"
        exit 1
        ;;
esac

echo "=== Setup Complete ==="
echo ""
echo "Installed models:"
docker exec ollama ollama list
echo ""
echo "Disk usage:"
docker exec ollama du -sh /root/.ollama/models 2>/dev/null || echo "Could not determine size"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:8080 (Open WebUI)"
echo "  2. Create an account"
echo "  3. Start chatting!"
