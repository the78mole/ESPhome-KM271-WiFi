#!/bin/bash
set -e

ESPHOME_VERSION="2025.8.3"
CONFIG_FILE="${1:-buderus-km271_en_espidf_8MB.yaml}"

echo "Building ESPHome firmware for $CONFIG_FILE..."

# Validate configuration
echo "1. Validating configuration..."
docker run --rm -v "$(pwd)":/config ghcr.io/esphome/esphome:$ESPHOME_VERSION config /config/$CONFIG_FILE

# Compile firmware
echo "2. Compiling firmware..."
CONTAINER_ID=$(docker run -d --rm -v "$(pwd)":/config ghcr.io/esphome/esphome:$ESPHOME_VERSION compile /config/$CONFIG_FILE)

# Wait for compilation to complete
docker wait $CONTAINER_ID

# Extract device name for binary location
DEVICE_NAME=$(grep -A 10 "substitutions:" $CONFIG_FILE | grep "name:" | sed 's/.*name: *"\([^"]*\)".*/\1/')

# Copy binaries from the container's build directory to host
echo "3. Extracting binaries from container..."
TEMP_DIR=$(mktemp -d)

# Copy the entire .esphome build directory from the container
docker cp $CONTAINER_ID:/config/.esphome/build/$DEVICE_NAME $TEMP_DIR/

# Find the binary files in the extracted directory
BINARY_DIR="$TEMP_DIR/$DEVICE_NAME/.pioenvs"
BINARY_PATH=""
FACTORY_BINARY=""
OTA_BINARY=""

# Find the pioenvs subdirectory and firmware.bin
if [ -d "$BINARY_DIR" ]; then
    PIOENV_DIR=$(find "$BINARY_DIR" -name "firmware.bin" -type f | head -1 | xargs dirname)
    if [ -n "$PIOENV_DIR" ]; then
        BINARY_PATH="$PIOENV_DIR/firmware.bin"
        FACTORY_BINARY="$PIOENV_DIR/firmware.factory.bin"
        OTA_BINARY="$PIOENV_DIR/firmware.ota.bin"
    fi
fi

if [ -f "$BINARY_PATH" ]; then
    echo "3. Firmware compiled successfully!"
    echo "   Main binary: $BINARY_PATH"
    echo "   File size: $(du -h "$BINARY_PATH" | cut -f1)"
    
    # Copy main binary
    cp "$BINARY_PATH" "./firmware-$DEVICE_NAME.bin"
    echo "   Copied main binary to: ./firmware-$DEVICE_NAME.bin"
    
    # Copy factory binary if it exists (ESP-IDF)
    if [ -f "$FACTORY_BINARY" ]; then
        cp "$FACTORY_BINARY" "./firmware-$DEVICE_NAME-factory.bin"
        echo "   Copied factory binary to: ./firmware-$DEVICE_NAME-factory.bin"
        echo "   Factory size: $(du -h "$FACTORY_BINARY" | cut -f1)"
    fi
    
    # Copy OTA binary if it exists
    if [ -f "$OTA_BINARY" ]; then
        cp "$OTA_BINARY" "./firmware-$DEVICE_NAME-ota.bin"
        echo "   Copied OTA binary to: ./firmware-$DEVICE_NAME-ota.bin" 
        echo "   OTA size: $(du -h "$OTA_BINARY" | cut -f1)"
    fi
    
    echo ""
    echo "To flash the firmware:"
    echo "  docker run --rm -v \"\$(pwd)\":/config --device=/dev/ttyUSB0 ghcr.io/esphome/esphome:$ESPHOME_VERSION upload /config/$CONFIG_FILE"
    echo ""
    echo "To monitor logs:"
    echo "  docker run --rm -v \"\$(pwd)\":/config --device=/dev/ttyUSB0 ghcr.io/esphome/esphome:$ESPHOME_VERSION logs /config/$CONFIG_FILE"
else
    echo "3. ERROR: Firmware compilation failed!"
    exit 1
fi
