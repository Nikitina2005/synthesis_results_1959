set ::env(DESIGN_NAME) serv_top

set verilog_files [concat \
    [glob $::env(DESIGN_DIR)/src/serv/rtl/*.v] \
    [glob $::env(DESIGN_DIR)/src/serv/serving/*.v] \
    $::env(DESIGN_DIR)/src/serv_top.v
]

set ::env(VERILOG_FILES) $verilog_files

set ::env(CLOCK_PORT) clk
set ::env(CLOCK_PERIOD) 100

set ::env(CLOCK_TREE_SYNTH) true
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 400 400"
set ::env(PL_TARGET_DENSITY) 0.75
set ::env(DESIGN_IS_CORE) 0