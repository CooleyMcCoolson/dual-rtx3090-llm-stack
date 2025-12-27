# Troubleshooting Guide

Common issues and solutions for the dual RTX 3090 LLM stack.

## GPU Issues

### GPUs Not Detected

**Symptom:** `nvidia-smi` shows no GPUs or only one GPU

**Check drivers:**
```bash
nvidia-smi
# Should show both GPUs

# If not, check driver status
sudo dmesg | grep -i nvidia
```

**Solutions:**
1. Reinstall NVIDIA drivers: `sudo apt install nvidia-driver-545`
2. Check physical seating of GPUs
3. Verify power connections (separate cables per GPU)
4. Check BIOS PCIe settings

### Docker Can't Access GPUs

**Symptom:** Containers start but can't use GPU

**Check NVIDIA Container Toolkit:**
```bash
# Verify installation
dpkg -l | grep nvidia-container

# Test GPU access in Docker
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

**Install if missing:**
```bash
# Add NVIDIA repo
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Install toolkit
sudo apt update
sudo apt install nvidia-container-toolkit

# Configure Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Only One GPU Used

**Symptom:** Model fits on single GPU, second GPU idle

**This is normal.** Ollama only uses multiple GPUs when needed. A 32B model fits on one 24GB GPU.

**To verify multi-GPU works:**
```bash
# Run 72B model (requires both GPUs)
ollama run qwen2.5:72b-instruct-q4_K_M

# Watch GPU usage
watch -n 1 nvidia-smi
# Both should show high utilization
```

### Thermal Throttling

**Symptom:** Performance degrades over time, GPU clocks drop

**Check temperatures:**
```bash
nvidia-smi -q -d TEMPERATURE
# Warning if >83°C
```

**Solutions:**
1. Apply power limits:
   ```bash
   sudo nvidia-smi -i 0 -pl 300
   sudo nvidia-smi -i 1 -pl 250
   ```
2. Improve case airflow
3. Check GPU fans are working
4. Clean dust from heatsinks

## Docker Issues

### Docker Compose Not Found / Wrong Version

**Symptom:** `docker-compose: command not found` or `-p shorthand flag error`

**You need Docker Compose v2 (plugin), not v1 (standalone):**
```bash
# Check version
docker compose version
# Should show "Docker Compose version v2.x.x"

# If missing or v1, install v2 plugin:
sudo apt update
sudo apt install docker-compose-v2

# Use new syntax (space, not hyphen)
docker compose up -d   # Correct (v2)
docker-compose up -d   # Old (v1)
```

### Containers Won't Start

**Check Docker status:**
```bash
docker ps -a
docker logs <container_name>
```

**Common fixes:**
```bash
# Restart Docker
sudo systemctl restart docker

# Clean up and restart
docker compose down
docker compose up -d
```

### Port Already in Use

**Symptom:** `Error: port 8080 already in use` or `port 11434 already in use`

**Find what's using it:**
```bash
sudo lsof -i :8080
# or
sudo ss -tlnp | grep 8080
```

**Port 11434 (Ollama) - Most Common Issue:**

If you have standalone Ollama installed (not in Docker), it conflicts with the containerized version:
```bash
# Check if standalone Ollama is running
pgrep ollama

# Stop and disable it
sudo systemctl stop ollama
sudo systemctl disable ollama

# Kill any remaining processes
sudo pkill -9 ollama

# Verify port is free
sudo ss -tlnp | grep 11434
```

**Solutions for other ports:**
1. Stop the conflicting service
2. Change port in docker-compose:
   ```yaml
   ports:
     - "8081:8080"  # Use 8081 externally
   ```

### Out of Disk Space

**Symptom:** Containers fail, disk full errors

**Check Docker disk usage:**
```bash
docker system df
```

**Clean up:**
```bash
# Remove unused containers, images, volumes
docker system prune -a --volumes

# Warning: This removes ALL unused data
```

## Ollama Issues

### Model Loading Fails

**Symptom:** `error loading model: out of memory`

**Check VRAM usage:**
```bash
nvidia-smi
```

**Solutions:**
1. Close other GPU applications
2. Use smaller quantization:
   ```bash
   ollama run qwen2.5:72b-instruct-q3_K_M  # Q3 instead of Q4
   ```
3. Reduce context window:
   ```bash
   ollama run qwen2.5:72b --num-ctx 4096
   ```

### Slow Response Times

**Symptom:** <20 tokens/second on 72B model

**Diagnose:**
```bash
# Check GPU utilization
nvidia-smi
# Should be 80-95% during inference

# Check for throttling
nvidia-smi -q -d PERFORMANCE
```

**Solutions:**
1. Verify both GPUs are being used
2. Check for thermal throttling
3. Ensure model is loaded (first query is slow)
4. Restart Ollama container

### Model Keeps Unloading

**Symptom:** Long load time on every query

**Extend keep-alive:**
```bash
# Temporary
ollama run qwen2.5:72b --keepalive 60m

# Permanent (add to docker-compose environment)
OLLAMA_KEEP_ALIVE=60m
```

## Open WebUI Issues

### Can't Login / Create Account

**Check if service is running:**
```bash
docker ps | grep open-webui
docker logs open-webui
```

**Reset if needed:**
```bash
# Warning: Loses all data
docker compose down
docker volume rm local-ai-packaged_open-webui
docker compose up -d
```

### RAG Not Working

**Check embedding model:**
```bash
docker exec ollama ollama list | grep embed
# Should show nomic-embed-text
```

**Pull if missing:**
```bash
docker exec ollama ollama pull nomic-embed-text
```

**Check collection settings:**
1. Open WebUI → Settings → Documents
2. Verify embedding model is set
3. Try re-uploading a document

### Chat History Lost

**Check volume persistence:**
```bash
docker volume ls | grep webui
docker inspect open-webui | grep -A 10 Mounts
```

Ensure docker-compose has persistent volume:
```yaml
volumes:
  - open-webui-data:/app/backend/data
```

## n8n Issues

### Can't Connect to Ollama

**Symptom:** n8n workflows fail with connection error

**Check Ollama accessibility:**
```bash
# From host
curl http://localhost:11434/api/tags

# Should return JSON with model list
```

**In n8n, use correct URL:**
- If same Docker network: `http://ollama:11434`
- If accessing from host network: `http://host.docker.internal:11434`

### Workflows Not Saving

**Check n8n volume:**
```bash
docker volume inspect local-ai-packaged_n8n
```

**Check permissions:**
```bash
docker exec n8n ls -la /home/node/.n8n
```

## Network Issues

### Can't Access from Other Devices

**Check firewall:**
```bash
sudo ufw status
# If active, add rules:
sudo ufw allow 8080  # Open WebUI
sudo ufw allow 5678  # n8n
```

**Check Docker port binding:**
```bash
docker port open-webui
# Should show 0.0.0.0:8080 (accessible from network)
# NOT 127.0.0.1:8080 (localhost only)
```

### Services Not Accessible

**Verify services are running:**
```bash
docker ps
ss -tlnp | grep -E '8080|5678|11434'
```

**Check for Docker network issues:**
```bash
docker network ls
docker network inspect local-ai-packaged_default
```

## Performance Issues

### Slow Inference

**Checklist:**
1. [ ] Both GPUs detected and used
2. [ ] No thermal throttling
3. [ ] Model loaded (not loading each query)
4. [ ] Context window not too large
5. [ ] No other GPU applications running

### High Memory Usage

**Check system memory:**
```bash
free -h
```

**Check Docker memory:**
```bash
docker stats
```

**If running out of RAM:**
1. Reduce context window
2. Use smaller models
3. Stop unused containers

## Logs and Diagnostics

### Collect All Logs

```bash
# GPU info
nvidia-smi > gpu-info.txt

# Docker logs
docker compose logs > docker-logs.txt

# System info
uname -a > system-info.txt
lsb_release -a >> system-info.txt
```

### Real-Time Monitoring

```bash
# GPU monitoring
watch -n 1 nvidia-smi

# Docker resource usage
docker stats

# System resources
htop
```

## Getting Help

### Before Asking for Help

1. Check this troubleshooting guide
2. Search [r/LocalLLaMA](https://reddit.com/r/LocalLLaMA)
3. Check Cole's repo issues: [local-ai-packaged issues](https://github.com/coleam00/local-ai-packaged/issues)
4. Check Ollama issues: [ollama issues](https://github.com/ollama/ollama/issues)

### Information to Include

When asking for help, provide:
- GPU model and count
- `nvidia-smi` output
- Docker container logs
- Exact error message
- Steps to reproduce
