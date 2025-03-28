//We might have a problem with the PC as it doesn't count from the start and thus doesn't advance. Consider making it a reg and have an inital block maybe, but that will create other problems as well



module RISCV_pipeline (input clk,reset,  input [1:0] ledSel, input [3:0] ssdSel,  output reg [15:0] leds, output reg [12:0] ssd);
    wire [31:0] instruction;
    wire Branch;// M
    wire Mem; //M
    wire MemtoReg; // WB
    wire [1:0] ALUOp; //EX
    wire MemWrite; // M
    wire ALUSrc; // EX
    wire RegWrite; // WB
    wire [31:0] imm_out;
    wire [31:0] shifted_imm_out;
    wire [31:0] data_in1;
    wire [31:0] data_in2;
    wire zero_flag;
    wire [31:0] ALU_Result;
    wire  [3:0] ALU_sel;
    wire [31:0] B;
    wire [31:0] data_final;
    wire [31:0] WriteData;
    //reg [31:0] PC_in;
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
    wire [31:0] EX_MEM_Rd;
    wire EX_MEM_Zero;
    wire [31:0] MEM_WB_Mem_out, MEM_WB_ALU_out;
    wire [1:0] MEM_WB_Ctrl;
    wire [4:0] MEM_WB_Rd;
    

//    initial begin 
    
//        PC_in = 32'd0;
//    end
    
    NbitRegister #(32) PC( PC_in , reset, 1'b1, clk, PC_out);
    InstMem Inst ( PC_out[7:2] ,  instruction); 
    NbitRegister #(64) IF_ID ({PC_out,instruction}, rst ,1'b1, clk,  {IF_ID_PC,IF_ID_Inst} );
    
    
    ControlUnit CU(IF_ID_Inst [6:2], Branch,  MemRead,  MemtoReg,   ALUOp,    MemWrite, ALUSrc,  RegWrite); 
    ImmGen imm (imm_out, IF_ID_Inst);        
    Register_Reset RF(clk,reset,MEM_WB_Ctrl[0],IF_ID_Inst [19:15], IF_ID_Inst [24:20], IF_ID_Inst [11:7], WriteData, data_in1, data_in2); 
    NbitRegister #(200) ID_EX ({IF_ID_PC,data_in1,data_in2, imm_out, {IF_ID_Inst[30], IF_ID_Inst[14:12]},IF_ID_Inst[19:15], IF_ID_Inst[24:20], IF_ID_Inst[11: 7],{Branch, MemRead, MemtoReg, ALUOp,MemWrite, ALUSrc, RegWrite}}, rst,1'b1, clk,{ID_EX_PC,ID_EX_RegR1,ID_EX_RegR2,ID_EX_Imm, ID_EX_Func,ID_EX_Rs1,ID_EX_Rs2,ID_EX_Rd, ID_EX_Ctrl} );//originally 155
    
    Nbit_2x1mux #(32) MUX(ID_EX_RegR2,ID_EX_Imm,ID_EX_Ctrl[1],B);
//  ALUControlUnit ALUcontrol(ID_EX_Ctrl[4:3],ID_EX_Rs1,ID_EX_Func,ALU_sel); 
    ALUControlUnit ALUcontrol(ID_EX_Ctrl[4:3],ID_EX_Func[2:0],ID_EX_Func[3],ALU_sel); 
    NBitALU #(32) ALU(clk,ID_EX_RegR1,B, ALU_sel,ALU_Result,zero_flag);    
   // ID_EX_Ctrl[5],ID_EX_Ctrl[0], ID_EX_Ctrl[7], ID_EX_Ctrl[6], ID_EX_Ctrl[2]
    NbitRegister #(200) EX_MEM ({Sum, ALU_Result, zero_flag ,ID_EX_RegR2,ID_EX_Rd, {ID_EX_Ctrl[5],ID_EX_Ctrl[0], ID_EX_Ctrl[7], ID_EX_Ctrl[6], ID_EX_Ctrl[2]}}, rst, 1'b1, clk , {EX_MEM_BranchAddOut, EX_MEM_ALU_out, EX_MEM_Zero, EX_MEM_RegR2, EX_MEM_Rd, EX_MEM_Ctrl}); //originally 107
    //wire [...] MEM_WB_Mem_out, MEM_WB_ALU_out;
    
    
    //order of control signals after EX_MEM is: MemtoReg RegWrite Branch MemRead MemWrite 
    
    
    //DataMem data_mem(clk,MemRead,MemWrite,EX_MEM_ALU_out[7:2] ,EX_MEM_RegR2 ,data_final);
    DataMem data_mem(clk,EX_MEM_Ctrl[1],EX_MEM_Ctrl[0],EX_MEM_ALU_out[7:2] ,EX_MEM_RegR2 ,data_final);
    //EX_MEM_Ctrl[5], EX_MEM_Ctrl[0]
    NbitRegister #(200) MEM_WB ({data_final,EX_MEM_ALU_out[7:2],EX_MEM_Rd, {EX_MEM_Ctrl[4], EX_MEM_Ctrl[0]}} ,rst,1'b1, clk , {MEM_WB_Mem_out, MEM_WB_ALU_out, MEM_WB_Rd, MEM_WB_Ctrl} ); //originally 45
    
    //order of control signals after MEM_WB is: MemtoReg RegWrite
    
    Nbit_2x1mux #(32) mux2(EX_MEM_ALU_out,MEM_WB_Mem_out,MEM_WB_Ctrl[1], WriteData);
    
    //Nbit_shift_left #(32) shift(imm_out,shifted_imm_out);
    Nbit_shift_left #(32) shift(ID_EX_Imm,shifted_imm_out);
    //N_bit_adder #(32) add1( 32'd4 , PC_out, add4 );
    N_bit_adder #(32) add1( 32'd4 , PC_out, add4 );
    N_bit_adder #(32) add2(shifted_imm_out, ID_EX_PC, Sum);
    //assign last_sel = zero_flag & Branch;
    //assign last_sel = EX_MEM_Zero & ID_EX_Ctrl[7];
    assign last_sel = EX_MEM_Zero & EX_MEM_Ctrl[2];
    //Nbit_2x1mux #(32) mux3(add4,Sum, last_sel,PC_in);
    
    Nbit_2x1mux #(32) mux3(add4,EX_MEM_BranchAddOut,last_sel,PC_in);
    
//    assign signals ={2'b00,ALUOp,ALU_Result,zero_flag,last_sel,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite};
//    always@(*)begin
//    case(ledSel)
//    2'b00:leds =IF_ID_Inst[15:0];
//    2'b01:leds =IF_ID_Inst[31:16];
//    2'b10:leds =signals;
//    2'b11:leds =15'd0;
//    endcase 
//    end 
    
//     always @(*) begin
//            case(ssdSel)
//                4'b0000: ssd = PC_out;               
//                4'b0001: ssd = add4;       
//                4'b0010: ssd = Sum;    
//                4'b0011: ssd = PC_in;            
//                4'b0100: ssd = data_in1;     
//                4'b0101: ssd = data_in1;     
//                4'b0110: ssd = WriteData;           
//                4'b0111: ssd = imm_out;     
//                4'b1000: ssd = shifted_imm_out;   
//                4'b1001: ssd = B;     
//                4'b1010: ssd = ALU_Result;      
//                4'b1011: ssd = data_final;          
//                default: ssd = 13'd0;                  
//            endcase
//        end

assign signals ={2'b00,ALUOp,ALU_Result,zero_flag,last_sel,Branch,MemRead,MemtoReg,MemWrite,ALUSrc,RegWrite};
    always@(*)begin
    case(ledSel)
    2'b00:leds =IF_ID_Inst[15:0];
    2'b01:leds =IF_ID_Inst[31:16];
    2'b10:leds =signals;
    2'b11:leds =15'd0;
    endcase 
    end 
    
     always @(*) begin
            case(ssdSel)
                4'b0000: ssd = IF_ID_PC;               
                4'b0001: ssd = add4;       
                4'b0010: ssd = Sum;    
                4'b0011: ssd = PC_in;            
                4'b0100: ssd = ID_EX_RegR1;     
                4'b0101: ssd = ID_EX_RegR1;     
                4'b0110: ssd = WriteData;           
                4'b0111: ssd = ID_EX_Imm;     
                4'b1000: ssd = shifted_imm_out;   
                4'b1001: ssd = B;     
                4'b1010: ssd = EX_MEM_ALU_out;      
                4'b1011: ssd = MEM_WB_Mem_out;          
                default: ssd = 13'd0;                  
            endcase
        end

//    always @(*) begin
//        leds = {ledSel, 14'b0};  
//    end

//always@(clk || reset) begin
//    if(reset == 1) begin  
//       PC_in <=32'd0;
//       end
//    else begin
//        PC_in <= (last_sel)? EX_MEM_BranchAddOut: add4; 
//      end
//   end
    
    

    
    
//Below is the code for pipelined from my report
    
    // wires declarations
    // the module "Register" is an n-bit register module with n as a parameter// and with I/O’s (clk, rst, load, data_in, data_out) in sequence wire [...] IF_ID_PC, IF_ID_Inst;
    //Register #() IF_ID (clk,rst,1'b1, {....}, {IF_ID_PC,IF_ID_Inst} );
//    wire [...] ID_EX_PC, ID_EX_RegR1, ID_EX_RegR2, ID_EX_Imm;
//    wire [...] ID_EX_Ctrl;
//    wire [...] ID_EX_Func;
//    wire [...] ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd;
//    Register #(...) ID_EX (clk,rst,1'b1, {....},{ID_EX_Ctrl,ID_EX_PC,ID_EX_RegR1,ID_EX_RegR2,ID_EX_Imm, ID_EX_Func,ID_EX_Rs1,ID_EX_Rs2,ID_EX_Rd} );
    
    // Rs1 and Rs2 are needed later for the forwarding unit
//    wire [...] EX_MEM_BranchAddOut, EX_MEM_ALU_out, EX_MEM_RegR2; wire [...] EX_MEM_Ctrl;
//    wire [...] EX_MEM_Rd;
//    wire EX_MEM_Zero;
//    Register #(...) EX_MEM (clk,rst,1'b1, {....}, {EX_MEM_Ctrl, EX_MEM_BranchAddOut, EX_MEM_Zero, EX_MEM_ALU_out, EX_MEM_RegR2, EX_MEM_Rd} );
//    wire [...] MEM_WB_Mem_out, MEM_WB_ALU_out;
//    wire [...] MEM_WB_Ctrl;
//    wire [...] MEM_WB_Rd;
//    Register #(...) MEM_WB (clk,rst,1'b1,{}, {MEM_WB_Ctrl,MEM_WB_Mem_out, MEM_WB_ALU_out, MEM_WB_Rd} );
    // all modules instantiations
    // LED and SSD outputs case statements
endmodule
