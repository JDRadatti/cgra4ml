SUMMARY = "Device Tree Overlay for CGRA4ML Accelerator"
DESCRIPTION = "Device tree overlay that adds CGRA4ML DNN accelerator to ZynqMP PL region"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.GPLv2;md5=751419260aa954499df77692b04c8d24"

PV = "1.0"

SRC_URI = "file://cgra4ml-overlay.dts"

S = "${WORKDIR}"

inherit devicetree

# Compile device tree overlay
do_compile() {
    dtc -@ -I dts -O dtb -o ${S}/cgra4ml-overlay.dtbo ${WORKDIR}/cgra4ml-overlay.dts
}

do_install() {
    install -d ${D}/boot/firmware/overlays
    install -m 644 ${S}/cgra4ml-overlay.dtbo ${D}/boot/firmware/overlays/
}

FILES:${PN} = "/boot/firmware/overlays"
