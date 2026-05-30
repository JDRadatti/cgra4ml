SUMMARY = "CGRA4ML Linux Kernel Driver"
DESCRIPTION = "Kernel driver for CGRA4ML DNN accelerator with DMA buffer support"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

PV = "1.0+git${SRCPV}"

# Source: Linux driver directory
SRC_URI = "${CGRA4ML_DRIVER_SRC}"

S = "${WORKDIR}"

inherit module

# Kernel module dependencies
DEPENDS += "virtual/kernel"

# Module compilation flags
EXTRA_OEMAKE = "ARCH=arm64 CROSS_COMPILE=${TARGET_PREFIX} KBUILD_OUTPUT=${STAGING_KERNEL_DIR}"

# Auto-load on boot
KERNEL_MODULE_AUTOLOAD += "cgra4ml_drv"

# Install device tree overlay
do_install:append() {
    install -d ${D}/boot/firmware/overlays
    install -m 644 ${WORKDIR}/cgra4ml.dts ${D}/boot/firmware/overlays/cgra4ml-overlay.dts
}

FILES:${PN} += "/boot/firmware"

# Don't strip kernel modules (helps with debugging)
INHIBIT_PACKAGE_STRIP_MODULES = "1"
