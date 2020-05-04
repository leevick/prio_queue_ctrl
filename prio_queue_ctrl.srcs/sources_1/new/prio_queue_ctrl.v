`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2020 04:02:16 PM
// Design Name: 
// Module Name: prio_queue_ctrl
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


module prio_queue_ctrl # 
(
    C_NEIGHBOR_WIDTH = 5,
    C_PRIORITY_WIDTH = 3,
    C_BTT_WIDTH = 16
)
(
    input axis_aclk,
    input axis_aresetn,

    input[47:0] s_axis_cmd_tdata,
    input[C_NEIGHBOR_WIDTH+C_PRIORITY_WIDTH-1:0] s_axis_cmd_tdest,
    input s_axis_cmd_tvalid,
    output s_axis_cmd_tready,

    output[63:0] m_axis_mm2s_tdata,
    output m_axis_mm2s_tvalid,
    input m_axis_mm2s_tready,

    input dl_xfer_valid,
    input[C_BTT_WIDTH-1:0] dl_xfer_size,
    input[C_NEIGHBOR_WIDTH-1:0] dl_xfer_dest

);

    genvar i;
    generate
    for(i=0;i<2^(C_NEIGHBOR_WIDTH+C_PRIORITY_WIDTH);i=i+1) 
    begin
        axis_data_fifo_0 (
          .s_axis_aresetn(axis_aresetn),  // input wire s_axis_aresetn
          .s_axis_aclk(axis_aclk),        // input wire s_axis_aclk
          .s_axis_tvalid(s_axis_tvalid),    // input wire s_axis_tvalid
          .s_axis_tready(s_axis_tready),    // output wire s_axis_tready
          .s_axis_tdata(s_axis_tdata),      // input wire [47 : 0] s_axis_tdata
          .m_axis_aclk(m_axis_aclk),        // input wire m_axis_aclk
          .m_axis_tvalid(m_axis_tvalid),    // output wire m_axis_tvalid
          .m_axis_tready(m_axis_tready),    // input wire m_axis_tready
          .m_axis_tdata(m_axis_tdata)      // output wire [47 : 0] m_axis_tdata
        );    
    end
    endgenerate
    
    
    axis_switch_v1_1_19_axis_switch #(
    .C_FAMILY("virtex7"),
    .C_NUM_SI_SLOTS(1),
    .C_LOG_SI_SLOTS(1),
    .C_NUM_MI_SLOTS(2^(C_NEIGHBOR_WIDTH + C_PRIORITY_WIDTH)),
    .C_AXIS_TDATA_WIDTH(48),
    .C_AXIS_TID_WIDTH(1),
    .C_AXIS_TDEST_WIDTH(C_NEIGHBOR_WIDTH + C_PRIORITY_WIDTH),
    .C_AXIS_TUSER_WIDTH(1),
    .C_AXIS_SIGNAL_SET(32'B00000000000000000000000001000011),
    .C_ARB_ON_MAX_XFERS(1),
    .C_ARB_ON_NUM_CYCLES(0),
    .C_ARB_ON_TLAST(0),
    .C_INCLUDE_ARBITER(1),
    .C_ARB_ALGORITHM(0),
    .C_OUTPUT_REG(0),
    .C_DECODER_REG(1),
    .C_ROUTING_MODE(0),
    .C_S_AXI_CTRL_ADDR_WIDTH(7),
    .C_S_AXI_CTRL_DATA_WIDTH(32),
    .C_COMMON_CLOCK(0)
  ) inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .aclken(1'H1),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tstrb(6'H3F),
    .s_axis_tkeep(6'H3F),
    .s_axis_tlast(1'H1),
    .s_axis_tid(1'H0),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(1'H0),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tstrb(),
    .m_axis_tkeep(),
    .m_axis_tlast(),
    .m_axis_tid(),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(),
    .arb_req(),
    .arb_done(),
    .arb_gnt(8'H00),
    .arb_sel(8'H00),
    .arb_last(),
    .arb_id(),
    .arb_dest(),
    .arb_user(),
    .s_req_suppress(1'H0),
    .s_axi_ctrl_aclk(1'H0),
    .s_axi_ctrl_aresetn(1'H0),
    .s_axi_ctrl_awvalid(1'H0),
    .s_axi_ctrl_awready(),
    .s_axi_ctrl_awaddr(7'H00),
    .s_axi_ctrl_wvalid(1'H0),
    .s_axi_ctrl_wready(),
    .s_axi_ctrl_wdata(32'H00000000),
    .s_axi_ctrl_bvalid(),
    .s_axi_ctrl_bready(1'H0),
    .s_axi_ctrl_bresp(),
    .s_axi_ctrl_arvalid(1'H0),
    .s_axi_ctrl_arready(),
    .s_axi_ctrl_araddr(7'H00),
    .s_axi_ctrl_rvalid(),
    .s_axi_ctrl_rready(1'H0),
    .s_axi_ctrl_rdata(),
    .s_axi_ctrl_rresp(),
    .s_decode_err(s_decode_err)
  );
    
    

    
endmodule
