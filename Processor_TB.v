
`timescale 1ns / 1ps

module tb_RISCV_pipeline();

    // Inputs to the pipeline
    reg clk;
    reg reset;
    reg [1:0] ledSel;
    reg [3:0] ssdSel;

    // Outputs from the pipeline
    wire [15:0] leds;
    wire [12:0] ssd;

    // Instantiate the RISCV_pipeline module
    RISCV_pipeline uut (
        .clk(clk),
        .reset(reset),
//        .ledSel(ledSel),
//        .ssdSel(ssdSel),
//        .leds(leds),
//        .ssd(ssd)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;  // 100MHz clock (10ns period)
    end

    // Stimulus process
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 0;
//        ledSel = 2'b00;
//        ssdSel = 4'b0000;

        // Apply reset
        reset = 1;
        #10 reset = 0; // Release reset after 10ns

        // Monitor the output PC
        $display("Simulation Start: Checking PC updates...");

        // Simulate for some time, check for PC progression
        #10;
        
//        // Change ledSel and ssdSel to observe different outputs
//        ledSel = 2'b01;
//        ssdSel = 4'b0010;
//        #10;
        
//        ledSel = 2'b10;
//        ssdSel = 4'b0100;
//        #10;
        
        // End simulation
        $finish;
    end

    // Monitor the PC and other signals
    initial begin
        $monitor("Time: %t, PC: %h, leds: %h, ssd: %h", $time, uut.PC_out);
    end

endmodule
