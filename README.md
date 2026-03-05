# LBPM Container Recipes

Apptainer/Singularity container recipes for
[LBPM](https://github.com/OPM/LBPM) — a lattice Boltzmann simulation
framework for flow and transport in porous media.

Pre-built containers are available on
[Docker Hub](https://hub.docker.com/r/bchang19/lbpm).

---

## Quick Start

```bash
# Pull the container
apptainer pull lbpm_mrt_permeability.sif \
    oras://docker.io/bchang19/lbpm:mrt-x86-cuda11-latest

# Run with 1 GPU (default)
apptainer run --nv lbpm_mrt_permeability.sif /path/to/input.db

# Run with 3 GPUs
apptainer run --nv lbpm_mrt_permeability.sif /path/to/input.db 3
```

---

## Available Images

| Tag | Description |
|-----|-------------|
| `mrt-x86-cuda11-latest` | Single-phase MRT Permeability simulator |
| `morphdrain-x86-cuda11-latest` | Morphological drain post-processor |
| `color-x86-cuda11-latest` | Multi-phase Color simulator |
| `builder-x86-cuda11-latest` | Full LBPM build with all executables |
| `toolchain-x86-cuda11-latest` | GCC11 + OpenMPI5 + HDF5 1.14.3 + CUDA11 |

All images are also available with version tags (e.g. `mrt-x86-cuda11-v1.0`).
To inspect the exact LBPM commit built into an image:

```bash
apptainer inspect lbpm_mrt_permeability.sif | grep LBPM
```

---

## Requirements

- Apptainer/Singularity
- NVIDIA GPU with CUDA 11.4+ driver
- Single node only (up to 3 GPUs)

> **Note:** These containers are limited to single-node execution. For
> multi-node jobs, please compile LBPM manually against your cluster's
> MPI implementation. See the
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
│   │   └── lbpm_toolchain_x86_cuda11.def   # GCC11 + OpenMPI5 + HDF5 + CUDA11
│   ├── builder/
│   │   └── lbpm_builder_x86_cuda11.def     # Compiles LBPM from source
│   └── template/
│       └── lbpm_app_template_gpu.def       # Template for GPU app containers
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

| Component | Version |
|-----------|---------|
| Base image | `nvidia/cuda:11.4.3-devel-rockylinux8` |
| GCC | 11.2 (via gcc-toolset-11) |
| OpenMPI | 5.0.3 (CUDA-aware, shared memory transport) |
| HDF5 | 1.14.3 (parallel) |
| CUDA | 11.4 |

---

## Building from Source

### Prerequisites

The toolchain recipe pulls the NVIDIA CUDA base image from Docker Hub.
If your system does not have internet access (e.g. TACC Lonestar6),
pull the base image manually first:

```bash
apptainer pull nvidia-cuda-11.4.3-devel-rockylinux8.sif \
    docker://nvidia/cuda:11.4.3-devel-rockylinux8
```

Then update `recipes/base/lbpm_toolchain_x86_cuda11.def` to use the
local image:

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

./scripts/build_all.sh v1.0 x86_cuda11
```

### Update LBPM Only

When LBPM source code updates, rebuild just the builder and application
containers without rebuilding the toolchain:

```bash
./scripts/update_lbpm.sh v2.0 x86_cuda11
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

# Example:
./scripts/generate_app.sh greyscale lbpm_greyscale_simulator \
    "LBPM Greyscale Simulator"
```

Then build and push manually:

```bash
apptainer build recipes/apps/lbpm_greyscale_x86_cuda11.sif \
    recipes/apps/lbpm_greyscale_x86_cuda11.def

apptainer push recipes/apps/lbpm_greyscale_x86_cuda11.sif \
    oras://docker.io/bchang19/lbpm:greyscale-x86-cuda11-latest
```

---

## Future Targets

The build system is designed to support multiple architectures and
backends. Planned future targets:

| Target | Description |
|--------|-------------|
| `x86-cuda11` | x86_64 + CUDA 11.4 (current) |
| `x86-cuda12` | x86_64 + CUDA 12.x |
| `x86-cpu` | x86_64 CPU only |
| `arm-cuda12` | ARM + CUDA 12.x |

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
apptainer exec --nv lbpm_mrt_permeability.sif ls /opt/lbpm-build/bin/

# Run a different executable interactively
apptainer exec --nv lbpm_mrt_permeability.sif lbpm_color_simulator input.db
```

---

## License

Container recipes are MIT licensed. LBPM itself is licensed under the
[LGPL-3.0 license](https://github.com/OPM/LBPM/blob/master/LICENSE).
