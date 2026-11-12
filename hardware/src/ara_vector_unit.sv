// Description:
// The vector half of ara_system: Ara or AraXL only. In multithreading, one instance is shared by all hosts.
// The invalidation filters live in the hosts (host_system); this module exports its AXI


module ara_vector_unit import axi_pkg::*; import ara_pkg::*; #(
    parameter int unsigned NrHosts      = 2,
    parameter int unsigned NrLanes      = 0,
    parameter int unsigned NrClusters   = 0,
    parameter fpu_support_e   FPUSupport   = FPUSupportHalfSingleDouble,
    parameter fpext_support_e FPExtSupport = FPExtSupportEnable,
    parameter fixpt_support_e FixPtSupport = FixedPointEnable,
    parameter config_pkg::cva6_cfg_t CVA6Cfg = cva6_config_pkg::cva6_cfg,
    parameter type exception_t        = logic,
    parameter type accelerator_req_t  = logic,
    parameter type accelerator_resp_t = logic,
    parameter type acc_mmu_req_t      = logic,
    parameter type acc_mmu_resp_t     = logic,
    parameter type cva6_to_acc_t      = logic,
    parameter type acc_to_cva6_t      = logic,
    parameter int unsigned AxiAddrWidth        = 64,
    parameter int unsigned AxiIdWidth          = 6,
    parameter int unsigned AxiWideDataWidth    = 64*NrLanes*NrClusters/2,
    parameter int unsigned ClusterAxiDataWidth = 64*NrLanes/2,
    parameter type ara_axi_ar_t    = logic,
    parameter type ara_axi_r_t     = logic,
    parameter type ara_axi_aw_t    = logic,
    parameter type ara_axi_w_t     = logic,
    parameter type ara_axi_b_t     = logic,
    parameter type ara_axi_req_t   = logic,
    parameter type ara_axi_resp_t  = logic,
    parameter type cluster_axi_ar_t   = logic,
    parameter type cluster_axi_r_t    = logic,
    parameter type cluster_axi_aw_t   = logic,
    parameter type cluster_axi_w_t    = logic,
    parameter type cluster_axi_b_t    = logic,
    parameter type cluster_axi_req_t  = logic,
    parameter type cluster_axi_resp_t = logic,
    localparam int unsigned HartIdW = (NrHosts > 1) ? $clog2(NrHosts) : 1
  ) (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic                  scan_enable_i,
    input  logic                  scan_data_i,
    output logic                  scan_data_o,
    // Accelerator port, behind the arbiter
    input  cva6_to_acc_t          acc_req_i,
    input  logic [HartIdW-1:0]    req_hart_i,    // issuing hart, valid with acc_req_i
    output acc_to_cva6_t          acc_resp_o,
    // Memory, with a thread tag per transaction
    output ara_axi_req_t          axi_req_o,
    input  ara_axi_resp_t         axi_resp_i,
    output logic [HartIdW-1:0]    axi_aw_hart_o,
    output logic [HartIdW-1:0]    axi_ar_hart_o
  );

  // PLACEHOLDER thread tag: hart of the most recently accepted instruction
  logic [HartIdW-1:0] last_hart_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin : p_last_hart
    if (!rst_ni)
      last_hart_q <= '0;
    else if (acc_req_i.acc_req.req_valid && acc_resp_o.acc_resp.req_ready)
      last_hart_q <= req_hart_i;
  end
  assign axi_aw_hart_o = last_hart_q;
  assign axi_ar_hart_o = last_hart_q;

`ifndef USE_CLUSTER

  ara #(
    .NrLanes            (NrLanes            ),
    .FPUSupport         (FPUSupport         ),
    .FPExtSupport       (FPExtSupport       ),
    .FixPtSupport       (FixPtSupport       ),
    .CVA6Cfg            (CVA6Cfg            ),
    .exception_t        (exception_t        ),
    .accelerator_req_t  (accelerator_req_t  ),
    .accelerator_resp_t (accelerator_resp_t ),
    .cva6_to_acc_t      (cva6_to_acc_t      ),
    .acc_to_cva6_t      (acc_to_cva6_t      ),
    .AxiDataWidth       (AxiWideDataWidth   ),
    .AxiAddrWidth       (AxiAddrWidth       ),
    .axi_ar_t           (ara_axi_ar_t       ),
    .axi_r_t            (ara_axi_r_t        ),
    .axi_aw_t           (ara_axi_aw_t       ),
    .axi_w_t            (ara_axi_w_t        ),
    .axi_b_t            (ara_axi_b_t        ),
    .axi_req_t          (ara_axi_req_t      ),
    .axi_resp_t         (ara_axi_resp_t     )
  ) i_ara (
    .clk_i              (clk_i              ),
    .rst_ni             (rst_ni             ),
    .scan_enable_i      (scan_enable_i      ),
    .scan_data_i        (1'b0               ),
    .scan_data_o        (/* Unused */       ),
    .cluster_id_i       (id_cluster_t'(0)   ),
    .num_clusters_i     (num_cluster_t'(0)  ),
    // .hart_id_i       (req_hart_i         ), // TODO: add this port to ara / dispatcher
    .acc_req_i          (acc_req_i          ),
    .acc_resp_o         (acc_resp_o         ),
    .axi_req_o          (axi_req_o          ),
    .axi_resp_i         (axi_resp_i         )
  );

`else

  ara_cluster #(
    .NrLanes            (NrLanes             ),
    .NrClusters         (NrClusters          ),
    .FPUSupport         (FPUSupport          ),
    .FPExtSupport       (FPExtSupport        ),
    .FixPtSupport       (FixPtSupport        ),
    .CVA6Cfg            (CVA6Cfg             ),
    .exception_t        (exception_t         ),
    .accelerator_req_t  (accelerator_req_t   ),
    .accelerator_resp_t (accelerator_resp_t  ),
    .cva6_to_acc_t      (cva6_to_acc_t       ),
    .acc_to_cva6_t      (acc_to_cva6_t       ),
    .AxiDataWidth       (AxiWideDataWidth    ),
    .AxiAddrWidth       (AxiAddrWidth        ),
    .ClusterAxiDataWidth(ClusterAxiDataWidth ),
    .axi_ar_t           (ara_axi_ar_t        ),
    .axi_r_t            (ara_axi_r_t         ),
    .axi_aw_t           (ara_axi_aw_t        ),
    .axi_w_t            (ara_axi_w_t         ),
    .axi_b_t            (ara_axi_b_t         ),
    .axi_req_t          (ara_axi_req_t       ),
    .axi_resp_t         (ara_axi_resp_t      ),
    .cluster_axi_ar_t   (cluster_axi_ar_t    ),
    .cluster_axi_r_t    (cluster_axi_r_t     ),
    .cluster_axi_aw_t   (cluster_axi_aw_t    ),
    .cluster_axi_w_t    (cluster_axi_w_t     ),
    .cluster_axi_b_t    (cluster_axi_b_t     ),
    .cluster_axi_req_t  (cluster_axi_req_t   ),
    .cluster_axi_resp_t (cluster_axi_resp_t  )
  ) i_ara_cluster (
    .clk_i              (clk_i               ),
    .rst_ni             (rst_ni              ),
    .scan_enable_i      (scan_enable_i       ),
    .scan_data_i        (1'b0                ),
    .scan_data_o        (/* Unused */        ),
    // .hart_id_i       (req_hart_i          ), // TODO: add this port to ara_cluster / dispatcher
    .acc_req_i          (acc_req_i           ),
    .acc_resp_o         (acc_resp_o          ),
    .axi_req_o          (axi_req_o           ),
    .axi_resp_i         (axi_resp_i          )
  );

`endif

  assign scan_data_o = 1'b0;

endmodule : ara_vector_unit