#!/bin/sh
# Builds the apps for anyone to install, with no server address or Google client
# built in: people type their own server's address in the app.
#   apple/scripts/build_release.sh
# Makes apple/build/release/Pongo.ipa (iPhone, for SideStore or AltStore, which sign
# it with the installer's own Apple ID) and Pongo-Mac.zip (signed with your team from
# Pongo.local.xcconfig, not notarized). Upload both to a GitHub release.
set -e
cd "$(dirname "$0")/.."
out=build/release
derived=build/release-derived
rm -rf "$out" "$derived"
mkdir -p "$out"

# The empty settings override Pongo.local.xcconfig, so your own server stays out
blank="PONGO_SERVER_URL= PONGO_LOCAL_SERVER_URL= GOOGLE_CLIENT_ID="
bundle=$(sed -n 's/^PONGO_BUNDLE_ID *= *//p' Config/Pongo.xcconfig | tail -n 1)

echo "Building the iPhone app"
# shellcheck disable=SC2086
xcodebuild -project Pongo.xcodeproj -scheme Pongo -configuration Release \
    -destination 'generic/platform=iOS' -derivedDataPath "$derived" \
    CODE_SIGNING_ALLOWED=NO PONGO_BUNDLE_ID="$bundle" $blank -quiet build
app="$derived/Build/Products/Release-iphoneos/Pongo.app"
# Signed without a certificate, but with the app group, which the sideloading
# app keeps when it signs the app again for the installer
entitlements="$derived/ios.entitlements"
sed "s/\$(PONGO_BUNDLE_ID)/$bundle/" Config/Pongo.entitlements > "$entitlements"
for appex in "$app"/PlugIns/*.appex; do
    [ -e "$appex" ] && codesign -f -s - --entitlements "$entitlements" "$appex"
done
codesign -f -s - --entitlements "$entitlements" "$app"
mkdir -p "$derived/ipa/Payload"
cp -R "$app" "$derived/ipa/Payload/"
(cd "$derived/ipa" && zip -qry ../../release/Pongo.ipa Payload)

echo "Building the Mac app"
# shellcheck disable=SC2086
xcodebuild -project Pongo.xcodeproj -scheme "Pongo Mac" -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$derived" \
    -allowProvisioningUpdates PONGO_BUNDLE_ID="$bundle" $blank -quiet build
ditto -c -k --keepParent "$derived/Build/Products/Release/Pongo.app" "$out/Pongo-Mac.zip"

rm -rf "$derived"
ls -lh "$out"
