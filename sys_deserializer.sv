`default_nettype none

module sys_deserializer #(
    parameter integer DATA_W = 8
)(
    input  wire                i_clk,
    input  wire                i_rst_n,
    input  wire                i_rx,
    input  wire                i_shift_en,
    output logic [DATA_W-1:0]  o_data
);

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_data <= '0;
        end else if (i_shift_en) begin
            o_data <= {i_rx, o_data[DATA_W-1:1]};
        end
    end

endmodule

`default_nettype wire


