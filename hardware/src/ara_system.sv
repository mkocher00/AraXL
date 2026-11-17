// Copyright 2021-2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Matheus Cavalcante <matheusd@iis.ee.ethz.ch>
// Description:
// Ara's System, containing Ariane and Ara.
//
// This module is a thin composition of the two halves it used to implement itself:
//   host_system      : CVA6 (or ideal dispatcher), dw converter, inval filter, AXI mux
//   ara_vector_unit  : Ara or AraXL


module ara_system import axi_pkg::*; import ara_pkg::*; #(
    // RVV Parameters
    parameter int                      unsigned NrLanes            = 0,                               // Number of parallel vector lanes.
    parameter int                      unsigned NrClusters         = 0,                               // Number of Ara instances
    // Support for floating-point data types
    parameter fpu_support_e                     FPUSupport         = FPUSupportHalfSingleDouble,
    // External support for vfrec7, vfrsqrt7
    parameter fpext_support_e                   FPExtSupport       = FPExtSupportEnable,
    // Support for fixed-point data types
    parameter fixpt_support_e                   FixPtSupport       = FixedPointEnable,
    // Ariane configuration
    parameter config_pkg::cva6_cfg_t            CVA6Cfg            = cva6_config_pkg::cva6_cfg,
    // CVA6-related parameters
    parameter type                              exception_t        = logic,
    parameter type                              accelerator_req_t  = logic,
    parameter type                              accelerator_resp_t = logic,
    parameter type                              acc_mmu_req_t      = logic,
    parameter type                              acc_mmu_resp_t     = logic,
    parameter type                              cva6_to_acc_t      = logic,
    parameter type                              acc_to_cva6_t      = logic,
    // AXI Interface
    parameter int                      unsigned AxiAddrWidth           = 64,
    parameter int                      unsigned AxiIdWidth             = 6,
    parameter int                      unsigned AxiNarrowDataWidth     = 64,
    parameter int                      unsigned AxiWideDataWidth       = 64*NrLanes*NrClusters/2,
    parameter int                      unsigned ClusterAxiDataWidth    = 64*NrLanes/2,
    parameter type                              ariane_axi_ar_t    = logic,
    parameter type                              ariane_axi_r_t     = logic,
    parameter type                              ariane_axi_aw_t    = logic,
    parameter type                              ariane_axi_w_t     = logic,
    parameter type                              ariane_axi_b_t     = logic,
    parameter type                              ariane_axi_req_t   = logic,
    parameter type                              ariane_axi_resp_t  = logic,
    parameter type                              ara_axi_ar_t       = logic,
    parameter type                              ara_axi_r_t        = logic,
    parameter type                              ara_axi_aw_t       = logic,
    parameter type                              ara_axi_w_t        = logic,
    parameter type                              ara_axi_b_t        = logic,
    parameter type                              ara_axi_req_t      = logic,
    parameter type                              ara_axi_resp_t     = logic,

    parameter type                              cluster_axi_ar_t       = logic,
    parameter type                              cluster_axi_r_t        = logic,
    parameter type                              cluster_axi_aw_t       = logic,
    parameter type                              cluster_axi_w_t        = logic,
    parameter type                              cluster_axi_b_t        = logic,
    parameter type                              cluster_axi_req_t      = logic,
    parameter type                              cluster_axi_resp_t     = logic,

    parameter type                              system_axi_ar_t    = logic,
    parameter type                              system_axi_r_t     = logic,
    parameter type                              system_axi_aw_t    = logic,
    parameter type                              system_axi_w_t     = logic,
    parameter type                              system_axi_b_t     = logic,
    parameter type                              system_axi_req_t   = logic,
    parameter type                              system_axi_resp_t  = logic
  ) (
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic             [63:0] boot_addr_i,
    input                     [2:0] hart_id_i,
    // Scan chain
    input  logic                    scan_enable_i,
    input  logic                    scan_data_i,
    output logic                    scan_data_o,
    // AXI Interface
    output system_axi_req_t         axi_req_o,
    input  system_axi_resp_t        axi_resp_i
  );

  // Interface between host and vector unit
  cva6_to_acc_t  acc_req;
  acc_to_cva6_t  acc_resp;

  // Vector unit AXI, through the host's invalidation filter
  ara_axi_req_t  vec_axi_req;
  ara_axi_resp_t vec_axi_resp;

  //////////////
  //  Host    //
  //////////////

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
    .ariane_axi_r_t    (ariane_axi_r_t    ),
    .ariane_axi_aw_t   (ariane_axi_aw_t   ),
    .ariane_axi_w_t    (ariane_axi_w_t    ),
    .ariane_axi_b_t    (ariane_axi_b_t    ),
    .ariane_axi_req_t  (ariane_axi_req_t  ),
    .ariane_axi_resp_t (ariane_axi_resp_t ),
    .ara_axi_ar_t      (ara_axi_ar_t      ),
    .ara_axi_r_t       (ara_axi_r_t       ),
    .ara_axi_aw_t      (ara_axi_aw_t      ),
    .ara_axi_w_t       (ara_axi_w_t       ),
    .ara_axi_b_t       (ara_axi_b_t       ),
    .ara_axi_req_t     (ara_axi_req_t     ),
    .ara_axi_resp_t    (ara_axi_resp_t    ),
    .system_axi_ar_t   (system_axi_ar_t   ),
    .system_axi_r_t    (system_axi_r_t    ),
    .system_axi_aw_t   (system_axi_aw_t   ),
    .system_axi_w_t    (system_axi_w_t    ),
    .system_axi_b_t    (system_axi_b_t    ),
    .system_axi_req_t  (system_axi_req_t  ),
    .system_axi_resp_t (system_axi_resp_t )
  ) i_host (
    .clk_i            (clk_i         ),
    .rst_ni           (rst_ni        ),
    .boot_addr_i      (boot_addr_i   ),
    .hart_id_i        (hart_id_i     ),
    .scan_enable_i    (scan_enable_i ),
    .scan_data_i      (scan_data_i   ),
    .scan_data_o      (scan_data_o   ),
    .axi_req_o        (axi_req_o     ),
    .axi_resp_i       (axi_resp_i    ),
    .vec_axi_req_i    (vec_axi_req   ),
    .vec_axi_resp_o   (vec_axi_resp  ),
    .acc_req_o     (acc_req       ),
    .acc_resp_i    (acc_resp      )
  );

  /////////////////////
  //  Vector unit    //
  /////////////////////

  // One vector unit for one host: NrHosts = 1, so no thread tag is needed.
  ara_vector_unit #(
    .NrHosts            (1                  ),
    .NrVecCores         (1                  ),
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
    .ara_axi_r_t        (ara_axi_r_t        ),
    .ara_axi_aw_t       (ara_axi_aw_t       ),
    .ara_axi_w_t        (ara_axi_w_t        ),
    .ara_axi_b_t        (ara_axi_b_t        ),
    .ara_axi_req_t      (ara_axi_req_t      ),
    .ara_axi_resp_t     (ara_axi_resp_t     ),
    .cluster_axi_ar_t   (cluster_axi_ar_t   ),
    .cluster_axi_r_t    (cluster_axi_r_t    ),
    .cluster_axi_aw_t   (cluster_axi_aw_t   ),
    .cluster_axi_w_t    (cluster_axi_w_t    ),
    .cluster_axi_b_t    (cluster_axi_b_t    ),
    .cluster_axi_req_t  (cluster_axi_req_t  ),
    .cluster_axi_resp_t (cluster_axi_resp_t )
  ) i_vector (
    .clk_i         (clk_i              ),
    .rst_ni        (rst_ni             ),
    .scan_enable_i (scan_enable_i      ),
    .scan_data_i   (1'b0               ),
    .scan_data_o   (/* Unused */       ),
    .acc_req_i     (acc_req            ),
    .req_hart_i    ('0                 ),
    .acc_resp_o    (acc_resp           ),
    .axi_req_o     (vec_axi_req        ),
    .axi_resp_i    (vec_axi_resp       ),
    .axi_aw_hart_o (/* Unused */       ),
    .axi_ar_hart_o (/* Unused */       )
  );

endmodule : ara_system