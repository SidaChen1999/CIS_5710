/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] dividend [16:0];
      wire [15:0] quotient [16:0];
      wire [15:0] remainder [16:0];
      assign dividend[0] = i_dividend;
      assign remainder[0] = 16'h0000;
      assign quotient[0] = 16'h0000;
      genvar i;
      for (i = 0; i < 16; i = i+1) begin
            lc4_divider_one_iter iter(    .i_dividend(dividend[i]),
                                          .i_divisor(i_divisor),
                                          .i_remainder(remainder[i]),
                                          .i_quotient(quotient[i]),
                                          .o_dividend(dividend[i+1]),
                                          .o_remainder(remainder[i+1]),
                                          .o_quotient(quotient[i+1])
                                          );
      end
      assign o_remainder = (i_divisor > 0) ? remainder[16] : 16'h0000;
      assign o_quotient = (i_divisor > 0) ? quotient[16] : 16'h0000;

endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/
      wire [15:0] remainder = (i_remainder << 1) | ((i_dividend >> 15) & 1'b1);
      assign o_quotient = (remainder < i_divisor) ? i_quotient << 1 : (i_quotient << 1) | 1'b1;
      assign o_remainder = (remainder < i_divisor) ? remainder: remainder - i_divisor;
      assign o_dividend = i_dividend << 1;

endmodule
