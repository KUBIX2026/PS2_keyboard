//============================================================================
// salida_nes : bloque "Logica salida" del flujo general (ps2_flujo.png)
//
// Maneja la bandera de break code F0 (tecla soltada) y el registro de
// botones out_RX estilo mando NES.
// Es SECUENCIAL: guarda el estado de F0 y de out_RX entre bytes recibidos.
// (El bloque ID_trama es combinacional y no puede guardar este estado; aqui
//  se recibe is_f0 e idx del byte actual y se actualiza el estado.)
//
// Flujo V3 ("INICIO: load data_RX, i_tradANes, out_RX, F0"):
//   data_RX = 0xF0?            -> is_f0 (viene de ID_trama)
//     Si -> F0 = 1             -> esperar el scancode de la tecla soltada
//     No -> i_tradANes = -1?
//             Si -> no hay indice valido -> mantener o limpiar F0
//             No -> out_RX[i] = F0 ; luego F0 = 0
//
// Interfaz tipo datapath: 'start' es un pulso de un ciclo que ordena procesar
// el byte actual (is_f0, idx, idx_valid). 'done' se levanta un ciclo al
// terminar. out_RX es de 8 bits: es el registro de botones estilo mando NES
// (un bit por tecla de control, indice 0..7) que luego se envia a la CPU:
//   out_RX[i] = 1 => boton i PRESIONADO  (scancode make, sin 0xF0 previo)
//   out_RX[i] = 0 => boton i SOLTADO     (break: 0xF0 seguido del scancode)
//
// Para la semantica NES se usa el complemento: out_RX[i] = ~F0.
// Tras un 0xF0, F0=1 y el siguiente scancode reconocido pone el boton en 0
// (soltado). Sin el prefijo F0, F0=0 y el scancode pone el boton en 1
// (presionado).
//============================================================================
module salida_nes(
  input        clk,
  input        rst,       // reset sincrono: F0=0, out_RX=0x00, done=0
  input        start,     // pulso de un ciclo: procesar el byte actual
  input        is_f0,     // 1 => el byte actual es 0xF0 (de ID_trama)
  input  [2:0] idx,       // indice de tecla (de ID_trama)
  input        idx_valid, // 1 => 'idx' corresponde a una tecla reconocida

  output reg [7:0] out_RX, // registro de botones NES (bit i => boton i)
  output reg       F0,     // bandera de break code (tecla soltada)
  output reg       done    // 1 ciclo cuando termina de procesar un byte
);

  initial begin
    out_RX = 8'h00;
    F0     = 1'b0;
    done   = 1'b0;
  end

  always @(posedge clk) begin
    if (rst) begin
      out_RX <= 8'h00;
      F0     <= 1'b0;
      done   <= 1'b0;
    end else if (start) begin
      if (is_f0) begin
        // data_RX = 0xF0?  Si -> F0 = 1
        F0 <= 1'b1;
      end else if (idx_valid) begin
        // No 0xF0 y i >= 0 -> boton i = estado presionado/soltado.
        // Diagrama: out_RX[i] = F0. Semantica NES: presionado=1, soltado=0,
        // por eso se escribe el complemento (~F0). Luego F0 = 0.
        out_RX[idx] <= ~F0;
        F0          <= 1'b0;
      end else begin
        // No 0xF0 y sin indice valido -> F0 = 0
        F0 <= 1'b0;
      end
      done <= 1'b1;
    end else begin
      done <= 1'b0;
    end
  end

endmodule
