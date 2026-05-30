# CGRA4ML EDF Quick Reference

## Build Commands

### Initial Setup
```bash
cd /home/justin/Documents/GitHub/cgra4ml/edf
./setup-edf.sh
```

### Build Image
```bash
cd /home/justin/Documents/GitHub/cgra4ml/edf
source poky/oe-init-build-env build
bitbake cgra4ml-minimal-image
```

### Flash SD Card
```bash
# Using bmaptool (faster, recommended)
sudo bmaptool copy \
    edf/build/tmp/deploy/images/zcu104-cgra4ml/cgra4ml-minimal-image-*.wic.wic \
    /dev/sdX

# Using dd (slower, universal)
sudo dd if=edf/build/tmp/deploy/images/zcu104-cgra4ml/*.wic.wic \
         of=/dev/sdX bs=4M status=progress conv=fsync
```

## Development Workflow

### Userspace Development (Fastest)
```bash
# Cross-compile C program
aarch64-linux-gnu-gcc -O3 -o my_app my_app.c

# Copy to FPGA
scp my_app root@192.168.1.100:/root/

# Run on FPGA
ssh root@192.168.1.100 ./my_app
```

### Kernel Module Development
```bash
# Rebuild module only
cd edf/build
bitbake cgra4ml-kernel-module -c compile -f

# Copy module to FPGA
scp tmp/deploy/modules/cgra4ml_drv.ko root@192.168.1.100:/root/

# Reload on FPGA
ssh root@192.168.1.100 "rmmod cgra4ml_drv && insmod cgra4ml_drv.ko"
```

### Device Tree Changes
```bash
# Edit overlay
vim edf/layers/meta-cgra4ml/recipes-bsp/device-tree/files/cgra4ml-overlay.dts

# Rebuild device tree
cd edf/build
bitbake cgra4ml-overlay -c compile -f

# Rebuild image (includes new DTB)
bitbake cgra4ml-minimal-image

# Deploy and reboot
```

### Full Rebuild (Production)
```bash
cd edf/build
bitbake cgra4ml-minimal-image
```

## Common bitbake Commands

```bash
# Clean a recipe
bitbake <recipe> -c clean
bitbake <recipe> -c cleansstate  # More thorough clean

# Rebuild from specific task
bitbake <recipe> -c compile -f  # Force rebuild from compile
bitbake <recipe> -c install -f  # Force rebuild from install

# View recipe information
bitbake -e <recipe> | grep "^VAR="  # Show environment
bitbake -s | grep <recipe>          # Show recipe status

# Build specific task
bitbake <recipe> -c devshell        # Open dev shell
bitbake <recipe> -c menuconfig      # Kernel menuconfig
bitbake <recipe> -c configure       # Run configure only

# Generate SDK
bitbake cgra4ml-minimal-image -c populate_sdk

# List all recipes
bitbake-layers show-recipes

# List all layers
bitbake-layers show-layers
```

## Troubleshooting

### Check Build Status
```bash
cd edf/build
tail -f tmp/log/bitbake*
```

### Find Build Artifacts
```bash
# Find compiled kernel module
find edf/build/tmp/deploy -name "cgra4ml_drv.ko"

# Find image files
ls -lh edf/build/tmp/deploy/images/zcu104-cgra4ml/

# Find work directory for recipe
ls edf/build/tmp/work/*/cgra4ml-*
```

### Inspect Image Contents
```bash
# Extract rootfs tarball
cd edf/build/tmp/deploy/images/zcu104-cgra4ml/
tar -tzf cgra4ml-minimal-image-*.rootfs.tar.gz | less

# Or mount the wic image
sudo mkdir /mnt/cgra4ml
sudo mount -o loop,offset=$((512*131072)) cgra4ml-minimal-image-*.wic.wic /mnt/cgra4ml
```

### Debug Device Tree
```bash
# On FPGA, check if overlay loaded
cat /sys/firmware/devicetree/base/amba_pl/cgra4ml@b0000000/compatible

# Check kernel messages
dmesg | grep -i cgra4ml

# Verify device node
ls -l /dev/cgra4ml
```

### Network Issues
```bash
# Check network configuration
ip addr show eth0

# Test connectivity
ping 8.8.8.8

# Check SSH service
systemctl status sshd

# View SSH logs
journalctl -u sshd
```

## Performance Tips

### Speed Up Builds
```bash
# Use shared state cache
SSTATE_DIR ?= "/home/justin/cgra4ml-yocto/sstate-cache"

# Use ccache
INHERIT += "ccache"

# Build in parallel
PARALLEL_MAKE = "-j$(nproc)"
BB_NUMBER_THREADS = "$(nproc)"

# Remove work after build
INHERIT += "rm_work"
```

### Reduce Image Size
```bash
# Remove documentation
IMAGE_INSTALL:remove = "man-pages doc-pkgs"

# Use busybox instead of full utils
IMAGE_INSTALL:append = " busybox"

# Strip binaries (default enabled)
# Disable with: INHIBIT_PACKAGE_STRIP = "1"
```

## Testing on FPGA

### Smoke Tests
```bash
ssh root@192.168.1.100

# Run all smoke tests
run_smoke.sh

# Individual tests
reg_test
ioctl_test
dma_buf_test
```

### Python Interface
```bash
ssh root@192.168.1.100

# Test NumPy
python3 -c "import numpy as np; print(np.__version__)"

# Run your inference code
python3 /root/my_inference.py
```

### Monitor System
```bash
# Check CPU usage
top

# Check memory
free -h

# Check temperature (if available)
cat /sys/class/thermal/thermal_zone*/temp

# Check kernel module
lsmod | grep cgra4ml
```

## Version Control

### Track Layer Changes
```bash
cd edf/layers/meta-cgra4ml
git status
git add recipes-kernel/cgra4ml/cgra4ml-kernel-module_1.0.bb
git commit -m "Update kernel module recipe"
```

### Ignore Build Artifacts
```bash
# Already in .gitignore:
edf/build/
edf/tmp/
edf/downloads/
edf/sstate-cache/

# But keep the layer:
!edf/layers/meta-cgra4ml/
```

## Reference

- Build directory: `/home/justin/Documents/GitHub/cgra4ml/edf/build`
- Layer directory: `/home/justin/Documents/GitHub/cgra4ml/edf/layers/meta-cgra4ml`
- XSA file: `/home/justin/Documents/GitHub/cgra4ml/edf/sources/cgra4ml-hw/design_1_wrapper.xsa`
- Deploy images: `/home/justin/Documents/GitHub/cgra4ml/edf/build/tmp/deploy/images/zcu104-cgra4ml/`
