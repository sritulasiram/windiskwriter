# WinDiskWriter

<p align="center">
  <img src="https://i.postimg.cc/X3tS32rs/Artboard.jpg" alt="WinDiskWriter Banner"/>
</p>

<p align="center">
  <a href="license.md">
    <img alt="License" src="https://img.shields.io/badge/license-BSD--2--Clause-blue.svg">
  </a>
  <a href="https://github.com/TechUnRestricted/windiskwriter">
    <img alt="Original Project" src="https://img.shields.io/badge/original%20project-TechUnRestricted-orange.svg">
  </a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2010.6%2B-lightgrey.svg">
</p>

<h2 align="center">Modern Windows USB Disk Creator for macOS</h2>

WinDiskWriter creates universal bootable USB **Windows installers** supporting both **UEFI** and **Legacy BIOS** modes directly on macOS. The resulting USB drives can be used to install Windows on standard PCs, Intel Macs, or virtual machines.

<p align="center">
  <a href="https://github.com/sritulasiram/windiskwriter/releases/latest">
    <b>📥 Download Latest Release (v1.0.0)</b>
  </a>
  <br>
  <sub>
    <a href="https://github.com/sritulasiram/windiskwriter/releases/download/v1.0.0/WinDiskWriter.dmg">Download .DMG</a>
    &nbsp;•&nbsp;
    <a href="https://github.com/sritulasiram/windiskwriter/releases/download/v1.0.0/WinDiskWriter.zip">Download .ZIP</a>
  </sub>
</p>

---

## Table of Contents
- [Features](#features)
- [Compatibility](#compatibility)
  - [💻 Supported Windows Images](#-supported-windows-images)
  - [🍏 Supported macOS Versions](#-supported-macos-versions)
- [Building from Source](#building-from-source)
- [Planned Changes](#planned-changes)
- [Additional Information](#additional-information)
- [Acknowledgements \& Credits](#acknowledgements--credits)
- [Licenses](#licenses)

---

## Features

- 📀 **Create Bootable USB Windows Installers**  
  Automatically formats the target USB disk and prepares the bootloader files tailored for the selected Windows image type.

- 📊 **Dual Real-time Progress Monitoring**  
  Features distinct visual progress bars for both **Current Operation** and **Total Progress**, complete with live byte readouts (e.g. `1.42 GB / 2.00 GB`), percentage displays, and animated formatting indicators.

- 🗂 **Automatic Windows WIM Splitting**  
  Modern Windows 10/11 ISOs contain an `install.wim` larger than 4GB. Because FAT32 only supports files up to 4GB, WinDiskWriter seamlessly splits large WIM files into multi-part `.swm` slices using `wimlib-imagex`.

- 🛠 **Bypass Windows 11 Hardware Restrictions**  
  Easily bypass Microsoft's TPM 2.0, Secure Boot, and minimum RAM checks on Windows 11 installers with a single click.

- 🪟 **Streamlined Native macOS Interface**  
  A modern, uncluttered design following macOS Human Interface Guidelines.
  - **Collapsible Diagnostic Logs**: Raw terminal logs are hidden by default in a compact, sleek window (`340x390`), accessible on demand via the **`Show Log ▾`** button or **Window → Show Log (`⌘L`)**.
  - **Smart Auto-Expansion**: The log view automatically animates open downwards if a warning or write error occurs, giving immediate troubleshooting details.

- 👾 **Legacy BIOS & EFI Support**  
  Create universal USB drives supporting both **UEFI** and **Legacy BIOS** boot modes (via optional `grub4dos` boot sector). Automatically adds EFI bootloader support for older Windows Vista and 7 images.

- 🛡 **Robust Disk Operations**  
  Features pre-emptive forced unmounting and automatic retries to prevent common macOS `diskutil` busy errors (`error -69888: Couldn't unmount disk`).

---

## Compatibility

### 💻 Supported Windows Images

| Version | Architecture | Boot Mode | Status |
| :--- | :---: | :---: | :---: |
| **Windows 11** | x64, ARM64 | UEFI, Legacy | Fully Supported |
| **Windows 10** | x64, x86 | UEFI, Legacy | Fully Supported |
| **Windows 8.1** | x64, x86 | UEFI, Legacy | Fully Supported |
| **Windows 8** | x64, x86 | UEFI, Legacy | Fully Supported |
| **Windows 7** | x64, x86 | UEFI, Legacy | Fully Supported |
| **Windows Vista** | x64, x86 | UEFI, Legacy | Fully Supported |

### 🍏 Supported macOS Versions

| Version | Architecture | Status |
| :--- | :---: | :---: |
| **macOS Tahoe 26.0** | x86_64, ARM64 | Fully Supported |
| **macOS Sequoia 15.0** | x86_64, ARM64 | Fully Supported |
| **macOS Sonoma 14.0** | x86_64, ARM64 | Fully Supported |
| **macOS Ventura 13.0** | x86_64, ARM64 | Fully Supported |
| **macOS Monterey 12.0** | x86_64, ARM64 | Fully Supported |
| **macOS Big Sur 11.0** | x86_64, ARM64 | Fully Supported |
| **macOS Catalina 10.15** | x86_64 | Fully Supported |
| **macOS Mojave 10.14** | x86_64 | Fully Supported |
| **macOS High Sierra 10.13** to **Snow Leopard 10.6** | x86_64 | Supported |

---

## Building from Source

### Prerequisites
- macOS with Xcode Command Line Tools installed (`xcode-select --install`).
- Clang compiler with Apple macOS SDK.

### Fast Command-Line Build
A standalone build script is included to compile all sources in parallel and assemble the application bundle:

```bash
# Clone the repository
git clone https://github.com/sritulasiram/windiskwriter.git
cd windiskwriter

# Build and sign the application bundle
chmod +x build_app.sh
./build_app.sh

# Launch the newly built app
open build/WinDiskWriter.app
```

### Xcode Build
You can also open `windiskwriter.xcodeproj` in Xcode and select **Product → Build** (`⌘B`) or **Product → Run** (`⌘R`).

---

## Planned Changes

- 📁 **Select Individual Partitions**: Option to target specific USB partitions instead of entire disks.
- 🗜 **Support for `.esd` Images**: Native decompression/splitting of ESD images.
- 📝 **Automated `ei.cfg` Injection**: Select edition directly without relying on UEFI ACPI SLIC tables.
- 🌐 **Automated Local Account (`BypassNRO`)**: Pre-configure Windows 11 22H2+ to bypass mandatory Microsoft Account login.

---

## Additional Information

- **Objective-C & Cocoa**: Written in native Objective-C with custom AppKit layout logic to achieve broad backward and forward compatibility across macOS generations.
- **wimlib**: Integrates [wimlib](https://wimlib.net/) for high-performance WIM image manipulation, file extraction, and multi-part slice generation.
- **grub4dos**: Optionally downloads and applies `grub4dos` bootloader code for legacy PC firmware.

---

## Acknowledgements & Credits

This project is an enhanced and modernized fork based on the original work by **TechUnRestricted**:

- **Original Author & Project Creator**: [@TechUnRestricted](https://github.com/TechUnRestricted) — Created the original [WinDiskWriter](https://github.com/TechUnRestricted/windiskwriter) software.
- **Key Enhancements in this Fork**:
  - **Full macOS Sonoma (14.0+), Sequoia (15.0+), and Tahoe (26.0+) Compatibility**: Resolved `-[NSCell _visualProviderIfExists]` AppKit crashes on modern macOS versions using custom `MiddleAlignedCell`.
  - **Dual Real-time Progress Monitoring**: Re-architected progress tracking with distinct `Current Operation` and `Total Progress` bars, live byte readouts (`X.XX GB / Y.YY GB`), percentage indicators, and formatting animations.
  - **Streamlined macOS Interface**: Cleaned up the layout by removing footer ads/nagware, and made the diagnostic log view collapsible on-demand with smooth macOS frame animations and auto-expansion on error alerts.
  - **Reliable Disk Management**: Added pre-emptive unmounting and retry logic in `DiskManagerProcessor` to eliminate disk busy errors (`-69888: Couldn't unmount disk`).
  - **Headless Build Tooling**: Added `./build_app.sh` for fast parallel command-line compilation and ad-hoc code-signing without requiring Xcode GUI.

---

## Licenses

- **WinDiskWriter**: Licensed under the [BSD 2-Clause License](license.md).
- **wimlib**: [GNU LGPL v3](libs/wimlib/License.txt).
- **grub4dos**: [GNU GPL v2](https://github.com/chenall/grub4dos).
