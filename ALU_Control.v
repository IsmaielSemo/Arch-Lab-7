`timescale 1ns / 1ps


module ALUControlUnit (
    input [1:0] ALUOp,      
    input [2:0] Inst_14_12,  
    input Inst_30,           
    output reg [3:0] ALU_sel 
);

always @(*) begin

    ALU_sel  = 4'b0000;
    
    case (ALUOp)
        2'b00: ALU_sel  = 4'b0010;  // ADD
        2'b01: ALU_sel  = 4'b0110;  // SUB
        2'b10: begin      
            case (Inst_14_12)
                3'b000: begin     
                    if (Inst_30 == 1'b0) 
                        ALU_sel  = 4'b0010; 
                     else 
                        ALU_sel  = 4'b0110;         
                end
                3'b111:  ALU_sel  = 4'b0000;  // AND         
                3'b110: ALU_sel  = 4'b0001;  // OR

            endcase
        end             
    endcase
end

endmodule