//============================================================================
// ID_trama : Identificar trama (bloque COMBINACIONAL)
//
// Implementa el "switch case grande" del diagrama IdentificarTramaFlujo.png.
// Segun el byte recibido (data_rx) del receptor PS/2 decide la reaccion:
// responde comandos de control, reconoce el ID del teclado (0xAB,0x83),
// marca errores o mapea el scancode a un indice de control (i = 0..7).
//
// NOTA: por ser combinacional, la bandera C de contexto (vista en el
// diagrama) NO se puede guardar aqui. Se recibe como entrada (c_in) y se
// expone el valor siguiente (c_out). Quien use este modulo debe registrar
// c_out en un flip-flop y realimentarlo a c_in. Igual con out/done/etc.
//
// La deteccion del break code 0xF0 (tecla soltada) se expone con la salida
// 'is_f0'. El estado persistente de la bandera F0 y el banco out_RX NO viven
// aqui (este modulo es combinacional); los maneja el modulo secuencial
// 'logica_salida' (ver ps2_flujo.png, bloque "Logica salida").
//============================================================================
module ID_trama(
  input  [7:0] data_rx,   // byte recibido del RX_PS2
  input        c_in,      // bandera de contexto (llego antes 0xAB)

  output reg       done,      // 1 => comando ACK (0xFA) procesado
  output reg       tx_start,  // 1 => pedir retransmision (0xFE) -> Transmision
  output reg       c_out,     // bandera de contexto siguiente
  output reg       error,     // 1 => byte de error (0x00 / 0xFF)
  output reg [7:0] out,       // dato hacia la CPU (valido con out_valid)
  output reg       out_valid, // 1 => 'out' contiene un dato valido para la CPU
  output reg [2:0] indice,    // indice de tecla de control (0..7)
  output reg       idx_valid, // 1 => 'indice' es valido
  output reg       is_f0      // 1 => el byte recibido es el break code 0xF0
);

  // Codigo temporal que avisa a la CPU "el ID si era del teclado PS/2".
  // 0x6B = 'k' (keyboard). CAMBIAR por el valor real que espere la CPU.
  localparam [7:0] OUT_OK = 8'h6B;

  always @(*) begin
    // valores por defecto (ninguna accion)
    done      = 1'b0;
    tx_start  = 1'b0;
    c_out     = c_in;    // conserva la bandera salvo que una rama la cambie
    error     = 1'b0;
    out       = 8'h00;
    out_valid = 1'b0;
    indice    = 3'd0;
    idx_valid = 1'b0;
    is_f0     = 1'b0;

    case (data_rx)
      // --- Respuestas de control ---
      8'hFA: begin                 // ACK
        done  = 1'b1;
      end
      8'hFE: begin                 // Resend -> ir a Transmision
        tx_start = 1'b1;
      end
      8'hAB: begin                 // primer byte del ID del teclado
        c_out = 1'b1;
      end
      8'h83: begin                 // segundo byte del ID
        if (c_in) begin            // solo si antes llego 0xAB
          c_out     = 1'b0;
          out       = OUT_OK;      // avisa a la CPU: ID == teclado PS/2
          out_valid = 1'b1;
        end
      end
      8'hAA: begin                 // Self-test OK -> seguir en Recepcion
        // sin accion (vuelve a Recepcion)
      end
      8'hF0: begin                 // Break code (prefijo de tecla soltada)
        is_f0 = 1'b1;
      end
      8'h00, 8'hFF: begin          // Error interno del teclado
        error = 1'b1;
      end

      // --- Scancodes de teclas de control (make). i = 0..7 ---
      8'h3B, 8'h75: begin indice = 3'd0; idx_valid = 1'b1; end  // A  / Pad 8
      8'h42, 8'h06: begin indice = 3'd1; idx_valid = 1'b1; end  // B  / Pad F2
      8'h29, 8'h70: begin indice = 3'd2; idx_valid = 1'b1; end  // Sel/ Pad 0
      8'h5A:        begin indice = 3'd3; idx_valid = 1'b1; end  // Start (Enter)
      8'h1D, 8'h72: begin indice = 3'd4; idx_valid = 1'b1; end  // Up / Pad 2
      8'h1B, 8'h7A: begin indice = 3'd5; idx_valid = 1'b1; end  // Down / Pad 3
      8'h1C, 8'h71: begin indice = 3'd6; idx_valid = 1'b1; end  // Left / Pad .
      8'h23, 8'h74: begin indice = 3'd7; idx_valid = 1'b1; end  // Right / Pad 6

      default: begin
        // byte no reconocido -> "volver" sin accion
      end
    endcase
  end

endmodule
