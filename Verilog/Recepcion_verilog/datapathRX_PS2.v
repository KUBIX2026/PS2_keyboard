//============================================================================
// datapathRX_PS2 : Datapath del receptor PS/2
//
// Bloques del diagrama (todos sincronos a clk; dec_sh/rst_dp son pulsos de
// un ciclo generados por el Control, igual que sh/add en control_mult):
//   data_IN   : registro de desplazamiento (LSR) de 11 bits
//   PARITY    : acumulador de paridad (XOR)
//   COMP_PAR  : comparador de paridad (paridad == 1?)   -> ok_2
//   CONTADOR  : contador descendente BIT_COUNT (10 -> 0) -> dec con dec_sh
//   COMP_BIT  : comparador de bits (BIT_COUNT == 0?)     -> ok_1
//
// Trama PS/2: start + data[8] + paridad + stop. Se capturan 10 bits
// (start + 8 datos + paridad); el bit de stop no se procesa.
// data_rx = 8 bits de datos (sr[9:2]).
//============================================================================
module datapathRX_PS2( clk , rst , rst_dp , dec_sh , load , data_ps2 , data_rx , ok_1 , ok_2 );

 input clk;
 input rst;         // reset global (borra el dato retenido data_hold)
 input rst_dp;
 input dec_sh;
 input load;        // pulso del control: capturar data_rx (trama valida, DONE)
 input data_ps2;

 output [7:0] data_rx;
 output ok_1;
 output ok_2;

 // data_IN : registro de desplazamiento (se cargan 10 bits de la trama:
 //   start + 8 datos + paridad; el bit de stop NO se captura)
 //   sr[1] start , sr[9:2] datos (data_RX de 8 bits, 0:7) , sr[10] paridad
 reg [10:0] sr;

 // PARITY : paridad acumulada
 reg parity;

 // CONTADOR : BIT_COUNT descendente, inicia en 10
 reg [3:0] bit_count;

 initial begin
  sr        = 11'd0;
  parity    = 1'b0;
  bit_count = 4'd10;
 end

 always @(posedge clk) begin
   if (rst_dp) begin
     sr        <= 11'd0;
     parity    <= 1'b0;
     bit_count <= 4'd10;
   end else if (dec_sh) begin
     sr        <= {data_ps2, sr[10:1]};   // entra por MSB, desplaza hacia LSB
     bit_count <= bit_count - 1'b1;       // decrementa contador de bits
     parity    <= parity ^ data_ps2;      // acumula paridad (sin bit de stop)
   end
 end

 // COMP_BIT : BIT_COUNT == 0?
 assign ok_1 = (bit_count == 4'd0);

 // COMP_PAR : paridad == 1?  (paridad impar correcta)
 assign ok_2 = (parity == 1'b1);

 // data_RX : registro de SALIDA. A diferencia de una ventana combinacional
 // del shift register (que cambiaria bit a bit mientras llega la trama), este
 // registro SOLO se actualiza cuando el control pulsa 'load' (en DONE, tras
 // comprobar paridad). Asi data_rx queda ESTABLE con el byte final y no
 // "baila" con los valores intermedios de la recepcion. Se borra solo con el
 // reset GLOBAL (no con rst_dp, que se activa al inicio de CADA trama y
 // perderia el dato retenido entre bytes).
 //   sr[9:2] = 8 bits de datos alineados al capturar los 10 bits de la trama.
 reg [7:0] data_hold;
 initial data_hold = 8'h00;
 always @(posedge clk) begin
   if (rst)       data_hold <= 8'h00;
   else if (load) data_hold <= sr[9:2];
 end
 assign data_rx = data_hold;

endmodule
