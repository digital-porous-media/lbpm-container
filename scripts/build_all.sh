#!/bin/bash
# Usage: ./scripts/build_all.sh <version> <target>
# Example: ./scripts/build_all.sh v1.0 x86_cuda11
#          ./scripts/build_all.sh v1.0 x86_cpu
#          ./scripts/build_all.sh v1.0 arm_cuda12

VERSION=${1:-v1.0}
TARGET=${2:-x86_cuda11}
REGISTRY=docker.io/bchang19/lbpm

APPS=(
    "permeability:lbpm_permeability_simulator:LBPM Permeability Simulator"
    "morphdrain:lbpm_morphdrain_pp:LBPM Morphological Drain Post-Processor"
    "color:lbpm_color_simulator:LBPM Color Simulator"
)

# Check base image exists for localimage targets
if [[ "$TARGET" == *"cuda"* ]]; then
    CUDA_VERSION=$(echo $TARGET | grep -o 'cuda[0-9]*')
    if [ ! -f "nvidia-${CUDA_VERSION}-devel-rockylinux8.sif" ]; then
        echo "Base CUDA image not found!"
        echo "Please run first:"
        echo "  apptainer pull nvidia-${CUDA_VERSION}-devel-rockylinux8.sif docker://nvidia/cuda:11.4.3-devel-rockylinux8"
        exit 1
    fi
fi

echo "========================================"
echo "Building LBPM containers"
echo "Version: $VERSION"
echo "Target:  $TARGET"
echo "========================================"

# Build toolchain
echo "Building toolchain..."
apptainer build recipes/base/lbpm_toolchain_${TARGET}.sif \
    recipes/base/lbpm_toolchain_${TARGET}.def
apptainer push recipes/base/lbpm_toolchain_${TARGET}.sif \
    oras://$REGISTRY:toolchain-${TARGET}-$VERSION
apptainer push recipes/base/lbpm_toolchain_${TARGET}.sif \
    oras://$REGISTRY:toolchain-${TARGET}-latest

# Build builder
echo "Building builder..."
apptainer build recipes/builder/lbpm_builder_${TARGET}.sif \
    recipes/builder/lbpm_builder_${TARGET}.def
apptainer push recipes/builder/lbpm_builder_${TARGET}.sif \
    oras://$REGISTRY:builder-${TARGET}-$VERSION
apptainer push recipes/builder/lbpm_builder_${TARGET}.sif \
    oras://$REGISTRY:builder-${TARGET}-latest

# Build app containers
for app_info in "${APPS[@]}"; do
    APP_NAME=$(echo $app_info | cut -d: -f1)
    EXECUTABLE=$(echo $app_info | cut -d: -f2)
    DESCRIPTION=$(echo $app_info | cut -d: -f3)

    echo "Building $APP_NAME container..."

    # Determine which template to use
    if [[ "$TARGET" == *"cpu"* ]]; then
        TEMPLATE=recipes/template/lbpm_app_template_cpu.def
    else
        TEMPLATE=recipes/template/lbpm_app_template_gpu.def
    fi

    # Generate def file from template
    ./scripts/generate_app.sh $APP_NAME $EXECUTABLE "$DESCRIPTION" $TEMPLATE $TARGET

    apptainer build recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
        recipes/apps/lbpm_${APP_NAME}_${TARGET}.def
    apptainer push recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
        oras://$REGISTRY:${APP_NAME}-${TARGET}-$VERSION
    apptainer push recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
        oras://$REGISTRY:${APP_NAME}-${TARGET}-latest
done

echo "========================================"
echo "Build complete!"
echo "Target: $TARGET"
echo "Version: $VERSION"
echo "========================================"
