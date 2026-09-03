`default_nettype none

module sys_stop_check (
    input  wire i_rx,
    output logic o_frame_err
);

    assign o_frame_err = ~i_rx;

endmodule

`default_nettype wire
