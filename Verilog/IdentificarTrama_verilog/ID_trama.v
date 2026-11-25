//============================================================================
// ID_trama : Identificar trama (bloque COMBINACIONAL)
//
// Implementa el flujo de IdentificarTramaFlujoV2.png: un "switch case grande"
// (combinacional) con decisiones ORDENADAS, tal cual el diagrama:
//
//     Inicio: data_RX, Load C, i = -1
//       data_RX == 0xFA ?      -> si: done = 1  (-> Recepcion)
//       data_RX == 0x3B|0x75 ? -> si: i = 0
//       data_RX == 0x42|0x06 ? -> si: i = 1
//       data_RX == 0x29|0x70 ? -> si: i = 2
//       data_RX == 0x5A      ? -> si: i = 3
//       data_RX == 0x1D|0x72 ? -> si: i = 4
//       data_RX == 0x1B|0x7A ? -> si: i = 5
//       data_RX == 0x1C|0x71 ? -> si: i = 6
//       data_RX == 0x23|0x74 ? -> si: i = 7
//       en cualquier otro caso -> "volver" (sin accion)
//
// El "i = -1" del Inicio es el valor centinela que sirve para que AFUERA se
// identifique "no hizo nada" (ninguna rama matcheo). Como 'indice' es de 3
// bits sin signo, -1 no es representable; ese estado "nada" se expone con
// idx_valid = 0. Es decir, para quien consume este modulo:
//     idx_valid == 0   <=>   i == -1   <=>   no se reconocio tecla (nada)
//     idx_valid == 1   <=>   'indice' (0..7) es la tecla reconocida
// 'indice' solo tiene sentido cuando idx_valid = 1.
//
// NOTA (recuadro amarillo del diagrama): por ser combinacional, la bandera C
// de contexto NO se guarda aqui. Se recibe como entrada (c_in) y se expone
// hacia afuera (c_out) para que el modulo secuencial la registre y realimente
// ("guardar el valor de c afuera y cargarlo"). En V2 ninguna rama usa ni
// cambia C, de modo que c_out simplemente conserva c_in.
//
// Las salidas auxiliares (tx_start, error, out/out_valid, is_f0) se mantienen
// por compatibilidad con el resto del sistema (top_ps2_leds usa 'is_f0' para
// ignorar el break code 0xF0). V2 no las acciona, por eso quedan en su valor
// de reposo salvo 'is_f0', que sigue detectando 0xF0 fuera de la cadena.
//============================================================================
module ID_trama(
  input  [7:0] data_rx,   // byte recibido del RX_PS2
  input        c_in,      // bandera de contexto (Load C, cargada desde afuera)

  output reg       done,      // 1 => comando ACK (0xFA) procesado -> Recepcion
  output reg       tx_start,  // (compat) pedir retransmision; no usado en V2
  output reg       c_out,     // bandera de contexto siguiente (= c_in en V2)
  output reg       error,     // (compat) byte de error; no usado en V2
  output reg [7:0] out,       // (compat) dato hacia la CPU; no usado en V2
  output reg       out_valid, // (compat) 'out' valido; no usado en V2
  output reg [2:0] indice,    // indice de tecla de control (0..7), valido si idx_valid
  output reg       idx_valid, // 0 => i = -1 (no hizo nada); 1 => 'indice' valido
  output reg       is_f0      // 1 => el byte recibido es el break code 0xF0
);

  always @(*) begin
    // --- Inicio: valores por defecto (i = -1, sin accion) ---
    done      = 1'b0;
    tx_start  = 1'b0;
    c_out     = c_in;    // conserva C (no se modifica en V2)
    error     = 1'b0;
    out       = 8'h00;
    out_valid = 1'b0;
    indice    = 3'd0;    // sin significado mientras idx_valid = 0 (i = -1 = nada)
    idx_valid = 1'b0;
    // 'is_f0' se evalua aparte: deteccion del break code 0xF0 (compat).
    is_f0     = (data_rx == 8'hF0);

    // --- Cadena de decisiones ordenada (tal como el diagrama V2) ---
    if (data_rx == 8'hFA) begin
      done = 1'b1;                                   // ACK -> done=1 -> Recepcion
    end
    else if (data_rx == 8'h3B || data_rx == 8'h75) begin
      indice = 3'd0; idx_valid = 1'b1;               // A      / Pad 8
    end
    else if (data_rx == 8'h42 || data_rx == 8'h06) begin
      indice = 3'd1; idx_valid = 1'b1;               // B      / Pad F2
    end
    else if (data_rx == 8'h29 || data_rx == 8'h70) begin
      indice = 3'd2; idx_valid = 1'b1;               // Select / Pad 0
    end
    else if (data_rx == 8'h5A) begin
      indice = 3'd3; idx_valid = 1'b1;               // Start (Enter)
    end
    else if (data_rx == 8'h1D || data_rx == 8'h72) begin
      indice = 3'd4; idx_valid = 1'b1;               // Up    / Pad 2
    end
    else if (data_rx == 8'h1B || data_rx == 8'h7A) begin
      indice = 3'd5; idx_valid = 1'b1;               // Down  / Pad 3
    end
    else if (data_rx == 8'h1C || data_rx == 8'h71) begin
      indice = 3'd6; idx_valid = 1'b1;               // Left  / Pad .
    end
    else if (data_rx == 8'h23 || data_rx == 8'h74) begin
      indice = 3'd7; idx_valid = 1'b1;               // Right / Pad 6
    end
    // else: "volver" -> sin accion (i = -1, idx_valid = 0)
  end

endmodule
