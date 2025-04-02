`timescale 1ns / 1ps


`timescale 1ns / 1ps

module Nbit_shift_left #(parameter N=8)(
input [N-1:0] a,
output [N-1:0] out
    );
    
    assign out = {a[N-2:0], 1'b0};
    
endmodule
