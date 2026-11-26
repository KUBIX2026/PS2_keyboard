//============================================================================
// ID_trama : Identificar trama (bloque COMBINACIONAL)
//
// Implementa el flujo de IdentificarTramaFlujoV2.png: un "switch case grande"
// (combinacional). V2 solo contempla:
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
// Por eso este modulo SOLO expone lo que V2 usa:
//   - done      : 1 cuando llega el ACK 0xFA.
//   - indice    : indice de tecla de control (0..7).
//   - idx_valid : 1 si 'indice' es valido; 0 => "i = -1" = no hizo nada.
//
// Lo demas del diagrama antiguo (bandera de contexto C para 0xAB/0x83,
// tx_start para 0xFE, error para 0x00/0xFF, out/out_valid, deteccion de 0xF0)
// NO forma parte de V2 y se elimina. La deteccion del break code 0xF0, si se
// necesita aguas arriba, se hace afuera directamente como (data_rx == 0xF0).
//
// El "i = -1" del Inicio es el centinela que identifica "no hizo nada" desde
// afuera: como 'indice' es de 3 bits sin signo, -1 no es representable, asi
// que ese estado "nada" se expone con idx_valid = 0 (indice solo tiene
// sentido cuando idx_valid = 1).
//============================================================================
module ID_trama(
  input  [7:0] data_rx,   // byte recibido del RX_PS2

  output reg       done,      // 1 => comando ACK (0xFA) -> Recepcion
  output reg [2:0] indice,    // indice de tecla de control (0..7), valido si idx_valid
  output reg       idx_valid  // 0 => i = -1 (no hizo nada); 1 => 'indice' valido
);

  always @(*) begin
    // --- Inicio: valores por defecto (i = -1, sin accion) ---
    done      = 1'b0;
    indice    = 3'd0;    // sin significado mientras idx_valid = 0 (i = -1 = nada)
    idx_valid = 1'b0;

    // --- Switch case grande (tal como el diagrama V2) ---
    case (data_rx)
      8'hFA: begin
        done = 1'b1;                                 // ACK -> done=1 -> Recepcion
      end

      8'h3B, 8'h75: begin
        indice = 3'd0; idx_valid = 1'b1;             // A      / Pad 8
      end
      8'h42, 8'h06: begin
        indice = 3'd1; idx_valid = 1'b1;             // B      / Pad F2
      end

      8'h29, 8'h70: begin
        indice = 3'd2; idx_valid = 1'b1;             // Select / Pad 0
      end
      8'h5A: begin
        indice = 3'd3; idx_valid = 1'b1;             // Start (Enter)
      end
      8'h1D, 8'h72: begin
        indice = 3'd4; idx_valid = 1'b1;             // Up    / Pad 2
      end
      8'h1B, 8'h7A: begin
        indice = 3'd5; idx_valid = 1'b1;             // Down  / Pad 3
      end
      8'h1C, 8'h71: begin
        indice = 3'd6; idx_valid = 1'b1;             // Left  / Pad .
      end
      8'h23, 8'h74: begin
        indice = 3'd7; idx_valid = 1'b1;             // Right / Pad 6
      end

      default: begin
        // "volver" -> sin accion (i = -1, idx_valid = 0)
      end
    endcase
  end

endmodule
