`timescale 1ns / 1ps



module uart_top_tb();
    localparam CLK_PERIOD = 50;
    localparam BAUD_PERIOD = 8680;

    reg clk, rst_n, tx_start_i, rx_data_i;
    reg [7:0] tx_data_i;
    wire tx_data_o;
    wire [7:0] rx_data_o;
    wire tx_done_o, rx_done_o;

    uart_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_data_i(rx_data_i),
        .tx_data_i(tx_data_i),
        .tx_start_i(tx_start_i),
        .tx_data_o(tx_data_o),
        .rx_data_o(rx_data_o),
        .tx_done_o(tx_done_o),
        .rx_done_o(rx_done_o)
    );

    // 20MHZ CLOCK
    always #(CLK_PERIOD/2) clk = !clk;

    reg tx_done_flag, rx_done_flag;
    always @(posedge clk) begin
        if (!rst_n) begin
            tx_done_flag <= 0;
            rx_done_flag <= 0;
        end
        else begin
            if (tx_done_o) begin 
                tx_done_flag <= 1;
            end
            if (rx_done_o) begin 
                rx_done_flag <= 1;
            end
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        tx_start_i = 0;
        rx_data_i = 1;
        tx_data_i = 0;

        #200;
        rst_n = 1;
        #100;

        @(posedge clk);
        tx_data_i = 8'b10101100; //  0xAC 
        tx_start_i = 1;
        @(posedge clk);
        tx_start_i = 0;

        wait(tx_done_flag == 1);
        $display("tx bitti :%b", 8'b10101100);
        #5000;


        // rx testi
        rx_data_i = 0;      
        #8680;

        rx_data_i = 1; //lsb
        #8680;
        rx_data_i = 0;
        #8680;
        rx_data_i = 1;
        #8680;
        rx_data_i = 1;
        #8680;
        rx_data_i = 1;
        #8680;
        rx_data_i = 1;
        #8680;
        rx_data_i = 0;
        #8680;
        rx_data_i = 1;//msb
        #8680;

        rx_data_i = 1; // Stop biti yollanmasi 1 stop biti kullaniliyor 2 de yollanabilir fark etmez
        #8680;
        // 10111101 -> 0XBD
        //
        wait(rx_done_flag == 1);
        $display("rx tamamlandi: %b (0x%h)", rx_data_o, rx_data_o);

        #8680;
        $finish;
    end
endmodule