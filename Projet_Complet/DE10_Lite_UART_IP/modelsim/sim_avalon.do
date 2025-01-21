# Creation de la lirairie de travail
vlib work

# Compilation
vcom -93 ../IP_UART_Avalon.vhd
vcom -93 ../TB_UART_Avalon.vhd

# Simulation
vsim TB_UART_Avalon_DUT

# Visualisation
view signals
add wave *
#add wave sim:/TB_UART_Avalon_DUT/G1/*

run 210 ms
wave zoom full