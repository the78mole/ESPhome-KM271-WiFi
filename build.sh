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
docker run --rm -v "$(pwd)":/config -v "$(pwd)/.esphome":/config/.esphome ghcr.io/esphome/esphome:$ESPHOME_VERSION compile /config/$CONFIG_FILE

# Extract device name for binary location
DEVICE_NAME=$(grep -A 5 "substitutions:" $CONFIG_FILE | grep "name:" | head -1 | sed 's/.*name: *"\([^"]*\)".*/\1/')

# Find the binary files
BINARY_DIR=".esphome/build/$DEVICE_NAME/.pioenvs"
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
    echo "  esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 write_flash 0x0 ./firmware-$DEVICE_NAME-factory.bin"
    echo "  # or for OTA update:"
    echo "  esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 write_flash 0x10000 ./firmware-$DEVICE_NAME-ota.bin"
else
    echo "3. ERROR: Firmware compilation failed!"
    echo "   Expected binary not found at: $BINARY_PATH"
    echo "   Device name: $DEVICE_NAME"
    echo "   Binary directory: $BINARY_DIR"
    echo "   Available files:"
    find .esphome/build -name "*.bin" -type f 2>/dev/null || echo "   No .bin files found"
    exit 1
fi
