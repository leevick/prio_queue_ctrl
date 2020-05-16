`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/16/2020 03:16:47 PM
// Design Name: 
// Module Name: prio_queue_ctrl_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module prio_queue_ctrl_tb(

    );

    wire axis_aclk;
    wire axis_aresetn;

    clk_gen_sim_0 clk_gen_inst (
        .axi_clk_0(axis_aclk),
        .axi_rst_0_n(axis_aresetn)
    );


    reg[47:0] s_axis_s2mm_tdata;
    wire s_axis_s2mm_tready;
    reg s_axis_s2mm_tvalid;
    reg[7:0] s_axis_s2mm_tdest;

    prio_queue_ctrl # 
    (
        .C_NID_WIDTH(5),
        .C_PRIO_WIDTH(3),
        .C_ADDR_WIDTH(32),
        .C_BTT_WIDTH(16),
        .C_SEQ_WIDTH(1)
    )
    prio_queue_inst
    (
        .axis_aclk(axis_aclk),
        .axis_aresetn(axis_aresetn),
        .s_axis_s2mm_tdest(s_axis_s2mm_tdest),
        .s_axis_s2mm_tdata(s_axis_s2mm_tdata),
        .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid),
        .s_axis_s2mm_tready(s_axis_s2mm_tready),
        .m_axis_mm2s_tdest(),
        .m_axis_mm2s_tdata(),
        .m_axis_mm2s_tvalid(),
        .m_axis_mm2s_tready(0)
    );
    
    reg[5:0] i = 0;
    reg[3:0] j = 0;
    initial begin
        s_axis_s2mm_tdata <= 0;
        s_axis_s2mm_tdest <= 0;
        s_axis_s2mm_tvalid <= 0;
        @(posedge axis_aresetn);
        #1000;
        @(posedge axis_aclk);
        
        for (i = 0;i<32;i=i+1) begin
        for (j = 0;j<8;j=j+1) begin
            s_axis_s2mm_tdata <= {27'b0,i[4:0],4'b0,i[4:0]};
            s_axis_s2mm_tvalid <= 1;
            s_axis_s2mm_tdest <= {i[4:0],j[2:0]};
            @(posedge axis_aclk);
        end
        end
        s_axis_s2mm_tdata <= 0;
        s_axis_s2mm_tdest <= 0;
        s_axis_s2mm_tvalid <= 0;
    end


endmodule
