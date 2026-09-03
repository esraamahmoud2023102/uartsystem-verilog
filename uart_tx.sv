
`default_nettype none

module uart_tx #(
    parameter integer DATA_W = 8
)(
    input  wire                i_clk,
    input  wire                i_rst_n,
    input  wire [DATA_W-1:0]   i_data,
    input  wire                i_valid,
    input  wire                i_par_en,
    input  wire                i_par_odd,
    output logic               o_tx,
    output logic               o_busy
);

    typedef enum logic [2:0] {
        IDLE   = 3'b000,
        START  = 3'b001,
        DATA   = 3'b010,
        PARITY = 3'b011,
        STOP   = 3'b100
    } state_e;

    state_e current_state, next_state;

    logic [DATA_W-1:0] tx_reg;
    logic [2:0]        bit_cnt;
    logic              parity_bit;

    // Fast Parity Generation
    assign parity_bit = i_par_odd ? ~(^tx_reg) : (^tx_reg);

    // State Register
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Data Register & Counter Logic
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            tx_reg  <= '0;
            bit_cnt <= '0;
        end else begin
            if (current_state == IDLE && i_valid) begin
                tx_reg  <= i_data;
                bit_cnt <= '0;
            end else if (current_state == DATA) begin
                tx_reg  <= {1'b0, tx_reg[DATA_W-1:1]};
                bit_cnt <= bit_cnt + 1'b1;
            end else if (current_state != DATA) begin
                bit_cnt <= '0;
            end
        end
    end

    // Next State Logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (i_valid) next_state = START;
            end
            START: begin
                next_state = DATA;
            end
            DATA: begin
                if (bit_cnt == 3'd7) begin
                    if (i_par_en)
                        next_state = PARITY;
                    else
                        next_state = STOP;
                end
            end
            PARITY: begin
                next_state = STOP;
            end
            STOP: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output Mapping
    always_comb begin
        case (current_state)
            IDLE:   o_tx = 1'b1;
            START:  o_tx = 1'b0;
            DATA:   o_tx = tx_reg[0];
            PARITY: o_tx = parity_bit;
            STOP:   o_tx = 1'b1;
            default: o_tx = 1'b1;
        endcase
    end

    assign o_busy = (current_state != IDLE);

endmodule

`default_nettype wire