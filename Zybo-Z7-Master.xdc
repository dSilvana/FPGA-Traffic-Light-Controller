## traffic_light_constraints.xdc
## Zybo Z7 (Zynq-7020) - Top-row JE/JD Pmod (single-digit - RIGHT digit)
##
## Ports in VHDL entity:
##   clk, reset, ped_button,
##   NS_red, NS_yellow, NS_green,
##   EW_red, EW_yellow, EW_green,
##   seg(6 downto 0), an(1 downto 0)
##

# ------------------------------------------------------------------
# CLOCK (Zybo Z7 125 MHz reference)
# Use the MRCC pin (K17) or the board's provided sysclk pin.
# If your board uses a different clock pin in the master XDC, change here.
# ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -period 8.000 -name sys_clk -waveform {0 4} [get_ports { clk }];

# ------------------------------------------------------------------
# Reset button (BTN0) and Pedestrian button (BTNC)
# BTN pins (from your master XDC):
#  BTN0 -> K18, BTN1(BTNC) -> P16 (this matches your earlier mapping)
# ------------------------------------------------------------------
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { reset }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { ped_button }];

# ------------------------------------------------------------------
# Traffic light outputs (map to usable board pins)
# We use four single-color user LEDs + two extra GPIO pins for the remaining
# signals. Change mapping later if you want different LEDs/pmod outputs.
# ------------------------------------------------------------------
# North-South LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { NS_red }];     # LD0
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { NS_yellow }];  # LD1
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { NS_green }];   # LD2

# East-West LEDs (two more pins)
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { EW_red }];     # LD3
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { EW_yellow }];  # GPIO (RGB6_R pin)
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { EW_green }];   # GPIO (RGB6_G pin)

# ------------------------------------------------------------------
# Pmod SSD pin mapping (single-digit - right digit)
# Using the same wiring you used in BCD7:
#  JD top-row pins for segments 0..3  -> seg(0..3)
#  JE top-row pins for segments 4..6  -> seg(4..6)
#  JE top-row pin for common cathode  -> an(0) (right digit)
#  We'll wire an(1) to an available JD pin (kept unused/inactive).
# ------------------------------------------------------------------

# JD header (top row) -> seg(0..3)
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]; # JD pin 1
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]; # JD pin 2
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]; # JD pin 3
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]; # JD pin 4

# JE header (top row) -> seg(4..6)
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]; # JE pin 1
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]; # JE pin 2
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]; # JE pin 3

# JE header pin used as C (cathode) for RIGHT digit -> an(0)
# (This follows your earlier BCD7 mapping where JE H15 was used as C)
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { an[0] }];

# JD/JE spare pin used as the other an bit (an[1]) - keep it available but unused.
# We map it so Vivado sees both bits assigned; set it to a JD pin that is free.
set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { an[1] }];

# ------------------------------------------------------------------
# Optional: If you want to expose SW0..SW2 (switches for timing), uncomment and add
# top-level ports for sw0..sw2, then enable these lines:
# ------------------------------------------------------------------
#set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw0 }];
#set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw1 }];
#set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw2 }];

# End of file
