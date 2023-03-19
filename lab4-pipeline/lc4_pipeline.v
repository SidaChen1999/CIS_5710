/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
     
   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   /*** YOUR CODE HERE ***/

   //========================================= F ============================================// 
   // pc wires attached to the PC register's ports
   wire [15:0] F_pc_out;   // Current program counter (read out from pc_reg)
   wire [15:0] F_pc_in;    // Next program counter (you compute this and feed it into next_pc)
   wire pc_we;
   assign o_cur_pc = F_pc_out;

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(F_pc_in), .out(F_pc_out), .clk(clk), .we(pc_we), .gwe(gwe), .rst(rst));

   wire [15:0] pc_plus_one;
   cla16 adder (.a(F_pc_out), .b(16'b1), .cin(1'b0), .sum(pc_plus_one));

   assign F_pc_in = pc_plus_one;

   //========================================= D ============================================// 
   wire [15:0] D_pc_out;
   wire [15:0] D_ir_out;
   wire D_we;

   Nbit_reg #(16, 0) D_pc_reg (.in(F_pc_out), .out(D_pc_out), .clk(clk), .we(D_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) D_ir_reg (.in(i_cur_insn), .out(D_ir_out), .clk(clk), .we(D_we), .gwe(gwe), .rst(rst));

   wire [2:0] D_r1sel;  // rs
   wire [2:0] D_r2sel;  // rt
   wire [2:0] D_wsel;   // rd
   wire D_r1re, D_r2re, D_select_pc_plus_one, D_is_load, D_is_store, D_is_branch, D_is_control_insn, D_nzp_we, D_regfile_we;

   lc4_decoder d_decoder (
      .insn(D_ir_out),                            // instruction in 
      .r1sel(D_r1sel),                            // rs [2:0]
      .r1re(D_r1re),                              // does this instruction read from rs? [3]
      .r2sel(D_r2sel),                            // rt [6:4]
      .r2re(D_r2re),                              // does this instruction read from rt? [7]
      .wsel(D_wsel),                              // rd [10:8]
      .regfile_we(D_regfile_we),                  // does this instruction write to rd? [11]
      .nzp_we(D_nzp_we),                          // does this instruction write the NZP bits? [12]
      .select_pc_plus_one(D_select_pc_plus_one),  // write PC+1 to the regfile? [13]
      .is_load(D_is_load),                        // is this a load instruction? [14]
      .is_store(D_is_store),                      // is this a store instruction? [15]
      .is_branch(D_is_branch),                    // is this a branch instruction? [16]
      .is_control_insn(D_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)? [17]
   );

   wire [17:0] D_ctrl_out = {D_is_control_insn, D_is_branch, D_is_store, D_is_load, D_select_pc_plus_one,
                            D_nzp_we, D_regfile_we, D_wsel, D_r2re, D_r2sel, D_r1re, D_r1sel};

   wire [15:0] D_rs_data; //output
   wire [15:0] D_rt_data; //output
   wire [15:0] W_rd_data; //input
   lc4_regfile regfile (
      .clk(clk),
      .gwe(gwe),
      .rst(rst),
      .i_rs(D_r1sel),        // rs selector
      .o_rs_data(D_rs_data), // rs contents
      .i_rt(D_r2sel),        // rt selector
      .o_rt_data(D_rt_data), // rt contents
      .i_rd(W_wsel),         // rd selector
      .i_wdata(W_rd_data),   // data to write
      .i_rd_we(W_regfile_we) // write enable
   );

   // WD bypass
   assign X_r1data_in = (W_wsel == D_r1sel && W_regfile_we) ? W_rd_data : D_rs_data;
   assign X_r2data_in = (W_wsel == D_r2sel && W_regfile_we) ? W_rd_data : D_rt_data;
   
   //========================================= X ============================================// 
    wire [15:0] X_pc_out;
   wire [15:0] X_ir_in;
   wire [15:0] X_ir_out;
   wire [15:0] X_r1data_in;
   wire [15:0] X_r1data_out;
   wire [15:0] X_r2data_in;
   wire [15:0] X_r2data_out;
   wire [17:0] X_ctrl_out;
   wire X_we = 1'b1;
 
   Nbit_reg #(16, 0) X_pc_reg (.in(D_pc_out), .out(X_pc_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) X_ir_reg (.in(X_ir_in), .out(X_ir_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) X_r1data_reg (.in(X_r1data_in), .out(X_r1data_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) X_r2data_reg (.in(X_r2data_in), .out(X_r2data_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(18, 0) X_ctrl_reg (.in(D_ctrl_out), .out(X_ctrl_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));

   wire [15:0] X_r1_ALUin; // MUX bypass
   wire [15:0] X_r2_ALUin; // MUX bypass

   wire [15:0] X_alu_result;
   lc4_alu alu(
      .i_insn(X_ir_out),
      .i_pc(X_pc_out),
      .i_r1data(X_r1_ALUin),
      .i_r2data(X_r2_ALUin),
      .o_result(X_alu_result)
   );

   wire [2:0] X_r1sel = X_ctrl_out[2:0];    // rs
   wire X_r1re = X_ctrl_out[3];
   wire [2:0] X_r2sel = X_ctrl_out[6:4];    // rt
   wire X_r2re = X_ctrl_out[7];
   wire [2:0] X_wsel = X_ctrl_out[10:8];    // rd
   wire X_regfile_we = X_ctrl_out[11];
   wire X_nzp_we = X_ctrl_out[12];
   wire X_select_pc_plus_one = X_ctrl_out[13];
   wire X_is_load = X_ctrl_out[14];
   wire X_is_store = X_ctrl_out[15];
   wire X_is_branch = X_ctrl_out[16];
   wire X_is_control_insn = X_ctrl_out[17];

   // ===================================== M =======================================// 
   wire [15:0] M_O_out;
   wire [15:0] M_r2data_out;
   wire [15:0] M_ir_out;
   wire [15:0] M_pc_out;
   wire [17:0] M_ctrl_out;
   wire M_we;

   assign M_we = 1'b1;
   assign o_dmem_addr = (M_is_load | M_is_store) ? M_O_out : 0; 
   assign o_dmem_we = M_is_store;

   Nbit_reg #(16, 0) M_O_reg (.in(X_alu_result), .out(M_O_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) M_r2data_reg (.in(X_r2_ALUin), .out(M_r2data_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) M_ir_reg (.in(X_ir_out), .out(M_ir_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) M_pc_reg (.in(X_pc_out), .out(M_pc_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(18, 0) M_ctrl_reg (.in(X_ctrl_out), .out(M_ctrl_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));

   wire [2:0] M_r1sel = M_ctrl_out[2:0];    // rs
   wire M_r1re = M_ctrl_out[3];
   wire [2:0] M_r2sel = M_ctrl_out[6:4];    // rt
   wire M_r2re = M_ctrl_out[7];
   wire [2:0] M_wsel = M_ctrl_out[10:8];    // rd
   wire M_regfile_we = M_ctrl_out[11];
   wire M_nzp_we = M_ctrl_out[12];
   wire M_select_pc_plus_one = M_ctrl_out[13];
   wire M_is_load = M_ctrl_out[14];
   wire M_is_store = M_ctrl_out[15];
   wire M_is_branch = M_ctrl_out[16];
   wire M_is_control_insn = M_ctrl_out[17];

   // ===================================== W =======================================// 
   wire [15:0] W_O_out;
   wire [15:0] W_D_out;
   wire [15:0] W_ir_out;
   wire [15:0] W_pc_out;
   wire [17:0] W_ctrl_out;
   wire W_we = 1'b1;

   Nbit_reg #(16, 0) W_ir_reg (.in(M_ir_out), .out(W_ir_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) W_O_reg (.in(M_O_out), .out(W_O_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) W_D_reg (.in(i_cur_dmem_data), .out(W_D_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) W_pc_reg (.in(M_pc_out), .out(W_pc_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(18, 0) W_ctrl_reg (.in(M_ctrl_out), .out(W_ctrl_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));

   wire [2:0] W_r1sel = W_ctrl_out[2:0];    // rs
   wire W_r1re = W_ctrl_out[3];
   wire [2:0] W_r2sel = W_ctrl_out[6:4];    // rt
   wire W_r2re = W_ctrl_out[7];
   wire [2:0] W_wsel = W_ctrl_out[10:8];    // rd
   wire W_regfile_we = W_ctrl_out[11];
   wire W_nzp_we = W_ctrl_out[12];
   wire W_select_pc_plus_one = W_ctrl_out[13];
   wire W_is_load = W_ctrl_out[14];
   wire W_is_store = W_ctrl_out[15];
   wire W_is_branch = W_ctrl_out[16];
   wire W_is_control_insn = W_ctrl_out[17];

   // =============== RD data ==================//
   assign W_rd_data = W_is_load ? W_D_out : W_O_out;

   //============== WX & MX  Bypass ============//   
   wire [1:0]r1_Bypass;
   wire [1:0]r2_Bypass;
   assign r1_Bypass = (X_r1sel == M_wsel && M_regfile_we) ? 2'd0 :
                        (X_r1sel == W_wsel && W_regfile_we) ? 2'd1 : 2'd2 ;

   assign r2_Bypass = (X_r2sel == M_wsel && M_regfile_we) ? 2'd0 :
                        (X_r2sel == W_wsel && W_regfile_we) ? 2'd1 : 2'd2 ;

   assign X_r1_ALUin = (r1_Bypass == 2'd0) ? M_O_out :
                        (r1_Bypass == 2'd1) ? W_rd_data : X_r1data_out;
   assign X_r2_ALUin = (r2_Bypass == 2'd0) ? M_O_out :
                        (r2_Bypass == 2'd1) ? W_rd_data : X_r2data_out;

   /*** WM  Bypass ***/
   wire WM_Bypass;
   assign WM_Bypass = W_is_load && M_is_store && (W_wsel == M_r2sel);
   assign o_dmem_towrite = (WM_Bypass) ? W_rd_data : M_r2data_out;

   /*** Load to use ***/
   wire Stall;
   assign Stall = X_is_load && ((D_r1sel == X_wsel) || ((D_r2sel == X_wsel) && !D_is_store));

   assign pc_we = !Stall;
   assign D_we = !Stall; 
   assign X_ir_in = (Stall) ? 16'b0 : D_ir_out;
   
   // =================================== BR =============================//
   wire [2:0] NZP =   (W_rd_data[15] == 1'b1) ? 3'b100 :
                  (| W_rd_data) ? 3'b001 : 3'b10;

   // ====================== Testbench signals ==========================//
   assign test_stall = (W_pc_out == 16'd0) ? 2'd2 : 
                        Stall ? 2'd3 : 2'd0; 
   assign test_cur_pc = W_pc_out; 
   assign test_cur_insn = W_ir_out;
   assign test_regfile_we = W_regfile_we;
   assign test_regfile_wsel = W_wsel;
   assign test_regfile_data = W_rd_data;
   assign test_nzp_we = 1'b1;
   assign test_nzp_new_bits = NZP;
   assign test_dmem_we = W_is_store;
   assign test_dmem_addr = o_dmem_addr;
   assign test_dmem_data = 16'd0;

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);
      // pinstr(W_ir_out);
      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      // $display(); 
   end
`endif
endmodule
