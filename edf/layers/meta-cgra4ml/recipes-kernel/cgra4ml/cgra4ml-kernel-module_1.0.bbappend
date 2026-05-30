# CGRA4ML Kernel Module
# This recipe builds the CGRA4ML Linux kernel driver

# The driver source is located in the main project directory
# SRC_URI points to: /home/justin/Documents/GitHub/cgra4ml/linux_driver

# Key files:
# - cgra4ml_main.c    : Driver entry point, file_operations, IOCTL handlers
# - cgra4ml_hw.c      : Hardware register access, reset, start, status
# - cgra4ml_dma.c     : DMA buffer allocation and mmap
# - cgra4ml_ioctl.h   : IOCTL interface (shared with userspace)
# - cgra4ml_regs.h    : Register map definitions
# - cgra4ml_priv.h    : Internal driver structures
# - cgra4ml.dts       : Device tree overlay

# The module provides:
# - /dev/cgra4ml character device
# - IOCTL interface for register access and buffer info
# - DMA-coherent memory buffers (weights, input, output, OCM0, OCM1)
# - mmap support for zero-copy buffer access

# Auto-loaded on boot via KERNEL_MODULE_AUTOLOAD
