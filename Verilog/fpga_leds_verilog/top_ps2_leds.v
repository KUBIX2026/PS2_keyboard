//============================================================================
// top_ps2_leds : TOP para Tang Nano 9K (Gowin GW1NR-9)
//
//   Teclado PS/2  ->  RX_PS2 (recepcion)  ->  ID_trama (identificar trama)
//                 ->  leds_ctrl (logica de salida)  ->  LEDs de la placa
//
// Cada vez que se PRESIONA (make) una tecla de control mapeada, se enciende
// un LED. El mapeo y el comportamiento incremental ("de a 2 al acabarse")
// viven en leds_ctrl.v. El break code 0xF0 (tecla soltada) se ignora para
// que solo cuenten las pulsaciones, no las sueltas.
//
// Senales de la placa:
//   clk27   : reloj de 27 MHz (pin 52)
//   rst_n   : boton de reset, ACTIVO EN BAJO
//   ps2_clk : linea CLK del teclado PS/2 (entrada, open-drain con pull-up)
//   ps2_dat : linea DATA del teclado PS/2 (entrada)
//   led_n   : 6 LEDs de la placa, ACTIVOS EN BAJO
//
// NOTA: RX_PS2 espera 'clk_ps2' y 'data_ps2' ya acondicionados. Aqui se
// sincronizan al dominio de clk27 con doble flip-flop y se filtra ruido.
//============================================================================
module top_ps2_leds #(
  // Duracion del destello del LED por pulsacion, en ciclos de clk27.
  // 27 MHz * 0.3 s ~= 8_100_000. El testbench lo reduce para simular rapido.
  parameter FLASH_CYCLES = 27'd8_100_000
)(
  input        clk27,
  input        rst_n,
  input        ps2_clk,
  input        ps2_dat,
  output [5:0] led_n
);

  localparam N_LEDS = 6;

  // Reset sincrono activo en alto a partir del boton activo en bajo.
  wire rst = ~rst_n;

  //--------------------------------------------------------------------------
  // Sincronizacion de las lineas PS/2 al dominio de clk27 (doble FF).
  //--------------------------------------------------------------------------
  reg [1:0] clk_sync, dat_sync;
  always @(posedge clk27) begin
    if (rst) begin
      clk_sync <= 2'b11;
      dat_sync <= 2'b11;
    end else begin
      clk_sync <= {clk_sync[0], ps2_clk};
      dat_sync <= {dat_sync[0], ps2_dat};
    end
  end

  //--------------------------------------------------------------------------
  // Filtro de glitches en PS2_CLK: solo cambia tras varios ciclos estable.
  // (debounce simple de 8 muestras). Entrega 'clk_ps2_f' limpio.
  //--------------------------------------------------------------------------
  reg [2:0] filt;
  reg       clk_ps2_f;
  always @(posedge clk27) begin
    if (rst) begin
      filt      <= 3'b111;
      clk_ps2_f <= 1'b1;
    end else begin
      filt <= {filt[1:0], clk_sync[1]};
      if (filt == 3'b000) clk_ps2_f <= 1'b0;
      else if (filt == 3'b111) clk_ps2_f <= 1'b1;
    end
  end

  wire data_ps2_f = dat_sync[1];

  //--------------------------------------------------------------------------
  // Receptor PS/2
  //--------------------------------------------------------------------------
  wire [7:0] data_rx;
  wire       rx_error;
  wire       rx_done;   // pulso de 1 ciclo cuando hay byte recibido

  RX_PS2 u_rx (
    .clk      (clk27),
    .rst      (rst),
    .data_ps2 (data_ps2_f),
    .clk_ps2  (clk_ps2_f),
    .data_rx  (data_rx),
    .error    (rx_error),
    .done     (rx_done)
  );

  //--------------------------------------------------------------------------
  // Identificar trama (combinacional). Se evalua sobre data_rx.
  //--------------------------------------------------------------------------
  // Bandera de contexto 'c' (0xAB -> 0x83) registrada, como pide ID_trama.
  reg  c_reg;
  wire c_next;
  wire id_done, id_tx, id_error, id_out_valid, id_idx_valid, id_is_f0;
  wire [7:0] id_out;
  wire [2:0] id_indice;

  ID_trama u_id (
    .data_rx   (data_rx),
    .c_in      (c_reg),
    .done      (id_done),
    .tx_start  (id_tx),
    .c_out     (c_next),
    .error     (id_error),
    .out       (id_out),
    .out_valid (id_out_valid),
    .indice    (id_indice),
    .idx_valid (id_idx_valid),
    .is_f0     (id_is_f0)
  );

  //--------------------------------------------------------------------------
  // Secuencial de contexto: registrar c y la bandera de break (F0).
  //   - c_reg se actualiza solo cuando llega un byte nuevo (rx_done).
  //   - f0_reg marca que el PROXIMO scancode es un "break" (tecla soltada),
  //     para NO contarlo como pulsacion.
  //--------------------------------------------------------------------------
  reg f0_reg;
  always @(posedge clk27) begin
    if (rst) begin
      c_reg  <= 1'b0;
      f0_reg <= 1'b0;
    end else if (rx_done) begin
      c_reg <= c_next;                 // registra la bandera de contexto
      if (id_is_f0)
        f0_reg <= 1'b1;                // llego 0xF0 -> el siguiente es break
      else
        f0_reg <= 1'b0;                // cualquier otro byte limpia el break
    end
  end

  // Pulso de "tecla presionada": byte recibido + indice valido + NO es break.
  wire key_stroke = rx_done & id_idx_valid & ~f0_reg;

  //--------------------------------------------------------------------------
  // Logica de salida de LEDs
  //--------------------------------------------------------------------------
  wire [N_LEDS-1:0] leds_pos;   // logica positiva (1 = encendido)

  leds_ctrl #(.N_LEDS(N_LEDS), .FLASH_CYCLES(FLASH_CYCLES)) u_leds (
    .clk        (clk27),
    .rst        (rst),
    .key_stroke (key_stroke),
    .indice     (id_indice),
    .leds       (leds_pos)
  );

  // LEDs de la placa son activos en bajo -> invertir.
  assign led_n = ~leds_pos;

endmodule
