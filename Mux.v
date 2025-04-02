`timescale 1ns / 1ps

module mux2x1(
input a,b,sel, 
output out
);

assign out = (sel==1)? a:b;
endmodule

module Nbit_2x1mux #(parameter N=8)(
input [N-1:0] a,b,
input sel,
output [N-1:0] out
    );
    assign out = (sel)? b : a;
//    genvar i;
//    generate 
//    for(i=0;i<N;i=i+1)begin 
//        mux2x1 mux(a[i],b[i], sel, out[i] );
//    end
//  endgenerate
    
endmodule

module mux16x1 #(parameter N=32)(
    input [N-1:0] AND,OR,ADD,SUB, // 16-bit input data
    input [3:0] sel,       // 4-bit select signal
    output reg [N-1:0]  out         // Output
);

always @(*) begin
    case(sel)
        4'b0000: out = AND;
        4'b0001: out = OR;
        4'b0010: out = ADD;
        4'b0110: out = SUB;     
        default: out = N-1'b0;  // Default case
    endcase
end
endmodule
