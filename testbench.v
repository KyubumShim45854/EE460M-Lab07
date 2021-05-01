`timescale 1ns / 1ps

// You can use this skeleton testbench code, the textbook testbench code, or your own
module mips_testbench; 
reg CLK; 
wire CS, WE; 
parameter N = 10; 
reg[31:0] expected[N:1]; 
wire[6:0] Address, Address_Mux;
wire [31:0] Mem_Bus_Wire; 
reg[6:0] AddressTB; 
wire WE_Mux, CS_Mux; 
reg init, rst, WE_TB, CS_TB; 
integer i; 
wire[7:0] OUT;
wire [6:0] PCTOP;
reg [2:0] CTRL;
wire [31:0] S2;
wire [31:0] S4,S5,S6,S31;

MIPSB CPU(CLK, rst, CS, WE, Address, Mem_Bus_Wire,OUT,PCTOP,S2,CTRL,S4,S5,S6,S31); 
MemoryB MEM(CS_Mux, WE_Mux, CLK, Address_Mux, Mem_Bus_Wire); 
assign Address_Mux = (init)? AddressTB : Address; 
assign WE_Mux = (init)? WE_TB : WE; 
assign CS_Mux = (init)? CS_TB : CS; 
always #10 CLK = ~CLK; 
initial begin expected[1] = 32'h00000006;
 // $1 content=6 decimal 
 expected[2] = 32'h00000012; // $2 content=18 dec

  expected[3] = 32'h00000018; // $3 content=24 decimal 
  expected[4] = 32'h0000000C; // $4 content=12 decimal 
  expected[5] = 32'h00000002; // $5 content=2
  expected[6] = 32'h00000016; // $6 content=22 decimal
  expected[7] = 32'h00000001; // $7 content=1 
  expected[8] = 32'h00000120; // $8 content=288 decimal
   expected[9] = 32'h00000003; // $9 content=3 
   expected[10] = 32'h00412022; // $10 content=5th instr 
   CLK = 0; 
   CTRL = 0;
   #1000
   CTRL = 1;
   #1000
   CTRL = 2;
   #1000
   CTRL = 3;
   #1000 CTRL = 4;
   #1000 CTRL = 5;
   #1000 CTRL = 0;
   
   
   
   end 
   
   always begin 
   rst = 1; 
   @(posedge CLK); //wait until posedge CLK //Initialize the instructions from the testbench 
   init <= 1; 
   CS_TB <= 1;
    WE_TB <= 1; 
    @(posedge CLK);
     CS_TB <= 0; WE_TB <= 0; init <= 0; 
     @(posedge CLK); 
     rst <= 0;
      for(i = 1; i <= N; i = i+1) begin 
      @(posedge WE); // When a store word is executed 
      @(negedge CLK);
       if (Mem_Bus_Wire != expected[i]) 
       $display("Output mismatch: got %d, expect %d", Mem_Bus_Wire,
        expected[i]); 
        end 
        
        $display("Testing Finished:");
         $stop; 
         end
   
   endmodule