#!/bin/bash
# CGRA4ML EDF Build Setup Script
#
# This script sets up the complete Yocto build environment for CGRA4ML.
# Run this once to clone all required layers and configure the build.
#
# Usage:
#   ./setup-edf.sh
#
# Requirements:
#   - Ubuntu 22.04 LTS
#   - ~100GB free disk space
#   - git, vim, and basic build tools

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EDF_DIR="${SCRIPT_DIR}"
LAYERS_DIR="${EDF_DIR}/layers"

echo "=========================================="
echo "CGRA4ML EDF Setup"
echo "=========================================="
echo ""

# Check disk space
echo "[1/6] Checking disk space..."
AVAILABLE_SPACE=$(df -P "${EDF_DIR}" | awk 'NR==2 {print $4}')
REQUIRED_SPACE=104857600  # 100GB in KB

if [ "${AVAILABLE_SPACE}" -lt "${REQUIRED_SPACE}" ]; then
    echo "ERROR: Insufficient disk space!"
    echo "  Available: $((AVAILABLE_SPACE / 1024 / 1024)) GB"
    echo "  Required:  100 GB"
    exit 1
fi
echo "  ✓ Disk space OK ($((AVAILABLE_SPACE / 1024 / 1024)) GB available)"
echo ""

# Clone Yocto Project layers
echo "[2/6] Cloning Yocto Project layers..."
cd "${EDF_DIR}"

if [ ! -d "poky" ]; then
    echo "  Cloning poky (Yocto Project)..."
    git clone -b scarthgap --depth 1 https://git.yoctoproject.org/poky.git
else
    echo "  ✓ poky already exists"
fi

if [ ! -d "meta-openembedded" ]; then
    echo "  Cloning meta-openembedded..."
    git clone -b scarthgap --depth 1 https://git.openembedded.org/meta-openembedded
else
    echo "  ✓ meta-openembedded already exists"
fi

if [ ! -d "meta-arm" ]; then
    echo "  Cloning meta-arm..."
    git clone -b main --depth 1 https://git.yoctoproject.org/meta-arm
else
    echo "  ✓ meta-arm already exists"
fi
echo ""

# Clone AMD Xilinx layers
echo "[3/6] Cloning AMD Xilinx layers..."

if [ ! -d "meta-xilinx" ]; then
    echo "  Cloning meta-xilinx..."
    git clone -b scarthgap-next --depth 1 https://github.com/Xilinx/meta-xilinx.git
else
    echo "  ✓ meta-xilinx already exists"
fi

if [ ! -d "meta-xilinx-tools" ]; then
    echo "  Cloning meta-xilinx-tools..."
    git clone -b scarthgap-next --depth 1 https://github.com/Xilinx/meta-xilinx-tools.git
else
    echo "  ✓ meta-xilinx-tools already exists"
fi

if [ ! -d "meta-amd-edf" ]; then
    echo "  Cloning meta-amd-edf..."
    git clone -b scarthgap-next --depth 1 https://github.com/Xilinx/meta-amd-edf.git
else
    echo "  ✓ meta-amd-edf already exists"
fi
echo ""

# Create build directory structure
echo "[4/6] Creating build directory structure..."
mkdir -p "${EDF_DIR}/build"
mkdir -p "${EDF_DIR}/downloads"
mkdir -p "${EDF_DIR}/sstate-cache"
echo "  ✓ Directory structure created"
echo ""

# Initialize build environment
echo "[5/6] Initializing build configuration..."
cd "${EDF_DIR}/build"

if [ ! -f "conf/bblayers.conf" ]; then
    # Source environment to create initial config
    source "${EDF_DIR}/poky/oe-init-build-env" "${EDF_DIR}/build"
    
    # Add meta-cgra4ml layer
    echo "  Adding meta-cgra4ml layer..."
    bblayers add-layer "${LAYERS_DIR}/meta-cgra4ml"
else
    echo "  ✓ Build configuration already exists"
fi
echo ""

# Configure local.conf
echo "[6/6] Configuring local.conf..."
LOCAL_CONF="${EDF_DIR}/build/conf/local.conf"

if ! grep -q "MACHINE = \"zcu104-cgra4ml\"" "${LOCAL_CONF}" 2>/dev/null; then
    cat >> "${LOCAL_CONF}" << 'EOF'

# CGRA4ML Configuration
MACHINE = "zcu104-cgra4ml"
DISTRO = "cgra4ml-minimal"
DL_DIR ?= "/home/justin/Documents/GitHub/cgra4ml/edf/downloads"
SSTATE_DIR ?= "/home/justin/Documents/GitHub/cgra4ml/edf/sstate-cache"

# Accept Xilinx licenses
XILINX_ACCEPT_EULA = "1"
LICENSE_FLAGS_ACCEPTED = "commercial"

# Build optimization
PARALLEL_MAKE = "-j$(nproc)"
BB_NUMBER_THREADS = "$(nproc)"

# Headless build
EXTRA_IMAGE_FEATURES = "debug-tweaks"
USER_CLASSES = "buildstats buildhistory"

# Cleanup work directories
INHERIT += "rm_work"

# Serial console
SERIAL_CONSOLES = "115200;ttyPS0"

# Enable SDT workflow
XILINX_WITH_ESW = "sdt"
EOF
    echo "  ✓ local.conf configured"
else
    echo "  ✓ local.conf already configured"
fi
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Copy XSA file to edf/sources/cgra4ml-hw/"
echo "     cp run/work/dsf_zcu104/design_1_wrapper.xsa edf/sources/cgra4ml-hw/"
echo ""
echo "  2. Build the image:"
echo "     cd edf/build"
echo "     source poky/oe-init-build-env build"
echo "     bitbake cgra4ml-minimal-image"
echo ""
echo "  3. Flash SD card:"
echo "     sudo bmaptool copy tmp/deploy/images/zcu104-cgra4ml/*.wic.wic /dev/sdX"
echo ""
echo "Build time: 4-8 hours (first build), 30-60 min (subsequent)"
echo "Disk usage: ~80-100 GB"
echo ""
