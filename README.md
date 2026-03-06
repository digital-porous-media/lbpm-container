# LBPM Container Recipes

Apptainer/Singularity container recipes for
[LBPM](https://github.com/OPM/LBPM) — a lattice Boltzmann simulation
framework for flow and transport in porous media.

Pre-built containers are available on
[Docker Hub](https://hub.docker.com/r/bchang19/lbpm).

---

## Quick Start

**x86 (TACC Lonestar6, A100 GPUs):**
```bash
# Pull the container
apptainer pull lbpm_mrt.sif \
    oras://docker.io/bchang19/lbpm:mrt-x86-cuda11-latest

# Run with 1 GPU (default)
apptainer run --nv lbpm_mrt.sif /path/to/input.db

# Run with 3 GPUs
apptainer run --nv lbpm_mrt.sif /path/to/input.db 3
```

**ARM (TACC Vista, GH200 GPUs):**
```bash
# Pull the container
apptainer pull lbpm_mrt.sif \
    oras://docker.io/bchang19/lbpm:mrt-arm-cuda13-latest

# Run
apptainer run --nv lbpm_mrt.sif /path/to/input.db
```

---

## Available Images

### x86 (CUDA 11.4, Rocky Linux 8, A100)

| Tag | Description |
|-----|-------------|
| `mrt-x86-cuda11-latest` | MRT Permeability simulator |
| `morphdrain-x86-cuda11-latest` | Morphological drain post-processor |
| `color-x86-cuda11-latest` | Color (two-phase) simulator |
| `builder-x86-cuda11-latest` | Full LBPM build with all executables |
| `toolchain-x86-cuda11-latest` | GCC11 + OpenMPI 5.0.3 + HDF5 1.14.3 + CUDA 11.4 |

### ARM (CUDA 13.1, Ubuntu 24.04, GH200)

| Tag | Description |
|-----|-------------|
| `mrt-arm-cuda13-latest` | MRT Permeability simulator |
| `morphdrain-arm-cuda13-latest` | Morphological drain post-processor |
| `color-arm-cuda13-latest` | Color (two-phase) simulator |
| `builder-arm-cuda13-latest` | Full LBPM build with all executables |
| `toolchain-arm-cuda13-latest` | GCC13 + OpenMPI 5.0.5 + HDF5 1.14.3 + CUDA 13.1 |

All images are also available with version tags (e.g. `mrt-x86-cuda11-v1.0`).
To inspect the exact LBPM commit built into an image:

```bash
apptainer inspect lbpm_mrt.sif | grep LBPM
```

---

## Requirements

| | x86 | ARM |
|--|-----|-----|
| Architecture | x86_64 | aarch64 |
| GPU | NVIDIA A100 or similar | NVIDIA GH200 |
| CUDA Driver | 11.4+ | 13.1+ |
| Cluster | TACC Lonestar6 or similar | TACC Vista or similar |
| Max GPUs | 3 (single node) | 1 (single GH200) |

> **Note:** These containers use shared memory MPI transport and are
> limited to single-node execution. For multi-node jobs, please compile
> LBPM manually against your cluster's MPI implementation. See the
> [LBPM documentation](https://github.com/OPM/LBPM) for details.

---

## Job Submission

Sample SLURM job scripts are provided in `examples/`:

```bash
# TACC Lonestar6
sbatch examples/tacc_ls6_job.sh /path/to/input.db

# Generic SLURM cluster
sbatch examples/generic_job.sh /path/to/input.db
```

---

## Repository Structure

```
lbpm-containers/
├── README.md
├── recipes/
│   ├── base/
│   │   ├── lbpm_toolchain_x86_cuda11.def   # GCC11 + OpenMPI 5.0.3 + HDF5 + CUDA 11.4
│   │   └── lbpm_toolchain_arm_cuda13.def   # GCC13 + OpenMPI 5.0.5 + HDF5 + CUDA 13.1
│   ├── builder/
│   │   ├── lbpm_builder_x86_cuda11.def     # Compiles LBPM (x86)
│   │   └── lbpm_builder_arm_cuda13.def     # Compiles LBPM (ARM)
│   └── template/
│       ├── lbpm_app_template_gpu.def       # Template for x86 GPU app containers
│       └── lbpm_app_template_arm_cuda13.def # Template for ARM GPU app containers
├── scripts/
│   ├── build_all.sh                        # First time full build
│   ├── update_lbpm.sh                      # Rebuild when LBPM source updates
│   ├── build_app.sh                        # Generate, build, and push a single app
│   └── generate_app.sh                     # Generate app def from template only
└── examples/
    ├── tacc_ls6_job.sh                     # TACC Lonestar6 job script
    └── generic_job.sh                      # Generic SLURM job script
```

---

## Toolchain

### x86 (TACC Lonestar6)

| Component | Version |
|-----------|---------|
| Base image | `nvidia/cuda:11.4.3-devel-rockylinux8` |
| GCC | 11.2 (via gcc-toolset-11) |
| OpenMPI | 5.0.3 (CUDA-aware, shared memory transport) |
| HDF5 | 1.14.3 (parallel) |
| CUDA | 11.4 |
| CUDA arch | sm_80 (A100) |

### ARM (TACC Vista)

| Component | Version |
|-----------|---------|
| Base image | `nvidia/cuda:13.1.0-devel-ubuntu24.04` |
| GCC | 13 (system default) |
| OpenMPI | 5.0.5 (shared memory transport) |
| HDF5 | 1.14.3 (parallel) |
| CUDA | 13.1 |
| CUDA arch | sm_90 (GH200) |

---

## Building from Source

### Prerequisites

The toolchain recipes pull base images from Docker Hub. If your system
does not have internet access (e.g. TACC), pull the base image manually
first and update the recipe to use `localimage`:

**x86:**
```bash
apptainer pull nvidia-cuda-11.4.3-devel-rockylinux8.sif \
    docker://nvidia/cuda:11.4.3-devel-rockylinux8
```

**ARM:**
```bash
apptainer pull nvidia-cuda-13.1.0-devel-ubuntu24.04.sif \
    docker://nvidia/cuda:13.1.0-devel-ubuntu24.04
```

Then update the corresponding `Bootstrap` and `From` lines in the toolchain recipe:
```apptainer
Bootstrap: localimage
From: nvidia-cuda-11.4.3-devel-rockylinux8.sif
```

### Full Build (First Time)

Builds and pushes the entire stack — toolchain, builder, and all
application containers:

```bash
git clone https://github.com/bchang19/lbpm-containers
cd lbpm-containers

# x86 on TACC Lonestar6
./scripts/build_all.sh v1.0 x86_cuda11

# ARM on TACC Vista
./scripts/build_all.sh v1.0 arm_cuda13
```

### Update LBPM Only

When LBPM source code updates, rebuild just the builder and application
containers without rebuilding the toolchain:

```bash
./scripts/update_lbpm.sh v2.0 x86_cuda11
./scripts/update_lbpm.sh v2.0 arm_cuda13
```

### Add a New Simulator

To generate, build, and push a container for any other LBPM executable
in one command:

```bash
./scripts/build_app.sh <app_name> <executable> "<description>" <version> <target>

# Example:
./scripts/build_app.sh greyscale lbpm_greyscale_simulator \
    "LBPM Greyscale Simulator" v1.0 x86_cuda11
```

If you only want to generate the recipe without building:

```bash
./scripts/generate_app.sh <app_name> <executable> "<description>"
```

Then build and push manually:

```bash
apptainer build recipes/apps/lbpm_greyscale_x86_cuda11.sif \
    recipes/apps/lbpm_greyscale_x86_cuda11.def

apptainer push recipes/apps/lbpm_greyscale_x86_cuda11.sif \
    oras://docker.io/bchang19/lbpm:greyscale-x86-cuda11-latest
```

---

## Supported Targets

| Target | Architecture | CUDA | OS | Status |
|--------|-------------|------|----|--------|
| `x86_cuda11` | x86_64 | 11.4 | Rocky Linux 8 | ✅ Available |
| `arm_cuda13` | aarch64 | 13.1 | Ubuntu 24.04 | ✅ Available |
| `x86_cuda12` | x86_64 | 12.x | Rocky Linux 8 | 🔜 Planned |
| `x86_cpu` | x86_64 | — | Rocky Linux 8 | 🔜 Planned |

To build for a new target, add the corresponding toolchain and builder
recipes and run:

```bash
./scripts/build_all.sh v1.0 <target>
```

---

## Interactive Use

All LBPM executables are available inside every container:

```bash
# List all available executables
apptainer exec --nv lbpm_mrt.sif ls /opt/lbpm-build/bin/

# Run a different executable interactively
apptainer exec --nv lbpm_mrt.sif lbpm_color_simulator input.db
```

---

## License

Container recipes are MIT licensed. LBPM itself is licensed under the
[LGPL-3.0 license](https://github.com/OPM/LBPM/blob/master/LICENSE).