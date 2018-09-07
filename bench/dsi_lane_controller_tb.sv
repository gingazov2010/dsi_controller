`timescale 1ns/1ps
module dsi_lane_controller_tb();

bit clk_sys;
bit clk_serdes;
bit clk_serdes_clk;
bit clk_latch;
bit rst_n;
logic [31:0]   iface_write_data;
logic [3:0]    iface_write_strb;
logic          iface_write_rqst;
logic          iface_last_word;
logic          iface_data_rqst;
logic [1:0]    reg_lanes_number = 3;
logic          lines_enable;
logic          clock_enable;
logic          lines_ready;
logic          clock_ready;
logic          data_underflow_error;
logic  [3:0]   hs_lane_output;
logic          LP_p_output;
logic          LP_n_output;
logic          clock_LP_p_output;
logic          clock_LP_n_output;
logic          clock_hs_output;

dsi_lanes_controller dsi_lanes_controller_0(
    .clk_sys                    (clk_sys                ),
    .clk_serdes                 (clk_serdes             ),
    .clk_serdes_clk             (clk_serdes_clk         ),
    .clk_latch                  (clk_latch              ),
    .rst_n                      (rst_n                  ),
    .iface_write_data           (iface_write_data       ),
    .iface_write_strb           (iface_write_strb       ),
    .iface_write_rqst           (iface_write_rqst       ),
    .iface_last_word            (iface_last_word        ),
    .iface_data_rqst            (iface_data_rqst        ),
    .reg_lanes_number           (reg_lanes_number       ),
    .lines_enable               (lines_enable           ),
    .clock_enable               (clock_enable           ),
    .lines_ready                (lines_ready            ),
    .clock_ready                (clock_ready            ),
    .hs_lane_output             (hs_lane_output         ),
    .LP_p_output                (LP_p_output            ),
    .LP_n_output                (LP_n_output            ),
    .clock_LP_p_output          (clock_LP_p_output      ),
    .clock_LP_n_output          (clock_LP_n_output      ),
    .clock_hs_output            (clock_hs_output        )
);

initial begin
clk_sys             = 1;
clk_latch           = 1;
clk_serdes          = 1;
clk_serdes_clk      = 1;
rst_n               = 0;

#100
wait(10) @(posedge clk_sys)
rst_n = 1;
end

always
    #5 clk_sys = ~clk_sys;

always
begin
    #6.25 clk_latch = 1;
    #3.75 clk_latch = ~clk_latch;
end

always
    #0.625 clk_serdes      = ~clk_serdes;

always
    #0.625 clk_serdes_clk  = ~clk_serdes_clk;

/********************************************************************
                    Generate data array
********************************************************************/
integer data_size = 0;
bit [31:0] data_array [0:64];


initial begin
iface_write_rqst = 0;
iface_write_data = 0;
iface_write_strb = 0;
iface_last_word = 0;
lines_enable = 0;
clock_enable = 0;

wait(rst_n);
repeat(10) @(posedge clk_sys);
lines_enable = 1;
wait(lines_ready);
repeat(10) @(posedge clk_sys);

clock_enable = 1;

wait(clock_ready);

repeat(20) @(posedge clk_sys);

write_data();

end // initial


task write_data;

    integer data_size;
    bit [31:0] data_array [0:64];
    integer total_cycles;
    integer data_left;
    integer i;
    data_size = $urandom_range(4,256);
    $display("Data size %d", data_size);


    for (i = 0; i < data_size; i++) begin
        data_array[i] = $urandom_range(0,32'hffff_ffff);
    end

    total_cycles = data_size/4 + (data_size%4 ? 1 : 0);

    $display("Total cycles %d", total_cycles);

    data_left = data_size;
    i = 0;
    iface_write_data = data_array[i];
    iface_write_strb = 4'hf;
    iface_write_rqst = 1;
    i = i + 1;

    while(i <= total_cycles) begin
        repeat(1) @(posedge clk_sys);
        if(iface_data_rqst)
        begin
             $display($time()," Current data %h", data_array[i]);
             $display($time()," Index %h", i);
            #0.01 iface_write_data = data_array[i];
            iface_write_strb = data_left >= 4 ? 4'hf : (4'hf >> (4 - data_left));

            iface_write_rqst = 1;

            if(i == total_cycles)
                iface_last_word = 1;
            else
                iface_last_word = 0;

            i = i + 1;
            data_left = data_left >= 4 ? data_left - 4 : 0;
            $display($time()," Data left %h", data_left);
        end
    end
    repeat(1) @(posedge clk_sys);

    iface_write_rqst = 0;
    iface_last_word = 0;
    iface_write_strb = 0;

endtask

endmodule

