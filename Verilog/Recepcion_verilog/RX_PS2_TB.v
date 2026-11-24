`timescale 1ns / 1ps
`define SIMULATION

module RX_PS2_TB;

 reg clk;
 reg rst;
 reg data_ps2;
 reg clk_ps2;
 wire [7:0] data_rx;
 wire       error;
 wire       done;

 RX_PS2 uut( .clk(clk), .rst(rst), .data_ps2(data_ps2), .clk_ps2(clk_ps2),
             .data_rx(data_rx), .error(error), .done(done) );

   parameter PERIOD          = 20;
   parameter real DUTY_CYCLE = 0.5;
   parameter OFFSET          = 0;

   initial  begin  // Process for clk
     #OFFSET;
     forever
       begin
         clk = 1'b0;
         #(PERIOD-(PERIOD*DUTY_CYCLE)) clk = 1'b1;
         #(PERIOD*DUTY_CYCLE);
       end
   end

   initial begin // valores iniciales
      rst = 0; data_ps2 = 1; clk_ps2 = 1;
   end

   // Envia un bit PS/2: dato estable y flanco de bajada de clk_ps2,
   // la FSM recorre NEG_CLK -> DEC_SH -> POS_CLK -> COMP_BITC.
   task send_bit;
     input b;
     begin
       data_ps2 = b;
       clk_ps2  = 1'b1;
       repeat (4) @ (posedge clk);
       clk_ps2  = 1'b0;      // flanco de bajada -> captura el bit
       repeat (4) @ (posedge clk);
       clk_ps2  = 1'b1;
       repeat (4) @ (posedge clk);
     end
   endtask

   integer i;
   reg [10:0] frame;    // {stop, parity, data[7:0], start}; el stop no se envia

   // Monitor: reporta cada dato recibido (flanco de done)
   always @(posedge done)
     $display("[%0t] RX done: data_rx=0x%02h error=%b", $time, data_rx, error);

   initial begin : STIMULUS
        #20 rst = 1;
        @ (posedge clk);
        @ (negedge clk);
        rst = 0;

        // --- Caso 1: dato 0x5A con paridad impar correcta ---
        // paridad impar de 0x5A (cuatro unos) = 1
        // La FSM procesa 10 bits: start + 8 datos + paridad (el stop no se usa)
        frame = {1'b1, 1'b1, 8'h5A, 1'b0};
        for (i = 0; i < 10; i = i + 1)
          send_bit(frame[i]);
        @ (posedge clk);
        $display("[%0t] Caso1 data_rx=0x%02h error=%b done=%b (esperado 0x5A, err=0)",
                 $time, data_rx, error, done);

        repeat (4) @ (posedge clk);
        rst = 1;
        @ (posedge clk);
        @ (negedge clk);
        rst = 0;

        // --- Caso 2: dato 0x3C con paridad incorrecta ---
        // paridad impar de 0x3C (cuatro unos) = 1; se envia 0 (mala)
        frame = {1'b1, 1'b0, 8'h3C, 1'b0};
        for (i = 0; i < 10; i = i + 1)
          send_bit(frame[i]);
        @ (posedge clk);
        $display("[%0t] Caso2 data_rx=0x%02h error=%b done=%b (esperado err=1)",
                 $time, data_rx, error, done);
   end

   initial begin: TEST_CASE
     $dumpfile("RX_PS2_TB.vcd");
     $dumpvars(-1, uut);
     #(6000) $finish;
   end
endmodule
