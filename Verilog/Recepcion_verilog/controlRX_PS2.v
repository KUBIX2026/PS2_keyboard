module controlRX_PS2( clk , rst , data_ps2 , clk_ps2 , ok_1 , ok_2 , rst_dp , dec_sh , error , done );

 input clk;
 input rst;
 input data_ps2;
 input clk_ps2;
 input ok_1;
 input ok_2;

 output reg rst_dp;
 output reg dec_sh;
 output reg error;
 output reg done;


 parameter START     = 3'b000;
 parameter NEG_CLK   = 3'b001;
 parameter DEC_SH    = 3'b010;
 parameter POS_CLK   = 3'b011;
 parameter COMP_BITC = 3'b100;
 parameter COMP_PAR  = 3'b101;
 parameter ST_ERROR  = 3'b110;
 parameter DONE      = 3'b111;

 reg [2:0] state;

 initial begin
  rst_dp = 0;
  dec_sh = 0;
  error  = 0;
  done   = 0;
  state  = 0;
 end

always @(posedge clk) begin
    if (rst) begin
      state = START;
    end else begin
    case(state)

      START:begin
        rst_dp <= 1;
        dec_sh <= 0;
        error  <= 0;
        done   <= 0;
        state = NEG_CLK;
      end

      NEG_CLK: begin
        rst_dp <= 0;
        dec_sh <= 0;
        error  <= 0;
        done   <= 0;
        if(clk_ps2)
          state = NEG_CLK;
        else
          state = DEC_SH;
      end

      DEC_SH: begin
        rst_dp <= 0;
        dec_sh <= 1;
        error  <= 0;
        done   <= 0;
        state = POS_CLK;
      end

      POS_CLK: begin
        rst_dp <= 0;
        dec_sh <= 0;
        error  <= 0;
        done   <= 0;
        if(clk_ps2)
          state = COMP_BITC;
        else
          state = POS_CLK;
      end

      COMP_BITC: begin
        rst_dp <= 0;
        dec_sh <= 0;
        error  <= 0;
        done   <= 0;
        if(ok_1)
          state = COMP_PAR;
        else
          state = NEG_CLK;
      end

      COMP_PAR: begin
        rst_dp <= 0;
        dec_sh <= 0;
        error  <= 0;
        done   <= 0;
        if(ok_2)
          state = DONE;
        else
          state = ST_ERROR;
      end

      ST_ERROR: begin
        rst_dp <= 0;
        dec_sh <= 0;
        error  <= 1;
        done   <= 0;
        state = DONE;
      end

      DONE:begin
        rst_dp <= 0;
        dec_sh <= 0;
        error  <= error;   // conserva el error calculado en ST_ERROR/COMP_PAR
        done   <= 1;
        state = START;
      end

     default: state = START;
   endcase
  end
end




`ifdef BENCH
reg [8*40:1] state_name;
always @(*) begin
  case(state)
    START     : state_name = "START";
    NEG_CLK   : state_name = "NEG_CLK";
    DEC_SH    : state_name = "DEC_SH";
    POS_CLK   : state_name = "POS_CLK";
    COMP_BITC : state_name = "COMP_BITC";
    COMP_PAR  : state_name = "COMP_PAR";
    ST_ERROR  : state_name = "ST_ERROR";
    DONE      : state_name = "DONE";
  endcase
end
`endif



endmodule
