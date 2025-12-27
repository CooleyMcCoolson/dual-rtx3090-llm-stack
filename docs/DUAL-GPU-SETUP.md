# Dual GPU Setup for Ollama

How to configure and verify dual RTX 3090s for local LLM inference.

## How Ollama Uses Multiple GPUs

Ollama automatically detects and uses multiple GPUs. When you load a model larger than one GPU can hold, it splits the model layers across available GPUs.

```
72B Model (40GB total)
├── Layers 0-40   → GPU 0 (22GB)
└── Layers 41-80  → GPU 1 (22GB)
```

**No manual configuration required** for basic operation.

## Verification

### Check GPU Detection

```bash
# Ollama's view
docker exec ollama ollama list

# System view
nvidia-smi

# Expected: Two GPUs listed with full VRAM
```

### Monitor During Inference

```bash
# Terminal 1: Start chat
docker exec -it ollama ollama run qwen2.5:72b-instruct-q4_K_M

# Terminal 2: Watch GPU usage
watch -n 1 nvidia-smi
```

**Expected during 72B inference:**
- GPU 0: 80-95% utilization, ~22GB memory
- GPU 1: 80-95% utilization, ~22GB memory

## Docker Configuration

### Default (Recommended)

Cole's local-ai-packaged already includes proper GPU config:

```yaml
# In docker-compose.yml
services:
  ollama:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all  # Uses ALL available GPUs
              capabilities: [gpu]
```

### Explicit GPU Selection

If you need to specify GPUs:

```yaml
services:
  ollama:
    environment:
      - NVIDIA_VISIBLE_DEVICES=0,1
      - CUDA_VISIBLE_DEVICES=0,1
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['0', '1']
              capabilities: [gpu]
```

### Using GPU UUIDs (Most Reliable)

GPU IDs can change between reboots. UUIDs are stable:

```bash
# Get GPU UUIDs
nvidia-smi -L
# GPU 0: NVIDIA GeForce RTX 3090 Ti (UUID: GPU-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
# GPU 1: NVIDIA GeForce RTX 3090 (UUID: GPU-yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy)
```

```yaml
environment:
  - NVIDIA_VISIBLE_DEVICES=GPU-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,GPU-yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
```

## Performance Optimization

### Layer Distribution

Ollama distributes layers automatically based on VRAM. For manual control:

```bash
# Set number of layers on GPU (rest goes to CPU/RAM)
docker exec ollama ollama run qwen2.5:72b --num-gpu 999
```

`999` means "put as many layers as possible on GPU" - Ollama calculates the actual split.

### Context Window Tuning

Larger context = more VRAM per GPU:

```bash
# Default context (4k)
ollama run qwen2.5:72b

# Extended context (32k) - uses more VRAM
ollama run qwen2.5:72b --num-ctx 32768
```

**VRAM usage by context:**
| Context | Additional VRAM |
|---------|-----------------|
| 4k | Baseline |
| 8k | +2GB |
| 16k | +4GB |
| 32k | +8GB |
| 64k | +16GB |

With 48GB total, you can run 72B models with up to ~32k context comfortably.

## Model Loading Behavior

### First Load (Slow)

```
Loading model...
[=================>                    ] 45% (copying to VRAM)
```

First load takes 30-90 seconds depending on model size. This is PCIe transfer time.

### Subsequent Queries (Fast)

Model stays in VRAM. New queries start generating immediately.

### Keep Model Loaded

```bash
# Increase keep-alive time (default 5 minutes)
docker exec ollama ollama run qwen2.5:72b --keepalive 60m
```

Or set environment variable:
```yaml
environment:
  - OLLAMA_KEEP_ALIVE=60m
```

## Troubleshooting

### Only One GPU Being Used

**Symptom:** nvidia-smi shows one GPU at 90%+, other at 0%

**Cause:** Model fits on single GPU

**Solution:** This is correct behavior. Smaller models don't need both GPUs. Try a larger model to see both GPUs activate.

### Out of Memory Errors

**Symptom:** `CUDA out of memory` during model load

**Possible causes:**
1. Model too large for 48GB total
2. Context window too large
3. Another process using VRAM

**Solutions:**
```bash
# Check what's using VRAM
nvidia-smi

# Kill other GPU processes if needed
sudo fuser -v /dev/nvidia*

# Try smaller model or quantization
ollama run qwen2.5:72b-instruct-q3_K_M  # Q3 instead of Q4
```

### Uneven GPU Utilization

**Symptom:** GPU 0 at 95%, GPU 1 at 60%

**Cause:** Normal. Layer computation isn't perfectly balanced.

**This is expected.** The GPU with later layers may appear less utilized because it's waiting for earlier layer results.

### Slow Performance

**Symptom:** <20 tokens/second on 72B model

**Check:**
```bash
# Verify both GPUs are being used
nvidia-smi

# Check for thermal throttling
nvidia-smi -q -d PERFORMANCE

# Look for "Perf" state - should be P0 (max) or P2
```

**Solutions:**
1. Improve cooling / apply power limits
2. Close other GPU applications
3. Restart Ollama container

## Advanced: Running Multiple Models

### Model Switching

```bash
# Load different model (unloads previous)
ollama run llama3.3:70b
```

### Parallel Models (Advanced)

Run two Ollama instances, one per GPU:

```bash
# Instance 1: GPU 0 only
CUDA_VISIBLE_DEVICES=0 ollama serve --port 11434

# Instance 2: GPU 1 only
CUDA_VISIBLE_DEVICES=1 ollama serve --port 11435
```

Use case: Run 32B coding model on GPU 0, 32B chat model on GPU 1.

## Summary

| Configuration | Recommendation |
|---------------|----------------|
| Basic setup | No config needed, Ollama auto-detects |
| Docker | Verify `count: all` in compose |
| Verification | `nvidia-smi` during inference |
| Optimization | Set `--keepalive 60m` to avoid reloads |
| Troubleshooting | Check both GPUs show memory usage |
