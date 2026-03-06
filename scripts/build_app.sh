#!/bin/bash
# Usage: ./scripts/build_app.sh <app_name> <executable> <description> <version> <target>

APP_NAME=$1
EXECUTABLE=$2
DESCRIPTION=$3
VERSION=${4:-latest}
TARGET=${5:-x86_cuda11}

./scripts/generate_app.sh $APP_NAME $EXECUTABLE "$DESCRIPTION" \
    recipes/template/lbpm_app_template_arm-cuda13.def $TARGET

apptainer build recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
    recipes/apps/lbpm_${APP_NAME}_${TARGET}.def

apptainer push recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
    oras://docker.io/bchang19/lbpm:${APP_NAME}-${TARGET}-$VERSION
apptainer push recipes/apps/lbpm_${APP_NAME}_${TARGET}.sif \
    oras://docker.io/bchang19/lbpm:${APP_NAME}-${TARGET}-latest
