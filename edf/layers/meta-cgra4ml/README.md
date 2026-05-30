# CGRA4ML Yocto Layer (meta-cgra4ml)

This Yocto layer creates a minimal, production-ready Linux distribution for the ZCU104 FPGA board with the CGRA4ML DNN accelerator.

## Quick Start

### 1. Setup Yocto Environment

```bash
cd /home/justin/Documents/GitHub/cgra4ml/edf

# Clone required Yocto layers
git clone -b scarthgap https://git.yoctoproject.org/poky.git
git clone -b scarthgap https://git.openembedded.org/meta-openembedded
git clone -b main https://git.yoctoproject.org/meta-arm
git clone -b scarthgap-next https://github.com/Xilinx/meta-xilinx.git
git clone -b scarthgap-next https://github.com/Xilinx/meta-xilinx-tools.git
git clone -b scarthgap-next https://github.com/Xilinx/meta-amd-edf.git

# Source build environment
source poky/oe-init-build-env build
```

### 2. Configure Build

Edit `conf/bblayers.conf` to add this layer:
```bash
BBLAYERS ?= " \
    ${TOPDIR}/../poky/meta \
    ${TOPDIR}/../poky/meta-poky \
    ${TOPDIR}/../meta-openembedded/meta-oe \
    ${TOPDIR}/../meta-openembedded/meta-python \
    ${TOPDIR}/../meta-arm/meta-arm \
    ${TOPDIR}/../meta-arm/meta-arm-toolchain \
    ${TOPDIR}/../meta-xilinx \
    ${TOPDIR}/../meta-xilinx/meta-xilinx-core \
    ${TOPDIR}/../meta-xilinx/meta-xilinx-tools \
    ${TOPDIR}/../meta-xilinx/meta-xilinx-vendor \
    ${TOPDIR}/../meta-amd-edf \
    ${TOPDIR}/../layers/meta-cgra4ml \
"
```

Edit `conf/local.conf`:
```bash
MACHINE = "zcu104-cgra4ml"
DISTRO = "cgra4ml-minimal"
DL_DIR ?= "/home/justin/Documents/GitHub/cgra4ml/edf/downloads"
SSTATE_DIR ?= "/home/justin/Documents/GitHub/cgra4ml/edf/sstate-cache"
XILINX_ACCEPT_EULA = "1"
LICENSE_FLAGS_ACCEPTED = "commercial"
```

### 3. Build Image

```bash
# Build complete image (4-8 hours first time)
time bitbake cgra4ml-minimal-image

# Build will create:
# - tmp/deploy/images/zcu104-cgra4ml/BOOT.BIN
# - tmp/deploy/images/zcu104-cgra4ml/image.ub
# - tmp/deploy/images/zcu104-cgra4ml/*.wic.wic
```

### 4. Deploy to SD Card

```bash
# Flash SD card (replace /dev/sdX with your device)
sudo bmaptool copy \
    tmp/deploy/images/zcu104-cgra4ml/cgra4ml-minimal-image-*.wic.wic \
    /dev/sdX

# Or with dd:
sudo dd if=tmp/deploy/images/zcu104-cgra4ml/*.wic.wic of=/dev/sdX bs=4M status=progress
```

### 5. Boot ZCU104

1. Insert SD card into ZCU104 slot J83
2. Set boot switches SW6: `0=ON, 1=OFF, 2=ON, 3=ON` (SD card boot)
3. Connect serial console (115200 8N1, Micro-USB JTAG UART)
4. Power on the board
5. Login: `root` / `cgra4ml`

## Development Workflow

### Fast Iteration (Userspace)

```bash
# Cross-compile on host
aarch64-linux-gnu-gcc -O3 -o my_app my_app.c
scp my_app root@192.168.1.100:/root/
ssh root@192.168.1.100 ./my_app
# Iteration: 10-30 seconds
```

### Kernel Module Development

```bash
# Rebuild module only
bitbake cgra4ml-kernel-module -c compile -f
scp tmp/deploy/modules/cgra4ml_drv.ko root@fpga:/root/
ssh root@fpga "rmmod cgra4ml_drv && insmod cgra4ml_drv.ko"
# Iteration: 1-2 minutes
```

### Full Rebuild (Production Deploy)

```bash
# End-of-day or production deployment
bitbake cgra4ml-minimal-image
# Iteration: 30-60 minutes
```

## Layer Structure

```
meta-cgra4ml/
├── conf/
│   ├── layer.conf              # Layer metadata
│   ├── machine/
│   │   └── zcu104-cgra4ml.conf # Machine configuration
│   └── distro/
│       └── cgra4ml-minimal.conf # Distribution config
├── recipes-kernel/
│   └── cgra4ml/
│       ├── cgra4ml-kernel-module_1.0.bb  # Kernel driver recipe
│       └── files/
├── recipes-cgra4ml/
│   └── cgra4ml-userspace-tools_1.0.bb    # Userspace test utilities
├── recipes-bsp/
│   └── device-tree/
│       └── cgra4ml-overlay_1.0.bb        # Device tree overlay
└── recipes-core/
    └── images/
        ├── cgra4ml-minimal-image.bb      # Image recipe
        └── cgra4ml-minimal.wks           # WIC partition layout
```

## Key Components

### Kernel Module (`cgra4ml-kernel-module`)
- Provides `/dev/cgra4ml` character device
- DMA-coherent buffer allocation (weights, input, output, OCM)
- IOCTL interface for register access
- mmap support for zero-copy buffer access

### Userspace Tools (`cgra4ml-userspace-tools`)
- `reg_test`: Register read/write verification
- `ioctl_test`: Buffer info and status query
- `dma_buf_test`: DMA buffer mmap test
- `run_smoke.sh`: Automated smoke test script

### Device Tree Overlay (`cgra4ml-overlay`)
- Adds CGRA4ML device node at 0xB0000000
- Enables DMA-coherent memory access
- Loaded automatically at boot

## Testing

After booting, run smoke tests:

```bash
# Login to FPGA
ssh root@192.168.1.100

# Verify device node
ls -l /dev/cgra4ml

# Run smoke tests
run_smoke.sh

# Test Python interface
python3 -c "import numpy as np; print('NumPy:', np.__version__)"
```

## Troubleshooting

### Build fails with license error
```bash
# Accept Xilinx licenses in local.conf
echo 'XILINX_ACCEPT_EULA = "1"' >> conf/local.conf
echo 'LICENSE_FLAGS_ACCEPTED = "commercial"' >> conf/local.conf
```

### Out of disk space
```bash
# Clean work directories
bitbake -c cleanall <recipe>
rm -rf tmp/work
```

### Module doesn't load
```bash
# Check kernel messages
dmesg | grep cgra4ml

# Verify device tree overlay loaded
cat /sys/firmware/devicetree/base/amba_pl/cgra4ml@b0000000/compatible
```

## Production Deployment

Before deploying to production:

1. **Change default password:**
   ```bash
   passwd root
   ```

2. **Disable password SSH authentication:**
   Edit `/etc/ssh/sshd_config`:
   ```
   PasswordAuthentication no
   PubkeyAuthentication yes
   ```

3. **Add SSH authorized keys:**
   ```bash
   mkdir -p /root/.ssh
   echo "ssh-rsa AAAA... your-key" > /root/.ssh/authorized_keys
   chmod 700 /root/.ssh
   chmod 600 /root/.ssh/authorized_keys
   ```

4. **Enable read-only rootfs (optional):**
   Rebuild image with `IMAGE_FSTYPES:append = " squashfs"`

## Iteration Speed

| Task | Method | Time |
|------|--------|------|
| Python script | Cross-compile + SCP | 10-30 sec |
| C userspace app | Cross-compile + SCP | 30-60 sec |
| Kernel module | `bitbake module -c compile -f` | 1-2 min |
| Device tree | Rebuild + reboot | 5-10 min |
| Kernel config | Full rebuild + reboot | 15-25 min |
| Add package | Rootfs rebuild | 2-5 min |
| Full image | Production deploy | 30-60 min |

## License

This layer is released under the MIT license.

## Authors

- CGRA4ML Team
- Based on AMD EDF 2025.2 (Scarthgap)

## References

- [AMD EDF Documentation](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/3250585601/AMD+Embedded+Development+Framework+EDF)
- [Yocto Project Reference Manual](https://docs.yoctoproject.org/)
- [meta-xilinx Documentation](https://github.com/Xilinx/meta-xilinx)
