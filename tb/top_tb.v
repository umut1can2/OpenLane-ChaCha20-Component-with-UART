/*
    TEST VEKTORU COK UZUN OLDUGU ICIN DIREKT CLAUDE TARAFINDAN HAZIRLANMIS TESTI KULLANIYORUM
    BURADA CIKTI LITTLE ENDIAN FORMUNDA OLUYOR AMA DIKKAT EDILMESI GEREKIYOR.
    CIKTI BIR NEVI TERSTEN YAZILMIS GIBI - (degistirmek icin KeystreamGenerator ayari lazim)
*/

`timescale 1ns / 1ps
module top_tb();

    localparam CLK_PERIOD  = 50;    // 20 MHz
    localparam BAUD_PERIOD = 8680;  // 115200 baud @ 20MHz

    reg clk, rst_n, data_i, start_i;
    wire data_o, ready_o, done_o;
    top uut (
        .clk    (clk),
        .rst_n  (rst_n),
        .data_i (data_i),
        .start_i(start_i),
        .data_o (data_o),
        .ready_o(ready_o),
        .done_o (done_o)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // done flag latch — 1 cycle pulse kaçmasın
    reg done_flag;
    always @(posedge clk) begin
        if (!rst_n)       done_flag <= 1'b0;
        else if (done_o)  done_flag <= 1'b1;
    end

    // Tek byte UART TX task
    task send_byte;
        input [7:0] b;
        integer k;
        begin
            data_i = 1'b0; #(BAUD_PERIOD); // start bit
            for (k = 0; k < 8; k = k + 1) begin
                data_i = b[k]; #(BAUD_PERIOD);
            end
            data_i = 1'b1; #(BAUD_PERIOD); // stop bit
        end
    endtask

    // RFC 8439 Test Vektörü
    // Key:     00 01 02 ... 1f  (32 byte)
    // Nonce:   00 00 00 00 00 00 00 4a 00 00 00 00 (12 byte)
    // Counter: 01 00 00 00  (little-endian = 1)
    // Plain:   "Ladies and Gentlemen..." (64 byte)
    // Cipher:  6e2e359a... (64 byte)

    reg [7:0] plain_arr  [0:63];
    reg [7:0] expected   [0:63];
    integer i, err_count;

    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        data_i   = 1'b1;
        start_i  = 1'b0;
        err_count = 0;

        // Plaintext — "Ladies and Gentlemen of the class of '99: If I could offer you o"
        plain_arr[0]=8'h4c;  plain_arr[1]=8'h61;  plain_arr[2]=8'h64;  plain_arr[3]=8'h69;
        plain_arr[4]=8'h65;  plain_arr[5]=8'h73;  plain_arr[6]=8'h20;  plain_arr[7]=8'h61;
        plain_arr[8]=8'h6e;  plain_arr[9]=8'h64;  plain_arr[10]=8'h20; plain_arr[11]=8'h47;
        plain_arr[12]=8'h65; plain_arr[13]=8'h6e; plain_arr[14]=8'h74; plain_arr[15]=8'h6c;
        plain_arr[16]=8'h65; plain_arr[17]=8'h6d; plain_arr[18]=8'h65; plain_arr[19]=8'h6e;
        plain_arr[20]=8'h20; plain_arr[21]=8'h6f; plain_arr[22]=8'h66; plain_arr[23]=8'h20;
        plain_arr[24]=8'h74; plain_arr[25]=8'h68; plain_arr[26]=8'h65; plain_arr[27]=8'h20;
        plain_arr[28]=8'h63; plain_arr[29]=8'h6c; plain_arr[30]=8'h61; plain_arr[31]=8'h73;
        plain_arr[32]=8'h73; plain_arr[33]=8'h20; plain_arr[34]=8'h6f; plain_arr[35]=8'h66;
        plain_arr[36]=8'h20; plain_arr[37]=8'h27; plain_arr[38]=8'h39; plain_arr[39]=8'h39;
        plain_arr[40]=8'h3a; plain_arr[41]=8'h20; plain_arr[42]=8'h49; plain_arr[43]=8'h66;
        plain_arr[44]=8'h20; plain_arr[45]=8'h49; plain_arr[46]=8'h20; plain_arr[47]=8'h63;
        plain_arr[48]=8'h6f; plain_arr[49]=8'h75; plain_arr[50]=8'h6c; plain_arr[51]=8'h64;
        plain_arr[52]=8'h20; plain_arr[53]=8'h6f; plain_arr[54]=8'h66; plain_arr[55]=8'h66;
        plain_arr[56]=8'h65; plain_arr[57]=8'h72; plain_arr[58]=8'h20; plain_arr[59]=8'h79;
        plain_arr[60]=8'h6f; plain_arr[61]=8'h75; plain_arr[62]=8'h20; plain_arr[63]=8'h6f;

        // Beklenen ciphertext (RFC 8439)
        expected[0]=8'h6e;  expected[1]=8'h2e;  expected[2]=8'h35;  expected[3]=8'h9a;
        expected[4]=8'h25;  expected[5]=8'h68;  expected[6]=8'hf9;  expected[7]=8'h80;
        expected[8]=8'h41;  expected[9]=8'hba;  expected[10]=8'h07; expected[11]=8'h28;
        expected[12]=8'hdd; expected[13]=8'h0d; expected[14]=8'h69; expected[15]=8'h81;
        expected[16]=8'he9; expected[17]=8'h7e; expected[18]=8'h7a; expected[19]=8'hec;
        expected[20]=8'h1d; expected[21]=8'h43; expected[22]=8'h60; expected[23]=8'hc2;
        expected[24]=8'h0a; expected[25]=8'h27; expected[26]=8'haf; expected[27]=8'hcc;
        expected[28]=8'hfd; expected[29]=8'h9f; expected[30]=8'hae; expected[31]=8'h0b;
        expected[32]=8'hf9; expected[33]=8'h1b; expected[34]=8'h65; expected[35]=8'hc5;
        expected[36]=8'h52; expected[37]=8'h47; expected[38]=8'h33; expected[39]=8'hab;
        expected[40]=8'h8f; expected[41]=8'h59; expected[42]=8'h3d; expected[43]=8'hab;
        expected[44]=8'hcd; expected[45]=8'h62; expected[46]=8'hb3; expected[47]=8'h57;
        expected[48]=8'h16; expected[49]=8'h39; expected[50]=8'hd6; expected[51]=8'h24;
        expected[52]=8'he6; expected[53]=8'h51; expected[54]=8'h52; expected[55]=8'hab;
        expected[56]=8'h8f; expected[57]=8'h53; expected[58]=8'h0c; expected[59]=8'h35;
        expected[60]=8'h9f; expected[61]=8'h08; expected[62]=8'h61; expected[63]=8'hd8;

        // Reset
        #200; rst_n = 1'b1; #200;

        // start_i ile FSM'i başlat
        @(posedge clk); start_i = 1'b1;
        @(posedge clk); start_i = 1'b0;

        // KEY gönder (32 byte: 00 01 02 ... 1f)
        $display("KEY gonderiliyor...");
        for (i = 0; i < 32; i = i + 1)
            send_byte(i[7:0]);

        // NONCE gönder (12 byte)
        $display("NONCE gonderiliyor...");
        send_byte(8'h00); send_byte(8'h00); send_byte(8'h00); send_byte(8'h00);
        send_byte(8'h00); send_byte(8'h00); send_byte(8'h00); send_byte(8'h4a);
        send_byte(8'h00); send_byte(8'h00); send_byte(8'h00); send_byte(8'h00);

        // COUNTER gönder (4 byte, little-endian = 1)
        $display("COUNTER gonderiliyor...");
        send_byte(8'h01); send_byte(8'h00); send_byte(8'h00); send_byte(8'h00);

        // PLAINTEXT gönder (64 byte)
        $display("PLAINTEXT gonderiliyor...");
        for (i = 0; i < 64; i = i + 1)
            send_byte(plain_arr[i]);

        // PROCESS + SEND bitmesini bekle
        $display("PROCESS bekleniyor...");
        wait(done_flag == 1'b1);
        $display("=== DONE! ===");

        #10000;
        $display("Hata sayisi: %0d", err_count);
        if (err_count == 0)
            $display("TUM BYTELER DOGRU! RFC 8439 eslesme tamam.");
        $finish;
    end

    // TX Monitor — data_o'dan gelen 64 byte'i oku ve karşılaştır
    reg [7:0] rx_byte;
    integer j;
    initial begin
        rx_byte = 8'h00;
        wait(done_flag == 1'b1);
        #(BAUD_PERIOD);

        for (j = 0; j < 64; j = j + 1) begin
            @(negedge data_o);                         // start bit kenarı
            #(BAUD_PERIOD + BAUD_PERIOD/2);            // bit ortasına gel

            rx_byte[0] = data_o; #(BAUD_PERIOD);
            rx_byte[1] = data_o; #(BAUD_PERIOD);
            rx_byte[2] = data_o; #(BAUD_PERIOD);
            rx_byte[3] = data_o; #(BAUD_PERIOD);
            rx_byte[4] = data_o; #(BAUD_PERIOD);
            rx_byte[5] = data_o; #(BAUD_PERIOD);
            rx_byte[6] = data_o; #(BAUD_PERIOD);
            rx_byte[7] = data_o; #(BAUD_PERIOD);

            if (rx_byte == expected[j])
                $display("Byte[%0d] OK : beklenen=%h alinan=%h", j, expected[j], rx_byte);
            else begin
                $display("Byte[%0d] HATA: beklenen=%h alinan=%h", j, expected[j], rx_byte);
                err_count = err_count + 1;
            end
        end
        $display("=== TX Monitor Tamamlandi ===");
    end

endmodule