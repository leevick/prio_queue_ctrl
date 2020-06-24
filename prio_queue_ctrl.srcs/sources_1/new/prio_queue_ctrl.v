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
    parameter  C_NID_WIDTH = 5,
    parameter  C_PRIO_WIDTH = 3,
    parameter  C_ADDR_WIDTH = 32,
    parameter  C_BTT_WIDTH = 16,
    parameter  C_SEQ_WIDTH = 12
)
(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 axis_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS_S2MM:M_AXIS_MM2S, ASSOCIATED_RESET axis_aresetn, FREQ_HZ 100000000" *)
    input axis_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 axis_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input axis_aresetn,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM TDEST" *)
    input [C_NID_WIDTH+C_PRIO_WIDTH-1:0] s_axis_s2mm_tdest,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM TDATA" *)
    input [C_ADDR_WIDTH+C_BTT_WIDTH-1:0] s_axis_s2mm_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM TVALID" *)
    input s_axis_s2mm_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM TREADY" *)
    output s_axis_s2mm_tready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S TDEST" *)
    output [C_NID_WIDTH-1:0] m_axis_mm2s_tdest,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S TDATA" *)
    output [63:0] m_axis_mm2s_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S TVALID" *)
    output m_axis_mm2s_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_MM2S TREADY" *)
    input m_axis_mm2s_tready,    //

    input xfer_valid,
    input[C_BTT_WIDTH-1:0] xfer_btt,
    input[C_NID_WIDTH-1:0] xfer_dest,

    output xfer_cmplt   //

    // input mpr_flags_valid,
    // input[2**(C_NID_WIDTH+C_PRIO_WIDTH)-1:0] mpr_flags

);

    localparam IDLE = 0;
    localparam LOAD_SWITCHER = 1;
    localparam PUSH = 2;
    
    localparam XFER_INIT = 1;
    localparam XFER_PREPARE = 2;
    localparam POP = 3;
    localparam SWITCH_NEXT = 4;
    localparam XFER_CMPLT = 5;

    reg[2**C_NID_WIDTH-1:0] mpr_flags = {2**(C_NID_WIDTH-1){1'b01}};
    reg[C_SEQ_WIDTH-1:0] seq[0:2**C_NID_WIDTH-1];   //Sequence number for each neighbor
    
    wire[2 ** (C_PRIO_WIDTH + C_NID_WIDTH) - 1:0] s_tvalid;
    wire[C_ADDR_WIDTH+C_BTT_WIDTH-1:0] s_tdata[0:2 ** (C_PRIO_WIDTH + C_NID_WIDTH) - 1];
    wire[2 ** (C_PRIO_WIDTH + C_NID_WIDTH) - 1:0] s_tready;

    wire[2 ** (C_PRIO_WIDTH + C_NID_WIDTH) - 1:0] m_tvalid;
    wire[C_ADDR_WIDTH+C_BTT_WIDTH-1:0] m_tdata[0:2 ** (C_PRIO_WIDTH + C_NID_WIDTH) - 1];
    wire[2 ** (C_PRIO_WIDTH + C_NID_WIDTH) - 1:0] m_tready;

    wire m_axis_tvalid;
    wire m_axis_tready;
    wire [C_ADDR_WIDTH+C_BTT_WIDTH-1:0] m_axis_tdata;
    wire [C_NID_WIDTH+C_PRIO_WIDTH-1:0] m_axis_tdest;

    integer incoming_state;
    always @(posedge axis_aclk) begin
    if(!axis_aresetn)
        incoming_state <= IDLE;
    else
    case (incoming_state)
        IDLE:
        if(m_axis_tvalid)
            incoming_state <= LOAD_SWITCHER;
        LOAD_SWITCHER:
            incoming_state <= PUSH;
        PUSH:
            incoming_state <= IDLE;
        default: 
            incoming_state <= IDLE;
    endcase
    end

    integer outgoing_state;
    reg[C_NID_WIDTH-1:0] xfer_nid;
    reg[C_BTT_WIDTH-1:0] xfer_btt_accum = 0;
    reg[C_BTT_WIDTH-1:0] xfer_btt_total;
    reg[C_PRIO_WIDTH-1:0] xfer_switch = 0;
    
    wire xfer_switch_next = outgoing_state == SWITCH_NEXT ? 1 : 0;
    wire xfer_switch_clr = outgoing_state == XFER_INIT ? 1 : 0;
    assign xfer_cmplt = outgoing_state == XFER_CMPLT ? 1 : 0;

    wire m_xfer_tvalid = m_tvalid[{xfer_nid,xfer_switch}];
    wire [C_ADDR_WIDTH+C_BTT_WIDTH-1:0] m_xfer_tdata = m_tdata[{xfer_nid,xfer_switch}];
    wire [C_NID_WIDTH-1:0] m_xfer_tdest = xfer_nid;

    wire[C_BTT_WIDTH-1:0] xfer_len = m_xfer_tdata[C_BTT_WIDTH-1:0];

    genvar i,j;
    generate
    for (i = 0;i < 2 ** C_NID_WIDTH;i = i + 1) begin
    for (j = 0;j < 2 ** C_PRIO_WIDTH;j = j + 1) begin
        assign m_tready[i*(2**C_PRIO_WIDTH)+j] = outgoing_state == POP && {xfer_nid,xfer_switch} == i*(2**C_PRIO_WIDTH)+j ? 1 : 0;
    end
    end
    endgenerate

    //xfer btt & dest buffer
    always @(posedge axis_aclk)
    if (!axis_aresetn) begin
        xfer_btt_total <= 0;
        xfer_nid <= 0;
    end else if (xfer_valid) begin
        xfer_btt_total <= xfer_btt;
        xfer_nid <= xfer_dest;
    end

    //xfer accumulator
    wire xfer_btt_accum_clr = outgoing_state == XFER_INIT ? 1 : 0;
    wire xfer_btt_accum_enb = outgoing_state == POP && m_xfer_tvalid ? 1 : 0;
    always @(posedge axis_aclk)
    if (!axis_aresetn || xfer_btt_accum_clr)
        xfer_btt_accum <= 0;
    else if (xfer_btt_accum_enb)
        xfer_btt_accum <= xfer_btt_accum + xfer_len;


    //xfer switch instance
    always @(posedge axis_aclk)
    if (!axis_aresetn || xfer_switch_clr)
        xfer_switch <= 2 ** C_PRIO_WIDTH-1;
    else if (xfer_switch_next)
        xfer_switch <= xfer_switch - 1;

    //seq num instance
    wire[2**C_NID_WIDTH-1:0] pop;
    genvar k;
    generate
    for(k=0;k<2 ** C_NID_WIDTH;k = k + 1) begin
        assign pop[k] = outgoing_state == POP && m_xfer_tvalid && xfer_nid == k ? 1 : 0;
    always @(posedge axis_aclk)
    if(!axis_aresetn)
        seq[k] <= 0;
    else if (pop[k])
        seq[k] <= seq[k] + 1;
    end
    endgenerate

    wire[63:0] s_axis_tdata = {4'b0,seq[xfer_nid],m_xfer_tdata};
    wire s_axis_tready;
    wire s_axis_tvalid = outgoing_state == POP && m_xfer_tvalid ? 1 : 0;
    wire[C_NID_WIDTH-1:0] s_axis_tdest = xfer_dest;

    always @(posedge axis_aclk) begin
    if(!axis_aresetn)
        outgoing_state <= IDLE;
    else
    case (outgoing_state)
        IDLE:
        if (xfer_valid)
            outgoing_state <= XFER_INIT;
        XFER_INIT:
            outgoing_state <= XFER_PREPARE;
        XFER_PREPARE:
        if (m_xfer_tvalid)
            outgoing_state <= POP;
        else
            outgoing_state <= SWITCH_NEXT;
        POP:
        if (m_xfer_tvalid)
            if (xfer_btt_accum + xfer_len > xfer_btt_total)
            outgoing_state <= XFER_CMPLT;
            else
            outgoing_state <= POP;
        else
            if (xfer_switch == 0)
            outgoing_state <= XFER_CMPLT;
            else
            outgoing_state <= SWITCH_NEXT;
        SWITCH_NEXT:
            if (xfer_switch == 0)
            outgoing_state <= XFER_CMPLT;
            else
            outgoing_state <= XFER_PREPARE;
        XFER_CMPLT:
            outgoing_state <= IDLE;
        default: 
            outgoing_state <= IDLE;
    endcase
    end

    //Switcher instance
    wire switcher_enb = incoming_state == LOAD_SWITCHER ? 1 : 0;
    reg[2**(C_NID_WIDTH+C_PRIO_WIDTH)-1:0] switcher;
    reg[C_NID_WIDTH+C_PRIO_WIDTH:0] index = 0;
    //reg[C_NID_WIDTH+C_PRIO_WIDTH-1:0] index;
    always @(posedge axis_aclk)
    if(!axis_aresetn)
        switcher <= 0;
    else if (switcher_enb) begin
    //Process broadcast message
    if (m_axis_tdest[C_NID_WIDTH+C_PRIO_WIDTH-1-:C_NID_WIDTH] == {C_NID_WIDTH{1'b1}}) begin
        for (index = 0;index < 2**(C_NID_WIDTH+C_PRIO_WIDTH);index = index+1) begin
            if (m_axis_tdest[C_PRIO_WIDTH-1:0] == index[C_PRIO_WIDTH-1:0]
                && mpr_flags[index[C_PRIO_WIDTH+C_NID_WIDTH-1-:C_NID_WIDTH]] == 1)
                switcher[index] <= 1;
            else
                switcher[index] <= 0;
        end
    //Process unicast message
    end else begin
        for (index = 0;index < 2**(C_NID_WIDTH+C_PRIO_WIDTH);index = index+1) begin
            if (index[C_NID_WIDTH+C_PRIO_WIDTH-1:0] == m_axis_tdest)
                switcher[index] <= 1;
            else
                switcher[index] <= 0;
        end
    end
    end else begin
        switcher <= 0;
    end

    

    genvar l;
    generate
    for (l = 0;l < 2 ** (C_PRIO_WIDTH + C_NID_WIDTH) ;l = l + 1 ) begin
        assign s_tdata[l] = switcher[l] ? m_axis_tdata : 0;
        assign s_tvalid[l] = switcher[l] ? 1 : 0;
        axis_data_fifo_0 fifo_inst (
            .s_axis_aresetn(axis_aresetn),
            .s_axis_aclk(axis_aclk),
            .s_axis_tvalid(s_tvalid[l]),
            .s_axis_tready(),
            .s_axis_tdata(s_tdata[l]),
            .m_axis_aclk(axis_aclk),
            .m_axis_tvalid(m_tvalid[l]),
            .m_axis_tready(m_tready[l]),
            .m_axis_tdata(m_tdata[l])
        );
    end
    endgenerate

    assign m_axis_tready = incoming_state == PUSH ? 1 : 0;
    axis_data_fifo_1 fifo_incoming_input_inst (
        .s_axis_aresetn(axis_aresetn),
        .s_axis_aclk(axis_aclk),
        .s_axis_tvalid(s_axis_s2mm_tvalid),
        .s_axis_tready(s_axis_s2mm_tready),
        .s_axis_tdata(s_axis_s2mm_tdata),
        .s_axis_tdest(s_axis_s2mm_tdest),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tdest(m_axis_tdest)
    );

    axis_data_fifo_2 fifo_outgoing_output_inst (
        .s_axis_aresetn(axis_aresetn),
        .s_axis_aclk(axis_aclk),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tdest(s_axis_tdest),
        .m_axis_tvalid(m_axis_mm2s_tvalid),
        .m_axis_tready(m_axis_mm2s_tready),
        .m_axis_tdata(m_axis_mm2s_tdata),
        .m_axis_tdest(m_axis_mm2s_tdest)
    );
    
endmodule
