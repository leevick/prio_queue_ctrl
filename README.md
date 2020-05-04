# Priority Queue Controller HDL Implementation

This project aims to design a priority queue controller based on AXI
infrastructures provided by Xilinx Vivado 2019.1 design suite. The packet
storing & forwarding logic is implemented with DMA s2mm & mm2s mechanism. This
controller only handles the storage address & lenght of packets and generate
the appropriate commands to the DMA engine.


# 优先级队列控制器的HDL实现

本项目旨在设计一款基于Xinlinx Vivado 2019.1 AXI IP基础设施的优先级队列控制器。
数据包的存储与转发由DMA s2mm 和 mm2s 机制实现。本控制器仅处理数据包的存储地址
和包长，并根据他们产生正确的控制命令并提供给DMA引擎。
