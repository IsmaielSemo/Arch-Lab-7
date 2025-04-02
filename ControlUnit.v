`timescale 1ns / 1ps

module ControlUnit ( //Inst was originally from 4:0
    input [4:0] Inst,          
    output reg Branch,        
    output reg MemRead,       
    output reg MemtoReg,      
    output reg [1:0] ALUOp,   
    output reg MemWrite,      
    output reg ALUSrc,        
    output reg RegWrite       
);

always @(*) begin
   
    Branch = 0;
    MemRead = 0;
    MemtoReg = 0;
    ALUOp = 2'b00;            
    MemWrite = 0;
    ALUSrc = 0;
    RegWrite = 0;

    case (Inst)
        5'b01100: begin  //originally 5'b01100
            Branch = 0;
            MemRead = 0;
            MemtoReg = 0;
            ALUOp = 2'b10;   
            MemWrite = 0;
            ALUSrc = 0;
            RegWrite = 1;    
        end

        5'b00000: begin  //originally 5'b00000
            Branch = 0;
            MemRead = 1;
            MemtoReg = 1;    
            ALUOp = 2'b00;   
            MemWrite = 0;
            ALUSrc = 1;     
            RegWrite = 1;    
        end

        5'b01000: begin  //originally 5'b01000
            Branch = 0;
            MemRead = 0;
            MemtoReg = 1'bx;   
            ALUOp = 2'b00;  
            MemWrite = 1;    
            ALUSrc = 1;     
            RegWrite = 0;    
        end

        5'b11000: begin  //originally 11000
            Branch = 1;  
            MemRead = 0;
            MemtoReg = 1'bx;    
            ALUOp = 2'b01;   
            MemWrite = 0;
            ALUSrc = 0;      
            RegWrite = 0;   
        end

        default: begin
           
            Branch = 0;
            MemRead = 0;
            MemtoReg = 0;
            ALUOp = 2'b00;
            MemWrite = 0;
            ALUSrc = 0;
            RegWrite = 0;
        end
    endcase
end

endmodule