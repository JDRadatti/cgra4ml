# Run from run/work/ with: xsct ../../deepsocflow/tcl/fpga/vitis_build.tcl
# Or pass paths as args: xsct vitis_build.tcl [xsa_path] [root_path]

set SCRIPT_DIR [file normalize [file dirname [info script]]]
set ROOT       [file normalize [expr { [llength $argv] > 1 ? [lindex $argv 1] : "$SCRIPT_DIR/../../.." }]]
set XSA        [file normalize [expr { [llength $argv] > 0 ? [lindex $argv 0] : "./design_1_wrapper.xsa" }]]
set INC1       [file normalize "./"]
set INC2       [file normalize "$ROOT/deepsocflow/c"]
set APP        my_app
set PROC       psu_cortexa53_0

# unique workspace to avoid lock/name collisions
set WS [file normalize "./ws_[clock format [clock seconds] -format %Y%m%d_%H%M%S]"]
setws $WS

puts "ROOT:  $ROOT"
puts "XSA:   $XSA"
puts "INC1:  $INC1"
puts "INC2:  $INC2"
puts "WS:    $WS"

if {![file exists $XSA]} { error "XSA not found: $XSA" }

# cleanup if reusing names
catch { app remove $APP }
catch { domain remove a53_standalone }
catch { platform remove plat }

# create platform and generate BSP
platform create -name plat -hw $XSA -proc $PROC -os standalone -arch {64-bit}
platform generate -domains all

# create app from Hello World template
app create -name $APP -platform plat -domain standalone_domain -template {Hello World} -lang C

# compiler settings
app config -name $APP -add include-path $INC1
app config -name $APP -add include-path $INC2
app config -name $APP -set compiler-optimization {Optimize most (-O3)}
app config -name $APP -add libraries m

# ---- replace source (local file ops; no tfile) ----
set DSTH [glob -nocomplain "$WS/$APP/src/helloworld.c"]
set SRC  [file normalize "$ROOT/deepsocflow/c/xilinx_example.c"]
if {$DSTH ne ""} { file delete -force $DSTH }
file copy -force $SRC "$WS/$APP/src/helloworld.c"

# build
app build -name $APP
puts "\nDone. ELF: $WS/$APP/Debug/$APP.elf"