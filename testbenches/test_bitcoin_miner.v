

`timescale 1ns/1ps

module test_bitcoin_miner ();
  
	reg clk;
	reg rst_n;
	wire hit;
	wire [31:0] nonce;
	
	// The LOOP_LOG2 parameter determines how unrolled the SHA-256
	// calculations are. For example, a setting of 0 will completely
	// unroll the calculations, resulting in 128 rounds and a large, but
	// fast design.
	//
	// A setting of 1 will result in 64 rounds, with half the size and
	// half the speed. 2 will be 32 rounds, with 1/4th the size and speed.
	// And so on.
	//
	// Valid range: [0, 5]
	bitcoin_miner # (.LOOP_LOG2(5)) uut (clk, rst_n, hit, nonce);


	initial begin
		clk = 0;
		rst_n = 0;
		
		#100
		rst_n = 1;

	end

  always # 5 clk <= ~ clk;

	reg [63:0] cycle;
	always @ (posedge clk) if(~rst_n) cycle <= 64'h0; else cycle <= cycle + 64'd1;
	
	reg hit_last;
	always @ (posedge clk) hit_last <= hit;
	always @ (posedge clk) if(hit_last == 1'b0 && hit == 1'b1) $display("Hit nonce:%08x\n Time: %16x", nonce, cycle);

endmodule

