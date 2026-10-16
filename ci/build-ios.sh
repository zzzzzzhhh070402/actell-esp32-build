#!/usr/bin/env bash
set -euo pipefail
source_dir="${1:?usage: build-ios.sh UPSTREAM_DIR OUTPUT_DIR}"
output_dir="${2:?usage: build-ios.sh UPSTREAM_DIR OUTPUT_DIR}"
source_dir=$(cd "$source_dir" && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
cd "$source_dir"

expected_revision=55234856b8cb6fc114c0ca2674cd7bd420b1654c
test "$(git rev-parse HEAD)" = "$expected_revision"
test -z "$(git status --porcelain)"
export DEVELOPER_DIR="$(xcode-select -p)"
xcodebuild -version
xcodebuild -version | head -n 1 | grep -Eq '^Xcode 27([.]|$)'
rustup target add aarch64-apple-ios
python3 ios-app/scripts/check_localizations.py

xcodebuild \
  -project ios-app/PhoneAgent.xcodeproj \
  -scheme PhoneAgent \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/DeviceBuild \
  -clonedSourcePackagesDirPath .build/SourcePackages \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= \
  build

app_path="$source_dir/.build/DeviceBuild/Build/Products/Release-iphoneos/PhoneAgent.app"
test -d "$app_path"
test -d "$app_path/PlugIns/PhoneAgentLiveActivity.appex"
/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$app_path/Info.plist"
staging_dir=$(mktemp -d)
trap 'rm -rf "$staging_dir"' EXIT
mkdir "$staging_dir/Payload"
ditto "$app_path" "$staging_dir/Payload/PhoneAgent.app"
(cd "$staging_dir" && /usr/bin/zip -q -r -y "$output_dir/Actell-iOS27-unsigned.ipa" Payload)
cp LICENSE "$output_dir/UPSTREAM-LICENSE.txt"
git rev-parse HEAD > "$output_dir/UPSTREAM-REVISION.txt"
git archive --format=tar.gz --output="$output_dir/actell-source.tar.gz" HEAD
printf '%s\n' 'Unsigned build. Sign locally with your own Apple account; preserve the LiveActivity extension.' > "$output_dir/INSTALL-NOTE.txt"
(cd "$output_dir" && shasum -a 256 Actell-iOS27-unsigned.ipa actell-source.tar.gz UPSTREAM-LICENSE.txt UPSTREAM-REVISION.txt INSTALL-NOTE.txt > SHA256SUMS.txt)
unzip -t "$output_dir/Actell-iOS27-unsigned.ipa" | tail -n 1
