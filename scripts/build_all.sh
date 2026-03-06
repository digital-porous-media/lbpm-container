#!/bin/bash
# Usage: ./scripts/build_all.sh <version> <target>
# Example: ./scripts/build_all.sh v1.0 x86_cuda11
#          ./scripts/build_all.sh v1.0 x86_cpu
#          ./scripts/build_all.sh v1.0 arm_cuda13

VERSION=${1:-v1.0}
TARGET=${2:-x86-cuda11}
REGISTRY=docker.io/bchang19/lbpm

APPS=(
    "mrt:lbpm_permeability_simulator:LBPM MRT Permeability Simulator"
    "morphdrain:lbpm_morphdrain_pp:LBPM Morphological Drain Post-Processor"
    "color:lbpm_color_simulator:LBPM Color Simulator"
)

# Map target to base image filename
declare -A BASE_IMAGES
BASE_IMAGES["x86-cuda11"]="nvidia-cuda-11.4.3-devel-rockylinux8.sif"
BASE_IMAGES["arm-cuda13"]="nvidia-cuda-13.1.0-devel-ubuntu24.04.sif"

# Check base image exists for cuda targets
if [[ "$TARGET" == *"cuda"* ]]; then
    BASE_IMAGE=${BASE_IMAGES[$TARGET]}
    if [ -z "$BASE_IMAGE" ]; then
        echo "Error: No base image mapping found for target $TARGET"
        echo "Please add it to the BASE_IMAGES map in build_all.sh"
        exit 1
    fi
    if [ ! -f "$BASE_IMAGE" ]; then
        echo "Base CUDA image not found: $BASE_IMAGE"
        echo "Please pull it first:"
        echo "  apptainer pull $BASE_IMAGE docker://nvidia/cuda:..."
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
    elif [[ "$TARGET" == "arm-cuda13" ]]; then
	TEMPLATE=recipes/template/lbpm_app_template_arm-cuda13.def
    else
        TEMPLATE=recipes/template/lbpm_app_template_x86-cuda11.def
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
