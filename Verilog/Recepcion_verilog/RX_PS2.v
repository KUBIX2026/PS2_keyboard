//============================================================================
// RX_PS2 : receptor PS/2 (top) = controlRX_PS2 (FSM) + datapathRX_PS2
//
//   data_rx : 8 bits de datos recibidos (validos durante done=1)
//   error   : 1 si la paridad fallo (valido durante done=1)
//   done    : 1 ciclo en el estado DONE (dato recibido)
//
// El registro de desplazamiento mantiene el dato estable desde que ok_1=1
// hasta el proximo START, por lo que las salidas se exponen directamente.
//============================================================================
module RX_PS2( clk , rst , data_ps2 , clk_ps2 , data_rx , error , done );

 input clk;
 input rst;
 input data_ps2;
 input clk_ps2;

 output [7:0] data_rx;
 output error;
 output done;

 wire rst_dp;
 wire dec_sh;
 wire load;
 wire ok_1;
 wire ok_2;

 controlRX_PS2 u_control(
   .clk(clk), .rst(rst), .data_ps2(data_ps2), .clk_ps2(clk_ps2),
   .ok_1(ok_1), .ok_2(ok_2),
   .rst_dp(rst_dp), .dec_sh(dec_sh), .load(load), .error(error), .done(done)
 );

 datapathRX_PS2 u_datapath(
   .clk(clk), .rst(rst), .rst_dp(rst_dp), .dec_sh(dec_sh), .load(load),
   .data_ps2(data_ps2), .data_rx(data_rx), .ok_1(ok_1), .ok_2(ok_2)
 );

endmodule
