module miriscv_signextend (
	data_i,
	data_o
);
	parameter IN_WIDTH = 12;
	parameter OUT_WIDTH = 32;
	input wire [IN_WIDTH - 1:0] data_i;
	output wire [OUT_WIDTH - 1:0] data_o;
	assign data_o = {{OUT_WIDTH - IN_WIDTH {data_i[IN_WIDTH - 1]}}, data_i};
endmodule
module miriscv_core (
	clk_i,
	arstn_i,
	boot_addr_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_req_o,
	instr_addr_o,
	data_rvalid_i,
	data_rdata_i,
	data_req_o,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	rvfi_valid_o,
	rvfi_order_o,
	rvfi_insn_o,
	rvfi_trap_o,
	rvfi_halt_o,
	rvfi_intr_o,
	rvfi_mode_o,
	rvfi_ixl_o,
	rvfi_rs1_addr_o,
	rvfi_rs2_addr_o,
	rvfi_rs1_rdata_o,
	rvfi_rs2_rdata_o,
	rvfi_rd_addr_o,
	rvfi_rd_wdata_o,
	rvfi_pc_rdata_o,
	rvfi_pc_wdata_o,
	rvfi_mem_addr_o,
	rvfi_mem_rmask_o,
	rvfi_mem_wmask_o,
	rvfi_mem_rdata_o,
	rvfi_mem_wdata_o
);
	parameter [0:0] RVFI = 1'b1;
	input wire clk_i;
	input wire arstn_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] boot_addr_i;
	input wire instr_rvalid_i;
	input wire [31:0] instr_rdata_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire data_rvalid_i;
	input wire [31:0] data_rdata_i;
	output wire data_req_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	output wire rvfi_valid_o;
	output wire [63:0] rvfi_order_o;
	output wire [31:0] rvfi_insn_o;
	output wire rvfi_trap_o;
	output wire rvfi_halt_o;
	output wire rvfi_intr_o;
	output wire [1:0] rvfi_mode_o;
	output wire [1:0] rvfi_ixl_o;
	output wire [4:0] rvfi_rs1_addr_o;
	output wire [4:0] rvfi_rs2_addr_o;
	output wire [31:0] rvfi_rs1_rdata_o;
	output wire [31:0] rvfi_rs2_rdata_o;
	output wire [4:0] rvfi_rd_addr_o;
	output wire [31:0] rvfi_rd_wdata_o;
	output wire [31:0] rvfi_pc_rdata_o;
	output wire [31:0] rvfi_pc_wdata_o;
	output wire [31:0] rvfi_mem_addr_o;
	output wire [3:0] rvfi_mem_rmask_o;
	output wire [3:0] rvfi_mem_wmask_o;
	output wire [31:0] rvfi_mem_rdata_o;
	output wire [31:0] rvfi_mem_wdata_o;
	localparam f = 3'd0;
	localparam d = 3'd1;
	localparam e = 3'd2;
	localparam m = 3'd3;
	localparam w = 3'd4;
	wire [31:0] current_pc [f:f];
	wire [31:0] next_pc [f:m];
	localparam miriscv_pkg_ILEN = 32;
	wire [31:0] instr [f:f];
	wire valid [f:m];
	wire gpr_wr_en [d:m];
	localparam miriscv_gpr_pkg_RISCV_E = 0;
	localparam miriscv_gpr_pkg_GPR_ADDR_W = 5;
	wire [4:0] gpr_wr_addr [d:m];
	localparam miriscv_decode_pkg_WB_SRC_W = 2;
	wire [1:0] gpr_src_sel [d:e];
	wire [31:0] gpr_wr_data [m:m];
	wire [31:0] op1 [d:d];
	wire [31:0] op2 [d:d];
	wire [31:0] alu_result [e:e];
	wire [31:0] mdu_result [e:e];
	localparam miriscv_alu_pkg_ALU_OP_W = 5;
	wire [4:0] alu_operation [d:d];
	wire mdu_req [d:d];
	localparam miriscv_mdu_pkg_MDU_OP_W = 3;
	wire [2:0] mdu_operation [d:d];
	wire mem_req [d:e];
	wire mem_we [d:e];
	localparam miriscv_lsu_pkg_MEM_ACCESS_W = 3;
	wire [2:0] mem_size [d:e];
	wire [31:0] mem_addr [d:e];
	wire [31:0] mem_data [d:e];
	wire branch [d:m];
	wire jal [d:m];
	wire jalr [d:m];
	wire [31:0] target_pc [d:m];
	wire prediction [d:m];
	wire br_j_taken [d:m];
	wire cu_stall_req [f:m];
	wire cu_stall [f:m];
	wire cu_kill [f:m];
	wire cu_force [f:f];
	wire [31:0] cu_force_pc [f:f];
	wire [4:0] cu_rs1_addr [f:f];
	wire cu_rs1_req [f:f];
	wire [4:0] cu_rs2_addr [f:f];
	wire cu_rs2_req [f:f];
	wire [31:0] rvfi_wb_data [m:w];
	wire rvfi_wb_we [f:w];
	wire [4:0] rvfi_wb_rd_addr [f:w];
	wire [31:0] rvfi_instr [f:w];
	wire [4:0] rvfi_rs1_addr [f:w];
	wire [4:0] rvfi_rs2_addr [f:w];
	wire rvfi_op1_gpr [f:w];
	wire rvfi_op2_gpr [f:w];
	wire [31:0] rvfi_rs1_rdata [f:w];
	wire [31:0] rvfi_rs2_rdata [f:w];
	wire [31:0] rvfi_current_pc [f:w];
	wire [31:0] rvfi_next_pc [f:w];
	wire rvfi_valid [f:w];
	wire rvfi_trap [f:w];
	wire rvfi_intr [f:w];
	wire rvfi_mem_req [f:w];
	wire rvfi_mem_we [f:w];
	wire [2:0] rvfi_mem_size [f:w];
	wire [31:0] rvfi_mem_addr [f:w];
	wire [31:0] rvfi_mem_wdata [f:w];
	wire [31:0] rvfi_mem_rdata [m:w];
	miriscv_fetch_stage #(.RVFI(RVFI)) i_fetch_stage(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.cu_kill_f_i(cu_kill[f]),
		.cu_stall_f_i(cu_stall[f]),
		.cu_force_f_i(cu_force[f]),
		.cu_force_pc_i(cu_force_pc[f]),
		.f_stall_req_o(cu_stall_req[f]),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.f_instr_o(instr[f]),
		.f_current_pc_o(current_pc[f]),
		.f_next_pc_o(next_pc[f]),
		.f_valid_o(valid[f])
	);
	miriscv_decode_stage #(.RVFI(RVFI)) i_decode_stage(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.cu_kill_d_i(cu_kill[d]),
		.cu_stall_d_i(cu_stall[d]),
		.cu_stall_f_i(cu_stall[f]),
		.d_stall_req_o(cu_stall_req[d]),
		.f_instr_i(instr[f]),
		.f_current_pc_i(current_pc[f]),
		.f_next_pc_i(next_pc[f]),
		.f_valid_i(valid[f]),
		.m_gpr_wr_en_i(gpr_wr_en[m]),
		.m_gpr_wr_data_i(gpr_wr_data[m]),
		.m_gpr_wr_addr_i(gpr_wr_addr[m]),
		.d_valid_o(valid[d]),
		.d_op1_o(op1[d]),
		.d_op2_o(op2[d]),
		.d_alu_operation_o(alu_operation[d]),
		.d_mdu_req_o(mdu_req[d]),
		.d_mdu_operation_o(mdu_operation[d]),
		.d_mem_req_o(mem_req[d]),
		.d_mem_we_o(mem_we[d]),
		.d_mem_size_o(mem_size[d]),
		.d_mem_addr_o(mem_addr[d]),
		.d_mem_data_o(mem_data[d]),
		.d_gpr_wr_en_o(gpr_wr_en[d]),
		.d_gpr_wr_addr_o(gpr_wr_addr[d]),
		.d_gpr_src_sel_o(gpr_src_sel[d]),
		.d_branch_o(branch[d]),
		.d_jal_o(jal[d]),
		.d_jalr_o(jalr[d]),
		.d_target_pc_o(target_pc[d]),
		.d_next_pc_o(next_pc[d]),
		.d_prediction_o(prediction[d]),
		.d_br_j_taken_o(br_j_taken[d]),
		.f_cu_rs1_addr_o(cu_rs1_addr[f]),
		.f_cu_rs1_req_o(cu_rs1_req[f]),
		.f_cu_rs2_addr_o(cu_rs2_addr[f]),
		.f_cu_rs2_req_o(cu_rs2_req[f]),
		.d_rvfi_wb_we_o(rvfi_wb_we[d]),
		.d_rvfi_wb_rd_addr_o(rvfi_wb_rd_addr[d]),
		.d_rvfi_instr_o(rvfi_instr[d]),
		.d_rvfi_rs1_addr_o(rvfi_rs1_addr[d]),
		.d_rvfi_rs2_addr_o(rvfi_rs2_addr[d]),
		.d_rvfi_op1_gpr_o(rvfi_op1_gpr[d]),
		.d_rvfi_op2_gpr_o(rvfi_op2_gpr[d]),
		.d_rvfi_rs1_rdata_o(rvfi_rs1_rdata[d]),
		.d_rvfi_rs2_rdata_o(rvfi_rs2_rdata[d]),
		.d_rvfi_current_pc_o(rvfi_current_pc[d]),
		.d_rvfi_next_pc_o(rvfi_next_pc[d]),
		.d_rvfi_valid_o(rvfi_valid[d]),
		.d_rvfi_trap_o(rvfi_trap[d]),
		.d_rvfi_intr_o(rvfi_intr[d]),
		.d_rvfi_mem_req_o(rvfi_mem_req[d]),
		.d_rvfi_mem_we_o(rvfi_mem_we[d]),
		.d_rvfi_mem_size_o(rvfi_mem_size[d]),
		.d_rvfi_mem_addr_o(rvfi_mem_addr[d]),
		.d_rvfi_mem_wdata_o(rvfi_mem_wdata[d])
	);
	miriscv_execute_stage #(.RVFI(RVFI)) i_execute_stage(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.cu_kill_e_i(cu_kill[e]),
		.cu_stall_e_i(cu_stall[e]),
		.e_stall_req_o(cu_stall_req[e]),
		.d_valid_i(valid[d]),
		.d_op1_i(op1[d]),
		.d_op2_i(op2[d]),
		.d_alu_operation_i(alu_operation[d]),
		.d_mdu_req_i(mdu_req[d]),
		.d_mdu_operation_i(mdu_operation[d]),
		.d_mem_req_i(mem_req[d]),
		.d_mem_we_i(mem_we[d]),
		.d_mem_size_i(mem_size[d]),
		.d_mem_addr_i(mem_addr[d]),
		.d_mem_data_i(mem_data[d]),
		.d_gpr_wr_en_i(gpr_wr_en[d]),
		.d_gpr_wr_addr_i(gpr_wr_addr[d]),
		.d_gpr_src_sel_i(gpr_src_sel[d]),
		.d_branch_i(branch[d]),
		.d_jal_i(jal[d]),
		.d_jalr_i(jalr[d]),
		.d_target_pc_i(target_pc[d]),
		.d_next_pc_i(next_pc[d]),
		.d_prediction_i(prediction[d]),
		.d_br_j_taken_i(br_j_taken[d]),
		.e_valid_o(valid[e]),
		.e_alu_result_o(alu_result[e]),
		.e_mdu_result_o(mdu_result[e]),
		.e_mem_req_o(mem_req[e]),
		.e_mem_we_o(mem_we[e]),
		.e_mem_size_o(mem_size[e]),
		.e_mem_addr_o(mem_addr[e]),
		.e_mem_data_o(mem_data[e]),
		.e_gpr_wr_en_o(gpr_wr_en[e]),
		.e_gpr_wr_addr_o(gpr_wr_addr[e]),
		.e_gpr_src_sel_o(gpr_src_sel[e]),
		.e_branch_o(branch[e]),
		.e_jal_o(jal[e]),
		.e_jalr_o(jalr[e]),
		.e_target_pc_o(target_pc[e]),
		.e_next_pc_o(next_pc[e]),
		.e_prediction_o(prediction[e]),
		.e_br_j_taken_o(br_j_taken[e]),
		.d_rvfi_wb_we_i(rvfi_wb_we[d]),
		.d_rvfi_wb_rd_addr_i(rvfi_wb_rd_addr[d]),
		.d_rvfi_instr_i(rvfi_instr[d]),
		.d_rvfi_rs1_addr_i(rvfi_rs1_addr[d]),
		.d_rvfi_rs2_addr_i(rvfi_rs2_addr[d]),
		.d_rvfi_op1_gpr_i(rvfi_op1_gpr[d]),
		.d_rvfi_op2_gpr_i(rvfi_op2_gpr[d]),
		.d_rvfi_rs1_rdata_i(rvfi_rs1_rdata[d]),
		.d_rvfi_rs2_rdata_i(rvfi_rs2_rdata[d]),
		.d_rvfi_current_pc_i(rvfi_current_pc[d]),
		.d_rvfi_next_pc_i(rvfi_next_pc[d]),
		.d_rvfi_valid_i(rvfi_valid[d]),
		.d_rvfi_trap_i(rvfi_trap[d]),
		.d_rvfi_intr_i(rvfi_intr[d]),
		.d_rvfi_mem_req_i(rvfi_mem_req[d]),
		.d_rvfi_mem_we_i(rvfi_mem_we[d]),
		.d_rvfi_mem_size_i(rvfi_mem_size[d]),
		.d_rvfi_mem_addr_i(rvfi_mem_addr[d]),
		.d_rvfi_mem_wdata_i(rvfi_mem_wdata[d]),
		.e_rvfi_wb_we_o(rvfi_wb_we[e]),
		.e_rvfi_wb_rd_addr_o(rvfi_wb_rd_addr[e]),
		.e_rvfi_instr_o(rvfi_instr[e]),
		.e_rvfi_rs1_addr_o(rvfi_rs1_addr[e]),
		.e_rvfi_rs2_addr_o(rvfi_rs2_addr[e]),
		.e_rvfi_op1_gpr_o(rvfi_op1_gpr[e]),
		.e_rvfi_op2_gpr_o(rvfi_op2_gpr[e]),
		.e_rvfi_rs1_rdata_o(rvfi_rs1_rdata[e]),
		.e_rvfi_rs2_rdata_o(rvfi_rs2_rdata[e]),
		.e_rvfi_current_pc_o(rvfi_current_pc[e]),
		.e_rvfi_next_pc_o(rvfi_next_pc[e]),
		.e_rvfi_valid_o(rvfi_valid[e]),
		.e_rvfi_trap_o(rvfi_trap[e]),
		.e_rvfi_intr_o(rvfi_intr[e]),
		.e_rvfi_mem_req_o(rvfi_mem_req[e]),
		.e_rvfi_mem_we_o(rvfi_mem_we[e]),
		.e_rvfi_mem_size_o(rvfi_mem_size[e]),
		.e_rvfi_mem_addr_o(rvfi_mem_addr[e]),
		.e_rvfi_mem_wdata_o(rvfi_mem_wdata[e])
	);
	miriscv_memory_stage #(.RVFI(RVFI)) i_memory_stage(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.cu_kill_m_i(cu_kill[m]),
		.cu_stall_m_i(cu_stall[m]),
		.m_stall_req_o(cu_stall_req[m]),
		.e_valid_i(valid[e]),
		.e_alu_result_i(alu_result[e]),
		.e_mdu_result_i(mdu_result[e]),
		.e_mem_req_i(mem_req[e]),
		.e_mem_we_i(mem_we[e]),
		.e_mem_size_i(mem_size[e]),
		.e_mem_addr_i(mem_addr[e]),
		.e_mem_data_i(mem_data[e]),
		.e_gpr_wr_en_i(gpr_wr_en[e]),
		.e_gpr_wr_addr_i(gpr_wr_addr[e]),
		.e_gpr_src_sel_i(gpr_src_sel[e]),
		.e_branch_i(branch[e]),
		.e_jal_i(jal[e]),
		.e_jalr_i(jalr[e]),
		.e_target_pc_i(target_pc[e]),
		.e_next_pc_i(next_pc[e]),
		.e_prediction_i(prediction[e]),
		.e_br_j_taken_i(br_j_taken[e]),
		.m_valid_o(valid[m]),
		.m_gpr_wr_en_o(gpr_wr_en[m]),
		.m_gpr_wr_addr_o(gpr_wr_addr[m]),
		.m_gpr_wr_data_o(gpr_wr_data[m]),
		.m_branch_o(branch[m]),
		.m_jal_o(jal[m]),
		.m_jalr_o(jalr[m]),
		.m_target_pc_o(target_pc[m]),
		.m_next_pc_o(next_pc[m]),
		.m_prediction_o(prediction[m]),
		.m_br_j_taken_o(br_j_taken[m]),
		.data_rvalid_i(data_rvalid_i),
		.data_rdata_i(data_rdata_i),
		.data_req_o(data_req_o),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_addr_o(data_addr_o),
		.data_wdata_o(data_wdata_o),
		.e_rvfi_wb_we_i(rvfi_wb_we[e]),
		.e_rvfi_wb_rd_addr_i(rvfi_wb_rd_addr[e]),
		.e_rvfi_instr_i(rvfi_instr[e]),
		.e_rvfi_rs1_addr_i(rvfi_rs1_addr[e]),
		.e_rvfi_rs2_addr_i(rvfi_rs2_addr[e]),
		.e_rvfi_op1_gpr_i(rvfi_op1_gpr[e]),
		.e_rvfi_op2_gpr_i(rvfi_op2_gpr[e]),
		.e_rvfi_rs1_rdata_i(rvfi_rs1_rdata[e]),
		.e_rvfi_rs2_rdata_i(rvfi_rs2_rdata[e]),
		.e_rvfi_current_pc_i(rvfi_current_pc[e]),
		.e_rvfi_next_pc_i(rvfi_next_pc[e]),
		.e_rvfi_valid_i(rvfi_valid[e]),
		.e_rvfi_trap_i(rvfi_trap[e]),
		.e_rvfi_intr_i(rvfi_intr[e]),
		.e_rvfi_mem_req_i(rvfi_mem_req[e]),
		.e_rvfi_mem_we_i(rvfi_mem_we[e]),
		.e_rvfi_mem_size_i(rvfi_mem_size[e]),
		.e_rvfi_mem_addr_i(rvfi_mem_addr[e]),
		.e_rvfi_mem_wdata_i(rvfi_mem_wdata[e]),
		.m_rvfi_wb_data_o(rvfi_wb_data[m]),
		.m_rvfi_wb_we_o(rvfi_wb_we[m]),
		.m_rvfi_wb_rd_addr_o(rvfi_wb_rd_addr[m]),
		.m_rvfi_instr_o(rvfi_instr[m]),
		.m_rvfi_rs1_addr_o(rvfi_rs1_addr[m]),
		.m_rvfi_rs2_addr_o(rvfi_rs2_addr[m]),
		.m_rvfi_op1_gpr_o(rvfi_op1_gpr[m]),
		.m_rvfi_op2_gpr_o(rvfi_op2_gpr[m]),
		.m_rvfi_rs1_rdata_o(rvfi_rs1_rdata[m]),
		.m_rvfi_rs2_rdata_o(rvfi_rs2_rdata[m]),
		.m_rvfi_current_pc_o(rvfi_current_pc[m]),
		.m_rvfi_next_pc_o(rvfi_next_pc[m]),
		.m_rvfi_valid_o(rvfi_valid[m]),
		.m_rvfi_trap_o(rvfi_trap[m]),
		.m_rvfi_intr_o(rvfi_intr[m]),
		.m_rvfi_mem_req_o(rvfi_mem_req[m]),
		.m_rvfi_mem_we_o(rvfi_mem_we[m]),
		.m_rvfi_mem_size_o(rvfi_mem_size[m]),
		.m_rvfi_mem_addr_o(rvfi_mem_addr[m]),
		.m_rvfi_mem_wdata_o(rvfi_mem_wdata[m]),
		.m_rvfi_mem_rdata_o(rvfi_mem_rdata[m])
	);
	miriscv_control_unit i_control_unit(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.boot_addr_i(boot_addr_i),
		.f_stall_req_i(cu_stall_req[f]),
		.d_stall_req_i(cu_stall_req[d]),
		.e_stall_req_i(cu_stall_req[e]),
		.m_stall_req_i(cu_stall_req[m]),
		.f_valid_i(valid[f]),
		.d_valid_i(valid[d]),
		.e_valid_i(valid[e]),
		.m_valid_i(valid[m]),
		.f_cu_rs1_addr_i(cu_rs1_addr[f]),
		.f_cu_rs1_req_i(cu_rs1_req[f]),
		.f_cu_rs2_addr_i(cu_rs2_addr[f]),
		.f_cu_rs2_req_i(cu_rs2_req[f]),
		.d_cu_rd_addr_i(gpr_wr_addr[d]),
		.d_cu_rd_we_i(gpr_wr_en[d]),
		.e_cu_rd_addr_i(gpr_wr_addr[e]),
		.e_cu_rd_we_i(gpr_wr_en[e]),
		.m_branch_i(branch[m]),
		.m_jal_i(jal[m]),
		.m_jalr_i(jalr[m]),
		.m_target_pc_i(target_pc[m]),
		.m_next_pc_i(next_pc[m]),
		.m_prediction_i(prediction[m]),
		.m_br_j_taken_i(br_j_taken[m]),
		.cu_stall_f_o(cu_stall[f]),
		.cu_stall_d_o(cu_stall[d]),
		.cu_stall_e_o(cu_stall[e]),
		.cu_stall_m_o(cu_stall[m]),
		.cu_kill_f_o(cu_kill[f]),
		.cu_kill_d_o(cu_kill[d]),
		.cu_kill_e_o(cu_kill[e]),
		.cu_kill_m_o(cu_kill[m]),
		.cu_force_pc_o(cu_force_pc[f]),
		.cu_force_f_o(cu_force[f])
	);
	assign rvfi_instr[w] = rvfi_instr[m];
	assign rvfi_rs1_addr[w] = rvfi_rs1_addr[m];
	assign rvfi_rs2_addr[w] = rvfi_rs2_addr[m];
	assign rvfi_op1_gpr[w] = rvfi_op1_gpr[m];
	assign rvfi_op2_gpr[w] = rvfi_op2_gpr[m];
	assign rvfi_rs1_rdata[w] = rvfi_rs1_rdata[m];
	assign rvfi_rs2_rdata[w] = rvfi_rs2_rdata[m];
	assign rvfi_wb_rd_addr[w] = rvfi_wb_rd_addr[m];
	assign rvfi_wb_we[w] = rvfi_wb_we[m];
	assign rvfi_wb_data[w] = rvfi_wb_data[m];
	assign rvfi_mem_we[w] = rvfi_mem_we[m];
	assign rvfi_mem_req[w] = rvfi_mem_req[m];
	assign rvfi_mem_size[w] = rvfi_mem_size[m];
	assign rvfi_mem_addr[w] = rvfi_mem_addr[m];
	assign rvfi_mem_wdata[w] = rvfi_mem_wdata[m];
	assign rvfi_mem_rdata[w] = rvfi_mem_rdata[m];
	assign rvfi_current_pc[w] = rvfi_current_pc[m];
	assign rvfi_next_pc[w] = rvfi_next_pc[m];
	assign rvfi_valid[w] = rvfi_valid[m];
	assign rvfi_intr[w] = rvfi_intr[m];
	assign rvfi_trap[w] = rvfi_trap[m];
	generate
		if (RVFI) begin : genblk1
			miriscv_rvfi_controller i_rvfi(
				.clk_i(clk_i),
				.aresetn_i(arstn_i),
				.w_instr_i(rvfi_instr[w]),
				.w_rs1_addr_i(rvfi_rs1_addr[w]),
				.w_rs2_addr_i(rvfi_rs2_addr[w]),
				.w_op1_gpr_i(rvfi_op1_gpr[w]),
				.w_op2_gpr_i(rvfi_op2_gpr[w]),
				.w_rs1_rdata_i(rvfi_rs1_rdata[w]),
				.w_rs2_rdata_i(rvfi_rs2_rdata[w]),
				.w_wb_rd_addr_i(rvfi_wb_rd_addr[w]),
				.w_wb_we_i(rvfi_wb_we[w]),
				.w_wb_data_i(rvfi_wb_data[w]),
				.w_data_we_i(rvfi_mem_we[w]),
				.w_data_req_i(rvfi_mem_req[w]),
				.w_data_size_i(rvfi_mem_size[w]),
				.w_data_addr_i(rvfi_mem_addr[w]),
				.w_data_wdata_i(rvfi_mem_wdata[w]),
				.w_data_rdata_i(rvfi_mem_rdata[w]),
				.w_current_pc_i(rvfi_current_pc[w]),
				.w_next_pc_i(rvfi_next_pc[w]),
				.w_valid_i(rvfi_valid[w]),
				.w_intr_i(rvfi_intr[w]),
				.w_trap_i(rvfi_trap[w]),
				.rvfi_valid_o(rvfi_valid_o),
				.rvfi_order_o(rvfi_order_o),
				.rvfi_insn_o(rvfi_insn_o),
				.rvfi_trap_o(rvfi_trap_o),
				.rvfi_halt_o(rvfi_halt_o),
				.rvfi_intr_o(rvfi_intr_o),
				.rvfi_mode_o(rvfi_mode_o),
				.rvfi_ixl_o(rvfi_ixl_o),
				.rvfi_rs1_addr_o(rvfi_rs1_addr_o),
				.rvfi_rs2_addr_o(rvfi_rs2_addr_o),
				.rvfi_rs1_rdata_o(rvfi_rs1_rdata_o),
				.rvfi_rs2_rdata_o(rvfi_rs2_rdata_o),
				.rvfi_rd_addr_o(rvfi_rd_addr_o),
				.rvfi_rd_wdata_o(rvfi_rd_wdata_o),
				.rvfi_pc_rdata_o(rvfi_pc_rdata_o),
				.rvfi_pc_wdata_o(rvfi_pc_wdata_o),
				.rvfi_mem_addr_o(rvfi_mem_addr_o),
				.rvfi_mem_rmask_o(rvfi_mem_rmask_o),
				.rvfi_mem_wmask_o(rvfi_mem_wmask_o),
				.rvfi_mem_rdata_o(rvfi_mem_rdata_o),
				.rvfi_mem_wdata_o(rvfi_mem_wdata_o)
			);
		end
		else begin : genblk1
			assign rvfi_valid_o = 1'sb0;
			assign rvfi_order_o = 1'sb0;
			assign rvfi_insn_o = 1'sb0;
			assign rvfi_trap_o = 1'sb0;
			assign rvfi_halt_o = 1'sb0;
			assign rvfi_intr_o = 1'sb0;
			assign rvfi_mode_o = 1'sb0;
			assign rvfi_ixl_o = 1'sb0;
			assign rvfi_rs1_addr_o = 1'sb0;
			assign rvfi_rs2_addr_o = 1'sb0;
			assign rvfi_rs1_rdata_o = 1'sb0;
			assign rvfi_rs2_rdata_o = 1'sb0;
			assign rvfi_rd_addr_o = 1'sb0;
			assign rvfi_rd_wdata_o = 1'sb0;
			assign rvfi_pc_rdata_o = 1'sb0;
			assign rvfi_pc_wdata_o = 1'sb0;
			assign rvfi_mem_addr_o = 1'sb0;
			assign rvfi_mem_rmask_o = 1'sb0;
			assign rvfi_mem_wmask_o = 1'sb0;
			assign rvfi_mem_rdata_o = 1'sb0;
			assign rvfi_mem_wdata_o = 1'sb0;
		end
	endgenerate
endmodule
module miriscv_control_unit (
	clk_i,
	arstn_i,
	boot_addr_i,
	f_stall_req_i,
	d_stall_req_i,
	e_stall_req_i,
	m_stall_req_i,
	f_cu_rs1_addr_i,
	f_cu_rs1_req_i,
	f_cu_rs2_addr_i,
	f_cu_rs2_req_i,
	d_cu_rd_addr_i,
	d_cu_rd_we_i,
	e_cu_rd_addr_i,
	e_cu_rd_we_i,
	f_valid_i,
	d_valid_i,
	e_valid_i,
	m_valid_i,
	m_branch_i,
	m_jal_i,
	m_jalr_i,
	m_target_pc_i,
	m_next_pc_i,
	m_prediction_i,
	m_br_j_taken_i,
	cu_stall_f_o,
	cu_stall_d_o,
	cu_stall_e_o,
	cu_stall_m_o,
	cu_kill_f_o,
	cu_kill_d_o,
	cu_kill_e_o,
	cu_kill_m_o,
	cu_force_pc_o,
	cu_force_f_o
);
	input wire clk_i;
	input wire arstn_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] boot_addr_i;
	input wire f_stall_req_i;
	input wire d_stall_req_i;
	input wire e_stall_req_i;
	input wire m_stall_req_i;
	localparam miriscv_gpr_pkg_RISCV_E = 0;
	localparam miriscv_gpr_pkg_GPR_ADDR_W = 5;
	input wire [4:0] f_cu_rs1_addr_i;
	input wire f_cu_rs1_req_i;
	input wire [4:0] f_cu_rs2_addr_i;
	input wire f_cu_rs2_req_i;
	input wire [4:0] d_cu_rd_addr_i;
	input wire d_cu_rd_we_i;
	input wire [4:0] e_cu_rd_addr_i;
	input wire e_cu_rd_we_i;
	input wire f_valid_i;
	input wire d_valid_i;
	input wire e_valid_i;
	input wire m_valid_i;
	input wire m_branch_i;
	input wire m_jal_i;
	input wire m_jalr_i;
	input wire [31:0] m_target_pc_i;
	input wire [31:0] m_next_pc_i;
	input wire m_prediction_i;
	input wire m_br_j_taken_i;
	output wire cu_stall_f_o;
	output wire cu_stall_d_o;
	output wire cu_stall_e_o;
	output wire cu_stall_m_o;
	output wire cu_kill_f_o;
	output wire cu_kill_d_o;
	output wire cu_kill_e_o;
	output wire cu_kill_m_o;
	output wire [31:0] cu_force_pc_o;
	output wire cu_force_f_o;
	reg [1:0] boot_addr_load_ff;
	wire cu_boot_addr_load_en;
	wire cu_mispredict;
	wire e_raw_hazard_rs1;
	wire e_raw_hazard_rs2;
	wire e_raw_hazard;
	wire m_raw_hazard_rs1;
	wire m_raw_hazard_rs2;
	wire m_raw_hazard;
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i)
			boot_addr_load_ff <= 2'b00;
		else
			boot_addr_load_ff <= {boot_addr_load_ff[0], 1'b1};
	assign cu_boot_addr_load_en = ~boot_addr_load_ff[1];
	assign e_raw_hazard_rs1 = ((((f_cu_rs1_req_i & f_valid_i) & d_cu_rd_we_i) & d_valid_i) & (f_cu_rs1_addr_i == d_cu_rd_addr_i)) & (d_cu_rd_addr_i != {5 {1'sb0}});
	assign e_raw_hazard_rs2 = ((((f_cu_rs2_req_i & f_valid_i) & d_cu_rd_we_i) & d_valid_i) & (f_cu_rs2_addr_i == d_cu_rd_addr_i)) & (d_cu_rd_addr_i != {5 {1'sb0}});
	assign e_raw_hazard = e_raw_hazard_rs1 | e_raw_hazard_rs2;
	assign m_raw_hazard_rs1 = ((((f_cu_rs1_req_i & f_valid_i) & e_cu_rd_we_i) & e_valid_i) & (f_cu_rs1_addr_i == e_cu_rd_addr_i)) & (e_cu_rd_addr_i != {5 {1'sb0}});
	assign m_raw_hazard_rs2 = ((((f_cu_rs2_req_i & f_valid_i) & e_cu_rd_we_i) & e_valid_i) & (f_cu_rs2_addr_i == e_cu_rd_addr_i)) & (e_cu_rd_addr_i != {5 {1'sb0}});
	assign m_raw_hazard = m_raw_hazard_rs1 | m_raw_hazard_rs2;
	assign cu_stall_f_o = (((m_stall_req_i | e_stall_req_i) | d_stall_req_i) | e_raw_hazard) | m_raw_hazard;
	assign cu_stall_d_o = (m_stall_req_i | e_stall_req_i) | d_stall_req_i;
	assign cu_stall_e_o = m_stall_req_i | e_stall_req_i;
	assign cu_stall_m_o = m_stall_req_i;
	assign cu_mispredict = m_valid_i & (m_prediction_i ^ m_br_j_taken_i);
	assign cu_kill_f_o = cu_mispredict;
	assign cu_kill_d_o = cu_mispredict;
	assign cu_kill_e_o = cu_mispredict;
	assign cu_kill_m_o = cu_mispredict;
	assign cu_force_pc_o = (cu_boot_addr_load_en ? boot_addr_i : (m_br_j_taken_i ? m_target_pc_i : m_next_pc_i));
	assign cu_force_f_o = cu_boot_addr_load_en | cu_mispredict;
endmodule
module miriscv_rvfi_controller (
	clk_i,
	aresetn_i,
	w_instr_i,
	w_rs1_addr_i,
	w_rs2_addr_i,
	w_op1_gpr_i,
	w_op2_gpr_i,
	w_rs1_rdata_i,
	w_rs2_rdata_i,
	w_wb_rd_addr_i,
	w_wb_data_i,
	w_wb_we_i,
	w_data_we_i,
	w_data_req_i,
	w_data_size_i,
	w_data_addr_i,
	w_data_wdata_i,
	w_data_rdata_i,
	w_current_pc_i,
	w_next_pc_i,
	w_valid_i,
	w_intr_i,
	w_trap_i,
	rvfi_valid_o,
	rvfi_order_o,
	rvfi_insn_o,
	rvfi_trap_o,
	rvfi_halt_o,
	rvfi_intr_o,
	rvfi_mode_o,
	rvfi_ixl_o,
	rvfi_rs1_addr_o,
	rvfi_rs2_addr_o,
	rvfi_rs1_rdata_o,
	rvfi_rs2_rdata_o,
	rvfi_rd_addr_o,
	rvfi_rd_wdata_o,
	rvfi_pc_rdata_o,
	rvfi_pc_wdata_o,
	rvfi_mem_addr_o,
	rvfi_mem_rmask_o,
	rvfi_mem_wmask_o,
	rvfi_mem_rdata_o,
	rvfi_mem_wdata_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire aresetn_i;
	localparam miriscv_pkg_ILEN = 32;
	input wire [31:0] w_instr_i;
	localparam miriscv_gpr_pkg_RISCV_E = 0;
	localparam miriscv_gpr_pkg_GPR_ADDR_W = 5;
	input wire [4:0] w_rs1_addr_i;
	input wire [4:0] w_rs2_addr_i;
	input wire w_op1_gpr_i;
	input wire w_op2_gpr_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] w_rs1_rdata_i;
	input wire [31:0] w_rs2_rdata_i;
	input wire [4:0] w_wb_rd_addr_i;
	input wire [31:0] w_wb_data_i;
	input wire w_wb_we_i;
	input wire w_data_we_i;
	input wire w_data_req_i;
	localparam miriscv_lsu_pkg_MEM_ACCESS_W = 3;
	input wire [2:0] w_data_size_i;
	input wire [31:0] w_data_addr_i;
	input wire [31:0] w_data_wdata_i;
	input wire [31:0] w_data_rdata_i;
	input wire [31:0] w_current_pc_i;
	input wire [31:0] w_next_pc_i;
	input wire w_valid_i;
	input wire w_intr_i;
	input wire w_trap_i;
	output reg rvfi_valid_o;
	output reg [63:0] rvfi_order_o;
	output reg [31:0] rvfi_insn_o;
	output reg rvfi_trap_o;
	output wire rvfi_halt_o;
	output reg rvfi_intr_o;
	output wire [1:0] rvfi_mode_o;
	output wire [1:0] rvfi_ixl_o;
	output reg [4:0] rvfi_rs1_addr_o;
	output reg [4:0] rvfi_rs2_addr_o;
	output reg [31:0] rvfi_rs1_rdata_o;
	output reg [31:0] rvfi_rs2_rdata_o;
	output reg [4:0] rvfi_rd_addr_o;
	output reg [31:0] rvfi_rd_wdata_o;
	output reg [31:0] rvfi_pc_rdata_o;
	output reg [31:0] rvfi_pc_wdata_o;
	output reg [31:0] rvfi_mem_addr_o;
	output reg [3:0] rvfi_mem_rmask_o;
	output reg [3:0] rvfi_mem_wmask_o;
	output reg [31:0] rvfi_mem_rdata_o;
	output reg [31:0] rvfi_mem_wdata_o;
	assign rvfi_mode_o = 2'd3;
	assign rvfi_ixl_o = 2'd1;
	assign rvfi_halt_o = 1'b0;
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i) begin
			rvfi_rs1_addr_o <= 1'sb0;
			rvfi_rs1_rdata_o <= 1'sb0;
		end
		else if (w_op1_gpr_i) begin
			rvfi_rs1_addr_o <= w_rs1_addr_i;
			rvfi_rs1_rdata_o <= w_rs1_rdata_i;
		end
		else begin
			rvfi_rs1_addr_o <= 1'sb0;
			rvfi_rs1_rdata_o <= 1'sb0;
		end
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i) begin
			rvfi_rs2_addr_o <= 1'sb0;
			rvfi_rs2_rdata_o <= 1'sb0;
		end
		else if (w_op2_gpr_i) begin
			rvfi_rs2_addr_o <= w_rs2_addr_i;
			rvfi_rs2_rdata_o <= w_rs2_rdata_i;
		end
		else begin
			rvfi_rs2_addr_o <= 1'sb0;
			rvfi_rs2_rdata_o <= 1'sb0;
		end
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i) begin
			rvfi_rd_addr_o <= 1'sb0;
			rvfi_rd_wdata_o <= 1'sb0;
		end
		else if (w_wb_we_i) begin
			rvfi_rd_addr_o <= w_wb_rd_addr_i;
			if (w_wb_rd_addr_i == 0)
				rvfi_rd_wdata_o <= 1'sb0;
			else
				rvfi_rd_wdata_o <= w_wb_data_i;
		end
		else begin
			rvfi_rd_addr_o <= 1'sb0;
			rvfi_rd_wdata_o <= 1'sb0;
		end
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i)
			rvfi_insn_o <= 1'sb0;
		else
			rvfi_insn_o <= w_instr_i;
	reg [3:0] w_data_mask;
	localparam miriscv_lsu_pkg_MEM_ACCESS_BYTE = 3'd2;
	localparam miriscv_lsu_pkg_MEM_ACCESS_HALF = 3'd1;
	localparam miriscv_lsu_pkg_MEM_ACCESS_UBYTE = 3'd4;
	localparam miriscv_lsu_pkg_MEM_ACCESS_UHALF = 3'd3;
	localparam miriscv_lsu_pkg_MEM_ACCESS_WORD = 3'd0;
	always @(*) begin
		if (_sv2v_0)
			;
		if (w_data_size_i == miriscv_lsu_pkg_MEM_ACCESS_WORD)
			w_data_mask = 4'b1111;
		else if ((w_data_size_i == miriscv_lsu_pkg_MEM_ACCESS_HALF) || (w_data_size_i == miriscv_lsu_pkg_MEM_ACCESS_UHALF))
			w_data_mask = 4'b0011;
		else if ((w_data_size_i == miriscv_lsu_pkg_MEM_ACCESS_BYTE) || (w_data_size_i == miriscv_lsu_pkg_MEM_ACCESS_UBYTE))
			w_data_mask = 4'b0001;
		else
			w_data_mask = 'bx;
	end
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i) begin
			rvfi_mem_addr_o <= 1'sb0;
			rvfi_mem_rmask_o <= 1'sb0;
			rvfi_mem_wmask_o <= 1'sb0;
			rvfi_mem_rdata_o <= 1'sb0;
			rvfi_mem_wdata_o <= 1'sb0;
		end
		else if (w_data_req_i) begin
			rvfi_mem_addr_o <= w_data_addr_i;
			rvfi_mem_wmask_o <= 1'sb0;
			rvfi_mem_wdata_o <= 1'sb0;
			rvfi_mem_rmask_o <= 1'sb0;
			rvfi_mem_rdata_o <= 1'sb0;
			if (w_data_we_i) begin
				rvfi_mem_wmask_o <= w_data_mask;
				rvfi_mem_wdata_o <= w_data_wdata_i;
			end
			else begin
				rvfi_mem_rmask_o <= w_data_mask;
				rvfi_mem_rdata_o <= w_data_rdata_i;
			end
		end
		else begin
			rvfi_mem_addr_o <= 1'sb0;
			rvfi_mem_rmask_o <= 1'sb0;
			rvfi_mem_wmask_o <= 1'sb0;
			rvfi_mem_rdata_o <= 1'sb0;
			rvfi_mem_wdata_o <= 1'sb0;
		end
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i) begin
			rvfi_valid_o <= 1'sb0;
			rvfi_order_o <= 1'sb0;
		end
		else begin
			rvfi_valid_o <= w_valid_i;
			rvfi_order_o <= rvfi_order_o + rvfi_valid_o;
		end
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i) begin
			rvfi_pc_rdata_o <= 1'sb0;
			rvfi_pc_wdata_o <= 1'sb0;
		end
		else begin
			rvfi_pc_rdata_o <= w_current_pc_i;
			rvfi_pc_wdata_o <= w_next_pc_i;
		end
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i)
			rvfi_trap_o <= 1'sb0;
		else
			rvfi_trap_o <= w_trap_i;
	always @(posedge clk_i or negedge aresetn_i)
		if (~aresetn_i)
			rvfi_intr_o <= 1'sb0;
		else
			rvfi_intr_o <= w_intr_i;
	initial _sv2v_0 = 0;
endmodule
module miriscv_decoder (
	decode_instr_i,
	decode_rs1_re_o,
	decode_rs2_re_o,
	decode_ex_op1_sel_o,
	decode_ex_op2_sel_o,
	decode_alu_operation_o,
	decode_mdu_operation_o,
	decode_ex_mdu_req_o,
	decode_mem_we_o,
	decode_mem_size_o,
	decode_mem_req_o,
	decode_wb_src_sel_o,
	decode_wb_we_o,
	decode_fence_o,
	decode_branch_o,
	decode_jal_o,
	decode_jalr_o,
	decode_load_o,
	decode_illegal_instr_o
);
	reg _sv2v_0;
	localparam miriscv_pkg_ILEN = 32;
	input wire [31:0] decode_instr_i;
	output wire decode_rs1_re_o;
	output wire decode_rs2_re_o;
	localparam miriscv_decode_pkg_OP1_SEL_W = 2;
	output reg [1:0] decode_ex_op1_sel_o;
	localparam miriscv_decode_pkg_OP2_SEL_W = 2;
	output reg [1:0] decode_ex_op2_sel_o;
	localparam miriscv_alu_pkg_ALU_OP_W = 5;
	output reg [4:0] decode_alu_operation_o;
	localparam miriscv_mdu_pkg_MDU_OP_W = 3;
	output reg [2:0] decode_mdu_operation_o;
	output wire decode_ex_mdu_req_o;
	output wire decode_mem_we_o;
	localparam miriscv_lsu_pkg_MEM_ACCESS_W = 3;
	output reg [2:0] decode_mem_size_o;
	output wire decode_mem_req_o;
	localparam miriscv_decode_pkg_WB_SRC_W = 2;
	output reg [1:0] decode_wb_src_sel_o;
	output wire decode_wb_we_o;
	output wire decode_fence_o;
	output reg decode_branch_o;
	output reg decode_jal_o;
	output reg decode_jalr_o;
	output wire decode_load_o;
	output wire decode_illegal_instr_o;
	wire [6:0] funct7;
	wire [4:0] opcode;
	wire [2:0] funct3;
	reg [4:0] alu_op;
	reg ill_fence;
	reg ill_op;
	reg ill_opimm;
	reg ill_load;
	reg ill_store;
	reg ill_branch;
	reg ill_opcode;
	reg ill_op_mul;
	reg ill_op_s;
	reg ill_op_others;
	wire ill_last_bits;
	assign opcode = decode_instr_i[6:2];
	assign funct3 = decode_instr_i[14:12];
	assign funct7 = decode_instr_i[31:25];
	localparam miriscv_decode_pkg_RS1_DATA = 2'd0;
	assign decode_rs1_re_o = (decode_ex_op1_sel_o == miriscv_decode_pkg_RS1_DATA) && !decode_illegal_instr_o;
	localparam miriscv_decode_pkg_RS2_DATA = 2'd0;
	assign decode_rs2_re_o = (decode_ex_op2_sel_o == miriscv_decode_pkg_RS2_DATA) && !decode_illegal_instr_o;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_OP = 5'b01100;
	assign decode_ex_mdu_req_o = ((opcode == miriscv_opcodes_pkg_S_OPCODE_OP) && (funct7 == 1'b1)) && !(ill_last_bits || ill_op_mul);
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_FENCE = 5'b00011;
	assign decode_wb_we_o = !(((opcode == miriscv_opcodes_pkg_S_OPCODE_FENCE) || decode_illegal_instr_o) || (opcode[3:0] == 4'b1000));
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_LOAD = 5'b00000;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_STORE = 5'b01000;
	assign decode_mem_req_o = ((opcode == miriscv_opcodes_pkg_S_OPCODE_LOAD) || (opcode == miriscv_opcodes_pkg_S_OPCODE_STORE)) && !((ill_load || ill_store) || ill_last_bits);
	assign decode_mem_we_o = (opcode == miriscv_opcodes_pkg_S_OPCODE_STORE) && !(ill_store || ill_last_bits);
	assign decode_load_o = (opcode == miriscv_opcodes_pkg_S_OPCODE_LOAD) && !(ill_load || ill_last_bits);
	assign decode_illegal_instr_o = ((((((ill_fence || ill_op) || ill_opimm) || ill_load) || ill_store) || ill_branch) || ill_opcode) || ill_last_bits;
	assign decode_fence_o = (opcode == miriscv_opcodes_pkg_S_OPCODE_FENCE) && !(ill_fence || ill_last_bits);
	assign ill_last_bits = decode_instr_i[1:0] != 2'b11;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_AUIPC = 5'b00101;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_BRANCH = 5'b11000;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_JAL = 5'b11011;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_JALR = 5'b11001;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_LUI = 5'b01101;
	localparam [4:0] miriscv_opcodes_pkg_S_OPCODE_OPIMM = 5'b00100;
	localparam [0:0] miriscv_pkg_RV32M = 1;
	always @(*) begin
		if (_sv2v_0)
			;
		ill_fence = 1'b0;
		ill_op = 1'b0;
		ill_opimm = 1'b0;
		ill_load = 1'b0;
		ill_store = 1'b0;
		ill_branch = 1'b0;
		ill_op_mul = 1'b0;
		ill_op_s = 1'b0;
		ill_op_others = 1'b0;
		if ((opcode == miriscv_opcodes_pkg_S_OPCODE_FENCE) || (opcode == miriscv_opcodes_pkg_S_OPCODE_JALR)) begin
			if (funct3 != 3'b000)
				ill_fence = 1'b1;
		end
		if (((funct7 != 7'd0) && (funct7 != 7'b0100000)) && (funct7 != 3'd1))
			ill_op_others = 1'b1;
		if (((funct7 == 7'b0100000) && (funct3 != 3'b000)) && (funct3 != 3'b101))
			ill_op_s = 1'b1;
		if ((funct7 == 7'd1) && !miriscv_pkg_RV32M)
			ill_op_mul = 1'b1;
		if (opcode == miriscv_opcodes_pkg_S_OPCODE_OP)
			ill_op = (ill_op_others || ill_op_s) || ill_op_mul;
		if (opcode == miriscv_opcodes_pkg_S_OPCODE_OPIMM) begin
			if (((funct3[1:0] == 2'b01) && ({funct7[6], funct7[4:0]} != 6'd0)) || ((funct3 == 3'b001) && (funct7[5] == 1'b1)))
				ill_opimm = 1'b1;
		end
		if (opcode == miriscv_opcodes_pkg_S_OPCODE_LOAD) begin
			if ((funct3 == 3) || (funct3 > 5))
				ill_load = 1'b1;
		end
		if (opcode == miriscv_opcodes_pkg_S_OPCODE_STORE) begin
			if (funct3 > 2)
				ill_store = 1'b1;
		end
		if (opcode == miriscv_opcodes_pkg_S_OPCODE_BRANCH) begin
			if ((funct3 == 3'b010) || (funct3 == 3'b011))
				ill_branch = 1'b1;
		end
		case (opcode)
			miriscv_opcodes_pkg_S_OPCODE_FENCE: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_OP: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_OPIMM: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_LOAD: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_STORE: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_BRANCH: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_JAL: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_JALR: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_AUIPC: ill_opcode = 1'b0;
			miriscv_opcodes_pkg_S_OPCODE_LUI: ill_opcode = 1'b0;
			default: ill_opcode = 1'b1;
		endcase
	end
	localparam miriscv_alu_pkg_ALU_ADD = 5'b00000;
	localparam miriscv_alu_pkg_ALU_AND = 5'b01111;
	localparam miriscv_alu_pkg_ALU_EQ = 5'b00010;
	localparam miriscv_alu_pkg_ALU_GE = 5'b00110;
	localparam miriscv_alu_pkg_ALU_GEU = 5'b00111;
	localparam miriscv_alu_pkg_ALU_JAL = 5'b10000;
	localparam miriscv_alu_pkg_ALU_LT = 5'b00100;
	localparam miriscv_alu_pkg_ALU_LTU = 5'b00101;
	localparam miriscv_alu_pkg_ALU_NE = 5'b00011;
	localparam miriscv_alu_pkg_ALU_OR = 5'b01110;
	localparam miriscv_alu_pkg_ALU_SLL = 5'b01010;
	localparam miriscv_alu_pkg_ALU_SLT = 5'b01000;
	localparam miriscv_alu_pkg_ALU_SLTU = 5'b01001;
	localparam miriscv_alu_pkg_ALU_SRA = 5'b01100;
	localparam miriscv_alu_pkg_ALU_SRL = 5'b01011;
	localparam miriscv_alu_pkg_ALU_SUB = 5'b00001;
	localparam miriscv_alu_pkg_ALU_XOR = 5'b01101;
	localparam miriscv_decode_pkg_ALU_DATA = 2'd0;
	localparam miriscv_decode_pkg_CURRENT_PC = 2'd1;
	localparam miriscv_decode_pkg_IMM_I = 2'd1;
	localparam miriscv_decode_pkg_IMM_U = 2'd2;
	localparam miriscv_decode_pkg_LSU_DATA = 2'd2;
	localparam miriscv_decode_pkg_MDU_DATA = 2'd1;
	localparam miriscv_decode_pkg_NEXT_PC = 2'd3;
	localparam miriscv_decode_pkg_ZERO = 2'd3;
	localparam miriscv_lsu_pkg_MEM_ACCESS_BYTE = 3'd2;
	localparam miriscv_lsu_pkg_MEM_ACCESS_HALF = 3'd1;
	localparam miriscv_lsu_pkg_MEM_ACCESS_UBYTE = 3'd4;
	localparam miriscv_lsu_pkg_MEM_ACCESS_UHALF = 3'd3;
	localparam miriscv_lsu_pkg_MEM_ACCESS_WORD = 3'd0;
	localparam miriscv_mdu_pkg_MDU_DIV = 3'd4;
	localparam miriscv_mdu_pkg_MDU_DIVU = 3'd5;
	localparam miriscv_mdu_pkg_MDU_MUL = 3'd0;
	localparam miriscv_mdu_pkg_MDU_MULH = 3'd1;
	localparam miriscv_mdu_pkg_MDU_MULHSU = 3'd2;
	localparam miriscv_mdu_pkg_MDU_MULHU = 3'd3;
	localparam miriscv_mdu_pkg_MDU_REM = 3'd6;
	localparam miriscv_mdu_pkg_MDU_REMU = 3'd7;
	always @(*) begin
		if (_sv2v_0)
			;
		decode_jal_o = 1'b0;
		decode_jalr_o = 1'b0;
		decode_branch_o = 1'b0;
		(* full_case, parallel_case *)
		case (opcode)
			miriscv_opcodes_pkg_S_OPCODE_LUI: decode_ex_op1_sel_o = miriscv_decode_pkg_ZERO;
			miriscv_opcodes_pkg_S_OPCODE_AUIPC: decode_ex_op1_sel_o = miriscv_decode_pkg_CURRENT_PC;
			miriscv_opcodes_pkg_S_OPCODE_JAL: decode_ex_op1_sel_o = miriscv_decode_pkg_ZERO;
			miriscv_opcodes_pkg_S_OPCODE_FENCE: decode_ex_op1_sel_o = miriscv_decode_pkg_ZERO;
			default: decode_ex_op1_sel_o = miriscv_decode_pkg_RS1_DATA;
		endcase
		(* full_case, parallel_case *)
		case (opcode)
			miriscv_opcodes_pkg_S_OPCODE_OP, miriscv_opcodes_pkg_S_OPCODE_BRANCH, miriscv_opcodes_pkg_S_OPCODE_STORE: decode_ex_op2_sel_o = miriscv_decode_pkg_RS2_DATA;
			miriscv_opcodes_pkg_S_OPCODE_AUIPC, miriscv_opcodes_pkg_S_OPCODE_LUI: decode_ex_op2_sel_o = miriscv_decode_pkg_IMM_U;
			miriscv_opcodes_pkg_S_OPCODE_JAL, miriscv_opcodes_pkg_S_OPCODE_JALR: decode_ex_op2_sel_o = miriscv_decode_pkg_NEXT_PC;
			default: decode_ex_op2_sel_o = miriscv_decode_pkg_IMM_I;
		endcase
		(* full_case, parallel_case *)
		case (opcode)
			miriscv_opcodes_pkg_S_OPCODE_LOAD: decode_wb_src_sel_o = miriscv_decode_pkg_LSU_DATA;
			default: decode_wb_src_sel_o = (decode_ex_mdu_req_o ? miriscv_decode_pkg_MDU_DATA : miriscv_decode_pkg_ALU_DATA);
		endcase
		(* full_case, parallel_case *)
		case (funct3)
			3'b000: decode_mem_size_o = miriscv_lsu_pkg_MEM_ACCESS_BYTE;
			3'b001: decode_mem_size_o = miriscv_lsu_pkg_MEM_ACCESS_HALF;
			3'b100: decode_mem_size_o = miriscv_lsu_pkg_MEM_ACCESS_UBYTE;
			3'b101: decode_mem_size_o = miriscv_lsu_pkg_MEM_ACCESS_UHALF;
			default: decode_mem_size_o = miriscv_lsu_pkg_MEM_ACCESS_WORD;
		endcase
		(* full_case, parallel_case *)
		case (funct3)
			3'b000: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_MUL;
			3'b001: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_MULH;
			3'b010: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_MULHSU;
			3'b011: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_MULHU;
			3'b100: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_DIV;
			3'b101: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_DIVU;
			3'b110: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_REM;
			default: decode_mdu_operation_o = miriscv_mdu_pkg_MDU_REMU;
		endcase
		unique casez ({funct7[5], funct3, opcode})
			{1'b1, 3'b000, miriscv_opcodes_pkg_S_OPCODE_OP}: alu_op = miriscv_alu_pkg_ALU_SUB;
			9'b?0100?100: alu_op = miriscv_alu_pkg_ALU_SLT;
			9'b?0110?100: alu_op = miriscv_alu_pkg_ALU_SLTU;
			9'b?1000?100: alu_op = miriscv_alu_pkg_ALU_XOR;
			9'b?1100?100: alu_op = miriscv_alu_pkg_ALU_OR;
			9'b?1110?100: alu_op = miriscv_alu_pkg_ALU_AND;
			9'b?0010?100: alu_op = miriscv_alu_pkg_ALU_SLL;
			9'b01010?100: alu_op = miriscv_alu_pkg_ALU_SRL;
			9'b11010?100: alu_op = miriscv_alu_pkg_ALU_SRA;

			{4'b000?, miriscv_opcodes_pkg_S_OPCODE_BRANCH}: alu_op = miriscv_alu_pkg_ALU_EQ;
			{4'b001?, miriscv_opcodes_pkg_S_OPCODE_BRANCH}: alu_op = miriscv_alu_pkg_ALU_NE;
			{4'b100?, miriscv_opcodes_pkg_S_OPCODE_BRANCH}: alu_op = miriscv_alu_pkg_ALU_LT;
			{4'b101?, miriscv_opcodes_pkg_S_OPCODE_BRANCH}: alu_op = miriscv_alu_pkg_ALU_GE;
			{4'b110?, miriscv_opcodes_pkg_S_OPCODE_BRANCH}: alu_op = miriscv_alu_pkg_ALU_LTU;
			{4'b111?, miriscv_opcodes_pkg_S_OPCODE_BRANCH}: alu_op = miriscv_alu_pkg_ALU_GEU;

			{4'b????, miriscv_opcodes_pkg_S_OPCODE_JALR}: alu_op = miriscv_alu_pkg_ALU_JAL;
			{4'b????, miriscv_opcodes_pkg_S_OPCODE_JAL}:  alu_op = miriscv_alu_pkg_ALU_JAL;

			default: alu_op = miriscv_alu_pkg_ALU_ADD;
		endcase
		if (decode_illegal_instr_o)
			decode_alu_operation_o = miriscv_alu_pkg_ALU_ADD;
		else if (decode_ex_mdu_req_o == 1'b1)
			decode_alu_operation_o = miriscv_alu_pkg_ALU_ADD;
		else
			decode_alu_operation_o = alu_op;
		if (opcode[4:2] == 3'b110)
			case (opcode[1:0])
				2'b01: decode_jalr_o = !(ill_last_bits || ill_fence);
				2'b11: decode_jal_o = !ill_last_bits;
				default: decode_branch_o = !(ill_last_bits || ill_branch);
			endcase
	end
	initial _sv2v_0 = 0;
endmodule
module miriscv_fetch_unit_slow (
	clk_i,
	arstn_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_req_o,
	instr_addr_o,
	cu_stall_f_i,
	cu_force_f_i,
	cu_force_pc_i,
	fetched_pc_addr_o,
	fetched_pc_next_addr_o,
	instr_o,
	fetch_rvalid_o
);
	input wire clk_i;
	input wire arstn_i;
	input wire instr_rvalid_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] instr_rdata_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire cu_stall_f_i;
	input wire cu_force_f_i;
	input wire [31:0] cu_force_pc_i;
	output wire [31:0] fetched_pc_addr_o;
	output wire [31:0] fetched_pc_next_addr_o;
	localparam miriscv_pkg_ILEN = 32;
	output wire [31:0] instr_o;
	output wire fetch_rvalid_o;
	reg [31:0] pc_ff;
	wire [31:0] pc_next;
	wire [31:0] pc_plus_inc;
	wire fetch_en;
	assign fetch_en = fetch_rvalid_o | cu_force_f_i;
	assign pc_plus_inc = pc_ff + 'd4;
	assign pc_next = (cu_force_f_i ? cu_force_pc_i : pc_plus_inc);
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i)
			pc_ff <= {miriscv_pkg_XLEN {1'b0}};
		else if (fetch_en)
			pc_ff <= pc_next;
	assign instr_req_o = (~cu_stall_f_i & ~instr_rvalid_i) & ~cu_force_f_i;
	assign instr_addr_o = pc_ff;
	assign fetched_pc_addr_o = pc_ff;
	assign fetched_pc_next_addr_o = pc_plus_inc;
	assign instr_o = instr_rdata_i;
	assign fetch_rvalid_o = (instr_rvalid_i & ~cu_force_f_i) & ~cu_stall_f_i;
endmodule
module miriscv_execute_stage (
	clk_i,
	arstn_i,
	cu_kill_e_i,
	cu_stall_e_i,
	e_stall_req_o,
	d_valid_i,
	d_op1_i,
	d_op2_i,
	d_alu_operation_i,
	d_mdu_req_i,
	d_mdu_operation_i,
	d_mem_req_i,
	d_mem_we_i,
	d_mem_size_i,
	d_mem_addr_i,
	d_mem_data_i,
	d_gpr_wr_en_i,
	d_gpr_wr_addr_i,
	d_gpr_src_sel_i,
	d_branch_i,
	d_jal_i,
	d_jalr_i,
	d_target_pc_i,
	d_next_pc_i,
	d_prediction_i,
	d_br_j_taken_i,
	e_valid_o,
	e_alu_result_o,
	e_mdu_result_o,
	e_mem_req_o,
	e_mem_we_o,
	e_mem_size_o,
	e_mem_addr_o,
	e_mem_data_o,
	e_gpr_wr_en_o,
	e_gpr_wr_addr_o,
	e_gpr_src_sel_o,
	e_branch_o,
	e_jal_o,
	e_jalr_o,
	e_target_pc_o,
	e_next_pc_o,
	e_prediction_o,
	e_br_j_taken_o,
	d_rvfi_wb_we_i,
	d_rvfi_wb_rd_addr_i,
	d_rvfi_instr_i,
	d_rvfi_rs1_addr_i,
	d_rvfi_rs2_addr_i,
	d_rvfi_op1_gpr_i,
	d_rvfi_op2_gpr_i,
	d_rvfi_rs1_rdata_i,
	d_rvfi_rs2_rdata_i,
	d_rvfi_current_pc_i,
	d_rvfi_next_pc_i,
	d_rvfi_valid_i,
	d_rvfi_trap_i,
	d_rvfi_intr_i,
	d_rvfi_mem_req_i,
	d_rvfi_mem_we_i,
	d_rvfi_mem_size_i,
	d_rvfi_mem_addr_i,
	d_rvfi_mem_wdata_i,
	e_rvfi_wb_we_o,
	e_rvfi_wb_rd_addr_o,
	e_rvfi_instr_o,
	e_rvfi_rs1_addr_o,
	e_rvfi_rs2_addr_o,
	e_rvfi_op1_gpr_o,
	e_rvfi_op2_gpr_o,
	e_rvfi_rs1_rdata_o,
	e_rvfi_rs2_rdata_o,
	e_rvfi_current_pc_o,
	e_rvfi_next_pc_o,
	e_rvfi_valid_o,
	e_rvfi_trap_o,
	e_rvfi_intr_o,
	e_rvfi_mem_req_o,
	e_rvfi_mem_we_o,
	e_rvfi_mem_size_o,
	e_rvfi_mem_addr_o,
	e_rvfi_mem_wdata_o
);
	parameter [0:0] RVFI = 1'b0;
	input wire clk_i;
	input wire arstn_i;
	input wire cu_kill_e_i;
	input wire cu_stall_e_i;
	output wire e_stall_req_o;
	input wire d_valid_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] d_op1_i;
	input wire [31:0] d_op2_i;
	localparam miriscv_alu_pkg_ALU_OP_W = 5;
	input wire [4:0] d_alu_operation_i;
	input wire d_mdu_req_i;
	localparam miriscv_mdu_pkg_MDU_OP_W = 3;
	input wire [2:0] d_mdu_operation_i;
	input wire d_mem_req_i;
	input wire d_mem_we_i;
	localparam miriscv_lsu_pkg_MEM_ACCESS_W = 3;
	input wire [2:0] d_mem_size_i;
	input wire [31:0] d_mem_addr_i;
	input wire [31:0] d_mem_data_i;
	input wire d_gpr_wr_en_i;
	localparam miriscv_gpr_pkg_RISCV_E = 0;
	localparam miriscv_gpr_pkg_GPR_ADDR_W = 5;
	input wire [4:0] d_gpr_wr_addr_i;
	localparam miriscv_decode_pkg_WB_SRC_W = 2;
	input wire [1:0] d_gpr_src_sel_i;
	input wire d_branch_i;
	input wire d_jal_i;
	input wire d_jalr_i;
	input wire [31:0] d_target_pc_i;
	input wire [31:0] d_next_pc_i;
	input wire d_prediction_i;
	input wire d_br_j_taken_i;
	output wire e_valid_o;
	output wire [31:0] e_alu_result_o;
	output wire [31:0] e_mdu_result_o;
	output wire e_mem_req_o;
	output wire e_mem_we_o;
	output wire [2:0] e_mem_size_o;
	output wire [31:0] e_mem_addr_o;
	output wire [31:0] e_mem_data_o;
	output wire e_gpr_wr_en_o;
	output wire [4:0] e_gpr_wr_addr_o;
	output wire [1:0] e_gpr_src_sel_o;
	output wire e_branch_o;
	output wire e_jal_o;
	output wire e_jalr_o;
	output wire [31:0] e_target_pc_o;
	output wire [31:0] e_next_pc_o;
	output wire e_prediction_o;
	output wire e_br_j_taken_o;
	input wire d_rvfi_wb_we_i;
	input wire [4:0] d_rvfi_wb_rd_addr_i;
	localparam miriscv_pkg_ILEN = 32;
	input wire [31:0] d_rvfi_instr_i;
	input wire [4:0] d_rvfi_rs1_addr_i;
	input wire [4:0] d_rvfi_rs2_addr_i;
	input wire d_rvfi_op1_gpr_i;
	input wire d_rvfi_op2_gpr_i;
	input wire [31:0] d_rvfi_rs1_rdata_i;
	input wire [31:0] d_rvfi_rs2_rdata_i;
	input wire [31:0] d_rvfi_current_pc_i;
	input wire [31:0] d_rvfi_next_pc_i;
	input wire d_rvfi_valid_i;
	input wire d_rvfi_trap_i;
	input wire d_rvfi_intr_i;
	input wire d_rvfi_mem_req_i;
	input wire d_rvfi_mem_we_i;
	input wire [2:0] d_rvfi_mem_size_i;
	input wire [31:0] d_rvfi_mem_addr_i;
	input wire [31:0] d_rvfi_mem_wdata_i;
	output reg e_rvfi_wb_we_o;
	output reg [4:0] e_rvfi_wb_rd_addr_o;
	output reg [31:0] e_rvfi_instr_o;
	output reg [4:0] e_rvfi_rs1_addr_o;
	output reg [4:0] e_rvfi_rs2_addr_o;
	output reg e_rvfi_op1_gpr_o;
	output reg e_rvfi_op2_gpr_o;
	output reg [31:0] e_rvfi_rs1_rdata_o;
	output reg [31:0] e_rvfi_rs2_rdata_o;
	output reg [31:0] e_rvfi_current_pc_o;
	output reg [31:0] e_rvfi_next_pc_o;
	output reg e_rvfi_valid_o;
	output reg e_rvfi_trap_o;
	output reg e_rvfi_intr_o;
	output reg e_rvfi_mem_req_o;
	output reg e_rvfi_mem_we_o;
	output reg [2:0] e_rvfi_mem_size_o;
	output reg [31:0] e_rvfi_mem_addr_o;
	output reg [31:0] e_rvfi_mem_wdata_o;
	wire [31:0] alu_result;
	wire branch_des;
	wire [31:0] mdu_result;
	wire mdu_stall_req;
	wire mdu_req;
	reg e_valid_ff;
	reg [31:0] e_alu_result_ff;
	reg [31:0] e_mdu_result_ff;
	reg e_mem_req_ff;
	reg e_mem_we_ff;
	reg [2:0] e_mem_size_ff;
	reg [31:0] e_mem_addr_ff;
	reg [31:0] e_mem_data_ff;
	reg e_gpr_wr_en_ff;
	reg [4:0] e_gpr_wr_addr_ff;
	reg [1:0] e_gpr_src_sel_ff;
	reg e_branch_ff;
	reg e_jal_ff;
	reg e_jalr_ff;
	reg [31:0] e_target_pc_ff;
	reg [31:0] e_next_pc_ff;
	reg e_prediction_ff;
	reg e_br_j_taken_ff;
	miriscv_alu i_alu(
		.alu_port_a_i(d_op1_i),
		.alu_port_b_i(d_op2_i),
		.alu_op_i(d_alu_operation_i),
		.alu_result_o(alu_result),
		.alu_branch_des_o(branch_des)
	);
	assign mdu_req = d_mdu_req_i & d_valid_i;
	miriscv_mdu i_mdu(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.mdu_req_i(mdu_req),
		.mdu_port_a_i(d_op1_i),
		.mdu_port_b_i(d_op2_i),
		.mdu_op_i(d_mdu_operation_i),
		.mdu_kill_i(cu_kill_e_i),
		.mdu_keep_i(1'b0),
		.mdu_result_o(mdu_result),
		.mdu_stall_req_o(mdu_stall_req)
	);
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i)
			e_valid_ff <= 1'sb0;
		else if (cu_kill_e_i)
			e_valid_ff <= 1'sb0;
		else if (~cu_stall_e_i)
			e_valid_ff <= d_valid_i;
	always @(posedge clk_i)
		if (d_valid_i & ~cu_stall_e_i) begin
			e_alu_result_ff <= alu_result;
			e_mdu_result_ff <= mdu_result;
			e_mem_req_ff <= d_mem_req_i;
			e_mem_we_ff <= d_mem_we_i;
			e_mem_size_ff <= d_mem_size_i;
			e_mem_addr_ff <= d_mem_addr_i;
			e_mem_data_ff <= d_mem_data_i;
			e_gpr_wr_en_ff <= d_gpr_wr_en_i;
			e_gpr_wr_addr_ff <= d_gpr_wr_addr_i;
			e_gpr_src_sel_ff <= d_gpr_src_sel_i;
			e_branch_ff <= d_branch_i;
			e_jal_ff <= d_jal_i;
			e_jalr_ff <= d_jalr_i;
			e_target_pc_ff <= d_target_pc_i;
			e_next_pc_ff <= d_next_pc_i;
			e_prediction_ff <= d_prediction_i;
			e_br_j_taken_ff <= d_br_j_taken_i | (d_branch_i & branch_des);
		end
	assign e_valid_o = e_valid_ff;
	assign e_alu_result_o = e_alu_result_ff;
	assign e_mdu_result_o = e_mdu_result_ff;
	assign e_mem_req_o = e_mem_req_ff;
	assign e_mem_we_o = e_mem_we_ff;
	assign e_mem_size_o = e_mem_size_ff;
	assign e_mem_addr_o = e_mem_addr_ff;
	assign e_mem_data_o = e_mem_data_ff;
	assign e_gpr_wr_en_o = e_gpr_wr_en_ff;
	assign e_gpr_wr_addr_o = e_gpr_wr_addr_ff;
	assign e_gpr_src_sel_o = e_gpr_src_sel_ff;
	assign e_branch_o = e_branch_ff;
	assign e_jal_o = e_jal_ff;
	assign e_jalr_o = e_jalr_ff;
	assign e_target_pc_o = e_target_pc_ff;
	assign e_next_pc_o = e_next_pc_ff;
	assign e_prediction_o = e_prediction_ff;
	assign e_br_j_taken_o = e_br_j_taken_ff;
	assign e_stall_req_o = mdu_stall_req;
	generate
		if (RVFI) begin : genblk1
			always @(posedge clk_i or negedge arstn_i)
				if (~arstn_i) begin
					e_rvfi_wb_we_o <= 1'sb0;
					e_rvfi_wb_rd_addr_o <= 1'sb0;
					e_rvfi_instr_o <= 1'sb0;
					e_rvfi_rs1_addr_o <= 1'sb0;
					e_rvfi_rs2_addr_o <= 1'sb0;
					e_rvfi_op1_gpr_o <= 1'sb0;
					e_rvfi_op2_gpr_o <= 1'sb0;
					e_rvfi_rs1_rdata_o <= 1'sb0;
					e_rvfi_rs2_rdata_o <= 1'sb0;
					e_rvfi_current_pc_o <= 1'sb0;
					e_rvfi_next_pc_o <= 1'sb0;
					e_rvfi_valid_o <= 1'sb0;
					e_rvfi_trap_o <= 1'sb0;
					e_rvfi_intr_o <= 1'sb0;
					e_rvfi_mem_req_o <= 1'sb0;
					e_rvfi_mem_we_o <= 1'sb0;
					e_rvfi_mem_size_o <= 1'sb0;
					e_rvfi_mem_addr_o <= 1'sb0;
					e_rvfi_mem_wdata_o <= 1'sb0;
				end
				else if (cu_kill_e_i) begin
					e_rvfi_wb_we_o <= 1'sb0;
					e_rvfi_wb_rd_addr_o <= 1'sb0;
					e_rvfi_instr_o <= 1'sb0;
					e_rvfi_rs1_addr_o <= 1'sb0;
					e_rvfi_rs2_addr_o <= 1'sb0;
					e_rvfi_op1_gpr_o <= 1'sb0;
					e_rvfi_op2_gpr_o <= 1'sb0;
					e_rvfi_rs1_rdata_o <= 1'sb0;
					e_rvfi_rs2_rdata_o <= 1'sb0;
					e_rvfi_current_pc_o <= 1'sb0;
					e_rvfi_next_pc_o <= 1'sb0;
					e_rvfi_valid_o <= 1'sb0;
					e_rvfi_trap_o <= 1'sb0;
					e_rvfi_intr_o <= 1'sb0;
					e_rvfi_mem_req_o <= 1'sb0;
					e_rvfi_mem_we_o <= 1'sb0;
					e_rvfi_mem_size_o <= 1'sb0;
					e_rvfi_mem_addr_o <= 1'sb0;
					e_rvfi_mem_wdata_o <= 1'sb0;
				end
				else if (~cu_stall_e_i) begin
					e_rvfi_wb_we_o <= d_rvfi_wb_we_i;
					e_rvfi_wb_rd_addr_o <= d_rvfi_wb_rd_addr_i;
					e_rvfi_instr_o <= d_rvfi_instr_i;
					e_rvfi_rs1_addr_o <= d_rvfi_rs1_addr_i;
					e_rvfi_rs2_addr_o <= d_rvfi_rs2_addr_i;
					e_rvfi_op1_gpr_o <= d_rvfi_op1_gpr_i;
					e_rvfi_op2_gpr_o <= d_rvfi_op2_gpr_i;
					e_rvfi_rs1_rdata_o <= d_rvfi_rs1_rdata_i;
					e_rvfi_rs2_rdata_o <= d_rvfi_rs2_rdata_i;
					e_rvfi_current_pc_o <= d_rvfi_current_pc_i;
					e_rvfi_next_pc_o <= d_rvfi_next_pc_i;
					e_rvfi_valid_o <= d_rvfi_valid_i;
					e_rvfi_trap_o <= d_rvfi_trap_i;
					e_rvfi_intr_o <= d_rvfi_intr_i;
					e_rvfi_mem_req_o <= d_rvfi_mem_req_i;
					e_rvfi_mem_we_o <= d_rvfi_mem_we_i;
					e_rvfi_mem_size_o <= d_rvfi_mem_size_i;
					e_rvfi_mem_addr_o <= d_rvfi_mem_addr_i;
					e_rvfi_mem_wdata_o <= d_rvfi_mem_wdata_i;
				end
		end
		else begin : genblk1
			wire [1:1] sv2v_tmp_6EDC6;
			assign sv2v_tmp_6EDC6 = 1'sb0;
			always @(*) e_rvfi_wb_we_o = sv2v_tmp_6EDC6;
			wire [5:1] sv2v_tmp_D8F85;
			assign sv2v_tmp_D8F85 = 1'sb0;
			always @(*) e_rvfi_wb_rd_addr_o = sv2v_tmp_D8F85;
			wire [32:1] sv2v_tmp_43409;
			assign sv2v_tmp_43409 = 1'sb0;
			always @(*) e_rvfi_instr_o = sv2v_tmp_43409;
			wire [5:1] sv2v_tmp_78671;
			assign sv2v_tmp_78671 = 1'sb0;
			always @(*) e_rvfi_rs1_addr_o = sv2v_tmp_78671;
			wire [5:1] sv2v_tmp_1C075;
			assign sv2v_tmp_1C075 = 1'sb0;
			always @(*) e_rvfi_rs2_addr_o = sv2v_tmp_1C075;
			wire [1:1] sv2v_tmp_56E5F;
			assign sv2v_tmp_56E5F = 1'sb0;
			always @(*) e_rvfi_op1_gpr_o = sv2v_tmp_56E5F;
			wire [1:1] sv2v_tmp_69125;
			assign sv2v_tmp_69125 = 1'sb0;
			always @(*) e_rvfi_op2_gpr_o = sv2v_tmp_69125;
			wire [32:1] sv2v_tmp_3C861;
			assign sv2v_tmp_3C861 = 1'sb0;
			always @(*) e_rvfi_rs1_rdata_o = sv2v_tmp_3C861;
			wire [32:1] sv2v_tmp_42379;
			assign sv2v_tmp_42379 = 1'sb0;
			always @(*) e_rvfi_rs2_rdata_o = sv2v_tmp_42379;
			wire [32:1] sv2v_tmp_BB240;
			assign sv2v_tmp_BB240 = 1'sb0;
			always @(*) e_rvfi_current_pc_o = sv2v_tmp_BB240;
			wire [32:1] sv2v_tmp_06317;
			assign sv2v_tmp_06317 = 1'sb0;
			always @(*) e_rvfi_next_pc_o = sv2v_tmp_06317;
			wire [1:1] sv2v_tmp_DDEBD;
			assign sv2v_tmp_DDEBD = 1'sb0;
			always @(*) e_rvfi_valid_o = sv2v_tmp_DDEBD;
			wire [1:1] sv2v_tmp_F228C;
			assign sv2v_tmp_F228C = 1'sb0;
			always @(*) e_rvfi_trap_o = sv2v_tmp_F228C;
			wire [1:1] sv2v_tmp_41A1F;
			assign sv2v_tmp_41A1F = 1'sb0;
			always @(*) e_rvfi_intr_o = sv2v_tmp_41A1F;
			wire [1:1] sv2v_tmp_3A45F;
			assign sv2v_tmp_3A45F = 1'sb0;
			always @(*) e_rvfi_mem_req_o = sv2v_tmp_3A45F;
			wire [1:1] sv2v_tmp_B61A0;
			assign sv2v_tmp_B61A0 = 1'sb0;
			always @(*) e_rvfi_mem_we_o = sv2v_tmp_B61A0;
			wire [3:1] sv2v_tmp_5FEC3;
			assign sv2v_tmp_5FEC3 = 1'sb0;
			always @(*) e_rvfi_mem_size_o = sv2v_tmp_5FEC3;
			wire [32:1] sv2v_tmp_DB7E4;
			assign sv2v_tmp_DB7E4 = 1'sb0;
			always @(*) e_rvfi_mem_addr_o = sv2v_tmp_DB7E4;
			wire [32:1] sv2v_tmp_E2E6D;
			assign sv2v_tmp_E2E6D = 1'sb0;
			always @(*) e_rvfi_mem_wdata_o = sv2v_tmp_E2E6D;
		end
	endgenerate
endmodule
module miriscv_div (
	clk_i,
	arstn_i,
	div_start_i,
	port_a_i,
	port_b_i,
	mdu_op_i,
	zero_i,
	kill_i,
	keep_i,
	div_result_o,
	rem_result_o,
	div_stall_req_o
);
	reg _sv2v_0;
	parameter DIV_IMPLEMENTATION = "GENERIC";
	input wire clk_i;
	input wire arstn_i;
	input wire div_start_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] port_a_i;
	input wire [31:0] port_b_i;
	localparam miriscv_mdu_pkg_MDU_OP_W = 3;
	input wire [2:0] mdu_op_i;
	input wire zero_i;
	input wire kill_i;
	input wire keep_i;
	output wire [31:0] div_result_o;
	output wire [31:0] rem_result_o;
	output wire div_stall_req_o;
	reg [2:0] d_state_ff;
	reg [2:0] d_next_state;
	reg [31:0] div_result_ff;
	reg signed [64:0] rem_result_ff;
	reg [31:0] div_operand_a_ff;
	reg [31:0] div_operand_b_ff;
	reg sign_inv_ff;
	reg [4:0] iter_ff;
	wire sign_a;
	wire sign_b;
	wire div_done;
	assign sign_a = port_a_i[31];
	assign sign_b = port_b_i[31];
	assign div_done = d_state_ff == 3'd5;
	assign div_stall_req_o = div_start_i && !div_done;
	always @(posedge clk_i)
		if (~arstn_i)
			d_state_ff <= 3'd0;
		else if (kill_i)
			d_state_ff <= 3'd0;
		else
			d_state_ff <= d_next_state;
	always @(*) begin
		if (_sv2v_0)
			;
		case (d_state_ff)
			3'd0:
				if (div_start_i)
					d_next_state = 3'd1;
				else
					d_next_state = 3'd0;
			3'd1:
				if (zero_i)
					d_next_state = 3'd5;
				else
					d_next_state = 3'd2;
			3'd2:
				if (iter_ff == 'd1)
					d_next_state = 3'd3;
				else
					d_next_state = 3'd2;
			3'd3:
				if (sign_inv_ff)
					d_next_state = 3'd4;
				else
					d_next_state = 3'd5;
			3'd4: d_next_state = 3'd5;
			3'd5:
				if (~keep_i)
					d_next_state = 3'd0;
				else
					d_next_state = 3'd5;
			default: d_next_state = 3'd0;
		endcase
	end
	localparam miriscv_mdu_pkg_MDU_DIV = 3'd4;
	localparam miriscv_mdu_pkg_MDU_DIVU = 3'd5;
	localparam miriscv_mdu_pkg_MDU_REM = 3'd6;
	localparam miriscv_mdu_pkg_MDU_REMU = 3'd7;
	generate
		if (DIV_IMPLEMENTATION == "XILINX_7_SERIES") begin : dsp_div
			wire [6:0] dsp48_opmode;
			reg [3:0] dsp48_alumode;
			reg signed [29:0] dsp48_A;
			reg signed [17:0] dsp48_B;
			reg signed [47:0] dsp48_C;
			wire signed [47:0] dsp48_P;
			localparam [1:0] OPMODE_X_AB_CONCAT = 2'b11;
			localparam [1:0] OPMODE_Y_ZERO = 2'b00;
			localparam [2:0] OPMODE_Z_C = 3'b011;
			localparam [3:0] ALUMODE_SUM = 4'b0000;
			localparam [3:0] ALUMODE_INV_Z = 4'b0001;
			localparam [3:0] ALUMODE_SUB = 4'b0011;
			mrv1f_dsp48_wrapper #(
				.A_INPUT_SOURCE("DIRECT"),
				.B_INPUT_SOURCE("DIRECT"),
				.USE_MULT("NONE"),
				.A_REG(2'b00),
				.B_REG(2'b00),
				.P_REG(1'b0)
			) i_dsp48(
				.clk_i(clk_i),
				.srstn_i(arstn_i),
				.enable(1'b1),
				.OPMODE(dsp48_opmode),
				.ALUMODE(dsp48_alumode),
				.A(dsp48_A),
				.B(dsp48_B),
				.C(dsp48_C),
				.P(dsp48_P)
			);
			assign dsp48_opmode[6:4] = OPMODE_Z_C;
			assign dsp48_opmode[3:2] = OPMODE_Y_ZERO;
			assign dsp48_opmode[1:0] = OPMODE_X_AB_CONCAT;
			always @(*) begin
				if (_sv2v_0)
					;
				if (|{((4'h3 ^ ({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff})) === ({rem_result_ff[64], d_state_ff} ^ (4'h3 ^ 4'h3))) & (((({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff}) ^ (4'h3 ^ 4'h3)) === (4'h3 ^ 4'h3)) | 1'bx), ((4'bz100 ^ ({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff})) === ({rem_result_ff[64], d_state_ff} ^ (4'bz100 ^ 4'bz100))) & (((({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff}) ^ (4'bz100 ^ 4'bz100)) === (4'bz100 ^ 4'bz100)) | 1'bx)})
					dsp48_A = 'd0;
				else
					dsp48_A = {1'sb0, div_operand_b_ff[31:18]};
				if (((4'h3 ^ ({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff})) === ({rem_result_ff[64], d_state_ff} ^ (4'h3 ^ 4'h3))) & (((({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff}) ^ (4'h3 ^ 4'h3)) === (4'h3 ^ 4'h3)) | 1'bx))
					dsp48_B = 'd0;
				else if (((4'bz100 ^ ({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff})) === ({rem_result_ff[64], d_state_ff} ^ (4'bz100 ^ 4'bz100))) & (((({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff}) ^ (4'bz100 ^ 4'bz100)) === (4'bz100 ^ 4'bz100)) | 1'bx))
					dsp48_B = 'd1;
				else
					dsp48_B = div_operand_b_ff[17:0];
				case (d_state_ff)
					3'd1: dsp48_C = div_operand_a_ff[31];
					3'd2: dsp48_C = rem_result_ff[63:31];
					default: dsp48_C = rem_result_ff[64:miriscv_pkg_XLEN];
				endcase
				if (|{((4'ha ^ ({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff})) === ({rem_result_ff[64], d_state_ff} ^ (4'ha ^ 4'ha))) & (((({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff}) ^ (4'ha ^ 4'ha)) === (4'ha ^ 4'ha)) | 1'bx), ((4'hb ^ ({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff})) === ({rem_result_ff[64], d_state_ff} ^ (4'hb ^ 4'hb))) & (((({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff}) ^ (4'hb ^ 4'hb)) === (4'hb ^ 4'hb)) | 1'bx)})
					dsp48_alumode = ALUMODE_SUM;
				else if (((4'bz100 ^ ({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff})) === ({rem_result_ff[64], d_state_ff} ^ (4'bz100 ^ 4'bz100))) & (((({rem_result_ff[64], d_state_ff} ^ {rem_result_ff[64], d_state_ff}) ^ (4'bz100 ^ 4'bz100)) === (4'bz100 ^ 4'bz100)) | 1'bx))
					dsp48_alumode = ALUMODE_INV_Z;
				else
					dsp48_alumode = ALUMODE_SUB;
			end
			always @(posedge clk_i)
				if (~arstn_i) begin
					div_result_ff <= {miriscv_pkg_XLEN {1'b0}};
					rem_result_ff <= {65 {1'b0}};
					div_operand_a_ff <= {miriscv_pkg_XLEN {1'b0}};
					div_operand_b_ff <= {miriscv_pkg_XLEN {1'b0}};
					sign_inv_ff <= 1'b0;
					iter_ff <= {5 {1'b0}};
				end
				else begin
					rem_result_ff[64:miriscv_pkg_XLEN] <= dsp48_P[miriscv_pkg_XLEN:0];
					case (d_state_ff)
						3'd0: begin
							case (mdu_op_i)
								miriscv_mdu_pkg_MDU_DIV, miriscv_mdu_pkg_MDU_REM: begin
									div_operand_a_ff <= (sign_a ? ~port_a_i + 'd1 : port_a_i);
									div_operand_b_ff <= (sign_b ? ~port_b_i + 'd1 : port_b_i);
								end
								miriscv_mdu_pkg_MDU_DIVU, miriscv_mdu_pkg_MDU_REMU: begin
									div_operand_a_ff <= port_a_i;
									div_operand_b_ff <= port_b_i;
								end
								default:
									;
							endcase
							case (mdu_op_i)
								miriscv_mdu_pkg_MDU_DIV: sign_inv_ff <= sign_a ^ sign_b;
								miriscv_mdu_pkg_MDU_REM: sign_inv_ff <= sign_a;
								default: sign_inv_ff <= 1'b0;
							endcase
						end
						3'd1: begin
							iter_ff <= 31;
							if (zero_i) begin
								div_result_ff <= 1'sb1;
								rem_result_ff[63:miriscv_pkg_XLEN] <= port_a_i;
							end
							else begin
								div_result_ff <= {{31 {~sign_inv_ff}}, 1'b1};
								rem_result_ff[31:0] <= {div_operand_a_ff[30:0], 1'b0};
							end
						end
						3'd2, 3'd3: begin
							iter_ff <= iter_ff - 1;
							rem_result_ff[31:0] <= {rem_result_ff[30:0], 1'b0};
							div_result_ff[iter_ff] <= !rem_result_ff[64];
						end
						3'd4: div_result_ff <= ~div_result_ff + 'd1;
						default:
							;
					endcase
				end
		end
		else if (DIV_IMPLEMENTATION == "GENERIC") begin : genblk1
			always @(posedge clk_i)
				if (~arstn_i) begin
					div_result_ff <= {miriscv_pkg_XLEN {1'b0}};
					rem_result_ff <= {65 {1'b0}};
					div_operand_a_ff <= {miriscv_pkg_XLEN {1'b0}};
					div_operand_b_ff <= {miriscv_pkg_XLEN {1'b0}};
					sign_inv_ff <= 1'b0;
					iter_ff <= {5 {1'b0}};
				end
				else
					case (d_state_ff)
						3'd0: begin
							case (mdu_op_i)
								miriscv_mdu_pkg_MDU_DIV, miriscv_mdu_pkg_MDU_REM: begin
									div_operand_a_ff <= (sign_a ? ~port_a_i + 'd1 : port_a_i);
									div_operand_b_ff <= (sign_b ? ~port_b_i + 'd1 : port_b_i);
								end
								miriscv_mdu_pkg_MDU_DIVU, miriscv_mdu_pkg_MDU_REMU: begin
									div_operand_a_ff <= port_a_i;
									div_operand_b_ff <= port_b_i;
								end
								default:
									;
							endcase
							case (mdu_op_i)
								miriscv_mdu_pkg_MDU_DIV: sign_inv_ff <= sign_a ^ sign_b;
								miriscv_mdu_pkg_MDU_REM: sign_inv_ff <= sign_a;
								default: sign_inv_ff <= 1'b0;
							endcase
						end
						3'd1: begin
							iter_ff <= 31;
							if (zero_i) begin
								div_result_ff <= 1'sb1;
								rem_result_ff[63:miriscv_pkg_XLEN] <= port_a_i;
							end
							else begin
								div_result_ff <= {{31 {~sign_inv_ff}}, 1'b1};
								rem_result_ff[64:miriscv_pkg_XLEN] <= div_operand_a_ff[31] - div_operand_b_ff[31:0];
								rem_result_ff[31:0] <= {div_operand_a_ff[30:0], 1'b0};
							end
						end
						3'd2: begin
							iter_ff <= iter_ff - 'd1;
							div_result_ff[iter_ff] <= !rem_result_ff[64];
							rem_result_ff[31:0] <= {rem_result_ff[30:0], 1'b0};
							if (rem_result_ff[64])
								rem_result_ff[64:miriscv_pkg_XLEN] <= rem_result_ff[63:31] + div_operand_b_ff[31:0];
							else
								rem_result_ff[64:miriscv_pkg_XLEN] <= rem_result_ff[63:31] - div_operand_b_ff[31:0];
						end
						3'd3: begin
							div_result_ff[0] <= !rem_result_ff[64];
							if (rem_result_ff[64])
								rem_result_ff[64:miriscv_pkg_XLEN] <= rem_result_ff[64:miriscv_pkg_XLEN] + div_operand_b_ff[31:0];
						end
						3'd4: begin
							rem_result_ff[64:miriscv_pkg_XLEN] <= ~rem_result_ff[64:miriscv_pkg_XLEN] + 'd1;
							div_result_ff <= ~div_result_ff + 'd1;
						end
						default:
							;
					endcase
		end
	endgenerate
	assign div_result_o = div_result_ff;
	assign rem_result_o = rem_result_ff[63:miriscv_pkg_XLEN];
	initial if ((DIV_IMPLEMENTATION != "XILINX_7_SERIES") && (DIV_IMPLEMENTATION != "GENERIC"))
		$display("Error [%0t] ./miriscv_div.sv:355:7 - miriscv_div.<unnamed_block>.<unnamed_block>\n msg: ", $time, "Illegal parameter 'DIV_IMPLEMENTATION' in module 'mrv1f_div': %s", DIV_IMPLEMENTATION);
	initial _sv2v_0 = 0;
endmodule
module miriscv_fetch_unit (
	clk_i,
	arstn_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_req_o,
	instr_addr_o,
	cu_stall_f_i,
	cu_force_pc_i,
	cu_force_f_i,
	fetched_pc_addr_o,
	fetched_pc_next_addr_o,
	instr_o,
	fetch_rvalid_o
);
	input wire clk_i;
	input wire arstn_i;
	input wire instr_rvalid_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] instr_rdata_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire cu_stall_f_i;
	input wire [31:0] cu_force_pc_i;
	input wire cu_force_f_i;
	output wire [31:0] fetched_pc_addr_o;
	output wire [31:0] fetched_pc_next_addr_o;
	localparam miriscv_pkg_ILEN = 32;
	output wire [31:0] instr_o;
	output wire fetch_rvalid_o;
	localparam BYTE_ADDR_W = 2;
	wire [15:0] instr_rdata_s;
	wire misaligned_access;
	reg [31:0] pc_ff;
	wire [31:0] pc_next;
	wire [31:0] pc_plus_inc;
	wire fetch_en;
	wire compr_instr;
	reg [31:0] fetched_pc_ff;
	reg [31:0] fetched_pc_next_ff;
	assign fetch_en = (instr_req_o | cu_force_f_i) | cu_stall_f_i;
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i)
			pc_ff <= {miriscv_pkg_XLEN {1'b0}};
		else if (fetch_en)
			pc_ff <= pc_next;
	assign pc_plus_inc = pc_ff + 'd4;
	assign pc_next = (cu_force_f_i ? cu_force_pc_i : (cu_stall_f_i ? fetched_pc_ff : pc_plus_inc));
	assign instr_req_o = ~cu_force_f_i & ~cu_stall_f_i;
	assign instr_addr_o = pc_ff;
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i) begin
			fetched_pc_ff <= 1'sb0;
			fetched_pc_next_ff <= 1'sb0;
		end
		else if (instr_req_o) begin
			fetched_pc_ff <= pc_ff;
			fetched_pc_next_ff <= pc_next;
		end
	assign fetched_pc_addr_o = fetched_pc_ff;
	assign fetched_pc_next_addr_o = fetched_pc_next_ff;
	assign instr_o = instr_rdata_i;
	assign fetch_rvalid_o = instr_rvalid_i & ~cu_force_f_i;
endmodule
module miriscv_lsu (
	clk_i,
	arstn_i,
	data_rvalid_i,
	data_rdata_i,
	data_req_o,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	lsu_req_i,
	lsu_kill_i,
	lsu_keep_i,
	lsu_we_i,
	lsu_size_i,
	lsu_addr_i,
	lsu_data_i,
	lsu_data_o,
	lsu_stall_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire arstn_i;
	input wire data_rvalid_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] data_rdata_i;
	output wire data_req_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output reg [31:0] data_wdata_o;
	input wire lsu_req_i;
	input wire lsu_kill_i;
	input wire lsu_keep_i;
	input wire lsu_we_i;
	localparam miriscv_lsu_pkg_MEM_ACCESS_W = 3;
	input wire [2:0] lsu_size_i;
	input wire [31:0] lsu_addr_i;
	input wire [31:0] lsu_data_i;
	output reg [31:0] lsu_data_o;
	output wire lsu_stall_o;
	localparam BYTE_ADDR_W = 2;
	reg [3:0] data_be;
	wire [31:0] lsu_data;
	localparam miriscv_lsu_pkg_MEM_ACCESS_BYTE = 3'd2;
	localparam miriscv_lsu_pkg_MEM_ACCESS_HALF = 3'd1;
	localparam miriscv_lsu_pkg_MEM_ACCESS_UBYTE = 3'd4;
	localparam miriscv_lsu_pkg_MEM_ACCESS_UHALF = 3'd3;
	localparam miriscv_lsu_pkg_MEM_ACCESS_WORD = 3'd0;
	always @(*) begin
		if (_sv2v_0)
			;
		case (lsu_size_i)
			miriscv_lsu_pkg_MEM_ACCESS_WORD: data_be = 4'b1111;
			miriscv_lsu_pkg_MEM_ACCESS_UHALF, miriscv_lsu_pkg_MEM_ACCESS_HALF: data_be = 4'b0011 << lsu_addr_i[1:0];
			miriscv_lsu_pkg_MEM_ACCESS_UBYTE, miriscv_lsu_pkg_MEM_ACCESS_BYTE: data_be = 4'b0001 << lsu_addr_i[1:0];
			default: data_be = {4 {1'b0}};
		endcase
		case (lsu_addr_i[1:0])
			2'b00: data_wdata_o = {lsu_data_i[31:0]};
			2'b01: data_wdata_o = {lsu_data_i[23:0], lsu_data_i[31:24]};
			2'b10: data_wdata_o = {lsu_data_i[15:0], lsu_data_i[31:16]};
			2'b11: data_wdata_o = {lsu_data_i[7:0], lsu_data_i[31:8]};
			default: data_wdata_o = {miriscv_pkg_XLEN {1'b0}};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (lsu_size_i)
			miriscv_lsu_pkg_MEM_ACCESS_WORD:
				case (lsu_addr_i[1:0])
					2'b00: lsu_data_o = data_rdata_i[31:0];
					default: lsu_data_o = {miriscv_pkg_XLEN {1'b0}};
				endcase
			miriscv_lsu_pkg_MEM_ACCESS_HALF:
				case (lsu_addr_i[1:0])
					2'b00: lsu_data_o = {{16 {data_rdata_i[15]}}, data_rdata_i[15:0]};
					2'b01: lsu_data_o = {{16 {data_rdata_i[23]}}, data_rdata_i[23:8]};
					2'b10: lsu_data_o = {{16 {data_rdata_i[31]}}, data_rdata_i[31:16]};
					default: lsu_data_o = {miriscv_pkg_XLEN {1'b0}};
				endcase
			miriscv_lsu_pkg_MEM_ACCESS_BYTE:
				case (lsu_addr_i[1:0])
					2'b00: lsu_data_o = {{24 {data_rdata_i[7]}}, data_rdata_i[7:0]};
					2'b01: lsu_data_o = {{24 {data_rdata_i[15]}}, data_rdata_i[15:8]};
					2'b10: lsu_data_o = {{24 {data_rdata_i[23]}}, data_rdata_i[23:16]};
					2'b11: lsu_data_o = {{24 {data_rdata_i[31]}}, data_rdata_i[31:24]};
					default: lsu_data_o = {miriscv_pkg_XLEN {1'b0}};
				endcase
			miriscv_lsu_pkg_MEM_ACCESS_UHALF:
				case (lsu_addr_i[1:0])
					2'b00: lsu_data_o = {{16 {1'b0}}, data_rdata_i[15:0]};
					2'b01: lsu_data_o = {{16 {1'b0}}, data_rdata_i[23:8]};
					2'b10: lsu_data_o = {{16 {1'b0}}, data_rdata_i[31:16]};
					default: lsu_data_o = {miriscv_pkg_XLEN {1'b0}};
				endcase
			miriscv_lsu_pkg_MEM_ACCESS_UBYTE:
				case (lsu_addr_i[1:0])
					2'b00: lsu_data_o = {{24 {1'b0}}, data_rdata_i[7:0]};
					2'b01: lsu_data_o = {{24 {1'b0}}, data_rdata_i[15:8]};
					2'b10: lsu_data_o = {{24 {1'b0}}, data_rdata_i[23:16]};
					2'b11: lsu_data_o = {{24 {1'b0}}, data_rdata_i[31:24]};
					default: lsu_data_o = {miriscv_pkg_XLEN {1'b0}};
				endcase
			default: lsu_data_o = {miriscv_pkg_XLEN {1'b0}};
		endcase
	end
	assign data_req_o = (lsu_req_i & ~lsu_kill_i) & ~data_rvalid_i;
	assign data_addr_o = lsu_addr_i;
	assign data_we_o = lsu_we_i;
	assign data_be_o = data_be;
	assign lsu_stall_o = data_req_o;
	initial _sv2v_0 = 0;
endmodule
module miriscv_alu (
	alu_port_a_i,
	alu_port_b_i,
	alu_op_i,
	alu_result_o,
	alu_branch_des_o
);
	reg _sv2v_0;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] alu_port_a_i;
	input wire [31:0] alu_port_b_i;
	localparam miriscv_alu_pkg_ALU_OP_W = 5;
	input wire [4:0] alu_op_i;
	output reg [31:0] alu_result_o;
	output reg alu_branch_des_o;
	wire [31:0] alu_sum;
	wire alu_cmp;
	reg [31:0] alu_shift;
	reg [31:0] alu_bit;
	wire carry_out;
	wire op_add;
	wire signs_eq;
	reg signed_op;
	wire cmp_ne;
	wire cmp_lt;
	wire [4:0] shift;
	wire signed [31:0] sra_res;
	localparam miriscv_alu_pkg_ALU_ADD = 5'b00000;
	assign op_add = alu_op_i == miriscv_alu_pkg_ALU_ADD;
	assign {carry_out, alu_sum} = (op_add ? alu_port_a_i + alu_port_b_i : alu_port_a_i - alu_port_b_i);
	localparam miriscv_alu_pkg_ALU_GE = 5'b00110;
	localparam miriscv_alu_pkg_ALU_LT = 5'b00100;
	localparam miriscv_alu_pkg_ALU_SLT = 5'b01000;
	always @(*) begin
		if (_sv2v_0)
			;
		case (alu_op_i)
			miriscv_alu_pkg_ALU_LT, miriscv_alu_pkg_ALU_GE, miriscv_alu_pkg_ALU_SLT: signed_op = 1'b1;
			default: signed_op = 1'b0;
		endcase
	end
	assign signs_eq = alu_port_a_i[31] == alu_port_b_i[31];
	assign cmp_ne = |alu_bit;
	assign cmp_lt = (signs_eq ? carry_out : alu_port_a_i[31] == signed_op);
	localparam miriscv_alu_pkg_ALU_EQ = 5'b00010;
	localparam miriscv_alu_pkg_ALU_GEU = 5'b00111;
	localparam miriscv_alu_pkg_ALU_LTU = 5'b00101;
	localparam miriscv_alu_pkg_ALU_NE = 5'b00011;
	always @(*) begin
		if (_sv2v_0)
			;
		case (alu_op_i)
			miriscv_alu_pkg_ALU_EQ: alu_branch_des_o = ~cmp_ne;
			miriscv_alu_pkg_ALU_NE: alu_branch_des_o = cmp_ne;
			miriscv_alu_pkg_ALU_LT, miriscv_alu_pkg_ALU_LTU: alu_branch_des_o = cmp_lt;
			miriscv_alu_pkg_ALU_GE, miriscv_alu_pkg_ALU_GEU: alu_branch_des_o = ~cmp_lt;
			default: alu_branch_des_o = 1'b0;
		endcase
	end
	assign alu_cmp = cmp_lt;
	assign shift = alu_port_b_i[4:0];
	assign sra_res = $signed(alu_port_a_i) >>> shift;
	localparam miriscv_alu_pkg_ALU_SLL = 5'b01010;
	localparam miriscv_alu_pkg_ALU_SRL = 5'b01011;
	always @(*) begin
		if (_sv2v_0)
			;
		case (alu_op_i)
			miriscv_alu_pkg_ALU_SLL: alu_shift = alu_port_a_i << shift;
			miriscv_alu_pkg_ALU_SRL: alu_shift = alu_port_a_i >> shift;
			default: alu_shift = sra_res;
		endcase
	end
	localparam miriscv_alu_pkg_ALU_AND = 5'b01111;
	localparam miriscv_alu_pkg_ALU_OR = 5'b01110;
	always @(*) begin
		if (_sv2v_0)
			;
		case (alu_op_i)
			miriscv_alu_pkg_ALU_OR: alu_bit = alu_port_a_i | alu_port_b_i;
			miriscv_alu_pkg_ALU_AND: alu_bit = alu_port_a_i & alu_port_b_i;
			default: alu_bit = alu_port_a_i ^ alu_port_b_i;
		endcase
	end
	localparam miriscv_alu_pkg_ALU_SLTU = 5'b01001;
	localparam miriscv_alu_pkg_ALU_SRA = 5'b01100;
	localparam miriscv_alu_pkg_ALU_SUB = 5'b00001;
	localparam miriscv_alu_pkg_ALU_XOR = 5'b01101;
	always @(*) begin
		if (_sv2v_0)
			;
		case (alu_op_i)
			miriscv_alu_pkg_ALU_ADD, miriscv_alu_pkg_ALU_SUB: alu_result_o = alu_sum;
			miriscv_alu_pkg_ALU_SLT, miriscv_alu_pkg_ALU_SLTU: alu_result_o = {{31 {1'b0}}, alu_cmp};
			miriscv_alu_pkg_ALU_SLL, miriscv_alu_pkg_ALU_SRL, miriscv_alu_pkg_ALU_SRA: alu_result_o = alu_shift;
			miriscv_alu_pkg_ALU_XOR, miriscv_alu_pkg_ALU_OR, miriscv_alu_pkg_ALU_AND: alu_result_o = alu_bit;
			default: alu_result_o = alu_port_b_i;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module miriscv_gpr (
	clk_i,
	arstn_i,
	wr_en_i,
	wr_addr_i,
	wr_data_i,
	r1_addr_i,
	r1_data_o,
	r2_addr_i,
	r2_data_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire arstn_i;
	input wire wr_en_i;
	localparam miriscv_gpr_pkg_RISCV_E = 0;
	localparam miriscv_gpr_pkg_GPR_ADDR_W = 5;
	input wire [4:0] wr_addr_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] wr_data_i;
	input wire [4:0] r1_addr_i;
	output wire [31:0] r1_data_o;
	input wire [4:0] r2_addr_i;
	output wire [31:0] r2_data_o;
	localparam NUM_WORDS = 32;
	wire [1023:0] rf_reg;
	reg [1023:0] rf_reg_tmp_ff;
	reg [31:0] wr_en_dec;
	always @(*) begin : wr_en_decoder
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < NUM_WORDS; i = i + 1)
				if (wr_addr_i == i)
					wr_en_dec[i] = wr_en_i;
				else
					wr_en_dec[i] = 1'b0;
		end
	end
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 1; _gv_i_1 < NUM_WORDS; _gv_i_1 = _gv_i_1 + 1) begin : rf_gen
			localparam i = _gv_i_1;
			always @(posedge clk_i or negedge arstn_i) begin : register_write_behavioral
				if (arstn_i == 1'b0)
					rf_reg_tmp_ff[i * 32+:32] <= 'b0;
				else if (wr_en_dec[i])
					rf_reg_tmp_ff[i * 32+:32] <= wr_data_i;
			end
		end
	endgenerate
	assign rf_reg[0+:32] = 1'sb0;
	assign rf_reg[32+:992] = rf_reg_tmp_ff[32+:992];
	assign r1_data_o = rf_reg[r1_addr_i * 32+:32];
	assign r2_data_o = rf_reg[r2_addr_i * 32+:32];
	initial _sv2v_0 = 0;
endmodule
module miriscv_memory_stage (
	clk_i,
	arstn_i,
	cu_kill_m_i,
	cu_stall_m_i,
	m_stall_req_o,
	e_valid_i,
	e_alu_result_i,
	e_mdu_result_i,
	e_mem_req_i,
	e_mem_we_i,
	e_mem_size_i,
	e_mem_addr_i,
	e_mem_data_i,
	e_gpr_wr_en_i,
	e_gpr_wr_addr_i,
	e_gpr_src_sel_i,
	e_branch_i,
	e_jal_i,
	e_jalr_i,
	e_target_pc_i,
	e_next_pc_i,
	e_prediction_i,
	e_br_j_taken_i,
	m_valid_o,
	m_gpr_wr_en_o,
	m_gpr_wr_addr_o,
	m_gpr_wr_data_o,
	m_branch_o,
	m_jal_o,
	m_jalr_o,
	m_target_pc_o,
	m_next_pc_o,
	m_prediction_o,
	m_br_j_taken_o,
	data_rvalid_i,
	data_rdata_i,
	data_req_o,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	e_rvfi_wb_we_i,
	e_rvfi_wb_rd_addr_i,
	e_rvfi_instr_i,
	e_rvfi_rs1_addr_i,
	e_rvfi_rs2_addr_i,
	e_rvfi_op1_gpr_i,
	e_rvfi_op2_gpr_i,
	e_rvfi_rs1_rdata_i,
	e_rvfi_rs2_rdata_i,
	e_rvfi_current_pc_i,
	e_rvfi_next_pc_i,
	e_rvfi_valid_i,
	e_rvfi_trap_i,
	e_rvfi_intr_i,
	e_rvfi_mem_req_i,
	e_rvfi_mem_we_i,
	e_rvfi_mem_size_i,
	e_rvfi_mem_addr_i,
	e_rvfi_mem_wdata_i,
	m_rvfi_wb_data_o,
	m_rvfi_wb_we_o,
	m_rvfi_wb_rd_addr_o,
	m_rvfi_instr_o,
	m_rvfi_rs1_addr_o,
	m_rvfi_rs2_addr_o,
	m_rvfi_op1_gpr_o,
	m_rvfi_op2_gpr_o,
	m_rvfi_rs1_rdata_o,
	m_rvfi_rs2_rdata_o,
	m_rvfi_current_pc_o,
	m_rvfi_next_pc_o,
	m_rvfi_valid_o,
	m_rvfi_trap_o,
	m_rvfi_intr_o,
	m_rvfi_mem_req_o,
	m_rvfi_mem_we_o,
	m_rvfi_mem_size_o,
	m_rvfi_mem_addr_o,
	m_rvfi_mem_wdata_o,
	m_rvfi_mem_rdata_o
);
	reg _sv2v_0;
	parameter [0:0] RVFI = 1'b0;
	input wire clk_i;
	input wire arstn_i;
	input wire cu_kill_m_i;
	input wire cu_stall_m_i;
	output wire m_stall_req_o;
	input wire e_valid_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] e_alu_result_i;
	input wire [31:0] e_mdu_result_i;
	input wire e_mem_req_i;
	input wire e_mem_we_i;
	localparam miriscv_lsu_pkg_MEM_ACCESS_W = 3;
	input wire [2:0] e_mem_size_i;
	input wire [31:0] e_mem_addr_i;
	input wire [31:0] e_mem_data_i;
	input wire e_gpr_wr_en_i;
	localparam miriscv_gpr_pkg_RISCV_E = 0;
	localparam miriscv_gpr_pkg_GPR_ADDR_W = 5;
	input wire [4:0] e_gpr_wr_addr_i;
	localparam miriscv_decode_pkg_WB_SRC_W = 2;
	input wire [1:0] e_gpr_src_sel_i;
	input wire e_branch_i;
	input wire e_jal_i;
	input wire e_jalr_i;
	input wire [31:0] e_target_pc_i;
	input wire [31:0] e_next_pc_i;
	input wire e_prediction_i;
	input wire e_br_j_taken_i;
	output wire m_valid_o;
	output wire m_gpr_wr_en_o;
	output wire [4:0] m_gpr_wr_addr_o;
	output wire [31:0] m_gpr_wr_data_o;
	output wire m_branch_o;
	output wire m_jal_o;
	output wire m_jalr_o;
	output wire [31:0] m_target_pc_o;
	output wire [31:0] m_next_pc_o;
	output wire m_prediction_o;
	output wire m_br_j_taken_o;
	input wire data_rvalid_i;
	input wire [31:0] data_rdata_i;
	output wire data_req_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	input wire e_rvfi_wb_we_i;
	input wire [4:0] e_rvfi_wb_rd_addr_i;
	localparam miriscv_pkg_ILEN = 32;
	input wire [31:0] e_rvfi_instr_i;
	input wire [4:0] e_rvfi_rs1_addr_i;
	input wire [4:0] e_rvfi_rs2_addr_i;
	input wire e_rvfi_op1_gpr_i;
	input wire e_rvfi_op2_gpr_i;
	input wire [31:0] e_rvfi_rs1_rdata_i;
	input wire [31:0] e_rvfi_rs2_rdata_i;
	input wire [31:0] e_rvfi_current_pc_i;
	input wire [31:0] e_rvfi_next_pc_i;
	input wire e_rvfi_valid_i;
	input wire e_rvfi_trap_i;
	input wire e_rvfi_intr_i;
	input wire e_rvfi_mem_req_i;
	input wire e_rvfi_mem_we_i;
	input wire [2:0] e_rvfi_mem_size_i;
	input wire [31:0] e_rvfi_mem_addr_i;
	input wire [31:0] e_rvfi_mem_wdata_i;
	output wire [31:0] m_rvfi_wb_data_o;
	output wire m_rvfi_wb_we_o;
	output wire [4:0] m_rvfi_wb_rd_addr_o;
	output wire [31:0] m_rvfi_instr_o;
	output wire [4:0] m_rvfi_rs1_addr_o;
	output wire [4:0] m_rvfi_rs2_addr_o;
	output wire m_rvfi_op1_gpr_o;
	output wire m_rvfi_op2_gpr_o;
	output wire [31:0] m_rvfi_rs1_rdata_o;
	output wire [31:0] m_rvfi_rs2_rdata_o;
	output wire [31:0] m_rvfi_current_pc_o;
	output wire [31:0] m_rvfi_next_pc_o;
	output wire m_rvfi_valid_o;
	output wire m_rvfi_trap_o;
	output wire m_rvfi_intr_o;
	output wire m_rvfi_mem_req_o;
	output wire m_rvfi_mem_we_o;
	output wire [2:0] m_rvfi_mem_size_o;
	output wire [31:0] m_rvfi_mem_addr_o;
	output wire [31:0] m_rvfi_mem_wdata_o;
	output wire [31:0] m_rvfi_mem_rdata_o;
	wire [31:0] lsu_result;
	wire lsu_stall_req;
	wire lsu_req;
	reg [31:0] m_result;
	assign lsu_req = e_mem_req_i & e_valid_i;
	miriscv_lsu i_lsu(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.data_rvalid_i(data_rvalid_i),
		.data_rdata_i(data_rdata_i),
		.data_req_o(data_req_o),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_addr_o(data_addr_o),
		.data_wdata_o(data_wdata_o),
		.lsu_req_i(lsu_req),
		.lsu_kill_i(cu_kill_m_i),
		.lsu_keep_i(1'b0),
		.lsu_we_i(e_mem_we_i),
		.lsu_size_i(e_mem_size_i),
		.lsu_addr_i(e_mem_addr_i),
		.lsu_data_i(e_mem_data_i),
		.lsu_data_o(lsu_result),
		.lsu_stall_o(lsu_stall_req)
	);
	localparam miriscv_decode_pkg_ALU_DATA = 2'd0;
	localparam miriscv_decode_pkg_LSU_DATA = 2'd2;
	localparam miriscv_decode_pkg_MDU_DATA = 2'd1;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (e_gpr_src_sel_i)
			miriscv_decode_pkg_LSU_DATA: m_result = lsu_result;
			miriscv_decode_pkg_ALU_DATA: m_result = e_alu_result_i;
			miriscv_decode_pkg_MDU_DATA: m_result = e_mdu_result_i;
			default: m_result = e_alu_result_i;
		endcase
	end
	assign m_valid_o = e_valid_i;
	assign m_gpr_wr_en_o = (e_gpr_wr_en_i & e_valid_i) & ~cu_stall_m_i;
	assign m_gpr_wr_addr_o = e_gpr_wr_addr_i;
	assign m_gpr_wr_data_o = m_result;
	assign m_branch_o = e_branch_i;
	assign m_jal_o = e_jal_i;
	assign m_jalr_o = e_jalr_i;
	assign m_target_pc_o = e_target_pc_i;
	assign m_next_pc_o = e_next_pc_i;
	assign m_prediction_o = e_prediction_i;
	assign m_br_j_taken_o = e_br_j_taken_i;
	assign m_stall_req_o = lsu_stall_req;
	assign m_rvfi_wb_data_o = m_result;
	assign m_rvfi_wb_we_o = e_rvfi_wb_we_i;
	assign m_rvfi_wb_rd_addr_o = e_rvfi_wb_rd_addr_i;
	assign m_rvfi_instr_o = e_rvfi_instr_i;
	assign m_rvfi_rs1_addr_o = e_rvfi_rs1_addr_i;
	assign m_rvfi_rs2_addr_o = e_rvfi_rs2_addr_i;
	assign m_rvfi_op1_gpr_o = e_rvfi_op1_gpr_i;
	assign m_rvfi_op2_gpr_o = e_rvfi_op2_gpr_i;
	assign m_rvfi_rs1_rdata_o = e_rvfi_rs1_rdata_i;
	assign m_rvfi_rs2_rdata_o = e_rvfi_rs2_rdata_i;
	assign m_rvfi_current_pc_o = e_rvfi_current_pc_i;
	assign m_rvfi_next_pc_o = e_rvfi_next_pc_i;
	assign m_rvfi_valid_o = e_rvfi_valid_i & ~cu_stall_m_i;
	assign m_rvfi_trap_o = e_rvfi_trap_i;
	assign m_rvfi_intr_o = e_rvfi_intr_i;
	assign m_rvfi_mem_req_o = e_rvfi_mem_req_i;
	assign m_rvfi_mem_we_o = e_rvfi_mem_we_i;
	assign m_rvfi_mem_size_o = e_rvfi_mem_size_i;
	assign m_rvfi_mem_addr_o = e_rvfi_mem_addr_i;
	assign m_rvfi_mem_wdata_o = e_rvfi_mem_wdata_i;
	assign m_rvfi_mem_rdata_o = lsu_result;
	initial _sv2v_0 = 0;
endmodule
module miriscv_mdu (
	clk_i,
	arstn_i,
	mdu_req_i,
	mdu_port_a_i,
	mdu_port_b_i,
	mdu_op_i,
	mdu_kill_i,
	mdu_keep_i,
	mdu_result_o,
	mdu_stall_req_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire arstn_i;
	input wire mdu_req_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] mdu_port_a_i;
	input wire [31:0] mdu_port_b_i;
	localparam miriscv_mdu_pkg_MDU_OP_W = 3;
	input wire [2:0] mdu_op_i;
	input wire mdu_kill_i;
	input wire mdu_keep_i;
	output reg [31:0] mdu_result_o;
	output wire mdu_stall_req_o;
	wire sign_a;
	wire sign_b;
	reg msb_a;
	reg msb_b;
	wire b_is_zero;
	reg mult_op;
	wire signed [miriscv_pkg_XLEN:0] mul_operand_a;
	wire signed [miriscv_pkg_XLEN:0] mul_operand_b;
	wire signed [65:0] mult_result_full;
	wire [63:0] mult_result;
	wire [31:0] div_result;
	wire signed [31:0] rem_result;
	wire div_start;
	wire div_stall;
	wire mult_stall;
	reg b_zero_flag_ff;
	assign sign_a = mdu_port_a_i[31];
	assign sign_b = mdu_port_b_i[31];
	assign b_is_zero = ~|mdu_port_b_i;
	localparam miriscv_mdu_pkg_MDU_DIV = 3'd4;
	localparam miriscv_mdu_pkg_MDU_DIVU = 3'd5;
	localparam miriscv_mdu_pkg_MDU_MUL = 3'd0;
	localparam miriscv_mdu_pkg_MDU_MULH = 3'd1;
	localparam miriscv_mdu_pkg_MDU_MULHSU = 3'd2;
	localparam miriscv_mdu_pkg_MDU_MULHU = 3'd3;
	localparam miriscv_mdu_pkg_MDU_REM = 3'd6;
	localparam miriscv_mdu_pkg_MDU_REMU = 3'd7;
	always @(*) begin
		if (_sv2v_0)
			;
		case (mdu_op_i)
			miriscv_mdu_pkg_MDU_MUL, miriscv_mdu_pkg_MDU_MULH, miriscv_mdu_pkg_MDU_MULHU, miriscv_mdu_pkg_MDU_MULHSU: mult_op = 1'b1;
			miriscv_mdu_pkg_MDU_DIV, miriscv_mdu_pkg_MDU_REM, miriscv_mdu_pkg_MDU_DIVU, miriscv_mdu_pkg_MDU_REMU: mult_op = 1'b0;
			default: mult_op = 1'b0;
		endcase
	end
	assign mul_operand_a = {msb_a, mdu_port_a_i};
	assign mul_operand_b = {msb_b, mdu_port_b_i};
	always @(*) begin
		if (_sv2v_0)
			;
		case (mdu_op_i)
			miriscv_mdu_pkg_MDU_MUL, miriscv_mdu_pkg_MDU_MULH: begin
				msb_a = sign_a;
				msb_b = sign_b;
			end
			miriscv_mdu_pkg_MDU_MULHU: begin
				msb_a = 1'b0;
				msb_b = 1'b0;
			end
			miriscv_mdu_pkg_MDU_MULHSU: begin
				msb_a = sign_a;
				msb_b = 1'b0;
			end
			default: begin
				msb_a = 1'b0;
				msb_b = 1'b0;
			end
		endcase
	end
	assign mult_stall = 1'b0;
	assign mult_result_full = mul_operand_a * mul_operand_b;
	assign mult_result = mult_result_full[63:0];
	assign div_start = !mult_op && mdu_req_i;
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i)
			b_zero_flag_ff <= 1'b0;
		else
			b_zero_flag_ff <= b_is_zero;
	miriscv_div #(.DIV_IMPLEMENTATION("GENERIC")) i_div_unit(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.div_start_i(div_start),
		.port_a_i(mdu_port_a_i),
		.port_b_i(mdu_port_b_i),
		.mdu_op_i(mdu_op_i),
		.zero_i(b_zero_flag_ff),
		.kill_i(mdu_kill_i),
		.keep_i(mdu_keep_i),
		.div_result_o(div_result),
		.rem_result_o(rem_result),
		.div_stall_req_o(div_stall)
	);
	assign mdu_stall_req_o = div_stall || mult_stall;
	always @(*) begin
		if (_sv2v_0)
			;
		case (mdu_op_i)
			miriscv_mdu_pkg_MDU_MUL: mdu_result_o = mult_result[31:0];
			miriscv_mdu_pkg_MDU_MULH, miriscv_mdu_pkg_MDU_MULHSU, miriscv_mdu_pkg_MDU_MULHU: mdu_result_o = mult_result[63:miriscv_pkg_XLEN];
			miriscv_mdu_pkg_MDU_DIV, miriscv_mdu_pkg_MDU_DIVU: mdu_result_o = div_result;
			miriscv_mdu_pkg_MDU_REM, miriscv_mdu_pkg_MDU_REMU: mdu_result_o = rem_result;
			default: mdu_result_o = {miriscv_pkg_XLEN {1'b0}};
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module miriscv_decode_stage (
	clk_i,
	arstn_i,
	cu_kill_d_i,
	cu_stall_d_i,
	cu_stall_f_i,
	d_stall_req_o,
	f_instr_i,
	f_current_pc_i,
	f_next_pc_i,
	f_valid_i,
	m_gpr_wr_en_i,
	m_gpr_wr_data_i,
	m_gpr_wr_addr_i,
	d_valid_o,
	d_op1_o,
	d_op2_o,
	d_alu_operation_o,
	d_mdu_req_o,
	d_mdu_operation_o,
	d_mem_req_o,
	d_mem_we_o,
	d_mem_size_o,
	d_mem_addr_o,
	d_mem_data_o,
	d_gpr_wr_en_o,
	d_gpr_wr_addr_o,
	d_gpr_src_sel_o,
	d_branch_o,
	d_jal_o,
	d_jalr_o,
	d_target_pc_o,
	d_next_pc_o,
	d_prediction_o,
	d_br_j_taken_o,
	f_cu_rs1_addr_o,
	f_cu_rs1_req_o,
	f_cu_rs2_addr_o,
	f_cu_rs2_req_o,
	d_rvfi_wb_we_o,
	d_rvfi_wb_rd_addr_o,
	d_rvfi_instr_o,
	d_rvfi_rs1_addr_o,
	d_rvfi_rs2_addr_o,
	d_rvfi_op1_gpr_o,
	d_rvfi_op2_gpr_o,
	d_rvfi_rs1_rdata_o,
	d_rvfi_rs2_rdata_o,
	d_rvfi_current_pc_o,
	d_rvfi_next_pc_o,
	d_rvfi_valid_o,
	d_rvfi_trap_o,
	d_rvfi_intr_o,
	d_rvfi_mem_req_o,
	d_rvfi_mem_we_o,
	d_rvfi_mem_size_o,
	d_rvfi_mem_addr_o,
	d_rvfi_mem_wdata_o
);
	reg _sv2v_0;
	parameter [0:0] RVFI = 1'b0;
	input wire clk_i;
	input wire arstn_i;
	input wire cu_kill_d_i;
	input wire cu_stall_d_i;
	input wire cu_stall_f_i;
	output wire d_stall_req_o;
	localparam miriscv_pkg_ILEN = 32;
	input wire [31:0] f_instr_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] f_current_pc_i;
	input wire [31:0] f_next_pc_i;
	input wire f_valid_i;
	input wire m_gpr_wr_en_i;
	input wire [31:0] m_gpr_wr_data_i;
	localparam miriscv_gpr_pkg_RISCV_E = 0;
	localparam miriscv_gpr_pkg_GPR_ADDR_W = 5;
	input wire [4:0] m_gpr_wr_addr_i;
	output wire d_valid_o;
	output wire [31:0] d_op1_o;
	output wire [31:0] d_op2_o;
	localparam miriscv_alu_pkg_ALU_OP_W = 5;
	output wire [4:0] d_alu_operation_o;
	output wire d_mdu_req_o;
	localparam miriscv_mdu_pkg_MDU_OP_W = 3;
	output wire [2:0] d_mdu_operation_o;
	output wire d_mem_req_o;
	output wire d_mem_we_o;
	localparam miriscv_lsu_pkg_MEM_ACCESS_W = 3;
	output wire [2:0] d_mem_size_o;
	output wire [31:0] d_mem_addr_o;
	output wire [31:0] d_mem_data_o;
	output wire d_gpr_wr_en_o;
	output wire [4:0] d_gpr_wr_addr_o;
	localparam miriscv_decode_pkg_WB_SRC_W = 2;
	output wire [1:0] d_gpr_src_sel_o;
	output wire d_branch_o;
	output wire d_jal_o;
	output wire d_jalr_o;
	output wire [31:0] d_target_pc_o;
	output wire [31:0] d_next_pc_o;
	output wire d_prediction_o;
	output wire d_br_j_taken_o;
	output wire [4:0] f_cu_rs1_addr_o;
	output wire f_cu_rs1_req_o;
	output wire [4:0] f_cu_rs2_addr_o;
	output wire f_cu_rs2_req_o;
	output reg d_rvfi_wb_we_o;
	output reg [4:0] d_rvfi_wb_rd_addr_o;
	output reg [31:0] d_rvfi_instr_o;
	output reg [4:0] d_rvfi_rs1_addr_o;
	output reg [4:0] d_rvfi_rs2_addr_o;
	output reg d_rvfi_op1_gpr_o;
	output reg d_rvfi_op2_gpr_o;
	output reg [31:0] d_rvfi_rs1_rdata_o;
	output reg [31:0] d_rvfi_rs2_rdata_o;
	output reg [31:0] d_rvfi_current_pc_o;
	output reg [31:0] d_rvfi_next_pc_o;
	output reg d_rvfi_valid_o;
	output reg d_rvfi_trap_o;
	output reg d_rvfi_intr_o;
	output reg d_rvfi_mem_req_o;
	output reg d_rvfi_mem_we_o;
	output reg [2:0] d_rvfi_mem_size_o;
	output reg [31:0] d_rvfi_mem_addr_o;
	output reg [31:0] d_rvfi_mem_wdata_o;
	wire decode_rs1_re;
	wire decode_rs2_re;
	localparam miriscv_decode_pkg_OP1_SEL_W = 2;
	wire [1:0] decode_ex_op1_sel;
	localparam miriscv_decode_pkg_OP2_SEL_W = 2;
	wire [1:0] decode_ex_op2_sel;
	wire [4:0] decode_alu_operation;
	wire [2:0] decode_mdu_operation;
	wire decode_ex_mdu_req;
	wire decode_ex_result_sel;
	wire decode_mem_we;
	wire [2:0] decode_mem_size;
	wire decode_mem_req;
	wire [1:0] decode_wb_src_sel;
	wire decode_wb_we;
	wire [31:0] decode_mem_addr_imm;
	wire [31:0] decode_mem_addr;
	wire [31:0] decode_mem_data;
	wire decode_load;
	wire d_illegal_instr;
	wire d_ebreak;
	wire d_ecall;
	wire d_mret;
	wire d_fence;
	wire d_branch;
	wire d_jal;
	wire d_jalr;
	wire [4:0] r1_addr;
	wire [31:0] r1_data;
	wire [4:0] r2_addr;
	wire [31:0] r2_data;
	wire [4:0] rd_addr;
	wire gpr_wr_en;
	wire [4:0] gpr_wr_addr;
	wire [31:0] gpr_wr_data;
	wire [31:0] imm_i;
	wire [31:0] imm_u;
	wire [31:0] imm_s;
	wire [31:0] imm_b;
	wire [31:0] imm_j;
	reg [31:0] op1;
	reg [31:0] op2;
	wire [31:0] jalr_pc;
	wire [31:0] branch_pc;
	wire [31:0] jal_pc;
	reg [31:0] d_target_pc;
	wire f_handshake;
	reg d_valid_ff;
	reg [31:0] d_op1_ff;
	reg [31:0] d_op2_ff;
	reg [4:0] d_alu_operation_ff;
	reg d_mdu_req_ff;
	reg [2:0] d_mdu_operation_ff;
	reg d_mem_req_ff;
	reg d_mem_we_ff;
	reg [2:0] d_mem_size_ff;
	reg [31:0] d_mem_addr_ff;
	reg [31:0] d_mem_data_ff;
	reg d_gpr_wr_en_ff;
	reg [4:0] d_gpr_wr_addr_ff;
	reg [1:0] d_gpr_src_sel_ff;
	reg d_branch_ff;
	reg d_jal_ff;
	reg d_jalr_ff;
	reg [31:0] d_target_pc_ff;
	reg [31:0] d_next_pc_ff;
	reg d_prediction_ff;
	reg d_br_j_taken_ff;
	reg [3:0] next_pc_sel;
	miriscv_decoder i_decoder(
		.decode_instr_i(f_instr_i),
		.decode_rs1_re_o(decode_rs1_re),
		.decode_rs2_re_o(decode_rs2_re),
		.decode_ex_op1_sel_o(decode_ex_op1_sel),
		.decode_ex_op2_sel_o(decode_ex_op2_sel),
		.decode_alu_operation_o(decode_alu_operation),
		.decode_mdu_operation_o(decode_mdu_operation),
		.decode_ex_mdu_req_o(decode_ex_mdu_req),
		.decode_mem_we_o(decode_mem_we),
		.decode_mem_size_o(decode_mem_size),
		.decode_mem_req_o(decode_mem_req),
		.decode_wb_src_sel_o(decode_wb_src_sel),
		.decode_wb_we_o(decode_wb_we),
		.decode_fence_o(d_fence),
		.decode_branch_o(d_branch),
		.decode_jal_o(d_jal),
		.decode_jalr_o(d_jalr),
		.decode_load_o(decode_load),
		.decode_illegal_instr_o(d_illegal_instr)
	);
	assign gpr_wr_en = m_gpr_wr_en_i;
	assign gpr_wr_addr = m_gpr_wr_addr_i;
	assign gpr_wr_data = m_gpr_wr_data_i;
	assign r1_addr = f_instr_i[19:15];
	assign r2_addr = f_instr_i[24:20];
	assign rd_addr = f_instr_i[11:7];
	miriscv_gpr i_gpr(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.wr_en_i(gpr_wr_en),
		.wr_addr_i(gpr_wr_addr),
		.wr_data_i(gpr_wr_data),
		.r1_addr_i(r1_addr),
		.r1_data_o(r1_data),
		.r2_addr_i(r2_addr),
		.r2_data_o(r2_data)
	);
	miriscv_signextend #(
		.IN_WIDTH(12),
		.OUT_WIDTH(miriscv_pkg_XLEN)
	) extend_imm_i(
		.data_i(f_instr_i[31:20]),
		.data_o(imm_i)
	);
	assign imm_u = {f_instr_i[31:12], 12'd0};
	miriscv_signextend #(
		.IN_WIDTH(12),
		.OUT_WIDTH(miriscv_pkg_XLEN)
	) extend_imm_s(
		.data_i({f_instr_i[31:25], f_instr_i[11:7]}),
		.data_o(imm_s)
	);
	miriscv_signextend #(
		.IN_WIDTH(13),
		.OUT_WIDTH(miriscv_pkg_XLEN)
	) extend_imm_b(
		.data_i({f_instr_i[31], f_instr_i[7], f_instr_i[30:25], f_instr_i[11:8], 1'b0}),
		.data_o(imm_b)
	);
	miriscv_signextend #(
		.IN_WIDTH(21),
		.OUT_WIDTH(miriscv_pkg_XLEN)
	) extend_imm_j(
		.data_i({f_instr_i[31], f_instr_i[19:12], f_instr_i[20], f_instr_i[30:21], 1'b0}),
		.data_o(imm_j)
	);
	localparam miriscv_decode_pkg_CURRENT_PC = 2'd1;
	localparam miriscv_decode_pkg_RS1_DATA = 2'd0;
	localparam miriscv_decode_pkg_ZERO = 2'd3;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (decode_ex_op1_sel)
			miriscv_decode_pkg_RS1_DATA: op1 = r1_data;
			miriscv_decode_pkg_CURRENT_PC: op1 = f_current_pc_i;
			miriscv_decode_pkg_ZERO: op1 = {miriscv_pkg_XLEN {1'b0}};
		endcase
	end
	localparam miriscv_decode_pkg_IMM_I = 2'd1;
	localparam miriscv_decode_pkg_IMM_U = 2'd2;
	localparam miriscv_decode_pkg_NEXT_PC = 2'd3;
	localparam miriscv_decode_pkg_RS2_DATA = 2'd0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (decode_ex_op2_sel)
			miriscv_decode_pkg_RS2_DATA: op2 = r2_data;
			miriscv_decode_pkg_IMM_I: op2 = imm_i;
			miriscv_decode_pkg_IMM_U: op2 = imm_u;
			miriscv_decode_pkg_NEXT_PC: op2 = f_next_pc_i;
		endcase
	end
	assign decode_mem_data = op2;
	assign decode_mem_addr_imm = (decode_load ? imm_i : imm_s);
	assign decode_mem_addr = op1 + decode_mem_addr_imm;
	assign jalr_pc = (op1 + imm_i) & ~'b1;
	assign branch_pc = f_current_pc_i + imm_b;
	assign jal_pc = f_current_pc_i + imm_j;
	always @(*) begin
		if (_sv2v_0)
			;
		if ({d_branch, d_jalr, d_jal} == 3'b100)
			next_pc_sel = 4'd3;
		else if ({d_branch, d_jalr, d_jal} == 3'b010)
			next_pc_sel = 4'd2;
		else if ({d_branch, d_jalr, d_jal} == 3'b001)
			next_pc_sel = 4'd1;
		else
			next_pc_sel = 4'd0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (next_pc_sel)
			4'd1: d_target_pc = jal_pc;
			4'd2: d_target_pc = jalr_pc;
			4'd3: d_target_pc = branch_pc;
			default: d_target_pc = branch_pc;
		endcase
	end
	assign f_handshake = f_valid_i & ~cu_stall_f_i;
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i)
			d_valid_ff <= 1'sb0;
		else if (cu_kill_d_i)
			d_valid_ff <= 1'sb0;
		else if (~cu_stall_d_i)
			d_valid_ff <= f_handshake;
	always @(posedge clk_i)
		if (f_handshake & ~cu_stall_d_i) begin
			d_op1_ff <= op1;
			d_op2_ff <= op2;
			d_alu_operation_ff <= decode_alu_operation;
			d_mdu_req_ff <= decode_ex_mdu_req;
			d_mdu_operation_ff <= decode_mdu_operation;
			d_mem_req_ff <= decode_mem_req;
			d_mem_we_ff <= decode_mem_we;
			d_mem_size_ff <= decode_mem_size;
			d_mem_addr_ff <= decode_mem_addr;
			d_mem_data_ff <= decode_mem_data;
			d_gpr_wr_en_ff <= decode_wb_we;
			d_gpr_wr_addr_ff <= rd_addr;
			d_gpr_src_sel_ff <= decode_wb_src_sel;
			d_branch_ff <= d_branch;
			d_jal_ff <= d_jal;
			d_jalr_ff <= d_jalr;
			d_target_pc_ff <= d_target_pc;
			d_next_pc_ff <= f_next_pc_i;
			d_prediction_ff <= 1'sb0;
			d_br_j_taken_ff <= d_jal | d_jalr;
		end
	assign d_valid_o = d_valid_ff;
	assign d_op1_o = d_op1_ff;
	assign d_op2_o = d_op2_ff;
	assign d_alu_operation_o = d_alu_operation_ff;
	assign d_mdu_req_o = d_mdu_req_ff;
	assign d_mdu_operation_o = d_mdu_operation_ff;
	assign d_mem_req_o = d_mem_req_ff;
	assign d_mem_we_o = d_mem_we_ff;
	assign d_mem_size_o = d_mem_size_ff;
	assign d_mem_addr_o = d_mem_addr_ff;
	assign d_mem_data_o = d_mem_data_ff;
	assign d_gpr_wr_en_o = d_gpr_wr_en_ff;
	assign d_gpr_wr_addr_o = d_gpr_wr_addr_ff;
	assign d_gpr_src_sel_o = d_gpr_src_sel_ff;
	assign d_branch_o = d_branch_ff;
	assign d_jal_o = d_jal_ff;
	assign d_jalr_o = d_jalr_ff;
	assign d_target_pc_o = d_target_pc_ff;
	assign d_next_pc_o = d_next_pc_ff;
	assign d_prediction_o = d_prediction_ff;
	assign d_br_j_taken_o = d_br_j_taken_ff;
	assign d_stall_req_o = 1'sb0;
	assign f_cu_rs1_addr_o = r1_addr;
	assign f_cu_rs1_req_o = decode_rs1_re;
	assign f_cu_rs2_addr_o = r2_addr;
	assign f_cu_rs2_req_o = decode_rs2_re;
	generate
		if (RVFI) begin : genblk1
			always @(posedge clk_i or negedge arstn_i)
				if (~arstn_i) begin
					d_rvfi_wb_we_o <= 1'sb0;
					d_rvfi_wb_rd_addr_o <= 1'sb0;
					d_rvfi_instr_o <= 1'sb0;
					d_rvfi_rs1_addr_o <= 1'sb0;
					d_rvfi_rs2_addr_o <= 1'sb0;
					d_rvfi_op1_gpr_o <= 1'sb0;
					d_rvfi_op2_gpr_o <= 1'sb0;
					d_rvfi_rs1_rdata_o <= 1'sb0;
					d_rvfi_rs2_rdata_o <= 1'sb0;
					d_rvfi_current_pc_o <= 1'sb0;
					d_rvfi_next_pc_o <= 1'sb0;
					d_rvfi_valid_o <= 1'sb0;
					d_rvfi_trap_o <= 1'sb0;
					d_rvfi_intr_o <= 1'sb0;
					d_rvfi_mem_req_o <= 1'sb0;
					d_rvfi_mem_we_o <= 1'sb0;
					d_rvfi_mem_size_o <= 1'sb0;
					d_rvfi_mem_addr_o <= 1'sb0;
					d_rvfi_mem_wdata_o <= 1'sb0;
				end
				else if (cu_kill_d_i) begin
					d_rvfi_wb_we_o <= 1'sb0;
					d_rvfi_wb_rd_addr_o <= 1'sb0;
					d_rvfi_instr_o <= 1'sb0;
					d_rvfi_rs1_addr_o <= 1'sb0;
					d_rvfi_rs2_addr_o <= 1'sb0;
					d_rvfi_op1_gpr_o <= 1'sb0;
					d_rvfi_op2_gpr_o <= 1'sb0;
					d_rvfi_rs1_rdata_o <= 1'sb0;
					d_rvfi_rs2_rdata_o <= 1'sb0;
					d_rvfi_current_pc_o <= 1'sb0;
					d_rvfi_next_pc_o <= 1'sb0;
					d_rvfi_valid_o <= 1'sb0;
					d_rvfi_trap_o <= 1'sb0;
					d_rvfi_intr_o <= 1'sb0;
					d_rvfi_mem_req_o <= 1'sb0;
					d_rvfi_mem_we_o <= 1'sb0;
					d_rvfi_mem_size_o <= 1'sb0;
					d_rvfi_mem_addr_o <= 1'sb0;
					d_rvfi_mem_wdata_o <= 1'sb0;
				end
				else if (~cu_stall_d_i) begin
					d_rvfi_wb_we_o <= decode_wb_we;
					d_rvfi_wb_rd_addr_o <= rd_addr;
					d_rvfi_instr_o <= f_instr_i;
					d_rvfi_rs1_addr_o <= r1_addr;
					d_rvfi_rs2_addr_o <= r2_addr;
					d_rvfi_op1_gpr_o <= decode_rs1_re;
					d_rvfi_op2_gpr_o <= decode_rs2_re;
					d_rvfi_rs1_rdata_o <= op1;
					d_rvfi_rs2_rdata_o <= op2;
					d_rvfi_current_pc_o <= f_current_pc_i;
					d_rvfi_next_pc_o <= f_next_pc_i;
					d_rvfi_valid_o <= f_handshake;
					d_rvfi_trap_o <= 1'sb0;
					d_rvfi_intr_o <= 1'sb0;
					d_rvfi_mem_req_o <= decode_mem_req;
					d_rvfi_mem_we_o <= decode_mem_we;
					d_rvfi_mem_size_o <= decode_mem_size;
					d_rvfi_mem_addr_o <= decode_mem_addr;
					d_rvfi_mem_wdata_o <= decode_mem_data;
				end
		end
		else begin : genblk1
			wire [1:1] sv2v_tmp_5908F;
			assign sv2v_tmp_5908F = 1'sb0;
			always @(*) d_rvfi_wb_we_o = sv2v_tmp_5908F;
			wire [5:1] sv2v_tmp_EB5A0;
			assign sv2v_tmp_EB5A0 = 1'sb0;
			always @(*) d_rvfi_wb_rd_addr_o = sv2v_tmp_EB5A0;
			wire [32:1] sv2v_tmp_9A885;
			assign sv2v_tmp_9A885 = 1'sb0;
			always @(*) d_rvfi_instr_o = sv2v_tmp_9A885;
			wire [5:1] sv2v_tmp_58FFA;
			assign sv2v_tmp_58FFA = 1'sb0;
			always @(*) d_rvfi_rs1_addr_o = sv2v_tmp_58FFA;
			wire [5:1] sv2v_tmp_F7C1B;
			assign sv2v_tmp_F7C1B = 1'sb0;
			always @(*) d_rvfi_rs2_addr_o = sv2v_tmp_F7C1B;
			wire [1:1] sv2v_tmp_7FC55;
			assign sv2v_tmp_7FC55 = 1'sb0;
			always @(*) d_rvfi_op1_gpr_o = sv2v_tmp_7FC55;
			wire [1:1] sv2v_tmp_46ACC;
			assign sv2v_tmp_46ACC = 1'sb0;
			always @(*) d_rvfi_op2_gpr_o = sv2v_tmp_46ACC;
			wire [32:1] sv2v_tmp_68625;
			assign sv2v_tmp_68625 = 1'sb0;
			always @(*) d_rvfi_rs1_rdata_o = sv2v_tmp_68625;
			wire [32:1] sv2v_tmp_0F178;
			assign sv2v_tmp_0F178 = 1'sb0;
			always @(*) d_rvfi_rs2_rdata_o = sv2v_tmp_0F178;
			wire [32:1] sv2v_tmp_143EA;
			assign sv2v_tmp_143EA = 1'sb0;
			always @(*) d_rvfi_current_pc_o = sv2v_tmp_143EA;
			wire [32:1] sv2v_tmp_B9EBB;
			assign sv2v_tmp_B9EBB = 1'sb0;
			always @(*) d_rvfi_next_pc_o = sv2v_tmp_B9EBB;
			wire [1:1] sv2v_tmp_84970;
			assign sv2v_tmp_84970 = 1'sb0;
			always @(*) d_rvfi_valid_o = sv2v_tmp_84970;
			wire [1:1] sv2v_tmp_C6129;
			assign sv2v_tmp_C6129 = 1'sb0;
			always @(*) d_rvfi_trap_o = sv2v_tmp_C6129;
			wire [1:1] sv2v_tmp_F6436;
			assign sv2v_tmp_F6436 = 1'sb0;
			always @(*) d_rvfi_intr_o = sv2v_tmp_F6436;
			wire [1:1] sv2v_tmp_A121D;
			assign sv2v_tmp_A121D = 1'sb0;
			always @(*) d_rvfi_mem_req_o = sv2v_tmp_A121D;
			wire [1:1] sv2v_tmp_EBFD0;
			assign sv2v_tmp_EBFD0 = 1'sb0;
			always @(*) d_rvfi_mem_we_o = sv2v_tmp_EBFD0;
			wire [3:1] sv2v_tmp_88244;
			assign sv2v_tmp_88244 = 1'sb0;
			always @(*) d_rvfi_mem_size_o = sv2v_tmp_88244;
			wire [32:1] sv2v_tmp_505E5;
			assign sv2v_tmp_505E5 = 1'sb0;
			always @(*) d_rvfi_mem_addr_o = sv2v_tmp_505E5;
			wire [32:1] sv2v_tmp_C1B5F;
			assign sv2v_tmp_C1B5F = 1'sb0;
			always @(*) d_rvfi_mem_wdata_o = sv2v_tmp_C1B5F;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module miriscv_fetch_stage (
	clk_i,
	arstn_i,
	cu_kill_f_i,
	cu_stall_f_i,
	cu_force_f_i,
	cu_force_pc_i,
	f_stall_req_o,
	instr_rvalid_i,
	instr_rdata_i,
	instr_req_o,
	instr_addr_o,
	f_instr_o,
	f_current_pc_o,
	f_next_pc_o,
	f_valid_o
);
	parameter [0:0] RVFI = 1'b0;
	input wire clk_i;
	input wire arstn_i;
	input wire cu_kill_f_i;
	input wire cu_stall_f_i;
	input wire cu_force_f_i;
	localparam miriscv_pkg_XLEN = 32;
	input wire [31:0] cu_force_pc_i;
	output wire f_stall_req_o;
	input wire instr_rvalid_i;
	input wire [31:0] instr_rdata_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	localparam miriscv_pkg_ILEN = 32;
	output wire [31:0] f_instr_o;
	output wire [31:0] f_current_pc_o;
	output wire [31:0] f_next_pc_o;
	output wire f_valid_o;
	wire [31:0] fetch_instr;
	wire [31:0] f_current_pc;
	wire [31:0] f_next_pc;
	wire fetch_instr_valid;
	reg [31:0] f_instr_ff;
	reg [31:0] f_current_pc_ff;
	reg [31:0] f_next_pc_ff;
	reg f_valid_ff;
	miriscv_fetch_unit i_fetch_unit(
		.clk_i(clk_i),
		.arstn_i(arstn_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.cu_stall_f_i(cu_stall_f_i),
		.cu_force_f_i(cu_force_f_i),
		.cu_force_pc_i(cu_force_pc_i),
		.fetched_pc_addr_o(f_current_pc),
		.fetched_pc_next_addr_o(f_next_pc),
		.instr_o(fetch_instr),
		.fetch_rvalid_o(fetch_instr_valid)
	);
	always @(posedge clk_i or negedge arstn_i)
		if (~arstn_i)
			f_valid_ff <= 1'sb0;
		else if (cu_kill_f_i)
			f_valid_ff <= 1'sb0;
		else if (~cu_stall_f_i)
			f_valid_ff <= fetch_instr_valid;
	always @(posedge clk_i)
		if (~cu_stall_f_i) begin
			f_instr_ff <= fetch_instr;
			f_current_pc_ff <= f_current_pc;
			f_next_pc_ff <= f_next_pc;
		end
	assign f_instr_o = f_instr_ff;
	assign f_current_pc_o = f_current_pc_ff;
	assign f_next_pc_o = f_next_pc_ff;
	assign f_valid_o = f_valid_ff;
	assign f_stall_req_o = 1'sb0;
endmodule
