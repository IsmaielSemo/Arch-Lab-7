`timescale 1ns / 1ps



module ImmGen (output [31:0] gen_out, input [31:0] inst);

reg [11:0] imm;
wire sign_bit;
always @(*)begin
    if(inst[6:5] == 2'b00) begin //LW
    imm = inst[31:20];         
    end
    else if(inst[6:5] == 2'b01) begin //SW
    imm = {inst[31:25], inst[11:7]}; //7+5=12
    end 
    else if(inst[5] == 1'b1) begin //BEQ
    imm = {inst[31], inst[7], inst[30:25],inst[11:8]}; //1+1+6+4=12
    end
end

    assign sign_bit = inst[31];
    assign gen_out = (sign_bit == 0)? {20'b0, imm}:
    {20'b11111111111111111111 , imm};
    

endmodule
