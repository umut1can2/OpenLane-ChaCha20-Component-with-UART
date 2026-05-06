`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Umutcan Akyol
// Design Name: UART_TOP Module
// Module Name: uart_top
// Dependencies: uart_rx, uart_txx
//////////////////////////////////////////////////////////////////////////////////



module uart_top(
    input clk,
    input rst_n,
    input rx_data_i, //rx in           
    input [7:0] tx_data_i, //tx in 
	input tx_start_i,
    
    output tx_data_o,          
    output [7:0] rx_data_o,
	
	output tx_done_o,
	output rx_done_o
);

    uart_tx 
	#
	(
		.BAUD_RATE(115_200), // 9600 dene?
		.CLK_FREQ(20_000_000) // 20Mhz degistirmeyi unutma
	)
	tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(tx_data_i),
        .uart_tx_start_i(tx_start_i),
        .data_o_out(tx_data_o),
        .uart_tx_done_o(tx_done_o)
    );

    uart_rx 
	#
	(
		.BAUD_RATE(115_200), // 9600 dene?
		.CLK_FREQ(20_000_000) // 20Mhz degistirmeyi unutma
	)
	rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(rx_data_i),
        .data_o(rx_data_o),
        .done_o(rx_done_o)
    );

endmodule
