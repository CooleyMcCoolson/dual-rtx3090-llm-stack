# Hardware Setup Guide

Complete hardware specifications and build notes for the dual RTX 3090 LLM stack.

## Build Specifications

### GPUs

| Slot | GPU | VRAM | TDP | PCIe |
|------|-----|------|-----|------|
| 1 (Top) | RTX 3090 Ti | 24GB | 450W | x16 (5.0) |
| 5 (Bottom) | RTX 3090 | 24GB | 350W | x4 (4.0) |

**Total VRAM:** 48GB

### System

| Component | Spec |
|-----------|------|
| CPU | Intel 12th/13th Gen (LGA 1700) |
| RAM | 64GB DDR4 |
| Motherboard | Z690 (x16/x4 config) |
| PSU | 1300W Platinum |
| Case | Full tower with excellent airflow |
| OS | Pop!_OS 22.04 |

## PCIe Configuration

### The x16/x4 Reality

Most consumer motherboards run dual GPUs at x16/x4, not x8/x8. This is fine for LLM inference.

**Why x4 is acceptable:**

| Concern | Reality |
|---------|---------|
| "x4 will bottleneck inference" | Inference happens in VRAM, minimal PCIe traffic |
| "Model loading will be slow" | Yes, 30-90 seconds one-time load, then fast |
| "Should I upgrade motherboard?" | No, x8/x8 gives ~30% gain, not worth platform change |

**PCIe Bandwidth Math:**
- PCIe 4.0 x4 = 8 GB/s
- LLM token generation = ~10-50 MB/s actual traffic
- Bottleneck: Only during initial model load

### Verifying Your Config

```bash
# Check PCIe link speed and width
nvidia-smi -q | grep -A 5 "GPU Link Info"

# Expected output:
# GPU 0: Link Speed 16 GT/s, Link Width 16x
# GPU 1: Link Speed 16 GT/s, Link Width 4x
```

## Power Requirements

### Power Supply Sizing

| Component | Idle | LLM Inference | Gaming/Render |
|-----------|------|---------------|---------------|
| RTX 3090 Ti | 20W | 250-300W | 400-450W |
| RTX 3090 | 15W | 200-250W | 300-350W |
| Rest of system | 100W | 150W | 200W |
| **Total** | 135W | **600-700W** | 900-1000W |

**Recommendation:** 1300W PSU is sufficient for inference. Gaming on both GPUs simultaneously would require more headroom.

### Power Cable Configuration

**Critical:** Use separate power cables for each GPU. Do not daisy-chain.

```
PSU Port 1 → Cable A → 3090 Ti (2x 8-pin)
PSU Port 2 → Cable B → 3090 Ti (1x 8-pin)
PSU Port 3 → Cable C → 3090 (2x 8-pin)
```

## Thermal Management

### Expected Temperatures

| Condition | GPU 0 (Top) | GPU 1 (Bottom) |
|-----------|-------------|----------------|
| Idle | 35-40°C | 30-35°C |
| LLM Inference | 65-72°C | 55-65°C |
| Sustained Load | 70-78°C | 60-70°C |

**Note:** Top GPU runs hotter due to receiving warm air from bottom GPU. This is normal.

### Power Limiting (Recommended)

Reduce power limits for better thermals with minimal performance loss:

```bash
# Apply power limits (survives until reboot)
sudo nvidia-smi -i 0 -pl 300  # 3090 Ti: 300W (vs 450W default)
sudo nvidia-smi -i 1 -pl 250  # 3090: 250W (vs 350W default)

# Make persistent (add to startup script)
echo 'nvidia-smi -i 0 -pl 300 && nvidia-smi -i 1 -pl 250' | sudo tee /etc/rc.local
```

**Impact:** <5% performance reduction, 10-15°C cooler.

### Monitoring

```bash
# Real-time monitoring
watch -n 1 nvidia-smi

# Detailed stats
nvidia-smi dmon -s pucvmet

# Temperature alerts (add to cron)
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader | while read temp; do
  if [ "$temp" -gt 80 ]; then
    echo "GPU temp warning: ${temp}C" | wall
  fi
done
```

## Case Considerations

### Airflow Requirements

Dual 3090s generate significant heat. Case requirements:

- **Minimum:** Mid-tower with 3x 120mm intake, 2x 120mm exhaust
- **Recommended:** Full tower with 3x 140mm intake, direct GPU airflow path
- **Optimal:** Airflow-focused case (Fractal Torrent, Meshify, etc.)

### GPU Clearance

RTX 3090 cards are typically 2.5-3 slots thick. Ensure:

- Sufficient slot spacing between GPUs (at least 1 slot gap preferred)
- Bottom GPU clears any case fans
- Power cables have routing space

## Installation Checklist

### Pre-Installation

- [ ] Verify PSU wattage (1200W+ recommended)
- [ ] Count available 8-pin PCIe power connectors (need 5-6)
- [ ] Measure GPU clearance in case
- [ ] Have separate power cables ready (no daisy-chaining)
- [ ] Check motherboard PCIe slot configuration

### Installation Steps

1. Power off, unplug PSU
2. Install first GPU in top x16 slot
3. Install second GPU in lowest x16 slot (runs at x4)
4. Connect power cables (separate cables per GPU)
5. Verify clearances, close case
6. Boot, verify both GPUs detected: `nvidia-smi`

### Post-Installation

- [ ] Both GPUs show in `nvidia-smi`
- [ ] Temperatures reasonable at idle (<45°C)
- [ ] Run stress test: `gpu-burn` or LLM inference
- [ ] Apply power limits for thermal headroom
- [ ] Configure monitoring alerts

## Troubleshooting

### GPU Not Detected

```bash
# Check PCIe devices
lspci | grep -i nvidia

# Should show two entries
# If only one, check seating and power connections
```

### High Temperatures

1. Verify case airflow (intake at front, exhaust at rear/top)
2. Apply power limits (see above)
3. Consider undervolting (advanced)
4. Check thermal paste if temps exceed 85°C

### Power Issues

Signs of insufficient power:
- System crashes under load
- GPU clocks throttling
- Coil whine changes dramatically

Solutions:
- Verify separate cables per GPU
- Check PSU rating matches actual needs
- Consider higher wattage PSU
