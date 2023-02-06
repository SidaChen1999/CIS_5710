/* TODO: INSERT NAME AND PENNKEY HERE */
// Sida Chen, chensida
// Jingyi Chen, cjychen

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

  assign pout = & pin;
  assign gout = gin[3] | pin[3]&gin[2] | (&pin[3:2])&gin[1] | (&pin[3:1])&gin[0];
  assign cout[0] = gin[0] | pin[0]&cin;
  assign cout[1] = gin[1] | pin[1]&gin[0] | (&pin[1:0])&cin;
  assign cout[2] = gin[2] | pin[2]&gin[1] | (&pin[2:1])&gin[0] | (&pin[2:0])&cin;

endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

  wire [15:0] g;
  wire [15:0] p;
  wire [15:0] c;
  assign c[0] = cin;
  wire [2:0] c_inter;
  wire [3:0] g_inter;
  wire [3:0] p_inter;
  wire g15, p15;
  wire [15:0] sum_inter = a ^ b;
  genvar i;
  for (i = 0; i < 16; i = i+1) begin
    gp1 d1(.a(a[i]), .b(b[i]), .g(g[i]), .p(p[i]));
  end
  genvar j;
  for (j = 0; j < 4; j = j+1) begin
    gpn #(4) d3(.gin(g[3+4*j:4*j]), .pin(p[3+4*j:4*j]), .cin(c[j*4]), 
           .gout(g_inter[j]), .pout(p_inter[j]), .cout(c[3+j*4:1+j*4]));
  end
  gpn #(4) d5(.gin(g_inter), .pin(p_inter), .cin(c[0]), 
           .gout(g15), .pout(p15), .cout({c[12], c[8], c[4]})); // c[2:0], MSB at left
  assign sum = c ^ sum_inter;

endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);

  assign pout = & pin;

  genvar i;
  genvar j;
  genvar k;
  wire [N-1:0] gout_inter [N-1:0];
  for (i = N-1; i >= 0; i = i-1) begin
      assign gout_inter[i][i] = gin[N-1-i];
      for (j = i-1; j >= 0; j = j-1) begin
        assign gout_inter[i][j] = gout_inter[i][j+1] & pin[j+N-i];
    end
  end
  wire [N-1:0] gout_sum;
  assign gout_sum[0] = gout_inter[0][0];
  for (i = 1; i < N; i = i+1) begin
    assign gout_sum[i] = gout_sum[i-1] | gout_inter[i][0];
  end
  assign gout = gout_sum[N-1];

  wire [N-1:0] cout_inter [N-1:0][N-2:0];
  for (k = 0; k < N-1; k = k+1) begin
    for (i = k+1; i >= 0; i = i-1) begin
      if (i == k+1) assign cout_inter[i][k][i] = cin;
      else assign cout_inter[i][k][i] = gin[k-i];
      for (j = i-1; j >= 0; j = j-1) begin
        assign cout_inter[i][k][j] = cout_inter[i][k][j+1] & pin[j+k-i+1];
      end
    end
  end
  wire [N-1:0] cout_sum [N-2:0];
  for (k = 0; k < N-1; k = k+1) begin
    assign cout_sum[k][0] = cout_inter[0][k][0];
    for (i = 1; i < k+2; i = i+1) begin
      assign cout_sum[k][i] = cout_sum[k][i-1] | cout_inter[i][k][0];
    end
    assign cout[k] = cout_sum[k][k+1];
  end

endmodule
