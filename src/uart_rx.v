`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Umutcan Akyol
// Design Name: UART_RX Module
// Module Name: uart_rx
// Dependencies: ? yok
// sample da patladi kontrol et!!
//////////////////////////////////////////////////////////////////////////////////


module uart_rx
	#(
		parameter BAUD_RATE = 115_200,
		parameter CLK_FREQ  = 20_000_000 // 20Mhz degistir
	)
	(
		input clk,
		input rst_n,
		input data_i,
		
		output [7:0] data_o,
		output done_o
    );
	
	
	localparam IDLE = 5'b00001;
	localparam START = 5'b00010;
	localparam TRANSFER = 5'b00100;
	localparam TRANSFER_STEP = 5'b01000;
	localparam DONE = 5'b10000;
	
	reg [4:0] state;
	
	reg [7:0] data_reg;
	reg done_reg;
	
	localparam bit_timer_total = CLK_FREQ/BAUD_RATE; // burada 173 - 174 cycle bekleme arasi bisey hata payi cikartiyor
	reg [15:0] bit_timer;
	
	reg [2:0] bit_counter;
	always@(posedge clk, negedge rst_n) begin 
		if(!rst_n) begin 
			done_reg <= 1'b0;
			data_reg <= 8'd0;
			bit_timer <= 0;
			bit_counter <= 3'd0;
			done_reg <= 1'b0;
			state <= IDLE;
		end
		else begin 
			done_reg <= 1'b0;
			case(state)
				IDLE : begin 
					done_reg <= 1'b0;
					data_reg <= 8'd0;
					bit_timer <= 0;
					bit_counter <= 3'd0;
					if(data_i == 1'b0) begin 
						state <= START;
					end
				end
				START : begin 
					if(bit_timer == bit_timer_total/2) begin // tam ortada sample aliyoruz
						if(data_i == 1'b0) begin 
							bit_timer <= 0;
							state <= TRANSFER;
						end
						else begin 
							state <= IDLE;
						end
					end
					else begin 
						bit_timer <= bit_timer + 1;
					end
				end
				TRANSFER : begin 
					if(bit_timer == bit_timer_total) begin 
						bit_timer <= 0 ;
						
						data_reg[bit_counter] <= data_i;
						
						if(bit_counter == 7) begin 
							state <= DONE;
						end
						else begin 
							bit_counter <= bit_counter + 1;
						end
						
					end
					else begin 
						bit_timer <= bit_timer + 1;
					end
				end
			DONE : begin 
				//STOP BIT KADAR BEKLMEKE LAZIM
				if(bit_timer == bit_timer_total / 2) begin 
					state <= IDLE;
					done_reg <= 1'b1;
				end
				else begin 
					bit_timer <= bit_timer + 1;
				end
			end
			endcase
		end
	end
	assign data_o = data_reg;
	assign done_o = done_reg;
endmodule
