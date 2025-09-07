# ESPHome KM271-WiFi

[![CI](https://github.com/the78mole/ESPhome-KM271-WiFi/actions/workflows/ci.yml/badge.svg)](https://github.com/the78mole/ESPhome-KM271-WiFi/actions/workflows/ci.yml)
[![Publish Firmware](https://github.com/the78mole/ESPhome-KM271-WiFi/actions/workflows/publish-firmware.yml/badge.svg)](https://github.com/the78mole/ESPhome-KM271-WiFi/actions/workflows/publish-firmware.yml)
[![Publish Pages](https://github.com/the78mole/ESPhome-KM271-WiFi/actions/workflows/publish-pages.yml/badge.svg)](https://github.com/the78mole/ESPhome-KM271-WiFi/actions/workflows/publish-pages.yml)
![GitHub Release](https://img.shields.io/github/v/release/the78mole/ESPhome-KM271-WiFi)

This repo is the ESPhome project page of my KM271-WiFi hardware.

The KM271-WiFi is an addon to the (oldish) Buderus oil heating control units like the Logamatic 2107.

More details can be found on my [blog](https://the78mole.de/reverse-engineering-the-buderus-km217/) or the
[project page](https://the78mole.de/projects/km271-wifi-howto/).

The hardware itself is available on [tindie](https://www.tindie.com/products/24664/).

The repo for the esphome component has a [seperate repo](https://github.com/the78mole/esphome_components).

Find the Github pages with the WebTools button here: <https://the78mole.github.io/ESPhome-KM271-WiFi/>

## Available Firmware Variants

This repository provides several firmware variants for different ESP32 configurations:

| Firmware | Framework | Flash Size | Description |
|----------|-----------|------------|-------------|
| `buderus-km271_en.yaml` | Arduino | 4MB | Standard firmware for 4MB ESP32 modules |
| `buderus-km271_en_8MB.yaml` | Arduino | 8MB | Extended firmware for 8MB ESP32 modules |
| `buderus-km271_en_espidf.yaml` | ESP-IDF | 4MB | ESP-IDF firmware for 4MB modules (more features) |
| `buderus-km271_en_espidf_8MB.yaml` | ESP-IDF | 8MB | ESP-IDF firmware for 8MB modules (maximum features) |

Each variant also has a corresponding `.factory.yaml` file used for automated builds with additional provisioning
features.

## Local Development and Building

### Prerequisites

- [Docker](https://www.docker.com/) installed on your system
- Git to clone this repository

### Building Firmware Locally

You can build and test firmware locally using Docker without installing ESPHome directly:

#### 1. Clone the Repository

```bash
git clone https://github.com/the78mole/ESPhome-KM271-WiFi.git
cd ESPhome-KM271-WiFi
```

#### 2. Validate Configuration

Before building, validate the configuration syntax:

```bash
# Test a specific configuration
docker run --rm -v "$(pwd)":/config ghcr.io/esphome/esphome:2025.8.3 config /config/buderus-km271_en_espidf_8MB.yaml

# Test all main configurations
for config in buderus-km271_en.yaml buderus-km271_en_8MB.yaml buderus-km271_en_espidf.yaml buderus-km271_en_espidf_8MB.yaml; do
  echo "Testing $config..."
  docker run --rm -v "$(pwd)":/config ghcr.io/esphome/esphome:2025.8.3 config /config/$config
done
```

#### 3. Compile Firmware

To compile firmware and generate flashable binaries:

```bash
# Compile a specific variant (example: ESP-IDF 8MB)
docker run --rm -v "$(pwd)":/config ghcr.io/esphome/esphome:2025.8.3 compile /config/buderus-km271_en_espidf_8MB.yaml

# The compiled firmware will be available in:
# .esphome/build/km271-ff-espidf-8mb/.pioenvs/esp32dev/firmware.bin
```

#### 4. Flash to Device

After compilation, you can flash the firmware to your ESP32:

```bash
# Flash via USB (adjust port as needed)
docker run --rm -v "$(pwd)":/config --device=/dev/ttyUSB0 ghcr.io/esphome/esphome:2025.8.3 upload /config/buderus-km271_en_espidf_8MB.yaml

# Alternative: Extract binary and flash with esptool
cp .esphome/build/km271-ff-espidf-8mb/.pioenvs/esp32dev/firmware.bin ./firmware-8mb.bin
# Use esptool.py or ESP32 Flash Download Tool to flash firmware-8mb.bin
```

#### 5. Monitor Serial Output

To monitor the device during development:

```bash
docker run --rm -v "$(pwd)":/config --device=/dev/ttyUSB0 ghcr.io/esphome/esphome:2025.8.3 logs /config/buderus-km271_en_espidf_8MB.yaml
```

### Quick Build Script

```bash
./build.sh buderus-km271_en_espidf_8MB.yaml
```

### Development Tips

- **Configuration Testing**: Always validate with `config` before compiling
- **Incremental Builds**: Docker containers cache build artifacts for faster subsequent builds
- **Binary Location**: Compiled binaries are in `.esphome/build/[device-name]/.pioenvs/esp32dev/firmware.bin`
- **Factory Reset**: Use `.factory.yaml` variants for initial device setup with WiFi provisioning
- **Serial Port**: Replace `/dev/ttyUSB0` with your actual serial port (Windows: `COM1`, `COM2`, etc.)

### Troubleshooting

**Permission Issues (Linux/macOS):**

```bash
# Add your user to dialout group for serial access
sudo usermod -a -G dialout $USER
# Then logout and login again
```

**Windows Serial Ports:**

```bash
# Use Windows device paths in Docker
docker run --rm -v "%cd%":/config --device=COM3 ghcr.io/esphome/esphome:2025.8.3 upload /config/firmware.yaml
```

**Build Errors:**

- Ensure Docker has enough disk space (builds can be several GB)
- Check that the configuration validates before attempting compilation
- For ESP-IDF builds, ensure adequate memory is available to Docker
