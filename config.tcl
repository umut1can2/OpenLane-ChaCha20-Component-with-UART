set ::env(DESIGN_NAME) {top}

set ::env(VERILOG_FILES) "\
    $::env(DESIGN_DIR)/src/quarter_round.v \
    $::env(DESIGN_DIR)/src/KeystreamGenerator.v \
    $::env(DESIGN_DIR)/src/uart_rx.v \
    $::env(DESIGN_DIR)/src/uart_tx.v \
    $::env(DESIGN_DIR)/src/uart_top.v \
    $::env(DESIGN_DIR)/src/top.v"


# clk_i duzelt
set ::env(CLOCK_PORT) "clk"
# 20 Mhz = 50ns etmesi gerekir
set ::env(CLOCK_PERIOD) "50.0" 

# no flat 0 data sentezlemiyor
set ::env(SYNTH_NO_FLAT) {1}
set ::env(SYNTH_MAX_FANOUT) {10}

# tek basina cip degil bir modul
set ::env(DESIGN_IS_CORE) {0}

# degerleri degistir
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 1000 1000"
set ::env(PL_TARGET_DENSITY) "0.4"
set tech_specific_config "$::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl"
if { [file exists $tech_specific_config] == 1 } {
    source $tech_specific_config
}