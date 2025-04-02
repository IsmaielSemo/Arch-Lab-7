`timescale 1ns / 1ps

module Processor_Lab6(input clk,reset,  input [1:0] ledSel,
    input [3:0] ssdSel,
    output reg [15:0] leds, output reg [12:0] ssd );

    wire [31:0] instruction;
    wire Branch;
    wire Mem;
    wire MemtoReg;
    wire [1:0] ALUOp;
    wire MemWrite;
    wire ALUSrc;
    wire RegWrite;
    wire [31:0] imm_out;
    wire [31:0] shifted_imm_out;
    wire [31:0] data_in1;
    wire [31:0] data_in2;
    wire zero_flag;
    wire [31:0] ALU_Result;
    wire  [3:0] ALU_sel;
    wire [31:0] B;
    wire [31:0] data_final;
    wire [31:0] WriteData;
    wire [31:0] PC_in;
    wire cout;
    wire [31:0] Sum, add4;
    wire last_sel;
    wire [31:0] PC_out;
    wire [15:0] signals;
    
    N_Bit_ResetLoad_Register #(32) PC( PC_in , reset, 1'b1, clk, PC_out);
    InstMem Inst ( PC_out[7:2] ,  instruction); //why is PC from 7:2 that's 6 not 5 bits
    ControlUnit CU(instruction [6:2], Branch,  MemRead,  MemtoReg,   ALUOp,    MemWrite, ALUSrc,  RegWrite); //why 6:2 not 6:0 as in the figure (og was 6:2)
    ImmGen imm (imm_out, instruction);
            
    Register_Reset RF(clk,reset,RegWrite,instruction [19:15], instruction [24:20], instruction [11:7], WriteData, data_in1, data_in2); //should data_in1 and data_in2 be outputs or inputs (refer to RF module and change over there if necessary)
    Nbit_2x1mux #(32) MUX(data_in2,imm_out,ALUSrc,B);
    ALUControlUnit ALUcontrol(ALUOp,instruction[14:12],instruction[30],ALU_sel); 
    NBitALU #(32) ALU(clk,data_in1,B, ALU_sel,ALU_Result,zero_flag);
    //Nbit_2x1mux #(32) mux1(ALU_Result,data_in2,MemtoReg,B);
    DataMem data_mem(clk,MemRead,MemWrite,ALU_Result[7:2] ,data_in2 ,data_final);//why ALU_Result [7:2]
    Nbit_2x1mux #(32) mux2(ALU_Result,data_final,MemtoReg, WriteData);
    
    Nbit_shift_left #(32) shift(imm_out,shifted_imm_out);
    N_bit_adder #(32) add1( 32'd4 , PC_out, add4 );
    N_bit_adder #(32) add2( shifted_imm_out, PC_out, Sum);
    
    assign last_sel = zero_flag & Branch;
    
    Nbit_2x1mux #(32) mux3(add4,Sum, last_sel,PC_in);
    
    
    assign signals ={2'b00,ALUOp,ALU_Result,zero_flag,last_sel,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite};
    always@(*)begin
    case(ledSel)
    2'b00:leds =instruction[15:0];
    2'b01:leds =instruction[31:16];
    2'b10:leds =signals;
    2'b11:leds =15'd0;
    endcase 
    end 
    
     always @(*) begin
            case(ssdSel)
                4'b0000: ssd = PC_out;               
                4'b0001: ssd = add4;       
                4'b0010: ssd = Sum;    
                4'b0011: ssd = PC_in;            
                4'b0100: ssd = data_in1;     
                4'b0101: ssd = data_in1;     
                4'b0110: ssd = WriteData;           
                4'b0111: ssd = imm_out;     
                4'b1000: ssd = shifted_imm_out;   
                4'b1001: ssd = B;     
                4'b1010: ssd = ALU_Result;      
                4'b1011: ssd = data_final;          
                default: ssd = 13'd0;                  
            endcase
        end
    
    //    always @(*) begin
    //        leds = {ledSel, 14'b0};  
    //    end
        
        
endmodule
