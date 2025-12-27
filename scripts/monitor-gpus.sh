#!/bin/bash
# monitor-gpus.sh - Real-time GPU monitoring for LLM inference
#
# Usage: ./scripts/monitor-gpus.sh

set -e

# Check for nvidia-smi
if ! command -v nvidia-smi &>/dev/null; then
    echo "Error: nvidia-smi not found. Are NVIDIA drivers installed?"
    exit 1
fi

echo "=== GPU Monitor - Press Ctrl+C to exit ==="
echo ""

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                    DUAL RTX 3090 LLM MONITOR                       ║"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    echo ""

    # GPU Stats
    nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,power.limit,utilization.gpu,memory.used,memory.total \
        --format=csv,noheader,nounits | while IFS=',' read -r idx name temp power plimit util memused memtotal; do
        # Trim whitespace
        idx=$(echo "$idx" | xargs)
        name=$(echo "$name" | xargs)
        temp=$(echo "$temp" | xargs)
        power=$(echo "$power" | xargs)
        plimit=$(echo "$plimit" | xargs)
        util=$(echo "$util" | xargs)
        memused=$(echo "$memused" | xargs)
        memtotal=$(echo "$memtotal" | xargs)

        # Calculate memory percentage
        mempct=$((memused * 100 / memtotal))

        # Color coding for temperature
        if [ "$temp" -gt 80 ]; then
            tempcolor="\033[1;31m"  # Red
        elif [ "$temp" -gt 70 ]; then
            tempcolor="\033[1;33m"  # Yellow
        else
            tempcolor="\033[1;32m"  # Green
        fi

        echo -e "GPU $idx: $name"
        echo -e "  Temp: ${tempcolor}${temp}°C\033[0m | Power: ${power}W / ${plimit}W"
        echo -e "  Util: ${util}% | Memory: ${memused}MB / ${memtotal}MB (${mempct}%)"
        echo ""
    done

    echo "╠════════════════════════════════════════════════════════════════════╣"
    echo ""

    # Docker stats (if running)
    if docker ps -q | head -1 | grep -q .; then
        echo "Docker Containers:"
        docker stats --no-stream --format "  {{.Name}}: CPU {{.CPUPerc}}, Mem {{.MemUsage}}" 2>/dev/null | head -5
    else
        echo "No Docker containers running"
    fi

    echo ""
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo "Updated: $(date '+%Y-%m-%d %H:%M:%S') | Refresh: 2s"

    sleep 2
done
