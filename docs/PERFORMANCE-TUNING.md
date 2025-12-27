# Performance Tuning Guide

Optimize your dual RTX 3090 setup for best performance and efficiency.

## Power Management

### Why Limit Power?

| Power Level | Performance | Temperature | Efficiency |
|-------------|-------------|-------------|------------|
| Stock (450W/350W) | 100% | 75-85°C | Low |
| Limited (300W/250W) | 95-97% | 60-70°C | High |
| Aggressive (250W/200W) | 90-92% | 55-65°C | Very High |

**Recommendation:** Limited power saves 200W, drops temps 15°C, loses <5% performance.

### Apply Power Limits

```bash
# Temporary (until reboot)
sudo nvidia-smi -i 0 -pl 300  # 3090 Ti
sudo nvidia-smi -i 1 -pl 250  # 3090

# Verify
nvidia-smi --query-gpu=power.limit --format=csv
```

### Persistent Power Limits

Create startup script:

```bash
# /etc/rc.local or systemd service
#!/bin/bash
nvidia-smi -i 0 -pl 300
nvidia-smi -i 1 -pl 250
```

Or create systemd service:

```bash
# /etc/systemd/system/nvidia-powerlimit.service
[Unit]
Description=Set NVIDIA GPU Power Limits
After=nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi -i 0 -pl 300
ExecStart=/usr/bin/nvidia-smi -i 1 -pl 250
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl enable nvidia-powerlimit.service
```

## Memory Optimization

### Context Window Sizing

| Context | VRAM Impact | When to Use |
|---------|-------------|-------------|
| 4k | Baseline | Quick Q&A |
| 8k | +2GB | Normal conversations |
| 16k | +4GB | Longer documents |
| 32k | +8GB | Complex analysis |

**Default recommendation:** 8k for daily use, increase when needed.

```bash
# Set context window
ollama run qwen2.5:72b --num-ctx 8192
```

### KV Cache Quantization

Reduce memory used by attention cache:

```bash
# In Ollama modelfile or environment
PARAMETER num_ctx 16384
PARAMETER num_batch 512
```

### Keep Models Loaded

Avoid reload latency:

```bash
# Keep model in VRAM for 1 hour
export OLLAMA_KEEP_ALIVE=60m

# Or per-run
ollama run qwen2.5:72b --keepalive 60m
```

## Inference Speed Optimization

### Batch Size Tuning

Larger batches = higher throughput:

```bash
# Increase batch size (more VRAM, faster)
PARAMETER num_batch 1024
```

### Thread Optimization

```bash
# Set CPU threads for non-GPU operations
export OLLAMA_NUM_THREADS=8
```

### GPU Scheduling

```bash
# Use compute-exclusive mode (one app at a time)
sudo nvidia-smi -i 0 -c EXCLUSIVE_PROCESS
sudo nvidia-smi -i 1 -c EXCLUSIVE_PROCESS

# Reset to default when done
sudo nvidia-smi -i 0 -c DEFAULT
sudo nvidia-smi -i 1 -c DEFAULT
```

## Monitoring Setup

### Real-Time Dashboard

Create monitoring script:

```bash
#!/bin/bash
# monitor-gpus.sh

while true; do
    clear
    echo "=== GPU Status ==="
    nvidia-smi --query-gpu=name,temperature.gpu,power.draw,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits
    echo ""
    echo "=== Docker Stats ==="
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    sleep 2
done
```

### Logging

```bash
# Log GPU stats every minute
*/1 * * * * nvidia-smi --query-gpu=timestamp,name,temperature.gpu,power.draw,utilization.gpu,memory.used --format=csv >> /var/log/gpu-stats.csv
```

### Alert on High Temperature

```bash
#!/bin/bash
# temp-alert.sh

THRESHOLD=80

while true; do
    TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | sort -rn | head -1)
    if [ "$TEMP" -gt "$THRESHOLD" ]; then
        echo "GPU TEMP WARNING: ${TEMP}°C" | wall
        # Optional: send notification
    fi
    sleep 30
done
```

## Docker Optimization

### Resource Limits

Prevent containers from consuming too much:

```yaml
services:
  ollama:
    deploy:
      resources:
        limits:
          memory: 32G
        reservations:
          memory: 16G
```

### Storage Driver

Use overlay2 for best performance:

```bash
# /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
```

### Log Rotation

Prevent log files from filling disk:

```yaml
services:
  ollama:
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

## Model Optimization

### Choosing Quantization

| Need | Quantization | Trade-off |
|------|--------------|-----------|
| Best quality | Q6_K | Slower, more VRAM |
| Balanced | Q5_K_M | Good default |
| Speed priority | Q4_K_M | Slight quality drop |
| Maximum speed | Q4_K_S | More quality drop |

### Flash Attention

Enabled by default in modern Ollama. Verify:

```bash
docker logs ollama 2>&1 | grep -i flash
```

### Model Parallelism

For 70B+ models, Ollama automatically splits across GPUs. Monitor balance:

```bash
# Check memory per GPU during inference
watch -n 1 'nvidia-smi --query-gpu=memory.used --format=csv,noheader'
```

## Network Optimization (Remote Access)

### Enable Keep-Alive

For Tailscale/remote connections:

```bash
# Increase TCP keepalive
sudo sysctl -w net.ipv4.tcp_keepalive_time=60
sudo sysctl -w net.ipv4.tcp_keepalive_intvl=10
sudo sysctl -w net.ipv4.tcp_keepalive_probes=6
```

### Compression

If bandwidth limited, enable response compression in Caddy/nginx.

## Benchmarking

### Quick Performance Test

```bash
# Time a response
time docker exec ollama ollama run qwen2.5:72b "Write a haiku about computers"
```

### Detailed Benchmark

```bash
# tokens/second calculation
START=$(date +%s.%N)
docker exec ollama ollama run qwen2.5:72b "Write a 500 word essay about artificial intelligence" > /dev/null
END=$(date +%s.%N)
echo "Time: $(echo "$END - $START" | bc) seconds"
```

### Compare Models

```bash
#!/bin/bash
# benchmark-models.sh

MODELS=("qwen2.5:72b" "qwen2.5:32b" "llama3.3:70b")
PROMPT="Explain quantum computing in 200 words"

for model in "${MODELS[@]}"; do
    echo "=== $model ==="
    START=$(date +%s.%N)
    docker exec ollama ollama run "$model" "$PROMPT" > /dev/null
    END=$(date +%s.%N)
    echo "Time: $(echo "$END - $START" | bc)s"
    echo ""
done
```

## Recommended Settings

### Daily Use Profile

```bash
# Power limits
nvidia-smi -i 0 -pl 300
nvidia-smi -i 1 -pl 250

# Ollama settings
OLLAMA_KEEP_ALIVE=60m
OLLAMA_NUM_THREADS=8

# Model settings
num_ctx: 8192
num_batch: 512
```

### Performance Profile

```bash
# Power limits (higher)
nvidia-smi -i 0 -pl 400
nvidia-smi -i 1 -pl 320

# Ollama settings
OLLAMA_KEEP_ALIVE=120m
OLLAMA_NUM_THREADS=12

# Model settings
num_ctx: 16384
num_batch: 1024
```

### Efficiency Profile

```bash
# Power limits (lower)
nvidia-smi -i 0 -pl 250
nvidia-smi -i 1 -pl 200

# Ollama settings
OLLAMA_KEEP_ALIVE=30m
OLLAMA_NUM_THREADS=6

# Model settings
num_ctx: 4096
num_batch: 256
```
