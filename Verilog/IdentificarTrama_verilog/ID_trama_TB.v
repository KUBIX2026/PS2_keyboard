`timescale 1ns / 1ps

//============================================================================
// ID_trama_TB : banco de pruebas del bloque combinacional "Identificar trama".
//
// Como 'ID_trama' es combinacional, cada caso solo fija data_rx y c_in y
// revisa las salidas tras un pequeno retardo. El caso central es el ID del
// teclado: 0xAB (pone c=1) seguido de 0x83 con c=1 -> out_valid, out=OUT_OK.
// Tambien se verifica la deteccion del break code 0xF0 (is_f0).
//============================================================================
module ID_trama_TB;

  reg  [7:0] data_rx;
  reg        c_in;

  wire       done;
  wire       tx_start;
  wire       c_out;
  wire       error;
  wire [7:0] out;
  wire       out_valid;
  wire [2:0] indice;
  wire       idx_valid;
  wire       is_f0;

  ID_trama uut(
    .data_rx(data_rx), .c_in(c_in),
    .done(done), .tx_start(tx_start), .c_out(c_out), .error(error),
    .out(out), .out_valid(out_valid), .indice(indice), .idx_valid(idx_valid),
    .is_f0(is_f0)
  );

  // Aplica un byte y reporta las salidas.
  task probar;
    input [7:0] b;
    input       c;
    begin
      data_rx = b;
      c_in    = c;
      #5;
      $display("[%0t] data_rx=0x%02h c_in=%b | done=%b tx=%b c_out=%b err=%b out=0x%02h ov=%b idx=%0d iv=%b f0=%b",
               $time, data_rx, c_in, done, tx_start, c_out, error,
               out, out_valid, indice, idx_valid, is_f0);
    end
  endtask

  initial begin
    $dumpfile("ID_trama_TB.vcd");
    $dumpvars(-1, uut);

    data_rx = 8'h00; c_in = 1'b0; #5;

    $display("--- Comandos de control ---");
    probar(8'hFA, 1'b0);   // ACK   -> done=1
    probar(8'hFE, 1'b0);   // Resend-> tx_start=1

    $display("--- Identificacion del teclado (0xAB, 0x83) ---");
    probar(8'hAB, 1'b0);   // 1er byte ID -> c_out=1
    probar(8'h83, 1'b1);   // 2do byte ID con c=1 -> out_valid=1, out=OUT_OK
    probar(8'h83, 1'b0);   // 0x83 sin c previo -> NO valido (out_valid=0)

    $display("--- Self-test y errores ---");
    probar(8'hAA, 1'b0);   // Self-test OK -> sin accion
    probar(8'h00, 1'b0);   // Error -> error=1
    probar(8'hFF, 1'b0);   // Error -> error=1

    $display("--- Break code (tecla soltada) ---");
    probar(8'hF0, 1'b0);   // 0xF0 -> is_f0=1

    $display("--- Scancodes de control (i = 0..7) ---");
    probar(8'h3B, 1'b0);   // A      -> i=0
    probar(8'h5A, 1'b0);   // Start  -> i=3
    probar(8'h74, 1'b0);   // Pad 6  -> i=7

    $display("--- Byte no reconocido ---");
    probar(8'h99, 1'b0);   // default -> todo en 0

    #10 $finish;
  end

endmodule
