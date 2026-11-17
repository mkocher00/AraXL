// ---------------------------------------------------------------------------
// Accelerator arbiter
// ---------------------------------------------------------------------------
// One instruction is in flight at a time. A request is granted round-robin when the
// arbiter is idle; While busy every host sees req_ready = 0.

module mt_arbiter #(
    parameter int unsigned NrHosts       = 2,   // must be 2^{x}}
    parameter type         cva6_to_acc_t = logic,
    parameter type         acc_to_cva6_t = logic,
    localparam int unsigned HartIdW      = (NrHosts > 1) ? $clog2(NrHosts) : 1
  ) (
    input  logic                       clk_i,
    input  logic                       rst_ni,
    input  cva6_to_acc_t [NrHosts-1:0] host_req_i,
    output acc_to_cva6_t [NrHosts-1:0] host_resp_o,
    output cva6_to_acc_t               shared_req_o,
    input  acc_to_cva6_t               shared_resp_i
  );

  // hosts -> vector unit
  logic         [NrHosts-1:0] arb_req, arb_gnt;
  cva6_to_acc_t [NrHosts-1:0] arb_in;
  cva6_to_acc_t               arb_data;
  logic                       arb_valid;
  logic         [HartIdW-1:0] arb_idx;

  for (genvar h = 0; h < NrHosts; h++) begin : gen_req
    assign arb_req[h] = host_req_i[h].acc_req.req_valid;
  end

  // Only the instruction itself is arbitrated. Levels that can toggle while a request is held
  // are removed from the arbitrated payload and handled explicitly in p_req.
  always_comb begin : p_arb_in
    arb_in = host_req_i;
    for (int h = 0; h < NrHosts; h++) begin
      arb_in[h].acc_req.resp_ready    = 1'b0;
      arb_in[h].acc_req.store_pending = 1'b0;
      arb_in[h].acc_req.acc_cons_en   = 1'b0;
      arb_in[h].acc_req.inval_ready   = 1'b0;
      arb_in[h].acc_mmu_en            = 1'b0;
      arb_in[h].acc_mmu_resp          = '0;
    end
  end

  rr_arb_tree #(
    .NumIn    (NrHosts       ),
    .DataType (cva6_to_acc_t ),
    .AxiVldRdy(1'b1          ),
    .LockIn   (1'b1          )   // winner stays selected until the request is accepted
  ) i_rr_arb (
    .clk_i,
    .rst_ni,
    .flush_i(1'b0),
    .rr_i   ('0),
    .req_i  (arb_req),
    .gnt_o  (arb_gnt),
    .data_i (arb_in),
    .req_o  (arb_valid),
    .gnt_i  (shared_resp_i.acc_resp.req_ready),
    .data_o (arb_data),
    .idx_o  (arb_idx)
  );


  // Tags coming back from the vector side
  // convert it into One-hot decoding (e.g. resp_sel[h] is true (1) if the response belongs to host h)
  logic [HartIdW-1:0] resp_hart, ld_hart, st_hart, ff_hart, mmu_hart;
  assign resp_hart = HartIdW'(shared_resp_i.acc_resp.hart);      // echo of the request tag
  assign ld_hart   = HartIdW'(shared_resp_i.acc_resp.ld_hart);
  assign st_hart   = HartIdW'(shared_resp_i.acc_resp.st_hart);
  assign ff_hart   = HartIdW'(shared_resp_i.acc_resp.ff_hart);
  assign mmu_hart  = HartIdW'(shared_resp_i.acc_mmu_req.mmu_hart);

  logic [NrHosts-1:0] resp_sel, ld_sel, st_sel, ff_sel, mmu_sel;

  for (genvar h = 0; h < NrHosts; h++) begin : gen_sel
    assign resp_sel[h] = (resp_hart == HartIdW'(h));
    assign ld_sel[h]   = (ld_hart   == HartIdW'(h));
    assign st_sel[h]   = (st_hart   == HartIdW'(h));
    assign ff_sel[h]   = (ff_hart   == HartIdW'(h));
    assign mmu_sel[h]  = (mmu_hart  == HartIdW'(h));
  end

  always_comb begin : p_req
    shared_req_o                       = arb_data;
    shared_req_o.acc_req.req_valid     = arb_valid;
    shared_req_o.acc_req.hart          = arb_idx;   // the tag which does travels with the instruction
    // The dispatcher decodes only if resp_ready is set, so it must be the ready of the host that
    // the response belongs to. This relies on the dispatcher echoing hart unconditionally
    shared_req_o.acc_req.resp_ready    = host_req_i[resp_hart].acc_req.resp_ready;
    // Invalidation is not handled here, but rather by the axi_inval_filter in host_system.
    shared_req_o.acc_req.inval_ready   = 1'b0;
    // Conservative OR over all hosts (could be changed to per-hart).
    shared_req_o.acc_req.store_pending = 1'b0;
    shared_req_o.acc_req.acc_cons_en   = 1'b0;
    for (int h = 0; h < NrHosts; h++) begin
      shared_req_o.acc_req.store_pending |= host_req_i[h].acc_req.store_pending;
      shared_req_o.acc_req.acc_cons_en   |= host_req_i[h].acc_req.acc_cons_en;
    end
    // MMU: the host whose memory instruction is currently being translated.
    shared_req_o.acc_mmu_en            = host_req_i[mmu_hart].acc_mmu_en;
    shared_req_o.acc_mmu_resp          = host_req_i[mmu_hart].acc_mmu_resp;
  end


  // vector unit -> hosts 
  always_comb begin : p_resp
    for (int h = 0; h < NrHosts; h++) begin
      // Levels (store_pending) and tags are broadcasted.
      host_resp_o[h] = shared_resp_i;
      host_resp_o[h].acc_resp.req_ready      = arb_gnt[h];
      host_resp_o[h].acc_resp.resp_valid     = shared_resp_i.acc_resp.resp_valid     & resp_sel[h];
      host_resp_o[h].acc_resp.load_complete  = shared_resp_i.acc_resp.load_complete  & ld_sel[h];
      host_resp_o[h].acc_resp.store_complete = shared_resp_i.acc_resp.store_complete & st_sel[h];
      host_resp_o[h].acc_resp.fflags_valid   = shared_resp_i.acc_resp.fflags_valid   & ff_sel[h];
      host_resp_o[h].acc_resp.inval_valid    = 1'b0;   // host_system drives its own
      if (!resp_sel[h]) begin
        host_resp_o[h].acc_resp.result    = '0;
        host_resp_o[h].acc_resp.exception = '0;
        host_resp_o[h].acc_resp.trans_id  = '0;
      end
      if (!ff_sel[h])  
        host_resp_o[h].acc_resp.fflags = '0;
      if (!mmu_sel[h]) 
        host_resp_o[h].acc_mmu_req     = '0;
    end
  end

endmodule : mt_arbiter