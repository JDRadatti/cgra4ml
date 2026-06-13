# Run from run/work/ with: xsct ../../deepsocflow/tcl/fpga/vitis_run.tcl
# Requires: vitis_build.tcl to have been run first (creates ws_* directory)

set APP my_app

# pick most recent workspace
set ws_dirs [lsort [glob -nocomplain -types d ./ws_*]]
if {[llength $ws_dirs] == 0} { error "No workspace found. Run vitis_build.tcl first." }
set WS [lindex $ws_dirs end]
puts "Using workspace: $WS"
setws $WS

set ELF     "$WS/$APP/Debug/$APP.elf"
set WBX_BIN [file normalize "./vectors/wbx.bin"]

if {![file exists $ELF]}     { error "ELF not found: $ELF — run vitis_build.tcl first" }
if {![file exists $WBX_BIN]} { error "wbx.bin not found: $WBX_BIN — run model export first" }

connect
targets -set -filter {name =~ "Cortex-A53*#0"}
rst -processor

# download ELF and weights+biases+input blob
dow $ELF
dow -data $WBX_BIN 0x20000000

puts "Running inference..."
con