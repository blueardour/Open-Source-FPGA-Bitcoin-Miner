/*
*
* Copyright (c) 2011 fpgaminer@bitcoin-mining.com
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

`timescale 1ns/1ps

module bitcoin_miner (osc_clk, rst_n, hit, hit_nonce);

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
	parameter LOOP_LOG2 = 5;

	// No need to adjust these parameters
	localparam [5:0] LOOP = (6'd1 << LOOP_LOG2);
	// The nonce will always be larger at the time we discover a valid
	// hash. This is its offset from the nonce that gave rise to the valid
	// hash (except when LOOP_LOG2 == 0 or 1, where the offset is 131 or
	// 66 respectively).
	localparam [31:0] GOLDEN_NONCE_OFFSET = (32'd1 << (7 - LOOP_LOG2)) + 32'd1;

	input osc_clk;
	input rst_n;

	output hit;
	output [31:0] hit_nonce;
	
	////
	reg hit;
	reg [31:0] hit_nonce;

	////	
	reg [31:0] nonce;
	wire [255:0] hash, hash2;
	reg [5:0] cnt;
	reg feedback;
	
	wire [255:0] state = 256'h010101010101;
	wire [511:0] data = {384'h000002800000000000000000000000000000000000000000000000000000000000000000000000000000000080000000, nonce, 96'h0};

	
	//// Hashers
	assign hash_clk = osc_clk;
	wire reset = ~ rst_n;
	
	sha256_transform #(.LOOP(LOOP)) uut (
		.clk(hash_clk),
		.feedback(feedback),
		.cnt(cnt),
		.rx_state(state),
		.rx_input(data),
		.tx_hash(hash)
	);
	sha256_transform #(.LOOP(LOOP)) uut2 (
		.clk(hash_clk),
		.feedback(feedback),
		.cnt(cnt),
		.rx_state(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
		.rx_input({256'h0000010000000000000000000000000000000000000000000000000080000000, hash}),
		.tx_hash(hash2)
	);

	//// Control Unit
	reg feedback_d1;
	wire [5:0] cnt_next;
	wire [31:0] nonce_next;
	wire feedback_next;
	
	assign cnt_next =  reset ? 6'd0 : (LOOP == 1) ? 6'd0 : (cnt + 6'd1) & (LOOP-1);
	// On the first count (cnt==0), load data from previous stage (no feedback)
	// on 1..LOOP-1, take feedback from current stage
	// This reduces the throughput by a factor of (LOOP), but also reduces the design size by the same amount
	assign feedback_next = (LOOP == 1) ? 1'b0 : (cnt_next != {(LOOP_LOG2){1'b0}});
	assign nonce_next = reset ? 32'd0 : feedback_next ? nonce : (nonce + 32'd1);

	
	always @ (posedge hash_clk)
	begin
		cnt <= cnt_next;
		feedback <= feedback_next;
		feedback_d1 <= feedback;
		nonce <= nonce_next;
	end

	always @ (posedge hash_clk)
	begin
	  if(~rst_n) begin hit <= 1'b0; hit_nonce <= hit_nonce; end
	  else if((hash2 >= 256'hffffffff) && !feedback_d1) begin hit <= 1'b1; hit_nonce <= nonce; end
	  else begin hit <= hit; hit_nonce <= hit_nonce; end
	end
	  
endmodule

