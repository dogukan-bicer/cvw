///////////////////////////////////////////
// mul.sv
//
// Written: David_Harris@hmc.edu 16 February 2021
// Modified: 
//
// Purpose: Multiply instructions
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module mul (
  // Execute Stage interface
  input  logic             clk, reset,
  input  logic             StallM, FlushM,
    //    input logic [`XLEN-1:0] 	SrcAE, SrcBE,
  input logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  input  logic [2:0]       Funct3E,
  output logic [`XLEN*2-1:0] ProdM
);

    // Number systems
    // Let A' = sum(i=0, XLEN-2, A[i]*2^i)
    // Unsigned: A = A' + A[XLEN-1]*2^(XLEN-1)
    // Signed:   A = A' - A[XLEN-1]*2^(XLEN-1)

    // Multiplication: A*B
    // Let P' = A' * B'
    //     PA = (A' * B[XLEN-1]) 
    //     PB = (B' * A[XLEN-1])
    //     PP = A[XLEN-1] * B[XLEN-1]
    // Signed * Signed     = P' + (-PA - PB)*2^(XLEN-1) + PP*2^(2XLEN-2)
    // Signed * Unsigned   = P' + ( PA - PB)*2^(XLEN-1) - PP*2^(2XLEN-2)
    // Unsigned * Unsigned = P' + ( PA + PB)*2^(XLEN-1) + PP*2^(2XLEN-2)

    logic [`XLEN*2-1:0] PP0E, PP1E, PP2E, PP3E, PP4E;
    logic [`XLEN*2-1:0] PP0M, PP1M, PP2M, PP3M, PP4M;
    logic [`XLEN-2:0]   PA, PB;
    logic               PP;
    logic               MULH, MULHSU;
    logic [`XLEN-1:0]   Aprime, Bprime;

  //////////////////////////////
  // Execute Stage: Compute partial products
  //////////////////////////////

    assign Aprime = {1'b0, ForwardedSrcAE[`XLEN-2:0]};
    assign Bprime = {1'b0, ForwardedSrcBE[`XLEN-2:0]};
    redundantmul #(`XLEN) bigmul(.a(Aprime), .b(Bprime), .out0(PP0E), .out1(PP1E));
    assign PA = {(`XLEN-1){ForwardedSrcAE[`XLEN-1]}} & ForwardedSrcBE[`XLEN-2:0];  
    assign PB = {(`XLEN-1){ForwardedSrcBE[`XLEN-1]}} & ForwardedSrcAE[`XLEN-2:0];
    assign PP = ForwardedSrcAE[`XLEN-1] & ForwardedSrcBE[`XLEN-1];

    // flavor of multiplication
    assign MULH   = (Funct3E == 3'b001);
    assign MULHSU = (Funct3E == 3'b010);

    // Handle signs
    assign PP2E = {2'b00, (MULH | MULHSU) ? ~PA : PA, {(`XLEN-1){1'b0}}};
    assign PP3E = {2'b00, (MULH) ? ~PB : PB, {(`XLEN-1){1'b0}}};
    always_comb 
    if (MULH)        PP4E = {1'b1, PP, {(`XLEN-3){1'b0}}, 1'b1, {(`XLEN){1'b0}}}; 
    else if (MULHSU) PP4E = {1'b1, ~PP, {(`XLEN-2){1'b0}}, 1'b1, {(`XLEN-1){1'b0}}};
    else             PP4E = {1'b0, PP, {(`XLEN*2-2){1'b0}}};

  //////////////////////////////
  // Memory Stage: Sum partial proudcts
  //////////////////////////////

	 flopenrc #(`XLEN*2) PP0Reg(clk, reset, FlushM, ~StallM, PP0E, PP0M); 
	 flopenrc #(`XLEN*2) PP1Reg(clk, reset, FlushM, ~StallM, PP1E, PP1M); 
	 flopenrc #(`XLEN*2) PP2Reg(clk, reset, FlushM, ~StallM, PP2E, PP2M); 
	 flopenrc #(`XLEN*2) PP3Reg(clk, reset, FlushM, ~StallM, PP3E, PP3M); 
	 flopenrc #(`XLEN*2) PP4Reg(clk, reset, FlushM, ~StallM, PP4E, PP4M); 

    assign ProdM = PP0M + PP1M + PP2M + PP3M + PP4M; //ForwardedSrcAE * ForwardedSrcBE;
 endmodule
