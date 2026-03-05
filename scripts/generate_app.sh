#!/bin/bash
# Usage: ./scripts/generate_app.sh <app_name> <executable> <description> <template> <target>

APP_NAME=$1
EXECUTABLE=$2
DESCRIPTION=$3
TEMPLATE=${4:-recipes/template/lbpm_app_template_gpu.def}
TARGET=${5:-x86_cuda11}

OUTPUT=recipes/apps/lbpm_${APP_NAME}_${TARGET}.def

if [ -z "$APP_NAME" ] || [ -z "$EXECUTABLE" ] || [ -z "$DESCRIPTION" ]; then
    echo "Usage: ./scripts/generate_app.sh <app_name> <executable> <description> [template] [target]"
    exit 1
fi

if [ -f "$OUTPUT" ]; then
    echo "Warning: $OUTPUT already exists. Overwrite? (y/n)"
    read -r answer
    if [ "$answer" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
fi

sed \
    -e "s/__APP_DESCRIPTION__/$DESCRIPTION/g" \
    -e "s/__APP_EXECUTABLE__/$EXECUTABLE/g" \
    -e "s/__APP_IMAGE__/lbpm_${APP_NAME}_${TARGET}/g" \
    -e "s/__TARGET__/$TARGET/g" \
    $TEMPLATE > $OUTPUT

echo "Generated $OUTPUT"
