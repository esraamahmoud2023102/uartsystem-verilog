`default_nettype none

module uart_rx #(
    parameter integer DATA_W = 8
)(
    input  wire                i_clk,
    input  wire                i_rst_n,
    input  wire                i_rx,
    input  wire                i_par_en,
    input  wire                i_par_odd,
    output logic [DATA_W-1:0]  o_data,
    output logic               o_valid,
    output logic               o_busy,
    output logic               o_parity_err,
    output logic               o_frame_err
);

    logic              shift_en;
    logic              check_en;
    logic              par_chk;
    logic              raw_parity_err;
    logic              raw_frame_err;
    logic [DATA_W-1:0] internal_data;
    logic              saved_parity_bit;

    assign o_data = internal_data;

    sys_deserializer #(
        .DATA_W(DATA_W)
    ) u_deserializer (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_rx       (i_rx),
        .i_shift_en (shift_en),
        .o_data     (internal_data)
    );

    // تخزين بت الباريتي فقط أثناء تفعيل إشارة par_chk
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            saved_parity_bit <= 1'b0;
        end else if (par_chk) begin
            saved_parity_bit <= i_rx;
        end
    end

    sys_parity_check u_parity_check (
        .i_data       (internal_data),
        .i_par_odd    (i_par_odd),
        .i_par_bit    (saved_parity_bit),
        .o_parity_err (raw_parity_err)
    );

    sys_stop_check u_stop_check (
        .i_rx         (i_rx),
        .o_frame_err  (raw_frame_err)
    );

    sys_fsm2 u_fsm2 (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_rx       (i_rx),
        .i_par_en   (i_par_en),
        .o_shift_en (shift_en),
        .o_busy     (o_busy),
        .o_valid    (o_valid),
        .o_check_en (check_en),
        .o_par_chk  (par_chk)
    );

    assign o_parity_err = (check_en && i_par_en) ? raw_parity_err : 1'b0;
    assign o_frame_err  = check_en ? raw_frame_err : 1'b0;

endmodule

`default_nettype wire
