// Description:
// Multithreading abstraction layer. NrHosts scalar Hosts share one vector core. Instanciate it once in ara_soc
// Implements a simple round-robin arbiter for the accelerator interface, and a thread-tag demux for the vector AXI interface.


module ara_multithreading_system import ara_pkg::*; #(
    parameter int unsigned NrHosts             = 2,        
    // RVV parameters
    parameter int unsigned NrVecCores          = 1,
    parameter int unsigned NrLanes             = 0,
    parameter int unsigned NrClusters          = 0,
    parameter fpu_support_e   FPUSupport       = FPUSupportHalfSingleDouble,
    parameter fpext_support_e FPExtSupport     = FPExtSupportEnable,
    parameter fixpt_support_e FixPtSupport     = FixedPointEnable,
    // CVA6 / accelerator interface types
    parameter config_pkg::cva6_cfg_t CVA6Cfg   = cva6_config_pkg::cva6_cfg,
    parameter type exception_t                 = logic,
    parameter type accelerator_req_t           = logic,
    parameter type accelerator_resp_t          = logic,
    parameter type acc_mmu_req_t               = logic,
    parameter type acc_mmu_resp_t              = logic,
    parameter type cva6_to_acc_t               = logic,
    parameter type acc_to_cva6_t               = logic,
    // AXI
    parameter int unsigned AxiAddrWidth        = 64,
    parameter int unsigned AxiIdWidth          = 5,   
    parameter int unsigned AxiNarrowDataWidth  = 64,
    parameter int unsigned AxiWideDataWidth    = 0,
    parameter int unsigned ClusterAxiDataWidth = 0,
    parameter type ara_axi_ar_t                = logic,
    parameter type ara_axi_aw_t                = logic,
    parameter type ara_axi_b_t                 = logic,
    parameter type ara_axi_r_t                 = logic,
    parameter type ara_axi_w_t                 = logic,
    parameter type ara_axi_req_t               = logic,
    parameter type ara_axi_resp_t              = logic,
    parameter type cluster_axi_ar_t            = logic,
    parameter type cluster_axi_aw_t            = logic,
    parameter type cluster_axi_b_t             = logic,
    parameter type cluster_axi_r_t             = logic,
    parameter type cluster_axi_w_t             = logic,
    parameter type cluster_axi_req_t           = logic,
    parameter type cluster_axi_resp_t          = logic,
    parameter type ariane_axi_ar_t             = logic,
    parameter type ariane_axi_aw_t             = logic,
    parameter type ariane_axi_b_t              = logic,
    parameter type ariane_axi_r_t              = logic,
    parameter type ariane_axi_w_t              = logic,
    parameter type ariane_axi_req_t            = logic,
    parameter type ariane_axi_resp_t           = logic,
    parameter type system_axi_ar_t             = logic,
    parameter type system_axi_aw_t             = logic,
    parameter type system_axi_b_t              = logic,
    parameter type system_axi_r_t              = logic,
    parameter type system_axi_w_t              = logic,
    parameter type system_axi_req_t            = logic,
    parameter type system_axi_resp_t           = logic,
    localparam int unsigned HartIdW            = (NrHosts > 1) ? $clog2(NrHosts) : 1
  ) (
    input  logic                             clk_i,
    input  logic                             rst_ni,
    input  logic [63:0]                      boot_addr_i,
    output system_axi_req_t  [NrHosts-1:0]   host_axi_req_o,
    input  system_axi_resp_t [NrHosts-1:0]   host_axi_resp_i
  );

  cva6_to_acc_t [NrHosts-1:0] host_to_acc;
  acc_to_cva6_t [NrHosts-1:0] acc_to_host;

  // Vector AXI: from the vector unit, then steered per thread tag to the hosts
  ara_axi_req_t                vec_axi_req;
  ara_axi_resp_t               vec_axi_resp;
  logic [HartIdW-1:0]          vec_aw_hart, vec_ar_hart;
  ara_axi_req_t  [NrHosts-1:0] vec_to_host_req;
  ara_axi_resp_t [NrHosts-1:0] vec_to_host_resp;

  for (genvar h = 0; h < NrHosts; h++) begin : gen_host
    host_system #(
      .CVA6Cfg           (CVA6Cfg           ),
      .exception_t       (exception_t       ),
      .accelerator_req_t (accelerator_req_t ),
      .accelerator_resp_t(accelerator_resp_t),
      .acc_mmu_req_t     (acc_mmu_req_t     ),
      .acc_mmu_resp_t    (acc_mmu_resp_t    ),
      .cva6_to_acc_t     (cva6_to_acc_t     ),
      .acc_to_cva6_t     (acc_to_cva6_t     ),
      .AxiAddrWidth      (AxiAddrWidth      ),
      .AxiIdWidth        (AxiIdWidth        ),
      .AxiNarrowDataWidth(AxiNarrowDataWidth),
      .AxiWideDataWidth  (AxiWideDataWidth  ),
      .ariane_axi_ar_t   (ariane_axi_ar_t   ),
      .ariane_axi_aw_t   (ariane_axi_aw_t   ),
      .ariane_axi_b_t    (ariane_axi_b_t    ),
      .ariane_axi_r_t    (ariane_axi_r_t    ),
      .ariane_axi_w_t    (ariane_axi_w_t    ),
      .ariane_axi_req_t  (ariane_axi_req_t  ),
      .ariane_axi_resp_t (ariane_axi_resp_t ),
      .ara_axi_ar_t      (ara_axi_ar_t      ),
      .ara_axi_aw_t      (ara_axi_aw_t      ),
      .ara_axi_b_t       (ara_axi_b_t       ),
      .ara_axi_r_t       (ara_axi_r_t       ),
      .ara_axi_w_t       (ara_axi_w_t       ),
      .ara_axi_req_t     (ara_axi_req_t     ),
      .ara_axi_resp_t    (ara_axi_resp_t    ),
      .system_axi_ar_t   (system_axi_ar_t   ),
      .system_axi_aw_t   (system_axi_aw_t   ),
      .system_axi_b_t    (system_axi_b_t    ),
      .system_axi_r_t    (system_axi_r_t    ),
      .system_axi_w_t    (system_axi_w_t    ),
      .system_axi_req_t  (system_axi_req_t  ),
      .system_axi_resp_t (system_axi_resp_t )
    ) i_host (
      .clk_i        (clk_i              ),
      .rst_ni       (rst_ni             ),
      .boot_addr_i  (boot_addr_i        ),
      .hart_id_i    (3'(h)              ), // each host gets a unique hart ID, used for thread tags
      .scan_enable_i(1'b0               ),
      .scan_data_i  (1'b0               ),
      .scan_data_o  (/* Unconnected */  ),
      .axi_req_o    (host_axi_req_o[h]  ),
      .axi_resp_i   (host_axi_resp_i[h] ),
      .vec_axi_req_i (vec_to_host_req[h] ),
      .vec_axi_resp_o(vec_to_host_resp[h]),
      .acc_req_o    (host_to_acc[h]     ),
      .acc_resp_i   (acc_to_host[h]     )
    );
  end : gen_host

  cva6_to_acc_t       shared_to_acc;
  acc_to_cva6_t       shared_from_acc;
  logic [HartIdW-1:0] shared_req_hart;

  mt_arbiter #(
    .NrHosts      (NrHosts      ),
    .cva6_to_acc_t(cva6_to_acc_t),
    .acc_to_cva6_t(acc_to_cva6_t)
  ) i_acc_arbiter (
    .clk_i            (clk_i          ),
    .rst_ni           (rst_ni         ),
    .host_req_i       (host_to_acc    ),
    .host_resp_o      (acc_to_host    ),
    .shared_req_o     (shared_to_acc  ),
    .shared_resp_i    (shared_from_acc)
  );

  ara_vector_unit #(
    .NrHosts            (NrHosts            ),
    .NrVecCores         (NrVecCores         ),
    .NrLanes            (NrLanes            ),
    .NrClusters         (NrClusters         ),
    .FPUSupport         (FPUSupport         ),
    .FPExtSupport       (FPExtSupport       ),
    .FixPtSupport       (FixPtSupport       ),
    .CVA6Cfg            (CVA6Cfg            ),
    .exception_t        (exception_t        ),
    .accelerator_req_t  (accelerator_req_t  ),
    .accelerator_resp_t (accelerator_resp_t ),
    .acc_mmu_req_t      (acc_mmu_req_t      ),
    .acc_mmu_resp_t     (acc_mmu_resp_t     ),
    .cva6_to_acc_t      (cva6_to_acc_t      ),
    .acc_to_cva6_t      (acc_to_cva6_t      ),
    .AxiAddrWidth       (AxiAddrWidth       ),
    .AxiIdWidth         (AxiIdWidth         ),
    .AxiWideDataWidth   (AxiWideDataWidth   ),
    .ClusterAxiDataWidth(ClusterAxiDataWidth),
    .ara_axi_ar_t       (ara_axi_ar_t       ),
    .ara_axi_aw_t       (ara_axi_aw_t       ),
    .ara_axi_b_t        (ara_axi_b_t        ),
    .ara_axi_r_t        (ara_axi_r_t        ),
    .ara_axi_w_t        (ara_axi_w_t        ),
    .ara_axi_req_t      (ara_axi_req_t      ),
    .ara_axi_resp_t     (ara_axi_resp_t     ),
    .cluster_axi_ar_t   (cluster_axi_ar_t   ),
    .cluster_axi_aw_t   (cluster_axi_aw_t   ),
    .cluster_axi_b_t    (cluster_axi_b_t    ),
    .cluster_axi_r_t    (cluster_axi_r_t    ),
    .cluster_axi_w_t    (cluster_axi_w_t    ),
    .cluster_axi_req_t  (cluster_axi_req_t  ),
    .cluster_axi_resp_t (cluster_axi_resp_t )
  ) i_vector_unit (
    .clk_i        (clk_i            ),
    .rst_ni       (rst_ni           ),
    .scan_enable_i(1'b0             ),
    .scan_data_i  (1'b0             ),
    .scan_data_o  (/* Unconnected */),
    .acc_req_i    (shared_to_acc    ),
    .req_hart_i   (shared_req_hart  ),
    .acc_resp_o   (shared_from_acc  ),
    .axi_req_o    (vec_axi_req      ),
    .axi_resp_i   (vec_axi_resp     ),
    .axi_aw_hart_o(vec_aw_hart      ),
    .axi_ar_hart_o(vec_ar_hart      )
  );

  axi_demux #(
    .AxiIdWidth (AxiIdWidth     ),
    .AtopSupport(1'b0           ),   // Ara issues no atomics
    .aw_chan_t  (ara_axi_aw_t   ),
    .w_chan_t   (ara_axi_w_t    ),
    .b_chan_t   (ara_axi_b_t    ),
    .ar_chan_t  (ara_axi_ar_t   ),
    .r_chan_t   (ara_axi_r_t    ),
    .axi_req_t  (ara_axi_req_t  ),
    .axi_resp_t (ara_axi_resp_t ),
    .NoMstPorts (NrHosts        ),
    .MaxTrans   (8              ),
    .AxiLookBits(AxiIdWidth     ),
    .UniqueIds  (1'b0           ),
    .SpillAw    (1'b0           ), // Write address. 0 = spill register deactivated. 
    .SpillW     (1'b0           ), // Write data
    .SpillB     (1'b0           ), // Write response
    .SpillAr    (1'b0           ), // Read address
    .SpillR     (1'b0           )  // Read data
  ) i_vec_axi_demux (
    .clk_i           (clk_i           ),
    .rst_ni          (rst_ni          ),
    .test_i          (1'b0            ),
    .slv_req_i       (vec_axi_req     ),
    .slv_aw_select_i (vec_aw_hart     ), // carries the ID of the host that issued the request, as assigned by the vector unit
    .slv_ar_select_i (vec_ar_hart     ),
    .slv_resp_o      (vec_axi_resp    ),
    .mst_reqs_o      (vec_to_host_req ),
    .mst_resps_i     (vec_to_host_resp)
  );

  if (NrHosts < 2)
    $error("[ara_multithreading_system] Multithreading needs at least two hosts.");

endmodule : ara_multithreading_system


