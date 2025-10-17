set ::env(DESIGN_NAME) "ibex_core"

set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]

set ::env(CLOCK_PERIOD) "100"
set ::env(CLOCK_PORT) "clk_i"

set ::env(CLOCK_NET) "clk_i"
set ::env(CLOCK_NET) $::env(CLOCK_PORT)

# set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg