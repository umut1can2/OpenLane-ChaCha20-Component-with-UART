`timescale 1ns / 1ps
// 8680 i constant olarak tanimla

module uart_rx_tb(
    );
	
	wire [7:0] data_o;
	wire done_o;
	
	reg clk;
	reg rst_n;
	reg data_i;
	
	uart_rx
	#(
		.BAUD_RATE(115_200),
		.CLK_FREQ(20_000_000) // 20Mhz degistir
	)
	UUT (
		.clk(clk),
		.rst_n(rst_n),
		.data_i(data_i),
		
		.data_o(data_o),
		.done_o(done_o)
    );
	
	always #25 clk = ~clk;
	
	initial begin 
	
	clk = 1'b0;
	rst_n = 1'b0;
	data_i = 1'b1;
	
	#50;
	
	rst_n = 1'b1;
	#50;
	
	// hatta sinyali cakiyoruz
	data_i = 1'b0;
	#8680;
	
	// burada veri yollanacak
	data_i = 1'b1;
	#8680;
	data_i = 1'b1;
	#8680;
	data_i = 1'b0;
	#8680;
	data_i = 1'b1;
	#8680;
	data_i = 1'b0;
	#8680;
	data_i = 1'b1;
	#8680;
	data_i = 1'b0;
	#8680;
	data_i = 1'b1;
	#8680;
	
	// 11010101 -- 10101011
	
	data_i = 1'b1;
	#8680;
	
	#10000;
	
	$finish;
	end
endmodule
