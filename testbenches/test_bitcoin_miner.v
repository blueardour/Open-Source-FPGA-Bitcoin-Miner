

`timescale 1ns/1ps

module test_bitcoin_miner ();
  
	reg clk;
	reg rst_n;
	
	reg ready;
	reg [31:0] serial_in;

	wire hit;
	wire [31:0] serial_out;

	reg [31:0] i;

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
	bitcoin_miner # (.LOOP_LOG2(5)) uut
		(.osc_clk(clk),
		.rst_n(rst_n),
		.hit(hit),
		.ready(ready),
		.serial_in(serial_in),
		.serial_out(serial_out)
		);


	initial begin
		clk = 0;
		rst_n = 0;
		ready = 0;
		serial_in = 32'h00;
		i = 32'h01;
		
		#100
		rst_n = 1;

		#20;
		ready = 1;
		while( i < 32'd12)
		begin
			serial_in = i;
			i = i + 32'h01;
			#10;
		end

		ready = 0;
	end

	always # 5 clk <= ~ clk;

	reg [63:0] cycle;
	always @ (posedge clk) if(~rst_n) cycle <= 64'h0; else cycle <= cycle + 64'd1;
	
	reg hit_last;
	always @ (posedge clk) hit_last <= hit;
	always @ (posedge clk) if(hit_last == 1'b0 && hit == 1'b1) $display("Hit nonce:%08x\n Time: %16x", serial_out, cycle);

endmodule

