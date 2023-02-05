/* INSERT NAME AND PENNKEY HERE */
// Sida Chen, chensida
// Jingyi Chen, cjychen

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/
      wire [15:0] output_temp [15:0];
      assign o_result = (i_insn[15:12] == 4'b0000) ? output_temp[0] :
                        (i_insn[15:12] == 4'b0001) ? output_temp[1] :
                        (i_insn[15:12] == 4'b0010) ? output_temp[2] :
                        (i_insn[15:12] == 4'b0011) ? output_temp[3] :
                        (i_insn[15:12] == 4'b0100) ? output_temp[4] :
                        (i_insn[15:12] == 4'b0101) ? output_temp[5] :
                        (i_insn[15:12] == 4'b0110) ? output_temp[6] :
                        (i_insn[15:12] == 4'b0111) ? output_temp[7] :
                        (i_insn[15:12] == 4'b1000) ? output_temp[8] :
                        (i_insn[15:12] == 4'b1001) ? output_temp[9] :
                        (i_insn[15:12] == 4'b1010) ? output_temp[10] :
                        (i_insn[15:12] == 4'b1011) ? output_temp[11] :
                        (i_insn[15:12] == 4'b1100) ? output_temp[12] :
                        (i_insn[15:12] == 4'b1101) ? output_temp[13] :
                        (i_insn[15:12] == 4'b1110) ? output_temp[14] : output_temp[15];
      

endmodule
