## This file is a general .xdc for the Basys3 rev B board for ENGS31/CoSc56
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

##====================================================================
## External_Clock_Port
##====================================================================
set_property PACKAGE_PIN W5 [get_ports ext_clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports ext_clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports ext_clk]

##====================================================================
## Buttons
##====================================================================
set_property PACKAGE_PIN U17 	 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## Buttons for paddle control
# Right button (btnR)
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btn_right]
# Left button (btnL)
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btn_left]
# Center button (btnC)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btn_center]

##====================================================================
## VGA Connector
##====================================================================
set_property PACKAGE_PIN G19     [get_ports {rgb[11]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[11]}]
set_property PACKAGE_PIN H19     [get_ports {rgb[10]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[10]}]
set_property PACKAGE_PIN J19     [get_ports {rgb[9]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[9]}]
set_property PACKAGE_PIN N19     [get_ports {rgb[8]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[8]}]
set_property PACKAGE_PIN J17     [get_ports {rgb[7]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[7]}]
set_property PACKAGE_PIN H17     [get_ports {rgb[6]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[6]}]
set_property PACKAGE_PIN G17     [get_ports {rgb[5]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[5]}]
set_property PACKAGE_PIN D17     [get_ports {rgb[4]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[4]}]
set_property PACKAGE_PIN N18     [get_ports {rgb[3]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[3]}]
set_property PACKAGE_PIN L18     [get_ports {rgb[2]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[2]}]
set_property PACKAGE_PIN K18     [get_ports {rgb[1]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[1]}]
set_property PACKAGE_PIN J18     [get_ports {rgb[0]}]				
set_property IOSTANDARD LVCMOS33 [get_ports {rgb[0]}]
set_property PACKAGE_PIN P19     [get_ports hsync]						
set_property IOSTANDARD LVCMOS33 [get_ports hsync]
set_property PACKAGE_PIN R19     [get_ports vsync]						
set_property IOSTANDARD LVCMOS33 [get_ports vsync]

##====================================================================	
## 7 segment display
##====================================================================
set_property PACKAGE_PIN W7 [get_ports {seg_ext_port[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg_ext_port[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg_ext_port[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg_ext_port[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg_ext_port[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg_ext_port[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg_ext_port[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {seg_ext_port[6]}]

set_property PACKAGE_PIN V7 [get_ports dp_ext_port]							
	set_property IOSTANDARD LVCMOS33 [get_ports dp_ext_port]

set_property PACKAGE_PIN U2 [get_ports {an_ext_port[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[0]}]
set_property PACKAGE_PIN U4 [get_ports {an_ext_port[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[1]}]
set_property PACKAGE_PIN V4 [get_ports {an_ext_port[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[2]}]
set_property PACKAGE_PIN W4 [get_ports {an_ext_port[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an_ext_port[3]}]
	
##====================================================================
## Pmod Header JA
##====================================================================
#Sch name = JA1
set_property PACKAGE_PIN J1 [get_ports {spi_cs_ext_port}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {spi_cs_ext_port}]
#Sch name = JA2
set_property PACKAGE_PIN L2 [get_ports {spi_s_data_ext_port}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {spi_s_data_ext_port}]
#Sch name = JA3
#set_property PACKAGE_PIN J2 [get_ports {JA_port[2]}]					
#	set_property IOSTANDARD LVCMOS33 [get_ports {JA_port[2]}]
#Sch name = JA4
set_property PACKAGE_PIN G2 [get_ports {spi_sclk_ext_port}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {spi_sclk_ext_port}]
	
	##====================================================================
## Pmod Header JB
##====================================================================
##Sch name = JB1
set_property PACKAGE_PIN A14 [get_ports {spi_trigger_ext_port}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {spi_trigger_ext_port}]

