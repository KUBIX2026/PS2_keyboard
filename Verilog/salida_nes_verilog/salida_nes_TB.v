`timescale 1ns / 1ps

//============================================================================
// salida_nes_TB : banco de pruebas del bloque "Logica salida" (salida_nes).
//
// Prueba la secuencia break code del protocolo PS/2 con semantica NES:
//   make  boton i=2   -> out_RX[2]=1 (presionado)
//   0xF0             -> F0=1
//   boton i=2 (break) -> out_RX[2]=0 (soltado) y luego F0=0
//   make  boton i=5   -> out_RX[5]=1 (presionado)
// Cada byte se procesa con un pulso 'start' de un ciclo.
//============================================================================
module salida_nes_TB;

  reg        clk;
  reg        rst;
  reg        start;
  reg        is_f0;
  reg  [2:0] idx;
  reg        idx_valid;

  wire [7:0] out_RX;
  wire       F0;
  wire       done;

  salida_nes uut(
    .clk(clk), .rst(rst), .start(start),
    .is_f0(is_f0), .idx(idx), .idx_valid(idx_valid),
    .out_RX(out_RX), .F0(F0), .done(done)
  );

  // reloj de 10 ns
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Procesa un byte: aplica is_f0/idx/idx_valid y da un pulso start de 1 ciclo.
  task procesar;
    input       f0_byte;
    input [2:0] i;
    input       ivalid;
    begin
      @(negedge clk);
      is_f0     = f0_byte;
      idx       = i;
      idx_valid = ivalid;
      start     = 1'b1;
      @(negedge clk);
      start     = 1'b0;
      @(negedge clk);   // deja ver 'done' y el estado actualizado
      $display("[%0t] is_f0=%b idx=%0d iv=%b | F0=%b out_RX=0x%02h done=%b",
               $time, f0_byte, i, ivalid, F0, out_RX, done);
    end
  endtask

  initial begin
    $dumpfile("salida_nes_TB.vcd");
    $dumpvars(-1, uut);

    is_f0 = 0; idx = 0; idx_valid = 0; start = 0;
    rst = 1; @(negedge clk); @(negedge clk); rst = 0;

    $display("--- make boton 2 (presionado => out_RX[2]=1) ---");
    procesar(1'b0, 3'd2, 1'b1);

    $display("--- break code 0xF0 (F0 -> 1) ---");
    procesar(1'b1, 3'd0, 1'b0);

    $display("--- boton 2 tras 0xF0 (soltado => out_RX[2]=0, F0 -> 0) ---");
    procesar(1'b0, 3'd2, 1'b1);

    $display("--- make boton 5 (presionado => out_RX[5]=1) ---");
    procesar(1'b0, 3'd5, 1'b1);

    #10 $finish;
  end

endmodule
