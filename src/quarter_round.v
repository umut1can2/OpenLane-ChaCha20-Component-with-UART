//////////////////////////////////////////////////////////////////////////////////
// Engineer: Umutcan Akyol
// Design Name: QuarterROund Module
// Module Name: quarterround
// Dependencies: yok
//////////////////////////////////////////////////////////////////////////////////


module QuarterRound (
    input [31:0] a_i,
    input [31:0] b_i,
    input [31:0] c_i,
    input [31:0] d_i,
    
    output [31:0] a_o,
    output [31:0] b_o,
    output [31:0] c_o,
    output [31:0] d_o
);
    
    reg [31:0] a, b, c, d;

    function [31:0] sola_dondur;
        input [31:0] deger;
        input [4:0] msf;
        begin
            sola_dondur = (deger << msf) | (deger >> (32 - msf));
        end
    endfunction

    always @(*) begin
        a = a_i + b_i;
        d = sola_dondur((d_i ^ a), 16);

        c = c_i + d;
        b = sola_dondur((b_i ^ c), 12);

        a = a + b;
        d = sola_dondur((d ^ a), 8);

        c = c + d;
        b = sola_dondur((b ^ c), 7);
    end

    assign a_o = a;
    assign b_o = b;
    assign c_o = c;
    assign d_o = d;


endmodule

