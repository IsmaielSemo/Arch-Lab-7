`timescale 1ns / 1ps


module top(input clk, input reset, input [1:0] ledSel, input [3:0] ssdSel, input SSD_clk, 
output [15:0] leds //, output [12:0] ssd
,output [3:0] Anode,output [6:0] LED_out  
);
    wire  [12:0] ssdin;
     RISCV_pipeline processor(clk,reset,ledSel,ssdSel,leds,ssdin); //originally ssdin
    //assign ssd = ssdin;   // Assign the ssd input from Processor_Lab6 to the top-level output ssd
    Four_Digit_Seven_Segment_Driver ( SSD_clk,  ssdin, Anode ,LED_out);
    
     
       
    
endmodule
