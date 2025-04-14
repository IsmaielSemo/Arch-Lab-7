module RISCV_pipeline (
    input clk, reset, 
    input [1:0] ledSel, 
    input [3:0] ssdSel, 
    output reg [15:0] leds, 
    output reg [12:0] ssd
);
    wire [31:0] instruction;
    wire Branch;   // M
    wire Mem;      // M
    wire MemtoReg; // WB
    wire [1:0] ALUOp;  // EX
    wire MemWrite; // M
    wire ALUSrc;   // EX
    wire RegWrite; // WB
    wire [31:0] imm_out;
    wire [31:0] shifted_imm_out;
    wire [31:0] data_in1;
    wire [31:0] data_in2;
    wire zero_flag;
    wire [31:0] ALU_Result;
    wire [3:0] ALU_sel;
    wire [31:0] B;
    wire [31:0] data_final;
    wire [31:0] WriteData;
    wire cout;
    wire [31:0] Sum, add4;
    wire last_sel;
    wire [31:0] PC_out;
    wire [15:0] signals;
    wire [31:0] IF_ID_PC;
    wire [31:0] IF_ID_Inst;
    wire [31:0] ID_EX_PC, ID_EX_RegR1, ID_EX_RegR2, ID_EX_Imm;
    wire [7:0] ID_EX_Ctrl;
    wire [3:0] ID_EX_Func;
    wire [4:0] ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd;
    wire [31:0] EX_MEM_BranchAddOut, EX_MEM_ALU_out, EX_MEM_RegR2; 
    wire [4:0] EX_MEM_Ctrl;
    wire [4:0] EX_MEM_Rd;
    wire EX_MEM_Zero;
    wire [31:0] MEM_WB_Mem_out, MEM_WB_ALU_out;
    wire [1:0] MEM_WB_Ctrl;
    wire [4:0] MEM_WB_Rd;

    // Register for PC with initialization on reset
    reg [31:0] PC_in; // Register for PC input logic

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_in <= 32'd0; // Reset PC to 0
        end else begin
            PC_in <= (last_sel) ? EX_MEM_BranchAddOut : add4; // Normal PC or branch PC
         // PC_in <= (last_sel) ?  add4 : EX_MEM_BranchAddOut; // Normal PC or branch PC  
        end
    end

    // Instantiate 32-bit Program Counter Register
    NbitRegister #(32) PC (
        .D(PC_in), 
        .rst(reset), 
        .load(1'b1), 
        .clk(clk), 
        .Q(PC_out)
    );

    InstMem Inst (
        .offset(PC_out[7:2]), 
        .data_out(instruction)
    );

    // Pipeline Register IF/ID
    NbitRegister #(64) IF_ID (
        .D({PC_out, instruction}),
        .rst(reset),
        .load(1'b1),
        .clk(clk),
        .Q({IF_ID_PC, IF_ID_Inst})
    );

    // Control Unit
    ControlUnit CU (
       IF_ID_Inst[6:2] ,
       Branch,  
       MemRead,  
       MemtoReg,  
       ALUOp,    
       MemWrite,  
       ALUSrc,  
       RegWrite
    );

    // Immediate Generator
    ImmGen imm (
        imm_out,
        IF_ID_Inst
    );

    // Register File
    Register_Reset RF(
        clk,
        reset,
        MEM_WB_Ctrl[0],
        IF_ID_Inst [19:15],
        IF_ID_Inst [24:20],
        MEM_WB_Rd,
        WriteData,
        data_in1,
        data_in2); 

    // Pipeline Register ID/EX
    NbitRegister #(200) ID_EX (
        .D({IF_ID_PC, data_in1, data_in2, imm_out, IF_ID_Inst[30], IF_ID_Inst[14:12], IF_ID_Inst[19:15], IF_ID_Inst[24:20], IF_ID_Inst[11:7], Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite}),
        .rst(reset),
        .load(1'b1),
        .clk(clk),
        .Q({ID_EX_PC, ID_EX_RegR1, ID_EX_RegR2, ID_EX_Imm, ID_EX_Func, ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd, ID_EX_Ctrl})
    );

    // ALU Control
    ALUControlUnit ALUcontrol (
        ID_EX_Ctrl[4:3],
        ID_EX_Func[2:0],
        ID_EX_Func[3],
        ALU_sel
    );

    // ALU Unit
    
     Nbit_2x1mux #(32) ALU_2ndInput (
        ID_EX_RegR2,
        ID_EX_Imm,
        ID_EX_Ctrl[1],
        B
    );
    NBitALU #(32) ALU(
        clk,
        ID_EX_RegR1,
        B,
        ALU_sel,
        ALU_Result,
        zero_flag
    );
    
        Nbit_shift_left #(32) shift (
        ID_EX_Imm,
        shifted_imm_out
    );
    
        N_bit_adder #(32) add2 (
        shifted_imm_out,
        ID_EX_PC,
        Sum
    );

    // Pipeline Register EX/MEM
    NbitRegister #(107) EX_MEM (
        .D({Sum, ALU_Result, zero_flag, ID_EX_RegR2, ID_EX_Rd, ID_EX_Ctrl[5]/*Memtoreg*/, ID_EX_Ctrl[0]/*Regwrite*/, ID_EX_Ctrl[7]/*Branch*/, ID_EX_Ctrl[6]/*MemRead*/, ID_EX_Ctrl[2]/*Memwrite*/}),
        .rst(reset),
        .load(1'b1),
        .clk(clk),
        .Q({EX_MEM_BranchAddOut, EX_MEM_ALU_out, EX_MEM_Zero, EX_MEM_RegR2, EX_MEM_Rd, EX_MEM_Ctrl})
    );

    // Data Memory
    DataMem data_mem (
        clk,
        EX_MEM_Ctrl[1],
        EX_MEM_Ctrl[0],
        EX_MEM_ALU_out[7:2],
        EX_MEM_RegR2,
        data_final
    );

    // Pipeline Register MEM/WB
    NbitRegister #(200) MEM_WB (
        .D({data_final, EX_MEM_ALU_out, EX_MEM_Rd, EX_MEM_Ctrl[4], EX_MEM_Ctrl[3]}),
        .rst(reset),
        .load(1'b1),
        .clk(clk),
        .Q({MEM_WB_Mem_out, MEM_WB_ALU_out, MEM_WB_Rd, MEM_WB_Ctrl})
    );

    // Multiplexer for Write Data (from ALU or memory)
    Nbit_2x1mux #(32) mux2 (
        EX_MEM_ALU_out,
        MEM_WB_Mem_out,
        MEM_WB_Ctrl[1],
        WriteData
    );

    // Branch Address Calculation


    // PC Update Calculation
    N_bit_adder #(32) add1 (
        32'd4,
        PC_out,
        add4
    );



    // Branch Selection
    assign last_sel = EX_MEM_Zero & EX_MEM_Ctrl[2];
//    Nbit_2x1mux #(32) mux3(
//        add4,
//        EX_MEM_BranchAddOut,
//        last_sel,
//        PC_in
//    );

    // LEDs and SSD Output Logic
    assign signals = {2'b00, ALUOp, ALU_Result, zero_flag, last_sel, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite};
    always @(*) begin
        case(ledSel)
            2'b00: leds = IF_ID_Inst[15:0];
            2'b01: leds = IF_ID_Inst[31:16];
            2'b10: leds = signals;
            2'b11: leds = 15'd0;
        endcase
    end 

    always @(*) begin
        case(ssdSel)
            4'b0000: ssd = IF_ID_PC;
            4'b0001: ssd = add4;
            4'b0010: ssd = Sum;
            4'b0011: ssd = PC_in;
            4'b0100: ssd = ID_EX_RegR1;
            4'b0101: ssd = ID_EX_RegR2;
            4'b0110: ssd = WriteData;
            4'b0111: ssd = ID_EX_Imm;
            4'b1000: ssd = shifted_imm_out;
            4'b1001: ssd = B;
            4'b1010: ssd = ALU_Result;
            4'b1011: ssd = data_final;
            default: ssd = 13'd0;
        endcase
    end

endmodule
