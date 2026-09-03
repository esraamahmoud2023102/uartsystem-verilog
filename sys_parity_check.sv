
`default_nettype none

module sys_parity_check (
    input  wire [7:0] i_data,
    input  wire       i_par_odd,
    input  wire       i_par_bit,
    output logic      o_parity_err
);

    logic calc_parity;

    assign calc_parity = i_par_odd ? ~(^i_data) : (^i_data);
    assign o_parity_err = (calc_parity != i_par_bit);

endmodule

`default_nettype wire
