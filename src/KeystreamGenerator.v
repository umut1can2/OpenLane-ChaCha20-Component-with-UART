//////////////////////////////////////////////////////////////////////////////////
// Engineer: Umutcan Akyol
// Design Name: KeystreamGenerator Module
// Module Name: KeystreamGenerator
// Dependencies: QuarterRound
//////////////////////////////////////////////////////////////////////////////////


module KeystreamGenerator (
    input clk,
    input rst_n,
    input start_i,
    input [255 : 0] key_i,
    input [95 : 0] nonce_i,
    input [31 : 0] counter_i,

    output [511 : 0] keystream_o,
    output ready_o,
    output done_o
);

    // One hot seklinde durumlar
    localparam IDLE = 5'b00001;
    localparam LOAD = 5'b00010;
    localparam ROUND = 5'b00100;
    localparam F_ADD = 5'b01000;
    localparam DONE = 5'b10000;

    reg [4:0] state;
    
    // chacha20 sabitleri
    localparam C0 = 32'h61707865;
    localparam C1 = 32'h3320646e;
    localparam C2 = 32'h79622d32;
    localparam C3 = 32'h6b206574;

    reg [31:0] initial_matrix [15:0]; // sondaki toplam icin lazim
    reg [31:0] working_matrix [15:0];

    localparam ROUND_COL = 1'b0; 
    localparam ROUND_DIAG = 1'b1;
    reg round_state; 
    reg [4:0] round_counter;
    
    // initiallarin tutulmasi icin bir registerlama.
    reg [255 : 0] key_reg;
    reg [95 : 0] nonce_reg;
    reg [31 : 0] counter_reg;

    reg ready, done;
    reg [511: 0] keystream;
    integer i;
    reg [31:0] temp_sum;

    // QR Modul baglantilari -> ciktilari reglemek?
    reg [31:0] qr0_a_in, qr0_b_in, qr0_c_in, qr0_d_in;
    wire [31:0] qr0_a_out, qr0_b_out, qr0_c_out, qr0_d_out;

    reg [31:0] qr1_a_in, qr1_b_in, qr1_c_in, qr1_d_in;
    wire [31:0] qr1_a_out, qr1_b_out, qr1_c_out, qr1_d_out;

    reg [31:0] qr2_a_in, qr2_b_in, qr2_c_in, qr2_d_in;
    wire [31:0] qr2_a_out, qr2_b_out, qr2_c_out, qr2_d_out;

    reg [31:0] qr3_a_in, qr3_b_in, qr3_c_in, qr3_d_in;
    wire [31:0] qr3_a_out, qr3_b_out, qr3_c_out, qr3_d_out;

    QuarterRound qr0(
        .a_i(qr0_a_in),
        .b_i(qr0_b_in),
        .c_i(qr0_c_in),
        .d_i(qr0_d_in),
        .a_o(qr0_a_out),
        .b_o(qr0_b_out),
        .c_o(qr0_c_out),
        .d_o(qr0_d_out)
    );
    
    QuarterRound qr1(
        .a_i(qr1_a_in), 
        .b_i(qr1_b_in),
        .c_i(qr1_c_in),
        .d_i(qr1_d_in),
        .a_o(qr1_a_out),
        .b_o(qr1_b_out),
        .c_o(qr1_c_out),
        .d_o(qr1_d_out)
    );

    QuarterRound qr2(
        .a_i(qr2_a_in),
        .b_i(qr2_b_in),
        .c_i(qr2_c_in),
        .d_i(qr2_d_in),
        .a_o(qr2_a_out),
        .b_o(qr2_b_out),
        .c_o(qr2_c_out),
        .d_o(qr2_d_out)
    );

    QuarterRound qr3(
        .a_i(qr3_a_in),
        .b_i(qr3_b_in),
        .c_i(qr3_c_in),
        .d_i(qr3_d_in),
        .a_o(qr3_a_out),
        .b_o(qr3_b_out), 
        .c_o(qr3_c_out),
        .d_o(qr3_d_out)
    );

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin 
            state <= IDLE;
            ready <= 1'b0;
            done <= 1'b0;
            round_counter <= 5'b00000;
            round_state <= ROUND_COL; // col durumunda baslat //
        end
        else begin 
            case (state)
                
                IDLE: begin
                    ready <= 1'b1;
                    done <= 1'b0;
                    if(start_i == 1'b1) begin 
                        ready <= 1'b0;
                        round_counter <= 5'b00000;
                        round_state <= ROUND_COL;
                        key_reg <= key_i;
                        nonce_reg <= nonce_i;
                        counter_reg <= counter_i;
                        state <= LOAD;
                    end
                end 
                // initial_m = working_m yapma
                LOAD : begin
                    // 16 byte alan constantlar
                    working_matrix[0] <= C0; 
                    working_matrix[1] <= C1; 
                    working_matrix[2] <= C2; 
                    working_matrix[3] <= C3; 

                    // 32 byte key 
                    for (i = 0; i < 8; i = i + 1) begin
                        working_matrix[4 + i] <= key_reg[i*32 +: 32];
                    end

                    // 4 byte counter degerinin kaydedilmesi
                    working_matrix[12] <= counter_reg;

                    // nonce degerinin kaydedilmesi 12 byte
                    working_matrix[13] <= nonce_reg[31:0];
                    working_matrix[14] <= nonce_reg[63:32];
                    working_matrix[15] <= nonce_reg[95:64];

                    // initial matrixin de doldurulmasi
                    initial_matrix[0] <= C0; 
                    initial_matrix[1] <= C1; 
                    initial_matrix[2] <= C2; 
                    initial_matrix[3] <= C3; 

                    for (i = 0; i < 8; i = i + 1) begin
                        initial_matrix[4 + i] <= key_reg[i*32 +: 32];
                    end

                    initial_matrix[12] <= counter_reg;
                    initial_matrix[13] <= nonce_reg[31:0];
                    initial_matrix[14] <= nonce_reg[63:32];
                    initial_matrix[15] <= nonce_reg[95:64];

                    state <= ROUND;
                end

                ROUND : begin 
                    if(round_counter == 10) begin // Double sayildigi icin 10 normalde 20 cycle lik isi var.
                        state <= F_ADD;
                    end
                    else begin 
                        if(round_state == ROUND_COL) begin 
                            working_matrix[0] <= qr0_a_out;
                            working_matrix[4] <= qr0_b_out;
                            working_matrix[8] <= qr0_c_out;
                            working_matrix[12] <= qr0_d_out;

                            working_matrix[1] <= qr1_a_out;
                            working_matrix[5] <= qr1_b_out;
                            working_matrix[9] <= qr1_c_out;
                            working_matrix[13] <= qr1_d_out;

                            working_matrix[2] <= qr2_a_out;
                            working_matrix[6] <= qr2_b_out;
                            working_matrix[10] <= qr2_c_out;
                            working_matrix[14] <= qr2_d_out;

                            working_matrix[3] <= qr3_a_out;
                            working_matrix[7] <= qr3_b_out;
                            working_matrix[11] <= qr3_c_out;
                            working_matrix[15] <= qr3_d_out;
                            round_state <= ROUND_DIAG;
                        end
                        else begin
                            working_matrix[0] <= qr0_a_out;
                            working_matrix[5] <= qr0_b_out;
                            working_matrix[10] <= qr0_c_out;
                            working_matrix[15] <= qr0_d_out;

                            working_matrix[1] <= qr1_a_out;
                            working_matrix[6] <= qr1_b_out;
                            working_matrix[11] <= qr1_c_out;
                            working_matrix[12] <= qr1_d_out;

                            working_matrix[2] <= qr2_a_out;
                            working_matrix[7] <= qr2_b_out;
                            working_matrix[8] <= qr2_c_out;
                            working_matrix[13] <= qr2_d_out;

                            working_matrix[3] <= qr3_a_out;
                            working_matrix[4] <= qr3_b_out;
                            working_matrix[9] <= qr3_c_out;
                            working_matrix[14] <= qr3_d_out;

                            round_state <= ROUND_COL;
                            round_counter <= round_counter + 1;
                        end
                    end
                end

                F_ADD : begin 
                    for (i = 0; i < 16; i = i + 1) begin
                        temp_sum = working_matrix[i] + initial_matrix[i];
                        
                        // endianess icin buranin degistirilmesi lazim 
                        // su an little endian da
                        keystream[i*32 +: 32] <= {
                            temp_sum[7:0],   
                            temp_sum[15:8],
                            temp_sum[23:16],
                            temp_sum[31:24]
                        };
                    end
                    state <= DONE;
                end

                DONE : begin 
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: begin 
                    state <= IDLE;
                end
            endcase
        end
    end

    // bu kisimin clk ile isi yok qr modulleri comb 
    always @(*) begin
        if(round_state == ROUND_COL) begin 
            qr0_a_in = working_matrix[0];
            qr0_b_in = working_matrix[4];
            qr0_c_in = working_matrix[8];
            qr0_d_in = working_matrix[12];

            qr1_a_in = working_matrix[1];
            qr1_b_in = working_matrix[5];
            qr1_c_in = working_matrix[9];
            qr1_d_in = working_matrix[13];

            qr2_a_in = working_matrix[2];
            qr2_b_in = working_matrix[6];
            qr2_c_in = working_matrix[10];
            qr2_d_in = working_matrix[14];
            qr3_a_in = working_matrix[3];
            qr3_b_in = working_matrix[7];
            qr3_c_in = working_matrix[11];
            qr3_d_in = working_matrix[15];

        end
        else begin
            // 0 5 10 15
            qr0_a_in = working_matrix[0];
            qr0_b_in = working_matrix[5];
            qr0_c_in = working_matrix[10];
            qr0_d_in = working_matrix[15];

            qr1_a_in = working_matrix[1];
            qr1_b_in = working_matrix[6];
            qr1_c_in = working_matrix[11];
            qr1_d_in = working_matrix[12];

            qr2_a_in = working_matrix[2];
            qr2_b_in = working_matrix[7];
            qr2_c_in = working_matrix[8];
            qr2_d_in = working_matrix[13];

            qr3_a_in = working_matrix[3];
            qr3_b_in = working_matrix[4];
            qr3_c_in = working_matrix[9];
            qr3_d_in = working_matrix[14];
        end
    end

    assign ready_o = ready;
    assign done_o = done;
    assign keystream_o = keystream;

endmodule