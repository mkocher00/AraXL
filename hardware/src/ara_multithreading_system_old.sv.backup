// Description:
// Multithreading abstraction layer. NrHosts scalar Hosts share one vector core. Instanciate it once in ara_soc
// 


// Description:
// Multithreading abstraction layer: NrHosts scalar hosts (CVA6 only) share ONE
// vector unit. Instantiate this once in ara_soc.
//
//   acc_req : host_system[h] -> acc_mt_arbiter (round-robin MUX) -> ara_vector_unit
//   acc_resp: ara_vector_unit -> acc_mt_arbiter (DEMUX on the owner) -> host_system[h]
//   Ara AXI : ara_vector_unit -> axi_demux (thread tag) -> host_system[h] inval filter
//             -> host mux -> that host's system AXI port (host_axi_req_o[h])
//
// All memory traffic, scalar and vector, therefore leaves through host_axi_req_o.

module ara_multithreading_system import ara_pkg::*; #(
    parameter int unsigned NrHosts             = 2,
    // RVV parameters
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
    parameter int unsigned AxiIdWidth          = 5,   // AxiCoreIdWidth in ara_soc
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
    // Scalar traffic of every host (to each host's pre-xbar)
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
      .hart_id_i    (3'(h)              ),
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

  acc_mt_arbiter #(
    .NrHosts      (NrHosts      ),
    .cva6_to_acc_t(cva6_to_acc_t),
    .acc_to_cva6_t(acc_to_cva6_t)
  ) i_acc_arbiter (
    .clk_i            (clk_i          ),
    .rst_ni           (rst_ni         ),
    .host_req_i       (host_to_acc    ),
    .host_resp_o      (acc_to_host    ),
    .shared_req_o     (shared_to_acc  ),
    .shared_req_hart_o(shared_req_hart),
    .shared_resp_i    (shared_from_acc)
  );

  ara_vector_unit #(
    .NrHosts            (NrHosts            ),
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

  // Thread-tag DEMUX: sends each vector AW / AR to the owning host. W follows its AW,
  // R / B responses are merged back and routed by the demux's ID tracking.
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
    .SpillAw    (1'b1           ),
    .SpillW     (1'b0           ),
    .SpillB     (1'b0           ),
    .SpillAr    (1'b1           ),
    .SpillR     (1'b0           )
  ) i_vec_axi_demux (
    .clk_i           (clk_i           ),
    .rst_ni          (rst_ni          ),
    .test_i          (1'b0            ),
    .slv_req_i       (vec_axi_req     ),
    .slv_aw_select_i (vec_aw_hart     ),
    .slv_ar_select_i (vec_ar_hart     ),
    .slv_resp_o      (vec_axi_resp    ),
    .mst_reqs_o      (vec_to_host_req ),
    .mst_resps_i     (vec_to_host_resp)
  );

  if (NrHosts < 2)
    $error("[ara_multithreading_system] Multithreading needs at least two hosts.");

endmodule : ara_multithreading_system


// ---------------------------------------------------------------------------
// Accelerator arbiter: no FIFO, the dispatcher (the host's req_ready) just stalls.
// ---------------------------------------------------------------------------
// One instruction is in flight at a time. A request is granted round-robin when the
// arbiter is idle; the owner register then routes the response, and the arbiter is
// idle again after the response handshake. While busy every host sees req_ready = 0.
//
// ASSUMPTION TO VERIFY in ara_dispatcher: Ara answers every accepted instruction
// with resp_valid (not only those with a scalar result). If some instructions never
// respond, busy_q never clears and the system deadlocks.

module acc_mt_arbiter #(
    parameter int unsigned NrHosts = 2,
    parameter type cva6_to_acc_t   = logic,
    parameter type acc_to_cva6_t   = logic,
    localparam int unsigned HartIdW = (NrHosts > 1) ? $clog2(NrHosts) : 1
  ) (
    input  logic                           clk_i,
    input  logic                           rst_ni,
    input  cva6_to_acc_t [NrHosts-1:0]     host_req_i,
    output acc_to_cva6_t [NrHosts-1:0]     host_resp_o,
    output cva6_to_acc_t                   shared_req_o,
    output logic [HartIdW-1:0]             shared_req_hart_o,
    input  acc_to_cva6_t                   shared_resp_i
  );

  logic [NrHosts-1:0] arb_req, arb_gnt;
  cva6_to_acc_t       arb_data;
  logic               arb_valid;
  logic [HartIdW-1:0] arb_idx;

  logic               busy_q, busy_d;
  logic [HartIdW-1:0] owner_q, owner_d;   // last accepted hart
  logic [HartIdW-1:0] cur_owner;          // owner of the response seen this cycle
  logic               accept, resp_hs;

  for (genvar h = 0; h < NrHosts; h++) begin : gen_req
    assign arb_req[h] = host_req_i[h].acc_req.req_valid;
  end

  // Pick a requester only while idle; the selection stays locked until it is accepted.
  rr_arb_tree #(
    .NumIn    (NrHosts      ),
    .DataType (cva6_to_acc_t),
    .AxiVldRdy(1'b1         ),
    .LockIn   (1'b1         )
  ) i_rr_arb (
    .clk_i  (clk_i  ),
    .rst_ni (rst_ni ),
    .flush_i(1'b0   ),
    .rr_i   ('0     ),
    .req_i  (arb_req),
    .gnt_o  (arb_gnt),
    .data_i (host_req_i),
    .req_o  (arb_valid),
    .gnt_i  (!busy_q && shared_resp_i.acc_resp.req_ready),
    .data_o (arb_data ),
    .idx_o  (arb_idx  )
  );

  // A response can come in the same cycle as the accept, so the owner is arb_idx then.
  assign cur_owner = busy_q ? owner_q : arb_idx;
  assign accept    = arb_valid && !busy_q && shared_resp_i.acc_resp.req_ready;
  assign resp_hs   = shared_resp_i.acc_resp.resp_valid &&
                     host_req_i[cur_owner].acc_req.resp_ready;

  always_comb begin : p_state
    busy_d  = busy_q;
    owner_d = owner_q;
    if (accept) begin
      busy_d  = 1'b1;
      owner_d = arb_idx;
    end
    if (resp_hs) busy_d = 1'b0;
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : p_ff
    if (!rst_ni) begin
      busy_q  <= 1'b0;
      owner_q <= '0;
    end else begin
      busy_q  <= busy_d;
      owner_q <= owner_d;
    end
  end

  // ---- Hosts -> vector unit -----------------------------------------------
  always_comb begin : p_to_acc
    shared_req_o                       = arb_data;
    shared_req_o.acc_req.req_valid     = arb_valid && !busy_q;
    shared_req_hart_o                  = arb_idx;
    shared_req_o.acc_req.resp_ready    = host_req_i[cur_owner].acc_req.resp_ready;

    // MMU: attributed to the last issuer (see limits below)
    shared_req_o.acc_mmu_en            = host_req_i[owner_q].acc_mmu_en;
    shared_req_o.acc_mmu_resp          = host_req_i[owner_q].acc_mmu_resp;

    // store_pending is global. acc_cons_en / inval_ready are NOT aggregated: every host
    // has its own inval filter (host_system), the vector unit does not use them.
    shared_req_o.acc_req.store_pending = 1'b0;
    for (int h = 0; h < NrHosts; h++)
      shared_req_o.acc_req.store_pending |= host_req_i[h].acc_req.store_pending;
  end

  // ---- Vector unit -> hosts -----------------------------------------------
  always_comb begin : p_to_host
    for (int h = 0; h < NrHosts; h++) begin
      host_resp_o[h] = shared_resp_i;   // global signals (store/load_complete) broadcast;
                                        // inval_* is overwritten by each host's own filter

      host_resp_o[h].acc_resp.req_ready    = arb_gnt[h];
      host_resp_o[h].acc_resp.resp_valid   = shared_resp_i.acc_resp.resp_valid &&
                                             (cur_owner == HartIdW'(h));
      host_resp_o[h].acc_resp.fflags_valid = shared_resp_i.acc_resp.fflags_valid &&
                                             (owner_q == HartIdW'(h));
      if (owner_q != HartIdW'(h)) host_resp_o[h].acc_mmu_req = '0;
    end
  end

  // LIMITS: resp_valid is exact (single in flight). fflags_valid, acc_mmu_* and
  // store_complete / load_complete can outlive the dispatch handshake; they are
  // attributed to the last issuer (fflags, mmu) or broadcast (store/load_complete).
  // That is exact only if the other hosts are idle. A full fix needs the hart tag
  // carried inside Ara per vector instruction.

endmodule : acc_mt_arbiter