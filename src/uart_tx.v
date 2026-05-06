`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Umutcan Akyol
// Design Name: uart_tx Module
// Module Name: uart_tx
// Dependencies: -
//////////////////////////////////////////////////////////////////////////////////
module uart_tx 
#(
    parameter BAUD_RATE = 115_200,
    parameter CLK_FREQ  = 20_000_000 
) 
(
    input clk,
    input rst_n,
    input [7:0]  data_i,
    input uart_tx_start_i,
    output data_o_out,
    output uart_tx_done_o
);
    // 173.xx bir seyler geliyor.
    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    
    reg [15:0] tick_counter;
    reg [7:0]  shift_reg;
    reg [2:0]  bit_counter;

    localparam IDLE = 4'b0001;
    localparam START = 4'b0010;
    localparam TRANSFER = 4'b0100;
    localparam DONE = 4'b1000;

    reg [3:0] state;

    reg data_o_reg, uart_tx_done_reg;

    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            state          <= IDLE;
            tick_counter   <= 16'd0;
            bit_counter    <= 3'd0;
            shift_reg      <= 8'd0;
            data_o_reg     <= 1'b1; 
            uart_tx_done_reg <= 1'b0;
        end
        else begin 
            // idle icinde olunca patladi??
            uart_tx_done_reg <= 1'b0;
            
            case (state)
                IDLE : begin
                    data_o_reg   <= 1'b1;
                    tick_counter <= 16'd0;
                    bit_counter  <= 3'd0;
                    if (uart_tx_start_i) begin 
                        shift_reg <= data_i; 
                        state     <= START;
                    end
                end
                START : begin
                    data_o_reg <= 1'b0; // baslangic biti uart icin 0(iletim halinde degilken hat 1 de takili)
                    if (tick_counter >= BIT_PERIOD - 1) begin 
                        tick_counter <= 16'd0;
                        state        <= TRANSFER;
                    end
                    else begin
                        tick_counter <= tick_counter + 16'd1;
                    end
                end

                TRANSFER : begin 
                    data_o_reg <= shift_reg[0]; 
                    if (tick_counter >= BIT_PERIOD - 1) begin 
                        tick_counter <= 16'd0;
                        if (bit_counter == 3'd7) begin 
                            state <= DONE;
                        end
                        else begin 
                            shift_reg   <= (shift_reg >> 1);
                            bit_counter <= bit_counter + 3'd1;
                        end
                    end
                    else begin 
                        tick_counter <= tick_counter + 16'd1;
                    end
                end
                DONE : begin
                    data_o_reg <= 1'b1; // stop biti uart icin 1 
                    if (tick_counter >= BIT_PERIOD - 1) begin 
                        uart_tx_done_reg <= 1'b1; // 1 cycle done 1 olacak
                         state          <= IDLE;
                    end
                    else begin 
                        tick_counter <= tick_counter + 16'd1;
                    end
                end
                default : begin 
                    state <= IDLE;
                end
            endcase
        end
    end

    assign data_o_out = data_o_reg;
    assign uart_tx_done_o = uart_tx_done_reg;
    
endmodule

