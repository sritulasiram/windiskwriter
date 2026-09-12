#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="$SCRIPT_DIR/build"
OBJ_DIR="$BUILD_DIR/obj"
APP_NAME="WinDiskWriter"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== Building $APP_NAME for macOS Tahoe (x86_64) ==="

# Clean and prepare directories
rm -rf "$BUILD_DIR"
mkdir -p "$OBJ_DIR" "$MACOS_DIR" "$RESOURCES_DIR"

echo "Compiling sources in parallel..."

python3 - <<'PYEOF'
import os, sys, subprocess
from concurrent.futures import ThreadPoolExecutor

script_dir = os.path.abspath(os.getcwd())
obj_dir = os.path.join(script_dir, "build", "obj")
src_root = os.path.join(script_dir, "WinDiskWriter")

inc_dirs = [x[0] for x in os.walk(src_root)]
includes = [f"-iquote{d}" for d in inc_dirs]

sources = []
for root, dirs, files in os.walk(src_root):
    for f in files:
        if f.endswith('.m') or f.endswith('.c'):
            sources.append(os.path.join(root, f))

print(f"Found {len(sources)} source files to compile.")

def compile_file(src):
    base = os.path.basename(src)
    rel = os.path.relpath(src, script_dir)
    h = abs(hash(rel)) % 1000000
    obj = os.path.join(obj_dir, f"{base}_{h}.o")
    
    is_objc = src.endswith('.m')
    flags = ['-fobjc-arc'] if is_objc else []
    
    cmd = ['clang', '-O2', '-g'] + flags + ['-c', src, '-o', obj] + includes
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error compiling {src}:\n{res.stderr}", file=sys.stderr)
        return False
    return True

with ThreadPoolExecutor() as executor:
    results = list(executor.map(compile_file, sources))

if not all(results):
    print("Compilation failed!", file=sys.stderr)
    sys.exit(1)

print("All sources compiled successfully.")
PYEOF

echo "Linking $APP_NAME binary..."

OBJS=()
while IFS= read -r obj; do
    OBJS+=("$obj")
done < <(find "$OBJ_DIR" -name "*.o")

clang -O2 -g \
    -framework Cocoa \
    -framework IOKit \
    -framework DiskArbitration \
    -framework Security \
    -framework QuartzCore \
    -liconv \
    -lxml2 \
    "${OBJS[@]}" \
    -o "$MACOS_DIR/$APP_NAME"

echo "Assembling $APP_BUNDLE..."

# Copy Info.plist
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>WinDiskWriter</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.techunrestricted.windiskwriter</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>WinDiskWriter</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.3</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>MacOSX</string>
	</array>
	<key>CFBundleVersion</key>
	<string>2</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.utilities</string>
	<key>LSMinimumSystemVersion</key>
	<string>10.13</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2023-2026 TechUnRestricted. All rights reserved.</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
EOF

# Copy Resources
if [ -f "$SCRIPT_DIR/WinDiskWriter/Resources/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/WinDiskWriter/Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

if [ -f "$SCRIPT_DIR/WinDiskWriter/Resources/Assets.car" ]; then
    cp "$SCRIPT_DIR/WinDiskWriter/Resources/Assets.car" "$RESOURCES_DIR/"
fi

# Copy localized strings
mkdir -p "$RESOURCES_DIR/en.lproj" "$RESOURCES_DIR/ru.lproj"
if [ -f "$SCRIPT_DIR/WinDiskWriter/LocalizedStrings/en.lproj/Localizable.strings" ]; then
    cp "$SCRIPT_DIR/WinDiskWriter/LocalizedStrings/en.lproj/Localizable.strings" "$RESOURCES_DIR/en.lproj/"
fi

if [ -f "$SCRIPT_DIR/WinDiskWriter/LocalizedStrings/ru.lproj/Localizable.strings" ]; then
    cp "$SCRIPT_DIR/WinDiskWriter/LocalizedStrings/ru.lproj/Localizable.strings" "$RESOURCES_DIR/ru.lproj/"
fi

echo "Signing application with ad-hoc identity..."
codesign -s - --force --deep "$APP_BUNDLE"

if [ -f "$SCRIPT_DIR/compile_commands.json" ]; then
    cp "$SCRIPT_DIR/compile_commands.json" "$BUILD_DIR/"
fi

echo "=== Build Successful! ==="
echo "Application bundle created at: $APP_BUNDLE"
