# Dev Workstation — Software

## OS

Ubuntu 24.04.4 LTS (Noble Numbat).

## GPU driver

NVIDIA proprietary driver, version 590.48.01 (Linux). CUDA-capable (Ampere, sm_86) — used by LLM workloads ([../ollama/](../ollama/)) for inference acceleration.

```bash
nvidia-smi                   # quick check that the driver is loaded and the GPU is visible
nvidia-smi -q                # full property dump
```

## Development environment

Also serves as the Linux dev box for <your-sibling-repo> project work. Stack details (Python, Node, etc.) live with each tinker-lab project — this file only covers system-level installs that aren't project-scoped.

Not tracked — system-level package lists drift quickly and are reinstalled from muscle memory. Per-project dependencies live with each project in <your-sibling-repo>.
