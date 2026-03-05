#!/bin/bash
# Rebuild LBPM application containers when LBPM source updates.
# Skips toolchain rebuild since GCC/OpenMPI/HDF5 rarely change.
#
# Usage: ./scripts/update_lbpm.sh <version> <target>
# Example: ./scripts/update_lbpm.sh v2.0 x86_cuda11
#          ./scripts/update_lbpm.sh v2.0 x86_cpu

VERSION=${1:-latest}
TARGET=${2:-x86_cuda11}
REGISTRY=docker.io/bchang19/lbpm

APPS=(
    "mrt:lbpm_permeability_simulator:LBPM MRT Permeability Simulator"
    "morphdrain:lbpm_morphdrain_pp:LBPM Morphological Drain Post-Processor"
    "color:lbpm_color_simulator:LBPM Color Simulator"
)

echo "========================================"
echo "Updating LBPM containers"
echo "Version: $VERSION"
echo "Target:  $TARGET"
echo "========================================"

# Rebuild builder to get latest LBPM commit
echo "Rebuilding builder with latest LBPM..."
apptainer build recipes/builder/lbpm_builder_${TARGET}.sif \
    recipes/builder/lbpm_builder_${TARGET}.def

# Get the LBPM commit that was built
LBPM_COMMIT=$(apptainer inspect recipes/builder/lbpm_builder_${TARGET}.sif \
    | grep LBPM_SHORT_COMMIT | cut -d= -f2)
echo "Built LBPM commit: $LBPM_COMMIT"

# Push updated builder
apptainer push recipes/builder/lbpm_builder_${TARGET}.sif \
    oras://$REGISTRY:builder-${TARGET}-$VERSION
apptainer push recipes/builder/lbpm_builder_${TARGET}.sif \
    oras://$REGISTRY:builder-${TARGET}-latest

# Rebuild and push application containers
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

    # Regenerate def file from template
    ./scripts/generate_app.sh $APP_NAME $EXECUTABLE "$DESCRIPTION" $TEMPLATE $TARGET

    apptainer build recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
        recipes/apps/lbpm_${APP_NAME}_${TARGET}.def

    apptainer push recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
        oras://$REGISTRY:${APP_NAME}-${TARGET}-$VERSION
    apptainer push recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
        oras://$REGISTRY:${APP_NAME}-${TARGET}-latest

    echo "$APP_NAME pushed successfully!"
done

echo "========================================"
echo "Update complete!"
echo "LBPM commit: $LBPM_COMMIT"
echo "Version tag: $VERSION"
echo "Target:      $TARGET"
echo "========================================"
