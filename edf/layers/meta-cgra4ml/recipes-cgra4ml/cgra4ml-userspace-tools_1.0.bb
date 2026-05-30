SUMMARY = "CGRA4ML Userspace Test Utilities"
DESCRIPTION = "C test programs for CGRA4ML driver verification and smoke tests"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

PV = "1.0+git${SRCPV}"

# Source: Linux test directory
SRC_URI = "file:///home/justin/Documents/GitHub/cgra4ml/linux_test"

S = "${WORKDIR}"

# Include driver headers for IOCTL definitions
CFLAGS:append = " -I/home/justin/Documents/GitHub/cgra4ml/linux_driver"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}/usr/bin
    install -m 755 ${S}/reg_test ${D}/usr/bin/
    install -m 755 ${S}/ioctl_test ${D}/usr/bin/
    install -m 755 ${S}/dma_buf_test ${D}/usr/bin/
    install -m 755 ${S}/run_smoke.sh ${D}/usr/bin/
}

FILES:${PN} = "/usr/bin"

# Don't strip binaries (helps with debugging)
INHIBIT_PACKAGE_STRIP = "1"
