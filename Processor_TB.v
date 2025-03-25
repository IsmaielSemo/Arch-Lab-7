`timescale 1ns / 1ps


module Processor_TB();
localparam clk_period = 10;



reg clk = 1'b0;
reg reset;

RISCV_pipeline  Process(clk, reset);
 
initial 
    begin
      forever
         #(clk_period /2) clk = ~clk;
    end 
 
initial begin
         
       

       
        reset = 1;
        #10 
        reset = 0;

       

    end 
 

endmodule
