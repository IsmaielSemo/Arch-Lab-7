`timescale 1ns / 1ps


module Register_Reset (
    input clk,                
    input reset,              
    input RegWrite,           
    input [4:0] read_addr1,   
    input [4:0] read_addr2,  
    input [4:0] write_addr,  
    input [31:0] write_data,  
    output [31:0] read_data1, 
    output [31:0] read_data2  
);
    reg [31:0] regFile [31:0]; 
   
    assign read_data1 = regFile[read_addr1];
    assign read_data2 = regFile[read_addr2];
     integer i;
   
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                regFile[i] = 32'b0;
            end
        end
        else if (RegWrite && write_addr != 0) begin
            regFile[write_addr] = write_data;
        end
    end

endmodule