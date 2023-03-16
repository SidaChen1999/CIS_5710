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

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)


   /*** YOUR CODE HERE ***/


   //========================================= F ============================================// 
   // pc wires attached to the PC register's ports
   wire [15:0] next_pc;      // Current program counter (read out from pc_reg)
   wire [15:0] pc;            // Next program counter (you compute this and feed it into next_pc)
   wire pc_we;
   assign o_cur_pc = pc;

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(pc_we), .gwe(gwe), .rst(rst));

   wire [15:0] pc_plus_one;
   cla16 adder (.a(pc), .b(16'b1), .cin(1'b0), .sum(pc_plus_one));

   assign next_pc = pc_plus_one;


   //========================================= D ============================================// 
   wire [15:0] D_pc_in;
   wire [15:0] D_pc_out;
   wire [15:0] D_ir_in;
   wire [15:0] D_ir_out;
   wire D_we;
   assign D_pc_in = pc;
   assign D_ir_in = i_cur_insn;

   Nbit_reg #(16, 0) D_pc_reg (.in(D_pc_in), .out(D_pc_out), .clk(clk), .we(D_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) D_ir_reg (.in(D_ir_in), .out(D_ir_out), .clk(clk), .we(D_we), .gwe(gwe), .rst(rst));

   wire [2:0] D_r1sel;    // rs
   wire [2:0] D_r2sel;    // rt
   wire [2:0] D_wsel;     // rd
   wire D_r1re, D_r2re, D_regfile_we, D_select_pc_plus_one, D_is_load, D_is_store, D_is_branch, D_is_control_insn, D_nzp_we ;

   lc4_decoder d_decoder (
      .insn(D_ir_out),                            // instruction///////////////////////// in
      .r1sel(D_r1sel),                            // rs
      .r1re(D_r1re),                              // does this instruction read from rs?
      .r2sel(D_r2sel),                            // rt
      .r2re(D_r2re),                              // does this instruction read from rt?
      .wsel(D_wsel),                              // rd
      .regfile_we(D_regfile_we),                  // does this instruction write to rd?
      .nzp_we(D_nzp_we),                            // does this instruction write the NZP bits?
      .select_pc_plus_one(D_select_pc_plus_one),  // write PC+1 to the regfile?
      .is_load(D_is_load),                        // is this a load instruction?
      .is_store(D_is_store),                      // is this a store instruction?
      .is_branch(D_is_branch),                    // is this a branch instruction?
      .is_control_insn(D_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
   );

   wire [15:0] D_rs_data;//output
   wire [15:0] D_rt_data;//output
   wire [15:0] D_rd_data;////////////////////////////////input
   lc4_regfile regfile (
      .clk(clk),
      .gwe(gwe),
      .rst(rst),
      .i_rs(D_r1sel),        // rs selector
      .o_rs_data(D_rs_data), // rs contents
      .i_rt(D_r2sel),        // rt selector
      .o_rt_data(D_rt_data), // rt contents
      .i_rd(W_wsel),         // rd selector
      .i_wdata(D_rd_data),   // data to write
      .i_rd_we(W_regfile_we) // write enable
   );


   // WD bypass
   assign X_r1data_in = (W_wsel == D_r1sel && W_regfile_we) ? D_rd_data : D_rs_data;
   assign X_r2data_in = (W_wsel == D_r2sel && W_regfile_we) ? D_rd_data : D_rt_data;
   


   //========================================= X ============================================// 
   wire [15:0] X_pc_in;
   wire [15:0] X_pc_out;
   wire [15:0] X_ir_in;
   wire [15:0] X_ir_out;
   wire [15:0] X_r1data_in;
   wire [15:0] X_r1data_out;
   wire [15:0] X_r2data_in;
   wire [15:0] X_r2data_out;
   wire X_we;///////////////////////////////////
   assign X_we = 1'b1;
   assign X_pc_in = D_pc_out;

   Nbit_reg #(16, 0) X_pc_reg (.in(X_pc_in), .out(X_pc_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) X_ir_reg (.in(X_ir_in), .out(X_ir_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) X_r1data_reg (.in(X_r1data_in), .out(X_r1data_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) X_r2data_reg (.in(X_r2data_in), .out(X_r2data_out), .clk(clk), .we(X_we), .gwe(gwe), .rst(rst));

   wire [15:0] X_r1_ALUin;/////////////////// MUX bypass
   wire [15:0] X_r2_ALUin;/////////////////// MUX bypass

   wire [15:0] X_alu_result;
   lc4_alu alu(
      .i_insn(X_ir_out),
      .i_pc(X_pc_out),
      .i_r1data(X_r1_ALUin),
      .i_r2data(X_r2_ALUin),
      .o_result(X_alu_result)
   );

   wire [2:0] X_r1sel;    // rs
   wire [2:0] X_r2sel;    // rt
   wire [2:0] X_wsel;     // rd
   wire X_r1re, X_r2re, X_regfile_we, X_select_pc_plus_one, X_is_load, X_is_store, X_is_branch, X_is_control_insn, X_nzp_we;

   lc4_decoder x_decoder (
      .insn(X_ir_out),                            // instruction///////////////////////// in
      .r1sel(X_r1sel),                            // rs
      .r1re(X_r1re),                              // does this instruction read from rs?
      .r2sel(X_r2sel),                            // rt
      .r2re(X_r2re),                              // does this instruction read from rt?
      .wsel(X_wsel),                              // rd
      .regfile_we(X_regfile_we),                  // does this instruction write to rd?
      .nzp_we(X_nzp_we),                            // does this instruction write the NZP bits?
      .select_pc_plus_one(X_select_pc_plus_one),  // write PC+1 to the regfile?
      .is_load(X_is_load),                        // is this a load instruction?
      .is_store(X_is_store),                      // is this a store instruction?
      .is_branch(X_is_branch),                    // is this a branch instruction?
      .is_control_insn(X_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
   );

   // ===================================== M =======================================// 
   wire [15:0] M_O_in;
   wire [15:0] M_O_out;
   wire [15:0] M_r2data_in;
   wire [15:0] M_r2data_out;
   wire [15:0] M_ir_in;
   wire [15:0] M_ir_out;
   wire [15:0] M_pc_in;
   wire [15:0] M_pc_out;
   wire M_we;

   assign M_we = 1'b1;
   assign M_pc_in = X_pc_out;
   assign M_r2data_in = X_r2_ALUin;////////////////////////////////////////////////////
   assign M_ir_in = X_ir_out;
   assign M_O_in = X_alu_result;
   assign o_dmem_addr = (M_is_load | M_is_store) ? M_O_out : 0; 
   assign o_dmem_we = M_is_store;

   Nbit_reg #(16, 0) M_O_reg (.in(M_O_in), .out(M_O_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) M_r2data_reg (.in(M_r2data_in), .out(M_r2data_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) M_ir_reg (.in(M_ir_in), .out(M_ir_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) M_pc_reg (.in(M_pc_in), .out(M_pc_out), .clk(clk), .we(M_we), .gwe(gwe), .rst(rst));

   wire [2:0] M_r1sel;    // rs
   wire [2:0] M_r2sel;    // rt
   wire [2:0] M_wsel;     // rd
   wire M_r1re, M_r2re, M_regfile_we, M_select_pc_plus_one, M_is_load, M_is_store, M_is_branch, M_is_control_insn, M_nzp_we;

   lc4_decoder m_decoder (
      .insn(M_ir_out),                            // instruction///////////////////////// in
      .r1sel(M_r1sel),                            // rs
      .r1re(M_r1re),                              // does this instruction read from rs?
      .r2sel(M_r2sel),                            // rt
      .r2re(M_r2re),                              // does this instruction read from rt?
      .wsel(M_wsel),                              // rd
      .regfile_we(M_regfile_we),                  // does this instruction write to rd?
      .nzp_we(M_nzp_we),                            // does this instruction write the NZP bits?
      .select_pc_plus_one(M_select_pc_plus_one),  // write PC+1 to the regfile?
      .is_load(M_is_load),                        // is this a load instruction?
      .is_store(M_is_store),                      // is this a store instruction?
      .is_branch(M_is_branch),                    // is this a branch instruction?
      .is_control_insn(M_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
   );



   // ===================================== W =======================================// 
   wire [15:0] W_O_in;
   wire [15:0] W_O_out;
   wire [15:0] W_D_in;
   wire [15:0] W_D_out;
   wire [15:0] W_ir_in;
   wire [15:0] W_ir_out;
   wire [15:0] W_pc_in;
   wire [15:0] W_pc_out;
   wire W_we;

   assign W_O_in = M_O_out;
   assign W_D_in = i_cur_dmem_data;
   assign W_ir_in = M_ir_out;
   assign W_we = 1'b1;
   assign W_pc_in = M_pc_out;

   Nbit_reg #(16, 0) W_ir_reg (.in(W_ir_in), .out(W_ir_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) W_O_reg (.in(W_O_in), .out(W_O_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) W_D_reg (.in(W_D_in), .out(W_D_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));
   Nbit_reg #(16, 0) W_pc_reg (.in(W_pc_in), .out(W_pc_out), .clk(clk), .we(W_we), .gwe(gwe), .rst(rst));

   wire [2:0] W_r1sel;    // rs
   wire [2:0] W_r2sel;    // rt
   wire [2:0] W_wsel;     // rd
   wire W_r1re, W_r2re, W_regfile_we, W_select_pc_plus_one, W_is_load, W_is_store, W_is_branch, W_is_control_insn, W_nzp_we;

   lc4_decoder w_decoder (
      .insn(W_ir_out),                            // instruction///////////////////////// in
      .r1sel(W_r1sel),                            // rs
      .r1re(W_r1re),                              // does this instruction read from rs?
      .r2sel(W_r2sel),                            // rt
      .r2re(W_r2re),                              // does this instruction read from rt?
      .wsel(W_wsel),                              // rd
      .regfile_we(W_regfile_we),                  // does this instruction write to rd?
      .nzp_we(W_nzp_we),                            // does this instruction write the NZP bits?
      .select_pc_plus_one(W_select_pc_plus_one),  // write PC+1 to the regfile?
      .is_load(W_is_load),                        // is this a load instruction?
      .is_store(W_is_store),                      // is this a store instruction?
      .is_branch(W_is_branch),                    // is this a branch instruction?
      .is_control_insn(W_is_control_insn)         // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
   );

   // =============== RD data ==================//

   assign D_rd_data = W_is_load ? W_D_out : W_O_out;

   //============== WX & MX  Bypass ============//   
   wire [1:0]r1_Bypass;
   wire [1:0]r2_Bypass;
   assign r1_Bypass = (X_r1sel == M_wsel && M_regfile_we) ? 2'd0 :
                        (X_r1sel == W_wsel && W_regfile_we) ? 2'd1 : 2'd2 ;

   assign r2_Bypass = (X_r2sel == M_wsel && M_regfile_we) ? 2'd0 :
                        (X_r2sel == W_wsel && W_regfile_we) ? 2'd1 : 2'd2 ;


   assign X_r1_ALUin = (r1_Bypass == 2'd0) ? M_O_out :
                        (r1_Bypass == 2'd1) ? D_rd_data : X_r1data_out;
   assign X_r2_ALUin = (r2_Bypass == 2'd0) ? M_O_out :
                        (r2_Bypass == 2'd1) ? D_rd_data : X_r2data_out;

   
   /*** WM  Bypass ***/
   wire WM_Bypass;
   assign WM_Bypass = W_is_load && M_is_store && (W_wsel == M_r2sel);
   assign o_dmem_towrite = (WM_Bypass) ? D_rd_data : M_r2data_out;

   /*** Load to use ***/
   wire Stall;
   assign Stall = X_is_load && ( (D_r1sel == X_wsel) || ((D_r2sel == X_wsel) && D_is_store) );

   assign pc_we = !Stall;
   assign D_we = !Stall; 
   assign X_ir_in = (Stall) ? 16'b0 : D_ir_out;

   
   // ===================================
   wire [2:0] NZP =   (D_rd_data[15] == 1'b1) ? 3'b100 :
                  (| D_rd_data) ? 3'b001 : 3'b10;

   // ====================== Testbench signals ==========================//
   assign test_stall = (W_pc_out == 16'd0) ? 2'd2 : 
                        Stall ? 2'd3 : 2'd0; 
   assign test_cur_pc = W_pc_out; 
   assign test_cur_insn = W_ir_out;
   assign test_regfile_we = W_regfile_we;
   assign test_regfile_wsel = W_wsel;
   assign test_regfile_data = D_rd_data; ////////////////
   assign test_nzp_we = 1'b1;
   assign test_nzp_new_bits = NZP;
   assign test_dmem_we = W_is_store;
   assign test_dmem_addr = o_dmem_addr; ///////////////
   // assign test_dmem_data = M_is_load ? i_cur_dmem_data : o_dmem_towrite;   /////////////
   assign test_dmem_data = 16'd0;

   // ====================== Output signals ==========================//






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
