`timescale 1ns / 1ps

module uart_tx_tb(

); 

    reg clk, rst_n;
    reg [7:0] data_i;
    reg uart_tx_start_i;
    
    wire data_o_out, uart_tx_done_o;
    
    uart_tx #(
        .BAUD_RATE(115_200),
        .CLK_FREQ(20_000_000) 
    ) UUT (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(data_i),
        .uart_tx_start_i(uart_tx_start_i),
        .data_o_out(data_o_out),
        .uart_tx_done_o(uart_tx_done_o)
    );
    
    always #25 clk = !clk;
    
    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        data_i = 8'h00;
        uart_tx_start_i = 1'b0;
        
        #200;
        rst_n = 1'b1; 
        #200;
        
        // 0xAA
        data_i = 8'hF1;
        uart_tx_start_i = 1'b1;
        #100;
        uart_tx_start_i = 1'b0;
        
        wait(uart_tx_done_o); 
        #1000; 
        
        // 0x4f
        data_i = 8'h4F;
        uart_tx_start_i = 1'b1;
        #100;
        uart_tx_start_i = 1'b0;
        
        wait(uart_tx_done_o);
        #2000;
        $finish;
    end
endmodule