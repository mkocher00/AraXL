// Copyright 2021-2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Matheus Cavalcante <matheusd@iis.ee.ethz.ch>
//         Maximilian Kocher <et16koma@gmail.com>
// Description:
// Host system: ara_system with the vector unit removed. Contains CVA6, its AXI path and
// its own axi_inval_filter. 

module host_system import axi_pkg::*; import ara_pkg::*; #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = cva6_config_pkg::cva6_cfg,
    parameter type              exception_t        = logic,
    parameter type              accelerator_req_t  = logic,
    parameter type              accelerator_resp_t = logic,
    parameter type              acc_mmu_req_t      = logic,
    parameter type              acc_mmu_resp_t     = logic,
    parameter type              cva6_to_acc_t      = logic,
    parameter type              acc_to_cva6_t      = logic,
    // AXI Interface
    parameter int      unsigned AxiAddrWidth       = 64,
    parameter int      unsigned AxiIdWidth         = 6,
    parameter int      unsigned AxiNarrowDataWidth = 64,
    parameter int      unsigned AxiWideDataWidth   = 64, // 64*NrLanes*NrClusters/2 (but takes it from a higher level file (ara_sysstem.sv
    parameter type              ariane_axi_ar_t    = logic,
    parameter type              ariane_axi_r_t     = logic,
    parameter type              ariane_axi_aw_t    = logic,
    parameter type              ariane_axi_w_t     = logic,
    parameter type              ariane_axi_b_t     = logic,
    parameter type              ariane_axi_req_t   = logic,
    parameter type              ariane_axi_resp_t  = logic,
    parameter type              ara_axi_ar_t       = logic,
    parameter type              ara_axi_r_t        = logic,
    parameter type              ara_axi_aw_t       = logic,
    parameter type              ara_axi_w_t        = logic,
    parameter type              ara_axi_b_t        = logic,
    parameter type              ara_axi_req_t      = logic,
    parameter type              ara_axi_resp_t     = logic,
    parameter type              system_axi_ar_t    = logic,
    parameter type              system_axi_r_t     = logic,
    parameter type              system_axi_aw_t    = logic,
    parameter type              system_axi_w_t     = logic,
    parameter type              system_axi_b_t     = logic,
    parameter type              system_axi_req_t   = logic,
    parameter type              system_axi_resp_t  = logic
  ) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic             [63:0] boot_addr_i,
    input                     [2:0] hart_id_i,
    // Scan chain
    input  logic                    scan_enable_i,
    input  logic                    scan_data_i,
    output logic                    scan_data_o,
    // AXI (scalar traffic only)
    output system_axi_req_t         axi_req_o,
    input  system_axi_resp_t        axi_resp_i,
    // Vector AXI traffic steered to this host by the thread tag
    input  ara_axi_req_t            vec_axi_req_i,
    output ara_axi_resp_t           vec_axi_resp_o,
    // Accelerator interface, exported to the shared vector unit
    output cva6_to_acc_t            acc_req_o,
    input  acc_to_cva6_t            acc_resp_i
  );

  `include "axi/assign.svh"
  `include "axi/typedef.svh"

  ariane_axi_req_t  ariane_narrow_axi_req;
  ariane_axi_resp_t ariane_narrow_axi_resp;
  ara_axi_req_t     ariane_axi_req;
  ara_axi_resp_t    ariane_axi_resp;

// Accelerator ports
 cva6_to_acc_t            acc_req;
  acc_to_cva6_t            acc_resp_pack;
  ara_axi_req_t            vec_axi_req_inval;
  ara_axi_resp_t           vec_axi_resp_inval;
  logic [AxiAddrWidth-1:0] inval_addr;
  logic                    inval_valid, inval_ready, acc_cons_en;
  logic [63:0] hart_id;
  assign hart_id = {'0, hart_id_i};

 

  assign acc_req_o = acc_req;

  // Pack this host's invalidation interface into acc  (as in ara_system)
  always_comb begin : pack_inval
    acc_resp_pack                      = acc_resp_i;
    acc_resp_pack.acc_resp.inval_valid = inval_valid;
    acc_resp_pack.acc_resp.inval_addr  = inval_addr;
    inval_ready                        = acc_req.acc_req.inval_ready;
    acc_cons_en                        = acc_req.acc_req.acc_cons_en;
  end

`ifdef IDEAL_DISPATCHER
  // Perfect dispatcher to Ara
  accel_dispatcher_ideal   #(
    .CVA6Cfg           (CVA6Cfg              ),
    .cva6_to_acc_t     (cva6_to_acc_t        ),
    .acc_to_cva6_t     (acc_to_cva6_t        )
  ) i_accel_dispatcher_ideal (
    .clk_i            (clk_i                 ),
    .rst_ni           (rst_ni                ),
    .acc_req_o        (acc_req               ),
    .acc_resp_i       (acc_resp_i            )
    // .acc_resp_valid_i (acc_resp_valid     ),
    // .acc_resp_ready_o (acc_resp_ready     )
  );
`else
  cva6 #(
    .CVA6Cfg          (CVA6Cfg           ),
    .cvxif_req_t      (cva6_to_acc_t     ),
    .cvxif_resp_t     (acc_to_cva6_t     ),
    .axi_ar_chan_t    (ariane_axi_ar_t   ),
    .axi_aw_chan_t    (ariane_axi_aw_t   ),
    .axi_w_chan_t     (ariane_axi_w_t    ),
    .b_chan_t         (ariane_axi_b_t    ),
    .r_chan_t         (ariane_axi_r_t    ),
    .noc_req_t        (ariane_axi_req_t  ),
    .noc_resp_t       (ariane_axi_resp_t ),
    .accelerator_req_t (accelerator_req_t),
    .accelerator_resp_t(accelerator_resp_t),
    .acc_mmu_req_t     (acc_mmu_req_t     ),
    .acc_mmu_resp_t    (acc_mmu_resp_t    )
  ) i_ariane (
    .clk_i            (clk_i                   ),
    .rst_ni           (rst_ni                  ),
    .boot_addr_i      (boot_addr_i             ),
    .hart_id_i        (hart_id                 ),
    .irq_i            ('0                      ),
    .ipi_i            ('0                      ),
    .time_irq_i       ('0                      ),
    .debug_req_i      ('0                      ),
    .clic_irq_valid_i ('0                      ),
    .clic_irq_id_i    ('0                      ),
    .clic_irq_level_i ('0                      ),
    .clic_irq_priv_i  (riscv::priv_lvl_t'(2'b0)),
    .clic_irq_v_i     ('0                      ),
    .clic_irq_vsid_i  ('0                      ),
    .clic_irq_shv_i   ('0                      ),
    .clic_irq_ready_o (/* empty */             ),
    .clic_kill_req_i  ('0                      ),
    .clic_kill_ack_o  (/* empty */             ),
    .rvfi_probes_o    (/* empty */             ),
    // Accelerator ports
    .cvxif_req_o      (acc_req                 ),
    .cvxif_resp_i     (acc_resp_pack           ),
    .noc_req_o        (ariane_narrow_axi_req   ),
    .noc_resp_i       (ariane_narrow_axi_resp  )
  );
`endif

  axi_dw_converter #(
    .AxiSlvPortDataWidth(AxiNarrowDataWidth),
    .AxiMstPortDataWidth(AxiWideDataWidth  ),
    .AxiAddrWidth       (AxiAddrWidth      ),
    .AxiIdWidth         (AxiIdWidth        ),
    .AxiMaxReads        (2                 ),
    .ar_chan_t          (ariane_axi_ar_t   ),
    .mst_r_chan_t       (ara_axi_r_t       ),
    .slv_r_chan_t       (ariane_axi_r_t    ),
    .aw_chan_t          (ariane_axi_aw_t   ),
    .b_chan_t           (ariane_axi_b_t    ),
    .mst_w_chan_t       (ara_axi_w_t       ),
    .slv_w_chan_t       (ariane_axi_w_t    ),
    .axi_mst_req_t      (ara_axi_req_t     ),
    .axi_mst_resp_t     (ara_axi_resp_t    ),
    .axi_slv_req_t      (ariane_axi_req_t  ),
    .axi_slv_resp_t     (ariane_axi_resp_t )
  ) i_ariane_axi_dwc (
    .clk_i     (clk_i                 ),
    .rst_ni    (rst_ni                ),
`ifdef IDEAL_DISPATCHER
    .slv_req_i ('0                    ),
`else
    .slv_req_i (ariane_narrow_axi_req ),
`endif
    .slv_resp_o(ariane_narrow_axi_resp),
    .mst_req_o (ariane_axi_req        ),
    .mst_resp_i(ariane_axi_resp       )
  );
  
  axi_inval_filter #(
    .MaxTxns    (16                             ),
    .AddrWidth  (AxiAddrWidth                   ),
    .NumSets    (CVA6Cfg.DCACHE_NUM_WORDS       ),
    .L1LineWidth(CVA6Cfg.DCACHE_LINE_WIDTH/8    ),
    .aw_chan_t  (ara_axi_aw_t                   ),
    .req_t      (ara_axi_req_t                  ),
    .resp_t     (ara_axi_resp_t                 )
  ) i_axi_inval_filter (
    .clk_i        (clk_i             ),
    .rst_ni       (rst_ni            ),
`ifdef IDEAL_DISPATCHER
    .en_i         (1'b0              ),
`else
    .en_i         (acc_cons_en       ),
`endif
    .slv_req_i    (vec_axi_req_i     ),
    .slv_resp_o   (vec_axi_resp_o    ),
    .mst_req_o    (vec_axi_req_inval ),
    .mst_resp_i   (vec_axi_resp_inval),
    .inval_addr_o (inval_addr        ),
    .inval_valid_o(inval_valid       ),
`ifdef IDEAL_DISPATCHER
    .inval_ready_i(1'b0              )
`else
    .inval_ready_i(inval_ready       )
`endif
  );

  // Same mux as in ara_system: CVA6 traffic on port 0, filtered vector traffic on port 1.

  axi_mux #(
    .SlvAxiIDWidth(AxiIdWidth       ),
    .slv_ar_chan_t(ara_axi_ar_t     ),
    .slv_aw_chan_t(ara_axi_aw_t     ),
    .slv_b_chan_t (ara_axi_b_t      ),
    .slv_r_chan_t (ara_axi_r_t      ),
    .slv_req_t    (ara_axi_req_t    ),
    .slv_resp_t   (ara_axi_resp_t   ),
    .mst_ar_chan_t(system_axi_ar_t  ),
    .mst_aw_chan_t(system_axi_aw_t  ),
    .w_chan_t     (system_axi_w_t   ),
    .mst_b_chan_t (system_axi_b_t   ),
    .mst_r_chan_t (system_axi_r_t   ),
    .mst_req_t    (system_axi_req_t ),
    .mst_resp_t   (system_axi_resp_t),
    .NoSlvPorts   (2                ),
    .SpillAr      (1'b1             ),
    .SpillR       (1'b1             ),
    .SpillAw      (1'b1             ),
    .SpillW       (1'b1             ),
    .SpillB       (1'b1             )
  ) i_system_mux (
    .clk_i      (clk_i                              ),
    .rst_ni     (rst_ni                             ),
    .test_i     (1'b0                               ),
    .slv_reqs_i ({vec_axi_req_inval, ariane_axi_req}  ),
    .slv_resps_o({vec_axi_resp_inval, ariane_axi_resp}),
    .mst_req_o  (axi_req_o                          ),
    .mst_resp_i (axi_resp_i                         )
  );

  assign scan_data_o = 1'b0;

endmodule : host_system