`default_nettype none

module sys_fsm2 (
    input  wire  i_clk,
    input  wire  i_rst_n,
    input  wire  i_rx,
    input  wire  i_par_en,
    output logic o_shift_en,
    output logic o_busy,
    output logic o_valid,
    output logic o_check_en,
    output logic o_par_chk
);

    typedef enum logic [2:0] {
        IDLE   = 3'b000,
        DATA   = 3'b001,
        PARITY = 3'b010,
        STOP   = 3'b011
    } state_e;

    state_e current_state, next_state;
    logic [2:0] bit_cnt;

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            current_state <= IDLE;
            bit_cnt       <= '0;
        end else begin
            current_state <= next_state;
            if (current_state == DATA) begin
                bit_cnt <= bit_cnt + 1'b1;
            end else begin
                bit_cnt <= '0;
            end
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (!i_rx) next_state = DATA;
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
                if (!i_rx)
                    next_state = DATA;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    assign o_busy     = (current_state != IDLE);
    assign o_shift_en = (current_state == DATA);
    assign o_par_chk  = (current_state == PARITY);
    assign o_check_en = (current_state == STOP);
    assign o_valid    = (current_state == STOP);

endmodule

`default_nettype wire
