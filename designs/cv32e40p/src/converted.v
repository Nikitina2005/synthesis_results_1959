module cv32e40p_clock_gate (
    input  logic clk_i,
    input  logic en_i,
    input  logic scan_cg_en_i,
    output logic clk_o
);

  logic clk_en;

  always_latch begin
    if (clk_i == 1'b0) clk_en <= en_i | scan_cg_en_i;
  end

  assign clk_o = clk_i & clk_en;

endmodule

module cv32e40p_aligner (
	clk,
	rst_n,
	fetch_valid_i,
	aligner_ready_o,
	if_valid_i,
	fetch_rdata_i,
	instr_aligned_o,
	instr_valid_o,
	branch_addr_i,
	branch_i,
	hwlp_addr_i,
	hwlp_update_pc_i,
	pc_o
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire fetch_valid_i;
	output reg aligner_ready_o;
	input wire if_valid_i;
	input wire [31:0] fetch_rdata_i;
	output reg [31:0] instr_aligned_o;
	output reg instr_valid_o;
	input wire [31:0] branch_addr_i;
	input wire branch_i;
	input wire [31:0] hwlp_addr_i;
	input wire hwlp_update_pc_i;
	output wire [31:0] pc_o;
	reg [2:0] state;
	reg [2:0] next_state;
	reg [15:0] r_instr_h;
	reg [31:0] hwlp_addr_q;
	reg [31:0] pc_q;
	reg [31:0] pc_n;
	reg update_state;
	wire [31:0] pc_plus4;
	wire [31:0] pc_plus2;
	reg aligner_ready_q;
	reg hwlp_update_pc_q;
	assign pc_o = pc_q;
	assign pc_plus2 = pc_q + 2;
	assign pc_plus4 = pc_q + 4;
	always @(posedge clk or negedge rst_n) begin : proc_SEQ_FSM
		if (~rst_n) begin
			state <= 3'd0;
			r_instr_h <= 1'sb0;
			hwlp_addr_q <= 1'sb0;
			pc_q <= 1'sb0;
			aligner_ready_q <= 1'b0;
			hwlp_update_pc_q <= 1'b0;
		end
		else if (update_state) begin
			pc_q <= pc_n;
			state <= next_state;
			r_instr_h <= fetch_rdata_i[31:16];
			aligner_ready_q <= aligner_ready_o;
			hwlp_update_pc_q <= 1'b0;
		end
		else if (hwlp_update_pc_i) begin
			hwlp_addr_q <= hwlp_addr_i;
			hwlp_update_pc_q <= 1'b1;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		pc_n = pc_q;
		instr_valid_o = fetch_valid_i;
		instr_aligned_o = fetch_rdata_i;
		aligner_ready_o = 1'b1;
		update_state = 1'b0;
		next_state = state;
		case (state)
			3'd0:
				if (fetch_rdata_i[1:0] == 2'b11) begin
					next_state = 3'd0;
					pc_n = pc_plus4;
					instr_aligned_o = fetch_rdata_i;
					update_state = fetch_valid_i & if_valid_i;
					if (hwlp_update_pc_i || hwlp_update_pc_q)
						pc_n = (hwlp_update_pc_i ? hwlp_addr_i : hwlp_addr_q);
				end
				else begin
					next_state = 3'd1;
					pc_n = pc_plus2;
					instr_aligned_o = fetch_rdata_i;
					update_state = fetch_valid_i & if_valid_i;
				end
			3'd1:
				if (r_instr_h[1:0] == 2'b11) begin
					next_state = 3'd1;
					pc_n = pc_plus4;
					instr_aligned_o = {fetch_rdata_i[15:0], r_instr_h[15:0]};
					update_state = fetch_valid_i & if_valid_i;
				end
				else begin
					instr_aligned_o = {fetch_rdata_i[31:16], r_instr_h[15:0]};
					next_state = 3'd2;
					instr_valid_o = 1'b1;
					pc_n = pc_plus2;
					aligner_ready_o = !fetch_valid_i;
					update_state = if_valid_i;
				end
			3'd2: begin
				instr_valid_o = !aligner_ready_q || fetch_valid_i;
				if (fetch_rdata_i[1:0] == 2'b11) begin
					next_state = 3'd0;
					pc_n = pc_plus4;
					instr_aligned_o = fetch_rdata_i;
					update_state = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
				end
				else begin
					next_state = 3'd1;
					pc_n = pc_plus2;
					instr_aligned_o = fetch_rdata_i;
					update_state = (!aligner_ready_q | fetch_valid_i) & if_valid_i;
				end
			end
			3'd3:
				if (fetch_rdata_i[17:16] == 2'b11) begin
					next_state = 3'd1;
					instr_valid_o = 1'b0;
					pc_n = pc_q;
					instr_aligned_o = fetch_rdata_i;
					update_state = fetch_valid_i & if_valid_i;
				end
				else begin
					next_state = 3'd0;
					pc_n = pc_plus2;
					instr_aligned_o = {fetch_rdata_i[31:16], fetch_rdata_i[31:16]};
					update_state = fetch_valid_i & if_valid_i;
				end
		endcase
		if (branch_i) begin
			update_state = 1'b1;
			pc_n = branch_addr_i;
			next_state = (branch_addr_i[1] ? 3'd3 : 3'd0);
		end
	end
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_alu (
	clk,
	rst_n,
	enable_i,
	operator_i,
	operand_a_i,
	operand_b_i,
	operand_c_i,
	vector_mode_i,
	bmask_a_i,
	bmask_b_i,
	imm_vec_ext_i,
	is_clpx_i,
	is_subrot_i,
	clpx_shift_i,
	result_o,
	comparison_result_o,
	ready_o,
	ex_ready_i
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire enable_i;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	input wire [6:0] operator_i;
	input wire [31:0] operand_a_i;
	input wire [31:0] operand_b_i;
	input wire [31:0] operand_c_i;
	input wire [1:0] vector_mode_i;
	input wire [4:0] bmask_a_i;
	input wire [4:0] bmask_b_i;
	input wire [1:0] imm_vec_ext_i;
	input wire is_clpx_i;
	input wire is_subrot_i;
	input wire [1:0] clpx_shift_i;
	output reg [31:0] result_o;
	output wire comparison_result_o;
	output wire ready_o;
	input wire ex_ready_i;
	wire [31:0] operand_a_rev;
	wire [31:0] operand_a_neg;
	wire [31:0] operand_a_neg_rev;
	assign operand_a_neg = ~operand_a_i;
	genvar _gv_k_1;
	generate
		for (_gv_k_1 = 0; _gv_k_1 < 32; _gv_k_1 = _gv_k_1 + 1) begin : gen_operand_a_rev
			localparam k = _gv_k_1;
			assign operand_a_rev[k] = operand_a_i[31 - k];
		end
	endgenerate
	genvar _gv_m_1;
	generate
		for (_gv_m_1 = 0; _gv_m_1 < 32; _gv_m_1 = _gv_m_1 + 1) begin : gen_operand_a_neg_rev
			localparam m = _gv_m_1;
			assign operand_a_neg_rev[m] = operand_a_neg[31 - m];
		end
	endgenerate
	wire [31:0] operand_b_neg;
	assign operand_b_neg = ~operand_b_i;
	wire [5:0] div_shift;
	wire div_valid;
	wire [31:0] bmask;
	wire adder_op_b_negate;
	wire [31:0] adder_op_a;
	wire [31:0] adder_op_b;
	reg [35:0] adder_in_a;
	reg [35:0] adder_in_b;
	wire [31:0] adder_result;
	wire [36:0] adder_result_expanded;
	function automatic [6:0] sv2v_cast_81146;
		input reg [6:0] inp;
		sv2v_cast_81146 = inp;
	endfunction
	assign adder_op_b_negate = ((((operator_i == sv2v_cast_81146(7'b0011001)) || (operator_i == sv2v_cast_81146(7'b0011101))) || (operator_i == sv2v_cast_81146(7'b0011011))) || (operator_i == sv2v_cast_81146(7'b0011111))) || is_subrot_i;
	assign adder_op_a = (operator_i == sv2v_cast_81146(7'b0010100) ? operand_a_neg : (is_subrot_i ? {operand_b_i[15:0], operand_a_i[31:16]} : operand_a_i));
	assign adder_op_b = (adder_op_b_negate ? (is_subrot_i ? ~{operand_a_i[15:0], operand_b_i[31:16]} : operand_b_neg) : operand_b_i);
	localparam cv32e40p_pkg_VEC_MODE16 = 2'b10;
	localparam cv32e40p_pkg_VEC_MODE8 = 2'b11;
	always @(*) begin
		if (_sv2v_0)
			;
		adder_in_a[0] = 1'b1;
		adder_in_a[8:1] = adder_op_a[7:0];
		adder_in_a[9] = 1'b1;
		adder_in_a[17:10] = adder_op_a[15:8];
		adder_in_a[18] = 1'b1;
		adder_in_a[26:19] = adder_op_a[23:16];
		adder_in_a[27] = 1'b1;
		adder_in_a[35:28] = adder_op_a[31:24];
		adder_in_b[0] = 1'b0;
		adder_in_b[8:1] = adder_op_b[7:0];
		adder_in_b[9] = 1'b0;
		adder_in_b[17:10] = adder_op_b[15:8];
		adder_in_b[18] = 1'b0;
		adder_in_b[26:19] = adder_op_b[23:16];
		adder_in_b[27] = 1'b0;
		adder_in_b[35:28] = adder_op_b[31:24];
		if (adder_op_b_negate || ((operator_i == sv2v_cast_81146(7'b0010100)) || (operator_i == sv2v_cast_81146(7'b0010110)))) begin
			adder_in_b[0] = 1'b1;
			case (vector_mode_i)
				cv32e40p_pkg_VEC_MODE16: adder_in_b[18] = 1'b1;
				cv32e40p_pkg_VEC_MODE8: begin
					adder_in_b[9] = 1'b1;
					adder_in_b[18] = 1'b1;
					adder_in_b[27] = 1'b1;
				end
			endcase
		end
		else
			case (vector_mode_i)
				cv32e40p_pkg_VEC_MODE16: adder_in_a[18] = 1'b0;
				cv32e40p_pkg_VEC_MODE8: begin
					adder_in_a[9] = 1'b0;
					adder_in_a[18] = 1'b0;
					adder_in_a[27] = 1'b0;
				end
			endcase
	end
	assign adder_result_expanded = $signed(adder_in_a) + $signed(adder_in_b);
	assign adder_result = {adder_result_expanded[35:28], adder_result_expanded[26:19], adder_result_expanded[17:10], adder_result_expanded[8:1]};
	wire [31:0] adder_round_value;
	wire [31:0] adder_round_result;
	assign adder_round_value = ((((operator_i == sv2v_cast_81146(7'b0011100)) || (operator_i == sv2v_cast_81146(7'b0011101))) || (operator_i == sv2v_cast_81146(7'b0011110))) || (operator_i == sv2v_cast_81146(7'b0011111)) ? {1'b0, bmask[31:1]} : {32 {1'sb0}});
	assign adder_round_result = adder_result + adder_round_value;
	wire shift_left;
	wire shift_use_round;
	wire shift_arithmetic;
	reg [31:0] shift_amt_left;
	wire [31:0] shift_amt;
	wire [31:0] shift_amt_int;
	wire [31:0] shift_amt_norm;
	wire [31:0] shift_op_a;
	wire [31:0] shift_result;
	reg [31:0] shift_right_result;
	wire [31:0] shift_left_result;
	wire [15:0] clpx_shift_ex;
	assign shift_amt = (div_valid ? div_shift : operand_b_i);
	always @(*) begin
		if (_sv2v_0)
			;
		case (vector_mode_i)
			cv32e40p_pkg_VEC_MODE16: begin
				shift_amt_left[15:0] = shift_amt[31:16];
				shift_amt_left[31:16] = shift_amt[15:0];
			end
			cv32e40p_pkg_VEC_MODE8: begin
				shift_amt_left[7:0] = shift_amt[31:24];
				shift_amt_left[15:8] = shift_amt[23:16];
				shift_amt_left[23:16] = shift_amt[15:8];
				shift_amt_left[31:24] = shift_amt[7:0];
			end
			default: shift_amt_left[31:0] = shift_amt[31:0];
		endcase
	end
	assign shift_left = ((((((((operator_i == sv2v_cast_81146(7'b0100111)) || (operator_i == sv2v_cast_81146(7'b0101010))) || (operator_i == sv2v_cast_81146(7'b0110111))) || (operator_i == sv2v_cast_81146(7'b0110101))) || (operator_i == sv2v_cast_81146(7'b0110001))) || (operator_i == sv2v_cast_81146(7'b0110000))) || (operator_i == sv2v_cast_81146(7'b0110011))) || (operator_i == sv2v_cast_81146(7'b0110010))) || (operator_i == sv2v_cast_81146(7'b1001001));
	assign shift_use_round = (((((((operator_i == sv2v_cast_81146(7'b0011000)) || (operator_i == sv2v_cast_81146(7'b0011001))) || (operator_i == sv2v_cast_81146(7'b0011100))) || (operator_i == sv2v_cast_81146(7'b0011101))) || (operator_i == sv2v_cast_81146(7'b0011010))) || (operator_i == sv2v_cast_81146(7'b0011011))) || (operator_i == sv2v_cast_81146(7'b0011110))) || (operator_i == sv2v_cast_81146(7'b0011111));
	assign shift_arithmetic = (((((operator_i == sv2v_cast_81146(7'b0100100)) || (operator_i == sv2v_cast_81146(7'b0101000))) || (operator_i == sv2v_cast_81146(7'b0011000))) || (operator_i == sv2v_cast_81146(7'b0011001))) || (operator_i == sv2v_cast_81146(7'b0011100))) || (operator_i == sv2v_cast_81146(7'b0011101));
	assign shift_op_a = (shift_left ? operand_a_rev : (shift_use_round ? adder_round_result : operand_a_i));
	assign shift_amt_int = (shift_use_round ? shift_amt_norm : (shift_left ? shift_amt_left : shift_amt));
	assign shift_amt_norm = (is_clpx_i ? {clpx_shift_ex, clpx_shift_ex} : {4 {3'b000, bmask_b_i}});
	assign clpx_shift_ex = $unsigned(clpx_shift_i);
	wire [63:0] shift_op_a_32;
	assign shift_op_a_32 = (operator_i == sv2v_cast_81146(7'b0100110) ? {shift_op_a, shift_op_a} : $signed({{32 {shift_arithmetic & shift_op_a[31]}}, shift_op_a}));
	always @(*) begin
		if (_sv2v_0)
			;
		case (vector_mode_i)
			cv32e40p_pkg_VEC_MODE16: begin
				shift_right_result[31:16] = $signed({shift_arithmetic & shift_op_a[31], shift_op_a[31:16]}) >>> shift_amt_int[19:16];
				shift_right_result[15:0] = $signed({shift_arithmetic & shift_op_a[15], shift_op_a[15:0]}) >>> shift_amt_int[3:0];
			end
			cv32e40p_pkg_VEC_MODE8: begin
				shift_right_result[31:24] = $signed({shift_arithmetic & shift_op_a[31], shift_op_a[31:24]}) >>> shift_amt_int[26:24];
				shift_right_result[23:16] = $signed({shift_arithmetic & shift_op_a[23], shift_op_a[23:16]}) >>> shift_amt_int[18:16];
				shift_right_result[15:8] = $signed({shift_arithmetic & shift_op_a[15], shift_op_a[15:8]}) >>> shift_amt_int[10:8];
				shift_right_result[7:0] = $signed({shift_arithmetic & shift_op_a[7], shift_op_a[7:0]}) >>> shift_amt_int[2:0];
			end
			default: shift_right_result = shift_op_a_32 >> shift_amt_int[4:0];
		endcase
	end
	genvar _gv_j_1;
	generate
		for (_gv_j_1 = 0; _gv_j_1 < 32; _gv_j_1 = _gv_j_1 + 1) begin : gen_shift_left_result
			localparam j = _gv_j_1;
			assign shift_left_result[j] = shift_right_result[31 - j];
		end
	endgenerate
	assign shift_result = (shift_left ? shift_left_result : shift_right_result);
	reg [3:0] is_equal;
	reg [3:0] is_greater;
	reg [3:0] cmp_signed;
	wire [3:0] is_equal_vec;
	wire [3:0] is_greater_vec;
	reg [31:0] operand_b_eq;
	wire is_equal_clip;
	always @(*) begin
		if (_sv2v_0)
			;
		operand_b_eq = operand_b_neg;
		if (operator_i == sv2v_cast_81146(7'b0010111))
			operand_b_eq = 1'sb0;
		else
			operand_b_eq = operand_b_neg;
	end
	assign is_equal_clip = operand_a_i == operand_b_eq;
	always @(*) begin
		if (_sv2v_0)
			;
		cmp_signed = 4'b0000;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_81146(7'b0001000), sv2v_cast_81146(7'b0001010), sv2v_cast_81146(7'b0000000), sv2v_cast_81146(7'b0000100), sv2v_cast_81146(7'b0000010), sv2v_cast_81146(7'b0000110), sv2v_cast_81146(7'b0010000), sv2v_cast_81146(7'b0010010), sv2v_cast_81146(7'b0010100), sv2v_cast_81146(7'b0010110), sv2v_cast_81146(7'b0010111):
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: cmp_signed[3:0] = 4'b1111;
					cv32e40p_pkg_VEC_MODE16: cmp_signed[3:0] = 4'b1010;
					default: cmp_signed[3:0] = 4'b1000;
				endcase
			default:
				;
		endcase
	end
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 4; _gv_i_1 = _gv_i_1 + 1) begin : gen_is_vec
			localparam i = _gv_i_1;
			assign is_equal_vec[i] = operand_a_i[(8 * i) + 7:8 * i] == operand_b_i[(8 * i) + 7:i * 8];
			assign is_greater_vec[i] = $signed({operand_a_i[(8 * i) + 7] & cmp_signed[i], operand_a_i[(8 * i) + 7:8 * i]}) > $signed({operand_b_i[(8 * i) + 7] & cmp_signed[i], operand_b_i[(8 * i) + 7:i * 8]});
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		is_equal[3:0] = {4 {((is_equal_vec[3] & is_equal_vec[2]) & is_equal_vec[1]) & is_equal_vec[0]}};
		is_greater[3:0] = {4 {is_greater_vec[3] | (is_equal_vec[3] & (is_greater_vec[2] | (is_equal_vec[2] & (is_greater_vec[1] | (is_equal_vec[1] & is_greater_vec[0])))))}};
		case (vector_mode_i)
			cv32e40p_pkg_VEC_MODE16: begin
				is_equal[1:0] = {2 {is_equal_vec[0] & is_equal_vec[1]}};
				is_equal[3:2] = {2 {is_equal_vec[2] & is_equal_vec[3]}};
				is_greater[1:0] = {2 {is_greater_vec[1] | (is_equal_vec[1] & is_greater_vec[0])}};
				is_greater[3:2] = {2 {is_greater_vec[3] | (is_equal_vec[3] & is_greater_vec[2])}};
			end
			cv32e40p_pkg_VEC_MODE8: begin
				is_equal[3:0] = is_equal_vec[3:0];
				is_greater[3:0] = is_greater_vec[3:0];
			end
			default:
				;
		endcase
	end
	reg [3:0] cmp_result;
	always @(*) begin
		if (_sv2v_0)
			;
		cmp_result = is_equal;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_81146(7'b0001100): cmp_result = is_equal;
			sv2v_cast_81146(7'b0001101): cmp_result = ~is_equal;
			sv2v_cast_81146(7'b0001000), sv2v_cast_81146(7'b0001001): cmp_result = is_greater;
			sv2v_cast_81146(7'b0001010), sv2v_cast_81146(7'b0001011): cmp_result = is_greater | is_equal;
			sv2v_cast_81146(7'b0000000), sv2v_cast_81146(7'b0000010), sv2v_cast_81146(7'b0000001), sv2v_cast_81146(7'b0000011): cmp_result = ~(is_greater | is_equal);
			sv2v_cast_81146(7'b0000110), sv2v_cast_81146(7'b0000111), sv2v_cast_81146(7'b0000100), sv2v_cast_81146(7'b0000101): cmp_result = ~is_greater;
			default:
				;
		endcase
	end
	assign comparison_result_o = cmp_result[3];
	wire [31:0] result_minmax;
	wire [3:0] sel_minmax;
	wire do_min;
	wire [31:0] minmax_b;
	assign minmax_b = (operator_i == sv2v_cast_81146(7'b0010100) ? adder_result : operand_b_i);
	assign do_min = (((operator_i == sv2v_cast_81146(7'b0010000)) || (operator_i == sv2v_cast_81146(7'b0010001))) || (operator_i == sv2v_cast_81146(7'b0010110))) || (operator_i == sv2v_cast_81146(7'b0010111));
	assign sel_minmax[3:0] = is_greater ^ {4 {do_min}};
	assign result_minmax[31:24] = (sel_minmax[3] == 1'b1 ? operand_a_i[31:24] : minmax_b[31:24]);
	assign result_minmax[23:16] = (sel_minmax[2] == 1'b1 ? operand_a_i[23:16] : minmax_b[23:16]);
	assign result_minmax[15:8] = (sel_minmax[1] == 1'b1 ? operand_a_i[15:8] : minmax_b[15:8]);
	assign result_minmax[7:0] = (sel_minmax[0] == 1'b1 ? operand_a_i[7:0] : minmax_b[7:0]);
	reg [31:0] clip_result;
	always @(*) begin
		if (_sv2v_0)
			;
		clip_result = result_minmax;
		if (operator_i == sv2v_cast_81146(7'b0010111)) begin
			if (operand_a_i[31] || is_equal_clip)
				clip_result = 1'sb0;
			else
				clip_result = result_minmax;
		end
		else if (adder_result_expanded[36] || is_equal_clip)
			clip_result = operand_b_neg;
		else
			clip_result = result_minmax;
	end
	reg [7:0] shuffle_byte_sel;
	reg [3:0] shuffle_reg_sel;
	reg [1:0] shuffle_reg1_sel;
	reg [1:0] shuffle_reg0_sel;
	reg [3:0] shuffle_through;
	wire [31:0] shuffle_r1;
	wire [31:0] shuffle_r0;
	wire [31:0] shuffle_r1_in;
	wire [31:0] shuffle_r0_in;
	wire [31:0] shuffle_result;
	wire [31:0] pack_result;
	always @(*) begin
		if (_sv2v_0)
			;
		shuffle_reg_sel = 1'sb0;
		shuffle_reg1_sel = 2'b01;
		shuffle_reg0_sel = 2'b10;
		shuffle_through = 1'sb1;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_81146(7'b0111111), sv2v_cast_81146(7'b0111110): begin
				if (operator_i == sv2v_cast_81146(7'b0111110))
					shuffle_reg1_sel = 2'b11;
				if (vector_mode_i == cv32e40p_pkg_VEC_MODE8) begin
					shuffle_reg_sel[3:1] = 3'b111;
					shuffle_reg_sel[0] = 1'b0;
				end
				else begin
					shuffle_reg_sel[3:2] = 2'b11;
					shuffle_reg_sel[1:0] = 2'b00;
				end
			end
			sv2v_cast_81146(7'b0111000): begin
				shuffle_reg1_sel = 2'b00;
				if (vector_mode_i == cv32e40p_pkg_VEC_MODE8) begin
					shuffle_through = 4'b0011;
					shuffle_reg_sel = 4'b0001;
				end
				else
					shuffle_reg_sel = 4'b0011;
			end
			sv2v_cast_81146(7'b0111001): begin
				shuffle_reg1_sel = 2'b00;
				if (vector_mode_i == cv32e40p_pkg_VEC_MODE8) begin
					shuffle_through = 4'b1100;
					shuffle_reg_sel = 4'b0100;
				end
				else
					shuffle_reg_sel = 4'b0011;
			end
			sv2v_cast_81146(7'b0111011):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_reg_sel[3] = ~operand_b_i[26];
						shuffle_reg_sel[2] = ~operand_b_i[18];
						shuffle_reg_sel[1] = ~operand_b_i[10];
						shuffle_reg_sel[0] = ~operand_b_i[2];
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_reg_sel[3] = ~operand_b_i[17];
						shuffle_reg_sel[2] = ~operand_b_i[17];
						shuffle_reg_sel[1] = ~operand_b_i[1];
						shuffle_reg_sel[0] = ~operand_b_i[1];
					end
					default:
						;
				endcase
			sv2v_cast_81146(7'b0101101):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_reg0_sel = 2'b00;
						(* full_case, parallel_case *)
						case (imm_vec_ext_i)
							2'b00: shuffle_reg_sel[3:0] = 4'b1110;
							2'b01: shuffle_reg_sel[3:0] = 4'b1101;
							2'b10: shuffle_reg_sel[3:0] = 4'b1011;
							2'b11: shuffle_reg_sel[3:0] = 4'b0111;
						endcase
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_reg0_sel = 2'b01;
						shuffle_reg_sel[3] = ~imm_vec_ext_i[0];
						shuffle_reg_sel[2] = ~imm_vec_ext_i[0];
						shuffle_reg_sel[1] = imm_vec_ext_i[0];
						shuffle_reg_sel[0] = imm_vec_ext_i[0];
					end
					default:
						;
				endcase
			default:
				;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		shuffle_byte_sel = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_81146(7'b0111110), sv2v_cast_81146(7'b0111111):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = imm_vec_ext_i[1:0];
						shuffle_byte_sel[4+:2] = imm_vec_ext_i[1:0];
						shuffle_byte_sel[2+:2] = imm_vec_ext_i[1:0];
						shuffle_byte_sel[0+:2] = imm_vec_ext_i[1:0];
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = {imm_vec_ext_i[0], 1'b1};
						shuffle_byte_sel[4+:2] = {imm_vec_ext_i[0], 1'b1};
						shuffle_byte_sel[2+:2] = {imm_vec_ext_i[0], 1'b1};
						shuffle_byte_sel[0+:2] = {imm_vec_ext_i[0], 1'b0};
					end
					default:
						;
				endcase
			sv2v_cast_81146(7'b0111000):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = 2'b00;
						shuffle_byte_sel[4+:2] = 2'b00;
						shuffle_byte_sel[2+:2] = 2'b00;
						shuffle_byte_sel[0+:2] = 2'b00;
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = 2'b01;
						shuffle_byte_sel[4+:2] = 2'b00;
						shuffle_byte_sel[2+:2] = 2'b01;
						shuffle_byte_sel[0+:2] = 2'b00;
					end
					default:
						;
				endcase
			sv2v_cast_81146(7'b0111001):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = 2'b00;
						shuffle_byte_sel[4+:2] = 2'b00;
						shuffle_byte_sel[2+:2] = 2'b00;
						shuffle_byte_sel[0+:2] = 2'b00;
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = 2'b11;
						shuffle_byte_sel[4+:2] = 2'b10;
						shuffle_byte_sel[2+:2] = 2'b11;
						shuffle_byte_sel[0+:2] = 2'b10;
					end
					default:
						;
				endcase
			sv2v_cast_81146(7'b0111011), sv2v_cast_81146(7'b0111010):
				(* full_case, parallel_case *)
				case (vector_mode_i)
					cv32e40p_pkg_VEC_MODE8: begin
						shuffle_byte_sel[6+:2] = operand_b_i[25:24];
						shuffle_byte_sel[4+:2] = operand_b_i[17:16];
						shuffle_byte_sel[2+:2] = operand_b_i[9:8];
						shuffle_byte_sel[0+:2] = operand_b_i[1:0];
					end
					cv32e40p_pkg_VEC_MODE16: begin
						shuffle_byte_sel[6+:2] = {operand_b_i[16], 1'b1};
						shuffle_byte_sel[4+:2] = {operand_b_i[16], 1'b0};
						shuffle_byte_sel[2+:2] = {operand_b_i[0], 1'b1};
						shuffle_byte_sel[0+:2] = {operand_b_i[0], 1'b0};
					end
					default:
						;
				endcase
			sv2v_cast_81146(7'b0101101): begin
				shuffle_byte_sel[6+:2] = 2'b11;
				shuffle_byte_sel[4+:2] = 2'b10;
				shuffle_byte_sel[2+:2] = 2'b01;
				shuffle_byte_sel[0+:2] = 2'b00;
			end
			default:
				;
		endcase
	end
	assign shuffle_r0_in = (shuffle_reg0_sel[1] ? operand_a_i : (shuffle_reg0_sel[0] ? {2 {operand_a_i[15:0]}} : {4 {operand_a_i[7:0]}}));
	assign shuffle_r1_in = (shuffle_reg1_sel[1] ? {{8 {operand_a_i[31]}}, {8 {operand_a_i[23]}}, {8 {operand_a_i[15]}}, {8 {operand_a_i[7]}}} : (shuffle_reg1_sel[0] ? operand_c_i : operand_b_i));
	assign shuffle_r0[31:24] = (shuffle_byte_sel[7] ? (shuffle_byte_sel[6] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[6] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r0[23:16] = (shuffle_byte_sel[5] ? (shuffle_byte_sel[4] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[4] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r0[15:8] = (shuffle_byte_sel[3] ? (shuffle_byte_sel[2] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[2] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r0[7:0] = (shuffle_byte_sel[1] ? (shuffle_byte_sel[0] ? shuffle_r0_in[31:24] : shuffle_r0_in[23:16]) : (shuffle_byte_sel[0] ? shuffle_r0_in[15:8] : shuffle_r0_in[7:0]));
	assign shuffle_r1[31:24] = (shuffle_byte_sel[7] ? (shuffle_byte_sel[6] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[6] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_r1[23:16] = (shuffle_byte_sel[5] ? (shuffle_byte_sel[4] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[4] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_r1[15:8] = (shuffle_byte_sel[3] ? (shuffle_byte_sel[2] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[2] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_r1[7:0] = (shuffle_byte_sel[1] ? (shuffle_byte_sel[0] ? shuffle_r1_in[31:24] : shuffle_r1_in[23:16]) : (shuffle_byte_sel[0] ? shuffle_r1_in[15:8] : shuffle_r1_in[7:0]));
	assign shuffle_result[31:24] = (shuffle_reg_sel[3] ? shuffle_r1[31:24] : shuffle_r0[31:24]);
	assign shuffle_result[23:16] = (shuffle_reg_sel[2] ? shuffle_r1[23:16] : shuffle_r0[23:16]);
	assign shuffle_result[15:8] = (shuffle_reg_sel[1] ? shuffle_r1[15:8] : shuffle_r0[15:8]);
	assign shuffle_result[7:0] = (shuffle_reg_sel[0] ? shuffle_r1[7:0] : shuffle_r0[7:0]);
	assign pack_result[31:24] = (shuffle_through[3] ? shuffle_result[31:24] : operand_c_i[31:24]);
	assign pack_result[23:16] = (shuffle_through[2] ? shuffle_result[23:16] : operand_c_i[23:16]);
	assign pack_result[15:8] = (shuffle_through[1] ? shuffle_result[15:8] : operand_c_i[15:8]);
	assign pack_result[7:0] = (shuffle_through[0] ? shuffle_result[7:0] : operand_c_i[7:0]);
	reg [31:0] ff_input;
	wire [5:0] cnt_result;
	wire [5:0] clb_result;
	wire [4:0] ff1_result;
	wire ff_no_one;
	wire [4:0] fl1_result;
	reg [5:0] bitop_result;
	cv32e40p_popcnt popcnt_i(
		.in_i(operand_a_i),
		.result_o(cnt_result)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		ff_input = 1'sb0;
		case (operator_i)
			sv2v_cast_81146(7'b0110110): ff_input = operand_a_i;
			sv2v_cast_81146(7'b0110000), sv2v_cast_81146(7'b0110010), sv2v_cast_81146(7'b0110111): ff_input = operand_a_rev;
			sv2v_cast_81146(7'b0110001), sv2v_cast_81146(7'b0110011), sv2v_cast_81146(7'b0110101):
				if (operand_a_i[31])
					ff_input = operand_a_neg_rev;
				else
					ff_input = operand_a_rev;
		endcase
	end
	cv32e40p_ff_one ff_one_i(
		.in_i(ff_input),
		.first_one_o(ff1_result),
		.no_ones_o(ff_no_one)
	);
	assign fl1_result = 5'd31 - ff1_result;
	assign clb_result = ff1_result - 5'd1;
	always @(*) begin
		if (_sv2v_0)
			;
		bitop_result = 1'sb0;
		case (operator_i)
			sv2v_cast_81146(7'b0110110): bitop_result = (ff_no_one ? 6'd32 : {1'b0, ff1_result});
			sv2v_cast_81146(7'b0110111): bitop_result = (ff_no_one ? 6'd32 : {1'b0, fl1_result});
			sv2v_cast_81146(7'b0110100): bitop_result = cnt_result;
			sv2v_cast_81146(7'b0110101):
				if (ff_no_one) begin
					if (operand_a_i[31])
						bitop_result = 6'd31;
					else
						bitop_result = 1'sb0;
				end
				else
					bitop_result = clb_result;
			default:
				;
		endcase
	end
	wire extract_is_signed;
	wire extract_sign;
	wire [31:0] bmask_first;
	wire [31:0] bmask_inv;
	wire [31:0] bextins_and;
	wire [31:0] bextins_result;
	wire [31:0] bclr_result;
	wire [31:0] bset_result;
	assign bmask_first = 32'hfffffffe << bmask_a_i;
	assign bmask = ~bmask_first << bmask_b_i;
	assign bmask_inv = ~bmask;
	assign bextins_and = (operator_i == sv2v_cast_81146(7'b0101010) ? operand_c_i : {32 {extract_sign}});
	assign extract_is_signed = operator_i == sv2v_cast_81146(7'b0101000);
	assign extract_sign = extract_is_signed & shift_result[bmask_a_i];
	assign bextins_result = (bmask & shift_result) | (bextins_and & bmask_inv);
	assign bclr_result = operand_a_i & bmask_inv;
	assign bset_result = operand_a_i | bmask;
	wire [31:0] radix_2_rev;
	wire [31:0] radix_4_rev;
	wire [31:0] radix_8_rev;
	reg [31:0] reverse_result;
	wire [1:0] radix_mux_sel;
	assign radix_mux_sel = bmask_a_i[1:0];
	generate
		for (_gv_j_1 = 0; _gv_j_1 < 32; _gv_j_1 = _gv_j_1 + 1) begin : gen_radix_2_rev
			localparam j = _gv_j_1;
			assign radix_2_rev[j] = shift_result[31 - j];
		end
		for (_gv_j_1 = 0; _gv_j_1 < 16; _gv_j_1 = _gv_j_1 + 1) begin : gen_radix_4_rev
			localparam j = _gv_j_1;
			assign radix_4_rev[(2 * j) + 1:2 * j] = shift_result[31 - (j * 2):(31 - (j * 2)) - 1];
		end
		for (_gv_j_1 = 0; _gv_j_1 < 10; _gv_j_1 = _gv_j_1 + 1) begin : gen_radix_8_rev
			localparam j = _gv_j_1;
			assign radix_8_rev[(3 * j) + 2:3 * j] = shift_result[31 - (j * 3):(31 - (j * 3)) - 2];
		end
	endgenerate
	assign radix_8_rev[31:30] = 2'b00;
	always @(*) begin
		if (_sv2v_0)
			;
		reverse_result = 1'sb0;
		(* full_case, parallel_case *)
		case (radix_mux_sel)
			2'b00: reverse_result = radix_2_rev;
			2'b01: reverse_result = radix_4_rev;
			2'b10: reverse_result = radix_8_rev;
			default: reverse_result = radix_2_rev;
		endcase
	end
	wire [31:0] result_div;
	wire div_ready;
	wire div_signed;
	wire div_op_a_signed;
	wire [5:0] div_shift_int;
	assign div_signed = operator_i[0];
	assign div_op_a_signed = operand_a_i[31] & div_signed;
	assign div_shift_int = (ff_no_one ? 6'd31 : clb_result);
	assign div_shift = div_shift_int + (div_op_a_signed ? 6'd0 : 6'd1);
	assign div_valid = enable_i & ((((operator_i == sv2v_cast_81146(7'b0110001)) || (operator_i == sv2v_cast_81146(7'b0110000))) || (operator_i == sv2v_cast_81146(7'b0110011))) || (operator_i == sv2v_cast_81146(7'b0110010)));
	cv32e40p_alu_div alu_div_i(
		.Clk_CI(clk),
		.Rst_RBI(rst_n),
		.OpA_DI(operand_b_i),
		.OpB_DI(shift_left_result),
		.OpBShift_DI(div_shift),
		.OpBIsZero_SI(cnt_result == 0),
		.OpBSign_SI(div_op_a_signed),
		.OpCode_SI(operator_i[1:0]),
		.Res_DO(result_div),
		.InVld_SI(div_valid),
		.OutRdy_SI(ex_ready_i),
		.OutVld_SO(div_ready)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		result_o = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_81146(7'b0010101): result_o = operand_a_i & operand_b_i;
			sv2v_cast_81146(7'b0101110): result_o = operand_a_i | operand_b_i;
			sv2v_cast_81146(7'b0101111): result_o = operand_a_i ^ operand_b_i;
			sv2v_cast_81146(7'b0011000), sv2v_cast_81146(7'b0011100), sv2v_cast_81146(7'b0011010), sv2v_cast_81146(7'b0011110), sv2v_cast_81146(7'b0011001), sv2v_cast_81146(7'b0011101), sv2v_cast_81146(7'b0011011), sv2v_cast_81146(7'b0011111), sv2v_cast_81146(7'b0100111), sv2v_cast_81146(7'b0100101), sv2v_cast_81146(7'b0100100), sv2v_cast_81146(7'b0100110): result_o = shift_result;
			sv2v_cast_81146(7'b0101010), sv2v_cast_81146(7'b0101000), sv2v_cast_81146(7'b0101001): result_o = bextins_result;
			sv2v_cast_81146(7'b0101011): result_o = bclr_result;
			sv2v_cast_81146(7'b0101100): result_o = bset_result;
			sv2v_cast_81146(7'b1001001): result_o = reverse_result;
			sv2v_cast_81146(7'b0111010), sv2v_cast_81146(7'b0111011), sv2v_cast_81146(7'b0111000), sv2v_cast_81146(7'b0111001), sv2v_cast_81146(7'b0111111), sv2v_cast_81146(7'b0111110), sv2v_cast_81146(7'b0101101): result_o = pack_result;
			sv2v_cast_81146(7'b0010000), sv2v_cast_81146(7'b0010001), sv2v_cast_81146(7'b0010010), sv2v_cast_81146(7'b0010011): result_o = result_minmax;
			sv2v_cast_81146(7'b0010100): result_o = (is_clpx_i ? {adder_result[31:16], operand_a_i[15:0]} : result_minmax);
			sv2v_cast_81146(7'b0010110), sv2v_cast_81146(7'b0010111): result_o = clip_result;
			sv2v_cast_81146(7'b0001100), sv2v_cast_81146(7'b0001101), sv2v_cast_81146(7'b0001001), sv2v_cast_81146(7'b0001011), sv2v_cast_81146(7'b0000001), sv2v_cast_81146(7'b0000101), sv2v_cast_81146(7'b0001000), sv2v_cast_81146(7'b0001010), sv2v_cast_81146(7'b0000000), sv2v_cast_81146(7'b0000100): begin
				result_o[31:24] = {8 {cmp_result[3]}};
				result_o[23:16] = {8 {cmp_result[2]}};
				result_o[15:8] = {8 {cmp_result[1]}};
				result_o[7:0] = {8 {cmp_result[0]}};
			end
			sv2v_cast_81146(7'b0000010), sv2v_cast_81146(7'b0000011), sv2v_cast_81146(7'b0000110), sv2v_cast_81146(7'b0000111): result_o = {31'b0000000000000000000000000000000, comparison_result_o};
			sv2v_cast_81146(7'b0110110), sv2v_cast_81146(7'b0110111), sv2v_cast_81146(7'b0110101), sv2v_cast_81146(7'b0110100): result_o = {26'h0000000, bitop_result[5:0]};
			sv2v_cast_81146(7'b0110001), sv2v_cast_81146(7'b0110000), sv2v_cast_81146(7'b0110011), sv2v_cast_81146(7'b0110010): result_o = result_div;
			default:
				;
		endcase
	end
	assign ready_o = div_ready;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_alu_div (
	Clk_CI,
	Rst_RBI,
	OpA_DI,
	OpB_DI,
	OpBShift_DI,
	OpBIsZero_SI,
	OpBSign_SI,
	OpCode_SI,
	InVld_SI,
	OutRdy_SI,
	OutVld_SO,
	Res_DO
);
	reg _sv2v_0;
	parameter C_WIDTH = 32;
	parameter C_LOG_WIDTH = 6;
	input wire Clk_CI;
	input wire Rst_RBI;
	input wire [C_WIDTH - 1:0] OpA_DI;
	input wire [C_WIDTH - 1:0] OpB_DI;
	input wire [C_LOG_WIDTH - 1:0] OpBShift_DI;
	input wire OpBIsZero_SI;
	input wire OpBSign_SI;
	input wire [1:0] OpCode_SI;
	input wire InVld_SI;
	input wire OutRdy_SI;
	output reg OutVld_SO;
	output wire [C_WIDTH - 1:0] Res_DO;
	reg [C_WIDTH - 1:0] ResReg_DP;
	wire [C_WIDTH - 1:0] ResReg_DN;
	wire [C_WIDTH - 1:0] ResReg_DP_rev;
	reg [C_WIDTH - 1:0] AReg_DP;
	wire [C_WIDTH - 1:0] AReg_DN;
	reg [C_WIDTH - 1:0] BReg_DP;
	wire [C_WIDTH - 1:0] BReg_DN;
	wire RemSel_SN;
	reg RemSel_SP;
	wire CompInv_SN;
	reg CompInv_SP;
	wire ResInv_SN;
	reg ResInv_SP;
	wire [C_WIDTH - 1:0] AddMux_D;
	wire [C_WIDTH - 1:0] AddOut_D;
	wire [C_WIDTH - 1:0] AddTmp_D;
	wire [C_WIDTH - 1:0] BMux_D;
	wire [C_WIDTH - 1:0] OutMux_D;
	reg [C_LOG_WIDTH - 1:0] Cnt_DP;
	wire [C_LOG_WIDTH - 1:0] Cnt_DN;
	wire CntZero_S;
	reg ARegEn_S;
	reg BRegEn_S;
	reg ResRegEn_S;
	wire ABComp_S;
	wire PmSel_S;
	reg LoadEn_S;
	reg [1:0] State_SN;
	reg [1:0] State_SP;
	assign PmSel_S = LoadEn_S & ~(OpCode_SI[0] & (OpA_DI[C_WIDTH - 1] ^ OpBSign_SI));
	assign AddMux_D = (LoadEn_S ? OpA_DI : BReg_DP);
	assign BMux_D = (LoadEn_S ? OpB_DI : {CompInv_SP, BReg_DP[C_WIDTH - 1:1]});
	genvar _gv_index_1;
	generate
		for (_gv_index_1 = 0; _gv_index_1 < C_WIDTH; _gv_index_1 = _gv_index_1 + 1) begin : gen_bit_swapping
			localparam index = _gv_index_1;
			assign ResReg_DP_rev[index] = ResReg_DP[(C_WIDTH - 1) - index];
		end
	endgenerate
	assign OutMux_D = (RemSel_SP ? AReg_DP : ResReg_DP_rev);
	assign Res_DO = (ResInv_SP ? -$signed(OutMux_D) : OutMux_D);
	assign ABComp_S = ((AReg_DP == BReg_DP) | ((AReg_DP > BReg_DP) ^ CompInv_SP)) & (|AReg_DP | OpBIsZero_SI);
	assign AddTmp_D = (LoadEn_S ? 0 : AReg_DP);
	assign AddOut_D = (PmSel_S ? AddTmp_D + AddMux_D : AddTmp_D - $signed(AddMux_D));
	assign Cnt_DN = (LoadEn_S ? OpBShift_DI : (~CntZero_S ? Cnt_DP - 1 : Cnt_DP));
	assign CntZero_S = ~(|Cnt_DP);
	always @(*) begin : p_fsm
		if (_sv2v_0)
			;
		State_SN = State_SP;
		OutVld_SO = 1'b0;
		LoadEn_S = 1'b0;
		ARegEn_S = 1'b0;
		BRegEn_S = 1'b0;
		ResRegEn_S = 1'b0;
		case (State_SP)
			2'd0: begin
				OutVld_SO = 1'b1;
				if (InVld_SI) begin
					OutVld_SO = 1'b0;
					ARegEn_S = 1'b1;
					BRegEn_S = 1'b1;
					LoadEn_S = 1'b1;
					State_SN = 2'd1;
				end
			end
			2'd1: begin
				ARegEn_S = ABComp_S;
				BRegEn_S = 1'b1;
				ResRegEn_S = 1'b1;
				if (CntZero_S)
					State_SN = 2'd2;
			end
			2'd2: begin
				OutVld_SO = 1'b1;
				if (OutRdy_SI)
					State_SN = 2'd0;
			end
			default:
				;
		endcase
	end
	assign RemSel_SN = (LoadEn_S ? OpCode_SI[1] : RemSel_SP);
	assign CompInv_SN = (LoadEn_S ? OpBSign_SI : CompInv_SP);
	assign ResInv_SN = (LoadEn_S ? ((~OpBIsZero_SI | OpCode_SI[1]) & OpCode_SI[0]) & (OpA_DI[C_WIDTH - 1] ^ OpBSign_SI) : ResInv_SP);
	assign AReg_DN = (ARegEn_S ? AddOut_D : AReg_DP);
	assign BReg_DN = (BRegEn_S ? BMux_D : BReg_DP);
	assign ResReg_DN = (LoadEn_S ? {C_WIDTH {1'sb0}} : (ResRegEn_S ? {ABComp_S, ResReg_DP[C_WIDTH - 1:1]} : ResReg_DP));
	always @(posedge Clk_CI or negedge Rst_RBI) begin : p_regs
		if (~Rst_RBI) begin
			State_SP <= 2'd0;
			AReg_DP <= 1'sb0;
			BReg_DP <= 1'sb0;
			ResReg_DP <= 1'sb0;
			Cnt_DP <= 1'sb0;
			RemSel_SP <= 1'b0;
			CompInv_SP <= 1'b0;
			ResInv_SP <= 1'b0;
		end
		else begin
			State_SP <= State_SN;
			AReg_DP <= AReg_DN;
			BReg_DP <= BReg_DN;
			ResReg_DP <= ResReg_DN;
			Cnt_DP <= Cnt_DN;
			RemSel_SP <= RemSel_SN;
			CompInv_SP <= CompInv_SN;
			ResInv_SP <= ResInv_SN;
		end
	end
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_apu_disp (
	clk_i,
	rst_ni,
	enable_i,
	apu_lat_i,
	apu_waddr_i,
	apu_waddr_o,
	apu_multicycle_o,
	apu_singlecycle_o,
	active_o,
	stall_o,
	is_decoding_i,
	read_regs_i,
	read_regs_valid_i,
	read_dep_o,
	read_dep_for_jalr_o,
	write_regs_i,
	write_regs_valid_i,
	write_dep_o,
	perf_type_o,
	perf_cont_o,
	apu_req_o,
	apu_gnt_i,
	apu_rvalid_i
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire enable_i;
	input wire [1:0] apu_lat_i;
	input wire [5:0] apu_waddr_i;
	output reg [5:0] apu_waddr_o;
	output wire apu_multicycle_o;
	output wire apu_singlecycle_o;
	output wire active_o;
	output wire stall_o;
	input wire is_decoding_i;
	input wire [17:0] read_regs_i;
	input wire [2:0] read_regs_valid_i;
	output wire read_dep_o;
	output wire read_dep_for_jalr_o;
	input wire [11:0] write_regs_i;
	input wire [1:0] write_regs_valid_i;
	output wire write_dep_o;
	output wire perf_type_o;
	output wire perf_cont_o;
	output wire apu_req_o;
	input wire apu_gnt_i;
	input wire apu_rvalid_i;
	wire [5:0] addr_req;
	reg [5:0] addr_inflight;
	reg [5:0] addr_waiting;
	reg [5:0] addr_inflight_dn;
	reg [5:0] addr_waiting_dn;
	wire valid_req;
	reg valid_inflight;
	reg valid_waiting;
	reg valid_inflight_dn;
	reg valid_waiting_dn;
	wire returned_req;
	wire returned_inflight;
	wire returned_waiting;
	wire req_accepted;
	wire active;
	reg [1:0] apu_lat;
	wire [2:0] read_deps_req;
	wire [2:0] read_deps_inflight;
	wire [2:0] read_deps_waiting;
	wire [1:0] write_deps_req;
	wire [1:0] write_deps_inflight;
	wire [1:0] write_deps_waiting;
	wire read_dep_req;
	wire read_dep_inflight;
	wire read_dep_waiting;
	wire write_dep_req;
	wire write_dep_inflight;
	wire write_dep_waiting;
	wire stall_full;
	wire stall_type;
	wire stall_nack;
	assign valid_req = enable_i & !(stall_full | stall_type);
	assign addr_req = apu_waddr_i;
	assign req_accepted = valid_req & apu_gnt_i;
	assign returned_req = ((valid_req & apu_rvalid_i) & !valid_inflight) & !valid_waiting;
	assign returned_inflight = (valid_inflight & apu_rvalid_i) & !valid_waiting;
	assign returned_waiting = valid_waiting & apu_rvalid_i;
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			valid_inflight <= 1'b0;
			valid_waiting <= 1'b0;
			addr_inflight <= 1'sb0;
			addr_waiting <= 1'sb0;
		end
		else begin
			valid_inflight <= valid_inflight_dn;
			valid_waiting <= valid_waiting_dn;
			addr_inflight <= addr_inflight_dn;
			addr_waiting <= addr_waiting_dn;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		valid_inflight_dn = valid_inflight;
		valid_waiting_dn = valid_waiting;
		addr_inflight_dn = addr_inflight;
		addr_waiting_dn = addr_waiting;
		if (req_accepted & !returned_req) begin
			valid_inflight_dn = 1'b1;
			addr_inflight_dn = addr_req;
			if (valid_inflight & !returned_inflight) begin
				valid_waiting_dn = 1'b1;
				addr_waiting_dn = addr_inflight;
			end
			if (returned_waiting) begin
				valid_waiting_dn = 1'b1;
				addr_waiting_dn = addr_inflight;
			end
		end
		else if (returned_inflight) begin
			valid_inflight_dn = 1'sb0;
			valid_waiting_dn = 1'sb0;
			addr_inflight_dn = 1'sb0;
			addr_waiting_dn = 1'sb0;
		end
		else if (returned_waiting) begin
			valid_waiting_dn = 1'sb0;
			addr_waiting_dn = 1'sb0;
		end
	end
	assign active = valid_inflight | valid_waiting;
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			apu_lat <= 1'sb0;
		else if (valid_req)
			apu_lat <= apu_lat_i;
	genvar _gv_i_2;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < 3; _gv_i_2 = _gv_i_2 + 1) begin : gen_read_deps
			localparam i = _gv_i_2;
			assign read_deps_req[i] = (read_regs_i[i * 6+:6] == addr_req) & read_regs_valid_i[i];
			assign read_deps_inflight[i] = (read_regs_i[i * 6+:6] == addr_inflight) & read_regs_valid_i[i];
			assign read_deps_waiting[i] = (read_regs_i[i * 6+:6] == addr_waiting) & read_regs_valid_i[i];
		end
	endgenerate
	genvar _gv_i_3;
	generate
		for (_gv_i_3 = 0; _gv_i_3 < 2; _gv_i_3 = _gv_i_3 + 1) begin : gen_write_deps
			localparam i = _gv_i_3;
			assign write_deps_req[i] = (write_regs_i[i * 6+:6] == addr_req) & write_regs_valid_i[i];
			assign write_deps_inflight[i] = (write_regs_i[i * 6+:6] == addr_inflight) & write_regs_valid_i[i];
			assign write_deps_waiting[i] = (write_regs_i[i * 6+:6] == addr_waiting) & write_regs_valid_i[i];
		end
	endgenerate
	assign read_dep_req = (|read_deps_req & valid_req) & !returned_req;
	assign read_dep_inflight = (|read_deps_inflight & valid_inflight) & !returned_inflight;
	assign read_dep_waiting = (|read_deps_waiting & valid_waiting) & !returned_waiting;
	assign write_dep_req = (|write_deps_req & valid_req) & !returned_req;
	assign write_dep_inflight = (|write_deps_inflight & valid_inflight) & !returned_inflight;
	assign write_dep_waiting = (|write_deps_waiting & valid_waiting) & !returned_waiting;
	assign read_dep_o = ((read_dep_req | read_dep_inflight) | read_dep_waiting) & is_decoding_i;
	assign write_dep_o = ((write_dep_req | write_dep_inflight) | write_dep_waiting) & is_decoding_i;
	assign read_dep_for_jalr_o = is_decoding_i & (((|read_deps_req & enable_i) | (|read_deps_inflight & valid_inflight)) | (|read_deps_waiting & valid_waiting));
	assign stall_full = valid_inflight & valid_waiting;
	assign stall_type = (enable_i & active) & (((apu_lat_i == 2'h1) | ((apu_lat_i == 2'h2) & (apu_lat == 2'h3))) | (apu_lat_i == 2'h3));
	assign stall_nack = valid_req & !apu_gnt_i;
	assign stall_o = (stall_full | stall_type) | stall_nack;
	assign apu_req_o = valid_req;
	always @(*) begin
		if (_sv2v_0)
			;
		apu_waddr_o = 1'sb0;
		if (returned_req)
			apu_waddr_o = addr_req;
		if (returned_inflight)
			apu_waddr_o = addr_inflight;
		if (returned_waiting)
			apu_waddr_o = addr_waiting;
	end
	assign active_o = active;
	assign perf_type_o = stall_type;
	assign perf_cont_o = stall_nack;
	assign apu_multicycle_o = apu_lat == 2'h3;
	assign apu_singlecycle_o = ~(valid_inflight | valid_waiting);
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_compressed_decoder (
	instr_i,
	instr_o,
	is_compressed_o,
	illegal_instr_o
);
	reg _sv2v_0;
	parameter FPU = 0;
	parameter ZFINX = 0;
	input wire [31:0] instr_i;
	output reg [31:0] instr_o;
	output wire is_compressed_o;
	output reg illegal_instr_o;
	localparam cv32e40p_pkg_OPCODE_BRANCH = 7'h63;
	localparam cv32e40p_pkg_OPCODE_JAL = 7'h6f;
	localparam cv32e40p_pkg_OPCODE_JALR = 7'h67;
	localparam cv32e40p_pkg_OPCODE_LOAD = 7'h03;
	localparam cv32e40p_pkg_OPCODE_LOAD_FP = 7'h07;
	localparam cv32e40p_pkg_OPCODE_LUI = 7'h37;
	localparam cv32e40p_pkg_OPCODE_OP = 7'h33;
	localparam cv32e40p_pkg_OPCODE_OPIMM = 7'h13;
	localparam cv32e40p_pkg_OPCODE_STORE = 7'h23;
	localparam cv32e40p_pkg_OPCODE_STORE_FP = 7'h27;
	always @(*) begin
		if (_sv2v_0)
			;
		illegal_instr_o = 1'b0;
		instr_o = 1'sb0;
		(* full_case, parallel_case *)
		case (instr_i[1:0])
			2'b00:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 12'h041, instr_i[4:2], cv32e40p_pkg_OPCODE_OPIMM};
						if (instr_i[12:5] == 8'b00000000)
							illegal_instr_o = 1'b1;
					end
					3'b001:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[6:5], instr_i[12:10], 5'b00001, instr_i[9:7], 5'b01101, instr_i[4:2], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b010: instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 4'b0001, instr_i[9:7], 5'b01001, instr_i[4:2], cv32e40p_pkg_OPCODE_LOAD};
					3'b011:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 4'b0001, instr_i[9:7], 5'b01001, instr_i[4:2], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b101:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[6:5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b011, instr_i[11:10], 3'b000, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
					3'b110: instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 2'b00, cv32e40p_pkg_OPCODE_STORE};
					3'b111:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 2'b00, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b01:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
					3'b001, 3'b101: instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9 {instr_i[12]}}, 4'b0000, ~instr_i[15], cv32e40p_pkg_OPCODE_JAL};
					3'b010:
						if (instr_i[11:7] == 5'b00000)
							instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
						else
							instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
					3'b011:
						if ({instr_i[12], instr_i[6:2]} == 6'b000000)
							illegal_instr_o = 1'b1;
						else if (instr_i[11:7] == 5'h02)
							instr_o = {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 17'h00202, cv32e40p_pkg_OPCODE_OPIMM};
						else if (instr_i[11:7] == 5'b00000)
							instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], cv32e40p_pkg_OPCODE_LUI};
						else
							instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], cv32e40p_pkg_OPCODE_LUI};
					3'b100:
						(* full_case, parallel_case *)
						case (instr_i[11:10])
							2'b00, 2'b01:
								if (instr_i[12] == 1'b1) begin
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
									illegal_instr_o = 1'b1;
								end
								else if (instr_i[6:2] == 5'b00000)
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
								else
									instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
							2'b10: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], cv32e40p_pkg_OPCODE_OPIMM};
							2'b11:
								(* full_case, parallel_case *)
								case ({instr_i[12], instr_i[6:5]})
									3'b000: instr_o = {9'b010000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b00001, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b001: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b10001, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b010: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11001, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b011: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], cv32e40p_pkg_OPCODE_OP};
									3'b100, 3'b101, 3'b110, 3'b111: illegal_instr_o = 1'b1;
								endcase
						endcase
					3'b110, 3'b111: instr_o = {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 7'b0000001, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], cv32e40p_pkg_OPCODE_BRANCH};
				endcase
			2'b10:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000:
						if (instr_i[12] == 1'b1) begin
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
							illegal_instr_o = 1'b1;
						end
						else if ((instr_i[6:2] == 5'b00000) || (instr_i[11:7] == 5'b00000))
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
						else
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], cv32e40p_pkg_OPCODE_OPIMM};
					3'b001:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {3'b000, instr_i[4:2], instr_i[12], instr_i[6:5], 11'h013, instr_i[11:7], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b010: begin
						instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 10'h012, instr_i[11:7], cv32e40p_pkg_OPCODE_LOAD};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
					end
					3'b011:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 10'h012, instr_i[11:7], cv32e40p_pkg_OPCODE_LOAD_FP};
						else
							illegal_instr_o = 1'b1;
					3'b100:
						if (instr_i[12] == 1'b0) begin
							if (instr_i[6:2] == 5'b00000) begin
								instr_o = {12'b000000000000, instr_i[11:7], 8'b00000000, cv32e40p_pkg_OPCODE_JALR};
								if (instr_i[11:7] == 5'b00000)
									illegal_instr_o = 1'b1;
							end
							else if (instr_i[11:7] == 5'b00000)
								instr_o = {7'b0000000, instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
							else
								instr_o = {7'b0000000, instr_i[6:2], 8'b00000000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
						end
						else if (instr_i[6:2] == 5'b00000) begin
							if (instr_i[11:7] == 5'b00000)
								instr_o = 32'h00100073;
							else
								instr_o = {12'b000000000000, instr_i[11:7], 8'b00000001, cv32e40p_pkg_OPCODE_JALR};
						end
						else if (instr_i[11:7] == 5'b00000)
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
						else
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], cv32e40p_pkg_OPCODE_OP};
					3'b101:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {3'b000, instr_i[9:7], instr_i[12], instr_i[6:2], 8'h13, instr_i[11:10], 3'b000, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
					3'b110: instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 8'h12, instr_i[11:9], 2'b00, cv32e40p_pkg_OPCODE_STORE};
					3'b111:
						if ((FPU == 1) && (ZFINX == 0))
							instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 8'h12, instr_i[11:9], 2'b00, cv32e40p_pkg_OPCODE_STORE_FP};
						else
							illegal_instr_o = 1'b1;
				endcase
			default: instr_o = instr_i;
		endcase
	end
	assign is_compressed_o = instr_i[1:0] != 2'b11;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_controller (
	clk,
	clk_ungated_i,
	rst_n,
	fetch_enable_i,
	ctrl_busy_o,
	is_decoding_o,
	is_fetch_failed_i,
	deassert_we_o,
	illegal_insn_i,
	ecall_insn_i,
	mret_insn_i,
	uret_insn_i,
	dret_insn_i,
	mret_dec_i,
	uret_dec_i,
	dret_dec_i,
	wfi_i,
	ebrk_insn_i,
	fencei_insn_i,
	csr_status_i,
	hwlp_mask_o,
	instr_valid_i,
	instr_req_o,
	pc_set_o,
	pc_mux_o,
	exc_pc_mux_o,
	trap_addr_mux_o,
	pc_id_i,
	hwlp_start_addr_i,
	hwlp_end_addr_i,
	hwlp_counter_i,
	hwlp_dec_cnt_o,
	hwlp_jump_o,
	hwlp_targ_addr_o,
	data_req_ex_i,
	data_we_ex_i,
	data_misaligned_i,
	data_load_event_i,
	data_err_i,
	data_err_ack_o,
	mult_multicycle_i,
	apu_en_i,
	apu_read_dep_i,
	apu_read_dep_for_jalr_i,
	apu_write_dep_i,
	apu_stall_o,
	branch_taken_ex_i,
	ctrl_transfer_insn_in_id_i,
	ctrl_transfer_insn_in_dec_i,
	irq_req_ctrl_i,
	irq_sec_ctrl_i,
	irq_id_ctrl_i,
	irq_wu_ctrl_i,
	current_priv_lvl_i,
	irq_ack_o,
	irq_id_o,
	exc_cause_o,
	debug_mode_o,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	debug_p_elw_no_sleep_o,
	debug_wfi_no_sleep_o,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o,
	wake_from_sleep_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_ex_o,
	csr_cause_o,
	csr_irq_sec_o,
	csr_restore_mret_id_o,
	csr_restore_uret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	regfile_we_id_i,
	regfile_alu_waddr_id_i,
	regfile_we_ex_i,
	regfile_waddr_ex_i,
	regfile_we_wb_i,
	regfile_alu_we_fw_i,
	operand_a_fw_mux_sel_o,
	operand_b_fw_mux_sel_o,
	operand_c_fw_mux_sel_o,
	reg_d_ex_is_reg_a_i,
	reg_d_ex_is_reg_b_i,
	reg_d_ex_is_reg_c_i,
	reg_d_wb_is_reg_a_i,
	reg_d_wb_is_reg_b_i,
	reg_d_wb_is_reg_c_i,
	reg_d_alu_is_reg_a_i,
	reg_d_alu_is_reg_b_i,
	reg_d_alu_is_reg_c_i,
	halt_if_o,
	halt_id_o,
	misaligned_stall_o,
	jr_stall_o,
	load_stall_o,
	id_ready_i,
	id_valid_i,
	ex_valid_i,
	wb_ready_i,
	perf_pipeline_stall_o
);
	reg _sv2v_0;
	parameter COREV_CLUSTER = 0;
	parameter COREV_PULP = 0;
	parameter FPU = 0;
	input wire clk;
	input wire clk_ungated_i;
	input wire rst_n;
	input wire fetch_enable_i;
	output reg ctrl_busy_o;
	output reg is_decoding_o;
	input wire is_fetch_failed_i;
	output reg deassert_we_o;
	input wire illegal_insn_i;
	input wire ecall_insn_i;
	input wire mret_insn_i;
	input wire uret_insn_i;
	input wire dret_insn_i;
	input wire mret_dec_i;
	input wire uret_dec_i;
	input wire dret_dec_i;
	input wire wfi_i;
	input wire ebrk_insn_i;
	input wire fencei_insn_i;
	input wire csr_status_i;
	output reg hwlp_mask_o;
	input wire instr_valid_i;
	output reg instr_req_o;
	output reg pc_set_o;
	output reg [3:0] pc_mux_o;
	output reg [2:0] exc_pc_mux_o;
	output reg [1:0] trap_addr_mux_o;
	input wire [31:0] pc_id_i;
	input wire [63:0] hwlp_start_addr_i;
	input wire [63:0] hwlp_end_addr_i;
	input wire [63:0] hwlp_counter_i;
	output reg [1:0] hwlp_dec_cnt_o;
	output wire hwlp_jump_o;
	output reg [31:0] hwlp_targ_addr_o;
	input wire data_req_ex_i;
	input wire data_we_ex_i;
	input wire data_misaligned_i;
	input wire data_load_event_i;
	input wire data_err_i;
	output reg data_err_ack_o;
	input wire mult_multicycle_i;
	input wire apu_en_i;
	input wire apu_read_dep_i;
	input wire apu_read_dep_for_jalr_i;
	input wire apu_write_dep_i;
	output wire apu_stall_o;
	input wire branch_taken_ex_i;
	input wire [1:0] ctrl_transfer_insn_in_id_i;
	input wire [1:0] ctrl_transfer_insn_in_dec_i;
	input wire irq_req_ctrl_i;
	input wire irq_sec_ctrl_i;
	input wire [4:0] irq_id_ctrl_i;
	input wire irq_wu_ctrl_i;
	input wire [1:0] current_priv_lvl_i;
	output reg irq_ack_o;
	output reg [4:0] irq_id_o;
	output reg [4:0] exc_cause_o;
	output wire debug_mode_o;
	output reg [2:0] debug_cause_o;
	output reg debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	output wire debug_p_elw_no_sleep_o;
	output wire debug_wfi_no_sleep_o;
	output wire debug_havereset_o;
	output wire debug_running_o;
	output wire debug_halted_o;
	output wire wake_from_sleep_o;
	output reg csr_save_if_o;
	output reg csr_save_id_o;
	output reg csr_save_ex_o;
	output reg [5:0] csr_cause_o;
	output reg csr_irq_sec_o;
	output reg csr_restore_mret_id_o;
	output reg csr_restore_uret_id_o;
	output reg csr_restore_dret_id_o;
	output reg csr_save_cause_o;
	input wire regfile_we_id_i;
	input wire [5:0] regfile_alu_waddr_id_i;
	input wire regfile_we_ex_i;
	input wire [5:0] regfile_waddr_ex_i;
	input wire regfile_we_wb_i;
	input wire regfile_alu_we_fw_i;
	output reg [1:0] operand_a_fw_mux_sel_o;
	output reg [1:0] operand_b_fw_mux_sel_o;
	output reg [1:0] operand_c_fw_mux_sel_o;
	input wire reg_d_ex_is_reg_a_i;
	input wire reg_d_ex_is_reg_b_i;
	input wire reg_d_ex_is_reg_c_i;
	input wire reg_d_wb_is_reg_a_i;
	input wire reg_d_wb_is_reg_b_i;
	input wire reg_d_wb_is_reg_c_i;
	input wire reg_d_alu_is_reg_a_i;
	input wire reg_d_alu_is_reg_b_i;
	input wire reg_d_alu_is_reg_c_i;
	output reg halt_if_o;
	output reg halt_id_o;
	output wire misaligned_stall_o;
	output reg jr_stall_o;
	output reg load_stall_o;
	input wire id_ready_i;
	input wire id_valid_i;
	input wire ex_valid_i;
	input wire wb_ready_i;
	output reg perf_pipeline_stall_o;
	reg [4:0] ctrl_fsm_cs;
	reg [4:0] ctrl_fsm_ns;
	reg [2:0] debug_fsm_cs;
	reg [2:0] debug_fsm_ns;
	reg jump_done;
	reg jump_done_q;
	reg jump_in_dec;
	reg branch_in_id;
	reg data_err_q;
	reg debug_mode_q;
	reg debug_mode_n;
	reg ebrk_force_debug_mode;
	wire is_hwlp_body;
	reg illegal_insn_q;
	reg illegal_insn_n;
	reg debug_req_entry_q;
	reg debug_req_entry_n;
	reg debug_force_wakeup_q;
	reg debug_force_wakeup_n;
	wire hwlp_end0_eq_pc;
	wire hwlp_end1_eq_pc;
	wire hwlp_counter0_gt_1;
	wire hwlp_counter1_gt_1;
	wire hwlp_counter0_eq_1;
	wire hwlp_counter1_eq_1;
	wire hwlp_counter0_eq_0;
	wire hwlp_counter1_eq_0;
	wire hwlp_end0_eq_pc_plus4;
	wire hwlp_end1_eq_pc_plus4;
	wire hwlp_start0_leq_pc;
	wire hwlp_start1_leq_pc;
	wire hwlp_end0_geq_pc;
	wire hwlp_end1_geq_pc;
	reg hwlp_end_4_id_d;
	reg hwlp_end_4_id_q;
	reg debug_req_q;
	wire debug_req_pending;
	wire wfi_active;
	localparam cv32e40p_pkg_BRANCH_COND = 2'b11;
	localparam cv32e40p_pkg_BRANCH_JAL = 2'b01;
	localparam cv32e40p_pkg_BRANCH_JALR = 2'b10;
	localparam cv32e40p_pkg_DBG_CAUSE_EBREAK = 3'h1;
	localparam cv32e40p_pkg_DBG_CAUSE_HALTREQ = 3'h3;
	localparam cv32e40p_pkg_DBG_CAUSE_STEP = 3'h4;
	localparam cv32e40p_pkg_DBG_CAUSE_TRIGGER = 3'h2;
	localparam cv32e40p_pkg_EXC_CAUSE_BREAKPOINT = 5'h03;
	localparam cv32e40p_pkg_EXC_CAUSE_ECALL_MMODE = 5'h0b;
	localparam cv32e40p_pkg_EXC_CAUSE_ECALL_UMODE = 5'h08;
	localparam cv32e40p_pkg_EXC_CAUSE_ILLEGAL_INSN = 5'h02;
	localparam cv32e40p_pkg_EXC_CAUSE_INSTR_FAULT = 5'h01;
	localparam cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT = 5'h05;
	localparam cv32e40p_pkg_EXC_CAUSE_STORE_FAULT = 5'h07;
	localparam cv32e40p_pkg_EXC_PC_DBD = 3'b010;
	localparam cv32e40p_pkg_EXC_PC_DBE = 3'b011;
	localparam cv32e40p_pkg_EXC_PC_EXCEPTION = 3'b000;
	localparam cv32e40p_pkg_EXC_PC_IRQ = 3'b001;
	localparam cv32e40p_pkg_PC_BOOT = 4'b0000;
	localparam cv32e40p_pkg_PC_BRANCH = 4'b0011;
	localparam cv32e40p_pkg_PC_DRET = 4'b0111;
	localparam cv32e40p_pkg_PC_EXCEPTION = 4'b0100;
	localparam cv32e40p_pkg_PC_FENCEI = 4'b0001;
	localparam cv32e40p_pkg_PC_HWLOOP = 4'b1000;
	localparam cv32e40p_pkg_PC_JUMP = 4'b0010;
	localparam cv32e40p_pkg_PC_MRET = 4'b0101;
	localparam cv32e40p_pkg_PC_URET = 4'b0110;
	localparam cv32e40p_pkg_TRAP_MACHINE = 2'b00;
	localparam cv32e40p_pkg_TRAP_USER = 2'b01;
	always @(*) begin
		if (_sv2v_0)
			;
		instr_req_o = 1'b1;
		data_err_ack_o = 1'b0;
		csr_save_if_o = 1'b0;
		csr_save_id_o = 1'b0;
		csr_save_ex_o = 1'b0;
		csr_restore_mret_id_o = 1'b0;
		csr_restore_uret_id_o = 1'b0;
		csr_restore_dret_id_o = 1'b0;
		csr_save_cause_o = 1'b0;
		exc_cause_o = 1'sb0;
		exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
		trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
		csr_cause_o = 1'sb0;
		csr_irq_sec_o = 1'b0;
		pc_mux_o = cv32e40p_pkg_PC_BOOT;
		pc_set_o = 1'b0;
		jump_done = jump_done_q;
		ctrl_fsm_ns = ctrl_fsm_cs;
		ctrl_busy_o = 1'b1;
		halt_if_o = 1'b0;
		halt_id_o = 1'b0;
		is_decoding_o = 1'b0;
		irq_ack_o = 1'b0;
		irq_id_o = 5'b00000;
		jump_in_dec = (ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JALR) || (ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JAL);
		branch_in_id = ctrl_transfer_insn_in_id_i == cv32e40p_pkg_BRANCH_COND;
		ebrk_force_debug_mode = (debug_ebreakm_i && (current_priv_lvl_i == 2'b11)) || (debug_ebreaku_i && (current_priv_lvl_i == 2'b00));
		debug_csr_save_o = 1'b0;
		debug_cause_o = cv32e40p_pkg_DBG_CAUSE_EBREAK;
		debug_mode_n = debug_mode_q;
		illegal_insn_n = illegal_insn_q;
		debug_req_entry_n = debug_req_entry_q;
		debug_force_wakeup_n = debug_force_wakeup_q;
		perf_pipeline_stall_o = 1'b0;
		hwlp_mask_o = 1'b0;
		hwlp_dec_cnt_o = 1'sb0;
		hwlp_end_4_id_d = 1'b0;
		hwlp_targ_addr_o = ((hwlp_start1_leq_pc && hwlp_end1_geq_pc) && !(hwlp_start0_leq_pc && hwlp_end0_geq_pc) ? hwlp_start_addr_i[32+:32] : hwlp_start_addr_i[0+:32]);
		(* full_case, parallel_case *)
		case (ctrl_fsm_cs)
			5'd0: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b0;
				if (fetch_enable_i == 1'b1)
					ctrl_fsm_ns = 5'd1;
			end
			5'd1: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b1;
				pc_mux_o = cv32e40p_pkg_PC_BOOT;
				pc_set_o = 1'b1;
				if (debug_req_pending) begin
					ctrl_fsm_ns = 5'd12;
					debug_force_wakeup_n = 1'b1;
				end
				else
					ctrl_fsm_ns = 5'd4;
			end
			5'd3: begin
				is_decoding_o = 1'b0;
				ctrl_busy_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				ctrl_fsm_ns = 5'd2;
			end
			5'd2: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				if (wake_from_sleep_o) begin
					if (debug_req_pending) begin
						ctrl_fsm_ns = 5'd12;
						debug_force_wakeup_n = 1'b1;
					end
					else
						ctrl_fsm_ns = 5'd4;
				end
				else
					ctrl_busy_o = 1'b0;
			end
			5'd4: begin
				is_decoding_o = 1'b0;
				ctrl_fsm_ns = 5'd5;
				if (irq_req_ctrl_i && ~(debug_req_pending || debug_mode_q)) begin
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					pc_set_o = 1'b1;
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
					exc_cause_o = irq_id_ctrl_i;
					csr_irq_sec_o = irq_sec_ctrl_i;
					irq_ack_o = 1'b1;
					irq_id_o = irq_id_ctrl_i;
					if (irq_sec_ctrl_i)
						trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					else
						trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
					csr_save_cause_o = 1'b1;
					csr_cause_o = {1'b1, irq_id_ctrl_i};
					csr_save_if_o = 1'b1;
				end
			end
			5'd5:
				if (branch_taken_ex_i) begin
					is_decoding_o = 1'b0;
					pc_mux_o = cv32e40p_pkg_PC_BRANCH;
					pc_set_o = 1'b1;
				end
				else if (data_err_i) begin
					is_decoding_o = 1'b0;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					csr_save_ex_o = 1'b1;
					csr_save_cause_o = 1'b1;
					data_err_ack_o = 1'b1;
					csr_cause_o = {1'b0, (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_STORE_FAULT : cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT)};
					ctrl_fsm_ns = 5'd9;
				end
				else if (is_fetch_failed_i) begin
					is_decoding_o = 1'b0;
					halt_id_o = 1'b1;
					halt_if_o = 1'b1;
					csr_save_if_o = 1'b1;
					csr_save_cause_o = !debug_mode_q;
					csr_cause_o = {1'b0, cv32e40p_pkg_EXC_CAUSE_INSTR_FAULT};
					ctrl_fsm_ns = 5'd9;
				end
				else if (instr_valid_i) begin : blk_decode_level1
					is_decoding_o = 1'b1;
					illegal_insn_n = 1'b0;
					if ((debug_req_pending || trigger_match_i) & ~debug_mode_q) begin
						is_decoding_o = (COREV_PULP ? 1'b0 : 1'b1);
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
						ctrl_fsm_ns = 5'd13;
						debug_req_entry_n = 1'b1;
					end
					else if (irq_req_ctrl_i && ~debug_mode_q) begin
						hwlp_mask_o = (COREV_PULP ? 1'b1 : 1'b0);
						is_decoding_o = 1'b0;
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
						pc_set_o = 1'b1;
						pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
						exc_cause_o = irq_id_ctrl_i;
						csr_irq_sec_o = irq_sec_ctrl_i;
						irq_ack_o = 1'b1;
						irq_id_o = irq_id_ctrl_i;
						if (irq_sec_ctrl_i)
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
						else
							trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
						csr_save_cause_o = 1'b1;
						csr_cause_o = {1'b1, irq_id_ctrl_i};
						csr_save_id_o = 1'b1;
					end
					else begin
						if (illegal_insn_i) begin
							halt_if_o = 1'b1;
							halt_id_o = 1'b0;
							ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
							illegal_insn_n = 1'b1;
						end
						else
							(* full_case, parallel_case *)
							case (1'b1)
								jump_in_dec: begin
									pc_mux_o = cv32e40p_pkg_PC_JUMP;
									if (~jr_stall_o && ~jump_done_q) begin
										pc_set_o = 1'b1;
										jump_done = 1'b1;
									end
								end
								ebrk_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									if (debug_mode_q)
										ctrl_fsm_ns = 5'd13;
									else if (ebrk_force_debug_mode)
										ctrl_fsm_ns = 5'd13;
									else
										ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								wfi_active: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								ecall_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								fencei_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								(mret_insn_i | uret_insn_i) | dret_insn_i: begin
									halt_if_o = 1'b1;
									halt_id_o = 1'b0;
									ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd5);
								end
								csr_status_i: begin
									halt_if_o = 1'b1;
									if (~id_ready_i)
										ctrl_fsm_ns = 5'd5;
									else begin
										ctrl_fsm_ns = 5'd8;
										if (hwlp_end0_eq_pc)
											hwlp_dec_cnt_o[0] = 1'b1;
										if (hwlp_end1_eq_pc)
											hwlp_dec_cnt_o[1] = 1'b1;
									end
								end
								data_load_event_i: begin
									ctrl_fsm_ns = (id_ready_i ? 5'd7 : 5'd5);
									halt_if_o = 1'b1;
								end
								default: begin
									if (is_hwlp_body) begin
										ctrl_fsm_ns = (hwlp_end0_eq_pc_plus4 || hwlp_end1_eq_pc_plus4 ? 5'd5 : 5'd15);
										if (hwlp_end0_eq_pc && hwlp_counter0_gt_1) begin
											pc_mux_o = cv32e40p_pkg_PC_HWLOOP;
											if (~jump_done_q) begin
												pc_set_o = 1'b1;
												jump_done = 1'b1;
												hwlp_dec_cnt_o[0] = 1'b1;
											end
										end
										if (hwlp_end1_eq_pc && hwlp_counter1_gt_1) begin
											pc_mux_o = cv32e40p_pkg_PC_HWLOOP;
											if (~jump_done_q) begin
												pc_set_o = 1'b1;
												jump_done = 1'b1;
												hwlp_dec_cnt_o[1] = 1'b1;
											end
										end
									end
									if (hwlp_end0_eq_pc && hwlp_counter0_eq_1)
										hwlp_dec_cnt_o[0] = 1'b1;
									if (hwlp_end1_eq_pc && hwlp_counter1_eq_1)
										hwlp_dec_cnt_o[1] = 1'b1;
								end
							endcase
						if (debug_single_step_i & ~debug_mode_q) begin
							halt_if_o = 1'b1;
							if (id_ready_i)
								(* full_case, parallel_case *)
								case (1'b1)
									illegal_insn_i | ecall_insn_i: ctrl_fsm_ns = 5'd8;
									~ebrk_force_debug_mode & ebrk_insn_i: ctrl_fsm_ns = 5'd8;
									mret_insn_i | uret_insn_i: ctrl_fsm_ns = 5'd8;
									branch_in_id: ctrl_fsm_ns = 5'd14;
									default: ctrl_fsm_ns = 5'd13;
								endcase
						end
					end
				end
				else begin
					is_decoding_o = 1'b0;
					perf_pipeline_stall_o = data_load_event_i;
				end
			5'd15:
				if (COREV_PULP) begin
					if (instr_valid_i) begin
						is_decoding_o = 1'b1;
						if ((debug_req_pending || trigger_match_i) & ~debug_mode_q) begin
							is_decoding_o = (COREV_PULP ? 1'b0 : 1'b1);
							halt_if_o = 1'b1;
							halt_id_o = 1'b1;
							ctrl_fsm_ns = 5'd13;
							debug_req_entry_n = 1'b1;
						end
						else if (irq_req_ctrl_i && ~debug_mode_q) begin
							hwlp_mask_o = (COREV_PULP ? 1'b1 : 1'b0);
							is_decoding_o = 1'b0;
							halt_if_o = 1'b1;
							halt_id_o = 1'b1;
							pc_set_o = 1'b1;
							pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
							exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
							exc_cause_o = irq_id_ctrl_i;
							csr_irq_sec_o = irq_sec_ctrl_i;
							irq_ack_o = 1'b1;
							irq_id_o = irq_id_ctrl_i;
							if (irq_sec_ctrl_i)
								trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
							else
								trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
							csr_save_cause_o = 1'b1;
							csr_cause_o = {1'b1, irq_id_ctrl_i};
							csr_save_id_o = 1'b1;
							ctrl_fsm_ns = 5'd5;
						end
						else begin
							if (illegal_insn_i) begin
								halt_if_o = 1'b1;
								halt_id_o = 1'b1;
								ctrl_fsm_ns = 5'd8;
								illegal_insn_n = 1'b1;
							end
							else
								(* full_case, parallel_case *)
								case (1'b1)
									ebrk_insn_i: begin
										halt_if_o = 1'b1;
										halt_id_o = 1'b0;
										if (debug_mode_q)
											ctrl_fsm_ns = 5'd13;
										else if (ebrk_force_debug_mode)
											ctrl_fsm_ns = 5'd13;
										else
											ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd15);
									end
									ecall_insn_i: begin
										halt_if_o = 1'b1;
										halt_id_o = 1'b0;
										ctrl_fsm_ns = (id_ready_i ? 5'd8 : 5'd15);
									end
									csr_status_i: begin
										halt_if_o = 1'b1;
										if (~id_ready_i)
											ctrl_fsm_ns = 5'd15;
										else begin
											ctrl_fsm_ns = 5'd8;
											if (hwlp_end0_eq_pc)
												hwlp_dec_cnt_o[0] = 1'b1;
											if (hwlp_end1_eq_pc)
												hwlp_dec_cnt_o[1] = 1'b1;
										end
									end
									data_load_event_i: begin
										ctrl_fsm_ns = (id_ready_i ? 5'd7 : 5'd15);
										halt_if_o = 1'b1;
									end
									default: begin
										if (hwlp_end1_eq_pc_plus4) begin
											if (hwlp_counter1_gt_1) begin
												hwlp_end_4_id_d = 1'b1;
												hwlp_targ_addr_o = hwlp_start_addr_i[32+:32];
												ctrl_fsm_ns = 5'd15;
											end
											else
												ctrl_fsm_ns = (is_hwlp_body ? 5'd15 : 5'd5);
										end
										if (hwlp_end0_eq_pc_plus4) begin
											if (hwlp_counter0_gt_1) begin
												hwlp_end_4_id_d = 1'b1;
												hwlp_targ_addr_o = hwlp_start_addr_i[0+:32];
												ctrl_fsm_ns = 5'd15;
											end
											else
												ctrl_fsm_ns = (is_hwlp_body ? 5'd15 : 5'd5);
										end
										hwlp_dec_cnt_o[0] = hwlp_end0_eq_pc && !hwlp_counter0_eq_0;
										hwlp_dec_cnt_o[1] = hwlp_end1_eq_pc && !hwlp_counter1_eq_0;
									end
								endcase
							if (debug_single_step_i & ~debug_mode_q) begin
								halt_if_o = 1'b1;
								if (id_ready_i)
									(* full_case, parallel_case *)
									case (1'b1)
										illegal_insn_i | ecall_insn_i: ctrl_fsm_ns = 5'd8;
										~ebrk_force_debug_mode & ebrk_insn_i: ctrl_fsm_ns = 5'd8;
										mret_insn_i | uret_insn_i: ctrl_fsm_ns = 5'd8;
										branch_in_id: ctrl_fsm_ns = 5'd14;
										default: ctrl_fsm_ns = 5'd13;
									endcase
							end
						end
					end
					else begin
						is_decoding_o = 1'b0;
						perf_pipeline_stall_o = data_load_event_i;
					end
				end
			5'd8: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				if (data_err_i) begin
					csr_save_ex_o = 1'b1;
					csr_save_cause_o = 1'b1;
					data_err_ack_o = 1'b1;
					csr_cause_o = {1'b0, (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_STORE_FAULT : cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT)};
					ctrl_fsm_ns = 5'd9;
					illegal_insn_n = 1'b0;
				end
				else if (ex_valid_i) begin
					ctrl_fsm_ns = 5'd9;
					if (illegal_insn_q) begin
						csr_save_id_o = 1'b1;
						csr_save_cause_o = !debug_mode_q;
						csr_cause_o = {1'b0, cv32e40p_pkg_EXC_CAUSE_ILLEGAL_INSN};
					end
					else
						(* full_case, parallel_case *)
						case (1'b1)
							ebrk_insn_i: begin
								csr_save_id_o = 1'b1;
								csr_save_cause_o = 1'b1;
								csr_cause_o = {1'b0, cv32e40p_pkg_EXC_CAUSE_BREAKPOINT};
							end
							ecall_insn_i: begin
								csr_save_id_o = 1'b1;
								csr_save_cause_o = !debug_mode_q;
								csr_cause_o = {1'b0, (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_EXC_CAUSE_ECALL_UMODE : cv32e40p_pkg_EXC_CAUSE_ECALL_MMODE)};
							end
							default:
								;
						endcase
				end
			end
			5'd6:
				if (COREV_CLUSTER == 1'b1) begin
					is_decoding_o = 1'b0;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					ctrl_fsm_ns = 5'd5;
					perf_pipeline_stall_o = data_load_event_i;
					if (irq_req_ctrl_i && ~(debug_req_pending || debug_mode_q)) begin
						is_decoding_o = 1'b0;
						halt_if_o = 1'b1;
						halt_id_o = 1'b1;
						pc_set_o = 1'b1;
						pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_IRQ;
						exc_cause_o = irq_id_ctrl_i;
						csr_irq_sec_o = irq_sec_ctrl_i;
						irq_ack_o = 1'b1;
						irq_id_o = irq_id_ctrl_i;
						if (irq_sec_ctrl_i)
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
						else
							trap_addr_mux_o = (current_priv_lvl_i == 2'b00 ? cv32e40p_pkg_TRAP_USER : cv32e40p_pkg_TRAP_MACHINE);
						csr_save_cause_o = 1'b1;
						csr_cause_o = {1'b1, irq_id_ctrl_i};
						csr_save_id_o = 1'b1;
					end
				end
			5'd7:
				if (COREV_CLUSTER == 1'b1) begin
					is_decoding_o = 1'b0;
					halt_if_o = 1'b1;
					halt_id_o = 1'b1;
					if (id_ready_i)
						ctrl_fsm_ns = ((debug_req_pending || trigger_match_i) & ~debug_mode_q ? 5'd13 : 5'd6);
					else
						ctrl_fsm_ns = 5'd7;
					perf_pipeline_stall_o = data_load_event_i;
				end
			5'd9: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				ctrl_fsm_ns = 5'd5;
				if (data_err_q) begin
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					pc_set_o = 1'b1;
					trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					exc_pc_mux_o = cv32e40p_pkg_EXC_PC_EXCEPTION;
					exc_cause_o = (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT : cv32e40p_pkg_EXC_CAUSE_STORE_FAULT);
				end
				else if (is_fetch_failed_i) begin
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					pc_set_o = 1'b1;
					trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					exc_pc_mux_o = (debug_mode_q ? cv32e40p_pkg_EXC_PC_DBE : cv32e40p_pkg_EXC_PC_EXCEPTION);
					exc_cause_o = cv32e40p_pkg_EXC_CAUSE_INSTR_FAULT;
				end
				else if (illegal_insn_q) begin
					pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
					pc_set_o = 1'b1;
					trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
					exc_pc_mux_o = (debug_mode_q ? cv32e40p_pkg_EXC_PC_DBE : cv32e40p_pkg_EXC_PC_EXCEPTION);
					illegal_insn_n = 1'b0;
					if (debug_single_step_i && ~debug_mode_q)
						ctrl_fsm_ns = 5'd12;
				end
				else
					(* full_case, parallel_case *)
					case (1'b1)
						ebrk_insn_i: begin
							pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
							pc_set_o = 1'b1;
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
							exc_pc_mux_o = cv32e40p_pkg_EXC_PC_EXCEPTION;
							if (debug_single_step_i && ~debug_mode_q)
								ctrl_fsm_ns = 5'd12;
						end
						ecall_insn_i: begin
							pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
							pc_set_o = 1'b1;
							trap_addr_mux_o = cv32e40p_pkg_TRAP_MACHINE;
							exc_pc_mux_o = (debug_mode_q ? cv32e40p_pkg_EXC_PC_DBE : cv32e40p_pkg_EXC_PC_EXCEPTION);
							if (debug_single_step_i && ~debug_mode_q)
								ctrl_fsm_ns = 5'd12;
						end
						mret_insn_i: begin
							csr_restore_mret_id_o = !debug_mode_q;
							ctrl_fsm_ns = 5'd10;
						end
						uret_insn_i: begin
							csr_restore_uret_id_o = !debug_mode_q;
							ctrl_fsm_ns = 5'd10;
						end
						dret_insn_i: begin
							csr_restore_dret_id_o = 1'b1;
							ctrl_fsm_ns = 5'd10;
						end
						csr_status_i:
							if ((hwlp_end0_eq_pc && !hwlp_counter0_eq_0) || (hwlp_end1_eq_pc && !hwlp_counter1_eq_0)) begin
								pc_mux_o = cv32e40p_pkg_PC_HWLOOP;
								pc_set_o = 1'b1;
							end
						wfi_i:
							if (debug_req_pending) begin
								ctrl_fsm_ns = 5'd12;
								debug_force_wakeup_n = 1'b1;
							end
							else
								ctrl_fsm_ns = 5'd3;
						fencei_insn_i: begin
							pc_mux_o = cv32e40p_pkg_PC_FENCEI;
							pc_set_o = 1'b1;
						end
						default:
							;
					endcase
			end
			5'd10: begin
				is_decoding_o = 1'b0;
				ctrl_fsm_ns = 5'd5;
				(* full_case, parallel_case *)
				case (1'b1)
					mret_dec_i: begin
						pc_mux_o = (debug_mode_q ? cv32e40p_pkg_PC_EXCEPTION : cv32e40p_pkg_PC_MRET);
						pc_set_o = 1'b1;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBE;
					end
					uret_dec_i: begin
						pc_mux_o = (debug_mode_q ? cv32e40p_pkg_PC_EXCEPTION : cv32e40p_pkg_PC_URET);
						pc_set_o = 1'b1;
						exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBE;
					end
					dret_dec_i: begin
						pc_mux_o = cv32e40p_pkg_PC_DRET;
						pc_set_o = 1'b1;
						debug_mode_n = 1'b0;
					end
					default:
						;
				endcase
				if (debug_single_step_i && ~debug_mode_q)
					ctrl_fsm_ns = 5'd12;
			end
			5'd14: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				if (branch_taken_ex_i) begin
					pc_mux_o = cv32e40p_pkg_PC_BRANCH;
					pc_set_o = 1'b1;
				end
				ctrl_fsm_ns = 5'd13;
			end
			5'd11: begin
				is_decoding_o = 1'b0;
				pc_set_o = 1'b1;
				pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
				exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBD;
				if (~debug_mode_q) begin
					csr_save_cause_o = 1'b1;
					csr_save_id_o = 1'b1;
					debug_csr_save_o = 1'b1;
					if (trigger_match_i)
						debug_cause_o = cv32e40p_pkg_DBG_CAUSE_TRIGGER;
					else if (ebrk_force_debug_mode & ebrk_insn_i)
						debug_cause_o = cv32e40p_pkg_DBG_CAUSE_EBREAK;
					else if (debug_req_entry_q)
						debug_cause_o = cv32e40p_pkg_DBG_CAUSE_HALTREQ;
				end
				debug_req_entry_n = 1'b0;
				ctrl_fsm_ns = 5'd5;
				debug_mode_n = 1'b1;
			end
			5'd12: begin
				is_decoding_o = 1'b0;
				pc_set_o = 1'b1;
				pc_mux_o = cv32e40p_pkg_PC_EXCEPTION;
				exc_pc_mux_o = cv32e40p_pkg_EXC_PC_DBD;
				csr_save_cause_o = 1'b1;
				debug_csr_save_o = 1'b1;
				if (debug_force_wakeup_q)
					debug_cause_o = cv32e40p_pkg_DBG_CAUSE_HALTREQ;
				else if (debug_single_step_i)
					debug_cause_o = cv32e40p_pkg_DBG_CAUSE_STEP;
				csr_save_if_o = 1'b1;
				ctrl_fsm_ns = 5'd5;
				debug_mode_n = 1'b1;
				debug_force_wakeup_n = 1'b0;
			end
			5'd13: begin
				is_decoding_o = 1'b0;
				halt_if_o = 1'b1;
				halt_id_o = 1'b1;
				perf_pipeline_stall_o = data_load_event_i;
				if (data_err_i) begin
					csr_save_ex_o = 1'b1;
					csr_save_cause_o = 1'b1;
					data_err_ack_o = 1'b1;
					csr_cause_o = {1'b0, (data_we_ex_i ? cv32e40p_pkg_EXC_CAUSE_STORE_FAULT : cv32e40p_pkg_EXC_CAUSE_LOAD_FAULT)};
					ctrl_fsm_ns = 5'd9;
				end
				else if ((((debug_mode_q | trigger_match_i) | (ebrk_force_debug_mode & ebrk_insn_i)) | data_load_event_i) | debug_req_entry_q)
					ctrl_fsm_ns = 5'd11;
				else
					ctrl_fsm_ns = 5'd12;
			end
			default: begin
				is_decoding_o = 1'b0;
				instr_req_o = 1'b0;
				ctrl_fsm_ns = 5'd0;
			end
		endcase
	end
	generate
		if (COREV_PULP) begin : gen_hwlp
			assign hwlp_jump_o = (hwlp_end_4_id_d && !hwlp_end_4_id_q ? 1'b1 : 1'b0);
			always @(posedge clk or negedge rst_n)
				if (!rst_n)
					hwlp_end_4_id_q <= 1'b0;
				else
					hwlp_end_4_id_q <= hwlp_end_4_id_d;
			assign hwlp_end0_eq_pc = hwlp_end_addr_i[0+:32] == (pc_id_i + 4);
			assign hwlp_end1_eq_pc = hwlp_end_addr_i[32+:32] == (pc_id_i + 4);
			assign hwlp_counter0_gt_1 = hwlp_counter_i[0+:32] > 1;
			assign hwlp_counter1_gt_1 = hwlp_counter_i[32+:32] > 1;
			assign hwlp_counter0_eq_1 = hwlp_counter_i[0+:32] == 1;
			assign hwlp_counter1_eq_1 = hwlp_counter_i[32+:32] == 1;
			assign hwlp_counter0_eq_0 = hwlp_counter_i[0+:32] == 0;
			assign hwlp_counter1_eq_0 = hwlp_counter_i[32+:32] == 0;
			assign hwlp_end0_eq_pc_plus4 = hwlp_end_addr_i[0+:32] == (pc_id_i + 8);
			assign hwlp_end1_eq_pc_plus4 = hwlp_end_addr_i[32+:32] == (pc_id_i + 8);
			assign hwlp_start0_leq_pc = hwlp_start_addr_i[0+:32] <= pc_id_i;
			assign hwlp_start1_leq_pc = hwlp_start_addr_i[32+:32] <= pc_id_i;
			assign hwlp_end0_geq_pc = hwlp_end_addr_i[0+:32] >= (pc_id_i + 4);
			assign hwlp_end1_geq_pc = hwlp_end_addr_i[32+:32] >= (pc_id_i + 4);
			assign is_hwlp_body = ((hwlp_start0_leq_pc && hwlp_end0_geq_pc) && hwlp_counter0_gt_1) || ((hwlp_start1_leq_pc && hwlp_end1_geq_pc) && hwlp_counter1_gt_1);
		end
		else begin : gen_no_hwlp
			assign hwlp_jump_o = 1'b0;
			wire [1:1] sv2v_tmp_64C4D;
			assign sv2v_tmp_64C4D = 1'b0;
			always @(*) hwlp_end_4_id_q = sv2v_tmp_64C4D;
			assign hwlp_end0_eq_pc = 1'b0;
			assign hwlp_end1_eq_pc = 1'b0;
			assign hwlp_counter0_gt_1 = 1'b0;
			assign hwlp_counter1_gt_1 = 1'b0;
			assign hwlp_counter0_eq_1 = 1'b0;
			assign hwlp_counter1_eq_1 = 1'b0;
			assign hwlp_counter0_eq_0 = 1'b0;
			assign hwlp_counter1_eq_0 = 1'b0;
			assign hwlp_end0_eq_pc_plus4 = 1'b0;
			assign hwlp_end1_eq_pc_plus4 = 1'b0;
			assign hwlp_start0_leq_pc = 1'b0;
			assign hwlp_start1_leq_pc = 1'b0;
			assign hwlp_end0_geq_pc = 1'b0;
			assign hwlp_end1_geq_pc = 1'b0;
			assign is_hwlp_body = 1'b0;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		load_stall_o = 1'b0;
		deassert_we_o = 1'b0;
		if (~is_decoding_o)
			deassert_we_o = 1'b1;
		if (illegal_insn_i)
			deassert_we_o = 1'b1;
		if ((((data_req_ex_i == 1'b1) && (regfile_we_ex_i == 1'b1)) || ((wb_ready_i == 1'b0) && (regfile_we_wb_i == 1'b1))) && ((((reg_d_ex_is_reg_a_i == 1'b1) || (reg_d_ex_is_reg_b_i == 1'b1)) || (reg_d_ex_is_reg_c_i == 1'b1)) || ((is_decoding_o && (regfile_we_id_i && !data_misaligned_i)) && (regfile_waddr_ex_i == regfile_alu_waddr_id_i)))) begin
			deassert_we_o = 1'b1;
			load_stall_o = 1'b1;
		end
		if ((ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JALR) && (((((regfile_we_wb_i == 1'b1) && (reg_d_wb_is_reg_a_i == 1'b1)) || ((regfile_we_ex_i == 1'b1) && (reg_d_ex_is_reg_a_i == 1'b1))) || ((regfile_alu_we_fw_i == 1'b1) && (reg_d_alu_is_reg_a_i == 1'b1))) || (FPU && (apu_read_dep_for_jalr_i == 1'b1)))) begin
			jr_stall_o = 1'b1;
			deassert_we_o = 1'b1;
		end
		else
			jr_stall_o = 1'b0;
	end
	assign misaligned_stall_o = data_misaligned_i;
	assign apu_stall_o = apu_read_dep_i | (apu_write_dep_i & ~apu_en_i);
	localparam cv32e40p_pkg_SEL_FW_EX = 2'b01;
	localparam cv32e40p_pkg_SEL_FW_WB = 2'b10;
	localparam cv32e40p_pkg_SEL_REGFILE = 2'b00;
	always @(*) begin
		if (_sv2v_0)
			;
		operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		if (regfile_we_wb_i == 1'b1) begin
			if (reg_d_wb_is_reg_a_i == 1'b1)
				operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_WB;
			if (reg_d_wb_is_reg_b_i == 1'b1)
				operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_WB;
			if (reg_d_wb_is_reg_c_i == 1'b1)
				operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_WB;
		end
		if (regfile_alu_we_fw_i == 1'b1) begin
			if (reg_d_alu_is_reg_a_i == 1'b1)
				operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
			if (reg_d_alu_is_reg_b_i == 1'b1)
				operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
			if (reg_d_alu_is_reg_c_i == 1'b1)
				operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
		end
		if (data_misaligned_i) begin
			operand_a_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
			operand_b_fw_mux_sel_o = cv32e40p_pkg_SEL_REGFILE;
		end
		else if (mult_multicycle_i)
			operand_c_fw_mux_sel_o = cv32e40p_pkg_SEL_FW_EX;
	end
	always @(posedge clk or negedge rst_n) begin : UPDATE_REGS
		if (rst_n == 1'b0) begin
			ctrl_fsm_cs <= 5'd0;
			jump_done_q <= 1'b0;
			data_err_q <= 1'b0;
			debug_mode_q <= 1'b0;
			illegal_insn_q <= 1'b0;
			debug_req_entry_q <= 1'b0;
			debug_force_wakeup_q <= 1'b0;
		end
		else begin
			ctrl_fsm_cs <= ctrl_fsm_ns;
			jump_done_q <= jump_done & ~id_ready_i;
			data_err_q <= data_err_i;
			debug_mode_q <= debug_mode_n;
			illegal_insn_q <= illegal_insn_n;
			debug_req_entry_q <= debug_req_entry_n;
			debug_force_wakeup_q <= debug_force_wakeup_n;
		end
	end
	assign wake_from_sleep_o = (irq_wu_ctrl_i || debug_req_pending) || debug_mode_q;
	assign debug_mode_o = debug_mode_q;
	assign debug_req_pending = debug_req_i || debug_req_q;
	assign debug_p_elw_no_sleep_o = ((debug_mode_q || debug_req_q) || debug_single_step_i) || trigger_match_i;
	assign debug_wfi_no_sleep_o = (((debug_mode_q || debug_req_pending) || debug_single_step_i) || trigger_match_i) || COREV_CLUSTER;
	assign wfi_active = wfi_i & ~debug_wfi_no_sleep_o;
	always @(posedge clk_ungated_i or negedge rst_n)
		if (!rst_n)
			debug_req_q <= 1'b0;
		else if (debug_req_i)
			debug_req_q <= 1'b1;
		else if (debug_mode_q)
			debug_req_q <= 1'b0;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			debug_fsm_cs <= 3'b001;
		else
			debug_fsm_cs <= debug_fsm_ns;
	always @(*) begin
		if (_sv2v_0)
			;
		debug_fsm_ns = debug_fsm_cs;
		case (debug_fsm_cs)
			3'b001:
				if (debug_mode_n || (ctrl_fsm_ns == 5'd4)) begin
					if (debug_mode_n)
						debug_fsm_ns = 3'b100;
					else
						debug_fsm_ns = 3'b010;
				end
			3'b010:
				if (debug_mode_n)
					debug_fsm_ns = 3'b100;
			3'b100:
				if (!debug_mode_n)
					debug_fsm_ns = 3'b010;
			default: debug_fsm_ns = 3'b001;
		endcase
	end
	localparam cv32e40p_pkg_HAVERESET_INDEX = 0;
	assign debug_havereset_o = debug_fsm_cs[cv32e40p_pkg_HAVERESET_INDEX];
	localparam cv32e40p_pkg_RUNNING_INDEX = 1;
	assign debug_running_o = debug_fsm_cs[cv32e40p_pkg_RUNNING_INDEX];
	localparam cv32e40p_pkg_HALTED_INDEX = 2;
	assign debug_halted_o = debug_fsm_cs[cv32e40p_pkg_HALTED_INDEX];
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_core (
	clk_i,
	rst_ni,
	pulp_clock_en_i,
	scan_cg_en_i,
	boot_addr_i,
	mtvec_addr_i,
	dm_halt_addr_i,
	hart_id_i,
	dm_exception_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_rdata_i,
	apu_busy_o,
	apu_req_o,
	apu_gnt_i,
	apu_operands_o,
	apu_op_o,
	apu_flags_o,
	apu_rvalid_i,
	apu_result_i,
	apu_flags_i,
	irq_i,
	irq_ack_o,
	irq_id_o,
	debug_req_i,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o,
	fetch_enable_i,
	core_sleep_o
);
	parameter COREV_PULP = 0;
	parameter COREV_CLUSTER = 0;
	parameter FPU = 0;
	parameter FPU_ADDMUL_LAT = 0;
	parameter FPU_OTHERS_LAT = 0;
	parameter ZFINX = 0;
	parameter NUM_MHPMCOUNTERS = 1;
	input wire clk_i;
	input wire rst_ni;
	input wire pulp_clock_en_i;
	input wire scan_cg_en_i;
	input wire [31:0] boot_addr_i;
	input wire [31:0] mtvec_addr_i;
	input wire [31:0] dm_halt_addr_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] dm_exception_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	input wire [31:0] data_rdata_i;
	output wire apu_busy_o;
	output wire apu_req_o;
	input wire apu_gnt_i;
	localparam cv32e40p_apu_core_pkg_APU_NARGS_CPU = 3;
	output wire [95:0] apu_operands_o;
	localparam cv32e40p_apu_core_pkg_APU_WOP_CPU = 6;
	output wire [5:0] apu_op_o;
	localparam cv32e40p_apu_core_pkg_APU_NDSFLAGS_CPU = 15;
	output wire [14:0] apu_flags_o;
	input wire apu_rvalid_i;
	input wire [31:0] apu_result_i;
	localparam cv32e40p_apu_core_pkg_APU_NUSFLAGS_CPU = 5;
	input wire [4:0] apu_flags_i;
	input wire [31:0] irq_i;
	output wire irq_ack_o;
	output wire [4:0] irq_id_o;
	input wire debug_req_i;
	output wire debug_havereset_o;
	output wire debug_running_o;
	output wire debug_halted_o;
	input wire fetch_enable_i;
	output wire core_sleep_o;
	localparam PULP_SECURE = 0;
	localparam N_PMP_ENTRIES = 16;
	localparam USE_PMP = 0;
	localparam A_EXTENSION = 0;
	localparam DEBUG_TRIGGER_EN = 1;
	localparam PULP_OBI = 0;
	wire [5:0] data_atop_o;
	wire irq_sec_i;
	wire sec_lvl_o;
	localparam N_HWLP = 2;
	localparam APU = (FPU == 1 ? 1 : 0);
	wire instr_valid_id;
	wire [31:0] instr_rdata_id;
	wire is_compressed_id;
	wire illegal_c_insn_id;
	wire is_fetch_failed_id;
	wire clear_instr_valid;
	wire pc_set;
	wire [3:0] pc_mux_id;
	wire [2:0] exc_pc_mux_id;
	wire [4:0] m_exc_vec_pc_mux_id;
	wire [4:0] u_exc_vec_pc_mux_id;
	wire [4:0] exc_cause;
	wire [1:0] trap_addr_mux;
	wire [31:0] pc_if;
	wire [31:0] pc_id;
	wire is_decoding;
	wire useincr_addr_ex;
	wire data_misaligned;
	wire mult_multicycle;
	wire [31:0] jump_target_id;
	wire [31:0] jump_target_ex;
	wire branch_in_ex;
	wire branch_decision;
	wire [1:0] ctrl_transfer_insn_in_dec;
	wire ctrl_busy;
	wire if_busy;
	wire lsu_busy;
	wire [31:0] pc_ex;
	wire alu_en_ex;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	wire [6:0] alu_operator_ex;
	wire [31:0] alu_operand_a_ex;
	wire [31:0] alu_operand_b_ex;
	wire [31:0] alu_operand_c_ex;
	wire [4:0] bmask_a_ex;
	wire [4:0] bmask_b_ex;
	wire [1:0] imm_vec_ext_ex;
	wire [1:0] alu_vec_mode_ex;
	wire alu_is_clpx_ex;
	wire alu_is_subrot_ex;
	wire [1:0] alu_clpx_shift_ex;
	localparam cv32e40p_pkg_MUL_OP_WIDTH = 3;
	wire [2:0] mult_operator_ex;
	wire [31:0] mult_operand_a_ex;
	wire [31:0] mult_operand_b_ex;
	wire [31:0] mult_operand_c_ex;
	wire mult_en_ex;
	wire mult_sel_subword_ex;
	wire [1:0] mult_signed_mode_ex;
	wire [4:0] mult_imm_ex;
	wire [31:0] mult_dot_op_a_ex;
	wire [31:0] mult_dot_op_b_ex;
	wire [31:0] mult_dot_op_c_ex;
	wire [1:0] mult_dot_signed_ex;
	wire mult_is_clpx_ex;
	wire [1:0] mult_clpx_shift_ex;
	wire mult_clpx_img_ex;
	wire fs_off;
	localparam cv32e40p_pkg_C_RM = 3;
	wire [2:0] frm_csr;
	localparam cv32e40p_pkg_C_FFLAG = 5;
	wire [4:0] fflags_csr;
	wire fflags_we;
	wire fregs_we;
	wire apu_en_ex;
	wire [14:0] apu_flags_ex;
	wire [5:0] apu_op_ex;
	wire [1:0] apu_lat_ex;
	wire [95:0] apu_operands_ex;
	wire [5:0] apu_waddr_ex;
	wire [17:0] apu_read_regs;
	wire [2:0] apu_read_regs_valid;
	wire apu_read_dep;
	wire apu_read_dep_for_jalr;
	wire [11:0] apu_write_regs;
	wire [1:0] apu_write_regs_valid;
	wire apu_write_dep;
	wire perf_apu_type;
	wire perf_apu_cont;
	wire perf_apu_dep;
	wire perf_apu_wb;
	wire [5:0] regfile_waddr_ex;
	wire regfile_we_ex;
	wire [5:0] regfile_waddr_fw_wb_o;
	wire regfile_we_wb;
	wire regfile_we_wb_power;
	wire [31:0] regfile_wdata;
	wire [5:0] regfile_alu_waddr_ex;
	wire regfile_alu_we_ex;
	wire [5:0] regfile_alu_waddr_fw;
	wire regfile_alu_we_fw;
	wire regfile_alu_we_fw_power;
	wire [31:0] regfile_alu_wdata_fw;
	wire csr_access_ex;
	localparam cv32e40p_pkg_CSR_OP_WIDTH = 2;
	wire [1:0] csr_op_ex;
	wire [23:0] mtvec;
	wire [23:0] utvec;
	wire [1:0] mtvec_mode;
	wire [1:0] utvec_mode;
	wire [1:0] csr_op;
	wire [11:0] csr_addr;
	wire [11:0] csr_addr_int;
	wire [31:0] csr_rdata;
	wire [31:0] csr_wdata;
	wire [1:0] current_priv_lvl;
	wire data_we_ex;
	wire [5:0] data_atop_ex;
	wire [1:0] data_type_ex;
	wire [1:0] data_sign_ext_ex;
	wire [1:0] data_reg_offset_ex;
	wire data_req_ex;
	wire data_load_event_ex;
	wire data_misaligned_ex;
	wire p_elw_start;
	wire p_elw_finish;
	wire [31:0] lsu_rdata;
	wire halt_if;
	wire id_ready;
	wire ex_ready;
	wire id_valid;
	wire ex_valid;
	wire wb_valid;
	wire lsu_ready_ex;
	wire lsu_ready_wb;
	wire apu_ready_wb;
	wire instr_req_int;
	wire m_irq_enable;
	wire u_irq_enable;
	wire csr_irq_sec;
	wire [31:0] mepc;
	wire [31:0] uepc;
	wire [31:0] depc;
	wire [31:0] mie_bypass;
	wire [31:0] mip;
	wire csr_save_cause;
	wire csr_save_if;
	wire csr_save_id;
	wire csr_save_ex;
	wire [5:0] csr_cause;
	wire csr_restore_mret_id;
	wire csr_restore_uret_id;
	wire csr_restore_dret_id;
	wire csr_mtvec_init;
	wire [31:0] mcounteren;
	wire debug_mode;
	wire [2:0] debug_cause;
	wire debug_csr_save;
	wire debug_single_step;
	wire debug_ebreakm;
	wire debug_ebreaku;
	wire trigger_match;
	wire debug_p_elw_no_sleep;
	wire [63:0] hwlp_start;
	wire [63:0] hwlp_end;
	wire [63:0] hwlp_cnt;
	wire [31:0] hwlp_target;
	wire hwlp_jump;
	wire mhpmevent_minstret;
	wire mhpmevent_load;
	wire mhpmevent_store;
	wire mhpmevent_jump;
	wire mhpmevent_branch;
	wire mhpmevent_branch_taken;
	wire mhpmevent_compressed;
	wire mhpmevent_jr_stall;
	wire mhpmevent_imiss;
	wire mhpmevent_ld_stall;
	wire mhpmevent_pipe_stall;
	wire perf_imiss;
	wire wake_from_sleep;
	wire [511:0] pmp_addr;
	wire [127:0] pmp_cfg;
	wire data_req_pmp;
	wire [31:0] data_addr_pmp;
	wire data_gnt_pmp;
	wire data_err_pmp;
	wire data_err_ack;
	wire instr_req_pmp;
	wire instr_gnt_pmp;
	wire [31:0] instr_addr_pmp;
	wire instr_err_pmp;
	assign m_exc_vec_pc_mux_id = (mtvec_mode == 2'b00 ? 5'h00 : exc_cause);
	assign u_exc_vec_pc_mux_id = (utvec_mode == 2'b00 ? 5'h00 : exc_cause);
	assign irq_sec_i = 1'b0;
	assign apu_flags_o = apu_flags_ex;
	wire clk;
	wire fetch_enable;
	cv32e40p_sleep_unit #(.COREV_CLUSTER(COREV_CLUSTER)) sleep_unit_i(
		.clk_ungated_i(clk_i),
		.rst_n(rst_ni),
		.clk_gated_o(clk),
		.scan_cg_en_i(scan_cg_en_i),
		.core_sleep_o(core_sleep_o),
		.fetch_enable_i(fetch_enable_i),
		.fetch_enable_o(fetch_enable),
		.if_busy_i(if_busy),
		.ctrl_busy_i(ctrl_busy),
		.lsu_busy_i(lsu_busy),
		.apu_busy_i(apu_busy_o),
		.pulp_clock_en_i(pulp_clock_en_i),
		.p_elw_start_i(p_elw_start),
		.p_elw_finish_i(p_elw_finish),
		.debug_p_elw_no_sleep_i(debug_p_elw_no_sleep),
		.wake_from_sleep_i(wake_from_sleep)
	);
	cv32e40p_if_stage #(
		.COREV_PULP(COREV_PULP),
		.PULP_OBI(PULP_OBI),
		.PULP_SECURE(PULP_SECURE),
		.FPU(FPU),
		.ZFINX(ZFINX)
	) if_stage_i(
		.clk(clk),
		.rst_n(rst_ni),
		.boot_addr_i(boot_addr_i[31:0]),
		.dm_exception_addr_i(dm_exception_addr_i[31:0]),
		.dm_halt_addr_i(dm_halt_addr_i[31:0]),
		.m_trap_base_addr_i(mtvec),
		.u_trap_base_addr_i(utvec),
		.trap_addr_mux_i(trap_addr_mux),
		.req_i(instr_req_int),
		.instr_req_o(instr_req_pmp),
		.instr_addr_o(instr_addr_pmp),
		.instr_gnt_i(instr_gnt_pmp),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.instr_err_i(1'b0),
		.instr_err_pmp_i(instr_err_pmp),
		.instr_valid_id_o(instr_valid_id),
		.instr_rdata_id_o(instr_rdata_id),
		.is_fetch_failed_o(is_fetch_failed_id),
		.clear_instr_valid_i(clear_instr_valid),
		.pc_set_i(pc_set),
		.mepc_i(mepc),
		.uepc_i(uepc),
		.depc_i(depc),
		.pc_mux_i(pc_mux_id),
		.exc_pc_mux_i(exc_pc_mux_id),
		.pc_id_o(pc_id),
		.pc_if_o(pc_if),
		.is_compressed_id_o(is_compressed_id),
		.illegal_c_insn_id_o(illegal_c_insn_id),
		.m_exc_vec_pc_mux_i(m_exc_vec_pc_mux_id),
		.u_exc_vec_pc_mux_i(u_exc_vec_pc_mux_id),
		.csr_mtvec_init_o(csr_mtvec_init),
		.hwlp_jump_i(hwlp_jump),
		.hwlp_target_i(hwlp_target),
		.jump_target_id_i(jump_target_id),
		.jump_target_ex_i(jump_target_ex),
		.halt_if_i(halt_if),
		.id_ready_i(id_ready),
		.if_busy_o(if_busy),
		.perf_imiss_o(perf_imiss)
	);
	cv32e40p_id_stage #(
		.COREV_PULP(COREV_PULP),
		.COREV_CLUSTER(COREV_CLUSTER),
		.N_HWLP(N_HWLP),
		.PULP_SECURE(PULP_SECURE),
		.USE_PMP(USE_PMP),
		.A_EXTENSION(A_EXTENSION),
		.APU(APU),
		.FPU(FPU),
		.FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
		.FPU_OTHERS_LAT(FPU_OTHERS_LAT),
		.ZFINX(ZFINX),
		.APU_NARGS_CPU(cv32e40p_apu_core_pkg_APU_NARGS_CPU),
		.APU_WOP_CPU(cv32e40p_apu_core_pkg_APU_WOP_CPU),
		.APU_NDSFLAGS_CPU(cv32e40p_apu_core_pkg_APU_NDSFLAGS_CPU),
		.APU_NUSFLAGS_CPU(cv32e40p_apu_core_pkg_APU_NUSFLAGS_CPU),
		.DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
	) id_stage_i(
		.clk(clk),
		.clk_ungated_i(clk_i),
		.rst_n(rst_ni),
		.scan_cg_en_i(scan_cg_en_i),
		.fetch_enable_i(fetch_enable),
		.ctrl_busy_o(ctrl_busy),
		.is_decoding_o(is_decoding),
		.instr_valid_i(instr_valid_id),
		.instr_rdata_i(instr_rdata_id),
		.instr_req_o(instr_req_int),
		.branch_in_ex_o(branch_in_ex),
		.branch_decision_i(branch_decision),
		.jump_target_o(jump_target_id),
		.ctrl_transfer_insn_in_dec_o(ctrl_transfer_insn_in_dec),
		.clear_instr_valid_o(clear_instr_valid),
		.pc_set_o(pc_set),
		.pc_mux_o(pc_mux_id),
		.exc_pc_mux_o(exc_pc_mux_id),
		.exc_cause_o(exc_cause),
		.trap_addr_mux_o(trap_addr_mux),
		.is_fetch_failed_i(is_fetch_failed_id),
		.pc_id_i(pc_id),
		.is_compressed_i(is_compressed_id),
		.illegal_c_insn_i(illegal_c_insn_id),
		.halt_if_o(halt_if),
		.id_ready_o(id_ready),
		.ex_ready_i(ex_ready),
		.wb_ready_i(lsu_ready_wb),
		.id_valid_o(id_valid),
		.ex_valid_i(ex_valid),
		.pc_ex_o(pc_ex),
		.alu_en_ex_o(alu_en_ex),
		.alu_operator_ex_o(alu_operator_ex),
		.alu_operand_a_ex_o(alu_operand_a_ex),
		.alu_operand_b_ex_o(alu_operand_b_ex),
		.alu_operand_c_ex_o(alu_operand_c_ex),
		.bmask_a_ex_o(bmask_a_ex),
		.bmask_b_ex_o(bmask_b_ex),
		.imm_vec_ext_ex_o(imm_vec_ext_ex),
		.alu_vec_mode_ex_o(alu_vec_mode_ex),
		.alu_is_clpx_ex_o(alu_is_clpx_ex),
		.alu_is_subrot_ex_o(alu_is_subrot_ex),
		.alu_clpx_shift_ex_o(alu_clpx_shift_ex),
		.regfile_waddr_ex_o(regfile_waddr_ex),
		.regfile_we_ex_o(regfile_we_ex),
		.regfile_alu_we_ex_o(regfile_alu_we_ex),
		.regfile_alu_waddr_ex_o(regfile_alu_waddr_ex),
		.mult_operator_ex_o(mult_operator_ex),
		.mult_en_ex_o(mult_en_ex),
		.mult_sel_subword_ex_o(mult_sel_subword_ex),
		.mult_signed_mode_ex_o(mult_signed_mode_ex),
		.mult_operand_a_ex_o(mult_operand_a_ex),
		.mult_operand_b_ex_o(mult_operand_b_ex),
		.mult_operand_c_ex_o(mult_operand_c_ex),
		.mult_imm_ex_o(mult_imm_ex),
		.mult_dot_op_a_ex_o(mult_dot_op_a_ex),
		.mult_dot_op_b_ex_o(mult_dot_op_b_ex),
		.mult_dot_op_c_ex_o(mult_dot_op_c_ex),
		.mult_dot_signed_ex_o(mult_dot_signed_ex),
		.mult_is_clpx_ex_o(mult_is_clpx_ex),
		.mult_clpx_shift_ex_o(mult_clpx_shift_ex),
		.mult_clpx_img_ex_o(mult_clpx_img_ex),
		.fs_off_i(fs_off),
		.frm_i(frm_csr),
		.apu_en_ex_o(apu_en_ex),
		.apu_op_ex_o(apu_op_ex),
		.apu_lat_ex_o(apu_lat_ex),
		.apu_operands_ex_o(apu_operands_ex),
		.apu_flags_ex_o(apu_flags_ex),
		.apu_waddr_ex_o(apu_waddr_ex),
		.apu_read_regs_o(apu_read_regs),
		.apu_read_regs_valid_o(apu_read_regs_valid),
		.apu_read_dep_i(apu_read_dep),
		.apu_read_dep_for_jalr_i(apu_read_dep_for_jalr),
		.apu_write_regs_o(apu_write_regs),
		.apu_write_regs_valid_o(apu_write_regs_valid),
		.apu_write_dep_i(apu_write_dep),
		.apu_perf_dep_o(perf_apu_dep),
		.apu_busy_i(apu_busy_o),
		.csr_access_ex_o(csr_access_ex),
		.csr_op_ex_o(csr_op_ex),
		.current_priv_lvl_i(current_priv_lvl),
		.csr_irq_sec_o(csr_irq_sec),
		.csr_cause_o(csr_cause),
		.csr_save_if_o(csr_save_if),
		.csr_save_id_o(csr_save_id),
		.csr_save_ex_o(csr_save_ex),
		.csr_restore_mret_id_o(csr_restore_mret_id),
		.csr_restore_uret_id_o(csr_restore_uret_id),
		.csr_restore_dret_id_o(csr_restore_dret_id),
		.csr_save_cause_o(csr_save_cause),
		.hwlp_start_o(hwlp_start),
		.hwlp_end_o(hwlp_end),
		.hwlp_cnt_o(hwlp_cnt),
		.hwlp_jump_o(hwlp_jump),
		.hwlp_target_o(hwlp_target),
		.data_req_ex_o(data_req_ex),
		.data_we_ex_o(data_we_ex),
		.atop_ex_o(data_atop_ex),
		.data_type_ex_o(data_type_ex),
		.data_sign_ext_ex_o(data_sign_ext_ex),
		.data_reg_offset_ex_o(data_reg_offset_ex),
		.data_load_event_ex_o(data_load_event_ex),
		.data_misaligned_ex_o(data_misaligned_ex),
		.prepost_useincr_ex_o(useincr_addr_ex),
		.data_misaligned_i(data_misaligned),
		.data_err_i(data_err_pmp),
		.data_err_ack_o(data_err_ack),
		.irq_i(irq_i),
		.irq_sec_i((PULP_SECURE ? irq_sec_i : 1'b0)),
		.mie_bypass_i(mie_bypass),
		.mip_o(mip),
		.m_irq_enable_i(m_irq_enable),
		.u_irq_enable_i(u_irq_enable),
		.irq_ack_o(irq_ack_o),
		.irq_id_o(irq_id_o),
		.debug_mode_o(debug_mode),
		.debug_cause_o(debug_cause),
		.debug_csr_save_o(debug_csr_save),
		.debug_req_i(debug_req_i),
		.debug_havereset_o(debug_havereset_o),
		.debug_running_o(debug_running_o),
		.debug_halted_o(debug_halted_o),
		.debug_single_step_i(debug_single_step),
		.debug_ebreakm_i(debug_ebreakm),
		.debug_ebreaku_i(debug_ebreaku),
		.trigger_match_i(trigger_match),
		.debug_p_elw_no_sleep_o(debug_p_elw_no_sleep),
		.wake_from_sleep_o(wake_from_sleep),
		.regfile_waddr_wb_i(regfile_waddr_fw_wb_o),
		.regfile_we_wb_i(regfile_we_wb),
		.regfile_we_wb_power_i(regfile_we_wb_power),
		.regfile_wdata_wb_i(regfile_wdata),
		.regfile_alu_waddr_fw_i(regfile_alu_waddr_fw),
		.regfile_alu_we_fw_i(regfile_alu_we_fw),
		.regfile_alu_we_fw_power_i(regfile_alu_we_fw_power),
		.regfile_alu_wdata_fw_i(regfile_alu_wdata_fw),
		.mult_multicycle_i(mult_multicycle),
		.mhpmevent_minstret_o(mhpmevent_minstret),
		.mhpmevent_load_o(mhpmevent_load),
		.mhpmevent_store_o(mhpmevent_store),
		.mhpmevent_jump_o(mhpmevent_jump),
		.mhpmevent_branch_o(mhpmevent_branch),
		.mhpmevent_branch_taken_o(mhpmevent_branch_taken),
		.mhpmevent_compressed_o(mhpmevent_compressed),
		.mhpmevent_jr_stall_o(mhpmevent_jr_stall),
		.mhpmevent_imiss_o(mhpmevent_imiss),
		.mhpmevent_ld_stall_o(mhpmevent_ld_stall),
		.mhpmevent_pipe_stall_o(mhpmevent_pipe_stall),
		.perf_imiss_i(perf_imiss),
		.mcounteren_i(mcounteren)
	);
	cv32e40p_ex_stage #(
		.COREV_PULP(COREV_PULP),
		.FPU(FPU),
		.APU_NARGS_CPU(cv32e40p_apu_core_pkg_APU_NARGS_CPU),
		.APU_WOP_CPU(cv32e40p_apu_core_pkg_APU_WOP_CPU),
		.APU_NDSFLAGS_CPU(cv32e40p_apu_core_pkg_APU_NDSFLAGS_CPU),
		.APU_NUSFLAGS_CPU(cv32e40p_apu_core_pkg_APU_NUSFLAGS_CPU)
	) ex_stage_i(
		.clk(clk),
		.rst_n(rst_ni),
		.alu_en_i(alu_en_ex),
		.alu_operator_i(alu_operator_ex),
		.alu_operand_a_i(alu_operand_a_ex),
		.alu_operand_b_i(alu_operand_b_ex),
		.alu_operand_c_i(alu_operand_c_ex),
		.bmask_a_i(bmask_a_ex),
		.bmask_b_i(bmask_b_ex),
		.imm_vec_ext_i(imm_vec_ext_ex),
		.alu_vec_mode_i(alu_vec_mode_ex),
		.alu_is_clpx_i(alu_is_clpx_ex),
		.alu_is_subrot_i(alu_is_subrot_ex),
		.alu_clpx_shift_i(alu_clpx_shift_ex),
		.mult_operator_i(mult_operator_ex),
		.mult_operand_a_i(mult_operand_a_ex),
		.mult_operand_b_i(mult_operand_b_ex),
		.mult_operand_c_i(mult_operand_c_ex),
		.mult_en_i(mult_en_ex),
		.mult_sel_subword_i(mult_sel_subword_ex),
		.mult_signed_mode_i(mult_signed_mode_ex),
		.mult_imm_i(mult_imm_ex),
		.mult_dot_op_a_i(mult_dot_op_a_ex),
		.mult_dot_op_b_i(mult_dot_op_b_ex),
		.mult_dot_op_c_i(mult_dot_op_c_ex),
		.mult_dot_signed_i(mult_dot_signed_ex),
		.mult_is_clpx_i(mult_is_clpx_ex),
		.mult_clpx_shift_i(mult_clpx_shift_ex),
		.mult_clpx_img_i(mult_clpx_img_ex),
		.mult_multicycle_o(mult_multicycle),
		.data_req_i(data_req_o),
		.data_rvalid_i(data_rvalid_i),
		.data_misaligned_ex_i(data_misaligned_ex),
		.data_misaligned_i(data_misaligned),
		.ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec),
		.fpu_fflags_we_o(fflags_we),
		.fpu_fflags_o(fflags_csr),
		.apu_en_i(apu_en_ex),
		.apu_op_i(apu_op_ex),
		.apu_lat_i(apu_lat_ex),
		.apu_operands_i(apu_operands_ex),
		.apu_waddr_i(apu_waddr_ex),
		.apu_read_regs_i(apu_read_regs),
		.apu_read_regs_valid_i(apu_read_regs_valid),
		.apu_read_dep_o(apu_read_dep),
		.apu_read_dep_for_jalr_o(apu_read_dep_for_jalr),
		.apu_write_regs_i(apu_write_regs),
		.apu_write_regs_valid_i(apu_write_regs_valid),
		.apu_write_dep_o(apu_write_dep),
		.apu_perf_type_o(perf_apu_type),
		.apu_perf_cont_o(perf_apu_cont),
		.apu_perf_wb_o(perf_apu_wb),
		.apu_ready_wb_o(apu_ready_wb),
		.apu_busy_o(apu_busy_o),
		.apu_req_o(apu_req_o),
		.apu_gnt_i(apu_gnt_i),
		.apu_operands_o(apu_operands_o),
		.apu_op_o(apu_op_o),
		.apu_rvalid_i(apu_rvalid_i),
		.apu_result_i(apu_result_i),
		.apu_flags_i(apu_flags_i),
		.lsu_en_i(data_req_ex),
		.lsu_rdata_i(lsu_rdata),
		.csr_access_i(csr_access_ex),
		.csr_rdata_i(csr_rdata),
		.branch_in_ex_i(branch_in_ex),
		.regfile_alu_waddr_i(regfile_alu_waddr_ex),
		.regfile_alu_we_i(regfile_alu_we_ex),
		.regfile_waddr_i(regfile_waddr_ex),
		.regfile_we_i(regfile_we_ex),
		.regfile_waddr_wb_o(regfile_waddr_fw_wb_o),
		.regfile_we_wb_o(regfile_we_wb),
		.regfile_we_wb_power_o(regfile_we_wb_power),
		.regfile_wdata_wb_o(regfile_wdata),
		.jump_target_o(jump_target_ex),
		.branch_decision_o(branch_decision),
		.regfile_alu_waddr_fw_o(regfile_alu_waddr_fw),
		.regfile_alu_we_fw_o(regfile_alu_we_fw),
		.regfile_alu_we_fw_power_o(regfile_alu_we_fw_power),
		.regfile_alu_wdata_fw_o(regfile_alu_wdata_fw),
		.is_decoding_i(is_decoding),
		.lsu_ready_ex_i(lsu_ready_ex),
		.lsu_err_i(data_err_pmp),
		.ex_ready_o(ex_ready),
		.ex_valid_o(ex_valid),
		.wb_ready_i(lsu_ready_wb)
	);
	cv32e40p_load_store_unit #(.PULP_OBI(PULP_OBI)) load_store_unit_i(
		.clk(clk),
		.rst_n(rst_ni),
		.data_req_o(data_req_pmp),
		.data_gnt_i(data_gnt_pmp),
		.data_rvalid_i(data_rvalid_i),
		.data_err_i(1'b0),
		.data_err_pmp_i(data_err_pmp),
		.data_addr_o(data_addr_pmp),
		.data_we_o(data_we_o),
		.data_atop_o(data_atop_o),
		.data_be_o(data_be_o),
		.data_wdata_o(data_wdata_o),
		.data_rdata_i(data_rdata_i),
		.data_we_ex_i(data_we_ex),
		.data_atop_ex_i(data_atop_ex),
		.data_type_ex_i(data_type_ex),
		.data_wdata_ex_i(alu_operand_c_ex),
		.data_reg_offset_ex_i(data_reg_offset_ex),
		.data_load_event_ex_i(data_load_event_ex),
		.data_sign_ext_ex_i(data_sign_ext_ex),
		.data_rdata_ex_o(lsu_rdata),
		.data_req_ex_i(data_req_ex),
		.operand_a_ex_i(alu_operand_a_ex),
		.operand_b_ex_i(alu_operand_b_ex),
		.addr_useincr_ex_i(useincr_addr_ex),
		.data_misaligned_ex_i(data_misaligned_ex),
		.data_misaligned_o(data_misaligned),
		.p_elw_start_o(p_elw_start),
		.p_elw_finish_o(p_elw_finish),
		.lsu_ready_ex_o(lsu_ready_ex),
		.lsu_ready_wb_o(lsu_ready_wb),
		.busy_o(lsu_busy)
	);
	assign wb_valid = lsu_ready_wb;
	cv32e40p_cs_registers #(
		.N_HWLP(N_HWLP),
		.A_EXTENSION(A_EXTENSION),
		.FPU(FPU),
		.ZFINX(ZFINX),
		.APU(APU),
		.PULP_SECURE(PULP_SECURE),
		.USE_PMP(USE_PMP),
		.N_PMP_ENTRIES(N_PMP_ENTRIES),
		.NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS),
		.COREV_PULP(COREV_PULP),
		.COREV_CLUSTER(COREV_CLUSTER),
		.DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
	) cs_registers_i(
		.clk(clk),
		.rst_n(rst_ni),
		.hart_id_i(hart_id_i),
		.mtvec_o(mtvec),
		.utvec_o(utvec),
		.mtvec_mode_o(mtvec_mode),
		.utvec_mode_o(utvec_mode),
		.mtvec_addr_i(mtvec_addr_i[31:0]),
		.csr_mtvec_init_i(csr_mtvec_init),
		.csr_addr_i(csr_addr),
		.csr_wdata_i(csr_wdata),
		.csr_op_i(csr_op),
		.csr_rdata_o(csr_rdata),
		.fs_off_o(fs_off),
		.frm_o(frm_csr),
		.fflags_i(fflags_csr),
		.fflags_we_i(fflags_we),
		.fregs_we_i(fregs_we),
		.mie_bypass_o(mie_bypass),
		.mip_i(mip),
		.m_irq_enable_o(m_irq_enable),
		.u_irq_enable_o(u_irq_enable),
		.csr_irq_sec_i(csr_irq_sec),
		.sec_lvl_o(sec_lvl_o),
		.mepc_o(mepc),
		.uepc_o(uepc),
		.mcounteren_o(mcounteren),
		.debug_mode_i(debug_mode),
		.debug_cause_i(debug_cause),
		.debug_csr_save_i(debug_csr_save),
		.depc_o(depc),
		.debug_single_step_o(debug_single_step),
		.debug_ebreakm_o(debug_ebreakm),
		.debug_ebreaku_o(debug_ebreaku),
		.trigger_match_o(trigger_match),
		.priv_lvl_o(current_priv_lvl),
		.pmp_addr_o(pmp_addr),
		.pmp_cfg_o(pmp_cfg),
		.pc_if_i(pc_if),
		.pc_id_i(pc_id),
		.pc_ex_i(pc_ex),
		.csr_save_if_i(csr_save_if),
		.csr_save_id_i(csr_save_id),
		.csr_save_ex_i(csr_save_ex),
		.csr_restore_mret_i(csr_restore_mret_id),
		.csr_restore_uret_i(csr_restore_uret_id),
		.csr_restore_dret_i(csr_restore_dret_id),
		.csr_cause_i(csr_cause),
		.csr_save_cause_i(csr_save_cause),
		.hwlp_start_i(hwlp_start),
		.hwlp_end_i(hwlp_end),
		.hwlp_cnt_i(hwlp_cnt),
		.mhpmevent_minstret_i(mhpmevent_minstret),
		.mhpmevent_load_i(mhpmevent_load),
		.mhpmevent_store_i(mhpmevent_store),
		.mhpmevent_jump_i(mhpmevent_jump),
		.mhpmevent_branch_i(mhpmevent_branch),
		.mhpmevent_branch_taken_i(mhpmevent_branch_taken),
		.mhpmevent_compressed_i(mhpmevent_compressed),
		.mhpmevent_jr_stall_i(mhpmevent_jr_stall),
		.mhpmevent_imiss_i(mhpmevent_imiss),
		.mhpmevent_ld_stall_i(mhpmevent_ld_stall),
		.mhpmevent_pipe_stall_i(mhpmevent_pipe_stall),
		.apu_typeconflict_i(perf_apu_type),
		.apu_contention_i(perf_apu_cont),
		.apu_dep_i(perf_apu_dep),
		.apu_wb_i(perf_apu_wb)
	);
	assign csr_addr = csr_addr_int;
	assign csr_wdata = alu_operand_a_ex;
	assign csr_op = csr_op_ex;
	function automatic [11:0] sv2v_cast_12;
		input reg [11:0] inp;
		sv2v_cast_12 = inp;
	endfunction
	assign csr_addr_int = sv2v_cast_12((csr_access_ex ? alu_operand_b_ex[11:0] : {12 {1'sb0}}));
	assign fregs_we = ((FPU == 1) & (ZFINX == 0) ? (regfile_alu_we_fw && regfile_alu_waddr_fw[5]) || (regfile_we_wb && regfile_waddr_fw_wb_o[5]) : 1'b0);
	generate
		if (1) begin : gen_no_pmp
			assign instr_req_o = instr_req_pmp;
			assign instr_addr_o = instr_addr_pmp;
			assign instr_gnt_pmp = instr_gnt_i;
			assign instr_err_pmp = 1'b0;
			assign data_req_o = data_req_pmp;
			assign data_addr_o = data_addr_pmp;
			assign data_gnt_pmp = data_gnt_i;
			assign data_err_pmp = 1'b0;
		end
	endgenerate
endmodule
module cv32e40p_cs_registers (
	clk,
	rst_n,
	hart_id_i,
	mtvec_o,
	utvec_o,
	mtvec_mode_o,
	utvec_mode_o,
	mtvec_addr_i,
	csr_mtvec_init_i,
	csr_addr_i,
	csr_wdata_i,
	csr_op_i,
	csr_rdata_o,
	fs_off_o,
	frm_o,
	fflags_i,
	fflags_we_i,
	fregs_we_i,
	mie_bypass_o,
	mip_i,
	m_irq_enable_o,
	u_irq_enable_o,
	csr_irq_sec_i,
	sec_lvl_o,
	mepc_o,
	uepc_o,
	mcounteren_o,
	debug_mode_i,
	debug_cause_i,
	debug_csr_save_i,
	depc_o,
	debug_single_step_o,
	debug_ebreakm_o,
	debug_ebreaku_o,
	trigger_match_o,
	pmp_addr_o,
	pmp_cfg_o,
	priv_lvl_o,
	pc_if_i,
	pc_id_i,
	pc_ex_i,
	csr_save_if_i,
	csr_save_id_i,
	csr_save_ex_i,
	csr_restore_mret_i,
	csr_restore_uret_i,
	csr_restore_dret_i,
	csr_cause_i,
	csr_save_cause_i,
	hwlp_start_i,
	hwlp_end_i,
	hwlp_cnt_i,
	mhpmevent_minstret_i,
	mhpmevent_load_i,
	mhpmevent_store_i,
	mhpmevent_jump_i,
	mhpmevent_branch_i,
	mhpmevent_branch_taken_i,
	mhpmevent_compressed_i,
	mhpmevent_jr_stall_i,
	mhpmevent_imiss_i,
	mhpmevent_ld_stall_i,
	mhpmevent_pipe_stall_i,
	apu_typeconflict_i,
	apu_contention_i,
	apu_dep_i,
	apu_wb_i
);
	reg _sv2v_0;
	parameter N_HWLP = 2;
	parameter APU = 0;
	parameter A_EXTENSION = 0;
	parameter FPU = 0;
	parameter ZFINX = 0;
	parameter PULP_SECURE = 0;
	parameter USE_PMP = 0;
	parameter N_PMP_ENTRIES = 16;
	parameter NUM_MHPMCOUNTERS = 1;
	parameter COREV_PULP = 0;
	parameter COREV_CLUSTER = 0;
	parameter DEBUG_TRIGGER_EN = 1;
	input wire clk;
	input wire rst_n;
	input wire [31:0] hart_id_i;
	output wire [23:0] mtvec_o;
	output wire [23:0] utvec_o;
	output wire [1:0] mtvec_mode_o;
	output wire [1:0] utvec_mode_o;
	input wire [31:0] mtvec_addr_i;
	input wire csr_mtvec_init_i;
	input wire [11:0] csr_addr_i;
	input wire [31:0] csr_wdata_i;
	localparam cv32e40p_pkg_CSR_OP_WIDTH = 2;
	input wire [1:0] csr_op_i;
	output wire [31:0] csr_rdata_o;
	output wire fs_off_o;
	output wire [2:0] frm_o;
	localparam cv32e40p_pkg_C_FFLAG = 5;
	input wire [4:0] fflags_i;
	input wire fflags_we_i;
	input wire fregs_we_i;
	output wire [31:0] mie_bypass_o;
	input wire [31:0] mip_i;
	output wire m_irq_enable_o;
	output wire u_irq_enable_o;
	input wire csr_irq_sec_i;
	output wire sec_lvl_o;
	output wire [31:0] mepc_o;
	output wire [31:0] uepc_o;
	output wire [31:0] mcounteren_o;
	input wire debug_mode_i;
	input wire [2:0] debug_cause_i;
	input wire debug_csr_save_i;
	output wire [31:0] depc_o;
	output wire debug_single_step_o;
	output wire debug_ebreakm_o;
	output wire debug_ebreaku_o;
	output wire trigger_match_o;
	output wire [(N_PMP_ENTRIES * 32) - 1:0] pmp_addr_o;
	output wire [(N_PMP_ENTRIES * 8) - 1:0] pmp_cfg_o;
	output wire [1:0] priv_lvl_o;
	input wire [31:0] pc_if_i;
	input wire [31:0] pc_id_i;
	input wire [31:0] pc_ex_i;
	input wire csr_save_if_i;
	input wire csr_save_id_i;
	input wire csr_save_ex_i;
	input wire csr_restore_mret_i;
	input wire csr_restore_uret_i;
	input wire csr_restore_dret_i;
	input wire [5:0] csr_cause_i;
	input wire csr_save_cause_i;
	input wire [(N_HWLP * 32) - 1:0] hwlp_start_i;
	input wire [(N_HWLP * 32) - 1:0] hwlp_end_i;
	input wire [(N_HWLP * 32) - 1:0] hwlp_cnt_i;
	input wire mhpmevent_minstret_i;
	input wire mhpmevent_load_i;
	input wire mhpmevent_store_i;
	input wire mhpmevent_jump_i;
	input wire mhpmevent_branch_i;
	input wire mhpmevent_branch_taken_i;
	input wire mhpmevent_compressed_i;
	input wire mhpmevent_jr_stall_i;
	input wire mhpmevent_imiss_i;
	input wire mhpmevent_ld_stall_i;
	input wire mhpmevent_pipe_stall_i;
	input wire apu_typeconflict_i;
	input wire apu_contention_i;
	input wire apu_dep_i;
	input wire apu_wb_i;
	localparam NUM_HPM_EVENTS = 16;
	localparam MTVEC_MODE = 2'b01;
	localparam MAX_N_PMP_ENTRIES = 16;
	localparam MAX_N_PMP_CFG = 4;
	localparam N_PMP_CFG = ((N_PMP_ENTRIES % 4) == 0 ? N_PMP_ENTRIES / 4 : (N_PMP_ENTRIES / 4) + 1);
	localparam MSTATUS_UIE_BIT = 0;
	localparam MSTATUS_SIE_BIT = 1;
	localparam MSTATUS_MIE_BIT = 3;
	localparam MSTATUS_UPIE_BIT = 4;
	localparam MSTATUS_SPIE_BIT = 5;
	localparam MSTATUS_MPIE_BIT = 7;
	localparam MSTATUS_SPP_BIT = 8;
	localparam MSTATUS_MPP_BIT_LOW = 11;
	localparam MSTATUS_MPP_BIT_HIGH = 12;
	localparam MSTATUS_FS_BIT_LOW = 13;
	localparam MSTATUS_FS_BIT_HIGH = 14;
	localparam MSTATUS_MPRV_BIT = 17;
	localparam MSTATUS_SD_BIT = 31;
	localparam [1:0] MXL = 2'd1;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	localparam [31:0] MISA_VALUE = (((((((((((A_EXTENSION << 0) | 4) | 0) | 0) | (sv2v_cast_32((FPU == 1) && (ZFINX == 0)) << 5)) | 256) | 4096) | 0) | 0) | (PULP_SECURE << 20)) | (sv2v_cast_32(COREV_PULP || COREV_CLUSTER) << 23)) | (sv2v_cast_32(MXL) << 30);
	localparam PULP_PERF_COUNTERS = 0;
	reg [31:0] csr_wdata_int;
	reg [31:0] csr_rdata_int;
	reg csr_we_int;
	localparam cv32e40p_pkg_C_RM = 3;
	reg [2:0] frm_q;
	reg [2:0] frm_n;
	reg [4:0] fflags_q;
	reg [4:0] fflags_n;
	reg fcsr_update;
	reg [31:0] mepc_q;
	reg [31:0] mepc_n;
	reg [31:0] uepc_q;
	reg [31:0] uepc_n;
	wire [31:0] tmatch_control_rdata;
	wire [31:0] tmatch_value_rdata;
	wire [15:0] tinfo_types;
	reg [31:0] dcsr_q;
	reg [31:0] dcsr_n;
	reg [31:0] depc_q;
	reg [31:0] depc_n;
	reg [31:0] dscratch0_q;
	reg [31:0] dscratch0_n;
	reg [31:0] dscratch1_q;
	reg [31:0] dscratch1_n;
	reg [31:0] mscratch_q;
	reg [31:0] mscratch_n;
	reg [31:0] exception_pc;
	reg [6:0] mstatus_q;
	reg [6:0] mstatus_n;
	reg mstatus_we_int;
	reg [1:0] mstatus_fs_q;
	reg [1:0] mstatus_fs_n;
	reg [5:0] mcause_q;
	reg [5:0] mcause_n;
	reg [5:0] ucause_q;
	reg [5:0] ucause_n;
	reg [23:0] mtvec_n;
	reg [23:0] mtvec_q;
	reg [23:0] utvec_n;
	reg [23:0] utvec_q;
	reg [1:0] mtvec_mode_n;
	reg [1:0] mtvec_mode_q;
	reg [1:0] utvec_mode_n;
	reg [1:0] utvec_mode_q;
	wire [31:0] mip;
	reg [31:0] mie_q;
	reg [31:0] mie_n;
	reg [31:0] csr_mie_wdata;
	reg csr_mie_we;
	wire is_irq;
	reg [1:0] priv_lvl_n;
	reg [1:0] priv_lvl_q;
	reg [767:0] pmp_reg_q;
	reg [767:0] pmp_reg_n;
	reg [15:0] pmpaddr_we;
	reg [15:0] pmpcfg_we;
	localparam cv32e40p_pkg_MHPMCOUNTER_WIDTH = 64;
	reg [2047:0] mhpmcounter_q;
	reg [2047:0] mhpmcounter_d;
	reg [1023:0] mhpmevent_q;
	reg [1023:0] mhpmevent_d;
	reg [1023:0] mhpmevent_n;
	reg [31:0] mcounteren_q;
	reg [31:0] mcounteren_n;
	reg [31:0] mcountinhibit_q;
	reg [31:0] mcountinhibit_d;
	reg [31:0] mcountinhibit_n;
	wire [15:0] hpm_events;
	wire [2047:0] mhpmcounter_increment;
	wire [31:0] mhpmcounter_write_lower;
	wire [31:0] mhpmcounter_write_upper;
	wire [31:0] mhpmcounter_write_increment;
	assign is_irq = csr_cause_i[5];
	assign mip = mip_i;
	function automatic [1:0] sv2v_cast_8FA4C;
		input reg [1:0] inp;
		sv2v_cast_8FA4C = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		csr_mie_wdata = csr_wdata_i;
		csr_mie_we = 1'b1;
		case (csr_op_i)
			sv2v_cast_8FA4C(2'b01): csr_mie_wdata = csr_wdata_i;
			sv2v_cast_8FA4C(2'b10): csr_mie_wdata = csr_wdata_i | mie_q;
			sv2v_cast_8FA4C(2'b11): csr_mie_wdata = ~csr_wdata_i & mie_q;
			sv2v_cast_8FA4C(2'b00): begin
				csr_mie_wdata = csr_wdata_i;
				csr_mie_we = 1'b0;
			end
		endcase
	end
	localparam cv32e40p_pkg_IRQ_MASK = 32'hffff0888;
	assign mie_bypass_o = ((csr_addr_i == 12'h304) && csr_mie_we ? csr_mie_wdata & cv32e40p_pkg_IRQ_MASK : mie_q);
	genvar _gv_j_2;
	localparam cv32e40p_pkg_MARCHID = 32'h00000004;
	localparam cv32e40p_pkg_MVENDORID_BANK = 25'h000000c;
	localparam cv32e40p_pkg_MVENDORID_OFFSET = 7'h02;
	generate
		if (PULP_SECURE == 1) begin : gen_pulp_secure_read_logic
			always @(*) begin
				if (_sv2v_0)
					;
				case (csr_addr_i)
					12'h001: csr_rdata_int = (FPU == 1 ? {27'b000000000000000000000000000, fflags_q} : {32 {1'sb0}});
					12'h002: csr_rdata_int = (FPU == 1 ? {29'b00000000000000000000000000000, frm_q} : {32 {1'sb0}});
					12'h003: csr_rdata_int = (FPU == 1 ? {24'b000000000000000000000000, frm_q, fflags_q} : {32 {1'sb0}});
					12'h300: csr_rdata_int = {14'b00000000000000, mstatus_q[0], 4'b0000, mstatus_q[2-:2], 3'b000, mstatus_q[3], 2'h0, mstatus_q[4], mstatus_q[5], 2'h0, mstatus_q[6]};
					12'h301: csr_rdata_int = MISA_VALUE;
					12'h304: csr_rdata_int = mie_q;
					12'h305: csr_rdata_int = {mtvec_q, 6'h00, mtvec_mode_q};
					12'h340: csr_rdata_int = mscratch_q;
					12'h341: csr_rdata_int = mepc_q;
					12'h342: csr_rdata_int = {mcause_q[5], 26'b00000000000000000000000000, mcause_q[4:0]};
					12'h344: csr_rdata_int = mip;
					12'hf14: csr_rdata_int = hart_id_i;
					12'hf11: csr_rdata_int = {cv32e40p_pkg_MVENDORID_BANK, cv32e40p_pkg_MVENDORID_OFFSET};
					12'hf12: csr_rdata_int = cv32e40p_pkg_MARCHID;
					12'hf13, 12'h343: csr_rdata_int = 'b0;
					12'h306: csr_rdata_int = mcounteren_q;
					12'h7a0, 12'h7a3, 12'h7a8, 12'h7aa: csr_rdata_int = 'b0;
					12'h7a1: csr_rdata_int = tmatch_control_rdata;
					12'h7a2: csr_rdata_int = tmatch_value_rdata;
					12'h7a4: csr_rdata_int = tinfo_types;
					12'h7b0: csr_rdata_int = dcsr_q;
					12'h7b1: csr_rdata_int = depc_q;
					12'h7b2: csr_rdata_int = dscratch0_q;
					12'h7b3: csr_rdata_int = dscratch1_q;
					12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f, 12'hc00, 12'hc02, 12'hc03, 12'hc04, 12'hc05, 12'hc06, 12'hc07, 12'hc08, 12'hc09, 12'hc0a, 12'hc0b, 12'hc0c, 12'hc0d, 12'hc0e, 12'hc0f, 12'hc10, 12'hc11, 12'hc12, 12'hc13, 12'hc14, 12'hc15, 12'hc16, 12'hc17, 12'hc18, 12'hc19, 12'hc1a, 12'hc1b, 12'hc1c, 12'hc1d, 12'hc1e, 12'hc1f: csr_rdata_int = mhpmcounter_q[(csr_addr_i[4:0] * 64) + 31-:32];
					12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f, 12'hc80, 12'hc82, 12'hc83, 12'hc84, 12'hc85, 12'hc86, 12'hc87, 12'hc88, 12'hc89, 12'hc8a, 12'hc8b, 12'hc8c, 12'hc8d, 12'hc8e, 12'hc8f, 12'hc90, 12'hc91, 12'hc92, 12'hc93, 12'hc94, 12'hc95, 12'hc96, 12'hc97, 12'hc98, 12'hc99, 12'hc9a, 12'hc9b, 12'hc9c, 12'hc9d, 12'hc9e, 12'hc9f: csr_rdata_int = mhpmcounter_q[(csr_addr_i[4:0] * 64) + 63-:32];
					12'h320: csr_rdata_int = mcountinhibit_q;
					12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_rdata_int = mhpmevent_q[csr_addr_i[4:0] * 32+:32];
					12'hcc0: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_start_i[0+:32]);
					12'hcc1: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_end_i[0+:32]);
					12'hcc2: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_cnt_i[0+:32]);
					12'hcc4: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_start_i[32+:32]);
					12'hcc5: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_end_i[32+:32]);
					12'hcc6: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_cnt_i[32+:32]);
					12'h3a0: csr_rdata_int = (USE_PMP ? pmp_reg_q[128+:32] : {32 {1'sb0}});
					12'h3a1: csr_rdata_int = (USE_PMP ? pmp_reg_q[160+:32] : {32 {1'sb0}});
					12'h3a2: csr_rdata_int = (USE_PMP ? pmp_reg_q[192+:32] : {32 {1'sb0}});
					12'h3a3: csr_rdata_int = (USE_PMP ? pmp_reg_q[224+:32] : {32 {1'sb0}});
					12'h3b0, 12'h3b1, 12'h3b2, 12'h3b3, 12'h3b4, 12'h3b5, 12'h3b6, 12'h3b7, 12'h3b8, 12'h3b9, 12'h3ba, 12'h3bb, 12'h3bc, 12'h3bd, 12'h3be, 12'h3bf: csr_rdata_int = (USE_PMP ? pmp_reg_q[256 + (csr_addr_i[3:0] * 32)+:32] : {32 {1'sb0}});
					12'h000: csr_rdata_int = {27'b000000000000000000000000000, mstatus_q[4], 3'h0, mstatus_q[6]};
					12'h005: csr_rdata_int = {utvec_q, 6'h00, utvec_mode_q};
					12'hcd0: csr_rdata_int = (!COREV_PULP ? 'b0 : hart_id_i);
					12'h041: csr_rdata_int = uepc_q;
					12'h042: csr_rdata_int = {ucause_q[5], 26'h0000000, ucause_q[4:0]};
					12'hcd1: csr_rdata_int = (!COREV_PULP ? 'b0 : {30'h00000000, priv_lvl_q});
					default: csr_rdata_int = 1'sb0;
				endcase
			end
		end
		else begin : gen_no_pulp_secure_read_logic
			always @(*) begin
				if (_sv2v_0)
					;
				case (csr_addr_i)
					12'h001: csr_rdata_int = (FPU == 1 ? {27'b000000000000000000000000000, fflags_q} : {32 {1'sb0}});
					12'h002: csr_rdata_int = (FPU == 1 ? {29'b00000000000000000000000000000, frm_q} : {32 {1'sb0}});
					12'h003: csr_rdata_int = (FPU == 1 ? {24'b000000000000000000000000, frm_q, fflags_q} : {32 {1'sb0}});
					12'h300: csr_rdata_int = {((FPU == 1) && (ZFINX == 0) ? (mstatus_fs_q == 2'b11 ? 1'b1 : 1'b0) : 1'b0), 13'b0000000000000, mstatus_q[0], 2'b00, ((FPU == 1) && (ZFINX == 0) ? mstatus_fs_q : 2'b00), mstatus_q[2-:2], 3'b000, mstatus_q[3], 2'h0, mstatus_q[4], mstatus_q[5], 2'h0, mstatus_q[6]};
					12'h301: csr_rdata_int = MISA_VALUE;
					12'h304: csr_rdata_int = mie_q;
					12'h305: csr_rdata_int = {mtvec_q, 6'h00, mtvec_mode_q};
					12'h340: csr_rdata_int = mscratch_q;
					12'h341: csr_rdata_int = mepc_q;
					12'h342: csr_rdata_int = {mcause_q[5], 26'b00000000000000000000000000, mcause_q[4:0]};
					12'h344: csr_rdata_int = mip;
					12'hf14: csr_rdata_int = hart_id_i;
					12'hf11: csr_rdata_int = {cv32e40p_pkg_MVENDORID_BANK, cv32e40p_pkg_MVENDORID_OFFSET};
					12'hf12: csr_rdata_int = cv32e40p_pkg_MARCHID;
					12'hf13: csr_rdata_int = (((FPU == 1) || (COREV_PULP == 1)) || (COREV_CLUSTER == 1) ? 32'h00000001 : 'b0);
					12'h343: csr_rdata_int = 'b0;
					12'h7a0, 12'h7a3, 12'h7a8, 12'h7aa: csr_rdata_int = 'b0;
					12'h7a1: csr_rdata_int = tmatch_control_rdata;
					12'h7a2: csr_rdata_int = tmatch_value_rdata;
					12'h7a4: csr_rdata_int = tinfo_types;
					12'h7b0: csr_rdata_int = dcsr_q;
					12'h7b1: csr_rdata_int = depc_q;
					12'h7b2: csr_rdata_int = dscratch0_q;
					12'h7b3: csr_rdata_int = dscratch1_q;
					12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f, 12'hc00, 12'hc02, 12'hc03, 12'hc04, 12'hc05, 12'hc06, 12'hc07, 12'hc08, 12'hc09, 12'hc0a, 12'hc0b, 12'hc0c, 12'hc0d, 12'hc0e, 12'hc0f, 12'hc10, 12'hc11, 12'hc12, 12'hc13, 12'hc14, 12'hc15, 12'hc16, 12'hc17, 12'hc18, 12'hc19, 12'hc1a, 12'hc1b, 12'hc1c, 12'hc1d, 12'hc1e, 12'hc1f: csr_rdata_int = mhpmcounter_q[(csr_addr_i[4:0] * 64) + 31-:32];
					12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f, 12'hc80, 12'hc82, 12'hc83, 12'hc84, 12'hc85, 12'hc86, 12'hc87, 12'hc88, 12'hc89, 12'hc8a, 12'hc8b, 12'hc8c, 12'hc8d, 12'hc8e, 12'hc8f, 12'hc90, 12'hc91, 12'hc92, 12'hc93, 12'hc94, 12'hc95, 12'hc96, 12'hc97, 12'hc98, 12'hc99, 12'hc9a, 12'hc9b, 12'hc9c, 12'hc9d, 12'hc9e, 12'hc9f: csr_rdata_int = mhpmcounter_q[(csr_addr_i[4:0] * 64) + 63-:32];
					12'h320: csr_rdata_int = mcountinhibit_q;
					12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_rdata_int = mhpmevent_q[csr_addr_i[4:0] * 32+:32];
					12'hcc0: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_start_i[0+:32]);
					12'hcc1: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_end_i[0+:32]);
					12'hcc2: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_cnt_i[0+:32]);
					12'hcc4: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_start_i[32+:32]);
					12'hcc5: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_end_i[32+:32]);
					12'hcc6: csr_rdata_int = (!COREV_PULP ? 'b0 : hwlp_cnt_i[32+:32]);
					12'hcd0: csr_rdata_int = (!COREV_PULP ? 'b0 : hart_id_i);
					12'hcd1: csr_rdata_int = (!COREV_PULP ? 'b0 : {30'h00000000, priv_lvl_q});
					12'hcd2: csr_rdata_int = ((FPU == 1) && (ZFINX == 1) ? 32'h00000001 : 32'h00000000);
					default: csr_rdata_int = 1'sb0;
				endcase
			end
		end
	endgenerate
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	generate
		if (PULP_SECURE == 1) begin : gen_pulp_secure_write_logic
			always @(*) begin
				if (_sv2v_0)
					;
				fflags_n = fflags_q;
				frm_n = frm_q;
				mscratch_n = mscratch_q;
				mepc_n = mepc_q;
				uepc_n = uepc_q;
				depc_n = depc_q;
				dcsr_n = dcsr_q;
				dscratch0_n = dscratch0_q;
				dscratch1_n = dscratch1_q;
				mstatus_n = mstatus_q;
				mcause_n = mcause_q;
				ucause_n = ucause_q;
				exception_pc = pc_id_i;
				priv_lvl_n = priv_lvl_q;
				mtvec_n = (csr_mtvec_init_i ? mtvec_addr_i[31:8] : mtvec_q);
				utvec_n = utvec_q;
				mtvec_mode_n = mtvec_mode_q;
				utvec_mode_n = utvec_mode_q;
				pmp_reg_n[767-:512] = pmp_reg_q[767-:512];
				pmp_reg_n[255-:128] = pmp_reg_q[255-:128];
				pmpaddr_we = 1'sb0;
				pmpcfg_we = 1'sb0;
				mie_n = mie_q;
				if (FPU == 1) begin
					if (fflags_we_i)
						fflags_n = fflags_i | fflags_q;
				end
				case (csr_addr_i)
					12'h001:
						if (csr_we_int)
							fflags_n = (FPU == 1 ? csr_wdata_int[4:0] : {5 {1'sb0}});
					12'h002:
						if (csr_we_int)
							frm_n = (FPU == 1 ? csr_wdata_int[2:0] : {3 {1'sb0}});
					12'h003:
						if (csr_we_int) begin
							fflags_n = (FPU == 1 ? csr_wdata_int[4:0] : {5 {1'sb0}});
							frm_n = (FPU == 1 ? csr_wdata_int[7:cv32e40p_pkg_C_FFLAG] : {3 {1'sb0}});
						end
					12'h300:
						if (csr_we_int)
							mstatus_n = {csr_wdata_int[MSTATUS_UIE_BIT], csr_wdata_int[MSTATUS_MIE_BIT], csr_wdata_int[MSTATUS_UPIE_BIT], csr_wdata_int[MSTATUS_MPIE_BIT], sv2v_cast_2(csr_wdata_int[MSTATUS_MPP_BIT_HIGH:MSTATUS_MPP_BIT_LOW]), csr_wdata_int[MSTATUS_MPRV_BIT]};
					12'h304:
						if (csr_we_int)
							mie_n = csr_wdata_int & cv32e40p_pkg_IRQ_MASK;
					12'h305:
						if (csr_we_int) begin
							mtvec_n = csr_wdata_int[31:8];
							mtvec_mode_n = {1'b0, csr_wdata_int[0]};
						end
					12'h340:
						if (csr_we_int)
							mscratch_n = csr_wdata_int;
					12'h341:
						if (csr_we_int)
							mepc_n = csr_wdata_int & ~32'b00000000000000000000000000000001;
					12'h342:
						if (csr_we_int)
							mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
					12'h7b0:
						if (csr_we_int) begin
							dcsr_n[15] = csr_wdata_int[15];
							dcsr_n[13] = 1'b0;
							dcsr_n[12] = csr_wdata_int[12];
							dcsr_n[11] = csr_wdata_int[11];
							dcsr_n[10] = 1'b0;
							dcsr_n[9] = 1'b0;
							dcsr_n[4] = 1'b0;
							dcsr_n[2] = csr_wdata_int[2];
							dcsr_n[1-:2] = (csr_wdata_int[1:0] == 2'b11 ? 2'b11 : 2'b00);
						end
					12'h7b1:
						if (csr_we_int)
							depc_n = csr_wdata_int & ~32'b00000000000000000000000000000001;
					12'h7b2:
						if (csr_we_int)
							dscratch0_n = csr_wdata_int;
					12'h7b3:
						if (csr_we_int)
							dscratch1_n = csr_wdata_int;
					12'h3a0:
						if (csr_we_int) begin
							pmp_reg_n[128+:32] = csr_wdata_int;
							pmpcfg_we[3:0] = 4'b1111;
						end
					12'h3a1:
						if (csr_we_int) begin
							pmp_reg_n[160+:32] = csr_wdata_int;
							pmpcfg_we[7:4] = 4'b1111;
						end
					12'h3a2:
						if (csr_we_int) begin
							pmp_reg_n[192+:32] = csr_wdata_int;
							pmpcfg_we[11:8] = 4'b1111;
						end
					12'h3a3:
						if (csr_we_int) begin
							pmp_reg_n[224+:32] = csr_wdata_int;
							pmpcfg_we[15:12] = 4'b1111;
						end
					12'h3b0, 12'h3b1, 12'h3b2, 12'h3b3, 12'h3b4, 12'h3b5, 12'h3b6, 12'h3b7, 12'h3b8, 12'h3b9, 12'h3ba, 12'h3bb, 12'h3bc, 12'h3bd, 12'h3be, 12'h3bf:
						if (csr_we_int) begin
							pmp_reg_n[256 + (csr_addr_i[3:0] * 32)+:32] = csr_wdata_int;
							pmpaddr_we[csr_addr_i[3:0]] = 1'b1;
						end
					12'h000:
						if (csr_we_int)
							mstatus_n = {csr_wdata_int[MSTATUS_UIE_BIT], mstatus_q[5], csr_wdata_int[MSTATUS_UPIE_BIT], mstatus_q[3], sv2v_cast_2(mstatus_q[2-:2]), mstatus_q[0]};
					12'h005:
						if (csr_we_int) begin
							utvec_n = csr_wdata_int[31:8];
							utvec_mode_n = {1'b0, csr_wdata_int[0]};
						end
					12'h041:
						if (csr_we_int)
							uepc_n = csr_wdata_int;
					12'h042:
						if (csr_we_int)
							ucause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
				endcase
				(* full_case, parallel_case *)
				case (1'b1)
					csr_save_cause_i: begin
						(* full_case, parallel_case *)
						case (1'b1)
							csr_save_if_i: exception_pc = pc_if_i;
							csr_save_id_i: exception_pc = pc_id_i;
							csr_save_ex_i: exception_pc = pc_ex_i;
							default:
								;
						endcase
						(* full_case, parallel_case *)
						case (priv_lvl_q)
							2'b00:
								if (~is_irq) begin
									priv_lvl_n = 2'b11;
									mstatus_n[3] = mstatus_q[6];
									mstatus_n[5] = 1'b0;
									mstatus_n[2-:2] = 2'b00;
									if (debug_csr_save_i)
										depc_n = exception_pc;
									else
										mepc_n = exception_pc;
									mcause_n = csr_cause_i;
								end
								else if (~csr_irq_sec_i) begin
									priv_lvl_n = 2'b00;
									mstatus_n[4] = mstatus_q[6];
									mstatus_n[6] = 1'b0;
									if (debug_csr_save_i)
										depc_n = exception_pc;
									else
										uepc_n = exception_pc;
									ucause_n = csr_cause_i;
								end
								else begin
									priv_lvl_n = 2'b11;
									mstatus_n[3] = mstatus_q[6];
									mstatus_n[5] = 1'b0;
									mstatus_n[2-:2] = 2'b00;
									if (debug_csr_save_i)
										depc_n = exception_pc;
									else
										mepc_n = exception_pc;
									mcause_n = csr_cause_i;
								end
							2'b11:
								if (debug_csr_save_i) begin
									dcsr_n[1-:2] = 2'b11;
									dcsr_n[8-:3] = debug_cause_i;
									depc_n = exception_pc;
								end
								else begin
									priv_lvl_n = 2'b11;
									mstatus_n[3] = mstatus_q[5];
									mstatus_n[5] = 1'b0;
									mstatus_n[2-:2] = 2'b11;
									mepc_n = exception_pc;
									mcause_n = csr_cause_i;
								end
							default:
								;
						endcase
					end
					csr_restore_uret_i: begin
						mstatus_n[6] = mstatus_q[4];
						priv_lvl_n = 2'b00;
						mstatus_n[4] = 1'b1;
					end
					csr_restore_mret_i:
						(* full_case, parallel_case *)
						case (mstatus_q[2-:2])
							2'b00: begin
								mstatus_n[6] = mstatus_q[3];
								priv_lvl_n = 2'b00;
								mstatus_n[3] = 1'b1;
								mstatus_n[2-:2] = 2'b00;
							end
							2'b11: begin
								mstatus_n[5] = mstatus_q[3];
								priv_lvl_n = 2'b11;
								mstatus_n[3] = 1'b1;
								mstatus_n[2-:2] = 2'b00;
							end
							default:
								;
						endcase
					csr_restore_dret_i: priv_lvl_n = dcsr_q[1-:2];
					default:
						;
				endcase
			end
		end
		else begin : gen_no_pulp_secure_write_logic
			always @(*) begin
				if (_sv2v_0)
					;
				if (FPU == 1) begin
					fflags_n = fflags_q;
					frm_n = frm_q;
					if (ZFINX == 0) begin
						mstatus_fs_n = mstatus_fs_q;
						fcsr_update = 1'b0;
					end
				end
				mscratch_n = mscratch_q;
				mepc_n = mepc_q;
				uepc_n = 'b0;
				depc_n = depc_q;
				dcsr_n = dcsr_q;
				dscratch0_n = dscratch0_q;
				dscratch1_n = dscratch1_q;
				mstatus_we_int = 1'b0;
				mstatus_n = mstatus_q;
				mcause_n = mcause_q;
				ucause_n = 1'sb0;
				exception_pc = pc_id_i;
				priv_lvl_n = priv_lvl_q;
				mtvec_n = (csr_mtvec_init_i ? mtvec_addr_i[31:8] : mtvec_q);
				utvec_n = 1'sb0;
				pmp_reg_n[767-:512] = 1'sb0;
				pmp_reg_n[255-:128] = 1'sb0;
				pmp_reg_n[127-:128] = 1'sb0;
				pmpaddr_we = 1'sb0;
				pmpcfg_we = 1'sb0;
				mie_n = mie_q;
				mtvec_mode_n = mtvec_mode_q;
				utvec_mode_n = 1'sb0;
				case (csr_addr_i)
					12'h001:
						if (FPU == 1) begin
							if (csr_we_int) begin
								fflags_n = csr_wdata_int[4:0];
								if (ZFINX == 0)
									fcsr_update = 1'b1;
							end
						end
					12'h002:
						if (FPU == 1) begin
							if (csr_we_int) begin
								frm_n = csr_wdata_int[2:0];
								if (ZFINX == 0)
									fcsr_update = 1'b1;
							end
						end
					12'h003:
						if (FPU == 1) begin
							if (csr_we_int) begin
								fflags_n = csr_wdata_int[4:0];
								frm_n = csr_wdata_int[7:cv32e40p_pkg_C_FFLAG];
								if (ZFINX == 0)
									fcsr_update = 1'b1;
							end
						end
					12'h300:
						if (csr_we_int) begin
							mstatus_n = {csr_wdata_int[MSTATUS_UIE_BIT], csr_wdata_int[MSTATUS_MIE_BIT], csr_wdata_int[MSTATUS_UPIE_BIT], csr_wdata_int[MSTATUS_MPIE_BIT], sv2v_cast_2(csr_wdata_int[MSTATUS_MPP_BIT_HIGH:MSTATUS_MPP_BIT_LOW]), csr_wdata_int[MSTATUS_MPRV_BIT]};
							if ((FPU == 1) && (ZFINX == 0)) begin
								mstatus_we_int = 1'b1;
								mstatus_fs_n = sv2v_cast_2(csr_wdata_int[MSTATUS_FS_BIT_HIGH:MSTATUS_FS_BIT_LOW]);
							end
						end
					12'h304:
						if (csr_we_int)
							mie_n = csr_wdata_int & cv32e40p_pkg_IRQ_MASK;
					12'h305:
						if (csr_we_int) begin
							mtvec_n = csr_wdata_int[31:8];
							mtvec_mode_n = {1'b0, csr_wdata_int[0]};
						end
					12'h340:
						if (csr_we_int)
							mscratch_n = csr_wdata_int;
					12'h341:
						if (csr_we_int)
							mepc_n = csr_wdata_int & ~32'b00000000000000000000000000000001;
					12'h342:
						if (csr_we_int)
							mcause_n = {csr_wdata_int[31], csr_wdata_int[4:0]};
					12'h7b0:
						if (csr_we_int) begin
							dcsr_n[15] = csr_wdata_int[15];
							dcsr_n[13] = 1'b0;
							dcsr_n[12] = 1'b0;
							dcsr_n[11] = csr_wdata_int[11];
							dcsr_n[10] = 1'b0;
							dcsr_n[9] = 1'b0;
							dcsr_n[4] = 1'b0;
							dcsr_n[2] = csr_wdata_int[2];
							dcsr_n[1-:2] = 2'b11;
						end
					12'h7b1:
						if (csr_we_int)
							depc_n = csr_wdata_int & ~32'b00000000000000000000000000000001;
					12'h7b2:
						if (csr_we_int)
							dscratch0_n = csr_wdata_int;
					12'h7b3:
						if (csr_we_int)
							dscratch1_n = csr_wdata_int;
				endcase
				if (FPU == 1) begin
					if (fflags_we_i)
						fflags_n = fflags_i | fflags_q;
					if (ZFINX == 0) begin
						if (((fregs_we_i && !(mstatus_we_int && (mstatus_fs_n != 2'b11))) || fflags_we_i) || fcsr_update)
							mstatus_fs_n = 2'b11;
					end
				end
				(* full_case, parallel_case *)
				case (1'b1)
					csr_save_cause_i: begin
						(* full_case, parallel_case *)
						case (1'b1)
							csr_save_if_i: exception_pc = pc_if_i;
							csr_save_id_i: exception_pc = pc_id_i;
							csr_save_ex_i: exception_pc = pc_ex_i;
							default:
								;
						endcase
						if (debug_csr_save_i) begin
							dcsr_n[1-:2] = 2'b11;
							dcsr_n[8-:3] = debug_cause_i;
							depc_n = exception_pc;
						end
						else begin
							priv_lvl_n = 2'b11;
							mstatus_n[3] = mstatus_q[5];
							mstatus_n[5] = 1'b0;
							mstatus_n[2-:2] = 2'b11;
							mepc_n = exception_pc;
							mcause_n = csr_cause_i;
						end
					end
					csr_restore_mret_i: begin
						mstatus_n[5] = mstatus_q[3];
						priv_lvl_n = 2'b11;
						mstatus_n[3] = 1'b1;
						mstatus_n[2-:2] = 2'b11;
					end
					csr_restore_dret_i: priv_lvl_n = dcsr_q[1-:2];
					default:
						;
				endcase
			end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		csr_wdata_int = csr_wdata_i;
		csr_we_int = 1'b1;
		case (csr_op_i)
			sv2v_cast_8FA4C(2'b01): csr_wdata_int = csr_wdata_i;
			sv2v_cast_8FA4C(2'b10): csr_wdata_int = csr_wdata_i | csr_rdata_o;
			sv2v_cast_8FA4C(2'b11): csr_wdata_int = ~csr_wdata_i & csr_rdata_o;
			sv2v_cast_8FA4C(2'b00): begin
				csr_wdata_int = csr_wdata_i;
				csr_we_int = 1'b0;
			end
		endcase
	end
	assign csr_rdata_o = csr_rdata_int;
	assign m_irq_enable_o = mstatus_q[5] && !(dcsr_q[2] && !dcsr_q[11]);
	assign u_irq_enable_o = mstatus_q[6] && !(dcsr_q[2] && !dcsr_q[11]);
	assign priv_lvl_o = priv_lvl_q;
	assign sec_lvl_o = priv_lvl_q[0];
	assign fs_off_o = ((FPU == 1) && (ZFINX == 0) ? (mstatus_fs_q == 2'b00 ? 1'b1 : 1'b0) : 1'b0);
	assign frm_o = (FPU == 1 ? frm_q : {3 {1'sb0}});
	assign mtvec_o = mtvec_q;
	assign utvec_o = utvec_q;
	assign mtvec_mode_o = mtvec_mode_q;
	assign utvec_mode_o = utvec_mode_q;
	assign mepc_o = mepc_q;
	assign uepc_o = uepc_q;
	assign mcounteren_o = (PULP_SECURE ? mcounteren_q : {32 {1'sb0}});
	assign depc_o = depc_q;
	assign pmp_addr_o = pmp_reg_q[767-:512];
	assign pmp_cfg_o = pmp_reg_q[127-:128];
	assign debug_single_step_o = dcsr_q[2];
	assign debug_ebreakm_o = dcsr_q[15];
	assign debug_ebreaku_o = dcsr_q[12];
	generate
		if (PULP_SECURE == 1) begin : gen_pmp_user
			for (_gv_j_2 = 0; _gv_j_2 < N_PMP_ENTRIES; _gv_j_2 = _gv_j_2 + 1) begin : CS_PMP_CFG
				localparam j = _gv_j_2;
				wire [8:1] sv2v_tmp_D8C4A;
				assign sv2v_tmp_D8C4A = pmp_reg_n[128 + (((j / 4) * 32) + (((8 * ((j % 4) + 1)) - 1) >= (8 * (j % 4)) ? (8 * ((j % 4) + 1)) - 1 : (((8 * ((j % 4) + 1)) - 1) + (((8 * ((j % 4) + 1)) - 1) >= (8 * (j % 4)) ? (((8 * ((j % 4) + 1)) - 1) - (8 * (j % 4))) + 1 : ((8 * (j % 4)) - ((8 * ((j % 4) + 1)) - 1)) + 1)) - 1))-:(((8 * ((j % 4) + 1)) - 1) >= (8 * (j % 4)) ? (((8 * ((j % 4) + 1)) - 1) - (8 * (j % 4))) + 1 : ((8 * (j % 4)) - ((8 * ((j % 4) + 1)) - 1)) + 1)];
				always @(*) pmp_reg_n[0 + (j * 8)+:8] = sv2v_tmp_D8C4A;
				wire [(((8 * ((j % 4) + 1)) - 1) >= (8 * (j % 4)) ? (((8 * ((j % 4) + 1)) - 1) - (8 * (j % 4))) + 1 : ((8 * (j % 4)) - ((8 * ((j % 4) + 1)) - 1)) + 1) * 1:1] sv2v_tmp_55D11;
				assign sv2v_tmp_55D11 = pmp_reg_q[0 + (j * 8)+:8];
				always @(*) pmp_reg_q[128 + (((j / 4) * 32) + (((8 * ((j % 4) + 1)) - 1) >= (8 * (j % 4)) ? (8 * ((j % 4) + 1)) - 1 : (((8 * ((j % 4) + 1)) - 1) + (((8 * ((j % 4) + 1)) - 1) >= (8 * (j % 4)) ? (((8 * ((j % 4) + 1)) - 1) - (8 * (j % 4))) + 1 : ((8 * (j % 4)) - ((8 * ((j % 4) + 1)) - 1)) + 1)) - 1))-:(((8 * ((j % 4) + 1)) - 1) >= (8 * (j % 4)) ? (((8 * ((j % 4) + 1)) - 1) - (8 * (j % 4))) + 1 : ((8 * (j % 4)) - ((8 * ((j % 4) + 1)) - 1)) + 1)] = sv2v_tmp_55D11;
			end
			for (_gv_j_2 = 0; _gv_j_2 < N_PMP_ENTRIES; _gv_j_2 = _gv_j_2 + 1) begin : CS_PMP_REGS_FF
				localparam j = _gv_j_2;
				always @(posedge clk or negedge rst_n)
					if (rst_n == 1'b0) begin
						pmp_reg_q[0 + (j * 8)+:8] <= 1'sb0;
						pmp_reg_q[256 + (j * 32)+:32] <= 1'sb0;
					end
					else begin
						if (pmpcfg_we[j])
							pmp_reg_q[0 + (j * 8)+:8] <= (USE_PMP ? pmp_reg_n[0 + (j * 8)+:8] : {8 {1'sb0}});
						if (pmpaddr_we[j])
							pmp_reg_q[256 + (j * 32)+:32] <= (USE_PMP ? pmp_reg_n[256 + (j * 32)+:32] : {32 {1'sb0}});
					end
			end
			always @(posedge clk or negedge rst_n)
				if (rst_n == 1'b0) begin
					uepc_q <= 1'sb0;
					ucause_q <= 1'sb0;
					utvec_q <= 1'sb0;
					utvec_mode_q <= MTVEC_MODE;
					priv_lvl_q <= 2'b11;
				end
				else begin
					uepc_q <= uepc_n;
					ucause_q <= ucause_n;
					utvec_q <= utvec_n;
					utvec_mode_q <= utvec_mode_n;
					priv_lvl_q <= priv_lvl_n;
				end
		end
		else begin : gen_no_pmp_user
			wire [768:1] sv2v_tmp_465C4;
			assign sv2v_tmp_465C4 = 1'sb0;
			always @(*) pmp_reg_q = sv2v_tmp_465C4;
			wire [32:1] sv2v_tmp_3902D;
			assign sv2v_tmp_3902D = 1'sb0;
			always @(*) uepc_q = sv2v_tmp_3902D;
			wire [6:1] sv2v_tmp_B705E;
			assign sv2v_tmp_B705E = 1'sb0;
			always @(*) ucause_q = sv2v_tmp_B705E;
			wire [24:1] sv2v_tmp_887BD;
			assign sv2v_tmp_887BD = 1'sb0;
			always @(*) utvec_q = sv2v_tmp_887BD;
			wire [2:1] sv2v_tmp_75169;
			assign sv2v_tmp_75169 = 1'sb0;
			always @(*) utvec_mode_q = sv2v_tmp_75169;
			wire [2:1] sv2v_tmp_49C73;
			assign sv2v_tmp_49C73 = 2'b11;
			always @(*) priv_lvl_q = sv2v_tmp_49C73;
		end
	endgenerate
	localparam cv32e40p_pkg_DBG_CAUSE_NONE = 3'h0;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			if (FPU == 1) begin
				frm_q <= 1'sb0;
				fflags_q <= 1'sb0;
				if (ZFINX == 0)
					mstatus_fs_q <= 2'b00;
			end
			mstatus_q <= 7'b0000110;
			mepc_q <= 1'sb0;
			mcause_q <= 1'sb0;
			depc_q <= 1'sb0;
			dcsr_q <= {23'h200000, cv32e40p_pkg_DBG_CAUSE_NONE, 6'b000011};
			dscratch0_q <= 1'sb0;
			dscratch1_q <= 1'sb0;
			mscratch_q <= 1'sb0;
			mie_q <= 1'sb0;
			mtvec_q <= 1'sb0;
			mtvec_mode_q <= MTVEC_MODE;
		end
		else begin
			if (FPU == 1) begin
				frm_q <= frm_n;
				fflags_q <= fflags_n;
				if (ZFINX == 0)
					mstatus_fs_q <= mstatus_fs_n;
			end
			if (PULP_SECURE == 1)
				mstatus_q <= mstatus_n;
			else
				mstatus_q <= {1'b0, mstatus_n[5], 1'b0, mstatus_n[3], 3'b110};
			mepc_q <= mepc_n;
			mcause_q <= mcause_n;
			depc_q <= depc_n;
			dcsr_q <= dcsr_n;
			dscratch0_q <= dscratch0_n;
			dscratch1_q <= dscratch1_n;
			mscratch_q <= mscratch_n;
			mie_q <= mie_n;
			mtvec_q <= mtvec_n;
			mtvec_mode_q <= mtvec_mode_n;
		end
	generate
		if (DEBUG_TRIGGER_EN) begin : gen_trigger_regs
			reg tmatch_control_exec_q;
			reg [31:0] tmatch_value_q;
			wire tmatch_control_we;
			wire tmatch_value_we;
			assign tmatch_control_we = (csr_we_int & debug_mode_i) & (csr_addr_i == 12'h7a1);
			assign tmatch_value_we = (csr_we_int & debug_mode_i) & (csr_addr_i == 12'h7a2);
			always @(posedge clk or negedge rst_n)
				if (!rst_n) begin
					tmatch_control_exec_q <= 'b0;
					tmatch_value_q <= 'b0;
				end
				else begin
					if (tmatch_control_we)
						tmatch_control_exec_q <= csr_wdata_int[2];
					if (tmatch_value_we)
						tmatch_value_q <= csr_wdata_int[31:0];
				end
			assign tinfo_types = 4;
			assign tmatch_control_rdata = {28'h2800104, PULP_SECURE == 1, tmatch_control_exec_q, 2'b00};
			assign tmatch_value_rdata = tmatch_value_q;
			assign trigger_match_o = tmatch_control_exec_q & (pc_id_i[31:0] == tmatch_value_q[31:0]);
		end
		else begin : gen_no_trigger_regs
			assign tinfo_types = 'b0;
			assign tmatch_control_rdata = 'b0;
			assign tmatch_value_rdata = 'b0;
			assign trigger_match_o = 'b0;
		end
	endgenerate
	assign hpm_events[0] = 1'b1;
	assign hpm_events[1] = mhpmevent_minstret_i;
	assign hpm_events[2] = mhpmevent_ld_stall_i;
	assign hpm_events[3] = mhpmevent_jr_stall_i;
	assign hpm_events[4] = mhpmevent_imiss_i;
	assign hpm_events[5] = mhpmevent_load_i;
	assign hpm_events[6] = mhpmevent_store_i;
	assign hpm_events[7] = mhpmevent_jump_i;
	assign hpm_events[8] = mhpmevent_branch_i;
	assign hpm_events[9] = mhpmevent_branch_taken_i;
	assign hpm_events[10] = mhpmevent_compressed_i;
	assign hpm_events[11] = (COREV_CLUSTER ? mhpmevent_pipe_stall_i : 1'b0);
	assign hpm_events[12] = (!APU ? 1'b0 : apu_typeconflict_i && !apu_dep_i);
	assign hpm_events[13] = (!APU ? 1'b0 : apu_contention_i);
	assign hpm_events[14] = (!APU ? 1'b0 : apu_dep_i && !apu_contention_i);
	assign hpm_events[15] = (!APU ? 1'b0 : apu_wb_i);
	wire mcounteren_we;
	wire mcountinhibit_we;
	wire mhpmevent_we;
	assign mcounteren_we = csr_we_int & (csr_addr_i == 12'h306);
	assign mcountinhibit_we = csr_we_int & (csr_addr_i == 12'h320);
	assign mhpmevent_we = csr_we_int & (((((((((((((((((((((((((((((csr_addr_i == 12'h323) || (csr_addr_i == 12'h324)) || (csr_addr_i == 12'h325)) || (csr_addr_i == 12'h326)) || (csr_addr_i == 12'h327)) || (csr_addr_i == 12'h328)) || (csr_addr_i == 12'h329)) || (csr_addr_i == 12'h32a)) || (csr_addr_i == 12'h32b)) || (csr_addr_i == 12'h32c)) || (csr_addr_i == 12'h32d)) || (csr_addr_i == 12'h32e)) || (csr_addr_i == 12'h32f)) || (csr_addr_i == 12'h330)) || (csr_addr_i == 12'h331)) || (csr_addr_i == 12'h332)) || (csr_addr_i == 12'h333)) || (csr_addr_i == 12'h334)) || (csr_addr_i == 12'h335)) || (csr_addr_i == 12'h336)) || (csr_addr_i == 12'h337)) || (csr_addr_i == 12'h338)) || (csr_addr_i == 12'h339)) || (csr_addr_i == 12'h33a)) || (csr_addr_i == 12'h33b)) || (csr_addr_i == 12'h33c)) || (csr_addr_i == 12'h33d)) || (csr_addr_i == 12'h33e)) || (csr_addr_i == 12'h33f));
	genvar _gv_incr_gidx_1;
	generate
		for (_gv_incr_gidx_1 = 0; _gv_incr_gidx_1 < 32; _gv_incr_gidx_1 = _gv_incr_gidx_1 + 1) begin : gen_mhpmcounter_increment
			localparam incr_gidx = _gv_incr_gidx_1;
			assign mhpmcounter_increment[incr_gidx * 64+:64] = mhpmcounter_q[incr_gidx * 64+:64] + 1;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		mcounteren_n = mcounteren_q;
		mcountinhibit_n = mcountinhibit_q;
		mhpmevent_n = mhpmevent_q;
		if (PULP_SECURE && mcounteren_we)
			mcounteren_n = csr_wdata_int;
		if (mcountinhibit_we)
			mcountinhibit_n = csr_wdata_int;
		if (mhpmevent_we)
			mhpmevent_n[csr_addr_i[4:0] * 32+:32] = csr_wdata_int;
	end
	genvar _gv_wcnt_gidx_1;
	generate
		for (_gv_wcnt_gidx_1 = 0; _gv_wcnt_gidx_1 < 32; _gv_wcnt_gidx_1 = _gv_wcnt_gidx_1 + 1) begin : gen_mhpmcounter_write
			localparam wcnt_gidx = _gv_wcnt_gidx_1;
			assign mhpmcounter_write_lower[wcnt_gidx] = csr_we_int && (csr_addr_i == (12'hb00 + wcnt_gidx));
			assign mhpmcounter_write_upper[wcnt_gidx] = ((!mhpmcounter_write_lower[wcnt_gidx] && csr_we_int) && (csr_addr_i == (12'hb80 + wcnt_gidx))) && 1'd1;
			if (!PULP_PERF_COUNTERS) begin : gen_no_pulp_perf_counters
				if (wcnt_gidx == 0) begin : gen_mhpmcounter_mcycle
					assign mhpmcounter_write_increment[wcnt_gidx] = (!mhpmcounter_write_lower[wcnt_gidx] && !mhpmcounter_write_upper[wcnt_gidx]) && !mcountinhibit_q[wcnt_gidx];
				end
				else if (wcnt_gidx == 2) begin : gen_mhpmcounter_minstret
					assign mhpmcounter_write_increment[wcnt_gidx] = ((!mhpmcounter_write_lower[wcnt_gidx] && !mhpmcounter_write_upper[wcnt_gidx]) && !mcountinhibit_q[wcnt_gidx]) && hpm_events[1];
				end
				else if ((wcnt_gidx > 2) && (wcnt_gidx < (NUM_MHPMCOUNTERS + 3))) begin : gen_mhpmcounter
					assign mhpmcounter_write_increment[wcnt_gidx] = ((!mhpmcounter_write_lower[wcnt_gidx] && !mhpmcounter_write_upper[wcnt_gidx]) && !mcountinhibit_q[wcnt_gidx]) && |(hpm_events & mhpmevent_q[(wcnt_gidx * 32) + 15-:16]);
				end
				else begin : gen_mhpmcounter_not_implemented
					assign mhpmcounter_write_increment[wcnt_gidx] = 1'b0;
				end
			end
			else begin : gen_pulp_perf_counters
				assign mhpmcounter_write_increment[wcnt_gidx] = ((!mhpmcounter_write_lower[wcnt_gidx] && !mhpmcounter_write_upper[wcnt_gidx]) && !mcountinhibit_q[wcnt_gidx]) && |(hpm_events & mhpmevent_q[(wcnt_gidx * 32) + 15-:16]);
			end
		end
	endgenerate
	genvar _gv_cnt_gidx_1;
	generate
		integer cnt_gidx;

		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) begin
				mhpmcounter_q <= 0;
			end else begin
				mhpmcounter_d = mhpmcounter_q;

				for (cnt_gidx = 0; cnt_gidx < 32; cnt_gidx = cnt_gidx + 1) begin
					if ((cnt_gidx == 1) || (cnt_gidx >= (NUM_MHPMCOUNTERS + 3))) begin

						mhpmcounter_d[cnt_gidx*64 +: 64] = 64'b0;
					end else begin

						if (mhpmcounter_write_lower[cnt_gidx])
							mhpmcounter_d[cnt_gidx*64 + 31 -: 32] = csr_wdata_int;
						else if (mhpmcounter_write_upper[cnt_gidx])
							mhpmcounter_d[cnt_gidx*64 + 63 -: 32] = csr_wdata_int;
						else if (mhpmcounter_write_increment[cnt_gidx])
							mhpmcounter_d[cnt_gidx*64 +: 64] = mhpmcounter_increment[cnt_gidx*64 +: 64];
					end
				end

				mhpmcounter_q <= mhpmcounter_d;
			end
		end
	endgenerate
	genvar _gv_evt_gidx_1;
	generate
		integer evt_gidx;

		always @(posedge clk or negedge rst_n) begin
			if (!rst_n) begin
				mhpmevent_q <= 0;
			end else begin
				// копируем текущее состояние
				mhpmevent_d = mhpmevent_q;

				for (evt_gidx = 0; evt_gidx < NUM_MHPMCOUNTERS; evt_gidx = evt_gidx + 1) begin
					if (evt_gidx < 3 || evt_gidx >= (NUM_MHPMCOUNTERS + 3)) begin
						// non-implemented: зануляем все 32 бита
						mhpmevent_d[evt_gidx*32 + 31 -: 32] = 32'b0;
					end else begin
						// implemented: младшие 16 бит зануляем
						mhpmevent_d[evt_gidx*32 + 15 -: 16] = 16'b0;
						// старшие 16 бит остаются без изменений
						mhpmevent_d[evt_gidx*32 + 31 -: 16] = mhpmevent_q[evt_gidx*32 + 31 -: 16];
					end
				end

				// обновляем регистр один раз
				mhpmevent_q <= mhpmevent_d;
			end
		end
	endgenerate
	genvar _gv_en_gidx_1;
	generate
		for (_gv_en_gidx_1 = 0; _gv_en_gidx_1 < 32; _gv_en_gidx_1 = _gv_en_gidx_1 + 1) begin : gen_mcounteren
			localparam en_gidx = _gv_en_gidx_1;
			if (((PULP_SECURE == 0) || (en_gidx == 1)) || (en_gidx >= (NUM_MHPMCOUNTERS + 3))) begin : gen_non_implemented
				wire [1:1] sv2v_tmp_F00BA;
				assign sv2v_tmp_F00BA = 'b0;
				always @(*) mcounteren_q[en_gidx] = sv2v_tmp_F00BA;
			end
			else begin : gen_implemented
				always @(posedge clk or negedge rst_n)
					if (!rst_n)
						mcounteren_q[en_gidx] <= 'b0;
					else
						mcounteren_q[en_gidx] <= mcounteren_n[en_gidx];
			end
		end
	endgenerate
	genvar _gv_inh_gidx_1;
	generate
		for (_gv_inh_gidx_1 = 0; _gv_inh_gidx_1 < 32; _gv_inh_gidx_1 = _gv_inh_gidx_1 + 1) begin : gen_mcountinhibit
			localparam inh_gidx = _gv_inh_gidx_1;
			always @(posedge clk or negedge rst_n) begin
				if (!rst_n)
					mcountinhibit_q[inh_gidx] <= (inh_gidx == 1 || inh_gidx >= (NUM_MHPMCOUNTERS + 3)) ? 1'b0 : 1'b1;
				else
					if (!(inh_gidx == 1 || inh_gidx >= (NUM_MHPMCOUNTERS + 3)))
						mcountinhibit_q[inh_gidx] <= mcountinhibit_n[inh_gidx];
					else
						mcountinhibit_q[inh_gidx] <= 1'b0;
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_decoder (
	deassert_we_i,
	illegal_insn_o,
	ebrk_insn_o,
	mret_insn_o,
	uret_insn_o,
	dret_insn_o,
	mret_dec_o,
	uret_dec_o,
	dret_dec_o,
	ecall_insn_o,
	wfi_o,
	fencei_insn_o,
	rega_used_o,
	regb_used_o,
	regc_used_o,
	reg_fp_a_o,
	reg_fp_b_o,
	reg_fp_c_o,
	reg_fp_d_o,
	bmask_a_mux_o,
	bmask_b_mux_o,
	alu_bmask_a_mux_sel_o,
	alu_bmask_b_mux_sel_o,
	instr_rdata_i,
	illegal_c_insn_i,
	alu_en_o,
	alu_operator_o,
	alu_op_a_mux_sel_o,
	alu_op_b_mux_sel_o,
	alu_op_c_mux_sel_o,
	alu_vec_o,
	alu_vec_mode_o,
	scalar_replication_o,
	scalar_replication_c_o,
	imm_a_mux_sel_o,
	imm_b_mux_sel_o,
	regc_mux_o,
	is_clpx_o,
	is_subrot_o,
	mult_operator_o,
	mult_int_en_o,
	mult_dot_en_o,
	mult_imm_mux_o,
	mult_sel_subword_o,
	mult_signed_mode_o,
	mult_dot_signed_o,
	fs_off_i,
	frm_i,
	fpu_dst_fmt_o,
	fpu_src_fmt_o,
	fpu_int_fmt_o,
	apu_en_o,
	apu_op_o,
	apu_lat_o,
	fp_rnd_mode_o,
	regfile_mem_we_o,
	regfile_alu_we_o,
	regfile_alu_we_dec_o,
	regfile_alu_waddr_sel_o,
	csr_access_o,
	csr_status_o,
	csr_op_o,
	current_priv_lvl_i,
	data_req_o,
	data_we_o,
	prepost_useincr_o,
	data_type_o,
	data_sign_extension_o,
	data_reg_offset_o,
	data_load_event_o,
	atop_o,
	hwlp_we_o,
	hwlp_target_mux_sel_o,
	hwlp_start_mux_sel_o,
	hwlp_cnt_mux_sel_o,
	debug_mode_i,
	debug_wfi_no_sleep_i,
	ctrl_transfer_insn_in_dec_o,
	ctrl_transfer_insn_in_id_o,
	ctrl_transfer_target_mux_sel_o,
	mcounteren_i
);
	reg _sv2v_0;
	parameter COREV_PULP = 1;
	parameter COREV_CLUSTER = 0;
	parameter A_EXTENSION = 0;
	parameter FPU = 0;
	parameter FPU_ADDMUL_LAT = 0;
	parameter FPU_OTHERS_LAT = 0;
	parameter ZFINX = 0;
	parameter PULP_SECURE = 0;
	parameter USE_PMP = 0;
	parameter APU_WOP_CPU = 6;
	parameter DEBUG_TRIGGER_EN = 1;
	input wire deassert_we_i;
	output reg illegal_insn_o;
	output reg ebrk_insn_o;
	output reg mret_insn_o;
	output reg uret_insn_o;
	output reg dret_insn_o;
	output reg mret_dec_o;
	output reg uret_dec_o;
	output reg dret_dec_o;
	output reg ecall_insn_o;
	output reg wfi_o;
	output reg fencei_insn_o;
	output reg rega_used_o;
	output reg regb_used_o;
	output reg regc_used_o;
	output reg reg_fp_a_o;
	output reg reg_fp_b_o;
	output reg reg_fp_c_o;
	output reg reg_fp_d_o;
	output reg [0:0] bmask_a_mux_o;
	output reg [1:0] bmask_b_mux_o;
	output reg alu_bmask_a_mux_sel_o;
	output reg alu_bmask_b_mux_sel_o;
	input wire [31:0] instr_rdata_i;
	input wire illegal_c_insn_i;
	output wire alu_en_o;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	output reg [6:0] alu_operator_o;
	output reg [2:0] alu_op_a_mux_sel_o;
	output reg [2:0] alu_op_b_mux_sel_o;
	output reg [1:0] alu_op_c_mux_sel_o;
	output reg alu_vec_o;
	output reg [1:0] alu_vec_mode_o;
	output reg scalar_replication_o;
	output reg scalar_replication_c_o;
	output reg [0:0] imm_a_mux_sel_o;
	output reg [3:0] imm_b_mux_sel_o;
	output reg [1:0] regc_mux_o;
	output reg is_clpx_o;
	output reg is_subrot_o;
	localparam cv32e40p_pkg_MUL_OP_WIDTH = 3;
	output reg [2:0] mult_operator_o;
	output wire mult_int_en_o;
	output wire mult_dot_en_o;
	output reg [0:0] mult_imm_mux_o;
	output reg mult_sel_subword_o;
	output reg [1:0] mult_signed_mode_o;
	output reg [1:0] mult_dot_signed_o;
	input wire fs_off_i;
	localparam cv32e40p_pkg_C_RM = 3;
	input wire [2:0] frm_i;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] cv32e40p_fpu_pkg_FP_FORMAT_BITS = 3;
	output reg [2:0] fpu_dst_fmt_o;
	output reg [2:0] fpu_src_fmt_o;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_INT_FORMATS = 4;
	localparam [31:0] cv32e40p_fpu_pkg_INT_FORMAT_BITS = 2;
	output reg [1:0] fpu_int_fmt_o;
	output wire apu_en_o;
	output reg [APU_WOP_CPU - 1:0] apu_op_o;
	output reg [1:0] apu_lat_o;
	output reg [2:0] fp_rnd_mode_o;
	output wire regfile_mem_we_o;
	output wire regfile_alu_we_o;
	output wire regfile_alu_we_dec_o;
	output reg regfile_alu_waddr_sel_o;
	output reg csr_access_o;
	output reg csr_status_o;
	localparam cv32e40p_pkg_CSR_OP_WIDTH = 2;
	output wire [1:0] csr_op_o;
	input wire [1:0] current_priv_lvl_i;
	output wire data_req_o;
	output reg data_we_o;
	output reg prepost_useincr_o;
	output reg [1:0] data_type_o;
	output reg [1:0] data_sign_extension_o;
	output reg [1:0] data_reg_offset_o;
	output reg data_load_event_o;
	output reg [5:0] atop_o;
	output wire [2:0] hwlp_we_o;
	output reg [1:0] hwlp_target_mux_sel_o;
	output reg [1:0] hwlp_start_mux_sel_o;
	output reg hwlp_cnt_mux_sel_o;
	input wire debug_mode_i;
	input wire debug_wfi_no_sleep_i;
	output wire [1:0] ctrl_transfer_insn_in_dec_o;
	output wire [1:0] ctrl_transfer_insn_in_id_o;
	output reg [1:0] ctrl_transfer_target_mux_sel_o;
	input wire [31:0] mcounteren_i;
	reg regfile_mem_we;
	reg regfile_alu_we;
	reg data_req;
	reg [2:0] hwlp_we;
	reg csr_illegal;
	reg [1:0] ctrl_transfer_insn;
	reg [1:0] csr_op;
	reg alu_en;
	reg mult_int_en;
	reg mult_dot_en;
	reg apu_en;
	reg check_fprm;
	localparam [31:0] cv32e40p_fpu_pkg_OP_BITS = 4;
	reg [3:0] fpu_op;
	reg fpu_op_mod;
	reg fpu_vec_op;
	reg [1:0] fp_op_group;
	localparam cv32e40p_pkg_AMO_ADD = 5'b00000;
	localparam cv32e40p_pkg_AMO_AND = 5'b01100;
	localparam cv32e40p_pkg_AMO_LR = 5'b00010;
	localparam cv32e40p_pkg_AMO_MAX = 5'b10100;
	localparam cv32e40p_pkg_AMO_MAXU = 5'b11100;
	localparam cv32e40p_pkg_AMO_MIN = 5'b10000;
	localparam cv32e40p_pkg_AMO_MINU = 5'b11000;
	localparam cv32e40p_pkg_AMO_OR = 5'b01000;
	localparam cv32e40p_pkg_AMO_SC = 5'b00011;
	localparam cv32e40p_pkg_AMO_SWAP = 5'b00001;
	localparam cv32e40p_pkg_AMO_XOR = 5'b00100;
	localparam cv32e40p_pkg_BMASK_A_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_REG = 1'b0;
	localparam cv32e40p_pkg_BMASK_A_S3 = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_ZERO = 1'b0;
	localparam cv32e40p_pkg_BMASK_B_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_B_ONE = 2'b11;
	localparam cv32e40p_pkg_BMASK_B_REG = 1'b0;
	localparam cv32e40p_pkg_BMASK_B_S2 = 2'b00;
	localparam cv32e40p_pkg_BMASK_B_S3 = 2'b01;
	localparam cv32e40p_pkg_BMASK_B_ZERO = 2'b10;
	localparam cv32e40p_pkg_BRANCH_COND = 2'b11;
	localparam cv32e40p_pkg_BRANCH_JAL = 2'b01;
	localparam cv32e40p_pkg_BRANCH_JALR = 2'b10;
	localparam cv32e40p_pkg_BRANCH_NONE = 2'b00;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP16 = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP16ALT = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP64 = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP8 = 'd0;
	localparam [0:0] cv32e40p_pkg_C_RVD = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_RVF = 1'b1;
	localparam [0:0] cv32e40p_pkg_C_XF16 = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XF16ALT = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XF8 = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XFVEC = 1'b0;
	localparam cv32e40p_pkg_IMMA_Z = 1'b0;
	localparam cv32e40p_pkg_IMMA_ZERO = 1'b1;
	localparam cv32e40p_pkg_IMMB_BI = 4'b1011;
	localparam cv32e40p_pkg_IMMB_CLIP = 4'b1001;
	localparam cv32e40p_pkg_IMMB_I = 4'b0000;
	localparam cv32e40p_pkg_IMMB_PCINCR = 4'b0011;
	localparam cv32e40p_pkg_IMMB_S = 4'b0001;
	localparam cv32e40p_pkg_IMMB_S2 = 4'b0100;
	localparam cv32e40p_pkg_IMMB_SHUF = 4'b1000;
	localparam cv32e40p_pkg_IMMB_U = 4'b0010;
	localparam cv32e40p_pkg_IMMB_VS = 4'b0110;
	localparam cv32e40p_pkg_IMMB_VU = 4'b0111;
	localparam cv32e40p_pkg_JT_COND = 2'b11;
	localparam cv32e40p_pkg_JT_JAL = 2'b01;
	localparam cv32e40p_pkg_JT_JALR = 2'b10;
	localparam cv32e40p_pkg_MIMM_S3 = 1'b1;
	localparam cv32e40p_pkg_MIMM_ZERO = 1'b0;
	localparam cv32e40p_pkg_OPCODE_AMO = 7'h2f;
	localparam cv32e40p_pkg_OPCODE_AUIPC = 7'h17;
	localparam cv32e40p_pkg_OPCODE_BRANCH = 7'h63;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_0 = 7'h0b;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_1 = 7'h2b;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_2 = 7'h5b;
	localparam cv32e40p_pkg_OPCODE_CUSTOM_3 = 7'h7b;
	localparam cv32e40p_pkg_OPCODE_FENCE = 7'h0f;
	localparam cv32e40p_pkg_OPCODE_JAL = 7'h6f;
	localparam cv32e40p_pkg_OPCODE_JALR = 7'h67;
	localparam cv32e40p_pkg_OPCODE_LOAD = 7'h03;
	localparam cv32e40p_pkg_OPCODE_LOAD_FP = 7'h07;
	localparam cv32e40p_pkg_OPCODE_LUI = 7'h37;
	localparam cv32e40p_pkg_OPCODE_OP = 7'h33;
	localparam cv32e40p_pkg_OPCODE_OPIMM = 7'h13;
	localparam cv32e40p_pkg_OPCODE_OP_FMADD = 7'h43;
	localparam cv32e40p_pkg_OPCODE_OP_FMSUB = 7'h47;
	localparam cv32e40p_pkg_OPCODE_OP_FNMADD = 7'h4f;
	localparam cv32e40p_pkg_OPCODE_OP_FNMSUB = 7'h4b;
	localparam cv32e40p_pkg_OPCODE_OP_FP = 7'h53;
	localparam cv32e40p_pkg_OPCODE_STORE = 7'h23;
	localparam cv32e40p_pkg_OPCODE_STORE_FP = 7'h27;
	localparam cv32e40p_pkg_OPCODE_SYSTEM = 7'h73;
	localparam cv32e40p_pkg_OP_A_CURRPC = 3'b001;
	localparam cv32e40p_pkg_OP_A_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_A_REGA_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_A_REGB_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_A_REGC_OR_FWD = 3'b100;
	localparam cv32e40p_pkg_OP_B_BMASK = 3'b100;
	localparam cv32e40p_pkg_OP_B_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_B_REGA_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_B_REGB_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_B_REGC_OR_FWD = 3'b001;
	localparam cv32e40p_pkg_OP_C_JT = 2'b10;
	localparam cv32e40p_pkg_OP_C_REGB_OR_FWD = 2'b01;
	localparam cv32e40p_pkg_OP_C_REGC_OR_FWD = 2'b00;
	localparam cv32e40p_pkg_REGC_RD = 2'b01;
	localparam cv32e40p_pkg_REGC_S4 = 2'b00;
	localparam cv32e40p_pkg_REGC_ZERO = 2'b11;
	localparam cv32e40p_pkg_VEC_MODE16 = 2'b10;
	localparam cv32e40p_pkg_VEC_MODE32 = 2'b00;
	localparam cv32e40p_pkg_VEC_MODE8 = 2'b11;
	function automatic [6:0] sv2v_cast_81146;
		input reg [6:0] inp;
		sv2v_cast_81146 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_F9F94;
		input reg [2:0] inp;
		sv2v_cast_F9F94 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_FEEA0;
		input reg [3:0] inp;
		sv2v_cast_FEEA0 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_8141C;
		input reg [2:0] inp;
		sv2v_cast_8141C = inp;
	endfunction
	function automatic [1:0] sv2v_cast_4EB16;
		input reg [1:0] inp;
		sv2v_cast_4EB16 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_8FA4C;
		input reg [1:0] inp;
		sv2v_cast_8FA4C = inp;
	endfunction
	always @(*) begin : instruction_decoder
		if (_sv2v_0)
			;
		ctrl_transfer_insn = cv32e40p_pkg_BRANCH_NONE;
		ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_JAL;
		alu_en = 1'b1;
		alu_operator_o = sv2v_cast_81146(7'b0000011);
		alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGA_OR_FWD;
		alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
		alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGC_OR_FWD;
		alu_vec_o = 1'b0;
		alu_vec_mode_o = cv32e40p_pkg_VEC_MODE32;
		scalar_replication_o = 1'b0;
		scalar_replication_c_o = 1'b0;
		regc_mux_o = cv32e40p_pkg_REGC_ZERO;
		imm_a_mux_sel_o = cv32e40p_pkg_IMMA_ZERO;
		imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
		mult_int_en = 1'b0;
		mult_dot_en = 1'b0;
		mult_operator_o = sv2v_cast_F9F94(3'b010);
		mult_imm_mux_o = cv32e40p_pkg_MIMM_ZERO;
		mult_signed_mode_o = 2'b00;
		mult_sel_subword_o = 1'b0;
		mult_dot_signed_o = 2'b00;
		apu_en = 1'b0;
		apu_op_o = 1'sb0;
		apu_lat_o = 1'sb0;
		fp_rnd_mode_o = 1'sb0;
		fpu_op = sv2v_cast_FEEA0(6);
		fpu_op_mod = 1'b0;
		fpu_vec_op = 1'b0;
		fpu_dst_fmt_o = sv2v_cast_8141C('d0);
		fpu_src_fmt_o = sv2v_cast_8141C('d0);
		fpu_int_fmt_o = sv2v_cast_4EB16(2);
		check_fprm = 1'b0;
		fp_op_group = 2'd0;
		regfile_mem_we = 1'b0;
		regfile_alu_we = 1'b0;
		regfile_alu_waddr_sel_o = 1'b1;
		prepost_useincr_o = 1'b1;
		hwlp_we = 3'b000;
		hwlp_target_mux_sel_o = 2'b00;
		hwlp_start_mux_sel_o = 2'b00;
		hwlp_cnt_mux_sel_o = 1'b0;
		csr_access_o = 1'b0;
		csr_status_o = 1'b0;
		csr_illegal = 1'b0;
		csr_op = sv2v_cast_8FA4C(2'b00);
		mret_insn_o = 1'b0;
		uret_insn_o = 1'b0;
		dret_insn_o = 1'b0;
		data_we_o = 1'b0;
		data_type_o = 2'b00;
		data_sign_extension_o = 2'b00;
		data_reg_offset_o = 2'b00;
		data_req = 1'b0;
		data_load_event_o = 1'b0;
		atop_o = 6'b000000;
		illegal_insn_o = 1'b0;
		ebrk_insn_o = 1'b0;
		ecall_insn_o = 1'b0;
		wfi_o = 1'b0;
		fencei_insn_o = 1'b0;
		rega_used_o = 1'b0;
		regb_used_o = 1'b0;
		regc_used_o = 1'b0;
		reg_fp_a_o = 1'b0;
		reg_fp_b_o = 1'b0;
		reg_fp_c_o = 1'b0;
		reg_fp_d_o = 1'b0;
		bmask_a_mux_o = cv32e40p_pkg_BMASK_A_ZERO;
		bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
		alu_bmask_a_mux_sel_o = cv32e40p_pkg_BMASK_A_IMM;
		alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_IMM;
		is_clpx_o = 1'b0;
		is_subrot_o = 1'b0;
		mret_dec_o = 1'b0;
		uret_dec_o = 1'b0;
		dret_dec_o = 1'b0;
		(* full_case, parallel_case *)
		case (instr_rdata_i[6:0])
			cv32e40p_pkg_OPCODE_JAL: begin
				ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_JAL;
				ctrl_transfer_insn = cv32e40p_pkg_BRANCH_JAL;
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_CURRPC;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_PCINCR;
				alu_operator_o = sv2v_cast_81146(7'b0011000);
				regfile_alu_we = 1'b1;
			end
			cv32e40p_pkg_OPCODE_JALR: begin
				ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_JALR;
				ctrl_transfer_insn = cv32e40p_pkg_BRANCH_JALR;
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_CURRPC;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_PCINCR;
				alu_operator_o = sv2v_cast_81146(7'b0011000);
				regfile_alu_we = 1'b1;
				rega_used_o = 1'b1;
				if (instr_rdata_i[14:12] != 3'b000) begin
					ctrl_transfer_insn = cv32e40p_pkg_BRANCH_NONE;
					regfile_alu_we = 1'b0;
					illegal_insn_o = 1'b1;
				end
			end
			cv32e40p_pkg_OPCODE_BRANCH: begin
				ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_COND;
				ctrl_transfer_insn = cv32e40p_pkg_BRANCH_COND;
				alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_JT;
				rega_used_o = 1'b1;
				regb_used_o = 1'b1;
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: alu_operator_o = sv2v_cast_81146(7'b0001100);
					3'b001: alu_operator_o = sv2v_cast_81146(7'b0001101);
					3'b100: alu_operator_o = sv2v_cast_81146(7'b0000000);
					3'b101: alu_operator_o = sv2v_cast_81146(7'b0001010);
					3'b110: alu_operator_o = sv2v_cast_81146(7'b0000001);
					3'b111: alu_operator_o = sv2v_cast_81146(7'b0001011);
					default: illegal_insn_o = 1'b1;
				endcase
			end
			cv32e40p_pkg_OPCODE_STORE: begin
				data_req = 1'b1;
				data_we_o = 1'b1;
				rega_used_o = 1'b1;
				regb_used_o = 1'b1;
				alu_operator_o = sv2v_cast_81146(7'b0011000);
				alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: data_type_o = 2'b10;
					3'b001: data_type_o = 2'b01;
					3'b010: data_type_o = 2'b00;
					default: begin
						illegal_insn_o = 1'b1;
						data_req = 1'b0;
						data_we_o = 1'b0;
					end
				endcase
			end
			cv32e40p_pkg_OPCODE_LOAD: begin
				data_req = 1'b1;
				regfile_mem_we = 1'b1;
				rega_used_o = 1'b1;
				alu_operator_o = sv2v_cast_81146(7'b0011000);
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
				data_sign_extension_o = {1'b0, ~instr_rdata_i[14]};
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000, 3'b100: data_type_o = 2'b10;
					3'b001, 3'b101: data_type_o = 2'b01;
					3'b010: data_type_o = 2'b00;
					default: illegal_insn_o = 1'b1;
				endcase
			end
			cv32e40p_pkg_OPCODE_AMO:
				if (A_EXTENSION) begin : decode_amo
					if (instr_rdata_i[14:12] == 3'b010) begin
						data_req = 1'b1;
						data_type_o = 2'b00;
						rega_used_o = 1'b1;
						regb_used_o = 1'b1;
						regfile_mem_we = 1'b1;
						prepost_useincr_o = 1'b0;
						alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGA_OR_FWD;
						data_sign_extension_o = 1'b1;
						atop_o = {1'b1, instr_rdata_i[31:27]};
						(* full_case, parallel_case *)
						case (instr_rdata_i[31:27])
							cv32e40p_pkg_AMO_LR: data_we_o = 1'b0;
							cv32e40p_pkg_AMO_SC, cv32e40p_pkg_AMO_SWAP, cv32e40p_pkg_AMO_ADD, cv32e40p_pkg_AMO_XOR, cv32e40p_pkg_AMO_AND, cv32e40p_pkg_AMO_OR, cv32e40p_pkg_AMO_MIN, cv32e40p_pkg_AMO_MAX, cv32e40p_pkg_AMO_MINU, cv32e40p_pkg_AMO_MAXU: begin
								data_we_o = 1'b1;
								alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							end
							default: illegal_insn_o = 1'b1;
						endcase
					end
					else
						illegal_insn_o = 1'b1;
				end
				else begin : no_decode_amo
					illegal_insn_o = 1'b1;
				end
			cv32e40p_pkg_OPCODE_LUI: begin
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_IMM;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_a_mux_sel_o = cv32e40p_pkg_IMMA_ZERO;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_U;
				alu_operator_o = sv2v_cast_81146(7'b0011000);
				regfile_alu_we = 1'b1;
			end
			cv32e40p_pkg_OPCODE_AUIPC: begin
				alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_CURRPC;
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_U;
				alu_operator_o = sv2v_cast_81146(7'b0011000);
				regfile_alu_we = 1'b1;
			end
			cv32e40p_pkg_OPCODE_OPIMM: begin
				alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
				imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
				regfile_alu_we = 1'b1;
				rega_used_o = 1'b1;
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: alu_operator_o = sv2v_cast_81146(7'b0011000);
					3'b010: alu_operator_o = sv2v_cast_81146(7'b0000010);
					3'b011: alu_operator_o = sv2v_cast_81146(7'b0000011);
					3'b100: alu_operator_o = sv2v_cast_81146(7'b0101111);
					3'b110: alu_operator_o = sv2v_cast_81146(7'b0101110);
					3'b111: alu_operator_o = sv2v_cast_81146(7'b0010101);
					3'b001: begin
						alu_operator_o = sv2v_cast_81146(7'b0100111);
						if (instr_rdata_i[31:25] != 7'b0000000)
							illegal_insn_o = 1'b1;
					end
					3'b101:
						if (instr_rdata_i[31:25] == 7'b0000000)
							alu_operator_o = sv2v_cast_81146(7'b0100101);
						else if (instr_rdata_i[31:25] == 7'b0100000)
							alu_operator_o = sv2v_cast_81146(7'b0100100);
						else
							illegal_insn_o = 1'b1;
				endcase
			end
			cv32e40p_pkg_OPCODE_OP:
				if (instr_rdata_i[31:30] == 2'b11)
					illegal_insn_o = 1'b1;
				else if (instr_rdata_i[31:30] == 2'b10) begin
					if (instr_rdata_i[29:25] == 5'b00000)
						illegal_insn_o = 1'b1;
					else if ((FPU == 1) && 1'd0) begin
						alu_en = 1'b0;
						apu_en = 1'b1;
						rega_used_o = 1'b1;
						regb_used_o = 1'b1;
						if (ZFINX == 0) begin
							reg_fp_a_o = 1'b1;
							reg_fp_b_o = 1'b1;
							reg_fp_d_o = 1'b1;
						end
						else begin
							reg_fp_a_o = 1'b0;
							reg_fp_b_o = 1'b0;
							reg_fp_d_o = 1'b0;
						end
						fpu_vec_op = 1'b1;
						scalar_replication_o = instr_rdata_i[14];
						check_fprm = 1'b1;
						fp_rnd_mode_o = frm_i;
						(* full_case, parallel_case *)
						case (instr_rdata_i[13:12])
							2'b00: begin
								fpu_dst_fmt_o = sv2v_cast_8141C('d0);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE32;
							end
							2'b01: begin
								fpu_dst_fmt_o = sv2v_cast_8141C('d4);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
							end
							2'b10: begin
								fpu_dst_fmt_o = sv2v_cast_8141C('d2);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
							end
							2'b11: begin
								fpu_dst_fmt_o = sv2v_cast_8141C('d3);
								alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
							end
						endcase
						fpu_src_fmt_o = fpu_dst_fmt_o;
						(* full_case, parallel_case *)
						if (instr_rdata_i[29:25] == 5'b00001) begin
							fpu_op = sv2v_cast_FEEA0(2);
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							scalar_replication_o = 1'b0;
							scalar_replication_c_o = instr_rdata_i[14];
						end
						else if (instr_rdata_i[29:25] == 5'b00010) begin
							fpu_op = sv2v_cast_FEEA0(2);
							fpu_op_mod = 1'b1;
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							scalar_replication_o = 1'b0;
							scalar_replication_c_o = instr_rdata_i[14];
						end
						else if (instr_rdata_i[29:25] == 5'b00011) begin
							fpu_op = sv2v_cast_FEEA0(3);
							fp_op_group = 2'd0;
						end
						else if (instr_rdata_i[29:25] == 5'b00100) begin
							fpu_op = sv2v_cast_FEEA0(4);
							fp_op_group = 2'd1;
						end
						else if (instr_rdata_i[29:25] == 5'b00101) begin
							fpu_op = sv2v_cast_FEEA0(7);
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b00110) begin
							fpu_op = sv2v_cast_FEEA0(7);
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b00111) begin
							regb_used_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(5);
							fp_op_group = 2'd1;
							if ((instr_rdata_i[24:20] != 5'b00000) || instr_rdata_i[14])
								illegal_insn_o = 1'b1;
						end
						else if (instr_rdata_i[29:25] == 5'b01000) begin
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (ZFINX == 0)
								reg_fp_c_o = 1'b1;
							else
								reg_fp_c_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(0);
							fp_op_group = 2'd0;
						end
						else if (instr_rdata_i[29:25] == 5'b01001) begin
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (ZFINX == 0)
								reg_fp_c_o = 1'b1;
							else
								reg_fp_c_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(0);
							fpu_op_mod = 1'b1;
							fp_op_group = 2'd0;
						end
						else if (instr_rdata_i[29:25] == 5'b01100) begin
							regb_used_o = 1'b0;
							scalar_replication_o = 1'b0;
							(* full_case, parallel_case *)
							if (instr_rdata_i[24:20] == 5'b00000) begin
								alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
								fpu_op = sv2v_cast_FEEA0(6);
								fp_rnd_mode_o = 3'b011;
								fp_op_group = 2'd2;
								check_fprm = 1'b0;
								if (instr_rdata_i[14]) begin
									reg_fp_a_o = 1'b0;
									fpu_op_mod = 1'b0;
								end
								else begin
									reg_fp_d_o = 1'b0;
									fpu_op_mod = 1'b1;
								end
							end
							else if (instr_rdata_i[24:20] == 5'b00001) begin
								reg_fp_d_o = 1'b0;
								fpu_op = sv2v_cast_FEEA0(9);
								fp_rnd_mode_o = 3'b000;
								fp_op_group = 2'd2;
								check_fprm = 1'b0;
								if (instr_rdata_i[14])
									illegal_insn_o = 1'b1;
							end
							else if ((instr_rdata_i[24:20] | 5'b00001) == 5'b00011) begin
								fp_op_group = 2'd3;
								fpu_op_mod = instr_rdata_i[14];
								(* full_case, parallel_case *)
								case (instr_rdata_i[13:12])
									2'b00: fpu_int_fmt_o = sv2v_cast_4EB16(2);
									2'b01, 2'b10: fpu_int_fmt_o = sv2v_cast_4EB16(1);
									2'b11: fpu_int_fmt_o = sv2v_cast_4EB16(0);
								endcase
								if (instr_rdata_i[20]) begin
									reg_fp_a_o = 1'b0;
									fpu_op = sv2v_cast_FEEA0(12);
								end
								else begin
									reg_fp_d_o = 1'b0;
									fpu_op = sv2v_cast_FEEA0(11);
								end
							end
							else if ((instr_rdata_i[24:20] | 5'b00011) == 5'b00111) begin
								fpu_op = sv2v_cast_FEEA0(10);
								fp_op_group = 2'd3;
								(* full_case, parallel_case *)
								case (instr_rdata_i[21:20])
									2'b00: begin
										fpu_src_fmt_o = sv2v_cast_8141C('d0);
										if (~cv32e40p_pkg_C_RVF)
											illegal_insn_o = 1'b1;
									end
									2'b01: begin
										fpu_src_fmt_o = sv2v_cast_8141C('d4);
										if (~cv32e40p_pkg_C_XF16ALT)
											illegal_insn_o = 1'b1;
									end
									2'b10: begin
										fpu_src_fmt_o = sv2v_cast_8141C('d2);
										if (~cv32e40p_pkg_C_XF16)
											illegal_insn_o = 1'b1;
									end
									2'b11: begin
										fpu_src_fmt_o = sv2v_cast_8141C('d3);
										if (~cv32e40p_pkg_C_XF8)
											illegal_insn_o = 1'b1;
									end
								endcase
								if (instr_rdata_i[14])
									illegal_insn_o = 1'b1;
							end
							else
								illegal_insn_o = 1'b1;
						end
						else if (instr_rdata_i[29:25] == 5'b01101) begin
							fpu_op = sv2v_cast_FEEA0(6);
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b01110) begin
							fpu_op = sv2v_cast_FEEA0(6);
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b01111) begin
							fpu_op = sv2v_cast_FEEA0(6);
							fp_rnd_mode_o = 3'b010;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10000) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(8);
							fp_rnd_mode_o = 3'b010;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10001) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(8);
							fpu_op_mod = 1'b1;
							fp_rnd_mode_o = 3'b010;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10010) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(8);
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10011) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(8);
							fpu_op_mod = 1'b1;
							fp_rnd_mode_o = 3'b001;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10100) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(8);
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if (instr_rdata_i[29:25] == 5'b10101) begin
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(8);
							fpu_op_mod = 1'b1;
							fp_rnd_mode_o = 3'b000;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
						end
						else if ((instr_rdata_i[29:25] | 5'b00011) == 5'b11011) begin
							fpu_op_mod = instr_rdata_i[14];
							fp_op_group = 2'd3;
							scalar_replication_o = 1'b0;
							if (instr_rdata_i[25])
								fpu_op = sv2v_cast_FEEA0(14);
							else
								fpu_op = sv2v_cast_FEEA0(13);
							if (instr_rdata_i[26]) begin
								fpu_src_fmt_o = sv2v_cast_8141C('d1);
								if (~cv32e40p_pkg_C_RVD)
									illegal_insn_o = 1'b1;
							end
							else begin
								fpu_src_fmt_o = sv2v_cast_8141C('d0);
								if (~cv32e40p_pkg_C_RVF)
									illegal_insn_o = 1'b1;
							end
							if (fpu_op == sv2v_cast_FEEA0(14)) begin
								if (~cv32e40p_pkg_C_XF8 || ~cv32e40p_pkg_C_RVD)
									illegal_insn_o = 1'b1;
							end
							else if (instr_rdata_i[14]) begin
								if (fpu_dst_fmt_o == sv2v_cast_8141C('d0))
									illegal_insn_o = 1'b1;
								if (~cv32e40p_pkg_C_RVD && (fpu_dst_fmt_o != sv2v_cast_8141C('d3)))
									illegal_insn_o = 1'b1;
							end
						end
						else
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_RVF || ~cv32e40p_pkg_C_RVD) && (fpu_dst_fmt_o == sv2v_cast_8141C('d0)))
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_XF16 || ~cv32e40p_pkg_C_RVF) && (fpu_dst_fmt_o == sv2v_cast_8141C('d2)))
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_XF16ALT || ~cv32e40p_pkg_C_RVF) && (fpu_dst_fmt_o == sv2v_cast_8141C('d4)))
							illegal_insn_o = 1'b1;
						if ((~cv32e40p_pkg_C_XF8 || (~cv32e40p_pkg_C_XF16 && ~cv32e40p_pkg_C_XF16ALT)) && (fpu_dst_fmt_o == sv2v_cast_8141C('d3)))
							illegal_insn_o = 1'b1;
						if (check_fprm) begin
							(* full_case, parallel_case *)
							if ((3'b000 <= frm_i) && (3'b100 >= frm_i))
								;
							else
								illegal_insn_o = 1'b1;
						end
						case (fp_op_group)
							2'd0:
								(* full_case, parallel_case *)
								case (fpu_dst_fmt_o)
									sv2v_cast_8141C('d0): apu_lat_o = (FPU_ADDMUL_LAT < 2 ? FPU_ADDMUL_LAT + 1 : 2'h3);
									sv2v_cast_8141C('d2): apu_lat_o = 1;
									sv2v_cast_8141C('d4): apu_lat_o = 1;
									sv2v_cast_8141C('d3): apu_lat_o = 1;
									default:
										;
								endcase
							2'd1: apu_lat_o = 2'h3;
							2'd2: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
							2'd3: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
						endcase
						apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
					end
					else
						illegal_insn_o = 1'b1;
				end
				else begin
					regfile_alu_we = 1'b1;
					rega_used_o = 1'b1;
					if (~instr_rdata_i[28])
						regb_used_o = 1'b1;
					(* full_case, parallel_case *)
					case ({instr_rdata_i[30:25], instr_rdata_i[14:12]})
						9'b000000000: alu_operator_o = sv2v_cast_81146(7'b0011000);
						9'b100000000: alu_operator_o = sv2v_cast_81146(7'b0011001);
						9'b000000010: alu_operator_o = sv2v_cast_81146(7'b0000010);
						9'b000000011: alu_operator_o = sv2v_cast_81146(7'b0000011);
						9'b000000100: alu_operator_o = sv2v_cast_81146(7'b0101111);
						9'b000000110: alu_operator_o = sv2v_cast_81146(7'b0101110);
						9'b000000111: alu_operator_o = sv2v_cast_81146(7'b0010101);
						9'b000000001: alu_operator_o = sv2v_cast_81146(7'b0100111);
						9'b000000101: alu_operator_o = sv2v_cast_81146(7'b0100101);
						9'b100000101: alu_operator_o = sv2v_cast_81146(7'b0100100);
						9'b000001000: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							mult_operator_o = sv2v_cast_F9F94(3'b000);
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
						end
						9'b000001001: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							mult_signed_mode_o = 2'b11;
							mult_operator_o = sv2v_cast_F9F94(3'b110);
						end
						9'b000001010: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							mult_signed_mode_o = 2'b01;
							mult_operator_o = sv2v_cast_F9F94(3'b110);
						end
						9'b000001011: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							mult_signed_mode_o = 2'b00;
							mult_operator_o = sv2v_cast_F9F94(3'b110);
						end
						9'b000001100: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_81146(7'b0110001);
						end
						9'b000001101: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_81146(7'b0110000);
						end
						9'b000001110: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_81146(7'b0110011);
						end
						9'b000001111: begin
							alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGB_OR_FWD;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_81146(7'b0110010);
						end
						default: illegal_insn_o = 1'b1;
					endcase
				end
			cv32e40p_pkg_OPCODE_OP_FP:
				if ((FPU == 1) && ((ZFINX == 1) || (fs_off_i == 1'b0))) begin
					alu_en = 1'b0;
					apu_en = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					if (ZFINX == 0) begin
						reg_fp_a_o = 1'b1;
						reg_fp_b_o = 1'b1;
						reg_fp_d_o = 1'b1;
					end
					else begin
						reg_fp_a_o = 1'b0;
						reg_fp_b_o = 1'b0;
						reg_fp_d_o = 1'b0;
					end
					check_fprm = 1'b1;
					fp_rnd_mode_o = instr_rdata_i[14:12];
					(* full_case, parallel_case *)
					case (instr_rdata_i[26:25])
						2'b00: fpu_dst_fmt_o = sv2v_cast_8141C('d0);
						2'b01: fpu_dst_fmt_o = sv2v_cast_8141C('d1);
						2'b10:
							if (instr_rdata_i[14:12] == 3'b101)
								fpu_dst_fmt_o = sv2v_cast_8141C('d4);
							else
								fpu_dst_fmt_o = sv2v_cast_8141C('d2);
						2'b11: fpu_dst_fmt_o = sv2v_cast_8141C('d3);
					endcase
					fpu_src_fmt_o = fpu_dst_fmt_o;
					(* full_case, parallel_case *)
					case (instr_rdata_i[31:27])
						5'b00000: begin
							fpu_op = sv2v_cast_FEEA0(2);
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
						end
						5'b00001: begin
							fpu_op = sv2v_cast_FEEA0(2);
							fpu_op_mod = 1'b1;
							fp_op_group = 2'd0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
						end
						5'b00010: begin
							fpu_op = sv2v_cast_FEEA0(3);
							fp_op_group = 2'd0;
						end
						5'b00011: begin
							fpu_op = sv2v_cast_FEEA0(4);
							fp_op_group = 2'd1;
						end
						5'b01011: begin
							regb_used_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(5);
							fp_op_group = 2'd1;
							if (instr_rdata_i[24:20] != 5'b00000)
								illegal_insn_o = 1'b1;
						end
						5'b00100: begin
							fpu_op = sv2v_cast_FEEA0(6);
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
							if (cv32e40p_pkg_C_XF16ALT) begin
								if (!(|{(3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12]), (3'b100 <= instr_rdata_i[14:12]) && (3'b110 >= instr_rdata_i[14:12])}))
									illegal_insn_o = 1'b1;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_8141C('d4);
									fpu_src_fmt_o = sv2v_cast_8141C('d4);
								end
								else
									fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
							end
							else if (!((3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12])))
								illegal_insn_o = 1'b1;
						end
						5'b00101: begin
							fpu_op = sv2v_cast_FEEA0(7);
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
							if (cv32e40p_pkg_C_XF16ALT) begin
								if (!(|{(3'b000 <= instr_rdata_i[14:12]) && (3'b001 >= instr_rdata_i[14:12]), (3'b100 <= instr_rdata_i[14:12]) && (3'b101 >= instr_rdata_i[14:12])}))
									illegal_insn_o = 1'b1;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_8141C('d4);
									fpu_src_fmt_o = sv2v_cast_8141C('d4);
								end
								else
									fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
							end
							else if (!((3'b000 <= instr_rdata_i[14:12]) && (3'b001 >= instr_rdata_i[14:12])))
								illegal_insn_o = 1'b1;
						end
						5'b01000: begin
							regb_used_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(10);
							fp_op_group = 2'd3;
							if (instr_rdata_i[24:23])
								illegal_insn_o = 1'b1;
							(* full_case, parallel_case *)
							case (instr_rdata_i[22:20])
								3'b000: begin
									illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_8141C('d0);
								end
								3'b001: begin
									if (~cv32e40p_pkg_C_RVD)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_8141C('d1);
								end
								3'b010: begin
									if (~cv32e40p_pkg_C_XF16)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_8141C('d2);
								end
								3'b110: begin
									if (~cv32e40p_pkg_C_XF16ALT)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_8141C('d4);
								end
								3'b011: begin
									if (~cv32e40p_pkg_C_XF8)
										illegal_insn_o = 1'b1;
									fpu_src_fmt_o = sv2v_cast_8141C('d3);
								end
								default: illegal_insn_o = 1'b1;
							endcase
						end
						5'b01001: begin
							if ((~cv32e40p_pkg_C_XF16 && ~cv32e40p_pkg_C_XF16ALT) && ~cv32e40p_pkg_C_XF8)
								illegal_insn_o = 1;
							fpu_op = sv2v_cast_FEEA0(3);
							fp_op_group = 2'd0;
							fpu_dst_fmt_o = sv2v_cast_8141C('d0);
						end
						5'b01010: begin
							if ((~cv32e40p_pkg_C_XF16 && ~cv32e40p_pkg_C_XF16ALT) && ~cv32e40p_pkg_C_XF8)
								illegal_insn_o = 1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (ZFINX == 0)
								reg_fp_c_o = 1'b1;
							else
								reg_fp_c_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(0);
							fp_op_group = 2'd0;
							fpu_dst_fmt_o = sv2v_cast_8141C('d0);
						end
						5'b10100: begin
							fpu_op = sv2v_cast_FEEA0(8);
							fp_op_group = 2'd2;
							reg_fp_d_o = 1'b0;
							check_fprm = 1'b0;
							if (cv32e40p_pkg_C_XF16ALT) begin
								if (!(|{(3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12]), (3'b100 <= instr_rdata_i[14:12]) && (3'b110 >= instr_rdata_i[14:12])}))
									illegal_insn_o = 1'b1;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_8141C('d4);
									fpu_src_fmt_o = sv2v_cast_8141C('d4);
								end
								else
									fp_rnd_mode_o = {1'b0, instr_rdata_i[13:12]};
							end
							else if (!((3'b000 <= instr_rdata_i[14:12]) && (3'b010 >= instr_rdata_i[14:12])))
								illegal_insn_o = 1'b1;
						end
						5'b11000: begin
							regb_used_o = 1'b0;
							reg_fp_d_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(11);
							fp_op_group = 2'd3;
							fpu_op_mod = instr_rdata_i[20];
							(* full_case, parallel_case *)
							case (instr_rdata_i[26:25])
								2'b00:
									if (~cv32e40p_pkg_C_RVF)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_8141C('d0);
								2'b01:
									if (~cv32e40p_pkg_C_RVD)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_8141C('d1);
								2'b10:
									if (instr_rdata_i[14:12] == 3'b101) begin
										if (~cv32e40p_pkg_C_XF16ALT)
											illegal_insn_o = 1;
										else
											fpu_src_fmt_o = sv2v_cast_8141C('d4);
									end
									else if (~cv32e40p_pkg_C_XF16)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_8141C('d2);
								2'b11:
									if (~cv32e40p_pkg_C_XF8)
										illegal_insn_o = 1;
									else
										fpu_src_fmt_o = sv2v_cast_8141C('d3);
							endcase
							if (instr_rdata_i[24:21])
								illegal_insn_o = 1'b1;
						end
						5'b11010: begin
							regb_used_o = 1'b0;
							reg_fp_a_o = 1'b0;
							fpu_op = sv2v_cast_FEEA0(12);
							fp_op_group = 2'd3;
							fpu_op_mod = instr_rdata_i[20];
							if (instr_rdata_i[24:21])
								illegal_insn_o = 1'b1;
						end
						5'b11100: begin
							regb_used_o = 1'b0;
							reg_fp_d_o = 1'b0;
							fp_op_group = 2'd2;
							check_fprm = 1'b0;
							if (((ZFINX == 0) && (instr_rdata_i[14:12] == 3'b000)) || 1'd0) begin
								alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
								fpu_op = sv2v_cast_FEEA0(6);
								fpu_op_mod = 1'b1;
								fp_rnd_mode_o = 3'b011;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_8141C('d4);
									fpu_src_fmt_o = sv2v_cast_8141C('d4);
								end
							end
							else if ((instr_rdata_i[14:12] == 3'b001) || 1'd0) begin
								fpu_op = sv2v_cast_FEEA0(9);
								fp_rnd_mode_o = 3'b000;
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_8141C('d4);
									fpu_src_fmt_o = sv2v_cast_8141C('d4);
								end
							end
							else
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[24:20])
								illegal_insn_o = 1'b1;
						end
						5'b11110: begin
							regb_used_o = 1'b0;
							reg_fp_a_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
							fpu_op = sv2v_cast_FEEA0(6);
							fpu_op_mod = 1'b0;
							fp_op_group = 2'd2;
							fp_rnd_mode_o = 3'b011;
							check_fprm = 1'b0;
							if (((ZFINX == 0) && (instr_rdata_i[14:12] == 3'b000)) || 1'd0) begin
								if (instr_rdata_i[14]) begin
									fpu_dst_fmt_o = sv2v_cast_8141C('d4);
									fpu_src_fmt_o = sv2v_cast_8141C('d4);
								end
							end
							else
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[24:20] != 5'b00000)
								illegal_insn_o = 1'b1;
						end
						default: illegal_insn_o = 1'b1;
					endcase
					if (~cv32e40p_pkg_C_RVF && (fpu_dst_fmt_o == sv2v_cast_8141C('d0)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_RVD && (fpu_dst_fmt_o == sv2v_cast_8141C('d1)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16 && (fpu_dst_fmt_o == sv2v_cast_8141C('d2)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16ALT && (fpu_dst_fmt_o == sv2v_cast_8141C('d4)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF8 && (fpu_dst_fmt_o == sv2v_cast_8141C('d3)))
						illegal_insn_o = 1'b1;
					if (check_fprm) begin
						(* full_case, parallel_case *)
						if (|{instr_rdata_i[14:12] == 3'b000, instr_rdata_i[14:12] == 3'b001, instr_rdata_i[14:12] == 3'b010, instr_rdata_i[14:12] == 3'b011, instr_rdata_i[14:12] == 3'b100})
							;
						else if (instr_rdata_i[14:12] == 3'b101) begin
							if (~cv32e40p_pkg_C_XF16ALT || (fpu_dst_fmt_o != sv2v_cast_8141C('d4)))
								illegal_insn_o = 1'b1;
							(* full_case, parallel_case *)
							if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
								fp_rnd_mode_o = frm_i;
							else
								illegal_insn_o = 1'b1;
						end
						else if (instr_rdata_i[14:12] == 3'b111) begin
							(* full_case, parallel_case *)
							if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
								fp_rnd_mode_o = frm_i;
							else
								illegal_insn_o = 1'b1;
						end
						else
							illegal_insn_o = 1'b1;
					end
					case (fp_op_group)
						2'd0:
							(* full_case, parallel_case *)
							case (fpu_dst_fmt_o)
								sv2v_cast_8141C('d0): apu_lat_o = (FPU_ADDMUL_LAT < 2 ? FPU_ADDMUL_LAT + 1 : 2'h3);
								sv2v_cast_8141C('d1): apu_lat_o = 1;
								sv2v_cast_8141C('d2): apu_lat_o = 1;
								sv2v_cast_8141C('d4): apu_lat_o = 1;
								sv2v_cast_8141C('d3): apu_lat_o = 1;
								default:
									;
							endcase
						2'd1: apu_lat_o = 2'h3;
						2'd2: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
						2'd3: apu_lat_o = (FPU_OTHERS_LAT < 2 ? FPU_OTHERS_LAT + 1 : 2'h3);
						default:
							;
					endcase
					apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_OP_FMADD, cv32e40p_pkg_OPCODE_OP_FMSUB, cv32e40p_pkg_OPCODE_OP_FNMSUB, cv32e40p_pkg_OPCODE_OP_FNMADD:
				if ((FPU == 1) && ((ZFINX == 1) || (fs_off_i == 1'b0))) begin
					alu_en = 1'b0;
					apu_en = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					regc_used_o = 1'b1;
					regc_mux_o = cv32e40p_pkg_REGC_S4;
					if (ZFINX == 0) begin
						reg_fp_a_o = 1'b1;
						reg_fp_b_o = 1'b1;
						reg_fp_c_o = 1'b1;
						reg_fp_d_o = 1'b1;
					end
					else begin
						reg_fp_a_o = 1'b0;
						reg_fp_b_o = 1'b0;
						reg_fp_c_o = 1'b0;
						reg_fp_d_o = 1'b0;
					end
					fp_rnd_mode_o = instr_rdata_i[14:12];
					(* full_case, parallel_case *)
					case (instr_rdata_i[26:25])
						2'b00: fpu_dst_fmt_o = sv2v_cast_8141C('d0);
						2'b01: fpu_dst_fmt_o = sv2v_cast_8141C('d1);
						2'b10:
							if (instr_rdata_i[14:12] == 3'b101)
								fpu_dst_fmt_o = sv2v_cast_8141C('d4);
							else
								fpu_dst_fmt_o = sv2v_cast_8141C('d2);
						2'b11: fpu_dst_fmt_o = sv2v_cast_8141C('d3);
					endcase
					fpu_src_fmt_o = fpu_dst_fmt_o;
					(* full_case, parallel_case *)
					case (instr_rdata_i[6:0])
						cv32e40p_pkg_OPCODE_OP_FMADD: fpu_op = sv2v_cast_FEEA0(0);
						cv32e40p_pkg_OPCODE_OP_FMSUB: begin
							fpu_op = sv2v_cast_FEEA0(0);
							fpu_op_mod = 1'b1;
						end
						cv32e40p_pkg_OPCODE_OP_FNMSUB: fpu_op = sv2v_cast_FEEA0(1);
						cv32e40p_pkg_OPCODE_OP_FNMADD: begin
							fpu_op = sv2v_cast_FEEA0(1);
							fpu_op_mod = 1'b1;
						end
						default:
							;
					endcase
					if (~cv32e40p_pkg_C_RVF && (fpu_dst_fmt_o == sv2v_cast_8141C('d0)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_RVD && (fpu_dst_fmt_o == sv2v_cast_8141C('d1)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16 && (fpu_dst_fmt_o == sv2v_cast_8141C('d2)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF16ALT && (fpu_dst_fmt_o == sv2v_cast_8141C('d4)))
						illegal_insn_o = 1'b1;
					if (~cv32e40p_pkg_C_XF8 && (fpu_dst_fmt_o == sv2v_cast_8141C('d3)))
						illegal_insn_o = 1'b1;
					(* full_case, parallel_case *)
					if (|{instr_rdata_i[14:12] == 3'b000, instr_rdata_i[14:12] == 3'b001, instr_rdata_i[14:12] == 3'b010, instr_rdata_i[14:12] == 3'b011, instr_rdata_i[14:12] == 3'b100})
						;
					else if (instr_rdata_i[14:12] == 3'b101) begin
						if (~cv32e40p_pkg_C_XF16ALT || (fpu_dst_fmt_o != sv2v_cast_8141C('d4)))
							illegal_insn_o = 1'b1;
						(* full_case, parallel_case *)
						if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
							fp_rnd_mode_o = frm_i;
						else
							illegal_insn_o = 1'b1;
					end
					else if (instr_rdata_i[14:12] == 3'b111) begin
						(* full_case, parallel_case *)
						if (|{frm_i == 3'b000, frm_i == 3'b001, frm_i == 3'b010, frm_i == 3'b011, frm_i == 3'b100})
							fp_rnd_mode_o = frm_i;
						else
							illegal_insn_o = 1'b1;
					end
					else
						illegal_insn_o = 1'b1;
					(* full_case, parallel_case *)
					case (fpu_dst_fmt_o)
						sv2v_cast_8141C('d0): apu_lat_o = (FPU_ADDMUL_LAT < 2 ? FPU_ADDMUL_LAT + 1 : 2'h3);
						sv2v_cast_8141C('d1): apu_lat_o = 1;
						sv2v_cast_8141C('d2): apu_lat_o = 1;
						sv2v_cast_8141C('d4): apu_lat_o = 1;
						sv2v_cast_8141C('d3): apu_lat_o = 1;
						default:
							;
					endcase
					apu_op_o = {fpu_vec_op, fpu_op_mod, fpu_op};
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_STORE_FP:
				if (((FPU == 1) && (ZFINX == 0)) && (fs_off_i == 1'b0)) begin
					data_req = 1'b1;
					data_we_o = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					alu_operator_o = sv2v_cast_81146(7'b0011000);
					reg_fp_b_o = 1'b1;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:12])
						3'b000:
							if (cv32e40p_pkg_C_XF8)
								data_type_o = 2'b10;
							else
								illegal_insn_o = 1'b1;
						3'b001:
							if (cv32e40p_pkg_C_XF16 | cv32e40p_pkg_C_XF16ALT)
								data_type_o = 2'b01;
							else
								illegal_insn_o = 1'b1;
						3'b010:
							if (cv32e40p_pkg_C_RVF)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						3'b011:
							if (cv32e40p_pkg_C_RVD)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						default: illegal_insn_o = 1'b1;
					endcase
					if (illegal_insn_o) begin
						data_req = 1'b0;
						data_we_o = 1'b0;
					end
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_LOAD_FP:
				if (((FPU == 1) && (ZFINX == 0)) && (fs_off_i == 1'b0)) begin
					data_req = 1'b1;
					regfile_mem_we = 1'b1;
					reg_fp_d_o = 1'b1;
					rega_used_o = 1'b1;
					alu_operator_o = sv2v_cast_81146(7'b0011000);
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					data_sign_extension_o = 2'b10;
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:12])
						3'b000:
							if (cv32e40p_pkg_C_XF8)
								data_type_o = 2'b10;
							else
								illegal_insn_o = 1'b1;
						3'b001:
							if (cv32e40p_pkg_C_XF16 | cv32e40p_pkg_C_XF16ALT)
								data_type_o = 2'b01;
							else
								illegal_insn_o = 1'b1;
						3'b010:
							if (cv32e40p_pkg_C_RVF)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						3'b011:
							if (cv32e40p_pkg_C_RVD)
								data_type_o = 2'b00;
							else
								illegal_insn_o = 1'b1;
						default: illegal_insn_o = 1'b1;
					endcase
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_0:
				if (COREV_PULP && (instr_rdata_i[14:13] != 2'b11)) begin
					data_req = 1'b1;
					regfile_mem_we = 1'b1;
					rega_used_o = 1'b1;
					alu_operator_o = sv2v_cast_81146(7'b0011000);
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
					if (instr_rdata_i[13:12] != 2'b11) begin
						prepost_useincr_o = 1'b0;
						regfile_alu_waddr_sel_o = 1'b0;
						regfile_alu_we = 1'b1;
					end
					data_sign_extension_o = {1'b0, ~instr_rdata_i[14]};
					(* full_case, parallel_case *)
					case (instr_rdata_i[13:12])
						2'b00: data_type_o = 2'b10;
						2'b01: data_type_o = 2'b01;
						default: data_type_o = 2'b00;
					endcase
					if (instr_rdata_i[13:12] == 2'b11) begin
						if (COREV_CLUSTER)
							data_load_event_o = 1'b1;
						else
							illegal_insn_o = 1'b1;
					end
				end
				else if (COREV_PULP) begin
					ctrl_transfer_target_mux_sel_o = cv32e40p_pkg_JT_COND;
					ctrl_transfer_insn = cv32e40p_pkg_BRANCH_COND;
					alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_JT;
					rega_used_o = 1'b1;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_BI;
					if (instr_rdata_i[12] == 1'b0)
						alu_operator_o = sv2v_cast_81146(7'b0001100);
					else
						alu_operator_o = sv2v_cast_81146(7'b0001101);
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_1:
				if (COREV_PULP)
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:12])
						3'b000, 3'b001, 3'b010: begin
							data_req = 1'b1;
							data_we_o = 1'b1;
							rega_used_o = 1'b1;
							regb_used_o = 1'b1;
							alu_operator_o = sv2v_cast_81146(7'b0011000);
							alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
							prepost_useincr_o = 1'b0;
							regfile_alu_waddr_sel_o = 1'b0;
							regfile_alu_we = 1'b1;
							(* full_case, parallel_case *)
							case (instr_rdata_i[13:12])
								2'b00: data_type_o = 2'b10;
								2'b01: data_type_o = 2'b01;
								default: data_type_o = 2'b00;
							endcase
						end
						3'b011:
							(* full_case, parallel_case *)
							case (instr_rdata_i[31:25])
								7'b0000000, 7'b0000001, 7'b0000010, 7'b0000011, 7'b0000100, 7'b0000101, 7'b0000110, 7'b0000111, 7'b0001000, 7'b0001001, 7'b0001010, 7'b0001011, 7'b0001100, 7'b0001101, 7'b0001110, 7'b0001111: begin
									data_req = 1'b1;
									regfile_mem_we = 1'b1;
									rega_used_o = 1'b1;
									alu_operator_o = sv2v_cast_81146(7'b0011000);
									regb_used_o = 1'b1;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
									if (instr_rdata_i[27] == 1'b0) begin
										prepost_useincr_o = 1'b0;
										regfile_alu_waddr_sel_o = 1'b0;
										regfile_alu_we = 1'b1;
									end
									data_sign_extension_o = {1'b0, ~instr_rdata_i[28]};
									(* full_case, parallel_case *)
									case ({instr_rdata_i[28], instr_rdata_i[26:25]})
										3'b000: data_type_o = 2'b10;
										3'b001: data_type_o = 2'b01;
										3'b010: data_type_o = 2'b00;
										3'b100: data_type_o = 2'b10;
										3'b101: data_type_o = 2'b01;
										default: begin
											illegal_insn_o = 1'b1;
											data_req = 1'b0;
											regfile_mem_we = 1'b0;
											regfile_alu_we = 1'b0;
										end
									endcase
								end
								7'b0010000, 7'b0010001, 7'b0010010, 7'b0010011, 7'b0010100, 7'b0010101, 7'b0010110, 7'b0010111: begin
									data_req = 1'b1;
									data_we_o = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									alu_operator_o = sv2v_cast_81146(7'b0011000);
									alu_op_c_mux_sel_o = cv32e40p_pkg_OP_C_REGB_OR_FWD;
									regc_used_o = 1'b1;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGC_OR_FWD;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									if (instr_rdata_i[27] == 1'b0) begin
										prepost_useincr_o = 1'b0;
										regfile_alu_waddr_sel_o = 1'b0;
										regfile_alu_we = 1'b1;
									end
									(* full_case, parallel_case *)
									case (instr_rdata_i[26:25])
										2'b00: data_type_o = 2'b10;
										2'b01: data_type_o = 2'b01;
										2'b10: data_type_o = 2'b00;
										default: begin
											illegal_insn_o = 1'b1;
											data_req = 1'b0;
											data_we_o = 1'b0;
											data_type_o = 2'b00;
										end
									endcase
								end
								7'b0011000, 7'b0011001, 7'b0011010, 7'b0011011, 7'b0011100, 7'b0011101, 7'b0011110, 7'b0011111: begin
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									bmask_a_mux_o = cv32e40p_pkg_BMASK_A_S3;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S2;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
									alu_bmask_a_mux_sel_o = cv32e40p_pkg_BMASK_A_REG;
									(* full_case, parallel_case *)
									case (instr_rdata_i[27:25])
										3'b000: begin
											alu_operator_o = sv2v_cast_81146(7'b0101000);
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
											bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_BMASK;
										end
										3'b001: begin
											alu_operator_o = sv2v_cast_81146(7'b0101001);
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
											bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_BMASK;
										end
										3'b010: begin
											alu_operator_o = sv2v_cast_81146(7'b0101010);
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
											regc_used_o = 1'b1;
											regc_mux_o = cv32e40p_pkg_REGC_RD;
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_BMASK;
											alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
										end
										3'b100: begin
											alu_operator_o = sv2v_cast_81146(7'b0101011);
											alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
										end
										3'b101: begin
											alu_operator_o = sv2v_cast_81146(7'b0101100);
											alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
										end
										default: illegal_insn_o = 1'b1;
									endcase
								end
								7'b0100000, 7'b0100001, 7'b0100010, 7'b0100011, 7'b0100100, 7'b0100101, 7'b0100110, 7'b0100111, 7'b0101000, 7'b0101001, 7'b0101010, 7'b0101011, 7'b0101100, 7'b0101101, 7'b0101110, 7'b0101111, 7'b0110000, 7'b0110001, 7'b0110010, 7'b0110011, 7'b0110100, 7'b0110101, 7'b0110110, 7'b0110111, 7'b0111000, 7'b0111001, 7'b0111010, 7'b0111011, 7'b0111100, 7'b0111101, 7'b0111110, 7'b0111111: begin
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									(* full_case, parallel_case *)
									case (instr_rdata_i[29:25])
										5'b00000: alu_operator_o = sv2v_cast_81146(7'b0100110);
										5'b00001: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0110110);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b00010: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0110111);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b00011: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0110101);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b00100: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0110100);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b01000: begin
											alu_operator_o = sv2v_cast_81146(7'b0010100);
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b01001: alu_operator_o = sv2v_cast_81146(7'b0000110);
										5'b01010: alu_operator_o = sv2v_cast_81146(7'b0000111);
										5'b01011: alu_operator_o = sv2v_cast_81146(7'b0010000);
										5'b01100: alu_operator_o = sv2v_cast_81146(7'b0010001);
										5'b01101: alu_operator_o = sv2v_cast_81146(7'b0010010);
										5'b01110: alu_operator_o = sv2v_cast_81146(7'b0010011);
										5'b10000: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0111110);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b10001: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0111111);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b10010: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0111110);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b10011: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0111111);
											alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
											if (instr_rdata_i[24:20] != 5'b00000)
												illegal_insn_o = 1'b1;
										end
										5'b11000: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0010110);
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_CLIP;
										end
										5'b11001: begin
											regb_used_o = 1'b0;
											alu_operator_o = sv2v_cast_81146(7'b0010111);
											alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
											imm_b_mux_sel_o = cv32e40p_pkg_IMMB_CLIP;
										end
										5'b11010: alu_operator_o = sv2v_cast_81146(7'b0010110);
										5'b11011: alu_operator_o = sv2v_cast_81146(7'b0010111);
										default: illegal_insn_o = 1'b1;
									endcase
								end
								7'b1000000, 7'b1000001, 7'b1000010, 7'b1000011, 7'b1000100, 7'b1000101, 7'b1000110, 7'b1000111: begin
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									bmask_a_mux_o = cv32e40p_pkg_BMASK_A_ZERO;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S3;
									alu_bmask_b_mux_sel_o = cv32e40p_pkg_BMASK_B_REG;
									alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGC_OR_FWD;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGA_OR_FWD;
									(* full_case, parallel_case *)
									case (instr_rdata_i[27:25])
										3'b001: alu_operator_o = sv2v_cast_81146(7'b0011010);
										3'b010: alu_operator_o = sv2v_cast_81146(7'b0011100);
										3'b011: alu_operator_o = sv2v_cast_81146(7'b0011110);
										3'b100: alu_operator_o = sv2v_cast_81146(7'b0011001);
										3'b101: alu_operator_o = sv2v_cast_81146(7'b0011011);
										3'b110: alu_operator_o = sv2v_cast_81146(7'b0011101);
										3'b111: alu_operator_o = sv2v_cast_81146(7'b0011111);
										default: alu_operator_o = sv2v_cast_81146(7'b0011000);
									endcase
								end
								7'b1001000, 7'b1001001: begin
									alu_en = 1'b0;
									mult_int_en = 1'b1;
									regfile_alu_we = 1'b1;
									rega_used_o = 1'b1;
									regb_used_o = 1'b1;
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									if (instr_rdata_i[25] == 1'b0)
										mult_operator_o = sv2v_cast_F9F94(3'b000);
									else
										mult_operator_o = sv2v_cast_F9F94(3'b001);
								end
								default: illegal_insn_o = 1'b1;
							endcase
						3'b100: begin
							hwlp_target_mux_sel_o = 2'b00;
							(* full_case, parallel_case *)
							case (instr_rdata_i[11:8])
								4'b0000: begin
									hwlp_we[0] = 1'b1;
									hwlp_start_mux_sel_o = 2'b00;
									if (instr_rdata_i[19:15] != 5'b00000)
										illegal_insn_o = 1'b1;
								end
								4'b0001: begin
									hwlp_we[0] = 1'b1;
									hwlp_start_mux_sel_o = 2'b10;
									rega_used_o = 1'b1;
									if (instr_rdata_i[31:20] != 12'b000000000000)
										illegal_insn_o = 1'b1;
								end
								4'b0010: begin
									hwlp_we[1] = 1'b1;
									if (instr_rdata_i[19:15] != 5'b00000)
										illegal_insn_o = 1'b1;
								end
								4'b0011: begin
									hwlp_we[1] = 1'b1;
									hwlp_target_mux_sel_o = 2'b10;
									rega_used_o = 1'b1;
									if (instr_rdata_i[31:20] != 12'b000000000000)
										illegal_insn_o = 1'b1;
								end
								4'b0100: begin
									hwlp_we[2] = 1'b1;
									hwlp_cnt_mux_sel_o = 1'b0;
									if (instr_rdata_i[19:15] != 5'b00000)
										illegal_insn_o = 1'b1;
								end
								4'b0101: begin
									hwlp_we[2] = 1'b1;
									hwlp_cnt_mux_sel_o = 1'b1;
									rega_used_o = 1'b1;
									if (instr_rdata_i[31:20] != 12'b000000000000)
										illegal_insn_o = 1'b1;
								end
								4'b0110: begin
									hwlp_we = 3'b111;
									hwlp_target_mux_sel_o = 2'b01;
									hwlp_start_mux_sel_o = 2'b01;
									hwlp_cnt_mux_sel_o = 1'b0;
								end
								4'b0111: begin
									hwlp_we = 3'b111;
									hwlp_start_mux_sel_o = 2'b01;
									hwlp_cnt_mux_sel_o = 1'b1;
									rega_used_o = 1'b1;
								end
								default: illegal_insn_o = 1'b1;
							endcase
						end
						default: illegal_insn_o = 1'b1;
					endcase
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_2:
				if (COREV_PULP) begin
					regfile_alu_we = 1'b1;
					rega_used_o = 1'b1;
					regb_used_o = 1'b1;
					(* full_case, parallel_case *)
					case (instr_rdata_i[14:13])
						2'b00: begin
							regb_used_o = 1'b0;
							bmask_a_mux_o = cv32e40p_pkg_BMASK_A_S3;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S2;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
							(* full_case, parallel_case *)
							case ({instr_rdata_i[31:30], instr_rdata_i[12]})
								3'b000: begin
									alu_operator_o = sv2v_cast_81146(7'b0101000);
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
								end
								3'b010: begin
									alu_operator_o = sv2v_cast_81146(7'b0101001);
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ZERO;
								end
								3'b100: begin
									alu_operator_o = sv2v_cast_81146(7'b0101010);
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
								end
								3'b001: alu_operator_o = sv2v_cast_81146(7'b0101011);
								3'b011: alu_operator_o = sv2v_cast_81146(7'b0101100);
								3'b111: begin
									alu_operator_o = sv2v_cast_81146(7'b1001001);
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_S2;
									alu_bmask_a_mux_sel_o = cv32e40p_pkg_BMASK_A_IMM;
									if (instr_rdata_i[29:27] != 3'b000)
										illegal_insn_o = 1'b1;
								end
								default: illegal_insn_o = 1'b1;
							endcase
						end
						2'b01: begin
							bmask_a_mux_o = cv32e40p_pkg_BMASK_A_ZERO;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_S3;
							(* full_case, parallel_case *)
							case ({instr_rdata_i[31:30], instr_rdata_i[12]})
								3'b010: alu_operator_o = sv2v_cast_81146(7'b0011010);
								3'b100: alu_operator_o = sv2v_cast_81146(7'b0011100);
								3'b110: alu_operator_o = sv2v_cast_81146(7'b0011110);
								3'b001: alu_operator_o = sv2v_cast_81146(7'b0011001);
								3'b011: alu_operator_o = sv2v_cast_81146(7'b0011011);
								3'b101: alu_operator_o = sv2v_cast_81146(7'b0011101);
								3'b111: alu_operator_o = sv2v_cast_81146(7'b0011111);
								default: alu_operator_o = sv2v_cast_81146(7'b0011000);
							endcase
						end
						default: begin
							alu_en = 1'b0;
							mult_int_en = 1'b1;
							mult_imm_mux_o = cv32e40p_pkg_MIMM_S3;
							mult_sel_subword_o = instr_rdata_i[30];
							mult_signed_mode_o = {2 {~instr_rdata_i[12]}};
							if (instr_rdata_i[13]) begin
								regc_used_o = 1'b1;
								regc_mux_o = cv32e40p_pkg_REGC_RD;
							end
							else
								regc_mux_o = cv32e40p_pkg_REGC_ZERO;
							if (instr_rdata_i[31])
								mult_operator_o = sv2v_cast_F9F94(3'b011);
							else
								mult_operator_o = sv2v_cast_F9F94(3'b010);
						end
					endcase
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_CUSTOM_3:
				if (COREV_PULP) begin
					regfile_alu_we = 1'b1;
					rega_used_o = 1'b1;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
					alu_vec_o = 1'b1;
					if (instr_rdata_i[12]) begin
						alu_vec_mode_o = cv32e40p_pkg_VEC_MODE8;
						mult_operator_o = sv2v_cast_F9F94(3'b100);
					end
					else begin
						alu_vec_mode_o = cv32e40p_pkg_VEC_MODE16;
						mult_operator_o = sv2v_cast_F9F94(3'b101);
					end
					if (instr_rdata_i[14]) begin
						scalar_replication_o = 1'b1;
						if (instr_rdata_i[13])
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
						else
							regb_used_o = 1'b1;
					end
					else
						regb_used_o = 1'b1;
					(* full_case, parallel_case *)
					case (instr_rdata_i[31:26])
						6'b000000: begin
							alu_operator_o = sv2v_cast_81146(7'b0011000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000010: begin
							alu_operator_o = sv2v_cast_81146(7'b0011001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000100: begin
							alu_operator_o = sv2v_cast_81146(7'b0011000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ONE;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000110: begin
							alu_operator_o = sv2v_cast_81146(7'b0011010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							bmask_b_mux_o = cv32e40p_pkg_BMASK_B_ONE;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001000: begin
							alu_operator_o = sv2v_cast_81146(7'b0010000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001010: begin
							alu_operator_o = sv2v_cast_81146(7'b0010001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001100: begin
							alu_operator_o = sv2v_cast_81146(7'b0010010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001110: begin
							alu_operator_o = sv2v_cast_81146(7'b0010011);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010000: begin
							alu_operator_o = sv2v_cast_81146(7'b0100101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:23] != 2'b00)) || ((instr_rdata_i[14:12] == 3'b111) && (instr_rdata_i[24:22] != 3'b000)))
								illegal_insn_o = 1'b1;
						end
						6'b010010: begin
							alu_operator_o = sv2v_cast_81146(7'b0100100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:23] != 2'b00)) || ((instr_rdata_i[14:12] == 3'b111) && (instr_rdata_i[24:22] != 3'b000)))
								illegal_insn_o = 1'b1;
						end
						6'b010100: begin
							alu_operator_o = sv2v_cast_81146(7'b0100111);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:23] != 2'b00)) || ((instr_rdata_i[14:12] == 3'b111) && (instr_rdata_i[24:22] != 3'b000)))
								illegal_insn_o = 1'b1;
						end
						6'b010110: begin
							alu_operator_o = sv2v_cast_81146(7'b0101110);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011000: begin
							alu_operator_o = sv2v_cast_81146(7'b0101111);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011010: begin
							alu_operator_o = sv2v_cast_81146(7'b0010101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011100: begin
							alu_operator_o = sv2v_cast_81146(7'b0010100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] != 3'b000) && (instr_rdata_i[14:12] != 3'b001))
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[25:20] != 6'b000000)
								illegal_insn_o = 1'b1;
						end
						6'b100000: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b00;
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b100010: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b01;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b100100: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b11;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b100110: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b00;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b101000: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b01;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b101010: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b11;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b101110: begin
							(* full_case, parallel_case *)
							case (instr_rdata_i[14:13])
								2'b00: alu_operator_o = sv2v_cast_81146(7'b0111110);
								2'b01: alu_operator_o = sv2v_cast_81146(7'b0111111);
								2'b10: begin
									alu_operator_o = sv2v_cast_81146(7'b0101101);
									regc_used_o = 1'b1;
									regc_mux_o = cv32e40p_pkg_REGC_RD;
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGC_OR_FWD;
								end
								default: illegal_insn_o = 1'b1;
							endcase
							if (((instr_rdata_i[12] == 1'b0) && (instr_rdata_i[24:20] != 5'b00000)) || ((instr_rdata_i[12] == 1'b1) && (instr_rdata_i[24:21] != 4'b0000)))
								illegal_insn_o = 1'b1;
						end
						6'b110000: begin
							alu_operator_o = sv2v_cast_81146(7'b0111010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_SHUF;
							regb_used_o = 1'b1;
							scalar_replication_o = 1'b0;
							if ((((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011)) || (instr_rdata_i[14:12] == 3'b100)) || (instr_rdata_i[14:12] == 3'b101))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
							if ((instr_rdata_i[14:12] == 3'b110) && (instr_rdata_i[24:21] != 4'b0000))
								illegal_insn_o = 1'b1;
						end
						6'b110010, 6'b110100, 6'b110110: begin
							alu_operator_o = sv2v_cast_81146(7'b0111010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_SHUF;
							regb_used_o = 1'b1;
							scalar_replication_o = 1'b0;
							if (instr_rdata_i[14:12] != 3'b111)
								illegal_insn_o = 1'b1;
						end
						6'b111000: begin
							alu_operator_o = sv2v_cast_81146(7'b0111011);
							regb_used_o = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							scalar_replication_o = 1'b0;
							if ((instr_rdata_i[14:12] != 3'b000) && (instr_rdata_i[14:12] != 3'b001))
								illegal_insn_o = 1'b1;
							if (instr_rdata_i[25] != 1'b0)
								illegal_insn_o = 1'b1;
						end
						6'b111100: begin
							alu_operator_o = (instr_rdata_i[25] ? sv2v_cast_81146(7'b0111001) : sv2v_cast_81146(7'b0111000));
							regb_used_o = 1'b1;
							if (instr_rdata_i[14:12] != 3'b000)
								illegal_insn_o = 1'b1;
						end
						6'b111110: begin
							alu_operator_o = (instr_rdata_i[25] ? sv2v_cast_81146(7'b0111001) : sv2v_cast_81146(7'b0111000));
							regb_used_o = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							if (instr_rdata_i[14:12] != 3'b001)
								illegal_insn_o = 1'b1;
						end
						6'b000001: begin
							alu_operator_o = sv2v_cast_81146(7'b0001100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000011: begin
							alu_operator_o = sv2v_cast_81146(7'b0001101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000101: begin
							alu_operator_o = sv2v_cast_81146(7'b0001000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b000111: begin
							alu_operator_o = sv2v_cast_81146(7'b0001010);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001001: begin
							alu_operator_o = sv2v_cast_81146(7'b0000000);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001011: begin
							alu_operator_o = sv2v_cast_81146(7'b0000100);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VS;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001101: begin
							alu_operator_o = sv2v_cast_81146(7'b0001001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b001111: begin
							alu_operator_o = sv2v_cast_81146(7'b0001011);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010001: begin
							alu_operator_o = sv2v_cast_81146(7'b0000001);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010011: begin
							alu_operator_o = sv2v_cast_81146(7'b0000101);
							imm_b_mux_sel_o = cv32e40p_pkg_IMMB_VU;
							if ((instr_rdata_i[14:12] == 3'b010) || (instr_rdata_i[14:12] == 3'b011))
								illegal_insn_o = 1'b1;
							if (((instr_rdata_i[14:12] != 3'b110) && (instr_rdata_i[14:12] != 3'b111)) && (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b010101: begin
							alu_en = 1'b0;
							mult_dot_en = 1'b1;
							mult_dot_signed_o = 2'b11;
							is_clpx_o = 1'b1;
							regc_used_o = 1'b1;
							regc_mux_o = cv32e40p_pkg_REGC_RD;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							illegal_insn_o = instr_rdata_i[12];
						end
						6'b010111: begin
							alu_operator_o = sv2v_cast_81146(7'b0010100);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							regb_used_o = 1'b0;
							if ((instr_rdata_i[14:12] != 3'b000) || (instr_rdata_i[25:20] != 6'b000000))
								illegal_insn_o = 1'b1;
						end
						6'b011001: begin
							alu_operator_o = sv2v_cast_81146(7'b0011001);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							is_subrot_o = 1'b1;
							if ((instr_rdata_i[12] != 1'b0) || (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011011: begin
							alu_operator_o = sv2v_cast_81146(7'b0011000);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							if (((instr_rdata_i[12] != 1'b0) || (instr_rdata_i[14:12] == 3'b000)) || (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						6'b011101: begin
							alu_operator_o = sv2v_cast_81146(7'b0011001);
							is_clpx_o = 1'b1;
							scalar_replication_o = 1'b0;
							alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_REGB_OR_FWD;
							regb_used_o = 1'b1;
							if (((instr_rdata_i[12] != 1'b0) || (instr_rdata_i[14:12] == 3'b000)) || (instr_rdata_i[25] != 1'b0))
								illegal_insn_o = 1'b1;
						end
						default: illegal_insn_o = 1'b1;
					endcase
				end
				else
					illegal_insn_o = 1'b1;
			cv32e40p_pkg_OPCODE_FENCE:
				(* full_case, parallel_case *)
				case (instr_rdata_i[14:12])
					3'b000: fencei_insn_o = 1'b1;
					3'b001: fencei_insn_o = 1'b1;
					default: illegal_insn_o = 1'b1;
				endcase
			cv32e40p_pkg_OPCODE_SYSTEM:
				if (instr_rdata_i[14:12] == 3'b000) begin
					if ({instr_rdata_i[19:15], instr_rdata_i[11:7]} == {10 {1'sb0}})
						(* full_case, parallel_case *)
						case (instr_rdata_i[31:20])
							12'h000: ecall_insn_o = 1'b1;
							12'h001: ebrk_insn_o = 1'b1;
							12'h302: begin
								illegal_insn_o = (PULP_SECURE ? current_priv_lvl_i != 2'b11 : 1'b0);
								mret_insn_o = ~illegal_insn_o;
								mret_dec_o = 1'b1;
							end
							12'h002: begin
								illegal_insn_o = (PULP_SECURE ? 1'b0 : 1'b1);
								uret_insn_o = ~illegal_insn_o;
								uret_dec_o = 1'b1;
							end
							12'h7b2: begin
								illegal_insn_o = !debug_mode_i;
								dret_insn_o = debug_mode_i;
								dret_dec_o = 1'b1;
							end
							12'h105: begin
								wfi_o = 1'b1;
								if (debug_wfi_no_sleep_i) begin
									alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
									imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
									alu_operator_o = sv2v_cast_81146(7'b0011000);
								end
							end
							default: illegal_insn_o = 1'b1;
						endcase
					else
						illegal_insn_o = 1'b1;
				end
				else begin
					csr_access_o = 1'b1;
					regfile_alu_we = 1'b1;
					alu_op_b_mux_sel_o = cv32e40p_pkg_OP_B_IMM;
					imm_a_mux_sel_o = cv32e40p_pkg_IMMA_Z;
					imm_b_mux_sel_o = cv32e40p_pkg_IMMB_I;
					if (instr_rdata_i[14] == 1'b1)
						alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_IMM;
					else begin
						rega_used_o = 1'b1;
						alu_op_a_mux_sel_o = cv32e40p_pkg_OP_A_REGA_OR_FWD;
					end
					(* full_case, parallel_case *)
					case (instr_rdata_i[13:12])
						2'b01: csr_op = sv2v_cast_8FA4C(2'b01);
						2'b10: csr_op = (instr_rdata_i[19:15] == 5'b00000 ? sv2v_cast_8FA4C(2'b00) : sv2v_cast_8FA4C(2'b10));
						2'b11: csr_op = (instr_rdata_i[19:15] == 5'b00000 ? sv2v_cast_8FA4C(2'b00) : sv2v_cast_8FA4C(2'b11));
						default: csr_illegal = 1'b1;
					endcase
					if (instr_rdata_i[29:28] > current_priv_lvl_i)
						csr_illegal = 1'b1;
					case (instr_rdata_i[31:20])
						12'h001:
							if ((FPU == 0) || (fs_off_i == 1'b1))
								csr_illegal = 1'b1;
						12'h002, 12'h003:
							if ((FPU == 0) || (fs_off_i == 1'b1))
								csr_illegal = 1'b1;
							else if (csr_op != sv2v_cast_8FA4C(2'b00))
								csr_status_o = 1'b1;
						12'hf11, 12'hf12, 12'hf13, 12'hf14:
							if (csr_op != sv2v_cast_8FA4C(2'b00))
								csr_illegal = 1'b1;
						12'h300, 12'h341, 12'h305, 12'h342: csr_status_o = 1'b1;
						12'h301, 12'h304, 12'h340, 12'h343, 12'h344:
							;
						12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f, 12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f, 12'h320, 12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_status_o = 1'b1;
						12'hc00, 12'hc02, 12'hc03, 12'hc04, 12'hc05, 12'hc06, 12'hc07, 12'hc08, 12'hc09, 12'hc0a, 12'hc0b, 12'hc0c, 12'hc0d, 12'hc0e, 12'hc0f, 12'hc10, 12'hc11, 12'hc12, 12'hc13, 12'hc14, 12'hc15, 12'hc16, 12'hc17, 12'hc18, 12'hc19, 12'hc1a, 12'hc1b, 12'hc1c, 12'hc1d, 12'hc1e, 12'hc1f, 12'hc80, 12'hc82, 12'hc83, 12'hc84, 12'hc85, 12'hc86, 12'hc87, 12'hc88, 12'hc89, 12'hc8a, 12'hc8b, 12'hc8c, 12'hc8d, 12'hc8e, 12'hc8f, 12'hc90, 12'hc91, 12'hc92, 12'hc93, 12'hc94, 12'hc95, 12'hc96, 12'hc97, 12'hc98, 12'hc99, 12'hc9a, 12'hc9b, 12'hc9c, 12'hc9d, 12'hc9e, 12'hc9f:
							if ((csr_op != sv2v_cast_8FA4C(2'b00)) || ((PULP_SECURE && (current_priv_lvl_i != 2'b11)) && !mcounteren_i[instr_rdata_i[24:20]]))
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'h306:
							if (!PULP_SECURE)
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'h7b0, 12'h7b1, 12'h7b2, 12'h7b3:
							if (!debug_mode_i)
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'h7a0, 12'h7a1, 12'h7a2, 12'h7a3, 12'h7a4, 12'h7a8, 12'h7aa:
							if (DEBUG_TRIGGER_EN != 1)
								csr_illegal = 1'b1;
						12'hcc0, 12'hcc1, 12'hcc2, 12'hcc4, 12'hcc5, 12'hcc6:
							if (!COREV_PULP || (csr_op != sv2v_cast_8FA4C(2'b00)))
								csr_illegal = 1'b1;
						12'hcd0:
							if (!COREV_PULP || (csr_op != sv2v_cast_8FA4C(2'b00)))
								csr_illegal = 1'b1;
						12'hcd1:
							if (!COREV_PULP || (csr_op != sv2v_cast_8FA4C(2'b00)))
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						12'hcd2:
							if ((!COREV_PULP || (FPU && !ZFINX)) || (csr_op != sv2v_cast_8FA4C(2'b00)))
								csr_illegal = 1'b1;
						12'h3a0, 12'h3a1, 12'h3a2, 12'h3a3, 12'h3b0, 12'h3b1, 12'h3b2, 12'h3b3, 12'h3b4, 12'h3b5, 12'h3b6, 12'h3b7, 12'h3b8, 12'h3b9, 12'h3ba, 12'h3bb, 12'h3bc, 12'h3bd, 12'h3be, 12'h3bf:
							if (!USE_PMP)
								csr_illegal = 1'b1;
						12'h000, 12'h041, 12'h005, 12'h042:
							if (!PULP_SECURE)
								csr_illegal = 1'b1;
							else
								csr_status_o = 1'b1;
						default: csr_illegal = 1'b1;
					endcase
					illegal_insn_o = csr_illegal;
				end
			default: illegal_insn_o = 1'b1;
		endcase
		if (illegal_c_insn_i)
			illegal_insn_o = 1'b1;
	end
	assign alu_en_o = (deassert_we_i ? 1'b0 : alu_en);
	assign mult_int_en_o = (deassert_we_i ? 1'b0 : mult_int_en);
	assign mult_dot_en_o = (deassert_we_i ? 1'b0 : mult_dot_en);
	assign apu_en_o = (deassert_we_i ? 1'b0 : apu_en);
	assign regfile_mem_we_o = (deassert_we_i ? 1'b0 : regfile_mem_we);
	assign regfile_alu_we_o = (deassert_we_i ? 1'b0 : regfile_alu_we);
	assign data_req_o = (deassert_we_i ? 1'b0 : data_req);
	assign hwlp_we_o = (deassert_we_i ? 3'b000 : hwlp_we);
	assign csr_op_o = (deassert_we_i ? sv2v_cast_8FA4C(2'b00) : csr_op);
	assign ctrl_transfer_insn_in_id_o = (deassert_we_i ? cv32e40p_pkg_BRANCH_NONE : ctrl_transfer_insn);
	assign ctrl_transfer_insn_in_dec_o = ctrl_transfer_insn;
	assign regfile_alu_we_dec_o = regfile_alu_we;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_ex_stage (
	clk,
	rst_n,
	alu_operator_i,
	alu_operand_a_i,
	alu_operand_b_i,
	alu_operand_c_i,
	alu_en_i,
	bmask_a_i,
	bmask_b_i,
	imm_vec_ext_i,
	alu_vec_mode_i,
	alu_is_clpx_i,
	alu_is_subrot_i,
	alu_clpx_shift_i,
	mult_operator_i,
	mult_operand_a_i,
	mult_operand_b_i,
	mult_operand_c_i,
	mult_en_i,
	mult_sel_subword_i,
	mult_signed_mode_i,
	mult_imm_i,
	mult_dot_op_a_i,
	mult_dot_op_b_i,
	mult_dot_op_c_i,
	mult_dot_signed_i,
	mult_is_clpx_i,
	mult_clpx_shift_i,
	mult_clpx_img_i,
	mult_multicycle_o,
	data_req_i,
	data_rvalid_i,
	data_misaligned_ex_i,
	data_misaligned_i,
	ctrl_transfer_insn_in_dec_i,
	fpu_fflags_we_o,
	fpu_fflags_o,
	apu_en_i,
	apu_op_i,
	apu_lat_i,
	apu_operands_i,
	apu_waddr_i,
	apu_flags_i,
	apu_read_regs_i,
	apu_read_regs_valid_i,
	apu_read_dep_o,
	apu_read_dep_for_jalr_o,
	apu_write_regs_i,
	apu_write_regs_valid_i,
	apu_write_dep_o,
	apu_perf_type_o,
	apu_perf_cont_o,
	apu_perf_wb_o,
	apu_busy_o,
	apu_ready_wb_o,
	apu_req_o,
	apu_gnt_i,
	apu_operands_o,
	apu_op_o,
	apu_rvalid_i,
	apu_result_i,
	lsu_en_i,
	lsu_rdata_i,
	branch_in_ex_i,
	regfile_alu_waddr_i,
	regfile_alu_we_i,
	regfile_we_i,
	regfile_waddr_i,
	csr_access_i,
	csr_rdata_i,
	regfile_waddr_wb_o,
	regfile_we_wb_o,
	regfile_we_wb_power_o,
	regfile_wdata_wb_o,
	regfile_alu_waddr_fw_o,
	regfile_alu_we_fw_o,
	regfile_alu_we_fw_power_o,
	regfile_alu_wdata_fw_o,
	jump_target_o,
	branch_decision_o,
	is_decoding_i,
	lsu_ready_ex_i,
	lsu_err_i,
	ex_ready_o,
	ex_valid_o,
	wb_ready_i
);
	reg _sv2v_0;
	parameter COREV_PULP = 0;
	parameter FPU = 0;
	parameter APU_NARGS_CPU = 3;
	parameter APU_WOP_CPU = 6;
	parameter APU_NDSFLAGS_CPU = 15;
	parameter APU_NUSFLAGS_CPU = 5;
	input wire clk;
	input wire rst_n;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	input wire [6:0] alu_operator_i;
	input wire [31:0] alu_operand_a_i;
	input wire [31:0] alu_operand_b_i;
	input wire [31:0] alu_operand_c_i;
	input wire alu_en_i;
	input wire [4:0] bmask_a_i;
	input wire [4:0] bmask_b_i;
	input wire [1:0] imm_vec_ext_i;
	input wire [1:0] alu_vec_mode_i;
	input wire alu_is_clpx_i;
	input wire alu_is_subrot_i;
	input wire [1:0] alu_clpx_shift_i;
	localparam cv32e40p_pkg_MUL_OP_WIDTH = 3;
	input wire [2:0] mult_operator_i;
	input wire [31:0] mult_operand_a_i;
	input wire [31:0] mult_operand_b_i;
	input wire [31:0] mult_operand_c_i;
	input wire mult_en_i;
	input wire mult_sel_subword_i;
	input wire [1:0] mult_signed_mode_i;
	input wire [4:0] mult_imm_i;
	input wire [31:0] mult_dot_op_a_i;
	input wire [31:0] mult_dot_op_b_i;
	input wire [31:0] mult_dot_op_c_i;
	input wire [1:0] mult_dot_signed_i;
	input wire mult_is_clpx_i;
	input wire [1:0] mult_clpx_shift_i;
	input wire mult_clpx_img_i;
	output wire mult_multicycle_o;
	input wire data_req_i;
	input wire data_rvalid_i;
	input wire data_misaligned_ex_i;
	input wire data_misaligned_i;
	input wire [1:0] ctrl_transfer_insn_in_dec_i;
	output wire fpu_fflags_we_o;
	output wire [APU_NUSFLAGS_CPU - 1:0] fpu_fflags_o;
	input wire apu_en_i;
	input wire [APU_WOP_CPU - 1:0] apu_op_i;
	input wire [1:0] apu_lat_i;
	input wire [(APU_NARGS_CPU * 32) - 1:0] apu_operands_i;
	input wire [5:0] apu_waddr_i;
	input wire [APU_NUSFLAGS_CPU - 1:0] apu_flags_i;
	input wire [17:0] apu_read_regs_i;
	input wire [2:0] apu_read_regs_valid_i;
	output wire apu_read_dep_o;
	output wire apu_read_dep_for_jalr_o;
	input wire [11:0] apu_write_regs_i;
	input wire [1:0] apu_write_regs_valid_i;
	output wire apu_write_dep_o;
	output wire apu_perf_type_o;
	output wire apu_perf_cont_o;
	output wire apu_perf_wb_o;
	output wire apu_busy_o;
	output wire apu_ready_wb_o;
	output wire apu_req_o;
	input wire apu_gnt_i;
	output wire [(APU_NARGS_CPU * 32) - 1:0] apu_operands_o;
	output wire [APU_WOP_CPU - 1:0] apu_op_o;
	input wire apu_rvalid_i;
	input wire [31:0] apu_result_i;
	input wire lsu_en_i;
	input wire [31:0] lsu_rdata_i;
	input wire branch_in_ex_i;
	input wire [5:0] regfile_alu_waddr_i;
	input wire regfile_alu_we_i;
	input wire regfile_we_i;
	input wire [5:0] regfile_waddr_i;
	input wire csr_access_i;
	input wire [31:0] csr_rdata_i;
	output reg [5:0] regfile_waddr_wb_o;
	output reg regfile_we_wb_o;
	output reg regfile_we_wb_power_o;
	output reg [31:0] regfile_wdata_wb_o;
	output reg [5:0] regfile_alu_waddr_fw_o;
	output reg regfile_alu_we_fw_o;
	output reg regfile_alu_we_fw_power_o;
	output reg [31:0] regfile_alu_wdata_fw_o;
	output wire [31:0] jump_target_o;
	output wire branch_decision_o;
	input wire is_decoding_i;
	input wire lsu_ready_ex_i;
	input wire lsu_err_i;
	output wire ex_ready_o;
	output wire ex_valid_o;
	input wire wb_ready_i;
	wire [31:0] alu_result;
	wire [31:0] mult_result;
	wire alu_cmp_result;
	reg regfile_we_lsu;
	reg [5:0] regfile_waddr_lsu;
	reg wb_contention;
	reg wb_contention_lsu;
	wire alu_ready;
	wire mulh_active;
	wire mult_ready;
	wire apu_valid;
	wire [5:0] apu_waddr;
	wire [31:0] apu_result;
	wire apu_stall;
	wire apu_active;
	wire apu_singlecycle;
	wire apu_multicycle;
	wire apu_req;
	wire apu_gnt;
	reg apu_rvalid_q;
	reg [31:0] apu_result_q;
	reg [APU_NUSFLAGS_CPU - 1:0] apu_flags_q;
	always @(*) begin
		if (_sv2v_0)
			;
		regfile_alu_wdata_fw_o = 1'sb0;
		regfile_alu_waddr_fw_o = 1'sb0;
		regfile_alu_we_fw_o = 1'b0;
		regfile_alu_we_fw_power_o = 1'b0;
		wb_contention = 1'b0;
		if (apu_valid & (apu_singlecycle | apu_multicycle)) begin
			regfile_alu_we_fw_o = 1'b1;
			regfile_alu_we_fw_power_o = 1'b1;
			regfile_alu_waddr_fw_o = apu_waddr;
			regfile_alu_wdata_fw_o = apu_result;
			if (regfile_alu_we_i & ~apu_en_i)
				wb_contention = 1'b1;
		end
		else begin
			regfile_alu_we_fw_o = regfile_alu_we_i & ~apu_en_i;
			regfile_alu_we_fw_power_o = (COREV_PULP == 0 ? regfile_alu_we_i & ~apu_en_i : (((regfile_alu_we_i & ~apu_en_i) & mult_ready) & alu_ready) & lsu_ready_ex_i);
			regfile_alu_waddr_fw_o = regfile_alu_waddr_i;
			if (alu_en_i)
				regfile_alu_wdata_fw_o = alu_result;
			if (mult_en_i)
				regfile_alu_wdata_fw_o = mult_result;
			if (csr_access_i)
				regfile_alu_wdata_fw_o = csr_rdata_i;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		regfile_we_wb_o = 1'b0;
		regfile_we_wb_power_o = 1'b0;
		regfile_waddr_wb_o = regfile_waddr_lsu;
		regfile_wdata_wb_o = lsu_rdata_i;
		wb_contention_lsu = 1'b0;
		if (regfile_we_lsu) begin
			regfile_we_wb_o = 1'b1;
			regfile_we_wb_power_o = (COREV_PULP == 0 ? 1'b1 : ~data_misaligned_ex_i & wb_ready_i);
			if (apu_valid & (!apu_singlecycle & !apu_multicycle))
				wb_contention_lsu = 1'b1;
		end
		else if (apu_valid & (!apu_singlecycle & !apu_multicycle)) begin
			regfile_we_wb_o = 1'b1;
			regfile_we_wb_power_o = 1'b1;
			regfile_waddr_wb_o = apu_waddr;
			regfile_wdata_wb_o = apu_result;
		end
	end
	assign branch_decision_o = alu_cmp_result;
	assign jump_target_o = alu_operand_c_i;
	cv32e40p_alu alu_i(
		.clk(clk),
		.rst_n(rst_n),
		.enable_i(alu_en_i),
		.operator_i(alu_operator_i),
		.operand_a_i(alu_operand_a_i),
		.operand_b_i(alu_operand_b_i),
		.operand_c_i(alu_operand_c_i),
		.vector_mode_i(alu_vec_mode_i),
		.bmask_a_i(bmask_a_i),
		.bmask_b_i(bmask_b_i),
		.imm_vec_ext_i(imm_vec_ext_i),
		.is_clpx_i(alu_is_clpx_i),
		.clpx_shift_i(alu_clpx_shift_i),
		.is_subrot_i(alu_is_subrot_i),
		.result_o(alu_result),
		.comparison_result_o(alu_cmp_result),
		.ready_o(alu_ready),
		.ex_ready_i(ex_ready_o)
	);
	cv32e40p_mult mult_i(
		.clk(clk),
		.rst_n(rst_n),
		.enable_i(mult_en_i),
		.operator_i(mult_operator_i),
		.short_subword_i(mult_sel_subword_i),
		.short_signed_i(mult_signed_mode_i),
		.op_a_i(mult_operand_a_i),
		.op_b_i(mult_operand_b_i),
		.op_c_i(mult_operand_c_i),
		.imm_i(mult_imm_i),
		.dot_op_a_i(mult_dot_op_a_i),
		.dot_op_b_i(mult_dot_op_b_i),
		.dot_op_c_i(mult_dot_op_c_i),
		.dot_signed_i(mult_dot_signed_i),
		.is_clpx_i(mult_is_clpx_i),
		.clpx_shift_i(mult_clpx_shift_i),
		.clpx_img_i(mult_clpx_img_i),
		.result_o(mult_result),
		.multicycle_o(mult_multicycle_o),
		.mulh_active_o(mulh_active),
		.ready_o(mult_ready),
		.ex_ready_i(ex_ready_o)
	);
	localparam cv32e40p_pkg_BRANCH_JALR = 2'b10;
	function automatic [2:0] sv2v_cast_F9F94;
		input reg [2:0] inp;
		sv2v_cast_F9F94 = inp;
	endfunction
	generate
		if (FPU == 1) begin : gen_apu
			cv32e40p_apu_disp apu_disp_i(
				.clk_i(clk),
				.rst_ni(rst_n),
				.enable_i(apu_en_i),
				.apu_lat_i(apu_lat_i),
				.apu_waddr_i(apu_waddr_i),
				.apu_waddr_o(apu_waddr),
				.apu_multicycle_o(apu_multicycle),
				.apu_singlecycle_o(apu_singlecycle),
				.active_o(apu_active),
				.stall_o(apu_stall),
				.is_decoding_i(is_decoding_i),
				.read_regs_i(apu_read_regs_i),
				.read_regs_valid_i(apu_read_regs_valid_i),
				.read_dep_o(apu_read_dep_o),
				.read_dep_for_jalr_o(apu_read_dep_for_jalr_o),
				.write_regs_i(apu_write_regs_i),
				.write_regs_valid_i(apu_write_regs_valid_i),
				.write_dep_o(apu_write_dep_o),
				.perf_type_o(apu_perf_type_o),
				.perf_cont_o(apu_perf_cont_o),
				.apu_req_o(apu_req),
				.apu_gnt_i(apu_gnt),
				.apu_rvalid_i(apu_valid)
			);
			assign apu_perf_wb_o = wb_contention | wb_contention_lsu;
			assign apu_ready_wb_o = ~((apu_active | apu_en_i) | apu_stall) | apu_valid;
			always @(posedge clk or negedge rst_n) begin : APU_Result_Memorization
				if (~rst_n) begin
					apu_rvalid_q <= 1'b0;
					apu_result_q <= 'b0;
					apu_flags_q <= 'b0;
				end
				else if ((apu_rvalid_i && apu_multicycle) && ((((data_misaligned_i || data_misaligned_ex_i) || ((data_req_i || data_rvalid_i) && regfile_alu_we_i)) || (mulh_active && (mult_operator_i == sv2v_cast_F9F94(3'b110)))) || (((ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JALR) && regfile_alu_we_i) && ~apu_read_dep_for_jalr_o))) begin
					apu_rvalid_q <= 1'b1;
					apu_result_q <= apu_result_i;
					apu_flags_q <= apu_flags_i;
				end
				else if (apu_rvalid_q && !((((data_misaligned_i || data_misaligned_ex_i) || ((data_req_i || data_rvalid_i) && regfile_alu_we_i)) || (mulh_active && (mult_operator_i == sv2v_cast_F9F94(3'b110)))) || (((ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JALR) && regfile_alu_we_i) && ~apu_read_dep_for_jalr_o)))
					apu_rvalid_q <= 1'b0;
			end
			assign apu_req_o = apu_req;
			assign apu_gnt = apu_gnt_i;
			assign apu_valid = (apu_multicycle && ((((data_misaligned_i || data_misaligned_ex_i) || ((data_req_i || data_rvalid_i) && regfile_alu_we_i)) || (mulh_active && (mult_operator_i == sv2v_cast_F9F94(3'b110)))) || (((ctrl_transfer_insn_in_dec_i == cv32e40p_pkg_BRANCH_JALR) && regfile_alu_we_i) && ~apu_read_dep_for_jalr_o)) ? 1'b0 : apu_rvalid_i || apu_rvalid_q);
			assign apu_operands_o = apu_operands_i;
			assign apu_op_o = apu_op_i;
			assign apu_result = (apu_rvalid_q ? apu_result_q : apu_result_i);
			assign fpu_fflags_we_o = apu_valid;
			assign fpu_fflags_o = (apu_rvalid_q ? apu_flags_q : apu_flags_i);
		end
		else begin : gen_no_apu
			assign apu_req_o = 1'sb0;
			assign apu_operands_o[0+:32] = 1'sb0;
			assign apu_operands_o[32+:32] = 1'sb0;
			assign apu_operands_o[64+:32] = 1'sb0;
			assign apu_op_o = 1'sb0;
			assign apu_req = 1'b0;
			assign apu_gnt = 1'b0;
			assign apu_result = 32'b00000000000000000000000000000000;
			assign apu_valid = 1'b0;
			assign apu_waddr = 6'b000000;
			assign apu_stall = 1'b0;
			assign apu_active = 1'b0;
			assign apu_ready_wb_o = 1'b1;
			assign apu_perf_wb_o = 1'b0;
			assign apu_perf_cont_o = 1'b0;
			assign apu_perf_type_o = 1'b0;
			assign apu_singlecycle = 1'b0;
			assign apu_multicycle = 1'b0;
			assign apu_read_dep_o = 1'b0;
			assign apu_read_dep_for_jalr_o = 1'b0;
			assign apu_write_dep_o = 1'b0;
			assign fpu_fflags_o = 1'sb0;
			assign fpu_fflags_we_o = 1'sb0;
		end
	endgenerate
	assign apu_busy_o = apu_active;
	always @(posedge clk or negedge rst_n) begin : EX_WB_Pipeline_Register
		if (~rst_n) begin
			regfile_waddr_lsu <= 1'sb0;
			regfile_we_lsu <= 1'b0;
		end
		else if (ex_valid_o) begin
			regfile_we_lsu <= regfile_we_i & ~lsu_err_i;
			if (regfile_we_i & ~lsu_err_i)
				regfile_waddr_lsu <= regfile_waddr_i;
		end
		else if (wb_ready_i)
			regfile_we_lsu <= 1'b0;
	end
	assign ex_ready_o = (((((~apu_stall & alu_ready) & mult_ready) & lsu_ready_ex_i) & wb_ready_i) & ~wb_contention) | branch_in_ex_i;
	assign ex_valid_o = ((((apu_valid | alu_en_i) | mult_en_i) | csr_access_i) | lsu_en_i) & (((alu_ready & mult_ready) & lsu_ready_ex_i) & wb_ready_i);
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_ff_one (
	in_i,
	first_one_o,
	no_ones_o
);
	parameter LEN = 32;
	input wire [LEN - 1:0] in_i;
	output wire [$clog2(LEN) - 1:0] first_one_o;
	output wire no_ones_o;
	localparam NUM_LEVELS = $clog2(LEN);
	wire [(LEN * NUM_LEVELS) - 1:0] index_lut;
	wire [(2 ** NUM_LEVELS) - 1:0] sel_nodes;
	wire [((2 ** NUM_LEVELS) * NUM_LEVELS) - 1:0] index_nodes;
	genvar _gv_j_3;
	generate
		for (_gv_j_3 = 0; _gv_j_3 < LEN; _gv_j_3 = _gv_j_3 + 1) begin : gen_index_lut
			localparam j = _gv_j_3;
			assign index_lut[j * NUM_LEVELS+:NUM_LEVELS] = $unsigned(j);
		end
	endgenerate
	genvar _gv_k_2;
	genvar _gv_l_1;
	genvar _gv_level_1;
	assign sel_nodes[(2 ** NUM_LEVELS) - 1] = 1'b0;
	generate
		for (_gv_level_1 = 0; _gv_level_1 < NUM_LEVELS; _gv_level_1 = _gv_level_1 + 1) begin : gen_tree
			localparam level = _gv_level_1;
			if (level < (NUM_LEVELS - 1)) begin : gen_non_root_level
				for (_gv_l_1 = 0; _gv_l_1 < (2 ** level); _gv_l_1 = _gv_l_1 + 1) begin : gen_node
					localparam l = _gv_l_1;
					assign sel_nodes[((2 ** level) - 1) + l] = sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] | sel_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) + 1];
					assign index_nodes[(((2 ** level) - 1) + l) * NUM_LEVELS+:NUM_LEVELS] = (sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] == 1'b1 ? index_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) * NUM_LEVELS+:NUM_LEVELS] : index_nodes[((((2 ** (level + 1)) - 1) + (l * 2)) + 1) * NUM_LEVELS+:NUM_LEVELS]);
				end
			end
			if (level == (NUM_LEVELS - 1)) begin : gen_root_level
				for (_gv_k_2 = 0; _gv_k_2 < (2 ** level); _gv_k_2 = _gv_k_2 + 1) begin : gen_node
					localparam k = _gv_k_2;
					if ((k * 2) < (LEN - 1)) begin : gen_two
						assign sel_nodes[((2 ** level) - 1) + k] = in_i[k * 2] | in_i[(k * 2) + 1];
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = (in_i[k * 2] == 1'b1 ? index_lut[(k * 2) * NUM_LEVELS+:NUM_LEVELS] : index_lut[((k * 2) + 1) * NUM_LEVELS+:NUM_LEVELS]);
					end
					if ((k * 2) == (LEN - 1)) begin : gen_one
						assign sel_nodes[((2 ** level) - 1) + k] = in_i[k * 2];
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = index_lut[(k * 2) * NUM_LEVELS+:NUM_LEVELS];
					end
					if ((k * 2) > (LEN - 1)) begin : gen_out_of_range
						assign sel_nodes[((2 ** level) - 1) + k] = 1'b0;
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = 1'sb0;
					end
				end
			end
		end
	endgenerate
	assign first_one_o = index_nodes[0+:NUM_LEVELS];
	assign no_ones_o = ~sel_nodes[0];
endmodule
module cv32e40p_fifo (
	clk_i,
	rst_ni,
	flush_i,
	flush_but_first_i,
	testmode_i,
	full_o,
	empty_o,
	cnt_o,
	data_i,
	push_i,
	data_o,
	pop_i
);
	reg _sv2v_0;
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire flush_but_first_i;
	input wire testmode_i;
	output wire full_o;
	output wire empty_o;
	output wire [ADDR_DEPTH:0] cnt_o;
	input wire [DATA_WIDTH - 1:0] data_i;
	input wire push_i;
	output reg [DATA_WIDTH - 1:0] data_o;
	input wire pop_i;
	localparam [31:0] FIFO_DEPTH = (DEPTH > 0 ? DEPTH : 1);
	reg gate_clock;
	reg [ADDR_DEPTH - 1:0] read_pointer_n;
	reg [ADDR_DEPTH - 1:0] read_pointer_q;
	reg [ADDR_DEPTH - 1:0] write_pointer_n;
	reg [ADDR_DEPTH - 1:0] write_pointer_q;
	reg [ADDR_DEPTH:0] status_cnt_n;
	reg [ADDR_DEPTH:0] status_cnt_q;
	reg [(FIFO_DEPTH * DATA_WIDTH) - 1:0] mem_n;
	reg [(FIFO_DEPTH * DATA_WIDTH) - 1:0] mem_q;
	assign cnt_o = status_cnt_q;
	generate
		if (DEPTH == 0) begin : gen_zero_depth
			assign empty_o = ~push_i;
			assign full_o = ~pop_i;
		end
		else begin : gen_non_zero_depth
			assign full_o = status_cnt_q == FIFO_DEPTH[ADDR_DEPTH:0];
			assign empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i);
		end
	endgenerate
	always @(*) begin : read_write_comb
		if (_sv2v_0)
			;
		read_pointer_n = read_pointer_q;
		write_pointer_n = write_pointer_q;
		status_cnt_n = status_cnt_q;
		data_o = (DEPTH == 0 ? data_i : mem_q[read_pointer_q * DATA_WIDTH+:DATA_WIDTH]);
		mem_n = mem_q;
		gate_clock = 1'b1;
		if (push_i && ~full_o) begin
			mem_n[write_pointer_q * DATA_WIDTH+:DATA_WIDTH] = data_i;
			gate_clock = 1'b0;
			if (write_pointer_q == (FIFO_DEPTH[ADDR_DEPTH - 1:0] - 1))
				write_pointer_n = 1'sb0;
			else
				write_pointer_n = write_pointer_q + 1;
			status_cnt_n = status_cnt_q + 1;
		end
		if (pop_i && ~empty_o) begin
			if (read_pointer_n == (FIFO_DEPTH[ADDR_DEPTH - 1:0] - 1))
				read_pointer_n = 1'sb0;
			else
				read_pointer_n = read_pointer_q + 1;
			status_cnt_n = status_cnt_q - 1;
		end
		if (((push_i && pop_i) && ~full_o) && ~empty_o)
			status_cnt_n = status_cnt_q;
		if ((FALL_THROUGH && (status_cnt_q == 0)) && push_i) begin
			data_o = data_i;
			if (pop_i) begin
				status_cnt_n = status_cnt_q;
				read_pointer_n = read_pointer_q;
				write_pointer_n = write_pointer_q;
			end
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			read_pointer_q <= 1'sb0;
			write_pointer_q <= 1'sb0;
			status_cnt_q <= 1'sb0;
		end
		else
			(* full_case, parallel_case *)
			case (1'b1)
				flush_i: begin
					read_pointer_q <= 1'sb0;
					write_pointer_q <= 1'sb0;
					status_cnt_q <= 1'sb0;
				end
				flush_but_first_i: begin
					read_pointer_q <= (status_cnt_q > 0 ? read_pointer_q : {ADDR_DEPTH {1'sb0}});
					write_pointer_q <= (status_cnt_q > 0 ? read_pointer_q + 1 : {ADDR_DEPTH {1'sb0}});
					status_cnt_q <= (status_cnt_q > 0 ? 1'b1 : {(ADDR_DEPTH >= 0 ? ADDR_DEPTH + 1 : 1 - ADDR_DEPTH) {1'sb0}});
				end
				default: begin
					read_pointer_q <= read_pointer_n;
					write_pointer_q <= write_pointer_n;
					status_cnt_q <= status_cnt_n;
				end
			endcase
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			mem_q <= 1'sb0;
		else if (!gate_clock)
			mem_q <= mem_n;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_fp_wrapper (
	clk_i,
	rst_ni,
	apu_req_i,
	apu_gnt_o,
	apu_operands_i,
	apu_op_i,
	apu_flags_i,
	apu_rvalid_o,
	apu_rdata_o,
	apu_rflags_o
);
	parameter FPU_ADDMUL_LAT = 0;
	parameter FPU_OTHERS_LAT = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire apu_req_i;
	output wire apu_gnt_o;
	localparam cv32e40p_apu_core_pkg_APU_NARGS_CPU = 3;
	input wire [95:0] apu_operands_i;
	localparam cv32e40p_apu_core_pkg_APU_WOP_CPU = 6;
	input wire [5:0] apu_op_i;
	localparam cv32e40p_apu_core_pkg_APU_NDSFLAGS_CPU = 15;
	input wire [14:0] apu_flags_i;
	output wire apu_rvalid_o;
	output wire [31:0] apu_rdata_o;
	localparam cv32e40p_apu_core_pkg_APU_NUSFLAGS_CPU = 5;
	output wire [4:0] apu_rflags_o;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	wire [3:0] fpu_op;
	wire fpu_op_mod;
	wire fpu_vec_op;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	wire [2:0] fpu_dst_fmt;
	wire [2:0] fpu_src_fmt;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	wire [1:0] fpu_int_fmt;
	localparam cv32e40p_pkg_C_RM = 3;
	wire [2:0] fp_rnd_mode;
	assign {fpu_vec_op, fpu_op_mod, fpu_op} = apu_op_i;
	assign {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode} = apu_flags_i;
	localparam [0:0] cv32e40p_pkg_C_RVD = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_RVF = 1'b1;
	localparam [0:0] cv32e40p_pkg_C_XF16 = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XF16ALT = 1'b0;
	localparam [0:0] cv32e40p_pkg_C_XF8 = 1'b0;
	localparam cv32e40p_pkg_C_FLEN = (cv32e40p_pkg_C_RVD ? 64 : (cv32e40p_pkg_C_RVF ? 32 : (cv32e40p_pkg_C_XF16 ? 16 : (cv32e40p_pkg_C_XF16ALT ? 16 : (cv32e40p_pkg_C_XF8 ? 8 : 0)))));
	localparam [0:0] cv32e40p_pkg_C_XFVEC = 1'b0;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	localparam [42:0] FPU_FEATURES = {sv2v_cast_32(cv32e40p_pkg_C_FLEN), cv32e40p_pkg_C_XFVEC, 1'b0, sv2v_cast_5({cv32e40p_pkg_C_RVF, cv32e40p_pkg_C_RVD, cv32e40p_pkg_C_XF16, cv32e40p_pkg_C_XF8, cv32e40p_pkg_C_XF16ALT}), 4'h2};
	localparam [31:0] cv32e40p_pkg_C_LAT_DIVSQRT = 'd1;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP16 = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP16ALT = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP64 = 'd0;
	localparam [31:0] cv32e40p_pkg_C_LAT_FP8 = 'd0;
	localparam [31:0] fpnew_pkg_NUM_OPGROUPS = 4;
	function automatic [((32'd4 * 32'd5) * 32) - 1:0] sv2v_cast_9CB06;
		input reg [((32'd4 * 32'd5) * 32) - 1:0] inp;
		sv2v_cast_9CB06 = inp;
	endfunction
	function automatic [((32'd4 * 32'd5) * 2) - 1:0] sv2v_cast_2DA10;
		input reg [((32'd4 * 32'd5) * 2) - 1:0] inp;
		sv2v_cast_2DA10 = inp;
	endfunction
	localparam [(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) + ((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2)) + 1:0] FPU_IMPLEMENTATION = {sv2v_cast_9CB06({FPU_ADDMUL_LAT, cv32e40p_pkg_C_LAT_FP64, cv32e40p_pkg_C_LAT_FP16, cv32e40p_pkg_C_LAT_FP8, cv32e40p_pkg_C_LAT_FP16ALT, {fpnew_pkg_NUM_FP_FORMATS {cv32e40p_pkg_C_LAT_DIVSQRT}}, {fpnew_pkg_NUM_FP_FORMATS {sv2v_cast_32(FPU_OTHERS_LAT)}}, {fpnew_pkg_NUM_FP_FORMATS {sv2v_cast_32(FPU_OTHERS_LAT)}}}), sv2v_cast_2DA10({{fpnew_pkg_NUM_FP_FORMATS {2'd2}}, {fpnew_pkg_NUM_FP_FORMATS {2'd2}}, {fpnew_pkg_NUM_FP_FORMATS {2'd1}}, {fpnew_pkg_NUM_FP_FORMATS {2'd2}}}), 2'd1};
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_2D3A8;
		input reg [1:0] inp;
		sv2v_cast_2D3A8 = inp;
	endfunction
	fpnew_top_CBA7B #(
		.Features(FPU_FEATURES),
		.Implementation(FPU_IMPLEMENTATION),
		.PulpDivsqrt(1'b0)
	) i_fpnew_bulk(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.operands_i(apu_operands_i),
		.rnd_mode_i(fp_rnd_mode),
		.op_i(sv2v_cast_7BCAE(fpu_op)),
		.op_mod_i(fpu_op_mod),
		.src_fmt_i(sv2v_cast_9FB13(fpu_src_fmt)),
		.dst_fmt_i(sv2v_cast_9FB13(fpu_dst_fmt)),
		.int_fmt_i(sv2v_cast_2D3A8(fpu_int_fmt)),
		.vectorial_op_i(fpu_vec_op),
		.tag_i(1'b0),
		.simd_mask_i(1'b0),
		.in_valid_i(apu_req_i),
		.in_ready_o(apu_gnt_o),
		.flush_i(1'b0),
		.result_o(apu_rdata_o),
		.status_o(apu_rflags_o),
		.tag_o(),
		.out_valid_o(apu_rvalid_o),
		.out_ready_i(1'b1),
		.busy_o()
	);
endmodule
module cv32e40p_hwloop_regs (
	clk,
	rst_n,
	hwlp_start_data_i,
	hwlp_end_data_i,
	hwlp_cnt_data_i,
	hwlp_we_i,
	hwlp_regid_i,
	valid_i,
	hwlp_dec_cnt_i,
	hwlp_start_addr_o,
	hwlp_end_addr_o,
	hwlp_counter_o
);
	parameter N_REGS = 2;
	parameter N_REG_BITS = $clog2(N_REGS);
	input wire clk;
	input wire rst_n;
	input wire [31:0] hwlp_start_data_i;
	input wire [31:0] hwlp_end_data_i;
	input wire [31:0] hwlp_cnt_data_i;
	input wire [2:0] hwlp_we_i;
	input wire [N_REG_BITS - 1:0] hwlp_regid_i;
	input wire valid_i;
	input wire [N_REGS - 1:0] hwlp_dec_cnt_i;
	output wire [(N_REGS * 32) - 1:0] hwlp_start_addr_o;
	output wire [(N_REGS * 32) - 1:0] hwlp_end_addr_o;
	output wire [(N_REGS * 32) - 1:0] hwlp_counter_o;
	reg [(N_REGS * 32) - 1:0] hwlp_start_q;
	reg [(N_REGS * 32) - 1:0] hwlp_end_q;
	reg [(N_REGS * 32) - 1:0] hwlp_counter_q;
	wire [(N_REGS * 32) - 1:0] hwlp_counter_n;
	reg [31:0] i;
	assign hwlp_start_addr_o = hwlp_start_q;
	assign hwlp_end_addr_o = hwlp_end_q;
	assign hwlp_counter_o = hwlp_counter_q;
	always @(posedge clk or negedge rst_n) begin : HWLOOP_REGS_START
		if (rst_n == 1'b0)
			hwlp_start_q <= {N_REGS {32'b00000000000000000000000000000000}};
		else if (hwlp_we_i[0] == 1'b1)
			hwlp_start_q[hwlp_regid_i * 32+:32] <= {hwlp_start_data_i[31:2], 2'b00};
	end
	always @(posedge clk or negedge rst_n) begin : HWLOOP_REGS_END
		if (rst_n == 1'b0)
			hwlp_end_q <= {N_REGS {32'b00000000000000000000000000000000}};
		else if (hwlp_we_i[1] == 1'b1)
			hwlp_end_q[hwlp_regid_i * 32+:32] <= {hwlp_end_data_i[31:2], 2'b00};
	end
	genvar _gv_k_3;
	generate
		for (_gv_k_3 = 0; _gv_k_3 < N_REGS; _gv_k_3 = _gv_k_3 + 1) begin : genblk1
			localparam k = _gv_k_3;
			assign hwlp_counter_n[k * 32+:32] = hwlp_counter_q[k * 32+:32] - 1;
		end
	endgenerate
	always @(posedge clk or negedge rst_n) begin : HWLOOP_REGS_COUNTER
		if (rst_n == 1'b0)
			hwlp_counter_q <= {N_REGS {32'b00000000000000000000000000000000}};
		else
			for (i = 0; i < N_REGS; i = i + 1)
				if ((hwlp_we_i[2] == 1'b1) && (i == hwlp_regid_i))
					hwlp_counter_q[i * 32+:32] <= hwlp_cnt_data_i;
				else if (hwlp_dec_cnt_i[i] && valid_i)
					hwlp_counter_q[i * 32+:32] <= hwlp_counter_n[i * 32+:32];
	end
endmodule
module cv32e40p_id_stage (
	clk,
	clk_ungated_i,
	rst_n,
	scan_cg_en_i,
	fetch_enable_i,
	ctrl_busy_o,
	is_decoding_o,
	instr_valid_i,
	instr_rdata_i,
	instr_req_o,
	is_compressed_i,
	illegal_c_insn_i,
	branch_in_ex_o,
	branch_decision_i,
	jump_target_o,
	ctrl_transfer_insn_in_dec_o,
	clear_instr_valid_o,
	pc_set_o,
	pc_mux_o,
	exc_pc_mux_o,
	trap_addr_mux_o,
	is_fetch_failed_i,
	pc_id_i,
	halt_if_o,
	id_ready_o,
	ex_ready_i,
	wb_ready_i,
	id_valid_o,
	ex_valid_i,
	pc_ex_o,
	alu_operand_a_ex_o,
	alu_operand_b_ex_o,
	alu_operand_c_ex_o,
	bmask_a_ex_o,
	bmask_b_ex_o,
	imm_vec_ext_ex_o,
	alu_vec_mode_ex_o,
	regfile_waddr_ex_o,
	regfile_we_ex_o,
	regfile_alu_waddr_ex_o,
	regfile_alu_we_ex_o,
	alu_en_ex_o,
	alu_operator_ex_o,
	alu_is_clpx_ex_o,
	alu_is_subrot_ex_o,
	alu_clpx_shift_ex_o,
	mult_operator_ex_o,
	mult_operand_a_ex_o,
	mult_operand_b_ex_o,
	mult_operand_c_ex_o,
	mult_en_ex_o,
	mult_sel_subword_ex_o,
	mult_signed_mode_ex_o,
	mult_imm_ex_o,
	mult_dot_op_a_ex_o,
	mult_dot_op_b_ex_o,
	mult_dot_op_c_ex_o,
	mult_dot_signed_ex_o,
	mult_is_clpx_ex_o,
	mult_clpx_shift_ex_o,
	mult_clpx_img_ex_o,
	apu_en_ex_o,
	apu_op_ex_o,
	apu_lat_ex_o,
	apu_operands_ex_o,
	apu_flags_ex_o,
	apu_waddr_ex_o,
	apu_read_regs_o,
	apu_read_regs_valid_o,
	apu_read_dep_i,
	apu_read_dep_for_jalr_i,
	apu_write_regs_o,
	apu_write_regs_valid_o,
	apu_write_dep_i,
	apu_perf_dep_o,
	apu_busy_i,
	fs_off_i,
	frm_i,
	csr_access_ex_o,
	csr_op_ex_o,
	current_priv_lvl_i,
	csr_irq_sec_o,
	csr_cause_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_ex_o,
	csr_restore_mret_id_o,
	csr_restore_uret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	hwlp_start_o,
	hwlp_end_o,
	hwlp_cnt_o,
	hwlp_jump_o,
	hwlp_target_o,
	data_req_ex_o,
	data_we_ex_o,
	data_type_ex_o,
	data_sign_ext_ex_o,
	data_reg_offset_ex_o,
	data_load_event_ex_o,
	data_misaligned_ex_o,
	prepost_useincr_ex_o,
	data_misaligned_i,
	data_err_i,
	data_err_ack_o,
	atop_ex_o,
	irq_i,
	irq_sec_i,
	mie_bypass_i,
	mip_o,
	m_irq_enable_i,
	u_irq_enable_i,
	irq_ack_o,
	irq_id_o,
	exc_cause_o,
	debug_mode_o,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	debug_p_elw_no_sleep_o,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o,
	wake_from_sleep_o,
	regfile_waddr_wb_i,
	regfile_we_wb_i,
	regfile_we_wb_power_i,
	regfile_wdata_wb_i,
	regfile_alu_waddr_fw_i,
	regfile_alu_we_fw_i,
	regfile_alu_we_fw_power_i,
	regfile_alu_wdata_fw_i,
	mult_multicycle_i,
	mhpmevent_minstret_o,
	mhpmevent_load_o,
	mhpmevent_store_o,
	mhpmevent_jump_o,
	mhpmevent_branch_o,
	mhpmevent_branch_taken_o,
	mhpmevent_compressed_o,
	mhpmevent_jr_stall_o,
	mhpmevent_imiss_o,
	mhpmevent_ld_stall_o,
	mhpmevent_pipe_stall_o,
	perf_imiss_i,
	mcounteren_i
);
	reg _sv2v_0;
	parameter COREV_PULP = 1;
	parameter COREV_CLUSTER = 0;
	parameter N_HWLP = 2;
	parameter N_HWLP_BITS = $clog2(N_HWLP);
	parameter PULP_SECURE = 0;
	parameter USE_PMP = 0;
	parameter A_EXTENSION = 0;
	parameter APU = 0;
	parameter FPU = 0;
	parameter FPU_ADDMUL_LAT = 0;
	parameter FPU_OTHERS_LAT = 0;
	parameter ZFINX = 0;
	parameter APU_NARGS_CPU = 3;
	parameter APU_WOP_CPU = 6;
	parameter APU_NDSFLAGS_CPU = 15;
	parameter APU_NUSFLAGS_CPU = 5;
	parameter DEBUG_TRIGGER_EN = 1;
	input wire clk;
	input wire clk_ungated_i;
	input wire rst_n;
	input wire scan_cg_en_i;
	input wire fetch_enable_i;
	output wire ctrl_busy_o;
	output wire is_decoding_o;
	input wire instr_valid_i;
	input wire [31:0] instr_rdata_i;
	output wire instr_req_o;
	input wire is_compressed_i;
	input wire illegal_c_insn_i;
	output reg branch_in_ex_o;
	input wire branch_decision_i;
	output wire [31:0] jump_target_o;
	output wire [1:0] ctrl_transfer_insn_in_dec_o;
	output wire clear_instr_valid_o;
	output wire pc_set_o;
	output wire [3:0] pc_mux_o;
	output wire [2:0] exc_pc_mux_o;
	output wire [1:0] trap_addr_mux_o;
	input wire is_fetch_failed_i;
	input wire [31:0] pc_id_i;
	output wire halt_if_o;
	output wire id_ready_o;
	input wire ex_ready_i;
	input wire wb_ready_i;
	output wire id_valid_o;
	input wire ex_valid_i;
	output reg [31:0] pc_ex_o;
	output reg [31:0] alu_operand_a_ex_o;
	output reg [31:0] alu_operand_b_ex_o;
	output reg [31:0] alu_operand_c_ex_o;
	output reg [4:0] bmask_a_ex_o;
	output reg [4:0] bmask_b_ex_o;
	output reg [1:0] imm_vec_ext_ex_o;
	output reg [1:0] alu_vec_mode_ex_o;
	output reg [5:0] regfile_waddr_ex_o;
	output reg regfile_we_ex_o;
	output reg [5:0] regfile_alu_waddr_ex_o;
	output reg regfile_alu_we_ex_o;
	output reg alu_en_ex_o;
	localparam cv32e40p_pkg_ALU_OP_WIDTH = 7;
	output reg [6:0] alu_operator_ex_o;
	output reg alu_is_clpx_ex_o;
	output reg alu_is_subrot_ex_o;
	output reg [1:0] alu_clpx_shift_ex_o;
	localparam cv32e40p_pkg_MUL_OP_WIDTH = 3;
	output reg [2:0] mult_operator_ex_o;
	output reg [31:0] mult_operand_a_ex_o;
	output reg [31:0] mult_operand_b_ex_o;
	output reg [31:0] mult_operand_c_ex_o;
	output reg mult_en_ex_o;
	output reg mult_sel_subword_ex_o;
	output reg [1:0] mult_signed_mode_ex_o;
	output reg [4:0] mult_imm_ex_o;
	output reg [31:0] mult_dot_op_a_ex_o;
	output reg [31:0] mult_dot_op_b_ex_o;
	output reg [31:0] mult_dot_op_c_ex_o;
	output reg [1:0] mult_dot_signed_ex_o;
	output reg mult_is_clpx_ex_o;
	output reg [1:0] mult_clpx_shift_ex_o;
	output reg mult_clpx_img_ex_o;
	output reg apu_en_ex_o;
	output reg [APU_WOP_CPU - 1:0] apu_op_ex_o;
	output reg [1:0] apu_lat_ex_o;
	output reg [(APU_NARGS_CPU * 32) - 1:0] apu_operands_ex_o;
	output reg [APU_NDSFLAGS_CPU - 1:0] apu_flags_ex_o;
	output reg [5:0] apu_waddr_ex_o;
	output wire [17:0] apu_read_regs_o;
	output wire [2:0] apu_read_regs_valid_o;
	input wire apu_read_dep_i;
	input wire apu_read_dep_for_jalr_i;
	output wire [11:0] apu_write_regs_o;
	output wire [1:0] apu_write_regs_valid_o;
	input wire apu_write_dep_i;
	output wire apu_perf_dep_o;
	input wire apu_busy_i;
	input wire fs_off_i;
	localparam cv32e40p_pkg_C_RM = 3;
	input wire [2:0] frm_i;
	output reg csr_access_ex_o;
	localparam cv32e40p_pkg_CSR_OP_WIDTH = 2;
	output reg [1:0] csr_op_ex_o;
	input wire [1:0] current_priv_lvl_i;
	output wire csr_irq_sec_o;
	output wire [5:0] csr_cause_o;
	output wire csr_save_if_o;
	output wire csr_save_id_o;
	output wire csr_save_ex_o;
	output wire csr_restore_mret_id_o;
	output wire csr_restore_uret_id_o;
	output wire csr_restore_dret_id_o;
	output wire csr_save_cause_o;
	output wire [(N_HWLP * 32) - 1:0] hwlp_start_o;
	output wire [(N_HWLP * 32) - 1:0] hwlp_end_o;
	output wire [(N_HWLP * 32) - 1:0] hwlp_cnt_o;
	output wire hwlp_jump_o;
	output wire [31:0] hwlp_target_o;
	output reg data_req_ex_o;
	output reg data_we_ex_o;
	output reg [1:0] data_type_ex_o;
	output reg [1:0] data_sign_ext_ex_o;
	output reg [1:0] data_reg_offset_ex_o;
	output reg data_load_event_ex_o;
	output reg data_misaligned_ex_o;
	output reg prepost_useincr_ex_o;
	input wire data_misaligned_i;
	input wire data_err_i;
	output wire data_err_ack_o;
	output reg [5:0] atop_ex_o;
	input wire [31:0] irq_i;
	input wire irq_sec_i;
	input wire [31:0] mie_bypass_i;
	output wire [31:0] mip_o;
	input wire m_irq_enable_i;
	input wire u_irq_enable_i;
	output wire irq_ack_o;
	output wire [4:0] irq_id_o;
	output wire [4:0] exc_cause_o;
	output wire debug_mode_o;
	output wire [2:0] debug_cause_o;
	output wire debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	output wire debug_p_elw_no_sleep_o;
	output wire debug_havereset_o;
	output wire debug_running_o;
	output wire debug_halted_o;
	output wire wake_from_sleep_o;
	input wire [5:0] regfile_waddr_wb_i;
	input wire regfile_we_wb_i;
	input wire regfile_we_wb_power_i;
	input wire [31:0] regfile_wdata_wb_i;
	input wire [5:0] regfile_alu_waddr_fw_i;
	input wire regfile_alu_we_fw_i;
	input wire regfile_alu_we_fw_power_i;
	input wire [31:0] regfile_alu_wdata_fw_i;
	input wire mult_multicycle_i;
	output reg mhpmevent_minstret_o;
	output reg mhpmevent_load_o;
	output reg mhpmevent_store_o;
	output reg mhpmevent_jump_o;
	output reg mhpmevent_branch_o;
	output reg mhpmevent_branch_taken_o;
	output reg mhpmevent_compressed_o;
	output reg mhpmevent_jr_stall_o;
	output reg mhpmevent_imiss_o;
	output reg mhpmevent_ld_stall_o;
	output reg mhpmevent_pipe_stall_o;
	input wire perf_imiss_i;
	input wire [31:0] mcounteren_i;
	localparam REG_S1_MSB = 19;
	localparam REG_S1_LSB = 15;
	localparam REG_S2_MSB = 24;
	localparam REG_S2_LSB = 20;
	localparam REG_S4_MSB = 31;
	localparam REG_S4_LSB = 27;
	localparam REG_D_MSB = 11;
	localparam REG_D_LSB = 7;
	wire [31:0] instr;
	wire deassert_we;
	wire illegal_insn_dec;
	wire ebrk_insn_dec;
	wire mret_insn_dec;
	wire uret_insn_dec;
	wire dret_insn_dec;
	wire ecall_insn_dec;
	wire wfi_insn_dec;
	wire fencei_insn_dec;
	wire rega_used_dec;
	wire regb_used_dec;
	wire regc_used_dec;
	wire branch_taken_ex;
	wire [1:0] ctrl_transfer_insn_in_id;
	wire [1:0] ctrl_transfer_insn_in_dec;
	wire misaligned_stall;
	wire jr_stall;
	wire load_stall;
	wire csr_apu_stall;
	wire hwlp_mask;
	wire halt_id;
	wire halt_if;
	wire debug_wfi_no_sleep;
	wire [31:0] imm_i_type;
	wire [31:0] imm_iz_type;
	wire [31:0] imm_s_type;
	wire [31:0] imm_sb_type;
	wire [31:0] imm_u_type;
	wire [31:0] imm_uj_type;
	wire [31:0] imm_z_type;
	wire [31:0] imm_s2_type;
	wire [31:0] imm_bi_type;
	wire [31:0] imm_s3_type;
	wire [31:0] imm_vs_type;
	wire [31:0] imm_vu_type;
	wire [31:0] imm_shuffleb_type;
	wire [31:0] imm_shuffleh_type;
	reg [31:0] imm_shuffle_type;
	wire [31:0] imm_clip_type;
	reg [31:0] imm_a;
	reg [31:0] imm_b;
	reg [31:0] jump_target;
	wire irq_req_ctrl;
	wire irq_sec_ctrl;
	wire irq_wu_ctrl;
	wire [4:0] irq_id_ctrl;
	wire [5:0] regfile_addr_ra_id;
	wire [5:0] regfile_addr_rb_id;
	reg [5:0] regfile_addr_rc_id;
	wire regfile_fp_a;
	wire regfile_fp_b;
	wire regfile_fp_c;
	wire regfile_fp_d;
	wire [5:0] regfile_waddr_id;
	wire [5:0] regfile_alu_waddr_id;
	wire regfile_alu_we_id;
	wire regfile_alu_we_dec_id;
	wire [31:0] regfile_data_ra_id;
	wire [31:0] regfile_data_rb_id;
	wire [31:0] regfile_data_rc_id;
	wire alu_en;
	wire [6:0] alu_operator;
	wire [2:0] alu_op_a_mux_sel;
	wire [2:0] alu_op_b_mux_sel;
	wire [1:0] alu_op_c_mux_sel;
	wire [1:0] regc_mux;
	wire [0:0] imm_a_mux_sel;
	wire [3:0] imm_b_mux_sel;
	wire [1:0] ctrl_transfer_target_mux_sel;
	wire [2:0] mult_operator;
	wire mult_en;
	wire mult_int_en;
	wire mult_sel_subword;
	wire [1:0] mult_signed_mode;
	wire mult_dot_en;
	wire [1:0] mult_dot_signed;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] cv32e40p_fpu_pkg_FP_FORMAT_BITS = 3;
	wire [2:0] fpu_src_fmt;
	wire [2:0] fpu_dst_fmt;
	localparam [31:0] cv32e40p_fpu_pkg_NUM_INT_FORMATS = 4;
	localparam [31:0] cv32e40p_fpu_pkg_INT_FORMAT_BITS = 2;
	wire [1:0] fpu_int_fmt;
	wire apu_en;
	wire [APU_WOP_CPU - 1:0] apu_op;
	wire [1:0] apu_lat;
	wire [(APU_NARGS_CPU * 32) - 1:0] apu_operands;
	wire [APU_NDSFLAGS_CPU - 1:0] apu_flags;
	wire [5:0] apu_waddr;
	reg [17:0] apu_read_regs;
	reg [2:0] apu_read_regs_valid;
	wire [11:0] apu_write_regs;
	wire [1:0] apu_write_regs_valid;
	wire apu_stall;
	wire [2:0] fp_rnd_mode;
	wire regfile_we_id;
	wire regfile_alu_waddr_mux_sel;
	wire data_we_id;
	wire [1:0] data_type_id;
	wire [1:0] data_sign_ext_id;
	wire [1:0] data_reg_offset_id;
	wire data_req_id;
	wire data_load_event_id;
	wire [5:0] atop_id;
	wire [N_HWLP_BITS - 1:0] hwlp_regid;
	wire [2:0] hwlp_we;
	wire [2:0] hwlp_we_masked;
	wire [1:0] hwlp_target_mux_sel;
	wire [1:0] hwlp_start_mux_sel;
	wire hwlp_cnt_mux_sel;
	reg [31:0] hwlp_start;
	reg [31:0] hwlp_end;
	reg [31:0] hwlp_cnt;
	wire [N_HWLP - 1:0] hwlp_dec_cnt;
	wire hwlp_valid;
	wire csr_access;
	wire [1:0] csr_op;
	wire csr_status;
	wire prepost_useincr;
	wire [1:0] operand_a_fw_mux_sel;
	wire [1:0] operand_b_fw_mux_sel;
	wire [1:0] operand_c_fw_mux_sel;
	reg [31:0] operand_a_fw_id;
	reg [31:0] operand_b_fw_id;
	reg [31:0] operand_c_fw_id;
	reg [31:0] operand_b;
	reg [31:0] operand_b_vec;
	reg [31:0] operand_c;
	reg [31:0] operand_c_vec;
	reg [31:0] alu_operand_a;
	wire [31:0] alu_operand_b;
	wire [31:0] alu_operand_c;
	wire [0:0] bmask_a_mux;
	wire [1:0] bmask_b_mux;
	wire alu_bmask_a_mux_sel;
	wire alu_bmask_b_mux_sel;
	wire [0:0] mult_imm_mux;
	reg [4:0] bmask_a_id_imm;
	reg [4:0] bmask_b_id_imm;
	reg [4:0] bmask_a_id;
	reg [4:0] bmask_b_id;
	wire [1:0] imm_vec_ext_id;
	reg [4:0] mult_imm_id;
	wire alu_vec;
	wire [1:0] alu_vec_mode;
	wire scalar_replication;
	wire scalar_replication_c;
	wire reg_d_ex_is_reg_a_id;
	wire reg_d_ex_is_reg_b_id;
	wire reg_d_ex_is_reg_c_id;
	wire reg_d_wb_is_reg_a_id;
	wire reg_d_wb_is_reg_b_id;
	wire reg_d_wb_is_reg_c_id;
	wire reg_d_alu_is_reg_a_id;
	wire reg_d_alu_is_reg_b_id;
	wire reg_d_alu_is_reg_c_id;
	wire is_clpx;
	wire is_subrot;
	wire mret_dec;
	wire uret_dec;
	wire dret_dec;
	reg id_valid_q;
	wire minstret;
	wire perf_pipeline_stall;
	assign instr = instr_rdata_i;
	assign imm_i_type = {{20 {instr[31]}}, instr[31:20]};
	assign imm_iz_type = {20'b00000000000000000000, instr[31:20]};
	assign imm_s_type = {{20 {instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_sb_type = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_u_type = {instr[31:12], 12'b000000000000};
	assign imm_uj_type = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign imm_z_type = {27'b000000000000000000000000000, instr[REG_S1_MSB:REG_S1_LSB]};
	assign imm_s2_type = {27'b000000000000000000000000000, instr[24:20]};
	assign imm_bi_type = {{27 {instr[24]}}, instr[24:20]};
	assign imm_s3_type = {27'b000000000000000000000000000, instr[29:25]};
	assign imm_vs_type = {{26 {instr[24]}}, instr[24:20], instr[25]};
	assign imm_vu_type = {26'b00000000000000000000000000, instr[24:20], instr[25]};
	assign imm_shuffleb_type = {6'b000000, instr[28:27], 6'b000000, instr[24:23], 6'b000000, instr[22:21], 6'b000000, instr[20], instr[25]};
	assign imm_shuffleh_type = {15'h0000, instr[20], 15'h0000, instr[25]};
	assign imm_clip_type = (32'h00000001 << instr[24:20]) - 1;
	assign regfile_addr_ra_id = {regfile_fp_a, instr[REG_S1_MSB:REG_S1_LSB]};
	assign regfile_addr_rb_id = {regfile_fp_b, instr[REG_S2_MSB:REG_S2_LSB]};
	localparam cv32e40p_pkg_REGC_RD = 2'b01;
	localparam cv32e40p_pkg_REGC_S1 = 2'b10;
	localparam cv32e40p_pkg_REGC_S4 = 2'b00;
	localparam cv32e40p_pkg_REGC_ZERO = 2'b11;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (regc_mux)
			cv32e40p_pkg_REGC_ZERO: regfile_addr_rc_id = 1'sb0;
			cv32e40p_pkg_REGC_RD: regfile_addr_rc_id = {regfile_fp_c, instr[REG_D_MSB:REG_D_LSB]};
			cv32e40p_pkg_REGC_S1: regfile_addr_rc_id = {regfile_fp_c, instr[REG_S1_MSB:REG_S1_LSB]};
			cv32e40p_pkg_REGC_S4: regfile_addr_rc_id = {regfile_fp_c, instr[REG_S4_MSB:REG_S4_LSB]};
		endcase
	end
	assign regfile_waddr_id = {regfile_fp_d, instr[REG_D_MSB:REG_D_LSB]};
	assign regfile_alu_waddr_id = (regfile_alu_waddr_mux_sel ? regfile_waddr_id : regfile_addr_ra_id);
	assign reg_d_ex_is_reg_a_id = ((regfile_waddr_ex_o == regfile_addr_ra_id) && (rega_used_dec == 1'b1)) && (regfile_addr_ra_id != {6 {1'sb0}});
	assign reg_d_ex_is_reg_b_id = ((regfile_waddr_ex_o == regfile_addr_rb_id) && (regb_used_dec == 1'b1)) && (regfile_addr_rb_id != {6 {1'sb0}});
	assign reg_d_ex_is_reg_c_id = ((regfile_waddr_ex_o == regfile_addr_rc_id) && (regc_used_dec == 1'b1)) && (regfile_addr_rc_id != {6 {1'sb0}});
	assign reg_d_wb_is_reg_a_id = ((regfile_waddr_wb_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1)) && (regfile_addr_ra_id != {6 {1'sb0}});
	assign reg_d_wb_is_reg_b_id = ((regfile_waddr_wb_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1)) && (regfile_addr_rb_id != {6 {1'sb0}});
	assign reg_d_wb_is_reg_c_id = ((regfile_waddr_wb_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1)) && (regfile_addr_rc_id != {6 {1'sb0}});
	assign reg_d_alu_is_reg_a_id = ((regfile_alu_waddr_fw_i == regfile_addr_ra_id) && (rega_used_dec == 1'b1)) && (regfile_addr_ra_id != {6 {1'sb0}});
	assign reg_d_alu_is_reg_b_id = ((regfile_alu_waddr_fw_i == regfile_addr_rb_id) && (regb_used_dec == 1'b1)) && (regfile_addr_rb_id != {6 {1'sb0}});
	assign reg_d_alu_is_reg_c_id = ((regfile_alu_waddr_fw_i == regfile_addr_rc_id) && (regc_used_dec == 1'b1)) && (regfile_addr_rc_id != {6 {1'sb0}});
	assign clear_instr_valid_o = (id_ready_o | halt_id) | branch_taken_ex;
	assign branch_taken_ex = branch_in_ex_o && branch_decision_i;
	assign mult_en = mult_int_en | mult_dot_en;
	localparam cv32e40p_pkg_JT_COND = 2'b11;
	localparam cv32e40p_pkg_JT_JAL = 2'b01;
	localparam cv32e40p_pkg_JT_JALR = 2'b10;
	always @(*) begin : jump_target_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (ctrl_transfer_target_mux_sel)
			cv32e40p_pkg_JT_JAL: jump_target = pc_id_i + imm_uj_type;
			cv32e40p_pkg_JT_COND: jump_target = pc_id_i + imm_sb_type;
			cv32e40p_pkg_JT_JALR: jump_target = regfile_data_ra_id + imm_i_type;
			default: jump_target = regfile_data_ra_id + imm_i_type;
		endcase
	end
	assign jump_target_o = jump_target;
	localparam cv32e40p_pkg_OP_A_CURRPC = 3'b001;
	localparam cv32e40p_pkg_OP_A_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_A_REGA_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_A_REGB_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_A_REGC_OR_FWD = 3'b100;
	always @(*) begin : alu_operand_a_mux
		if (_sv2v_0)
			;
		case (alu_op_a_mux_sel)
			cv32e40p_pkg_OP_A_REGA_OR_FWD: alu_operand_a = operand_a_fw_id;
			cv32e40p_pkg_OP_A_REGB_OR_FWD: alu_operand_a = operand_b_fw_id;
			cv32e40p_pkg_OP_A_REGC_OR_FWD: alu_operand_a = operand_c_fw_id;
			cv32e40p_pkg_OP_A_CURRPC: alu_operand_a = pc_id_i;
			cv32e40p_pkg_OP_A_IMM: alu_operand_a = imm_a;
			default: alu_operand_a = operand_a_fw_id;
		endcase
	end
	localparam cv32e40p_pkg_IMMA_Z = 1'b0;
	localparam cv32e40p_pkg_IMMA_ZERO = 1'b1;
	always @(*) begin : immediate_a_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (imm_a_mux_sel)
			cv32e40p_pkg_IMMA_Z: imm_a = imm_z_type;
			cv32e40p_pkg_IMMA_ZERO: imm_a = 1'sb0;
		endcase
	end
	localparam cv32e40p_pkg_SEL_FW_EX = 2'b01;
	localparam cv32e40p_pkg_SEL_FW_WB = 2'b10;
	localparam cv32e40p_pkg_SEL_REGFILE = 2'b00;
	always @(*) begin : operand_a_fw_mux
		if (_sv2v_0)
			;
		case (operand_a_fw_mux_sel)
			cv32e40p_pkg_SEL_FW_EX: operand_a_fw_id = regfile_alu_wdata_fw_i;
			cv32e40p_pkg_SEL_FW_WB: operand_a_fw_id = regfile_wdata_wb_i;
			cv32e40p_pkg_SEL_REGFILE: operand_a_fw_id = regfile_data_ra_id;
			default: operand_a_fw_id = regfile_data_ra_id;
		endcase
	end
	localparam cv32e40p_pkg_IMMB_BI = 4'b1011;
	localparam cv32e40p_pkg_IMMB_CLIP = 4'b1001;
	localparam cv32e40p_pkg_IMMB_I = 4'b0000;
	localparam cv32e40p_pkg_IMMB_PCINCR = 4'b0011;
	localparam cv32e40p_pkg_IMMB_S = 4'b0001;
	localparam cv32e40p_pkg_IMMB_S2 = 4'b0100;
	localparam cv32e40p_pkg_IMMB_S3 = 4'b0101;
	localparam cv32e40p_pkg_IMMB_SHUF = 4'b1000;
	localparam cv32e40p_pkg_IMMB_U = 4'b0010;
	localparam cv32e40p_pkg_IMMB_VS = 4'b0110;
	localparam cv32e40p_pkg_IMMB_VU = 4'b0111;
	always @(*) begin : immediate_b_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (imm_b_mux_sel)
			cv32e40p_pkg_IMMB_I: imm_b = imm_i_type;
			cv32e40p_pkg_IMMB_S: imm_b = imm_s_type;
			cv32e40p_pkg_IMMB_U: imm_b = imm_u_type;
			cv32e40p_pkg_IMMB_PCINCR: imm_b = (is_compressed_i ? 32'h00000002 : 32'h00000004);
			cv32e40p_pkg_IMMB_S2: imm_b = imm_s2_type;
			cv32e40p_pkg_IMMB_BI: imm_b = imm_bi_type;
			cv32e40p_pkg_IMMB_S3: imm_b = imm_s3_type;
			cv32e40p_pkg_IMMB_VS: imm_b = imm_vs_type;
			cv32e40p_pkg_IMMB_VU: imm_b = imm_vu_type;
			cv32e40p_pkg_IMMB_SHUF: imm_b = imm_shuffle_type;
			cv32e40p_pkg_IMMB_CLIP: imm_b = {1'b0, imm_clip_type[31:1]};
			default: imm_b = imm_i_type;
		endcase
	end
	localparam cv32e40p_pkg_OP_B_BMASK = 3'b100;
	localparam cv32e40p_pkg_OP_B_IMM = 3'b010;
	localparam cv32e40p_pkg_OP_B_REGA_OR_FWD = 3'b011;
	localparam cv32e40p_pkg_OP_B_REGB_OR_FWD = 3'b000;
	localparam cv32e40p_pkg_OP_B_REGC_OR_FWD = 3'b001;
	always @(*) begin : alu_operand_b_mux
		if (_sv2v_0)
			;
		case (alu_op_b_mux_sel)
			cv32e40p_pkg_OP_B_REGA_OR_FWD: operand_b = operand_a_fw_id;
			cv32e40p_pkg_OP_B_REGB_OR_FWD: operand_b = operand_b_fw_id;
			cv32e40p_pkg_OP_B_REGC_OR_FWD: operand_b = operand_c_fw_id;
			cv32e40p_pkg_OP_B_IMM: operand_b = imm_b;
			cv32e40p_pkg_OP_B_BMASK: operand_b = $unsigned(operand_b_fw_id[4:0]);
			default: operand_b = operand_b_fw_id;
		endcase
	end
	localparam cv32e40p_pkg_VEC_MODE8 = 2'b11;
	always @(*) begin
		if (_sv2v_0)
			;
		if (alu_vec_mode == cv32e40p_pkg_VEC_MODE8) begin
			operand_b_vec = {4 {operand_b[7:0]}};
			imm_shuffle_type = imm_shuffleb_type;
		end
		else begin
			operand_b_vec = {2 {operand_b[15:0]}};
			imm_shuffle_type = imm_shuffleh_type;
		end
	end
	assign alu_operand_b = (scalar_replication == 1'b1 ? operand_b_vec : operand_b);
	always @(*) begin : operand_b_fw_mux
		if (_sv2v_0)
			;
		case (operand_b_fw_mux_sel)
			cv32e40p_pkg_SEL_FW_EX: operand_b_fw_id = regfile_alu_wdata_fw_i;
			cv32e40p_pkg_SEL_FW_WB: operand_b_fw_id = regfile_wdata_wb_i;
			cv32e40p_pkg_SEL_REGFILE: operand_b_fw_id = regfile_data_rb_id;
			default: operand_b_fw_id = regfile_data_rb_id;
		endcase
	end
	localparam cv32e40p_pkg_OP_C_JT = 2'b10;
	localparam cv32e40p_pkg_OP_C_REGB_OR_FWD = 2'b01;
	localparam cv32e40p_pkg_OP_C_REGC_OR_FWD = 2'b00;
	always @(*) begin : alu_operand_c_mux
		if (_sv2v_0)
			;
		case (alu_op_c_mux_sel)
			cv32e40p_pkg_OP_C_REGC_OR_FWD: operand_c = operand_c_fw_id;
			cv32e40p_pkg_OP_C_REGB_OR_FWD: operand_c = operand_b_fw_id;
			cv32e40p_pkg_OP_C_JT: operand_c = jump_target;
			default: operand_c = operand_c_fw_id;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (alu_vec_mode == cv32e40p_pkg_VEC_MODE8)
			operand_c_vec = {4 {operand_c[7:0]}};
		else
			operand_c_vec = {2 {operand_c[15:0]}};
	end
	assign alu_operand_c = (scalar_replication_c == 1'b1 ? operand_c_vec : operand_c);
	always @(*) begin : operand_c_fw_mux
		if (_sv2v_0)
			;
		case (operand_c_fw_mux_sel)
			cv32e40p_pkg_SEL_FW_EX: operand_c_fw_id = regfile_alu_wdata_fw_i;
			cv32e40p_pkg_SEL_FW_WB: operand_c_fw_id = regfile_wdata_wb_i;
			cv32e40p_pkg_SEL_REGFILE: operand_c_fw_id = regfile_data_rc_id;
			default: operand_c_fw_id = regfile_data_rc_id;
		endcase
	end
	localparam cv32e40p_pkg_BMASK_A_S3 = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_ZERO = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (bmask_a_mux)
			cv32e40p_pkg_BMASK_A_ZERO: bmask_a_id_imm = 1'sb0;
			cv32e40p_pkg_BMASK_A_S3: bmask_a_id_imm = imm_s3_type[4:0];
		endcase
	end
	localparam cv32e40p_pkg_BMASK_B_ONE = 2'b11;
	localparam cv32e40p_pkg_BMASK_B_S2 = 2'b00;
	localparam cv32e40p_pkg_BMASK_B_S3 = 2'b01;
	localparam cv32e40p_pkg_BMASK_B_ZERO = 2'b10;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (bmask_b_mux)
			cv32e40p_pkg_BMASK_B_ZERO: bmask_b_id_imm = 1'sb0;
			cv32e40p_pkg_BMASK_B_ONE: bmask_b_id_imm = 5'd1;
			cv32e40p_pkg_BMASK_B_S2: bmask_b_id_imm = imm_s2_type[4:0];
			cv32e40p_pkg_BMASK_B_S3: bmask_b_id_imm = imm_s3_type[4:0];
		endcase
	end
	localparam cv32e40p_pkg_BMASK_A_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_A_REG = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (alu_bmask_a_mux_sel)
			cv32e40p_pkg_BMASK_A_IMM: bmask_a_id = bmask_a_id_imm;
			cv32e40p_pkg_BMASK_A_REG: bmask_a_id = operand_b_fw_id[9:5];
		endcase
	end
	localparam cv32e40p_pkg_BMASK_B_IMM = 1'b1;
	localparam cv32e40p_pkg_BMASK_B_REG = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (alu_bmask_b_mux_sel)
			cv32e40p_pkg_BMASK_B_IMM: bmask_b_id = bmask_b_id_imm;
			cv32e40p_pkg_BMASK_B_REG: bmask_b_id = operand_b_fw_id[4:0];
		endcase
	end
	generate
		if (!COREV_PULP) begin : genblk1
			assign imm_vec_ext_id = imm_vu_type[1:0];
		end
		else begin : genblk1
			assign imm_vec_ext_id = (alu_vec ? imm_vu_type[1:0] : 2'b00);
		end
	endgenerate
	localparam cv32e40p_pkg_MIMM_S3 = 1'b1;
	localparam cv32e40p_pkg_MIMM_ZERO = 1'b0;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (mult_imm_mux)
			cv32e40p_pkg_MIMM_ZERO: mult_imm_id = 1'sb0;
			cv32e40p_pkg_MIMM_S3: mult_imm_id = imm_s3_type[4:0];
		endcase
	end
	generate
		if (APU == 1) begin : gen_apu
			if (APU_NARGS_CPU >= 1) begin : genblk1
				assign apu_operands[0+:32] = alu_operand_a;
			end
			if (APU_NARGS_CPU >= 2) begin : genblk2
				assign apu_operands[32+:32] = alu_operand_b;
			end
			if (APU_NARGS_CPU >= 3) begin : genblk3
				assign apu_operands[64+:32] = alu_operand_c;
			end
			assign apu_waddr = regfile_alu_waddr_id;
			assign apu_flags = (FPU == 1 ? {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode} : {APU_NDSFLAGS_CPU {1'sb0}});
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (alu_op_a_mux_sel)
					cv32e40p_pkg_OP_A_CURRPC:
						if (ctrl_transfer_target_mux_sel == cv32e40p_pkg_JT_JALR) begin
							apu_read_regs[0+:6] = regfile_addr_ra_id;
							apu_read_regs_valid[0] = 1'b1;
						end
						else begin
							apu_read_regs[0+:6] = regfile_addr_ra_id;
							apu_read_regs_valid[0] = 1'b0;
						end
					cv32e40p_pkg_OP_A_REGA_OR_FWD: begin
						apu_read_regs[0+:6] = regfile_addr_ra_id;
						apu_read_regs_valid[0] = 1'b1;
					end
					cv32e40p_pkg_OP_A_REGB_OR_FWD, cv32e40p_pkg_OP_A_REGC_OR_FWD: begin
						apu_read_regs[0+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[0] = 1'b1;
					end
					default: begin
						apu_read_regs[0+:6] = regfile_addr_ra_id;
						apu_read_regs_valid[0] = 1'b0;
					end
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (alu_op_b_mux_sel)
					cv32e40p_pkg_OP_B_REGA_OR_FWD: begin
						apu_read_regs[6+:6] = regfile_addr_ra_id;
						apu_read_regs_valid[1] = 1'b1;
					end
					cv32e40p_pkg_OP_B_REGB_OR_FWD, cv32e40p_pkg_OP_B_BMASK: begin
						apu_read_regs[6+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[1] = 1'b1;
					end
					cv32e40p_pkg_OP_B_REGC_OR_FWD: begin
						apu_read_regs[6+:6] = regfile_addr_rc_id;
						apu_read_regs_valid[1] = 1'b1;
					end
					cv32e40p_pkg_OP_B_IMM:
						if (alu_bmask_b_mux_sel == cv32e40p_pkg_BMASK_B_REG) begin
							apu_read_regs[6+:6] = regfile_addr_rb_id;
							apu_read_regs_valid[1] = 1'b1;
						end
						else begin
							apu_read_regs[6+:6] = regfile_addr_rb_id;
							apu_read_regs_valid[1] = 1'b0;
						end
					default: begin
						apu_read_regs[6+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[1] = 1'b0;
					end
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (alu_op_c_mux_sel)
					cv32e40p_pkg_OP_C_REGB_OR_FWD: begin
						apu_read_regs[12+:6] = regfile_addr_rb_id;
						apu_read_regs_valid[2] = 1'b1;
					end
					cv32e40p_pkg_OP_C_REGC_OR_FWD:
						if ((((alu_op_a_mux_sel != cv32e40p_pkg_OP_A_REGC_OR_FWD) && (ctrl_transfer_target_mux_sel != cv32e40p_pkg_JT_JALR)) && !((alu_op_b_mux_sel == cv32e40p_pkg_OP_B_IMM) && (alu_bmask_b_mux_sel == cv32e40p_pkg_BMASK_B_REG))) && (alu_op_b_mux_sel != cv32e40p_pkg_OP_B_BMASK)) begin
							apu_read_regs[12+:6] = regfile_addr_rc_id;
							apu_read_regs_valid[2] = 1'b1;
						end
						else begin
							apu_read_regs[12+:6] = regfile_addr_rc_id;
							apu_read_regs_valid[2] = 1'b0;
						end
					default: begin
						apu_read_regs[12+:6] = regfile_addr_rc_id;
						apu_read_regs_valid[2] = 1'b0;
					end
				endcase
			end
			assign apu_write_regs[0+:6] = regfile_alu_waddr_id;
			assign apu_write_regs_valid[0] = regfile_alu_we_id;
			assign apu_write_regs[6+:6] = regfile_waddr_id;
			assign apu_write_regs_valid[1] = regfile_we_id;
			assign apu_read_regs_o = apu_read_regs;
			assign apu_read_regs_valid_o = apu_read_regs_valid;
			assign apu_write_regs_o = apu_write_regs;
			assign apu_write_regs_valid_o = apu_write_regs_valid;
		end
		else begin : gen_no_apu
			genvar _gv_i_4;
			for (_gv_i_4 = 0; _gv_i_4 < APU_NARGS_CPU; _gv_i_4 = _gv_i_4 + 1) begin : gen_apu_tie_off
				localparam i = _gv_i_4;
				assign apu_operands[i * 32+:32] = 1'sb0;
			end
			wire [18:1] sv2v_tmp_D495B;
			assign sv2v_tmp_D495B = 1'sb0;
			always @(*) apu_read_regs = sv2v_tmp_D495B;
			wire [3:1] sv2v_tmp_66715;
			assign sv2v_tmp_66715 = 1'sb0;
			always @(*) apu_read_regs_valid = sv2v_tmp_66715;
			assign apu_write_regs = 1'sb0;
			assign apu_write_regs_valid = 1'sb0;
			assign apu_waddr = 1'sb0;
			assign apu_flags = 1'sb0;
			assign apu_write_regs_o = 1'sb0;
			assign apu_read_regs_o = 1'sb0;
			assign apu_write_regs_valid_o = 1'sb0;
			assign apu_read_regs_valid_o = 1'sb0;
		end
	endgenerate
	assign apu_perf_dep_o = apu_stall;
	assign csr_apu_stall = csr_access & ((apu_en_ex_o & (apu_lat_ex_o[1] == 1'b1)) | apu_busy_i);
	cv32e40p_register_file #(
		.ADDR_WIDTH(6),
		.DATA_WIDTH(32),
		.FPU(FPU),
		.ZFINX(ZFINX)
	) register_file_i(
		.clk(clk),
		.rst_n(rst_n),
		.scan_cg_en_i(scan_cg_en_i),
		.raddr_a_i(regfile_addr_ra_id),
		.rdata_a_o(regfile_data_ra_id),
		.raddr_b_i(regfile_addr_rb_id),
		.rdata_b_o(regfile_data_rb_id),
		.raddr_c_i(regfile_addr_rc_id),
		.rdata_c_o(regfile_data_rc_id),
		.waddr_a_i(regfile_waddr_wb_i),
		.wdata_a_i(regfile_wdata_wb_i),
		.we_a_i(regfile_we_wb_power_i),
		.waddr_b_i(regfile_alu_waddr_fw_i),
		.wdata_b_i(regfile_alu_wdata_fw_i),
		.we_b_i(regfile_alu_we_fw_power_i)
	);
	cv32e40p_decoder #(
		.COREV_PULP(COREV_PULP),
		.COREV_CLUSTER(COREV_CLUSTER),
		.A_EXTENSION(A_EXTENSION),
		.FPU(FPU),
		.FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
		.FPU_OTHERS_LAT(FPU_OTHERS_LAT),
		.ZFINX(ZFINX),
		.PULP_SECURE(PULP_SECURE),
		.USE_PMP(USE_PMP),
		.APU_WOP_CPU(APU_WOP_CPU),
		.DEBUG_TRIGGER_EN(DEBUG_TRIGGER_EN)
	) decoder_i(
		.deassert_we_i(deassert_we),
		.illegal_insn_o(illegal_insn_dec),
		.ebrk_insn_o(ebrk_insn_dec),
		.mret_insn_o(mret_insn_dec),
		.uret_insn_o(uret_insn_dec),
		.dret_insn_o(dret_insn_dec),
		.mret_dec_o(mret_dec),
		.uret_dec_o(uret_dec),
		.dret_dec_o(dret_dec),
		.ecall_insn_o(ecall_insn_dec),
		.wfi_o(wfi_insn_dec),
		.fencei_insn_o(fencei_insn_dec),
		.rega_used_o(rega_used_dec),
		.regb_used_o(regb_used_dec),
		.regc_used_o(regc_used_dec),
		.reg_fp_a_o(regfile_fp_a),
		.reg_fp_b_o(regfile_fp_b),
		.reg_fp_c_o(regfile_fp_c),
		.reg_fp_d_o(regfile_fp_d),
		.bmask_a_mux_o(bmask_a_mux),
		.bmask_b_mux_o(bmask_b_mux),
		.alu_bmask_a_mux_sel_o(alu_bmask_a_mux_sel),
		.alu_bmask_b_mux_sel_o(alu_bmask_b_mux_sel),
		.instr_rdata_i(instr),
		.illegal_c_insn_i(illegal_c_insn_i),
		.alu_en_o(alu_en),
		.alu_operator_o(alu_operator),
		.alu_op_a_mux_sel_o(alu_op_a_mux_sel),
		.alu_op_b_mux_sel_o(alu_op_b_mux_sel),
		.alu_op_c_mux_sel_o(alu_op_c_mux_sel),
		.alu_vec_o(alu_vec),
		.alu_vec_mode_o(alu_vec_mode),
		.scalar_replication_o(scalar_replication),
		.scalar_replication_c_o(scalar_replication_c),
		.imm_a_mux_sel_o(imm_a_mux_sel),
		.imm_b_mux_sel_o(imm_b_mux_sel),
		.regc_mux_o(regc_mux),
		.is_clpx_o(is_clpx),
		.is_subrot_o(is_subrot),
		.mult_operator_o(mult_operator),
		.mult_int_en_o(mult_int_en),
		.mult_sel_subword_o(mult_sel_subword),
		.mult_signed_mode_o(mult_signed_mode),
		.mult_imm_mux_o(mult_imm_mux),
		.mult_dot_en_o(mult_dot_en),
		.mult_dot_signed_o(mult_dot_signed),
		.fs_off_i(fs_off_i),
		.frm_i(frm_i),
		.fpu_src_fmt_o(fpu_src_fmt),
		.fpu_dst_fmt_o(fpu_dst_fmt),
		.fpu_int_fmt_o(fpu_int_fmt),
		.apu_en_o(apu_en),
		.apu_op_o(apu_op),
		.apu_lat_o(apu_lat),
		.fp_rnd_mode_o(fp_rnd_mode),
		.regfile_mem_we_o(regfile_we_id),
		.regfile_alu_we_o(regfile_alu_we_id),
		.regfile_alu_we_dec_o(regfile_alu_we_dec_id),
		.regfile_alu_waddr_sel_o(regfile_alu_waddr_mux_sel),
		.csr_access_o(csr_access),
		.csr_status_o(csr_status),
		.csr_op_o(csr_op),
		.current_priv_lvl_i(current_priv_lvl_i),
		.data_req_o(data_req_id),
		.data_we_o(data_we_id),
		.prepost_useincr_o(prepost_useincr),
		.data_type_o(data_type_id),
		.data_sign_extension_o(data_sign_ext_id),
		.data_reg_offset_o(data_reg_offset_id),
		.data_load_event_o(data_load_event_id),
		.atop_o(atop_id),
		.hwlp_we_o(hwlp_we),
		.hwlp_target_mux_sel_o(hwlp_target_mux_sel),
		.hwlp_start_mux_sel_o(hwlp_start_mux_sel),
		.hwlp_cnt_mux_sel_o(hwlp_cnt_mux_sel),
		.debug_mode_i(debug_mode_o),
		.debug_wfi_no_sleep_i(debug_wfi_no_sleep),
		.ctrl_transfer_insn_in_dec_o(ctrl_transfer_insn_in_dec_o),
		.ctrl_transfer_insn_in_id_o(ctrl_transfer_insn_in_id),
		.ctrl_transfer_target_mux_sel_o(ctrl_transfer_target_mux_sel),
		.mcounteren_i(mcounteren_i)
	);
	cv32e40p_controller #(
		.COREV_CLUSTER(COREV_CLUSTER),
		.COREV_PULP(COREV_PULP),
		.FPU(FPU)
	) controller_i(
		.clk(clk),
		.clk_ungated_i(clk_ungated_i),
		.rst_n(rst_n),
		.fetch_enable_i(fetch_enable_i),
		.ctrl_busy_o(ctrl_busy_o),
		.is_decoding_o(is_decoding_o),
		.is_fetch_failed_i(is_fetch_failed_i),
		.deassert_we_o(deassert_we),
		.illegal_insn_i(illegal_insn_dec),
		.ecall_insn_i(ecall_insn_dec),
		.mret_insn_i(mret_insn_dec),
		.uret_insn_i(uret_insn_dec),
		.dret_insn_i(dret_insn_dec),
		.mret_dec_i(mret_dec),
		.uret_dec_i(uret_dec),
		.dret_dec_i(dret_dec),
		.wfi_i(wfi_insn_dec),
		.ebrk_insn_i(ebrk_insn_dec),
		.fencei_insn_i(fencei_insn_dec),
		.csr_status_i(csr_status),
		.hwlp_mask_o(hwlp_mask),
		.instr_valid_i(instr_valid_i),
		.instr_req_o(instr_req_o),
		.pc_set_o(pc_set_o),
		.pc_mux_o(pc_mux_o),
		.exc_pc_mux_o(exc_pc_mux_o),
		.exc_cause_o(exc_cause_o),
		.trap_addr_mux_o(trap_addr_mux_o),
		.pc_id_i(pc_id_i),
		.hwlp_start_addr_i(hwlp_start_o),
		.hwlp_end_addr_i(hwlp_end_o),
		.hwlp_counter_i(hwlp_cnt_o),
		.hwlp_dec_cnt_o(hwlp_dec_cnt),
		.hwlp_jump_o(hwlp_jump_o),
		.hwlp_targ_addr_o(hwlp_target_o),
		.data_req_ex_i(data_req_ex_o),
		.data_we_ex_i(data_we_ex_o),
		.data_misaligned_i(data_misaligned_i),
		.data_load_event_i(data_load_event_id),
		.data_err_i(data_err_i),
		.data_err_ack_o(data_err_ack_o),
		.mult_multicycle_i(mult_multicycle_i),
		.apu_en_i(apu_en),
		.apu_read_dep_i(apu_read_dep_i),
		.apu_read_dep_for_jalr_i(apu_read_dep_for_jalr_i),
		.apu_write_dep_i(apu_write_dep_i),
		.apu_stall_o(apu_stall),
		.branch_taken_ex_i(branch_taken_ex),
		.ctrl_transfer_insn_in_id_i(ctrl_transfer_insn_in_id),
		.ctrl_transfer_insn_in_dec_i(ctrl_transfer_insn_in_dec_o),
		.irq_wu_ctrl_i(irq_wu_ctrl),
		.irq_req_ctrl_i(irq_req_ctrl),
		.irq_sec_ctrl_i(irq_sec_ctrl),
		.irq_id_ctrl_i(irq_id_ctrl),
		.current_priv_lvl_i(current_priv_lvl_i),
		.irq_ack_o(irq_ack_o),
		.irq_id_o(irq_id_o),
		.debug_mode_o(debug_mode_o),
		.debug_cause_o(debug_cause_o),
		.debug_csr_save_o(debug_csr_save_o),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step_i),
		.debug_ebreakm_i(debug_ebreakm_i),
		.debug_ebreaku_i(debug_ebreaku_i),
		.trigger_match_i(trigger_match_i),
		.debug_p_elw_no_sleep_o(debug_p_elw_no_sleep_o),
		.debug_wfi_no_sleep_o(debug_wfi_no_sleep),
		.debug_havereset_o(debug_havereset_o),
		.debug_running_o(debug_running_o),
		.debug_halted_o(debug_halted_o),
		.wake_from_sleep_o(wake_from_sleep_o),
		.csr_save_cause_o(csr_save_cause_o),
		.csr_cause_o(csr_cause_o),
		.csr_save_if_o(csr_save_if_o),
		.csr_save_id_o(csr_save_id_o),
		.csr_save_ex_o(csr_save_ex_o),
		.csr_restore_mret_id_o(csr_restore_mret_id_o),
		.csr_restore_uret_id_o(csr_restore_uret_id_o),
		.csr_restore_dret_id_o(csr_restore_dret_id_o),
		.csr_irq_sec_o(csr_irq_sec_o),
		.regfile_we_id_i(regfile_alu_we_dec_id),
		.regfile_alu_waddr_id_i(regfile_alu_waddr_id),
		.regfile_we_ex_i(regfile_we_ex_o),
		.regfile_waddr_ex_i(regfile_waddr_ex_o),
		.regfile_we_wb_i(regfile_we_wb_i),
		.regfile_alu_we_fw_i(regfile_alu_we_fw_i),
		.reg_d_ex_is_reg_a_i(reg_d_ex_is_reg_a_id),
		.reg_d_ex_is_reg_b_i(reg_d_ex_is_reg_b_id),
		.reg_d_ex_is_reg_c_i(reg_d_ex_is_reg_c_id),
		.reg_d_wb_is_reg_a_i(reg_d_wb_is_reg_a_id),
		.reg_d_wb_is_reg_b_i(reg_d_wb_is_reg_b_id),
		.reg_d_wb_is_reg_c_i(reg_d_wb_is_reg_c_id),
		.reg_d_alu_is_reg_a_i(reg_d_alu_is_reg_a_id),
		.reg_d_alu_is_reg_b_i(reg_d_alu_is_reg_b_id),
		.reg_d_alu_is_reg_c_i(reg_d_alu_is_reg_c_id),
		.operand_a_fw_mux_sel_o(operand_a_fw_mux_sel),
		.operand_b_fw_mux_sel_o(operand_b_fw_mux_sel),
		.operand_c_fw_mux_sel_o(operand_c_fw_mux_sel),
		.halt_if_o(halt_if),
		.halt_id_o(halt_id),
		.misaligned_stall_o(misaligned_stall),
		.jr_stall_o(jr_stall),
		.load_stall_o(load_stall),
		.id_ready_i(id_ready_o),
		.id_valid_i(id_valid_o),
		.ex_valid_i(ex_valid_i),
		.wb_ready_i(wb_ready_i),
		.perf_pipeline_stall_o(perf_pipeline_stall)
	);
	cv32e40p_int_controller #(.PULP_SECURE(PULP_SECURE)) int_controller_i(
		.clk(clk),
		.rst_n(rst_n),
		.irq_i(irq_i),
		.irq_sec_i(irq_sec_i),
		.irq_req_ctrl_o(irq_req_ctrl),
		.irq_sec_ctrl_o(irq_sec_ctrl),
		.irq_id_ctrl_o(irq_id_ctrl),
		.irq_wu_ctrl_o(irq_wu_ctrl),
		.mie_bypass_i(mie_bypass_i),
		.mip_o(mip_o),
		.m_ie_i(m_irq_enable_i),
		.u_ie_i(u_irq_enable_i),
		.current_priv_lvl_i(current_priv_lvl_i)
	);
	generate
		if (COREV_PULP) begin : gen_hwloop_regs
			cv32e40p_hwloop_regs #(.N_REGS(N_HWLP)) hwloop_regs_i(
				.clk(clk),
				.rst_n(rst_n),
				.hwlp_start_data_i(hwlp_start),
				.hwlp_end_data_i(hwlp_end),
				.hwlp_cnt_data_i(hwlp_cnt),
				.hwlp_we_i(hwlp_we_masked),
				.hwlp_regid_i(hwlp_regid),
				.valid_i(hwlp_valid),
				.hwlp_start_addr_o(hwlp_start_o),
				.hwlp_end_addr_o(hwlp_end_o),
				.hwlp_counter_o(hwlp_cnt_o),
				.hwlp_dec_cnt_i(hwlp_dec_cnt)
			);
			assign hwlp_valid = instr_valid_i & clear_instr_valid_o;
			assign hwlp_regid = instr[7];
			always @(*) begin
				if (_sv2v_0)
					;
				case (hwlp_target_mux_sel)
					2'b00: hwlp_end = pc_id_i + {imm_iz_type[29:0], 2'b00};
					2'b01: hwlp_end = pc_id_i + {imm_z_type[29:0], 2'b00};
					2'b10: hwlp_end = operand_a_fw_id;
					default: hwlp_end = operand_a_fw_id;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				case (hwlp_start_mux_sel)
					2'b00: hwlp_start = hwlp_end;
					2'b01: hwlp_start = pc_id_i + 4;
					2'b10: hwlp_start = operand_a_fw_id;
					default: hwlp_start = operand_a_fw_id;
				endcase
			end
			always @(*) begin : hwlp_cnt_mux
				if (_sv2v_0)
					;
				case (hwlp_cnt_mux_sel)
					1'b0: hwlp_cnt = imm_iz_type;
					1'b1: hwlp_cnt = operand_a_fw_id;
				endcase
			end
			assign hwlp_we_masked = (hwlp_we & ~{3 {hwlp_mask}}) & {3 {id_ready_o}};
		end
		else begin : gen_no_hwloop_regs
			assign hwlp_start_o = 'b0;
			assign hwlp_end_o = 'b0;
			assign hwlp_cnt_o = 'b0;
			assign hwlp_valid = 'b0;
			assign hwlp_we_masked = 'b0;
			wire [32:1] sv2v_tmp_3A88A;
			assign sv2v_tmp_3A88A = 'b0;
			always @(*) hwlp_start = sv2v_tmp_3A88A;
			wire [32:1] sv2v_tmp_CF2EC;
			assign sv2v_tmp_CF2EC = 'b0;
			always @(*) hwlp_end = sv2v_tmp_CF2EC;
			wire [32:1] sv2v_tmp_C02CF;
			assign sv2v_tmp_C02CF = 'b0;
			always @(*) hwlp_cnt = sv2v_tmp_C02CF;
			assign hwlp_regid = 'b0;
		end
	endgenerate
	localparam cv32e40p_pkg_BRANCH_COND = 2'b11;
	function automatic [6:0] sv2v_cast_81146;
		input reg [6:0] inp;
		sv2v_cast_81146 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_F9F94;
		input reg [2:0] inp;
		sv2v_cast_F9F94 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_8FA4C;
		input reg [1:0] inp;
		sv2v_cast_8FA4C = inp;
	endfunction
	always @(posedge clk or negedge rst_n) begin : ID_EX_PIPE_REGISTERS
		if (rst_n == 1'b0) begin
			alu_en_ex_o <= 1'sb0;
			alu_operator_ex_o <= sv2v_cast_81146(7'b0000011);
			alu_operand_a_ex_o <= 1'sb0;
			alu_operand_b_ex_o <= 1'sb0;
			alu_operand_c_ex_o <= 1'sb0;
			bmask_a_ex_o <= 1'sb0;
			bmask_b_ex_o <= 1'sb0;
			imm_vec_ext_ex_o <= 1'sb0;
			alu_vec_mode_ex_o <= 1'sb0;
			alu_clpx_shift_ex_o <= 2'b00;
			alu_is_clpx_ex_o <= 1'b0;
			alu_is_subrot_ex_o <= 1'b0;
			mult_operator_ex_o <= sv2v_cast_F9F94(3'b000);
			mult_operand_a_ex_o <= 1'sb0;
			mult_operand_b_ex_o <= 1'sb0;
			mult_operand_c_ex_o <= 1'sb0;
			mult_en_ex_o <= 1'b0;
			mult_sel_subword_ex_o <= 1'b0;
			mult_signed_mode_ex_o <= 2'b00;
			mult_imm_ex_o <= 1'sb0;
			mult_dot_op_a_ex_o <= 1'sb0;
			mult_dot_op_b_ex_o <= 1'sb0;
			mult_dot_op_c_ex_o <= 1'sb0;
			mult_dot_signed_ex_o <= 1'sb0;
			mult_is_clpx_ex_o <= 1'b0;
			mult_clpx_shift_ex_o <= 2'b00;
			mult_clpx_img_ex_o <= 1'b0;
			apu_en_ex_o <= 1'sb0;
			apu_op_ex_o <= 1'sb0;
			apu_lat_ex_o <= 1'sb0;
			apu_operands_ex_o[0+:32] <= 1'sb0;
			apu_operands_ex_o[32+:32] <= 1'sb0;
			apu_operands_ex_o[64+:32] <= 1'sb0;
			apu_flags_ex_o <= 1'sb0;
			apu_waddr_ex_o <= 1'sb0;
			regfile_waddr_ex_o <= 6'b000000;
			regfile_we_ex_o <= 1'b0;
			regfile_alu_waddr_ex_o <= 6'b000000;
			regfile_alu_we_ex_o <= 1'b0;
			prepost_useincr_ex_o <= 1'b0;
			csr_access_ex_o <= 1'b0;
			csr_op_ex_o <= sv2v_cast_8FA4C(2'b00);
			data_we_ex_o <= 1'b0;
			data_type_ex_o <= 2'b00;
			data_sign_ext_ex_o <= 2'b00;
			data_reg_offset_ex_o <= 2'b00;
			data_req_ex_o <= 1'b0;
			data_load_event_ex_o <= 1'b0;
			atop_ex_o <= 5'b00000;
			data_misaligned_ex_o <= 1'b0;
			pc_ex_o <= 1'sb0;
			branch_in_ex_o <= 1'b0;
		end
		else if (data_misaligned_i) begin
			if (ex_ready_i) begin
				if (prepost_useincr_ex_o == 1'b1)
					alu_operand_a_ex_o <= operand_a_fw_id;
				alu_operand_b_ex_o <= 32'h00000004;
				regfile_alu_we_ex_o <= 1'b0;
				prepost_useincr_ex_o <= 1'b1;
				data_misaligned_ex_o <= 1'b1;
			end
		end
		else if (mult_multicycle_i)
			mult_operand_c_ex_o <= operand_c_fw_id;
		else if (id_valid_o) begin
			alu_en_ex_o <= alu_en;
			if (alu_en) begin
				alu_operator_ex_o <= alu_operator;
				alu_operand_a_ex_o <= alu_operand_a;
				if ((alu_op_b_mux_sel == cv32e40p_pkg_OP_B_REGB_OR_FWD) && ((alu_operator == sv2v_cast_81146(7'b0010110)) || (alu_operator == sv2v_cast_81146(7'b0010111))))
					alu_operand_b_ex_o <= {1'b0, alu_operand_b[30:0]};
				else
					alu_operand_b_ex_o <= alu_operand_b;
				alu_operand_c_ex_o <= alu_operand_c;
				bmask_a_ex_o <= bmask_a_id;
				bmask_b_ex_o <= bmask_b_id;
				imm_vec_ext_ex_o <= imm_vec_ext_id;
				alu_vec_mode_ex_o <= alu_vec_mode;
				alu_is_clpx_ex_o <= is_clpx;
				alu_clpx_shift_ex_o <= instr[14:13];
				alu_is_subrot_ex_o <= is_subrot;
			end
			mult_en_ex_o <= mult_en;
			if (mult_int_en) begin
				mult_operator_ex_o <= mult_operator;
				mult_sel_subword_ex_o <= mult_sel_subword;
				mult_signed_mode_ex_o <= mult_signed_mode;
				mult_operand_a_ex_o <= alu_operand_a;
				mult_operand_b_ex_o <= alu_operand_b;
				mult_operand_c_ex_o <= alu_operand_c;
				mult_imm_ex_o <= mult_imm_id;
			end
			if (mult_dot_en) begin
				mult_operator_ex_o <= mult_operator;
				mult_dot_signed_ex_o <= mult_dot_signed;
				mult_dot_op_a_ex_o <= alu_operand_a;
				mult_dot_op_b_ex_o <= alu_operand_b;
				mult_dot_op_c_ex_o <= alu_operand_c;
				mult_is_clpx_ex_o <= is_clpx;
				mult_clpx_shift_ex_o <= instr[14:13];
				mult_clpx_img_ex_o <= instr[25];
			end
			apu_en_ex_o <= apu_en;
			if (apu_en) begin
				apu_op_ex_o <= apu_op;
				apu_lat_ex_o <= apu_lat;
				apu_operands_ex_o <= apu_operands;
				apu_flags_ex_o <= apu_flags;
				apu_waddr_ex_o <= apu_waddr;
			end
			regfile_we_ex_o <= regfile_we_id;
			if (regfile_we_id)
				regfile_waddr_ex_o <= regfile_waddr_id;
			regfile_alu_we_ex_o <= regfile_alu_we_id;
			if (regfile_alu_we_id)
				regfile_alu_waddr_ex_o <= regfile_alu_waddr_id;
			prepost_useincr_ex_o <= prepost_useincr;
			csr_access_ex_o <= csr_access;
			csr_op_ex_o <= csr_op;
			data_req_ex_o <= data_req_id;
			if (data_req_id) begin
				data_we_ex_o <= data_we_id;
				data_type_ex_o <= data_type_id;
				data_sign_ext_ex_o <= data_sign_ext_id;
				data_reg_offset_ex_o <= data_reg_offset_id;
				data_load_event_ex_o <= data_load_event_id;
				atop_ex_o <= atop_id;
			end
			else
				data_load_event_ex_o <= 1'b0;
			data_misaligned_ex_o <= 1'b0;
			if ((ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_COND) || data_req_id)
				pc_ex_o <= pc_id_i;
			branch_in_ex_o <= ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_COND;
		end
		else if (ex_ready_i) begin
			regfile_we_ex_o <= 1'b0;
			regfile_alu_we_ex_o <= 1'b0;
			csr_op_ex_o <= sv2v_cast_8FA4C(2'b00);
			data_req_ex_o <= 1'b0;
			data_load_event_ex_o <= 1'b0;
			data_misaligned_ex_o <= 1'b0;
			branch_in_ex_o <= 1'b0;
			apu_en_ex_o <= 1'b0;
			alu_operator_ex_o <= sv2v_cast_81146(7'b0000011);
			mult_en_ex_o <= 1'b0;
			alu_en_ex_o <= 1'b1;
		end
		else if (csr_access_ex_o)
			regfile_alu_we_ex_o <= 1'b0;
	end
	assign minstret = (id_valid_o && is_decoding_o) && !((illegal_insn_dec || ebrk_insn_dec) || ecall_insn_dec);
	localparam cv32e40p_pkg_BRANCH_JAL = 2'b01;
	localparam cv32e40p_pkg_BRANCH_JALR = 2'b10;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			id_valid_q <= 1'b0;
			mhpmevent_minstret_o <= 1'b0;
			mhpmevent_load_o <= 1'b0;
			mhpmevent_store_o <= 1'b0;
			mhpmevent_jump_o <= 1'b0;
			mhpmevent_branch_o <= 1'b0;
			mhpmevent_compressed_o <= 1'b0;
			mhpmevent_branch_taken_o <= 1'b0;
			mhpmevent_jr_stall_o <= 1'b0;
			mhpmevent_imiss_o <= 1'b0;
			mhpmevent_ld_stall_o <= 1'b0;
			mhpmevent_pipe_stall_o <= 1'b0;
		end
		else begin
			id_valid_q <= id_valid_o;
			mhpmevent_minstret_o <= minstret;
			mhpmevent_load_o <= (minstret && data_req_id) && !data_we_id;
			mhpmevent_store_o <= (minstret && data_req_id) && data_we_id;
			mhpmevent_jump_o <= minstret && ((ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_JAL) || (ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_JALR));
			mhpmevent_branch_o <= minstret && (ctrl_transfer_insn_in_id == cv32e40p_pkg_BRANCH_COND);
			mhpmevent_compressed_o <= minstret && is_compressed_i;
			mhpmevent_branch_taken_o <= mhpmevent_branch_o && branch_decision_i;
			mhpmevent_imiss_o <= perf_imiss_i;
			mhpmevent_jr_stall_o <= (jr_stall && !halt_id) && id_valid_q;
			mhpmevent_ld_stall_o <= (load_stall && !halt_id) && id_valid_q;
			mhpmevent_pipe_stall_o <= perf_pipeline_stall;
		end
	assign id_ready_o = ((((~misaligned_stall & ~jr_stall) & ~load_stall) & ~apu_stall) & ~csr_apu_stall) & ex_ready_i;
	assign id_valid_o = ~halt_id & id_ready_o;
	assign halt_if_o = halt_if;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_if_stage (
	clk,
	rst_n,
	m_trap_base_addr_i,
	u_trap_base_addr_i,
	trap_addr_mux_i,
	boot_addr_i,
	dm_exception_addr_i,
	dm_halt_addr_i,
	req_i,
	instr_req_o,
	instr_addr_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_err_i,
	instr_err_pmp_i,
	instr_valid_id_o,
	instr_rdata_id_o,
	is_compressed_id_o,
	illegal_c_insn_id_o,
	pc_if_o,
	pc_id_o,
	is_fetch_failed_o,
	clear_instr_valid_i,
	pc_set_i,
	mepc_i,
	uepc_i,
	depc_i,
	pc_mux_i,
	exc_pc_mux_i,
	m_exc_vec_pc_mux_i,
	u_exc_vec_pc_mux_i,
	csr_mtvec_init_o,
	jump_target_id_i,
	jump_target_ex_i,
	hwlp_jump_i,
	hwlp_target_i,
	halt_if_i,
	id_ready_i,
	if_busy_o,
	perf_imiss_o
);
	reg _sv2v_0;
	parameter COREV_PULP = 0;
	parameter PULP_OBI = 0;
	parameter PULP_SECURE = 0;
	parameter FPU = 0;
	parameter ZFINX = 0;
	input wire clk;
	input wire rst_n;
	input wire [23:0] m_trap_base_addr_i;
	input wire [23:0] u_trap_base_addr_i;
	input wire [1:0] trap_addr_mux_i;
	input wire [31:0] boot_addr_i;
	input wire [31:0] dm_exception_addr_i;
	input wire [31:0] dm_halt_addr_i;
	input wire req_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [31:0] instr_rdata_i;
	input wire instr_err_i;
	input wire instr_err_pmp_i;
	output reg instr_valid_id_o;
	output reg [31:0] instr_rdata_id_o;
	output reg is_compressed_id_o;
	output reg illegal_c_insn_id_o;
	output wire [31:0] pc_if_o;
	output reg [31:0] pc_id_o;
	output reg is_fetch_failed_o;
	input wire clear_instr_valid_i;
	input wire pc_set_i;
	input wire [31:0] mepc_i;
	input wire [31:0] uepc_i;
	input wire [31:0] depc_i;
	input wire [3:0] pc_mux_i;
	input wire [2:0] exc_pc_mux_i;
	input wire [4:0] m_exc_vec_pc_mux_i;
	input wire [4:0] u_exc_vec_pc_mux_i;
	output wire csr_mtvec_init_o;
	input wire [31:0] jump_target_id_i;
	input wire [31:0] jump_target_ex_i;
	input wire hwlp_jump_i;
	input wire [31:0] hwlp_target_i;
	input wire halt_if_i;
	input wire id_ready_i;
	output wire if_busy_o;
	output wire perf_imiss_o;
	wire if_valid;
	wire if_ready;
	wire prefetch_busy;
	reg branch_req;
	reg [31:0] branch_addr_n;
	wire fetch_valid;
	reg fetch_ready;
	wire [31:0] fetch_rdata;
	reg [31:0] exc_pc;
	reg [23:0] trap_base_addr;
	reg [4:0] exc_vec_pc_mux;
	wire fetch_failed;
	wire aligner_ready;
	wire instr_valid;
	wire illegal_c_insn;
	wire [31:0] instr_aligned;
	wire [31:0] instr_decompressed;
	wire instr_compressed_int;
	localparam cv32e40p_pkg_EXC_PC_DBD = 3'b010;
	localparam cv32e40p_pkg_EXC_PC_DBE = 3'b011;
	localparam cv32e40p_pkg_EXC_PC_EXCEPTION = 3'b000;
	localparam cv32e40p_pkg_EXC_PC_IRQ = 3'b001;
	localparam cv32e40p_pkg_TRAP_MACHINE = 2'b00;
	localparam cv32e40p_pkg_TRAP_USER = 2'b01;
	always @(*) begin : EXC_PC_MUX
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (trap_addr_mux_i)
			cv32e40p_pkg_TRAP_MACHINE: trap_base_addr = m_trap_base_addr_i;
			cv32e40p_pkg_TRAP_USER: trap_base_addr = u_trap_base_addr_i;
			default: trap_base_addr = m_trap_base_addr_i;
		endcase
		(* full_case, parallel_case *)
		case (trap_addr_mux_i)
			cv32e40p_pkg_TRAP_MACHINE: exc_vec_pc_mux = m_exc_vec_pc_mux_i;
			cv32e40p_pkg_TRAP_USER: exc_vec_pc_mux = u_exc_vec_pc_mux_i;
			default: exc_vec_pc_mux = m_exc_vec_pc_mux_i;
		endcase
		(* full_case, parallel_case *)
		case (exc_pc_mux_i)
			cv32e40p_pkg_EXC_PC_EXCEPTION: exc_pc = {trap_base_addr, 8'h00};
			cv32e40p_pkg_EXC_PC_IRQ: exc_pc = {trap_base_addr, 1'b0, exc_vec_pc_mux, 2'b00};
			cv32e40p_pkg_EXC_PC_DBD: exc_pc = {dm_halt_addr_i[31:2], 2'b00};
			cv32e40p_pkg_EXC_PC_DBE: exc_pc = {dm_exception_addr_i[31:2], 2'b00};
			default: exc_pc = {trap_base_addr, 8'h00};
		endcase
	end
	localparam cv32e40p_pkg_PC_BOOT = 4'b0000;
	localparam cv32e40p_pkg_PC_BRANCH = 4'b0011;
	localparam cv32e40p_pkg_PC_DRET = 4'b0111;
	localparam cv32e40p_pkg_PC_EXCEPTION = 4'b0100;
	localparam cv32e40p_pkg_PC_FENCEI = 4'b0001;
	localparam cv32e40p_pkg_PC_HWLOOP = 4'b1000;
	localparam cv32e40p_pkg_PC_JUMP = 4'b0010;
	localparam cv32e40p_pkg_PC_MRET = 4'b0101;
	localparam cv32e40p_pkg_PC_URET = 4'b0110;
	always @(*) begin
		if (_sv2v_0)
			;
		branch_addr_n = {boot_addr_i[31:2], 2'b00};
		(* full_case, parallel_case *)
		case (pc_mux_i)
			cv32e40p_pkg_PC_BOOT: branch_addr_n = {boot_addr_i[31:2], 2'b00};
			cv32e40p_pkg_PC_JUMP: branch_addr_n = jump_target_id_i;
			cv32e40p_pkg_PC_BRANCH: branch_addr_n = jump_target_ex_i;
			cv32e40p_pkg_PC_EXCEPTION: branch_addr_n = exc_pc;
			cv32e40p_pkg_PC_MRET: branch_addr_n = mepc_i;
			cv32e40p_pkg_PC_URET: branch_addr_n = uepc_i;
			cv32e40p_pkg_PC_DRET: branch_addr_n = depc_i;
			cv32e40p_pkg_PC_FENCEI: branch_addr_n = pc_id_o + 4;
			cv32e40p_pkg_PC_HWLOOP: branch_addr_n = hwlp_target_i;
			default:
				;
		endcase
	end
	assign csr_mtvec_init_o = (pc_mux_i == cv32e40p_pkg_PC_BOOT) & pc_set_i;
	assign fetch_failed = 1'b0;
	cv32e40p_prefetch_buffer #(
		.PULP_OBI(PULP_OBI),
		.COREV_PULP(COREV_PULP)
	) prefetch_buffer_i(
		.clk(clk),
		.rst_n(rst_n),
		.req_i(req_i),
		.branch_i(branch_req),
		.branch_addr_i({branch_addr_n[31:1], 1'b0}),
		.hwlp_jump_i(hwlp_jump_i),
		.hwlp_target_i(hwlp_target_i),
		.fetch_ready_i(fetch_ready),
		.fetch_valid_o(fetch_valid),
		.fetch_rdata_o(fetch_rdata),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_err_i(instr_err_i),
		.instr_err_pmp_i(instr_err_pmp_i),
		.instr_rdata_i(instr_rdata_i),
		.busy_o(prefetch_busy)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		fetch_ready = 1'b0;
		branch_req = 1'b0;
		if (pc_set_i)
			branch_req = 1'b1;
		else if (fetch_valid) begin
			if (req_i && if_valid)
				fetch_ready = aligner_ready;
		end
	end
	assign if_busy_o = prefetch_busy;
	assign perf_imiss_o = !fetch_valid && !branch_req;
	always @(posedge clk or negedge rst_n) begin : IF_ID_PIPE_REGISTERS
		if (rst_n == 1'b0) begin
			instr_valid_id_o <= 1'b0;
			instr_rdata_id_o <= 1'sb0;
			is_fetch_failed_o <= 1'b0;
			pc_id_o <= 1'sb0;
			is_compressed_id_o <= 1'b0;
			illegal_c_insn_id_o <= 1'b0;
		end
		else if (if_valid && instr_valid) begin
			instr_valid_id_o <= 1'b1;
			instr_rdata_id_o <= instr_decompressed;
			is_compressed_id_o <= instr_compressed_int;
			illegal_c_insn_id_o <= illegal_c_insn;
			is_fetch_failed_o <= 1'b0;
			pc_id_o <= pc_if_o;
		end
		else if (clear_instr_valid_i) begin
			instr_valid_id_o <= 1'b0;
			is_fetch_failed_o <= fetch_failed;
		end
	end
	assign if_ready = fetch_valid & id_ready_i;
	assign if_valid = ~halt_if_i & if_ready;
	cv32e40p_aligner aligner_i(
		.clk(clk),
		.rst_n(rst_n),
		.fetch_valid_i(fetch_valid),
		.aligner_ready_o(aligner_ready),
		.if_valid_i(if_valid),
		.fetch_rdata_i(fetch_rdata),
		.instr_aligned_o(instr_aligned),
		.instr_valid_o(instr_valid),
		.branch_addr_i({branch_addr_n[31:1], 1'b0}),
		.branch_i(branch_req),
		.hwlp_addr_i(hwlp_target_i),
		.hwlp_update_pc_i(hwlp_jump_i),
		.pc_o(pc_if_o)
	);
	cv32e40p_compressed_decoder #(
		.FPU(FPU),
		.ZFINX(ZFINX)
	) compressed_decoder_i(
		.instr_i(instr_aligned),
		.instr_o(instr_decompressed),
		.is_compressed_o(instr_compressed_int),
		.illegal_instr_o(illegal_c_insn)
	);
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_int_controller (
	clk,
	rst_n,
	irq_i,
	irq_sec_i,
	irq_req_ctrl_o,
	irq_sec_ctrl_o,
	irq_id_ctrl_o,
	irq_wu_ctrl_o,
	mie_bypass_i,
	mip_o,
	m_ie_i,
	u_ie_i,
	current_priv_lvl_i
);
	reg _sv2v_0;
	parameter PULP_SECURE = 0;
	input wire clk;
	input wire rst_n;
	input wire [31:0] irq_i;
	input wire irq_sec_i;
	output wire irq_req_ctrl_o;
	output wire irq_sec_ctrl_o;
	output reg [4:0] irq_id_ctrl_o;
	output wire irq_wu_ctrl_o;
	input wire [31:0] mie_bypass_i;
	output wire [31:0] mip_o;
	input wire m_ie_i;
	input wire u_ie_i;
	input wire [1:0] current_priv_lvl_i;
	wire global_irq_enable;
	wire [31:0] irq_local_qual;
	reg [31:0] irq_q;
	reg irq_sec_q;
	localparam cv32e40p_pkg_IRQ_MASK = 32'hffff0888;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			irq_q <= 1'sb0;
			irq_sec_q <= 1'b0;
		end
		else begin
			irq_q <= irq_i & cv32e40p_pkg_IRQ_MASK;
			irq_sec_q <= irq_sec_i;
		end
	assign mip_o = irq_q;
	assign irq_local_qual = irq_q & mie_bypass_i;
	assign irq_wu_ctrl_o = |(irq_i & mie_bypass_i);
	generate
		if (PULP_SECURE) begin : gen_pulp_secure
			assign global_irq_enable = ((u_ie_i || irq_sec_i) && (current_priv_lvl_i == 2'b00)) || (m_ie_i && (current_priv_lvl_i == 2'b11));
		end
		else begin : gen_no_pulp_secure
			assign global_irq_enable = m_ie_i;
		end
	endgenerate
	assign irq_req_ctrl_o = |irq_local_qual && global_irq_enable;
	localparam [31:0] cv32e40p_pkg_CSR_MEIX_BIT = 11;
	localparam [31:0] cv32e40p_pkg_CSR_MSIX_BIT = 3;
	localparam [31:0] cv32e40p_pkg_CSR_MTIX_BIT = 7;
	always @(*) begin
		if (_sv2v_0)
			;
		if (irq_local_qual[31])
			irq_id_ctrl_o = 5'd31;
		else if (irq_local_qual[30])
			irq_id_ctrl_o = 5'd30;
		else if (irq_local_qual[29])
			irq_id_ctrl_o = 5'd29;
		else if (irq_local_qual[28])
			irq_id_ctrl_o = 5'd28;
		else if (irq_local_qual[27])
			irq_id_ctrl_o = 5'd27;
		else if (irq_local_qual[26])
			irq_id_ctrl_o = 5'd26;
		else if (irq_local_qual[25])
			irq_id_ctrl_o = 5'd25;
		else if (irq_local_qual[24])
			irq_id_ctrl_o = 5'd24;
		else if (irq_local_qual[23])
			irq_id_ctrl_o = 5'd23;
		else if (irq_local_qual[22])
			irq_id_ctrl_o = 5'd22;
		else if (irq_local_qual[21])
			irq_id_ctrl_o = 5'd21;
		else if (irq_local_qual[20])
			irq_id_ctrl_o = 5'd20;
		else if (irq_local_qual[19])
			irq_id_ctrl_o = 5'd19;
		else if (irq_local_qual[18])
			irq_id_ctrl_o = 5'd18;
		else if (irq_local_qual[17])
			irq_id_ctrl_o = 5'd17;
		else if (irq_local_qual[16])
			irq_id_ctrl_o = 5'd16;
		else if (irq_local_qual[15])
			irq_id_ctrl_o = 5'd15;
		else if (irq_local_qual[14])
			irq_id_ctrl_o = 5'd14;
		else if (irq_local_qual[13])
			irq_id_ctrl_o = 5'd13;
		else if (irq_local_qual[12])
			irq_id_ctrl_o = 5'd12;
		else if (irq_local_qual[cv32e40p_pkg_CSR_MEIX_BIT])
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MEIX_BIT;
		else if (irq_local_qual[cv32e40p_pkg_CSR_MSIX_BIT])
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MSIX_BIT;
		else if (irq_local_qual[cv32e40p_pkg_CSR_MTIX_BIT])
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MTIX_BIT;
		else if (irq_local_qual[10])
			irq_id_ctrl_o = 5'd10;
		else if (irq_local_qual[2])
			irq_id_ctrl_o = 5'd2;
		else if (irq_local_qual[6])
			irq_id_ctrl_o = 5'd6;
		else if (irq_local_qual[9])
			irq_id_ctrl_o = 5'd9;
		else if (irq_local_qual[1])
			irq_id_ctrl_o = 5'd1;
		else if (irq_local_qual[5])
			irq_id_ctrl_o = 5'd5;
		else if (irq_local_qual[8])
			irq_id_ctrl_o = 5'd8;
		else if (irq_local_qual[0])
			irq_id_ctrl_o = 5'd0;
		else if (irq_local_qual[4])
			irq_id_ctrl_o = 5'd4;
		else
			irq_id_ctrl_o = cv32e40p_pkg_CSR_MTIX_BIT;
	end
	assign irq_sec_ctrl_o = irq_sec_q;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_load_store_unit (
	clk,
	rst_n,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_err_i,
	data_err_pmp_i,
	data_addr_o,
	data_we_o,
	data_be_o,
	data_wdata_o,
	data_rdata_i,
	data_we_ex_i,
	data_type_ex_i,
	data_wdata_ex_i,
	data_reg_offset_ex_i,
	data_load_event_ex_i,
	data_sign_ext_ex_i,
	data_rdata_ex_o,
	data_req_ex_i,
	operand_a_ex_i,
	operand_b_ex_i,
	addr_useincr_ex_i,
	data_misaligned_ex_i,
	data_misaligned_o,
	data_atop_ex_i,
	data_atop_o,
	p_elw_start_o,
	p_elw_finish_o,
	lsu_ready_ex_o,
	lsu_ready_wb_o,
	busy_o
);
	reg _sv2v_0;
	parameter PULP_OBI = 0;
	input wire clk;
	input wire rst_n;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_err_i;
	input wire data_err_pmp_i;
	output wire [31:0] data_addr_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_wdata_o;
	input wire [31:0] data_rdata_i;
	input wire data_we_ex_i;
	input wire [1:0] data_type_ex_i;
	input wire [31:0] data_wdata_ex_i;
	input wire [1:0] data_reg_offset_ex_i;
	input wire data_load_event_ex_i;
	input wire [1:0] data_sign_ext_ex_i;
	output wire [31:0] data_rdata_ex_o;
	input wire data_req_ex_i;
	input wire [31:0] operand_a_ex_i;
	input wire [31:0] operand_b_ex_i;
	input wire addr_useincr_ex_i;
	input wire data_misaligned_ex_i;
	output reg data_misaligned_o;
	input wire [5:0] data_atop_ex_i;
	output wire [5:0] data_atop_o;
	output wire p_elw_start_o;
	output wire p_elw_finish_o;
	output wire lsu_ready_ex_o;
	output wire lsu_ready_wb_o;
	output wire busy_o;
	localparam DEPTH = 2;
	wire trans_valid;
	wire trans_ready;
	wire [31:0] trans_addr;
	wire trans_we;
	wire [3:0] trans_be;
	wire [31:0] trans_wdata;
	wire [5:0] trans_atop;
	wire resp_valid;
	wire [31:0] resp_rdata;
	wire resp_err;
	reg [1:0] cnt_q;
	reg [1:0] next_cnt;
	wire count_up;
	wire count_down;
	wire ctrl_update;
	wire [31:0] data_addr_int;
	reg [1:0] data_type_q;
	reg [1:0] rdata_offset_q;
	reg [1:0] data_sign_ext_q;
	reg data_we_q;
	reg data_load_event_q;
	wire [1:0] wdata_offset;
	reg [3:0] data_be;
	reg [31:0] data_wdata;
	wire misaligned_st;
	wire load_err_o;
	wire store_err_o;
	reg [31:0] rdata_q;
	always @(*) begin
		if (_sv2v_0)
			;
		case (data_type_ex_i)
			2'b00:
				if (misaligned_st == 1'b0)
					case (data_addr_int[1:0])
						2'b00: data_be = 4'b1111;
						2'b01: data_be = 4'b1110;
						2'b10: data_be = 4'b1100;
						default: data_be = 4'b1000;
					endcase
				else
					case (data_addr_int[1:0])
						2'b01: data_be = 4'b0001;
						2'b10: data_be = 4'b0011;
						2'b11: data_be = 4'b0111;
						default: data_be = 4'b0000;
					endcase
			2'b01:
				if (misaligned_st == 1'b0)
					case (data_addr_int[1:0])
						2'b00: data_be = 4'b0011;
						2'b01: data_be = 4'b0110;
						2'b10: data_be = 4'b1100;
						default: data_be = 4'b1000;
					endcase
				else
					data_be = 4'b0001;
			2'b10, 2'b11:
				case (data_addr_int[1:0])
					2'b00: data_be = 4'b0001;
					2'b01: data_be = 4'b0010;
					2'b10: data_be = 4'b0100;
					default: data_be = 4'b1000;
				endcase
		endcase
	end
	assign wdata_offset = data_addr_int[1:0] - data_reg_offset_ex_i[1:0];
	always @(*) begin
		if (_sv2v_0)
			;
		case (wdata_offset)
			2'b00: data_wdata = data_wdata_ex_i[31:0];
			2'b01: data_wdata = {data_wdata_ex_i[23:0], data_wdata_ex_i[31:24]};
			2'b10: data_wdata = {data_wdata_ex_i[15:0], data_wdata_ex_i[31:16]};
			2'b11: data_wdata = {data_wdata_ex_i[7:0], data_wdata_ex_i[31:8]};
		endcase
	end
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			data_type_q <= 1'sb0;
			rdata_offset_q <= 1'sb0;
			data_sign_ext_q <= 1'sb0;
			data_we_q <= 1'b0;
			data_load_event_q <= 1'b0;
		end
		else if (ctrl_update) begin
			data_type_q <= data_type_ex_i;
			rdata_offset_q <= data_addr_int[1:0];
			data_sign_ext_q <= data_sign_ext_ex_i;
			data_we_q <= data_we_ex_i;
			data_load_event_q <= data_load_event_ex_i;
		end
	assign p_elw_start_o = data_load_event_ex_i && data_req_o;
	assign p_elw_finish_o = (data_load_event_q && data_rvalid_i) && !data_misaligned_ex_i;
	reg [31:0] data_rdata_ext;
	reg [31:0] rdata_w_ext;
	reg [31:0] rdata_h_ext;
	reg [31:0] rdata_b_ext;
	always @(*) begin
		if (_sv2v_0)
			;
		case (rdata_offset_q)
			2'b00: rdata_w_ext = resp_rdata[31:0];
			2'b01: rdata_w_ext = {resp_rdata[7:0], rdata_q[31:8]};
			2'b10: rdata_w_ext = {resp_rdata[15:0], rdata_q[31:16]};
			2'b11: rdata_w_ext = {resp_rdata[23:0], rdata_q[31:24]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (rdata_offset_q)
			2'b00:
				if (data_sign_ext_q == 2'b00)
					rdata_h_ext = {16'h0000, resp_rdata[15:0]};
				else if (data_sign_ext_q == 2'b10)
					rdata_h_ext = {16'hffff, resp_rdata[15:0]};
				else
					rdata_h_ext = {{16 {resp_rdata[15]}}, resp_rdata[15:0]};
			2'b01:
				if (data_sign_ext_q == 2'b00)
					rdata_h_ext = {16'h0000, resp_rdata[23:8]};
				else if (data_sign_ext_q == 2'b10)
					rdata_h_ext = {16'hffff, resp_rdata[23:8]};
				else
					rdata_h_ext = {{16 {resp_rdata[23]}}, resp_rdata[23:8]};
			2'b10:
				if (data_sign_ext_q == 2'b00)
					rdata_h_ext = {16'h0000, resp_rdata[31:16]};
				else if (data_sign_ext_q == 2'b10)
					rdata_h_ext = {16'hffff, resp_rdata[31:16]};
				else
					rdata_h_ext = {{16 {resp_rdata[31]}}, resp_rdata[31:16]};
			2'b11:
				if (data_sign_ext_q == 2'b00)
					rdata_h_ext = {16'h0000, resp_rdata[7:0], rdata_q[31:24]};
				else if (data_sign_ext_q == 2'b10)
					rdata_h_ext = {16'hffff, resp_rdata[7:0], rdata_q[31:24]};
				else
					rdata_h_ext = {{16 {resp_rdata[7]}}, resp_rdata[7:0], rdata_q[31:24]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (rdata_offset_q)
			2'b00:
				if (data_sign_ext_q == 2'b00)
					rdata_b_ext = {24'h000000, resp_rdata[7:0]};
				else if (data_sign_ext_q == 2'b10)
					rdata_b_ext = {24'hffffff, resp_rdata[7:0]};
				else
					rdata_b_ext = {{24 {resp_rdata[7]}}, resp_rdata[7:0]};
			2'b01:
				if (data_sign_ext_q == 2'b00)
					rdata_b_ext = {24'h000000, resp_rdata[15:8]};
				else if (data_sign_ext_q == 2'b10)
					rdata_b_ext = {24'hffffff, resp_rdata[15:8]};
				else
					rdata_b_ext = {{24 {resp_rdata[15]}}, resp_rdata[15:8]};
			2'b10:
				if (data_sign_ext_q == 2'b00)
					rdata_b_ext = {24'h000000, resp_rdata[23:16]};
				else if (data_sign_ext_q == 2'b10)
					rdata_b_ext = {24'hffffff, resp_rdata[23:16]};
				else
					rdata_b_ext = {{24 {resp_rdata[23]}}, resp_rdata[23:16]};
			2'b11:
				if (data_sign_ext_q == 2'b00)
					rdata_b_ext = {24'h000000, resp_rdata[31:24]};
				else if (data_sign_ext_q == 2'b10)
					rdata_b_ext = {24'hffffff, resp_rdata[31:24]};
				else
					rdata_b_ext = {{24 {resp_rdata[31]}}, resp_rdata[31:24]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		case (data_type_q)
			2'b00: data_rdata_ext = rdata_w_ext;
			2'b01: data_rdata_ext = rdata_h_ext;
			2'b10, 2'b11: data_rdata_ext = rdata_b_ext;
		endcase
	end
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			rdata_q <= 1'sb0;
		else if (resp_valid && ~data_we_q) begin
			if ((data_misaligned_ex_i == 1'b1) || (data_misaligned_o == 1'b1))
				rdata_q <= resp_rdata;
			else
				rdata_q <= data_rdata_ext;
		end
	assign data_rdata_ex_o = (resp_valid == 1'b1 ? data_rdata_ext : rdata_q);
	assign misaligned_st = data_misaligned_ex_i;
	assign load_err_o = (data_gnt_i && data_err_pmp_i) && ~data_we_o;
	assign store_err_o = (data_gnt_i && data_err_pmp_i) && data_we_o;
	always @(*) begin
		if (_sv2v_0)
			;
		data_misaligned_o = 1'b0;
		if ((data_req_ex_i == 1'b1) && (data_misaligned_ex_i == 1'b0))
			case (data_type_ex_i)
				2'b00:
					if (data_addr_int[1:0] != 2'b00)
						data_misaligned_o = 1'b1;
				2'b01:
					if (data_addr_int[1:0] == 2'b11)
						data_misaligned_o = 1'b1;
			endcase
	end
	assign data_addr_int = (addr_useincr_ex_i ? operand_a_ex_i + operand_b_ex_i : operand_a_ex_i);
	assign busy_o = (cnt_q != 2'b00) || trans_valid;
	assign trans_addr = (data_misaligned_ex_i ? {data_addr_int[31:2], 2'b00} : data_addr_int);
	assign trans_we = data_we_ex_i;
	assign trans_be = data_be;
	assign trans_wdata = data_wdata;
	assign trans_atop = data_atop_ex_i;
	generate
		if (PULP_OBI == 0) begin : gen_no_pulp_obi
			assign trans_valid = data_req_ex_i && (cnt_q < DEPTH);
		end
		else begin : gen_pulp_obi
			assign trans_valid = (cnt_q == 2'b00 ? data_req_ex_i && (cnt_q < DEPTH) : (data_req_ex_i && (cnt_q < DEPTH)) && resp_valid);
		end
	endgenerate
	assign lsu_ready_wb_o = (cnt_q == 2'b00 ? 1'b1 : resp_valid);
	assign lsu_ready_ex_o = (data_req_ex_i == 1'b0 ? 1'b1 : (cnt_q == 2'b00 ? trans_valid && trans_ready : (cnt_q == 2'b01 ? (resp_valid && trans_valid) && trans_ready : resp_valid)));
	assign ctrl_update = lsu_ready_ex_o && data_req_ex_i;
	assign count_up = trans_valid && trans_ready;
	assign count_down = resp_valid;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case ({count_up, count_down})
			2'b00: next_cnt = cnt_q;
			2'b01: next_cnt = cnt_q - 1'b1;
			2'b10: next_cnt = cnt_q + 1'b1;
			2'b11: next_cnt = cnt_q;
		endcase
	end
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			cnt_q <= 1'sb0;
		else
			cnt_q <= next_cnt;
	cv32e40p_obi_interface #(.TRANS_STABLE(1)) data_obi_i(
		.clk(clk),
		.rst_n(rst_n),
		.trans_valid_i(trans_valid),
		.trans_ready_o(trans_ready),
		.trans_addr_i(trans_addr),
		.trans_we_i(trans_we),
		.trans_be_i(trans_be),
		.trans_wdata_i(trans_wdata),
		.trans_atop_i(trans_atop),
		.resp_valid_o(resp_valid),
		.resp_rdata_o(resp_rdata),
		.resp_err_o(resp_err),
		.obi_req_o(data_req_o),
		.obi_gnt_i(data_gnt_i),
		.obi_addr_o(data_addr_o),
		.obi_we_o(data_we_o),
		.obi_be_o(data_be_o),
		.obi_wdata_o(data_wdata_o),
		.obi_atop_o(data_atop_o),
		.obi_rdata_i(data_rdata_i),
		.obi_rvalid_i(data_rvalid_i),
		.obi_err_i(data_err_i)
	);
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_mult (
	clk,
	rst_n,
	enable_i,
	operator_i,
	short_subword_i,
	short_signed_i,
	op_a_i,
	op_b_i,
	op_c_i,
	imm_i,
	dot_signed_i,
	dot_op_a_i,
	dot_op_b_i,
	dot_op_c_i,
	is_clpx_i,
	clpx_shift_i,
	clpx_img_i,
	result_o,
	multicycle_o,
	mulh_active_o,
	ready_o,
	ex_ready_i
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire enable_i;
	localparam cv32e40p_pkg_MUL_OP_WIDTH = 3;
	input wire [2:0] operator_i;
	input wire short_subword_i;
	input wire [1:0] short_signed_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [31:0] op_c_i;
	input wire [4:0] imm_i;
	input wire [1:0] dot_signed_i;
	input wire [31:0] dot_op_a_i;
	input wire [31:0] dot_op_b_i;
	input wire [31:0] dot_op_c_i;
	input wire is_clpx_i;
	input wire [1:0] clpx_shift_i;
	input wire clpx_img_i;
	output reg [31:0] result_o;
	output reg multicycle_o;
	output reg mulh_active_o;
	output wire ready_o;
	input wire ex_ready_i;
	wire [16:0] short_op_a;
	wire [16:0] short_op_b;
	wire [32:0] short_op_c;
	wire [33:0] short_mul;
	wire [33:0] short_mac;
	wire [31:0] short_round;
	wire [31:0] short_round_tmp;
	wire [33:0] short_result;
	wire short_mac_msb1;
	wire short_mac_msb0;
	wire [4:0] short_imm;
	wire [1:0] short_subword;
	wire [1:0] short_signed;
	wire short_shift_arith;
	reg [4:0] mulh_imm;
	reg [1:0] mulh_subword;
	reg [1:0] mulh_signed;
	reg mulh_shift_arith;
	reg mulh_carry_q;
	reg mulh_save;
	reg mulh_clearcarry;
	reg mulh_ready;
	reg [2:0] mulh_CS;
	reg [2:0] mulh_NS;
	assign short_round_tmp = 32'h00000001 << imm_i;
	function automatic [2:0] sv2v_cast_F9F94;
		input reg [2:0] inp;
		sv2v_cast_F9F94 = inp;
	endfunction
	assign short_round = (operator_i == sv2v_cast_F9F94(3'b011) ? {1'b0, short_round_tmp[31:1]} : {32 {1'sb0}});
	assign short_op_a[15:0] = (short_subword[0] ? op_a_i[31:16] : op_a_i[15:0]);
	assign short_op_b[15:0] = (short_subword[1] ? op_b_i[31:16] : op_b_i[15:0]);
	assign short_op_a[16] = short_signed[0] & short_op_a[15];
	assign short_op_b[16] = short_signed[1] & short_op_b[15];
	assign short_op_c = (mulh_active_o ? $signed({mulh_carry_q, op_c_i}) : $signed(op_c_i));
	assign short_mul = $signed(short_op_a) * $signed(short_op_b);
	assign short_mac = ($signed(short_op_c) + $signed(short_mul)) + $signed(short_round);
	assign short_result = $signed({short_shift_arith & short_mac_msb1, short_shift_arith & short_mac_msb0, short_mac[31:0]}) >>> short_imm;
	assign short_imm = (mulh_active_o ? mulh_imm : imm_i);
	assign short_subword = (mulh_active_o ? mulh_subword : {2 {short_subword_i}});
	assign short_signed = (mulh_active_o ? mulh_signed : short_signed_i);
	assign short_shift_arith = (mulh_active_o ? mulh_shift_arith : short_signed_i[0]);
	assign short_mac_msb1 = (mulh_active_o ? short_mac[33] : short_mac[31]);
	assign short_mac_msb0 = (mulh_active_o ? short_mac[32] : short_mac[31]);
	always @(*) begin
		if (_sv2v_0)
			;
		mulh_NS = mulh_CS;
		mulh_imm = 5'd0;
		mulh_subword = 2'b00;
		mulh_signed = 2'b00;
		mulh_shift_arith = 1'b0;
		mulh_ready = 1'b0;
		mulh_active_o = 1'b1;
		mulh_save = 1'b0;
		mulh_clearcarry = 1'b0;
		multicycle_o = 1'b0;
		case (mulh_CS)
			3'd0: begin
				mulh_active_o = 1'b0;
				mulh_ready = 1'b1;
				mulh_save = 1'b0;
				if ((operator_i == sv2v_cast_F9F94(3'b110)) && enable_i) begin
					mulh_ready = 1'b0;
					mulh_NS = 3'd1;
				end
			end
			3'd1: begin
				multicycle_o = 1'b1;
				mulh_imm = 5'd16;
				mulh_active_o = 1'b1;
				mulh_save = 1'b0;
				mulh_NS = 3'd2;
			end
			3'd2: begin
				multicycle_o = 1'b1;
				mulh_signed = {short_signed_i[1], 1'b0};
				mulh_subword = 2'b10;
				mulh_save = 1'b1;
				mulh_shift_arith = 1'b1;
				mulh_NS = 3'd3;
			end
			3'd3: begin
				multicycle_o = 1'b1;
				mulh_signed = {1'b0, short_signed_i[0]};
				mulh_subword = 2'b01;
				mulh_imm = 5'd16;
				mulh_save = 1'b1;
				mulh_clearcarry = 1'b1;
				mulh_shift_arith = 1'b1;
				mulh_NS = 3'd4;
			end
			3'd4: begin
				mulh_signed = short_signed_i;
				mulh_subword = 2'b11;
				mulh_ready = 1'b1;
				if (ex_ready_i)
					mulh_NS = 3'd0;
			end
		endcase
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			mulh_CS <= 3'd0;
			mulh_carry_q <= 1'b0;
		end
		else begin
			mulh_CS <= mulh_NS;
			if (mulh_save)
				mulh_carry_q <= ~mulh_clearcarry & short_mac[32];
			else if (ex_ready_i)
				mulh_carry_q <= 1'b0;
		end
	wire [31:0] int_op_a_msu;
	wire [31:0] int_op_b_msu;
	wire [31:0] int_result;
	wire int_is_msu;
	assign int_is_msu = operator_i == sv2v_cast_F9F94(3'b001);
	assign int_op_a_msu = op_a_i ^ {32 {int_is_msu}};
	assign int_op_b_msu = op_b_i & {32 {int_is_msu}};
	assign int_result = ($signed(op_c_i) + $signed(int_op_b_msu)) + ($signed(int_op_a_msu) * $signed(op_b_i));
	wire [31:0] dot_char_result;
	wire [32:0] dot_short_result;
	wire [31:0] accumulator;
	wire [15:0] clpx_shift_result;
	wire [35:0] dot_char_op_a;
	wire [35:0] dot_char_op_b;
	wire [71:0] dot_char_mul;
	wire [33:0] dot_short_op_a;
	wire [33:0] dot_short_op_b;
	wire [67:0] dot_short_mul;
	wire [16:0] dot_short_op_a_1_neg;
	wire [31:0] dot_short_op_b_ext;
	assign dot_char_op_a[0+:9] = {dot_signed_i[1] & dot_op_a_i[7], dot_op_a_i[7:0]};
	assign dot_char_op_a[9+:9] = {dot_signed_i[1] & dot_op_a_i[15], dot_op_a_i[15:8]};
	assign dot_char_op_a[18+:9] = {dot_signed_i[1] & dot_op_a_i[23], dot_op_a_i[23:16]};
	assign dot_char_op_a[27+:9] = {dot_signed_i[1] & dot_op_a_i[31], dot_op_a_i[31:24]};
	assign dot_char_op_b[0+:9] = {dot_signed_i[0] & dot_op_b_i[7], dot_op_b_i[7:0]};
	assign dot_char_op_b[9+:9] = {dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:8]};
	assign dot_char_op_b[18+:9] = {dot_signed_i[0] & dot_op_b_i[23], dot_op_b_i[23:16]};
	assign dot_char_op_b[27+:9] = {dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:24]};
	assign dot_char_mul[0+:18] = $signed(dot_char_op_a[0+:9]) * $signed(dot_char_op_b[0+:9]);
	assign dot_char_mul[18+:18] = $signed(dot_char_op_a[9+:9]) * $signed(dot_char_op_b[9+:9]);
	assign dot_char_mul[36+:18] = $signed(dot_char_op_a[18+:9]) * $signed(dot_char_op_b[18+:9]);
	assign dot_char_mul[54+:18] = $signed(dot_char_op_a[27+:9]) * $signed(dot_char_op_b[27+:9]);
	assign dot_char_result = ((($signed(dot_char_mul[0+:18]) + $signed(dot_char_mul[18+:18])) + $signed(dot_char_mul[36+:18])) + $signed(dot_char_mul[54+:18])) + $signed(dot_op_c_i);
	assign dot_short_op_a[0+:17] = {dot_signed_i[1] & dot_op_a_i[15], dot_op_a_i[15:0]};
	assign dot_short_op_a[17+:17] = {dot_signed_i[1] & dot_op_a_i[31], dot_op_a_i[31:16]};
	assign dot_short_op_a_1_neg = dot_short_op_a[17+:17] ^ {17 {is_clpx_i & ~clpx_img_i}};
	assign dot_short_op_b[0+:17] = (is_clpx_i & clpx_img_i ? {dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:16]} : {dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:0]});
	assign dot_short_op_b[17+:17] = (is_clpx_i & clpx_img_i ? {dot_signed_i[0] & dot_op_b_i[15], dot_op_b_i[15:0]} : {dot_signed_i[0] & dot_op_b_i[31], dot_op_b_i[31:16]});
	assign dot_short_mul[0+:34] = $signed(dot_short_op_a[0+:17]) * $signed(dot_short_op_b[0+:17]);
	assign dot_short_mul[34+:34] = $signed(dot_short_op_a_1_neg) * $signed(dot_short_op_b[17+:17]);
	assign dot_short_op_b_ext = $signed(dot_short_op_b[17+:17]);
	assign accumulator = (is_clpx_i ? dot_short_op_b_ext & {32 {~clpx_img_i}} : $signed(dot_op_c_i));
	assign dot_short_result = ($signed(dot_short_mul[31-:32]) + $signed(dot_short_mul[65-:32])) + $signed(accumulator);
	assign clpx_shift_result = $signed(dot_short_result[31:15]) >>> clpx_shift_i;
	always @(*) begin
		if (_sv2v_0)
			;
		result_o = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			sv2v_cast_F9F94(3'b000), sv2v_cast_F9F94(3'b001): result_o = int_result[31:0];
			sv2v_cast_F9F94(3'b010), sv2v_cast_F9F94(3'b011), sv2v_cast_F9F94(3'b110): result_o = short_result[31:0];
			sv2v_cast_F9F94(3'b100): result_o = dot_char_result[31:0];
			sv2v_cast_F9F94(3'b101):
				if (is_clpx_i) begin
					if (clpx_img_i) begin
						result_o[31:16] = clpx_shift_result;
						result_o[15:0] = dot_op_c_i[15:0];
					end
					else begin
						result_o[15:0] = clpx_shift_result;
						result_o[31:16] = dot_op_c_i[31:16];
					end
				end
				else
					result_o = dot_short_result[31:0];
			default:
				;
		endcase
	end
	assign ready_o = mulh_ready;
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_obi_interface (
	clk,
	rst_n,
	trans_valid_i,
	trans_ready_o,
	trans_addr_i,
	trans_we_i,
	trans_be_i,
	trans_wdata_i,
	trans_atop_i,
	resp_valid_o,
	resp_rdata_o,
	resp_err_o,
	obi_req_o,
	obi_gnt_i,
	obi_addr_o,
	obi_we_o,
	obi_be_o,
	obi_wdata_o,
	obi_atop_o,
	obi_rdata_i,
	obi_rvalid_i,
	obi_err_i
);
	reg _sv2v_0;
	parameter TRANS_STABLE = 0;
	input wire clk;
	input wire rst_n;
	input wire trans_valid_i;
	output wire trans_ready_o;
	input wire [31:0] trans_addr_i;
	input wire trans_we_i;
	input wire [3:0] trans_be_i;
	input wire [31:0] trans_wdata_i;
	input wire [5:0] trans_atop_i;
	output wire resp_valid_o;
	output wire [31:0] resp_rdata_o;
	output wire resp_err_o;
	output reg obi_req_o;
	input wire obi_gnt_i;
	output reg [31:0] obi_addr_o;
	output reg obi_we_o;
	output reg [3:0] obi_be_o;
	output reg [31:0] obi_wdata_o;
	output reg [5:0] obi_atop_o;
	input wire [31:0] obi_rdata_i;
	input wire obi_rvalid_i;
	input wire obi_err_i;
	reg state_q;
	reg next_state;
	assign resp_valid_o = obi_rvalid_i;
	assign resp_rdata_o = obi_rdata_i;
	assign resp_err_o = obi_err_i;
	generate
		if (TRANS_STABLE) begin : gen_trans_stable
			wire [1:1] sv2v_tmp_642EA;
			assign sv2v_tmp_642EA = trans_valid_i;
			always @(*) obi_req_o = sv2v_tmp_642EA;
			wire [32:1] sv2v_tmp_9F908;
			assign sv2v_tmp_9F908 = trans_addr_i;
			always @(*) obi_addr_o = sv2v_tmp_9F908;
			wire [1:1] sv2v_tmp_DED80;
			assign sv2v_tmp_DED80 = trans_we_i;
			always @(*) obi_we_o = sv2v_tmp_DED80;
			wire [4:1] sv2v_tmp_81239;
			assign sv2v_tmp_81239 = trans_be_i;
			always @(*) obi_be_o = sv2v_tmp_81239;
			wire [32:1] sv2v_tmp_920BD;
			assign sv2v_tmp_920BD = trans_wdata_i;
			always @(*) obi_wdata_o = sv2v_tmp_920BD;
			wire [6:1] sv2v_tmp_93628;
			assign sv2v_tmp_93628 = trans_atop_i;
			always @(*) obi_atop_o = sv2v_tmp_93628;
			assign trans_ready_o = obi_gnt_i;
			wire [1:1] sv2v_tmp_8A2DB;
			assign sv2v_tmp_8A2DB = 1'd0;
			always @(*) state_q = sv2v_tmp_8A2DB;
			wire [1:1] sv2v_tmp_EEADD;
			assign sv2v_tmp_EEADD = 1'd0;
			always @(*) next_state = sv2v_tmp_EEADD;
		end
		else begin : gen_no_trans_stable
			reg [31:0] obi_addr_q;
			reg obi_we_q;
			reg [3:0] obi_be_q;
			reg [31:0] obi_wdata_q;
			reg [5:0] obi_atop_q;
			always @(*) begin
				if (_sv2v_0)
					;
				next_state = state_q;
				case (state_q)
					1'd0:
						if (obi_req_o && !obi_gnt_i)
							next_state = 1'd1;
					1'd1:
						if (obi_gnt_i)
							next_state = 1'd0;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				if (state_q == 1'd0) begin
					obi_req_o = trans_valid_i;
					obi_addr_o = trans_addr_i;
					obi_we_o = trans_we_i;
					obi_be_o = trans_be_i;
					obi_wdata_o = trans_wdata_i;
					obi_atop_o = trans_atop_i;
				end
				else begin
					obi_req_o = 1'b1;
					obi_addr_o = obi_addr_q;
					obi_we_o = obi_we_q;
					obi_be_o = obi_be_q;
					obi_wdata_o = obi_wdata_q;
					obi_atop_o = obi_atop_q;
				end
			end
			always @(posedge clk or negedge rst_n)
				if (rst_n == 1'b0) begin
					state_q <= 1'd0;
					obi_addr_q <= 32'b00000000000000000000000000000000;
					obi_we_q <= 1'b0;
					obi_be_q <= 4'b0000;
					obi_wdata_q <= 32'b00000000000000000000000000000000;
					obi_atop_q <= 6'b000000;
				end
				else begin
					state_q <= next_state;
					if ((state_q == 1'd0) && (next_state == 1'd1)) begin
						obi_addr_q <= obi_addr_o;
						obi_we_q <= obi_we_o;
						obi_be_q <= obi_be_o;
						obi_wdata_q <= obi_wdata_o;
						obi_atop_q <= obi_atop_o;
					end
				end
			assign trans_ready_o = state_q == 1'd0;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_popcnt (
	in_i,
	result_o
);
	input wire [31:0] in_i;
	output wire [5:0] result_o;
	wire [31:0] cnt_l1;
	wire [23:0] cnt_l2;
	wire [15:0] cnt_l3;
	wire [9:0] cnt_l4;
	genvar _gv_l_2;
	genvar _gv_m_2;
	genvar _gv_n_1;
	genvar _gv_p_1;
	generate
		for (_gv_l_2 = 0; _gv_l_2 < 16; _gv_l_2 = _gv_l_2 + 1) begin : gen_cnt_l1
			localparam l = _gv_l_2;
			assign cnt_l1[l * 2+:2] = {1'b0, in_i[2 * l]} + {1'b0, in_i[(2 * l) + 1]};
		end
		for (_gv_m_2 = 0; _gv_m_2 < 8; _gv_m_2 = _gv_m_2 + 1) begin : gen_cnt_l2
			localparam m = _gv_m_2;
			assign cnt_l2[m * 3+:3] = {1'b0, cnt_l1[(2 * m) * 2+:2]} + {1'b0, cnt_l1[((2 * m) + 1) * 2+:2]};
		end
		for (_gv_n_1 = 0; _gv_n_1 < 4; _gv_n_1 = _gv_n_1 + 1) begin : gen_cnt_l3
			localparam n = _gv_n_1;
			assign cnt_l3[n * 4+:4] = {1'b0, cnt_l2[(2 * n) * 3+:3]} + {1'b0, cnt_l2[((2 * n) + 1) * 3+:3]};
		end
		for (_gv_p_1 = 0; _gv_p_1 < 2; _gv_p_1 = _gv_p_1 + 1) begin : gen_cnt_l4
			localparam p = _gv_p_1;
			assign cnt_l4[p * 5+:5] = {1'b0, cnt_l3[(2 * p) * 4+:4]} + {1'b0, cnt_l3[((2 * p) + 1) * 4+:4]};
		end
	endgenerate
	assign result_o = {1'b0, cnt_l4[0+:5]} + {1'b0, cnt_l4[5+:5]};
endmodule
module cv32e40p_prefetch_buffer (
	clk,
	rst_n,
	req_i,
	branch_i,
	branch_addr_i,
	hwlp_jump_i,
	hwlp_target_i,
	fetch_ready_i,
	fetch_valid_o,
	fetch_rdata_o,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_rvalid_i,
	instr_err_i,
	instr_err_pmp_i,
	busy_o
);
	parameter PULP_OBI = 0;
	parameter COREV_PULP = 1;
	input wire clk;
	input wire rst_n;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] branch_addr_i;
	input wire hwlp_jump_i;
	input wire [31:0] hwlp_target_i;
	input wire fetch_ready_i;
	output wire fetch_valid_o;
	output wire [31:0] fetch_rdata_o;
	output wire instr_req_o;
	input wire instr_gnt_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_rvalid_i;
	input wire instr_err_i;
	input wire instr_err_pmp_i;
	output wire busy_o;
	localparam FIFO_DEPTH = 2;
	localparam [31:0] FIFO_ADDR_DEPTH = 1;
	wire trans_valid;
	wire trans_ready;
	wire [31:0] trans_addr;
	wire fifo_flush;
	wire fifo_flush_but_first;
	wire [FIFO_ADDR_DEPTH:0] fifo_cnt;
	wire [31:0] fifo_rdata;
	wire fifo_push;
	wire fifo_pop;
	wire fifo_empty;
	wire resp_valid;
	wire [31:0] resp_rdata;
	wire resp_err;
	cv32e40p_prefetch_controller #(
		.DEPTH(FIFO_DEPTH),
		.PULP_OBI(PULP_OBI),
		.COREV_PULP(COREV_PULP)
	) prefetch_controller_i(
		.clk(clk),
		.rst_n(rst_n),
		.req_i(req_i),
		.branch_i(branch_i),
		.branch_addr_i(branch_addr_i),
		.busy_o(busy_o),
		.hwlp_jump_i(hwlp_jump_i),
		.hwlp_target_i(hwlp_target_i),
		.trans_valid_o(trans_valid),
		.trans_ready_i(trans_ready),
		.trans_addr_o(trans_addr),
		.resp_valid_i(resp_valid),
		.fetch_ready_i(fetch_ready_i),
		.fetch_valid_o(fetch_valid_o),
		.fifo_push_o(fifo_push),
		.fifo_pop_o(fifo_pop),
		.fifo_flush_o(fifo_flush),
		.fifo_flush_but_first_o(fifo_flush_but_first),
		.fifo_cnt_i(fifo_cnt),
		.fifo_empty_i(fifo_empty)
	);
	cv32e40p_fifo #(
		.FALL_THROUGH(1'b0),
		.DATA_WIDTH(32),
		.DEPTH(FIFO_DEPTH)
	) fifo_i(
		.clk_i(clk),
		.rst_ni(rst_n),
		.flush_i(fifo_flush),
		.flush_but_first_i(fifo_flush_but_first),
		.testmode_i(1'b0),
		.full_o(),
		.empty_o(fifo_empty),
		.cnt_o(fifo_cnt),
		.data_i(resp_rdata),
		.push_i(fifo_push),
		.data_o(fifo_rdata),
		.pop_i(fifo_pop)
	);
	assign fetch_rdata_o = (fifo_empty ? resp_rdata : fifo_rdata);
	cv32e40p_obi_interface #(.TRANS_STABLE(0)) instruction_obi_i(
		.clk(clk),
		.rst_n(rst_n),
		.trans_valid_i(trans_valid),
		.trans_ready_o(trans_ready),
		.trans_addr_i({trans_addr[31:2], 2'b00}),
		.trans_we_i(1'b0),
		.trans_be_i(4'b1111),
		.trans_wdata_i(32'b00000000000000000000000000000000),
		.trans_atop_i(6'b000000),
		.resp_valid_o(resp_valid),
		.resp_rdata_o(resp_rdata),
		.resp_err_o(resp_err),
		.obi_req_o(instr_req_o),
		.obi_gnt_i(instr_gnt_i),
		.obi_addr_o(instr_addr_o),
		.obi_we_o(),
		.obi_be_o(),
		.obi_wdata_o(),
		.obi_atop_o(),
		.obi_rdata_i(instr_rdata_i),
		.obi_rvalid_i(instr_rvalid_i),
		.obi_err_i(instr_err_i)
	);
endmodule
module cv32e40p_prefetch_controller (
	clk,
	rst_n,
	req_i,
	branch_i,
	branch_addr_i,
	busy_o,
	hwlp_jump_i,
	hwlp_target_i,
	trans_valid_o,
	trans_ready_i,
	trans_addr_o,
	resp_valid_i,
	fetch_ready_i,
	fetch_valid_o,
	fifo_push_o,
	fifo_pop_o,
	fifo_flush_o,
	fifo_flush_but_first_o,
	fifo_cnt_i,
	fifo_empty_i
);
	reg _sv2v_0;
	parameter PULP_OBI = 0;
	parameter COREV_PULP = 1;
	parameter DEPTH = 4;
	parameter FIFO_ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk;
	input wire rst_n;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] branch_addr_i;
	output wire busy_o;
	input wire hwlp_jump_i;
	input wire [31:0] hwlp_target_i;
	output wire trans_valid_o;
	input wire trans_ready_i;
	output reg [31:0] trans_addr_o;
	input wire resp_valid_i;
	input wire fetch_ready_i;
	output wire fetch_valid_o;
	output wire fifo_push_o;
	output wire fifo_pop_o;
	output wire fifo_flush_o;
	output wire fifo_flush_but_first_o;
	input wire [FIFO_ADDR_DEPTH:0] fifo_cnt_i;
	input wire fifo_empty_i;
	reg state_q;
	reg next_state;
	reg [FIFO_ADDR_DEPTH:0] cnt_q;
	reg [FIFO_ADDR_DEPTH:0] next_cnt;
	wire count_up;
	wire count_down;
	reg [FIFO_ADDR_DEPTH:0] flush_cnt_q;
	reg [FIFO_ADDR_DEPTH:0] next_flush_cnt;
	reg [31:0] trans_addr_q;
	wire [31:0] trans_addr_incr;
	wire [31:0] aligned_branch_addr;
	wire fifo_valid;
	wire [FIFO_ADDR_DEPTH:0] fifo_cnt_masked;
	wire hwlp_wait_resp_flush;
	reg hwlp_flush_after_resp;
	reg [FIFO_ADDR_DEPTH:0] hwlp_flush_cnt_delayed_q;
	wire hwlp_flush_resp_delayed;
	wire hwlp_flush_resp;
	assign busy_o = (cnt_q != 3'b000) || trans_valid_o;
	assign fetch_valid_o = (fifo_valid || resp_valid_i) && !(branch_i || (flush_cnt_q > 0));
	assign aligned_branch_addr = {branch_addr_i[31:2], 2'b00};
	assign trans_addr_incr = {trans_addr_q[31:2], 2'b00} + 32'd4;
	generate
		if (PULP_OBI == 0) begin : gen_no_pulp_obi
			assign trans_valid_o = req_i && ((fifo_cnt_masked + cnt_q) < DEPTH);
		end
		else begin : gen_pulp_obi
			assign trans_valid_o = (cnt_q == 3'b000 ? req_i && ((fifo_cnt_masked + cnt_q) < DEPTH) : (req_i && ((fifo_cnt_masked + cnt_q) < DEPTH)) && resp_valid_i);
		end
	endgenerate
	assign fifo_cnt_masked = (branch_i || hwlp_jump_i ? {(FIFO_ADDR_DEPTH >= 0 ? FIFO_ADDR_DEPTH + 1 : 1 - FIFO_ADDR_DEPTH) {1'sb0}} : fifo_cnt_i);
	always @(*) begin
		if (_sv2v_0)
			;
		next_state = state_q;
		trans_addr_o = trans_addr_q;
		case (state_q)
			1'd0: begin
				if (branch_i)
					trans_addr_o = aligned_branch_addr;
				else if (hwlp_jump_i)
					trans_addr_o = hwlp_target_i;
				else
					trans_addr_o = trans_addr_incr;
				if ((branch_i || hwlp_jump_i) && !(trans_valid_o && trans_ready_i))
					next_state = 1'd1;
			end
			1'd1: begin
				trans_addr_o = (branch_i ? aligned_branch_addr : trans_addr_q);
				if (trans_valid_o && trans_ready_i)
					next_state = 1'd0;
			end
		endcase
	end
	assign fifo_valid = !fifo_empty_i;
	assign fifo_push_o = (resp_valid_i && (fifo_valid || !fetch_ready_i)) && !(branch_i || (flush_cnt_q > 0));
	assign fifo_pop_o = fifo_valid && fetch_ready_i;
	assign count_up = trans_valid_o && trans_ready_i;
	assign count_down = resp_valid_i;
	always @(*) begin
		if (_sv2v_0)
			;
		case ({count_up, count_down})
			2'b00: next_cnt = cnt_q;
			2'b01: next_cnt = cnt_q - 1'b1;
			2'b10: next_cnt = cnt_q + 1'b1;
			2'b11: next_cnt = cnt_q;
		endcase
	end
	generate
		if (COREV_PULP) begin : gen_hwlp
			assign fifo_flush_o = branch_i || ((hwlp_jump_i && !fifo_empty_i) && fifo_pop_o);
			assign fifo_flush_but_first_o = (hwlp_jump_i && !fifo_empty_i) && !fifo_pop_o;
			assign hwlp_flush_resp = hwlp_jump_i && !(fifo_empty_i && !resp_valid_i);
			assign hwlp_wait_resp_flush = hwlp_jump_i && (fifo_empty_i && !resp_valid_i);
			always @(posedge clk or negedge rst_n)
				if (~rst_n) begin
					hwlp_flush_after_resp <= 1'b0;
					hwlp_flush_cnt_delayed_q <= 2'b00;
				end
				else if (branch_i) begin
					hwlp_flush_after_resp <= 1'b0;
					hwlp_flush_cnt_delayed_q <= 2'b00;
				end
				else if (hwlp_wait_resp_flush) begin
					hwlp_flush_after_resp <= 1'b1;
					hwlp_flush_cnt_delayed_q <= cnt_q - 1'b1;
				end
				else if (hwlp_flush_resp_delayed) begin
					hwlp_flush_after_resp <= 1'b0;
					hwlp_flush_cnt_delayed_q <= 2'b00;
				end
			assign hwlp_flush_resp_delayed = hwlp_flush_after_resp && resp_valid_i;
		end
		else begin : gen_no_hwlp
			assign fifo_flush_o = branch_i;
			assign fifo_flush_but_first_o = 1'b0;
			assign hwlp_flush_resp = 1'b0;
			assign hwlp_wait_resp_flush = 1'b0;
			wire [1:1] sv2v_tmp_844E5;
			assign sv2v_tmp_844E5 = 1'b0;
			always @(*) hwlp_flush_after_resp = sv2v_tmp_844E5;
			wire [(FIFO_ADDR_DEPTH >= 0 ? FIFO_ADDR_DEPTH + 1 : 1 - FIFO_ADDR_DEPTH):1] sv2v_tmp_FC45B;
			assign sv2v_tmp_FC45B = 2'b00;
			always @(*) hwlp_flush_cnt_delayed_q = sv2v_tmp_FC45B;
			assign hwlp_flush_resp_delayed = 1'b0;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		next_flush_cnt = flush_cnt_q;
		if (branch_i || hwlp_flush_resp) begin
			next_flush_cnt = cnt_q;
			if (resp_valid_i && (cnt_q > 0))
				next_flush_cnt = cnt_q - 1'b1;
		end
		else if (hwlp_flush_resp_delayed)
			next_flush_cnt = hwlp_flush_cnt_delayed_q;
		else if (resp_valid_i && (flush_cnt_q > 0))
			next_flush_cnt = flush_cnt_q - 1'b1;
	end
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			state_q <= 1'd0;
			cnt_q <= 1'sb0;
			flush_cnt_q <= 1'sb0;
			trans_addr_q <= 1'sb0;
		end
		else begin
			state_q <= next_state;
			cnt_q <= next_cnt;
			flush_cnt_q <= next_flush_cnt;
			if ((branch_i || hwlp_jump_i) || (trans_valid_o && trans_ready_i))
				trans_addr_q <= trans_addr_o;
		end
	initial _sv2v_0 = 0;
endmodule
module cv32e40p_register_file (
	clk,
	rst_n,
	scan_cg_en_i,
	raddr_a_i,
	rdata_a_o,
	raddr_b_i,
	rdata_b_o,
	raddr_c_i,
	rdata_c_o,
	waddr_a_i,
	wdata_a_i,
	we_a_i,
	waddr_b_i,
	wdata_b_i,
	we_b_i
);
	parameter ADDR_WIDTH = 5;
	parameter DATA_WIDTH = 32;
	parameter FPU = 0;
	parameter ZFINX = 0;
	input wire clk;
	input wire rst_n;
	input wire scan_cg_en_i;
	input wire [ADDR_WIDTH - 1:0] raddr_a_i;
	output wire [DATA_WIDTH - 1:0] rdata_a_o;
	input wire [ADDR_WIDTH - 1:0] raddr_b_i;
	output wire [DATA_WIDTH - 1:0] rdata_b_o;
	input wire [ADDR_WIDTH - 1:0] raddr_c_i;
	output wire [DATA_WIDTH - 1:0] rdata_c_o;
	input wire [ADDR_WIDTH - 1:0] waddr_a_i;
	input wire [DATA_WIDTH - 1:0] wdata_a_i;
	input wire we_a_i;
	input wire [ADDR_WIDTH - 1:0] waddr_b_i;
	input wire [DATA_WIDTH - 1:0] wdata_b_i;
	input wire we_b_i;
	localparam NUM_WORDS = 2 ** (ADDR_WIDTH - 1);
	localparam NUM_FP_WORDS = 2 ** (ADDR_WIDTH - 1);
	localparam NUM_TOT_WORDS = (FPU ? (ZFINX ? NUM_WORDS : NUM_WORDS + NUM_FP_WORDS) : NUM_WORDS);
	reg [(NUM_WORDS * DATA_WIDTH) - 1:0] mem;
	reg [(NUM_FP_WORDS * DATA_WIDTH) - 1:0] mem_fp;
	wire [ADDR_WIDTH - 1:0] waddr_a;
	wire [ADDR_WIDTH - 1:0] waddr_b;
	wire [NUM_TOT_WORDS - 1:0] we_a_dec;
	wire [NUM_TOT_WORDS - 1:0] we_b_dec;
	assign rdata_a_o = (raddr_a_i[5] ? mem_fp[raddr_a_i[4:0] * DATA_WIDTH+:DATA_WIDTH] : mem[raddr_a_i[4:0] * DATA_WIDTH+:DATA_WIDTH]);
	assign rdata_b_o = (raddr_b_i[5] ? mem_fp[raddr_b_i[4:0] * DATA_WIDTH+:DATA_WIDTH] : mem[raddr_b_i[4:0] * DATA_WIDTH+:DATA_WIDTH]);
	assign rdata_c_o = (raddr_c_i[5] ? mem_fp[raddr_c_i[4:0] * DATA_WIDTH+:DATA_WIDTH] : mem[raddr_c_i[4:0] * DATA_WIDTH+:DATA_WIDTH]);
	assign waddr_a = waddr_a_i;
	assign waddr_b = waddr_b_i;
	genvar _gv_gidx_1;
	generate
		for (_gv_gidx_1 = 0; _gv_gidx_1 < NUM_TOT_WORDS; _gv_gidx_1 = _gv_gidx_1 + 1) begin : gen_we_decoder
			localparam gidx = _gv_gidx_1;
			assign we_a_dec[gidx] = (waddr_a == gidx ? we_a_i : 1'b0);
			assign we_b_dec[gidx] = (waddr_b == gidx ? we_b_i : 1'b0);
		end
	endgenerate
	genvar _gv_i_5;
	genvar _gv_l_3;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			mem[0+:DATA_WIDTH] <= 32'b00000000000000000000000000000000;
		else
			mem[0+:DATA_WIDTH] <= 32'b00000000000000000000000000000000;
	generate
		for (_gv_i_5 = 1; _gv_i_5 < NUM_WORDS; _gv_i_5 = _gv_i_5 + 1) begin : gen_rf
			localparam i = _gv_i_5;
			always @(posedge clk or negedge rst_n) begin : register_write_behavioral
				if (rst_n == 1'b0)
					mem[i * DATA_WIDTH+:DATA_WIDTH] <= 32'b00000000000000000000000000000000;
				else if (we_b_dec[i] == 1'b1)
					mem[i * DATA_WIDTH+:DATA_WIDTH] <= wdata_b_i;
				else if (we_a_dec[i] == 1'b1)
					mem[i * DATA_WIDTH+:DATA_WIDTH] <= wdata_a_i;
			end
		end
		if ((FPU == 1) && (ZFINX == 0)) begin : gen_mem_fp_write
			for (_gv_l_3 = 0; _gv_l_3 < NUM_FP_WORDS; _gv_l_3 = _gv_l_3 + 1) begin : genblk1
				localparam l = _gv_l_3;
				always @(posedge clk or negedge rst_n) begin : fp_regs
					if (rst_n == 1'b0)
						mem_fp[l * DATA_WIDTH+:DATA_WIDTH] <= 1'sb0;
					else if (we_b_dec[l + NUM_WORDS] == 1'b1)
						mem_fp[l * DATA_WIDTH+:DATA_WIDTH] <= wdata_b_i;
					else if (we_a_dec[l + NUM_WORDS] == 1'b1)
						mem_fp[l * DATA_WIDTH+:DATA_WIDTH] <= wdata_a_i;
				end
			end
		end
		else begin : gen_no_mem_fp_write
			wire [NUM_FP_WORDS * DATA_WIDTH:1] sv2v_tmp_A73F2;
			assign sv2v_tmp_A73F2 = 'b0;
			always @(*) mem_fp = sv2v_tmp_A73F2;
		end
	endgenerate
endmodule
module cv32e40p_sleep_unit (
	clk_ungated_i,
	rst_n,
	clk_gated_o,
	scan_cg_en_i,
	core_sleep_o,
	fetch_enable_i,
	fetch_enable_o,
	if_busy_i,
	ctrl_busy_i,
	lsu_busy_i,
	apu_busy_i,
	pulp_clock_en_i,
	p_elw_start_i,
	p_elw_finish_i,
	debug_p_elw_no_sleep_i,
	wake_from_sleep_i
);
	parameter COREV_CLUSTER = 0;
	input wire clk_ungated_i;
	input wire rst_n;
	output wire clk_gated_o;
	input wire scan_cg_en_i;
	output wire core_sleep_o;
	input wire fetch_enable_i;
	output wire fetch_enable_o;
	input wire if_busy_i;
	input wire ctrl_busy_i;
	input wire lsu_busy_i;
	input wire apu_busy_i;
	input wire pulp_clock_en_i;
	input wire p_elw_start_i;
	input wire p_elw_finish_i;
	input wire debug_p_elw_no_sleep_i;
	input wire wake_from_sleep_i;
	reg fetch_enable_q;
	wire fetch_enable_d;
	reg core_busy_q;
	wire core_busy_d;
	reg p_elw_busy_q;
	wire p_elw_busy_d;
	wire clock_en;
	assign fetch_enable_d = (fetch_enable_i ? 1'b1 : fetch_enable_q);
	generate
		if (COREV_CLUSTER) begin : g_pulp_sleep
			assign core_busy_d = (p_elw_busy_d ? if_busy_i || apu_busy_i : 1'b1);
			assign clock_en = fetch_enable_q && (pulp_clock_en_i || core_busy_q);
			assign core_sleep_o = (p_elw_busy_d && !core_busy_q) && !debug_p_elw_no_sleep_i;
			assign p_elw_busy_d = (p_elw_start_i ? 1'b1 : (p_elw_finish_i ? 1'b0 : p_elw_busy_q));
		end
		else begin : g_no_pulp_sleep
			assign core_busy_d = ((if_busy_i || ctrl_busy_i) || lsu_busy_i) || apu_busy_i;
			assign clock_en = fetch_enable_q && (wake_from_sleep_i || core_busy_q);
			assign core_sleep_o = fetch_enable_q && !clock_en;
			assign p_elw_busy_d = 1'b0;
		end
	endgenerate
	always @(posedge clk_ungated_i or negedge rst_n)
		if (rst_n == 1'b0) begin
			core_busy_q <= 1'b0;
			p_elw_busy_q <= 1'b0;
			fetch_enable_q <= 1'b0;
		end
		else begin
			core_busy_q <= core_busy_d;
			p_elw_busy_q <= p_elw_busy_d;
			fetch_enable_q <= fetch_enable_d;
		end
	assign fetch_enable_o = fetch_enable_q;
	cv32e40p_clock_gate core_clock_gate_i(
		.clk_i(clk_ungated_i),
		.en_i(clock_en),
		.scan_cg_en_i(scan_cg_en_i),
		.clk_o(clk_gated_o)
	);
endmodule
module cv32e40p_top (
	clk_i,
	rst_ni,
	pulp_clock_en_i,
	scan_cg_en_i,
	boot_addr_i,
	mtvec_addr_i,
	dm_halt_addr_i,
	hart_id_i,
	dm_exception_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_rdata_i,
	irq_i,
	irq_ack_o,
	irq_id_o,
	debug_req_i,
	debug_havereset_o,
	debug_running_o,
	debug_halted_o,
	fetch_enable_i,
	core_sleep_o
);
	parameter COREV_PULP = 0;
	parameter COREV_CLUSTER = 0;
	parameter FPU = 0;
	parameter FPU_ADDMUL_LAT = 0;
	parameter FPU_OTHERS_LAT = 0;
	parameter ZFINX = 0;
	parameter NUM_MHPMCOUNTERS = 1;
	input wire clk_i;
	input wire rst_ni;
	input wire pulp_clock_en_i;
	input wire scan_cg_en_i;
	input wire [31:0] boot_addr_i;
	input wire [31:0] mtvec_addr_i;
	input wire [31:0] dm_halt_addr_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] dm_exception_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	input wire [31:0] data_rdata_i;
	input wire [31:0] irq_i;
	output wire irq_ack_o;
	output wire [4:0] irq_id_o;
	input wire debug_req_i;
	output wire debug_havereset_o;
	output wire debug_running_o;
	output wire debug_halted_o;
	input wire fetch_enable_i;
	output wire core_sleep_o;
	wire apu_busy;
	wire apu_req;
	localparam cv32e40p_apu_core_pkg_APU_NARGS_CPU = 3;
	wire [95:0] apu_operands;
	localparam cv32e40p_apu_core_pkg_APU_WOP_CPU = 6;
	wire [5:0] apu_op;
	localparam cv32e40p_apu_core_pkg_APU_NDSFLAGS_CPU = 15;
	wire [14:0] apu_flags;
	wire apu_gnt;
	wire apu_rvalid;
	wire [31:0] apu_rdata;
	localparam cv32e40p_apu_core_pkg_APU_NUSFLAGS_CPU = 5;
	wire [4:0] apu_rflags;
	wire apu_clk_en;
	wire apu_clk;
	cv32e40p_core #(
		.COREV_PULP(COREV_PULP),
		.COREV_CLUSTER(COREV_CLUSTER),
		.FPU(FPU),
		.FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
		.FPU_OTHERS_LAT(FPU_OTHERS_LAT),
		.ZFINX(ZFINX),
		.NUM_MHPMCOUNTERS(NUM_MHPMCOUNTERS)
	) core_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.pulp_clock_en_i(pulp_clock_en_i),
		.scan_cg_en_i(scan_cg_en_i),
		.boot_addr_i(boot_addr_i),
		.mtvec_addr_i(mtvec_addr_i),
		.dm_halt_addr_i(dm_halt_addr_i),
		.hart_id_i(hart_id_i),
		.dm_exception_addr_i(dm_exception_addr_i),
		.instr_req_o(instr_req_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_addr_o(instr_addr_o),
		.instr_rdata_i(instr_rdata_i),
		.data_req_o(data_req_o),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_addr_o(data_addr_o),
		.data_wdata_o(data_wdata_o),
		.data_rdata_i(data_rdata_i),
		.apu_busy_o(apu_busy),
		.apu_req_o(apu_req),
		.apu_gnt_i(apu_gnt),
		.apu_operands_o(apu_operands),
		.apu_op_o(apu_op),
		.apu_flags_o(apu_flags),
		.apu_rvalid_i(apu_rvalid),
		.apu_result_i(apu_rdata),
		.apu_flags_i(apu_rflags),
		.irq_i(irq_i),
		.irq_ack_o(irq_ack_o),
		.irq_id_o(irq_id_o),
		.debug_req_i(debug_req_i),
		.debug_havereset_o(debug_havereset_o),
		.debug_running_o(debug_running_o),
		.debug_halted_o(debug_halted_o),
		.fetch_enable_i(fetch_enable_i),
		.core_sleep_o(core_sleep_o)
	);
	generate
		if (FPU) begin : fpu_gen
			assign apu_clk_en = apu_req | apu_busy;
			cv32e40p_clock_gate core_clock_gate_i(
				.clk_i(clk_i),
				.en_i(apu_clk_en),
				.scan_cg_en_i(scan_cg_en_i),
				.clk_o(apu_clk)
			);
			cv32e40p_fp_wrapper #(
				.FPU_ADDMUL_LAT(FPU_ADDMUL_LAT),
				.FPU_OTHERS_LAT(FPU_OTHERS_LAT)
			) fp_wrapper_i(
				.clk_i(apu_clk),
				.rst_ni(rst_ni),
				.apu_req_i(apu_req),
				.apu_gnt_o(apu_gnt),
				.apu_operands_i(apu_operands),
				.apu_op_i(apu_op),
				.apu_flags_i(apu_flags),
				.apu_rvalid_o(apu_rvalid),
				.apu_rdata_o(apu_rdata),
				.apu_rflags_o(apu_rflags)
			);
		end
		else begin : no_fpu_gen
			assign apu_gnt = 1'sb0;
			assign apu_rvalid = 1'sb0;
			assign apu_rdata = 1'sb0;
			assign apu_rflags = 1'sb0;
		end
	endgenerate
endmodule
module addr_decode (
	addr_i,
	addr_map_i,
	idx_o,
	dec_valid_o,
	dec_error_o,
	en_default_idx_i,
	default_idx_i
);
	reg _sv2v_0;
	parameter [31:0] NoIndices = 32'd0;
	parameter [31:0] NoRules = 32'd0;
	function automatic [31:0] cf_math_pkg_idx_width;
		input reg [31:0] num_idx;
		cf_math_pkg_idx_width = (num_idx > 32'd1 ? $unsigned($clog2(num_idx)) : 32'd1);
	endfunction
	parameter [31:0] IdxWidth = cf_math_pkg_idx_width(NoIndices);
	input wire addr_i;
	input wire [NoRules - 1:0] addr_map_i;
	output reg [IdxWidth - 1:0] idx_o;
	output reg dec_valid_o;
	output reg dec_error_o;
	input wire en_default_idx_i;
	input wire [IdxWidth - 1:0] default_idx_i;
	reg [NoRules - 1:0] matched_rules;
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		matched_rules = 1'sb0;
		dec_valid_o = 1'b0;
		dec_error_o = (en_default_idx_i ? 1'b0 : 1'b1);
		idx_o = (en_default_idx_i ? default_idx_i : {IdxWidth {1'sb0}});
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < NoRules; i = i + 1)
				if ((addr_i >= addr_map_i[i].start_addr) && (addr_i < addr_map_i[i].end_addr)) begin
					matched_rules[i] = 1'b1;
					dec_valid_o = 1'b1;
					dec_error_o = 1'b0;
					idx_o = sv2v_cast_BCC4E(addr_map_i[i].idx);
				end
		end
	end
	initial begin : proc_check_parameters
		
	end
	always @(addr_map_i)
		#(0) begin : proc_check_addr_map
			if (!$isunknown(addr_map_i)) begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < NoRules; i = i + 1)
					begin
						begin : check_start
							
						end
						begin : check_idx
							
						end
						begin : sv2v_autoblock_3
							reg [31:0] j;
							for (j = i + 1; j < NoRules; j = j + 1)
								begin : check_overlap
									
								end
						end
					end
			end
		end
	initial _sv2v_0 = 0;
endmodule
module binary_to_gray (
	A,
	Z
);
	parameter signed [31:0] N = -1;
	input wire [N - 1:0] A;
	output wire [N - 1:0] Z;
	assign Z = A ^ (A >> 1);
endmodule
module cb_filter (
	clk_i,
	rst_ni,
	look_data_i,
	look_valid_o,
	incr_data_i,
	incr_valid_i,
	decr_data_i,
	decr_valid_i,
	filter_clear_i,
	filter_usage_o,
	filter_full_o,
	filter_empty_o,
	filter_error_o
);
	reg _sv2v_0;
	parameter [31:0] KHashes = 32'd3;
	parameter [31:0] HashWidth = 32'd4;
	parameter [31:0] HashRounds = 32'd1;
	parameter [31:0] InpWidth = 32'd32;
	parameter [31:0] BucketWidth = 32'd4;
	localparam [191:0] cb_filter_pkg_EgSeeds = 192'h11d2e881003e7b72012ff886000f318100047df403e20e8f;
	parameter [(KHashes * 64) - 1:0] Seeds = cb_filter_pkg_EgSeeds;
	input wire clk_i;
	input wire rst_ni;
	input wire [InpWidth - 1:0] look_data_i;
	output wire look_valid_o;
	input wire [InpWidth - 1:0] incr_data_i;
	input wire incr_valid_i;
	input wire [InpWidth - 1:0] decr_data_i;
	input wire decr_valid_i;
	input wire filter_clear_i;
	output wire [HashWidth - 1:0] filter_usage_o;
	output wire filter_full_o;
	output wire filter_empty_o;
	output wire filter_error_o;
	localparam [31:0] NoCounters = 2 ** HashWidth;
	wire [NoCounters - 1:0] look_ind;
	wire [NoCounters - 1:0] incr_ind;
	wire [NoCounters - 1:0] decr_ind;
	reg [NoCounters - 1:0] bucket_en;
	wire [NoCounters - 1:0] bucket_down;
	wire [NoCounters - 1:0] bucket_occupied;
	wire [NoCounters - 1:0] bucket_overflow;
	wire [NoCounters - 1:0] bucket_full;
	wire [NoCounters - 1:0] bucket_empty;
	wire [NoCounters - 1:0] data_in_bucket;
	wire cnt_en;
	wire cnt_down;
	wire cnt_overflow;
	hash_block #(
		.NoHashes(KHashes),
		.InpWidth(InpWidth),
		.HashWidth(HashWidth),
		.NoRounds(HashRounds),
		.Seeds(Seeds)
	) i_look_hashes(
		.data_i(look_data_i),
		.indicator_o(look_ind)
	);
	assign data_in_bucket = look_ind & bucket_occupied;
	assign look_valid_o = (data_in_bucket == look_ind ? 1'b1 : 1'b0);
	hash_block #(
		.NoHashes(KHashes),
		.InpWidth(InpWidth),
		.HashWidth(HashWidth),
		.NoRounds(HashRounds),
		.Seeds(Seeds)
	) i_incr_hashes(
		.data_i(incr_data_i),
		.indicator_o(incr_ind)
	);
	hash_block #(
		.NoHashes(KHashes),
		.InpWidth(InpWidth),
		.HashWidth(HashWidth),
		.NoRounds(HashRounds),
		.Seeds(Seeds)
	) i_decr_hashes(
		.data_i(decr_data_i),
		.indicator_o(decr_ind)
	);
	assign bucket_down = (decr_valid_i ? decr_ind : {NoCounters {1'sb0}});
	always @(*) begin : proc_bucket_control
		if (_sv2v_0)
			;
		case ({incr_valid_i, decr_valid_i})
			2'b00: bucket_en = 1'sb0;
			2'b10: bucket_en = incr_ind;
			2'b01: bucket_en = decr_ind;
			2'b11: bucket_en = incr_ind ^ decr_ind;
			default: bucket_en = 1'sb0;
		endcase
	end
	genvar _gv_i_6;
	generate
		for (_gv_i_6 = 0; _gv_i_6 < NoCounters; _gv_i_6 = _gv_i_6 + 1) begin : gen_buckets
			localparam i = _gv_i_6;
			wire [BucketWidth - 1:0] bucket_content;
			localparam [0:0] sv2v_uu_i_bucket_ext_load_i_0 = 1'sb0;
			localparam [31:0] sv2v_uu_i_bucket_WIDTH = BucketWidth;
			localparam [BucketWidth - 1:0] sv2v_uu_i_bucket_ext_d_i_0 = 1'sb0;
			counter #(.WIDTH(BucketWidth)) i_bucket(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.clear_i(filter_clear_i),
				.en_i(bucket_en[i]),
				.load_i(sv2v_uu_i_bucket_ext_load_i_0),
				.down_i(bucket_down[i]),
				.d_i(sv2v_uu_i_bucket_ext_d_i_0),
				.q_o(bucket_content),
				.overflow_o(bucket_overflow[i])
			);
			assign bucket_full[i] = bucket_overflow[i] | &bucket_content;
			assign bucket_occupied[i] = |bucket_content;
			assign bucket_empty[i] = ~bucket_occupied[i];
		end
	endgenerate
	assign cnt_en = incr_valid_i ^ decr_valid_i;
	assign cnt_down = decr_valid_i;
	localparam [0:0] sv2v_uu_i_tot_count_ext_load_i_0 = 1'sb0;
	localparam [31:0] sv2v_uu_i_tot_count_WIDTH = HashWidth;
	localparam [sv2v_uu_i_tot_count_WIDTH - 1:0] sv2v_uu_i_tot_count_ext_d_i_0 = 1'sb0;
	counter #(.WIDTH(HashWidth)) i_tot_count(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clear_i(filter_clear_i),
		.en_i(cnt_en),
		.load_i(sv2v_uu_i_tot_count_ext_load_i_0),
		.down_i(cnt_down),
		.d_i(sv2v_uu_i_tot_count_ext_d_i_0),
		.q_o(filter_usage_o),
		.overflow_o(cnt_overflow)
	);
	assign filter_full_o = |bucket_full;
	assign filter_empty_o = &bucket_empty;
	assign filter_error_o = |bucket_overflow | cnt_overflow;
	initial _sv2v_0 = 0;
endmodule
module hash_block (
	data_i,
	indicator_o
);
	reg _sv2v_0;
	parameter [31:0] NoHashes = 32'd3;
	parameter [31:0] InpWidth = 32'd11;
	parameter [31:0] HashWidth = 32'd5;
	parameter [31:0] NoRounds = 32'd1;
	localparam [191:0] cb_filter_pkg_EgSeeds = 192'h11d2e881003e7b72012ff886000f318100047df403e20e8f;
	parameter [(NoHashes * 64) - 1:0] Seeds = cb_filter_pkg_EgSeeds;
	input wire [InpWidth - 1:0] data_i;
	output reg [(2 ** HashWidth) - 1:0] indicator_o;
	wire [(NoHashes * (2 ** HashWidth)) - 1:0] hashes;
	genvar _gv_i_7;
	generate
		for (_gv_i_7 = 0; _gv_i_7 < NoHashes; _gv_i_7 = _gv_i_7 + 1) begin : gen_hashes
			localparam i = _gv_i_7;
			sub_per_hash #(
				.InpWidth(InpWidth),
				.HashWidth(HashWidth),
				.NoRounds(NoRounds),
				.PermuteKey(Seeds[(i * 64) + 63-:32]),
				.XorKey(Seeds[(i * 64) + 31-:32])
			) i_hash(
				.data_i(data_i),
				.hash_o(),
				.hash_onehot_o(hashes[i * (2 ** HashWidth)+:2 ** HashWidth])
			);
		end
	endgenerate
	always @(*) begin : proc_hash_or
		if (_sv2v_0)
			;
		indicator_o = 1'sb0;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < (2 ** HashWidth); i = i + 1)
				begin : sv2v_autoblock_2
					reg [31:0] j;
					for (j = 0; j < NoHashes; j = j + 1)
						indicator_o[i] = indicator_o[i] | hashes[(j * (2 ** HashWidth)) + i];
				end
		end
	end
	initial begin : hash_conf
		
	end
	initial _sv2v_0 = 0;
endmodule
module cdc_2phase_94CC0_AF237 (
	src_rst_ni,
	src_clk_i,
	src_data_i,
	src_valid_i,
	src_ready_o,
	dst_rst_ni,
	dst_clk_i,
	dst_data_o,
	dst_valid_o,
	dst_ready_i
);
	parameter signed [31:0] T_PtrWidth = 0;
	input wire src_rst_ni;
	input wire src_clk_i;
	input wire [T_PtrWidth - 1:0] src_data_i;
	input wire src_valid_i;
	output wire src_ready_o;
	input wire dst_rst_ni;
	input wire dst_clk_i;
	output wire [T_PtrWidth - 1:0] dst_data_o;
	output wire dst_valid_o;
	input wire dst_ready_i;
	(* dont_touch = "true" *) wire async_req;
	(* dont_touch = "true" *) wire async_ack;
	(* dont_touch = "true" *) wire [T_PtrWidth - 1:0] async_data;
	cdc_2phase_src_6C646_7BA3E #(.T_T_PtrWidth(T_PtrWidth)) i_src(
		.rst_ni(src_rst_ni),
		.clk_i(src_clk_i),
		.data_i(src_data_i),
		.valid_i(src_valid_i),
		.ready_o(src_ready_o),
		.async_req_o(async_req),
		.async_ack_i(async_ack),
		.async_data_o(async_data)
	);
	cdc_2phase_dst_9772E_A6C1C #(.T_T_PtrWidth(T_PtrWidth)) i_dst(
		.rst_ni(dst_rst_ni),
		.clk_i(dst_clk_i),
		.data_o(dst_data_o),
		.valid_o(dst_valid_o),
		.ready_i(dst_ready_i),
		.async_req_i(async_req),
		.async_ack_o(async_ack),
		.async_data_i(async_data)
	);
endmodule
module cdc_2phase_src_6C646_7BA3E (
	rst_ni,
	clk_i,
	data_i,
	valid_i,
	ready_o,
	async_req_o,
	async_ack_i,
	async_data_o
);
	parameter signed [31:0] T_T_PtrWidth = 0;
	input wire rst_ni;
	input wire clk_i;
	input wire [T_T_PtrWidth - 1:0] data_i;
	input wire valid_i;
	output wire ready_o;
	output wire async_req_o;
	input wire async_ack_i;
	output wire [T_T_PtrWidth - 1:0] async_data_o;
	(* dont_touch = "true" *) reg req_src_q;
	(* dont_touch = "true" *) reg ack_src_q;
	(* dont_touch = "true" *) reg ack_q;
	(* dont_touch = "true" *) reg [T_T_PtrWidth - 1:0] data_src_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			req_src_q <= 0;
			data_src_q <= 1'sb0;
		end
		else if (valid_i && ready_o) begin
			req_src_q <= ~req_src_q;
			data_src_q <= data_i;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ack_src_q <= 0;
			ack_q <= 0;
		end
		else begin
			ack_src_q <= async_ack_i;
			ack_q <= ack_src_q;
		end
	assign ready_o = req_src_q == ack_q;
	assign async_req_o = req_src_q;
	assign async_data_o = data_src_q;
endmodule
module cdc_2phase_dst_9772E_A6C1C (
	rst_ni,
	clk_i,
	data_o,
	valid_o,
	ready_i,
	async_req_i,
	async_ack_o,
	async_data_i
);
	parameter signed [31:0] T_T_PtrWidth = 0;
	input wire rst_ni;
	input wire clk_i;
	output wire [T_T_PtrWidth - 1:0] data_o;
	output wire valid_o;
	input wire ready_i;
	input wire async_req_i;
	output wire async_ack_o;
	input wire [T_T_PtrWidth - 1:0] async_data_i;
	(* dont_touch = "true" *) (* async_reg = "true" *) reg req_dst_q;
	(* dont_touch = "true" *) (* async_reg = "true" *) reg req_q0;
	(* dont_touch = "true" *) (* async_reg = "true" *) reg req_q1;
	(* dont_touch = "true" *) (* async_reg = "true" *) reg ack_dst_q;
	(* dont_touch = "true" *) reg [T_T_PtrWidth - 1:0] data_dst_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			ack_dst_q <= 0;
		else if (valid_o && ready_i)
			ack_dst_q <= ~ack_dst_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			data_dst_q <= 1'sb0;
		else if ((req_q0 != req_q1) && !valid_o)
			data_dst_q <= async_data_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			req_dst_q <= 0;
			req_q0 <= 0;
			req_q1 <= 0;
		end
		else begin
			req_dst_q <= async_req_i;
			req_q0 <= req_dst_q;
			req_q1 <= req_q0;
		end
	assign valid_o = ack_dst_q != req_q1;
	assign data_o = data_dst_q;
	assign async_ack_o = ack_dst_q;
endmodule
module cdc_fifo_2phase (
	src_rst_ni,
	src_clk_i,
	src_data_i,
	src_valid_i,
	src_ready_o,
	dst_rst_ni,
	dst_clk_i,
	dst_data_o,
	dst_valid_o,
	dst_ready_i
);
	parameter signed [31:0] LOG_DEPTH = 3;
	input wire src_rst_ni;
	input wire src_clk_i;
	input wire src_data_i;
	input wire src_valid_i;
	output wire src_ready_o;
	input wire dst_rst_ni;
	input wire dst_clk_i;
	output wire dst_data_o;
	output wire dst_valid_o;
	input wire dst_ready_i;
	localparam signed [31:0] PtrWidth = LOG_DEPTH + 1;
	localparam [PtrWidth - 1:0] PtrFull = 1 << LOG_DEPTH;
	localparam [PtrWidth - 1:0] PtrEmpty = 1'sb0;
	wire [LOG_DEPTH - 1:0] fifo_widx;
	wire [LOG_DEPTH - 1:0] fifo_ridx;
	wire fifo_write;
	wire fifo_wdata;
	wire fifo_rdata;
	reg fifo_data_q [0:(2 ** LOG_DEPTH) - 1];
	assign fifo_rdata = fifo_data_q[fifo_ridx];
	genvar _gv_i_8;
	generate
		for (_gv_i_8 = 0; _gv_i_8 < (2 ** LOG_DEPTH); _gv_i_8 = _gv_i_8 + 1) begin : g_word
			localparam i = _gv_i_8;
			always @(posedge src_clk_i or negedge src_rst_ni)
				if (!src_rst_ni)
					fifo_data_q[i] <= 1'sb0;
				else if (fifo_write && (fifo_widx == i))
					fifo_data_q[i] <= fifo_wdata;
		end
	endgenerate
	reg [PtrWidth - 1:0] src_wptr_q;
	wire [PtrWidth - 1:0] dst_wptr;
	wire [PtrWidth - 1:0] src_rptr;
	reg [PtrWidth - 1:0] dst_rptr_q;
	always @(posedge src_clk_i or negedge src_rst_ni)
		if (!src_rst_ni)
			src_wptr_q <= 0;
		else if (src_valid_i && src_ready_o)
			src_wptr_q <= src_wptr_q + 1;
	always @(posedge dst_clk_i or negedge dst_rst_ni)
		if (!dst_rst_ni)
			dst_rptr_q <= 0;
		else if (dst_valid_o && dst_ready_i)
			dst_rptr_q <= dst_rptr_q + 1;
	assign src_ready_o = (src_wptr_q ^ src_rptr) != PtrFull;
	assign dst_valid_o = (dst_rptr_q ^ dst_wptr) != PtrEmpty;
	cdc_2phase_94CC0_AF237 #(.T_PtrWidth(PtrWidth)) i_cdc_wptr(
		.src_rst_ni(src_rst_ni),
		.src_clk_i(src_clk_i),
		.src_data_i(src_wptr_q),
		.src_valid_i(1'b1),
		.src_ready_o(),
		.dst_rst_ni(dst_rst_ni),
		.dst_clk_i(dst_clk_i),
		.dst_data_o(dst_wptr),
		.dst_valid_o(),
		.dst_ready_i(1'b1)
	);
	cdc_2phase_94CC0_AF237 #(.T_PtrWidth(PtrWidth)) i_cdc_rptr(
		.src_rst_ni(dst_rst_ni),
		.src_clk_i(dst_clk_i),
		.src_data_i(dst_rptr_q),
		.src_valid_i(1'b1),
		.src_ready_o(),
		.dst_rst_ni(src_rst_ni),
		.dst_clk_i(src_clk_i),
		.dst_data_o(src_rptr),
		.dst_valid_o(),
		.dst_ready_i(1'b1)
	);
	assign fifo_widx = src_wptr_q;
	assign fifo_wdata = src_data_i;
	assign fifo_write = src_valid_i && src_ready_o;
	assign fifo_ridx = dst_rptr_q;
	assign dst_data_o = fifo_rdata;
endmodule
(* no_ungroup *) (* no_boundary_optimization *) module cdc_fifo_gray (
	src_rst_ni,
	src_clk_i,
	src_data_i,
	src_valid_i,
	src_ready_o,
	dst_rst_ni,
	dst_clk_i,
	dst_data_o,
	dst_valid_o,
	dst_ready_i
);
	parameter [31:0] WIDTH = 1;
	parameter signed [31:0] LOG_DEPTH = 3;
	parameter signed [31:0] SYNC_STAGES = 2;
	input wire src_rst_ni;
	input wire src_clk_i;
	input wire [WIDTH - 1:0] src_data_i;
	input wire src_valid_i;
	output wire src_ready_o;
	input wire dst_rst_ni;
	input wire dst_clk_i;
	output wire [WIDTH - 1:0] dst_data_o;
	output wire dst_valid_o;
	input wire dst_ready_i;
	wire [((2 ** LOG_DEPTH) * WIDTH) - 1:0] async_data;
	wire [LOG_DEPTH:0] async_wptr;
	wire [LOG_DEPTH:0] async_rptr;
	cdc_fifo_gray_src_6BAB7_82BC4 #(
		.T_WIDTH(WIDTH),
		.LOG_DEPTH(LOG_DEPTH)
	) i_src(
		.src_rst_ni(src_rst_ni),
		.src_clk_i(src_clk_i),
		.src_data_i(src_data_i),
		.src_valid_i(src_valid_i),
		.src_ready_o(src_ready_o),
		.async_data_o(async_data),
		.async_wptr_o(async_wptr),
		.async_rptr_i(async_rptr)
	);
	cdc_fifo_gray_dst_2030F_15C90 #(
		.T_WIDTH(WIDTH),
		.LOG_DEPTH(LOG_DEPTH)
	) i_dst(
		.dst_rst_ni(dst_rst_ni),
		.dst_clk_i(dst_clk_i),
		.dst_data_o(dst_data_o),
		.dst_valid_o(dst_valid_o),
		.dst_ready_i(dst_ready_i),
		.async_data_i(async_data),
		.async_wptr_i(async_wptr),
		.async_rptr_o(async_rptr)
	);
endmodule
(* no_ungroup *) (* no_boundary_optimization *) module cdc_fifo_gray_src_6BAB7_82BC4 (
	src_rst_ni,
	src_clk_i,
	src_data_i,
	src_valid_i,
	src_ready_o,
	async_data_o,
	async_wptr_o,
	async_rptr_i
);
	parameter [31:0] T_WIDTH = 0;
	parameter signed [31:0] LOG_DEPTH = 3;
	parameter signed [31:0] SYNC_STAGES = 2;
	input wire src_rst_ni;
	input wire src_clk_i;
	input wire [T_WIDTH - 1:0] src_data_i;
	input wire src_valid_i;
	output wire src_ready_o;
	output wire [((2 ** LOG_DEPTH) * T_WIDTH) - 1:0] async_data_o;
	output wire [LOG_DEPTH:0] async_wptr_o;
	input wire [LOG_DEPTH:0] async_rptr_i;
	localparam signed [31:0] PtrWidth = LOG_DEPTH + 1;
	localparam [PtrWidth - 1:0] PtrFull = 1 << LOG_DEPTH;
	reg [((2 ** LOG_DEPTH) * T_WIDTH) - 1:0] data_q;
	reg [PtrWidth - 1:0] wptr_q;
	wire [PtrWidth - 1:0] wptr_d;
	wire [PtrWidth - 1:0] wptr_bin;
	wire [PtrWidth - 1:0] wptr_next;
	wire [PtrWidth - 1:0] rptr;
	wire [PtrWidth - 1:0] rptr_bin;
	assign async_data_o = data_q;
	genvar _gv_i_9;
	generate
		for (_gv_i_9 = 0; _gv_i_9 < (2 ** LOG_DEPTH); _gv_i_9 = _gv_i_9 + 1) begin : gen_word
			localparam i = _gv_i_9;
			always @(posedge src_clk_i) data_q[i * T_WIDTH+:T_WIDTH] <= ((src_valid_i & src_ready_o) & (wptr_bin[LOG_DEPTH - 1:0] == i) ? src_data_i : data_q[i * T_WIDTH+:T_WIDTH]);
		end
	endgenerate
	genvar _gv_i_10;
	generate
		for (_gv_i_10 = 0; _gv_i_10 < PtrWidth; _gv_i_10 = _gv_i_10 + 1) begin : gen_sync
			localparam i = _gv_i_10;
			sync #(.STAGES(SYNC_STAGES)) i_sync(
				.clk_i(src_clk_i),
				.rst_ni(src_rst_ni),
				.serial_i(async_rptr_i[i]),
				.serial_o(rptr[i])
			);
		end
	endgenerate
	gray_to_binary #(.N(PtrWidth)) i_rptr_g2b(
		.A(rptr),
		.Z(rptr_bin)
	);
	assign wptr_next = wptr_bin + 1;
	gray_to_binary #(.N(PtrWidth)) i_wptr_g2b(
		.A(wptr_q),
		.Z(wptr_bin)
	);
	binary_to_gray #(.N(PtrWidth)) i_wptr_b2g(
		.A(wptr_next),
		.Z(wptr_d)
	);
	always @(posedge src_clk_i or negedge src_rst_ni)
		if (!src_rst_ni)
			wptr_q <= 1'sb0;
		else
			wptr_q <= (src_valid_i & src_ready_o ? wptr_d : wptr_q);
	assign async_wptr_o = wptr_q;
	assign src_ready_o = (wptr_bin ^ rptr_bin) != PtrFull;
endmodule
(* no_ungroup *) (* no_boundary_optimization *) module cdc_fifo_gray_dst_2030F_15C90 (
	dst_rst_ni,
	dst_clk_i,
	dst_data_o,
	dst_valid_o,
	dst_ready_i,
	async_data_i,
	async_wptr_i,
	async_rptr_o
);
	parameter [31:0] T_WIDTH = 0;
	parameter signed [31:0] LOG_DEPTH = 3;
	parameter signed [31:0] SYNC_STAGES = 2;
	input wire dst_rst_ni;
	input wire dst_clk_i;
	output wire [T_WIDTH - 1:0] dst_data_o;
	output wire dst_valid_o;
	input wire dst_ready_i;
	input wire [((2 ** LOG_DEPTH) * T_WIDTH) - 1:0] async_data_i;
	input wire [LOG_DEPTH:0] async_wptr_i;
	output wire [LOG_DEPTH:0] async_rptr_o;
	localparam signed [31:0] PtrWidth = LOG_DEPTH + 1;
	localparam [PtrWidth - 1:0] PtrEmpty = 1'sb0;
	wire [T_WIDTH - 1:0] dst_data;
	reg [PtrWidth - 1:0] rptr_q;
	wire [PtrWidth - 1:0] rptr_d;
	wire [PtrWidth - 1:0] rptr_bin;
	wire [PtrWidth - 1:0] rptr_bin_d;
	wire [PtrWidth - 1:0] rptr_next;
	wire [PtrWidth - 1:0] wptr;
	wire [PtrWidth - 1:0] wptr_bin;
	wire dst_valid;
	wire dst_ready;
	assign dst_data = async_data_i[rptr_bin[LOG_DEPTH - 1:0] * T_WIDTH+:T_WIDTH];
	assign rptr_next = rptr_bin + 1;
	gray_to_binary #(.N(PtrWidth)) i_rptr_g2b(
		.A(rptr_q),
		.Z(rptr_bin)
	);
	binary_to_gray #(.N(PtrWidth)) i_rptr_b2g(
		.A(rptr_next),
		.Z(rptr_d)
	);
	always @(posedge dst_clk_i or negedge dst_rst_ni)
		if (!dst_rst_ni)
			rptr_q <= 1'sb0;
		else
			rptr_q <= (dst_valid & dst_ready ? rptr_d : rptr_q);
	assign async_rptr_o = rptr_q;
	genvar _gv_i_11;
	generate
		for (_gv_i_11 = 0; _gv_i_11 < PtrWidth; _gv_i_11 = _gv_i_11 + 1) begin : gen_sync
			localparam i = _gv_i_11;
			sync #(.STAGES(SYNC_STAGES)) i_sync(
				.clk_i(dst_clk_i),
				.rst_ni(dst_rst_ni),
				.serial_i(async_wptr_i[i]),
				.serial_o(wptr[i])
			);
		end
	endgenerate
	gray_to_binary #(.N(PtrWidth)) i_wptr_g2b(
		.A(wptr),
		.Z(wptr_bin)
	);
	assign dst_valid = (wptr_bin ^ rptr_bin) != PtrEmpty;
	spill_register_04039_BB60C #(.T_T_WIDTH(T_WIDTH)) i_spill_register(
		.clk_i(dst_clk_i),
		.rst_ni(dst_rst_ni),
		.valid_i(dst_valid),
		.ready_o(dst_ready),
		.data_i(dst_data),
		.valid_o(dst_valid_o),
		.ready_i(dst_ready_i),
		.data_o(dst_data_o)
	);
endmodule
module clk_div (
	clk_i,
	rst_ni,
	testmode_i,
	en_i,
	clk_o
);
	parameter [31:0] RATIO = 4;
	input wire clk_i;
	input wire rst_ni;
	input wire testmode_i;
	input wire en_i;
	output wire clk_o;
	reg [RATIO - 1:0] counter_q;
	reg clk_q;
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			clk_q <= 1'b0;
			counter_q <= 1'sb0;
		end
		else begin
			clk_q <= 1'b0;
			if (en_i) begin
				if (counter_q == (RATIO[RATIO - 1:0] - 1))
					clk_q <= 1'b1;
				else
					counter_q <= counter_q + 1;
			end
		end
	assign clk_o = (testmode_i ? clk_i : clk_q);
endmodule
module counter (
	clk_i,
	rst_ni,
	clear_i,
	en_i,
	load_i,
	down_i,
	d_i,
	q_o,
	overflow_o
);
	parameter [31:0] WIDTH = 4;
	parameter [0:0] STICKY_OVERFLOW = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire clear_i;
	input wire en_i;
	input wire load_i;
	input wire down_i;
	input wire [WIDTH - 1:0] d_i;
	output wire [WIDTH - 1:0] q_o;
	output wire overflow_o;
	delta_counter #(
		.WIDTH(WIDTH),
		.STICKY_OVERFLOW(STICKY_OVERFLOW)
	) i_counter(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clear_i(clear_i),
		.en_i(en_i),
		.load_i(load_i),
		.down_i(down_i),
		.delta_i({{WIDTH - 1 {1'b0}}, 1'b1}),
		.d_i(d_i),
		.q_o(q_o),
		.overflow_o(overflow_o)
	);
endmodule
module delta_counter (
	clk_i,
	rst_ni,
	clear_i,
	en_i,
	load_i,
	down_i,
	delta_i,
	d_i,
	q_o,
	overflow_o
);
	reg _sv2v_0;
	parameter [31:0] WIDTH = 4;
	parameter [0:0] STICKY_OVERFLOW = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire clear_i;
	input wire en_i;
	input wire load_i;
	input wire down_i;
	input wire [WIDTH - 1:0] delta_i;
	input wire [WIDTH - 1:0] d_i;
	output wire [WIDTH - 1:0] q_o;
	output wire overflow_o;
	reg [WIDTH:0] counter_q;
	reg [WIDTH:0] counter_d;
	generate
		if (STICKY_OVERFLOW) begin : gen_sticky_overflow
			reg overflow_d;
			reg overflow_q;
			always @(posedge clk_i or negedge rst_ni) overflow_q <= (~rst_ni ? 1'b0 : overflow_d);
			always @(*) begin
				if (_sv2v_0)
					;
				overflow_d = overflow_q;
				if (clear_i || load_i)
					overflow_d = 1'b0;
				else if (!overflow_q && en_i) begin
					if (down_i)
						overflow_d = delta_i > counter_q[WIDTH - 1:0];
					else
						overflow_d = counter_q[WIDTH - 1:0] > ({WIDTH {1'b1}} - delta_i);
				end
			end
			assign overflow_o = overflow_q;
		end
		else begin : gen_transient_overflow
			assign overflow_o = counter_q[WIDTH];
		end
	endgenerate
	assign q_o = counter_q[WIDTH - 1:0];
	always @(*) begin
		if (_sv2v_0)
			;
		counter_d = counter_q;
		if (clear_i)
			counter_d = 1'sb0;
		else if (load_i)
			counter_d = {1'b0, d_i};
		else if (en_i) begin
			if (down_i)
				counter_d = counter_q - delta_i;
			else
				counter_d = counter_q + delta_i;
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			counter_q <= 1'sb0;
		else
			counter_q <= counter_d;
	initial _sv2v_0 = 0;
endmodule
module clock_divider (
	clk_i,
	rstn_i,
	test_mode_i,
	clk_gate_async_i,
	clk_div_data_i,
	clk_div_valid_i,
	clk_div_ack_o,
	clk_o
);
	reg _sv2v_0;
	parameter DIV_INIT = 0;
	parameter BYPASS_INIT = 1;
	input wire clk_i;
	input wire rstn_i;
	input wire test_mode_i;
	input wire clk_gate_async_i;
	input wire [7:0] clk_div_data_i;
	input wire clk_div_valid_i;
	output wire clk_div_ack_o;
	output wire clk_o;
	reg [1:0] state;
	reg [1:0] state_next;
	wire s_clk_out;
	reg s_clock_enable;
	wire s_clock_enable_gate;
	reg s_clk_div_valid;
	reg [7:0] reg_clk_div;
	wire s_clk_div_valid_sync;
	wire s_rstn_sync;
	reg [1:0] reg_ext_gate_sync;
	assign s_clock_enable_gate = s_clock_enable & reg_ext_gate_sync;
	rstgen i_rst_gen(
		.clk_i(clk_i),
		.rst_ni(rstn_i),
		.test_mode_i(test_mode_i),
		.rst_no(s_rstn_sync),
		.init_no()
	);
	pulp_sync_wedge i_edge_prop(
		.clk_i(clk_i),
		.rstn_i(s_rstn_sync),
		.en_i(1'b1),
		.serial_i(clk_div_valid_i),
		.serial_o(clk_div_ack_o),
		.r_edge_o(s_clk_div_valid_sync),
		.f_edge_o()
	);
	clock_divider_counter #(
		.BYPASS_INIT(BYPASS_INIT),
		.DIV_INIT(DIV_INIT)
	) i_clkdiv_cnt(
		.clk(clk_i),
		.rstn(s_rstn_sync),
		.test_mode(test_mode_i),
		.clk_div(reg_clk_div),
		.clk_div_valid(s_clk_div_valid),
		.clk_out(s_clk_out)
	);
	pulp_clock_gating i_clk_gate(
		.clk_i(s_clk_out),
		.en_i(s_clock_enable_gate),
		.test_en_i(test_mode_i),
		.clk_o(clk_o)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		case (state)
			2'd0: begin
				s_clock_enable = 1'b1;
				s_clk_div_valid = 1'b0;
				if (s_clk_div_valid_sync)
					state_next = 2'd1;
				else
					state_next = 2'd0;
			end
			2'd1: begin
				s_clock_enable = 1'b0;
				s_clk_div_valid = 1'b1;
				state_next = 2'd2;
			end
			2'd2: begin
				s_clock_enable = 1'b0;
				s_clk_div_valid = 1'b0;
				state_next = 2'd3;
			end
			2'd3: begin
				s_clock_enable = 1'b0;
				s_clk_div_valid = 1'b0;
				state_next = 2'd0;
			end
		endcase
	end
	always @(posedge clk_i or negedge s_rstn_sync)
		if (!s_rstn_sync)
			state <= 2'd0;
		else
			state <= state_next;
	always @(posedge clk_i or negedge s_rstn_sync)
		if (!s_rstn_sync)
			reg_clk_div <= 1'sb0;
		else if (s_clk_div_valid_sync)
			reg_clk_div <= clk_div_data_i;
	always @(posedge clk_i or negedge s_rstn_sync)
		if (!s_rstn_sync)
			reg_ext_gate_sync <= 2'b00;
		else
			reg_ext_gate_sync <= {clk_gate_async_i, reg_ext_gate_sync[1]};
	initial _sv2v_0 = 0;
endmodule
module clock_divider_counter (
	clk,
	rstn,
	test_mode,
	clk_div,
	clk_div_valid,
	clk_out
);
	reg _sv2v_0;
	parameter BYPASS_INIT = 1;
	parameter DIV_INIT = 'hff;
	input wire clk;
	input wire rstn;
	input wire test_mode;
	input wire [7:0] clk_div;
	input wire clk_div_valid;
	output wire clk_out;
	reg [7:0] counter;
	reg [7:0] counter_next;
	reg [7:0] clk_cnt;
	reg en1;
	reg en2;
	reg is_odd;
	reg div1;
	reg div2;
	wire div2_neg_sync;
	wire [7:0] clk_cnt_odd;
	wire [7:0] clk_cnt_odd_incr;
	wire [7:0] clk_cnt_even;
	wire [7:0] clk_cnt_en2;
	reg bypass;
	wire clk_out_gen;
	reg clk_div_valid_reg;
	wire clk_inv_test;
	wire clk_inv;
	assign clk_cnt_odd = clk_div - 8'h01;
	assign clk_cnt_even = (clk_div == 8'h02 ? 8'h00 : {1'b0, clk_div[7:1]} - 8'h01);
	assign clk_cnt_en2 = {1'b0, clk_cnt[7:1]} + 8'h01;
	always @(*) begin
		if (_sv2v_0)
			;
		if (counter == 'h0)
			en1 = 1'b1;
		else
			en1 = 1'b0;
		if (clk_div_valid)
			counter_next = 'h0;
		else if (counter == clk_cnt)
			counter_next = 'h0;
		else
			counter_next = counter + 1;
		if (clk_div_valid)
			en2 = 1'b0;
		else if (counter == clk_cnt_en2)
			en2 = 1'b1;
		else
			en2 = 1'b0;
	end
	always @(posedge clk or negedge rstn)
		if (~rstn) begin
			counter <= 'h0;
			div1 <= 1'b0;
			bypass <= BYPASS_INIT;
			clk_cnt <= DIV_INIT;
			is_odd <= 1'b0;
			clk_div_valid_reg <= 1'b0;
		end
		else begin
			if (!bypass)
				counter <= counter_next;
			clk_div_valid_reg <= clk_div_valid;
			if (clk_div_valid) begin
				if ((clk_div == 8'h00) || (clk_div == 8'h01)) begin
					bypass <= 1'b1;
					clk_cnt <= 'h0;
					is_odd <= 1'b0;
				end
				else begin
					bypass <= 1'b0;
					if (clk_div[0]) begin
						is_odd <= 1'b1;
						clk_cnt <= clk_cnt_odd;
					end
					else begin
						is_odd <= 1'b0;
						clk_cnt <= clk_cnt_even;
					end
				end
				div1 <= 1'b0;
			end
			else if (en1 && !bypass)
				div1 <= ~div1;
		end
	pulp_clock_inverter clk_inv_i(
		.clk_i(clk),
		.clk_o(clk_inv)
	);
	assign clk_inv_test = clk_inv;
	always @(posedge clk_inv_test or negedge rstn)
		if (!rstn)
			div2 <= 1'b0;
		else if (clk_div_valid_reg)
			div2 <= 1'b0;
		else if ((en2 && is_odd) && !bypass)
			div2 <= ~div2;
	pulp_clock_xor2 clock_xor_i(
		.clk_o(clk_out_gen),
		.clk0_i(div1),
		.clk1_i(div2)
	);
	pulp_clock_mux2 clk_mux_i(
		.clk0_i(clk_out_gen),
		.clk1_i(clk),
		.clk_sel_i(bypass || test_mode),
		.clk_o(clk_out)
	);
	initial _sv2v_0 = 0;
endmodule
module fifo (
	clk_i,
	rst_ni,
	flush_i,
	testmode_i,
	full_o,
	empty_o,
	threshold_o,
	data_i,
	push_i,
	data_o,
	pop_i
);
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] THRESHOLD = 1;
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire testmode_i;
	output wire full_o;
	output wire empty_o;
	output wire threshold_o;
	input wire [DATA_WIDTH - 1:0] data_i;
	input wire push_i;
	output wire [DATA_WIDTH - 1:0] data_o;
	input wire pop_i;
	fifo_v2_3163A_BB919 #(
		.dtype_DATA_WIDTH(DATA_WIDTH),
		.FALL_THROUGH(FALL_THROUGH),
		.DATA_WIDTH(DATA_WIDTH),
		.DEPTH(DEPTH),
		.ALM_FULL_TH(THRESHOLD)
	) impl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.testmode_i(testmode_i),
		.full_o(full_o),
		.empty_o(empty_o),
		.alm_full_o(threshold_o),
		.alm_empty_o(),
		.data_i(data_i),
		.push_i(push_i),
		.data_o(data_o),
		.pop_i(pop_i)
	);
endmodule
module fifo_v2_3163A_BB919 (
	clk_i,
	rst_ni,
	flush_i,
	testmode_i,
	full_o,
	empty_o,
	alm_full_o,
	alm_empty_o,
	data_i,
	push_i,
	data_o,
	pop_i
);
	parameter [31:0] dtype_DATA_WIDTH = 0;
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] ALM_EMPTY_TH = 1;
	parameter [31:0] ALM_FULL_TH = 1;
	parameter [31:0] ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire testmode_i;
	output wire full_o;
	output wire empty_o;
	output wire alm_full_o;
	output wire alm_empty_o;
	input wire [dtype_DATA_WIDTH - 1:0] data_i;
	input wire push_i;
	output wire [dtype_DATA_WIDTH - 1:0] data_o;
	input wire pop_i;
	wire [ADDR_DEPTH - 1:0] usage;
	generate
		if (DEPTH == 0) begin : genblk1
			assign alm_full_o = 1'b0;
			assign alm_empty_o = 1'b0;
		end
		else begin : genblk1
			assign alm_full_o = usage >= ALM_FULL_TH[ADDR_DEPTH - 1:0];
			assign alm_empty_o = usage <= ALM_EMPTY_TH[ADDR_DEPTH - 1:0];
		end
	endgenerate
	fifo_v3_7B453_D1E92 #(
		.dtype_dtype_DATA_WIDTH(dtype_DATA_WIDTH),
		.FALL_THROUGH(FALL_THROUGH),
		.DATA_WIDTH(DATA_WIDTH),
		.DEPTH(DEPTH)
	) i_fifo_v3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.testmode_i(testmode_i),
		.full_o(full_o),
		.empty_o(empty_o),
		.usage_o(usage),
		.data_i(data_i),
		.push_i(push_i),
		.data_o(data_o),
		.pop_i(pop_i)
	);
endmodule
module fifo_v2_EE579 (
	clk_i,
	rst_ni,
	flush_i,
	testmode_i,
	full_o,
	empty_o,
	alm_full_o,
	alm_empty_o,
	data_i,
	push_i,
	data_o,
	pop_i
);
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] ALM_EMPTY_TH = 1;
	parameter [31:0] ALM_FULL_TH = 1;
	parameter [31:0] ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire testmode_i;
	output wire full_o;
	output wire empty_o;
	output wire alm_full_o;
	output wire alm_empty_o;
	input wire data_i;
	input wire push_i;
	output wire data_o;
	input wire pop_i;
	wire [ADDR_DEPTH - 1:0] usage;
	generate
		if (DEPTH == 0) begin : genblk1
			assign alm_full_o = 1'b0;
			assign alm_empty_o = 1'b0;
		end
		else begin : genblk1
			assign alm_full_o = usage >= ALM_FULL_TH[ADDR_DEPTH - 1:0];
			assign alm_empty_o = usage <= ALM_EMPTY_TH[ADDR_DEPTH - 1:0];
		end
	endgenerate
	fifo_v3_FB6ED #(
		.FALL_THROUGH(FALL_THROUGH),
		.DATA_WIDTH(DATA_WIDTH),
		.DEPTH(DEPTH)
	) i_fifo_v3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.testmode_i(testmode_i),
		.full_o(full_o),
		.empty_o(empty_o),
		.usage_o(usage),
		.data_i(data_i),
		.push_i(push_i),
		.data_o(data_o),
		.pop_i(pop_i)
	);
endmodule
module find_first_one (
	in_i,
	first_one_o,
	no_ones_o
);
	parameter signed [31:0] WIDTH = -1;
	parameter signed [31:0] FLIP = 0;
	input wire [WIDTH - 1:0] in_i;
	output wire [$clog2(WIDTH) - 1:0] first_one_o;
	output wire no_ones_o;
	localparam signed [31:0] NUM_LEVELS = $clog2(WIDTH);
	wire [(WIDTH * NUM_LEVELS) - 1:0] index_lut;
	wire [(2 ** NUM_LEVELS) - 1:0] sel_nodes;
	wire [((2 ** NUM_LEVELS) * NUM_LEVELS) - 1:0] index_nodes;
	wire [WIDTH - 1:0] in_tmp;
	genvar _gv_i_12;
	generate
		for (_gv_i_12 = 0; _gv_i_12 < WIDTH; _gv_i_12 = _gv_i_12 + 1) begin : genblk1
			localparam i = _gv_i_12;
			assign in_tmp[i] = (FLIP ? in_i[(WIDTH - 1) - i] : in_i[i]);
		end
	endgenerate
	genvar _gv_j_4;
	generate
		for (_gv_j_4 = 0; _gv_j_4 < WIDTH; _gv_j_4 = _gv_j_4 + 1) begin : genblk2
			localparam j = _gv_j_4;
			assign index_lut[j * NUM_LEVELS+:NUM_LEVELS] = j;
		end
	endgenerate
	genvar _gv_level_2;
	generate
		for (_gv_level_2 = 0; _gv_level_2 < NUM_LEVELS; _gv_level_2 = _gv_level_2 + 1) begin : genblk3
			localparam level = _gv_level_2;
			if (level < (NUM_LEVELS - 1)) begin : genblk1
				genvar _gv_l_4;
				for (_gv_l_4 = 0; _gv_l_4 < (2 ** level); _gv_l_4 = _gv_l_4 + 1) begin : genblk1
					localparam l = _gv_l_4;
					assign sel_nodes[((2 ** level) - 1) + l] = sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] | sel_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) + 1];
					assign index_nodes[(((2 ** level) - 1) + l) * NUM_LEVELS+:NUM_LEVELS] = (sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] == 1'b1 ? index_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) * NUM_LEVELS+:NUM_LEVELS] : index_nodes[((((2 ** (level + 1)) - 1) + (l * 2)) + 1) * NUM_LEVELS+:NUM_LEVELS]);
				end
			end
			if (level == (NUM_LEVELS - 1)) begin : genblk2
				genvar _gv_k_4;
				for (_gv_k_4 = 0; _gv_k_4 < (2 ** level); _gv_k_4 = _gv_k_4 + 1) begin : genblk1
					localparam k = _gv_k_4;
					if ((k * 2) < (WIDTH - 1)) begin : genblk1
						assign sel_nodes[((2 ** level) - 1) + k] = in_tmp[k * 2] | in_tmp[(k * 2) + 1];
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = (in_tmp[k * 2] == 1'b1 ? index_lut[(k * 2) * NUM_LEVELS+:NUM_LEVELS] : index_lut[((k * 2) + 1) * NUM_LEVELS+:NUM_LEVELS]);
					end
					if ((k * 2) == (WIDTH - 1)) begin : genblk2
						assign sel_nodes[((2 ** level) - 1) + k] = in_tmp[k * 2];
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = index_lut[(k * 2) * NUM_LEVELS+:NUM_LEVELS];
					end
					if ((k * 2) > (WIDTH - 1)) begin : genblk3
						assign sel_nodes[((2 ** level) - 1) + k] = 1'b0;
						assign index_nodes[(((2 ** level) - 1) + k) * NUM_LEVELS+:NUM_LEVELS] = 1'sb0;
					end
				end
			end
		end
	endgenerate
	assign first_one_o = (NUM_LEVELS > 0 ? index_nodes[0+:NUM_LEVELS] : {$clog2(WIDTH) {1'sb0}});
	assign no_ones_o = (NUM_LEVELS > 0 ? ~sel_nodes[0] : 1'b1);
endmodule
module generic_LFSR_8bit (
	data_OH_o,
	data_BIN_o,
	enable_i,
	clk,
	rst_n
);
	reg _sv2v_0;
	parameter OH_WIDTH = 4;
	parameter BIN_WIDTH = $clog2(OH_WIDTH);
	parameter SEED = 8'b00000000;
	output reg [OH_WIDTH - 1:0] data_OH_o;
	output wire [BIN_WIDTH - 1:0] data_BIN_o;
	input wire enable_i;
	input wire clk;
	input wire rst_n;
	reg [7:0] out;
	wire linear_feedback;
	wire [BIN_WIDTH - 1:0] temp_ref_way;
	assign linear_feedback = !(((out[7] ^ out[3]) ^ out[2]) ^ out[1]);
	assign data_BIN_o = temp_ref_way;
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0)
			out <= SEED;
		else if (enable_i)
			out <= {out[6], out[5], out[4], out[3], out[2], out[1], out[0], linear_feedback};
	generate
		if (OH_WIDTH == 2) begin : genblk1
			assign temp_ref_way = out[1];
		end
		else begin : genblk1
			assign temp_ref_way = out[BIN_WIDTH:1];
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		data_OH_o = 1'sb0;
		data_OH_o[temp_ref_way] = 1'b1;
	end
	initial _sv2v_0 = 0;
endmodule
module generic_fifo (
	clk,
	rst_n,
	data_i,
	valid_i,
	grant_o,
	data_o,
	valid_o,
	grant_i,
	test_mode_i
);
	reg _sv2v_0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DATA_DEPTH = 8;
	input wire clk;
	input wire rst_n;
	input wire [DATA_WIDTH - 1:0] data_i;
	input wire valid_i;
	output reg grant_o;
	output wire [DATA_WIDTH - 1:0] data_o;
	output reg valid_o;
	input wire grant_i;
	input wire test_mode_i;
	localparam [31:0] ADDR_DEPTH = $clog2(DATA_DEPTH);
	reg [1:0] CS;
	reg [1:0] NS;
	reg gate_clock;
	wire clk_gated;
	reg [ADDR_DEPTH - 1:0] Pop_Pointer_CS;
	reg [ADDR_DEPTH - 1:0] Pop_Pointer_NS;
	reg [ADDR_DEPTH - 1:0] Push_Pointer_CS;
	reg [ADDR_DEPTH - 1:0] Push_Pointer_NS;
	reg [DATA_WIDTH - 1:0] FIFO_REGISTERS [DATA_DEPTH - 1:0];
	reg [31:0] i;
	initial begin : parameter_check
		integer param_err_flg;
		param_err_flg = 0;
		if (DATA_WIDTH < 1) begin
			param_err_flg = 1;
			$display("ERROR: %m :\n  Invalid value (%d) for parameter DATA_WIDTH (legal range: greater than 1)", DATA_WIDTH);
		end
		if (DATA_DEPTH < 1) begin
			param_err_flg = 1;
			$display("ERROR: %m :\n  Invalid value (%d) for parameter DATA_DEPTH (legal range: greater than 1)", DATA_DEPTH);
		end
	end
	cluster_clock_gating cg_cell(
		.clk_i(clk),
		.en_i(~gate_clock),
		.test_en_i(test_mode_i),
		.clk_o(clk_gated)
	);
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			CS <= 2'd0;
			Pop_Pointer_CS <= {ADDR_DEPTH {1'b0}};
			Push_Pointer_CS <= {ADDR_DEPTH {1'b0}};
		end
		else begin
			CS <= NS;
			Pop_Pointer_CS <= Pop_Pointer_NS;
			Push_Pointer_CS <= Push_Pointer_NS;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		gate_clock = 1'b0;
		case (CS)
			2'd0: begin
				grant_o = 1'b1;
				valid_o = 1'b0;
				case (valid_i)
					1'b0: begin
						NS = 2'd0;
						Push_Pointer_NS = Push_Pointer_CS;
						Pop_Pointer_NS = Pop_Pointer_CS;
						gate_clock = 1'b1;
					end
					1'b1: begin
						NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS + 1'b1;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
				endcase
			end
			2'd2: begin
				grant_o = 1'b1;
				valid_o = 1'b1;
				case ({valid_i, grant_i})
					2'b01: begin
						gate_clock = 1'b1;
						if ((Pop_Pointer_CS == (Push_Pointer_CS - 1)) || ((Pop_Pointer_CS == (DATA_DEPTH - 1)) && (Push_Pointer_CS == 0)))
							NS = 2'd0;
						else
							NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS;
						if (Pop_Pointer_CS == (DATA_DEPTH - 1))
							Pop_Pointer_NS = 0;
						else
							Pop_Pointer_NS = Pop_Pointer_CS + 1'b1;
					end
					2'b00: begin
						gate_clock = 1'b1;
						NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
					2'b11: begin
						NS = 2'd2;
						if (Push_Pointer_CS == (DATA_DEPTH - 1))
							Push_Pointer_NS = 0;
						else
							Push_Pointer_NS = Push_Pointer_CS + 1'b1;
						if (Pop_Pointer_CS == (DATA_DEPTH - 1))
							Pop_Pointer_NS = 0;
						else
							Pop_Pointer_NS = Pop_Pointer_CS + 1'b1;
					end
					2'b10: begin
						if ((Push_Pointer_CS == (Pop_Pointer_CS - 1)) || ((Push_Pointer_CS == (DATA_DEPTH - 1)) && (Pop_Pointer_CS == 0)))
							NS = 2'd1;
						else
							NS = 2'd2;
						if (Push_Pointer_CS == (DATA_DEPTH - 1))
							Push_Pointer_NS = 0;
						else
							Push_Pointer_NS = Push_Pointer_CS + 1'b1;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
				endcase
			end
			2'd1: begin
				grant_o = 1'b0;
				valid_o = 1'b1;
				gate_clock = 1'b1;
				case (grant_i)
					1'b1: begin
						NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS;
						if (Pop_Pointer_CS == (DATA_DEPTH - 1))
							Pop_Pointer_NS = 0;
						else
							Pop_Pointer_NS = Pop_Pointer_CS + 1'b1;
					end
					1'b0: begin
						NS = 2'd1;
						Push_Pointer_NS = Push_Pointer_CS;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
				endcase
			end
			default: begin
				gate_clock = 1'b1;
				grant_o = 1'b0;
				valid_o = 1'b0;
				NS = 2'd0;
				Pop_Pointer_NS = 0;
				Push_Pointer_NS = 0;
			end
		endcase
	end
	always @(posedge clk_gated or negedge rst_n)
		if (rst_n == 1'b0)
			for (i = 0; i < DATA_DEPTH; i = i + 1)
				FIFO_REGISTERS[i] <= {DATA_WIDTH {1'b0}};
		else if ((grant_o == 1'b1) && (valid_i == 1'b1))
			FIFO_REGISTERS[Push_Pointer_CS] <= data_i;
	assign data_o = FIFO_REGISTERS[Pop_Pointer_CS];
	initial _sv2v_0 = 0;
endmodule
module generic_fifo_adv (
	clk,
	rst_n,
	clear_i,
	data_i,
	valid_i,
	grant_o,
	data_o,
	valid_o,
	grant_i,
	test_mode_i
);
	reg _sv2v_0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DATA_DEPTH = 8;
	input wire clk;
	input wire rst_n;
	input wire clear_i;
	input wire [DATA_WIDTH - 1:0] data_i;
	input wire valid_i;
	output reg grant_o;
	output wire [DATA_WIDTH - 1:0] data_o;
	output reg valid_o;
	input wire grant_i;
	input wire test_mode_i;
	localparam [31:0] ADDR_DEPTH = $clog2(DATA_DEPTH);
	reg [1:0] CS;
	reg [1:0] NS;
	reg gate_clock;
	wire clk_gated;
	reg [ADDR_DEPTH - 1:0] Pop_Pointer_CS;
	reg [ADDR_DEPTH - 1:0] Pop_Pointer_NS;
	reg [ADDR_DEPTH - 1:0] Push_Pointer_CS;
	reg [ADDR_DEPTH - 1:0] Push_Pointer_NS;
	reg [DATA_WIDTH - 1:0] FIFO_REGISTERS [DATA_DEPTH - 1:0];
	reg [31:0] i;
	initial begin : parameter_check
		integer param_err_flg;
		param_err_flg = 0;
		if (DATA_WIDTH < 1) begin
			param_err_flg = 1;
			$display("ERROR: %m :\n  Invalid value (%d) for parameter DATA_WIDTH (legal range: greater than 1)", DATA_WIDTH);
		end
		if (DATA_DEPTH < 1) begin
			param_err_flg = 1;
			$display("ERROR: %m :\n  Invalid value (%d) for parameter DATA_DEPTH (legal range: greater than 1)", DATA_DEPTH);
		end
	end
	cluster_clock_gating cg_cell(
		.clk_i(clk),
		.en_i(~gate_clock),
		.test_en_i(test_mode_i),
		.clk_o(clk_gated)
	);
	always @(posedge clk or negedge rst_n)
		if (rst_n == 1'b0) begin
			CS <= 2'd0;
			Pop_Pointer_CS <= {ADDR_DEPTH {1'b0}};
			Push_Pointer_CS <= {ADDR_DEPTH {1'b0}};
		end
		else if (clear_i) begin
			CS <= 2'd0;
			Pop_Pointer_CS <= {ADDR_DEPTH {1'b0}};
			Push_Pointer_CS <= {ADDR_DEPTH {1'b0}};
		end
		else begin
			CS <= NS;
			Pop_Pointer_CS <= Pop_Pointer_NS;
			Push_Pointer_CS <= Push_Pointer_NS;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		gate_clock = 1'b0;
		case (CS)
			2'd0: begin
				grant_o = 1'b1;
				valid_o = 1'b0;
				case (valid_i)
					1'b0: begin
						NS = 2'd0;
						Push_Pointer_NS = Push_Pointer_CS;
						Pop_Pointer_NS = Pop_Pointer_CS;
						gate_clock = 1'b1;
					end
					1'b1: begin
						NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS + 1'b1;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
				endcase
			end
			2'd2: begin
				grant_o = 1'b1;
				valid_o = 1'b1;
				case ({valid_i, grant_i})
					2'b01: begin
						gate_clock = 1'b1;
						if ((Pop_Pointer_CS == (Push_Pointer_CS - 1)) || ((Pop_Pointer_CS == (DATA_DEPTH - 1)) && (Push_Pointer_CS == 0)))
							NS = 2'd0;
						else
							NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS;
						if (Pop_Pointer_CS == (DATA_DEPTH - 1))
							Pop_Pointer_NS = 0;
						else
							Pop_Pointer_NS = Pop_Pointer_CS + 1'b1;
					end
					2'b00: begin
						gate_clock = 1'b1;
						NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
					2'b11: begin
						NS = 2'd2;
						if (Push_Pointer_CS == (DATA_DEPTH - 1))
							Push_Pointer_NS = 0;
						else
							Push_Pointer_NS = Push_Pointer_CS + 1'b1;
						if (Pop_Pointer_CS == (DATA_DEPTH - 1))
							Pop_Pointer_NS = 0;
						else
							Pop_Pointer_NS = Pop_Pointer_CS + 1'b1;
					end
					2'b10: begin
						if ((Push_Pointer_CS == (Pop_Pointer_CS - 1)) || ((Push_Pointer_CS == (DATA_DEPTH - 1)) && (Pop_Pointer_CS == 0)))
							NS = 2'd1;
						else
							NS = 2'd2;
						if (Push_Pointer_CS == (DATA_DEPTH - 1))
							Push_Pointer_NS = 0;
						else
							Push_Pointer_NS = Push_Pointer_CS + 1'b1;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
				endcase
			end
			2'd1: begin
				grant_o = 1'b0;
				valid_o = 1'b1;
				gate_clock = 1'b1;
				case (grant_i)
					1'b1: begin
						NS = 2'd2;
						Push_Pointer_NS = Push_Pointer_CS;
						if (Pop_Pointer_CS == (DATA_DEPTH - 1))
							Pop_Pointer_NS = 0;
						else
							Pop_Pointer_NS = Pop_Pointer_CS + 1'b1;
					end
					1'b0: begin
						NS = 2'd1;
						Push_Pointer_NS = Push_Pointer_CS;
						Pop_Pointer_NS = Pop_Pointer_CS;
					end
				endcase
			end
			default: begin
				gate_clock = 1'b1;
				grant_o = 1'b0;
				valid_o = 1'b0;
				NS = 2'd0;
				Pop_Pointer_NS = 0;
				Push_Pointer_NS = 0;
			end
		endcase
	end
	always @(posedge clk_gated or negedge rst_n)
		if (rst_n == 1'b0)
			for (i = 0; i < DATA_DEPTH; i = i + 1)
				FIFO_REGISTERS[i] <= {DATA_WIDTH {1'b0}};
		else if ((grant_o == 1'b1) && (valid_i == 1'b1))
			FIFO_REGISTERS[Push_Pointer_CS] <= data_i;
	assign data_o = FIFO_REGISTERS[Pop_Pointer_CS];
	initial _sv2v_0 = 0;
endmodule
module prioarbiter (
	clk_i,
	rst_ni,
	flush_i,
	en_i,
	req_i,
	ack_o,
	vld_o,
	idx_o
);
	parameter [31:0] NUM_REQ = 13;
	parameter [31:0] LOCK_IN = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire en_i;
	input wire [NUM_REQ - 1:0] req_i;
	output wire [NUM_REQ - 1:0] ack_o;
	output wire vld_o;
	output wire [$clog2(NUM_REQ) - 1:0] idx_o;
	localparam SEL_WIDTH = $clog2(NUM_REQ);
	wire [SEL_WIDTH - 1:0] arb_sel_lock_d;
	reg [SEL_WIDTH - 1:0] arb_sel_lock_q;
	wire lock_d;
	reg lock_q;
	wire [$clog2(NUM_REQ) - 1:0] idx;
	assign vld_o = |req_i & en_i;
	assign idx_o = (lock_q ? arb_sel_lock_q : idx);
	assign ack_o[0] = (req_i[0] ? en_i : 1'b0);
	genvar _gv_i_13;
	generate
		for (_gv_i_13 = 1; _gv_i_13 < NUM_REQ; _gv_i_13 = _gv_i_13 + 1) begin : gen_arb_req_ports
			localparam i = _gv_i_13;
			assign ack_o[i] = (req_i[i] & ~(|ack_o[i - 1:0]) ? en_i : 1'b0);
		end
	endgenerate
	onehot_to_bin #(.ONEHOT_WIDTH(NUM_REQ)) i_onehot_to_bin(
		.onehot(ack_o),
		.bin(idx)
	);
	generate
		if (LOCK_IN) begin : gen_lock_in
			assign lock_d = |req_i & ~en_i;
			assign arb_sel_lock_d = idx_o;
		end
		else begin : genblk2
			assign lock_d = 1'sb0;
			assign arb_sel_lock_d = 1'sb0;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			lock_q <= 1'b0;
			arb_sel_lock_q <= 1'sb0;
		end
		else if (flush_i) begin
			lock_q <= 1'b0;
			arb_sel_lock_q <= 1'sb0;
		end
		else begin
			lock_q <= lock_d;
			arb_sel_lock_q <= arb_sel_lock_d;
		end
	end
endmodule
module pulp_sync (
	clk_i,
	rstn_i,
	serial_i,
	serial_o
);
	parameter STAGES = 2;
	input wire clk_i;
	input wire rstn_i;
	input wire serial_i;
	output wire serial_o;
	reg [STAGES - 1:0] r_reg;
	always @(posedge clk_i or negedge rstn_i)
		if (!rstn_i)
			r_reg <= 'h0;
		else
			r_reg <= {r_reg[STAGES - 2:0], serial_i};
	assign serial_o = r_reg[STAGES - 1];
endmodule
module pulp_sync_wedge (
	clk_i,
	rstn_i,
	en_i,
	serial_i,
	r_edge_o,
	f_edge_o,
	serial_o
);
	parameter [31:0] STAGES = 2;
	input wire clk_i;
	input wire rstn_i;
	input wire en_i;
	input wire serial_i;
	output wire r_edge_o;
	output wire f_edge_o;
	output wire serial_o;
	wire clk;
	wire serial;
	reg serial_q;
	assign serial_o = serial_q;
	assign f_edge_o = ~serial & serial_q;
	assign r_edge_o = serial & ~serial_q;
	pulp_sync #(.STAGES(STAGES)) i_pulp_sync(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.serial_i(serial_i),
		.serial_o(serial)
	);
	pulp_clock_gating i_pulp_clock_gating(
		.clk_i(clk_i),
		.en_i(en_i),
		.test_en_i(1'b0),
		.clk_o(clk)
	);
	always @(posedge clk or negedge rstn_i)
		if (!rstn_i)
			serial_q <= 1'b0;
		else
			serial_q <= serial;
endmodule
module rrarbiter (
	clk_i,
	rst_ni,
	flush_i,
	en_i,
	req_i,
	ack_o,
	vld_o,
	idx_o
);
	parameter [31:0] NUM_REQ = 64;
	parameter [0:0] LOCK_IN = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire en_i;
	input wire [NUM_REQ - 1:0] req_i;
	output wire [NUM_REQ - 1:0] ack_o;
	output wire vld_o;
	output wire [$clog2(NUM_REQ) - 1:0] idx_o;
	wire req;
	assign vld_o = |req_i & en_i;
	localparam [31:0] sv2v_uu_i_rr_arb_tree_NumIn = NUM_REQ;
	localparam [31:0] sv2v_uu_i_rr_arb_tree_IdxWidth = (sv2v_uu_i_rr_arb_tree_NumIn > 32'd1 ? $unsigned($clog2(sv2v_uu_i_rr_arb_tree_NumIn)) : 32'd1);
	localparam [sv2v_uu_i_rr_arb_tree_IdxWidth - 1:0] sv2v_uu_i_rr_arb_tree_ext_rr_i_0 = 1'sb0;
	localparam [31:0] sv2v_uu_i_rr_arb_tree_DataWidth = 1;
	localparam [(sv2v_uu_i_rr_arb_tree_NumIn * sv2v_uu_i_rr_arb_tree_DataWidth) - 1:0] sv2v_uu_i_rr_arb_tree_ext_data_i_0 = 1'sb0;
	rr_arb_tree #(
		.NumIn(NUM_REQ),
		.DataWidth(1),
		.LockIn(LOCK_IN)
	) i_rr_arb_tree(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.rr_i(sv2v_uu_i_rr_arb_tree_ext_rr_i_0),
		.req_i(req_i),
		.gnt_o(ack_o),
		.data_i(sv2v_uu_i_rr_arb_tree_ext_data_i_0),
		.gnt_i(en_i & req),
		.req_o(req),
		.data_o(),
		.idx_o(idx_o)
	);
endmodule
module sram (
	clk_i,
	req_i,
	we_i,
	addr_i,
	wdata_i,
	be_i,
	rdata_o
);
	parameter [31:0] DATA_WIDTH = 64;
	parameter [31:0] NUM_WORDS = 1024;
	input wire clk_i;
	input wire req_i;
	input wire we_i;
	input wire [$clog2(NUM_WORDS) - 1:0] addr_i;
	input wire [DATA_WIDTH - 1:0] wdata_i;
	input wire [DATA_WIDTH - 1:0] be_i;
	output wire [DATA_WIDTH - 1:0] rdata_o;
	localparam ADDR_WIDTH = $clog2(NUM_WORDS);
	reg [DATA_WIDTH - 1:0] ram [NUM_WORDS - 1:0];
	reg [ADDR_WIDTH - 1:0] raddr_q;
	always @(posedge clk_i)
		if (req_i) begin
			if (!we_i)
				raddr_q <= addr_i;
			else begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < DATA_WIDTH; i = i + 1)
					if (be_i[i])
						ram[addr_i][i] <= wdata_i[i];
			end
		end
	assign rdata_o = ram[raddr_q];
endmodule
module ecc_decode (
	data_i,
	data_o,
	syndrome_o,
	single_error_o,
	parity_error_o,
	double_error_o
);
	reg _sv2v_0;
	parameter [31:0] DataWidth = 64;
	function automatic [31:0] ecc_pkg_get_parity_width;
		input reg [31:0] data_width;
		reg [31:0] cw_width;
		begin
			cw_width = 2;
			while ($unsigned(2 ** cw_width) < ((cw_width + data_width) + 1)) cw_width = cw_width + 1;
			ecc_pkg_get_parity_width = cw_width;
		end
	endfunction
	function automatic [31:0] ecc_pkg_get_cw_width;
		input reg [31:0] data_width;
		ecc_pkg_get_cw_width = data_width + ecc_pkg_get_parity_width(data_width);
	endfunction
	input wire [(1 + ecc_pkg_get_cw_width(DataWidth)) - 1:0] data_i;
	output wire [DataWidth - 1:0] data_o;
	output wire [ecc_pkg_get_parity_width(DataWidth) - 1:0] syndrome_o;
	output wire single_error_o;
	output wire parity_error_o;
	output wire double_error_o;
	wire parity;
	reg [DataWidth - 1:0] data_wo_parity;
	reg [ecc_pkg_get_parity_width(DataWidth) - 1:0] syndrome;
	wire syndrome_not_zero;
	reg [ecc_pkg_get_cw_width(DataWidth) - 1:0] correct_data;
	assign parity = data_i[ecc_pkg_get_cw_width(DataWidth) + 0] ^ ^data_i[ecc_pkg_get_cw_width(DataWidth) - 1-:ecc_pkg_get_cw_width(DataWidth)];
	always @(*) begin : calculate_syndrome
		if (_sv2v_0)
			;
		syndrome = 0;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < $unsigned(ecc_pkg_get_parity_width(DataWidth)); i = i + 1)
				begin : sv2v_autoblock_2
					reg [31:0] j;
					for (j = 0; j < $unsigned(ecc_pkg_get_cw_width(DataWidth)); j = j + 1)
						if (|($unsigned(2 ** i) & (j + 1)))
							syndrome[i] = syndrome[i] ^ data_i[(ecc_pkg_get_cw_width(DataWidth) - 1) - ((ecc_pkg_get_cw_width(DataWidth) - 1) - j)];
				end
		end
	end
	assign syndrome_not_zero = |syndrome;
	always @(*) begin
		if (_sv2v_0)
			;
		correct_data = data_i[ecc_pkg_get_cw_width(DataWidth) - 1-:ecc_pkg_get_cw_width(DataWidth)];
		if (syndrome_not_zero)
			correct_data[syndrome - 1] = ~data_i[(ecc_pkg_get_cw_width(DataWidth) - 1) - ((ecc_pkg_get_cw_width(DataWidth) - 1) - (syndrome - 1))];
	end
	assign single_error_o = parity & syndrome_not_zero;
	assign parity_error_o = parity & ~syndrome_not_zero;
	assign double_error_o = ~parity & syndrome_not_zero;
	always @(*) begin : sv2v_autoblock_3
		reg [31:0] idx;
		if (_sv2v_0)
			;
		data_wo_parity = 1'sb0;
		idx = 0;
		begin : sv2v_autoblock_4
			reg [31:0] i;
			for (i = 1; i < ($unsigned(ecc_pkg_get_cw_width(DataWidth)) + 1); i = i + 1)
				if ($unsigned(2 ** $clog2(i)) != i) begin
					data_wo_parity[idx] = correct_data[i - 1];
					idx = idx + 1;
				end
		end
	end
	assign data_o = data_wo_parity;
	initial _sv2v_0 = 0;
endmodule
module ecc_encode (
	data_i,
	data_o
);
	reg _sv2v_0;
	parameter [31:0] DataWidth = 64;
	function automatic [31:0] ecc_pkg_get_parity_width;
		input reg [31:0] data_width;
		reg [31:0] cw_width;
		begin
			cw_width = 2;
			while ($unsigned(2 ** cw_width) < ((cw_width + data_width) + 1)) cw_width = cw_width + 1;
			ecc_pkg_get_parity_width = cw_width;
		end
	endfunction
	function automatic [31:0] ecc_pkg_get_cw_width;
		input reg [31:0] data_width;
		ecc_pkg_get_cw_width = data_width + ecc_pkg_get_parity_width(data_width);
	endfunction
	input wire [DataWidth - 1:0] data_i;
	output wire [(1 + ecc_pkg_get_cw_width(DataWidth)) - 1:0] data_o;
	reg [ecc_pkg_get_parity_width(DataWidth) - 1:0] parity_code_word;
	reg [ecc_pkg_get_cw_width(DataWidth) - 1:0] data;
	reg [ecc_pkg_get_cw_width(DataWidth) - 1:0] codeword;
	always @(*) begin : expand_data
		reg [31:0] idx;
		if (_sv2v_0)
			;
		data = 1'sb0;
		idx = 0;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 1; i < ($unsigned(ecc_pkg_get_cw_width(DataWidth)) + 1); i = i + 1)
				if ($unsigned(2 ** $clog2(i)) != i) begin
					data[i - 1] = data_i[idx];
					idx = idx + 1;
				end
		end
	end
	always @(*) begin : calculate_syndrome
		if (_sv2v_0)
			;
		parity_code_word = 0;
		begin : sv2v_autoblock_2
			reg [31:0] i;
			for (i = 0; i < $unsigned(ecc_pkg_get_parity_width(DataWidth)); i = i + 1)
				begin : sv2v_autoblock_3
					reg [31:0] j;
					for (j = 1; j < ($unsigned(ecc_pkg_get_cw_width(DataWidth)) + 1); j = j + 1)
						if (|($unsigned(2 ** i) & j))
							parity_code_word[i] = parity_code_word[i] ^ data[j - 1];
				end
		end
	end
	always @(*) begin : generate_codeword
		if (_sv2v_0)
			;
		codeword = data;
		begin : sv2v_autoblock_4
			reg [31:0] i;
			for (i = 0; i < $unsigned(ecc_pkg_get_parity_width(DataWidth)); i = i + 1)
				codeword[(2 ** i) - 1] = parity_code_word[i];
		end
	end
	assign data_o[ecc_pkg_get_cw_width(DataWidth) - 1-:ecc_pkg_get_cw_width(DataWidth)] = codeword;
	assign data_o[ecc_pkg_get_cw_width(DataWidth) + 0] = ^codeword;
	initial _sv2v_0 = 0;
endmodule
module edge_detect (
	clk_i,
	rst_ni,
	d_i,
	re_o,
	fe_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire d_i;
	output wire re_o;
	output wire fe_o;
	sync_wedge i_sync_wedge(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.en_i(1'b1),
		.serial_i(d_i),
		.r_edge_o(re_o),
		.f_edge_o(fe_o),
		.serial_o()
	);
endmodule
module edge_propagator (
	clk_tx_i,
	rstn_tx_i,
	edge_i,
	clk_rx_i,
	rstn_rx_i,
	edge_o
);
	input wire clk_tx_i;
	input wire rstn_tx_i;
	input wire edge_i;
	input wire clk_rx_i;
	input wire rstn_rx_i;
	output wire edge_o;
	reg [1:0] sync_a;
	wire sync_b;
	reg r_input_reg;
	wire s_input_reg_next;
	assign s_input_reg_next = edge_i | (r_input_reg & ~sync_a[0]);
	always @(negedge rstn_tx_i or posedge clk_tx_i)
		if (~rstn_tx_i) begin
			r_input_reg <= 1'b0;
			sync_a <= 2'b00;
		end
		else begin
			r_input_reg <= s_input_reg_next;
			sync_a <= {sync_b, sync_a[1]};
		end
	pulp_sync_wedge i_sync_clkb(
		.clk_i(clk_rx_i),
		.rstn_i(rstn_rx_i),
		.en_i(1'b1),
		.serial_i(r_input_reg),
		.r_edge_o(edge_o),
		.f_edge_o(),
		.serial_o(sync_b)
	);
endmodule
module edge_propagator_rx (
	clk_i,
	rstn_i,
	valid_i,
	ack_o,
	valid_o
);
	input wire clk_i;
	input wire rstn_i;
	input wire valid_i;
	output wire ack_o;
	output wire valid_o;
	pulp_sync_wedge i_sync_clkb(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.en_i(1'b1),
		.serial_i(valid_i),
		.r_edge_o(valid_o),
		.f_edge_o(),
		.serial_o(ack_o)
	);
endmodule
module edge_propagator_tx (
	clk_i,
	rstn_i,
	valid_i,
	ack_i,
	valid_o
);
	input wire clk_i;
	input wire rstn_i;
	input wire valid_i;
	input wire ack_i;
	output wire valid_o;
	reg [1:0] sync_a;
	reg r_input_reg;
	wire s_input_reg_next;
	assign s_input_reg_next = valid_i | (r_input_reg & ~sync_a[0]);
	always @(negedge rstn_i or posedge clk_i)
		if (~rstn_i) begin
			r_input_reg <= 1'b0;
			sync_a <= 2'b00;
		end
		else begin
			r_input_reg <= s_input_reg_next;
			sync_a <= {ack_i, sync_a[1]};
		end
	assign valid_o = r_input_reg;
endmodule
module exp_backoff (
	clk_i,
	rst_ni,
	set_i,
	clr_i,
	is_zero_o
);
	parameter [31:0] Seed = 'hffff;
	parameter [31:0] MaxExp = 16;
	input wire clk_i;
	input wire rst_ni;
	input wire set_i;
	input wire clr_i;
	output wire is_zero_o;
	localparam [31:0] WIDTH = 16;
	wire [15:0] lfsr_d;
	reg [15:0] lfsr_q;
	wire [15:0] cnt_d;
	reg [15:0] cnt_q;
	wire [15:0] mask_d;
	reg [15:0] mask_q;
	wire lfsr;
	assign lfsr = ((lfsr_q[0] ^ lfsr_q[2]) ^ lfsr_q[3]) ^ lfsr_q[5];
	assign lfsr_d = (set_i ? {lfsr, lfsr_q[15:1]} : lfsr_q);
	assign mask_d = (clr_i ? {16 {1'sb0}} : (set_i ? {{WIDTH - MaxExp {1'b0}}, mask_q[MaxExp - 2:0], 1'b1} : mask_q));
	assign cnt_d = (clr_i ? {16 {1'sb0}} : (set_i ? mask_q & lfsr_q : (!is_zero_o ? cnt_q - 1'b1 : {16 {1'sb0}})));
	assign is_zero_o = cnt_q == {16 {1'sb0}};
	function automatic [15:0] sv2v_cast_B952C;
		input reg [15:0] inp;
		sv2v_cast_B952C = inp;
	endfunction
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			lfsr_q <= sv2v_cast_B952C(Seed);
			mask_q <= 1'sb0;
			cnt_q <= 1'sb0;
		end
		else begin
			lfsr_q <= lfsr_d;
			mask_q <= mask_d;
			cnt_q <= cnt_d;
		end
	end
endmodule
module fall_through_register (
	clk_i,
	rst_ni,
	clr_i,
	testmode_i,
	valid_i,
	ready_o,
	data_i,
	valid_o,
	ready_i,
	data_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire clr_i;
	input wire testmode_i;
	input wire valid_i;
	output wire ready_o;
	input wire data_i;
	output wire valid_o;
	input wire ready_i;
	output wire data_o;
	wire fifo_empty;
	wire fifo_full;
	fifo_v2_EE579 #(
		.FALL_THROUGH(1'b1),
		.DATA_WIDTH(1'sbx),
		.DEPTH(1)
	) i_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(clr_i),
		.testmode_i(testmode_i),
		.full_o(fifo_full),
		.empty_o(fifo_empty),
		.alm_full_o(),
		.alm_empty_o(),
		.data_i(data_i),
		.push_i(valid_i & ~fifo_full),
		.data_o(data_o),
		.pop_i(ready_i & ~fifo_empty)
	);
	assign ready_o = ~fifo_full;
	assign valid_o = ~fifo_empty;
endmodule
module fifo_v3_7B453_D1E92 (
	clk_i,
	rst_ni,
	flush_i,
	testmode_i,
	full_o,
	empty_o,
	usage_o,
	data_i,
	push_i,
	data_o,
	pop_i
);
	parameter [31:0] dtype_dtype_DATA_WIDTH = 0;
	reg _sv2v_0;
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire testmode_i;
	output wire full_o;
	output wire empty_o;
	output wire [ADDR_DEPTH - 1:0] usage_o;
	input wire [dtype_dtype_DATA_WIDTH - 1:0] data_i;
	input wire push_i;
	output reg [dtype_dtype_DATA_WIDTH - 1:0] data_o;
	input wire pop_i;
	localparam [31:0] FifoDepth = (DEPTH > 0 ? DEPTH : 1);
	reg gate_clock;
	reg [ADDR_DEPTH - 1:0] read_pointer_n;
	reg [ADDR_DEPTH - 1:0] read_pointer_q;
	reg [ADDR_DEPTH - 1:0] write_pointer_n;
	reg [ADDR_DEPTH - 1:0] write_pointer_q;
	reg [ADDR_DEPTH:0] status_cnt_n;
	reg [ADDR_DEPTH:0] status_cnt_q;
	reg [(FifoDepth * dtype_dtype_DATA_WIDTH) - 1:0] mem_n;
	reg [(FifoDepth * dtype_dtype_DATA_WIDTH) - 1:0] mem_q;
	assign usage_o = status_cnt_q[ADDR_DEPTH - 1:0];
	generate
		if (DEPTH == 0) begin : gen_pass_through
			assign empty_o = ~push_i;
			assign full_o = ~pop_i;
		end
		else begin : gen_fifo
			assign full_o = status_cnt_q == FifoDepth[ADDR_DEPTH:0];
			assign empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i);
		end
	endgenerate
	always @(*) begin : read_write_comb
		if (_sv2v_0)
			;
		read_pointer_n = read_pointer_q;
		write_pointer_n = write_pointer_q;
		status_cnt_n = status_cnt_q;
		data_o = (DEPTH == 0 ? data_i : mem_q[read_pointer_q * dtype_dtype_DATA_WIDTH+:dtype_dtype_DATA_WIDTH]);
		mem_n = mem_q;
		gate_clock = 1'b1;
		if (push_i && ~full_o) begin
			mem_n[write_pointer_q * dtype_dtype_DATA_WIDTH+:dtype_dtype_DATA_WIDTH] = data_i;
			gate_clock = 1'b0;
			if (write_pointer_q == (FifoDepth[ADDR_DEPTH - 1:0] - 1))
				write_pointer_n = 1'sb0;
			else
				write_pointer_n = write_pointer_q + 1;
			status_cnt_n = status_cnt_q + 1;
		end
		if (pop_i && ~empty_o) begin
			if (read_pointer_n == (FifoDepth[ADDR_DEPTH - 1:0] - 1))
				read_pointer_n = 1'sb0;
			else
				read_pointer_n = read_pointer_q + 1;
			status_cnt_n = status_cnt_q - 1;
		end
		if (((push_i && pop_i) && ~full_o) && ~empty_o)
			status_cnt_n = status_cnt_q;
		if ((FALL_THROUGH && (status_cnt_q == 0)) && push_i) begin
			data_o = data_i;
			if (pop_i) begin
				status_cnt_n = status_cnt_q;
				read_pointer_n = read_pointer_q;
				write_pointer_n = write_pointer_q;
			end
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			read_pointer_q <= 1'sb0;
			write_pointer_q <= 1'sb0;
			status_cnt_q <= 1'sb0;
		end
		else if (flush_i) begin
			read_pointer_q <= 1'sb0;
			write_pointer_q <= 1'sb0;
			status_cnt_q <= 1'sb0;
		end
		else begin
			read_pointer_q <= read_pointer_n;
			write_pointer_q <= write_pointer_n;
			status_cnt_q <= status_cnt_n;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			mem_q <= 1'sb0;
		else if (!gate_clock)
			mem_q <= mem_n;
	initial _sv2v_0 = 0;
endmodule
module fifo_v3_FB6ED (
	clk_i,
	rst_ni,
	flush_i,
	testmode_i,
	full_o,
	empty_o,
	usage_o,
	data_i,
	push_i,
	data_o,
	pop_i
);
	reg _sv2v_0;
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire testmode_i;
	output wire full_o;
	output wire empty_o;
	output wire [ADDR_DEPTH - 1:0] usage_o;
	input wire data_i;
	input wire push_i;
	output reg data_o;
	input wire pop_i;
	localparam [31:0] FifoDepth = (DEPTH > 0 ? DEPTH : 1);
	reg gate_clock;
	reg [ADDR_DEPTH - 1:0] read_pointer_n;
	reg [ADDR_DEPTH - 1:0] read_pointer_q;
	reg [ADDR_DEPTH - 1:0] write_pointer_n;
	reg [ADDR_DEPTH - 1:0] write_pointer_q;
	reg [ADDR_DEPTH:0] status_cnt_n;
	reg [ADDR_DEPTH:0] status_cnt_q;
	reg [FifoDepth - 1:0] mem_n;
	reg [FifoDepth - 1:0] mem_q;
	assign usage_o = status_cnt_q[ADDR_DEPTH - 1:0];
	generate
		if (DEPTH == 0) begin : gen_pass_through
			assign empty_o = ~push_i;
			assign full_o = ~pop_i;
		end
		else begin : gen_fifo
			assign full_o = status_cnt_q == FifoDepth[ADDR_DEPTH:0];
			assign empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i);
		end
	endgenerate
	always @(*) begin : read_write_comb
		if (_sv2v_0)
			;
		read_pointer_n = read_pointer_q;
		write_pointer_n = write_pointer_q;
		status_cnt_n = status_cnt_q;
		data_o = (DEPTH == 0 ? data_i : mem_q[read_pointer_q]);
		mem_n = mem_q;
		gate_clock = 1'b1;
		if (push_i && ~full_o) begin
			mem_n[write_pointer_q] = data_i;
			gate_clock = 1'b0;
			if (write_pointer_q == (FifoDepth[ADDR_DEPTH - 1:0] - 1))
				write_pointer_n = 1'sb0;
			else
				write_pointer_n = write_pointer_q + 1;
			status_cnt_n = status_cnt_q + 1;
		end
		if (pop_i && ~empty_o) begin
			if (read_pointer_n == (FifoDepth[ADDR_DEPTH - 1:0] - 1))
				read_pointer_n = 1'sb0;
			else
				read_pointer_n = read_pointer_q + 1;
			status_cnt_n = status_cnt_q - 1;
		end
		if (((push_i && pop_i) && ~full_o) && ~empty_o)
			status_cnt_n = status_cnt_q;
		if ((FALL_THROUGH && (status_cnt_q == 0)) && push_i) begin
			data_o = data_i;
			if (pop_i) begin
				status_cnt_n = status_cnt_q;
				read_pointer_n = read_pointer_q;
				write_pointer_n = write_pointer_q;
			end
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			read_pointer_q <= 1'sb0;
			write_pointer_q <= 1'sb0;
			status_cnt_q <= 1'sb0;
		end
		else if (flush_i) begin
			read_pointer_q <= 1'sb0;
			write_pointer_q <= 1'sb0;
			status_cnt_q <= 1'sb0;
		end
		else begin
			read_pointer_q <= read_pointer_n;
			write_pointer_q <= write_pointer_n;
			status_cnt_q <= status_cnt_n;
		end
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			mem_q <= 1'sb0;
		else if (!gate_clock)
			mem_q <= mem_n;
	initial _sv2v_0 = 0;
endmodule
module gray_to_binary (
	A,
	Z
);
	parameter signed [31:0] N = -1;
	input wire [N - 1:0] A;
	output wire [N - 1:0] Z;
	genvar _gv_i_14;
	generate
		for (_gv_i_14 = 0; _gv_i_14 < N; _gv_i_14 = _gv_i_14 + 1) begin : genblk1
			localparam i = _gv_i_14;
			assign Z[i] = ^A[N - 1:i];
		end
	endgenerate
endmodule
module id_queue (
	clk_i,
	rst_ni,
	inp_id_i,
	inp_data_i,
	inp_req_i,
	inp_gnt_o,
	exists_data_i,
	exists_mask_i,
	exists_req_i,
	exists_o,
	exists_gnt_o,
	oup_id_i,
	oup_pop_i,
	oup_req_i,
	oup_data_o,
	oup_data_valid_o,
	oup_gnt_o
);
	reg _sv2v_0;
	parameter signed [31:0] ID_WIDTH = 0;
	parameter signed [31:0] CAPACITY = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire [ID_WIDTH - 1:0] inp_id_i;
	input wire inp_data_i;
	input wire inp_req_i;
	output wire inp_gnt_o;
	input wire exists_data_i;
	input wire [0:0] exists_mask_i;
	input wire exists_req_i;
	output reg exists_o;
	output reg exists_gnt_o;
	input wire [ID_WIDTH - 1:0] oup_id_i;
	input wire oup_pop_i;
	input wire oup_req_i;
	output reg oup_data_o;
	output reg oup_data_valid_o;
	output reg oup_gnt_o;
	localparam signed [31:0] NIds = 2 ** ID_WIDTH;
	localparam signed [31:0] HtCapacity = (NIds <= CAPACITY ? NIds : CAPACITY);
	function automatic [31:0] cf_math_pkg_idx_width;
		input reg [31:0] num_idx;
		cf_math_pkg_idx_width = (num_idx > 32'd1 ? $unsigned($clog2(num_idx)) : 32'd1);
	endfunction
	localparam [31:0] HtIdxWidth = cf_math_pkg_idx_width(HtCapacity);
	localparam [31:0] LdIdxWidth = cf_math_pkg_idx_width(CAPACITY);
	reg [((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (HtCapacity * (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1)) - 1 : (HtCapacity * (1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) - 1)):((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)] head_tail_d;
	reg [((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (HtCapacity * (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1)) - 1 : (HtCapacity * (1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) - 1)):((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)] head_tail_q;
	reg [(((1 + LdIdxWidth) + 0) >= 0 ? (CAPACITY * ((1 + LdIdxWidth) + 1)) - 1 : (CAPACITY * (1 - ((1 + LdIdxWidth) + 0))) + ((1 + LdIdxWidth) - 1)):(((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0)] linked_data_d;
	reg [(((1 + LdIdxWidth) + 0) >= 0 ? (CAPACITY * ((1 + LdIdxWidth) + 1)) - 1 : (CAPACITY * (1 - ((1 + LdIdxWidth) + 0))) + ((1 + LdIdxWidth) - 1)):(((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0)] linked_data_q;
	wire full;
	reg match_id_valid;
	wire no_id_match;
	wire [HtCapacity - 1:0] head_tail_free;
	wire [HtCapacity - 1:0] idx_matches_id;
	wire [CAPACITY - 1:0] exists_match;
	wire [CAPACITY - 1:0] linked_data_free;
	reg [ID_WIDTH - 1:0] match_id;
	wire [HtIdxWidth - 1:0] head_tail_free_idx;
	wire [HtIdxWidth - 1:0] match_idx;
	wire [LdIdxWidth - 1:0] linked_data_free_idx;
	genvar _gv_i_15;
	generate
		for (_gv_i_15 = 0; _gv_i_15 < HtCapacity; _gv_i_15 = _gv_i_15 + 1) begin : gen_idx_match
			localparam i = _gv_i_15;
			assign idx_matches_id[i] = (match_id_valid && (head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (i * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0)) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0)))) : (((i * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0)) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0))))) + ((ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0))) >= (LdIdxWidth + (LdIdxWidth + 1)) ? ((ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0))) - (LdIdxWidth + (LdIdxWidth + 1))) + 1 : ((LdIdxWidth + (LdIdxWidth + 1)) - (ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0)))) + 1)) - 1)-:((ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0))) >= (LdIdxWidth + (LdIdxWidth + 1)) ? ((ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0))) - (LdIdxWidth + (LdIdxWidth + 1))) + 1 : ((LdIdxWidth + (LdIdxWidth + 1)) - (ID_WIDTH + (LdIdxWidth + (LdIdxWidth + 0)))) + 1)] == match_id)) && !head_tail_q[(i * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)];
		end
	endgenerate
	assign no_id_match = !(|idx_matches_id);
	onehot_to_bin #(.ONEHOT_WIDTH(HtCapacity)) i_id_ohb(
		.onehot(idx_matches_id),
		.bin(match_idx)
	);
	genvar _gv_i_16;
	generate
		for (_gv_i_16 = 0; _gv_i_16 < HtCapacity; _gv_i_16 = _gv_i_16 + 1) begin : gen_head_tail_free
			localparam i = _gv_i_16;
			assign head_tail_free[i] = head_tail_q[(i * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)];
		end
	endgenerate
	lzc #(
		.WIDTH(HtCapacity),
		.MODE(0)
	) i_ht_free_lzc(
		.in_i(head_tail_free),
		.cnt_o(head_tail_free_idx),
		.empty_o()
	);
	genvar _gv_i_17;
	generate
		for (_gv_i_17 = 0; _gv_i_17 < CAPACITY; _gv_i_17 = _gv_i_17 + 1) begin : gen_linked_data_free
			localparam i = _gv_i_17;
			assign linked_data_free[i] = linked_data_q[(i * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0)];
		end
	endgenerate
	lzc #(
		.WIDTH(CAPACITY),
		.MODE(0)
	) i_ld_free_lzc(
		.in_i(linked_data_free),
		.cnt_o(linked_data_free_idx),
		.empty_o()
	);
	assign full = !(|linked_data_free);
	assign inp_gnt_o = ~full;
	function automatic [ID_WIDTH - 1:0] sv2v_cast_41322;
		input reg [ID_WIDTH - 1:0] inp;
		sv2v_cast_41322 = inp;
	endfunction
	function automatic [LdIdxWidth - 1:0] sv2v_cast_6A851;
		input reg [LdIdxWidth - 1:0] inp;
		sv2v_cast_6A851 = inp;
	endfunction
	function automatic [ID_WIDTH - 1:0] sv2v_cast_623BB;
		input reg [ID_WIDTH - 1:0] inp;
		sv2v_cast_623BB = inp;
	endfunction
	function automatic [LdIdxWidth - 1:0] sv2v_cast_4B52A;
		input reg [LdIdxWidth - 1:0] inp;
		sv2v_cast_4B52A = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		match_id = 1'sb0;
		match_id_valid = 1'b0;
		head_tail_d = head_tail_q;
		linked_data_d = linked_data_q;
		oup_gnt_o = 1'b0;
		oup_data_o = 1'b0;
		oup_data_valid_o = 1'b0;
		if (inp_req_i && !full) begin
			match_id = inp_id_i;
			match_id_valid = 1'b1;
			if (no_id_match)
				head_tail_d[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) + (head_tail_free_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)))+:((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))] = {sv2v_cast_41322(inp_id_i), sv2v_cast_6A851(linked_data_free_idx), sv2v_cast_6A851(linked_data_free_idx), 1'b0};
			else begin
				linked_data_d[(((1 + LdIdxWidth) + 0) >= 0 ? (head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0)) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0))) + ((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))) - 1)-:((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))] * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : ((1 + LdIdxWidth) + 0) - (LdIdxWidth + 0)) : (((head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0)) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0))) + ((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))) - 1)-:((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))] * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : ((1 + LdIdxWidth) + 0) - (LdIdxWidth + 0))) + ((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))) - 1)-:((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))] = linked_data_free_idx;
				head_tail_d[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0)) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0))) + ((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))) - 1)-:((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))] = linked_data_free_idx;
			end
			linked_data_d[(((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0) + (linked_data_free_idx * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0)))+:(((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))] = {inp_data_i, sv2v_cast_6A851(1'sb0), 1'b0};
		end
		else if (oup_req_i) begin
			match_id = oup_id_i;
			match_id_valid = 1'b1;
			if (!no_id_match) begin
				oup_data_o = linked_data_q[(head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0))) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0)))) + ((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)) - 1)-:((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)] * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? 1 + (LdIdxWidth + 0) : ((1 + LdIdxWidth) + 0) - (1 + (LdIdxWidth + 0)))];
				oup_data_valid_o = 1'b1;
				if (oup_pop_i) begin
					linked_data_d[(((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0) + (head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0))) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0)))) + ((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)) - 1)-:((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)] * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0)))+:(((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))] = 1'sb0;
					linked_data_d[(head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0))) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0)))) + ((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)) - 1)-:((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)] * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0)] = 1'b1;
					if (head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0))) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0)))) + ((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)) - 1)-:((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)] == head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0)) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + 0))) + ((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))) - 1)-:((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))])
						head_tail_d[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) + (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)))+:((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))] = {sv2v_cast_623BB(1'sb0), sv2v_cast_4B52A(1'sb0), sv2v_cast_4B52A(1'sb0), 1'b1};
					else
						head_tail_d[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0))) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0)))) + ((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)) - 1)-:((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)] = linked_data_q[(((1 + LdIdxWidth) + 0) >= 0 ? (head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0))) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0)))) + ((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)) - 1)-:((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)] * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : ((1 + LdIdxWidth) + 0) - (LdIdxWidth + 0)) : (((head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? (match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0))) : (((match_idx * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))) + ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + (LdIdxWidth + 0) : (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) - (LdIdxWidth + (LdIdxWidth + 0)))) + ((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)) - 1)-:((LdIdxWidth + (LdIdxWidth + 0)) >= (LdIdxWidth + 1) ? ((LdIdxWidth + (LdIdxWidth + 0)) - (LdIdxWidth + 1)) + 1 : ((LdIdxWidth + 1) - (LdIdxWidth + (LdIdxWidth + 0))) + 1)] * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? LdIdxWidth + 0 : ((1 + LdIdxWidth) + 0) - (LdIdxWidth + 0))) + ((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))) - 1)-:((LdIdxWidth + 0) >= 1 ? LdIdxWidth + 0 : 2 - (LdIdxWidth + 0))];
				end
			end
			oup_gnt_o = 1'b1;
		end
	end
	genvar _gv_i_18;
	generate
		for (_gv_i_18 = 0; _gv_i_18 < CAPACITY; _gv_i_18 = _gv_i_18 + 1) begin : gen_lookup
			localparam i = _gv_i_18;
			reg [0:0] exists_match_bits;
			genvar _gv_j_5;
			for (_gv_j_5 = 0; _gv_j_5 < 1; _gv_j_5 = _gv_j_5 + 1) begin : gen_mask
				localparam j = _gv_j_5;
				always @(*) begin
					if (_sv2v_0)
						;
					if (linked_data_q[(i * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0)])
						exists_match_bits[j] = 1'b0;
					else if (!exists_mask_i[j])
						exists_match_bits[j] = 1'b1;
					else
						exists_match_bits[j] = linked_data_q[(i * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? 1 + (LdIdxWidth + 0) : ((1 + LdIdxWidth) + 0) - (1 + (LdIdxWidth + 0)))] == exists_data_i[j];
				end
			end
			assign exists_match[i] = &exists_match_bits;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		exists_gnt_o = 1'b0;
		exists_o = 1'sb0;
		if (exists_req_i) begin
			exists_gnt_o = 1'b1;
			exists_o = |exists_match;
		end
	end
	genvar _gv_i_19;
	generate
		for (_gv_i_19 = 0; _gv_i_19 < HtCapacity; _gv_i_19 = _gv_i_19 + 1) begin : gen_ht_ffs
			localparam i = _gv_i_19;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) + (i * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)))+:((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))] <= {sv2v_cast_623BB(1'sb0), sv2v_cast_4B52A(1'sb0), sv2v_cast_4B52A(1'sb0), 1'b1};
				else
					head_tail_q[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) + (i * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)))+:((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))] <= head_tail_d[((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? 0 : ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) + (i * ((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0)))+:((((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0) >= 0 ? ((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 1 : 1 - (((ID_WIDTH + LdIdxWidth) + LdIdxWidth) + 0))];
		end
	endgenerate
	genvar _gv_i_20;
	generate
		for (_gv_i_20 = 0; _gv_i_20 < CAPACITY; _gv_i_20 = _gv_i_20 + 1) begin : gen_data_ffs
			localparam i = _gv_i_20;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					linked_data_q[(((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0) + (i * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0)))+:(((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))] <= 1'sb0;
					linked_data_q[(i * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))) + (((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0)] <= 1'b1;
				end
				else
					linked_data_q[(((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0) + (i * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0)))+:(((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))] <= linked_data_d[(((1 + LdIdxWidth) + 0) >= 0 ? 0 : (1 + LdIdxWidth) + 0) + (i * (((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0)))+:(((1 + LdIdxWidth) + 0) >= 0 ? (1 + LdIdxWidth) + 1 : 1 - ((1 + LdIdxWidth) + 0))];
		end
	endgenerate
	initial begin : validate_params
		
	end
	initial _sv2v_0 = 0;
endmodule
module isochronous_spill_register (
	src_clk_i,
	src_rst_ni,
	src_valid_i,
	src_ready_o,
	src_data_i,
	dst_clk_i,
	dst_rst_ni,
	dst_valid_o,
	dst_ready_i,
	dst_data_o
);
	reg _sv2v_0;
	parameter [0:0] Bypass = 1'b0;
	input wire src_clk_i;
	input wire src_rst_ni;
	input wire src_valid_i;
	output wire src_ready_o;
	input wire src_data_i;
	input wire dst_clk_i;
	input wire dst_rst_ni;
	output wire dst_valid_o;
	input wire dst_ready_i;
	output wire dst_data_o;
	generate
		if (Bypass) begin : gen_bypass
			assign dst_valid_o = src_valid_i;
			assign src_ready_o = dst_ready_i;
			assign dst_data_o = src_data_i;
		end
		else begin : gen_isochronous_spill_register
			reg [1:0] rd_pointer_q;
			reg [1:0] wr_pointer_q;
			always @(posedge src_clk_i or negedge src_rst_ni)
				if (!src_rst_ni)
					wr_pointer_q <= 1'sb0;
				else
					wr_pointer_q <= (src_valid_i && src_ready_o ? wr_pointer_q + 1 : wr_pointer_q);
			always @(posedge dst_clk_i or negedge dst_rst_ni)
				if (!dst_rst_ni)
					rd_pointer_q <= 1'sb0;
				else
					rd_pointer_q <= (dst_valid_o && dst_ready_i ? rd_pointer_q + 1 : rd_pointer_q);
			reg [1:0] mem_d;
			reg [1:0] mem_q;
			always @(posedge src_clk_i) mem_q <= (src_valid_i && src_ready_o ? mem_d : mem_q);
			always @(*) begin
				if (_sv2v_0)
					;
				mem_d = mem_q;
				mem_d[wr_pointer_q[0]] = src_data_i;
			end
			assign src_ready_o = (rd_pointer_q ^ wr_pointer_q) != 2'b10;
			assign dst_valid_o = (rd_pointer_q ^ wr_pointer_q) != {2 {1'sb0}};
			assign dst_data_o = mem_q[rd_pointer_q[0]];
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module lfsr (
	clk_i,
	rst_ni,
	en_i,
	out_o
);
	reg _sv2v_0;
	parameter [31:0] LfsrWidth = 64;
	parameter [31:0] OutWidth = 8;
	parameter [LfsrWidth - 1:0] RstVal = 1'sb1;
	parameter [31:0] CipherLayers = 0;
	parameter [0:0] CipherReg = 1'b1;
	input wire clk_i;
	input wire rst_ni;
	input wire en_i;
	output wire [OutWidth - 1:0] out_o;
	localparam [4159:256] Masks = 3904'hc000000000000001e0000000000000039000000000000007e00000000000000fa00000000000001fd00000000000003fc000000000000064b0000000000000d8f0000000000001296000000000000249600000000000043570000000000008679000000000001030e00000000000206cd00000000000403fe00000000000807b800000000001004b200000000002006a800000000004004b20000000000800b8700000000010004f3000000000200072d00000000040006ae00000000080009e300000000100005830000000020000c9200000000400005b60000000080000ea600000001000007a30000000200000abf0000000400000842000000080000123e000000100000074e0000002000000ae9000000400000086a0000008000001213000001000000077e000002000000123b0000040000000877000008000000108d0000100000000ae90000200000000e9f00004000000008a6000080000000191e000100000000090e0002000000000fb30004000000000d7d00080000000016a50010000000000b4b00200000000010af0040000000000dde008000000000181a0100000000000b65020000000000102d0400000000000cd508000000000024c11000000000000ef620000000000013634000000000000fcd80000000000019e2;
	localparam [63:0] Sbox4 = 64'h21748fe3da09b65c;
	localparam [383:0] Perm = 384'hfef7cffae78ef6d74df2c70ceeb6cbeaa68ae69649e28608de75c7da6586d65545d24504ce34c3ca2482c61441c20400;
	function automatic [63:0] sbox4_layer;
		input reg [63:0] in;
		reg [63:0] out;
		begin
			out[0+:4] = Sbox4[in[0+:4] * 4+:4];
			out[4+:4] = Sbox4[in[4+:4] * 4+:4];
			out[8+:4] = Sbox4[in[8+:4] * 4+:4];
			out[12+:4] = Sbox4[in[12+:4] * 4+:4];
			out[16+:4] = Sbox4[in[16+:4] * 4+:4];
			out[20+:4] = Sbox4[in[20+:4] * 4+:4];
			out[24+:4] = Sbox4[in[24+:4] * 4+:4];
			out[28+:4] = Sbox4[in[28+:4] * 4+:4];
			out[32+:4] = Sbox4[in[32+:4] * 4+:4];
			out[36+:4] = Sbox4[in[36+:4] * 4+:4];
			out[40+:4] = Sbox4[in[40+:4] * 4+:4];
			out[44+:4] = Sbox4[in[44+:4] * 4+:4];
			out[48+:4] = Sbox4[in[48+:4] * 4+:4];
			out[52+:4] = Sbox4[in[52+:4] * 4+:4];
			out[56+:4] = Sbox4[in[56+:4] * 4+:4];
			out[60+:4] = Sbox4[in[60+:4] * 4+:4];
			sbox4_layer = out;
		end
	endfunction
	function automatic [63:0] perm_layer;
		input reg [63:0] in;
		reg [63:0] out;
		begin
			out[Perm[0+:6]] = in[0];
			out[Perm[6+:6]] = in[1];
			out[Perm[12+:6]] = in[2];
			out[Perm[18+:6]] = in[3];
			out[Perm[24+:6]] = in[4];
			out[Perm[30+:6]] = in[5];
			out[Perm[36+:6]] = in[6];
			out[Perm[42+:6]] = in[7];
			out[Perm[48+:6]] = in[8];
			out[Perm[54+:6]] = in[9];
			out[Perm[60+:6]] = in[10];
			out[Perm[66+:6]] = in[11];
			out[Perm[72+:6]] = in[12];
			out[Perm[78+:6]] = in[13];
			out[Perm[84+:6]] = in[14];
			out[Perm[90+:6]] = in[15];
			out[Perm[96+:6]] = in[16];
			out[Perm[102+:6]] = in[17];
			out[Perm[108+:6]] = in[18];
			out[Perm[114+:6]] = in[19];
			out[Perm[120+:6]] = in[20];
			out[Perm[126+:6]] = in[21];
			out[Perm[132+:6]] = in[22];
			out[Perm[138+:6]] = in[23];
			out[Perm[144+:6]] = in[24];
			out[Perm[150+:6]] = in[25];
			out[Perm[156+:6]] = in[26];
			out[Perm[162+:6]] = in[27];
			out[Perm[168+:6]] = in[28];
			out[Perm[174+:6]] = in[29];
			out[Perm[180+:6]] = in[30];
			out[Perm[186+:6]] = in[31];
			out[Perm[192+:6]] = in[32];
			out[Perm[198+:6]] = in[33];
			out[Perm[204+:6]] = in[34];
			out[Perm[210+:6]] = in[35];
			out[Perm[216+:6]] = in[36];
			out[Perm[222+:6]] = in[37];
			out[Perm[228+:6]] = in[38];
			out[Perm[234+:6]] = in[39];
			out[Perm[240+:6]] = in[40];
			out[Perm[246+:6]] = in[41];
			out[Perm[252+:6]] = in[42];
			out[Perm[258+:6]] = in[43];
			out[Perm[264+:6]] = in[44];
			out[Perm[270+:6]] = in[45];
			out[Perm[276+:6]] = in[46];
			out[Perm[282+:6]] = in[47];
			out[Perm[288+:6]] = in[48];
			out[Perm[294+:6]] = in[49];
			out[Perm[300+:6]] = in[50];
			out[Perm[306+:6]] = in[51];
			out[Perm[312+:6]] = in[52];
			out[Perm[318+:6]] = in[53];
			out[Perm[324+:6]] = in[54];
			out[Perm[330+:6]] = in[55];
			out[Perm[336+:6]] = in[56];
			out[Perm[342+:6]] = in[57];
			out[Perm[348+:6]] = in[58];
			out[Perm[354+:6]] = in[59];
			out[Perm[360+:6]] = in[60];
			out[Perm[366+:6]] = in[61];
			out[Perm[372+:6]] = in[62];
			out[Perm[378+:6]] = in[63];
			perm_layer = out;
		end
	endfunction
	wire [LfsrWidth - 1:0] lfsr_d;
	reg [LfsrWidth - 1:0] lfsr_q;
	assign lfsr_d = (en_i ? (lfsr_q >> 1) ^ ({LfsrWidth {lfsr_q[0]}} & Masks[((68 - LfsrWidth) * 64) + (LfsrWidth - 1)-:LfsrWidth]) : lfsr_q);
	function automatic [LfsrWidth - 1:0] sv2v_cast_E2FB5;
		input reg [LfsrWidth - 1:0] inp;
		sv2v_cast_E2FB5 = inp;
	endfunction
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni)
			lfsr_q <= sv2v_cast_E2FB5(RstVal);
		else
			lfsr_q <= lfsr_d;
	end
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
	generate
		if (CipherLayers > $unsigned(0)) begin : g_cipher_layers
			reg [63:0] ciph_layer;
			localparam [31:0] NumRepl = (64 + LfsrWidth) / LfsrWidth;
			always @(*) begin : p_ciph_layer
				reg [63:0] tmp;
				if (_sv2v_0)
					;
				tmp = sv2v_cast_64({NumRepl {lfsr_q}});
				begin : sv2v_autoblock_1
					reg [31:0] k;
					for (k = 0; k < CipherLayers; k = k + 1)
						tmp = perm_layer(sbox4_layer(tmp));
				end
				ciph_layer = tmp;
			end
			if (CipherReg) begin : g_cipher_reg
				wire [OutWidth - 1:0] out_d;
				reg [OutWidth - 1:0] out_q;
				assign out_d = (en_i ? ciph_layer[OutWidth - 1:0] : out_q);
				assign out_o = out_q[OutWidth - 1:0];
				always @(posedge clk_i or negedge rst_ni) begin : p_regs
					if (!rst_ni)
						out_q <= 1'sb0;
					else
						out_q <= out_d;
				end
			end
			else begin : g_no_out_reg
				assign out_o = ciph_layer[OutWidth - 1:0];
			end
		end
		else begin : g_no_cipher_layers
			assign out_o = lfsr_q[OutWidth - 1:0];
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module lfsr_16bit (
	clk_i,
	rst_ni,
	en_i,
	refill_way_oh,
	refill_way_bin
);
	reg _sv2v_0;
	parameter [15:0] SEED = 8'b00000000;
	parameter [31:0] WIDTH = 16;
	input wire clk_i;
	input wire rst_ni;
	input wire en_i;
	output reg [WIDTH - 1:0] refill_way_oh;
	output reg [$clog2(WIDTH) - 1:0] refill_way_bin;
	localparam [31:0] LogWidth = $clog2(WIDTH);
	reg [15:0] shift_d;
	reg [15:0] shift_q;
	always @(*) begin : sv2v_autoblock_1
		reg shift_in;
		if (_sv2v_0)
			;
		shift_in = !(((shift_q[15] ^ shift_q[12]) ^ shift_q[5]) ^ shift_q[1]);
		shift_d = shift_q;
		if (en_i)
			shift_d = {shift_q[14:0], shift_in};
		refill_way_oh = 'b0;
		refill_way_oh[shift_q[LogWidth - 1:0]] = 1'b1;
		refill_way_bin = shift_q;
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_
		if (~rst_ni)
			shift_q <= SEED;
		else
			shift_q <= shift_d;
	end
	initial _sv2v_0 = 0;
endmodule
module lfsr_8bit (
	clk_i,
	rst_ni,
	en_i,
	refill_way_oh,
	refill_way_bin
);
	reg _sv2v_0;
	parameter [7:0] SEED = 8'b00000000;
	parameter [31:0] WIDTH = 8;
	input wire clk_i;
	input wire rst_ni;
	input wire en_i;
	output reg [WIDTH - 1:0] refill_way_oh;
	output reg [$clog2(WIDTH) - 1:0] refill_way_bin;
	localparam [31:0] LogWidth = $clog2(WIDTH);
	reg [7:0] shift_d;
	reg [7:0] shift_q;
	always @(*) begin : sv2v_autoblock_1
		reg shift_in;
		if (_sv2v_0)
			;
		shift_in = !(((shift_q[7] ^ shift_q[3]) ^ shift_q[2]) ^ shift_q[1]);
		shift_d = shift_q;
		if (en_i)
			shift_d = {shift_q[6:0], shift_in};
		refill_way_oh = 'b0;
		refill_way_oh[shift_q[LogWidth - 1:0]] = 1'b1;
		refill_way_bin = shift_q;
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_
		if (~rst_ni)
			shift_q <= SEED;
		else
			shift_q <= shift_d;
	end
	initial _sv2v_0 = 0;
endmodule
module lzc (
	in_i,
	cnt_o,
	empty_o
);
	reg _sv2v_0;
	parameter [31:0] WIDTH = 2;
	parameter [0:0] MODE = 1'b0;
	function automatic [31:0] cf_math_pkg_idx_width;
		input reg [31:0] num_idx;
		cf_math_pkg_idx_width = (num_idx > 32'd1 ? $unsigned($clog2(num_idx)) : 32'd1);
	endfunction
	parameter [31:0] CNT_WIDTH = cf_math_pkg_idx_width(WIDTH);
	input wire [WIDTH - 1:0] in_i;
	output wire [CNT_WIDTH - 1:0] cnt_o;
	output wire empty_o;
	generate
		if (WIDTH == 1) begin : gen_degenerate_lzc
			assign cnt_o[0] = !in_i[0];
			assign empty_o = !in_i[0];
		end
		else begin : gen_lzc
			localparam [31:0] NumLevels = $clog2(WIDTH);
			wire [(WIDTH * NumLevels) - 1:0] index_lut;
			wire [(2 ** NumLevels) - 1:0] sel_nodes;
			wire [((2 ** NumLevels) * NumLevels) - 1:0] index_nodes;
			reg [WIDTH - 1:0] in_tmp;
			always @(*) begin : flip_vector
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_1
					reg [31:0] i;
					for (i = 0; i < WIDTH; i = i + 1)
						in_tmp[i] = (MODE ? in_i[(WIDTH - 1) - i] : in_i[i]);
				end
			end
			genvar _gv_j_6;
			for (_gv_j_6 = 0; $unsigned(_gv_j_6) < WIDTH; _gv_j_6 = _gv_j_6 + 1) begin : g_index_lut
				localparam j = _gv_j_6;
				function automatic [NumLevels - 1:0] sv2v_cast_CD1FF;
					input reg [NumLevels - 1:0] inp;
					sv2v_cast_CD1FF = inp;
				endfunction
				assign index_lut[j * NumLevels+:NumLevels] = sv2v_cast_CD1FF($unsigned(j));
			end
			genvar _gv_level_3;
			for (_gv_level_3 = 0; $unsigned(_gv_level_3) < NumLevels; _gv_level_3 = _gv_level_3 + 1) begin : g_levels
				localparam level = _gv_level_3;
				if ($unsigned(level) == (NumLevels - 1)) begin : g_last_level
					genvar _gv_k_5;
					for (_gv_k_5 = 0; _gv_k_5 < (2 ** level); _gv_k_5 = _gv_k_5 + 1) begin : g_level
						localparam k = _gv_k_5;
						if (($unsigned(k) * 2) < (WIDTH - 1)) begin : g_reduce
							assign sel_nodes[((2 ** level) - 1) + k] = in_tmp[k * 2] | in_tmp[(k * 2) + 1];
							assign index_nodes[(((2 ** level) - 1) + k) * NumLevels+:NumLevels] = (in_tmp[k * 2] == 1'b1 ? index_lut[(k * 2) * NumLevels+:NumLevels] : index_lut[((k * 2) + 1) * NumLevels+:NumLevels]);
						end
						if (($unsigned(k) * 2) == (WIDTH - 1)) begin : g_base
							assign sel_nodes[((2 ** level) - 1) + k] = in_tmp[k * 2];
							assign index_nodes[(((2 ** level) - 1) + k) * NumLevels+:NumLevels] = index_lut[(k * 2) * NumLevels+:NumLevels];
						end
						if (($unsigned(k) * 2) > (WIDTH - 1)) begin : g_out_of_range
							assign sel_nodes[((2 ** level) - 1) + k] = 1'b0;
							assign index_nodes[(((2 ** level) - 1) + k) * NumLevels+:NumLevels] = 1'sb0;
						end
					end
				end
				else begin : g_not_last_level
					genvar _gv_l_5;
					for (_gv_l_5 = 0; _gv_l_5 < (2 ** level); _gv_l_5 = _gv_l_5 + 1) begin : g_level
						localparam l = _gv_l_5;
						assign sel_nodes[((2 ** level) - 1) + l] = sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] | sel_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) + 1];
						assign index_nodes[(((2 ** level) - 1) + l) * NumLevels+:NumLevels] = (sel_nodes[((2 ** (level + 1)) - 1) + (l * 2)] == 1'b1 ? index_nodes[(((2 ** (level + 1)) - 1) + (l * 2)) * NumLevels+:NumLevels] : index_nodes[((((2 ** (level + 1)) - 1) + (l * 2)) + 1) * NumLevels+:NumLevels]);
					end
				end
			end
			assign cnt_o = (NumLevels > $unsigned(0) ? index_nodes[0+:NumLevels] : {$clog2(WIDTH) {1'b0}});
			assign empty_o = (NumLevels > $unsigned(0) ? ~sel_nodes[0] : ~(|in_i));
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module max_counter (
	clk_i,
	rst_ni,
	clear_i,
	clear_max_i,
	en_i,
	load_i,
	down_i,
	delta_i,
	d_i,
	q_o,
	max_o,
	overflow_o,
	overflow_max_o
);
	reg _sv2v_0;
	parameter [31:0] WIDTH = 4;
	input wire clk_i;
	input wire rst_ni;
	input wire clear_i;
	input wire clear_max_i;
	input wire en_i;
	input wire load_i;
	input wire down_i;
	input wire [WIDTH - 1:0] delta_i;
	input wire [WIDTH - 1:0] d_i;
	output wire [WIDTH - 1:0] q_o;
	output reg [WIDTH - 1:0] max_o;
	output wire overflow_o;
	output wire overflow_max_o;
	reg [WIDTH - 1:0] max_d;
	reg [WIDTH - 1:0] max_q;
	reg overflow_max_d;
	reg overflow_max_q;
	delta_counter #(
		.WIDTH(WIDTH),
		.STICKY_OVERFLOW(1'b1)
	) i_counter(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clear_i(clear_i),
		.en_i(en_i),
		.load_i(load_i),
		.down_i(down_i),
		.delta_i(delta_i),
		.d_i(d_i),
		.q_o(q_o),
		.overflow_o(overflow_o)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		max_d = max_q;
		max_o = max_q;
		overflow_max_d = overflow_max_q;
		if (clear_max_i) begin
			max_d = 1'sb0;
			overflow_max_d = 1'b0;
		end
		else if (q_o > max_q) begin
			max_d = q_o;
			max_o = q_o;
			if (overflow_o)
				overflow_max_d = 1'b1;
		end
	end
	assign overflow_max_o = overflow_max_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			max_q <= 1'sb0;
			overflow_max_q <= 1'b0;
		end
		else begin
			max_q <= max_d;
			overflow_max_q <= overflow_max_d;
		end
	initial _sv2v_0 = 0;
endmodule
module mv_filter (
	clk_i,
	rst_ni,
	sample_i,
	clear_i,
	d_i,
	q_o
);
	reg _sv2v_0;
	parameter [31:0] WIDTH = 4;
	parameter [31:0] THRESHOLD = 10;
	input wire clk_i;
	input wire rst_ni;
	input wire sample_i;
	input wire clear_i;
	input wire d_i;
	output wire q_o;
	reg [WIDTH - 1:0] counter_q;
	reg [WIDTH - 1:0] counter_d;
	reg d;
	reg q;
	assign q_o = q;
	always @(*) begin
		if (_sv2v_0)
			;
		counter_d = counter_q;
		d = q;
		if (counter_q >= THRESHOLD[WIDTH - 1:0])
			d = 1'b1;
		else if (sample_i && d_i)
			counter_d = counter_q + 1;
		if (clear_i) begin
			counter_d = 1'sb0;
			d = 1'b0;
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			counter_q <= 1'sb0;
			q <= 1'b0;
		end
		else begin
			counter_q <= counter_d;
			q <= d;
		end
	initial _sv2v_0 = 0;
endmodule
module onehot_to_bin (
	onehot,
	bin
);
	parameter [31:0] ONEHOT_WIDTH = 16;
	parameter [31:0] BIN_WIDTH = (ONEHOT_WIDTH == 1 ? 1 : $clog2(ONEHOT_WIDTH));
	input wire [ONEHOT_WIDTH - 1:0] onehot;
	output wire [BIN_WIDTH - 1:0] bin;
	genvar _gv_j_7;
	generate
		for (_gv_j_7 = 0; _gv_j_7 < BIN_WIDTH; _gv_j_7 = _gv_j_7 + 1) begin : jl
			localparam j = _gv_j_7;
			wire [ONEHOT_WIDTH - 1:0] tmp_mask;
			genvar _gv_i_21;
			for (_gv_i_21 = 0; _gv_i_21 < ONEHOT_WIDTH; _gv_i_21 = _gv_i_21 + 1) begin : il
				localparam i = _gv_i_21;
				wire [BIN_WIDTH - 1:0] tmp_i;
				assign tmp_i = i;
				assign tmp_mask[i] = tmp_i[j];
			end
			assign bin[j] = |(tmp_mask & onehot);
		end
	endgenerate
endmodule
module plru_tree (
	clk_i,
	rst_ni,
	used_i,
	plru_o
);
	reg _sv2v_0;
	parameter [31:0] ENTRIES = 16;
	input wire clk_i;
	input wire rst_ni;
	input wire [ENTRIES - 1:0] used_i;
	output reg [ENTRIES - 1:0] plru_o;
	localparam [31:0] LogEntries = $clog2(ENTRIES);
	reg [(2 * (ENTRIES - 1)) - 1:0] plru_tree_q;
	reg [(2 * (ENTRIES - 1)) - 1:0] plru_tree_d;
	always @(*) begin : plru_replacement
		if (_sv2v_0)
			;
		plru_tree_d = plru_tree_q;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < ENTRIES; i = i + 1)
				begin : sv2v_autoblock_2
					reg [31:0] idx_base;
					reg [31:0] shift;
					reg [31:0] new_index;
					if (used_i[i]) begin : sv2v_autoblock_3
						reg [31:0] lvl;
						for (lvl = 0; lvl < LogEntries; lvl = lvl + 1)
							begin
								idx_base = $unsigned((2 ** lvl) - 1);
								shift = LogEntries - lvl;
								new_index = ~((i >> (shift - 1)) & 1);
								plru_tree_d[idx_base + (i >> shift)] = new_index[0];
							end
					end
				end
		end
		begin : sv2v_autoblock_4
			reg [31:0] i;
			for (i = 0; i < ENTRIES; i = i + 1)
				begin : sv2v_autoblock_5
					reg en;
					reg [31:0] idx_base;
					reg [31:0] shift;
					reg [31:0] new_index;
					en = 1'b1;
					begin : sv2v_autoblock_6
						reg [31:0] lvl;
						for (lvl = 0; lvl < LogEntries; lvl = lvl + 1)
							begin
								idx_base = $unsigned((2 ** lvl) - 1);
								shift = LogEntries - lvl;
								new_index = (i >> (shift - 1)) & 1;
								if (new_index[0])
									en = en & plru_tree_q[idx_base + (i >> shift)];
								else
									en = en & ~plru_tree_q[idx_base + (i >> shift)];
							end
					end
					plru_o[i] = en;
				end
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			plru_tree_q <= 1'sb0;
		else
			plru_tree_q <= plru_tree_d;
	initial _sv2v_0 = 0;
endmodule
module popcount (
	data_i,
	popcount_o
);
	reg _sv2v_0;
	parameter [31:0] INPUT_WIDTH = 256;
	localparam [31:0] PopcountWidth = $clog2(INPUT_WIDTH) + 1;
	input wire [INPUT_WIDTH - 1:0] data_i;
	output wire [PopcountWidth - 1:0] popcount_o;
	localparam [31:0] PaddedWidth = 1 << $clog2(INPUT_WIDTH);
	reg [PaddedWidth - 1:0] padded_input;
	wire [PopcountWidth - 2:0] left_child_result;
	wire [PopcountWidth - 2:0] right_child_result;
	always @(*) begin
		if (_sv2v_0)
			;
		padded_input = 1'sb0;
		padded_input[INPUT_WIDTH - 1:0] = data_i;
	end
	generate
		if (INPUT_WIDTH == 1) begin : single_node
			assign left_child_result = 1'b0;
			assign right_child_result = padded_input[0];
		end
		else if (INPUT_WIDTH == 2) begin : leaf_node
			assign left_child_result = padded_input[1];
			assign right_child_result = padded_input[0];
		end
		else begin : non_leaf_node
			popcount #(.INPUT_WIDTH(PaddedWidth / 2)) left_child(
				.data_i(padded_input[PaddedWidth - 1:PaddedWidth / 2]),
				.popcount_o(left_child_result)
			);
			popcount #(.INPUT_WIDTH(PaddedWidth / 2)) right_child(
				.data_i(padded_input[(PaddedWidth / 2) - 1:0]),
				.popcount_o(right_child_result)
			);
		end
	endgenerate
	assign popcount_o = left_child_result + right_child_result;
	initial _sv2v_0 = 0;
endmodule
module rr_arb_tree (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [(NumIn * DataWidth) - 1:0] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire [DataWidth - 1:0] data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	function automatic [DataWidth - 1:0] sv2v_cast_9719B;
		input reg [DataWidth - 1:0] inp;
		sv2v_cast_9719B = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[0+:DataWidth];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * DataWidth) - 1 : ((3 - (2 ** NumLevels)) * DataWidth) + ((((2 ** NumLevels) - 2) * DataWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * DataWidth)] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * DataWidth+:DataWidth];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_B41BF;
				assign sv2v_tmp_B41BF = rr_i;
				always @(*) rr_q = sv2v_tmp_B41BF;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					wire [NumIn - 1:0] req_tmp;
					assign req_tmp = req_q & req_i;
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar _gv_i_22;
					for (_gv_i_22 = 0; _gv_i_22 < NumIn; _gv_i_22 = _gv_i_22 + 1) begin : gen_mask
						localparam i = _gv_i_22;
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_BCC4E(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar _gv_level_4;
			for (_gv_level_4 = 0; $unsigned(_gv_level_4) < NumLevels; _gv_level_4 = _gv_level_4 + 1) begin : gen_levels
				localparam level = _gv_level_4;
				genvar _gv_l_6;
				for (_gv_l_6 = 0; _gv_l_6 < (2 ** level); _gv_l_6 = _gv_l_6 + 1) begin : gen_level
					localparam l = _gv_l_6;
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(sel);
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataWidth+:DataWidth] = (sel ? data_i[((l * 2) + 1) * DataWidth+:DataWidth] : data_i[(l * 2) * DataWidth+:DataWidth]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataWidth+:DataWidth] = data_i[(l * 2) * DataWidth+:DataWidth];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(1'sb0);
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataWidth+:DataWidth] = sv2v_cast_9719B(1'sb0);
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_BCC4E({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_BCC4E({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataWidth+:DataWidth] = (sel ? data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * DataWidth+:DataWidth] : data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * DataWidth+:DataWidth]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
			initial begin : p_assert
				
			end
		end
	endgenerate
endmodule
module rr_arb_tree_209FB (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [NumIn - 1:0] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[0];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(2 ** NumLevels) - 2:0] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[0];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_B41BF;
				assign sv2v_tmp_B41BF = rr_i;
				always @(*) rr_q = sv2v_tmp_B41BF;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					wire [NumIn - 1:0] req_tmp;
					assign req_tmp = req_q & req_i;
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar _gv_i_22;
					for (_gv_i_22 = 0; _gv_i_22 < NumIn; _gv_i_22 = _gv_i_22 + 1) begin : gen_mask
						localparam i = _gv_i_22;
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_BCC4E(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar _gv_level_4;
			for (_gv_level_4 = 0; $unsigned(_gv_level_4) < NumLevels; _gv_level_4 = _gv_level_4 + 1) begin : gen_levels
				localparam level = _gv_level_4;
				genvar _gv_l_6;
				for (_gv_l_6 = 0; _gv_l_6 < (2 ** level); _gv_l_6 = _gv_l_6 + 1) begin : gen_level
					localparam l = _gv_l_6;
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(sel);
							assign data_nodes[Idx0] = (sel ? data_i[(l * 2) + 1] : data_i[l * 2]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[Idx0] = data_i[l * 2];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(1'sb0);
							assign data_nodes[Idx0] = 1'b0;
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_BCC4E({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_BCC4E({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[Idx0] = (sel ? data_nodes[Idx1 + 1] : data_nodes[Idx1]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
			initial begin : p_assert
				
			end
		end
	endgenerate
endmodule
module rr_arb_tree_4B249_E9E1F (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] DataType_payload_t_DataWidth = 0;
	parameter [31:0] DataType_payload_t_IdxWidth = 0;
	parameter integer DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D = 0;
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [(NumIn * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)) - 1:0] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire [((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth) - 1:0] data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	function automatic [((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth) - 1:0] sv2v_cast_C570D;
		input reg [((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth) - 1:0] inp;
		sv2v_cast_C570D = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[0+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)) - 1 : ((3 - (2 ** NumLevels)) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)) + ((((2 ** NumLevels) - 2) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth))] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_B41BF;
				assign sv2v_tmp_B41BF = rr_i;
				always @(*) rr_q = sv2v_tmp_B41BF;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					wire [NumIn - 1:0] req_tmp;
					assign req_tmp = req_q & req_i;
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar _gv_i_22;
					for (_gv_i_22 = 0; _gv_i_22 < NumIn; _gv_i_22 = _gv_i_22 + 1) begin : gen_mask
						localparam i = _gv_i_22;
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_BCC4E(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar _gv_level_4;
			for (_gv_level_4 = 0; $unsigned(_gv_level_4) < NumLevels; _gv_level_4 = _gv_level_4 + 1) begin : gen_levels
				localparam level = _gv_level_4;
				genvar _gv_l_6;
				for (_gv_l_6 = 0; _gv_l_6 < (2 ** level); _gv_l_6 = _gv_l_6 + 1) begin : gen_level
					localparam l = _gv_l_6;
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(sel);
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth] = (sel ? data_i[((l * 2) + 1) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth] : data_i[(l * 2) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth] = data_i[(l * 2) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(1'sb0);
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth] = sv2v_cast_C570D(1'sb0);
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_BCC4E({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_BCC4E({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth] = (sel ? data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth] : data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * ((DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth)+:(DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D + DataType_payload_t_DataWidth) + DataType_payload_t_IdxWidth]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
			initial begin : p_assert
				
			end
		end
	endgenerate
endmodule
module rr_arb_tree_DDE89_9935E (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] DataType_payload_t_DataWidth = 0;
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [(NumIn * DataType_payload_t_DataWidth) - 1:0] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire [DataType_payload_t_DataWidth - 1:0] data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	function automatic [DataType_payload_t_DataWidth - 1:0] sv2v_cast_842CB;
		input reg [DataType_payload_t_DataWidth - 1:0] inp;
		sv2v_cast_842CB = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[0+:DataType_payload_t_DataWidth];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * DataType_payload_t_DataWidth) - 1 : ((3 - (2 ** NumLevels)) * DataType_payload_t_DataWidth) + ((((2 ** NumLevels) - 2) * DataType_payload_t_DataWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * DataType_payload_t_DataWidth)] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_B41BF;
				assign sv2v_tmp_B41BF = rr_i;
				always @(*) rr_q = sv2v_tmp_B41BF;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					wire [NumIn - 1:0] req_tmp;
					assign req_tmp = req_q & req_i;
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar _gv_i_22;
					for (_gv_i_22 = 0; _gv_i_22 < NumIn; _gv_i_22 = _gv_i_22 + 1) begin : gen_mask
						localparam i = _gv_i_22;
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_BCC4E(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar _gv_level_4;
			for (_gv_level_4 = 0; $unsigned(_gv_level_4) < NumLevels; _gv_level_4 = _gv_level_4 + 1) begin : gen_levels
				localparam level = _gv_level_4;
				genvar _gv_l_6;
				for (_gv_l_6 = 0; _gv_l_6 < (2 ** level); _gv_l_6 = _gv_l_6 + 1) begin : gen_level
					localparam l = _gv_l_6;
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(sel);
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth] = (sel ? data_i[((l * 2) + 1) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth] : data_i[(l * 2) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth] = data_i[(l * 2) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(1'sb0);
							assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth] = sv2v_cast_842CB(1'sb0);
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_BCC4E({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_BCC4E({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth] = (sel ? data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth] : data_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * DataType_payload_t_DataWidth+:DataType_payload_t_DataWidth]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
			initial begin : p_assert
				
			end
		end
	endgenerate
endmodule
module rr_arb_tree_FF0CA_81131 (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] DataType_Width = 0;
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [((DataType_Width + 6) >= 0 ? (NumIn * (DataType_Width + 7)) - 1 : (NumIn * (1 - (DataType_Width + 6))) + (DataType_Width + 5)):((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6)] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire [DataType_Width + 6:0] data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	function automatic [((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)) - 1:0] sv2v_cast_72D16;
		input reg [((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)) - 1:0] inp;
		sv2v_cast_72D16 = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + 0+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(((2 ** NumLevels) - 2) >= 0 ? ((DataType_Width + 6) >= 0 ? (((2 ** NumLevels) - 1) * (DataType_Width + 7)) - 1 : (((2 ** NumLevels) - 1) * (1 - (DataType_Width + 6))) + (DataType_Width + 5)) : ((DataType_Width + 6) >= 0 ? ((3 - (2 ** NumLevels)) * (DataType_Width + 7)) + ((((2 ** NumLevels) - 2) * (DataType_Width + 7)) - 1) : ((3 - (2 ** NumLevels)) * (1 - (DataType_Width + 6))) + (((DataType_Width + 6) + (((2 ** NumLevels) - 2) * (1 - (DataType_Width + 6)))) - 1))):(((2 ** NumLevels) - 2) >= 0 ? ((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) : ((DataType_Width + 6) >= 0 ? ((2 ** NumLevels) - 2) * (DataType_Width + 7) : (DataType_Width + 6) + (((2 ** NumLevels) - 2) * (1 - (DataType_Width + 6)))))] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_B41BF;
				assign sv2v_tmp_B41BF = rr_i;
				always @(*) rr_q = sv2v_tmp_B41BF;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					wire [NumIn - 1:0] req_tmp;
					assign req_tmp = req_q & req_i;
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar _gv_i_22;
					for (_gv_i_22 = 0; _gv_i_22 < NumIn; _gv_i_22 = _gv_i_22 + 1) begin : gen_mask
						localparam i = _gv_i_22;
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_BCC4E(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar _gv_level_4;
			for (_gv_level_4 = 0; $unsigned(_gv_level_4) < NumLevels; _gv_level_4 = _gv_level_4 + 1) begin : gen_levels
				localparam level = _gv_level_4;
				genvar _gv_l_6;
				for (_gv_l_6 = 0; _gv_l_6 < (2 ** level); _gv_l_6 = _gv_l_6 + 1) begin : gen_level
					localparam l = _gv_l_6;
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(sel);
							assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = (sel ? data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + (((l * 2) + 1) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] : data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((l * 2) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = data_i[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((l * 2) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(1'sb0);
							assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = sv2v_cast_72D16(1'sb0);
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_BCC4E({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_BCC4E({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] = (sel ? data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))] : data_nodes[((DataType_Width + 6) >= 0 ? 0 : DataType_Width + 6) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * ((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6)))+:((DataType_Width + 6) >= 0 ? DataType_Width + 7 : 1 - (DataType_Width + 6))]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
			initial begin : p_assert
				
			end
		end
	endgenerate
endmodule
module rr_arb_tree_D71DB_88D54 (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	req_i,
	gnt_o,
	data_i,
	req_o,
	gnt_i,
	data_o,
	idx_o
);
	parameter [31:0] DataType_WIDTH = 0;
	parameter [31:0] NumIn = 64;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] ExtPrio = 1'b0;
	parameter [0:0] AxiVldRdy = 1'b0;
	parameter [0:0] LockIn = 1'b0;
	parameter [0:0] FairArb = 1'b1;
	parameter [31:0] IdxWidth = (NumIn > 32'd1 ? $unsigned($clog2(NumIn)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [IdxWidth - 1:0] rr_i;
	input wire [NumIn - 1:0] req_i;
	output wire [NumIn - 1:0] gnt_o;
	input wire [((DataType_WIDTH + 5) >= 0 ? (NumIn * (DataType_WIDTH + 6)) - 1 : (NumIn * (1 - (DataType_WIDTH + 5))) + (DataType_WIDTH + 4)):((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5)] data_i;
	output wire req_o;
	input wire gnt_i;
	output wire [DataType_WIDTH + 5:0] data_o;
	output wire [IdxWidth - 1:0] idx_o;
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	function automatic [((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)) - 1:0] sv2v_cast_90A84;
		input reg [((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)) - 1:0] inp;
		sv2v_cast_90A84 = inp;
	endfunction
	generate
		if (NumIn == $unsigned(1)) begin : gen_pass_through
			assign req_o = req_i[0];
			assign gnt_o[0] = gnt_i;
			assign data_o = data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + 0+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))];
			assign idx_o = 1'sb0;
		end
		else begin : gen_arbiter
			localparam [31:0] NumLevels = $unsigned($clog2(NumIn));
			wire [(((2 ** NumLevels) - 2) >= 0 ? (((2 ** NumLevels) - 1) * IdxWidth) - 1 : ((3 - (2 ** NumLevels)) * IdxWidth) + ((((2 ** NumLevels) - 2) * IdxWidth) - 1)):(((2 ** NumLevels) - 2) >= 0 ? 0 : ((2 ** NumLevels) - 2) * IdxWidth)] index_nodes;
			wire [(((2 ** NumLevels) - 2) >= 0 ? ((DataType_WIDTH + 5) >= 0 ? (((2 ** NumLevels) - 1) * (DataType_WIDTH + 6)) - 1 : (((2 ** NumLevels) - 1) * (1 - (DataType_WIDTH + 5))) + (DataType_WIDTH + 4)) : ((DataType_WIDTH + 5) >= 0 ? ((3 - (2 ** NumLevels)) * (DataType_WIDTH + 6)) + ((((2 ** NumLevels) - 2) * (DataType_WIDTH + 6)) - 1) : ((3 - (2 ** NumLevels)) * (1 - (DataType_WIDTH + 5))) + (((DataType_WIDTH + 5) + (((2 ** NumLevels) - 2) * (1 - (DataType_WIDTH + 5)))) - 1))):(((2 ** NumLevels) - 2) >= 0 ? ((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) : ((DataType_WIDTH + 5) >= 0 ? ((2 ** NumLevels) - 2) * (DataType_WIDTH + 6) : (DataType_WIDTH + 5) + (((2 ** NumLevels) - 2) * (1 - (DataType_WIDTH + 5)))))] data_nodes;
			wire [(2 ** NumLevels) - 2:0] gnt_nodes;
			wire [(2 ** NumLevels) - 2:0] req_nodes;
			reg [IdxWidth - 1:0] rr_q;
			wire [NumIn - 1:0] req_d;
			assign req_o = req_nodes[0];
			assign data_o = data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))];
			assign idx_o = index_nodes[(((2 ** NumLevels) - 2) >= 0 ? 0 : (2 ** NumLevels) - 2) * IdxWidth+:IdxWidth];
			if (ExtPrio) begin : gen_ext_rr
				wire [IdxWidth:1] sv2v_tmp_B41BF;
				assign sv2v_tmp_B41BF = rr_i;
				always @(*) rr_q = sv2v_tmp_B41BF;
				assign req_d = req_i;
			end
			else begin : gen_int_rr
				wire [IdxWidth - 1:0] rr_d;
				if (LockIn) begin : gen_lock
					wire lock_d;
					reg lock_q;
					reg [NumIn - 1:0] req_q;
					assign lock_d = req_o & ~gnt_i;
					assign req_d = (lock_q ? req_q : req_i);
					always @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
						if (!rst_ni)
							lock_q <= 1'sb0;
						else if (flush_i)
							lock_q <= 1'sb0;
						else
							lock_q <= lock_d;
					end
					wire [NumIn - 1:0] req_tmp;
					assign req_tmp = req_q & req_i;
					always @(posedge clk_i or negedge rst_ni) begin : p_req_regs
						if (!rst_ni)
							req_q <= 1'sb0;
						else if (flush_i)
							req_q <= 1'sb0;
						else
							req_q <= req_d;
					end
				end
				else begin : gen_no_lock
					assign req_d = req_i;
				end
				if (FairArb) begin : gen_fair_arb
					wire [NumIn - 1:0] upper_mask;
					wire [NumIn - 1:0] lower_mask;
					wire [IdxWidth - 1:0] upper_idx;
					wire [IdxWidth - 1:0] lower_idx;
					wire [IdxWidth - 1:0] next_idx;
					wire upper_empty;
					wire lower_empty;
					genvar _gv_i_22;
					for (_gv_i_22 = 0; _gv_i_22 < NumIn; _gv_i_22 = _gv_i_22 + 1) begin : gen_mask
						localparam i = _gv_i_22;
						assign upper_mask[i] = (i > rr_q ? req_d[i] : 1'b0);
						assign lower_mask[i] = (i <= rr_q ? req_d[i] : 1'b0);
					end
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_upper(
						.in_i(upper_mask),
						.cnt_o(upper_idx),
						.empty_o(upper_empty)
					);
					lzc #(
						.WIDTH(NumIn),
						.MODE(1'b0)
					) i_lzc_lower(
						.in_i(lower_mask),
						.cnt_o(lower_idx),
						.empty_o()
					);
					assign next_idx = (upper_empty ? lower_idx : upper_idx);
					assign rr_d = (gnt_i && req_o ? next_idx : rr_q);
				end
				else begin : gen_unfair_arb
					assign rr_d = (gnt_i && req_o ? (rr_q == sv2v_cast_BCC4E(NumIn - 1) ? {IdxWidth {1'sb0}} : rr_q + 1'b1) : rr_q);
				end
				always @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
					if (!rst_ni)
						rr_q <= 1'sb0;
					else if (flush_i)
						rr_q <= 1'sb0;
					else
						rr_q <= rr_d;
				end
			end
			assign gnt_nodes[0] = gnt_i;
			genvar _gv_level_4;
			for (_gv_level_4 = 0; $unsigned(_gv_level_4) < NumLevels; _gv_level_4 = _gv_level_4 + 1) begin : gen_levels
				localparam level = _gv_level_4;
				genvar _gv_l_6;
				for (_gv_l_6 = 0; _gv_l_6 < (2 ** level); _gv_l_6 = _gv_l_6 + 1) begin : gen_level
					localparam l = _gv_l_6;
					wire sel;
					localparam [31:0] Idx0 = ((2 ** level) - 1) + l;
					localparam [31:0] Idx1 = ((2 ** (level + 1)) - 1) + (l * 2);
					if ($unsigned(level) == (NumLevels - 1)) begin : gen_first_level
						if (($unsigned(l) * 2) < (NumIn - 1)) begin : gen_reduce
							assign req_nodes[Idx0] = req_d[l * 2] | req_d[(l * 2) + 1];
							assign sel = ~req_d[l * 2] | (req_d[(l * 2) + 1] & rr_q[(NumLevels - 1) - level]);
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(sel);
							assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = (sel ? data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + (((l * 2) + 1) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] : data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((l * 2) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))]);
							assign gnt_o[l * 2] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2])) & ~sel;
							assign gnt_o[(l * 2) + 1] = (gnt_nodes[Idx0] & (AxiVldRdy | req_d[(l * 2) + 1])) & sel;
						end
						if (($unsigned(l) * 2) == (NumIn - 1)) begin : gen_first
							assign req_nodes[Idx0] = req_d[l * 2];
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = 1'sb0;
							assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = data_i[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((l * 2) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))];
							assign gnt_o[l * 2] = gnt_nodes[Idx0] & (AxiVldRdy | req_d[l * 2]);
						end
						if (($unsigned(l) * 2) > (NumIn - 1)) begin : gen_out_of_range
							assign req_nodes[Idx0] = 1'b0;
							assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = sv2v_cast_BCC4E(1'sb0);
							assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = sv2v_cast_90A84(1'sb0);
						end
					end
					else begin : gen_other_levels
						assign req_nodes[Idx0] = req_nodes[Idx1] | req_nodes[Idx1 + 1];
						assign sel = ~req_nodes[Idx1] | (req_nodes[Idx1 + 1] & rr_q[(NumLevels - 1) - level]);
						assign index_nodes[(((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * IdxWidth+:IdxWidth] = (sel ? sv2v_cast_BCC4E({1'b1, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}) : sv2v_cast_BCC4E({1'b0, index_nodes[((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * IdxWidth) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 2 : (((NumLevels - $unsigned(level)) - 2) + (((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))) - 1)-:(((NumLevels - $unsigned(level)) - 2) >= 0 ? (NumLevels - $unsigned(level)) - 1 : 3 - (NumLevels - $unsigned(level)))]}));
						assign data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx0 : ((2 ** NumLevels) - 2) - Idx0) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] = (sel ? data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 + 1 : ((2 ** NumLevels) - 2) - (Idx1 + 1)) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))] : data_nodes[((DataType_WIDTH + 5) >= 0 ? 0 : DataType_WIDTH + 5) + ((((2 ** NumLevels) - 2) >= 0 ? Idx1 : ((2 ** NumLevels) - 2) - Idx1) * ((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5)))+:((DataType_WIDTH + 5) >= 0 ? DataType_WIDTH + 6 : 1 - (DataType_WIDTH + 5))]);
						assign gnt_nodes[Idx1] = gnt_nodes[Idx0] & ~sel;
						assign gnt_nodes[Idx1 + 1] = gnt_nodes[Idx0] & sel;
					end
				end
			end
			initial begin : p_assert
				
			end
		end
	endgenerate
endmodule
module rstgen (
	clk_i,
	rst_ni,
	test_mode_i,
	rst_no,
	init_no
);
	input wire clk_i;
	input wire rst_ni;
	input wire test_mode_i;
	output wire rst_no;
	output wire init_no;
	rstgen_bypass i_rstgen_bypass(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.rst_test_mode_ni(rst_ni),
		.test_mode_i(test_mode_i),
		.rst_no(rst_no),
		.init_no(init_no)
	);
endmodule
module rstgen_bypass (
	clk_i,
	rst_ni,
	rst_test_mode_ni,
	test_mode_i,
	rst_no,
	init_no
);
	reg _sv2v_0;
	parameter [31:0] NumRegs = 4;
	input wire clk_i;
	input wire rst_ni;
	input wire rst_test_mode_ni;
	input wire test_mode_i;
	output reg rst_no;
	output reg init_no;
	reg rst_n;
	reg [NumRegs - 1:0] synch_regs_q;
	always @(*) begin
		if (_sv2v_0)
			;
		if (test_mode_i == 1'b0) begin
			rst_n = rst_ni;
			rst_no = synch_regs_q[NumRegs - 1];
			init_no = synch_regs_q[NumRegs - 1];
		end
		else begin
			rst_n = rst_test_mode_ni;
			rst_no = rst_test_mode_ni;
			init_no = 1'b1;
		end
	end
	always @(posedge clk_i or negedge rst_n)
		if (~rst_n)
			synch_regs_q <= 0;
		else
			synch_regs_q <= {synch_regs_q[NumRegs - 2:0], 1'b1};
	initial begin : p_assertions
		if (NumRegs < 1) begin
			$display("Fatal [%0t] ./vendor/pulp_platform_common_cells/src/rstgen_bypass.sv:53:26 - rstgen_bypass.p_assertions.<unnamed_block>\n msg: ", $time, "At least one register is required.");
			$finish(1);
		end
	end
	initial _sv2v_0 = 0;
endmodule
module serial_deglitch (
	clk_i,
	rst_ni,
	en_i,
	d_i,
	q_o
);
	reg _sv2v_0;
	parameter [31:0] SIZE = 4;
	input wire clk_i;
	input wire rst_ni;
	input wire en_i;
	input wire d_i;
	output reg q_o;
	reg [SIZE - 1:0] count_q;
	reg q;
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni) begin
			count_q <= 1'sb0;
			q <= 1'b0;
		end
		else if (en_i) begin
			if ((d_i == 1'b1) && (count_q != SIZE[SIZE - 1:0]))
				count_q <= count_q + 1;
			else if ((d_i == 1'b0) && (count_q != SIZE[SIZE - 1:0]))
				count_q <= count_q - 1;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		if (count_q == SIZE[SIZE - 1:0])
			q_o = 1'b1;
		else if (count_q == 0)
			q_o = 1'b0;
	end
	initial _sv2v_0 = 0;
endmodule
module shift_reg (
	clk_i,
	rst_ni,
	d_i,
	d_o
);
	parameter [31:0] Depth = 1;
	input wire clk_i;
	input wire rst_ni;
	input wire d_i;
	output reg d_o;
	generate
		if (Depth == 0) begin : gen_pass_through
			wire [1:1] sv2v_tmp_E0E3B;
			assign sv2v_tmp_E0E3B = d_i;
			always @(*) d_o = sv2v_tmp_E0E3B;
		end
		else if (Depth == 1) begin : gen_register
			always @(posedge clk_i or negedge rst_ni)
				if (~rst_ni)
					d_o <= 1'sb0;
				else
					d_o <= d_i;
		end
		else if (Depth > 1) begin : gen_shift_reg
			wire [Depth - 1:0] reg_d;
			reg [Depth - 1:0] reg_q;
			wire [1:1] sv2v_tmp_D24C8;
			assign sv2v_tmp_D24C8 = reg_q[Depth - 1];
			always @(*) d_o = sv2v_tmp_D24C8;
			assign reg_d = {reg_q[Depth - 2:0], d_i};
			always @(posedge clk_i or negedge rst_ni)
				if (~rst_ni)
					reg_q <= 1'sb0;
				else
					reg_q <= reg_d;
		end
	endgenerate
endmodule
module spill_register_04039_BB60C (
	clk_i,
	rst_ni,
	valid_i,
	ready_o,
	data_i,
	valid_o,
	ready_i,
	data_o
);
	parameter [31:0] T_T_WIDTH = 0;
	parameter [0:0] Bypass = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	output wire ready_o;
	input wire [T_T_WIDTH - 1:0] data_i;
	output wire valid_o;
	input wire ready_i;
	output wire [T_T_WIDTH - 1:0] data_o;
	generate
		if (Bypass) begin : gen_bypass
			assign valid_o = valid_i;
			assign ready_o = ready_i;
			assign data_o = data_i;
		end
		else begin : gen_spill_reg
			reg [T_T_WIDTH - 1:0] a_data_q;
			reg a_full_q;
			wire a_fill;
			wire a_drain;
			wire a_en;
			wire a_en_data;
			always @(posedge clk_i or negedge rst_ni) begin : ps_a_data
				if (!rst_ni)
					a_data_q <= 1'sb0;
				else if (a_fill)
					a_data_q <= data_i;
			end
			always @(posedge clk_i or negedge rst_ni) begin : ps_a_full
				if (!rst_ni)
					a_full_q <= 0;
				else if (a_fill || a_drain)
					a_full_q <= a_fill;
			end
			reg [T_T_WIDTH - 1:0] b_data_q;
			reg b_full_q;
			wire b_fill;
			wire b_drain;
			always @(posedge clk_i or negedge rst_ni) begin : ps_b_data
				if (!rst_ni)
					b_data_q <= 1'sb0;
				else if (b_fill)
					b_data_q <= a_data_q;
			end
			always @(posedge clk_i or negedge rst_ni) begin : ps_b_full
				if (!rst_ni)
					b_full_q <= 0;
				else if (b_fill || b_drain)
					b_full_q <= b_fill;
			end
			assign a_fill = valid_i && ready_o;
			assign a_drain = a_full_q && !b_full_q;
			assign b_fill = a_drain && !ready_i;
			assign b_drain = b_full_q && ready_i;
			assign ready_o = !a_full_q || !b_full_q;
			assign valid_o = a_full_q | b_full_q;
			assign data_o = (b_full_q ? b_data_q : a_data_q);
		end
	endgenerate
endmodule
module spill_register_5603B_A7272 (
	clk_i,
	rst_ni,
	valid_i,
	ready_o,
	data_i,
	valid_o,
	ready_i,
	data_o
);
	parameter [31:0] T_IdxWidth = 0;
	parameter [31:0] T_payload_t_DataWidth = 0;
	parameter [31:0] T_payload_t_IdxWidth = 0;
	parameter integer T_payload_t_i_stream_xbar_sv2v_pfunc_7505D = 0;
	parameter [0:0] Bypass = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	output wire ready_o;
	input wire [(((T_payload_t_i_stream_xbar_sv2v_pfunc_7505D + T_payload_t_DataWidth) + T_payload_t_IdxWidth) + T_IdxWidth) - 1:0] data_i;
	output wire valid_o;
	input wire ready_i;
	output wire [(((T_payload_t_i_stream_xbar_sv2v_pfunc_7505D + T_payload_t_DataWidth) + T_payload_t_IdxWidth) + T_IdxWidth) - 1:0] data_o;
	generate
		if (Bypass) begin : gen_bypass
			assign valid_o = valid_i;
			assign ready_o = ready_i;
			assign data_o = data_i;
		end
		else begin : gen_spill_reg
			reg [(((T_payload_t_i_stream_xbar_sv2v_pfunc_7505D + T_payload_t_DataWidth) + T_payload_t_IdxWidth) + T_IdxWidth) - 1:0] a_data_q;
			reg a_full_q;
			wire a_fill;
			wire a_drain;
			wire a_en;
			wire a_en_data;
			always @(posedge clk_i or negedge rst_ni) begin : ps_a_data
				if (!rst_ni)
					a_data_q <= 1'sb0;
				else if (a_fill)
					a_data_q <= data_i;
			end
			always @(posedge clk_i or negedge rst_ni) begin : ps_a_full
				if (!rst_ni)
					a_full_q <= 0;
				else if (a_fill || a_drain)
					a_full_q <= a_fill;
			end
			reg [(((T_payload_t_i_stream_xbar_sv2v_pfunc_7505D + T_payload_t_DataWidth) + T_payload_t_IdxWidth) + T_IdxWidth) - 1:0] b_data_q;
			reg b_full_q;
			wire b_fill;
			wire b_drain;
			always @(posedge clk_i or negedge rst_ni) begin : ps_b_data
				if (!rst_ni)
					b_data_q <= 1'sb0;
				else if (b_fill)
					b_data_q <= a_data_q;
			end
			always @(posedge clk_i or negedge rst_ni) begin : ps_b_full
				if (!rst_ni)
					b_full_q <= 0;
				else if (b_fill || b_drain)
					b_full_q <= b_fill;
			end
			assign a_fill = valid_i && ready_o;
			assign a_drain = a_full_q && !b_full_q;
			assign b_fill = a_drain && !ready_i;
			assign b_drain = b_full_q && ready_i;
			assign ready_o = !a_full_q || !b_full_q;
			assign valid_o = a_full_q | b_full_q;
			assign data_o = (b_full_q ? b_data_q : a_data_q);
		end
	endgenerate
endmodule
module spill_register_5AE7A_F0150 (
	clk_i,
	rst_ni,
	valid_i,
	ready_o,
	data_i,
	valid_o,
	ready_i,
	data_o
);
	parameter [31:0] T_IdxWidth = 0;
	parameter [31:0] T_payload_t_DataWidth = 0;
	parameter [0:0] Bypass = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	output wire ready_o;
	input wire [(T_payload_t_DataWidth + T_IdxWidth) - 1:0] data_i;
	output wire valid_o;
	input wire ready_i;
	output wire [(T_payload_t_DataWidth + T_IdxWidth) - 1:0] data_o;
	generate
		if (Bypass) begin : gen_bypass
			assign valid_o = valid_i;
			assign ready_o = ready_i;
			assign data_o = data_i;
		end
		else begin : gen_spill_reg
			reg [(T_payload_t_DataWidth + T_IdxWidth) - 1:0] a_data_q;
			reg a_full_q;
			wire a_fill;
			wire a_drain;
			wire a_en;
			wire a_en_data;
			always @(posedge clk_i or negedge rst_ni) begin : ps_a_data
				if (!rst_ni)
					a_data_q <= 1'sb0;
				else if (a_fill)
					a_data_q <= data_i;
			end
			always @(posedge clk_i or negedge rst_ni) begin : ps_a_full
				if (!rst_ni)
					a_full_q <= 0;
				else if (a_fill || a_drain)
					a_full_q <= a_fill;
			end
			reg [(T_payload_t_DataWidth + T_IdxWidth) - 1:0] b_data_q;
			reg b_full_q;
			wire b_fill;
			wire b_drain;
			always @(posedge clk_i or negedge rst_ni) begin : ps_b_data
				if (!rst_ni)
					b_data_q <= 1'sb0;
				else if (b_fill)
					b_data_q <= a_data_q;
			end
			always @(posedge clk_i or negedge rst_ni) begin : ps_b_full
				if (!rst_ni)
					b_full_q <= 0;
				else if (b_fill || b_drain)
					b_full_q <= b_fill;
			end
			assign a_fill = valid_i && ready_o;
			assign a_drain = a_full_q && !b_full_q;
			assign b_fill = a_drain && !ready_i;
			assign b_drain = b_full_q && ready_i;
			assign ready_o = !a_full_q || !b_full_q;
			assign valid_o = a_full_q | b_full_q;
			assign data_o = (b_full_q ? b_data_q : a_data_q);
		end
	endgenerate
endmodule
module stream_arbiter (
	clk_i,
	rst_ni,
	inp_data_i,
	inp_valid_i,
	inp_ready_o,
	oup_data_o,
	oup_valid_o,
	oup_ready_i
);
	parameter integer N_INP = -1;
	parameter ARBITER = "rr";
	input wire clk_i;
	input wire rst_ni;
	input wire [N_INP - 1:0] inp_data_i;
	input wire [N_INP - 1:0] inp_valid_i;
	output wire [N_INP - 1:0] inp_ready_o;
	output wire oup_data_o;
	output wire oup_valid_o;
	input wire oup_ready_i;
	stream_arbiter_flushable_12299 #(
		.N_INP(N_INP),
		.ARBITER(ARBITER)
	) i_arb(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(1'b0),
		.inp_data_i(inp_data_i),
		.inp_valid_i(inp_valid_i),
		.inp_ready_o(inp_ready_o),
		.oup_data_o(oup_data_o),
		.oup_valid_o(oup_valid_o),
		.oup_ready_i(oup_ready_i)
	);
endmodule
module stream_arbiter_flushable_12299 (
	clk_i,
	rst_ni,
	flush_i,
	inp_data_i,
	inp_valid_i,
	inp_ready_o,
	oup_data_o,
	oup_valid_o,
	oup_ready_i
);
	parameter integer N_INP = -1;
	parameter ARBITER = "rr";
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [N_INP - 1:0] inp_data_i;
	input wire [N_INP - 1:0] inp_valid_i;
	output wire [N_INP - 1:0] inp_ready_o;
	output wire oup_data_o;
	output wire oup_valid_o;
	input wire oup_ready_i;
	generate
		if (ARBITER == "rr") begin : gen_rr_arb
			localparam [31:0] sv2v_uu_i_arbiter_NumIn = N_INP;
			localparam [31:0] sv2v_uu_i_arbiter_IdxWidth = (sv2v_uu_i_arbiter_NumIn > 32'd1 ? $unsigned($clog2(sv2v_uu_i_arbiter_NumIn)) : 32'd1);
			localparam [sv2v_uu_i_arbiter_IdxWidth - 1:0] sv2v_uu_i_arbiter_ext_rr_i_0 = 1'sb0;
			rr_arb_tree_209FB #(
				.NumIn(N_INP),
				.ExtPrio(1'b0),
				.AxiVldRdy(1'b1),
				.LockIn(1'b1)
			) i_arbiter(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.flush_i(flush_i),
				.rr_i(sv2v_uu_i_arbiter_ext_rr_i_0),
				.req_i(inp_valid_i),
				.gnt_o(inp_ready_o),
				.data_i(inp_data_i),
				.gnt_i(oup_ready_i),
				.req_o(oup_valid_o),
				.data_o(oup_data_o),
				.idx_o()
			);
		end
		else if (ARBITER == "prio") begin : gen_prio_arb
			localparam [31:0] sv2v_uu_i_arbiter_NumIn = N_INP;
			localparam [31:0] sv2v_uu_i_arbiter_IdxWidth = (sv2v_uu_i_arbiter_NumIn > 32'd1 ? $unsigned($clog2(sv2v_uu_i_arbiter_NumIn)) : 32'd1);
			localparam [sv2v_uu_i_arbiter_IdxWidth - 1:0] sv2v_uu_i_arbiter_ext_rr_i_0 = 1'sb0;
			rr_arb_tree_209FB #(
				.NumIn(N_INP),
				.ExtPrio(1'b1),
				.AxiVldRdy(1'b1),
				.LockIn(1'b1)
			) i_arbiter(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.flush_i(flush_i),
				.rr_i(sv2v_uu_i_arbiter_ext_rr_i_0),
				.req_i(inp_valid_i),
				.gnt_o(inp_ready_o),
				.data_i(inp_data_i),
				.gnt_i(oup_ready_i),
				.req_o(oup_valid_o),
				.data_o(oup_data_o),
				.idx_o()
			);
		end
		else begin : gen_arb_error
			initial begin
				$display("Fatal [elaboration] ./vendor/pulp_platform_common_cells/src/stream_arbiter_flushable.sv:78:5 - stream_arbiter_flushable.gen_arb_error\n msg: ", "Invalid value for parameter 'ARBITER'!");
				$finish(1);
			end
		end
	endgenerate
endmodule
module stream_delay (
	clk_i,
	rst_ni,
	payload_i,
	ready_o,
	valid_i,
	payload_o,
	ready_i,
	valid_o
);
	reg _sv2v_0;
	parameter [0:0] StallRandom = 0;
	parameter signed [31:0] FixedDelay = 1;
	input wire clk_i;
	input wire rst_ni;
	input wire payload_i;
	output reg ready_o;
	input wire valid_i;
	output wire payload_o;
	input wire ready_i;
	output reg valid_o;
	generate
		if ((FixedDelay == 0) && !StallRandom) begin : gen_pass_through
			wire [1:1] sv2v_tmp_9212C;
			assign sv2v_tmp_9212C = ready_i;
			always @(*) ready_o = sv2v_tmp_9212C;
			wire [1:1] sv2v_tmp_39D37;
			assign sv2v_tmp_39D37 = valid_i;
			always @(*) valid_o = sv2v_tmp_39D37;
			assign payload_o = payload_i;
		end
		else begin : gen_delay
			localparam [31:0] CounterBits = 4;
			reg [1:0] state_d;
			reg [1:0] state_q;
			reg load;
			wire [3:0] count_out;
			reg en;
			wire [3:0] counter_load;
			assign payload_o = payload_i;
			always @(*) begin
				if (_sv2v_0)
					;
				state_d = state_q;
				valid_o = 1'b0;
				ready_o = 1'b0;
				load = 1'b0;
				en = 1'b0;
				(* full_case, parallel_case *)
				case (state_q)
					2'd0:
						if (valid_i) begin
							load = 1'b1;
							state_d = 2'd1;
							if ((FixedDelay == 1) || (StallRandom && (counter_load == 1)))
								state_d = 2'd2;
							if (StallRandom && (counter_load == 0)) begin
								valid_o = 1'b1;
								ready_o = ready_i;
								if (ready_i)
									state_d = 2'd0;
								else
									state_d = 2'd2;
							end
						end
					2'd1: begin
						en = 1'b1;
						if (count_out == 0)
							state_d = 2'd2;
					end
					2'd2: begin
						valid_o = 1'b1;
						ready_o = ready_i;
						if (ready_i)
							state_d = 2'd0;
					end
					default:
						;
				endcase
			end
			if (StallRandom) begin : gen_random_stall
				lfsr_16bit #(.WIDTH(16)) i_lfsr_16bit(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.en_i(load),
					.refill_way_oh(),
					.refill_way_bin(counter_load)
				);
			end
			else begin : gen_fixed_delay
				assign counter_load = FixedDelay;
			end
			counter #(.WIDTH(CounterBits)) i_counter(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.clear_i(1'b0),
				.en_i(en),
				.load_i(load),
				.down_i(1'b1),
				.d_i(counter_load),
				.q_o(count_out),
				.overflow_o()
			);
			always @(posedge clk_i or negedge rst_ni)
				if (~rst_ni)
					state_q <= 2'd0;
				else
					state_q <= state_d;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module stream_demux (
	inp_valid_i,
	inp_ready_o,
	oup_sel_i,
	oup_valid_o,
	oup_ready_i
);
	reg _sv2v_0;
	parameter [31:0] N_OUP = 32'd1;
	parameter [31:0] LOG_N_OUP = (N_OUP > 32'd1 ? $unsigned($clog2(N_OUP)) : 1'b1);
	input wire inp_valid_i;
	output wire inp_ready_o;
	input wire [LOG_N_OUP - 1:0] oup_sel_i;
	output reg [N_OUP - 1:0] oup_valid_o;
	input wire [N_OUP - 1:0] oup_ready_i;
	always @(*) begin
		if (_sv2v_0)
			;
		oup_valid_o = 1'sb0;
		oup_valid_o[oup_sel_i] = inp_valid_i;
	end
	assign inp_ready_o = oup_ready_i[oup_sel_i];
	initial _sv2v_0 = 0;
endmodule
module stream_fifo_18E2D (
	clk_i,
	rst_ni,
	flush_i,
	testmode_i,
	usage_o,
	data_i,
	valid_i,
	ready_o,
	data_o,
	valid_o,
	ready_i
);
	parameter [0:0] FALL_THROUGH = 1'b0;
	parameter [31:0] DATA_WIDTH = 32;
	parameter [31:0] DEPTH = 8;
	parameter [31:0] ADDR_DEPTH = (DEPTH > 1 ? $clog2(DEPTH) : 1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire testmode_i;
	output wire [ADDR_DEPTH - 1:0] usage_o;
	input wire data_i;
	input wire valid_i;
	output wire ready_o;
	output wire data_o;
	output wire valid_o;
	input wire ready_i;
	wire push;
	wire pop;
	wire empty;
	wire full;
	assign push = valid_i & ~full;
	assign pop = ready_i & ~empty;
	assign ready_o = ~full;
	assign valid_o = ~empty;
	fifo_v3_FB6ED #(
		.FALL_THROUGH(FALL_THROUGH),
		.DATA_WIDTH(DATA_WIDTH),
		.DEPTH(DEPTH)
	) fifo_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.testmode_i(testmode_i),
		.full_o(full),
		.empty_o(empty),
		.usage_o(usage_o),
		.data_i(data_i),
		.push_i(push),
		.data_o(data_o),
		.pop_i(pop)
	);
endmodule
module stream_filter (
	valid_i,
	ready_o,
	drop_i,
	valid_o,
	ready_i
);
	input wire valid_i;
	output wire ready_o;
	input wire drop_i;
	output wire valid_o;
	input wire ready_i;
	assign valid_o = (drop_i ? 1'b0 : valid_i);
	assign ready_o = (drop_i ? 1'b1 : ready_i);
endmodule
module stream_fork (
	clk_i,
	rst_ni,
	valid_i,
	ready_o,
	valid_o,
	ready_i
);
	reg _sv2v_0;
	parameter [31:0] N_OUP = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	output reg ready_o;
	output reg [N_OUP - 1:0] valid_o;
	input wire [N_OUP - 1:0] ready_i;
	reg [N_OUP - 1:0] oup_ready;
	wire [N_OUP - 1:0] all_ones;
	reg inp_state_d;
	reg inp_state_q;
	always @(*) begin
		if (_sv2v_0)
			;
		inp_state_d = inp_state_q;
		(* full_case, parallel_case *)
		case (inp_state_q)
			1'd0:
				if (valid_i) begin
					if ((valid_o == all_ones) && (ready_i == all_ones))
						ready_o = 1'b1;
					else begin
						ready_o = 1'b0;
						inp_state_d = 1'd1;
					end
				end
				else
					ready_o = 1'b0;
			1'd1:
				if (valid_i && (oup_ready == all_ones)) begin
					ready_o = 1'b1;
					inp_state_d = 1'd0;
				end
				else
					ready_o = 1'b0;
			default: begin
				inp_state_d = 1'd0;
				ready_o = 1'b0;
			end
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			inp_state_q <= 1'd0;
		else
			inp_state_q <= inp_state_d;
	genvar _gv_i_23;
	generate
		for (_gv_i_23 = 0; _gv_i_23 < N_OUP; _gv_i_23 = _gv_i_23 + 1) begin : gen_oup_state
			localparam i = _gv_i_23;
			reg oup_state_d;
			reg oup_state_q;
			always @(*) begin
				if (_sv2v_0)
					;
				oup_ready[i] = 1'b1;
				valid_o[i] = 1'b0;
				oup_state_d = oup_state_q;
				(* full_case, parallel_case *)
				case (oup_state_q)
					1'd0:
						if (valid_i) begin
							valid_o[i] = 1'b1;
							if (ready_i[i]) begin
								if (!ready_o)
									oup_state_d = 1'd1;
							end
							else
								oup_ready[i] = 1'b0;
						end
					1'd1:
						if (valid_i && ready_o)
							oup_state_d = 1'd0;
					default: oup_state_d = 1'd0;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					oup_state_q <= 1'd0;
				else
					oup_state_q <= oup_state_d;
		end
	endgenerate
	assign all_ones = 1'sb1;
	initial begin : p_assertions
		
	end
	initial _sv2v_0 = 0;
endmodule
module stream_fork_dynamic (
	clk_i,
	rst_ni,
	valid_i,
	ready_o,
	sel_i,
	sel_valid_i,
	sel_ready_o,
	valid_o,
	ready_i
);
	reg _sv2v_0;
	parameter [31:0] N_OUP = 32'd0;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	output reg ready_o;
	input wire [N_OUP - 1:0] sel_i;
	input wire sel_valid_i;
	output reg sel_ready_o;
	output reg [N_OUP - 1:0] valid_o;
	input wire [N_OUP - 1:0] ready_i;
	reg int_inp_valid;
	wire int_inp_ready;
	wire [N_OUP - 1:0] int_oup_valid;
	reg [N_OUP - 1:0] int_oup_ready;
	genvar _gv_i_24;
	generate
		for (_gv_i_24 = 0; _gv_i_24 < N_OUP; _gv_i_24 = _gv_i_24 + 1) begin : gen_oups
			localparam i = _gv_i_24;
			always @(*) begin
				if (_sv2v_0)
					;
				valid_o[i] = 1'b0;
				int_oup_ready[i] = 1'b0;
				if (sel_valid_i) begin
					if (sel_i[i]) begin
						valid_o[i] = int_oup_valid[i];
						int_oup_ready[i] = ready_i[i];
					end
					else
						int_oup_ready[i] = 1'b1;
				end
			end
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		int_inp_valid = 1'b0;
		ready_o = 1'b0;
		sel_ready_o = 1'b0;
		if (sel_valid_i) begin
			int_inp_valid = valid_i;
			ready_o = int_inp_ready;
			sel_ready_o = int_inp_ready;
		end
	end
	stream_fork #(.N_OUP(N_OUP)) i_fork(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.valid_i(int_inp_valid),
		.ready_o(int_inp_ready),
		.valid_o(int_oup_valid),
		.ready_i(int_oup_ready)
	);
	initial begin : p_assertions
		
	end
	initial _sv2v_0 = 0;
endmodule
module stream_join (
	inp_valid_i,
	inp_ready_o,
	oup_valid_o,
	oup_ready_i
);
	parameter [31:0] N_INP = 32'd0;
	input wire [N_INP - 1:0] inp_valid_i;
	output wire [N_INP - 1:0] inp_ready_o;
	output wire oup_valid_o;
	input wire oup_ready_i;
	assign oup_valid_o = &inp_valid_i;
	genvar _gv_i_25;
	generate
		for (_gv_i_25 = 0; _gv_i_25 < N_INP; _gv_i_25 = _gv_i_25 + 1) begin : gen_inp_ready
			localparam i = _gv_i_25;
			assign inp_ready_o[i] = oup_valid_o & oup_ready_i;
		end
	endgenerate
	initial begin : p_assertions
		
	end
endmodule
module stream_mux (
	inp_data_i,
	inp_valid_i,
	inp_ready_o,
	inp_sel_i,
	oup_data_o,
	oup_valid_o,
	oup_ready_i
);
	reg _sv2v_0;
	parameter integer N_INP = 0;
	parameter integer LOG_N_INP = $clog2(N_INP);
	input wire [N_INP - 1:0] inp_data_i;
	input wire [N_INP - 1:0] inp_valid_i;
	output reg [N_INP - 1:0] inp_ready_o;
	input wire [LOG_N_INP - 1:0] inp_sel_i;
	output wire oup_data_o;
	output wire oup_valid_o;
	input wire oup_ready_i;
	always @(*) begin
		if (_sv2v_0)
			;
		inp_ready_o = 1'sb0;
		inp_ready_o[inp_sel_i] = oup_ready_i;
	end
	assign oup_data_o = inp_data_i[inp_sel_i];
	assign oup_valid_o = inp_valid_i[inp_sel_i];
	initial begin : p_assertions
		
	end
	initial _sv2v_0 = 0;
endmodule
module stream_omega_net (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	data_i,
	sel_i,
	valid_i,
	ready_o,
	data_o,
	idx_o,
	valid_o,
	ready_i
);
	parameter [31:0] NumInp = 32'd0;
	parameter [31:0] NumOut = 32'd0;
	parameter [31:0] Radix = 32'd2;
	parameter [31:0] DataWidth = 32'd1;
	parameter [0:0] SpillReg = 1'b0;
	parameter [31:0] ExtPrio = 1'b0;
	parameter [31:0] AxiVldRdy = 1'b1;
	parameter [31:0] LockIn = 1'b1;
	parameter [31:0] SelWidth = (NumOut > 32'd1 ? $unsigned($clog2(NumOut)) : 32'd1);
	parameter [31:0] IdxWidth = (NumInp > 32'd1 ? $unsigned($clog2(NumInp)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [(NumOut * IdxWidth) - 1:0] rr_i;
	input wire [(NumInp * DataWidth) - 1:0] data_i;
	input wire [(NumInp * SelWidth) - 1:0] sel_i;
	input wire [NumInp - 1:0] valid_i;
	output wire [NumInp - 1:0] ready_o;
	output wire [(NumOut * DataWidth) - 1:0] data_o;
	output wire [(NumOut * IdxWidth) - 1:0] idx_o;
	output wire [NumOut - 1:0] valid_o;
	input wire [NumOut - 1:0] ready_i;
	function automatic integer cf_math_pkg_ceil_div;
		input reg signed [63:0] dividend;
		input reg signed [63:0] divisor;
		reg signed [63:0] remainder;
		begin
			if (dividend < 0) begin
				$display("Fatal [%0t] ./vendor/pulp_platform_common_cells/src/cf_math_pkg.sv:29:13 - stream_omega_net.cf_math_pkg_ceil_div.<unnamed_block>\n msg: ", $time, "Dividend %0d is not a natural number!", dividend);
				$finish(1);
			end
			if (divisor < 0) begin
				$display("Fatal [%0t] ./vendor/pulp_platform_common_cells/src/cf_math_pkg.sv:33:13 - stream_omega_net.cf_math_pkg_ceil_div.<unnamed_block>\n msg: ", $time, "Divisor %0d is not a natural number!", divisor);
				$finish(1);
			end
			if (divisor == 0) begin
				$display("Fatal [%0t] ./vendor/pulp_platform_common_cells/src/cf_math_pkg.sv:37:13 - stream_omega_net.cf_math_pkg_ceil_div.<unnamed_block>\n msg: ", $time, "Division by zero!");
				$finish(1);
			end
			remainder = dividend;
			for (cf_math_pkg_ceil_div = 0; remainder > 0; cf_math_pkg_ceil_div = cf_math_pkg_ceil_div + 1)
				remainder = remainder - divisor;
		end
	endfunction
	function automatic [DataWidth - 1:0] sv2v_cast_9719B;
		input reg [DataWidth - 1:0] inp;
		sv2v_cast_9719B = inp;
	endfunction
	function automatic [IdxWidth - 1:0] sv2v_cast_BCC4E;
		input reg [IdxWidth - 1:0] inp;
		sv2v_cast_BCC4E = inp;
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	generate
		if ((NumInp <= Radix) && (NumOut <= Radix)) begin : gen_degenerate_omega_net
			stream_xbar_0DA77_7EE1F #(
				.payload_t_DataWidth(DataWidth),
				.NumInp(NumInp),
				.NumOut(NumOut),
				.OutSpillReg(SpillReg),
				.ExtPrio(ExtPrio),
				.AxiVldRdy(AxiVldRdy),
				.LockIn(LockIn)
			) i_stream_xbar(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.flush_i(flush_i),
				.rr_i(rr_i),
				.data_i(data_i),
				.sel_i(sel_i),
				.valid_i(valid_i),
				.ready_o(ready_o),
				.data_o(data_o),
				.idx_o(idx_o),
				.valid_o(valid_o),
				.ready_i(ready_i)
			);
		end
		else begin : gen_omega_net
			localparam [31:0] NumLanes = (NumOut > NumInp ? $unsigned(Radix ** cf_math_pkg_ceil_div($clog2(NumOut), $clog2(Radix))) : $unsigned(Radix ** cf_math_pkg_ceil_div($clog2(NumInp), $clog2(Radix))));
			localparam [31:0] NumLevels = $unsigned((($clog2(NumLanes) + $clog2(Radix)) - 1) / $clog2(Radix));
			localparam [31:0] NumRouters = NumLanes / Radix;
			localparam [31:0] SelW = $unsigned($clog2(Radix));
			initial begin : proc_selw
				$display("SelW is:    %0d", SelW);
				$display("SelDstW is: %0d", $clog2(NumLanes));
			end
			wire [(((NumLevels * NumRouters) * Radix) * (($clog2(NumLanes) + DataWidth) + IdxWidth)) - 1:0] inp_router_data;
			wire [((NumLevels * NumRouters) * Radix) - 1:0] inp_router_valid;
			wire [((NumLevels * NumRouters) * Radix) - 1:0] inp_router_ready;
			wire [(((NumLevels * NumRouters) * Radix) * (($clog2(NumLanes) + DataWidth) + IdxWidth)) - 1:0] out_router_data;
			wire [((NumLevels * NumRouters) * Radix) - 1:0] out_router_valid;
			wire [((NumLevels * NumRouters) * Radix) - 1:0] out_router_ready;
			genvar _gv_i_26;
			for (_gv_i_26 = 0; $unsigned(_gv_i_26) < (NumLevels - 1); _gv_i_26 = _gv_i_26 + 1) begin : gen_shuffle_levels
				localparam i = _gv_i_26;
				genvar _gv_j_8;
				for (_gv_j_8 = 0; $unsigned(_gv_j_8) < NumRouters; _gv_j_8 = _gv_j_8 + 1) begin : gen_shuffle_routers
					localparam j = _gv_j_8;
					genvar _gv_k_6;
					for (_gv_k_6 = 0; $unsigned(_gv_k_6) < Radix; _gv_k_6 = _gv_k_6 + 1) begin : gen_shuffle_radix
						localparam k = _gv_k_6;
						localparam [31:0] IdxLane = (Radix * j) + k;
						assign inp_router_data[(((((i + 1) * NumRouters) + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)) * (($clog2(NumLanes) + DataWidth) + IdxWidth)+:($clog2(NumLanes) + DataWidth) + IdxWidth] = out_router_data[((((i * NumRouters) + j) * Radix) + k) * (($clog2(NumLanes) + DataWidth) + IdxWidth)+:($clog2(NumLanes) + DataWidth) + IdxWidth];
						assign inp_router_valid[((((i + 1) * NumRouters) + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)] = out_router_valid[(((i * NumRouters) + j) * Radix) + k];
						assign out_router_ready[(((i * NumRouters) + j) * Radix) + k] = inp_router_ready[((((i + 1) * NumRouters) + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)];
						if (i == 0) begin : gen_shuffle_inp
							if ((NumLanes - IdxLane) <= NumInp) begin : gen_inp_ports
								localparam [31:0] IdxInp = (NumLanes - IdxLane) - 32'd1;
								function automatic [$clog2(NumLanes) - 1:0] sv2v_cast_E2BA1;
									input reg [$clog2(NumLanes) - 1:0] inp;
									sv2v_cast_E2BA1 = inp;
								endfunction
								assign inp_router_data[(((0 + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)) * (($clog2(NumLanes) + DataWidth) + IdxWidth)+:($clog2(NumLanes) + DataWidth) + IdxWidth] = {sv2v_cast_E2BA1(sel_i[IdxInp * SelWidth+:SelWidth]), sv2v_cast_9719B(data_i[IdxInp * DataWidth+:DataWidth]), sv2v_cast_BCC4E(IdxInp)};
								assign inp_router_valid[((0 + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)] = valid_i[IdxInp];
								assign ready_o[IdxInp] = inp_router_ready[((0 + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)];
							end
							else begin : gen_tie_off
								function automatic [$clog2(NumLanes) - 1:0] sv2v_cast_E2BA1;
									input reg [$clog2(NumLanes) - 1:0] inp;
									sv2v_cast_E2BA1 = inp;
								endfunction
								assign inp_router_data[(((0 + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)) * (($clog2(NumLanes) + DataWidth) + IdxWidth)+:($clog2(NumLanes) + DataWidth) + IdxWidth] = {sv2v_cast_E2BA1(1'sb0), sv2v_cast_9719B(1'sb0), sv2v_cast_BCC4E(1'sb0)};
								assign inp_router_valid[((0 + (IdxLane % NumRouters)) * Radix) + (IdxLane / NumRouters)] = 1'b0;
							end
						end
					end
				end
			end
			genvar _gv_i_27;
			for (_gv_i_27 = 0; $unsigned(_gv_i_27) < NumLevels; _gv_i_27 = _gv_i_27 + 1) begin : gen_router_levels
				localparam i = _gv_i_27;
				genvar _gv_j_9;
				for (_gv_j_9 = 0; $unsigned(_gv_j_9) < NumRouters; _gv_j_9 = _gv_j_9 + 1) begin : gen_routers
					localparam j = _gv_j_9;
					wire [(Radix * SelW) - 1:0] sel_router;
					genvar _gv_k_7;
					for (_gv_k_7 = 0; $unsigned(_gv_k_7) < Radix; _gv_k_7 = _gv_k_7 + 1) begin : gen_router_sel
						localparam k = _gv_k_7;
						assign sel_router[k * SelW+:SelW] = inp_router_data[(((((i * NumRouters) + j) * Radix) + k) * (($clog2(NumLanes) + DataWidth) + IdxWidth)) + (($clog2(NumLanes) + (DataWidth + (IdxWidth - 1))) - (($clog2(NumLanes) - 1) - (SelW * ((NumLevels - i) - 1))))+:SelW];
					end
					localparam integer i_stream_xbar_sv2v_pfunc_7505D = $clog2(NumLanes);
					localparam [31:0] sv2v_uu_i_stream_xbar_NumInp = Radix;
					localparam [31:0] sv2v_uu_i_stream_xbar_IdxWidth = (sv2v_uu_i_stream_xbar_NumInp > 32'd1 ? $unsigned($clog2(sv2v_uu_i_stream_xbar_NumInp)) : 32'd1);
					localparam [31:0] sv2v_uu_i_stream_xbar_NumOut = Radix;
					localparam [(Radix * sv2v_cast_32((Radix > 32'd1 ? $unsigned($clog2(Radix)) : 32'd1))) - 1:0] sv2v_uu_i_stream_xbar_ext_rr_i_0 = 1'sb0;
					stream_xbar_0C5CF_4D6DF #(
						.payload_t_DataWidth(DataWidth),
						.payload_t_IdxWidth(IdxWidth),
						.payload_t_i_stream_xbar_sv2v_pfunc_7505D(i_stream_xbar_sv2v_pfunc_7505D),
						.NumInp(Radix),
						.NumOut(Radix),
						.OutSpillReg(SpillReg),
						.ExtPrio(1'b0),
						.AxiVldRdy(AxiVldRdy),
						.LockIn(LockIn)
					) i_stream_xbar(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.flush_i(flush_i),
						.rr_i(sv2v_uu_i_stream_xbar_ext_rr_i_0),
						.data_i(inp_router_data[(($clog2(NumLanes) + DataWidth) + IdxWidth) * (((i * NumRouters) + j) * Radix)+:(($clog2(NumLanes) + DataWidth) + IdxWidth) * Radix]),
						.sel_i(sel_router),
						.valid_i(inp_router_valid[((i * NumRouters) + j) * Radix+:Radix]),
						.ready_o(inp_router_ready[((i * NumRouters) + j) * Radix+:Radix]),
						.data_o(out_router_data[(($clog2(NumLanes) + DataWidth) + IdxWidth) * (((i * NumRouters) + j) * Radix)+:(($clog2(NumLanes) + DataWidth) + IdxWidth) * Radix]),
						.idx_o(),
						.valid_o(out_router_valid[((i * NumRouters) + j) * Radix+:Radix]),
						.ready_i(out_router_ready[((i * NumRouters) + j) * Radix+:Radix])
					);
				end
			end
			genvar _gv_i_28;
			for (_gv_i_28 = 0; $unsigned(_gv_i_28) < NumLanes; _gv_i_28 = _gv_i_28 + 1) begin : gen_outputs
				localparam i = _gv_i_28;
				if (i < NumOut) begin : gen_connect
					assign data_o[i * DataWidth+:DataWidth] = out_router_data[((((((NumLevels - 1) * NumRouters) + (i / Radix)) * Radix) + (i % Radix)) * (($clog2(NumLanes) + DataWidth) + IdxWidth)) + (DataWidth + (IdxWidth - 1))-:((DataWidth + (IdxWidth - 1)) >= (IdxWidth + 0) ? ((DataWidth + (IdxWidth - 1)) - (IdxWidth + 0)) + 1 : ((IdxWidth + 0) - (DataWidth + (IdxWidth - 1))) + 1)];
					assign idx_o[i * IdxWidth+:IdxWidth] = out_router_data[((((((NumLevels - 1) * NumRouters) + (i / Radix)) * Radix) + (i % Radix)) * (($clog2(NumLanes) + DataWidth) + IdxWidth)) + (IdxWidth - 1)-:IdxWidth];
					assign valid_o[i] = out_router_valid[((((NumLevels - 1) * NumRouters) + (i / Radix)) * Radix) + (i % Radix)];
					assign out_router_ready[((((NumLevels - 1) * NumRouters) + (i / Radix)) * Radix) + (i % Radix)] = ready_i[i];
				end
				else begin : gen_tie_off
					assign out_router_ready[((((NumLevels - 1) * NumRouters) + (i / Radix)) * Radix) + (i % Radix)] = 1'b0;
				end
			end
			initial begin : proc_debug_print
				$display("NumInp:     %0d", NumInp);
				$display("NumOut:     %0d", NumOut);
				$display("Radix:      %0d", Radix);
				$display("NumLanes:   %0d", NumLanes);
				$display("NumLevels:  %0d", NumLevels);
				$display("NumRouters: %0d", NumRouters);
			end
			genvar _gv_i_29;
			for (_gv_i_29 = 0; $unsigned(_gv_i_29) < NumInp; _gv_i_29 = _gv_i_29 + 1) begin : gen_sel_assertions
				localparam i = _gv_i_29;
			end
			if (AxiVldRdy) begin : gen_handshake_assertions
				genvar _gv_i_30;
				for (_gv_i_30 = 0; $unsigned(_gv_i_30) < NumInp; _gv_i_30 = _gv_i_30 + 1) begin : gen_inp_assertions
					localparam i = _gv_i_30;
				end
				genvar _gv_i_31;
				for (_gv_i_31 = 0; $unsigned(_gv_i_31) < NumOut; _gv_i_31 = _gv_i_31 + 1) begin : gen_out_assertions
					localparam i = _gv_i_31;
				end
			end
			initial begin : proc_parameter_assertions
				
			end
		end
	endgenerate
endmodule
module stream_register (
	clk_i,
	rst_ni,
	clr_i,
	testmode_i,
	valid_i,
	ready_o,
	data_i,
	valid_o,
	ready_i,
	data_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire clr_i;
	input wire testmode_i;
	input wire valid_i;
	output wire ready_o;
	input wire data_i;
	output wire valid_o;
	input wire ready_i;
	output wire data_o;
	wire fifo_empty;
	wire fifo_full;
	fifo_v2_EE579 #(
		.FALL_THROUGH(1'b0),
		.DATA_WIDTH(1),
		.DEPTH(1)
	) i_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(clr_i),
		.testmode_i(testmode_i),
		.full_o(fifo_full),
		.empty_o(fifo_empty),
		.alm_full_o(),
		.alm_empty_o(),
		.data_i(data_i),
		.push_i(valid_i & ~fifo_full),
		.data_o(data_o),
		.pop_i(ready_i & ~fifo_empty)
	);
	assign ready_o = ~fifo_full;
	assign valid_o = ~fifo_empty;
endmodule
module stream_to_mem (
	clk_i,
	rst_ni,
	req_i,
	req_valid_i,
	req_ready_o,
	resp_o,
	resp_valid_o,
	resp_ready_i,
	mem_req_o,
	mem_req_valid_o,
	mem_req_ready_i,
	mem_resp_i,
	mem_resp_valid_i
);
	reg _sv2v_0;
	parameter [31:0] BufDepth = 32'd1;
	input wire clk_i;
	input wire rst_ni;
	input wire req_i;
	input wire req_valid_i;
	output wire req_ready_o;
	output wire resp_o;
	output wire resp_valid_o;
	input wire resp_ready_i;
	output wire mem_req_o;
	output wire mem_req_valid_o;
	input wire mem_req_ready_i;
	input wire mem_resp_i;
	input wire mem_resp_valid_i;
	reg [$clog2(BufDepth + 1):0] cnt_d;
	reg [$clog2(BufDepth + 1):0] cnt_q;
	wire buf_ready;
	wire req_ready;
	generate
		if (BufDepth > 0) begin : gen_buf
			always @(*) begin
				if (_sv2v_0)
					;
				cnt_d = cnt_q;
				if (req_valid_i && req_ready_o)
					cnt_d = cnt_d + 1;
				if (resp_valid_o && resp_ready_i)
					cnt_d = cnt_d - 1;
			end
			assign req_ready = (cnt_q < BufDepth) | (resp_valid_o & resp_ready_i);
			assign req_ready_o = mem_req_ready_i & req_ready;
			assign mem_req_valid_o = req_valid_i & req_ready;
			stream_fifo_18E2D #(
				.FALL_THROUGH(1'b1),
				.DEPTH(BufDepth)
			) i_resp_buf(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.flush_i(1'b0),
				.testmode_i(1'b0),
				.data_i(mem_resp_i),
				.valid_i(mem_resp_valid_i),
				.ready_o(buf_ready),
				.data_o(resp_o),
				.valid_o(resp_valid_o),
				.ready_i(resp_ready_i),
				.usage_o()
			);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					cnt_q <= 1'sb0;
				else
					cnt_q <= cnt_d;
		end
		else begin : gen_no_buf
			assign mem_req_valid_o = req_valid_i;
			assign resp_valid_o = (mem_req_valid_o & mem_req_ready_i) & mem_resp_valid_i;
			assign req_ready_o = resp_ready_i & resp_valid_o;
			assign resp_o = mem_resp_i;
		end
	endgenerate
	assign mem_req_o = req_i;
	initial _sv2v_0 = 0;
endmodule
module stream_xbar_0C5CF_4D6DF (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	data_i,
	sel_i,
	valid_i,
	ready_o,
	data_o,
	idx_o,
	valid_o,
	ready_i
);
	parameter [31:0] payload_t_DataWidth = 0;
	parameter [31:0] payload_t_IdxWidth = 0;
	parameter integer payload_t_i_stream_xbar_sv2v_pfunc_7505D = 0;
	parameter [31:0] NumInp = 32'd0;
	parameter [31:0] NumOut = 32'd0;
	parameter [31:0] DataWidth = 32'd1;
	parameter [0:0] OutSpillReg = 1'b0;
	parameter [31:0] ExtPrio = 1'b0;
	parameter [31:0] AxiVldRdy = 1'b1;
	parameter [31:0] LockIn = 1'b1;
	parameter [31:0] SelWidth = (NumOut > 32'd1 ? $unsigned($clog2(NumOut)) : 32'd1);
	parameter [31:0] IdxWidth = (NumInp > 32'd1 ? $unsigned($clog2(NumInp)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [(NumOut * IdxWidth) - 1:0] rr_i;
	input wire [(NumInp * ((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth)) - 1:0] data_i;
	input wire [(NumInp * SelWidth) - 1:0] sel_i;
	input wire [NumInp - 1:0] valid_i;
	output wire [NumInp - 1:0] ready_o;
	output wire [(NumOut * ((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth)) - 1:0] data_o;
	output wire [(NumOut * IdxWidth) - 1:0] idx_o;
	output wire [NumOut - 1:0] valid_o;
	input wire [NumOut - 1:0] ready_i;
	wire [(NumInp * NumOut) - 1:0] inp_valid;
	wire [(NumInp * NumOut) - 1:0] inp_ready;
	wire [((NumOut * NumInp) * ((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth)) - 1:0] out_data;
	wire [(NumOut * NumInp) - 1:0] out_valid;
	wire [(NumOut * NumInp) - 1:0] out_ready;
	genvar _gv_i_32;
	generate
		for (_gv_i_32 = 0; $unsigned(_gv_i_32) < NumInp; _gv_i_32 = _gv_i_32 + 1) begin : gen_inps
			localparam i = _gv_i_32;
			stream_demux #(.N_OUP(NumOut)) i_stream_demux(
				.inp_valid_i(valid_i[i]),
				.inp_ready_o(ready_o[i]),
				.oup_sel_i(sel_i[i * SelWidth+:SelWidth]),
				.oup_valid_o(inp_valid[i * NumOut+:NumOut]),
				.oup_ready_i(inp_ready[i * NumOut+:NumOut])
			);
			genvar _gv_j_10;
			for (_gv_j_10 = 0; $unsigned(_gv_j_10) < NumOut; _gv_j_10 = _gv_j_10 + 1) begin : gen_cross
				localparam j = _gv_j_10;
				assign out_data[((j * NumInp) + i) * ((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth)+:(payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth] = data_i[i * ((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth)+:(payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth];
				assign out_valid[(j * NumInp) + i] = inp_valid[(i * NumOut) + j];
				assign inp_ready[(i * NumOut) + j] = out_ready[(j * NumInp) + i];
			end
		end
	endgenerate
	genvar _gv_j_11;
	generate
		for (_gv_j_11 = 0; $unsigned(_gv_j_11) < NumOut; _gv_j_11 = _gv_j_11 + 1) begin : gen_outs
			localparam j = _gv_j_11;
			wire [(((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + IdxWidth) - 1:0] arb;
			wire arb_valid;
			wire arb_ready;
			rr_arb_tree_4B249_E9E1F #(
				.DataType_payload_t_DataWidth(payload_t_DataWidth),
				.DataType_payload_t_IdxWidth(payload_t_IdxWidth),
				.DataType_payload_t_i_stream_xbar_sv2v_pfunc_7505D(payload_t_i_stream_xbar_sv2v_pfunc_7505D),
				.NumIn(NumInp),
				.ExtPrio(ExtPrio),
				.AxiVldRdy(AxiVldRdy),
				.LockIn(LockIn)
			) i_rr_arb_tree(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.flush_i(flush_i),
				.rr_i(rr_i[j * IdxWidth+:IdxWidth]),
				.req_i(out_valid[j * NumInp+:NumInp]),
				.gnt_o(out_ready[j * NumInp+:NumInp]),
				.data_i(out_data[((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) * (j * NumInp)+:((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) * NumInp]),
				.req_o(arb_valid),
				.gnt_i(arb_ready),
				.data_o(arb[((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1)-:((((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1)) >= (IdxWidth + 0) ? ((((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1)) - (IdxWidth + 0)) + 1 : ((IdxWidth + 0) - (((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1))) + 1)]),
				.idx_o(arb[IdxWidth - 1-:IdxWidth])
			);
			wire [(((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + IdxWidth) - 1:0] spill;
			spill_register_5603B_A7272 #(
				.T_IdxWidth(IdxWidth),
				.T_payload_t_DataWidth(payload_t_DataWidth),
				.T_payload_t_IdxWidth(payload_t_IdxWidth),
				.T_payload_t_i_stream_xbar_sv2v_pfunc_7505D(payload_t_i_stream_xbar_sv2v_pfunc_7505D),
				.Bypass(!OutSpillReg)
			) i_spill_register(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.valid_i(arb_valid),
				.ready_o(arb_ready),
				.data_i(arb),
				.valid_o(valid_o[j]),
				.ready_i(ready_i[j]),
				.data_o(spill)
			);
			assign data_o[j * ((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth)+:(payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth] = spill[((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1)-:((((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1)) >= (IdxWidth + 0) ? ((((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1)) - (IdxWidth + 0)) + 1 : ((IdxWidth + 0) - (((payload_t_i_stream_xbar_sv2v_pfunc_7505D + payload_t_DataWidth) + payload_t_IdxWidth) + (IdxWidth - 1))) + 1)];
			assign idx_o[j * IdxWidth+:IdxWidth] = spill[IdxWidth - 1-:IdxWidth];
		end
	endgenerate
	genvar _gv_i_33;
	generate
		for (_gv_i_33 = 0; $unsigned(_gv_i_33) < NumInp; _gv_i_33 = _gv_i_33 + 1) begin : gen_sel_assertions
			localparam i = _gv_i_33;
		end
		if (AxiVldRdy) begin : gen_handshake_assertions
			genvar _gv_i_34;
			for (_gv_i_34 = 0; $unsigned(_gv_i_34) < NumInp; _gv_i_34 = _gv_i_34 + 1) begin : gen_inp_assertions
				localparam i = _gv_i_34;
			end
			genvar _gv_i_35;
			for (_gv_i_35 = 0; $unsigned(_gv_i_35) < NumOut; _gv_i_35 = _gv_i_35 + 1) begin : gen_out_assertions
				localparam i = _gv_i_35;
			end
		end
	endgenerate
	initial begin : proc_parameter_assertions
		
	end
endmodule
module stream_xbar_0DA77_7EE1F (
	clk_i,
	rst_ni,
	flush_i,
	rr_i,
	data_i,
	sel_i,
	valid_i,
	ready_o,
	data_o,
	idx_o,
	valid_o,
	ready_i
);
	parameter [31:0] payload_t_DataWidth = 0;
	parameter [31:0] NumInp = 32'd0;
	parameter [31:0] NumOut = 32'd0;
	parameter [31:0] DataWidth = 32'd1;
	parameter [0:0] OutSpillReg = 1'b0;
	parameter [31:0] ExtPrio = 1'b0;
	parameter [31:0] AxiVldRdy = 1'b1;
	parameter [31:0] LockIn = 1'b1;
	parameter [31:0] SelWidth = (NumOut > 32'd1 ? $unsigned($clog2(NumOut)) : 32'd1);
	parameter [31:0] IdxWidth = (NumInp > 32'd1 ? $unsigned($clog2(NumInp)) : 32'd1);
	input wire clk_i;
	input wire rst_ni;
	input wire flush_i;
	input wire [(NumOut * IdxWidth) - 1:0] rr_i;
	input wire [(NumInp * payload_t_DataWidth) - 1:0] data_i;
	input wire [(NumInp * SelWidth) - 1:0] sel_i;
	input wire [NumInp - 1:0] valid_i;
	output wire [NumInp - 1:0] ready_o;
	output wire [(NumOut * payload_t_DataWidth) - 1:0] data_o;
	output wire [(NumOut * IdxWidth) - 1:0] idx_o;
	output wire [NumOut - 1:0] valid_o;
	input wire [NumOut - 1:0] ready_i;
	wire [(NumInp * NumOut) - 1:0] inp_valid;
	wire [(NumInp * NumOut) - 1:0] inp_ready;
	wire [((NumOut * NumInp) * payload_t_DataWidth) - 1:0] out_data;
	wire [(NumOut * NumInp) - 1:0] out_valid;
	wire [(NumOut * NumInp) - 1:0] out_ready;
	genvar _gv_i_32;
	generate
		for (_gv_i_32 = 0; $unsigned(_gv_i_32) < NumInp; _gv_i_32 = _gv_i_32 + 1) begin : gen_inps
			localparam i = _gv_i_32;
			stream_demux #(.N_OUP(NumOut)) i_stream_demux(
				.inp_valid_i(valid_i[i]),
				.inp_ready_o(ready_o[i]),
				.oup_sel_i(sel_i[i * SelWidth+:SelWidth]),
				.oup_valid_o(inp_valid[i * NumOut+:NumOut]),
				.oup_ready_i(inp_ready[i * NumOut+:NumOut])
			);
			genvar _gv_j_10;
			for (_gv_j_10 = 0; $unsigned(_gv_j_10) < NumOut; _gv_j_10 = _gv_j_10 + 1) begin : gen_cross
				localparam j = _gv_j_10;
				assign out_data[((j * NumInp) + i) * payload_t_DataWidth+:payload_t_DataWidth] = data_i[i * payload_t_DataWidth+:payload_t_DataWidth];
				assign out_valid[(j * NumInp) + i] = inp_valid[(i * NumOut) + j];
				assign inp_ready[(i * NumOut) + j] = out_ready[(j * NumInp) + i];
			end
		end
	endgenerate
	genvar _gv_j_11;
	generate
		for (_gv_j_11 = 0; $unsigned(_gv_j_11) < NumOut; _gv_j_11 = _gv_j_11 + 1) begin : gen_outs
			localparam j = _gv_j_11;
			wire [(payload_t_DataWidth + IdxWidth) - 1:0] arb;
			wire arb_valid;
			wire arb_ready;
			rr_arb_tree_DDE89_9935E #(
				.DataType_payload_t_DataWidth(payload_t_DataWidth),
				.NumIn(NumInp),
				.ExtPrio(ExtPrio),
				.AxiVldRdy(AxiVldRdy),
				.LockIn(LockIn)
			) i_rr_arb_tree(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.flush_i(flush_i),
				.rr_i(rr_i[j * IdxWidth+:IdxWidth]),
				.req_i(out_valid[j * NumInp+:NumInp]),
				.gnt_o(out_ready[j * NumInp+:NumInp]),
				.data_i(out_data[payload_t_DataWidth * (j * NumInp)+:payload_t_DataWidth * NumInp]),
				.req_o(arb_valid),
				.gnt_i(arb_ready),
				.data_o(arb[payload_t_DataWidth + (IdxWidth - 1)-:((payload_t_DataWidth + (IdxWidth - 1)) >= (IdxWidth + 0) ? ((payload_t_DataWidth + (IdxWidth - 1)) - (IdxWidth + 0)) + 1 : ((IdxWidth + 0) - (payload_t_DataWidth + (IdxWidth - 1))) + 1)]),
				.idx_o(arb[IdxWidth - 1-:IdxWidth])
			);
			wire [(payload_t_DataWidth + IdxWidth) - 1:0] spill;
			spill_register_5AE7A_F0150 #(
				.T_IdxWidth(IdxWidth),
				.T_payload_t_DataWidth(payload_t_DataWidth),
				.Bypass(!OutSpillReg)
			) i_spill_register(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.valid_i(arb_valid),
				.ready_o(arb_ready),
				.data_i(arb),
				.valid_o(valid_o[j]),
				.ready_i(ready_i[j]),
				.data_o(spill)
			);
			assign data_o[j * payload_t_DataWidth+:payload_t_DataWidth] = spill[payload_t_DataWidth + (IdxWidth - 1)-:((payload_t_DataWidth + (IdxWidth - 1)) >= (IdxWidth + 0) ? ((payload_t_DataWidth + (IdxWidth - 1)) - (IdxWidth + 0)) + 1 : ((IdxWidth + 0) - (payload_t_DataWidth + (IdxWidth - 1))) + 1)];
			assign idx_o[j * IdxWidth+:IdxWidth] = spill[IdxWidth - 1-:IdxWidth];
		end
	endgenerate
	genvar _gv_i_33;
	generate
		for (_gv_i_33 = 0; $unsigned(_gv_i_33) < NumInp; _gv_i_33 = _gv_i_33 + 1) begin : gen_sel_assertions
			localparam i = _gv_i_33;
		end
		if (AxiVldRdy) begin : gen_handshake_assertions
			genvar _gv_i_34;
			for (_gv_i_34 = 0; $unsigned(_gv_i_34) < NumInp; _gv_i_34 = _gv_i_34 + 1) begin : gen_inp_assertions
				localparam i = _gv_i_34;
			end
			genvar _gv_i_35;
			for (_gv_i_35 = 0; $unsigned(_gv_i_35) < NumOut; _gv_i_35 = _gv_i_35 + 1) begin : gen_out_assertions
				localparam i = _gv_i_35;
			end
		end
	endgenerate
	initial begin : proc_parameter_assertions
		
	end
endmodule
module sub_per_hash (
	data_i,
	hash_o,
	hash_onehot_o
);
	parameter [31:0] InpWidth = 32'd11;
	parameter [31:0] HashWidth = 32'd5;
	parameter [31:0] NoRounds = 32'd1;
	parameter [31:0] PermuteKey = 32'd299034753;
	parameter [31:0] XorKey = 32'd4094834;
	input wire [InpWidth - 1:0] data_i;
	output wire [HashWidth - 1:0] hash_o;
	output wire [(2 ** HashWidth) - 1:0] hash_onehot_o;
	function automatic [((NoRounds * InpWidth) * 32) - 1:0] get_permutations;
		input reg [31:0] seed;
		reg [31:0] indices [0:NoRounds - 1][0:InpWidth - 1];
		reg [((NoRounds * InpWidth) * 32) - 1:0] perm_array;
		reg [63:0] A;
		reg [63:0] C;
		reg [63:0] M;
		reg [63:0] index;
		reg [63:0] advance;
		reg [63:0] rand_number;
		begin
			A = 2147483629;
			C = 2147483587;
			M = 33'sd2147483648 - 1;
			index = 0;
			advance = 0;
			rand_number = ((A * seed) + C) % M;
			begin : sv2v_autoblock_1
				reg [31:0] r;
				for (r = 0; r < NoRounds; r = r + 1)
					begin
						begin : sv2v_autoblock_2
							reg [31:0] i;
							for (i = 0; i < InpWidth; i = i + 1)
								indices[r][i] = i;
						end
						begin : sv2v_autoblock_3
							reg [31:0] i;
							for (i = 0; i < InpWidth; i = i + 1)
								begin
									if (i > 0) begin
										rand_number = ((A * rand_number) + C) % M;
										index = rand_number % i;
									end
									if (i != index) begin
										perm_array[((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - i)) * 32+:32] = perm_array[((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - index)) * 32+:32];
										perm_array[((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - index)) * 32+:32] = indices[r][i];
									end
								end
						end
						rand_number = ((A * rand_number) + C) % M;
						advance = rand_number % NoRounds;
						begin : sv2v_autoblock_4
							reg [31:0] i;
							for (i = 0; i < advance; i = i + 1)
								rand_number = ((A * rand_number) + C) % M;
						end
					end
			end
			get_permutations = perm_array;
		end
	endfunction
	localparam [((NoRounds * InpWidth) * 32) - 1:0] PERMUTATIONS = get_permutations(PermuteKey);
	function automatic [(((NoRounds * InpWidth) * 3) * 32) - 1:0] get_xor_stages;
		input reg [31:0] seed;
		reg [(((NoRounds * InpWidth) * 3) * 32) - 1:0] xor_array;
		reg [63:0] A;
		reg [63:0] C;
		reg [63:0] M;
		reg [63:0] index;
		reg [63:0] advance;
		reg [63:0] rand_number;
		begin
			A = 1664525;
			C = 1013904223;
			M = 34'sd4294967296;
			index = 0;
			advance = 0;
			rand_number = ((A * seed) + C) % M;
			begin : sv2v_autoblock_5
				reg [31:0] r;
				for (r = 0; r < NoRounds; r = r + 1)
					begin
						begin : sv2v_autoblock_6
							reg [31:0] i;
							for (i = 0; i < InpWidth; i = i + 1)
								begin
									rand_number = ((A * rand_number) + C) % M;
									begin : sv2v_autoblock_7
										reg [31:0] j;
										for (j = 0; j < 3; j = j + 1)
											begin
												rand_number = ((A * rand_number) + C) % M;
												index = rand_number % InpWidth;
												xor_array[((((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - i)) * 3) + (2 - j)) * 32+:32] = index;
											end
									end
								end
						end
						rand_number = ((A * rand_number) + C) % M;
						advance = rand_number % NoRounds;
						begin : sv2v_autoblock_8
							reg [31:0] i;
							for (i = 0; i < advance; i = i + 1)
								rand_number = ((A * rand_number) + C) % M;
						end
					end
			end
			get_xor_stages = xor_array;
		end
	endfunction
	localparam [(((NoRounds * InpWidth) * 3) * 32) - 1:0] XorStages = get_xor_stages(XorKey);
	wire [(NoRounds * InpWidth) - 1:0] permuted;
	wire [(NoRounds * InpWidth) - 1:0] xored;
	genvar _gv_r_1;
	generate
		for (_gv_r_1 = 0; _gv_r_1 < NoRounds; _gv_r_1 = _gv_r_1 + 1) begin : gen_round
			localparam r = _gv_r_1;
			genvar _gv_i_36;
			for (_gv_i_36 = 0; _gv_i_36 < InpWidth; _gv_i_36 = _gv_i_36 + 1) begin : gen_sub_per
				localparam i = _gv_i_36;
				if (r == 0) begin : gen_input
					assign permuted[(r * InpWidth) + i] = data_i[PERMUTATIONS[((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - i)) * 32+:32]];
				end
				else begin : gen_permutation
					assign permuted[(r * InpWidth) + i] = permuted[((r - 1) * InpWidth) + PERMUTATIONS[((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - i)) * 32+:32]];
				end
				assign xored[(r * InpWidth) + i] = (permuted[(r * InpWidth) + XorStages[((((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - i)) * 3) + 2) * 32+:32]] ^ permuted[(r * InpWidth) + XorStages[((((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - i)) * 3) + 1) * 32+:32]]) ^ permuted[(r * InpWidth) + XorStages[(((((NoRounds - 1) - r) * InpWidth) + ((InpWidth - 1) - i)) * 3) * 32+:32]];
			end
		end
	endgenerate
	assign hash_o = xored[((NoRounds - 1) * InpWidth) + (HashWidth - 1)-:HashWidth];
	assign hash_onehot_o = 1 << hash_o;
endmodule
module sync (
	clk_i,
	rst_ni,
	serial_i,
	serial_o
);
	parameter [31:0] STAGES = 2;
	input wire clk_i;
	input wire rst_ni;
	input wire serial_i;
	output wire serial_o;
	reg [STAGES - 1:0] reg_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			reg_q <= 'h0;
		else
			reg_q <= {reg_q[STAGES - 2:0], serial_i};
	assign serial_o = reg_q[STAGES - 1];
endmodule
module sync_wedge (
	clk_i,
	rst_ni,
	en_i,
	serial_i,
	r_edge_o,
	f_edge_o,
	serial_o
);
	parameter [31:0] STAGES = 2;
	input wire clk_i;
	input wire rst_ni;
	input wire en_i;
	input wire serial_i;
	output wire r_edge_o;
	output wire f_edge_o;
	output wire serial_o;
	wire clk;
	wire serial;
	reg serial_q;
	assign serial_o = serial_q;
	assign f_edge_o = ~serial & serial_q;
	assign r_edge_o = serial & ~serial_q;
	sync #(.STAGES(STAGES)) i_sync(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.serial_i(serial_i),
		.serial_o(serial)
	);
	pulp_clock_gating i_pulp_clock_gating(
		.clk_i(clk_i),
		.en_i(en_i),
		.test_en_i(1'b0),
		.clk_o(clk)
	);
	always @(posedge clk or negedge rst_ni)
		if (!rst_ni)
			serial_q <= 1'b0;
		else if (en_i)
			serial_q <= serial;
endmodule
module unread (d_i);
	input wire d_i;
endmodule
module fpnew_cast_multi_3E15B_08E4E (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	int_fmt_i,
	tag_i,
	mask_i,
	aux_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	parameter [31:0] AuxType_AUX_BITS = 0;
	reg _sv2v_0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	parameter [0:4] FpFmtConfig = 1'sb1;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	parameter [0:3] IntFmtConfig = 1'sb1;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	function automatic [1:0] sv2v_cast_2D3A8;
		input reg [1:0] inp;
		sv2v_cast_2D3A8 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_int_width;
		input reg [1:0] ifmt;
		(* full_case, parallel_case *)
		case (ifmt)
			sv2v_cast_2D3A8(0): fpnew_pkg_int_width = 8;
			sv2v_cast_2D3A8(1): fpnew_pkg_int_width = 16;
			sv2v_cast_2D3A8(2): fpnew_pkg_int_width = 32;
			sv2v_cast_2D3A8(3): fpnew_pkg_int_width = 64;
			default: begin
				$display("Fatal [%0t] ./vendor/pulp_platform_fpnew/src/fpnew_pkg.sv:96:9 - fpnew_cast_multi.fpnew_pkg_int_width.<unnamed_block>\n msg: ", $time, "Invalid INT format supplied");
				$finish(1);
				fpnew_pkg_int_width = sv2v_cast_2D3A8(0);
			end
		endcase
	endfunction
	function automatic [31:0] fpnew_pkg_max_int_width;
		input reg [0:3] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_2
				reg signed [31:0] ifmt;
				for (ifmt = 0; ifmt < fpnew_pkg_NUM_INT_FORMATS; ifmt = ifmt + 1)
					if (cfg[ifmt])
						res = fpnew_pkg_maximum(res, fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt)));
			end
			fpnew_pkg_max_int_width = res;
		end
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_maximum(fpnew_pkg_max_fp_width(FpFmtConfig), fpnew_pkg_max_int_width(IntFmtConfig));
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [WIDTH - 1:0] operands_i;
	input wire [4:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	input wire [1:0] int_fmt_i;
	input wire tag_i;
	input wire mask_i;
	input wire [AuxType_AUX_BITS - 1:0] aux_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire mask_o;
	output wire [AuxType_AUX_BITS - 1:0] aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	localparam [31:0] NUM_INT_FORMATS = fpnew_pkg_NUM_INT_FORMATS;
	localparam [31:0] MAX_INT_WIDTH = fpnew_pkg_max_int_width(IntFmtConfig);
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	function automatic [63:0] fpnew_pkg_super_format;
		input reg [0:4] cfg;
		reg [63:0] res;
		begin
			res = 1'sb0;
			begin : sv2v_autoblock_3
				reg [31:0] fmt;
				for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
					if (cfg[fmt]) begin
						res[63-:32] = $unsigned(fpnew_pkg_maximum(res[63-:32], fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt))));
						res[31-:32] = $unsigned(fpnew_pkg_maximum(res[31-:32], fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt))));
					end
			end
			fpnew_pkg_super_format = res;
		end
	endfunction
	localparam [63:0] SUPER_FORMAT = fpnew_pkg_super_format(FpFmtConfig);
	localparam [31:0] SUPER_EXP_BITS = SUPER_FORMAT[63-:32];
	localparam [31:0] SUPER_MAN_BITS = SUPER_FORMAT[31-:32];
	localparam [31:0] SUPER_BIAS = (2 ** (SUPER_EXP_BITS - 1)) - 1;
	localparam [31:0] INT_MAN_WIDTH = fpnew_pkg_maximum(SUPER_MAN_BITS + 1, MAX_INT_WIDTH);
	localparam [31:0] LZC_RESULT_WIDTH = $clog2(INT_MAN_WIDTH);
	localparam [31:0] INT_EXP_WIDTH = fpnew_pkg_maximum($clog2(MAX_INT_WIDTH), fpnew_pkg_maximum(SUPER_EXP_BITS, $clog2(SUPER_BIAS + SUPER_MAN_BITS))) + 1;
	localparam NUM_INP_REGS = (PipeConfig == 2'd0 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 3 : 0));
	localparam NUM_MID_REGS = (PipeConfig == 2'd2 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 2) / 3 : 0));
	localparam NUM_OUT_REGS = (PipeConfig == 2'd1 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 3 : 0));
	wire [WIDTH - 1:0] operands_q;
	wire [4:0] is_boxed_q;
	wire op_mod_q;
	wire [2:0] src_fmt_q;
	wire [2:0] dst_fmt_q;
	wire [1:0] int_fmt_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * WIDTH) + ((NUM_INP_REGS * WIDTH) - 1) : ((NUM_INP_REGS + 1) * WIDTH) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * WIDTH : 0)] inp_pipe_operands_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0)] inp_pipe_is_boxed_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_op_mod_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] inp_pipe_src_fmt_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] inp_pipe_dst_fmt_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_INT_FORMAT_BITS) + ((NUM_INP_REGS * fpnew_pkg_INT_FORMAT_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_INT_FORMAT_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_INT_FORMAT_BITS : 0)] inp_pipe_int_fmt_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * AuxType_AUX_BITS) + ((NUM_INP_REGS * AuxType_AUX_BITS) - 1) : ((NUM_INP_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * AuxType_AUX_BITS : 0)] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	wire [0:NUM_INP_REGS] inp_pipe_ready;
	wire [WIDTH * 1:1] sv2v_tmp_51F1E;
	assign sv2v_tmp_51F1E = operands_i;
	always @(*) inp_pipe_operands_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * WIDTH+:WIDTH] = sv2v_tmp_51F1E;
	wire [5:1] sv2v_tmp_1C07D;
	assign sv2v_tmp_1C07D = is_boxed_i;
	always @(*) inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * NUM_FORMATS+:NUM_FORMATS] = sv2v_tmp_1C07D;
	wire [3:1] sv2v_tmp_357FA;
	assign sv2v_tmp_357FA = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_357FA;
	wire [4:1] sv2v_tmp_F9118;
	assign sv2v_tmp_F9118 = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_F9118;
	wire [1:1] sv2v_tmp_42D74;
	assign sv2v_tmp_42D74 = op_mod_i;
	always @(*) inp_pipe_op_mod_q[0] = sv2v_tmp_42D74;
	wire [3:1] sv2v_tmp_189D9;
	assign sv2v_tmp_189D9 = src_fmt_i;
	always @(*) inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_189D9;
	wire [3:1] sv2v_tmp_E7E22;
	assign sv2v_tmp_E7E22 = dst_fmt_i;
	always @(*) inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_E7E22;
	wire [2:1] sv2v_tmp_E89E3;
	assign sv2v_tmp_E89E3 = int_fmt_i;
	always @(*) inp_pipe_int_fmt_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] = sv2v_tmp_E89E3;
	wire [1:1] sv2v_tmp_6A91A;
	assign sv2v_tmp_6A91A = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_6A91A;
	wire [1:1] sv2v_tmp_43EE3;
	assign sv2v_tmp_43EE3 = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_43EE3;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_97D8E;
	assign sv2v_tmp_97D8E = aux_i;
	always @(*) inp_pipe_aux_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_97D8E;
	wire [1:1] sv2v_tmp_9CFD6;
	assign sv2v_tmp_9CFD6 = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_9CFD6;
	assign in_ready_o = inp_pipe_ready[0];
	genvar _gv_i_37;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	function automatic [AuxType_AUX_BITS - 1:0] sv2v_cast_F912A;
		input reg [AuxType_AUX_BITS - 1:0] inp;
		sv2v_cast_F912A = inp;
	endfunction
	generate
		for (_gv_i_37 = 0; _gv_i_37 < NUM_INP_REGS; _gv_i_37 = _gv_i_37 + 1) begin : gen_input_pipeline
			localparam i = _gv_i_37;
			wire reg_ena;
			assign inp_pipe_ready[i] = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * WIDTH+:WIDTH] <= 1'sb0;
				else
					inp_pipe_operands_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * WIDTH+:WIDTH] <= (reg_ena ? inp_pipe_operands_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * WIDTH+:WIDTH] : inp_pipe_operands_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * WIDTH+:WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS+:NUM_FORMATS] <= 1'sb0;
				else
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS+:NUM_FORMATS] <= (reg_ena ? inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * NUM_FORMATS+:NUM_FORMATS] : inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS+:NUM_FORMATS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_7BCAE(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_mod_q[i + 1] <= 1'sb0;
				else
					inp_pipe_op_mod_q[i + 1] <= (reg_ena ? inp_pipe_op_mod_q[i] : inp_pipe_op_mod_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_int_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] <= sv2v_cast_2D3A8(0);
				else
					inp_pipe_int_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] <= (reg_ena ? inp_pipe_int_fmt_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] : inp_pipe_int_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign operands_q = inp_pipe_operands_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * WIDTH+:WIDTH];
	assign is_boxed_q = inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * NUM_FORMATS+:NUM_FORMATS];
	assign op_mod_q = inp_pipe_op_mod_q[NUM_INP_REGS];
	assign src_fmt_q = inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	assign dst_fmt_q = inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	assign int_fmt_q = inp_pipe_int_fmt_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS];
	wire src_is_int;
	wire dst_is_int;
	assign src_is_int = inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] == sv2v_cast_7BCAE(12);
	assign dst_is_int = inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] == sv2v_cast_7BCAE(11);
	wire [INT_MAN_WIDTH - 1:0] encoded_mant;
	wire [4:0] fmt_sign;
	wire signed [(NUM_FORMATS * INT_EXP_WIDTH) - 1:0] fmt_exponent;
	wire [(NUM_FORMATS * INT_MAN_WIDTH) - 1:0] fmt_mantissa;
	wire signed [(NUM_FORMATS * INT_EXP_WIDTH) - 1:0] fmt_shift_compensation;
	wire [39:0] info;
	reg [(NUM_INT_FORMATS * INT_MAN_WIDTH) - 1:0] ifmt_input_val;
	wire int_sign;
	wire [INT_MAN_WIDTH - 1:0] int_value;
	wire [INT_MAN_WIDTH - 1:0] int_mantissa;
	genvar _gv_fmt_1;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic signed [0:0] sv2v_cast_1_signed;
		input reg signed [0:0] inp;
		sv2v_cast_1_signed = inp;
	endfunction
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (_gv_fmt_1 = 0; _gv_fmt_1 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_1 = _gv_fmt_1 + 1) begin : fmt_init_inputs
			localparam fmt = _gv_fmt_1;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			if (FpFmtConfig[fmt]) begin : active_format
				fpnew_classifier #(
					.FpFormat(sv2v_cast_9FB13(fmt)),
					.NumOperands(1)
				) i_fpnew_classifier(
					.operands_i(operands_q[FP_WIDTH - 1:0]),
					.is_boxed_i(is_boxed_q[fmt]),
					.info_o(info[fmt * 8+:8])
				);
				assign fmt_sign[fmt] = operands_q[FP_WIDTH - 1];
				assign fmt_exponent[fmt * INT_EXP_WIDTH+:INT_EXP_WIDTH] = $signed({1'b0, operands_q[MAN_BITS+:EXP_BITS]});
				assign fmt_mantissa[fmt * INT_MAN_WIDTH+:INT_MAN_WIDTH] = {info[(fmt * 8) + 7], operands_q[MAN_BITS - 1:0]};
				assign fmt_shift_compensation[fmt * INT_EXP_WIDTH+:INT_EXP_WIDTH] = $signed((INT_MAN_WIDTH - 1) - MAN_BITS);
			end
			else begin : inactive_format
				assign info[fmt * 8+:8] = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				assign fmt_sign[fmt] = fpnew_pkg_DONT_CARE;
				assign fmt_exponent[fmt * INT_EXP_WIDTH+:INT_EXP_WIDTH] = {INT_EXP_WIDTH {sv2v_cast_1_signed(fpnew_pkg_DONT_CARE)}};
				assign fmt_mantissa[fmt * INT_MAN_WIDTH+:INT_MAN_WIDTH] = {INT_MAN_WIDTH {fpnew_pkg_DONT_CARE}};
				assign fmt_shift_compensation[fmt * INT_EXP_WIDTH+:INT_EXP_WIDTH] = {INT_EXP_WIDTH {sv2v_cast_1_signed(fpnew_pkg_DONT_CARE)}};
			end
		end
	endgenerate
	genvar _gv_ifmt_1;
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	generate
		for (_gv_ifmt_1 = 0; _gv_ifmt_1 < sv2v_cast_32_signed(NUM_INT_FORMATS); _gv_ifmt_1 = _gv_ifmt_1 + 1) begin : gen_sign_extend_int
			localparam ifmt = _gv_ifmt_1;
			localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt));
			if (IntFmtConfig[ifmt]) begin : active_format
				always @(*) begin : sign_ext_input
					if (_sv2v_0)
						;
					ifmt_input_val[ifmt * INT_MAN_WIDTH+:INT_MAN_WIDTH] = {INT_MAN_WIDTH {sv2v_cast_1(operands_q[INT_WIDTH - 1] & ~op_mod_q)}};
					ifmt_input_val[(ifmt * INT_MAN_WIDTH) + (INT_WIDTH - 1)-:INT_WIDTH] = operands_q[INT_WIDTH - 1:0];
				end
			end
			else begin : inactive_format
				wire [INT_MAN_WIDTH * 1:1] sv2v_tmp_EDEE4;
				assign sv2v_tmp_EDEE4 = {INT_MAN_WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) ifmt_input_val[ifmt * INT_MAN_WIDTH+:INT_MAN_WIDTH] = sv2v_tmp_EDEE4;
			end
		end
	endgenerate
	assign int_value = ifmt_input_val[int_fmt_q * INT_MAN_WIDTH+:INT_MAN_WIDTH];
	assign int_sign = int_value[INT_MAN_WIDTH - 1] & ~op_mod_q;
	assign int_mantissa = (int_sign ? $unsigned(-int_value) : int_value);
	assign encoded_mant = (src_is_int ? int_mantissa : fmt_mantissa[src_fmt_q * INT_MAN_WIDTH+:INT_MAN_WIDTH]);
	wire signed [INT_EXP_WIDTH - 1:0] src_bias;
	wire signed [INT_EXP_WIDTH - 1:0] src_exp;
	wire signed [INT_EXP_WIDTH - 1:0] src_subnormal;
	wire signed [INT_EXP_WIDTH - 1:0] src_offset;
	function automatic [31:0] fpnew_pkg_bias;
		input reg [2:0] fmt;
		fpnew_pkg_bias = $unsigned((2 ** (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] - 1)) - 1);
	endfunction
	assign src_bias = $signed(fpnew_pkg_bias(src_fmt_q));
	assign src_exp = fmt_exponent[src_fmt_q * INT_EXP_WIDTH+:INT_EXP_WIDTH];
	assign src_subnormal = $signed({1'b0, info[(src_fmt_q * 8) + 6]});
	assign src_offset = fmt_shift_compensation[src_fmt_q * INT_EXP_WIDTH+:INT_EXP_WIDTH];
	wire input_sign;
	wire signed [INT_EXP_WIDTH - 1:0] input_exp;
	wire [INT_MAN_WIDTH - 1:0] input_mant;
	wire mant_is_zero;
	wire signed [INT_EXP_WIDTH - 1:0] fp_input_exp;
	wire signed [INT_EXP_WIDTH - 1:0] int_input_exp;
	wire [LZC_RESULT_WIDTH - 1:0] renorm_shamt;
	wire [LZC_RESULT_WIDTH:0] renorm_shamt_sgn;
	lzc #(
		.WIDTH(INT_MAN_WIDTH),
		.MODE(1)
	) i_lzc(
		.in_i(encoded_mant),
		.cnt_o(renorm_shamt),
		.empty_o(mant_is_zero)
	);
	assign renorm_shamt_sgn = $signed({1'b0, renorm_shamt});
	assign input_sign = (src_is_int ? int_sign : fmt_sign[src_fmt_q]);
	assign input_mant = encoded_mant << renorm_shamt;
	assign fp_input_exp = $signed((((src_exp + src_subnormal) - src_bias) - renorm_shamt_sgn) + src_offset);
	assign int_input_exp = $signed((INT_MAN_WIDTH - 1) - renorm_shamt_sgn);
	assign input_exp = (src_is_int ? int_input_exp : fp_input_exp);
	wire signed [INT_EXP_WIDTH - 1:0] destination_exp;
	assign destination_exp = input_exp + $signed(fpnew_pkg_bias(dst_fmt_q));
	wire input_sign_q;
	wire signed [INT_EXP_WIDTH - 1:0] input_exp_q;
	wire [INT_MAN_WIDTH - 1:0] input_mant_q;
	wire signed [INT_EXP_WIDTH - 1:0] destination_exp_q;
	wire src_is_int_q;
	wire dst_is_int_q;
	wire [7:0] info_q;
	wire mant_is_zero_q;
	wire op_mod_q2;
	wire [2:0] rnd_mode_q;
	wire [2:0] src_fmt_q2;
	wire [2:0] dst_fmt_q2;
	wire [1:0] int_fmt_q2;
	reg [0:NUM_MID_REGS] mid_pipe_input_sign_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * INT_EXP_WIDTH) + ((NUM_MID_REGS * INT_EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * INT_EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * INT_EXP_WIDTH : 0)] mid_pipe_input_exp_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * INT_MAN_WIDTH) + ((NUM_MID_REGS * INT_MAN_WIDTH) - 1) : ((NUM_MID_REGS + 1) * INT_MAN_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * INT_MAN_WIDTH : 0)] mid_pipe_input_mant_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * INT_EXP_WIDTH) + ((NUM_MID_REGS * INT_EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * INT_EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * INT_EXP_WIDTH : 0)] mid_pipe_dest_exp_q;
	reg [0:NUM_MID_REGS] mid_pipe_src_is_int_q;
	reg [0:NUM_MID_REGS] mid_pipe_dst_is_int_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 8) + ((NUM_MID_REGS * 8) - 1) : ((NUM_MID_REGS + 1) * 8) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 8 : 0)] mid_pipe_info_q;
	reg [0:NUM_MID_REGS] mid_pipe_mant_zero_q;
	reg [0:NUM_MID_REGS] mid_pipe_op_mod_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 3) + ((NUM_MID_REGS * 3) - 1) : ((NUM_MID_REGS + 1) * 3) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 3 : 0)] mid_pipe_rnd_mode_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_MID_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_MID_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] mid_pipe_src_fmt_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_MID_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_MID_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] mid_pipe_dst_fmt_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * fpnew_pkg_INT_FORMAT_BITS) + ((NUM_MID_REGS * fpnew_pkg_INT_FORMAT_BITS) - 1) : ((NUM_MID_REGS + 1) * fpnew_pkg_INT_FORMAT_BITS) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * fpnew_pkg_INT_FORMAT_BITS : 0)] mid_pipe_int_fmt_q;
	reg [0:NUM_MID_REGS] mid_pipe_tag_q;
	reg [0:NUM_MID_REGS] mid_pipe_mask_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * AuxType_AUX_BITS) + ((NUM_MID_REGS * AuxType_AUX_BITS) - 1) : ((NUM_MID_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * AuxType_AUX_BITS : 0)] mid_pipe_aux_q;
	reg [0:NUM_MID_REGS] mid_pipe_valid_q;
	wire [0:NUM_MID_REGS] mid_pipe_ready;
	wire [1:1] sv2v_tmp_F60A8;
	assign sv2v_tmp_F60A8 = input_sign;
	always @(*) mid_pipe_input_sign_q[0] = sv2v_tmp_F60A8;
	wire [INT_EXP_WIDTH * 1:1] sv2v_tmp_2635B;
	assign sv2v_tmp_2635B = input_exp;
	always @(*) mid_pipe_input_exp_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * INT_EXP_WIDTH+:INT_EXP_WIDTH] = sv2v_tmp_2635B;
	wire [INT_MAN_WIDTH * 1:1] sv2v_tmp_4E2E6;
	assign sv2v_tmp_4E2E6 = input_mant;
	always @(*) mid_pipe_input_mant_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * INT_MAN_WIDTH+:INT_MAN_WIDTH] = sv2v_tmp_4E2E6;
	wire [INT_EXP_WIDTH * 1:1] sv2v_tmp_5D87A;
	assign sv2v_tmp_5D87A = destination_exp;
	always @(*) mid_pipe_dest_exp_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * INT_EXP_WIDTH+:INT_EXP_WIDTH] = sv2v_tmp_5D87A;
	wire [1:1] sv2v_tmp_89756;
	assign sv2v_tmp_89756 = src_is_int;
	always @(*) mid_pipe_src_is_int_q[0] = sv2v_tmp_89756;
	wire [1:1] sv2v_tmp_AD70F;
	assign sv2v_tmp_AD70F = dst_is_int;
	always @(*) mid_pipe_dst_is_int_q[0] = sv2v_tmp_AD70F;
	wire [8:1] sv2v_tmp_6C4FE;
	assign sv2v_tmp_6C4FE = info[src_fmt_q * 8+:8];
	always @(*) mid_pipe_info_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 8+:8] = sv2v_tmp_6C4FE;
	wire [1:1] sv2v_tmp_5718C;
	assign sv2v_tmp_5718C = mant_is_zero;
	always @(*) mid_pipe_mant_zero_q[0] = sv2v_tmp_5718C;
	wire [1:1] sv2v_tmp_3B688;
	assign sv2v_tmp_3B688 = op_mod_q;
	always @(*) mid_pipe_op_mod_q[0] = sv2v_tmp_3B688;
	wire [3:1] sv2v_tmp_06BE2;
	assign sv2v_tmp_06BE2 = inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3];
	always @(*) mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 3+:3] = sv2v_tmp_06BE2;
	wire [3:1] sv2v_tmp_CBFB7;
	assign sv2v_tmp_CBFB7 = src_fmt_q;
	always @(*) mid_pipe_src_fmt_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_CBFB7;
	wire [3:1] sv2v_tmp_884B7;
	assign sv2v_tmp_884B7 = dst_fmt_q;
	always @(*) mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_884B7;
	wire [2:1] sv2v_tmp_A809A;
	assign sv2v_tmp_A809A = int_fmt_q;
	always @(*) mid_pipe_int_fmt_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] = sv2v_tmp_A809A;
	wire [1:1] sv2v_tmp_C9632;
	assign sv2v_tmp_C9632 = inp_pipe_tag_q[NUM_INP_REGS];
	always @(*) mid_pipe_tag_q[0] = sv2v_tmp_C9632;
	wire [1:1] sv2v_tmp_2E03C;
	assign sv2v_tmp_2E03C = inp_pipe_mask_q[NUM_INP_REGS];
	always @(*) mid_pipe_mask_q[0] = sv2v_tmp_2E03C;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_63481;
	assign sv2v_tmp_63481 = inp_pipe_aux_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	always @(*) mid_pipe_aux_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_63481;
	wire [1:1] sv2v_tmp_3D86F;
	assign sv2v_tmp_3D86F = inp_pipe_valid_q[NUM_INP_REGS];
	always @(*) mid_pipe_valid_q[0] = sv2v_tmp_3D86F;
	assign inp_pipe_ready[NUM_INP_REGS] = mid_pipe_ready[0];
	genvar _gv_i_38;
	generate
		for (_gv_i_38 = 0; _gv_i_38 < NUM_MID_REGS; _gv_i_38 = _gv_i_38 + 1) begin : gen_inside_pipeline
			localparam i = _gv_i_38;
			wire reg_ena;
			assign mid_pipe_ready[i] = mid_pipe_ready[i + 1] | ~mid_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_valid_q[i + 1] <= 1'b0;
				else
					mid_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (mid_pipe_ready[i] ? mid_pipe_valid_q[i] : mid_pipe_valid_q[i + 1]));
			assign reg_ena = (mid_pipe_ready[i] & mid_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_input_sign_q[i + 1] <= 1'sb0;
				else
					mid_pipe_input_sign_q[i + 1] <= (reg_ena ? mid_pipe_input_sign_q[i] : mid_pipe_input_sign_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_input_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_EXP_WIDTH+:INT_EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_input_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_EXP_WIDTH+:INT_EXP_WIDTH] <= (reg_ena ? mid_pipe_input_exp_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * INT_EXP_WIDTH+:INT_EXP_WIDTH] : mid_pipe_input_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_EXP_WIDTH+:INT_EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_input_mant_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_MAN_WIDTH+:INT_MAN_WIDTH] <= 1'sb0;
				else
					mid_pipe_input_mant_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_MAN_WIDTH+:INT_MAN_WIDTH] <= (reg_ena ? mid_pipe_input_mant_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * INT_MAN_WIDTH+:INT_MAN_WIDTH] : mid_pipe_input_mant_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_MAN_WIDTH+:INT_MAN_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_dest_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_EXP_WIDTH+:INT_EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_dest_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_EXP_WIDTH+:INT_EXP_WIDTH] <= (reg_ena ? mid_pipe_dest_exp_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * INT_EXP_WIDTH+:INT_EXP_WIDTH] : mid_pipe_dest_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * INT_EXP_WIDTH+:INT_EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_src_is_int_q[i + 1] <= 1'sb0;
				else
					mid_pipe_src_is_int_q[i + 1] <= (reg_ena ? mid_pipe_src_is_int_q[i] : mid_pipe_src_is_int_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_dst_is_int_q[i + 1] <= 1'sb0;
				else
					mid_pipe_dst_is_int_q[i + 1] <= (reg_ena ? mid_pipe_dst_is_int_q[i] : mid_pipe_dst_is_int_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_info_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 8+:8] <= 1'sb0;
				else
					mid_pipe_info_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 8+:8] <= (reg_ena ? mid_pipe_info_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 8+:8] : mid_pipe_info_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 8+:8]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_mant_zero_q[i + 1] <= 1'sb0;
				else
					mid_pipe_mant_zero_q[i + 1] <= (reg_ena ? mid_pipe_mant_zero_q[i] : mid_pipe_mant_zero_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_op_mod_q[i + 1] <= 1'sb0;
				else
					mid_pipe_op_mod_q[i + 1] <= (reg_ena ? mid_pipe_op_mod_q[i] : mid_pipe_op_mod_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= (reg_ena ? mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 3+:3] : mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_src_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					mid_pipe_src_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? mid_pipe_src_fmt_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : mid_pipe_src_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_int_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] <= sv2v_cast_2D3A8(0);
				else
					mid_pipe_int_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] <= (reg_ena ? mid_pipe_int_fmt_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS] : mid_pipe_int_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_tag_q[i + 1] <= 1'b0;
				else
					mid_pipe_tag_q[i + 1] <= (reg_ena ? mid_pipe_tag_q[i] : mid_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_mask_q[i + 1] <= 1'sb0;
				else
					mid_pipe_mask_q[i + 1] <= (reg_ena ? mid_pipe_mask_q[i] : mid_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign input_sign_q = mid_pipe_input_sign_q[NUM_MID_REGS];
	assign input_exp_q = mid_pipe_input_exp_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * INT_EXP_WIDTH+:INT_EXP_WIDTH];
	assign input_mant_q = mid_pipe_input_mant_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * INT_MAN_WIDTH+:INT_MAN_WIDTH];
	assign destination_exp_q = mid_pipe_dest_exp_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * INT_EXP_WIDTH+:INT_EXP_WIDTH];
	assign src_is_int_q = mid_pipe_src_is_int_q[NUM_MID_REGS];
	assign dst_is_int_q = mid_pipe_dst_is_int_q[NUM_MID_REGS];
	assign info_q = mid_pipe_info_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 8+:8];
	assign mant_is_zero_q = mid_pipe_mant_zero_q[NUM_MID_REGS];
	assign op_mod_q2 = mid_pipe_op_mod_q[NUM_MID_REGS];
	assign rnd_mode_q = mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 3+:3];
	assign src_fmt_q2 = mid_pipe_src_fmt_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	assign dst_fmt_q2 = mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	assign int_fmt_q2 = mid_pipe_int_fmt_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * fpnew_pkg_INT_FORMAT_BITS+:fpnew_pkg_INT_FORMAT_BITS];
	reg [INT_EXP_WIDTH - 1:0] final_exp;
	reg [2 * INT_MAN_WIDTH:0] preshift_mant;
	wire [2 * INT_MAN_WIDTH:0] destination_mant;
	wire [SUPER_MAN_BITS - 1:0] final_mant;
	wire [MAX_INT_WIDTH - 1:0] final_int;
	reg [$clog2(INT_MAN_WIDTH + 1) - 1:0] denorm_shamt;
	wire [1:0] fp_round_sticky_bits;
	wire [1:0] int_round_sticky_bits;
	wire [1:0] round_sticky_bits;
	reg of_before_round;
	reg uf_before_round;
	always @(*) begin : cast_value
		if (_sv2v_0)
			;
		final_exp = $unsigned(destination_exp_q);
		preshift_mant = 1'sb0;
		denorm_shamt = SUPER_MAN_BITS - fpnew_pkg_man_bits(dst_fmt_q2);
		of_before_round = 1'b0;
		uf_before_round = 1'b0;
		preshift_mant = input_mant_q << (INT_MAN_WIDTH + 1);
		if (dst_is_int_q) begin
			denorm_shamt = $unsigned((MAX_INT_WIDTH - 1) - input_exp_q);
			if ((input_exp_q >= $signed((fpnew_pkg_int_width(int_fmt_q2) - 1) + op_mod_q2)) && !(((!op_mod_q2 && input_sign_q) && (input_exp_q == $signed(fpnew_pkg_int_width(int_fmt_q2) - 1))) && (input_mant_q == {1'b1, {INT_MAN_WIDTH - 1 {1'b0}}}))) begin
				denorm_shamt = 1'sb0;
				of_before_round = 1'b1;
			end
			else if (input_exp_q < -1) begin
				denorm_shamt = MAX_INT_WIDTH + 1;
				uf_before_round = 1'b1;
			end
		end
		else if ((destination_exp_q >= ($signed(2 ** fpnew_pkg_exp_bits(dst_fmt_q2)) - 1)) || (~src_is_int_q && info_q[4])) begin
			final_exp = $unsigned((2 ** fpnew_pkg_exp_bits(dst_fmt_q2)) - 2);
			preshift_mant = 1'sb1;
			of_before_round = 1'b1;
		end
		else if ((destination_exp_q < 1) && (destination_exp_q >= -$signed(fpnew_pkg_man_bits(dst_fmt_q2)))) begin
			final_exp = 1'sb0;
			denorm_shamt = $unsigned((denorm_shamt + 1) - destination_exp_q);
			uf_before_round = 1'b1;
		end
		else if (destination_exp_q < -$signed(fpnew_pkg_man_bits(dst_fmt_q2))) begin
			final_exp = 1'sb0;
			denorm_shamt = $unsigned((denorm_shamt + 2) + fpnew_pkg_man_bits(dst_fmt_q2));
			uf_before_round = 1'b1;
		end
	end
	localparam NUM_FP_STICKY = ((2 * INT_MAN_WIDTH) - SUPER_MAN_BITS) - 1;
	localparam NUM_INT_STICKY = (2 * INT_MAN_WIDTH) - MAX_INT_WIDTH;
	assign destination_mant = preshift_mant >> denorm_shamt;
	assign {final_mant, fp_round_sticky_bits[1]} = destination_mant[(2 * INT_MAN_WIDTH) - 1-:SUPER_MAN_BITS + 1];
	assign {final_int, int_round_sticky_bits[1]} = destination_mant[2 * INT_MAN_WIDTH-:MAX_INT_WIDTH + 1];
	assign fp_round_sticky_bits[0] = |{destination_mant[NUM_FP_STICKY - 1:0]};
	assign int_round_sticky_bits[0] = |{destination_mant[NUM_INT_STICKY - 1:0]};
	assign round_sticky_bits = (dst_is_int_q ? int_round_sticky_bits : fp_round_sticky_bits);
	wire [WIDTH - 1:0] pre_round_abs;
	wire of_after_round;
	wire uf_after_round;
	reg [(NUM_FORMATS * WIDTH) - 1:0] fmt_pre_round_abs;
	reg [4:0] fmt_of_after_round;
	reg [4:0] fmt_uf_after_round;
	reg [(NUM_INT_FORMATS * WIDTH) - 1:0] ifmt_pre_round_abs;
	reg [3:0] ifmt_of_after_round;
	wire rounded_sign;
	wire [WIDTH - 1:0] rounded_abs;
	wire result_true_zero;
	wire [WIDTH - 1:0] rounded_int_res;
	wire rounded_int_res_zero;
	genvar _gv_fmt_2;
	generate
		for (_gv_fmt_2 = 0; _gv_fmt_2 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_2 = _gv_fmt_2 + 1) begin : gen_res_assemble
			localparam fmt = _gv_fmt_2;
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			if (FpFmtConfig[fmt]) begin : active_format
				always @(*) begin : assemble_result
					if (_sv2v_0)
						;
					fmt_pre_round_abs[fmt * WIDTH+:WIDTH] = {final_exp[EXP_BITS - 1:0], final_mant[MAN_BITS - 1:0]};
				end
			end
			else begin : inactive_format
				wire [WIDTH * 1:1] sv2v_tmp_B3A83;
				assign sv2v_tmp_B3A83 = {WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) fmt_pre_round_abs[fmt * WIDTH+:WIDTH] = sv2v_tmp_B3A83;
			end
		end
	endgenerate
	genvar _gv_ifmt_2;
	generate
		for (_gv_ifmt_2 = 0; _gv_ifmt_2 < sv2v_cast_32_signed(NUM_INT_FORMATS); _gv_ifmt_2 = _gv_ifmt_2 + 1) begin : gen_int_res_sign_ext
			localparam ifmt = _gv_ifmt_2;
			localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt));
			if (IntFmtConfig[ifmt]) begin : active_format
				always @(*) begin : assemble_result
					if (_sv2v_0)
						;
					ifmt_pre_round_abs[ifmt * WIDTH+:WIDTH] = {WIDTH {final_int[INT_WIDTH - 1]}};
					ifmt_pre_round_abs[(ifmt * WIDTH) + (INT_WIDTH - 1)-:INT_WIDTH] = final_int[INT_WIDTH - 1:0];
				end
			end
			else begin : inactive_format
				wire [WIDTH * 1:1] sv2v_tmp_E5CBE;
				assign sv2v_tmp_E5CBE = {WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) ifmt_pre_round_abs[ifmt * WIDTH+:WIDTH] = sv2v_tmp_E5CBE;
			end
		end
	endgenerate
	assign pre_round_abs = (dst_is_int_q ? ifmt_pre_round_abs[int_fmt_q2 * WIDTH+:WIDTH] : fmt_pre_round_abs[dst_fmt_q2 * WIDTH+:WIDTH]);
	fpnew_rounding #(.AbsWidth(WIDTH)) i_fpnew_rounding(
		.abs_value_i(pre_round_abs),
		.sign_i(input_sign_q),
		.round_sticky_bits_i(round_sticky_bits),
		.rnd_mode_i(rnd_mode_q),
		.effective_subtraction_i(1'b0),
		.abs_rounded_o(rounded_abs),
		.sign_o(rounded_sign),
		.exact_zero_o(result_true_zero)
	);
	reg [(NUM_FORMATS * WIDTH) - 1:0] fmt_result;
	genvar _gv_fmt_3;
	generate
		for (_gv_fmt_3 = 0; _gv_fmt_3 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_3 = _gv_fmt_3 + 1) begin : gen_sign_inject
			localparam fmt = _gv_fmt_3;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			if (FpFmtConfig[fmt]) begin : active_format
				always @(*) begin : post_process
					if (_sv2v_0)
						;
					fmt_uf_after_round[fmt] = rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb0}};
					fmt_of_after_round[fmt] = rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb1}};
					fmt_result[fmt * WIDTH+:WIDTH] = 1'sb1;
					fmt_result[(fmt * WIDTH) + (FP_WIDTH - 1)-:FP_WIDTH] = (src_is_int_q & mant_is_zero_q ? {FP_WIDTH * 1 {1'sb0}} : {rounded_sign, rounded_abs[(EXP_BITS + MAN_BITS) - 1:0]});
				end
			end
			else begin : inactive_format
				wire [1:1] sv2v_tmp_DD825;
				assign sv2v_tmp_DD825 = fpnew_pkg_DONT_CARE;
				always @(*) fmt_uf_after_round[fmt] = sv2v_tmp_DD825;
				wire [1:1] sv2v_tmp_358EF;
				assign sv2v_tmp_358EF = fpnew_pkg_DONT_CARE;
				always @(*) fmt_of_after_round[fmt] = sv2v_tmp_358EF;
				wire [WIDTH * 1:1] sv2v_tmp_542A8;
				assign sv2v_tmp_542A8 = {WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) fmt_result[fmt * WIDTH+:WIDTH] = sv2v_tmp_542A8;
			end
		end
	endgenerate
	assign rounded_int_res = (rounded_sign ? $unsigned(-rounded_abs) : rounded_abs);
	assign rounded_int_res_zero = rounded_int_res == {WIDTH {1'sb0}};
	genvar _gv_ifmt_3;
	generate
		for (_gv_ifmt_3 = 0; _gv_ifmt_3 < sv2v_cast_32_signed(NUM_INT_FORMATS); _gv_ifmt_3 = _gv_ifmt_3 + 1) begin : gen_int_overflow
			localparam ifmt = _gv_ifmt_3;
			localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt));
			if (IntFmtConfig[ifmt]) begin : active_format
				always @(*) begin : detect_overflow
					if (_sv2v_0)
						;
					ifmt_of_after_round[ifmt] = 1'b0;
					if (!rounded_sign && (input_exp_q == $signed((INT_WIDTH - 2) + op_mod_q2)))
						ifmt_of_after_round[ifmt] = ~rounded_int_res[(INT_WIDTH - 2) + op_mod_q2];
				end
			end
			else begin : inactive_format
				wire [1:1] sv2v_tmp_264CE;
				assign sv2v_tmp_264CE = fpnew_pkg_DONT_CARE;
				always @(*) ifmt_of_after_round[ifmt] = sv2v_tmp_264CE;
			end
		end
	endgenerate
	assign uf_after_round = fmt_uf_after_round[dst_fmt_q2];
	assign of_after_round = (dst_is_int_q ? ifmt_of_after_round[int_fmt_q2] : fmt_of_after_round[dst_fmt_q2]);
	wire [WIDTH - 1:0] fp_special_result;
	wire [4:0] fp_special_status;
	wire fp_result_is_special;
	reg [(NUM_FORMATS * WIDTH) - 1:0] fmt_special_result;
	genvar _gv_fmt_4;
	generate
		for (_gv_fmt_4 = 0; _gv_fmt_4 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_4 = _gv_fmt_4 + 1) begin : gen_special_results
			localparam fmt = _gv_fmt_4;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			localparam [EXP_BITS - 1:0] QNAN_EXPONENT = 1'sb1;
			localparam [MAN_BITS - 1:0] QNAN_MANTISSA = 2 ** (MAN_BITS - 1);
			if (FpFmtConfig[fmt]) begin : active_format
				always @(*) begin : special_results
					reg [FP_WIDTH - 1:0] special_res;
					if (_sv2v_0)
						;
					special_res = (info_q[5] ? input_sign_q << (FP_WIDTH - 1) : {1'b0, QNAN_EXPONENT, QNAN_MANTISSA});
					fmt_special_result[fmt * WIDTH+:WIDTH] = 1'sb1;
					fmt_special_result[(fmt * WIDTH) + (FP_WIDTH - 1)-:FP_WIDTH] = special_res;
				end
			end
			else begin : inactive_format
				wire [WIDTH * 1:1] sv2v_tmp_12E08;
				assign sv2v_tmp_12E08 = {WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) fmt_special_result[fmt * WIDTH+:WIDTH] = sv2v_tmp_12E08;
			end
		end
	endgenerate
	assign fp_result_is_special = ~src_is_int_q & ((info_q[5] | info_q[3]) | ~info_q[0]);
	assign fp_special_status = {info_q[2], 4'b0000};
	assign fp_special_result = fmt_special_result[dst_fmt_q2 * WIDTH+:WIDTH];
	wire [WIDTH - 1:0] int_special_result;
	wire [4:0] int_special_status;
	wire int_result_is_special;
	reg [(NUM_INT_FORMATS * WIDTH) - 1:0] ifmt_special_result;
	genvar _gv_ifmt_4;
	generate
		for (_gv_ifmt_4 = 0; _gv_ifmt_4 < sv2v_cast_32_signed(NUM_INT_FORMATS); _gv_ifmt_4 = _gv_ifmt_4 + 1) begin : gen_special_results_int
			localparam ifmt = _gv_ifmt_4;
			localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt));
			if (IntFmtConfig[ifmt]) begin : active_format
				always @(*) begin : special_results
					reg [INT_WIDTH - 1:0] special_res;
					if (_sv2v_0)
						;
					special_res[INT_WIDTH - 2:0] = 1'sb1;
					special_res[INT_WIDTH - 1] = op_mod_q2;
					if (input_sign_q && !info_q[3])
						special_res = ~special_res;
					ifmt_special_result[ifmt * WIDTH+:WIDTH] = {WIDTH {special_res[INT_WIDTH - 1]}};
					ifmt_special_result[(ifmt * WIDTH) + (INT_WIDTH - 1)-:INT_WIDTH] = special_res;
				end
			end
			else begin : inactive_format
				wire [WIDTH * 1:1] sv2v_tmp_B2A82;
				assign sv2v_tmp_B2A82 = {WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) ifmt_special_result[ifmt * WIDTH+:WIDTH] = sv2v_tmp_B2A82;
			end
		end
	endgenerate
	assign int_result_is_special = ((((info_q[3] | info_q[4]) | of_before_round) | of_after_round) | ~info_q[0]) | ((input_sign_q & op_mod_q2) & ~rounded_int_res_zero);
	assign int_special_status = 5'b10000;
	assign int_special_result = ifmt_special_result[int_fmt_q2 * WIDTH+:WIDTH];
	wire [4:0] int_regular_status;
	wire [4:0] fp_regular_status;
	wire [WIDTH - 1:0] fp_result;
	wire [WIDTH - 1:0] int_result;
	wire [4:0] fp_status;
	wire [4:0] int_status;
	assign fp_regular_status[4] = src_is_int_q & (of_before_round | of_after_round);
	assign fp_regular_status[3] = 1'b0;
	assign fp_regular_status[2] = ~src_is_int_q & (~info_q[4] & (of_before_round | of_after_round));
	assign fp_regular_status[1] = uf_after_round & fp_regular_status[0];
	assign fp_regular_status[0] = (src_is_int_q ? |fp_round_sticky_bits : |fp_round_sticky_bits | (~info_q[4] & (of_before_round | of_after_round)));
	assign int_regular_status = {4'b0000, |int_round_sticky_bits};
	assign fp_result = (fp_result_is_special ? fp_special_result : fmt_result[dst_fmt_q2 * WIDTH+:WIDTH]);
	assign fp_status = (fp_result_is_special ? fp_special_status : fp_regular_status);
	assign int_result = (int_result_is_special ? int_special_result : rounded_int_res);
	assign int_status = (int_result_is_special ? int_special_status : int_regular_status);
	wire [WIDTH - 1:0] result_d;
	wire [4:0] status_d;
	wire extension_bit;
	assign result_d = (dst_is_int_q ? int_result : fp_result);
	assign status_d = (dst_is_int_q ? int_status : fp_status);
	assign extension_bit = (dst_is_int_q ? int_result[WIDTH - 1] : 1'b1);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * WIDTH) + ((NUM_OUT_REGS * WIDTH) - 1) : ((NUM_OUT_REGS + 1) * WIDTH) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * WIDTH : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_ext_bit_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * AuxType_AUX_BITS) + ((NUM_OUT_REGS * AuxType_AUX_BITS) - 1) : ((NUM_OUT_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * AuxType_AUX_BITS : 0)] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [WIDTH * 1:1] sv2v_tmp_CEC39;
	assign sv2v_tmp_CEC39 = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * WIDTH+:WIDTH] = sv2v_tmp_CEC39;
	wire [5:1] sv2v_tmp_7F116;
	assign sv2v_tmp_7F116 = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_7F116;
	wire [1:1] sv2v_tmp_D2DFA;
	assign sv2v_tmp_D2DFA = extension_bit;
	always @(*) out_pipe_ext_bit_q[0] = sv2v_tmp_D2DFA;
	wire [1:1] sv2v_tmp_D3F91;
	assign sv2v_tmp_D3F91 = mid_pipe_tag_q[NUM_MID_REGS];
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_D3F91;
	wire [1:1] sv2v_tmp_F68B4;
	assign sv2v_tmp_F68B4 = mid_pipe_mask_q[NUM_MID_REGS];
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_F68B4;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_24F69;
	assign sv2v_tmp_24F69 = mid_pipe_aux_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	always @(*) out_pipe_aux_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_24F69;
	wire [1:1] sv2v_tmp_39CE2;
	assign sv2v_tmp_39CE2 = mid_pipe_valid_q[NUM_MID_REGS];
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_39CE2;
	assign mid_pipe_ready[NUM_MID_REGS] = out_pipe_ready[0];
	genvar _gv_i_39;
	generate
		for (_gv_i_39 = 0; _gv_i_39 < NUM_OUT_REGS; _gv_i_39 = _gv_i_39 + 1) begin : gen_output_pipeline
			localparam i = _gv_i_39;
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[(NUM_INP_REGS + NUM_MID_REGS) + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * WIDTH+:WIDTH] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_ext_bit_q[i + 1] <= 1'sb0;
				else
					out_pipe_ext_bit_q[i + 1] <= (reg_ena ? out_pipe_ext_bit_q[i] : out_pipe_ext_bit_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * WIDTH+:WIDTH];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = out_pipe_ext_bit_q[NUM_OUT_REGS];
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, mid_pipe_valid_q, out_pipe_valid_q};
	initial _sv2v_0 = 0;
endmodule
module fpnew_classifier (
	operands_i,
	is_boxed_i,
	info_o
);
	reg _sv2v_0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_9FB13(0);
	parameter [31:0] NumOperands = 1;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_fp_width(FpFormat);
	input wire [(NumOperands * WIDTH) - 1:0] operands_i;
	input wire [NumOperands - 1:0] is_boxed_i;
	output reg [(NumOperands * 8) - 1:0] info_o;
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(FpFormat);
	genvar _gv_op_1;
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (_gv_op_1 = 0; _gv_op_1 < sv2v_cast_32_signed(NumOperands); _gv_op_1 = _gv_op_1 + 1) begin : gen_num_values
			localparam op = _gv_op_1;
			reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] value;
			reg is_boxed;
			reg is_normal;
			reg is_inf;
			reg is_nan;
			reg is_signalling;
			reg is_quiet;
			reg is_zero;
			reg is_subnormal;
			always @(*) begin : classify_input
				if (_sv2v_0)
					;
				value = operands_i[op * WIDTH+:WIDTH];
				is_boxed = is_boxed_i[op];
				is_normal = (is_boxed && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] != {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb0}})) && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] != {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb1}});
				is_zero = (is_boxed && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb0}})) && (value[MAN_BITS - 1-:MAN_BITS] == {MAN_BITS * 1 {1'sb0}});
				is_subnormal = (is_boxed && (value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb0}})) && !is_zero;
				is_inf = is_boxed && ((value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb1}}) && (value[MAN_BITS - 1-:MAN_BITS] == {MAN_BITS * 1 {1'sb0}}));
				is_nan = !is_boxed || ((value[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)] == {((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1) * 1 {1'sb1}}) && (value[MAN_BITS - 1-:MAN_BITS] != {MAN_BITS * 1 {1'sb0}}));
				is_signalling = (is_boxed && is_nan) && (value[(MAN_BITS - 1) - ((MAN_BITS - 1) - (MAN_BITS - 1))] == 1'b0);
				is_quiet = is_nan && !is_signalling;
				info_o[(op * 8) + 7] = is_normal;
				info_o[(op * 8) + 6] = is_subnormal;
				info_o[(op * 8) + 5] = is_zero;
				info_o[(op * 8) + 4] = is_inf;
				info_o[(op * 8) + 3] = is_nan;
				info_o[(op * 8) + 2] = is_signalling;
				info_o[(op * 8) + 1] = is_quiet;
				info_o[op * 8] = is_boxed;
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module fpnew_divsqrt_multi_4A1A6_75781 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	dst_fmt_i,
	tag_i,
	mask_i,
	aux_i,
	vectorial_op_i,
	in_valid_i,
	in_ready_o,
	divsqrt_done_o,
	simd_synch_done_i,
	divsqrt_ready_o,
	simd_synch_rdy_i,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	parameter [31:0] AuxType_AUX_BITS = 0;
	reg _sv2v_0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	parameter [0:4] FpFmtConfig = 1'sb1;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd1;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_max_fp_width(FpFmtConfig);
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(2 * WIDTH) - 1:0] operands_i;
	input wire [9:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire [2:0] dst_fmt_i;
	input wire tag_i;
	input wire mask_i;
	input wire [AuxType_AUX_BITS - 1:0] aux_i;
	input wire vectorial_op_i;
	input wire in_valid_i;
	output wire in_ready_o;
	output wire divsqrt_done_o;
	input wire simd_synch_done_i;
	output wire divsqrt_ready_o;
	input wire simd_synch_rdy_i;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire mask_o;
	output wire [AuxType_AUX_BITS - 1:0] aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	localparam NUM_INP_REGS = (PipeConfig == 2'd0 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 2 : 0));
	localparam NUM_OUT_REGS = ((PipeConfig == 2'd1) || (PipeConfig == 2'd2) ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 2 : 0));
	wire [(2 * WIDTH) - 1:0] operands_q;
	wire [2:0] rnd_mode_q;
	wire [3:0] op_q;
	wire [2:0] dst_fmt_q;
	wire in_valid_q;
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * WIDTH) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * WIDTH) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * WIDTH : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * WIDTH)] inp_pipe_operands_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] inp_pipe_dst_fmt_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * AuxType_AUX_BITS) + ((NUM_INP_REGS * AuxType_AUX_BITS) - 1) : ((NUM_INP_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * AuxType_AUX_BITS : 0)] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_vec_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	wire [0:NUM_INP_REGS] inp_pipe_ready;
	wire [2 * WIDTH:1] sv2v_tmp_75CF9;
	assign sv2v_tmp_75CF9 = operands_i;
	always @(*) inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] = sv2v_tmp_75CF9;
	wire [3:1] sv2v_tmp_5C898;
	assign sv2v_tmp_5C898 = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_5C898;
	wire [4:1] sv2v_tmp_A50A8;
	assign sv2v_tmp_A50A8 = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_A50A8;
	wire [3:1] sv2v_tmp_A35AE;
	assign sv2v_tmp_A35AE = dst_fmt_i;
	always @(*) inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_A35AE;
	wire [1:1] sv2v_tmp_6A91A;
	assign sv2v_tmp_6A91A = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_6A91A;
	wire [1:1] sv2v_tmp_43EE3;
	assign sv2v_tmp_43EE3 = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_43EE3;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_329AB;
	assign sv2v_tmp_329AB = aux_i;
	always @(*) inp_pipe_aux_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_329AB;
	wire [1:1] sv2v_tmp_A731E;
	assign sv2v_tmp_A731E = vectorial_op_i;
	always @(*) inp_pipe_vec_op_q[0] = sv2v_tmp_A731E;
	wire [1:1] sv2v_tmp_9CFD6;
	assign sv2v_tmp_9CFD6 = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_9CFD6;
	assign in_ready_o = inp_pipe_ready[0];
	genvar _gv_i_40;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	function automatic [AuxType_AUX_BITS - 1:0] sv2v_cast_F912A;
		input reg [AuxType_AUX_BITS - 1:0] inp;
		sv2v_cast_F912A = inp;
	endfunction
	generate
		for (_gv_i_40 = 0; _gv_i_40 < NUM_INP_REGS; _gv_i_40 = _gv_i_40 + 1) begin : gen_input_pipeline
			localparam i = _gv_i_40;
			wire reg_ena;
			assign inp_pipe_ready[i] = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] <= 1'sb0;
				else
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] <= (reg_ena ? inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] : inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_7BCAE(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_vec_op_q[i + 1] <= sv2v_cast_F912A(1'sb0);
				else
					inp_pipe_vec_op_q[i + 1] <= (reg_ena ? inp_pipe_vec_op_q[i] : inp_pipe_vec_op_q[i + 1]);
		end
	endgenerate
	assign operands_q = inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2];
	assign rnd_mode_q = inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3];
	assign op_q = inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS];
	assign dst_fmt_q = inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	assign in_valid_q = inp_pipe_valid_q[NUM_INP_REGS];
	reg [1:0] divsqrt_fmt;
	reg [127:0] divsqrt_operands;
	reg input_is_fp8;
	always @(*) begin : translate_fmt
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (dst_fmt_q)
			sv2v_cast_9FB13('d0): divsqrt_fmt = 2'b00;
			sv2v_cast_9FB13('d1): divsqrt_fmt = 2'b01;
			sv2v_cast_9FB13('d2): divsqrt_fmt = 2'b10;
			sv2v_cast_9FB13('d4): divsqrt_fmt = 2'b11;
			default: divsqrt_fmt = 2'b10;
		endcase
		input_is_fp8 = FpFmtConfig[sv2v_cast_9FB13('d3)] & (dst_fmt_q == sv2v_cast_9FB13('d3));
		divsqrt_operands[0+:64] = (input_is_fp8 ? operands_q[0+:WIDTH] << 8 : operands_q[0+:WIDTH]);
		divsqrt_operands[64+:64] = (input_is_fp8 ? operands_q[WIDTH+:WIDTH] << 8 : operands_q[WIDTH+:WIDTH]);
	end
	reg in_ready;
	wire div_valid;
	wire sqrt_valid;
	wire unit_ready;
	wire unit_done;
	reg unit_done_q;
	wire op_starting;
	reg out_valid;
	wire out_ready;
	reg unit_busy;
	wire simd_synch_done;
	reg [1:0] state_q;
	reg [1:0] state_d;
	assign div_valid = ((in_valid_q & (op_q == sv2v_cast_7BCAE(4))) & in_ready) & ~flush_i;
	assign sqrt_valid = ((in_valid_q & (op_q != sv2v_cast_7BCAE(4))) & in_ready) & ~flush_i;
	assign op_starting = div_valid | sqrt_valid;
	reg result_is_fp8_q;
	reg result_tag_q;
	reg result_mask_q;
	reg [AuxType_AUX_BITS - 1:0] result_aux_q;
	reg result_vec_op_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_is_fp8_q <= 1'sb0;
		else
			result_is_fp8_q <= (op_starting ? input_is_fp8 : result_is_fp8_q);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_tag_q <= 1'sb0;
		else
			result_tag_q <= (op_starting ? inp_pipe_tag_q[NUM_INP_REGS] : result_tag_q);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_mask_q <= 1'sb0;
		else
			result_mask_q <= (op_starting ? inp_pipe_mask_q[NUM_INP_REGS] : result_mask_q);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_aux_q <= 1'sb0;
		else
			result_aux_q <= (op_starting ? inp_pipe_aux_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : result_aux_q);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_vec_op_q <= 1'sb0;
		else
			result_vec_op_q <= (op_starting ? inp_pipe_vec_op_q[NUM_INP_REGS] : result_vec_op_q);
	assign simd_synch_done = simd_synch_done_i || ~result_vec_op_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			unit_done_q <= 1'b0;
		else
			unit_done_q <= (simd_synch_done ? 1'b0 : (unit_done ? unit_done : unit_done_q));
	assign divsqrt_done_o = (unit_done_q | unit_done) & result_vec_op_q;
	assign divsqrt_ready_o = in_ready;
	assign inp_pipe_ready[NUM_INP_REGS] = (result_vec_op_q ? simd_synch_rdy_i : in_ready);
	always @(*) begin : flag_fsm
		if (_sv2v_0)
			;
		in_ready = 1'b0;
		out_valid = 1'b0;
		unit_busy = 1'b0;
		state_d = state_q;
		(* full_case, parallel_case *)
		case (state_q)
			2'd0: begin
				in_ready = 1'b1;
				if (in_valid_q && unit_ready)
					state_d = 2'd1;
			end
			2'd1: begin
				unit_busy = 1'b1;
				if (simd_synch_done_i || (~result_vec_op_q && unit_done)) begin
					out_valid = 1'b1;
					if (out_ready) begin
						state_d = 2'd0;
						in_ready = 1'b1;
						if (in_valid_q && unit_ready)
							state_d = 2'd1;
					end
					else
						state_d = 2'd2;
				end
			end
			2'd2: begin
				unit_busy = 1'b1;
				out_valid = 1'b1;
				if (out_ready) begin
					state_d = 2'd0;
					if (in_valid_q && unit_ready) begin
						in_ready = 1'b1;
						state_d = 2'd1;
					end
				end
			end
			default: state_d = 2'd0;
		endcase
		if (flush_i) begin
			unit_busy = 1'b0;
			out_valid = 1'b0;
			state_d = 2'd0;
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			state_q <= 2'd0;
		else
			state_q <= state_d;
	wire [63:0] unit_result;
	wire [WIDTH - 1:0] adjusted_result;
	reg [WIDTH - 1:0] held_result_q;
	wire [4:0] unit_status;
	reg [4:0] held_status_q;
	wire hold_en;
	div_sqrt_top_mvp i_divsqrt_lei(
		.Clk_CI(clk_i),
		.Rst_RBI(rst_ni),
		.Div_start_SI(div_valid),
		.Sqrt_start_SI(sqrt_valid),
		.Operand_a_DI(divsqrt_operands[0+:64]),
		.Operand_b_DI(divsqrt_operands[64+:64]),
		.RM_SI(rnd_mode_q),
		.Precision_ctl_SI(1'sb0),
		.Format_sel_SI(divsqrt_fmt),
		.Kill_SI(flush_i),
		.Result_DO(unit_result),
		.Fflags_SO(unit_status),
		.Ready_SO(unit_ready),
		.Done_SO(unit_done)
	);
	assign adjusted_result = (result_is_fp8_q ? unit_result >> 8 : unit_result);
	assign hold_en = (unit_done & (~simd_synch_done_i | ~out_ready)) & ~(~result_vec_op_q & out_ready);
	always @(posedge clk_i) held_result_q <= (hold_en ? adjusted_result : held_result_q);
	always @(posedge clk_i) held_status_q <= (hold_en ? unit_status : held_status_q);
	wire [WIDTH - 1:0] result_d;
	wire [4:0] status_d;
	assign result_d = (unit_done_q ? held_result_q : adjusted_result);
	assign status_d = (unit_done_q ? held_status_q : unit_status);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * WIDTH) + ((NUM_OUT_REGS * WIDTH) - 1) : ((NUM_OUT_REGS + 1) * WIDTH) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * WIDTH : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * AuxType_AUX_BITS) + ((NUM_OUT_REGS * AuxType_AUX_BITS) - 1) : ((NUM_OUT_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * AuxType_AUX_BITS : 0)] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [WIDTH * 1:1] sv2v_tmp_E3453;
	assign sv2v_tmp_E3453 = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * WIDTH+:WIDTH] = sv2v_tmp_E3453;
	wire [5:1] sv2v_tmp_B38F3;
	assign sv2v_tmp_B38F3 = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_B38F3;
	wire [1:1] sv2v_tmp_2AD04;
	assign sv2v_tmp_2AD04 = result_tag_q;
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_2AD04;
	wire [1:1] sv2v_tmp_1AD5F;
	assign sv2v_tmp_1AD5F = result_mask_q;
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_1AD5F;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_32529;
	assign sv2v_tmp_32529 = result_aux_q;
	always @(*) out_pipe_aux_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_32529;
	wire [1:1] sv2v_tmp_000CD;
	assign sv2v_tmp_000CD = out_valid;
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_000CD;
	assign out_ready = out_pipe_ready[0];
	genvar _gv_i_41;
	generate
		for (_gv_i_41 = 0; _gv_i_41 < NUM_OUT_REGS; _gv_i_41 = _gv_i_41 + 1) begin : gen_output_pipeline
			localparam i = _gv_i_41;
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * WIDTH+:WIDTH] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * WIDTH+:WIDTH];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = 1'b1;
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, unit_busy, out_pipe_valid_q};
	initial _sv2v_0 = 0;
endmodule
module fpnew_divsqrt_th_32_A4710_B4B7A (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	tag_i,
	mask_i,
	aux_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	parameter [31:0] AuxType_AUX_BITS = 0;
	reg _sv2v_0;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	localparam [31:0] WIDTH = 32;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [63:0] operands_i;
	input wire [9:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire tag_i;
	input wire mask_i;
	input wire [AuxType_AUX_BITS - 1:0] aux_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [31:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire mask_o;
	output wire [AuxType_AUX_BITS - 1:0] aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	localparam NUM_INP_REGS = (PipeConfig == 2'd0 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 2 : 0));
	localparam NUM_OUT_REGS = ((PipeConfig == 2'd1) || (PipeConfig == 2'd2) ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 2 : 0));
	wire [63:0] operands_q;
	wire [2:0] rnd_mode_q;
	wire [3:0] op_q;
	wire in_valid_q;
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0)) + 1) * 32) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * 32) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)) + 1) * 32) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * 32) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * 32 : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * 32)] inp_pipe_operands_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * AuxType_AUX_BITS) + ((NUM_INP_REGS * AuxType_AUX_BITS) - 1) : ((NUM_INP_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * AuxType_AUX_BITS : 0)] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	reg [0:NUM_INP_REGS] inp_pipe_ready;
	wire [64:1] sv2v_tmp_6F60A;
	assign sv2v_tmp_6F60A = operands_i;
	always @(*) inp_pipe_operands_q[32 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:64] = sv2v_tmp_6F60A;
	wire [3:1] sv2v_tmp_D397D;
	assign sv2v_tmp_D397D = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_D397D;
	wire [4:1] sv2v_tmp_C61AC;
	assign sv2v_tmp_C61AC = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_C61AC;
	wire [1:1] sv2v_tmp_6A91A;
	assign sv2v_tmp_6A91A = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_6A91A;
	wire [1:1] sv2v_tmp_43EE3;
	assign sv2v_tmp_43EE3 = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_43EE3;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_010F0;
	assign sv2v_tmp_010F0 = aux_i;
	always @(*) inp_pipe_aux_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_010F0;
	wire [1:1] sv2v_tmp_9CFD6;
	assign sv2v_tmp_9CFD6 = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_9CFD6;
	assign in_ready_o = inp_pipe_ready[0];
	genvar _gv_i_42;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	function automatic [AuxType_AUX_BITS - 1:0] sv2v_cast_F912A;
		input reg [AuxType_AUX_BITS - 1:0] inp;
		sv2v_cast_F912A = inp;
	endfunction
	generate
		for (_gv_i_42 = 0; _gv_i_42 < NUM_INP_REGS; _gv_i_42 = _gv_i_42 + 1) begin : gen_input_pipeline
			localparam i = _gv_i_42;
			wire reg_ena;
			wire [1:1] sv2v_tmp_BD88A;
			assign sv2v_tmp_BD88A = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(*) inp_pipe_ready[i] = sv2v_tmp_BD88A;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[32 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:64] <= 1'sb0;
				else
					inp_pipe_operands_q[32 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:64] <= (reg_ena ? inp_pipe_operands_q[32 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:64] : inp_pipe_operands_q[32 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:64]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_7BCAE(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign operands_q = inp_pipe_operands_q[32 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:64];
	assign rnd_mode_q = inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3];
	assign op_q = inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS];
	assign in_valid_q = inp_pipe_valid_q[NUM_INP_REGS];
	reg in_ready;
	wire div_op;
	wire sqrt_op;
	reg unit_ready_q;
	reg unit_done;
	wire op_starting;
	reg out_valid;
	wire out_ready;
	reg hold_result;
	reg data_is_held;
	reg unit_busy;
	reg [1:0] state_q;
	reg [1:0] state_d;
	assign div_op = ((in_valid_q & (op_q == sv2v_cast_7BCAE(4))) & in_ready) & ~flush_i;
	assign sqrt_op = ((in_valid_q & (op_q == sv2v_cast_7BCAE(5))) & in_ready) & ~flush_i;
	assign op_starting = div_op | sqrt_op;
	wire fdsu_fpu_ex1_stall;
	reg fdsu_fpu_ex1_stall_q;
	wire div_op_d;
	reg div_op_q;
	wire sqrt_op_d;
	reg sqrt_op_q;
	assign div_op_d = (fdsu_fpu_ex1_stall ? div_op : 1'b0);
	assign sqrt_op_d = (fdsu_fpu_ex1_stall ? sqrt_op : 1'b0);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			fdsu_fpu_ex1_stall_q <= 1'sb0;
		else
			fdsu_fpu_ex1_stall_q <= fdsu_fpu_ex1_stall;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			div_op_q <= 1'sb0;
		else
			div_op_q <= div_op_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			sqrt_op_q <= 1'sb0;
		else
			sqrt_op_q <= sqrt_op_d;
	always @(*) begin : flag_fsm
		if (_sv2v_0)
			;
		in_ready = 1'b0;
		out_valid = 1'b0;
		hold_result = 1'b0;
		data_is_held = 1'b0;
		unit_busy = 1'b0;
		state_d = state_q;
		inp_pipe_ready[NUM_INP_REGS] = unit_ready_q;
		(* full_case, parallel_case *)
		case (state_q)
			2'd0: begin
				in_ready = unit_ready_q;
				if (in_valid_q && unit_ready_q) begin
					inp_pipe_ready[NUM_INP_REGS] = unit_ready_q && !fdsu_fpu_ex1_stall;
					state_d = 2'd1;
				end
			end
			2'd1: begin
				inp_pipe_ready[NUM_INP_REGS] = fdsu_fpu_ex1_stall_q;
				unit_busy = 1'b1;
				if (unit_done) begin
					out_valid = 1'b1;
					if (out_ready) begin
						state_d = 2'd0;
						if (in_valid_q && unit_ready_q) begin
							in_ready = 1'b1;
							state_d = 2'd1;
						end
					end
					else begin
						hold_result = 1'b1;
						state_d = 2'd2;
					end
				end
			end
			2'd2: begin
				unit_busy = 1'b1;
				data_is_held = 1'b1;
				out_valid = 1'b1;
				if (out_ready) begin
					state_d = 2'd0;
					if (in_valid_q && unit_ready_q) begin
						in_ready = 1'b1;
						state_d = 2'd1;
					end
				end
			end
			default: state_d = 2'd0;
		endcase
		if (flush_i) begin
			unit_busy = 1'b0;
			out_valid = 1'b0;
			state_d = 2'd0;
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			state_q <= 2'd0;
		else
			state_q <= state_d;
	reg result_tag_q;
	reg [AuxType_AUX_BITS - 1:0] result_aux_q;
	reg result_mask_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_tag_q <= 1'sb0;
		else
			result_tag_q <= (op_starting ? inp_pipe_tag_q[NUM_INP_REGS] : result_tag_q);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_mask_q <= 1'sb0;
		else
			result_mask_q <= (op_starting ? inp_pipe_mask_q[NUM_INP_REGS] : result_mask_q);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			result_aux_q <= 1'sb0;
		else
			result_aux_q <= (op_starting ? inp_pipe_aux_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : result_aux_q);
	reg [31:0] unit_result;
	reg [31:0] held_result_q;
	reg [4:0] unit_status;
	reg [4:0] held_status_q;
	reg ctrl_fdsu_ex1_sel;
	wire fdsu_fpu_ex1_cmplt;
	wire [4:0] fdsu_fpu_ex1_fflags;
	wire [7:0] fdsu_fpu_ex1_special_sel;
	wire [3:0] fdsu_fpu_ex1_special_sign;
	wire fdsu_fpu_no_op;
	reg [2:0] idu_fpu_ex1_eu_sel;
	wire [31:0] fdsu_frbus_data;
	wire [4:0] fdsu_frbus_fflags;
	wire fdsu_frbus_wb_vld;
	wire [31:0] dp_frbus_ex2_data;
	wire [4:0] dp_frbus_ex2_fflags;
	wire [2:0] dp_xx_ex1_cnan;
	wire [2:0] dp_xx_ex1_id;
	wire [2:0] dp_xx_ex1_inf;
	wire [2:0] dp_xx_ex1_norm;
	wire [2:0] dp_xx_ex1_qnan;
	wire [2:0] dp_xx_ex1_snan;
	wire [2:0] dp_xx_ex1_zero;
	wire ex2_inst_wb;
	wire ex2_inst_wb_vld_d;
	reg ex2_inst_wb_vld_q;
	wire [31:0] fpu_idu_fwd_data;
	wire [4:0] fpu_idu_fwd_fflags;
	wire fpu_idu_fwd_vld;
	reg unit_ready_d;
	always @(*) begin
		if (_sv2v_0)
			;
		if (op_starting && unit_ready_q) begin
			if (ex2_inst_wb && ex2_inst_wb_vld_q)
				unit_ready_d = 1'b1;
			else
				unit_ready_d = 1'b0;
		end
		else if (fpu_idu_fwd_vld | flush_i)
			unit_ready_d = 1'b1;
		else
			unit_ready_d = unit_ready_q;
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			unit_ready_q <= 1'b1;
		else
			unit_ready_q <= unit_ready_d;
	always @(*) begin
		if (_sv2v_0)
			;
		ctrl_fdsu_ex1_sel = 1'b0;
		idu_fpu_ex1_eu_sel = 3'h0;
		if (op_starting) begin
			ctrl_fdsu_ex1_sel = 1'b1;
			idu_fpu_ex1_eu_sel = 3'h4;
		end
		else if (fdsu_fpu_ex1_stall_q) begin
			ctrl_fdsu_ex1_sel = 1'b1;
			idu_fpu_ex1_eu_sel = 3'h4;
		end
		else begin
			ctrl_fdsu_ex1_sel = 1'b0;
			idu_fpu_ex1_eu_sel = 3'h0;
		end
	end
	pa_fdsu_top i_divsqrt_thead(
		.cp0_fpu_icg_en(1'b0),
		.cp0_fpu_xx_dqnan(1'b0),
		.cp0_yy_clk_en(1'b1),
		.cpurst_b(rst_ni),
		.ctrl_fdsu_ex1_sel(ctrl_fdsu_ex1_sel),
		.ctrl_xx_ex1_cmplt_dp(ctrl_fdsu_ex1_sel),
		.ctrl_xx_ex1_inst_vld(ctrl_fdsu_ex1_sel),
		.ctrl_xx_ex1_stall(fdsu_fpu_ex1_stall),
		.ctrl_xx_ex1_warm_up(1'b0),
		.ctrl_xx_ex2_warm_up(1'b0),
		.ctrl_xx_ex3_warm_up(1'b0),
		.dp_xx_ex1_cnan(dp_xx_ex1_cnan),
		.dp_xx_ex1_id(dp_xx_ex1_id),
		.dp_xx_ex1_inf(dp_xx_ex1_inf),
		.dp_xx_ex1_qnan(dp_xx_ex1_qnan),
		.dp_xx_ex1_rm(rnd_mode_q),
		.dp_xx_ex1_snan(dp_xx_ex1_snan),
		.dp_xx_ex1_zero(dp_xx_ex1_zero),
		.fdsu_fpu_debug_info(),
		.fdsu_fpu_ex1_cmplt(fdsu_fpu_ex1_cmplt),
		.fdsu_fpu_ex1_cmplt_dp(),
		.fdsu_fpu_ex1_fflags(fdsu_fpu_ex1_fflags),
		.fdsu_fpu_ex1_special_sel(fdsu_fpu_ex1_special_sel),
		.fdsu_fpu_ex1_special_sign(fdsu_fpu_ex1_special_sign),
		.fdsu_fpu_ex1_stall(fdsu_fpu_ex1_stall),
		.fdsu_fpu_no_op(fdsu_fpu_no_op),
		.fdsu_frbus_data(fdsu_frbus_data),
		.fdsu_frbus_fflags(fdsu_frbus_fflags),
		.fdsu_frbus_freg(),
		.fdsu_frbus_wb_vld(fdsu_frbus_wb_vld),
		.forever_cpuclk(clk_i),
		.frbus_fdsu_wb_grant(fdsu_frbus_wb_vld),
		.idu_fpu_ex1_dst_freg(5'h0f),
		.idu_fpu_ex1_eu_sel(idu_fpu_ex1_eu_sel),
		.idu_fpu_ex1_func({8'b00000000, div_op | div_op_q, sqrt_op | sqrt_op_q}),
		.idu_fpu_ex1_srcf0(operands_q[31-:32]),
		.idu_fpu_ex1_srcf1(operands_q[63-:32]),
		.pad_yy_icg_scan_en(1'b0),
		.rtu_xx_ex1_cancel(1'b0),
		.rtu_xx_ex2_cancel(1'b0),
		.rtu_yy_xx_async_flush(flush_i),
		.rtu_yy_xx_flush(1'b0)
	);
	pa_fpu_dp x_pa_fpu_dp(
		.cp0_fpu_icg_en(1'b0),
		.cp0_fpu_xx_rm(rnd_mode_q),
		.cp0_yy_clk_en(1'b1),
		.ctrl_xx_ex1_inst_vld(ctrl_fdsu_ex1_sel),
		.ctrl_xx_ex1_stall(1'b0),
		.ctrl_xx_ex1_warm_up(1'b0),
		.dp_frbus_ex2_data(dp_frbus_ex2_data),
		.dp_frbus_ex2_fflags(dp_frbus_ex2_fflags),
		.dp_xx_ex1_cnan(dp_xx_ex1_cnan),
		.dp_xx_ex1_id(dp_xx_ex1_id),
		.dp_xx_ex1_inf(dp_xx_ex1_inf),
		.dp_xx_ex1_norm(dp_xx_ex1_norm),
		.dp_xx_ex1_qnan(dp_xx_ex1_qnan),
		.dp_xx_ex1_snan(dp_xx_ex1_snan),
		.dp_xx_ex1_zero(dp_xx_ex1_zero),
		.ex2_inst_wb(ex2_inst_wb),
		.fdsu_fpu_ex1_fflags(fdsu_fpu_ex1_fflags),
		.fdsu_fpu_ex1_special_sel(fdsu_fpu_ex1_special_sel),
		.fdsu_fpu_ex1_special_sign(fdsu_fpu_ex1_special_sign),
		.forever_cpuclk(clk_i),
		.idu_fpu_ex1_eu_sel(idu_fpu_ex1_eu_sel),
		.idu_fpu_ex1_func({8'b00000000, div_op, sqrt_op}),
		.idu_fpu_ex1_gateclk_vld(fdsu_fpu_ex1_cmplt),
		.idu_fpu_ex1_rm(rnd_mode_q),
		.idu_fpu_ex1_srcf0(operands_q[31-:32]),
		.idu_fpu_ex1_srcf1(operands_q[63-:32]),
		.idu_fpu_ex1_srcf2(1'sb0),
		.pad_yy_icg_scan_en(1'b0)
	);
	assign ex2_inst_wb_vld_d = ctrl_fdsu_ex1_sel;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			ex2_inst_wb_vld_q <= 1'sb0;
		else
			ex2_inst_wb_vld_q <= ex2_inst_wb_vld_d;
	pa_fpu_frbus x_pa_fpu_frbus(
		.ctrl_frbus_ex2_wb_req(ex2_inst_wb & ex2_inst_wb_vld_q),
		.dp_frbus_ex2_data(dp_frbus_ex2_data),
		.dp_frbus_ex2_fflags(dp_frbus_ex2_fflags),
		.fdsu_frbus_data(fdsu_frbus_data),
		.fdsu_frbus_fflags(fdsu_frbus_fflags),
		.fdsu_frbus_wb_vld(fdsu_frbus_wb_vld),
		.fpu_idu_fwd_data(fpu_idu_fwd_data),
		.fpu_idu_fwd_fflags(fpu_idu_fwd_fflags),
		.fpu_idu_fwd_vld(fpu_idu_fwd_vld)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		unit_result[31:0] = fpu_idu_fwd_data[31:0];
		unit_status[4:0] = fpu_idu_fwd_fflags[4:0];
		unit_done = fpu_idu_fwd_vld;
	end
	always @(posedge clk_i) held_result_q <= (hold_result ? unit_result : held_result_q);
	always @(posedge clk_i) held_status_q <= (hold_result ? unit_status : held_status_q);
	wire [31:0] result_d;
	wire [4:0] status_d;
	assign result_d = (data_is_held ? held_result_q : unit_result);
	assign status_d = (data_is_held ? held_status_q : unit_status);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * WIDTH) + ((NUM_OUT_REGS * WIDTH) - 1) : ((NUM_OUT_REGS + 1) * WIDTH) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * WIDTH : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * AuxType_AUX_BITS) + ((NUM_OUT_REGS * AuxType_AUX_BITS) - 1) : ((NUM_OUT_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * AuxType_AUX_BITS : 0)] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [32:1] sv2v_tmp_252A0;
	assign sv2v_tmp_252A0 = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * WIDTH+:WIDTH] = sv2v_tmp_252A0;
	wire [5:1] sv2v_tmp_C3491;
	assign sv2v_tmp_C3491 = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_C3491;
	wire [1:1] sv2v_tmp_2AD04;
	assign sv2v_tmp_2AD04 = result_tag_q;
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_2AD04;
	wire [1:1] sv2v_tmp_1AD5F;
	assign sv2v_tmp_1AD5F = result_mask_q;
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_1AD5F;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_B78E5;
	assign sv2v_tmp_B78E5 = result_aux_q;
	always @(*) out_pipe_aux_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_B78E5;
	wire [1:1] sv2v_tmp_000CD;
	assign sv2v_tmp_000CD = out_valid;
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_000CD;
	assign out_ready = out_pipe_ready[0];
	genvar _gv_i_43;
	generate
		for (_gv_i_43 = 0; _gv_i_43 < NUM_OUT_REGS; _gv_i_43 = _gv_i_43 + 1) begin : gen_output_pipeline
			localparam i = _gv_i_43;
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * WIDTH+:WIDTH] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * WIDTH+:WIDTH];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = 1'b1;
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, unit_busy, out_pipe_valid_q};
	initial _sv2v_0 = 0;
endmodule
module fpnew_fma_90763 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	tag_i,
	mask_i,
	aux_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	reg _sv2v_0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_9FB13(0);
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_fp_width(FpFormat);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(3 * WIDTH) - 1:0] operands_i;
	input wire [2:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire tag_i;
	input wire mask_i;
	input wire aux_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire mask_o;
	output wire aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_bias;
		input reg [2:0] fmt;
		fpnew_pkg_bias = $unsigned((2 ** (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] - 1)) - 1);
	endfunction
	localparam [31:0] BIAS = fpnew_pkg_bias(FpFormat);
	localparam [31:0] PRECISION_BITS = MAN_BITS + 1;
	localparam [31:0] LOWER_SUM_WIDTH = (2 * PRECISION_BITS) + 3;
	localparam [31:0] LZC_RESULT_WIDTH = $clog2(LOWER_SUM_WIDTH);
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	localparam [31:0] EXP_WIDTH = $unsigned(fpnew_pkg_maximum(EXP_BITS + 2, LZC_RESULT_WIDTH));
	localparam [31:0] SHIFT_AMOUNT_WIDTH = $clog2((3 * PRECISION_BITS) + 5);
	localparam NUM_INP_REGS = (PipeConfig == 2'd0 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 3 : 0));
	localparam NUM_MID_REGS = (PipeConfig == 2'd2 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 2) / 3 : 0));
	localparam NUM_OUT_REGS = (PipeConfig == 2'd1 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 3 : 0));
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) * WIDTH) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) * WIDTH) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) * WIDTH : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) * WIDTH)] inp_pipe_operands_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_is_boxed_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_op_mod_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [0:NUM_INP_REGS] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	wire [0:NUM_INP_REGS] inp_pipe_ready;
	wire [3 * WIDTH:1] sv2v_tmp_B135A;
	assign sv2v_tmp_B135A = operands_i;
	always @(*) inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] = sv2v_tmp_B135A;
	wire [3:1] sv2v_tmp_15896;
	assign sv2v_tmp_15896 = is_boxed_i;
	always @(*) inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_15896;
	wire [3:1] sv2v_tmp_26D09;
	assign sv2v_tmp_26D09 = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_26D09;
	wire [4:1] sv2v_tmp_F5BC4;
	assign sv2v_tmp_F5BC4 = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_F5BC4;
	wire [1:1] sv2v_tmp_42D74;
	assign sv2v_tmp_42D74 = op_mod_i;
	always @(*) inp_pipe_op_mod_q[0] = sv2v_tmp_42D74;
	wire [1:1] sv2v_tmp_6A91A;
	assign sv2v_tmp_6A91A = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_6A91A;
	wire [1:1] sv2v_tmp_43EE3;
	assign sv2v_tmp_43EE3 = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_43EE3;
	wire [1:1] sv2v_tmp_E1D93;
	assign sv2v_tmp_E1D93 = aux_i;
	always @(*) inp_pipe_aux_q[0] = sv2v_tmp_E1D93;
	wire [1:1] sv2v_tmp_9CFD6;
	assign sv2v_tmp_9CFD6 = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_9CFD6;
	assign in_ready_o = inp_pipe_ready[0];
	genvar _gv_i_44;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	generate
		for (_gv_i_44 = 0; _gv_i_44 < NUM_INP_REGS; _gv_i_44 = _gv_i_44 + 1) begin : gen_input_pipeline
			localparam i = _gv_i_44;
			wire reg_ena;
			assign inp_pipe_ready[i] = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] <= 1'sb0;
				else
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] <= (reg_ena ? inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] : inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 1'sb0;
				else
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_7BCAE(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_mod_q[i + 1] <= 1'sb0;
				else
					inp_pipe_op_mod_q[i + 1] <= (reg_ena ? inp_pipe_op_mod_q[i] : inp_pipe_op_mod_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[i + 1] <= 1'b0;
				else
					inp_pipe_aux_q[i + 1] <= (reg_ena ? inp_pipe_aux_q[i] : inp_pipe_aux_q[i + 1]);
		end
	endgenerate
	wire [23:0] info_q;
	fpnew_classifier #(
		.FpFormat(FpFormat),
		.NumOperands(3)
	) i_class_inputs(
		.operands_i(inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3]),
		.is_boxed_i(inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3]),
		.info_o(info_q)
	);
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_a;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_b;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_c;
	reg [7:0] info_a;
	reg [7:0] info_b;
	reg [7:0] info_c;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic [EXP_BITS - 1:0] sv2v_cast_DBE99;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_DBE99 = inp;
	endfunction
	function automatic [MAN_BITS - 1:0] sv2v_cast_AD1B9;
		input reg [MAN_BITS - 1:0] inp;
		sv2v_cast_AD1B9 = inp;
	endfunction
	function automatic [EXP_BITS - 1:0] sv2v_cast_E64C3;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_E64C3 = inp;
	endfunction
	function automatic [MAN_BITS - 1:0] sv2v_cast_33A5C;
		input reg [MAN_BITS - 1:0] inp;
		sv2v_cast_33A5C = inp;
	endfunction
	always @(*) begin : op_select
		if (_sv2v_0)
			;
		operand_a = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1))) * WIDTH+:WIDTH];
		operand_b = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 1 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - ((((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1))) * WIDTH+:WIDTH];
		operand_c = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - ((((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1))) * WIDTH+:WIDTH];
		info_a = info_q[0+:8];
		info_b = info_q[8+:8];
		info_c = info_q[16+:8];
		operand_c[1 + (EXP_BITS + (MAN_BITS - 1))] = operand_c[1 + (EXP_BITS + (MAN_BITS - 1))] ^ inp_pipe_op_mod_q[NUM_INP_REGS];
		(* full_case, parallel_case *)
		case (inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS])
			sv2v_cast_7BCAE(0):
				;
			sv2v_cast_7BCAE(1): operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] = ~operand_a[1 + (EXP_BITS + (MAN_BITS - 1))];
			sv2v_cast_7BCAE(2): begin
				operand_a = {1'b0, sv2v_cast_DBE99(BIAS), sv2v_cast_AD1B9(1'sb0)};
				info_a = 8'b10000001;
			end
			sv2v_cast_7BCAE(3): begin
				if (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3] == 3'b010)
					operand_c = {1'b0, sv2v_cast_E64C3(1'sb0), sv2v_cast_AD1B9(1'sb0)};
				else
					operand_c = {1'b1, sv2v_cast_E64C3(1'sb0), sv2v_cast_AD1B9(1'sb0)};
				info_c = 8'b00100001;
			end
			default: begin
				operand_a = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
				operand_b = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
				operand_c = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
				info_a = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				info_b = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				info_c = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
			end
		endcase
	end
	wire any_operand_inf;
	wire any_operand_nan;
	wire signalling_nan;
	wire effective_subtraction;
	wire tentative_sign;
	assign any_operand_inf = |{info_a[4], info_b[4], info_c[4]};
	assign any_operand_nan = |{info_a[3], info_b[3], info_c[3]};
	assign signalling_nan = |{info_a[2], info_b[2], info_c[2]};
	assign effective_subtraction = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ^ operand_b[1 + (EXP_BITS + (MAN_BITS - 1))]) ^ operand_c[1 + (EXP_BITS + (MAN_BITS - 1))];
	assign tentative_sign = operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ^ operand_b[1 + (EXP_BITS + (MAN_BITS - 1))];
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] special_result;
	reg [4:0] special_status;
	reg result_is_special;
	always @(*) begin : special_cases
		if (_sv2v_0)
			;
		special_result = {1'b0, sv2v_cast_E64C3(1'sb1), sv2v_cast_33A5C(2 ** (MAN_BITS - 1))};
		special_status = 1'sb0;
		result_is_special = 1'b0;
		if ((info_a[4] && info_b[5]) || (info_a[5] && info_b[4])) begin
			result_is_special = 1'b1;
			special_status[4] = 1'b1;
		end
		else if (any_operand_nan) begin
			result_is_special = 1'b1;
			special_status[4] = signalling_nan;
		end
		else if (any_operand_inf) begin
			result_is_special = 1'b1;
			if (((info_a[4] || info_b[4]) && info_c[4]) && effective_subtraction)
				special_status[4] = 1'b1;
			else if (info_a[4] || info_b[4])
				special_result = {operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ^ operand_b[1 + (EXP_BITS + (MAN_BITS - 1))], sv2v_cast_E64C3(1'sb1), sv2v_cast_AD1B9(1'sb0)};
			else if (info_c[4])
				special_result = {operand_c[1 + (EXP_BITS + (MAN_BITS - 1))], sv2v_cast_E64C3(1'sb1), sv2v_cast_AD1B9(1'sb0)};
		end
	end
	wire signed [EXP_WIDTH - 1:0] exponent_a;
	wire signed [EXP_WIDTH - 1:0] exponent_b;
	wire signed [EXP_WIDTH - 1:0] exponent_c;
	wire signed [EXP_WIDTH - 1:0] exponent_addend;
	wire signed [EXP_WIDTH - 1:0] exponent_product;
	wire signed [EXP_WIDTH - 1:0] exponent_difference;
	wire signed [EXP_WIDTH - 1:0] tentative_exponent;
	assign exponent_a = $signed({1'b0, operand_a[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)]});
	assign exponent_b = $signed({1'b0, operand_b[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)]});
	assign exponent_c = $signed({1'b0, operand_c[EXP_BITS + (MAN_BITS - 1)-:((EXP_BITS + (MAN_BITS - 1)) >= (MAN_BITS + 0) ? ((EXP_BITS + (MAN_BITS - 1)) - (MAN_BITS + 0)) + 1 : ((MAN_BITS + 0) - (EXP_BITS + (MAN_BITS - 1))) + 1)]});
	assign exponent_addend = $signed(exponent_c + $signed({1'b0, ~info_c[7]}));
	assign exponent_product = (info_a[5] || info_b[5] ? 2 - $signed(BIAS) : $signed((((exponent_a + info_a[6]) + exponent_b) + info_b[6]) - $signed(BIAS)));
	assign exponent_difference = exponent_addend - exponent_product;
	assign tentative_exponent = (exponent_difference > 0 ? exponent_addend : exponent_product);
	reg [SHIFT_AMOUNT_WIDTH - 1:0] addend_shamt;
	always @(*) begin : addend_shift_amount
		if (_sv2v_0)
			;
		if (exponent_difference <= $signed((-2 * PRECISION_BITS) - 1))
			addend_shamt = (3 * PRECISION_BITS) + 4;
		else if (exponent_difference <= $signed(PRECISION_BITS + 2))
			addend_shamt = $unsigned(($signed(PRECISION_BITS) + 3) - exponent_difference);
		else
			addend_shamt = 0;
	end
	wire [PRECISION_BITS - 1:0] mantissa_a;
	wire [PRECISION_BITS - 1:0] mantissa_b;
	wire [PRECISION_BITS - 1:0] mantissa_c;
	wire [(2 * PRECISION_BITS) - 1:0] product;
	wire [(3 * PRECISION_BITS) + 3:0] product_shifted;
	assign mantissa_a = {info_a[7], operand_a[MAN_BITS - 1-:MAN_BITS]};
	assign mantissa_b = {info_b[7], operand_b[MAN_BITS - 1-:MAN_BITS]};
	assign mantissa_c = {info_c[7], operand_c[MAN_BITS - 1-:MAN_BITS]};
	assign product = mantissa_a * mantissa_b;
	assign product_shifted = product << 2;
	wire [(3 * PRECISION_BITS) + 3:0] addend_after_shift;
	wire [PRECISION_BITS - 1:0] addend_sticky_bits;
	wire sticky_before_add;
	wire [(3 * PRECISION_BITS) + 3:0] addend_shifted;
	wire inject_carry_in;
	assign {addend_after_shift, addend_sticky_bits} = (mantissa_c << ((3 * PRECISION_BITS) + 4)) >> addend_shamt;
	assign sticky_before_add = |addend_sticky_bits;
	assign addend_shifted = (effective_subtraction ? ~addend_after_shift : addend_after_shift);
	assign inject_carry_in = effective_subtraction & ~sticky_before_add;
	wire [(3 * PRECISION_BITS) + 4:0] sum_raw;
	wire sum_carry;
	wire [(3 * PRECISION_BITS) + 3:0] sum;
	wire final_sign;
	assign sum_raw = (product_shifted + addend_shifted) + inject_carry_in;
	assign sum_carry = sum_raw[(3 * PRECISION_BITS) + 4];
	assign sum = (effective_subtraction && ~sum_carry ? -sum_raw : sum_raw);
	assign final_sign = (effective_subtraction && (sum_carry == tentative_sign) ? 1'b1 : (effective_subtraction ? 1'b0 : tentative_sign));
	wire effective_subtraction_q;
	wire signed [EXP_WIDTH - 1:0] exponent_product_q;
	wire signed [EXP_WIDTH - 1:0] exponent_difference_q;
	wire signed [EXP_WIDTH - 1:0] tentative_exponent_q;
	wire [SHIFT_AMOUNT_WIDTH - 1:0] addend_shamt_q;
	wire sticky_before_add_q;
	wire [(3 * PRECISION_BITS) + 3:0] sum_q;
	wire final_sign_q;
	wire [2:0] rnd_mode_q;
	wire result_is_special_q;
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] special_result_q;
	wire [4:0] special_status_q;
	reg [0:NUM_MID_REGS] mid_pipe_eff_sub_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_exp_prod_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_exp_diff_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_tent_exp_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH) + ((NUM_MID_REGS * SHIFT_AMOUNT_WIDTH) - 1) : ((NUM_MID_REGS + 1) * SHIFT_AMOUNT_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * SHIFT_AMOUNT_WIDTH : 0)] mid_pipe_add_shamt_q;
	reg [0:NUM_MID_REGS] mid_pipe_sticky_q;
	reg [(0 >= NUM_MID_REGS ? (((3 * PRECISION_BITS) + 3) >= 0 ? ((1 - NUM_MID_REGS) * ((3 * PRECISION_BITS) + 4)) + ((NUM_MID_REGS * ((3 * PRECISION_BITS) + 4)) - 1) : ((1 - NUM_MID_REGS) * (1 - ((3 * PRECISION_BITS) + 3))) + ((((3 * PRECISION_BITS) + 3) + (NUM_MID_REGS * (1 - ((3 * PRECISION_BITS) + 3)))) - 1)) : (((3 * PRECISION_BITS) + 3) >= 0 ? ((NUM_MID_REGS + 1) * ((3 * PRECISION_BITS) + 4)) - 1 : ((NUM_MID_REGS + 1) * (1 - ((3 * PRECISION_BITS) + 3))) + ((3 * PRECISION_BITS) + 2))):(0 >= NUM_MID_REGS ? (((3 * PRECISION_BITS) + 3) >= 0 ? NUM_MID_REGS * ((3 * PRECISION_BITS) + 4) : ((3 * PRECISION_BITS) + 3) + (NUM_MID_REGS * (1 - ((3 * PRECISION_BITS) + 3)))) : (((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3))] mid_pipe_sum_q;
	reg [0:NUM_MID_REGS] mid_pipe_final_sign_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 3) + ((NUM_MID_REGS * 3) - 1) : ((NUM_MID_REGS + 1) * 3) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 3 : 0)] mid_pipe_rnd_mode_q;
	reg [0:NUM_MID_REGS] mid_pipe_res_is_spec_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * ((1 + EXP_BITS) + MAN_BITS)) + ((NUM_MID_REGS * ((1 + EXP_BITS) + MAN_BITS)) - 1) : ((NUM_MID_REGS + 1) * ((1 + EXP_BITS) + MAN_BITS)) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * ((1 + EXP_BITS) + MAN_BITS) : 0)] mid_pipe_spec_res_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 5) + ((NUM_MID_REGS * 5) - 1) : ((NUM_MID_REGS + 1) * 5) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 5 : 0)] mid_pipe_spec_stat_q;
	reg [0:NUM_MID_REGS] mid_pipe_tag_q;
	reg [0:NUM_MID_REGS] mid_pipe_mask_q;
	reg [0:NUM_MID_REGS] mid_pipe_aux_q;
	reg [0:NUM_MID_REGS] mid_pipe_valid_q;
	wire [0:NUM_MID_REGS] mid_pipe_ready;
	wire [1:1] sv2v_tmp_72F3C;
	assign sv2v_tmp_72F3C = effective_subtraction;
	always @(*) mid_pipe_eff_sub_q[0] = sv2v_tmp_72F3C;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_51634;
	assign sv2v_tmp_51634 = exponent_product;
	always @(*) mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_51634;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_7826E;
	assign sv2v_tmp_7826E = exponent_difference;
	always @(*) mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_7826E;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_BEF1B;
	assign sv2v_tmp_BEF1B = tentative_exponent;
	always @(*) mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_BEF1B;
	wire [SHIFT_AMOUNT_WIDTH * 1:1] sv2v_tmp_BA51C;
	assign sv2v_tmp_BA51C = addend_shamt;
	always @(*) mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] = sv2v_tmp_BA51C;
	wire [1:1] sv2v_tmp_D9513;
	assign sv2v_tmp_D9513 = sticky_before_add;
	always @(*) mid_pipe_sticky_q[0] = sv2v_tmp_D9513;
	wire [(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)) * 1:1] sv2v_tmp_6102F;
	assign sv2v_tmp_6102F = sum;
	always @(*) mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] = sv2v_tmp_6102F;
	wire [1:1] sv2v_tmp_E5D4B;
	assign sv2v_tmp_E5D4B = final_sign;
	always @(*) mid_pipe_final_sign_q[0] = sv2v_tmp_E5D4B;
	wire [3:1] sv2v_tmp_D5331;
	assign sv2v_tmp_D5331 = inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3];
	always @(*) mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 3+:3] = sv2v_tmp_D5331;
	wire [1:1] sv2v_tmp_7E156;
	assign sv2v_tmp_7E156 = result_is_special;
	always @(*) mid_pipe_res_is_spec_q[0] = sv2v_tmp_7E156;
	wire [((1 + EXP_BITS) + MAN_BITS) * 1:1] sv2v_tmp_45CEC;
	assign sv2v_tmp_45CEC = special_result;
	always @(*) mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] = sv2v_tmp_45CEC;
	wire [5:1] sv2v_tmp_06630;
	assign sv2v_tmp_06630 = special_status;
	always @(*) mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 5+:5] = sv2v_tmp_06630;
	wire [1:1] sv2v_tmp_C9632;
	assign sv2v_tmp_C9632 = inp_pipe_tag_q[NUM_INP_REGS];
	always @(*) mid_pipe_tag_q[0] = sv2v_tmp_C9632;
	wire [1:1] sv2v_tmp_2E03C;
	assign sv2v_tmp_2E03C = inp_pipe_mask_q[NUM_INP_REGS];
	always @(*) mid_pipe_mask_q[0] = sv2v_tmp_2E03C;
	wire [1:1] sv2v_tmp_769AB;
	assign sv2v_tmp_769AB = inp_pipe_aux_q[NUM_INP_REGS];
	always @(*) mid_pipe_aux_q[0] = sv2v_tmp_769AB;
	wire [1:1] sv2v_tmp_3D86F;
	assign sv2v_tmp_3D86F = inp_pipe_valid_q[NUM_INP_REGS];
	always @(*) mid_pipe_valid_q[0] = sv2v_tmp_3D86F;
	assign inp_pipe_ready[NUM_INP_REGS] = mid_pipe_ready[0];
	genvar _gv_i_45;
	generate
		for (_gv_i_45 = 0; _gv_i_45 < NUM_MID_REGS; _gv_i_45 = _gv_i_45 + 1) begin : gen_inside_pipeline
			localparam i = _gv_i_45;
			wire reg_ena;
			assign mid_pipe_ready[i] = mid_pipe_ready[i + 1] | ~mid_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_valid_q[i + 1] <= 1'b0;
				else
					mid_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (mid_pipe_ready[i] ? mid_pipe_valid_q[i] : mid_pipe_valid_q[i + 1]));
			assign reg_ena = (mid_pipe_ready[i] & mid_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_eff_sub_q[i + 1] <= 1'sb0;
				else
					mid_pipe_eff_sub_q[i + 1] <= (reg_ena ? mid_pipe_eff_sub_q[i] : mid_pipe_eff_sub_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] <= 1'sb0;
				else
					mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] <= (reg_ena ? mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] : mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_sticky_q[i + 1] <= 1'sb0;
				else
					mid_pipe_sticky_q[i + 1] <= (reg_ena ? mid_pipe_sticky_q[i] : mid_pipe_sticky_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] <= 1'sb0;
				else
					mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] <= (reg_ena ? mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] : mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_final_sign_q[i + 1] <= 1'sb0;
				else
					mid_pipe_final_sign_q[i + 1] <= (reg_ena ? mid_pipe_final_sign_q[i] : mid_pipe_final_sign_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= (reg_ena ? mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 3+:3] : mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_res_is_spec_q[i + 1] <= 1'sb0;
				else
					mid_pipe_res_is_spec_q[i + 1] <= (reg_ena ? mid_pipe_res_is_spec_q[i] : mid_pipe_res_is_spec_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= 1'sb0;
				else
					mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= (reg_ena ? mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] : mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5] <= (reg_ena ? mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 5+:5] : mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_tag_q[i + 1] <= 1'b0;
				else
					mid_pipe_tag_q[i + 1] <= (reg_ena ? mid_pipe_tag_q[i] : mid_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_mask_q[i + 1] <= 1'sb0;
				else
					mid_pipe_mask_q[i + 1] <= (reg_ena ? mid_pipe_mask_q[i] : mid_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_aux_q[i + 1] <= 1'b0;
				else
					mid_pipe_aux_q[i + 1] <= (reg_ena ? mid_pipe_aux_q[i] : mid_pipe_aux_q[i + 1]);
		end
	endgenerate
	assign effective_subtraction_q = mid_pipe_eff_sub_q[NUM_MID_REGS];
	assign exponent_product_q = mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign exponent_difference_q = mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign tentative_exponent_q = mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign addend_shamt_q = mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH];
	assign sticky_before_add_q = mid_pipe_sticky_q[NUM_MID_REGS];
	assign sum_q = mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))];
	assign final_sign_q = mid_pipe_final_sign_q[NUM_MID_REGS];
	assign rnd_mode_q = mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 3+:3];
	assign result_is_special_q = mid_pipe_res_is_spec_q[NUM_MID_REGS];
	assign special_result_q = mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS];
	assign special_status_q = mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 5+:5];
	wire [LOWER_SUM_WIDTH - 1:0] sum_lower;
	wire [LZC_RESULT_WIDTH - 1:0] leading_zero_count;
	wire signed [LZC_RESULT_WIDTH:0] leading_zero_count_sgn;
	wire lzc_zeroes;
	reg [SHIFT_AMOUNT_WIDTH - 1:0] norm_shamt;
	reg signed [EXP_WIDTH - 1:0] normalized_exponent;
	wire [(3 * PRECISION_BITS) + 4:0] sum_shifted;
	reg [PRECISION_BITS:0] final_mantissa;
	reg [(2 * PRECISION_BITS) + 2:0] sum_sticky_bits;
	wire sticky_after_norm;
	reg signed [EXP_WIDTH - 1:0] final_exponent;
	assign sum_lower = sum_q[LOWER_SUM_WIDTH - 1:0];
	lzc #(
		.WIDTH(LOWER_SUM_WIDTH),
		.MODE(1)
	) i_lzc(
		.in_i(sum_lower),
		.cnt_o(leading_zero_count),
		.empty_o(lzc_zeroes)
	);
	assign leading_zero_count_sgn = $signed({1'b0, leading_zero_count});
	always @(*) begin : norm_shift_amount
		if (_sv2v_0)
			;
		if ((exponent_difference_q <= 0) || (effective_subtraction_q && (exponent_difference_q <= 2))) begin
			if ((((exponent_product_q - leading_zero_count_sgn) + 1) >= 0) && !lzc_zeroes) begin
				norm_shamt = (PRECISION_BITS + 2) + leading_zero_count;
				normalized_exponent = (exponent_product_q - leading_zero_count_sgn) + 1;
			end
			else begin
				norm_shamt = $unsigned(($signed(PRECISION_BITS) + 2) + exponent_product_q);
				normalized_exponent = 0;
			end
		end
		else begin
			norm_shamt = addend_shamt_q;
			normalized_exponent = tentative_exponent_q;
		end
	end
	assign sum_shifted = sum_q << norm_shamt;
	always @(*) begin : small_norm
		if (_sv2v_0)
			;
		{final_mantissa, sum_sticky_bits} = sum_shifted;
		final_exponent = normalized_exponent;
		if (sum_shifted[(3 * PRECISION_BITS) + 4]) begin
			{final_mantissa, sum_sticky_bits} = sum_shifted >> 1;
			final_exponent = normalized_exponent + 1;
		end
		else if (sum_shifted[(3 * PRECISION_BITS) + 3])
			;
		else if (normalized_exponent > 1) begin
			{final_mantissa, sum_sticky_bits} = sum_shifted << 1;
			final_exponent = normalized_exponent - 1;
		end
		else
			final_exponent = 1'sb0;
	end
	assign sticky_after_norm = |{sum_sticky_bits} | sticky_before_add_q;
	wire pre_round_sign;
	wire [EXP_BITS - 1:0] pre_round_exponent;
	wire [MAN_BITS - 1:0] pre_round_mantissa;
	wire [(EXP_BITS + MAN_BITS) - 1:0] pre_round_abs;
	wire [1:0] round_sticky_bits;
	wire of_before_round;
	wire of_after_round;
	wire uf_before_round;
	wire uf_after_round;
	wire result_zero;
	wire rounded_sign;
	wire [(EXP_BITS + MAN_BITS) - 1:0] rounded_abs;
	assign of_before_round = final_exponent >= ((2 ** EXP_BITS) - 1);
	assign uf_before_round = final_exponent == 0;
	assign pre_round_sign = final_sign_q;
	assign pre_round_exponent = (of_before_round ? (2 ** EXP_BITS) - 2 : $unsigned(final_exponent[EXP_BITS - 1:0]));
	assign pre_round_mantissa = (of_before_round ? {MAN_BITS {1'sb1}} : final_mantissa[MAN_BITS:1]);
	assign pre_round_abs = {pre_round_exponent, pre_round_mantissa};
	assign round_sticky_bits = (of_before_round ? 2'b11 : {final_mantissa[0], sticky_after_norm});
	fpnew_rounding #(.AbsWidth(EXP_BITS + MAN_BITS)) i_fpnew_rounding(
		.abs_value_i(pre_round_abs),
		.sign_i(pre_round_sign),
		.round_sticky_bits_i(round_sticky_bits),
		.rnd_mode_i(rnd_mode_q),
		.effective_subtraction_i(effective_subtraction_q),
		.abs_rounded_o(rounded_abs),
		.sign_o(rounded_sign),
		.exact_zero_o(result_zero)
	);
	assign uf_after_round = (rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb0}}) || (((pre_round_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb0}}) && (rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == 1)) && ((round_sticky_bits != 2'b11) || (!sum_sticky_bits[(MAN_BITS * 2) + 4] && ((rnd_mode_i == 3'b000) || (rnd_mode_i == 3'b100)))));
	assign of_after_round = rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb1}};
	wire [WIDTH - 1:0] regular_result;
	wire [4:0] regular_status;
	assign regular_result = {rounded_sign, rounded_abs};
	assign regular_status[4] = 1'b0;
	assign regular_status[3] = 1'b0;
	assign regular_status[2] = of_before_round | of_after_round;
	assign regular_status[1] = uf_after_round & regular_status[0];
	assign regular_status[0] = (|round_sticky_bits | of_before_round) | of_after_round;
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] result_d;
	wire [4:0] status_d;
	assign result_d = (result_is_special_q ? special_result_q : regular_result);
	assign status_d = (result_is_special_q ? special_status_q : regular_status);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)) + ((NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS)) - 1) : ((NUM_OUT_REGS + 1) * ((1 + EXP_BITS) + MAN_BITS)) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS) : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [0:NUM_OUT_REGS] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [((1 + EXP_BITS) + MAN_BITS) * 1:1] sv2v_tmp_93831;
	assign sv2v_tmp_93831 = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] = sv2v_tmp_93831;
	wire [5:1] sv2v_tmp_C58FF;
	assign sv2v_tmp_C58FF = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_C58FF;
	wire [1:1] sv2v_tmp_D3F91;
	assign sv2v_tmp_D3F91 = mid_pipe_tag_q[NUM_MID_REGS];
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_D3F91;
	wire [1:1] sv2v_tmp_F68B4;
	assign sv2v_tmp_F68B4 = mid_pipe_mask_q[NUM_MID_REGS];
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_F68B4;
	wire [1:1] sv2v_tmp_F447E;
	assign sv2v_tmp_F447E = mid_pipe_aux_q[NUM_MID_REGS];
	always @(*) out_pipe_aux_q[0] = sv2v_tmp_F447E;
	wire [1:1] sv2v_tmp_39CE2;
	assign sv2v_tmp_39CE2 = mid_pipe_valid_q[NUM_MID_REGS];
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_39CE2;
	assign mid_pipe_ready[NUM_MID_REGS] = out_pipe_ready[0];
	genvar _gv_i_46;
	generate
		for (_gv_i_46 = 0; _gv_i_46 < NUM_OUT_REGS; _gv_i_46 = _gv_i_46 + 1) begin : gen_output_pipeline
			localparam i = _gv_i_46;
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[(NUM_INP_REGS + NUM_MID_REGS) + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[i + 1] <= 1'b0;
				else
					out_pipe_aux_q[i + 1] <= (reg_ena ? out_pipe_aux_q[i] : out_pipe_aux_q[i + 1]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = 1'b1;
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[NUM_OUT_REGS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, mid_pipe_valid_q, out_pipe_valid_q};
	initial _sv2v_0 = 0;
endmodule
module fpnew_fma_multi_CA122_A2E8D (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	tag_i,
	mask_i,
	aux_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	parameter [31:0] AuxType_AUX_BITS = 0;
	reg _sv2v_0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	parameter [0:4] FpFmtConfig = 1'sb1;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_max_fp_width(FpFmtConfig);
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(3 * WIDTH) - 1:0] operands_i;
	input wire [14:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	input wire tag_i;
	input wire mask_i;
	input wire [AuxType_AUX_BITS - 1:0] aux_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire mask_o;
	output wire [AuxType_AUX_BITS - 1:0] aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	function automatic [63:0] fpnew_pkg_super_format;
		input reg [0:4] cfg;
		reg [63:0] res;
		begin
			res = 1'sb0;
			begin : sv2v_autoblock_2
				reg [31:0] fmt;
				for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
					if (cfg[fmt]) begin
						res[63-:32] = $unsigned(fpnew_pkg_maximum(res[63-:32], fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt))));
						res[31-:32] = $unsigned(fpnew_pkg_maximum(res[31-:32], fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt))));
					end
			end
			fpnew_pkg_super_format = res;
		end
	endfunction
	localparam [63:0] SUPER_FORMAT = fpnew_pkg_super_format(FpFmtConfig);
	localparam [31:0] SUPER_EXP_BITS = SUPER_FORMAT[63-:32];
	localparam [31:0] SUPER_MAN_BITS = SUPER_FORMAT[31-:32];
	localparam [31:0] PRECISION_BITS = SUPER_MAN_BITS + 1;
	localparam [31:0] LOWER_SUM_WIDTH = (2 * PRECISION_BITS) + 3;
	localparam [31:0] LZC_RESULT_WIDTH = $clog2(LOWER_SUM_WIDTH);
	localparam [31:0] EXP_WIDTH = fpnew_pkg_maximum(SUPER_EXP_BITS + 2, LZC_RESULT_WIDTH);
	localparam [31:0] SHIFT_AMOUNT_WIDTH = $clog2((3 * PRECISION_BITS) + 5);
	localparam NUM_INP_REGS = (PipeConfig == 2'd0 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 3 : 0));
	localparam NUM_MID_REGS = (PipeConfig == 2'd2 ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 2) / 3 : 0));
	localparam NUM_OUT_REGS = (PipeConfig == 2'd1 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 3 : 0));
	wire [(3 * WIDTH) - 1:0] operands_q;
	wire [2:0] src_fmt_q;
	wire [2:0] dst_fmt_q;
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) * WIDTH) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) * WIDTH) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) * WIDTH : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) * WIDTH)] inp_pipe_operands_q;
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0)) + 1) * 3) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) * 3) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1)) + 1) * 3) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) * 3) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) * 3 : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) * 3)] inp_pipe_is_boxed_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_op_mod_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] inp_pipe_src_fmt_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] inp_pipe_dst_fmt_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * AuxType_AUX_BITS) + ((NUM_INP_REGS * AuxType_AUX_BITS) - 1) : ((NUM_INP_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * AuxType_AUX_BITS : 0)] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	wire [0:NUM_INP_REGS] inp_pipe_ready;
	wire [3 * WIDTH:1] sv2v_tmp_65236;
	assign sv2v_tmp_65236 = operands_i;
	always @(*) inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] = sv2v_tmp_65236;
	wire [15:1] sv2v_tmp_03F0C;
	assign sv2v_tmp_03F0C = is_boxed_i;
	always @(*) inp_pipe_is_boxed_q[3 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * NUM_FORMATS) + 4) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * NUM_FORMATS) + 4) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1)))+:15] = sv2v_tmp_03F0C;
	wire [3:1] sv2v_tmp_E41A9;
	assign sv2v_tmp_E41A9 = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_E41A9;
	wire [4:1] sv2v_tmp_AA02B;
	assign sv2v_tmp_AA02B = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_AA02B;
	wire [1:1] sv2v_tmp_42D74;
	assign sv2v_tmp_42D74 = op_mod_i;
	always @(*) inp_pipe_op_mod_q[0] = sv2v_tmp_42D74;
	wire [3:1] sv2v_tmp_DA568;
	assign sv2v_tmp_DA568 = src_fmt_i;
	always @(*) inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_DA568;
	wire [3:1] sv2v_tmp_70747;
	assign sv2v_tmp_70747 = dst_fmt_i;
	always @(*) inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_70747;
	wire [1:1] sv2v_tmp_6A91A;
	assign sv2v_tmp_6A91A = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_6A91A;
	wire [1:1] sv2v_tmp_43EE3;
	assign sv2v_tmp_43EE3 = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_43EE3;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_B7273;
	assign sv2v_tmp_B7273 = aux_i;
	always @(*) inp_pipe_aux_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_B7273;
	wire [1:1] sv2v_tmp_9CFD6;
	assign sv2v_tmp_9CFD6 = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_9CFD6;
	assign in_ready_o = inp_pipe_ready[0];
	genvar _gv_i_47;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	function automatic [AuxType_AUX_BITS - 1:0] sv2v_cast_F912A;
		input reg [AuxType_AUX_BITS - 1:0] inp;
		sv2v_cast_F912A = inp;
	endfunction
	generate
		for (_gv_i_47 = 0; _gv_i_47 < NUM_INP_REGS; _gv_i_47 = _gv_i_47 + 1) begin : gen_input_pipeline
			localparam i = _gv_i_47;
			wire reg_ena;
			assign inp_pipe_ready[i] = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] <= 1'sb0;
				else
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] <= (reg_ena ? inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3] : inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_is_boxed_q[3 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS) + 4) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS) + 4) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1)))+:15] <= 1'sb0;
				else
					inp_pipe_is_boxed_q[3 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS) + 4) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS) + 4) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1)))+:15] <= (reg_ena ? inp_pipe_is_boxed_q[3 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * NUM_FORMATS) + 4) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * NUM_FORMATS) + 4) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1)))+:15] : inp_pipe_is_boxed_q[3 * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS) + 4) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * NUM_FORMATS) + 4) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1)))+:15]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_7BCAE(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_mod_q[i + 1] <= 1'sb0;
				else
					inp_pipe_op_mod_q[i + 1] <= (reg_ena ? inp_pipe_op_mod_q[i] : inp_pipe_op_mod_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : inp_pipe_aux_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign operands_q = inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3) + 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1)))+:WIDTH * 3];
	assign src_fmt_q = inp_pipe_src_fmt_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	assign dst_fmt_q = inp_pipe_dst_fmt_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	wire [14:0] fmt_sign;
	wire signed [(15 * SUPER_EXP_BITS) - 1:0] fmt_exponent;
	wire [(15 * SUPER_MAN_BITS) - 1:0] fmt_mantissa;
	wire [119:0] info_q;
	genvar _gv_fmt_5;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic [7:0] sv2v_cast_8;
		input reg [7:0] inp;
		sv2v_cast_8 = inp;
	endfunction
	function automatic signed [SUPER_EXP_BITS - 1:0] sv2v_cast_C9DEC_signed;
		input reg signed [SUPER_EXP_BITS - 1:0] inp;
		sv2v_cast_C9DEC_signed = inp;
	endfunction
	function automatic [SUPER_MAN_BITS - 1:0] sv2v_cast_75D45;
		input reg [SUPER_MAN_BITS - 1:0] inp;
		sv2v_cast_75D45 = inp;
	endfunction
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (_gv_fmt_5 = 0; _gv_fmt_5 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_5 = _gv_fmt_5 + 1) begin : fmt_init_inputs
			localparam fmt = _gv_fmt_5;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			if (FpFmtConfig[fmt]) begin : active_format
				wire [(3 * FP_WIDTH) - 1:0] trimmed_ops;
				fpnew_classifier #(
					.FpFormat(sv2v_cast_9FB13(fmt)),
					.NumOperands(3)
				) i_fpnew_classifier(
					.operands_i(trimmed_ops),
					.is_boxed_i(inp_pipe_is_boxed_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) ? ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * NUM_FORMATS) + fmt : (0 >= NUM_INP_REGS ? NUM_INP_REGS * NUM_FORMATS : 0) - ((((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * NUM_FORMATS) + fmt) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * NUM_FORMATS) + ((NUM_INP_REGS * NUM_FORMATS) - 1) : ((NUM_INP_REGS + 1) * NUM_FORMATS) - 1))) * 3+:3]),
					.info_o(info_q[8 * (fmt * 3)+:24])
				);
				genvar _gv_op_2;
				for (_gv_op_2 = 0; _gv_op_2 < 3; _gv_op_2 = _gv_op_2 + 1) begin : gen_operands
					localparam op = _gv_op_2;
					assign trimmed_ops[op * fpnew_pkg_fp_width(sv2v_cast_9FB13(_gv_fmt_5))+:fpnew_pkg_fp_width(sv2v_cast_9FB13(_gv_fmt_5))] = operands_q[(op * WIDTH) + (FP_WIDTH - 1)-:FP_WIDTH];
					assign fmt_sign[(fmt * 3) + op] = operands_q[(op * WIDTH) + (FP_WIDTH - 1)];
					assign fmt_exponent[((fmt * 3) + op) * SUPER_EXP_BITS+:SUPER_EXP_BITS] = $signed({1'b0, operands_q[(op * WIDTH) + MAN_BITS+:EXP_BITS]});
					assign fmt_mantissa[((fmt * 3) + op) * SUPER_MAN_BITS+:SUPER_MAN_BITS] = {info_q[(((fmt * 3) + op) * 8) + 7], operands_q[(op * WIDTH) + (MAN_BITS - 1)-:MAN_BITS]} << (SUPER_MAN_BITS - MAN_BITS);
				end
			end
			else begin : inactive_format
				assign info_q[8 * (fmt * 3)+:24] = {3 {sv2v_cast_8(fpnew_pkg_DONT_CARE)}};
				assign fmt_sign[fmt * 3+:3] = fpnew_pkg_DONT_CARE;
				assign fmt_exponent[SUPER_EXP_BITS * (fmt * 3)+:SUPER_EXP_BITS * 3] = {3 {sv2v_cast_C9DEC_signed(fpnew_pkg_DONT_CARE)}};
				assign fmt_mantissa[SUPER_MAN_BITS * (fmt * 3)+:SUPER_MAN_BITS * 3] = {3 {sv2v_cast_75D45(fpnew_pkg_DONT_CARE)}};
			end
		end
	endgenerate
	reg [((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS) - 1:0] operand_a;
	reg [((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS) - 1:0] operand_b;
	reg [((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS) - 1:0] operand_c;
	reg [7:0] info_a;
	reg [7:0] info_b;
	reg [7:0] info_c;
	function automatic [31:0] fpnew_pkg_bias;
		input reg [2:0] fmt;
		fpnew_pkg_bias = $unsigned((2 ** (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] - 1)) - 1);
	endfunction
	function automatic [SUPER_EXP_BITS - 1:0] sv2v_cast_C9DEC;
		input reg [SUPER_EXP_BITS - 1:0] inp;
		sv2v_cast_C9DEC = inp;
	endfunction
	function automatic [SUPER_MAN_BITS - 1:0] sv2v_cast_4DDC9;
		input reg [SUPER_MAN_BITS - 1:0] inp;
		sv2v_cast_4DDC9 = inp;
	endfunction
	function automatic [SUPER_EXP_BITS - 1:0] sv2v_cast_8433E;
		input reg [SUPER_EXP_BITS - 1:0] inp;
		sv2v_cast_8433E = inp;
	endfunction
	always @(*) begin : op_select
		if (_sv2v_0)
			;
		operand_a = {fmt_sign[src_fmt_q * 3], fmt_exponent[(src_fmt_q * 3) * SUPER_EXP_BITS+:SUPER_EXP_BITS], fmt_mantissa[(src_fmt_q * 3) * SUPER_MAN_BITS+:SUPER_MAN_BITS]};
		operand_b = {fmt_sign[(src_fmt_q * 3) + 1], fmt_exponent[((src_fmt_q * 3) + 1) * SUPER_EXP_BITS+:SUPER_EXP_BITS], fmt_mantissa[((src_fmt_q * 3) + 1) * SUPER_MAN_BITS+:SUPER_MAN_BITS]};
		operand_c = {fmt_sign[(dst_fmt_q * 3) + 2], fmt_exponent[((dst_fmt_q * 3) + 2) * SUPER_EXP_BITS+:SUPER_EXP_BITS], fmt_mantissa[((dst_fmt_q * 3) + 2) * SUPER_MAN_BITS+:SUPER_MAN_BITS]};
		info_a = info_q[(src_fmt_q * 3) * 8+:8];
		info_b = info_q[((src_fmt_q * 3) + 1) * 8+:8];
		info_c = info_q[((dst_fmt_q * 3) + 2) * 8+:8];
		operand_c[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))] = operand_c[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))] ^ inp_pipe_op_mod_q[NUM_INP_REGS];
		(* full_case, parallel_case *)
		case (inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS])
			sv2v_cast_7BCAE(0):
				;
			sv2v_cast_7BCAE(1): operand_a[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))] = ~operand_a[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))];
			sv2v_cast_7BCAE(2): begin
				operand_a = {1'b0, sv2v_cast_C9DEC(fpnew_pkg_bias(src_fmt_q)), sv2v_cast_4DDC9(1'sb0)};
				info_a = 8'b10000001;
			end
			sv2v_cast_7BCAE(3): begin
				if (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3] == 3'b010)
					operand_c = {1'b0, sv2v_cast_8433E(1'sb0), sv2v_cast_4DDC9(1'sb0)};
				else
					operand_c = {1'b1, sv2v_cast_8433E(1'sb0), sv2v_cast_4DDC9(1'sb0)};
				info_c = 8'b00100001;
			end
			default: begin
				operand_a = {fpnew_pkg_DONT_CARE, sv2v_cast_C9DEC(fpnew_pkg_DONT_CARE), sv2v_cast_75D45(fpnew_pkg_DONT_CARE)};
				operand_b = {fpnew_pkg_DONT_CARE, sv2v_cast_C9DEC(fpnew_pkg_DONT_CARE), sv2v_cast_75D45(fpnew_pkg_DONT_CARE)};
				operand_c = {fpnew_pkg_DONT_CARE, sv2v_cast_C9DEC(fpnew_pkg_DONT_CARE), sv2v_cast_75D45(fpnew_pkg_DONT_CARE)};
				info_a = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				info_b = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				info_c = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
			end
		endcase
	end
	wire any_operand_inf;
	wire any_operand_nan;
	wire signalling_nan;
	wire effective_subtraction;
	wire tentative_sign;
	assign any_operand_inf = |{info_a[4], info_b[4], info_c[4]};
	assign any_operand_nan = |{info_a[3], info_b[3], info_c[3]};
	assign signalling_nan = |{info_a[2], info_b[2], info_c[2]};
	assign effective_subtraction = (operand_a[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))] ^ operand_b[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))]) ^ operand_c[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))];
	assign tentative_sign = operand_a[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))] ^ operand_b[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))];
	wire [WIDTH - 1:0] special_result;
	wire [4:0] special_status;
	wire result_is_special;
	reg [(NUM_FORMATS * WIDTH) - 1:0] fmt_special_result;
	reg [24:0] fmt_special_status;
	reg [4:0] fmt_result_is_special;
	genvar _gv_fmt_6;
	generate
		for (_gv_fmt_6 = 0; _gv_fmt_6 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_6 = _gv_fmt_6 + 1) begin : gen_special_results
			localparam fmt = _gv_fmt_6;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			localparam [EXP_BITS - 1:0] QNAN_EXPONENT = 1'sb1;
			localparam [MAN_BITS - 1:0] QNAN_MANTISSA = 2 ** (MAN_BITS - 1);
			localparam [MAN_BITS - 1:0] ZERO_MANTISSA = 1'sb0;
			if (FpFmtConfig[fmt]) begin : active_format
				always @(*) begin : special_results
					reg [FP_WIDTH - 1:0] special_res;
					if (_sv2v_0)
						;
					special_res = {1'b0, QNAN_EXPONENT, QNAN_MANTISSA};
					fmt_special_status[fmt * 5+:5] = 1'sb0;
					fmt_result_is_special[fmt] = 1'b0;
					if ((info_a[4] && info_b[5]) || (info_a[5] && info_b[4])) begin
						fmt_result_is_special[fmt] = 1'b1;
						fmt_special_status[(fmt * 5) + 4] = 1'b1;
					end
					else if (any_operand_nan) begin
						fmt_result_is_special[fmt] = 1'b1;
						fmt_special_status[(fmt * 5) + 4] = signalling_nan;
					end
					else if (any_operand_inf) begin
						fmt_result_is_special[fmt] = 1'b1;
						if (((info_a[4] || info_b[4]) && info_c[4]) && effective_subtraction)
							fmt_special_status[(fmt * 5) + 4] = 1'b1;
						else if (info_a[4] || info_b[4])
							special_res = {operand_a[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))] ^ operand_b[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))], QNAN_EXPONENT, ZERO_MANTISSA};
						else if (info_c[4])
							special_res = {operand_c[1 + (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))], QNAN_EXPONENT, ZERO_MANTISSA};
					end
					fmt_special_result[fmt * WIDTH+:WIDTH] = 1'sb1;
					fmt_special_result[(fmt * WIDTH) + (FP_WIDTH - 1)-:FP_WIDTH] = special_res;
				end
			end
			else begin : inactive_format
				wire [WIDTH * 1:1] sv2v_tmp_948B8;
				assign sv2v_tmp_948B8 = {WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) fmt_special_result[fmt * WIDTH+:WIDTH] = sv2v_tmp_948B8;
				wire [5:1] sv2v_tmp_0DB31;
				assign sv2v_tmp_0DB31 = 1'sb0;
				always @(*) fmt_special_status[fmt * 5+:5] = sv2v_tmp_0DB31;
				wire [1:1] sv2v_tmp_6249C;
				assign sv2v_tmp_6249C = 1'b0;
				always @(*) fmt_result_is_special[fmt] = sv2v_tmp_6249C;
			end
		end
	endgenerate
	assign result_is_special = fmt_result_is_special[dst_fmt_q];
	assign special_status = fmt_special_status[dst_fmt_q * 5+:5];
	assign special_result = fmt_special_result[dst_fmt_q * WIDTH+:WIDTH];
	wire signed [EXP_WIDTH - 1:0] exponent_a;
	wire signed [EXP_WIDTH - 1:0] exponent_b;
	wire signed [EXP_WIDTH - 1:0] exponent_c;
	wire signed [EXP_WIDTH - 1:0] exponent_addend;
	wire signed [EXP_WIDTH - 1:0] exponent_product;
	wire signed [EXP_WIDTH - 1:0] exponent_difference;
	wire signed [EXP_WIDTH - 1:0] tentative_exponent;
	assign exponent_a = $signed({1'b0, operand_a[SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)-:((SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)) >= (SUPER_MAN_BITS + 0) ? ((SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)) - (SUPER_MAN_BITS + 0)) + 1 : ((SUPER_MAN_BITS + 0) - (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))) + 1)]});
	assign exponent_b = $signed({1'b0, operand_b[SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)-:((SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)) >= (SUPER_MAN_BITS + 0) ? ((SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)) - (SUPER_MAN_BITS + 0)) + 1 : ((SUPER_MAN_BITS + 0) - (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))) + 1)]});
	assign exponent_c = $signed({1'b0, operand_c[SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)-:((SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)) >= (SUPER_MAN_BITS + 0) ? ((SUPER_EXP_BITS + (SUPER_MAN_BITS - 1)) - (SUPER_MAN_BITS + 0)) + 1 : ((SUPER_MAN_BITS + 0) - (SUPER_EXP_BITS + (SUPER_MAN_BITS - 1))) + 1)]});
	assign exponent_addend = $signed(exponent_c + $signed({1'b0, ~info_c[7]}));
	assign exponent_product = (info_a[5] || info_b[5] ? 2 - $signed(fpnew_pkg_bias(dst_fmt_q)) : $signed(((((exponent_a + info_a[6]) + exponent_b) + info_b[6]) - (2 * $signed(fpnew_pkg_bias(src_fmt_q)))) + $signed(fpnew_pkg_bias(dst_fmt_q))));
	assign exponent_difference = exponent_addend - exponent_product;
	assign tentative_exponent = (exponent_difference > 0 ? exponent_addend : exponent_product);
	reg [SHIFT_AMOUNT_WIDTH - 1:0] addend_shamt;
	always @(*) begin : addend_shift_amount
		if (_sv2v_0)
			;
		if (exponent_difference <= $signed((-2 * PRECISION_BITS) - 1))
			addend_shamt = (3 * PRECISION_BITS) + 4;
		else if (exponent_difference <= $signed(PRECISION_BITS + 2))
			addend_shamt = $unsigned(($signed(PRECISION_BITS) + 3) - exponent_difference);
		else
			addend_shamt = 0;
	end
	wire [PRECISION_BITS - 1:0] mantissa_a;
	wire [PRECISION_BITS - 1:0] mantissa_b;
	wire [PRECISION_BITS - 1:0] mantissa_c;
	wire [(2 * PRECISION_BITS) - 1:0] product;
	wire [(3 * PRECISION_BITS) + 3:0] product_shifted;
	assign mantissa_a = {info_a[7], operand_a[SUPER_MAN_BITS - 1-:SUPER_MAN_BITS]};
	assign mantissa_b = {info_b[7], operand_b[SUPER_MAN_BITS - 1-:SUPER_MAN_BITS]};
	assign mantissa_c = {info_c[7], operand_c[SUPER_MAN_BITS - 1-:SUPER_MAN_BITS]};
	assign product = mantissa_a * mantissa_b;
	assign product_shifted = product << 2;
	wire [(3 * PRECISION_BITS) + 3:0] addend_after_shift;
	wire [PRECISION_BITS - 1:0] addend_sticky_bits;
	wire sticky_before_add;
	wire [(3 * PRECISION_BITS) + 3:0] addend_shifted;
	wire inject_carry_in;
	assign {addend_after_shift, addend_sticky_bits} = (mantissa_c << ((3 * PRECISION_BITS) + 4)) >> addend_shamt;
	assign sticky_before_add = |addend_sticky_bits;
	assign addend_shifted = (effective_subtraction ? ~addend_after_shift : addend_after_shift);
	assign inject_carry_in = effective_subtraction & ~sticky_before_add;
	wire [(3 * PRECISION_BITS) + 4:0] sum_raw;
	wire sum_carry;
	wire [(3 * PRECISION_BITS) + 3:0] sum;
	wire final_sign;
	assign sum_raw = (product_shifted + addend_shifted) + inject_carry_in;
	assign sum_carry = sum_raw[(3 * PRECISION_BITS) + 4];
	assign sum = (effective_subtraction && ~sum_carry ? -sum_raw : sum_raw);
	assign final_sign = (effective_subtraction && (sum_carry == tentative_sign) ? 1'b1 : (effective_subtraction ? 1'b0 : tentative_sign));
	wire effective_subtraction_q;
	wire signed [EXP_WIDTH - 1:0] exponent_product_q;
	wire signed [EXP_WIDTH - 1:0] exponent_difference_q;
	wire signed [EXP_WIDTH - 1:0] tentative_exponent_q;
	wire [SHIFT_AMOUNT_WIDTH - 1:0] addend_shamt_q;
	wire sticky_before_add_q;
	wire [(3 * PRECISION_BITS) + 3:0] sum_q;
	wire final_sign_q;
	wire [2:0] dst_fmt_q2;
	wire [2:0] rnd_mode_q;
	wire result_is_special_q;
	wire [((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS) - 1:0] special_result_q;
	wire [4:0] special_status_q;
	reg [0:NUM_MID_REGS] mid_pipe_eff_sub_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_exp_prod_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_exp_diff_q;
	reg signed [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * EXP_WIDTH) + ((NUM_MID_REGS * EXP_WIDTH) - 1) : ((NUM_MID_REGS + 1) * EXP_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * EXP_WIDTH : 0)] mid_pipe_tent_exp_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH) + ((NUM_MID_REGS * SHIFT_AMOUNT_WIDTH) - 1) : ((NUM_MID_REGS + 1) * SHIFT_AMOUNT_WIDTH) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * SHIFT_AMOUNT_WIDTH : 0)] mid_pipe_add_shamt_q;
	reg [0:NUM_MID_REGS] mid_pipe_sticky_q;
	reg [(0 >= NUM_MID_REGS ? (((3 * PRECISION_BITS) + 3) >= 0 ? ((1 - NUM_MID_REGS) * ((3 * PRECISION_BITS) + 4)) + ((NUM_MID_REGS * ((3 * PRECISION_BITS) + 4)) - 1) : ((1 - NUM_MID_REGS) * (1 - ((3 * PRECISION_BITS) + 3))) + ((((3 * PRECISION_BITS) + 3) + (NUM_MID_REGS * (1 - ((3 * PRECISION_BITS) + 3)))) - 1)) : (((3 * PRECISION_BITS) + 3) >= 0 ? ((NUM_MID_REGS + 1) * ((3 * PRECISION_BITS) + 4)) - 1 : ((NUM_MID_REGS + 1) * (1 - ((3 * PRECISION_BITS) + 3))) + ((3 * PRECISION_BITS) + 2))):(0 >= NUM_MID_REGS ? (((3 * PRECISION_BITS) + 3) >= 0 ? NUM_MID_REGS * ((3 * PRECISION_BITS) + 4) : ((3 * PRECISION_BITS) + 3) + (NUM_MID_REGS * (1 - ((3 * PRECISION_BITS) + 3)))) : (((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3))] mid_pipe_sum_q;
	reg [0:NUM_MID_REGS] mid_pipe_final_sign_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 3) + ((NUM_MID_REGS * 3) - 1) : ((NUM_MID_REGS + 1) * 3) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 3 : 0)] mid_pipe_rnd_mode_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS) + ((NUM_MID_REGS * fpnew_pkg_FP_FORMAT_BITS) - 1) : ((NUM_MID_REGS + 1) * fpnew_pkg_FP_FORMAT_BITS) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * fpnew_pkg_FP_FORMAT_BITS : 0)] mid_pipe_dst_fmt_q;
	reg [0:NUM_MID_REGS] mid_pipe_res_is_spec_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)) + ((NUM_MID_REGS * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)) - 1) : ((NUM_MID_REGS + 1) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS) : 0)] mid_pipe_spec_res_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * 5) + ((NUM_MID_REGS * 5) - 1) : ((NUM_MID_REGS + 1) * 5) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * 5 : 0)] mid_pipe_spec_stat_q;
	reg [0:NUM_MID_REGS] mid_pipe_tag_q;
	reg [0:NUM_MID_REGS] mid_pipe_mask_q;
	reg [(0 >= NUM_MID_REGS ? ((1 - NUM_MID_REGS) * AuxType_AUX_BITS) + ((NUM_MID_REGS * AuxType_AUX_BITS) - 1) : ((NUM_MID_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_MID_REGS ? NUM_MID_REGS * AuxType_AUX_BITS : 0)] mid_pipe_aux_q;
	reg [0:NUM_MID_REGS] mid_pipe_valid_q;
	wire [0:NUM_MID_REGS] mid_pipe_ready;
	wire [1:1] sv2v_tmp_72F3C;
	assign sv2v_tmp_72F3C = effective_subtraction;
	always @(*) mid_pipe_eff_sub_q[0] = sv2v_tmp_72F3C;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_33460;
	assign sv2v_tmp_33460 = exponent_product;
	always @(*) mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_33460;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_D58F0;
	assign sv2v_tmp_D58F0 = exponent_difference;
	always @(*) mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_D58F0;
	wire [EXP_WIDTH * 1:1] sv2v_tmp_36F3A;
	assign sv2v_tmp_36F3A = tentative_exponent;
	always @(*) mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH] = sv2v_tmp_36F3A;
	wire [SHIFT_AMOUNT_WIDTH * 1:1] sv2v_tmp_670FF;
	assign sv2v_tmp_670FF = addend_shamt;
	always @(*) mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] = sv2v_tmp_670FF;
	wire [1:1] sv2v_tmp_D9513;
	assign sv2v_tmp_D9513 = sticky_before_add;
	always @(*) mid_pipe_sticky_q[0] = sv2v_tmp_D9513;
	wire [(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)) * 1:1] sv2v_tmp_7FA5A;
	assign sv2v_tmp_7FA5A = sum;
	always @(*) mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] = sv2v_tmp_7FA5A;
	wire [1:1] sv2v_tmp_E5D4B;
	assign sv2v_tmp_E5D4B = final_sign;
	always @(*) mid_pipe_final_sign_q[0] = sv2v_tmp_E5D4B;
	wire [3:1] sv2v_tmp_24A07;
	assign sv2v_tmp_24A07 = inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3];
	always @(*) mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 3+:3] = sv2v_tmp_24A07;
	wire [3:1] sv2v_tmp_B536C;
	assign sv2v_tmp_B536C = dst_fmt_q;
	always @(*) mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] = sv2v_tmp_B536C;
	wire [1:1] sv2v_tmp_7E156;
	assign sv2v_tmp_7E156 = result_is_special;
	always @(*) mid_pipe_res_is_spec_q[0] = sv2v_tmp_7E156;
	wire [((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS) * 1:1] sv2v_tmp_D459F;
	assign sv2v_tmp_D459F = special_result;
	always @(*) mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)+:(1 + SUPER_EXP_BITS) + SUPER_MAN_BITS] = sv2v_tmp_D459F;
	wire [5:1] sv2v_tmp_AC961;
	assign sv2v_tmp_AC961 = special_status;
	always @(*) mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * 5+:5] = sv2v_tmp_AC961;
	wire [1:1] sv2v_tmp_C9632;
	assign sv2v_tmp_C9632 = inp_pipe_tag_q[NUM_INP_REGS];
	always @(*) mid_pipe_tag_q[0] = sv2v_tmp_C9632;
	wire [1:1] sv2v_tmp_2E03C;
	assign sv2v_tmp_2E03C = inp_pipe_mask_q[NUM_INP_REGS];
	always @(*) mid_pipe_mask_q[0] = sv2v_tmp_2E03C;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_1BDCC;
	assign sv2v_tmp_1BDCC = inp_pipe_aux_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	always @(*) mid_pipe_aux_q[(0 >= NUM_MID_REGS ? 0 : NUM_MID_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_1BDCC;
	wire [1:1] sv2v_tmp_3D86F;
	assign sv2v_tmp_3D86F = inp_pipe_valid_q[NUM_INP_REGS];
	always @(*) mid_pipe_valid_q[0] = sv2v_tmp_3D86F;
	assign inp_pipe_ready[NUM_INP_REGS] = mid_pipe_ready[0];
	genvar _gv_i_48;
	generate
		for (_gv_i_48 = 0; _gv_i_48 < NUM_MID_REGS; _gv_i_48 = _gv_i_48 + 1) begin : gen_inside_pipeline
			localparam i = _gv_i_48;
			wire reg_ena;
			assign mid_pipe_ready[i] = mid_pipe_ready[i + 1] | ~mid_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_valid_q[i + 1] <= 1'b0;
				else
					mid_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (mid_pipe_ready[i] ? mid_pipe_valid_q[i] : mid_pipe_valid_q[i + 1]));
			assign reg_ena = (mid_pipe_ready[i] & mid_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_eff_sub_q[i + 1] <= 1'sb0;
				else
					mid_pipe_eff_sub_q[i + 1] <= (reg_ena ? mid_pipe_eff_sub_q[i] : mid_pipe_eff_sub_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= 1'sb0;
				else
					mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH] <= (reg_ena ? mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * EXP_WIDTH+:EXP_WIDTH] : mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * EXP_WIDTH+:EXP_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] <= 1'sb0;
				else
					mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] <= (reg_ena ? mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH] : mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_sticky_q[i + 1] <= 1'sb0;
				else
					mid_pipe_sticky_q[i + 1] <= (reg_ena ? mid_pipe_sticky_q[i] : mid_pipe_sticky_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] <= 1'sb0;
				else
					mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] <= (reg_ena ? mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))] : mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_final_sign_q[i + 1] <= 1'sb0;
				else
					mid_pipe_final_sign_q[i + 1] <= (reg_ena ? mid_pipe_final_sign_q[i] : mid_pipe_final_sign_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3] <= (reg_ena ? mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 3+:3] : mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= sv2v_cast_9FB13(0);
				else
					mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] <= (reg_ena ? mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS] : mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_res_is_spec_q[i + 1] <= 1'sb0;
				else
					mid_pipe_res_is_spec_q[i + 1] <= (reg_ena ? mid_pipe_res_is_spec_q[i] : mid_pipe_res_is_spec_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)+:(1 + SUPER_EXP_BITS) + SUPER_MAN_BITS] <= 1'sb0;
				else
					mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)+:(1 + SUPER_EXP_BITS) + SUPER_MAN_BITS] <= (reg_ena ? mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)+:(1 + SUPER_EXP_BITS) + SUPER_MAN_BITS] : mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)+:(1 + SUPER_EXP_BITS) + SUPER_MAN_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5] <= (reg_ena ? mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * 5+:5] : mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_tag_q[i + 1] <= 1'b0;
				else
					mid_pipe_tag_q[i + 1] <= (reg_ena ? mid_pipe_tag_q[i] : mid_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_mask_q[i + 1] <= 1'sb0;
				else
					mid_pipe_mask_q[i + 1] <= (reg_ena ? mid_pipe_mask_q[i] : mid_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i : NUM_MID_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : mid_pipe_aux_q[(0 >= NUM_MID_REGS ? i + 1 : NUM_MID_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign effective_subtraction_q = mid_pipe_eff_sub_q[NUM_MID_REGS];
	assign exponent_product_q = mid_pipe_exp_prod_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign exponent_difference_q = mid_pipe_exp_diff_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign tentative_exponent_q = mid_pipe_tent_exp_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * EXP_WIDTH+:EXP_WIDTH];
	assign addend_shamt_q = mid_pipe_add_shamt_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * SHIFT_AMOUNT_WIDTH+:SHIFT_AMOUNT_WIDTH];
	assign sticky_before_add_q = mid_pipe_sticky_q[NUM_MID_REGS];
	assign sum_q = mid_pipe_sum_q[(((3 * PRECISION_BITS) + 3) >= 0 ? 0 : (3 * PRECISION_BITS) + 3) + ((0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * (((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3)))+:(((3 * PRECISION_BITS) + 3) >= 0 ? (3 * PRECISION_BITS) + 4 : 1 - ((3 * PRECISION_BITS) + 3))];
	assign final_sign_q = mid_pipe_final_sign_q[NUM_MID_REGS];
	assign rnd_mode_q = mid_pipe_rnd_mode_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 3+:3];
	assign dst_fmt_q2 = mid_pipe_dst_fmt_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * fpnew_pkg_FP_FORMAT_BITS+:fpnew_pkg_FP_FORMAT_BITS];
	assign result_is_special_q = mid_pipe_res_is_spec_q[NUM_MID_REGS];
	assign special_result_q = mid_pipe_spec_res_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * ((1 + SUPER_EXP_BITS) + SUPER_MAN_BITS)+:(1 + SUPER_EXP_BITS) + SUPER_MAN_BITS];
	assign special_status_q = mid_pipe_spec_stat_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * 5+:5];
	wire [LOWER_SUM_WIDTH - 1:0] sum_lower;
	wire [LZC_RESULT_WIDTH - 1:0] leading_zero_count;
	wire signed [LZC_RESULT_WIDTH:0] leading_zero_count_sgn;
	wire lzc_zeroes;
	reg [SHIFT_AMOUNT_WIDTH - 1:0] norm_shamt;
	reg signed [EXP_WIDTH - 1:0] normalized_exponent;
	wire [(3 * PRECISION_BITS) + 4:0] sum_shifted;
	reg [PRECISION_BITS:0] final_mantissa;
	reg [(2 * PRECISION_BITS) + 2:0] sum_sticky_bits;
	wire sticky_after_norm;
	reg signed [EXP_WIDTH - 1:0] final_exponent;
	assign sum_lower = sum_q[LOWER_SUM_WIDTH - 1:0];
	lzc #(
		.WIDTH(LOWER_SUM_WIDTH),
		.MODE(1)
	) i_lzc(
		.in_i(sum_lower),
		.cnt_o(leading_zero_count),
		.empty_o(lzc_zeroes)
	);
	assign leading_zero_count_sgn = $signed({1'b0, leading_zero_count});
	always @(*) begin : norm_shift_amount
		if (_sv2v_0)
			;
		if ((exponent_difference_q <= 0) || (effective_subtraction_q && (exponent_difference_q <= 2))) begin
			if ((((exponent_product_q - leading_zero_count_sgn) + 1) >= 0) && !lzc_zeroes) begin
				norm_shamt = (PRECISION_BITS + 2) + leading_zero_count;
				normalized_exponent = (exponent_product_q - leading_zero_count_sgn) + 1;
			end
			else begin
				norm_shamt = $unsigned($signed((PRECISION_BITS + 2) + exponent_product_q));
				normalized_exponent = 0;
			end
		end
		else begin
			norm_shamt = addend_shamt_q;
			normalized_exponent = tentative_exponent_q;
		end
	end
	assign sum_shifted = sum_q << norm_shamt;
	always @(*) begin : small_norm
		if (_sv2v_0)
			;
		{final_mantissa, sum_sticky_bits} = sum_shifted;
		final_exponent = normalized_exponent;
		if (sum_shifted[(3 * PRECISION_BITS) + 4]) begin
			{final_mantissa, sum_sticky_bits} = sum_shifted >> 1;
			final_exponent = normalized_exponent + 1;
		end
		else if (sum_shifted[(3 * PRECISION_BITS) + 3])
			;
		else if (normalized_exponent > 1) begin
			{final_mantissa, sum_sticky_bits} = sum_shifted << 1;
			final_exponent = normalized_exponent - 1;
		end
		else
			final_exponent = 1'sb0;
	end
	assign sticky_after_norm = |{sum_sticky_bits} | sticky_before_add_q;
	wire pre_round_sign;
	wire [(SUPER_EXP_BITS + SUPER_MAN_BITS) - 1:0] pre_round_abs;
	wire [1:0] round_sticky_bits;
	wire of_before_round;
	wire of_after_round;
	wire uf_before_round;
	wire uf_after_round;
	wire [(NUM_FORMATS * (SUPER_EXP_BITS + SUPER_MAN_BITS)) - 1:0] fmt_pre_round_abs;
	wire [9:0] fmt_round_sticky_bits;
	reg [4:0] fmt_of_after_round;
	reg [4:0] fmt_uf_after_round;
	wire rounded_sign;
	wire [(SUPER_EXP_BITS + SUPER_MAN_BITS) - 1:0] rounded_abs;
	wire result_zero;
	assign of_before_round = final_exponent >= ((2 ** fpnew_pkg_exp_bits(dst_fmt_q2)) - 1);
	assign uf_before_round = final_exponent == 0;
	genvar _gv_fmt_7;
	generate
		for (_gv_fmt_7 = 0; _gv_fmt_7 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_7 = _gv_fmt_7 + 1) begin : gen_res_assemble
			localparam fmt = _gv_fmt_7;
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			wire [EXP_BITS - 1:0] pre_round_exponent;
			wire [MAN_BITS - 1:0] pre_round_mantissa;
			if (FpFmtConfig[fmt]) begin : active_format
				assign pre_round_exponent = (of_before_round ? (2 ** EXP_BITS) - 2 : final_exponent[EXP_BITS - 1:0]);
				assign pre_round_mantissa = (of_before_round ? {fpnew_pkg_man_bits(sv2v_cast_9FB13(_gv_fmt_7)) {1'sb1}} : final_mantissa[SUPER_MAN_BITS-:MAN_BITS]);
				assign fmt_pre_round_abs[fmt * (SUPER_EXP_BITS + SUPER_MAN_BITS)+:SUPER_EXP_BITS + SUPER_MAN_BITS] = {pre_round_exponent, pre_round_mantissa};
				assign fmt_round_sticky_bits[(fmt * 2) + 1] = final_mantissa[SUPER_MAN_BITS - MAN_BITS] | of_before_round;
				if (MAN_BITS < SUPER_MAN_BITS) begin : narrow_sticky
					assign fmt_round_sticky_bits[fmt * 2] = (|final_mantissa[(SUPER_MAN_BITS - MAN_BITS) - 1:0] | sticky_after_norm) | of_before_round;
				end
				else begin : normal_sticky
					assign fmt_round_sticky_bits[fmt * 2] = sticky_after_norm | of_before_round;
				end
			end
			else begin : inactive_format
				assign fmt_pre_round_abs[fmt * (SUPER_EXP_BITS + SUPER_MAN_BITS)+:SUPER_EXP_BITS + SUPER_MAN_BITS] = {SUPER_EXP_BITS + SUPER_MAN_BITS {fpnew_pkg_DONT_CARE}};
				assign fmt_round_sticky_bits[fmt * 2+:2] = {2 {fpnew_pkg_DONT_CARE}};
			end
		end
	endgenerate
	assign pre_round_sign = final_sign_q;
	assign pre_round_abs = fmt_pre_round_abs[dst_fmt_q2 * (SUPER_EXP_BITS + SUPER_MAN_BITS)+:SUPER_EXP_BITS + SUPER_MAN_BITS];
	assign round_sticky_bits = fmt_round_sticky_bits[dst_fmt_q2 * 2+:2];
	fpnew_rounding #(.AbsWidth(SUPER_EXP_BITS + SUPER_MAN_BITS)) i_fpnew_rounding(
		.abs_value_i(pre_round_abs),
		.sign_i(pre_round_sign),
		.round_sticky_bits_i(round_sticky_bits),
		.rnd_mode_i(rnd_mode_q),
		.effective_subtraction_i(effective_subtraction_q),
		.abs_rounded_o(rounded_abs),
		.sign_o(rounded_sign),
		.exact_zero_o(result_zero)
	);
	reg [(NUM_FORMATS * WIDTH) - 1:0] fmt_result;
	genvar _gv_fmt_8;
	generate
		for (_gv_fmt_8 = 0; _gv_fmt_8 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_8 = _gv_fmt_8 + 1) begin : gen_sign_inject
			localparam fmt = _gv_fmt_8;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(sv2v_cast_9FB13(fmt));
			localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(sv2v_cast_9FB13(fmt));
			if (FpFmtConfig[fmt]) begin : active_format
				always @(*) begin : post_process
					if (_sv2v_0)
						;
					fmt_uf_after_round[fmt] = (rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb0}}) || (((pre_round_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb0}}) && (rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == 1)) && ((round_sticky_bits != 2'b11) || (!sum_sticky_bits[(MAN_BITS * 2) + 4] && ((rnd_mode_i == 3'b000) || (rnd_mode_i == 3'b100)))));
					fmt_of_after_round[fmt] = rounded_abs[(EXP_BITS + MAN_BITS) - 1:MAN_BITS] == {(((EXP_BITS + MAN_BITS) - 1) >= MAN_BITS ? (((EXP_BITS + MAN_BITS) - 1) - MAN_BITS) + 1 : (MAN_BITS - ((EXP_BITS + MAN_BITS) - 1)) + 1) * 1 {1'sb1}};
					fmt_result[fmt * WIDTH+:WIDTH] = 1'sb1;
					fmt_result[(fmt * WIDTH) + (FP_WIDTH - 1)-:FP_WIDTH] = {rounded_sign, rounded_abs[(EXP_BITS + MAN_BITS) - 1:0]};
				end
			end
			else begin : inactive_format
				wire [1:1] sv2v_tmp_DD825;
				assign sv2v_tmp_DD825 = fpnew_pkg_DONT_CARE;
				always @(*) fmt_uf_after_round[fmt] = sv2v_tmp_DD825;
				wire [1:1] sv2v_tmp_358EF;
				assign sv2v_tmp_358EF = fpnew_pkg_DONT_CARE;
				always @(*) fmt_of_after_round[fmt] = sv2v_tmp_358EF;
				wire [WIDTH * 1:1] sv2v_tmp_C89CB;
				assign sv2v_tmp_C89CB = {WIDTH {fpnew_pkg_DONT_CARE}};
				always @(*) fmt_result[fmt * WIDTH+:WIDTH] = sv2v_tmp_C89CB;
			end
		end
	endgenerate
	assign uf_after_round = fmt_uf_after_round[dst_fmt_q2];
	assign of_after_round = fmt_of_after_round[dst_fmt_q2];
	wire [WIDTH - 1:0] regular_result;
	wire [4:0] regular_status;
	assign regular_result = fmt_result[dst_fmt_q2 * WIDTH+:WIDTH];
	assign regular_status[4] = 1'b0;
	assign regular_status[3] = 1'b0;
	assign regular_status[2] = of_before_round | of_after_round;
	assign regular_status[1] = uf_after_round & regular_status[0];
	assign regular_status[0] = (|round_sticky_bits | of_before_round) | of_after_round;
	wire [WIDTH - 1:0] result_d;
	wire [4:0] status_d;
	assign result_d = (result_is_special_q ? special_result_q : regular_result);
	assign status_d = (result_is_special_q ? special_status_q : regular_status);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * WIDTH) + ((NUM_OUT_REGS * WIDTH) - 1) : ((NUM_OUT_REGS + 1) * WIDTH) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * WIDTH : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * AuxType_AUX_BITS) + ((NUM_OUT_REGS * AuxType_AUX_BITS) - 1) : ((NUM_OUT_REGS + 1) * AuxType_AUX_BITS) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * AuxType_AUX_BITS : 0)] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [WIDTH * 1:1] sv2v_tmp_8CCB4;
	assign sv2v_tmp_8CCB4 = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * WIDTH+:WIDTH] = sv2v_tmp_8CCB4;
	wire [5:1] sv2v_tmp_1B7C7;
	assign sv2v_tmp_1B7C7 = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_1B7C7;
	wire [1:1] sv2v_tmp_D3F91;
	assign sv2v_tmp_D3F91 = mid_pipe_tag_q[NUM_MID_REGS];
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_D3F91;
	wire [1:1] sv2v_tmp_F68B4;
	assign sv2v_tmp_F68B4 = mid_pipe_mask_q[NUM_MID_REGS];
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_F68B4;
	wire [AuxType_AUX_BITS * 1:1] sv2v_tmp_8420F;
	assign sv2v_tmp_8420F = mid_pipe_aux_q[(0 >= NUM_MID_REGS ? NUM_MID_REGS : NUM_MID_REGS - NUM_MID_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	always @(*) out_pipe_aux_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS] = sv2v_tmp_8420F;
	wire [1:1] sv2v_tmp_39CE2;
	assign sv2v_tmp_39CE2 = mid_pipe_valid_q[NUM_MID_REGS];
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_39CE2;
	assign mid_pipe_ready[NUM_MID_REGS] = out_pipe_ready[0];
	genvar _gv_i_49;
	generate
		for (_gv_i_49 = 0; _gv_i_49 < NUM_OUT_REGS; _gv_i_49 = _gv_i_49 + 1) begin : gen_output_pipeline
			localparam i = _gv_i_49;
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[(NUM_INP_REGS + NUM_MID_REGS) + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * WIDTH+:WIDTH] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * WIDTH+:WIDTH]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= sv2v_cast_F912A(1'sb0);
				else
					out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS] <= (reg_ena ? out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * AuxType_AUX_BITS+:AuxType_AUX_BITS] : out_pipe_aux_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * AuxType_AUX_BITS+:AuxType_AUX_BITS]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * WIDTH+:WIDTH];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = 1'b1;
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * AuxType_AUX_BITS+:AuxType_AUX_BITS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, mid_pipe_valid_q, out_pipe_valid_q};
	initial _sv2v_0 = 0;
endmodule
module fpnew_noncomp_C2090 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	tag_i,
	mask_i,
	aux_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	class_mask_o,
	is_class_o,
	tag_o,
	mask_o,
	aux_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	reg _sv2v_0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_9FB13(0);
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	localparam [31:0] WIDTH = fpnew_pkg_fp_width(FpFormat);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(2 * WIDTH) - 1:0] operands_i;
	input wire [1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire tag_i;
	input wire mask_i;
	input wire aux_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire [9:0] class_mask_o;
	output wire is_class_o;
	output wire tag_o;
	output wire mask_o;
	output wire aux_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	function automatic [31:0] fpnew_pkg_exp_bits;
		input reg [2:0] fmt;
		fpnew_pkg_exp_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32];
	endfunction
	localparam [31:0] EXP_BITS = fpnew_pkg_exp_bits(FpFormat);
	function automatic [31:0] fpnew_pkg_man_bits;
		input reg [2:0] fmt;
		fpnew_pkg_man_bits = fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32];
	endfunction
	localparam [31:0] MAN_BITS = fpnew_pkg_man_bits(FpFormat);
	localparam NUM_INP_REGS = ((PipeConfig == 2'd0) || (PipeConfig == 2'd2) ? NumPipeRegs : (PipeConfig == 2'd3 ? (NumPipeRegs + 1) / 2 : 0));
	localparam NUM_OUT_REGS = (PipeConfig == 2'd1 ? NumPipeRegs : (PipeConfig == 2'd3 ? NumPipeRegs / 2 : 0));
	reg [((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) - (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * WIDTH) - 1) : ((((0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)) + 1) * WIDTH) + (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * WIDTH) - 1)):((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) * WIDTH : (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) * WIDTH)] inp_pipe_operands_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0)] inp_pipe_is_boxed_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 3) + ((NUM_INP_REGS * 3) - 1) : ((NUM_INP_REGS + 1) * 3) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * 3 : 0)] inp_pipe_rnd_mode_q;
	reg [(0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * fpnew_pkg_OP_BITS) + ((NUM_INP_REGS * fpnew_pkg_OP_BITS) - 1) : ((NUM_INP_REGS + 1) * fpnew_pkg_OP_BITS) - 1):(0 >= NUM_INP_REGS ? NUM_INP_REGS * fpnew_pkg_OP_BITS : 0)] inp_pipe_op_q;
	reg [0:NUM_INP_REGS] inp_pipe_op_mod_q;
	reg [0:NUM_INP_REGS] inp_pipe_tag_q;
	reg [0:NUM_INP_REGS] inp_pipe_mask_q;
	reg [0:NUM_INP_REGS] inp_pipe_aux_q;
	reg [0:NUM_INP_REGS] inp_pipe_valid_q;
	wire [0:NUM_INP_REGS] inp_pipe_ready;
	wire [2 * WIDTH:1] sv2v_tmp_F8807;
	assign sv2v_tmp_F8807 = operands_i;
	always @(*) inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] = sv2v_tmp_F8807;
	wire [2:1] sv2v_tmp_CD89A;
	assign sv2v_tmp_CD89A = is_boxed_i;
	always @(*) inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 2+:2] = sv2v_tmp_CD89A;
	wire [3:1] sv2v_tmp_6B838;
	assign sv2v_tmp_6B838 = rnd_mode_i;
	always @(*) inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * 3+:3] = sv2v_tmp_6B838;
	wire [4:1] sv2v_tmp_D9BC9;
	assign sv2v_tmp_D9BC9 = op_i;
	always @(*) inp_pipe_op_q[(0 >= NUM_INP_REGS ? 0 : NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] = sv2v_tmp_D9BC9;
	wire [1:1] sv2v_tmp_42D74;
	assign sv2v_tmp_42D74 = op_mod_i;
	always @(*) inp_pipe_op_mod_q[0] = sv2v_tmp_42D74;
	wire [1:1] sv2v_tmp_6A91A;
	assign sv2v_tmp_6A91A = tag_i;
	always @(*) inp_pipe_tag_q[0] = sv2v_tmp_6A91A;
	wire [1:1] sv2v_tmp_43EE3;
	assign sv2v_tmp_43EE3 = mask_i;
	always @(*) inp_pipe_mask_q[0] = sv2v_tmp_43EE3;
	wire [1:1] sv2v_tmp_E1D93;
	assign sv2v_tmp_E1D93 = aux_i;
	always @(*) inp_pipe_aux_q[0] = sv2v_tmp_E1D93;
	wire [1:1] sv2v_tmp_9CFD6;
	assign sv2v_tmp_9CFD6 = in_valid_i;
	always @(*) inp_pipe_valid_q[0] = sv2v_tmp_9CFD6;
	assign in_ready_o = inp_pipe_ready[0];
	genvar _gv_i_50;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	generate
		for (_gv_i_50 = 0; _gv_i_50 < NUM_INP_REGS; _gv_i_50 = _gv_i_50 + 1) begin : gen_input_pipeline
			localparam i = _gv_i_50;
			wire reg_ena;
			assign inp_pipe_ready[i] = inp_pipe_ready[i + 1] | ~inp_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_valid_q[i + 1] <= 1'b0;
				else
					inp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (inp_pipe_ready[i] ? inp_pipe_valid_q[i] : inp_pipe_valid_q[i + 1]));
			assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] <= 1'sb0;
				else
					inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] <= (reg_ena ? inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2 : ((0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2] : inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2 : ((0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2+:2] <= 1'sb0;
				else
					inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2+:2] <= (reg_ena ? inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 2+:2] : inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 2+:2]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= 3'b000;
				else
					inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3] <= (reg_ena ? inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * 3+:3] : inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * 3+:3]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= sv2v_cast_7BCAE(0);
				else
					inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] <= (reg_ena ? inp_pipe_op_q[(0 >= NUM_INP_REGS ? i : NUM_INP_REGS - i) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] : inp_pipe_op_q[(0 >= NUM_INP_REGS ? i + 1 : NUM_INP_REGS - (i + 1)) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_op_mod_q[i + 1] <= 1'sb0;
				else
					inp_pipe_op_mod_q[i + 1] <= (reg_ena ? inp_pipe_op_mod_q[i] : inp_pipe_op_mod_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_tag_q[i + 1] <= 1'b0;
				else
					inp_pipe_tag_q[i + 1] <= (reg_ena ? inp_pipe_tag_q[i] : inp_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_mask_q[i + 1] <= 1'sb0;
				else
					inp_pipe_mask_q[i + 1] <= (reg_ena ? inp_pipe_mask_q[i] : inp_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					inp_pipe_aux_q[i + 1] <= 1'b0;
				else
					inp_pipe_aux_q[i + 1] <= (reg_ena ? inp_pipe_aux_q[i] : inp_pipe_aux_q[i + 1]);
		end
	endgenerate
	wire [15:0] info_q;
	fpnew_classifier #(
		.FpFormat(FpFormat),
		.NumOperands(2)
	) i_class_a(
		.operands_i(inp_pipe_operands_q[WIDTH * ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1)))+:WIDTH * 2]),
		.is_boxed_i(inp_pipe_is_boxed_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2+:2]),
		.info_o(info_q)
	);
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_a;
	wire [((1 + EXP_BITS) + MAN_BITS) - 1:0] operand_b;
	wire [7:0] info_a;
	wire [7:0] info_b;
	assign operand_a = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? (0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - (((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1))) * WIDTH+:WIDTH];
	assign operand_b = inp_pipe_operands_q[((0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1) >= (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) ? ((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1 : (0 >= NUM_INP_REGS ? NUM_INP_REGS * 2 : 0) - ((((0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 2) + 1) - (0 >= NUM_INP_REGS ? ((1 - NUM_INP_REGS) * 2) + ((NUM_INP_REGS * 2) - 1) : ((NUM_INP_REGS + 1) * 2) - 1))) * WIDTH+:WIDTH];
	assign info_a = info_q[0+:8];
	assign info_b = info_q[8+:8];
	wire any_operand_inf;
	wire any_operand_nan;
	wire signalling_nan;
	assign any_operand_inf = |{info_a[4], info_b[4]};
	assign any_operand_nan = |{info_a[3], info_b[3]};
	assign signalling_nan = |{info_a[2], info_b[2]};
	wire operands_equal;
	wire operand_a_smaller;
	assign operands_equal = (operand_a == operand_b) || (info_a[5] && info_b[5]);
	assign operand_a_smaller = (operand_a < operand_b) ^ (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] || operand_b[1 + (EXP_BITS + (MAN_BITS - 1))]);
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] sgnj_result;
	wire [4:0] sgnj_status;
	wire sgnj_extension_bit;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic [EXP_BITS - 1:0] sv2v_cast_641B7;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_641B7 = inp;
	endfunction
	function automatic [MAN_BITS - 1:0] sv2v_cast_33A5C;
		input reg [MAN_BITS - 1:0] inp;
		sv2v_cast_33A5C = inp;
	endfunction
	function automatic [EXP_BITS - 1:0] sv2v_cast_DBE99;
		input reg [EXP_BITS - 1:0] inp;
		sv2v_cast_DBE99 = inp;
	endfunction
	always @(*) begin : sign_injections
		reg sign_a;
		reg sign_b;
		if (_sv2v_0)
			;
		sgnj_result = operand_a;
		if (!info_a[0])
			sgnj_result = {1'b0, sv2v_cast_641B7(1'sb1), sv2v_cast_33A5C(2 ** (MAN_BITS - 1))};
		sign_a = operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] & info_a[0];
		sign_b = operand_b[1 + (EXP_BITS + (MAN_BITS - 1))] & info_b[0];
		(* full_case, parallel_case *)
		case (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3])
			3'b000: sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] = sign_b;
			3'b001: sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] = ~sign_b;
			3'b010: sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] = sign_a ^ sign_b;
			3'b011: sgnj_result = operand_a;
			default: sgnj_result = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
		endcase
	end
	assign sgnj_status = 1'sb0;
	assign sgnj_extension_bit = (inp_pipe_op_mod_q[NUM_INP_REGS] ? sgnj_result[1 + (EXP_BITS + (MAN_BITS - 1))] : 1'b1);
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] minmax_result;
	reg [4:0] minmax_status;
	wire minmax_extension_bit;
	always @(*) begin : min_max
		if (_sv2v_0)
			;
		minmax_status = 1'sb0;
		minmax_status[4] = signalling_nan;
		if (info_a[3] && info_b[3])
			minmax_result = {1'b0, sv2v_cast_641B7(1'sb1), sv2v_cast_33A5C(2 ** (MAN_BITS - 1))};
		else if (info_a[3])
			minmax_result = operand_b;
		else if (info_b[3])
			minmax_result = operand_a;
		else
			(* full_case, parallel_case *)
			case (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3])
				3'b000: minmax_result = (operand_a_smaller ? operand_a : operand_b);
				3'b001: minmax_result = (operand_a_smaller ? operand_b : operand_a);
				default: minmax_result = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
			endcase
	end
	assign minmax_extension_bit = 1'b1;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] cmp_result;
	reg [4:0] cmp_status;
	wire cmp_extension_bit;
	always @(*) begin : comparisons
		if (_sv2v_0)
			;
		cmp_result = 1'sb0;
		cmp_status = 1'sb0;
		if (signalling_nan)
			cmp_status[4] = 1'b1;
		else
			(* full_case, parallel_case *)
			case (inp_pipe_rnd_mode_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * 3+:3])
				3'b000:
					if (any_operand_nan)
						cmp_status[4] = 1'b1;
					else
						cmp_result = (operand_a_smaller | operands_equal) ^ inp_pipe_op_mod_q[NUM_INP_REGS];
				3'b001:
					if (any_operand_nan)
						cmp_status[4] = 1'b1;
					else
						cmp_result = (operand_a_smaller & ~operands_equal) ^ inp_pipe_op_mod_q[NUM_INP_REGS];
				3'b010:
					if (any_operand_nan)
						cmp_result = inp_pipe_op_mod_q[NUM_INP_REGS];
					else
						cmp_result = operands_equal ^ inp_pipe_op_mod_q[NUM_INP_REGS];
				default: cmp_result = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
			endcase
	end
	assign cmp_extension_bit = 1'b0;
	wire [4:0] class_status;
	wire class_extension_bit;
	reg [9:0] class_mask_d;
	always @(*) begin : classify
		if (_sv2v_0)
			;
		if (info_a[7])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000000010 : 10'b0001000000);
		else if (info_a[6])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000000100 : 10'b0000100000);
		else if (info_a[5])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000001000 : 10'b0000010000);
		else if (info_a[4])
			class_mask_d = (operand_a[1 + (EXP_BITS + (MAN_BITS - 1))] ? 10'b0000000001 : 10'b0010000000);
		else if (info_a[3])
			class_mask_d = (info_a[2] ? 10'b0100000000 : 10'b1000000000);
		else
			class_mask_d = 10'b1000000000;
	end
	assign class_status = 1'sb0;
	assign class_extension_bit = 1'b0;
	reg [((1 + EXP_BITS) + MAN_BITS) - 1:0] result_d;
	reg [4:0] status_d;
	reg extension_bit_d;
	wire is_class_d;
	always @(*) begin : select_result
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS])
			sv2v_cast_7BCAE(6): begin
				result_d = sgnj_result;
				status_d = sgnj_status;
				extension_bit_d = sgnj_extension_bit;
			end
			sv2v_cast_7BCAE(7): begin
				result_d = minmax_result;
				status_d = minmax_status;
				extension_bit_d = minmax_extension_bit;
			end
			sv2v_cast_7BCAE(8): begin
				result_d = cmp_result;
				status_d = cmp_status;
				extension_bit_d = cmp_extension_bit;
			end
			sv2v_cast_7BCAE(9): begin
				result_d = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
				status_d = class_status;
				extension_bit_d = class_extension_bit;
			end
			default: begin
				result_d = {fpnew_pkg_DONT_CARE, sv2v_cast_DBE99(fpnew_pkg_DONT_CARE), sv2v_cast_33A5C(fpnew_pkg_DONT_CARE)};
				status_d = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				extension_bit_d = fpnew_pkg_DONT_CARE;
			end
		endcase
	end
	assign is_class_d = inp_pipe_op_q[(0 >= NUM_INP_REGS ? NUM_INP_REGS : NUM_INP_REGS - NUM_INP_REGS) * fpnew_pkg_OP_BITS+:fpnew_pkg_OP_BITS] == sv2v_cast_7BCAE(9);
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)) + ((NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS)) - 1) : ((NUM_OUT_REGS + 1) * ((1 + EXP_BITS) + MAN_BITS)) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * ((1 + EXP_BITS) + MAN_BITS) : 0)] out_pipe_result_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 5) + ((NUM_OUT_REGS * 5) - 1) : ((NUM_OUT_REGS + 1) * 5) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 5 : 0)] out_pipe_status_q;
	reg [0:NUM_OUT_REGS] out_pipe_extension_bit_q;
	reg [(0 >= NUM_OUT_REGS ? ((1 - NUM_OUT_REGS) * 10) + ((NUM_OUT_REGS * 10) - 1) : ((NUM_OUT_REGS + 1) * 10) - 1):(0 >= NUM_OUT_REGS ? NUM_OUT_REGS * 10 : 0)] out_pipe_class_mask_q;
	reg [0:NUM_OUT_REGS] out_pipe_is_class_q;
	reg [0:NUM_OUT_REGS] out_pipe_tag_q;
	reg [0:NUM_OUT_REGS] out_pipe_mask_q;
	reg [0:NUM_OUT_REGS] out_pipe_aux_q;
	reg [0:NUM_OUT_REGS] out_pipe_valid_q;
	wire [0:NUM_OUT_REGS] out_pipe_ready;
	wire [((1 + EXP_BITS) + MAN_BITS) * 1:1] sv2v_tmp_BDBA0;
	assign sv2v_tmp_BDBA0 = result_d;
	always @(*) out_pipe_result_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] = sv2v_tmp_BDBA0;
	wire [5:1] sv2v_tmp_F85FB;
	assign sv2v_tmp_F85FB = status_d;
	always @(*) out_pipe_status_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 5+:5] = sv2v_tmp_F85FB;
	wire [1:1] sv2v_tmp_43031;
	assign sv2v_tmp_43031 = extension_bit_d;
	always @(*) out_pipe_extension_bit_q[0] = sv2v_tmp_43031;
	wire [10:1] sv2v_tmp_8049D;
	assign sv2v_tmp_8049D = class_mask_d;
	always @(*) out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? 0 : NUM_OUT_REGS) * 10+:10] = sv2v_tmp_8049D;
	wire [1:1] sv2v_tmp_7DA92;
	assign sv2v_tmp_7DA92 = is_class_d;
	always @(*) out_pipe_is_class_q[0] = sv2v_tmp_7DA92;
	wire [1:1] sv2v_tmp_FFBE4;
	assign sv2v_tmp_FFBE4 = inp_pipe_tag_q[NUM_INP_REGS];
	always @(*) out_pipe_tag_q[0] = sv2v_tmp_FFBE4;
	wire [1:1] sv2v_tmp_A9F63;
	assign sv2v_tmp_A9F63 = inp_pipe_mask_q[NUM_INP_REGS];
	always @(*) out_pipe_mask_q[0] = sv2v_tmp_A9F63;
	wire [1:1] sv2v_tmp_024FB;
	assign sv2v_tmp_024FB = inp_pipe_aux_q[NUM_INP_REGS];
	always @(*) out_pipe_aux_q[0] = sv2v_tmp_024FB;
	wire [1:1] sv2v_tmp_23287;
	assign sv2v_tmp_23287 = inp_pipe_valid_q[NUM_INP_REGS];
	always @(*) out_pipe_valid_q[0] = sv2v_tmp_23287;
	assign inp_pipe_ready[NUM_INP_REGS] = out_pipe_ready[0];
	genvar _gv_i_51;
	generate
		for (_gv_i_51 = 0; _gv_i_51 < NUM_OUT_REGS; _gv_i_51 = _gv_i_51 + 1) begin : gen_output_pipeline
			localparam i = _gv_i_51;
			wire reg_ena;
			assign out_pipe_ready[i] = out_pipe_ready[i + 1] | ~out_pipe_valid_q[i + 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_valid_q[i + 1] <= 1'b0;
				else
					out_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (out_pipe_ready[i] ? out_pipe_valid_q[i] : out_pipe_valid_q[i + 1]));
			assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= 1'sb0;
				else
					out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] <= (reg_ena ? out_pipe_result_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS] : out_pipe_result_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= 1'sb0;
				else
					out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5] <= (reg_ena ? out_pipe_status_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 5+:5] : out_pipe_status_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 5+:5]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_extension_bit_q[i + 1] <= 1'sb0;
				else
					out_pipe_extension_bit_q[i + 1] <= (reg_ena ? out_pipe_extension_bit_q[i] : out_pipe_extension_bit_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 10+:10] <= 10'b1000000000;
				else
					out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 10+:10] <= (reg_ena ? out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i : NUM_OUT_REGS - i) * 10+:10] : out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? i + 1 : NUM_OUT_REGS - (i + 1)) * 10+:10]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_is_class_q[i + 1] <= 1'sb0;
				else
					out_pipe_is_class_q[i + 1] <= (reg_ena ? out_pipe_is_class_q[i] : out_pipe_is_class_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_tag_q[i + 1] <= 1'b0;
				else
					out_pipe_tag_q[i + 1] <= (reg_ena ? out_pipe_tag_q[i] : out_pipe_tag_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_mask_q[i + 1] <= 1'sb0;
				else
					out_pipe_mask_q[i + 1] <= (reg_ena ? out_pipe_mask_q[i] : out_pipe_mask_q[i + 1]);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					out_pipe_aux_q[i + 1] <= 1'b0;
				else
					out_pipe_aux_q[i + 1] <= (reg_ena ? out_pipe_aux_q[i] : out_pipe_aux_q[i + 1]);
		end
	endgenerate
	assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
	assign result_o = out_pipe_result_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * ((1 + EXP_BITS) + MAN_BITS)+:(1 + EXP_BITS) + MAN_BITS];
	assign status_o = out_pipe_status_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 5+:5];
	assign extension_bit_o = out_pipe_extension_bit_q[NUM_OUT_REGS];
	assign class_mask_o = out_pipe_class_mask_q[(0 >= NUM_OUT_REGS ? NUM_OUT_REGS : NUM_OUT_REGS - NUM_OUT_REGS) * 10+:10];
	assign is_class_o = out_pipe_is_class_q[NUM_OUT_REGS];
	assign tag_o = out_pipe_tag_q[NUM_OUT_REGS];
	assign mask_o = out_pipe_mask_q[NUM_OUT_REGS];
	assign aux_o = out_pipe_aux_q[NUM_OUT_REGS];
	assign out_valid_o = out_pipe_valid_q[NUM_OUT_REGS];
	assign busy_o = |{inp_pipe_valid_q, out_pipe_valid_q};
	initial _sv2v_0 = 0;
endmodule
module fpnew_opgroup_block_28857 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	int_fmt_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o
);
	reg _sv2v_0;
	parameter [1:0] OpGroup = 2'd0;
	parameter [31:0] Width = 32;
	parameter [0:0] EnableVectors = 1'b1;
	parameter [0:0] PulpDivsqrt = 1'b1;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	parameter [0:4] FpFmtMask = 1'sb1;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	parameter [0:3] IntFmtMask = 1'sb1;
	parameter [159:0] FmtPipeRegs = {fpnew_pkg_NUM_FP_FORMATS {32'd0}};
	parameter [9:0] FmtUnitTypes = {fpnew_pkg_NUM_FP_FORMATS {2'd1}};
	parameter [1:0] PipeConfig = 2'd0;
	parameter [31:0] TrueSIMDClass = 0;
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		(* full_case, parallel_case *)
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	localparam [31:0] NUM_OPERANDS = fpnew_pkg_num_operands(OpGroup);
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	function automatic signed [31:0] fpnew_pkg_minimum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_minimum = (a < b ? a : b);
	endfunction
	function automatic [31:0] fpnew_pkg_min_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = fpnew_pkg_max_fp_width(cfg);
			begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_minimum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_min_fp_width = res;
		end
	endfunction
	function automatic [31:0] fpnew_pkg_max_num_lanes;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg vec;
		fpnew_pkg_max_num_lanes = (vec ? width / fpnew_pkg_min_fp_width(cfg) : 1);
	endfunction
	localparam [31:0] NUM_LANES = fpnew_pkg_max_num_lanes(Width, FpFmtMask, EnableVectors);
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * Width) - 1:0] operands_i;
	input wire [(NUM_FORMATS * NUM_OPERANDS) - 1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	input wire [1:0] int_fmt_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NUM_LANES - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [Width - 1:0] result_o;
	output wire [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	wire [4:0] fmt_in_ready;
	wire [4:0] fmt_out_valid;
	wire [4:0] fmt_out_ready;
	wire [4:0] fmt_busy;
	wire [((Width + 6) >= 0 ? (5 * (Width + 7)) - 1 : (5 * (1 - (Width + 6))) + (Width + 5)):((Width + 6) >= 0 ? 0 : Width + 6)] fmt_outputs;
	assign in_ready_o = in_valid_i & fmt_in_ready[dst_fmt_i];
	genvar _gv_fmt_9;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	function automatic fpnew_pkg_any_enabled_multi;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [1:0] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			begin : sv2v_autoblock_3
				reg [31:0] i;
				begin : sv2v_autoblock_4
					reg [31:0] _sv2v_value_on_break;
					for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2)) begin
								fpnew_pkg_any_enabled_multi = 1'b1;
								_sv2v_jump = 2'b11;
							end
							_sv2v_value_on_break = i;
						end
					if (!(_sv2v_jump < 2'b10))
						i = _sv2v_value_on_break;
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
			end
			if (_sv2v_jump == 2'b00) begin
				fpnew_pkg_any_enabled_multi = 1'b0;
				_sv2v_jump = 2'b11;
			end
		end
	endfunction
	function automatic [2:0] fpnew_pkg_get_first_enabled_multi;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [1:0] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			begin : sv2v_autoblock_5
				reg [31:0] i;
				begin : sv2v_autoblock_6
					reg [31:0] _sv2v_value_on_break;
					for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2)) begin
								fpnew_pkg_get_first_enabled_multi = sv2v_cast_9FB13(i);
								_sv2v_jump = 2'b11;
							end
							_sv2v_value_on_break = i;
						end
					if (!(_sv2v_jump < 2'b10))
						i = _sv2v_value_on_break;
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
			end
			if (_sv2v_jump == 2'b00) begin
				fpnew_pkg_get_first_enabled_multi = sv2v_cast_9FB13(0);
				_sv2v_jump = 2'b11;
			end
		end
	endfunction
	function automatic fpnew_pkg_is_first_enabled_multi;
		input reg [2:0] fmt;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [1:0] _sv2v_jump;
		begin
			_sv2v_jump = 2'b00;
			begin : sv2v_autoblock_7
				reg [31:0] i;
				begin : sv2v_autoblock_8
					reg [31:0] _sv2v_value_on_break;
					for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
						if (_sv2v_jump < 2'b10) begin
							_sv2v_jump = 2'b00;
							if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2)) begin
								fpnew_pkg_is_first_enabled_multi = sv2v_cast_9FB13(i) == fmt;
								_sv2v_jump = 2'b11;
							end
							_sv2v_value_on_break = i;
						end
					if (!(_sv2v_jump < 2'b10))
						i = _sv2v_value_on_break;
					if (_sv2v_jump != 2'b11)
						_sv2v_jump = 2'b00;
				end
			end
			if (_sv2v_jump == 2'b00) begin
				fpnew_pkg_is_first_enabled_multi = 1'b0;
				_sv2v_jump = 2'b11;
			end
		end
	endfunction
	function automatic [31:0] fpnew_pkg_num_lanes;
		input reg [31:0] width;
		input reg [2:0] fmt;
		input reg vec;
		fpnew_pkg_num_lanes = (vec ? width / fpnew_pkg_fp_width(fmt) : 1);
	endfunction
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	generate
		for (_gv_fmt_9 = 0; _gv_fmt_9 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_9 = _gv_fmt_9 + 1) begin : gen_parallel_slices
			localparam fmt = _gv_fmt_9;
			localparam [0:0] ANY_MERGED = fpnew_pkg_any_enabled_multi(FmtUnitTypes, FpFmtMask);
			localparam [0:0] IS_FIRST_MERGED = fpnew_pkg_is_first_enabled_multi(sv2v_cast_9FB13(fmt), FmtUnitTypes, FpFmtMask);
			if (FpFmtMask[fmt] && (FmtUnitTypes[(4 - fmt) * 2+:2] == 2'd1)) begin : active_format
				wire in_valid;
				assign in_valid = in_valid_i & (dst_fmt_i == fmt);
				localparam [31:0] INTERNAL_LANES = fpnew_pkg_num_lanes(Width, sv2v_cast_9FB13(fmt), EnableVectors);
				reg [INTERNAL_LANES - 1:0] mask_slice;
				always @(*) begin : sv2v_autoblock_9
					reg signed [31:0] b;
					if (_sv2v_0)
						;
					for (b = 0; b < INTERNAL_LANES; b = b + 1)
						mask_slice[b] = simd_mask_i[(NUM_LANES / INTERNAL_LANES) * b];
				end
				localparam [31:0] sv2v_uu_i_fmt_slice_NumPipeRegs = FmtPipeRegs[(4 - fmt) * 32+:32];
				localparam [31:0] sv2v_uu_i_fmt_slice_ExtRegEnaWidth = (sv2v_uu_i_fmt_slice_NumPipeRegs == 0 ? 1 : sv2v_uu_i_fmt_slice_NumPipeRegs);
				localparam [sv2v_cast_32((sv2v_cast_32(FmtPipeRegs[(4 - _gv_fmt_9) * 32+:32]) == 0 ? 1 : sv2v_cast_32(FmtPipeRegs[(4 - _gv_fmt_9) * 32+:32]))) - 1:0] sv2v_uu_i_fmt_slice_ext_reg_ena_i_0 = 1'sb0;
				fpnew_opgroup_fmt_slice_B0DD3 #(
					.OpGroup(OpGroup),
					.FpFormat(sv2v_cast_9FB13(fmt)),
					.Width(Width),
					.EnableVectors(EnableVectors),
					.NumPipeRegs(FmtPipeRegs[(4 - fmt) * 32+:32]),
					.PipeConfig(PipeConfig),
					.TrueSIMDClass(TrueSIMDClass)
				) i_fmt_slice(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.operands_i(operands_i),
					.is_boxed_i(is_boxed_i[fmt * NUM_OPERANDS+:NUM_OPERANDS]),
					.rnd_mode_i(rnd_mode_i),
					.op_i(op_i),
					.op_mod_i(op_mod_i),
					.vectorial_op_i(vectorial_op_i),
					.tag_i(tag_i),
					.simd_mask_i(mask_slice),
					.in_valid_i(in_valid),
					.in_ready_o(fmt_in_ready[fmt]),
					.flush_i(flush_i),
					.result_o(fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))]),
					.status_o(fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5]),
					.extension_bit_o(fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)]),
					.tag_o(fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)]),
					.out_valid_o(fmt_out_valid[fmt]),
					.out_ready_i(fmt_out_ready[fmt]),
					.busy_o(fmt_busy[fmt]),
					.reg_ena_i(sv2v_uu_i_fmt_slice_ext_reg_ena_i_0)
				);
			end
			else if ((FpFmtMask[fmt] && ANY_MERGED) && !IS_FIRST_MERGED) begin : merged_unused
				localparam FMT = fpnew_pkg_get_first_enabled_multi(FmtUnitTypes, FpFmtMask);
				assign fmt_in_ready[fmt] = fmt_in_ready[sv2v_cast_32_signed(FMT)];
				assign fmt_out_valid[fmt] = 1'b0;
				assign fmt_busy[fmt] = 1'b0;
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))] = {Width {fpnew_pkg_DONT_CARE}};
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5] = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)] = fpnew_pkg_DONT_CARE;
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)] = fpnew_pkg_DONT_CARE;
			end
			else if (!FpFmtMask[fmt] || (FmtUnitTypes[(4 - fmt) * 2+:2] == 2'd0)) begin : disable_fmt
				assign fmt_in_ready[fmt] = 1'b0;
				assign fmt_out_valid[fmt] = 1'b0;
				assign fmt_busy[fmt] = 1'b0;
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))] = {Width {fpnew_pkg_DONT_CARE}};
				assign fmt_outputs[((Width + 6) >= 0 ? (fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5] = {fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE, fpnew_pkg_DONT_CARE};
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)] = fpnew_pkg_DONT_CARE;
				assign fmt_outputs[(fmt * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)] = fpnew_pkg_DONT_CARE;
			end
		end
	endgenerate
	function automatic [31:0] fpnew_pkg_get_num_regs_multi;
		input reg [159:0] regs;
		input reg [9:0] types;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_10
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i] && (types[(4 - i) * 2+:2] == 2'd2))
						res = fpnew_pkg_maximum(res, regs[(4 - i) * 32+:32]);
			end
			fpnew_pkg_get_num_regs_multi = res;
		end
	endfunction
	generate
		if (fpnew_pkg_any_enabled_multi(FmtUnitTypes, FpFmtMask)) begin : gen_merged_slice
			localparam FMT = fpnew_pkg_get_first_enabled_multi(FmtUnitTypes, FpFmtMask);
			localparam REG = fpnew_pkg_get_num_regs_multi(FmtPipeRegs, FmtUnitTypes, FpFmtMask);
			wire in_valid;
			assign in_valid = in_valid_i & (FmtUnitTypes[(4 - dst_fmt_i) * 2+:2] == 2'd2);
			localparam [31:0] sv2v_uu_i_multifmt_slice_NumPipeRegs = REG;
			localparam [31:0] sv2v_uu_i_multifmt_slice_ExtRegEnaWidth = (sv2v_uu_i_multifmt_slice_NumPipeRegs == 0 ? 1 : sv2v_uu_i_multifmt_slice_NumPipeRegs);
			localparam [sv2v_uu_i_multifmt_slice_ExtRegEnaWidth - 1:0] sv2v_uu_i_multifmt_slice_ext_reg_ena_i_0 = 1'sb0;
			fpnew_opgroup_multifmt_slice_B17D8 #(
				.OpGroup(OpGroup),
				.Width(Width),
				.FpFmtConfig(FpFmtMask),
				.IntFmtConfig(IntFmtMask),
				.EnableVectors(EnableVectors),
				.PulpDivsqrt(PulpDivsqrt),
				.NumPipeRegs(REG),
				.PipeConfig(PipeConfig)
			) i_multifmt_slice(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.operands_i(operands_i),
				.is_boxed_i(is_boxed_i),
				.rnd_mode_i(rnd_mode_i),
				.op_i(op_i),
				.op_mod_i(op_mod_i),
				.src_fmt_i(src_fmt_i),
				.dst_fmt_i(dst_fmt_i),
				.int_fmt_i(int_fmt_i),
				.vectorial_op_i(vectorial_op_i),
				.tag_i(tag_i),
				.simd_mask_i(simd_mask_i),
				.in_valid_i(in_valid),
				.in_ready_o(fmt_in_ready[FMT]),
				.flush_i(flush_i),
				.result_o(fmt_outputs[((Width + 6) >= 0 ? (FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6)) : (((FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? Width + 6 : (Width + 6) - (Width + 6))) + ((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))) - 1)-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))]),
				.status_o(fmt_outputs[((Width + 6) >= 0 ? (FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0) : ((FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 6 : Width + 0)) + 4)-:5]),
				.extension_bit_o(fmt_outputs[(FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 1 : Width + 5)]),
				.tag_o(fmt_outputs[(FMT * ((Width + 6) >= 0 ? Width + 7 : 1 - (Width + 6))) + ((Width + 6) >= 0 ? 0 : Width + 6)]),
				.out_valid_o(fmt_out_valid[FMT]),
				.out_ready_i(fmt_out_ready[FMT]),
				.busy_o(fmt_busy[FMT]),
				.reg_ena_i(sv2v_uu_i_multifmt_slice_ext_reg_ena_i_0)
			);
		end
	endgenerate
	wire [Width + 6:0] arbiter_output;
	localparam [31:0] sv2v_uu_i_arbiter_NumIn = NUM_FORMATS;
	localparam [31:0] sv2v_uu_i_arbiter_IdxWidth = $unsigned(3);
	localparam [sv2v_uu_i_arbiter_IdxWidth - 1:0] sv2v_uu_i_arbiter_ext_rr_i_0 = 1'sb0;
	rr_arb_tree_FF0CA_81131 #(
		.DataType_Width(Width),
		.NumIn(NUM_FORMATS),
		.AxiVldRdy(1'b1)
	) i_arbiter(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.rr_i(sv2v_uu_i_arbiter_ext_rr_i_0),
		.req_i(fmt_out_valid),
		.gnt_o(fmt_out_ready),
		.data_i(fmt_outputs),
		.gnt_i(out_ready_i),
		.req_o(out_valid_o),
		.data_o(arbiter_output),
		.idx_o()
	);
	assign result_o = arbiter_output[Width + 6-:((Width + 6) >= 7 ? Width + 0 : 8 - (Width + 6))];
	assign status_o = arbiter_output[6-:5];
	assign extension_bit_o = arbiter_output[1];
	assign tag_o = arbiter_output[0];
	assign busy_o = |fmt_busy;
	initial _sv2v_0 = 0;
endmodule
module fpnew_opgroup_fmt_slice_B0DD3 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	reg _sv2v_0;
	parameter [1:0] OpGroup = 2'd0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	parameter [2:0] FpFormat = sv2v_cast_9FB13(0);
	parameter [31:0] Width = 32;
	parameter [0:0] EnableVectors = 1'b1;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	parameter [0:0] ExtRegEna = 1'b0;
	parameter [31:0] TrueSIMDClass = 0;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		(* full_case, parallel_case *)
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	localparam [31:0] NUM_OPERANDS = fpnew_pkg_num_operands(OpGroup);
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic [31:0] fpnew_pkg_num_lanes;
		input reg [31:0] width;
		input reg [2:0] fmt;
		input reg vec;
		fpnew_pkg_num_lanes = (vec ? width / fpnew_pkg_fp_width(fmt) : 1);
	endfunction
	localparam [31:0] NUM_LANES = fpnew_pkg_num_lanes(Width, FpFormat, EnableVectors);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * Width) - 1:0] operands_i;
	input wire [NUM_OPERANDS - 1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NUM_LANES - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [Width - 1:0] result_o;
	output reg [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(FpFormat);
	localparam [31:0] SIMD_WIDTH = $unsigned(Width / NUM_LANES);
	wire [NUM_LANES - 1:0] lane_in_ready;
	wire [NUM_LANES - 1:0] lane_out_valid;
	wire vectorial_op;
	wire [(NUM_LANES * FP_WIDTH) - 1:0] slice_result;
	wire [Width - 1:0] slice_regular_result;
	wire [Width - 1:0] slice_class_result;
	wire [Width - 1:0] slice_vec_class_result;
	wire [(NUM_LANES * 5) - 1:0] lane_status;
	wire [NUM_LANES - 1:0] lane_ext_bit;
	wire [(NUM_LANES * 10) - 1:0] lane_class_mask;
	wire [NUM_LANES - 1:0] lane_tags;
	wire [NUM_LANES - 1:0] lane_masks;
	wire [NUM_LANES - 1:0] lane_vectorial;
	wire [NUM_LANES - 1:0] lane_busy;
	wire [NUM_LANES - 1:0] lane_is_class;
	wire result_is_vector;
	wire result_is_class;
	assign in_ready_o = lane_in_ready[0];
	assign vectorial_op = vectorial_op_i & EnableVectors;
	genvar _gv_lane_1;
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (_gv_lane_1 = 0; _gv_lane_1 < sv2v_cast_32_signed(NUM_LANES); _gv_lane_1 = _gv_lane_1 + 1) begin : gen_num_lanes
			localparam lane = _gv_lane_1;
			wire [FP_WIDTH - 1:0] local_result;
			wire local_sign;
			if ((lane == 0) || EnableVectors) begin : active_lane
				wire in_valid;
				wire out_valid;
				wire out_ready;
				reg [(NUM_OPERANDS * FP_WIDTH) - 1:0] local_operands;
				wire [FP_WIDTH - 1:0] op_result;
				wire [4:0] op_status;
				assign in_valid = in_valid_i & ((lane == 0) | vectorial_op);
				always @(*) begin : prepare_input
					if (_sv2v_0)
						;
					begin : sv2v_autoblock_1
						reg signed [31:0] i;
						for (i = 0; i < sv2v_cast_32_signed(NUM_OPERANDS); i = i + 1)
							local_operands[i * FP_WIDTH+:FP_WIDTH] = operands_i[(i * Width) + (((($unsigned(lane) + 1) * FP_WIDTH) - 1) >= ($unsigned(lane) * FP_WIDTH) ? (($unsigned(lane) + 1) * FP_WIDTH) - 1 : (((($unsigned(lane) + 1) * FP_WIDTH) - 1) + (((($unsigned(lane) + 1) * FP_WIDTH) - 1) >= ($unsigned(lane) * FP_WIDTH) ? (((($unsigned(lane) + 1) * FP_WIDTH) - 1) - ($unsigned(lane) * FP_WIDTH)) + 1 : (($unsigned(lane) * FP_WIDTH) - ((($unsigned(lane) + 1) * FP_WIDTH) - 1)) + 1)) - 1)-:(((($unsigned(lane) + 1) * FP_WIDTH) - 1) >= ($unsigned(lane) * FP_WIDTH) ? (((($unsigned(lane) + 1) * FP_WIDTH) - 1) - ($unsigned(lane) * FP_WIDTH)) + 1 : (($unsigned(lane) * FP_WIDTH) - ((($unsigned(lane) + 1) * FP_WIDTH) - 1)) + 1)];
					end
				end
				if (OpGroup == 2'd0) begin : lane_instance
					fpnew_fma_90763 #(
						.FpFormat(FpFormat),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_fma(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands),
						.is_boxed_i(is_boxed_i[NUM_OPERANDS - 1:0]),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(vectorial_op),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_vectorial[lane]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
					assign lane_is_class[lane] = 1'b0;
					assign lane_class_mask[lane * 10+:10] = 10'b0000000001;
				end
				else if (OpGroup == 2'd1) begin
					;
				end
				else if (OpGroup == 2'd2) begin : lane_instance
					fpnew_noncomp_C2090 #(
						.FpFormat(FpFormat),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_noncomp(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands),
						.is_boxed_i(is_boxed_i[NUM_OPERANDS - 1:0]),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(vectorial_op),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.class_mask_o(lane_class_mask[lane * 10+:10]),
						.is_class_o(lane_is_class[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_vectorial[lane]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
				end
				assign out_ready = out_ready_i & ((lane == 0) | result_is_vector);
				assign lane_out_valid[lane] = out_valid & ((lane == 0) | result_is_vector);
				assign local_result = (lane_out_valid[lane] | ExtRegEna ? op_result : {FP_WIDTH {lane_ext_bit[0]}});
				assign lane_status[lane * 5+:5] = (lane_out_valid[lane] | ExtRegEna ? op_status : {5 {1'sb0}});
			end
			else begin : genblk1
				assign lane_out_valid[lane] = 1'b0;
				assign lane_in_ready[lane] = 1'b0;
				assign local_result = {FP_WIDTH {lane_ext_bit[0]}};
				assign lane_status[lane * 5+:5] = 1'sb0;
				assign lane_busy[lane] = 1'b0;
				assign lane_is_class[lane] = 1'b0;
			end
			assign slice_result[(($unsigned(lane) + 1) * FP_WIDTH) - 1:$unsigned(lane) * FP_WIDTH] = local_result;
			if (TrueSIMDClass && (SIMD_WIDTH >= 10)) begin : vectorial_true_class
				assign slice_vec_class_result[lane * SIMD_WIDTH+:10] = lane_class_mask[lane * 10+:10];
				assign slice_vec_class_result[((lane + 1) * SIMD_WIDTH) - 1-:SIMD_WIDTH - 10] = 1'sb0;
			end
			else if (((lane + 1) * 8) <= Width) begin : vectorial_class
				assign local_sign = (((lane_class_mask[lane * 10+:10] == 10'b0000000001) || (lane_class_mask[lane * 10+:10] == 10'b0000000010)) || (lane_class_mask[lane * 10+:10] == 10'b0000000100)) || (lane_class_mask[lane * 10+:10] == 10'b0000001000);
				assign slice_vec_class_result[((lane + 1) * 8) - 1:lane * 8] = {local_sign, ~local_sign, lane_class_mask[lane * 10+:10] == 10'b1000000000, lane_class_mask[lane * 10+:10] == 10'b0100000000, (lane_class_mask[lane * 10+:10] == 10'b0000010000) || (lane_class_mask[lane * 10+:10] == 10'b0000001000), (lane_class_mask[lane * 10+:10] == 10'b0000100000) || (lane_class_mask[lane * 10+:10] == 10'b0000000100), (lane_class_mask[lane * 10+:10] == 10'b0001000000) || (lane_class_mask[lane * 10+:10] == 10'b0000000010), (lane_class_mask[lane * 10+:10] == 10'b0010000000) || (lane_class_mask[lane * 10+:10] == 10'b0000000001)};
			end
		end
	endgenerate
	assign result_is_vector = lane_vectorial[0];
	assign result_is_class = lane_is_class[0];
	assign slice_regular_result = $signed({extension_bit_o, slice_result});
	localparam [31:0] CLASS_VEC_BITS = ((NUM_LANES * 8) > Width ? 8 * (Width / 8) : NUM_LANES * 8);
	generate
		if (!(TrueSIMDClass && (SIMD_WIDTH >= 10))) begin : genblk2
			if (CLASS_VEC_BITS < Width) begin : pad_vectorial_class
				assign slice_vec_class_result[Width - 1:CLASS_VEC_BITS] = 1'sb0;
			end
		end
	endgenerate
	assign slice_class_result = (result_is_vector ? slice_vec_class_result : lane_class_mask[0+:10]);
	assign result_o = (result_is_class ? slice_class_result : slice_regular_result);
	assign extension_bit_o = lane_ext_bit[0];
	assign tag_o = lane_tags[0];
	assign busy_o = |lane_busy;
	assign out_valid_o = lane_out_valid[0];
	always @(*) begin : output_processing
		reg [4:0] temp_status;
		if (_sv2v_0)
			;
		temp_status = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < sv2v_cast_32_signed(NUM_LANES); i = i + 1)
				temp_status = temp_status | (lane_status[i * 5+:5] & {5 {lane_masks[i]}});
		end
		status_o = temp_status;
	end
	initial _sv2v_0 = 0;
endmodule
module fpnew_opgroup_multifmt_slice_B17D8 (
	clk_i,
	rst_ni,
	operands_i,
	is_boxed_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	int_fmt_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	extension_bit_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o,
	reg_ena_i
);
	reg _sv2v_0;
	parameter [1:0] OpGroup = 2'd3;
	parameter [31:0] Width = 64;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	parameter [0:4] FpFmtConfig = 1'sb1;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	parameter [0:3] IntFmtConfig = 1'sb1;
	parameter [0:0] EnableVectors = 1'b1;
	parameter [0:0] PulpDivsqrt = 1'b1;
	parameter [31:0] NumPipeRegs = 0;
	parameter [1:0] PipeConfig = 2'd0;
	parameter [0:0] ExtRegEna = 1'b0;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		(* full_case, parallel_case *)
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	localparam [31:0] NUM_OPERANDS = fpnew_pkg_num_operands(OpGroup);
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	function automatic signed [31:0] fpnew_pkg_minimum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_minimum = (a < b ? a : b);
	endfunction
	function automatic [31:0] fpnew_pkg_min_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = fpnew_pkg_max_fp_width(cfg);
			begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_minimum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_min_fp_width = res;
		end
	endfunction
	function automatic [31:0] fpnew_pkg_max_num_lanes;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg vec;
		fpnew_pkg_max_num_lanes = (vec ? width / fpnew_pkg_min_fp_width(cfg) : 1);
	endfunction
	localparam [31:0] NUM_SIMD_LANES = fpnew_pkg_max_num_lanes(Width, FpFmtConfig, EnableVectors);
	localparam [31:0] ExtRegEnaWidth = (NumPipeRegs == 0 ? 1 : NumPipeRegs);
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * Width) - 1:0] operands_i;
	input wire [(NUM_FORMATS * NUM_OPERANDS) - 1:0] is_boxed_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	input wire [1:0] int_fmt_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NUM_SIMD_LANES - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [Width - 1:0] result_o;
	output reg [4:0] status_o;
	output wire extension_bit_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	input wire [ExtRegEnaWidth - 1:0] reg_ena_i;
	generate
		if (((OpGroup == 2'd1) && !PulpDivsqrt) && !((FpFmtConfig[0] == 1) && (FpFmtConfig[1:4] == {4 {1'sb0}}))) begin : genblk1
			initial begin
				$display("Fatal [elaboration] ./vendor/pulp_platform_fpnew/src/fpnew_opgroup_multifmt_slice.sv:71:5 - fpnew_opgroup_multifmt_slice.genblk1\n msg: ", "T-Head-based DivSqrt unit supported only in FP32-only configurations. Set PulpDivsqrt to 1 not to use the PULP DivSqrt unit or set Features.FpFmtMask to support only FP32");
				$finish(1);
			end
		end
	endgenerate
	localparam [31:0] MAX_FP_WIDTH = fpnew_pkg_max_fp_width(FpFmtConfig);
	function automatic [1:0] sv2v_cast_2D3A8;
		input reg [1:0] inp;
		sv2v_cast_2D3A8 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_int_width;
		input reg [1:0] ifmt;
		(* full_case, parallel_case *)
		case (ifmt)
			sv2v_cast_2D3A8(0): fpnew_pkg_int_width = 8;
			sv2v_cast_2D3A8(1): fpnew_pkg_int_width = 16;
			sv2v_cast_2D3A8(2): fpnew_pkg_int_width = 32;
			sv2v_cast_2D3A8(3): fpnew_pkg_int_width = 64;
			default: begin
				$display("Fatal [%0t] ./vendor/pulp_platform_fpnew/src/fpnew_pkg.sv:96:9 - fpnew_opgroup_multifmt_slice.fpnew_pkg_int_width.<unnamed_block>\n msg: ", $time, "Invalid INT format supplied");
				$finish(1);
				fpnew_pkg_int_width = sv2v_cast_2D3A8(0);
			end
		endcase
	endfunction
	function automatic [31:0] fpnew_pkg_max_int_width;
		input reg [0:3] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_3
				reg signed [31:0] ifmt;
				for (ifmt = 0; ifmt < fpnew_pkg_NUM_INT_FORMATS; ifmt = ifmt + 1)
					if (cfg[ifmt])
						res = fpnew_pkg_maximum(res, fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt)));
			end
			fpnew_pkg_max_int_width = res;
		end
	endfunction
	localparam [31:0] MAX_INT_WIDTH = fpnew_pkg_max_int_width(IntFmtConfig);
	localparam [31:0] NUM_LANES = fpnew_pkg_max_num_lanes(Width, FpFmtConfig, 1'b1);
	localparam [31:0] NUM_INT_FORMATS = fpnew_pkg_NUM_INT_FORMATS;
	localparam [31:0] FMT_BITS = fpnew_pkg_maximum(3, 2);
	localparam [31:0] AUX_BITS = FMT_BITS + 2;
	wire [NUM_LANES - 1:0] lane_in_ready;
	wire [NUM_LANES - 1:0] lane_out_valid;
	wire [NUM_LANES - 1:0] divsqrt_done;
	wire [NUM_LANES - 1:0] divsqrt_ready;
	wire vectorial_op;
	wire [FMT_BITS - 1:0] dst_fmt;
	wire [AUX_BITS - 1:0] aux_data;
	wire dst_fmt_is_int;
	wire dst_is_cpk;
	wire [1:0] dst_vec_op;
	wire [2:0] target_aux_d;
	wire is_up_cast;
	wire is_down_cast;
	wire [(NUM_FORMATS * Width) - 1:0] fmt_slice_result;
	wire [(NUM_INT_FORMATS * Width) - 1:0] ifmt_slice_result;
	wire [Width - 1:0] conv_target_d;
	wire [Width - 1:0] conv_target_q;
	wire [(NUM_LANES * 5) - 1:0] lane_status;
	wire [NUM_LANES - 1:0] lane_ext_bit;
	wire [NUM_LANES - 1:0] lane_tags;
	wire [NUM_LANES - 1:0] lane_masks;
	wire [(NUM_LANES * AUX_BITS) - 1:0] lane_aux;
	wire [NUM_LANES - 1:0] lane_busy;
	wire result_is_vector;
	wire [FMT_BITS - 1:0] result_fmt;
	wire result_fmt_is_int;
	wire result_is_cpk;
	wire [1:0] result_vec_op;
	wire simd_synch_rdy;
	wire simd_synch_done;
	assign in_ready_o = lane_in_ready[0];
	assign vectorial_op = vectorial_op_i & EnableVectors;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	assign dst_fmt_is_int = (OpGroup == 2'd3) & (op_i == sv2v_cast_7BCAE(11));
	assign dst_is_cpk = (OpGroup == 2'd3) & ((op_i == sv2v_cast_7BCAE(13)) || (op_i == sv2v_cast_7BCAE(14)));
	assign dst_vec_op = (OpGroup == 2'd3) & {op_i == sv2v_cast_7BCAE(14), op_mod_i};
	assign is_up_cast = fpnew_pkg_fp_width(dst_fmt_i) > fpnew_pkg_fp_width(src_fmt_i);
	assign is_down_cast = fpnew_pkg_fp_width(dst_fmt_i) < fpnew_pkg_fp_width(src_fmt_i);
	assign dst_fmt = (dst_fmt_is_int ? int_fmt_i : dst_fmt_i);
	assign aux_data = {dst_fmt_is_int, vectorial_op, dst_fmt};
	assign target_aux_d = {dst_vec_op, dst_is_cpk};
	generate
		if (OpGroup == 2'd3) begin : conv_target
			assign conv_target_d = (dst_is_cpk ? operands_i[2 * Width+:Width] : operands_i[Width+:Width]);
		end
		else begin : not_conv_target
			assign conv_target_d = 1'sb0;
		end
	endgenerate
	reg [4:0] is_boxed_1op;
	reg [9:0] is_boxed_2op;
	always @(*) begin : boxed_2op
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_4
			reg signed [31:0] fmt;
			for (fmt = 0; fmt < NUM_FORMATS; fmt = fmt + 1)
				begin
					is_boxed_1op[fmt] = is_boxed_i[fmt * NUM_OPERANDS];
					is_boxed_2op[fmt * 2+:2] = is_boxed_i[(fmt * NUM_OPERANDS) + 1-:2];
				end
		end
	end
	genvar _gv_lane_2;
	localparam [0:4] fpnew_pkg_CPK_FORMATS = 5'b11000;
	function automatic [0:4] fpnew_pkg_get_conv_lane_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [31:0] lane_no;
		reg [0:4] res;
		begin
			begin : sv2v_autoblock_5
				reg [31:0] fmt;
				for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
					res[fmt] = cfg[fmt] && (((width / fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt))) > lane_no) || (fpnew_pkg_CPK_FORMATS[fmt] && (lane_no < 2)));
			end
			fpnew_pkg_get_conv_lane_formats = res;
		end
	endfunction
	function automatic [0:3] fpnew_pkg_get_conv_lane_int_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [0:3] icfg;
		input reg [31:0] lane_no;
		reg [0:3] res;
		reg [0:4] lanefmts;
		begin
			res = 1'sb0;
			lanefmts = fpnew_pkg_get_conv_lane_formats(width, cfg, lane_no);
			begin : sv2v_autoblock_6
				reg [31:0] ifmt;
				for (ifmt = 0; ifmt < fpnew_pkg_NUM_INT_FORMATS; ifmt = ifmt + 1)
					begin : sv2v_autoblock_7
						reg [31:0] fmt;
						for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
							res[ifmt] = res[ifmt] | ((icfg[ifmt] && lanefmts[fmt]) && (fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt)) == fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt))));
					end
			end
			fpnew_pkg_get_conv_lane_int_formats = res;
		end
	endfunction
	function automatic [0:4] fpnew_pkg_get_lane_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [31:0] lane_no;
		reg [0:4] res;
		begin
			begin : sv2v_autoblock_8
				reg [31:0] fmt;
				for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
					res[fmt] = cfg[fmt] & ((width / fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt))) > lane_no);
			end
			fpnew_pkg_get_lane_formats = res;
		end
	endfunction
	function automatic [0:3] fpnew_pkg_get_lane_int_formats;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg [0:3] icfg;
		input reg [31:0] lane_no;
		reg [0:3] res;
		reg [0:4] lanefmts;
		begin
			res = 1'sb0;
			lanefmts = fpnew_pkg_get_lane_formats(width, cfg, lane_no);
			begin : sv2v_autoblock_9
				reg [31:0] ifmt;
				for (ifmt = 0; ifmt < fpnew_pkg_NUM_INT_FORMATS; ifmt = ifmt + 1)
					begin : sv2v_autoblock_10
						reg [31:0] fmt;
						for (fmt = 0; fmt < fpnew_pkg_NUM_FP_FORMATS; fmt = fmt + 1)
							if (fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt)) == fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt)))
								res[ifmt] = res[ifmt] | (icfg[ifmt] && lanefmts[fmt]);
					end
			end
			fpnew_pkg_get_lane_int_formats = res;
		end
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_D5AB9;
		input reg [4:0] inp;
		sv2v_cast_D5AB9 = inp;
	endfunction
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (_gv_lane_2 = 0; _gv_lane_2 < sv2v_cast_32_signed(NUM_LANES); _gv_lane_2 = _gv_lane_2 + 1) begin : gen_num_lanes
			localparam lane = _gv_lane_2;
			localparam [31:0] LANE = $unsigned(lane);
			localparam [0:4] ACTIVE_FORMATS = fpnew_pkg_get_lane_formats(Width, FpFmtConfig, LANE);
			localparam [0:3] ACTIVE_INT_FORMATS = fpnew_pkg_get_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
			localparam [31:0] MAX_WIDTH = fpnew_pkg_max_fp_width(ACTIVE_FORMATS);
			localparam [0:4] CONV_FORMATS = fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, LANE);
			localparam [0:3] CONV_INT_FORMATS = fpnew_pkg_get_conv_lane_int_formats(Width, FpFmtConfig, IntFmtConfig, LANE);
			localparam [31:0] CONV_WIDTH = fpnew_pkg_max_fp_width(CONV_FORMATS);
			localparam [0:4] LANE_FORMATS = (OpGroup == 2'd3 ? CONV_FORMATS : ACTIVE_FORMATS);
			localparam [31:0] LANE_WIDTH = (OpGroup == 2'd3 ? CONV_WIDTH : MAX_WIDTH);
			wire [LANE_WIDTH - 1:0] local_result;
			if ((lane == 0) || EnableVectors) begin : active_lane
				wire in_valid;
				wire out_valid;
				wire out_ready;
				reg [(NUM_OPERANDS * LANE_WIDTH) - 1:0] local_operands;
				wire [LANE_WIDTH - 1:0] op_result;
				wire [4:0] op_status;
				assign in_valid = in_valid_i & ((lane == 0) | vectorial_op);
				always @(*) begin : prepare_input
					if (_sv2v_0)
						;
					begin : sv2v_autoblock_11
						reg [31:0] i;
						for (i = 0; i < NUM_OPERANDS; i = i + 1)
							if (i == 2)
								local_operands[i * (OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))] = operands_i[i * Width+:Width] >> (LANE * fpnew_pkg_fp_width(dst_fmt_i));
							else
								local_operands[i * (OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))] = operands_i[i * Width+:Width] >> (LANE * fpnew_pkg_fp_width(src_fmt_i));
					end
					if (OpGroup == 2'd3) begin
						if (op_i == sv2v_cast_7BCAE(12))
							local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))] = operands_i[0+:Width] >> (LANE * fpnew_pkg_int_width(int_fmt_i));
						else if (op_i == sv2v_cast_7BCAE(10)) begin
							if ((vectorial_op && op_mod_i) && is_up_cast)
								local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))] = operands_i[0+:Width] >> ((LANE * fpnew_pkg_fp_width(src_fmt_i)) + (MAX_FP_WIDTH / 2));
						end
						else if (dst_is_cpk) begin
							if (lane == 1)
								local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))] = operands_i[Width + (LANE_WIDTH - 1)-:LANE_WIDTH];
						end
					end
				end
				if (OpGroup == 2'd0) begin : lane_instance
					fpnew_fma_multi_CA122_A2E8D #(
						.AuxType_AUX_BITS(AUX_BITS),
						.FpFmtConfig(LANE_FORMATS),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_fpnew_fma_multi(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands),
						.is_boxed_i(is_boxed_i),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.src_fmt_i(src_fmt_i),
						.dst_fmt_i(dst_fmt_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(aux_data),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
				end
				else if (OpGroup == 2'd1) begin : lane_instance
					if ((!PulpDivsqrt && LANE_FORMATS[0]) && (LANE_FORMATS[1:4] == {4 {1'sb0}})) begin : genblk1
						fpnew_divsqrt_th_32_A4710_B4B7A #(
							.AuxType_AUX_BITS(AUX_BITS),
							.NumPipeRegs(NumPipeRegs),
							.PipeConfig(PipeConfig)
						) i_fpnew_divsqrt_multi_th(
							.clk_i(clk_i),
							.rst_ni(rst_ni),
							.operands_i(local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2))))) * 2]),
							.is_boxed_i(is_boxed_2op),
							.rnd_mode_i(rnd_mode_i),
							.op_i(op_i),
							.tag_i(tag_i),
							.mask_i(simd_mask_i[lane]),
							.aux_i(aux_data),
							.in_valid_i(in_valid),
							.in_ready_o(lane_in_ready[lane]),
							.flush_i(flush_i),
							.result_o(op_result),
							.status_o(op_status),
							.extension_bit_o(lane_ext_bit[lane]),
							.tag_o(lane_tags[lane]),
							.mask_o(lane_masks[lane]),
							.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
							.out_valid_o(out_valid),
							.out_ready_i(out_ready),
							.busy_o(lane_busy[lane]),
							.reg_ena_i(reg_ena_i)
						);
					end
					else begin : genblk1
						fpnew_divsqrt_multi_4A1A6_75781 #(
							.AuxType_AUX_BITS(AUX_BITS),
							.FpFmtConfig(LANE_FORMATS),
							.NumPipeRegs(NumPipeRegs),
							.PipeConfig(PipeConfig)
						) i_fpnew_divsqrt_multi(
							.clk_i(clk_i),
							.rst_ni(rst_ni),
							.operands_i(local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2))))) * 2]),
							.is_boxed_i(is_boxed_2op),
							.rnd_mode_i(rnd_mode_i),
							.op_i(op_i),
							.dst_fmt_i(dst_fmt_i),
							.tag_i(tag_i),
							.mask_i(simd_mask_i[lane]),
							.aux_i(aux_data),
							.vectorial_op_i(vectorial_op),
							.in_valid_i(in_valid),
							.in_ready_o(lane_in_ready[lane]),
							.divsqrt_done_o(divsqrt_done[lane]),
							.simd_synch_done_i(simd_synch_done),
							.divsqrt_ready_o(divsqrt_ready[lane]),
							.simd_synch_rdy_i(simd_synch_rdy),
							.flush_i(flush_i),
							.result_o(op_result),
							.status_o(op_status),
							.extension_bit_o(lane_ext_bit[lane]),
							.tag_o(lane_tags[lane]),
							.mask_o(lane_masks[lane]),
							.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
							.out_valid_o(out_valid),
							.out_ready_i(out_ready),
							.busy_o(lane_busy[lane]),
							.reg_ena_i(reg_ena_i)
						);
					end
				end
				else if (OpGroup == 2'd2) begin
					;
				end
				else if (OpGroup == 2'd3) begin : lane_instance
					fpnew_cast_multi_3E15B_08E4E #(
						.AuxType_AUX_BITS(AUX_BITS),
						.FpFmtConfig(LANE_FORMATS),
						.IntFmtConfig(CONV_INT_FORMATS),
						.NumPipeRegs(NumPipeRegs),
						.PipeConfig(PipeConfig)
					) i_fpnew_cast_multi(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.operands_i(local_operands[0+:(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))) : fpnew_pkg_max_fp_width(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))]),
						.is_boxed_i(is_boxed_1op),
						.rnd_mode_i(rnd_mode_i),
						.op_i(op_i),
						.op_mod_i(op_mod_i),
						.src_fmt_i(src_fmt_i),
						.dst_fmt_i(dst_fmt_i),
						.int_fmt_i(int_fmt_i),
						.tag_i(tag_i),
						.mask_i(simd_mask_i[lane]),
						.aux_i(aux_data),
						.in_valid_i(in_valid),
						.in_ready_o(lane_in_ready[lane]),
						.flush_i(flush_i),
						.result_o(op_result),
						.status_o(op_status),
						.extension_bit_o(lane_ext_bit[lane]),
						.tag_o(lane_tags[lane]),
						.mask_o(lane_masks[lane]),
						.aux_o(lane_aux[lane * AUX_BITS+:AUX_BITS]),
						.out_valid_o(out_valid),
						.out_ready_i(out_ready),
						.busy_o(lane_busy[lane]),
						.reg_ena_i(reg_ena_i)
					);
				end
				assign out_ready = out_ready_i & ((lane == 0) | result_is_vector);
				assign lane_out_valid[lane] = out_valid & ((lane == 0) | result_is_vector);
				assign local_result = (lane_out_valid[lane] | ExtRegEna ? op_result : {(OpGroup == 2'd3 ? fpnew_pkg_max_fp_width(sv2v_cast_D5AB9(fpnew_pkg_get_conv_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2))))) : fpnew_pkg_max_fp_width(sv2v_cast_D5AB9(fpnew_pkg_get_lane_formats(Width, FpFmtConfig, sv2v_cast_32($unsigned(_gv_lane_2)))))) {lane_ext_bit[0]}});
				assign lane_status[lane * 5+:5] = (lane_out_valid[lane] | ExtRegEna ? op_status : {5 {1'sb0}});
			end
			else begin : inactive_lane
				assign lane_out_valid[lane] = 1'b0;
				assign lane_in_ready[lane] = 1'b0;
				assign lane_aux[lane * AUX_BITS+:AUX_BITS] = 1'b0;
				assign lane_masks[lane] = 1'b1;
				assign lane_tags[lane] = 1'b0;
				assign divsqrt_done[lane] = 1'b0;
				assign divsqrt_ready[lane] = 1'b0;
				assign lane_ext_bit[lane] = 1'b1;
				assign local_result = {LANE_WIDTH {lane_ext_bit[0]}};
				assign lane_status[lane * 5+:5] = 1'sb0;
				assign lane_busy[lane] = 1'b0;
			end
			genvar _gv_fmt_10;
			for (_gv_fmt_10 = 0; _gv_fmt_10 < NUM_FORMATS; _gv_fmt_10 = _gv_fmt_10 + 1) begin : pack_fp_result
				localparam fmt = _gv_fmt_10;
				localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
				if (ACTIVE_FORMATS[fmt]) begin : genblk1
					assign fmt_slice_result[(fmt * Width) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((LANE + 1) * FP_WIDTH) - 1 : ((((LANE + 1) * FP_WIDTH) - 1) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)] = local_result[FP_WIDTH - 1:0];
				end
				else if (((LANE + 1) * FP_WIDTH) <= Width) begin : genblk1
					assign fmt_slice_result[(fmt * Width) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((LANE + 1) * FP_WIDTH) - 1 : ((((LANE + 1) * FP_WIDTH) - 1) + ((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1)] = {((((LANE + 1) * FP_WIDTH) - 1) >= (LANE * FP_WIDTH) ? ((((LANE + 1) * FP_WIDTH) - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (((LANE + 1) * FP_WIDTH) - 1)) + 1) {lane_ext_bit[LANE]}};
				end
				else if ((LANE * FP_WIDTH) < Width) begin : genblk1
					assign fmt_slice_result[(fmt * Width) + ((Width - 1) >= (LANE * FP_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (LANE * FP_WIDTH) ? ((Width - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (LANE * FP_WIDTH) ? ((Width - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (Width - 1)) + 1)] = {((Width - 1) >= (LANE * FP_WIDTH) ? ((Width - 1) - (LANE * FP_WIDTH)) + 1 : ((LANE * FP_WIDTH) - (Width - 1)) + 1) {lane_ext_bit[LANE]}};
				end
			end
			if (OpGroup == 2'd3) begin : int_results_enabled
				genvar _gv_ifmt_5;
				for (_gv_ifmt_5 = 0; _gv_ifmt_5 < NUM_INT_FORMATS; _gv_ifmt_5 = _gv_ifmt_5 + 1) begin : pack_int_result
					localparam ifmt = _gv_ifmt_5;
					localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt));
					if (ACTIVE_INT_FORMATS[ifmt]) begin : genblk1
						assign ifmt_slice_result[(ifmt * Width) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((LANE + 1) * INT_WIDTH) - 1 : ((((LANE + 1) * INT_WIDTH) - 1) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)] = local_result[INT_WIDTH - 1:0];
					end
					else if (((LANE + 1) * INT_WIDTH) <= Width) begin : genblk1
						assign ifmt_slice_result[(ifmt * Width) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((LANE + 1) * INT_WIDTH) - 1 : ((((LANE + 1) * INT_WIDTH) - 1) + ((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)) - 1)-:((((LANE + 1) * INT_WIDTH) - 1) >= (LANE * INT_WIDTH) ? ((((LANE + 1) * INT_WIDTH) - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (((LANE + 1) * INT_WIDTH) - 1)) + 1)] = 1'sb0;
					end
					else if ((LANE * INT_WIDTH) < Width) begin : genblk1
						assign ifmt_slice_result[(ifmt * Width) + ((Width - 1) >= (LANE * INT_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (LANE * INT_WIDTH) ? ((Width - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (LANE * INT_WIDTH) ? ((Width - 1) - (LANE * INT_WIDTH)) + 1 : ((LANE * INT_WIDTH) - (Width - 1)) + 1)] = 1'sb0;
					end
				end
			end
		end
	endgenerate
	genvar _gv_fmt_11;
	generate
		for (_gv_fmt_11 = 0; _gv_fmt_11 < NUM_FORMATS; _gv_fmt_11 = _gv_fmt_11 + 1) begin : extend_fp_result
			localparam fmt = _gv_fmt_11;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			if ((NUM_LANES * FP_WIDTH) < Width) begin : genblk1
				assign fmt_slice_result[(fmt * Width) + ((Width - 1) >= (NUM_LANES * FP_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (NUM_LANES * FP_WIDTH) ? ((Width - 1) - (NUM_LANES * FP_WIDTH)) + 1 : ((NUM_LANES * FP_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (NUM_LANES * FP_WIDTH) ? ((Width - 1) - (NUM_LANES * FP_WIDTH)) + 1 : ((NUM_LANES * FP_WIDTH) - (Width - 1)) + 1)] = {((Width - 1) >= (NUM_LANES * FP_WIDTH) ? ((Width - 1) - (NUM_LANES * FP_WIDTH)) + 1 : ((NUM_LANES * FP_WIDTH) - (Width - 1)) + 1) {lane_ext_bit[0]}};
			end
		end
	endgenerate
	genvar _gv_ifmt_6;
	generate
		for (_gv_ifmt_6 = 0; _gv_ifmt_6 < NUM_INT_FORMATS; _gv_ifmt_6 = _gv_ifmt_6 + 1) begin : extend_or_mute_int_result
			localparam ifmt = _gv_ifmt_6;
			if (OpGroup != 2'd3) begin : mute_int_result
				assign ifmt_slice_result[ifmt * Width+:Width] = 1'sb0;
			end
			else begin : extend_int_result
				localparam [31:0] INT_WIDTH = fpnew_pkg_int_width(sv2v_cast_2D3A8(ifmt));
				if ((NUM_LANES * INT_WIDTH) < Width) begin : genblk1
					assign ifmt_slice_result[(ifmt * Width) + ((Width - 1) >= (NUM_LANES * INT_WIDTH) ? Width - 1 : ((Width - 1) + ((Width - 1) >= (NUM_LANES * INT_WIDTH) ? ((Width - 1) - (NUM_LANES * INT_WIDTH)) + 1 : ((NUM_LANES * INT_WIDTH) - (Width - 1)) + 1)) - 1)-:((Width - 1) >= (NUM_LANES * INT_WIDTH) ? ((Width - 1) - (NUM_LANES * INT_WIDTH)) + 1 : ((NUM_LANES * INT_WIDTH) - (Width - 1)) + 1)] = 1'sb0;
				end
			end
		end
		if (OpGroup == 2'd3) begin : target_regs
			reg [(0 >= NumPipeRegs ? ((1 - NumPipeRegs) * Width) + ((NumPipeRegs * Width) - 1) : ((NumPipeRegs + 1) * Width) - 1):(0 >= NumPipeRegs ? NumPipeRegs * Width : 0)] byp_pipe_target_q;
			reg [(0 >= NumPipeRegs ? ((1 - NumPipeRegs) * 3) + ((NumPipeRegs * 3) - 1) : ((NumPipeRegs + 1) * 3) - 1):(0 >= NumPipeRegs ? NumPipeRegs * 3 : 0)] byp_pipe_aux_q;
			reg [0:NumPipeRegs] byp_pipe_valid_q;
			wire [0:NumPipeRegs] byp_pipe_ready;
			wire [Width * 1:1] sv2v_tmp_77847;
			assign sv2v_tmp_77847 = conv_target_d;
			always @(*) byp_pipe_target_q[(0 >= NumPipeRegs ? 0 : NumPipeRegs) * Width+:Width] = sv2v_tmp_77847;
			wire [3:1] sv2v_tmp_2A1F7;
			assign sv2v_tmp_2A1F7 = target_aux_d;
			always @(*) byp_pipe_aux_q[(0 >= NumPipeRegs ? 0 : NumPipeRegs) * 3+:3] = sv2v_tmp_2A1F7;
			wire [1:1] sv2v_tmp_5453C;
			assign sv2v_tmp_5453C = in_valid_i & vectorial_op;
			always @(*) byp_pipe_valid_q[0] = sv2v_tmp_5453C;
			genvar _gv_i_52;
			for (_gv_i_52 = 0; _gv_i_52 < NumPipeRegs; _gv_i_52 = _gv_i_52 + 1) begin : gen_bypass_pipeline
				localparam i = _gv_i_52;
				wire reg_ena;
				assign byp_pipe_ready[i] = byp_pipe_ready[i + 1] | ~byp_pipe_valid_q[i + 1];
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						byp_pipe_valid_q[i + 1] <= 1'b0;
					else
						byp_pipe_valid_q[i + 1] <= (flush_i ? 1'b0 : (byp_pipe_ready[i] ? byp_pipe_valid_q[i] : byp_pipe_valid_q[i + 1]));
				assign reg_ena = (byp_pipe_ready[i] & byp_pipe_valid_q[i]) | reg_ena_i[i];
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						byp_pipe_target_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * Width+:Width] <= 1'sb0;
					else
						byp_pipe_target_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * Width+:Width] <= (reg_ena ? byp_pipe_target_q[(0 >= NumPipeRegs ? i : NumPipeRegs - i) * Width+:Width] : byp_pipe_target_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * Width+:Width]);
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						byp_pipe_aux_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * 3+:3] <= 1'sb0;
					else
						byp_pipe_aux_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * 3+:3] <= (reg_ena ? byp_pipe_aux_q[(0 >= NumPipeRegs ? i : NumPipeRegs - i) * 3+:3] : byp_pipe_aux_q[(0 >= NumPipeRegs ? i + 1 : NumPipeRegs - (i + 1)) * 3+:3]);
			end
			assign byp_pipe_ready[NumPipeRegs] = out_ready_i & result_is_vector;
			assign conv_target_q = byp_pipe_target_q[(0 >= NumPipeRegs ? NumPipeRegs : NumPipeRegs - NumPipeRegs) * Width+:Width];
			assign {result_vec_op, result_is_cpk} = byp_pipe_aux_q[(0 >= NumPipeRegs ? NumPipeRegs : NumPipeRegs - NumPipeRegs) * 3+:3];
		end
		else begin : no_conv
			assign {result_vec_op, result_is_cpk} = 1'sb0;
			assign conv_target_q = 1'sb0;
		end
		if (PulpDivsqrt) begin : genblk7
			assign simd_synch_rdy = (EnableVectors ? &divsqrt_ready : divsqrt_ready[0]);
			assign simd_synch_done = (EnableVectors ? &divsqrt_done : divsqrt_done[0]);
		end
		else begin : genblk7
			assign simd_synch_rdy = 1'sb0;
			assign simd_synch_done = 1'sb0;
		end
	endgenerate
	assign {result_fmt_is_int, result_is_vector, result_fmt} = lane_aux[0+:AUX_BITS];
	assign result_o = (result_fmt_is_int ? ifmt_slice_result[result_fmt * Width+:Width] : fmt_slice_result[result_fmt * Width+:Width]);
	assign extension_bit_o = lane_ext_bit[0];
	assign tag_o = lane_tags[0];
	assign busy_o = |lane_busy;
	assign out_valid_o = lane_out_valid[0];
	always @(*) begin : output_processing
		reg [4:0] temp_status;
		if (_sv2v_0)
			;
		temp_status = 1'sb0;
		begin : sv2v_autoblock_12
			reg signed [31:0] i;
			for (i = 0; i < sv2v_cast_32_signed(NUM_LANES); i = i + 1)
				temp_status = temp_status | (lane_status[i * 5+:5] & {5 {lane_masks[i]}});
		end
		status_o = temp_status;
	end
	initial _sv2v_0 = 0;
endmodule
module fpnew_rounding (
	abs_value_i,
	sign_i,
	round_sticky_bits_i,
	rnd_mode_i,
	effective_subtraction_i,
	abs_rounded_o,
	sign_o,
	exact_zero_o
);
	reg _sv2v_0;
	parameter [31:0] AbsWidth = 2;
	input wire [AbsWidth - 1:0] abs_value_i;
	input wire sign_i;
	input wire [1:0] round_sticky_bits_i;
	input wire [2:0] rnd_mode_i;
	input wire effective_subtraction_i;
	output wire [AbsWidth - 1:0] abs_rounded_o;
	output wire sign_o;
	output wire exact_zero_o;
	reg round_up;
	localparam [0:0] fpnew_pkg_DONT_CARE = 1'b1;
	always @(*) begin : rounding_decision
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rnd_mode_i)
			3'b000:
				(* full_case, parallel_case *)
				case (round_sticky_bits_i)
					2'b00, 2'b01: round_up = 1'b0;
					2'b10: round_up = abs_value_i[0];
					2'b11: round_up = 1'b1;
					default: round_up = fpnew_pkg_DONT_CARE;
				endcase
			3'b001: round_up = 1'b0;
			3'b010: round_up = (|round_sticky_bits_i ? sign_i : 1'b0);
			3'b011: round_up = (|round_sticky_bits_i ? ~sign_i : 1'b0);
			3'b100: round_up = round_sticky_bits_i[1];
			3'b101: round_up = ~abs_value_i[0] & |round_sticky_bits_i;
			default: round_up = fpnew_pkg_DONT_CARE;
		endcase
	end
	assign abs_rounded_o = abs_value_i + round_up;
	assign exact_zero_o = (abs_value_i == {AbsWidth {1'sb0}}) && (round_sticky_bits_i == {2 {1'sb0}});
	assign sign_o = (exact_zero_o && effective_subtraction_i ? rnd_mode_i == 3'b010 : sign_i);
	initial _sv2v_0 = 0;
endmodule
module fpnew_top_CBA7B (
	clk_i,
	rst_ni,
	operands_i,
	rnd_mode_i,
	op_i,
	op_mod_i,
	src_fmt_i,
	dst_fmt_i,
	int_fmt_i,
	vectorial_op_i,
	tag_i,
	simd_mask_i,
	in_valid_i,
	in_ready_o,
	flush_i,
	result_o,
	status_o,
	tag_o,
	out_valid_o,
	out_ready_i,
	busy_o
);
	reg _sv2v_0;
	localparam [31:0] fpnew_pkg_NUM_FP_FORMATS = 5;
	localparam [31:0] fpnew_pkg_NUM_INT_FORMATS = 4;
	localparam [42:0] fpnew_pkg_RV64D_Xsflt = 43'h000000207ff;
	parameter [42:0] Features = fpnew_pkg_RV64D_Xsflt;
	localparam [31:0] fpnew_pkg_NUM_OPGROUPS = 4;
	function automatic [159:0] sv2v_cast_A9CF0;
		input reg [159:0] inp;
		sv2v_cast_A9CF0 = inp;
	endfunction
	function automatic [((32'd4 * 32'd5) * 32) - 1:0] sv2v_cast_9CB06;
		input reg [((32'd4 * 32'd5) * 32) - 1:0] inp;
		sv2v_cast_9CB06 = inp;
	endfunction
	function automatic [((32'd4 * 32'd5) * 2) - 1:0] sv2v_cast_2DA10;
		input reg [((32'd4 * 32'd5) * 2) - 1:0] inp;
		sv2v_cast_2DA10 = inp;
	endfunction
	localparam [(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) + ((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2)) + 1:0] fpnew_pkg_DEFAULT_NOREGS = {sv2v_cast_9CB06({fpnew_pkg_NUM_OPGROUPS {sv2v_cast_A9CF0(0)}}), sv2v_cast_2DA10({{fpnew_pkg_NUM_FP_FORMATS {2'd1}}, {fpnew_pkg_NUM_FP_FORMATS {2'd2}}, {fpnew_pkg_NUM_FP_FORMATS {2'd1}}, {fpnew_pkg_NUM_FP_FORMATS {2'd2}}}), 2'd0};
	parameter [(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) + ((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2)) + 1:0] Implementation = fpnew_pkg_DEFAULT_NOREGS;
	parameter [0:0] PulpDivsqrt = 1'b1;
	parameter [31:0] TrueSIMDClass = 0;
	parameter [31:0] EnableSIMDMask = 0;
	localparam [31:0] fpnew_pkg_FP_FORMAT_BITS = 3;
	localparam [319:0] fpnew_pkg_FP_ENCODINGS = 320'h8000000170000000b00000034000000050000000a00000005000000020000000800000007;
	function automatic [31:0] fpnew_pkg_fp_width;
		input reg [2:0] fmt;
		fpnew_pkg_fp_width = (fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 63-:32] + fpnew_pkg_FP_ENCODINGS[((4 - fmt) * 64) + 31-:32]) + 1;
	endfunction
	function automatic signed [31:0] fpnew_pkg_maximum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_maximum = (a > b ? a : b);
	endfunction
	function automatic [2:0] sv2v_cast_9FB13;
		input reg [2:0] inp;
		sv2v_cast_9FB13 = inp;
	endfunction
	function automatic [31:0] fpnew_pkg_max_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = 0;
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_maximum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_max_fp_width = res;
		end
	endfunction
	function automatic signed [31:0] fpnew_pkg_minimum;
		input reg signed [31:0] a;
		input reg signed [31:0] b;
		fpnew_pkg_minimum = (a < b ? a : b);
	endfunction
	function automatic [31:0] fpnew_pkg_min_fp_width;
		input reg [0:4] cfg;
		reg [31:0] res;
		begin
			res = fpnew_pkg_max_fp_width(cfg);
			begin : sv2v_autoblock_2
				reg [31:0] i;
				for (i = 0; i < fpnew_pkg_NUM_FP_FORMATS; i = i + 1)
					if (cfg[i])
						res = $unsigned(fpnew_pkg_minimum(res, fpnew_pkg_fp_width(sv2v_cast_9FB13(i))));
			end
			fpnew_pkg_min_fp_width = res;
		end
	endfunction
	function automatic [31:0] fpnew_pkg_max_num_lanes;
		input reg [31:0] width;
		input reg [0:4] cfg;
		input reg vec;
		fpnew_pkg_max_num_lanes = (vec ? width / fpnew_pkg_min_fp_width(cfg) : 1);
	endfunction
	localparam [31:0] NumLanes = fpnew_pkg_max_num_lanes(Features[42-:32], Features[8-:5], Features[10]);
	localparam [31:0] WIDTH = Features[42-:32];
	localparam [31:0] NUM_OPERANDS = 3;
	input wire clk_i;
	input wire rst_ni;
	input wire [(NUM_OPERANDS * WIDTH) - 1:0] operands_i;
	input wire [2:0] rnd_mode_i;
	localparam [31:0] fpnew_pkg_OP_BITS = 4;
	input wire [3:0] op_i;
	input wire op_mod_i;
	input wire [2:0] src_fmt_i;
	input wire [2:0] dst_fmt_i;
	localparam [31:0] fpnew_pkg_INT_FORMAT_BITS = 2;
	input wire [1:0] int_fmt_i;
	input wire vectorial_op_i;
	input wire tag_i;
	input wire [NumLanes - 1:0] simd_mask_i;
	input wire in_valid_i;
	output wire in_ready_o;
	input wire flush_i;
	output wire [WIDTH - 1:0] result_o;
	output wire [4:0] status_o;
	output wire tag_o;
	output wire out_valid_o;
	input wire out_ready_i;
	output wire busy_o;
	localparam [31:0] NUM_OPGROUPS = fpnew_pkg_NUM_OPGROUPS;
	localparam [31:0] NUM_FORMATS = fpnew_pkg_NUM_FP_FORMATS;
	wire [3:0] opgrp_in_ready;
	wire [3:0] opgrp_out_valid;
	wire [3:0] opgrp_out_ready;
	wire [3:0] opgrp_ext;
	wire [3:0] opgrp_busy;
	wire [((WIDTH + 5) >= 0 ? (4 * (WIDTH + 6)) - 1 : (4 * (1 - (WIDTH + 5))) + (WIDTH + 4)):((WIDTH + 5) >= 0 ? 0 : WIDTH + 5)] opgrp_outputs;
	wire [(NUM_FORMATS * NUM_OPERANDS) - 1:0] is_boxed;
	function automatic [3:0] sv2v_cast_7BCAE;
		input reg [3:0] inp;
		sv2v_cast_7BCAE = inp;
	endfunction
	function automatic [1:0] fpnew_pkg_get_opgroup;
		input reg [3:0] op;
		(* full_case, parallel_case *)
		case (op)
			sv2v_cast_7BCAE(0), sv2v_cast_7BCAE(1), sv2v_cast_7BCAE(2), sv2v_cast_7BCAE(3): fpnew_pkg_get_opgroup = 2'd0;
			sv2v_cast_7BCAE(4), sv2v_cast_7BCAE(5): fpnew_pkg_get_opgroup = 2'd1;
			sv2v_cast_7BCAE(6), sv2v_cast_7BCAE(7), sv2v_cast_7BCAE(8), sv2v_cast_7BCAE(9): fpnew_pkg_get_opgroup = 2'd2;
			sv2v_cast_7BCAE(10), sv2v_cast_7BCAE(11), sv2v_cast_7BCAE(12), sv2v_cast_7BCAE(13), sv2v_cast_7BCAE(14): fpnew_pkg_get_opgroup = 2'd3;
			default: fpnew_pkg_get_opgroup = 2'd2;
		endcase
	endfunction
	assign in_ready_o = in_valid_i & opgrp_in_ready[fpnew_pkg_get_opgroup(op_i)];
	genvar _gv_fmt_12;
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	generate
		for (_gv_fmt_12 = 0; _gv_fmt_12 < sv2v_cast_32_signed(NUM_FORMATS); _gv_fmt_12 = _gv_fmt_12 + 1) begin : gen_nanbox_check
			localparam fmt = _gv_fmt_12;
			localparam [31:0] FP_WIDTH = fpnew_pkg_fp_width(sv2v_cast_9FB13(fmt));
			if (Features[9] && (FP_WIDTH < WIDTH)) begin : check
				genvar _gv_op_3;
				for (_gv_op_3 = 0; _gv_op_3 < sv2v_cast_32_signed(NUM_OPERANDS); _gv_op_3 = _gv_op_3 + 1) begin : operands
					localparam op = _gv_op_3;
					assign is_boxed[(fmt * NUM_OPERANDS) + op] = (!vectorial_op_i ? operands_i[(op * WIDTH) + ((WIDTH - 1) >= FP_WIDTH ? WIDTH - 1 : ((WIDTH - 1) + ((WIDTH - 1) >= FP_WIDTH ? ((WIDTH - 1) - FP_WIDTH) + 1 : (FP_WIDTH - (WIDTH - 1)) + 1)) - 1)-:((WIDTH - 1) >= FP_WIDTH ? ((WIDTH - 1) - FP_WIDTH) + 1 : (FP_WIDTH - (WIDTH - 1)) + 1)] == {((WIDTH - 1) >= FP_WIDTH ? ((WIDTH - 1) - FP_WIDTH) + 1 : (FP_WIDTH - (WIDTH - 1)) + 1) * 1 {1'sb1}} : 1'b1);
				end
			end
			else begin : no_check
				assign is_boxed[fmt * NUM_OPERANDS+:NUM_OPERANDS] = 1'sb1;
			end
		end
	endgenerate
	wire [NumLanes - 1:0] simd_mask;
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	assign simd_mask = simd_mask_i | ~{NumLanes {sv2v_cast_1(EnableSIMDMask)}};
	genvar _gv_opgrp_1;
	function automatic [31:0] fpnew_pkg_num_operands;
		input reg [1:0] grp;
		(* full_case, parallel_case *)
		case (grp)
			2'd0: fpnew_pkg_num_operands = 3;
			2'd1: fpnew_pkg_num_operands = 2;
			2'd2: fpnew_pkg_num_operands = 2;
			2'd3: fpnew_pkg_num_operands = 3;
			default: fpnew_pkg_num_operands = 0;
		endcase
	endfunction
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	generate
		for (_gv_opgrp_1 = 0; _gv_opgrp_1 < sv2v_cast_32_signed(NUM_OPGROUPS); _gv_opgrp_1 = _gv_opgrp_1 + 1) begin : gen_operation_groups
			localparam opgrp = _gv_opgrp_1;
			localparam [31:0] NUM_OPS = fpnew_pkg_num_operands(sv2v_cast_2(opgrp));
			wire in_valid;
			reg [(NUM_FORMATS * NUM_OPS) - 1:0] input_boxed;
			assign in_valid = in_valid_i & (fpnew_pkg_get_opgroup(op_i) == sv2v_cast_2(opgrp));
			always @(*) begin : slice_inputs
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_3
					reg [31:0] fmt;
					for (fmt = 0; fmt < NUM_FORMATS; fmt = fmt + 1)
						input_boxed[fmt * fpnew_pkg_num_operands(sv2v_cast_2(_gv_opgrp_1))+:fpnew_pkg_num_operands(sv2v_cast_2(_gv_opgrp_1))] = is_boxed[(fmt * NUM_OPERANDS) + (NUM_OPS - 1)-:NUM_OPS];
				end
			end
			fpnew_opgroup_block_28857 #(
				.OpGroup(sv2v_cast_2(opgrp)),
				.Width(WIDTH),
				.EnableVectors(Features[10]),
				.PulpDivsqrt(PulpDivsqrt),
				.FpFmtMask(Features[8-:5]),
				.IntFmtMask(Features[3-:fpnew_pkg_NUM_INT_FORMATS]),
				.FmtPipeRegs(Implementation[(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) + (((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2) + 1)) - ((((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 32) - 1) - (32 * ((3 - opgrp) * fpnew_pkg_NUM_FP_FORMATS)))+:160]),
				.FmtUnitTypes(Implementation[(((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2) + 1) - ((((fpnew_pkg_NUM_OPGROUPS * fpnew_pkg_NUM_FP_FORMATS) * 2) - 1) - (2 * ((3 - opgrp) * fpnew_pkg_NUM_FP_FORMATS)))+:10]),
				.PipeConfig(Implementation[1-:2]),
				.TrueSIMDClass(TrueSIMDClass)
			) i_opgroup_block(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.operands_i(operands_i[WIDTH * ((NUM_OPS - 1) - (NUM_OPS - 1))+:WIDTH * NUM_OPS]),
				.is_boxed_i(input_boxed),
				.rnd_mode_i(rnd_mode_i),
				.op_i(op_i),
				.op_mod_i(op_mod_i),
				.src_fmt_i(src_fmt_i),
				.dst_fmt_i(dst_fmt_i),
				.int_fmt_i(int_fmt_i),
				.vectorial_op_i(vectorial_op_i),
				.tag_i(tag_i),
				.simd_mask_i(simd_mask),
				.in_valid_i(in_valid),
				.in_ready_o(opgrp_in_ready[opgrp]),
				.flush_i(flush_i),
				.result_o(opgrp_outputs[((WIDTH + 5) >= 0 ? (opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? WIDTH + 5 : (WIDTH + 5) - (WIDTH + 5)) : (((opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? WIDTH + 5 : (WIDTH + 5) - (WIDTH + 5))) + ((WIDTH + 5) >= 6 ? WIDTH + 0 : 7 - (WIDTH + 5))) - 1)-:((WIDTH + 5) >= 6 ? WIDTH + 0 : 7 - (WIDTH + 5))]),
				.status_o(opgrp_outputs[((WIDTH + 5) >= 0 ? (opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? 5 : WIDTH + 0) : ((opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? 5 : WIDTH + 0)) + 4)-:5]),
				.extension_bit_o(opgrp_ext[opgrp]),
				.tag_o(opgrp_outputs[(opgrp * ((WIDTH + 5) >= 0 ? WIDTH + 6 : 1 - (WIDTH + 5))) + ((WIDTH + 5) >= 0 ? 0 : WIDTH + 5)]),
				.out_valid_o(opgrp_out_valid[opgrp]),
				.out_ready_i(opgrp_out_ready[opgrp]),
				.busy_o(opgrp_busy[opgrp])
			);
		end
	endgenerate
	wire [WIDTH + 5:0] arbiter_output;
	localparam [31:0] sv2v_uu_i_arbiter_NumIn = NUM_OPGROUPS;
	localparam [31:0] sv2v_uu_i_arbiter_IdxWidth = $unsigned(2);
	localparam [sv2v_uu_i_arbiter_IdxWidth - 1:0] sv2v_uu_i_arbiter_ext_rr_i_0 = 1'sb0;
	rr_arb_tree_D71DB_88D54 #(
		.DataType_WIDTH(WIDTH),
		.NumIn(NUM_OPGROUPS),
		.AxiVldRdy(1'b1)
	) i_arbiter(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.flush_i(flush_i),
		.rr_i(sv2v_uu_i_arbiter_ext_rr_i_0),
		.req_i(opgrp_out_valid),
		.gnt_o(opgrp_out_ready),
		.data_i(opgrp_outputs),
		.gnt_i(out_ready_i),
		.req_o(out_valid_o),
		.data_o(arbiter_output),
		.idx_o()
	);
	assign result_o = arbiter_output[WIDTH + 5-:((WIDTH + 5) >= 6 ? WIDTH + 0 : 7 - (WIDTH + 5))];
	assign status_o = arbiter_output[5-:5];
	assign tag_o = arbiter_output[0];
	assign busy_o = |opgrp_busy;
	initial _sv2v_0 = 0;
endmodule
