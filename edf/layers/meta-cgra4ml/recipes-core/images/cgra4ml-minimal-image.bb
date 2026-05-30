SUMMARY = "Minimal CGRA4ML Linux Image"
DESCRIPTION = "Production Linux image for ZCU104 with CGRA4ML DNN accelerator"
LICENSE = "MIT"

inherit core-image

# Minimal root filesystem
# Only include packages needed for CGRA4ML inference
IMAGE_INSTALL = " \
    packagegroup-core-boot \
    busybox \
    busybox-syslog \
    python3-core \
    python3-pip \
    python3-numpy \
    python3-pytest \
    cgra4ml-kernel-module \
    cgra4ml-userspace-tools \
    cgra4ml-overlay \
    kernel-modules \
    kernel-devicetree \
    systemd-networkd \
    systemd-resolv \
    openssh-sshd \
    openssh-sftp-server \
"

# Remove unnecessary packages to reduce image size
IMAGE_INSTALL:remove = " \
    packagegroup-core-buildessential \
    gdb \
    strace \
    perf \
"

# Security hardening
# Include shadow for password management
# Include sudo for privilege escalation (if needed)
IMAGE_INSTALL:append = " shadow sudo"

# Set default root password for development
# IMPORTANT: Change this for production deployment!
ROOTFS_POSTPROCESS_COMMAND:append = " \
    # Set development password \
    echo 'root:cgra4ml' | chpasswd ; \
    \
    # Enable SSH password authentication (development only) \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' \
        \${IMAGE_ROOTFS}/etc/ssh/sshd_config ; \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' \
        \${IMAGE_ROOTFS}/etc/ssh/sshd_config ; \
"

# Create firmware directory structure
# Used for storing bitstreams and configuration files
do_rootfs:append() {
    install -d \${IMAGE_ROOTFS}/lib/firmware/xilinx
    install -d \${IMAGE_ROOTFS}/root/cgra4ml
}

# Image format configuration
# wic.wic: SD card image with partition table
# tar.gz: Root filesystem tarball (for manual deployment)
# wic.bmap: Block map for fast flashing with bmaptool
IMAGE_FSTYPES = "wic.wic tar.gz wic.bmap"

# Boot configuration
# BOOT.BIN: First stage bootloader + PMU + ATF + U-Boot
# image.ub: Linux kernel + device tree + initramfs
IMAGE_BOOT_FILES = "BOOT.BIN image.ub"

# WIC image configuration
# Uses the kickstart file for partition layout
WKS_FILE ?= "cgra4ml-minimal.wks"

# Size optimization
# Remove development files from final image
IMAGE_INSTALL:append = " \
    rm -rf /var/cache/* \
    rm -rf /var/log/* \
    rm -rf /usr/share/doc/* \
    rm -rf /usr/share/man/* \
"

# Enable auto-login on serial console (development convenience)
ROOTFS_POSTPROCESS_COMMAND:append = " \
    # Create getty service for auto-login \
    mkdir -p \${IMAGE_ROOTFS}/etc/systemd/system/serial-getty@ttyPS0.service.d ; \
    cat > \${IMAGE_ROOTFS}/etc/systemd/system/serial-getty@ttyPS0.service.d/override.conf << 'EOF' \
[Service] \
ExecStart= \
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM \
EOF \
"
