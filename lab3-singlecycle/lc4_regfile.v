/* TODO: Names of all group members
 * TODO: PennKeys of all group members
 * Sida Chen, chensida
 * Jingyi Chen, cjychen
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

   /***********************
    * TODO YOUR CODE HERE *
    ***********************/
    wire [n-1:0] reg_out [7:0];

    genvar i;
    for (i = 0; i < 8; i = i+1) begin
        wire we = i_rd_we & (i_rd == i);
        Nbit_reg #(n, 0) single_reg(.in(i_wdata),
                                    .out(reg_out[i]),
                                    .clk(clk),
                                    .we(we),
                                    .gwe(gwe),
                                    .rst(rst)
                                    );
        end
    
    assign o_rs_data =  (i_rs == 0) ? reg_out[0] :
                        (i_rs == 1) ? reg_out[1] :
                        (i_rs == 2) ? reg_out[2] :
                        (i_rs == 3) ? reg_out[3] :
                        (i_rs == 4) ? reg_out[4] :
                        (i_rs == 5) ? reg_out[5] :
                        (i_rs == 6) ? reg_out[6] : reg_out[7];

    assign o_rt_data =  (i_rt == 0) ? reg_out[0] :
                        (i_rt == 1) ? reg_out[1] :
                        (i_rt == 2) ? reg_out[2] :
                        (i_rt == 3) ? reg_out[3] :
                        (i_rt == 4) ? reg_out[4] :
                        (i_rt == 5) ? reg_out[5] :
                        (i_rt == 6) ? reg_out[6] : reg_out[7];

endmodule
