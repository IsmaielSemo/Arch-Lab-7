`timescale 1ns / 1ps


module Processor_TB();
localparam clk_period = 10;



reg clk = 1'b0;
reg reset;
reg [1:0] ledSel;
reg [3:0] ssdSel;
wire [15:0] leds;
wire [12:0] ssd;
    
RISCV_pipeline uut(
  clk, reset, 
   ledSel, 
   ssdSel, 
  leds, 
  ssd
);
 
initial 
    begin
      forever
         #(clk_period /2) clk = ~clk;
    end 
 
initial begin
       
        reset = 1;
        #10 
        reset = 0;
`       #10   
        reset = 1;
        #10   
        reset = 0;
       

    end 
 

endmodule
