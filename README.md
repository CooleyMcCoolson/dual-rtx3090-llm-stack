# Dual RTX 3090 LLM Stack

A complete local AI setup running on dual NVIDIA RTX 3090 GPUs (48GB VRAM total). Includes agents, RAG, web search, and workflow automation - all running locally for privacy and unlimited usage.

**Built on:** [Cole Medin's local-ai-packaged](https://github.com/coleam00/local-ai-packaged) - full credit to Cole for the excellent foundation.

## What This Adds

- **Dual GPU configuration** for 70B+ parameter models
- **Benchmarks and performance tuning** specific to RTX 3090s
- **Ready-to-use n8n workflows** for common tasks
- **Troubleshooting guide** from real-world deployment
- **Model recommendations** optimized for 48GB VRAM

## Hardware Specs

| Component | Spec |
|-----------|------|
| GPU 1 | NVIDIA RTX 3090 Ti (24GB VRAM) |
| GPU 2 | NVIDIA RTX 3090 (24GB VRAM) |
| Total VRAM | 48GB |
| RAM | 64GB DDR4 |
| PCIe Config | x16 + x4 (works fine for inference) |
| OS | Pop!_OS 22.04 |

## What You Can Run

With 48GB VRAM, you can run models that typically require enterprise hardware:

| Model | Size | Speed | Use Case |
|-------|------|-------|----------|
| Qwen 2.5 72B Q4 | 40GB | 25-35 t/s | Best all-around quality |
| Llama 3.3 70B Q4 | 38GB | 28-38 t/s | Reasoning, analysis |
| DeepSeek-R1 32B | 18GB | 50-70 t/s | Fast reasoning |
| Qwen 2.5 32B Q5 | 20GB | 45-60 t/s | Quick daily tasks |

## Quick Start

### Prerequisites

- Docker Desktop or Docker Engine with Compose
- NVIDIA drivers installed (`nvidia-smi` works)
- NVIDIA Container Toolkit

### 1. Clone Cole's Stack

```bash
cd ~/projects
git clone https://github.com/coleam00/local-ai-packaged.git
cd local-ai-packaged
```

### 2. Start with NVIDIA Profile

```bash
python3 start_services.py --profile gpu-nvidia
```

### 3. Pull Models

```bash
# 72B model (uses both GPUs)
docker exec -it ollama ollama pull qwen2.5:72b-instruct-q4_K_M

# Faster 32B for quick tasks
docker exec -it ollama ollama pull qwen2.5:32b-instruct-q5_K_M

# Embeddings for RAG
docker exec -it ollama ollama pull nomic-embed-text
```

### 4. Access Services

| Service | URL | Purpose |
|---------|-----|---------|
| Open WebUI | http://localhost:8080 | Chat interface |
| n8n | http://localhost:5678 | Workflow builder |
| SearXNG | http://localhost:8081 | Web search |

## Documentation

- [Hardware Setup](docs/HARDWARE.md) - Build details, PCIe considerations
- [Dual GPU Configuration](docs/DUAL-GPU-SETUP.md) - Multi-GPU specifics
- [Model Recommendations](docs/MODEL-RECOMMENDATIONS.md) - What fits, what's fast
- [Performance Tuning](docs/PERFORMANCE-TUNING.md) - Power limits, thermals
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and fixes

## Workflows

Pre-built n8n workflows in the `workflows/` directory:

- **Research Assistant** - Web search + summarization
- **Document Q&A** - RAG-powered document chat
- **Daily Briefing** - Automated news summary

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    DOCKER DESKTOP                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Ollama  │  │Open WebUI│  │   n8n    │              │
│  │ (Models) │  │  (Chat)  │  │(Workflow)│              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│       └─────────────┼─────────────┘                     │
│  ┌──────────┐  ┌────┴─────┐  ┌──────────┐              │
│  │ SearXNG  │  │ Supabase │  │  Qdrant  │              │
│  │ (Search) │  │(Database)│  │ (Vectors)│              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
           │                           │
    ┌──────┴──────┐             ┌──────┴──────┐
    │ RTX 3090 Ti │             │  RTX 3090   │
    │   (24GB)    │             │   (24GB)    │
    │ Layers 0-40 │             │ Layers 41-80│
    └─────────────┘             └─────────────┘
```

## Cost Analysis

### One-Time

| Item | Cost |
|------|------|
| RTX 3090 Ti | ~$850 |
| RTX 3090 + PSU | ~$900 |
| **Total** | **~$1,750** |

### Monthly Operating

| Item | Cost |
|------|------|
| Electricity (~700W avg, 8hrs/day) | $20-30 |
| Optional API (Tavily, etc.) | $0-10 |
| **Total** | **$20-40** |

### vs Cloud APIs

Running 70B models locally at $30/month vs $100-200/month for equivalent cloud API usage. ROI in ~12 months, plus unlimited usage and complete privacy.

## Contributing

Contributions welcome! Especially:

- Performance benchmarks on similar hardware
- n8n workflow templates
- Troubleshooting tips
- Model recommendations

## Credits

- [Cole Medin](https://github.com/coleam00) - local-ai-packaged foundation
- [Ollama](https://ollama.com) - Local model serving
- [Open WebUI](https://github.com/open-webui/open-webui) - Chat interface
- [n8n](https://n8n.io) - Workflow automation

## License

MIT License - See [LICENSE](LICENSE)
