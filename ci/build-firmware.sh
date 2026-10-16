#!/usr/bin/env bash
set -euo pipefail
source_dir="${1:?usage: build-firmware.sh UPSTREAM_DIR OUTPUT_DIR}"
output_dir="${2:?usage: build-firmware.sh UPSTREAM_DIR OUTPUT_DIR}"
source_dir=$(cd "$source_dir" && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
cd "$source_dir"

expected_revision=55234856b8cb6fc114c0ca2674cd7bd420b1654c
test "$(git -c safe.directory="$source_dir" rev-parse HEAD)" = "$expected_revision"
test -z "$(git -c safe.directory="$source_dir" status --porcelain)"
idf.py --version | grep -F 'v5.5.5'
lock_before=$(sha256sum firmware-device/dependencies.lock | cut -d ' ' -f 1)
export IDF_COMPONENT_CACHE_PATH="$source_dir/.build/component-cache"
build_dir="$source_dir/.build/device-ncm"
mkdir -p "$build_dir"
idf.py -C "$source_dir/firmware-device" -B "$build_dir" \
  -D IDF_TARGET=esp32s3 \
  -D "SDKCONFIG=$build_dir/sdkconfig" \
  -D "SDKCONFIG_DEFAULTS=$source_dir/firmware-device/sdkconfig.defaults" \
  build

test "$lock_before" = "$(sha256sum firmware-device/dependencies.lock | cut -d ' ' -f 1)"
test -z "$(git -c safe.directory="$source_dir" status --porcelain --untracked-files=no)"
python - "$build_dir" <<'PY'
import json, pathlib, sys
build = pathlib.Path(sys.argv[1])
config = set((build / 'sdkconfig').read_text().splitlines())
required = {'CONFIG_IDF_TARGET="esp32s3"', 'CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y',
            'CONFIG_TINYUSB_NET_MODE_NCM=y', 'CONFIG_TINYUSB_HID_COUNT=0',
            '# CONFIG_LWIP_IP_FORWARD is not set', '# CONFIG_LWIP_DHCPS is not set'}
assert required <= config, 'Unexpected NCM configuration: ' + repr(required - config)
description = json.loads((build / 'project_description.json').read_text())
assert not ({'esp_wifi', 'bt'} & set(description['build_components'])), 'Unexpected radio components'
print('NCM_CONFIGURATION=PASS')
PY

mkdir -p "$output_dir/bootloader" "$output_dir/partition_table"
cp "$build_dir/phoneagent_usb_device.bin" "$output_dir/"
cp "$build_dir/phoneagent_usb_device.elf" "$output_dir/"
cp "$build_dir/bootloader/bootloader.bin" "$output_dir/bootloader/"
cp "$build_dir/partition_table/partition-table.bin" "$output_dir/partition_table/"
cp "$build_dir/flasher_args.json" "$build_dir/flash_args" "$build_dir/sdkconfig" "$output_dir/"
cp "$build_dir/project_description.json" "$output_dir/"
cp firmware-device/dependencies.lock "$output_dir/"
cp LICENSE "$output_dir/UPSTREAM-LICENSE.txt"
git -c safe.directory="$source_dir" rev-parse HEAD > "$output_dir/UPSTREAM-REVISION.txt"
git -c safe.directory="$source_dir" archive --format=tar.gz --output="$output_dir/actell-source.tar.gz" HEAD
printf '%s\n' 'For verified ESP32-S3 with 16MB flash only. Back up the entire flash before writing. Use the native USB port for iPhone NCM.' > "$output_dir/INSTALL-NOTE.txt"
(cd "$output_dir" && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt)
