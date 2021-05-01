`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/28/2021 04:24:57 PM
// Design Name: 
// Module Name: MIPS
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module Complete_MIPSB(CLK, RST, A_Out, D_Out,OUT,PCtop,S2,CTRL,S4,S5,S6);
  // Will need to be modified to add functionality
  input CLK;
  input RST;
  input [2:0] CTRL;
  output [6:0] A_Out;
  output [31:0] S6,S4,S5;
  output [31:0] D_Out;
  output OUT;
  output [6:0] PCtop;
  output [31:0] S2;
  
 
  
  wire [31:0] S2w;
  wire [31:0] s6,s4,s5;
   assign S2 = S2w;
   assign S4 = s4;
   assign S5 = s5;
   assign S6 = s6;
  wire CS, WE;
  wire [6:0] ADDR;
  wire [31:0] Mem_Bus;
  wire [7:0] OUTy;
  wire PCnew;
  assign PCnew = PC;
  assign PCtop = PCnew;
  assign OUT = OUTy;

  MIPSB CPU(CLK, RST, CS, WE, ADDR, Mem_Bus,OUTy,PC,S2w,CTRL,s4,s5,s6);
  MemoryB MEM(CS, WE, CLK, ADDR, Mem_Bus);

endmodule

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

module MemoryB(CS, WE, CLK, ADDR, Mem_Bus);
  input CS;
  input WE;
  input CLK;
  input [6:0] ADDR;
  inout [31:0] Mem_Bus;

  reg [31:0] data_out;
  reg [31:0] RAM [0:127];
  integer i;


  initial
  begin
    /* Write your Verilog-Text IO code here */
    for(i=0; i<128; i = i+1)
        begin
            RAM[i] = 32'd0; // init all locations to 0
        end
        $readmemh("mylab7test.txt", RAM);
        // read init values from a file
    
  end

  assign Mem_Bus = ((CS == 1'b0) || (WE == 1'b1)) ? 32'bZ : data_out;

  always @(negedge CLK)
  begin

    if((CS == 1'b1) && (WE == 1'b1))
      RAM[ADDR] <= Mem_Bus[31:0];

    data_out <= RAM[ADDR];
  end
endmodule

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

module REGB(CLK, RegW, DR, SR1, SR2, Reg_In, ReadReg1, ReadReg2, OUT,S2,CTRL,S4,S5,S6);
  input CLK;
  input RegW;
  input [2:0] CTRL;
  input [4:0] DR;
  input [4:0] SR1;
  input [4:0] SR2;
  input [31:0] Reg_In;
  output reg [31:0] ReadReg1;
  output reg [31:0] ReadReg2;
  output [7:0] OUT;
  output [31:0] S2;
  output [31:0] S6,S4,S5;

  reg [31:0] REG [0:31];
  integer i;
  
  assign OUT = REG[1][7:0];
  assign S2 = REG[2];
  assign S5 = REG[5];
  assign S6 = REG[6];
  assign S4 = REG[4];
 
  

  initial begin
    ReadReg1 = 0;
    ReadReg2 = 0;
  end

  always @(posedge CLK)
  begin
  REG[1] = {29'd0,CTRL};

    if(RegW == 1'b1)
      REG[DR] <= Reg_In[31:0];

    ReadReg1 <= REG[SR1];
    ReadReg2 <= REG[SR2];
  end
endmodule


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

`define opcode instr[31:26]
`define sr1 instr[25:21]
`define sr2 instr[20:16]
`define f_code instr[5:0]
`define numshift instr[10:6]

module MIPSB (CLK, RST, CS, WE, ADDR, Mem_Bus, OUT,programcounter,S2,CTRL,S4,S5,S6);
  input CLK, RST;
  input [2:0] CTRL;
  output reg CS, WE;
  output [6:0] ADDR;
  inout [31:0] Mem_Bus;
  output [7:0] OUT;
  output [6:0] programcounter;
  output[31:0] S2;
  output[31:0] S4,S5,S6;
 
  //special instructions (opcode == 000000), values of F code (bits 5-0):
  parameter add = 6'b100000;
  parameter sub = 6'b100010;
  parameter xor1 = 6'b100110;
  parameter and1 = 6'b100100;
  parameter or1 = 6'b100101;
  parameter slt = 6'b101010;
  parameter srl = 6'b000010;
  parameter sll = 6'b000000;
  parameter jr = 6'b001000;
  parameter rbit = 6'b101111;
  parameter rev = 6'b110000;
  parameter add8 = 6'b101101;
  parameter sadd = 6'b110001;
  parameter ssub = 6'b110010;
  parameter lu1 = 6'b110011;

  //non-special instructions, values of opcodes:
  parameter addi = 6'b001000;
  parameter andi = 6'b001100;
  parameter ori = 6'b001101;
  parameter lw = 6'b100011;
  parameter sw = 6'b101011;
  parameter beq = 6'b000100;
  parameter bne = 6'b000101;
  parameter j = 6'b000010;
  parameter jal = 6'b000011;
  parameter lui = 6'b001111;

  //instruction format
  parameter R = 2'd0;
  parameter I = 2'd1;
  parameter J = 2'd2;

  //internal signals
  reg [5:0] op, opsave;
  wire [1:0] format;
  reg [31:0] instr, alu_result;
  reg [6:0] pc, npc;
  assign programcounter = pc;
  wire [31:0] imm_ext, alu_in_A, alu_in_B, reg_in, readreg1, readreg2;
  reg [31:0] alu_result_save;
  reg [32:0] sadboy;
  reg alu_or_mem, alu_or_mem_save, regw, writing, reg_or_imm, reg_or_imm_save;
  reg fetchDorI;
  wire [4:0] dr;
  integer i;
  reg [2:0] state, nstate;
  // my code ////////////////////////////////////////////////////////////////////////////////////////////////
  wire [7:0] OUTy;
  wire [31:0] S2y;
  wire [31:0] s4,s5,s6;
  assign S4 = s4;
  assign S5 = s5;
  assign S6 = s6;
  assign OUT = OUTy;
  assign S2 = S2y;
  
  // end of my code /////////////////////////////////////////////////////////////////////////////////////////////

  //combinational
  assign imm_ext = (instr[15] == 1)? {16'hFFFF, instr[15:0]} : {16'h0000, instr[15:0]};//Sign extend immediate field
  assign dr = (`opcode == 6'd3)? 5'b11111 :((format == R)? instr[15:11] : instr[20:16]); //Destination Register MUX (MUX1)
  assign alu_in_A = readreg1;
  assign alu_in_B = (reg_or_imm_save)? imm_ext : readreg2; //ALU MUX (MUX2)
  assign reg_in = (`opcode == 6'd3)? pc+1 : ((alu_or_mem_save)? Mem_Bus : alu_result_save); //Data MUX
  assign format = (`opcode == 6'd0)? R : ((`opcode == 6'd2 || `opcode == 6'd3)? J : I);
  assign Mem_Bus = (writing)? readreg2 : 32'bZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;

  //drive memory bus only during writes
  assign ADDR = (fetchDorI)? pc : alu_result_save[6:0]; //ADDR Mux
  REGB Register(CLK, regw, dr, `sr1, `sr2, reg_in, readreg1, readreg2,OUTy,S2y,CTRL,s4,s5,s6);

  initial begin
    op = and1; opsave = and1;
    state = 3'b0; nstate = 3'b0;
    alu_or_mem = 0;
    regw = 0;
    fetchDorI = 0;
    writing = 0;
    reg_or_imm = 0; reg_or_imm_save = 0;
    alu_or_mem_save = 0;
  end

  always @(*)
  begin
    fetchDorI = 0; CS = 0; WE = 0; regw = 0; writing = 0; alu_result = 32'd0;
    npc = pc; op = jr; reg_or_imm = 0; alu_or_mem = 0; nstate = 3'd0;
    case (state)
      0: begin //fetch
        npc = pc + 7'd1; CS = 1; nstate = 3'd1;
        fetchDorI = 1;
      end
      1: begin //decode
        nstate = 3'd2; reg_or_imm = 0; alu_or_mem = 0;
        if (format == J) begin //jump, and finish
          npc = instr[6:0];
          if(`opcode == jal) regw = 1;
          nstate = 3'd0;
        end
        else if (format == R) //register instructions
          op = `f_code;
        else if (format == I) begin //immediate instructions
          reg_or_imm = 1;
          if(`opcode == lw) begin
            op = add;
            alu_or_mem = 1;
          end
          else if ((`opcode == lw)||(`opcode == sw)||(`opcode == addi)) op = add;
          else if ((`opcode == beq)||(`opcode == bne)) begin
            op = sub;
            reg_or_imm = 0;
          end
          else if (`opcode == andi) op = and1;
          else if (`opcode == ori) op = or1;
          else if (`opcode == lui) op = lu1;
        end
      end
      2: begin //execute
        nstate = 3'd3;
        if (opsave == and1) alu_result = alu_in_A & alu_in_B;
        else if (opsave == or1) alu_result = alu_in_A | alu_in_B;
        else if (opsave == add) alu_result = alu_in_A + alu_in_B;
        else if (opsave == lu1) alu_result = {alu_in_B,16'd0};
        else if (opsave == rbit) begin
        for(i=0;i<=31; i=i+1)
            alu_result[i] = alu_in_B[31-i];
           end
        else if (opsave == rev) begin
        alu_result[7:0] = alu_in_B[31:24];
        alu_result[15:8] = alu_in_B[23:16];
        alu_result[23:16] = alu_in_B[15:8];
        alu_result[31:24] = alu_in_B[7:0];
        end
        else if(opsave == add8) begin
        alu_result[7:0] = alu_in_A[7:0] + alu_in_B[7:0];
        alu_result[15:8] = alu_in_A[15:8] + alu_in_B[15:8];
        alu_result[23:16] = alu_in_A[23:16] + alu_in_B[23:16];
        alu_result[31:24] = alu_in_A[31:24] + alu_in_B[31:24];
        end
        else if(opsave == sadd) begin
        sadboy = alu_in_A + alu_in_B;
        if(sadboy[32]) alu_result = 32'hFFFFFFFF;
        else alu_result = alu_in_A + alu_in_B;
        end
        else if(opsave == ssub) begin
        if(alu_in_B > alu_in_A) alu_result = 0;
        else alu_result = alu_in_A - alu_in_B;
        end
        else if (opsave == sub) alu_result = alu_in_A - alu_in_B;
        else if (opsave == srl) alu_result = alu_in_B >> `numshift;
        else if (opsave == sll) alu_result = alu_in_B << `numshift;
        else if (opsave == slt) alu_result = (alu_in_A < alu_in_B)? 32'd1 : 32'd0;
        else if (opsave == xor1) alu_result = alu_in_A ^ alu_in_B;
        if (((alu_in_A == alu_in_B)&&(`opcode == beq)) || ((alu_in_A != alu_in_B)&&(`opcode == bne))) begin
          npc = pc + imm_ext[6:0];
          nstate = 3'd0;
        end
        else if ((`opcode == bne)||(`opcode == beq)) nstate = 3'd0;
        else if (opsave == jr) begin
          npc = alu_in_A[6:0];
          nstate = 3'd0;
        end
      end
      3: begin //prepare to write to mem
        nstate = 3'd0;
        if ((format == R)||(`opcode == addi)||(`opcode == andi)||(`opcode == ori)) regw = 1;
        else if (`opcode == sw) begin
          CS = 1;
          WE = 1;
          writing = 1;
        end
        else if (`opcode == lw) begin
          CS = 1;
          nstate = 3'd4;
        end
      end
      4: begin
        nstate = 3'd0;
        CS = 1;
        if (`opcode == lw) regw = 1;
      end
    endcase
  end //always

  always @(posedge CLK) begin

    if (RST) begin
      state <= 3'd0;
      pc <= 7'd0;
    end
    else begin
      state <= nstate;
      pc <= npc;
    end

    if (state == 3'd0) instr <= Mem_Bus;
    else if (state == 3'd1) begin
      opsave <= op;
      reg_or_imm_save <= reg_or_imm;
      alu_or_mem_save <= alu_or_mem;
    end
    else if (state == 3'd2) alu_result_save <= alu_result;

  end //always

endmodule
