`timescale 1ns / 1ps

//============================================================================
// ID_trama_TB : banco de pruebas del bloque combinacional "Identificar trama".
//
// Flujo V2 (IdentificarTramaFlujoV2.png): como 'ID_trama' es combinacional,
// cada caso solo fija data_rx y revisa las salidas tras un pequeno retardo.
// V2 solo expone: done (ACK 0xFA), indice (0..7) e idx_valid.
//============================================================================
module ID_trama_TB;

  reg  [7:0] data_rx;

  wire       done;
  wire [2:0] indice;
  wire       idx_valid;

  ID_trama uut(
    .data_rx(data_rx),
    .done(done), .indice(indice), .idx_valid(idx_valid)
  );

  // Aplica un byte y reporta las salidas.
  task probar;
    input [7:0] b;
    begin
      data_rx = b;
      #5;
      $display("[%0t] data_rx=0x%02h | done=%b idx=%0d idx_valid=%b",
               $time, data_rx, done, indice, idx_valid);
    end
  endtask

  initial begin
    $dumpfile("ID_trama_TB.vcd");
    $dumpvars(-1, uut);

    data_rx = 8'h00; #5;

    $display("--- Comando de control ---");
    probar(8'hFA);         // ACK -> done=1

    $display("--- Scancodes de control (i = 0..7) ---");
    probar(8'h29);         // Select -> i=2
    probar(8'h5A);         // Start  -> i=3
    probar(8'h1D);         // Up     -> i=4
    probar(8'h1B);         // Down   -> i=5
    probar(8'h1C);         // Left   -> i=6
    probar(8'h23);         // Right  -> i=7

    $display("--- Byte no reconocido (volver: i = -1) ---");
    probar(8'h99);         // default -> done=0, idx_valid=0

    #10 $finish;
  end

endmodule
