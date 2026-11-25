#============================================================================
# Makefile : PS/2 -> Recepcion -> Identificar trama -> LEDs (Tang Nano 9K)
#
#   make sim    -> compila y simula el TOP con su testbench (iverilog + vvp)
#   make wave   -> abre las ondas en gtkwave
#   make synth  -> sintetiza, place&route y genera bitstream (.fs) Gowin
#   make load   -> carga el bitstream a la placa (SRAM) con openFPGALoader
#   make flash  -> graba el bitstream a la flash de la placa
#
# Requiere la OSS CAD Suite:  source digital-logic-design activate
#============================================================================
TOP      = top_ps2_leds
DEVICE   = GW1NR-LV9QN88PC6/I5
FAMILY   = GW1N-9C
CST      = tangnano9k.cst

# Fuentes RTL (incluye los modulos reutilizados de otras carpetas)
RX_DIR   = ../Recepcion_verilog
ID_DIR   = ../IdentificarTrama_verilog
SRCS     = $(TOP).v leds_ctrl.v \
           $(RX_DIR)/RX_PS2.v $(RX_DIR)/controlRX_PS2.v $(RX_DIR)/datapathRX_PS2.v \
           $(ID_DIR)/ID_trama.v

#--------------------------- Simulacion ------------------------------------
sim:
	rm -f a.out *.vcd
	iverilog -g2012 -o a.out $(TOP)_TB.v $(SRCS)
	vvp a.out

wave:
	gtkwave $(TOP)_TB.vcd &

#--------------------------- Sintesis Gowin (flujo himbaechel) -------------
# OSS CAD Suite reciente usa nextpnr-himbaechel con backend Gowin
# (ya no existe nextpnr-gowin). El CST se pasa a nextpnr via --vopt cst=...
synth: $(TOP).fs

$(TOP).json: $(SRCS)
	yosys -p "read_verilog $(SRCS); synth_gowin -top $(TOP) -json $@"

$(TOP)_pnr.json: $(TOP).json $(CST)
	nextpnr-himbaechel --json $(TOP).json --write $@ \
		--device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CST)

$(TOP).fs: $(TOP)_pnr.json
	gowin_pack -d $(FAMILY) -o $@ $(TOP)_pnr.json

#--------------------------- Carga a la placa ------------------------------
load: $(TOP).fs
	openFPGALoader -b tangnano9k $(TOP).fs

flash: $(TOP).fs
	openFPGALoader -b tangnano9k -f $(TOP).fs

clean:
	rm -f a.out *.vcd *.json *.fs
