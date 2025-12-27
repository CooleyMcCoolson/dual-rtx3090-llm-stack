# Model Recommendations for 48GB VRAM

Curated model selection optimized for dual RTX 3090 (48GB total VRAM).

## Quick Reference

### Daily Drivers

| Model | VRAM | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| `qwen2.5:72b-instruct-q4_K_M` | 42GB | 25-35 t/s | Excellent | Everything |
| `qwen2.5:32b-instruct-q5_K_M` | 20GB | 45-60 t/s | Very Good | Quick tasks |
| `llama3.3:70b-instruct-q4_K_M` | 40GB | 28-38 t/s | Excellent | Reasoning |

### Specialists

| Model | VRAM | Speed | Best For |
|-------|------|-------|----------|
| `qwen2.5-coder:32b-q4_K_M` | 18GB | 50-65 t/s | Coding |
| `deepseek-r1:32b` | 18GB | 50-70 t/s | Reasoning chains |
| `llama3.2-vision:11b` | 8GB | 80-100 t/s | Image understanding |
| `nomic-embed-text` | 0.5GB | N/A | RAG embeddings |

## Detailed Model Analysis

### Tier 1: 70B Class (Use Both GPUs)

These models require both GPUs and represent the best quality you can run locally.

#### Qwen 2.5 72B (Recommended Primary)

```bash
ollama pull qwen2.5:72b-instruct-q4_K_M
```

| Aspect | Rating |
|--------|--------|
| General quality | 9/10 |
| Coding | 9/10 |
| Reasoning | 8/10 |
| Instruction following | 9/10 |
| Speed (dual 3090) | 25-35 t/s |

**Why choose:** Best all-around performer. Strong at everything, excellent instruction following.

#### Llama 3.3 70B

```bash
ollama pull llama3.3:70b-instruct-q4_K_M
```

| Aspect | Rating |
|--------|--------|
| General quality | 9/10 |
| Coding | 8/10 |
| Reasoning | 9/10 |
| Instruction following | 8/10 |
| Speed (dual 3090) | 28-38 t/s |

**Why choose:** Slightly better reasoning than Qwen, good for complex analysis.

### Tier 2: 32B Class (Single GPU, Fast)

These fit comfortably on one GPU, leaving the second for other tasks or extended context.

#### Qwen 2.5 32B

```bash
ollama pull qwen2.5:32b-instruct-q5_K_M
```

| Aspect | Rating |
|--------|--------|
| General quality | 8/10 |
| Coding | 8/10 |
| Reasoning | 7/10 |
| Instruction following | 8/10 |
| Speed (single GPU) | 45-60 t/s |

**Why choose:** Fast daily driver. 80-85% of 72B quality at 2x speed.

#### DeepSeek-R1 32B

```bash
ollama pull deepseek-r1:32b
```

| Aspect | Rating |
|--------|--------|
| Reasoning chains | 9/10 |
| Step-by-step thinking | 10/10 |
| Coding | 7/10 |
| General chat | 7/10 |
| Speed | 50-70 t/s |

**Why choose:** Shows reasoning process. Great for learning why an answer is correct.

### Tier 3: Specialists

#### Qwen 2.5 Coder 32B

```bash
ollama pull qwen2.5-coder:32b-instruct-q4_K_M
```

**Best for:** Code generation, debugging, refactoring
**Trade-off:** Weaker at non-coding tasks

#### Llama 3.2 Vision 11B

```bash
ollama pull llama3.2-vision:11b
```

**Best for:** Understanding images, screenshots, diagrams
**Trade-off:** Smaller, less capable for text-only

#### Nomic Embed Text

```bash
ollama pull nomic-embed-text
```

**Required for:** RAG embeddings (vector search)
**Note:** Always keep this loaded alongside chat model

## Quantization Guide

### What the Numbers Mean

| Quantization | Quality | Size | Speed | When to Use |
|--------------|---------|------|-------|-------------|
| Q8 | 99.9% | Largest | Slowest | Almost never (too big) |
| Q6_K | 99% | Large | Slow | When quality is critical |
| Q5_K_M | 98% | Medium | Good | **Recommended default** |
| Q4_K_M | 96% | Smaller | Faster | Good balance |
| Q3_K_M | 93% | Small | Fastest | Quality drops noticeably |
| Q2_K | 85% | Smallest | Fastest | Avoid for serious use |

### Recommendation

**Use Q4_K_M for 70B models** - fits in 48GB with room for context
**Use Q5_K_M for 32B models** - single GPU has headroom for better quality

## Context Window Considerations

### VRAM Cost by Context

| Context Size | Extra VRAM | Total for 72B Q4 |
|--------------|------------|------------------|
| 4k (default) | +0GB | 42GB |
| 8k | +2GB | 44GB |
| 16k | +4GB | 46GB |
| 32k | +8GB | 50GB (overflow to RAM) |

### Maximum Practical Context

With 48GB VRAM:
- **72B Q4:** Up to 16k in pure VRAM, 32k with slight RAM overflow
- **32B Q5:** Up to 64k in pure VRAM
- **32B Q4:** Up to 80k+ in pure VRAM

### Setting Context

```bash
# Extended context
ollama run qwen2.5:72b-instruct-q4_K_M --num-ctx 16384
```

## My Recommended Setup

### Install These Models

```bash
# Primary: Best quality (uses both GPUs)
ollama pull qwen2.5:72b-instruct-q4_K_M

# Fast: Quick tasks (single GPU)
ollama pull qwen2.5:32b-instruct-q5_K_M

# Coding: When doing development
ollama pull qwen2.5-coder:32b-instruct-q4_K_M

# Reasoning: Complex analysis
ollama pull deepseek-r1:32b

# RAG: Required for document Q&A
ollama pull nomic-embed-text
```

### Storage Required

| Model | Size on Disk |
|-------|--------------|
| qwen2.5:72b-q4 | 41GB |
| qwen2.5:32b-q5 | 22GB |
| qwen2.5-coder:32b-q4 | 18GB |
| deepseek-r1:32b | 18GB |
| nomic-embed-text | 274MB |
| **Total** | ~100GB |

### Decision Tree

```
Need best quality?
├── Yes → qwen2.5:72b
└── No, need speed?
    ├── Yes → qwen2.5:32b
    └── No, specific task?
        ├── Coding → qwen2.5-coder:32b
        ├── Reasoning → deepseek-r1:32b
        └── Images → llama3.2-vision:11b
```

## Performance Expectations

### Tokens Per Second by Model

| Model | Single 3090 | Dual 3090 |
|-------|-------------|-----------|
| 72B Q4 | N/A (won't fit) | 25-35 t/s |
| 70B Q4 | N/A (won't fit) | 28-38 t/s |
| 32B Q5 | 45-60 t/s | N/A (doesn't need both) |
| 32B Q4 | 55-75 t/s | N/A |

### What These Speeds Feel Like

| Speed | Experience |
|-------|------------|
| 10-20 t/s | Slow, like watching someone type slowly |
| 25-35 t/s | Comfortable, like reading a fast typer |
| 45-60 t/s | Fast, responses appear quickly |
| 75+ t/s | Very fast, nearly instant responses |

## Switching Models

### Via Command Line

```bash
# Stop current, load new
ollama run llama3.3:70b
```

### Via Open WebUI

1. Click model dropdown (top of chat)
2. Select new model
3. Wait for load (~30-60 seconds for 70B)

### Keep Models Loaded

```bash
# Extend keep-alive to 1 hour
ollama run qwen2.5:72b --keepalive 60m
```
