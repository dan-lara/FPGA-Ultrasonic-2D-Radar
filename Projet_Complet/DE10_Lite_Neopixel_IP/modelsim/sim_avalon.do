# Creation de la lirairie de travail
vlib work

# Compilation
vcom -93 ../IP_NeoPixel_Avalon.vhd
vcom -93 ../TB_NeoPixel_Avalon.vhd

# Simulation
vsim TB_NeoPixel_Avalon_DUT

# Visualisation
view signals
add wave *

run 10 ms
wave zoom full