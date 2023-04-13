/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);


      /*** YOUR CODE HERE ***/
        wire [15:0] output_temp [15:0];

        // ====================== module instantiation ==========================//
        wire [15:0] ain, bin, sum;
        wire cin;
        wire [15:0] ain_inter [3:0];
        wire [15:0] bin_inter [3:0];
        wire cin_inter [2:0];
        assign ain = ({i_insn[14], i_insn[12]} == 2'b00) ? ain_inter[0] :
                     ({i_insn[14], i_insn[12]} == 2'b01) ? ain_inter[1] :
                     ({i_insn[14], i_insn[12]} == 2'b10) ? ain_temp : ain_inter[3];
        assign bin = ({i_insn[14], i_insn[12]} == 2'b00) ? bin_inter[0] :
                     ({i_insn[14], i_insn[12]} == 2'b01) ? bin_inter[1] :
                     ({i_insn[14], i_insn[12]} == 2'b10) ? bin_temp : bin_inter[3];
        assign cin = ({i_insn[14], i_insn[12]} == 2'b00) ? cin_inter[0] :
                     ({i_insn[14], i_insn[12]} == 2'b01) ? cin_inter[1] :
                     ({i_insn[14], i_insn[12]} == 2'b10) ? cin_temp: 1'b0;
        wire cin_temp = (i_insn[13]) ? 1'b0 : cin_inter[2];
        wire [15:0] ain_temp = (i_insn[13]) ? ain_inter[3] : ain_inter[2];
        wire [15:0] bin_temp = (i_insn[13]) ? bin_inter[3] : bin_inter[2];
        cla16 adder (.a(ain), .b(bin), .cin(cin), .sum(sum));

        wire [15:0] remainder, quotient;
        lc4_divider div(.i_dividend(i_r1data), .i_divisor(i_r2data),
                        .o_remainder(remainder), .o_quotient(quotient));

        // ====================== instruction handelling ==========================//
        assign ain_inter[0] = {{7{i_insn[8]}}, i_insn[8:0]};
        assign bin_inter[0] = i_pc;
        assign cin_inter[0] = 1'b1;
        assign output_temp[0] = sum;

        wire [15:0] i1_adder = i_insn[5] ? {{11{i_insn[4]}}, i_insn[4:0]} : i_r2data;
        assign ain_inter[1] = i_r1data;
        assign bin_inter[1] = cin_inter[1] ? i1_adder ^ 16'hFFFF : i1_adder;
        assign cin_inter[1] = (i_insn[4:3] == 2'b10) & ~(i_insn[5] & 1'b1);
        wire [15:0] i1_inter = (i_insn[4:3] == 2'b00) ? sum :
                               (i_insn[4:3] == 2'b01) ? i_r1data * i_r2data :
                               (i_insn[4:3] == 2'b10) ? sum : quotient;
        assign output_temp[1] = i_insn[5] ? sum : i1_inter;

        wire [15:0] i2_inter1 = i_insn[7] ? {9'b0, i_insn[6:0]} : {{9{i_insn[6]}}, i_insn[6:0]};
        wire P = (i_insn[8:7] == 2'b00) ? ($signed(i_r1data) > $signed(i_r2data)) :
                 (i_insn[8:7] == 2'b01) ? i_r1data > i_r2data: 
                 (i_insn[8:7] == 2'b10) ? ($signed(i_r1data) > $signed(i2_inter1)): i_r1data > i2_inter1;
        wire ZP = (i_insn[8:7] == 2'b00) ? ($signed(i_r1data) >= $signed(i_r2data)) :
                  (i_insn[8:7] == 2'b01) ? i_r1data >= i_r2data: 
                  (i_insn[8:7] == 2'b10) ? ($signed(i_r1data) >= $signed(i2_inter1)): i_r1data >= i2_inter1;
        assign output_temp[2] = (P == 1'b1) ? 16'h0001 :
                                (ZP == 1'b1 & P == 1'b0) ? 16'h0000 : 16'hFFFF;

        assign output_temp[3] = 16'h0000;

        assign output_temp[4] = i_insn[11] ? (i_pc & 16'h8000) | (i_insn[10:0] << 4) : i_r1data; 

        wire [15:0] i5_inter = (i_insn[4:3] == 2'b00) ? i_r1data & i_r2data :
                               (i_insn[4:3] == 2'b01) ? ~ i_r1data :
                               (i_insn[4:3] == 2'b10) ? i_r1data | i_r2data : i_r1data ^ i_r2data;
        assign output_temp[5] = i_insn[5] ? i_r1data & {{11{i_insn[4]}}, i_insn[4:0]} : i5_inter;

        assign ain_inter[3] = i_r1data;
        assign bin_inter[3] = {{10{i_insn[5]}}, i_insn[5:0]};
        assign output_temp[6] = sum;
        assign output_temp[7] = sum;

        assign output_temp[8] = i_r1data;

        assign output_temp[9] = {{7{i_insn[8]}}, i_insn[8:0]};

        wire [15:0] SRA = $signed(i_r1data) >>> i_insn[3:0];
        /*
        assign test = (condition) ? (some signed wire) >>> (some number) : some unsigned number, 
        it wont carry the one. This is because the else statement is unsigned and I believe it 
        converts the first statement to an unsigned wire. 
        You can fix this by calculating the signed number before and using $signed() when creating it.
        */
        assign output_temp[10] = (i_insn[5:4] == 2'b00) ? i_r1data << i_insn[3:0] :
                                 (i_insn[5:4] == 2'b01) ? SRA :
                                 (i_insn[5:4] == 2'b10) ? i_r1data >> i_insn[3:0] : remainder;

        assign output_temp[11] = 16'h0000;

        assign cin_inter[2] = i_insn[11];
        assign ain_inter[2] = i_insn[11] ? i_pc : i_r1data;
        assign bin_inter[2] = i_insn[11] ? {{5{i_insn[10]}}, i_insn[10:0]} : 16'h0000;
        assign output_temp[12] = sum;

        assign output_temp[13] = (i_r1data & 16'h00FF) | ({8'h00, i_insn[7:0]} << 8);

        assign output_temp[14] = 16'h0000;

        assign output_temp[15] = 16'h8000 | {8'h00, i_insn[7:0]};

        // ====================== output 16-to-1 mux ==========================//
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
