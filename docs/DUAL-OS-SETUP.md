# Dual OS Setup Guide

Running the same LLM stack on two operating system installations on the same machine.

## Use Case

You have:
- **OS 1 (Breach):** Privacy-focused work, sensitive data
- **OS 2 (Clean):** Daily use, general productivity, team access

Both need access to the same powerful LLM infrastructure.

## Deployment Strategy

### Option A: Shared Data Directory (Recommended)

Both OS installations access the same data directory for models and configuration.

```
/mnt/shared-data/              # Separate partition or drive
├── ollama-models/             # Downloaded models (100GB+)
├── docker-volumes/            # Persistent container data
│   ├── open-webui/
│   ├── n8n/
│   ├── supabase/
│   └── qdrant/
└── local-ai-config/           # Shared configuration
```

**Pros:**
- Models downloaded once (saves 100GB+ disk)
- Consistent configuration
- Easy to maintain

**Cons:**
- Shared chat history (may not want for sensitive work)
- Must carefully manage RAG documents

### Option B: Fully Separate (Maximum Isolation)

Each OS has its own complete installation.

```
# OS 1 (Breach)
~/local-ai/ollama/
~/local-ai/docker-volumes/

# OS 2 (Clean)
~/local-ai/ollama/
~/local-ai/docker-volumes/
```

**Pros:**
- Complete isolation
- Different RAG documents per OS
- No data leakage between contexts

**Cons:**
- Download models twice (200GB+ total)
- Duplicate maintenance

## Implementation: Shared Data (Option A)

### Step 1: Create Shared Partition

If not already available, create a shared data partition accessible from both OS installs.

```bash
# Create mount point (run on both OSes)
sudo mkdir -p /mnt/shared-ai-data

# Add to /etc/fstab (adjust UUID/device for your system)
# UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /mnt/shared-ai-data ext4 defaults 0 2
```

### Step 2: Set Up Directory Structure

```bash
# Run once (on either OS)
mkdir -p /mnt/shared-ai-data/{ollama-models,docker-volumes,config}
mkdir -p /mnt/shared-ai-data/docker-volumes/{open-webui,n8n,supabase,qdrant}
```

### Step 3: Configure Ollama Model Path

On **both** OSes, set Ollama to use shared model directory:

```bash
# Add to ~/.bashrc or /etc/environment
export OLLAMA_MODELS=/mnt/shared-ai-data/ollama-models
```

Or in docker-compose:

```yaml
services:
  ollama:
    environment:
      - OLLAMA_MODELS=/shared/ollama-models
    volumes:
      - /mnt/shared-ai-data/ollama-models:/shared/ollama-models
```

### Step 4: Clone Stack on Both OSes

```bash
# Run on BOTH OSes
cd ~/projects
git clone https://github.com/coleam00/local-ai-packaged.git
cd local-ai-packaged
```

### Step 5: Configure Volume Mounts

Modify `docker-compose.yml` on both OSes to use shared volumes:

```yaml
services:
  ollama:
    volumes:
      - /mnt/shared-ai-data/ollama-models:/root/.ollama

  open-webui:
    volumes:
      - /mnt/shared-ai-data/docker-volumes/open-webui:/app/backend/data

  n8n:
    volumes:
      - /mnt/shared-ai-data/docker-volumes/n8n:/home/node/.n8n

  # etc.
```

## Implementation: Separate Installs (Option B)

### Step 1: Clone Stack on Each OS

```bash
# Same on both OSes
cd ~/projects
git clone https://github.com/coleam00/local-ai-packaged.git
cd local-ai-packaged
python3 start_services.py --profile gpu-nvidia
```

### Step 2: Pull Models on Each OS

```bash
# Run on BOTH OSes (downloads ~100GB each)
docker exec ollama ollama pull qwen2.5:72b-instruct-q4_K_M
docker exec ollama ollama pull qwen2.5:32b-instruct-q5_K_M
docker exec ollama ollama pull nomic-embed-text
```

### Step 3: Configure Independently

Each OS gets its own:
- `.env` file with different secrets
- RAG document collections
- n8n workflows
- System prompts

## Managing Different Contexts

### Approach: Separate RAG Collections

Even with shared storage, keep RAG documents separate:

```
Open WebUI Collections:
├── breach-methodology    # Only used on Breach OS
├── breach-formats        # Only used on Breach OS
├── general-knowledge     # Used on both
├── team-docs            # Only used on Clean OS
└── personal             # Only used on Clean OS
```

### Approach: Separate User Accounts

Create different Open WebUI users per OS:

- **breach-analyst** - Used on Breach OS
- **daily-user** - Used on Clean OS

Different chat histories, different default models, different RAG access.

### Approach: Separate n8n Workflows

```
workflows/
├── shared/               # Used on both
│   ├── research.json
│   └── summarize.json
├── breach-only/          # Only on Breach OS
│   └── investigation.json
└── clean-only/          # Only on Clean OS
    └── daily-briefing.json
```

## Private Files Per OS

### .gitignore Already Handles This

The repo's `.gitignore` excludes:
- `.env` (secrets)
- `*-private/` (private directories)
- `data/` (local data)

### OS-Specific Private Directories

```
~/projects/dual-rtx3090-llm-stack/
├── prompts/                  # Public (in git)
├── prompts-private/          # Gitignored, OS-specific
│   ├── breach-investigator.md    # Only exists on Breach OS
│   └── team-helper.md            # Only exists on Clean OS
└── workflows-private/        # Gitignored, OS-specific
```

## Syncing Between OSes

### What to Sync

| Content | Sync? | Method |
|---------|-------|--------|
| Git repo | Yes | `git pull` on both |
| Models | Optional | Shared drive or re-download |
| RAG docs | Usually No | OS-specific |
| Workflows | Selective | Export/import specific ones |
| Chat history | Usually No | OS-specific |

### Git Sync Workflow

```bash
# On OS where you made changes
git add .
git commit -m "Add new workflow"
git push

# On other OS
git pull
```

### Workflow Export/Import

Export from n8n on one OS, import on other:

1. n8n → Workflow → Export → Download JSON
2. Save to `workflows/` directory
3. Git commit and push
4. On other OS: git pull
5. n8n → Import → Select JSON

## Checklist: Setting Up Second OS

When you install PopOS on the clean machine partition:

### Pre-Installation
- [ ] Note where shared data partition is mounted
- [ ] Have this repo URL ready

### Post-Installation
- [ ] Install Docker Desktop or Docker Engine
- [ ] Install NVIDIA drivers (`nvidia-smi` works)
- [ ] Install NVIDIA Container Toolkit
- [ ] Mount shared data partition (if using Option A)

### Stack Setup
- [ ] Clone this repo: `git clone <your-repo>`
- [ ] Clone Cole's stack: `git clone https://github.com/coleam00/local-ai-packaged.git`
- [ ] Configure volume mounts (if shared)
- [ ] Start services: `python3 start_services.py --profile gpu-nvidia`
- [ ] Pull models (or verify shared models work)
- [ ] Create Open WebUI account
- [ ] Test chat with 72B model
- [ ] Verify both GPUs active: `nvidia-smi`

### Configuration
- [ ] Create OS-specific `.env`
- [ ] Set up OS-specific RAG collections
- [ ] Import relevant workflows
- [ ] Create OS-specific prompts in `prompts-private/`

## Troubleshooting

### Models Not Found (Shared Setup)

```bash
# Verify path is correct
echo $OLLAMA_MODELS
ls -la /mnt/shared-ai-data/ollama-models

# Check Docker volume mount
docker exec ollama ls /root/.ollama
```

### Permission Issues

```bash
# Ensure both OSes can read/write shared directory
sudo chown -R $USER:$USER /mnt/shared-ai-data
chmod -R 755 /mnt/shared-ai-data
```

### Different Versions

Keep Cole's stack at same version on both OSes:

```bash
cd ~/projects/local-ai-packaged
git pull
docker compose pull
```
