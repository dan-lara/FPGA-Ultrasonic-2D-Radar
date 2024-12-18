# Creation de la lirairie de travail
vlib work

# Compilation
vcom -93 ../IP_Telemetre.vhd
vcom -93 ../TB_Telemetre.vhd

# Simulation
vsim TB_Telemetre_DUT

# Visualisation
view signals
add wave *
#add wave sim:/TB_Telemetre_DUT/G1/*

run 210 ms
wave zoom full