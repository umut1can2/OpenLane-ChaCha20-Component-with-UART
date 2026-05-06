`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Umutcan Akyol
// Design Name: UART_TOP Module
// Module Name: uart_rx
// Dependencies: KeystreamGenerator, uart_top
//////////////////////////////////////////////////////////////////////////////////

module top(
    input  clk,
    input  rst_n,
    input  data_i,
	input  start_i,
    output data_o,
    output ready_o,
    output done_o
);

    reg keyGen_start_reg;
    reg [255:0] keyGen_key_reg;
    reg [95:0] keyGen_nonce_reg;
    reg [31:0] keyGen_counter_reg;
    wire [511:0] keygen_out_reg;    
    wire keyGen_ready_reg, keyGen_done_reg;  
    KeystreamGenerator keyGen(
        .clk(clk),
        .rst_n(rst_n),
        .start_i(keyGen_start_reg),
        .key_i(keyGen_key_reg),
        .nonce_i(keyGen_nonce_reg),
        .counter_i(keyGen_counter_reg),
        .keystream_o(keygen_out_reg),
        .ready_o(keyGen_ready_reg),
        .done_o(keyGen_done_reg)
    );
	
	


    reg uart_tx_start_reg;
    reg [7:0] uart_tx_data_reg, uart_rx_data_reg;
    wire uart_tx_done_reg, uart_rx_done_reg;   

    uart_top UART(
        .clk(clk),
        .rst_n(rst_n),
        .rx_data_i(data_i),
        .tx_data_i(uart_tx_data_reg),
        .tx_start_i(uart_tx_start_reg),
        .tx_data_o(data_o),
        .rx_data_o(uart_rx_data_reg),
        .tx_done_o(uart_tx_done_reg),
        .rx_done_o(uart_rx_done_reg)
    );
	
    localparam IDLE = 8'b00000001;
    localparam GET_KEY = 8'b00000010;
    localparam GET_NONCE = 8'b00000100;
    localparam GET_COUNTER = 8'b00001000;
    localparam GET_PLAIN_TEXT = 8'b00010000;
    localparam KEYSTREAM_GEN = 8'b00100000;
    localparam SEND_CIPHER_TEXT = 8'b01000000;
    localparam DONE = 8'b10000000;

    reg [7:0] state;
    reg [7:0] byte_counter;
	
	reg ready, done;
	
	reg [511:0] plaintext_reg;
	reg [511:0] ciphertext_reg;
	
	// eklemeyince surekli veri bozuluyor.
	reg tx_busy;
	
	always@(posedge clk, negedge rst_n) begin 
		if(!rst_n) begin 
			state <= IDLE;
            byte_counter <= 8'd0;
            keyGen_start_reg <= 1'b0;
            uart_tx_start_reg <= 1'b0;
            tx_busy <= 1'b0;
            // keyGen_key_reg <= 0;
            keyGen_key_reg <= 256'd0;
            keyGen_nonce_reg <= 96'd0;
            keyGen_counter_reg <= 32'd0;
            plaintext_reg <= 512'd0;
            ciphertext_reg <= 512'd0;
			state <= IDLE;
			done <= 1'b0;
			ready <= 1'b1;
		end
		else begin 
		
			keyGen_start_reg <= 1'b0; 
            uart_tx_start_reg <= 1'b0; 
			
			case(state)
				IDLE : begin 
					if(start_i == 1'b1) begin 
						ready <= 1'b0;
						byte_counter <= 8'd0;
						state <= GET_KEY;
					end
				end
				GET_KEY : begin 
					if(uart_rx_done_reg == 1'b1) begin 
						keyGen_key_reg[byte_counter*8 +: 8] <= uart_rx_data_reg;
						if(byte_counter == 8'd31) begin 
							byte_counter <= 8'd0;
							state <= GET_NONCE;
						end
						else begin 
							byte_counter <= byte_counter + 1;
						end
					end
				end
				GET_NONCE : begin 
					if(uart_rx_done_reg == 1'b1 ) begin 
						keyGen_nonce_reg[byte_counter*8 +: 8] <= uart_rx_data_reg;
						
						if(byte_counter == 8'd11) begin 
							byte_counter <= 8'd0;
							state <= GET_COUNTER;
						end
						else begin 
							byte_counter <= byte_counter + 1;
						end
					end
				end
				GET_COUNTER : begin 
					if(uart_rx_done_reg == 1'b1) begin 
						keyGen_counter_reg[byte_counter*8 +: 8] <= uart_rx_data_reg;
						if(byte_counter == 8'd3) begin 
							byte_counter <= 8'd0;
							state <= GET_PLAIN_TEXT;
						end
						else begin 
							byte_counter <= byte_counter + 1;
						end
					end
				end
				
				GET_PLAIN_TEXT : begin 
					if(uart_rx_done_reg) begin 
						plaintext_reg[byte_counter*8 +: 8] <= uart_rx_data_reg;
						
						if(byte_counter == 8'd63) begin 
							byte_counter <= 8'd0;
							state <= KEYSTREAM_GEN;
						end
						else begin 
							byte_counter <= byte_counter + 1;
						end
						
					end
				end
				
				KEYSTREAM_GEN : begin
					// IDLE state i icin bekliyor
					// done sinyali gelince keystream(DONE_STATE) te oluyor cunku
					if (!keyGen_done_reg && keyGen_ready_reg == 1'b1) begin 
						keyGen_start_reg <= 1'b1;  
					end
					if (keyGen_done_reg == 1'b1) begin
						ciphertext_reg <= keygen_out_reg ^ plaintext_reg;
						byte_counter <= 8'd0;
						state <= SEND_CIPHER_TEXT;
					end
				end
				
				SEND_CIPHER_TEXT : begin 
					if(tx_busy == 1'b0) begin 
						uart_tx_data_reg <= ciphertext_reg[byte_counter*8 +: 8];
						uart_tx_start_reg <= 1'b1;
						tx_busy <= 1'b1;
					end
					if(uart_tx_done_reg == 1'b1) begin 
						tx_busy <= 1'b0;
						if(byte_counter == 8'd63) begin 
							byte_counter <= 8'd0;
							state <= DONE;
						end
						else begin 
							byte_counter <= byte_counter + 1;
						end
					end
				end
				DONE : begin 
					done <= 1'b1;
					state <= IDLE;
				end
				default : begin 
					state <= IDLE;
				end
			endcase
		end
	end
	
	assign done_o = done;
	assign ready_o = ready;
	
endmodule
