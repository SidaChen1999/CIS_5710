`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/



   wire [n-1:0] i_wdata [7:0];
   wire [n-1:0] reg_out [7:0];
   wire [n-1:0] rs_data_A;
   wire [n-1:0] rt_data_A;
   wire [n-1:0] rs_data_B;
   wire [n-1:0] rt_data_B;

   genvar i;
   for (i = 0; i < 8; i = i+1) begin
      assign i_wdata[i] = (i_rd_B == i & i_rd_we_B) ? i_wdata_B : i_wdata_A ;
      wire we = i_rd_we_A & (i_rd_A == i) | i_rd_we_B & (i_rd_B == i) ;
      Nbit_reg #(n, 0) single_reg(.in(i_wdata[i]),
                                    .out(reg_out[i]),
                                    .clk(clk),
                                    .we(we),
                                    .gwe(gwe),
                                    .rst(rst)
                                    );

   
   end

   assign rs_data_A = (i_rs_A == 0) ? reg_out[0] : 
                      (i_rs_A == 1) ? reg_out[1] : 
                      (i_rs_A == 2) ? reg_out[2] : 
                      (i_rs_A == 3) ? reg_out[3] : 
                      (i_rs_A == 4) ? reg_out[4] : 
                      (i_rs_A == 5) ? reg_out[5] : 
                      (i_rs_A == 6) ? reg_out[6] : reg_out[7] ;

   assign rt_data_A = (i_rt_A == 0) ? reg_out[0] : 
                      (i_rt_A == 1) ? reg_out[1] : 
                      (i_rt_A == 2) ? reg_out[2] : 
                      (i_rt_A == 3) ? reg_out[3] : 
                      (i_rt_A == 4) ? reg_out[4] : 
                      (i_rt_A == 5) ? reg_out[5] : 
                      (i_rt_A == 6) ? reg_out[6] : reg_out[7] ;

   assign rs_data_B = (i_rs_B == 0) ? reg_out[0] : 
                      (i_rs_B == 1) ? reg_out[1] : 
                      (i_rs_B == 2) ? reg_out[2] : 
                      (i_rs_B == 3) ? reg_out[3] : 
                      (i_rs_B == 4) ? reg_out[4] : 
                      (i_rs_B == 5) ? reg_out[5] : 
                      (i_rs_B == 6) ? reg_out[6] : reg_out[7] ;

   assign rt_data_B = (i_rt_B == 0) ? reg_out[0] : 
                      (i_rt_B == 1) ? reg_out[1] : 
                      (i_rt_B == 2) ? reg_out[2] : 
                      (i_rt_B == 3) ? reg_out[3] : 
                      (i_rt_B == 4) ? reg_out[4] : 
                      (i_rt_B == 5) ? reg_out[5] : 
                      (i_rt_B == 6) ? reg_out[6] : reg_out[7] ;                 

   assign o_rs_data_A = (i_rd_we_B == 1 && i_rd_B == i_rs_A) ? i_wdata_B : 
                        (i_rd_we_A == 1 && i_rd_A == i_rs_A) ? i_wdata_A : rs_data_A; 

   assign o_rt_data_A = (i_rd_we_B == 1 && i_rd_B == i_rt_A) ? i_wdata_B : 
                        (i_rd_we_A == 1 && i_rd_A == i_rt_A) ? i_wdata_A : rt_data_A; 

   assign o_rs_data_B = (i_rd_we_B == 1 && i_rd_B == i_rs_B) ? i_wdata_B : 
                        (i_rd_we_A == 1 && i_rd_A == i_rs_B) ? i_wdata_A : rs_data_B; 

   assign o_rt_data_B = (i_rd_we_B == 1 && i_rd_B == i_rt_B) ? i_wdata_B : 
                        (i_rd_we_A == 1 && i_rd_A == i_rt_B) ? i_wdata_A : rt_data_B;


endmodule
