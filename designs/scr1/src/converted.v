module scr1_reset_buf_cell (
	rst_n,
	clk,
	test_mode,
	test_rst_n,
	reset_n_in,
	reset_n_out,
	reset_n_status
);
	input wire rst_n;
	input wire clk;
	input wire test_mode;
	input wire test_rst_n;
	input wire reset_n_in;
	output wire reset_n_out;
	output wire reset_n_status;
	reg reset_n_ff;
	reg reset_n_status_ff;
	wire rst_n_mux;
	assign rst_n_mux = (test_mode == 1'b1 ? test_rst_n : rst_n);
	always @(negedge rst_n_mux or posedge clk)
		if (~rst_n_mux)
			reset_n_ff <= 1'b0;
		else
			reset_n_ff <= reset_n_in;
	assign reset_n_out = (test_mode == 1'b1 ? test_rst_n : reset_n_ff);
	always @(negedge rst_n_mux or posedge clk)
		if (~rst_n_mux)
			reset_n_status_ff <= 1'b0;
		else
			reset_n_status_ff <= reset_n_in;
	assign reset_n_status = reset_n_status_ff;
endmodule
module scr1_reset_sync_cell (
	rst_n,
	clk,
	test_rst_n,
	test_mode,
	rst_n_in,
	rst_n_out
);
	parameter [31:0] STAGES_AMOUNT = 2;
	input wire rst_n;
	input wire clk;
	input wire test_rst_n;
	input wire test_mode;
	input wire rst_n_in;
	output wire rst_n_out;
	reg [STAGES_AMOUNT - 1:0] rst_n_dff;
	wire local_rst_n_in;
	assign local_rst_n_in = (test_mode == 1'b1 ? test_rst_n : rst_n);
	generate
		if (STAGES_AMOUNT == 1) begin : gen_reset_sync_cell_single
			always @(negedge local_rst_n_in or posedge clk)
				if (~local_rst_n_in)
					rst_n_dff <= 1'b0;
				else
					rst_n_dff <= rst_n_in;
		end
		else begin : gen_reset_sync_cell_multi
			always @(negedge local_rst_n_in or posedge clk)
				if (~local_rst_n_in)
					rst_n_dff <= 1'sb0;
				else
					rst_n_dff <= {rst_n_dff[STAGES_AMOUNT - 2:0], rst_n_in};
		end
	endgenerate
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : rst_n_dff[STAGES_AMOUNT - 1]);
endmodule
module scr1_data_sync_cell (
	rst_n,
	clk,
	data_in,
	data_out
);
	parameter [31:0] STAGES_AMOUNT = 1;
	input wire rst_n;
	input wire clk;
	input wire data_in;
	output wire data_out;
	reg [STAGES_AMOUNT - 1:0] data_dff;
	generate
		if (STAGES_AMOUNT == 1) begin : gen_data_sync_cell_single
			always @(negedge rst_n or posedge clk)
				if (~rst_n)
					data_dff <= 1'b0;
				else
					data_dff <= data_in;
		end
		else begin : gen_data_sync_cell_multi
			always @(negedge rst_n or posedge clk)
				if (~rst_n)
					data_dff <= 1'sb0;
				else
					data_dff <= {data_dff[STAGES_AMOUNT - 2:0], data_in};
		end
	endgenerate
	assign data_out = data_dff[STAGES_AMOUNT - 1];
endmodule
module scr1_reset_qlfy_adapter_cell_sync (
	rst_n,
	clk,
	test_rst_n,
	test_mode,
	reset_n_in_sync,
	reset_n_out_qlfy,
	reset_n_out,
	reset_n_status
);
	input wire rst_n;
	input wire clk;
	input wire test_rst_n;
	input wire test_mode;
	input wire reset_n_in_sync;
	output wire reset_n_out_qlfy;
	output wire reset_n_out;
	output wire reset_n_status;
	wire rst_n_mux;
	reg reset_n_front_ff;
	assign rst_n_mux = (test_mode == 1'b1 ? test_rst_n : rst_n);
	always @(negedge rst_n_mux or posedge clk)
		if (~rst_n_mux)
			reset_n_front_ff <= 1'b0;
		else
			reset_n_front_ff <= reset_n_in_sync;
	assign reset_n_out_qlfy = reset_n_front_ff;
	scr1_reset_buf_cell i_reset_output_buf(
		.rst_n(rst_n),
		.clk(clk),
		.test_mode(test_mode),
		.test_rst_n(test_rst_n),
		.reset_n_in(reset_n_front_ff),
		.reset_n_out(reset_n_out),
		.reset_n_status(reset_n_status)
	);
endmodule
module scr1_reset_and2_cell (
	rst_n_in,
	test_rst_n,
	test_mode,
	rst_n_out
);
	input wire [1:0] rst_n_in;
	input wire test_rst_n;
	input wire test_mode;
	output wire rst_n_out;
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : &rst_n_in);
endmodule
module scr1_reset_and3_cell (
	rst_n_in,
	test_rst_n,
	test_mode,
	rst_n_out
);
	input wire [2:0] rst_n_in;
	input wire test_rst_n;
	input wire test_mode;
	output wire rst_n_out;
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : &rst_n_in);
endmodule
module scr1_reset_mux2_cell (
	rst_n_in,
	select,
	test_rst_n,
	test_mode,
	rst_n_out
);
	input wire [1:0] rst_n_in;
	input wire select;
	input wire test_rst_n;
	input wire test_mode;
	output wire rst_n_out;
	assign rst_n_out = (test_mode == 1'b1 ? test_rst_n : rst_n_in[select]);
endmodule
module scr1_cg (
	clk,
	clk_en,
	test_mode,
	clk_out
);
	reg _sv2v_0;
	input wire clk;
	input wire clk_en;
	input wire test_mode;
	output wire clk_out;
	reg latch_en;
	always @(posedge clk) begin
    	latch_en <= test_mode | clk_en;
	end
	assign clk_out = latch_en & clk;
	initial _sv2v_0 = 0;
endmodule
module scr1_clk_ctrl (
	clk,
	rst_n,
	test_mode,
	test_rst_n,
	pipe2clkctl_sleep_req_i,
	pipe2clkctl_wake_req_i,
	clkctl2pipe_clk_alw_on_o,
	clkctl2pipe_clk_o,
	clkctl2pipe_clk_en_o,
	clkctl2pipe_clk_dbgc_o
);
	input wire clk;
	input wire rst_n;
	input wire test_mode;
	input wire test_rst_n;
	input wire pipe2clkctl_sleep_req_i;
	input wire pipe2clkctl_wake_req_i;
	output wire clkctl2pipe_clk_alw_on_o;
	output wire clkctl2pipe_clk_o;
	output reg clkctl2pipe_clk_en_o;
	output wire clkctl2pipe_clk_dbgc_o;
	wire ctrl_rst_n;
	assign clkctl2pipe_clk_alw_on_o = clk;
	assign clkctl2pipe_clk_dbgc_o = clk;
	assign ctrl_rst_n = (test_mode ? test_rst_n : rst_n);
	always @(posedge clk or negedge ctrl_rst_n)
		if (~ctrl_rst_n)
			clkctl2pipe_clk_en_o <= 1'b1;
		else if (clkctl2pipe_clk_en_o) begin
			if (pipe2clkctl_sleep_req_i & ~pipe2clkctl_wake_req_i)
				clkctl2pipe_clk_en_o <= 1'b0;
		end
		else if (pipe2clkctl_wake_req_i)
			clkctl2pipe_clk_en_o <= 1'b1;
	scr1_cg i_scr1_cg_pipe(
		.clk(clk),
		.clk_en(clkctl2pipe_clk_en_o),
		.test_mode(test_mode),
		.clk_out(clkctl2pipe_clk_o)
	);
endmodule
module scr1_tapc_shift_reg (
	clk,
	rst_n,
	rst_n_sync,
	fsm_dr_select,
	fsm_dr_capture,
	fsm_dr_shift,
	din_serial,
	din_parallel,
	dout_serial,
	dout_parallel
);
	parameter [31:0] SCR1_WIDTH = 8;
	parameter [SCR1_WIDTH - 1:0] SCR1_RESET_VALUE = 1'sb0;
	input wire clk;
	input wire rst_n;
	input wire rst_n_sync;
	input wire fsm_dr_select;
	input wire fsm_dr_capture;
	input wire fsm_dr_shift;
	input wire din_serial;
	input wire [SCR1_WIDTH - 1:0] din_parallel;
	output wire dout_serial;
	output wire [SCR1_WIDTH - 1:0] dout_parallel;
	reg [SCR1_WIDTH - 1:0] shift_reg;
	generate
		if (SCR1_WIDTH > 1) begin : dr_shift_reg
			always @(posedge clk or negedge rst_n)
				if (~rst_n)
					shift_reg <= SCR1_RESET_VALUE;
				else if (~rst_n_sync)
					shift_reg <= SCR1_RESET_VALUE;
				else if (fsm_dr_select & fsm_dr_capture)
					shift_reg <= din_parallel;
				else if (fsm_dr_select & fsm_dr_shift)
					shift_reg <= {din_serial, shift_reg[SCR1_WIDTH - 1:1]};
		end
		else begin : dr_shift_reg
			always @(posedge clk or negedge rst_n)
				if (~rst_n)
					shift_reg <= SCR1_RESET_VALUE;
				else if (~rst_n_sync)
					shift_reg <= SCR1_RESET_VALUE;
				else if (fsm_dr_select & fsm_dr_capture)
					shift_reg <= din_parallel;
				else if (fsm_dr_select & fsm_dr_shift)
					shift_reg <= din_serial;
		end
	endgenerate
	assign dout_parallel = shift_reg;
	assign dout_serial = shift_reg[0];
endmodule
module scr1_tapc (
	tapc_trst_n,
	tapc_tck,
	tapc_tms,
	tapc_tdi,
	tapc_tdo,
	tapc_tdo_en,
	soc2tapc_fuse_idcode_i,
	tapc2tapcsync_scu_ch_sel_o,
	tapc2tapcsync_dmi_ch_sel_o,
	tapc2tapcsync_ch_id_o,
	tapc2tapcsync_ch_capture_o,
	tapc2tapcsync_ch_shift_o,
	tapc2tapcsync_ch_update_o,
	tapc2tapcsync_ch_tdi_o,
	tapcsync2tapc_ch_tdo_i
);
	reg _sv2v_0;
	input wire tapc_trst_n;
	input wire tapc_tck;
	input wire tapc_tms;
	input wire tapc_tdi;
	output wire tapc_tdo;
	output wire tapc_tdo_en;
	input wire [31:0] soc2tapc_fuse_idcode_i;
	output reg tapc2tapcsync_scu_ch_sel_o;
	output reg tapc2tapcsync_dmi_ch_sel_o;
	localparam SCR1_DBG_DMI_CH_ID_WIDTH = 2'd2;
	output reg [SCR1_DBG_DMI_CH_ID_WIDTH - 1:0] tapc2tapcsync_ch_id_o;
	output wire tapc2tapcsync_ch_capture_o;
	output wire tapc2tapcsync_ch_shift_o;
	output wire tapc2tapcsync_ch_update_o;
	output wire tapc2tapcsync_ch_tdi_o;
	input wire tapcsync2tapc_ch_tdo_i;
	reg trst_n_int;
	localparam [31:0] SCR1_TAP_STATE_WIDTH = 4;
	reg [3:0] tap_fsm_ff;
	reg [3:0] tap_fsm_next;
	wire tap_fsm_reset;
	wire tap_fsm_ir_upd;
	wire tap_fsm_ir_cap;
	wire tap_fsm_ir_shft;
	reg tap_fsm_ir_shift_ff;
	wire tap_fsm_ir_shift_next;
	reg tap_fsm_dr_capture_ff;
	wire tap_fsm_dr_capture_next;
	reg tap_fsm_dr_shift_ff;
	wire tap_fsm_dr_shift_next;
	reg tap_fsm_dr_update_ff;
	wire tap_fsm_dr_update_next;
	localparam [31:0] SCR1_TAP_INSTRUCTION_WIDTH = 5;
	reg [4:0] tap_ir_shift_ff;
	wire [4:0] tap_ir_shift_next;
	reg [4:0] tap_ir_ff;
	wire [4:0] tap_ir_next;
	reg dr_bypass_sel;
	wire dr_bypass_tdo;
	reg dr_idcode_sel;
	wire dr_idcode_tdo;
	reg dr_bld_id_sel;
	wire dr_bld_id_tdo;
	reg dr_out;
	reg tdo_en_ff;
	wire tdo_en_next;
	reg tdo_out_ff;
	wire tdo_out_next;
	always @(negedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			trst_n_int <= 1'b0;
		else
			trst_n_int <= ~tap_fsm_reset;
	function automatic [3:0] sv2v_cast_67B99;
		input reg [3:0] inp;
		sv2v_cast_67B99 = inp;
	endfunction
	always @(posedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tap_fsm_ff <= sv2v_cast_67B99(0);
		else
			tap_fsm_ff <= tap_fsm_next;
	always @(*) begin
		tap_fsm_next = tap_fsm_ff;
		case (tap_fsm_ff)
			sv2v_cast_67B99(0): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(0) : sv2v_cast_67B99(1));
			sv2v_cast_67B99(1): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(2) : sv2v_cast_67B99(1));
			sv2v_cast_67B99(2): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(9) : sv2v_cast_67B99(3));
			sv2v_cast_67B99(3): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(5) : sv2v_cast_67B99(4));
			sv2v_cast_67B99(4): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(5) : sv2v_cast_67B99(4));
			sv2v_cast_67B99(5): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(8) : sv2v_cast_67B99(6));
			sv2v_cast_67B99(6): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(7) : sv2v_cast_67B99(6));
			sv2v_cast_67B99(7): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(8) : sv2v_cast_67B99(4));
			sv2v_cast_67B99(8): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(2) : sv2v_cast_67B99(1));
			sv2v_cast_67B99(9): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(0) : sv2v_cast_67B99(10));
			sv2v_cast_67B99(10): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(12) : sv2v_cast_67B99(11));
			sv2v_cast_67B99(11): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(12) : sv2v_cast_67B99(11));
			sv2v_cast_67B99(12): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(15) : sv2v_cast_67B99(13));
			sv2v_cast_67B99(13): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(14) : sv2v_cast_67B99(13));
			sv2v_cast_67B99(14): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(15) : sv2v_cast_67B99(11));
			sv2v_cast_67B99(15): tap_fsm_next = (tapc_tms ? sv2v_cast_67B99(2) : sv2v_cast_67B99(1));
			default: tap_fsm_next = tap_fsm_ff;
		endcase
	end
	assign tap_fsm_reset = tap_fsm_ff == sv2v_cast_67B99(0);
	assign tap_fsm_ir_upd = tap_fsm_ff == sv2v_cast_67B99(15);
	assign tap_fsm_ir_cap = tap_fsm_ff == sv2v_cast_67B99(10);
	assign tap_fsm_ir_shft = tap_fsm_ff == sv2v_cast_67B99(11);
	always @(posedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tap_ir_shift_ff <= 1'sb0;
		else if (~trst_n_int)
			tap_ir_shift_ff <= 1'sb0;
		else
			tap_ir_shift_ff <= tap_ir_shift_next;
	assign tap_ir_shift_next = (tap_fsm_ir_cap ? {{4 {1'b0}}, 1'b1} : (tap_fsm_ir_shft ? {tapc_tdi, tap_ir_shift_ff[4:1]} : tap_ir_shift_ff));
	function automatic [4:0] sv2v_cast_E1108;
		input reg [4:0] inp;
		sv2v_cast_E1108 = inp;
	endfunction
	always @(negedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tap_ir_ff <= sv2v_cast_E1108(5'h01);
		else if (~trst_n_int)
			tap_ir_ff <= sv2v_cast_E1108(5'h01);
		else
			tap_ir_ff <= tap_ir_next;
	assign tap_ir_next = (tap_fsm_ir_upd ? tap_ir_shift_ff : tap_ir_ff);
	always @(posedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tap_fsm_ir_shift_ff <= 1'b0;
		else if (~trst_n_int)
			tap_fsm_ir_shift_ff <= 1'b0;
		else
			tap_fsm_ir_shift_ff <= tap_fsm_ir_shift_next;
	assign tap_fsm_ir_shift_next = tap_fsm_next == sv2v_cast_67B99(11);
	always @(posedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tap_fsm_dr_capture_ff <= 1'b0;
		else if (~trst_n_int)
			tap_fsm_dr_capture_ff <= 1'b0;
		else
			tap_fsm_dr_capture_ff <= tap_fsm_dr_capture_next;
	assign tap_fsm_dr_capture_next = tap_fsm_next == sv2v_cast_67B99(3);
	always @(posedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tap_fsm_dr_shift_ff <= 1'b0;
		else if (~trst_n_int)
			tap_fsm_dr_shift_ff <= 1'b0;
		else
			tap_fsm_dr_shift_ff <= tap_fsm_dr_shift_next;
	assign tap_fsm_dr_shift_next = tap_fsm_next == sv2v_cast_67B99(4);
	always @(posedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tap_fsm_dr_update_ff <= 1'b0;
		else if (~trst_n_int)
			tap_fsm_dr_update_ff <= 1'b0;
		else
			tap_fsm_dr_update_ff <= tap_fsm_dr_update_next;
	assign tap_fsm_dr_update_next = tap_fsm_next == sv2v_cast_67B99(8);
	always @(*) begin
		dr_bypass_sel = 1'b0;
		dr_idcode_sel = 1'b0;
		dr_bld_id_sel = 1'b0;
		tapc2tapcsync_scu_ch_sel_o = 1'b0;
		tapc2tapcsync_dmi_ch_sel_o = 1'b0;
		case (tap_ir_ff)
			sv2v_cast_E1108(5'h10): tapc2tapcsync_dmi_ch_sel_o = 1'b1;
			sv2v_cast_E1108(5'h11): tapc2tapcsync_dmi_ch_sel_o = 1'b1;
			sv2v_cast_E1108(5'h01): dr_idcode_sel = 1'b1;
			sv2v_cast_E1108(5'h1f): dr_bypass_sel = 1'b1;
			sv2v_cast_E1108(5'h04): dr_bld_id_sel = 1'b1;
			sv2v_cast_E1108(5'h09): tapc2tapcsync_scu_ch_sel_o = 1'b1;
			default: dr_bypass_sel = 1'b1;
		endcase
	end
	always @(*) begin
		tapc2tapcsync_ch_id_o = 1'sb0;
		case (tap_ir_ff)
			sv2v_cast_E1108(5'h10): tapc2tapcsync_ch_id_o = 'd1;
			sv2v_cast_E1108(5'h11): tapc2tapcsync_ch_id_o = 'd2;
			default: tapc2tapcsync_ch_id_o = 1'sb0;
		endcase
	end
	always @(*) begin
		dr_out = 1'b0;
		case (tap_ir_ff)
			sv2v_cast_E1108(5'h10): dr_out = tapcsync2tapc_ch_tdo_i;
			sv2v_cast_E1108(5'h11): dr_out = tapcsync2tapc_ch_tdo_i;
			sv2v_cast_E1108(5'h01): dr_out = dr_idcode_tdo;
			sv2v_cast_E1108(5'h1f): dr_out = dr_bypass_tdo;
			sv2v_cast_E1108(5'h04): dr_out = dr_bld_id_tdo;
			sv2v_cast_E1108(5'h09): dr_out = tapcsync2tapc_ch_tdo_i;
			default: dr_out = dr_bypass_tdo;
		endcase
	end
	always @(negedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tdo_en_ff <= 1'b0;
		else if (~trst_n_int)
			tdo_en_ff <= 1'b0;
		else
			tdo_en_ff <= tdo_en_next;
	assign tdo_en_next = tap_fsm_dr_shift_ff | tap_fsm_ir_shift_ff;
	always @(negedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tdo_out_ff <= 1'b0;
		else if (~trst_n_int)
			tdo_out_ff <= 1'b0;
		else
			tdo_out_ff <= tdo_out_next;
	assign tdo_out_next = (tap_fsm_dr_shift_ff ? dr_out : (tap_fsm_ir_shift_ff ? tap_ir_shift_ff[0] : 1'b0));
	assign tapc_tdo_en = tdo_en_ff;
	assign tapc_tdo = tdo_out_ff;
	localparam [31:0] SCR1_TAP_DR_BYPASS_WIDTH = 1;
	function automatic signed [0:0] sv2v_cast_A2C08_signed;
		input reg signed [0:0] inp;
		sv2v_cast_A2C08_signed = inp;
	endfunction
	scr1_tapc_shift_reg #(
		.SCR1_WIDTH(SCR1_TAP_DR_BYPASS_WIDTH),
		.SCR1_RESET_VALUE(sv2v_cast_A2C08_signed(0))
	) i_bypass_reg(
		.clk(tapc_tck),
		.rst_n(tapc_trst_n),
		.rst_n_sync(trst_n_int),
		.fsm_dr_select(dr_bypass_sel),
		.fsm_dr_capture(tap_fsm_dr_capture_ff),
		.fsm_dr_shift(tap_fsm_dr_shift_ff),
		.din_serial(tapc_tdi),
		.din_parallel(1'b0),
		.dout_serial(dr_bypass_tdo),
		.dout_parallel()
	);
	localparam [31:0] SCR1_TAP_DR_IDCODE_WIDTH = 32;
	function automatic signed [31:0] sv2v_cast_DEBC9_signed;
		input reg signed [31:0] inp;
		sv2v_cast_DEBC9_signed = inp;
	endfunction
	scr1_tapc_shift_reg #(
		.SCR1_WIDTH(SCR1_TAP_DR_IDCODE_WIDTH),
		.SCR1_RESET_VALUE(sv2v_cast_DEBC9_signed(0))
	) i_tap_idcode_reg(
		.clk(tapc_tck),
		.rst_n(tapc_trst_n),
		.rst_n_sync(trst_n_int),
		.fsm_dr_select(dr_idcode_sel),
		.fsm_dr_capture(tap_fsm_dr_capture_ff),
		.fsm_dr_shift(tap_fsm_dr_shift_ff),
		.din_serial(tapc_tdi),
		.din_parallel(soc2tapc_fuse_idcode_i),
		.dout_serial(dr_idcode_tdo),
		.dout_parallel()
	);
	localparam [31:0] SCR1_TAP_DR_BLD_ID_WIDTH = 32;
	localparam [31:0] SCR1_TAP_BLD_ID_VALUE = 32'h22011200;
	scr1_tapc_shift_reg #(
		.SCR1_WIDTH(SCR1_TAP_DR_BLD_ID_WIDTH),
		.SCR1_RESET_VALUE(sv2v_cast_DEBC9_signed(0))
	) i_tap_dr_bld_id_reg(
		.clk(tapc_tck),
		.rst_n(tapc_trst_n),
		.rst_n_sync(trst_n_int),
		.fsm_dr_select(dr_bld_id_sel),
		.fsm_dr_capture(tap_fsm_dr_capture_ff),
		.fsm_dr_shift(tap_fsm_dr_shift_ff),
		.din_serial(tapc_tdi),
		.din_parallel(SCR1_TAP_BLD_ID_VALUE),
		.dout_serial(dr_bld_id_tdo),
		.dout_parallel()
	);
	assign tapc2tapcsync_ch_tdi_o = tapc_tdi;
	assign tapc2tapcsync_ch_capture_o = tap_fsm_dr_capture_ff;
	assign tapc2tapcsync_ch_shift_o = tap_fsm_dr_shift_ff;
	assign tapc2tapcsync_ch_update_o = tap_fsm_dr_update_ff;
	initial _sv2v_0 = 0;
endmodule
module scr1_tapc_synchronizer (
	pwrup_rst_n,
	dm_rst_n,
	clk,
	tapc_trst_n,
	tapc_tck,
	tapc2tapcsync_scu_ch_sel_i,
	tapcsync2scu_ch_sel_o,
	tapc2tapcsync_dmi_ch_sel_i,
	tapcsync2dmi_ch_sel_o,
	tapc2tapcsync_ch_id_i,
	tapcsync2core_ch_id_o,
	tapc2tapcsync_ch_capture_i,
	tapcsync2core_ch_capture_o,
	tapc2tapcsync_ch_shift_i,
	tapcsync2core_ch_shift_o,
	tapc2tapcsync_ch_update_i,
	tapcsync2core_ch_update_o,
	tapc2tapcsync_ch_tdi_i,
	tapcsync2core_ch_tdi_o,
	tapc2tapcsync_ch_tdo_i,
	tapcsync2core_ch_tdo_o
);
	input wire pwrup_rst_n;
	input wire dm_rst_n;
	input wire clk;
	input wire tapc_trst_n;
	input wire tapc_tck;
	input wire tapc2tapcsync_scu_ch_sel_i;
	output reg tapcsync2scu_ch_sel_o;
	input wire tapc2tapcsync_dmi_ch_sel_i;
	output reg tapcsync2dmi_ch_sel_o;
	localparam SCR1_DBG_DMI_CH_ID_WIDTH = 2'd2;
	input wire [SCR1_DBG_DMI_CH_ID_WIDTH - 1:0] tapc2tapcsync_ch_id_i;
	output reg [SCR1_DBG_DMI_CH_ID_WIDTH - 1:0] tapcsync2core_ch_id_o;
	input wire tapc2tapcsync_ch_capture_i;
	output reg tapcsync2core_ch_capture_o;
	input wire tapc2tapcsync_ch_shift_i;
	output reg tapcsync2core_ch_shift_o;
	input wire tapc2tapcsync_ch_update_i;
	output reg tapcsync2core_ch_update_o;
	input wire tapc2tapcsync_ch_tdi_i;
	output reg tapcsync2core_ch_tdi_o;
	output wire tapc2tapcsync_ch_tdo_i;
	input wire tapcsync2core_ch_tdo_o;
	reg tck_divpos;
	reg tck_divneg;
	wire tck_rise_load;
	wire tck_rise_reset;
	wire tck_fall_load;
	wire tck_fall_reset;
	reg [3:0] tck_divpos_sync;
	reg [3:0] tck_divneg_sync;
	reg [2:0] dmi_ch_capture_sync;
	reg [2:0] dmi_ch_shift_sync;
	reg [2:0] dmi_ch_tdi_sync;
	always @(posedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tck_divpos <= 1'b0;
		else
			tck_divpos <= ~tck_divpos;
	always @(negedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n)
			tck_divneg <= 1'b0;
		else
			tck_divneg <= ~tck_divneg;
	always @(posedge clk or negedge pwrup_rst_n)
		if (~pwrup_rst_n) begin
			tck_divpos_sync <= 4'd0;
			tck_divneg_sync <= 4'd0;
		end
		else begin
			tck_divpos_sync <= {tck_divpos_sync[2:0], tck_divpos};
			tck_divneg_sync <= {tck_divneg_sync[2:0], tck_divneg};
		end
	assign tck_rise_load = tck_divpos_sync[2] ^ tck_divpos_sync[1];
	assign tck_rise_reset = tck_divpos_sync[3] ^ tck_divpos_sync[2];
	assign tck_fall_load = tck_divneg_sync[2] ^ tck_divneg_sync[1];
	assign tck_fall_reset = tck_divneg_sync[3] ^ tck_divneg_sync[2];
	always @(posedge clk or negedge pwrup_rst_n)
		if (~pwrup_rst_n)
			tapcsync2core_ch_update_o <= 1'sb0;
		else if (tck_fall_load)
			tapcsync2core_ch_update_o <= tapc2tapcsync_ch_update_i;
		else if (tck_fall_reset)
			tapcsync2core_ch_update_o <= 1'sb0;
	always @(negedge tapc_tck or negedge tapc_trst_n)
		if (~tapc_trst_n) begin
			dmi_ch_capture_sync[0] <= 1'sb0;
			dmi_ch_shift_sync[0] <= 1'sb0;
		end
		else begin
			dmi_ch_capture_sync[0] <= tapc2tapcsync_ch_capture_i;
			dmi_ch_shift_sync[0] <= tapc2tapcsync_ch_shift_i;
		end
	always @(posedge clk or negedge pwrup_rst_n)
		if (~pwrup_rst_n) begin
			dmi_ch_capture_sync[2:1] <= 1'sb0;
			dmi_ch_shift_sync[2:1] <= 1'sb0;
		end
		else begin
			dmi_ch_capture_sync[2:1] <= {dmi_ch_capture_sync[1], dmi_ch_capture_sync[0]};
			dmi_ch_shift_sync[2:1] <= {dmi_ch_shift_sync[1], dmi_ch_shift_sync[0]};
		end
	always @(posedge clk or negedge pwrup_rst_n)
		if (~pwrup_rst_n)
			dmi_ch_tdi_sync <= 1'sb0;
		else
			dmi_ch_tdi_sync <= {dmi_ch_tdi_sync[1:0], tapc2tapcsync_ch_tdi_i};
	always @(posedge clk or negedge pwrup_rst_n)
		if (~pwrup_rst_n) begin
			tapcsync2core_ch_capture_o <= 1'sb0;
			tapcsync2core_ch_shift_o <= 1'sb0;
			tapcsync2core_ch_tdi_o <= 1'sb0;
		end
		else if (tck_rise_load) begin
			tapcsync2core_ch_capture_o <= dmi_ch_capture_sync[2];
			tapcsync2core_ch_shift_o <= dmi_ch_shift_sync[2];
			tapcsync2core_ch_tdi_o <= dmi_ch_tdi_sync[2];
		end
		else if (tck_rise_reset) begin
			tapcsync2core_ch_capture_o <= 1'sb0;
			tapcsync2core_ch_shift_o <= 1'sb0;
			tapcsync2core_ch_tdi_o <= 1'sb0;
		end
	always @(posedge clk or negedge dm_rst_n)
		if (~dm_rst_n) begin
			tapcsync2dmi_ch_sel_o <= 1'sb0;
			tapcsync2core_ch_id_o <= 1'sb0;
		end
		else if (tck_rise_load) begin
			tapcsync2dmi_ch_sel_o <= tapc2tapcsync_dmi_ch_sel_i;
			tapcsync2core_ch_id_o <= tapc2tapcsync_ch_id_i;
		end
	always @(posedge clk or negedge pwrup_rst_n)
		if (~pwrup_rst_n)
			tapcsync2scu_ch_sel_o <= 1'sb0;
		else if (tck_rise_load)
			tapcsync2scu_ch_sel_o <= tapc2tapcsync_scu_ch_sel_i;
	assign tapc2tapcsync_ch_tdo_i = tapcsync2core_ch_tdo_o;
endmodule
module scr1_dm (
	rst_n,
	clk,
	dmi2dm_req_i,
	dmi2dm_wr_i,
	dmi2dm_addr_i,
	dmi2dm_wdata_i,
	dm2dmi_resp_o,
	dm2dmi_rdata_o,
	ndm_rst_n_o,
	hart_rst_n_o,
	dm2pipe_active_o,
	dm2pipe_cmd_req_o,
	dm2pipe_cmd_o,
	pipe2dm_cmd_resp_i,
	pipe2dm_cmd_rcode_i,
	pipe2dm_hart_event_i,
	pipe2dm_hart_status_i,
	soc2dm_fuse_mhartid_i,
	pipe2dm_pc_sample_i,
	pipe2dm_pbuf_addr_i,
	dm2pipe_pbuf_instr_o,
	pipe2dm_dreg_req_i,
	pipe2dm_dreg_wr_i,
	pipe2dm_dreg_wdata_i,
	dm2pipe_dreg_resp_o,
	dm2pipe_dreg_fail_o,
	dm2pipe_dreg_rdata_o
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	input wire dmi2dm_req_i;
	input wire dmi2dm_wr_i;
	localparam SCR1_DBG_DMI_ADDR_WIDTH = 6'd7;
	input wire [SCR1_DBG_DMI_ADDR_WIDTH - 1:0] dmi2dm_addr_i;
	localparam SCR1_DBG_DMI_DATA_WIDTH = 6'd32;
	input wire [SCR1_DBG_DMI_DATA_WIDTH - 1:0] dmi2dm_wdata_i;
	output wire dm2dmi_resp_o;
	output reg [SCR1_DBG_DMI_DATA_WIDTH - 1:0] dm2dmi_rdata_o;
	output wire ndm_rst_n_o;
	output wire hart_rst_n_o;
	output wire dm2pipe_active_o;
	output wire dm2pipe_cmd_req_o;
	output wire [1:0] dm2pipe_cmd_o;
	input wire pipe2dm_cmd_resp_i;
	input wire pipe2dm_cmd_rcode_i;
	input wire pipe2dm_hart_event_i;
	input wire [3:0] pipe2dm_hart_status_i;
	input wire [31:0] soc2dm_fuse_mhartid_i;
	input wire [31:0] pipe2dm_pc_sample_i;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_SPAN = 8;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_WIDTH = 3;
	input wire [2:0] pipe2dm_pbuf_addr_i;
	localparam [31:0] SCR1_HDU_CORE_INSTR_WIDTH = 32;
	output reg [31:0] dm2pipe_pbuf_instr_o;
	input wire pipe2dm_dreg_req_i;
	input wire pipe2dm_dreg_wr_i;
	input wire [31:0] pipe2dm_dreg_wdata_i;
	output wire dm2pipe_dreg_resp_o;
	output wire dm2pipe_dreg_fail_o;
	output wire [31:0] dm2pipe_dreg_rdata_o;
	localparam SCR1_DBG_ABSTRACTCS_CMDERR_HI = 5'd10;
	localparam SCR1_DBG_ABSTRACTCS_CMDERR_LO = 5'd8;
	localparam SCR1_DBG_ABSTRACTCS_CMDERR_WDTH = SCR1_DBG_ABSTRACTCS_CMDERR_HI - SCR1_DBG_ABSTRACTCS_CMDERR_LO;
	localparam SCR1_OP_SYSTEM = 7'b1110011;
	localparam SCR1_OP_LOAD = 7'b0000011;
	localparam SCR1_OP_STORE = 7'b0100011;
	localparam SCR1_FUNCT3_CSRRW = 3'b001;
	localparam SCR1_FUNCT3_CSRRS = 3'b010;
	localparam SCR1_FUNCT3_SB = 3'b000;
	localparam SCR1_FUNCT3_SH = 3'b001;
	localparam SCR1_FUNCT3_SW = 3'b010;
	localparam SCR1_FUNCT3_LW = 3'b010;
	localparam SCR1_FUNCT3_LBU = 3'b100;
	localparam SCR1_FUNCT3_LHU = 3'b101;
	localparam DMCONTROL_HARTRESET = 1'd0;
	localparam DMCONTROL_RESERVEDB = 1'd0;
	localparam DMCONTROL_HASEL = 1'd0;
	localparam DMCONTROL_HARTSELLO = 1'd0;
	localparam DMCONTROL_HARTSELHI = 1'd0;
	localparam DMCONTROL_RESERVEDA = 1'd0;
	localparam DMSTATUS_RESERVEDC = 1'd0;
	localparam DMSTATUS_IMPEBREAK = 1'd1;
	localparam DMSTATUS_RESERVEDB = 1'd0;
	localparam DMSTATUS_ALLUNAVAIL = 1'd0;
	localparam DMSTATUS_ANYUNAVAIL = 1'd0;
	localparam DMSTATUS_ALLANYUNAVAIL = 1'd0;
	localparam DMSTATUS_ALLANYNONEXIST = 1'b0;
	localparam DMSTATUS_AUTHENTICATED = 1'd1;
	localparam DMSTATUS_AUTHBUSY = 1'd0;
	localparam DMSTATUS_RESERVEDA = 1'd0;
	localparam DMSTATUS_DEVTREEVALID = 1'd0;
	localparam DMSTATUS_VERSION = 2'd2;
	localparam HARTINFO_RESERVEDB = 1'd0;
	localparam HARTINFO_NSCRATCH = 4'd1;
	localparam HARTINFO_RESERVEDA = 1'd0;
	localparam HARTINFO_DATAACCESS = 1'd0;
	localparam HARTINFO_DATASIZE = 4'd1;
	localparam HARTINFO_DATAADDR = 12'h7b2;
	localparam ABSTRACTCS_RESERVEDD = 1'd0;
	localparam ABSTRACTCS_PROGBUFSIZE = 5'd6;
	localparam ABSTRACTCS_RESERVEDC = 1'd0;
	localparam ABSTRACTCS_RESERVEDB = 1'd0;
	localparam ABSTRACTCS_RESERVEDA = 1'd0;
	localparam ABSTRACTCS_DATACOUNT = 4'd2;
	localparam ABS_CMD_HARTREG = 1'd0;
	localparam ABS_CMD_HARTMEM = 2'd2;
	localparam ABS_CMD_HARTREG_CSR = 4'b0000;
	localparam ABS_CMD_HARTREG_INTFPU = 4'b0001;
	localparam ABS_CMD_HARTREG_INT = 7'b0000000;
	localparam ABS_CMD_HARTREG_FPU = 7'b0000001;
	localparam ABS_EXEC_EBREAK = 32'b00000000000100000000000001110011;
	reg dmi_req_dmcontrol;
	reg dmi_req_abstractcs;
	reg dmi_req_abstractauto;
	reg dmi_req_command;
	reg dmi_rpt_command;
	reg dmi_req_data0;
	reg dmi_req_data1;
	reg dmi_req_progbuf0;
	reg dmi_req_progbuf1;
	reg dmi_req_progbuf2;
	reg dmi_req_progbuf3;
	reg dmi_req_progbuf4;
	reg dmi_req_progbuf5;
	wire dmi_req_any;
	wire dmcontrol_wr_req;
	wire abstractcs_wr_req;
	wire data0_wr_req;
	wire data1_wr_req;
	wire dreg_wr_req;
	wire command_wr_req;
	wire autoexec_wr_req;
	wire progbuf0_wr_req;
	wire progbuf1_wr_req;
	wire progbuf2_wr_req;
	wire progbuf3_wr_req;
	wire progbuf4_wr_req;
	wire progbuf5_wr_req;
	wire clk_en_dm;
	reg clk_en_dm_ff;
	reg dmcontrol_haltreq_ff;
	reg dmcontrol_haltreq_next;
	reg dmcontrol_resumereq_ff;
	reg dmcontrol_resumereq_next;
	reg dmcontrol_ackhavereset_ff;
	reg dmcontrol_ackhavereset_next;
	reg dmcontrol_ndmreset_ff;
	reg dmcontrol_ndmreset_next;
	reg dmcontrol_dmactive_ff;
	wire dmcontrol_dmactive_next;
	reg havereset_skip_pwrup_ff;
	wire havereset_skip_pwrup_next;
	reg dmstatus_allany_havereset_ff;
	wire dmstatus_allany_havereset_next;
	reg dmstatus_allany_resumeack_ff;
	wire dmstatus_allany_resumeack_next;
	reg dmstatus_allany_halted_ff;
	wire dmstatus_allany_halted_next;
	wire [SCR1_DBG_DMI_DATA_WIDTH - 1:0] abs_cmd;
	reg abs_cmd_csr_ro;
	localparam SCR1_DBG_COMMAND_TYPE_HI = 5'd31;
	localparam SCR1_DBG_COMMAND_TYPE_LO = 5'd24;
	localparam SCR1_DBG_COMMAND_TYPE_WDTH = SCR1_DBG_COMMAND_TYPE_HI - SCR1_DBG_COMMAND_TYPE_LO;
	reg [SCR1_DBG_COMMAND_TYPE_WDTH:0] abs_cmd_type;
	reg abs_cmd_regacs;
	localparam SCR1_DBG_COMMAND_ACCESSREG_REGNO_HI = 5'd15;
	reg [SCR1_DBG_COMMAND_ACCESSREG_REGNO_HI - 12:0] abs_cmd_regtype;
	reg [6:0] abs_cmd_regfile;
	reg abs_cmd_regwr;
	localparam SCR1_DBG_COMMAND_ACCESSREG_SIZE_HI = 5'd22;
	localparam SCR1_DBG_COMMAND_ACCESSREG_SIZE_LO = 5'd20;
	localparam SCR1_DBG_COMMAND_ACCESSREG_SIZE_WDTH = SCR1_DBG_COMMAND_ACCESSREG_SIZE_HI - SCR1_DBG_COMMAND_ACCESSREG_SIZE_LO;
	reg [SCR1_DBG_COMMAND_ACCESSREG_SIZE_WDTH:0] abs_cmd_regsize;
	reg abs_cmd_execprogbuf;
	reg abs_cmd_regvalid;
	reg [2:0] abs_cmd_memsize;
	reg abs_cmd_memwr;
	reg abs_cmd_memvalid;
	wire abs_cmd_regsize_vd;
	wire abs_cmd_memsize_vd;
	reg abs_cmd_wr_ff;
	reg abs_cmd_wr_next;
	reg abs_cmd_postexec_ff;
	reg abs_cmd_postexec_next;
	reg [11:0] abs_cmd_regno;
	reg [11:0] abs_cmd_regno_ff;
	reg [1:0] abs_cmd_size_ff;
	reg [1:0] abs_cmd_size_next;
	wire abs_reg_access_csr;
	wire abs_reg_access_mprf;
	wire abs_cmd_hartreg_vd;
	wire abs_cmd_hartmem_vd;
	wire abs_cmd_reg_access_req;
	wire abs_cmd_csr_access_req;
	wire abs_cmd_mprf_access_req;
	wire abs_cmd_execprogbuf_req;
	wire abs_cmd_csr_ro_access_vd;
	wire abs_cmd_csr_rw_access_vd;
	wire abs_cmd_mprf_access_vd;
	wire abs_cmd_mem_access_vd;
	reg [3:0] abs_fsm_ff;
	reg [3:0] abs_fsm_next;
	wire abs_fsm_idle;
	wire abs_fsm_exec;
	wire abs_fsm_csr_ro;
	wire abs_fsm_err;
	wire abs_fsm_use_addr;
	wire clk_en_abs;
	wire abstractcs_busy;
	wire abstractcs_ro_en;
	reg [31:0] abs_command_ff;
	wire [31:0] abs_command_next;
	reg abs_autoexec_ff;
	wire abs_autoexec_next;
	reg [31:0] abs_progbuf0_ff;
	reg [31:0] abs_progbuf1_ff;
	reg [31:0] abs_progbuf2_ff;
	reg [31:0] abs_progbuf3_ff;
	reg [31:0] abs_progbuf4_ff;
	reg [31:0] abs_progbuf5_ff;
	wire data0_xreg_save;
	reg [31:0] abs_data0_ff;
	reg [31:0] abs_data0_next;
	reg [31:0] abs_data1_ff;
	reg [31:0] abs_data1_next;
	wire abs_err_exc_upd;
	reg abs_err_exc_ff;
	wire abs_err_exc_next;
	wire abs_err_acc_busy_upd;
	reg abs_err_acc_busy_ff;
	wire abs_err_acc_busy_next;
	reg [SCR1_DBG_ABSTRACTCS_CMDERR_WDTH:0] abstractcs_cmderr_ff;
	reg [SCR1_DBG_ABSTRACTCS_CMDERR_WDTH:0] abstractcs_cmderr_next;
	wire abs_exec_req_next;
	reg abs_exec_req_ff;
	reg [4:0] abs_instr_rd;
	reg [4:0] abs_instr_rs1;
	wire [4:0] abs_instr_rs2;
	reg [2:0] abs_instr_mem_funct3;
	reg [31:0] abs_exec_instr_next;
	reg [31:0] abs_exec_instr_ff;
	reg [2:0] dhi_fsm_next;
	reg [2:0] dhi_fsm_ff;
	reg [2:0] dhi_req;
	wire dhi_fsm_idle;
	wire dhi_fsm_exec;
	wire dhi_fsm_exec_halt;
	wire dhi_fsm_halt_req;
	wire dhi_fsm_resume_req;
	wire cmd_resp_ok;
	wire hart_rst_unexp;
	wire halt_req_vd;
	wire resume_req_vd;
	wire dhi_resp;
	wire dhi_resp_exc;
	reg hart_pbuf_ebreak_ff;
	wire hart_pbuf_ebreak_next;
	reg hart_cmd_req_ff;
	wire hart_cmd_req_next;
	reg [1:0] hart_cmd_ff;
	reg [1:0] hart_cmd_next;
	wire hart_state_reset;
	wire hart_state_run;
	wire hart_state_drun;
	wire hart_state_dhalt;
	localparam SCR1_DBG_ABSTRACTAUTO = 7'h18;
	localparam SCR1_DBG_ABSTRACTCS = 7'h16;
	localparam SCR1_DBG_COMMAND = 7'h17;
	localparam SCR1_DBG_DATA0 = 7'h04;
	localparam SCR1_DBG_DATA1 = 7'h05;
	localparam SCR1_DBG_DMCONTROL = 7'h10;
	localparam SCR1_DBG_PROGBUF0 = 7'h20;
	localparam SCR1_DBG_PROGBUF1 = 7'h21;
	localparam SCR1_DBG_PROGBUF2 = 7'h22;
	localparam SCR1_DBG_PROGBUF3 = 7'h23;
	localparam SCR1_DBG_PROGBUF4 = 7'h24;
	localparam SCR1_DBG_PROGBUF5 = 7'h25;
	always @(*) begin
		dmi_req_dmcontrol = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_DMCONTROL);
		dmi_req_abstractcs = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_ABSTRACTCS);
		dmi_req_abstractauto = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_ABSTRACTAUTO);
		dmi_req_data0 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_DATA0);
		dmi_req_data1 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_DATA1);
		dmi_req_command = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_COMMAND);
		dmi_rpt_command = abs_autoexec_ff & dmi_req_data0;
		dmi_req_progbuf0 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_PROGBUF0);
		dmi_req_progbuf1 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_PROGBUF1);
		dmi_req_progbuf2 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_PROGBUF2);
		dmi_req_progbuf3 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_PROGBUF3);
		dmi_req_progbuf4 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_PROGBUF4);
		dmi_req_progbuf5 = dmi2dm_req_i & (dmi2dm_addr_i == SCR1_DBG_PROGBUF5);
	end
	assign dmi_req_any = (((((((((dmi_req_command | dmi_rpt_command) | dmi_req_abstractauto) | dmi_req_data0) | dmi_req_data1) | dmi_req_progbuf0) | dmi_req_progbuf1) | dmi_req_progbuf2) | dmi_req_progbuf3) | dmi_req_progbuf4) | dmi_req_progbuf5;
	localparam SCR1_DBG_ABSTRACTCS_BUSY = 5'd12;
	localparam SCR1_DBG_ABSTRACTCS_DATACOUNT_HI = 5'd3;
	localparam SCR1_DBG_ABSTRACTCS_DATACOUNT_LO = 5'd0;
	localparam SCR1_DBG_ABSTRACTCS_PROGBUFSIZE_HI = 5'd28;
	localparam SCR1_DBG_ABSTRACTCS_PROGBUFSIZE_LO = 5'd24;
	localparam SCR1_DBG_ABSTRACTCS_RESERVEDA_HI = 5'd7;
	localparam SCR1_DBG_ABSTRACTCS_RESERVEDA_LO = 5'd4;
	localparam SCR1_DBG_ABSTRACTCS_RESERVEDB = 5'd11;
	localparam SCR1_DBG_ABSTRACTCS_RESERVEDC_HI = 5'd23;
	localparam SCR1_DBG_ABSTRACTCS_RESERVEDC_LO = 5'd13;
	localparam SCR1_DBG_ABSTRACTCS_RESERVEDD_HI = 5'd31;
	localparam SCR1_DBG_ABSTRACTCS_RESERVEDD_LO = 5'd29;
	localparam SCR1_DBG_DMCONTROL_ACKHAVERESET = 5'd28;
	localparam SCR1_DBG_DMCONTROL_DMACTIVE = 5'd0;
	localparam SCR1_DBG_DMCONTROL_HALTREQ = 5'd31;
	localparam SCR1_DBG_DMCONTROL_HARTRESET = 5'd29;
	localparam SCR1_DBG_DMCONTROL_HARTSELHI_HI = 5'd15;
	localparam SCR1_DBG_DMCONTROL_HARTSELHI_LO = 5'd6;
	localparam SCR1_DBG_DMCONTROL_HARTSELLO_HI = 5'd25;
	localparam SCR1_DBG_DMCONTROL_HARTSELLO_LO = 5'd16;
	localparam SCR1_DBG_DMCONTROL_HASEL = 5'd26;
	localparam SCR1_DBG_DMCONTROL_NDMRESET = 5'd1;
	localparam SCR1_DBG_DMCONTROL_RESERVEDA_HI = 5'd5;
	localparam SCR1_DBG_DMCONTROL_RESERVEDA_LO = 5'd2;
	localparam SCR1_DBG_DMCONTROL_RESERVEDB = 5'd27;
	localparam SCR1_DBG_DMCONTROL_RESUMEREQ = 5'd30;
	localparam SCR1_DBG_DMSTATUS = 7'h11;
	localparam SCR1_DBG_DMSTATUS_ALLHALTED = 5'd9;
	localparam SCR1_DBG_DMSTATUS_ALLHAVERESET = 5'd19;
	localparam SCR1_DBG_DMSTATUS_ALLNONEXISTENT = 5'd15;
	localparam SCR1_DBG_DMSTATUS_ALLRESUMEACK = 5'd17;
	localparam SCR1_DBG_DMSTATUS_ALLRUNNING = 5'd11;
	localparam SCR1_DBG_DMSTATUS_ALLUNAVAIL = 5'd13;
	localparam SCR1_DBG_DMSTATUS_ANYHALTED = 5'd8;
	localparam SCR1_DBG_DMSTATUS_ANYHAVERESET = 5'd18;
	localparam SCR1_DBG_DMSTATUS_ANYNONEXISTENT = 5'd14;
	localparam SCR1_DBG_DMSTATUS_ANYRESUMEACK = 5'd16;
	localparam SCR1_DBG_DMSTATUS_ANYRUNNING = 5'd10;
	localparam SCR1_DBG_DMSTATUS_ANYUNAVAIL = 5'd12;
	localparam SCR1_DBG_DMSTATUS_AUTHBUSY = 5'd6;
	localparam SCR1_DBG_DMSTATUS_AUTHENTICATED = 5'd7;
	localparam SCR1_DBG_DMSTATUS_DEVTREEVALID = 5'd4;
	localparam SCR1_DBG_DMSTATUS_IMPEBREAK = 5'd22;
	localparam SCR1_DBG_DMSTATUS_RESERVEDA = 5'd5;
	localparam SCR1_DBG_DMSTATUS_RESERVEDB_HI = 5'd21;
	localparam SCR1_DBG_DMSTATUS_RESERVEDB_LO = 5'd20;
	localparam SCR1_DBG_DMSTATUS_RESERVEDC_HI = 5'd31;
	localparam SCR1_DBG_DMSTATUS_RESERVEDC_LO = 5'd23;
	localparam SCR1_DBG_DMSTATUS_VERSION_HI = 5'd3;
	localparam SCR1_DBG_DMSTATUS_VERSION_LO = 5'd0;
	localparam SCR1_DBG_HALTSUM0 = 7'h40;
	localparam SCR1_DBG_HARTINFO = 7'h12;
	localparam SCR1_DBG_HARTINFO_DATAACCESS = 5'd16;
	localparam SCR1_DBG_HARTINFO_DATAADDR_HI = 5'd11;
	localparam SCR1_DBG_HARTINFO_DATAADDR_LO = 5'd0;
	localparam SCR1_DBG_HARTINFO_DATASIZE_HI = 5'd15;
	localparam SCR1_DBG_HARTINFO_DATASIZE_LO = 5'd12;
	localparam SCR1_DBG_HARTINFO_NSCRATCH_HI = 5'd23;
	localparam SCR1_DBG_HARTINFO_NSCRATCH_LO = 5'd20;
	localparam SCR1_DBG_HARTINFO_RESERVEDA_HI = 5'd19;
	localparam SCR1_DBG_HARTINFO_RESERVEDA_LO = 5'd17;
	localparam SCR1_DBG_HARTINFO_RESERVEDB_HI = 5'd31;
	localparam SCR1_DBG_HARTINFO_RESERVEDB_LO = 5'd24;
	always @(*) begin
		dm2dmi_rdata_o = 1'sb0;
		case (dmi2dm_addr_i)
			SCR1_DBG_DMSTATUS: begin
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_RESERVEDC_HI:SCR1_DBG_DMSTATUS_RESERVEDC_LO] = DMSTATUS_RESERVEDC;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_IMPEBREAK] = DMSTATUS_IMPEBREAK;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_RESERVEDB_HI:SCR1_DBG_DMSTATUS_RESERVEDB_LO] = DMSTATUS_RESERVEDB;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ALLHAVERESET] = dmstatus_allany_havereset_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ANYHAVERESET] = dmstatus_allany_havereset_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ALLRESUMEACK] = dmstatus_allany_resumeack_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ANYRESUMEACK] = dmstatus_allany_resumeack_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ALLNONEXISTENT] = DMSTATUS_ALLANYNONEXIST;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ANYNONEXISTENT] = DMSTATUS_ALLANYNONEXIST;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ALLUNAVAIL] = DMSTATUS_ALLANYUNAVAIL;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ANYUNAVAIL] = DMSTATUS_ALLANYUNAVAIL;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ALLRUNNING] = ~dmstatus_allany_halted_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ANYRUNNING] = ~dmstatus_allany_halted_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ALLHALTED] = dmstatus_allany_halted_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_ANYHALTED] = dmstatus_allany_halted_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_AUTHENTICATED] = DMSTATUS_AUTHENTICATED;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_AUTHBUSY] = DMSTATUS_AUTHBUSY;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_RESERVEDA] = DMSTATUS_RESERVEDA;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_DEVTREEVALID] = DMSTATUS_DEVTREEVALID;
				dm2dmi_rdata_o[SCR1_DBG_DMSTATUS_VERSION_HI:SCR1_DBG_DMSTATUS_VERSION_LO] = DMSTATUS_VERSION;
			end
			SCR1_DBG_DMCONTROL: begin
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_HALTREQ] = dmcontrol_haltreq_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_RESUMEREQ] = dmcontrol_resumereq_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_HARTRESET] = DMCONTROL_HARTRESET;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_ACKHAVERESET] = dmcontrol_ackhavereset_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_RESERVEDB] = DMCONTROL_RESERVEDB;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_HASEL] = DMCONTROL_HASEL;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_HARTSELLO_HI:SCR1_DBG_DMCONTROL_HARTSELLO_LO] = DMCONTROL_HARTSELLO;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_HARTSELHI_HI:SCR1_DBG_DMCONTROL_HARTSELHI_LO] = DMCONTROL_HARTSELHI;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_RESERVEDA_HI:SCR1_DBG_DMCONTROL_RESERVEDA_LO] = DMCONTROL_RESERVEDA;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_NDMRESET] = dmcontrol_ndmreset_ff;
				dm2dmi_rdata_o[SCR1_DBG_DMCONTROL_DMACTIVE] = dmcontrol_dmactive_ff;
			end
			SCR1_DBG_ABSTRACTCS: begin
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_RESERVEDD_HI:SCR1_DBG_ABSTRACTCS_RESERVEDD_LO] = ABSTRACTCS_RESERVEDD;
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_PROGBUFSIZE_HI:SCR1_DBG_ABSTRACTCS_PROGBUFSIZE_LO] = ABSTRACTCS_PROGBUFSIZE;
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_RESERVEDC_HI:SCR1_DBG_ABSTRACTCS_RESERVEDC_LO] = ABSTRACTCS_RESERVEDC;
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_BUSY] = abstractcs_busy;
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_RESERVEDB] = ABSTRACTCS_RESERVEDB;
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_CMDERR_HI:SCR1_DBG_ABSTRACTCS_CMDERR_LO] = abstractcs_cmderr_ff;
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_RESERVEDA_HI:SCR1_DBG_ABSTRACTCS_RESERVEDA_LO] = ABSTRACTCS_RESERVEDA;
				dm2dmi_rdata_o[SCR1_DBG_ABSTRACTCS_DATACOUNT_HI:SCR1_DBG_ABSTRACTCS_DATACOUNT_LO] = ABSTRACTCS_DATACOUNT;
			end
			SCR1_DBG_HARTINFO: begin
				dm2dmi_rdata_o[SCR1_DBG_HARTINFO_RESERVEDB_HI:SCR1_DBG_HARTINFO_RESERVEDB_LO] = HARTINFO_RESERVEDB;
				dm2dmi_rdata_o[SCR1_DBG_HARTINFO_NSCRATCH_HI:SCR1_DBG_HARTINFO_NSCRATCH_LO] = HARTINFO_NSCRATCH;
				dm2dmi_rdata_o[SCR1_DBG_HARTINFO_RESERVEDA_HI:SCR1_DBG_HARTINFO_RESERVEDA_LO] = HARTINFO_RESERVEDA;
				dm2dmi_rdata_o[SCR1_DBG_HARTINFO_DATAACCESS] = HARTINFO_DATAACCESS;
				dm2dmi_rdata_o[SCR1_DBG_HARTINFO_DATASIZE_HI:SCR1_DBG_HARTINFO_DATASIZE_LO] = HARTINFO_DATASIZE;
				dm2dmi_rdata_o[SCR1_DBG_HARTINFO_DATAADDR_HI:SCR1_DBG_HARTINFO_DATAADDR_LO] = HARTINFO_DATAADDR;
			end
			SCR1_DBG_ABSTRACTAUTO: dm2dmi_rdata_o[0] = abs_autoexec_ff;
			SCR1_DBG_DATA0: dm2dmi_rdata_o = abs_data0_ff;
			SCR1_DBG_DATA1: dm2dmi_rdata_o = abs_data1_ff;
			SCR1_DBG_PROGBUF0: dm2dmi_rdata_o = abs_progbuf0_ff;
			SCR1_DBG_PROGBUF1: dm2dmi_rdata_o = abs_progbuf1_ff;
			SCR1_DBG_PROGBUF2: dm2dmi_rdata_o = abs_progbuf2_ff;
			SCR1_DBG_PROGBUF3: dm2dmi_rdata_o = abs_progbuf3_ff;
			SCR1_DBG_PROGBUF4: dm2dmi_rdata_o = abs_progbuf4_ff;
			SCR1_DBG_PROGBUF5: dm2dmi_rdata_o = abs_progbuf5_ff;
			SCR1_DBG_HALTSUM0: dm2dmi_rdata_o[0] = dmstatus_allany_halted_ff;
			default: dm2dmi_rdata_o = 1'sb0;
		endcase
	end
	assign dm2dmi_resp_o = 1'b1;
	assign dmcontrol_wr_req = dmi_req_dmcontrol & dmi2dm_wr_i;
	assign data0_wr_req = dmi_req_data0 & dmi2dm_wr_i;
	assign data1_wr_req = dmi_req_data1 & dmi2dm_wr_i;
	assign dreg_wr_req = pipe2dm_dreg_req_i & pipe2dm_dreg_wr_i;
	assign command_wr_req = dmi_req_command & dmi2dm_wr_i;
	assign autoexec_wr_req = dmi_req_abstractauto & dmi2dm_wr_i;
	assign progbuf0_wr_req = dmi_req_progbuf0 & dmi2dm_wr_i;
	assign progbuf1_wr_req = dmi_req_progbuf1 & dmi2dm_wr_i;
	assign progbuf2_wr_req = dmi_req_progbuf2 & dmi2dm_wr_i;
	assign progbuf3_wr_req = dmi_req_progbuf3 & dmi2dm_wr_i;
	assign progbuf4_wr_req = dmi_req_progbuf4 & dmi2dm_wr_i;
	assign progbuf5_wr_req = dmi_req_progbuf5 & dmi2dm_wr_i;
	assign abstractcs_wr_req = dmi_req_abstractcs & dmi2dm_wr_i;
	assign hart_state_reset = pipe2dm_hart_status_i[1-:2] == 2'b00;
	assign hart_state_run = pipe2dm_hart_status_i[1-:2] == 2'b01;
	assign hart_state_dhalt = pipe2dm_hart_status_i[1-:2] == 2'b10;
	assign hart_state_drun = pipe2dm_hart_status_i[1-:2] == 2'b11;
	assign clk_en_dm = (dmcontrol_wr_req | dmcontrol_dmactive_ff) | clk_en_dm_ff;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			clk_en_dm_ff <= 1'b0;
		else if (clk_en_dm)
			clk_en_dm_ff <= dmcontrol_dmactive_ff;
	assign dm2pipe_active_o = clk_en_dm_ff;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			dmcontrol_dmactive_ff <= 1'b0;
			dmcontrol_ndmreset_ff <= 1'b0;
			dmcontrol_ackhavereset_ff <= 1'b0;
			dmcontrol_haltreq_ff <= 1'b0;
			dmcontrol_resumereq_ff <= 1'b0;
		end
		else if (clk_en_dm) begin
			dmcontrol_dmactive_ff <= dmcontrol_dmactive_next;
			dmcontrol_ndmreset_ff <= dmcontrol_ndmreset_next;
			dmcontrol_ackhavereset_ff <= dmcontrol_ackhavereset_next;
			dmcontrol_haltreq_ff <= dmcontrol_haltreq_next;
			dmcontrol_resumereq_ff <= dmcontrol_resumereq_next;
		end
	assign dmcontrol_dmactive_next = (dmcontrol_wr_req ? dmi2dm_wdata_i[SCR1_DBG_DMCONTROL_DMACTIVE] : dmcontrol_dmactive_ff);
	always @(*) begin
		dmcontrol_ndmreset_next = dmcontrol_ndmreset_ff;
		dmcontrol_ackhavereset_next = dmcontrol_ackhavereset_ff;
		dmcontrol_haltreq_next = dmcontrol_haltreq_ff;
		dmcontrol_resumereq_next = dmcontrol_resumereq_ff;
		if (~dmcontrol_dmactive_ff) begin
			dmcontrol_ndmreset_next = 1'b0;
			dmcontrol_ackhavereset_next = 1'b0;
			dmcontrol_haltreq_next = 1'b0;
			dmcontrol_resumereq_next = 1'b0;
		end
		else if (dmcontrol_wr_req) begin
			dmcontrol_ndmreset_next = dmi2dm_wdata_i[SCR1_DBG_DMCONTROL_NDMRESET];
			dmcontrol_ackhavereset_next = dmi2dm_wdata_i[SCR1_DBG_DMCONTROL_ACKHAVERESET];
			dmcontrol_haltreq_next = dmi2dm_wdata_i[SCR1_DBG_DMCONTROL_HALTREQ];
			dmcontrol_resumereq_next = dmi2dm_wdata_i[SCR1_DBG_DMCONTROL_RESUMEREQ];
		end
	end
	assign hart_rst_n_o = ~dmcontrol_ndmreset_ff;
	assign ndm_rst_n_o = ~dmcontrol_ndmreset_ff;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			havereset_skip_pwrup_ff <= 1'b1;
		else if (clk_en_dm)
			havereset_skip_pwrup_ff <= havereset_skip_pwrup_next;
	assign havereset_skip_pwrup_next = (~dmcontrol_dmactive_ff ? 1'b1 : (havereset_skip_pwrup_ff ? (hart_state_reset & ndm_rst_n_o) & hart_rst_n_o : havereset_skip_pwrup_ff));
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			dmstatus_allany_havereset_ff <= 1'b0;
			dmstatus_allany_resumeack_ff <= 1'b0;
			dmstatus_allany_halted_ff <= 1'b0;
		end
		else if (clk_en_dm) begin
			dmstatus_allany_havereset_ff <= dmstatus_allany_havereset_next;
			dmstatus_allany_resumeack_ff <= dmstatus_allany_resumeack_next;
			dmstatus_allany_halted_ff <= dmstatus_allany_halted_next;
		end
	assign dmstatus_allany_havereset_next = (~dmcontrol_dmactive_ff ? 1'b0 : (~havereset_skip_pwrup_ff & hart_state_reset ? 1'b1 : (dmcontrol_ackhavereset_ff ? 1'b0 : dmstatus_allany_havereset_ff)));
	assign dmstatus_allany_resumeack_next = (~dmcontrol_dmactive_ff ? 1'b0 : (~dmcontrol_resumereq_ff ? 1'b0 : (hart_state_run ? 1'b1 : dmstatus_allany_resumeack_ff)));
	assign dmstatus_allany_halted_next = (~dmcontrol_dmactive_ff ? 1'b0 : (hart_state_dhalt ? 1'b1 : (hart_state_run ? 1'b0 : dmstatus_allany_halted_ff)));
	assign clk_en_abs = clk_en_dm & dmcontrol_dmactive_ff;
	assign abs_cmd = (dmi_req_command ? dmi2dm_wdata_i : abs_command_ff);
	localparam [31:0] SCR1_CSR_ADDR_WIDTH = 12;
	function automatic [11:0] sv2v_cast_C1AAB;
		input reg [11:0] inp;
		sv2v_cast_C1AAB = inp;
	endfunction
	localparam [11:0] SCR1_CSR_ADDR_MARCHID = sv2v_cast_C1AAB('hf12);
	localparam [11:0] SCR1_CSR_ADDR_MHARTID = sv2v_cast_C1AAB('hf14);
	localparam [11:0] SCR1_CSR_ADDR_MIMPID = sv2v_cast_C1AAB('hf13);
	localparam [11:0] SCR1_CSR_ADDR_MISA = sv2v_cast_C1AAB('h301);
	localparam [11:0] SCR1_CSR_ADDR_MVENDORID = sv2v_cast_C1AAB('hf11);
	localparam SCR1_DBG_COMMAND_ACCESSMEM_AAMPOSTINC = 5'd19;
	localparam SCR1_DBG_COMMAND_ACCESSMEM_AAMSIZE_HI = 5'd22;
	localparam SCR1_DBG_COMMAND_ACCESSMEM_AAMSIZE_LO = 5'd20;
	localparam SCR1_DBG_COMMAND_ACCESSMEM_AAMVIRTUAL = 5'd23;
	localparam SCR1_DBG_COMMAND_ACCESSMEM_RESERVEDA_HI = 5'd13;
	localparam SCR1_DBG_COMMAND_ACCESSMEM_RESERVEDB_HI = 5'd18;
	localparam SCR1_DBG_COMMAND_ACCESSMEM_WRITE = 5'd16;
	localparam SCR1_DBG_COMMAND_ACCESSREG_POSTEXEC = 5'd18;
	localparam SCR1_DBG_COMMAND_ACCESSREG_REGNO_LO = 5'd0;
	localparam SCR1_DBG_COMMAND_ACCESSREG_RESERVEDA = 5'd19;
	localparam SCR1_DBG_COMMAND_ACCESSREG_RESERVEDB = 5'd23;
	localparam SCR1_DBG_COMMAND_ACCESSREG_TRANSFER = 5'd17;
	localparam SCR1_DBG_COMMAND_ACCESSREG_WRITE = 5'd16;
	localparam [11:0] SCR1_CSR_ADDR_HDU_MBASE = sv2v_cast_C1AAB('h7b0);
	localparam [11:0] SCR1_CSR_ADDR_HDU_MSPAN = sv2v_cast_C1AAB('h4);
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_SPAN = SCR1_CSR_ADDR_HDU_MSPAN;
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_WIDTH = $clog2(SCR1_HDU_DEBUGCSR_ADDR_SPAN);
	function automatic [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] sv2v_cast_68C55;
		input reg [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] inp;
		sv2v_cast_68C55 = inp;
	endfunction
	localparam SCR1_HDU_DBGCSR_OFFS_DPC = sv2v_cast_68C55('d1);
	localparam [11:0] SCR1_HDU_DBGCSR_ADDR_DPC = SCR1_CSR_ADDR_HDU_MBASE + SCR1_HDU_DBGCSR_OFFS_DPC;
	always @(*) begin
		abs_cmd_regno = abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_REGNO_LO+:12];
		abs_cmd_csr_ro = (((((abs_cmd_regno == SCR1_CSR_ADDR_MISA) | (abs_cmd_regno == SCR1_CSR_ADDR_MVENDORID)) | (abs_cmd_regno == SCR1_CSR_ADDR_MARCHID)) | (abs_cmd_regno == SCR1_CSR_ADDR_MIMPID)) | (abs_cmd_regno == SCR1_CSR_ADDR_MHARTID)) | (abs_cmd_regno == SCR1_HDU_DBGCSR_ADDR_DPC);
		abs_cmd_type = abs_cmd[SCR1_DBG_COMMAND_TYPE_HI:SCR1_DBG_COMMAND_TYPE_LO];
		abs_cmd_regacs = abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_TRANSFER];
		abs_cmd_regtype = abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_REGNO_HI:12];
		abs_cmd_regfile = abs_cmd[11:5];
		abs_cmd_regsize = abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_SIZE_HI:SCR1_DBG_COMMAND_ACCESSREG_SIZE_LO];
		abs_cmd_regwr = abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_WRITE];
		abs_cmd_execprogbuf = abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_POSTEXEC];
		abs_cmd_regvalid = ~(|{abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_RESERVEDB], abs_cmd[SCR1_DBG_COMMAND_ACCESSREG_RESERVEDA]});
		abs_cmd_memsize = abs_cmd[SCR1_DBG_COMMAND_ACCESSMEM_AAMSIZE_HI:SCR1_DBG_COMMAND_ACCESSMEM_AAMSIZE_LO];
		abs_cmd_memwr = abs_cmd[SCR1_DBG_COMMAND_ACCESSMEM_WRITE];
		abs_cmd_memvalid = ~(|{abs_cmd[SCR1_DBG_COMMAND_ACCESSMEM_AAMVIRTUAL], abs_cmd[SCR1_DBG_COMMAND_ACCESSMEM_AAMPOSTINC], abs_cmd[SCR1_DBG_COMMAND_ACCESSMEM_RESERVEDB_HI:SCR1_DBG_COMMAND_ACCESSMEM_RESERVEDB_HI], abs_cmd[SCR1_DBG_COMMAND_ACCESSMEM_RESERVEDA_HI:SCR1_DBG_COMMAND_ACCESSMEM_RESERVEDA_HI]});
	end
	assign abs_reg_access_csr = abs_cmd_regtype == ABS_CMD_HARTREG_CSR;
	assign abs_reg_access_mprf = (abs_cmd_regtype == ABS_CMD_HARTREG_INTFPU) & (abs_cmd_regfile == ABS_CMD_HARTREG_INT);
	assign abs_cmd_regsize_vd = abs_cmd_regsize == 3'h2;
	assign abs_cmd_memsize_vd = abs_cmd_memsize < 3'h3;
	assign abs_cmd_hartreg_vd = (abs_cmd_type == ABS_CMD_HARTREG) & abs_cmd_regvalid;
	assign abs_cmd_hartmem_vd = (abs_cmd_type == ABS_CMD_HARTMEM) & abs_cmd_memvalid;
	assign abs_cmd_reg_access_req = abs_cmd_hartreg_vd & abs_cmd_regacs;
	assign abs_cmd_csr_access_req = abs_cmd_reg_access_req & abs_reg_access_csr;
	assign abs_cmd_mprf_access_req = abs_cmd_reg_access_req & abs_reg_access_mprf;
	assign abs_cmd_execprogbuf_req = abs_cmd_hartreg_vd & abs_cmd_execprogbuf;
	assign abs_cmd_csr_ro_access_vd = ((((abs_cmd_csr_access_req & abs_cmd_regsize_vd) & ~abs_cmd_regwr) & ~abs_cmd_execprogbuf) & abs_cmd_csr_ro) & hart_state_run;
	assign abs_cmd_csr_rw_access_vd = (abs_cmd_csr_access_req & abs_cmd_regsize_vd) & (abs_cmd_regwr | ~abs_cmd_csr_ro_access_vd);
	assign abs_cmd_mprf_access_vd = abs_cmd_mprf_access_req & abs_cmd_regsize_vd;
	assign abs_cmd_mem_access_vd = abs_cmd_hartmem_vd & abs_cmd_memsize_vd;
	always @(posedge clk)
		if (clk_en_abs & abs_fsm_idle) begin
			abs_cmd_postexec_ff <= abs_cmd_postexec_next;
			abs_cmd_wr_ff <= abs_cmd_wr_next;
			abs_cmd_regno_ff <= abs_cmd_regno;
			abs_cmd_size_ff <= abs_cmd_size_next;
		end
	always @(*) begin
		abs_cmd_wr_next = 1'b0;
		abs_cmd_postexec_next = 1'b0;
		abs_cmd_size_next = abs_cmd_size_ff;
		if (((command_wr_req | dmi_rpt_command) & hart_state_dhalt) & abs_fsm_idle) begin
			if (abs_cmd_csr_rw_access_vd) begin
				abs_cmd_wr_next = abs_cmd_regwr;
				abs_cmd_postexec_next = abs_cmd_execprogbuf;
			end
			else if (abs_cmd_mprf_access_vd) begin
				abs_cmd_wr_next = abs_cmd_regwr;
				abs_cmd_size_next = abs_cmd_regsize[1:0];
				abs_cmd_postexec_next = abs_cmd_execprogbuf;
			end
			else if (abs_cmd_mem_access_vd) begin
				abs_cmd_wr_next = abs_cmd_memwr;
				abs_cmd_size_next = abs_cmd_memsize[1:0];
			end
		end
	end
	always @(posedge clk)
		if (clk_en_dm) begin
			if (~dmcontrol_dmactive_ff)
				abs_fsm_ff <= 4'd0;
			else
				abs_fsm_ff <= abs_fsm_next;
		end
	always @(*) begin
		abs_fsm_next = abs_fsm_ff;
		case (abs_fsm_ff)
			4'd0:
				if (command_wr_req | dmi_rpt_command)
					case (1'b1)
						abs_cmd_csr_ro_access_vd: abs_fsm_next = 4'd9;
						abs_cmd_csr_rw_access_vd: abs_fsm_next = (hart_state_dhalt ? 4'd10 : 4'd1);
						abs_cmd_mprf_access_vd: abs_fsm_next = (hart_state_dhalt ? 4'd3 : 4'd1);
						abs_cmd_execprogbuf_req: abs_fsm_next = 4'd2;
						abs_cmd_mem_access_vd: abs_fsm_next = (hart_state_dhalt ? 4'd4 : 4'd1);
						default: abs_fsm_next = 4'd1;
					endcase
			4'd2:
				if (dhi_resp) begin
					if (dhi_resp_exc | abs_err_acc_busy_ff)
						abs_fsm_next = 4'd1;
					else
						abs_fsm_next = 4'd0;
				end
			4'd3:
				if (dhi_resp)
					case (1'b1)
						abs_err_acc_busy_ff: abs_fsm_next = 4'd1;
						abs_cmd_postexec_ff: abs_fsm_next = 4'd2;
						default: abs_fsm_next = 4'd0;
					endcase
			4'd9: abs_fsm_next = (abs_err_acc_busy_ff ? 4'd1 : 4'd0);
			4'd10: abs_fsm_next = (dhi_resp ? 4'd11 : 4'd10);
			4'd11: abs_fsm_next = (dhi_resp ? 4'd12 : 4'd11);
			4'd12:
				if (dhi_resp)
					case (1'b1)
						abs_err_exc_ff: abs_fsm_next = 4'd1;
						abs_err_acc_busy_ff: abs_fsm_next = 4'd1;
						abs_cmd_postexec_ff: abs_fsm_next = 4'd2;
						default: abs_fsm_next = 4'd0;
					endcase
			4'd4: abs_fsm_next = (dhi_resp ? 4'd5 : 4'd4);
			4'd5: abs_fsm_next = (dhi_resp ? 4'd6 : 4'd5);
			4'd6: abs_fsm_next = (dhi_resp ? 4'd7 : 4'd6);
			4'd7: abs_fsm_next = (dhi_resp ? 4'd8 : 4'd7);
			4'd8:
				if (dhi_resp)
					case (1'b1)
						abs_err_exc_ff: abs_fsm_next = 4'd1;
						abs_err_acc_busy_ff: abs_fsm_next = 4'd1;
						abs_cmd_postexec_ff: abs_fsm_next = 4'd2;
						default: abs_fsm_next = 4'd0;
					endcase
			4'd1:
				if (abstractcs_wr_req & (abstractcs_cmderr_next == 3'b000))
					abs_fsm_next = 4'd0;
		endcase
		if (~abs_fsm_idle & hart_state_reset)
			abs_fsm_next = 4'd1;
	end
	assign abs_fsm_idle = abs_fsm_ff == 4'd0;
	assign abs_fsm_exec = abs_fsm_ff == 4'd2;
	assign abs_fsm_csr_ro = abs_fsm_ff == 4'd9;
	assign abs_fsm_err = abs_fsm_ff == 4'd1;
	assign abs_fsm_use_addr = (abs_fsm_ff == 4'd5) | (abs_fsm_ff == 4'd8);
	assign abs_err_acc_busy_upd = clk_en_abs & (abs_fsm_idle | dmi_req_any);
	always @(posedge clk)
		if (abs_err_acc_busy_upd)
			abs_err_acc_busy_ff <= abs_err_acc_busy_next;
	assign abs_err_acc_busy_next = ~abs_fsm_idle & dmi_req_any;
	assign abs_err_exc_upd = clk_en_abs & (abs_fsm_idle | (dhi_resp & dhi_resp_exc));
	always @(posedge clk)
		if (abs_err_exc_upd)
			abs_err_exc_ff <= abs_err_exc_next;
	assign abs_err_exc_next = (~abs_fsm_idle & dhi_resp) & dhi_resp_exc;
	assign abs_exec_req_next = ~((abs_fsm_idle | abs_fsm_csr_ro) | abs_fsm_err) & ~dhi_resp;
	always @(posedge clk)
		if (clk_en_dm) begin
			if (~dmcontrol_dmactive_ff)
				abs_exec_req_ff <= 1'b0;
			else
				abs_exec_req_ff <= abs_exec_req_next;
		end
	always @(*) begin
		case (abs_cmd_size_ff)
			2'b00: abs_instr_mem_funct3 = (abs_cmd_wr_ff ? SCR1_FUNCT3_SB : SCR1_FUNCT3_LBU);
			2'b01: abs_instr_mem_funct3 = (abs_cmd_wr_ff ? SCR1_FUNCT3_SH : SCR1_FUNCT3_LHU);
			2'b10: abs_instr_mem_funct3 = (abs_cmd_wr_ff ? SCR1_FUNCT3_SW : SCR1_FUNCT3_LW);
			default: abs_instr_mem_funct3 = SCR1_FUNCT3_SB;
		endcase
	end
	always @(*) begin
		abs_instr_rs1 = 5'h00;
		case (abs_fsm_ff)
			4'd3: abs_instr_rs1 = (abs_cmd_wr_ff ? 5'h00 : abs_cmd_regno_ff[4:0]);
			4'd10: abs_instr_rs1 = 5'h05;
			4'd4: abs_instr_rs1 = 5'h05;
			4'd12: abs_instr_rs1 = 5'h05;
			4'd7: abs_instr_rs1 = 5'h05;
			4'd11: abs_instr_rs1 = (abs_cmd_wr_ff ? 5'h05 : 5'h00);
			4'd5: abs_instr_rs1 = 5'h06;
			4'd8: abs_instr_rs1 = 5'h06;
			4'd6: abs_instr_rs1 = 5'h06;
			default:
				;
		endcase
	end
	assign abs_instr_rs2 = 5'h05;
	always @(*) begin
		abs_instr_rd = 5'h00;
		case (abs_fsm_ff)
			4'd3: abs_instr_rd = (abs_cmd_wr_ff ? abs_cmd_regno_ff[4:0] : 5'h00);
			4'd10: abs_instr_rd = (abs_cmd_wr_ff ? 5'h05 : 5'h00);
			4'd4: abs_instr_rd = (abs_cmd_wr_ff ? 5'h05 : 5'h00);
			4'd11: abs_instr_rd = (abs_cmd_wr_ff ? 5'h00 : 5'h05);
			4'd6: abs_instr_rd = (abs_cmd_wr_ff ? 5'h00 : 5'h05);
			4'd12: abs_instr_rd = 5'h05;
			4'd7: abs_instr_rd = 5'h05;
			4'd5: abs_instr_rd = 5'h06;
			4'd8: abs_instr_rd = 5'h06;
			default:
				;
		endcase
	end
	always @(posedge clk)
		if (clk_en_abs)
			abs_exec_instr_ff <= abs_exec_instr_next;
	localparam SCR1_HDU_DBGCSR_OFFS_DSCRATCH0 = sv2v_cast_68C55('d2);
	localparam [11:0] SCR1_HDU_DBGCSR_ADDR_DSCRATCH0 = SCR1_CSR_ADDR_HDU_MBASE + SCR1_HDU_DBGCSR_OFFS_DSCRATCH0;
	always @(*) begin
		abs_exec_instr_next = abs_exec_instr_ff;
		case (abs_fsm_ff)
			4'd3, 4'd10, 4'd12, 4'd4, 4'd5, 4'd7, 4'd8: abs_exec_instr_next = {SCR1_HDU_DBGCSR_ADDR_DSCRATCH0, abs_instr_rs1, SCR1_FUNCT3_CSRRW, abs_instr_rd, SCR1_OP_SYSTEM};
			4'd11: abs_exec_instr_next = (abs_cmd_wr_ff ? {abs_cmd_regno_ff[11:0], abs_instr_rs1, SCR1_FUNCT3_CSRRW, abs_instr_rd, SCR1_OP_SYSTEM} : {abs_cmd_regno_ff[11:0], abs_instr_rs1, SCR1_FUNCT3_CSRRS, abs_instr_rd, SCR1_OP_SYSTEM});
			4'd6: abs_exec_instr_next = (abs_cmd_wr_ff ? {7'h00, abs_instr_rs2, abs_instr_rs1, abs_instr_mem_funct3, 5'h00, SCR1_OP_STORE} : {12'h000, abs_instr_rs1, abs_instr_mem_funct3, abs_instr_rd, SCR1_OP_LOAD});
			default:
				;
		endcase
	end
	function automatic [((SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 0) >= 0 ? SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 1 : 1 - (SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 0)) - 1:0] sv2v_cast_11E98;
		input reg [((SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 0) >= 0 ? SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 1 : 1 - (SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 0)) - 1:0] inp;
		sv2v_cast_11E98 = inp;
	endfunction
	function automatic [(SCR1_DBG_ABSTRACTCS_CMDERR_WDTH >= 0 ? SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 1 : 1 - SCR1_DBG_ABSTRACTCS_CMDERR_WDTH) - 1:0] sv2v_cast_0E3B4;
		input reg [(SCR1_DBG_ABSTRACTCS_CMDERR_WDTH >= 0 ? SCR1_DBG_ABSTRACTCS_CMDERR_WDTH + 1 : 1 - SCR1_DBG_ABSTRACTCS_CMDERR_WDTH) - 1:0] inp;
		sv2v_cast_0E3B4 = inp;
	endfunction
	always @(posedge clk)
		if (clk_en_dm) begin
			if (~dmcontrol_dmactive_ff)
				abstractcs_cmderr_ff <= sv2v_cast_0E3B4(sv2v_cast_11E98('d0));
			else
				abstractcs_cmderr_ff <= abstractcs_cmderr_next;
		end
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	always @(*) begin
		abstractcs_cmderr_next = abstractcs_cmderr_ff;
		case (abs_fsm_ff)
			4'd0:
				if (command_wr_req | dmi_rpt_command) begin
					if (abs_cmd_hartreg_vd)
						case (1'b1)
							abs_cmd_reg_access_req:
								case (1'b1)
									abs_cmd_csr_rw_access_vd: abstractcs_cmderr_next = (hart_state_dhalt ? abstractcs_cmderr_ff : sv2v_cast_0E3B4(sv2v_cast_11E98('d4)));
									abs_cmd_mprf_access_vd: abstractcs_cmderr_next = (hart_state_dhalt ? abstractcs_cmderr_ff : sv2v_cast_0E3B4(sv2v_cast_11E98('d4)));
									abs_cmd_csr_ro_access_vd: abstractcs_cmderr_next = abstractcs_cmderr_ff;
									default: abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d2));
								endcase
							abs_cmd_execprogbuf_req: abstractcs_cmderr_next = abstractcs_cmderr_ff;
							default: abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d2));
						endcase
					else if (abs_cmd_hartmem_vd)
						abstractcs_cmderr_next = (~abs_cmd_memsize_vd ? sv2v_cast_0E3B4(sv2v_cast_11E98('d2)) : (~hart_state_dhalt ? sv2v_cast_0E3B4(sv2v_cast_11E98('d4)) : abstractcs_cmderr_ff));
					else
						abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d2));
				end
			4'd2:
				if (dhi_resp) begin
					if (dhi_resp_exc)
						abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d3));
					else if (abs_err_acc_busy_ff)
						abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d1));
				end
			4'd3, 4'd9:
				if (abs_err_acc_busy_ff)
					abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d1));
			4'd12, 4'd8:
				if (dhi_resp)
					case (1'b1)
						abs_err_exc_ff: abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d3));
						abs_err_acc_busy_ff: abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d1));
						default: abstractcs_cmderr_next = abstractcs_cmderr_ff;
					endcase
			4'd1:
				if (dmi_req_abstractcs & dmi2dm_wr_i)
					abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_1(abstractcs_cmderr_ff) & ~dmi2dm_wdata_i[SCR1_DBG_ABSTRACTCS_CMDERR_HI:SCR1_DBG_ABSTRACTCS_CMDERR_LO]);
			default:
				;
		endcase
		if (~abs_fsm_idle & hart_state_reset)
			abstractcs_cmderr_next = sv2v_cast_0E3B4(sv2v_cast_11E98('d3));
	end
	assign abstractcs_busy = ~abs_fsm_idle & ~abs_fsm_err;
	always @(posedge clk)
		if (clk_en_dm)
			abs_command_ff <= abs_command_next;
	assign abs_command_next = (~dmcontrol_dmactive_ff ? {32 {1'sb0}} : (command_wr_req & abs_fsm_idle ? dmi2dm_wdata_i : abs_command_ff));
	always @(posedge clk)
		if (clk_en_dm)
			abs_autoexec_ff <= abs_autoexec_next;
	assign abs_autoexec_next = (~dmcontrol_dmactive_ff ? 1'b0 : (autoexec_wr_req & abs_fsm_idle ? dmi2dm_wdata_i[0] : abs_autoexec_ff));
	always @(posedge clk)
		if (clk_en_abs & abs_fsm_idle) begin
			if (progbuf0_wr_req)
				abs_progbuf0_ff <= dmi2dm_wdata_i;
			if (progbuf1_wr_req)
				abs_progbuf1_ff <= dmi2dm_wdata_i;
			if (progbuf2_wr_req)
				abs_progbuf2_ff <= dmi2dm_wdata_i;
			if (progbuf3_wr_req)
				abs_progbuf3_ff <= dmi2dm_wdata_i;
			if (progbuf4_wr_req)
				abs_progbuf4_ff <= dmi2dm_wdata_i;
			if (progbuf5_wr_req)
				abs_progbuf5_ff <= dmi2dm_wdata_i;
		end
	always @(posedge clk)
		if (clk_en_abs)
			abs_data0_ff <= abs_data0_next;
	assign data0_xreg_save = dreg_wr_req & ~abs_cmd_wr_ff;
	localparam [31:0] SCR1_CSR_MARCHID = 32'd8;
	localparam [31:0] SCR1_CSR_MIMPID = 32'h22011200;
	localparam [1:0] SCR1_MISA_MXL_32 = 2'd1;
	localparam [31:0] SCR1_CSR_MISA = (((SCR1_MISA_MXL_32 << 30) | 32'h00000100) | 32'h00000004) | 32'h00001000;
	localparam [31:0] SCR1_CSR_MVENDORID = 32'h00000000;
	always @(*) begin
		abs_data0_next = abs_data0_ff;
		case (abs_fsm_ff)
			4'd0: abs_data0_next = (data0_wr_req ? dmi2dm_wdata_i : abs_data0_ff);
			4'd2: abs_data0_next = (dreg_wr_req ? pipe2dm_dreg_wdata_i : abs_data0_ff);
			4'd10: abs_data0_next = (dreg_wr_req ? pipe2dm_dreg_wdata_i : abs_data0_ff);
			4'd12: abs_data0_next = (dreg_wr_req ? pipe2dm_dreg_wdata_i : abs_data0_ff);
			4'd4: abs_data0_next = (dreg_wr_req ? pipe2dm_dreg_wdata_i : abs_data0_ff);
			4'd7: abs_data0_next = (dreg_wr_req ? pipe2dm_dreg_wdata_i : abs_data0_ff);
			4'd3: abs_data0_next = (data0_xreg_save ? pipe2dm_dreg_wdata_i : abs_data0_ff);
			4'd9:
				case (abs_cmd_regno_ff[11:0])
					SCR1_CSR_ADDR_MISA: abs_data0_next = SCR1_CSR_MISA;
					SCR1_CSR_ADDR_MVENDORID: abs_data0_next = SCR1_CSR_MVENDORID;
					SCR1_CSR_ADDR_MARCHID: abs_data0_next = SCR1_CSR_MARCHID;
					SCR1_CSR_ADDR_MIMPID: abs_data0_next = SCR1_CSR_MIMPID;
					SCR1_CSR_ADDR_MHARTID: abs_data0_next = soc2dm_fuse_mhartid_i;
					default: abs_data0_next = pipe2dm_pc_sample_i;
				endcase
			default:
				;
		endcase
	end
	always @(posedge clk)
		if (clk_en_abs)
			abs_data1_ff <= abs_data1_next;
	always @(*) begin
		abs_data1_next = abs_data1_ff;
		case (abs_fsm_ff)
			4'd0: abs_data1_next = (data1_wr_req ? dmi2dm_wdata_i : abs_data1_ff);
			4'd5: abs_data1_next = (dreg_wr_req ? pipe2dm_dreg_wdata_i : abs_data1_ff);
			4'd8: abs_data1_next = (dreg_wr_req ? pipe2dm_dreg_wdata_i : abs_data1_ff);
			default:
				;
		endcase
	end
	assign cmd_resp_ok = pipe2dm_cmd_resp_i & ~pipe2dm_cmd_rcode_i;
	assign hart_rst_unexp = (~dhi_fsm_idle & ~dhi_fsm_halt_req) & hart_state_reset;
	assign halt_req_vd = dmcontrol_haltreq_ff & ~hart_state_dhalt;
	assign resume_req_vd = (dmcontrol_resumereq_ff & ~dmstatus_allany_resumeack_ff) & hart_state_dhalt;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			dhi_fsm_ff <= 3'd0;
		else if (clk_en_dm)
			dhi_fsm_ff <= dhi_fsm_next;
	always @(*) begin
		dhi_fsm_next = dhi_fsm_ff;
		if (~hart_rst_unexp & dmcontrol_dmactive_ff)
			case (dhi_fsm_ff)
				3'd0: dhi_fsm_next = dhi_req;
				3'd1: dhi_fsm_next = (cmd_resp_ok ? 3'd2 : 3'd1);
				3'd2: dhi_fsm_next = (hart_state_drun ? 3'd3 : 3'd2);
				3'd4: dhi_fsm_next = (cmd_resp_ok ? 3'd3 : 3'd4);
				3'd3: dhi_fsm_next = (hart_state_dhalt ? 3'd0 : 3'd3);
				3'd5: dhi_fsm_next = (cmd_resp_ok ? 3'd6 : 3'd5);
				3'd6: dhi_fsm_next = (hart_state_run ? 3'd0 : 3'd6);
				default: dhi_fsm_next = dhi_fsm_ff;
			endcase
		else
			dhi_fsm_next = 3'd0;
	end
	assign dhi_fsm_idle = dhi_fsm_ff == 3'd0;
	assign dhi_fsm_halt_req = dhi_fsm_ff == 3'd4;
	assign dhi_fsm_exec = dhi_fsm_ff == 3'd1;
	assign dhi_fsm_exec_halt = dhi_fsm_ff == 3'd3;
	assign dhi_fsm_resume_req = dhi_fsm_ff == 3'd5;
	always @(*) begin
		dhi_req = 3'd0;
		case (1'b1)
			abs_exec_req_ff: dhi_req = 3'd1;
			halt_req_vd: dhi_req = 3'd4;
			resume_req_vd: dhi_req = 3'd5;
			default: dhi_req = 3'd0;
		endcase
	end
	assign dhi_resp = dhi_fsm_exec_halt & hart_state_dhalt;
	assign dhi_resp_exc = (pipe2dm_hart_event_i & pipe2dm_hart_status_i[3]) & ~pipe2dm_hart_status_i[2];
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			hart_cmd_req_ff <= 1'b0;
		else if (clk_en_dm)
			hart_cmd_req_ff <= hart_cmd_req_next;
	assign hart_cmd_req_next = (((dhi_fsm_exec | dhi_fsm_halt_req) | dhi_fsm_resume_req) & ~cmd_resp_ok) & dmcontrol_dmactive_ff;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			hart_cmd_ff <= 2'b01;
		else if (clk_en_dm)
			hart_cmd_ff <= hart_cmd_next;
	always @(*) begin
		hart_cmd_next = 2'b01;
		if (dmcontrol_dmactive_ff)
			case (dhi_fsm_ff)
				3'd1: hart_cmd_next = 2'b11;
				3'd4: hart_cmd_next = 2'b10;
				3'd5: hart_cmd_next = 2'b01;
				default: hart_cmd_next = dm2pipe_cmd_o;
			endcase
	end
	assign dm2pipe_cmd_req_o = hart_cmd_req_ff;
	assign dm2pipe_cmd_o = hart_cmd_ff;
	always @(posedge clk)
		if (clk_en_dm)
			hart_pbuf_ebreak_ff <= hart_pbuf_ebreak_next;
	assign hart_pbuf_ebreak_next = abs_fsm_exec & (dm2pipe_pbuf_instr_o == ABS_EXEC_EBREAK);
	always @(*) begin
		dm2pipe_pbuf_instr_o = ABS_EXEC_EBREAK;
		if (abs_fsm_exec & ~hart_pbuf_ebreak_ff)
			case (pipe2dm_pbuf_addr_i)
				3'h0: dm2pipe_pbuf_instr_o = abs_progbuf0_ff;
				3'h1: dm2pipe_pbuf_instr_o = abs_progbuf1_ff;
				3'h2: dm2pipe_pbuf_instr_o = abs_progbuf2_ff;
				3'h3: dm2pipe_pbuf_instr_o = abs_progbuf3_ff;
				3'h4: dm2pipe_pbuf_instr_o = abs_progbuf4_ff;
				3'h5: dm2pipe_pbuf_instr_o = abs_progbuf5_ff;
				default:
					;
			endcase
		else if (pipe2dm_pbuf_addr_i == 3'b000)
			dm2pipe_pbuf_instr_o = abs_exec_instr_ff;
	end
	assign dm2pipe_dreg_resp_o = 1'b1;
	assign dm2pipe_dreg_fail_o = 1'b0;
	assign dm2pipe_dreg_rdata_o = (abs_fsm_use_addr ? abs_data1_ff : abs_data0_ff);
	initial _sv2v_0 = 0;
endmodule
module scr1_dmi (
	rst_n,
	clk,
	tapcsync2dmi_ch_sel_i,
	tapcsync2dmi_ch_id_i,
	tapcsync2dmi_ch_capture_i,
	tapcsync2dmi_ch_shift_i,
	tapcsync2dmi_ch_update_i,
	tapcsync2dmi_ch_tdi_i,
	dmi2tapcsync_ch_tdo_o,
	dm2dmi_resp_i,
	dm2dmi_rdata_i,
	dmi2dm_req_o,
	dmi2dm_wr_o,
	dmi2dm_addr_o,
	dmi2dm_wdata_o
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	input wire tapcsync2dmi_ch_sel_i;
	localparam SCR1_DBG_DMI_CH_ID_WIDTH = 2'd2;
	input wire [SCR1_DBG_DMI_CH_ID_WIDTH - 1:0] tapcsync2dmi_ch_id_i;
	input wire tapcsync2dmi_ch_capture_i;
	input wire tapcsync2dmi_ch_shift_i;
	input wire tapcsync2dmi_ch_update_i;
	input wire tapcsync2dmi_ch_tdi_i;
	output wire dmi2tapcsync_ch_tdo_o;
	input wire dm2dmi_resp_i;
	localparam SCR1_DBG_DMI_DATA_WIDTH = 6'd32;
	input wire [SCR1_DBG_DMI_DATA_WIDTH - 1:0] dm2dmi_rdata_i;
	output reg dmi2dm_req_o;
	output reg dmi2dm_wr_o;
	localparam SCR1_DBG_DMI_ADDR_WIDTH = 6'd7;
	output reg [SCR1_DBG_DMI_ADDR_WIDTH - 1:0] dmi2dm_addr_o;
	output reg [SCR1_DBG_DMI_DATA_WIDTH - 1:0] dmi2dm_wdata_o;
	localparam DTMCS_RESERVEDB_HI = 5'd31;
	localparam DTMCS_RESERVEDB_LO = 5'd18;
	localparam DTMCS_DMIHARDRESET = 5'd17;
	localparam DTMCS_DMIRESET = 5'd16;
	localparam DTMCS_RESERVEDA = 5'd15;
	localparam DTMCS_IDLE_HI = 5'd14;
	localparam DTMCS_IDLE_LO = 5'd12;
	localparam DTMCS_DMISTAT_HI = 5'd11;
	localparam DTMCS_DMISTAT_LO = 5'd10;
	localparam DTMCS_ABITS_HI = 5'd9;
	localparam DTMCS_ABITS_LO = 5'd4;
	localparam DTMCS_VERSION_HI = 5'd3;
	localparam DTMCS_VERSION_LO = 5'd0;
	localparam DMI_OP_LO = 5'd0;
	localparam SCR1_DBG_DMI_OP_WIDTH = 2'd2;
	localparam DMI_OP_HI = (DMI_OP_LO + SCR1_DBG_DMI_OP_WIDTH) - 1;
	localparam DMI_DATA_LO = DMI_OP_HI + 1;
	localparam DMI_DATA_HI = (DMI_DATA_LO + SCR1_DBG_DMI_DATA_WIDTH) - 1;
	localparam DMI_ADDR_LO = DMI_DATA_HI + 1;
	localparam DMI_ADDR_HI = (DMI_ADDR_LO + SCR1_DBG_DMI_ADDR_WIDTH) - 1;
	wire tap_dr_upd;
	localparam SCR1_DBG_DMI_DR_DMI_ACCESS_WIDTH = (SCR1_DBG_DMI_OP_WIDTH + SCR1_DBG_DMI_DATA_WIDTH) + SCR1_DBG_DMI_ADDR_WIDTH;
	reg [SCR1_DBG_DMI_DR_DMI_ACCESS_WIDTH - 1:0] tap_dr_ff;
	wire [SCR1_DBG_DMI_DR_DMI_ACCESS_WIDTH - 1:0] tap_dr_shift;
	reg [SCR1_DBG_DMI_DR_DMI_ACCESS_WIDTH - 1:0] tap_dr_rdata;
	wire [SCR1_DBG_DMI_DR_DMI_ACCESS_WIDTH - 1:0] tap_dr_next;
	wire dm_rdata_upd;
	reg [SCR1_DBG_DMI_DATA_WIDTH - 1:0] dm_rdata_ff;
	wire tapc_dmi_access_req;
	wire tapc_dtmcs_sel;
	assign tapc_dtmcs_sel = tapcsync2dmi_ch_id_i == 1'd1;
	always @(*) begin
		tap_dr_rdata = 1'sb0;
		if (tapc_dtmcs_sel) begin
			tap_dr_rdata[DTMCS_RESERVEDB_HI:DTMCS_RESERVEDB_LO] = 'b0;
			tap_dr_rdata[DTMCS_DMIHARDRESET] = 'b0;
			tap_dr_rdata[DTMCS_DMIRESET] = 'b0;
			tap_dr_rdata[DTMCS_RESERVEDA] = 'b0;
			tap_dr_rdata[DTMCS_IDLE_HI:DTMCS_IDLE_LO] = 'b0;
			tap_dr_rdata[DTMCS_DMISTAT_HI:DTMCS_DMISTAT_LO] = 'b0;
			tap_dr_rdata[DTMCS_ABITS_HI:DTMCS_ABITS_LO] = SCR1_DBG_DMI_ADDR_WIDTH;
			tap_dr_rdata[DTMCS_VERSION_LO] = 1'b1;
		end
		else begin
			tap_dr_rdata[DMI_ADDR_HI:DMI_ADDR_LO] = 'b0;
			tap_dr_rdata[DMI_DATA_HI:DMI_DATA_LO] = dm_rdata_ff;
			tap_dr_rdata[DMI_OP_HI:DMI_OP_LO] = 'b0;
		end
	end
	localparam SCR1_DBG_DMI_DR_DTMCS_WIDTH = 6'd32;
	assign tap_dr_shift = (tapc_dtmcs_sel ? {9'b000000000, tapcsync2dmi_ch_tdi_i, tap_dr_ff[SCR1_DBG_DMI_DR_DTMCS_WIDTH - 1:1]} : {tapcsync2dmi_ch_tdi_i, tap_dr_ff[SCR1_DBG_DMI_DR_DMI_ACCESS_WIDTH - 1:1]});
	assign tap_dr_upd = tapcsync2dmi_ch_capture_i | tapcsync2dmi_ch_shift_i;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			tap_dr_ff <= 1'sb0;
		else if (tap_dr_upd)
			tap_dr_ff <= tap_dr_next;
	assign tap_dr_next = (tapcsync2dmi_ch_capture_i ? tap_dr_rdata : (tapcsync2dmi_ch_shift_i ? tap_dr_shift : tap_dr_ff));
	assign dmi2tapcsync_ch_tdo_o = tap_dr_ff[0];
	assign tapc_dmi_access_req = (tapcsync2dmi_ch_update_i & tapcsync2dmi_ch_sel_i) & (tapcsync2dmi_ch_id_i == 2'd2);
	always @(*) begin
		dmi2dm_req_o = 1'b0;
		dmi2dm_wr_o = 1'b0;
		dmi2dm_addr_o = 1'b0;
		dmi2dm_wdata_o = 1'b0;
		if (tapc_dmi_access_req) begin
			dmi2dm_req_o = tap_dr_ff[DMI_OP_HI:DMI_OP_LO] != 2'b00;
			dmi2dm_wr_o = tap_dr_ff[DMI_OP_HI:DMI_OP_LO] == 2'b10;
			dmi2dm_addr_o = tap_dr_ff[DMI_ADDR_HI:DMI_ADDR_LO];
			dmi2dm_wdata_o = tap_dr_ff[DMI_DATA_HI:DMI_DATA_LO];
		end
	end
	assign dm_rdata_upd = (dmi2dm_req_o & dm2dmi_resp_i) & ~dmi2dm_wr_o;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			dm_rdata_ff <= 1'sb0;
		else if (dm_rdata_upd)
			dm_rdata_ff <= dm2dmi_rdata_i;
	initial _sv2v_0 = 0;
endmodule
module scr1_scu (
	pwrup_rst_n,
	rst_n,
	cpu_rst_n,
	test_mode,
	test_rst_n,
	clk,
	tapcsync2scu_ch_sel_i,
	tapcsync2scu_ch_id_i,
	tapcsync2scu_ch_capture_i,
	tapcsync2scu_ch_shift_i,
	tapcsync2scu_ch_update_i,
	tapcsync2scu_ch_tdi_i,
	scu2tapcsync_ch_tdo_o,
	ndm_rst_n_i,
	hart_rst_n_i,
	sys_rst_n_o,
	core_rst_n_o,
	dm_rst_n_o,
	hdu_rst_n_o,
	sys_rst_status_o,
	core_rst_status_o,
	sys_rdc_qlfy_o,
	core_rdc_qlfy_o,
	core2hdu_rdc_qlfy_o,
	core2dm_rdc_qlfy_o,
	hdu2dm_rdc_qlfy_o
);
	reg _sv2v_0;
	input wire pwrup_rst_n;
	input wire rst_n;
	input wire cpu_rst_n;
	input wire test_mode;
	input wire test_rst_n;
	input wire clk;
	input wire tapcsync2scu_ch_sel_i;
	input wire tapcsync2scu_ch_id_i;
	input wire tapcsync2scu_ch_capture_i;
	input wire tapcsync2scu_ch_shift_i;
	input wire tapcsync2scu_ch_update_i;
	input wire tapcsync2scu_ch_tdi_i;
	output wire scu2tapcsync_ch_tdo_o;
	input wire ndm_rst_n_i;
	input wire hart_rst_n_i;
	output wire sys_rst_n_o;
	output wire core_rst_n_o;
	output wire dm_rst_n_o;
	output wire hdu_rst_n_o;
	output wire sys_rst_status_o;
	output wire core_rst_status_o;
	output wire sys_rdc_qlfy_o;
	output wire core_rdc_qlfy_o;
	output wire core2hdu_rdc_qlfy_o;
	output wire core2dm_rdc_qlfy_o;
	output wire hdu2dm_rdc_qlfy_o;
	localparam [31:0] SCR1_SCU_RST_SYNC_STAGES_NUM = 2;
	wire scu_csr_req;
	wire tapc_dr_cap_req;
	wire tapc_dr_shft_req;
	wire tapc_dr_upd_req;
	wire tapc_shift_upd;
	localparam [31:0] SCR1_SCU_DR_SYSCTRL_ADDR_WIDTH = 2;
	localparam [31:0] SCR1_SCU_DR_SYSCTRL_DATA_WIDTH = 4;
	localparam [31:0] SCR1_SCU_DR_SYSCTRL_OP_WIDTH = 2;
	reg [((SCR1_SCU_DR_SYSCTRL_DATA_WIDTH + SCR1_SCU_DR_SYSCTRL_ADDR_WIDTH) + SCR1_SCU_DR_SYSCTRL_OP_WIDTH) - 1:0] tapc_shift_ff;
	wire [((SCR1_SCU_DR_SYSCTRL_DATA_WIDTH + SCR1_SCU_DR_SYSCTRL_ADDR_WIDTH) + SCR1_SCU_DR_SYSCTRL_OP_WIDTH) - 1:0] tapc_shift_next;
	reg [((SCR1_SCU_DR_SYSCTRL_DATA_WIDTH + SCR1_SCU_DR_SYSCTRL_ADDR_WIDTH) + SCR1_SCU_DR_SYSCTRL_OP_WIDTH) - 1:0] tapc_shadow_ff;
	reg [3:0] scu_csr_wdata;
	reg [3:0] scu_csr_rdata;
	reg [3:0] scu_control_ff;
	reg scu_control_wr_req;
	reg [3:0] scu_mode_ff;
	reg scu_mode_wr_req;
	wire [3:0] scu_status_ff;
	reg [3:0] scu_status_ff_dly;
	wire [3:0] scu_status_ff_posedge;
	reg [3:0] scu_sticky_sts_ff;
	reg scu_sticky_sts_wr_req;
	wire pwrup_rst_n_sync;
	wire rst_n_sync;
	wire cpu_rst_n_sync;
	wire sys_rst_n_in;
	wire sys_rst_n_status;
	wire sys_rst_n_status_sync;
	wire sys_rst_n_qlfy;
	wire sys_reset_n;
	wire core_rst_n_in_sync;
	wire core_rst_n_status;
	wire core_rst_n_status_sync;
	wire core_rst_n_qlfy;
	wire core_reset_n;
	wire hdu_rst_n_in_sync;
	wire hdu_rst_n_status;
	wire hdu_rst_n_status_sync;
	wire hdu_rst_n_qlfy;
	wire dm_rst_n_in;
	wire dm_rst_n_status;
	assign scu_csr_req = tapcsync2scu_ch_sel_i & (tapcsync2scu_ch_id_i == 1'b0);
	assign tapc_dr_cap_req = scu_csr_req & tapcsync2scu_ch_capture_i;
	assign tapc_dr_shft_req = scu_csr_req & tapcsync2scu_ch_shift_i;
	assign tapc_dr_upd_req = scu_csr_req & tapcsync2scu_ch_update_i;
	assign tapc_shift_upd = tapc_dr_cap_req | tapc_dr_shft_req;
	always @(posedge clk or negedge pwrup_rst_n_sync)
		if (~pwrup_rst_n_sync)
			tapc_shift_ff <= 1'sb0;
		else if (tapc_shift_upd)
			tapc_shift_ff <= tapc_shift_next;
	assign tapc_shift_next = (tapc_dr_cap_req ? tapc_shadow_ff : (tapc_dr_shft_req ? {tapcsync2scu_ch_tdi_i, tapc_shift_ff[((SCR1_SCU_DR_SYSCTRL_DATA_WIDTH + SCR1_SCU_DR_SYSCTRL_ADDR_WIDTH) + SCR1_SCU_DR_SYSCTRL_OP_WIDTH) - 1:1]} : tapc_shift_ff));
	always @(posedge clk or negedge pwrup_rst_n_sync)
		if (~pwrup_rst_n_sync)
			tapc_shadow_ff <= 1'sb0;
		else if (tapc_dr_upd_req) begin
			tapc_shadow_ff[1-:SCR1_SCU_DR_SYSCTRL_OP_WIDTH] <= tapc_shift_ff[1-:SCR1_SCU_DR_SYSCTRL_OP_WIDTH];
			tapc_shadow_ff[3-:2] <= tapc_shift_ff[3-:2];
			tapc_shadow_ff[7-:4] <= scu_csr_wdata;
		end
	assign scu2tapcsync_ch_tdo_o = tapc_shift_ff[0];
	function automatic [1:0] sv2v_cast_4192F;
		input reg [1:0] inp;
		sv2v_cast_4192F = inp;
	endfunction
	function automatic [1:0] sv2v_cast_D5441;
		input reg [1:0] inp;
		sv2v_cast_D5441 = inp;
	endfunction
	always @(*) begin
		scu_control_wr_req = 1'b0;
		scu_mode_wr_req = 1'b0;
		scu_sticky_sts_wr_req = 1'b0;
		if (tapc_dr_upd_req && (tapc_shift_ff[1-:SCR1_SCU_DR_SYSCTRL_OP_WIDTH] != sv2v_cast_4192F(2'h1)))
			case (tapc_shift_ff[3-:2])
				sv2v_cast_D5441(2'h0): scu_control_wr_req = 1'b1;
				sv2v_cast_D5441(2'h1): scu_mode_wr_req = 1'b1;
				sv2v_cast_D5441(2'h3): scu_sticky_sts_wr_req = tapc_shift_ff[1-:SCR1_SCU_DR_SYSCTRL_OP_WIDTH] == sv2v_cast_4192F(2'h3);
				default:
					;
			endcase
	end
	always @(*) begin
		scu_csr_wdata = 1'sb0;
		if (tapc_dr_upd_req)
			case (tapc_shift_ff[1-:SCR1_SCU_DR_SYSCTRL_OP_WIDTH])
				sv2v_cast_4192F(2'h0): scu_csr_wdata = tapc_shift_ff[7-:4];
				sv2v_cast_4192F(2'h1): scu_csr_wdata = scu_csr_rdata;
				sv2v_cast_4192F(2'h2): scu_csr_wdata = scu_csr_rdata | tapc_shift_ff[7-:4];
				sv2v_cast_4192F(2'h3): scu_csr_wdata = scu_csr_rdata & ~tapc_shift_ff[7-:4];
				default:
					;
			endcase
	end
	always @(*) begin
		scu_csr_rdata = 1'sb0;
		if (tapc_dr_upd_req)
			case (tapc_shift_ff[3-:2])
				sv2v_cast_D5441(2'h0): scu_csr_rdata = scu_control_ff;
				sv2v_cast_D5441(2'h1): scu_csr_rdata = scu_mode_ff;
				sv2v_cast_D5441(2'h2): scu_csr_rdata = scu_status_ff;
				sv2v_cast_D5441(2'h3): scu_csr_rdata = scu_sticky_sts_ff;
				default: scu_csr_rdata = 1'sbx;
			endcase
	end
	always @(posedge clk or negedge pwrup_rst_n_sync)
		if (~pwrup_rst_n_sync)
			scu_control_ff <= 1'sb0;
		else if (scu_control_wr_req)
			scu_control_ff <= scu_csr_wdata;
	always @(posedge clk or negedge pwrup_rst_n_sync)
		if (~pwrup_rst_n_sync)
			scu_mode_ff <= 1'sb0;
		else if (scu_mode_wr_req)
			scu_mode_ff <= scu_csr_wdata;
	assign scu_status_ff[0] = sys_rst_status_o;
	assign scu_status_ff[1] = core_rst_status_o;
	assign scu_status_ff[2] = ~dm_rst_n_status;
	assign scu_status_ff[3] = ~hdu_rst_n_status_sync;
	always @(posedge clk or negedge pwrup_rst_n_sync)
		if (~pwrup_rst_n_sync)
			scu_status_ff_dly <= 1'sb0;
		else
			scu_status_ff_dly <= scu_status_ff;
	assign scu_status_ff_posedge = scu_status_ff & ~scu_status_ff_dly;
	always @(posedge clk or negedge pwrup_rst_n_sync)
		if (~pwrup_rst_n_sync)
			scu_sticky_sts_ff <= 1'sb0;
		else begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				if (scu_status_ff_posedge[i])
					scu_sticky_sts_ff[i] <= 1'b1;
				else if (scu_sticky_sts_wr_req)
					scu_sticky_sts_ff[i] <= scu_csr_wdata[i];
		end
	assign pwrup_rst_n_sync = pwrup_rst_n;
	assign rst_n_sync = rst_n;
	assign cpu_rst_n_sync = cpu_rst_n;
	assign sys_reset_n = ~scu_control_ff[0];
	assign core_reset_n = ~scu_control_ff[1];
	scr1_reset_qlfy_adapter_cell_sync i_sys_rstn_qlfy_adapter_cell_sync(
		.rst_n(pwrup_rst_n_sync),
		.clk(clk),
		.test_rst_n(test_rst_n),
		.test_mode(test_mode),
		.reset_n_in_sync(sys_rst_n_in),
		.reset_n_out_qlfy(sys_rst_n_qlfy),
		.reset_n_out(sys_rst_n_o),
		.reset_n_status(sys_rst_n_status)
	);
	assign sys_rst_n_in = (sys_reset_n & ndm_rst_n_i) & rst_n_sync;
	scr1_data_sync_cell #(.STAGES_AMOUNT(SCR1_SCU_RST_SYNC_STAGES_NUM)) i_sys_rstn_status_sync(
		.rst_n(pwrup_rst_n_sync),
		.clk(clk),
		.data_in(sys_rst_n_status),
		.data_out(sys_rst_n_status_sync)
	);
	assign sys_rst_status_o = ~sys_rst_n_status_sync;
	assign sys_rdc_qlfy_o = sys_rst_n_qlfy;
	scr1_reset_qlfy_adapter_cell_sync i_core_rstn_qlfy_adapter_cell_sync(
		.rst_n(pwrup_rst_n_sync),
		.clk(clk),
		.test_rst_n(test_rst_n),
		.test_mode(test_mode),
		.reset_n_in_sync(core_rst_n_in_sync),
		.reset_n_out_qlfy(core_rst_n_qlfy),
		.reset_n_out(core_rst_n_o),
		.reset_n_status(core_rst_n_status)
	);
	assign core_rst_n_in_sync = ((sys_rst_n_in & hart_rst_n_i) & core_reset_n) & cpu_rst_n_sync;
	scr1_data_sync_cell #(.STAGES_AMOUNT(SCR1_SCU_RST_SYNC_STAGES_NUM)) i_core_rstn_status_sync(
		.rst_n(pwrup_rst_n_sync),
		.clk(clk),
		.data_in(core_rst_n_status),
		.data_out(core_rst_n_status_sync)
	);
	assign core_rst_status_o = ~core_rst_n_status_sync;
	assign core_rdc_qlfy_o = core_rst_n_qlfy;
	assign core2hdu_rdc_qlfy_o = core_rst_n_qlfy;
	assign core2dm_rdc_qlfy_o = core_rst_n_qlfy;
	scr1_reset_qlfy_adapter_cell_sync i_hdu_rstn_qlfy_adapter_cell_sync(
		.rst_n(pwrup_rst_n_sync),
		.clk(clk),
		.test_rst_n(test_rst_n),
		.test_mode(test_mode),
		.reset_n_in_sync(hdu_rst_n_in_sync),
		.reset_n_out_qlfy(hdu_rst_n_qlfy),
		.reset_n_out(hdu_rst_n_o),
		.reset_n_status(hdu_rst_n_status)
	);
	assign hdu_rst_n_in_sync = scu_mode_ff[1] | core_rst_n_in_sync;
	scr1_data_sync_cell #(.STAGES_AMOUNT(SCR1_SCU_RST_SYNC_STAGES_NUM)) i_hdu_rstn_status_sync(
		.rst_n(pwrup_rst_n_sync),
		.clk(clk),
		.data_in(hdu_rst_n_status),
		.data_out(hdu_rst_n_status_sync)
	);
	assign hdu2dm_rdc_qlfy_o = hdu_rst_n_qlfy;
	scr1_reset_buf_cell i_dm_rstn_buf_cell(
		.rst_n(pwrup_rst_n_sync),
		.clk(clk),
		.test_mode(test_mode),
		.test_rst_n(test_rst_n),
		.reset_n_in(dm_rst_n_in),
		.reset_n_out(dm_rst_n_o),
		.reset_n_status(dm_rst_n_status)
	);
	assign dm_rst_n_in = ~scu_mode_ff[0] | sys_reset_n;
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_hdu (
	rst_n,
	clk,
	clk_en,
	clk_pipe_en,
	pipe2hdu_rdc_qlfy_i,
	csr2hdu_req_i,
	csr2hdu_cmd_i,
	csr2hdu_addr_i,
	csr2hdu_wdata_i,
	hdu2csr_resp_o,
	hdu2csr_rdata_o,
	dm2hdu_cmd_req_i,
	dm2hdu_cmd_i,
	hdu2dm_cmd_resp_o,
	hdu2dm_cmd_rcode_o,
	hdu2dm_hart_event_o,
	hdu2dm_hart_status_o,
	hdu2dm_pbuf_addr_o,
	dm2hdu_pbuf_instr_i,
	hdu2dm_dreg_req_o,
	hdu2dm_dreg_wr_o,
	hdu2dm_dreg_wdata_o,
	dm2hdu_dreg_resp_i,
	dm2hdu_dreg_fail_i,
	dm2hdu_dreg_rdata_i,
	hdu2tdu_hwbrk_dsbl_o,
	tdu2hdu_dmode_req_i,
	exu2hdu_ibrkpt_hw_i,
	pipe2hdu_exu_busy_i,
	pipe2hdu_instret_i,
	pipe2hdu_init_pc_i,
	pipe2hdu_exu_exc_req_i,
	pipe2hdu_brkpt_i,
	hdu2exu_pbuf_fetch_o,
	hdu2exu_no_commit_o,
	hdu2exu_irq_dsbl_o,
	hdu2exu_pc_advmt_dsbl_o,
	hdu2exu_dmode_sstep_en_o,
	hdu2exu_dbg_halted_o,
	hdu2exu_dbg_run2halt_o,
	hdu2exu_dbg_halt2run_o,
	hdu2exu_dbg_run_start_o,
	pipe2hdu_pc_curr_i,
	hdu2exu_dbg_new_pc_o,
	ifu2hdu_pbuf_instr_rdy_i,
	hdu2ifu_pbuf_instr_vd_o,
	hdu2ifu_pbuf_instr_err_o,
	hdu2ifu_pbuf_instr_o
);
	reg _sv2v_0;
	parameter HART_PBUF_INSTR_REGOUT_EN = 1'b1;
	input wire rst_n;
	input wire clk;
	input wire clk_en;
	input wire clk_pipe_en;
	input wire pipe2hdu_rdc_qlfy_i;
	input wire csr2hdu_req_i;
	localparam SCR1_CSR_CMD_ALL_NUM_E = 4;
	localparam SCR1_CSR_CMD_WIDTH_E = 2;
	input wire [1:0] csr2hdu_cmd_i;
	localparam [31:0] SCR1_CSR_ADDR_WIDTH = 12;
	function automatic [11:0] sv2v_cast_C1AAB;
		input reg [11:0] inp;
		sv2v_cast_C1AAB = inp;
	endfunction
	localparam [11:0] SCR1_CSR_ADDR_HDU_MSPAN = sv2v_cast_C1AAB('h4);
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_SPAN = SCR1_CSR_ADDR_HDU_MSPAN;
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_WIDTH = $clog2(SCR1_HDU_DEBUGCSR_ADDR_SPAN);
	input wire [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] csr2hdu_addr_i;
	input wire [31:0] csr2hdu_wdata_i;
	output wire hdu2csr_resp_o;
	output wire [31:0] hdu2csr_rdata_o;
	input wire dm2hdu_cmd_req_i;
	input wire [1:0] dm2hdu_cmd_i;
	output reg hdu2dm_cmd_resp_o;
	output wire hdu2dm_cmd_rcode_o;
	output wire hdu2dm_hart_event_o;
	output reg [3:0] hdu2dm_hart_status_o;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_SPAN = 8;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_WIDTH = 3;
	output wire [2:0] hdu2dm_pbuf_addr_o;
	localparam [31:0] SCR1_HDU_CORE_INSTR_WIDTH = 32;
	input wire [31:0] dm2hdu_pbuf_instr_i;
	output wire hdu2dm_dreg_req_o;
	output wire hdu2dm_dreg_wr_o;
	output wire [31:0] hdu2dm_dreg_wdata_o;
	input wire dm2hdu_dreg_resp_i;
	input wire dm2hdu_dreg_fail_i;
	input wire [31:0] dm2hdu_dreg_rdata_i;
	output wire hdu2tdu_hwbrk_dsbl_o;
	input wire tdu2hdu_dmode_req_i;
	input wire exu2hdu_ibrkpt_hw_i;
	input wire pipe2hdu_exu_busy_i;
	input wire pipe2hdu_instret_i;
	input wire pipe2hdu_init_pc_i;
	input wire pipe2hdu_exu_exc_req_i;
	input wire pipe2hdu_brkpt_i;
	output wire hdu2exu_pbuf_fetch_o;
	output wire hdu2exu_no_commit_o;
	output wire hdu2exu_irq_dsbl_o;
	output wire hdu2exu_pc_advmt_dsbl_o;
	output wire hdu2exu_dmode_sstep_en_o;
	output wire hdu2exu_dbg_halted_o;
	output wire hdu2exu_dbg_run2halt_o;
	output wire hdu2exu_dbg_halt2run_o;
	output wire hdu2exu_dbg_run_start_o;
	input wire [31:0] pipe2hdu_pc_curr_i;
	output wire [31:0] hdu2exu_dbg_new_pc_o;
	input wire ifu2hdu_pbuf_instr_rdy_i;
	output wire hdu2ifu_pbuf_instr_vd_o;
	output wire hdu2ifu_pbuf_instr_err_o;
	output reg [31:0] hdu2ifu_pbuf_instr_o;
	localparam [31:0] SCR1_HDU_TIMEOUT = 64;
	localparam [31:0] SCR1_HDU_TIMEOUT_WIDTH = 6;
	wire dm_dhalt_req;
	wire dm_run_req;
	wire dm_cmd_run;
	wire dm_cmd_dhalted;
	wire dm_cmd_drun;
	reg [1:0] dbg_state;
	reg [1:0] dbg_state_next;
	wire dbg_state_dhalted;
	wire dbg_state_drun;
	wire dbg_state_run;
	wire dbg_state_reset;
	reg dfsm_trans;
	reg dfsm_trans_next;
	reg dfsm_update;
	reg dfsm_update_next;
	reg dfsm_event;
	reg dfsm_event_next;
	wire hart_resume_req;
	wire hart_halt_req;
	reg hart_cmd_req;
	wire hart_runctrl_upd;
	wire hart_runctrl_clr;
	reg [5:0] hart_runctrl;
	reg [5:0] halt_req_timeout_cnt;
	wire [5:0] halt_req_timeout_cnt_next;
	wire halt_req_timeout_cnt_en;
	wire halt_req_timeout_flag;
	reg [3:0] hart_haltstatus;
	reg [2:0] hart_haltcause;
	wire hart_halt_pnd;
	wire hart_halt_ack;
	wire dmode_cause_sstep;
	wire dmode_cause_except;
	wire dmode_cause_ebreak;
	wire dmode_cause_any;
	wire dmode_cause_tmreq;
	wire ifu_handshake_done;
	wire pbuf_exc_inj_req;
	wire pbuf_exc_inj_end;
	wire pbuf_start_fetch;
	reg [1:0] pbuf_fsm_curr;
	reg [1:0] pbuf_fsm_next;
	wire pbuf_fsm_idle;
	wire pbuf_fsm_fetch;
	wire pbuf_fsm_excinj;
	reg [2:0] pbuf_addr_ff;
	wire [2:0] pbuf_addr_next;
	wire pbuf_addr_end;
	wire pbuf_addr_next_vd;
	reg pbuf_instr_wait_latching;
	wire csr_upd_on_halt;
	wire csr_wr;
	reg [31:0] csr_wr_data;
	wire [31:0] csr_rd_data;
	reg csr_dcsr_sel;
	reg csr_dcsr_wr;
	reg [(((((((((((32'sd31 - 32'sd28) >= 0 ? (32'sd31 - 32'sd28) + 1 : -2) + ((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10)) + 1) + ((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1)) + 1) + ((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0)) + ((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1)) + ((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1)) + 1) + ((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0)) - 1:0] csr_dcsr_in;
	reg [(((((((((((32'sd31 - 32'sd28) >= 0 ? (32'sd31 - 32'sd28) + 1 : -2) + ((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10)) + 1) + ((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1)) + 1) + ((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0)) + ((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1)) + ((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1)) + 1) + ((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0)) - 1:0] csr_dcsr_out;
	reg csr_dcsr_ebreakm;
	reg csr_dcsr_stepie;
	reg csr_dcsr_step;
	reg [32'sd8 - 32'sd6:0] csr_dcsr_cause;
	reg csr_dpc_sel;
	wire csr_dpc_wr;
	reg [31:0] csr_dpc_ff;
	wire [31:0] csr_dpc_next;
	wire [31:0] csr_dpc_out;
	wire csr_addr_dscratch0;
	reg csr_dscratch0_sel;
	wire csr_dscratch0_wr;
	wire [31:0] csr_dscratch0_out;
	wire csr_dscratch0_resp;
	assign dm_cmd_dhalted = dm2hdu_cmd_i == 2'b10;
	assign dm_cmd_run = dm2hdu_cmd_i == 2'b01;
	assign dm_cmd_drun = dm2hdu_cmd_i == 2'b11;
	assign dm_dhalt_req = dm2hdu_cmd_req_i & dm_cmd_dhalted;
	assign dm_run_req = dm2hdu_cmd_req_i & (dm_cmd_run | dm_cmd_drun);
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			dbg_state <= 2'b00;
		else
			dbg_state <= dbg_state_next;
	always @(*) begin
		if (~pipe2hdu_rdc_qlfy_i)
			dbg_state_next = 2'b00;
		else
			case (dbg_state)
				2'b00: dbg_state_next = (~pipe2hdu_init_pc_i ? 2'b00 : (dm_dhalt_req ? 2'b10 : 2'b01));
				2'b01: dbg_state_next = (dfsm_update ? 2'b10 : 2'b01);
				2'b10: dbg_state_next = (~dfsm_update ? 2'b10 : (dm_cmd_drun ? 2'b11 : 2'b01));
				2'b11: dbg_state_next = (dfsm_update ? 2'b10 : 2'b11);
				default: dbg_state_next = dbg_state;
			endcase
	end
	assign dbg_state_dhalted = dbg_state == 2'b10;
	assign dbg_state_drun = dbg_state == 2'b11;
	assign dbg_state_run = dbg_state == 2'b01;
	assign dbg_state_reset = dbg_state == 2'b00;
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			dfsm_trans <= 1'b0;
			dfsm_update <= 1'b0;
			dfsm_event <= 1'b0;
		end
		else begin
			dfsm_trans <= dfsm_trans_next;
			dfsm_update <= dfsm_update_next;
			dfsm_event <= dfsm_event_next;
		end
	always @(*) begin
		dfsm_trans_next = 1'b0;
		dfsm_update_next = 1'b0;
		dfsm_event_next = 1'b0;
		if (~pipe2hdu_rdc_qlfy_i) begin
			dfsm_trans_next = 1'b0;
			dfsm_update_next = 1'b0;
			dfsm_event_next = 1'b1;
		end
		else
			case (dbg_state)
				2'b00: begin
					dfsm_trans_next = 1'b0;
					dfsm_update_next = 1'b0;
					dfsm_event_next = pipe2hdu_init_pc_i & ~dm2hdu_cmd_req_i;
				end
				2'b01, 2'b11: begin
					dfsm_trans_next = (~dfsm_update ? hart_halt_pnd : dfsm_trans);
					dfsm_update_next = ~dfsm_update & hart_halt_ack;
					dfsm_event_next = dfsm_update;
				end
				2'b10: begin
					dfsm_trans_next = (~dfsm_update ? ~dfsm_trans & dm_run_req : dfsm_trans);
					dfsm_update_next = ~dfsm_update & dfsm_trans;
					dfsm_event_next = dfsm_update;
				end
				default: begin
					dfsm_trans_next = 1'sbx;
					dfsm_update_next = 1'sbx;
					dfsm_event_next = 1'sbx;
				end
			endcase
	end
	always @(*) begin
		hart_cmd_req = 1'b0;
		if (~pipe2hdu_rdc_qlfy_i)
			hart_cmd_req = 1'b0;
		else
			case (dbg_state)
				2'b00: hart_cmd_req = dm2hdu_cmd_req_i;
				2'b10: hart_cmd_req = dfsm_update | dfsm_trans;
				2'b01, 2'b11: hart_cmd_req = ~dfsm_update & dfsm_trans;
				default: hart_cmd_req = 1'sbx;
			endcase
	end
	assign hart_halt_req = dm_cmd_dhalted & hart_cmd_req;
	assign hart_resume_req = (dm_cmd_run | dm_cmd_drun) & hart_cmd_req;
	assign hart_runctrl_clr = (dbg_state_run | dbg_state_drun) & (dbg_state_next == 2'b10);
	assign hart_runctrl_upd = dbg_state_dhalted & dfsm_trans_next;
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			hart_runctrl[5] <= 1'b0;
			hart_runctrl[4] <= 1'b0;
			hart_runctrl[3] <= 1'b0;
			hart_runctrl[2] <= 1'b0;
			hart_runctrl[1-:2] <= 1'sb0;
		end
		else if (clk_en) begin
			if (hart_runctrl_clr)
				hart_runctrl <= 1'sb0;
			else if (hart_runctrl_upd) begin
				if (~dm_cmd_drun) begin
					hart_runctrl[5] <= (csr_dcsr_step ? ~csr_dcsr_stepie : 1'b0);
					hart_runctrl[4] <= 1'b0;
					hart_runctrl[3] <= 1'b0;
					hart_runctrl[2] <= 1'b0;
					hart_runctrl[1] <= csr_dcsr_step;
					hart_runctrl[0] <= csr_dcsr_ebreakm;
				end
				else begin
					hart_runctrl[5] <= 1'b1;
					hart_runctrl[4] <= 1'b1;
					hart_runctrl[3] <= 1'b1;
					hart_runctrl[2] <= 1'b1;
					hart_runctrl[1] <= 1'b0;
					hart_runctrl[0] <= 1'b1;
				end
			end
		end
	assign halt_req_timeout_cnt_en = hdu2exu_dbg_halt2run_o | (hart_halt_req & ~hdu2exu_dbg_run2halt_o);
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			halt_req_timeout_cnt <= 1'sb1;
		else if (halt_req_timeout_cnt_en)
			halt_req_timeout_cnt <= halt_req_timeout_cnt_next;
	assign halt_req_timeout_cnt_next = (hdu2exu_dbg_halt2run_o ? {SCR1_HDU_TIMEOUT_WIDTH {1'sb1}} : (hart_halt_req & ~hdu2exu_dbg_run2halt_o ? halt_req_timeout_cnt - 1'b1 : halt_req_timeout_cnt));
	assign halt_req_timeout_flag = ~|halt_req_timeout_cnt;
	assign dmode_cause_sstep = hart_runctrl[1] & pipe2hdu_instret_i;
	assign dmode_cause_except = ((dbg_state_drun & pipe2hdu_exu_exc_req_i) & ~pipe2hdu_brkpt_i) & ~exu2hdu_ibrkpt_hw_i;
	assign dmode_cause_ebreak = hart_runctrl[0] & pipe2hdu_brkpt_i;
	assign dmode_cause_tmreq = tdu2hdu_dmode_req_i & exu2hdu_ibrkpt_hw_i;
	assign dmode_cause_any = (((dmode_cause_sstep | dmode_cause_ebreak) | dmode_cause_except) | hart_halt_req) | dmode_cause_tmreq;
	always @(*) begin
		case (1'b1)
			dmode_cause_tmreq: hart_haltcause = 3'b010;
			dmode_cause_ebreak: hart_haltcause = 3'b001;
			hart_halt_req: hart_haltcause = 3'b011;
			dmode_cause_sstep: hart_haltcause = 3'b100;
			default: hart_haltcause = 3'b000;
		endcase
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			hart_haltstatus <= 1'sb0;
		else if (hart_halt_ack) begin
			hart_haltstatus[3] <= dmode_cause_except;
			hart_haltstatus[2-:3] <= hart_haltcause;
		end
	assign hart_halt_pnd = (dfsm_trans | dm_dhalt_req) & ~hart_halt_ack;
	assign hart_halt_ack = ~hdu2exu_dbg_halted_o & (halt_req_timeout_flag | (~pipe2hdu_exu_busy_i & dmode_cause_any));
	assign ifu_handshake_done = hdu2ifu_pbuf_instr_vd_o & ifu2hdu_pbuf_instr_rdy_i;
	assign pbuf_addr_end = pbuf_addr_ff == 7;
	assign pbuf_start_fetch = dbg_state_dhalted & (dbg_state_next == 2'b11);
	assign pbuf_exc_inj_req = ifu_handshake_done & pbuf_addr_end;
	assign pbuf_exc_inj_end = pipe2hdu_exu_exc_req_i | ifu_handshake_done;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			pbuf_fsm_curr <= 2'b00;
		else if (clk_en)
			pbuf_fsm_curr <= pbuf_fsm_next;
	always @(*) begin
		pbuf_fsm_next = pbuf_fsm_curr;
		case (pbuf_fsm_curr)
			2'b00: pbuf_fsm_next = (pbuf_start_fetch ? 2'b01 : 2'b00);
			2'b01: pbuf_fsm_next = (pipe2hdu_exu_exc_req_i ? 2'b11 : (pbuf_exc_inj_req ? 2'b10 : 2'b01));
			2'b10: pbuf_fsm_next = (pbuf_exc_inj_end ? 2'b11 : 2'b10);
			2'b11: pbuf_fsm_next = (hdu2exu_dbg_halted_o ? 2'b00 : 2'b11);
			default: pbuf_fsm_next = pbuf_fsm_curr;
		endcase
	end
	assign pbuf_fsm_idle = pbuf_fsm_curr == 2'b00;
	assign pbuf_fsm_fetch = pbuf_fsm_curr == 2'b01;
	assign pbuf_fsm_excinj = pbuf_fsm_curr == 2'b10;
	assign pbuf_addr_next_vd = ((pbuf_fsm_fetch & ifu_handshake_done) & ~pipe2hdu_exu_exc_req_i) & ~pbuf_addr_end;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			pbuf_addr_ff <= 1'sb0;
		else if (clk_en)
			pbuf_addr_ff <= pbuf_addr_next;
	assign pbuf_addr_next = (pbuf_fsm_idle ? {SCR1_HDU_PBUF_ADDR_WIDTH {1'sb0}} : (pbuf_addr_next_vd ? pbuf_addr_ff + 1'b1 : pbuf_addr_ff));
	generate
		if (HART_PBUF_INSTR_REGOUT_EN) begin : genblk1
			always @(posedge clk or negedge rst_n)
				if (~rst_n)
					pbuf_instr_wait_latching <= 1'b0;
				else
					pbuf_instr_wait_latching <= ifu_handshake_done;
		end
		else begin : genblk1
			wire [1:1] sv2v_tmp_8D5F6;
			assign sv2v_tmp_8D5F6 = 1'b0;
			always @(*) pbuf_instr_wait_latching = sv2v_tmp_8D5F6;
		end
	endgenerate
	assign csr_upd_on_halt = (dbg_state_reset | dbg_state_run) & (dbg_state_next == 2'b10);
	function automatic [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] sv2v_cast_68C55;
		input reg [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] inp;
		sv2v_cast_68C55 = inp;
	endfunction
	localparam SCR1_HDU_DBGCSR_OFFS_DCSR = sv2v_cast_68C55('d0);
	localparam SCR1_HDU_DBGCSR_OFFS_DPC = sv2v_cast_68C55('d1);
	localparam SCR1_HDU_DBGCSR_OFFS_DSCRATCH0 = sv2v_cast_68C55('d2);
	always @(*) begin : csr_if_regsel
		csr_dcsr_sel = 1'b0;
		csr_dpc_sel = 1'b0;
		csr_dscratch0_sel = 1'b0;
		if (csr2hdu_req_i)
			case (csr2hdu_addr_i)
				SCR1_HDU_DBGCSR_OFFS_DCSR: csr_dcsr_sel = 1'b1;
				SCR1_HDU_DBGCSR_OFFS_DPC: csr_dpc_sel = 1'b1;
				SCR1_HDU_DBGCSR_OFFS_DSCRATCH0: csr_dscratch0_sel = 1'b1;
				default: begin
					csr_dcsr_sel = 1'bx;
					csr_dpc_sel = 1'bx;
					csr_dscratch0_sel = 1'bx;
				end
			endcase
	end
	assign csr_rd_data = (csr_dcsr_out | csr_dpc_out) | csr_dscratch0_out;
	assign csr_wr = csr2hdu_req_i;
	function automatic [1:0] sv2v_cast_999B9;
		input reg [1:0] inp;
		sv2v_cast_999B9 = inp;
	endfunction
	always @(*) begin : csr_if_write
		csr_wr_data = 1'sb0;
		if (csr2hdu_req_i)
			case (csr2hdu_cmd_i)
				sv2v_cast_999B9({32 {1'sb0}} + 1): csr_wr_data = csr2hdu_wdata_i;
				sv2v_cast_999B9({32 {1'sb0}} + 2): csr_wr_data = csr_rd_data | csr2hdu_wdata_i;
				sv2v_cast_999B9({32 {1'sb0}} + 3): csr_wr_data = csr_rd_data & ~csr2hdu_wdata_i;
				default: csr_wr_data = 1'sbx;
			endcase
	end
	localparam [3:0] SCR1_HDU_DEBUGCSR_DCSR_XDEBUGVER = 4'h4;
	always @(*) begin
		csr_dcsr_in = csr_wr_data;
		csr_dcsr_wr = csr_wr & csr_dcsr_sel;
		csr_dcsr_out = 1'sb0;
		if (csr_dcsr_sel) begin
			csr_dcsr_out[((32'sd31 - 32'sd28) >= 0 ? (32'sd31 - 32'sd28) + 1 : -2) + (((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10) + (1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))))))-:((((32'sd31 - 32'sd28) >= 0 ? (32'sd31 - 32'sd28) + 1 : -2) + (((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10) + (1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))))))) >= (((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10) + (1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (1 + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))))))) ? ((((32'sd31 - 32'sd28) >= 0 ? (32'sd31 - 32'sd28) + 1 : -2) + (((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10) + (1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))))))) - (((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10) + (1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (1 + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0)))))))))) + 1 : ((((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10) + (1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (1 + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))))))) - (((32'sd31 - 32'sd28) >= 0 ? (32'sd31 - 32'sd28) + 1 : -2) + (((32'sd27 - 32'sd16) >= 0 ? (32'sd27 - 32'sd16) + 1 : -10) + (1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0)))))))))) + 1)] = SCR1_HDU_DEBUGCSR_DCSR_XDEBUGVER;
			csr_dcsr_out[1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))))] = csr_dcsr_ebreakm;
			csr_dcsr_out[1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))] = csr_dcsr_stepie;
			csr_dcsr_out[((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0] = csr_dcsr_step;
			csr_dcsr_out[((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) - 1-:((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0)] = 2'b11;
			csr_dcsr_out[((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))-:((((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))) >= (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (1 + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))) ? ((((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))) - (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (1 + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0)))) + 1 : ((((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (1 + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))) - (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0)))) + 1)] = csr_dcsr_cause;
		end
	end
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			csr_dcsr_ebreakm <= 1'b0;
			csr_dcsr_stepie <= 1'b0;
			csr_dcsr_step <= 1'b0;
		end
		else if (clk_en) begin
			if (csr_dcsr_wr) begin
				csr_dcsr_ebreakm <= csr_dcsr_in[1 + (((32'sd14 - 32'sd12) >= 0 ? (32'sd14 - 32'sd12) + 1 : -1) + (1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))))];
				csr_dcsr_stepie <= csr_dcsr_in[1 + (((32'sd10 - 32'sd9) >= 0 ? (32'sd10 - 32'sd9) + 1 : 0) + (((32'sd8 - 32'sd6) >= 0 ? (32'sd8 - 32'sd6) + 1 : -1) + (((32'sd5 - 32'sd3) >= 0 ? (32'sd5 - 32'sd3) + 1 : -1) + (((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0))))];
				csr_dcsr_step <= csr_dcsr_in[((32'sd1 - 32'sd0) >= 0 ? (32'sd1 - 32'sd0) + 1 : 0) + 0];
			end
		end
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			csr_dcsr_cause <= 1'b0;
		else if (clk_en) begin
			if (csr_upd_on_halt)
				csr_dcsr_cause <= hart_haltstatus[2-:3];
		end
	assign csr_dpc_wr = csr_wr & csr_dpc_sel;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			csr_dpc_ff <= 1'sb0;
		else if (clk_en)
			csr_dpc_ff <= csr_dpc_next;
	assign csr_dpc_next = (csr_upd_on_halt ? pipe2hdu_pc_curr_i : (csr_dpc_wr ? csr_wr_data : csr_dpc_ff));
	assign csr_dpc_out = (csr_dpc_sel ? csr_dpc_ff : {32 {1'sb0}});
	assign csr_dscratch0_resp = (~dm2hdu_dreg_resp_i | dm2hdu_dreg_fail_i ? 1'd1 : 1'd0);
	assign csr_dscratch0_out = (csr_dscratch0_sel ? dm2hdu_dreg_rdata_i : {32 {1'sb0}});
	assign hdu2dm_hart_event_o = dfsm_event;
	always @(*) begin
		hdu2dm_hart_status_o = 1'sb0;
		hdu2dm_hart_status_o[1-:2] = dbg_state;
		hdu2dm_hart_status_o[3] = dbg_state_dhalted & hart_haltstatus[3];
		hdu2dm_hart_status_o[2] = dbg_state_dhalted & (hart_haltstatus[2-:3] == 3'b001);
	end
	assign hdu2dm_cmd_rcode_o = (dbg_state_reset ? (~pipe2hdu_rdc_qlfy_i | ~pipe2hdu_init_pc_i) | ~dm2hdu_cmd_req_i : ~pipe2hdu_rdc_qlfy_i | ~dfsm_update);
	always @(*) begin
		hdu2dm_cmd_resp_o = 1'b0;
		case (dbg_state)
			2'b00: hdu2dm_cmd_resp_o = (pipe2hdu_rdc_qlfy_i & pipe2hdu_init_pc_i) & dm2hdu_cmd_req_i;
			2'b01: hdu2dm_cmd_resp_o = (pipe2hdu_rdc_qlfy_i & dfsm_update) & dm2hdu_cmd_req_i;
			2'b10: hdu2dm_cmd_resp_o = (pipe2hdu_rdc_qlfy_i ? dfsm_update : dm2hdu_cmd_req_i);
			2'b11: hdu2dm_cmd_resp_o = (~pipe2hdu_rdc_qlfy_i | dfsm_update) & dm2hdu_cmd_req_i;
			default: hdu2dm_cmd_resp_o = 1'sbx;
		endcase
	end
	assign hdu2dm_pbuf_addr_o = pbuf_addr_ff;
	assign hdu2dm_dreg_req_o = csr_dscratch0_sel;
	assign hdu2dm_dreg_wr_o = csr_wr & csr_dscratch0_sel;
	assign hdu2dm_dreg_wdata_o = csr_wr_data;
	assign hdu2exu_dbg_halted_o = (dbg_state_next == 2'b10) | (~pipe2hdu_rdc_qlfy_i & ~dbg_state_run);
	assign hdu2exu_dbg_run_start_o = (dbg_state_dhalted & pipe2hdu_rdc_qlfy_i) & dfsm_update;
	assign hdu2exu_dbg_halt2run_o = (hdu2exu_dbg_halted_o & hart_resume_req) & clk_pipe_en;
	assign hdu2exu_dbg_run2halt_o = hart_halt_ack;
	assign hdu2exu_pbuf_fetch_o = hart_runctrl[4];
	assign hdu2exu_irq_dsbl_o = hart_runctrl[5];
	assign hdu2exu_pc_advmt_dsbl_o = hart_runctrl[3];
	assign hdu2exu_no_commit_o = dmode_cause_ebreak | dmode_cause_tmreq;
	assign hdu2exu_dmode_sstep_en_o = hart_runctrl[1];
	assign hdu2exu_dbg_new_pc_o = csr_dpc_ff;
	assign hdu2ifu_pbuf_instr_vd_o = (pbuf_fsm_fetch | pbuf_fsm_excinj) & ~pbuf_instr_wait_latching;
	assign hdu2ifu_pbuf_instr_err_o = pbuf_fsm_excinj;
	generate
		if (HART_PBUF_INSTR_REGOUT_EN) begin : genblk2
			always @(posedge clk) hdu2ifu_pbuf_instr_o <= dm2hdu_pbuf_instr_i;
		end
		else begin : genblk2
			wire [32:1] sv2v_tmp_E72A7;
			assign sv2v_tmp_E72A7 = dm2hdu_pbuf_instr_i;
			always @(*) hdu2ifu_pbuf_instr_o = sv2v_tmp_E72A7;
		end
	endgenerate
	assign csr_addr_dscratch0 = csr2hdu_addr_i == SCR1_HDU_DBGCSR_OFFS_DSCRATCH0;
	assign hdu2csr_resp_o = (~dbg_state_drun ? 1'd1 : (csr_addr_dscratch0 ? csr_dscratch0_resp : (csr2hdu_req_i ? 1'd0 : 1'd1)));
	assign hdu2csr_rdata_o = csr_rd_data;
	assign hdu2tdu_hwbrk_dsbl_o = hart_runctrl[2];
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_tdu (
	rst_n,
	clk,
	clk_en,
	tdu_dsbl_i,
	csr2tdu_req_i,
	csr2tdu_cmd_i,
	csr2tdu_addr_i,
	csr2tdu_wdata_i,
	tdu2csr_rdata_o,
	tdu2csr_resp_o,
	exu2tdu_imon_i,
	tdu2exu_ibrkpt_match_o,
	tdu2exu_ibrkpt_exc_req_o,
	exu2tdu_bp_retire_i,
	tdu2lsu_ibrkpt_exc_req_o,
	lsu2tdu_dmon_i,
	tdu2lsu_dbrkpt_match_o,
	tdu2lsu_dbrkpt_exc_req_o,
	tdu2hdu_dmode_req_o
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	input wire clk_en;
	input wire tdu_dsbl_i;
	input wire csr2tdu_req_i;
	localparam SCR1_CSR_CMD_ALL_NUM_E = 4;
	localparam SCR1_CSR_CMD_WIDTH_E = 2;
	input wire [1:0] csr2tdu_cmd_i;
	localparam SCR1_CSR_ADDR_TDU_OFFS_W = 3;
	input wire [2:0] csr2tdu_addr_i;
	localparam [31:0] SCR1_TDU_DATA_W = 32;
	input wire [31:0] csr2tdu_wdata_i;
	output reg [31:0] tdu2csr_rdata_o;
	output wire tdu2csr_resp_o;
	input wire [33:0] exu2tdu_imon_i;
	localparam [31:0] SCR1_TDU_TRIG_NUM = 2;
	localparam [31:0] SCR1_TDU_MTRIG_NUM = SCR1_TDU_TRIG_NUM;
	localparam [31:0] SCR1_TDU_ALLTRIG_NUM = SCR1_TDU_MTRIG_NUM + 1'b1;
	output wire [SCR1_TDU_ALLTRIG_NUM - 1:0] tdu2exu_ibrkpt_match_o;
	output wire tdu2exu_ibrkpt_exc_req_o;
	input wire [SCR1_TDU_ALLTRIG_NUM - 1:0] exu2tdu_bp_retire_i;
	output wire tdu2lsu_ibrkpt_exc_req_o;
	input wire [34:0] lsu2tdu_dmon_i;
	output wire [1:0] tdu2lsu_dbrkpt_match_o;
	output wire tdu2lsu_dbrkpt_exc_req_o;
	output reg tdu2hdu_dmode_req_o;
	localparam [31:0] MTRIG_NUM = SCR1_TDU_MTRIG_NUM;
	localparam [31:0] ALLTRIG_NUM = SCR1_TDU_ALLTRIG_NUM;
	localparam [31:0] ALLTRIG_W = $clog2(ALLTRIG_NUM + 1);
	reg csr_wr_req;
	reg [31:0] csr_wr_data;
	reg csr_addr_tselect;
	reg [1:0] csr_addr_mcontrol;
	reg [1:0] csr_addr_tdata2;
	reg csr_addr_icount;
	wire csr_tselect_upd;
	reg [ALLTRIG_W - 1:0] csr_tselect_ff;
	wire [1:0] csr_mcontrol_wr_req;
	wire [1:0] csr_mcontrol_clk_en;
	wire [1:0] csr_mcontrol_upd;
	reg [1:0] csr_mcontrol_dmode_ff;
	reg [1:0] csr_mcontrol_dmode_next;
	reg [1:0] csr_mcontrol_m_ff;
	reg [1:0] csr_mcontrol_m_next;
	reg [1:0] csr_mcontrol_exec_ff;
	reg [1:0] csr_mcontrol_exec_next;
	reg [1:0] csr_mcontrol_load_ff;
	reg [1:0] csr_mcontrol_load_next;
	reg [1:0] csr_mcontrol_store_ff;
	reg [1:0] csr_mcontrol_store_next;
	reg [1:0] csr_mcontrol_action_ff;
	reg [1:0] csr_mcontrol_action_next;
	reg [1:0] csr_mcontrol_hit_ff;
	reg [1:0] csr_mcontrol_hit_next;
	wire [1:0] csr_mcontrol_exec_hit;
	wire [1:0] csr_mcontrol_ldst_hit;
	wire csr_icount_wr_req;
	wire csr_icount_clk_en;
	wire csr_icount_upd;
	reg csr_icount_dmode_ff;
	reg csr_icount_dmode_next;
	reg csr_icount_m_ff;
	reg csr_icount_m_next;
	reg csr_icount_action_ff;
	reg csr_icount_action_next;
	reg csr_icount_hit_ff;
	reg csr_icount_hit_next;
	localparam [31:0] SCR1_TDU_ICOUNT_COUNT_HI = 23;
	localparam [31:0] SCR1_TDU_ICOUNT_COUNT_LO = 10;
	reg [SCR1_TDU_ICOUNT_COUNT_HI - SCR1_TDU_ICOUNT_COUNT_LO:0] csr_icount_count_ff;
	reg [SCR1_TDU_ICOUNT_COUNT_HI - SCR1_TDU_ICOUNT_COUNT_LO:0] csr_icount_count_next;
	reg csr_icount_skip_ff;
	wire csr_icount_skip_next;
	wire csr_icount_decr_en;
	wire csr_icount_count_decr;
	wire csr_icount_skip_dsbl;
	wire csr_icount_hit;
	wire [1:0] csr_tdata2_upd;
	reg [(MTRIG_NUM * SCR1_TDU_DATA_W) - 1:0] csr_tdata2_ff;
	assign tdu2csr_resp_o = (csr2tdu_req_i ? 1'd0 : 1'd1);
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TDATA1 = 3'sd1;
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TDATA2 = 3'sd2;
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TINFO = 3'sd4;
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TSELECT = 3'sd0;
	localparam [31:0] SCR1_TDU_ICOUNT_ACTION_HI = 5;
	localparam [31:0] SCR1_TDU_ICOUNT_ACTION_LO = 0;
	localparam [31:0] SCR1_TDU_ICOUNT_HIT = 24;
	localparam [31:0] SCR1_TDU_ICOUNT_M = 9;
	localparam [31:0] SCR1_TDU_ICOUNT_S = 7;
	localparam [31:0] SCR1_TDU_TDATA1_TYPE_HI = 31;
	localparam [31:0] SCR1_TDU_TDATA1_TYPE_LO = 28;
	localparam [SCR1_TDU_TDATA1_TYPE_HI - SCR1_TDU_TDATA1_TYPE_LO:0] SCR1_TDU_ICOUNT_TYPE_VAL = 2'd3;
	localparam [31:0] SCR1_TDU_ICOUNT_U = 6;
	localparam [31:0] SCR1_TDU_MCONTROL_ACTION_HI = 17;
	localparam [31:0] SCR1_TDU_MCONTROL_ACTION_LO = 12;
	localparam [31:0] SCR1_TDU_MCONTROL_CHAIN = 11;
	localparam [31:0] SCR1_TDU_MCONTROL_EXECUTE = 2;
	localparam [31:0] SCR1_TDU_MCONTROL_HIT = 20;
	localparam [31:0] SCR1_TDU_MCONTROL_LOAD = 0;
	localparam [31:0] SCR1_TDU_MCONTROL_M = 6;
	localparam [31:0] SCR1_TDU_MCONTROL_MASKMAX_HI = 26;
	localparam [31:0] SCR1_TDU_MCONTROL_MASKMAX_LO = 21;
	localparam [SCR1_TDU_MCONTROL_MASKMAX_HI - SCR1_TDU_MCONTROL_MASKMAX_LO:0] SCR1_TDU_MCONTROL_MASKMAX_VAL = 1'b0;
	localparam [31:0] SCR1_TDU_MCONTROL_MATCH_HI = 10;
	localparam [31:0] SCR1_TDU_MCONTROL_MATCH_LO = 7;
	localparam [31:0] SCR1_TDU_MCONTROL_RESERVEDA = 5;
	localparam [0:0] SCR1_TDU_MCONTROL_RESERVEDA_VAL = 1'b0;
	localparam [31:0] SCR1_TDU_MCONTROL_S = 4;
	localparam [31:0] SCR1_TDU_MCONTROL_SELECT = 19;
	localparam [0:0] SCR1_TDU_MCONTROL_SELECT_VAL = 1'b0;
	localparam [31:0] SCR1_TDU_MCONTROL_STORE = 1;
	localparam [31:0] SCR1_TDU_MCONTROL_TIMING = 18;
	localparam [0:0] SCR1_TDU_MCONTROL_TIMING_VAL = 1'b0;
	localparam [SCR1_TDU_TDATA1_TYPE_HI - SCR1_TDU_TDATA1_TYPE_LO:0] SCR1_TDU_MCONTROL_TYPE_VAL = 2'd2;
	localparam [31:0] SCR1_TDU_MCONTROL_U = 3;
	localparam [31:0] SCR1_TDU_TDATA1_DMODE = 27;
	function automatic [ALLTRIG_W - 1:0] sv2v_cast_646DD;
		input reg [ALLTRIG_W - 1:0] inp;
		sv2v_cast_646DD = inp;
	endfunction
	always @(*) begin
		tdu2csr_rdata_o = 1'sb0;
		if (csr2tdu_req_i)
			case (csr2tdu_addr_i)
				SCR1_CSR_ADDR_TDU_OFFS_TSELECT: tdu2csr_rdata_o = {1'sb0, csr_tselect_ff};
				SCR1_CSR_ADDR_TDU_OFFS_TDATA2: begin : sv2v_autoblock_1
					reg [31:0] i;
					for (i = 0; i < MTRIG_NUM; i = i + 1)
						if (csr_tselect_ff == sv2v_cast_646DD(i))
							tdu2csr_rdata_o = csr_tdata2_ff[i * SCR1_TDU_DATA_W+:SCR1_TDU_DATA_W];
				end
				SCR1_CSR_ADDR_TDU_OFFS_TDATA1: begin
					begin : sv2v_autoblock_2
						reg [31:0] i;
						for (i = 0; i < MTRIG_NUM; i = i + 1)
							if (csr_tselect_ff == sv2v_cast_646DD(i)) begin
								tdu2csr_rdata_o[SCR1_TDU_TDATA1_TYPE_HI:SCR1_TDU_TDATA1_TYPE_LO] = SCR1_TDU_MCONTROL_TYPE_VAL;
								tdu2csr_rdata_o[SCR1_TDU_TDATA1_DMODE] = csr_mcontrol_dmode_ff[i];
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_MASKMAX_HI:SCR1_TDU_MCONTROL_MASKMAX_LO] = SCR1_TDU_MCONTROL_MASKMAX_VAL;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_HIT] = csr_mcontrol_hit_ff[i];
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_SELECT] = SCR1_TDU_MCONTROL_SELECT_VAL;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_TIMING] = SCR1_TDU_MCONTROL_TIMING_VAL;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_ACTION_HI:SCR1_TDU_MCONTROL_ACTION_LO] = {5'b00000, csr_mcontrol_action_ff[i]};
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_CHAIN] = 1'b0;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_MATCH_HI:SCR1_TDU_MCONTROL_MATCH_LO] = 4'b0000;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_M] = csr_mcontrol_m_ff[i];
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_RESERVEDA] = SCR1_TDU_MCONTROL_RESERVEDA_VAL;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_S] = 1'b0;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_U] = 1'b0;
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_EXECUTE] = csr_mcontrol_exec_ff[i];
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_STORE] = csr_mcontrol_store_ff[i];
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_LOAD] = csr_mcontrol_load_ff[i];
							end
					end
					if (csr_tselect_ff == sv2v_cast_646DD(SCR1_TDU_ALLTRIG_NUM - 1'b1)) begin
						tdu2csr_rdata_o[SCR1_TDU_TDATA1_TYPE_HI:SCR1_TDU_TDATA1_TYPE_LO] = SCR1_TDU_ICOUNT_TYPE_VAL;
						tdu2csr_rdata_o[SCR1_TDU_TDATA1_DMODE] = csr_icount_dmode_ff;
						tdu2csr_rdata_o[SCR1_TDU_ICOUNT_HIT] = csr_icount_hit_ff;
						tdu2csr_rdata_o[SCR1_TDU_ICOUNT_COUNT_HI:SCR1_TDU_ICOUNT_COUNT_LO] = csr_icount_count_ff;
						tdu2csr_rdata_o[SCR1_TDU_ICOUNT_U] = 1'b0;
						tdu2csr_rdata_o[SCR1_TDU_ICOUNT_S] = 1'b0;
						tdu2csr_rdata_o[SCR1_TDU_ICOUNT_M] = csr_icount_m_ff;
						tdu2csr_rdata_o[SCR1_TDU_ICOUNT_ACTION_HI:SCR1_TDU_ICOUNT_ACTION_LO] = {5'b00000, csr_icount_action_ff};
					end
				end
				SCR1_CSR_ADDR_TDU_OFFS_TINFO: begin
					begin : sv2v_autoblock_3
						reg [31:0] i;
						for (i = 0; i < MTRIG_NUM; i = i + 1)
							if (csr_tselect_ff == sv2v_cast_646DD(i))
								tdu2csr_rdata_o[SCR1_TDU_MCONTROL_TYPE_VAL] = 1'b1;
					end
					if (csr_tselect_ff == sv2v_cast_646DD(SCR1_TDU_ALLTRIG_NUM - 1'b1))
						tdu2csr_rdata_o[SCR1_TDU_ICOUNT_TYPE_VAL] = 1'b1;
				end
				default:
					;
			endcase
	end
	function automatic [1:0] sv2v_cast_999B9;
		input reg [1:0] inp;
		sv2v_cast_999B9 = inp;
	endfunction
	always @(*) begin
		csr_wr_req = 1'b0;
		csr_wr_data = 1'sb0;
		case (csr2tdu_cmd_i)
			sv2v_cast_999B9({32 {1'sb0}} + 1): begin
				csr_wr_req = 1'b1;
				csr_wr_data = csr2tdu_wdata_i;
			end
			sv2v_cast_999B9({32 {1'sb0}} + 2): begin
				csr_wr_req = |csr2tdu_wdata_i;
				csr_wr_data = tdu2csr_rdata_o | csr2tdu_wdata_i;
			end
			sv2v_cast_999B9({32 {1'sb0}} + 3): begin
				csr_wr_req = |csr2tdu_wdata_i;
				csr_wr_data = tdu2csr_rdata_o & ~csr2tdu_wdata_i;
			end
			default:
				;
		endcase
	end
	always @(*) begin
		csr_addr_tselect = 1'b0;
		csr_addr_tdata2 = 1'sb0;
		csr_addr_mcontrol = 1'sb0;
		csr_addr_icount = 1'sb0;
		if (csr2tdu_req_i)
			case (csr2tdu_addr_i)
				SCR1_CSR_ADDR_TDU_OFFS_TSELECT: csr_addr_tselect = 1'b1;
				SCR1_CSR_ADDR_TDU_OFFS_TDATA1: begin
					begin : sv2v_autoblock_4
						reg [31:0] i;
						for (i = 0; i < MTRIG_NUM; i = i + 1)
							if (csr_tselect_ff == sv2v_cast_646DD(i))
								csr_addr_mcontrol[i] = 1'b1;
					end
					if (csr_tselect_ff == sv2v_cast_646DD(SCR1_TDU_ALLTRIG_NUM - 1'b1))
						csr_addr_icount = 1'b1;
				end
				SCR1_CSR_ADDR_TDU_OFFS_TDATA2: begin : sv2v_autoblock_5
					reg [31:0] i;
					for (i = 0; i < MTRIG_NUM; i = i + 1)
						if (csr_tselect_ff == sv2v_cast_646DD(i))
							csr_addr_tdata2[i] = 1'b1;
				end
				default:
					;
			endcase
	end
	assign csr_tselect_upd = ((clk_en & csr_addr_tselect) & csr_wr_req) & (csr_wr_data[ALLTRIG_W - 1:0] < sv2v_cast_646DD(ALLTRIG_NUM));
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			csr_tselect_ff <= 1'sb0;
		else if (csr_tselect_upd)
			csr_tselect_ff <= csr_wr_data[ALLTRIG_W - 1:0];
	assign csr_icount_wr_req = csr_addr_icount & csr_wr_req;
	assign csr_icount_clk_en = clk_en & (csr_icount_wr_req | csr_icount_m_ff);
	assign csr_icount_upd = (~csr_icount_dmode_ff ? csr_icount_wr_req : tdu_dsbl_i & csr_icount_wr_req);
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			csr_icount_dmode_ff <= 1'b0;
			csr_icount_m_ff <= 1'b0;
			csr_icount_action_ff <= 1'b0;
			csr_icount_hit_ff <= 1'b0;
			csr_icount_count_ff <= 1'sb0;
			csr_icount_skip_ff <= 1'b0;
		end
		else if (csr_icount_clk_en) begin
			csr_icount_dmode_ff <= csr_icount_dmode_next;
			csr_icount_m_ff <= csr_icount_m_next;
			csr_icount_action_ff <= csr_icount_action_next;
			csr_icount_hit_ff <= csr_icount_hit_next;
			csr_icount_count_ff <= csr_icount_count_next;
			csr_icount_skip_ff <= csr_icount_skip_next;
		end
	assign csr_icount_decr_en = (~tdu_dsbl_i & csr_icount_m_ff ? exu2tdu_imon_i[33] & (csr_icount_count_ff != 14'b00000000000000) : 1'b0);
	assign csr_icount_count_decr = (exu2tdu_imon_i[32] & csr_icount_decr_en) & ~csr_icount_skip_ff;
	assign csr_icount_skip_dsbl = (exu2tdu_imon_i[32] & csr_icount_decr_en) & csr_icount_skip_ff;
	always @(*) begin
		if (csr_icount_upd) begin
			csr_icount_dmode_next = csr_wr_data[SCR1_TDU_TDATA1_DMODE];
			csr_icount_m_next = csr_wr_data[SCR1_TDU_ICOUNT_M];
			csr_icount_action_next = csr_wr_data[SCR1_TDU_ICOUNT_ACTION_HI:SCR1_TDU_ICOUNT_ACTION_LO] == 'b1;
			csr_icount_hit_next = csr_wr_data[SCR1_TDU_ICOUNT_HIT];
			csr_icount_count_next = csr_wr_data[SCR1_TDU_ICOUNT_COUNT_HI:SCR1_TDU_ICOUNT_COUNT_LO];
		end
		else begin
			csr_icount_dmode_next = csr_icount_dmode_ff;
			csr_icount_m_next = csr_icount_m_ff;
			csr_icount_action_next = csr_icount_action_ff;
			csr_icount_hit_next = (exu2tdu_bp_retire_i[ALLTRIG_NUM - 1'b1] ? 1'b1 : csr_icount_hit_ff);
			csr_icount_count_next = (csr_icount_count_decr ? csr_icount_count_ff - 1'b1 : csr_icount_count_ff);
		end
	end
	assign csr_icount_skip_next = (csr_icount_wr_req ? csr_wr_data[SCR1_TDU_ICOUNT_M] : (csr_icount_skip_dsbl ? 1'b0 : csr_icount_skip_ff));
	genvar _gv_trig_1;
	generate
		for (_gv_trig_1 = 0; $unsigned(_gv_trig_1) < MTRIG_NUM; _gv_trig_1 = _gv_trig_1 + 1) begin : gblock_mtrig
			localparam trig = _gv_trig_1;
			assign csr_mcontrol_wr_req[trig] = csr_addr_mcontrol[trig] & csr_wr_req;
			assign csr_mcontrol_clk_en[trig] = clk_en & (csr_mcontrol_wr_req[trig] | csr_mcontrol_m_ff[trig]);
			assign csr_mcontrol_upd[trig] = (~csr_mcontrol_dmode_ff[trig] ? csr_mcontrol_wr_req[trig] : tdu_dsbl_i & csr_mcontrol_wr_req[trig]);
			always @(negedge rst_n or posedge clk)
				if (~rst_n) begin
					csr_mcontrol_dmode_ff[trig] <= 1'b0;
					csr_mcontrol_m_ff[trig] <= 1'b0;
					csr_mcontrol_exec_ff[trig] <= 1'b0;
					csr_mcontrol_load_ff[trig] <= 1'b0;
					csr_mcontrol_store_ff[trig] <= 1'b0;
					csr_mcontrol_action_ff[trig] <= 1'b0;
					csr_mcontrol_hit_ff[trig] <= 1'b0;
				end
				else if (csr_mcontrol_clk_en[trig]) begin
					csr_mcontrol_dmode_ff[trig] <= csr_mcontrol_dmode_next[trig];
					csr_mcontrol_m_ff[trig] <= csr_mcontrol_m_next[trig];
					csr_mcontrol_exec_ff[trig] <= csr_mcontrol_exec_next[trig];
					csr_mcontrol_load_ff[trig] <= csr_mcontrol_load_next[trig];
					csr_mcontrol_store_ff[trig] <= csr_mcontrol_store_next[trig];
					csr_mcontrol_action_ff[trig] <= csr_mcontrol_action_next[trig];
					csr_mcontrol_hit_ff[trig] <= csr_mcontrol_hit_next[trig];
				end
			always @(*) begin
				if (csr_mcontrol_upd[trig]) begin
					csr_mcontrol_dmode_next[trig] = csr_wr_data[SCR1_TDU_TDATA1_DMODE];
					csr_mcontrol_m_next[trig] = csr_wr_data[SCR1_TDU_MCONTROL_M];
					csr_mcontrol_exec_next[trig] = csr_wr_data[SCR1_TDU_MCONTROL_EXECUTE];
					csr_mcontrol_load_next[trig] = csr_wr_data[SCR1_TDU_MCONTROL_LOAD];
					csr_mcontrol_store_next[trig] = csr_wr_data[SCR1_TDU_MCONTROL_STORE];
					csr_mcontrol_action_next[trig] = csr_wr_data[SCR1_TDU_MCONTROL_ACTION_HI:SCR1_TDU_MCONTROL_ACTION_LO] == 'b1;
					csr_mcontrol_hit_next[trig] = csr_wr_data[SCR1_TDU_MCONTROL_HIT];
				end
				else begin
					csr_mcontrol_dmode_next[trig] = csr_mcontrol_dmode_ff[trig];
					csr_mcontrol_m_next[trig] = csr_mcontrol_m_ff[trig];
					csr_mcontrol_exec_next[trig] = csr_mcontrol_exec_ff[trig];
					csr_mcontrol_load_next[trig] = csr_mcontrol_load_ff[trig];
					csr_mcontrol_store_next[trig] = csr_mcontrol_store_ff[trig];
					csr_mcontrol_action_next[trig] = csr_mcontrol_action_ff[trig];
					csr_mcontrol_hit_next[trig] = (exu2tdu_bp_retire_i[trig] ? 1'b1 : csr_mcontrol_hit_ff[trig]);
				end
			end
			assign csr_tdata2_upd[trig] = (~csr_mcontrol_dmode_ff[trig] ? (clk_en & csr_addr_tdata2[trig]) & csr_wr_req : ((clk_en & csr_addr_tdata2[trig]) & csr_wr_req) & tdu_dsbl_i);
			always @(posedge clk)
				if (csr_tdata2_upd[trig])
					csr_tdata2_ff[trig * SCR1_TDU_DATA_W+:SCR1_TDU_DATA_W] <= csr_wr_data;
		end
	endgenerate
	assign csr_icount_hit = (~tdu_dsbl_i & csr_icount_m_ff ? (exu2tdu_imon_i[33] & (csr_icount_count_ff == 14'b00000000000001)) & ~csr_icount_skip_ff : 1'b0);
	assign tdu2exu_ibrkpt_match_o = {csr_icount_hit, csr_mcontrol_exec_hit};
	assign tdu2exu_ibrkpt_exc_req_o = |csr_mcontrol_exec_hit | csr_icount_hit;
	generate
		for (_gv_trig_1 = 0; $unsigned(_gv_trig_1) < MTRIG_NUM; _gv_trig_1 = _gv_trig_1 + 1) begin : gblock_break_trig
			localparam trig = _gv_trig_1;
			assign csr_mcontrol_exec_hit[trig] = (((~tdu_dsbl_i & csr_mcontrol_m_ff[trig]) & csr_mcontrol_exec_ff[trig]) & exu2tdu_imon_i[33]) & (exu2tdu_imon_i[31-:32] == csr_tdata2_ff[trig * SCR1_TDU_DATA_W+:SCR1_TDU_DATA_W]);
		end
	endgenerate
	assign tdu2lsu_ibrkpt_exc_req_o = |csr_mcontrol_exec_hit | csr_icount_hit;
	generate
		for (_gv_trig_1 = 0; $unsigned(_gv_trig_1) < MTRIG_NUM; _gv_trig_1 = _gv_trig_1 + 1) begin : gblock_watch_trig
			localparam trig = _gv_trig_1;
			assign csr_mcontrol_ldst_hit[trig] = (((~tdu_dsbl_i & csr_mcontrol_m_ff[trig]) & lsu2tdu_dmon_i[34]) & ((csr_mcontrol_load_ff[trig] & lsu2tdu_dmon_i[33]) | (csr_mcontrol_store_ff[trig] & lsu2tdu_dmon_i[32]))) & (lsu2tdu_dmon_i[31-:32] == csr_tdata2_ff[trig * SCR1_TDU_DATA_W+:SCR1_TDU_DATA_W]);
		end
	endgenerate
	assign tdu2lsu_dbrkpt_match_o = csr_mcontrol_ldst_hit;
	assign tdu2lsu_dbrkpt_exc_req_o = |csr_mcontrol_ldst_hit;
	always @(*) begin
		tdu2hdu_dmode_req_o = 1'b0;
		begin : sv2v_autoblock_6
			reg [31:0] i;
			for (i = 0; i < MTRIG_NUM; i = i + 1)
				tdu2hdu_dmode_req_o = tdu2hdu_dmode_req_o | (csr_mcontrol_action_ff[i] & exu2tdu_bp_retire_i[i]);
		end
		tdu2hdu_dmode_req_o = tdu2hdu_dmode_req_o | (csr_icount_action_ff & exu2tdu_bp_retire_i[ALLTRIG_NUM - 1]);
	end
	initial _sv2v_0 = 0;
endmodule
module scr1_ipic (
	rst_n,
	clk,
	soc2ipic_irq_lines_i,
	csr2ipic_r_req_i,
	csr2ipic_w_req_i,
	csr2ipic_addr_i,
	csr2ipic_wdata_i,
	ipic2csr_rdata_o,
	ipic2csr_irq_m_req_o
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	localparam SCR1_IRQ_VECT_NUM = 16;
	localparam SCR1_IRQ_LINES_NUM = SCR1_IRQ_VECT_NUM;
	input wire [15:0] soc2ipic_irq_lines_i;
	input wire csr2ipic_r_req_i;
	input wire csr2ipic_w_req_i;
	input wire [2:0] csr2ipic_addr_i;
	input wire [31:0] csr2ipic_wdata_i;
	output reg [31:0] ipic2csr_rdata_o;
	output wire ipic2csr_irq_m_req_o;
	localparam SCR1_IRQ_IDX_WIDTH = 4;
	localparam SCR1_IRQ_LINES_WIDTH = 4;
	function automatic [1:0] scr1_search_one_2;
		input reg [1:0] din;
		reg [1:0] tmp;
		begin
			tmp[1] = |din;
			tmp[0] = ~din[0];
			scr1_search_one_2 = tmp;
		end
	endfunction
	function automatic [4:0] scr1_search_one_16;
		input reg [15:0] din;
		reg [7:0] stage1_vd;
		reg [3:0] stage2_vd;
		reg [1:0] stage3_vd;
		reg stage1_idx [7:0];
		reg [1:0] stage2_idx [3:0];
		reg [2:0] stage3_idx [1:0];
		reg [4:0] result;
		begin
			begin : sv2v_autoblock_1
				reg [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin : sv2v_autoblock_2
						reg [1:0] tmp;
						tmp = scr1_search_one_2(din[((i + 1) * 2) - 1-:2]);
						stage1_vd[i] = tmp[1];
						stage1_idx[i] = tmp[0];
					end
			end
			begin : sv2v_autoblock_3
				reg [31:0] i;
				for (i = 0; i < 4; i = i + 1)
					begin : sv2v_autoblock_4
						reg [1:0] tmp;
						tmp = scr1_search_one_2(stage1_vd[((i + 1) * 2) - 1-:2]);
						stage2_vd[i] = tmp[1];
						stage2_idx[i] = (~tmp[0] ? {tmp[0], stage1_idx[2 * i]} : {tmp[0], stage1_idx[(2 * i) + 1]});
					end
			end
			begin : sv2v_autoblock_5
				reg [31:0] i;
				for (i = 0; i < 2; i = i + 1)
					begin : sv2v_autoblock_6
						reg [1:0] tmp;
						tmp = scr1_search_one_2(stage2_vd[((i + 1) * 2) - 1-:2]);
						stage3_vd[i] = tmp[1];
						stage3_idx[i] = (~tmp[0] ? {tmp[0], stage2_idx[2 * i]} : {tmp[0], stage2_idx[(2 * i) + 1]});
					end
			end
			result[4] = |stage3_vd;
			result[3-:SCR1_IRQ_IDX_WIDTH] = (stage3_vd[0] ? {1'b0, stage3_idx[0]} : {1'b1, stage3_idx[1]});
			scr1_search_one_16 = result;
		end
	endfunction
	reg [15:0] irq_lines;
	reg [15:0] irq_lines_sync;
	reg [15:0] irq_lines_dly;
	wire [15:0] irq_edge_detected;
	wire [15:0] irq_lvl;
	wire ipic_cisv_upd;
	localparam SCR1_IRQ_VECT_WIDTH = 5;
	reg [4:0] ipic_cisv_ff;
	wire [4:0] ipic_cisv_next;
	reg cicsr_wr_req;
	wire [1:0] ipic_cicsr;
	reg eoi_wr_req;
	wire ipic_eoi_req;
	reg soi_wr_req;
	wire ipic_soi_req;
	reg idxr_wr_req;
	reg [3:0] ipic_idxr_ff;
	wire ipic_ipr_upd;
	reg [15:0] ipic_ipr_ff;
	reg [15:0] ipic_ipr_next;
	wire [15:0] ipic_ipr_clr_cond;
	reg [15:0] ipic_ipr_clr_req;
	wire [15:0] ipic_ipr_clr;
	wire ipic_isvr_upd;
	reg [15:0] ipic_isvr_ff;
	reg [15:0] ipic_isvr_next;
	wire ipic_ier_upd;
	reg [15:0] ipic_ier_ff;
	reg [15:0] ipic_ier_next;
	reg [15:0] ipic_imr_ff;
	reg [15:0] ipic_imr_next;
	reg [15:0] ipic_iinvr_ff;
	reg [15:0] ipic_iinvr_next;
	reg icsr_wr_req;
	wire [8:0] ipic_icsr;
	wire irq_serv_vd;
	wire [3:0] irq_serv_idx;
	wire irq_req_vd;
	wire [3:0] irq_req_idx;
	wire irq_eoi_req_vd;
	wire [3:0] irq_eoi_req_idx;
	wire [15:0] irq_req_v;
	wire irq_start_vd;
	wire irq_hi_prior_pnd;
	wire [4:0] irr_priority;
	wire [4:0] isvr_priority_eoi;
	reg [15:0] ipic_isvr_eoi;
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			irq_lines_sync <= 1'sb0;
			irq_lines <= 1'sb0;
		end
		else begin
			irq_lines_sync <= soc2ipic_irq_lines_i;
			irq_lines <= irq_lines_sync;
		end
	assign irq_lvl = irq_lines ^ ipic_iinvr_next;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			irq_lines_dly <= 1'sb0;
		else
			irq_lines_dly <= irq_lines;
	assign irq_edge_detected = (irq_lines_dly ^ irq_lines) & irq_lvl;
	localparam [2:0] SCR1_IPIC_CICSR = 3'h1;
	localparam [2:0] SCR1_IPIC_CISV = 3'h0;
	localparam [2:0] SCR1_IPIC_EOI = 3'h4;
	localparam [2:0] SCR1_IPIC_ICSR = 3'h7;
	localparam SCR1_IPIC_ICSR_IE = 1;
	localparam SCR1_IPIC_ICSR_IM = 2;
	localparam SCR1_IPIC_ICSR_INV = 3;
	localparam SCR1_IPIC_ICSR_IP = 0;
	localparam SCR1_IPIC_ICSR_IS = 4;
	localparam SCR1_IPIC_ICSR_LN_LSB = 12;
	localparam SCR1_IPIC_ICSR_LN_MSB = 16;
	localparam SCR1_IPIC_ICSR_PRV_LSB = 8;
	localparam SCR1_IPIC_ICSR_PRV_MSB = 9;
	localparam [2:0] SCR1_IPIC_IDX = 3'h6;
	localparam [2:0] SCR1_IPIC_IPR = 3'h2;
	localparam [2:0] SCR1_IPIC_ISVR = 3'h3;
	localparam [1:0] SCR1_IPIC_PRV_M = 2'b11;
	localparam [2:0] SCR1_IPIC_SOI = 3'h5;
	function automatic signed [4:0] sv2v_cast_5_signed;
		input reg signed [4:0] inp;
		sv2v_cast_5_signed = inp;
	endfunction
	localparam [4:0] SCR1_IRQ_VOID_VECT_NUM = sv2v_cast_5_signed(SCR1_IRQ_VECT_NUM);
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin
		ipic2csr_rdata_o = 1'sb0;
		if (csr2ipic_r_req_i)
			case (csr2ipic_addr_i)
				SCR1_IPIC_CISV: ipic2csr_rdata_o[4:0] = (irq_serv_vd ? ipic_cisv_ff : SCR1_IRQ_VOID_VECT_NUM);
				SCR1_IPIC_CICSR: begin
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_IP] = ipic_cicsr[1];
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_IE] = ipic_cicsr[0];
				end
				SCR1_IPIC_IPR: ipic2csr_rdata_o = sv2v_cast_32(ipic_ipr_ff);
				SCR1_IPIC_ISVR: ipic2csr_rdata_o = sv2v_cast_32(ipic_isvr_ff);
				SCR1_IPIC_EOI, SCR1_IPIC_SOI: ipic2csr_rdata_o = 1'sb0;
				SCR1_IPIC_IDX: ipic2csr_rdata_o = sv2v_cast_32(ipic_idxr_ff);
				SCR1_IPIC_ICSR: begin
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_IP] = ipic_icsr[8];
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_IE] = ipic_icsr[7];
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_IM] = ipic_icsr[6];
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_INV] = ipic_icsr[5];
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_PRV_MSB:SCR1_IPIC_ICSR_PRV_LSB] = SCR1_IPIC_PRV_M;
					ipic2csr_rdata_o[SCR1_IPIC_ICSR_IS] = ipic_icsr[4];
					ipic2csr_rdata_o[15:SCR1_IPIC_ICSR_LN_LSB] = ipic_icsr[3-:SCR1_IRQ_LINES_WIDTH];
				end
				default: ipic2csr_rdata_o = 1'sbx;
			endcase
	end
	always @(*) begin
		cicsr_wr_req = 1'b0;
		eoi_wr_req = 1'b0;
		soi_wr_req = 1'b0;
		idxr_wr_req = 1'b0;
		icsr_wr_req = 1'b0;
		if (csr2ipic_w_req_i)
			case (csr2ipic_addr_i)
				SCR1_IPIC_CISV:
					;
				SCR1_IPIC_CICSR: cicsr_wr_req = 1'b1;
				SCR1_IPIC_IPR:
					;
				SCR1_IPIC_ISVR:
					;
				SCR1_IPIC_EOI: eoi_wr_req = 1'b1;
				SCR1_IPIC_SOI: soi_wr_req = 1'b1;
				SCR1_IPIC_IDX: idxr_wr_req = 1'b1;
				SCR1_IPIC_ICSR: icsr_wr_req = 1'b1;
				default: begin
					cicsr_wr_req = 1'sbx;
					eoi_wr_req = 1'sbx;
					soi_wr_req = 1'sbx;
					idxr_wr_req = 1'sbx;
					icsr_wr_req = 1'sbx;
				end
			endcase
	end
	assign ipic_cisv_upd = irq_start_vd | ipic_eoi_req;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			ipic_cisv_ff <= SCR1_IRQ_VOID_VECT_NUM;
		else if (ipic_cisv_upd)
			ipic_cisv_ff <= ipic_cisv_next;
	assign ipic_cisv_next = (irq_start_vd ? {1'b0, irq_req_idx} : (ipic_eoi_req ? (irq_eoi_req_vd ? {1'b0, irq_eoi_req_idx} : SCR1_IRQ_VOID_VECT_NUM) : 1'b0));
	assign irq_serv_idx = ipic_cisv_ff[3:0];
	assign irq_serv_vd = ~ipic_cisv_ff[4];
	assign ipic_cicsr[1] = ipic_ipr_ff[irq_serv_idx] & irq_serv_vd;
	assign ipic_cicsr[0] = ipic_ier_ff[irq_serv_idx] & irq_serv_vd;
	assign ipic_eoi_req = eoi_wr_req & irq_serv_vd;
	assign ipic_soi_req = soi_wr_req & irq_req_vd;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			ipic_idxr_ff <= 1'sb0;
		else if (idxr_wr_req)
			ipic_idxr_ff <= csr2ipic_wdata_i[3:0];
	assign ipic_ipr_upd = ipic_ipr_next != ipic_ipr_ff;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			ipic_ipr_ff <= 1'sb0;
		else if (ipic_ipr_upd)
			ipic_ipr_ff <= ipic_ipr_next;
	always @(*) begin
		ipic_ipr_clr_req = 1'sb0;
		if (csr2ipic_w_req_i)
			case (csr2ipic_addr_i)
				SCR1_IPIC_CICSR: ipic_ipr_clr_req[irq_serv_idx] = csr2ipic_wdata_i[SCR1_IPIC_ICSR_IP] & irq_serv_vd;
				SCR1_IPIC_IPR: ipic_ipr_clr_req = csr2ipic_wdata_i[15:0];
				SCR1_IPIC_SOI: ipic_ipr_clr_req[irq_req_idx] = irq_req_vd;
				SCR1_IPIC_ICSR: ipic_ipr_clr_req[ipic_idxr_ff] = csr2ipic_wdata_i[SCR1_IPIC_ICSR_IP];
				default:
					;
			endcase
	end
	assign ipic_ipr_clr_cond = ~irq_lvl | ipic_imr_next;
	assign ipic_ipr_clr = ipic_ipr_clr_req & ipic_ipr_clr_cond;
	always @(*) begin
		ipic_ipr_next = 1'sb0;
		begin : sv2v_autoblock_7
			reg [31:0] i;
			for (i = 0; i < SCR1_IRQ_VECT_NUM; i = i + 1)
				ipic_ipr_next[i] = (ipic_ipr_clr[i] ? 1'b0 : (~ipic_imr_ff[i] ? irq_lvl[i] : ipic_ipr_ff[i] | irq_edge_detected[i]));
		end
	end
	assign ipic_isvr_upd = irq_start_vd | ipic_eoi_req;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			ipic_isvr_ff <= 1'sb0;
		else if (ipic_isvr_upd)
			ipic_isvr_ff <= ipic_isvr_next;
	always @(*) begin
		ipic_isvr_eoi = ipic_isvr_ff;
		if (irq_serv_vd)
			ipic_isvr_eoi[irq_serv_idx] = 1'b0;
	end
	always @(*) begin
		ipic_isvr_next = ipic_isvr_ff;
		if (irq_start_vd)
			ipic_isvr_next[irq_req_idx] = 1'b1;
		else if (ipic_eoi_req)
			ipic_isvr_next = ipic_isvr_eoi;
	end
	assign ipic_ier_upd = cicsr_wr_req | icsr_wr_req;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			ipic_ier_ff <= 1'sb0;
		else if (ipic_ier_upd)
			ipic_ier_ff <= ipic_ier_next;
	always @(*) begin
		ipic_ier_next = ipic_ier_ff;
		if (cicsr_wr_req)
			ipic_ier_next[irq_serv_idx] = (irq_serv_vd ? csr2ipic_wdata_i[SCR1_IPIC_ICSR_IE] : ipic_ier_ff[irq_serv_idx]);
		else if (icsr_wr_req)
			ipic_ier_next[ipic_idxr_ff] = csr2ipic_wdata_i[SCR1_IPIC_ICSR_IE];
	end
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			ipic_imr_ff <= 1'sb0;
		else if (icsr_wr_req)
			ipic_imr_ff <= ipic_imr_next;
	always @(*) begin
		ipic_imr_next = ipic_imr_ff;
		if (icsr_wr_req)
			ipic_imr_next[ipic_idxr_ff] = csr2ipic_wdata_i[SCR1_IPIC_ICSR_IM];
	end
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			ipic_iinvr_ff <= 1'sb0;
		else if (icsr_wr_req)
			ipic_iinvr_ff <= ipic_iinvr_next;
	always @(*) begin
		ipic_iinvr_next = ipic_iinvr_ff;
		if (icsr_wr_req)
			ipic_iinvr_next[ipic_idxr_ff] = csr2ipic_wdata_i[SCR1_IPIC_ICSR_INV];
	end
	assign ipic_icsr[8] = ipic_ipr_ff[ipic_idxr_ff];
	assign ipic_icsr[7] = ipic_ier_ff[ipic_idxr_ff];
	assign ipic_icsr[6] = ipic_imr_ff[ipic_idxr_ff];
	assign ipic_icsr[5] = ipic_iinvr_ff[ipic_idxr_ff];
	assign ipic_icsr[4] = ipic_isvr_ff[ipic_idxr_ff];
	assign ipic_icsr[3-:SCR1_IRQ_LINES_WIDTH] = ipic_idxr_ff;
	assign irq_req_v = ipic_ipr_ff & ipic_ier_ff;
	assign irr_priority = scr1_search_one_16(irq_req_v);
	assign irq_req_vd = irr_priority[4];
	assign irq_req_idx = irr_priority[3-:SCR1_IRQ_IDX_WIDTH];
	assign isvr_priority_eoi = scr1_search_one_16(ipic_isvr_eoi);
	assign irq_eoi_req_vd = isvr_priority_eoi[4];
	assign irq_eoi_req_idx = isvr_priority_eoi[3-:SCR1_IRQ_IDX_WIDTH];
	assign irq_hi_prior_pnd = irq_req_idx < irq_serv_idx;
	assign ipic2csr_irq_m_req_o = irq_req_vd & (~irq_serv_vd | irq_hi_prior_pnd);
	assign irq_start_vd = ipic2csr_irq_m_req_o & ipic_soi_req;
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_csr (
	rst_n,
	clk,
	clk_alw_on,
	soc2csr_irq_ext_i,
	soc2csr_irq_soft_i,
	soc2csr_irq_mtimer_i,
	soc2csr_mtimer_val_i,
	soc2csr_fuse_mhartid_i,
	exu2csr_r_req_i,
	exu2csr_rw_addr_i,
	csr2exu_r_data_o,
	exu2csr_w_req_i,
	exu2csr_w_cmd_i,
	exu2csr_w_data_i,
	csr2exu_rw_exc_o,
	exu2csr_take_irq_i,
	exu2csr_take_exc_i,
	exu2csr_mret_update_i,
	exu2csr_mret_instr_i,
	exu2csr_exc_code_i,
	exu2csr_trap_val_i,
	csr2exu_irq_o,
	csr2exu_ip_ie_o,
	csr2exu_mstatus_mie_up_o,
	csr2ipic_r_req_o,
	csr2ipic_w_req_o,
	csr2ipic_addr_o,
	csr2ipic_wdata_o,
	ipic2csr_rdata_i,
	csr2hdu_req_o,
	csr2hdu_cmd_o,
	csr2hdu_addr_o,
	csr2hdu_wdata_o,
	hdu2csr_rdata_i,
	hdu2csr_resp_i,
	hdu2csr_no_commit_i,
	csr2tdu_req_o,
	csr2tdu_cmd_o,
	csr2tdu_addr_o,
	csr2tdu_wdata_o,
	tdu2csr_rdata_i,
	tdu2csr_resp_i,
	exu2csr_instret_no_exc_i,
	exu2csr_pc_curr_i,
	exu2csr_pc_next_i,
	csr2exu_new_pc_o
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	input wire clk_alw_on;
	input wire soc2csr_irq_ext_i;
	input wire soc2csr_irq_soft_i;
	input wire soc2csr_irq_mtimer_i;
	input wire [63:0] soc2csr_mtimer_val_i;
	input wire [31:0] soc2csr_fuse_mhartid_i;
	input wire exu2csr_r_req_i;
	localparam [31:0] SCR1_CSR_ADDR_WIDTH = 12;
	input wire [11:0] exu2csr_rw_addr_i;
	output wire [31:0] csr2exu_r_data_o;
	input wire exu2csr_w_req_i;
	localparam SCR1_CSR_CMD_ALL_NUM_E = 4;
	localparam SCR1_CSR_CMD_WIDTH_E = 2;
	input wire [1:0] exu2csr_w_cmd_i;
	input wire [31:0] exu2csr_w_data_i;
	output wire csr2exu_rw_exc_o;
	input wire exu2csr_take_irq_i;
	input wire exu2csr_take_exc_i;
	input wire exu2csr_mret_update_i;
	input wire exu2csr_mret_instr_i;
	localparam [31:0] SCR1_EXC_CODE_WIDTH_E = 4;
	input wire [3:0] exu2csr_exc_code_i;
	input wire [31:0] exu2csr_trap_val_i;
	output wire csr2exu_irq_o;
	output wire csr2exu_ip_ie_o;
	output wire csr2exu_mstatus_mie_up_o;
	output reg csr2ipic_r_req_o;
	output reg csr2ipic_w_req_o;
	output wire [2:0] csr2ipic_addr_o;
	output wire [31:0] csr2ipic_wdata_o;
	input wire [31:0] ipic2csr_rdata_i;
	output wire csr2hdu_req_o;
	output wire [1:0] csr2hdu_cmd_o;
	function automatic [11:0] sv2v_cast_C1AAB;
		input reg [11:0] inp;
		sv2v_cast_C1AAB = inp;
	endfunction
	localparam [11:0] SCR1_CSR_ADDR_HDU_MSPAN = sv2v_cast_C1AAB('h4);
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_SPAN = SCR1_CSR_ADDR_HDU_MSPAN;
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_WIDTH = $clog2(SCR1_HDU_DEBUGCSR_ADDR_SPAN);
	output wire [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] csr2hdu_addr_o;
	output wire [31:0] csr2hdu_wdata_o;
	input wire [31:0] hdu2csr_rdata_i;
	input wire hdu2csr_resp_i;
	input wire hdu2csr_no_commit_i;
	output wire csr2tdu_req_o;
	output wire [1:0] csr2tdu_cmd_o;
	localparam SCR1_CSR_ADDR_TDU_OFFS_W = 3;
	output wire [2:0] csr2tdu_addr_o;
	output wire [31:0] csr2tdu_wdata_o;
	input wire [31:0] tdu2csr_rdata_i;
	input wire tdu2csr_resp_i;
	input wire exu2csr_instret_no_exc_i;
	input wire [31:0] exu2csr_pc_curr_i;
	input wire [31:0] exu2csr_pc_next_i;
	output reg [31:0] csr2exu_new_pc_o;
	localparam PC_LSB = 1;
	reg csr_mstatus_upd;
	reg [31:0] csr_mstatus;
	reg csr_mstatus_mie_ff;
	reg csr_mstatus_mie_next;
	reg csr_mstatus_mpie_ff;
	reg csr_mstatus_mpie_next;
	reg csr_mie_upd;
	reg [31:0] csr_mie;
	reg csr_mie_mtie_ff;
	reg csr_mie_meie_ff;
	reg csr_mie_msie_ff;
	reg csr_mtvec_upd;
	localparam [31:0] SCR1_CSR_MTVEC_BASE_ZERO_BITS = 6;
	reg [31:SCR1_CSR_MTVEC_BASE_ZERO_BITS] csr_mtvec_base;
	wire csr_mtvec_mode;
	reg csr_mtvec_mode_ff;
	wire csr_mtvec_mode_vect;
	reg csr_mscratch_upd;
	reg [31:0] csr_mscratch_ff;
	reg csr_mepc_upd;
	reg [31:PC_LSB] csr_mepc_ff;
	reg [31:PC_LSB] csr_mepc_next;
	wire [31:0] csr_mepc;
	reg csr_mcause_upd;
	reg csr_mcause_i_ff;
	reg csr_mcause_i_next;
	reg [3:0] csr_mcause_ec_ff;
	reg [3:0] csr_mcause_ec_next;
	reg [3:0] csr_mcause_ec_new;
	reg csr_mtval_upd;
	reg [31:0] csr_mtval_ff;
	reg [31:0] csr_mtval_next;
	reg [31:0] csr_mip;
	wire csr_mip_mtip;
	wire csr_mip_meip;
	wire csr_mip_msip;
	reg [1:0] csr_minstret_upd;
	localparam [31:0] SCR1_CSR_COUNTERS_WIDTH = 64;
	wire [63:0] csr_minstret;
	wire csr_minstret_lo_inc;
	wire csr_minstret_lo_upd;
	reg [7:0] csr_minstret_lo_ff;
	wire [7:0] csr_minstret_lo_next;
	wire csr_minstret_hi_inc;
	wire csr_minstret_hi_upd;
	reg [63:8] csr_minstret_hi_ff;
	wire [63:8] csr_minstret_hi_next;
	wire [63:8] csr_minstret_hi_new;
	reg [1:0] csr_mcycle_upd;
	wire [63:0] csr_mcycle;
	wire csr_mcycle_lo_inc;
	wire csr_mcycle_lo_upd;
	reg [7:0] csr_mcycle_lo_ff;
	wire [7:0] csr_mcycle_lo_next;
	wire csr_mcycle_hi_inc;
	wire csr_mcycle_hi_upd;
	reg [63:8] csr_mcycle_hi_ff;
	wire [63:8] csr_mcycle_hi_next;
	wire [63:8] csr_mcycle_hi_new;
	reg csr_mcounten_upd;
	reg [31:0] csr_mcounten;
	reg csr_mcounten_cy_ff;
	reg csr_mcounten_ir_ff;
	reg [31:0] csr_r_data;
	reg [31:0] csr_w_data;
	wire e_exc;
	wire e_irq;
	wire e_mret;
	wire e_irq_nmret;
	wire csr_eirq_pnd_en;
	wire csr_sirq_pnd_en;
	wire csr_tirq_pnd_en;
	reg csr_w_exc;
	reg csr_r_exc;
	wire exu_req_no_exc;
	wire csr_ipic_req;
	reg csr_hdu_req;
	reg csr_brkm_req;
	assign e_exc = exu2csr_take_exc_i & ~hdu2csr_no_commit_i;
	assign e_irq = (exu2csr_take_irq_i & ~exu2csr_take_exc_i) & ~hdu2csr_no_commit_i;
	assign e_mret = exu2csr_mret_update_i & ~hdu2csr_no_commit_i;
	assign e_irq_nmret = e_irq & ~exu2csr_mret_instr_i;
	assign csr_eirq_pnd_en = csr_mip_meip & csr_mie_meie_ff;
	assign csr_sirq_pnd_en = csr_mip_msip & csr_mie_msie_ff;
	assign csr_tirq_pnd_en = csr_mip_mtip & csr_mie_mtie_ff;
	localparam [3:0] SCR1_EXC_CODE_IRQ_M_EXTERNAL = 4'd11;
	localparam [3:0] SCR1_EXC_CODE_IRQ_M_SOFTWARE = 4'd3;
	localparam [3:0] SCR1_EXC_CODE_IRQ_M_TIMER = 4'd7;
	function automatic [3:0] sv2v_cast_92043;
		input reg [3:0] inp;
		sv2v_cast_92043 = inp;
	endfunction
	always @(*) begin
		csr_mcause_ec_new = sv2v_cast_92043(SCR1_EXC_CODE_IRQ_M_EXTERNAL);
		case (1'b1)
			csr_eirq_pnd_en: csr_mcause_ec_new = sv2v_cast_92043(SCR1_EXC_CODE_IRQ_M_EXTERNAL);
			csr_sirq_pnd_en: csr_mcause_ec_new = sv2v_cast_92043(SCR1_EXC_CODE_IRQ_M_SOFTWARE);
			csr_tirq_pnd_en: csr_mcause_ec_new = sv2v_cast_92043(SCR1_EXC_CODE_IRQ_M_TIMER);
			default: csr_mcause_ec_new = sv2v_cast_92043(SCR1_EXC_CODE_IRQ_M_EXTERNAL);
		endcase
	end
	assign exu_req_no_exc = (exu2csr_r_req_i & ~csr_r_exc) | (exu2csr_w_req_i & ~csr_w_exc);
	localparam [6:0] SCR1_CSR_ADDR_HPMCOUNTERH_MASK = 7'b1100100;
	localparam [6:0] SCR1_CSR_ADDR_HPMCOUNTER_MASK = 7'b1100000;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_BASE = sv2v_cast_C1AAB('hbf0);
	localparam [2:0] SCR1_IPIC_CICSR = 3'h1;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_CICSR = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_CICSR;
	localparam [2:0] SCR1_IPIC_CISV = 3'h0;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_CISV = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_CISV;
	localparam [2:0] SCR1_IPIC_EOI = 3'h4;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_EOI = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_EOI;
	localparam [2:0] SCR1_IPIC_ICSR = 3'h7;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_ICSR = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_ICSR;
	localparam [2:0] SCR1_IPIC_IDX = 3'h6;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_IDX = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_IDX;
	localparam [2:0] SCR1_IPIC_IPR = 3'h2;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_IPR = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_IPR;
	localparam [2:0] SCR1_IPIC_ISVR = 3'h3;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_ISVR = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_ISVR;
	localparam [2:0] SCR1_IPIC_SOI = 3'h5;
	localparam [11:0] SCR1_CSR_ADDR_IPIC_SOI = SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_SOI;
	localparam [11:0] SCR1_CSR_ADDR_MARCHID = sv2v_cast_C1AAB('hf12);
	localparam [11:0] SCR1_CSR_ADDR_MCAUSE = sv2v_cast_C1AAB('h342);
	localparam [11:0] SCR1_CSR_ADDR_MCOUNTEN = sv2v_cast_C1AAB('h7e0);
	localparam [11:0] SCR1_CSR_ADDR_MEPC = sv2v_cast_C1AAB('h341);
	localparam [11:0] SCR1_CSR_ADDR_MHARTID = sv2v_cast_C1AAB('hf14);
	localparam [6:0] SCR1_CSR_ADDR_MHPMCOUNTERH_MASK = 7'b1011100;
	localparam [6:0] SCR1_CSR_ADDR_MHPMCOUNTER_MASK = 7'b1011000;
	localparam [6:0] SCR1_CSR_ADDR_MHPMEVENT_MASK = 7'b0011001;
	localparam [11:0] SCR1_CSR_ADDR_MIE = sv2v_cast_C1AAB('h304);
	localparam [11:0] SCR1_CSR_ADDR_MIMPID = sv2v_cast_C1AAB('hf13);
	localparam [11:0] SCR1_CSR_ADDR_MIP = sv2v_cast_C1AAB('h344);
	localparam [11:0] SCR1_CSR_ADDR_MISA = sv2v_cast_C1AAB('h301);
	localparam [11:0] SCR1_CSR_ADDR_MSCRATCH = sv2v_cast_C1AAB('h340);
	localparam [11:0] SCR1_CSR_ADDR_MSTATUS = sv2v_cast_C1AAB('h300);
	localparam [11:0] SCR1_CSR_ADDR_MTVAL = sv2v_cast_C1AAB('h343);
	localparam [11:0] SCR1_CSR_ADDR_MTVEC = sv2v_cast_C1AAB('h305);
	localparam [11:0] SCR1_CSR_ADDR_MVENDORID = sv2v_cast_C1AAB('hf11);
	localparam [11:0] SCR1_CSR_ADDR_TDU_MBASE = sv2v_cast_C1AAB('h7a0);
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TDATA1 = 3'sd1;
	localparam [11:0] SCR1_CSR_ADDR_TDU_TDATA1 = SCR1_CSR_ADDR_TDU_MBASE + SCR1_CSR_ADDR_TDU_OFFS_TDATA1;
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TDATA2 = 3'sd2;
	localparam [11:0] SCR1_CSR_ADDR_TDU_TDATA2 = SCR1_CSR_ADDR_TDU_MBASE + SCR1_CSR_ADDR_TDU_OFFS_TDATA2;
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TINFO = 3'sd4;
	localparam [11:0] SCR1_CSR_ADDR_TDU_TINFO = SCR1_CSR_ADDR_TDU_MBASE + SCR1_CSR_ADDR_TDU_OFFS_TINFO;
	localparam [2:0] SCR1_CSR_ADDR_TDU_OFFS_TSELECT = 3'sd0;
	localparam [11:0] SCR1_CSR_ADDR_TDU_TSELECT = SCR1_CSR_ADDR_TDU_MBASE + SCR1_CSR_ADDR_TDU_OFFS_TSELECT;
	localparam [31:0] SCR1_CSR_MARCHID = 32'd8;
	localparam [31:0] SCR1_CSR_MIMPID = 32'h22011200;
	localparam [1:0] SCR1_MISA_MXL_32 = 2'd1;
	localparam [31:0] SCR1_CSR_MISA = (((SCR1_MISA_MXL_32 << 30) | 32'h00000100) | 32'h00000004) | 32'h00001000;
	localparam [31:0] SCR1_CSR_MVENDORID = 32'h00000000;
	localparam [11:0] SCR1_CSR_ADDR_HDU_MBASE = sv2v_cast_C1AAB('h7b0);
	function automatic [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] sv2v_cast_68C55;
		input reg [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] inp;
		sv2v_cast_68C55 = inp;
	endfunction
	localparam SCR1_HDU_DBGCSR_OFFS_DCSR = sv2v_cast_68C55('d0);
	localparam [11:0] SCR1_HDU_DBGCSR_ADDR_DCSR = SCR1_CSR_ADDR_HDU_MBASE + SCR1_HDU_DBGCSR_OFFS_DCSR;
	localparam SCR1_HDU_DBGCSR_OFFS_DPC = sv2v_cast_68C55('d1);
	localparam [11:0] SCR1_HDU_DBGCSR_ADDR_DPC = SCR1_CSR_ADDR_HDU_MBASE + SCR1_HDU_DBGCSR_OFFS_DPC;
	localparam SCR1_HDU_DBGCSR_OFFS_DSCRATCH0 = sv2v_cast_68C55('d2);
	localparam [11:0] SCR1_HDU_DBGCSR_ADDR_DSCRATCH0 = SCR1_CSR_ADDR_HDU_MBASE + SCR1_HDU_DBGCSR_OFFS_DSCRATCH0;
	localparam SCR1_HDU_DBGCSR_OFFS_DSCRATCH1 = sv2v_cast_68C55('d3);
	localparam [11:0] SCR1_HDU_DBGCSR_ADDR_DSCRATCH1 = SCR1_CSR_ADDR_HDU_MBASE + SCR1_HDU_DBGCSR_OFFS_DSCRATCH1;
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	function automatic [30:0] sv2v_cast_31;
		input reg [30:0] inp;
		sv2v_cast_31 = inp;
	endfunction
	always @(*) begin
		csr_r_data = 1'sb0;
		csr_r_exc = 1'b0;
		csr_hdu_req = 1'b0;
		csr_brkm_req = 1'b0;
		csr2ipic_r_req_o = 1'b0;
		casez (exu2csr_rw_addr_i)
			SCR1_CSR_ADDR_MVENDORID: csr_r_data = SCR1_CSR_MVENDORID;
			SCR1_CSR_ADDR_MARCHID: csr_r_data = SCR1_CSR_MARCHID;
			SCR1_CSR_ADDR_MIMPID: csr_r_data = SCR1_CSR_MIMPID;
			SCR1_CSR_ADDR_MHARTID: csr_r_data = soc2csr_fuse_mhartid_i;
			SCR1_CSR_ADDR_MSTATUS: csr_r_data = csr_mstatus;
			SCR1_CSR_ADDR_MISA: csr_r_data = SCR1_CSR_MISA;
			SCR1_CSR_ADDR_MIE: csr_r_data = csr_mie;
			SCR1_CSR_ADDR_MTVEC: csr_r_data = {csr_mtvec_base, 4'd0, sv2v_cast_2(csr_mtvec_mode)};
			SCR1_CSR_ADDR_MSCRATCH: csr_r_data = csr_mscratch_ff;
			SCR1_CSR_ADDR_MEPC: csr_r_data = csr_mepc;
			SCR1_CSR_ADDR_MCAUSE: csr_r_data = {csr_mcause_i_ff, sv2v_cast_31(csr_mcause_ec_ff)};
			SCR1_CSR_ADDR_MTVAL: csr_r_data = csr_mtval_ff;
			SCR1_CSR_ADDR_MIP: csr_r_data = csr_mip;
			{SCR1_CSR_ADDR_HPMCOUNTER_MASK, 5'bzzzzz}:
				case (exu2csr_rw_addr_i[4:0])
					5'd1: csr_r_data = soc2csr_mtimer_val_i[31:0];
					5'd0: csr_r_data = csr_mcycle[31:0];
					5'd2: csr_r_data = csr_minstret[31:0];
					default:
						;
				endcase
			{SCR1_CSR_ADDR_HPMCOUNTERH_MASK, 5'bzzzzz}:
				case (exu2csr_rw_addr_i[4:0])
					5'd1: csr_r_data = soc2csr_mtimer_val_i[63:32];
					5'd0: csr_r_data = csr_mcycle[63:32];
					5'd2: csr_r_data = csr_minstret[63:32];
					default:
						;
				endcase
			{SCR1_CSR_ADDR_MHPMCOUNTER_MASK, 5'bzzzzz}:
				case (exu2csr_rw_addr_i[4:0])
					5'd1: csr_r_exc = exu2csr_r_req_i;
					5'd0: csr_r_data = csr_mcycle[31:0];
					5'd2: csr_r_data = csr_minstret[31:0];
					default:
						;
				endcase
			{SCR1_CSR_ADDR_MHPMCOUNTERH_MASK, 5'bzzzzz}:
				case (exu2csr_rw_addr_i[4:0])
					5'd1: csr_r_exc = exu2csr_r_req_i;
					5'd0: csr_r_data = csr_mcycle[63:32];
					5'd2: csr_r_data = csr_minstret[63:32];
					default:
						;
				endcase
			{SCR1_CSR_ADDR_MHPMEVENT_MASK, 5'bzzzzz}:
				case (exu2csr_rw_addr_i[4:0])
					5'd0, 5'd1, 5'd2: csr_r_exc = exu2csr_r_req_i;
					default:
						;
				endcase
			SCR1_CSR_ADDR_MCOUNTEN: csr_r_data = csr_mcounten;
			SCR1_CSR_ADDR_IPIC_CISV, SCR1_CSR_ADDR_IPIC_CICSR, SCR1_CSR_ADDR_IPIC_IPR, SCR1_CSR_ADDR_IPIC_ISVR, SCR1_CSR_ADDR_IPIC_EOI, SCR1_CSR_ADDR_IPIC_SOI, SCR1_CSR_ADDR_IPIC_IDX, SCR1_CSR_ADDR_IPIC_ICSR: begin
				csr_r_data = ipic2csr_rdata_i;
				csr2ipic_r_req_o = exu2csr_r_req_i;
			end
			SCR1_HDU_DBGCSR_ADDR_DCSR, SCR1_HDU_DBGCSR_ADDR_DPC, SCR1_HDU_DBGCSR_ADDR_DSCRATCH0, SCR1_HDU_DBGCSR_ADDR_DSCRATCH1: begin
				csr_hdu_req = 1'b1;
				csr_r_data = hdu2csr_rdata_i;
			end
			SCR1_CSR_ADDR_TDU_TSELECT, SCR1_CSR_ADDR_TDU_TDATA1, SCR1_CSR_ADDR_TDU_TDATA2, SCR1_CSR_ADDR_TDU_TINFO: begin
				csr_brkm_req = 1'b1;
				csr_r_data = tdu2csr_rdata_i;
			end
			default: csr_r_exc = exu2csr_r_req_i;
		endcase
	end
	assign csr2exu_r_data_o = csr_r_data;
	function automatic [1:0] sv2v_cast_999B9;
		input reg [1:0] inp;
		sv2v_cast_999B9 = inp;
	endfunction
	always @(*) begin
		csr_w_data = 1'sb0;
		case (exu2csr_w_cmd_i)
			sv2v_cast_999B9({32 {1'sb0}} + 1): csr_w_data = exu2csr_w_data_i;
			sv2v_cast_999B9({32 {1'sb0}} + 2): csr_w_data = exu2csr_w_data_i | csr_r_data;
			sv2v_cast_999B9({32 {1'sb0}} + 3): csr_w_data = ~exu2csr_w_data_i & csr_r_data;
			default: csr_w_data = 1'sb0;
		endcase
	end
	always @(*) begin
		csr_mstatus_upd = 1'b0;
		csr_mie_upd = 1'b0;
		csr_mscratch_upd = 1'b0;
		csr_mepc_upd = 1'b0;
		csr_mcause_upd = 1'b0;
		csr_mtval_upd = 1'b0;
		csr_mtvec_upd = 1'b0;
		csr_mcycle_upd = 2'b00;
		csr_minstret_upd = 2'b00;
		csr_mcounten_upd = 1'b0;
		csr_w_exc = 1'b0;
		csr2ipic_w_req_o = 1'b0;
		if (exu2csr_w_req_i)
			casez (exu2csr_rw_addr_i)
				SCR1_CSR_ADDR_MSTATUS: csr_mstatus_upd = 1'b1;
				SCR1_CSR_ADDR_MISA:
					;
				SCR1_CSR_ADDR_MIE: csr_mie_upd = 1'b1;
				SCR1_CSR_ADDR_MTVEC: csr_mtvec_upd = 1'b1;
				SCR1_CSR_ADDR_MSCRATCH: csr_mscratch_upd = 1'b1;
				SCR1_CSR_ADDR_MEPC: csr_mepc_upd = 1'b1;
				SCR1_CSR_ADDR_MCAUSE: csr_mcause_upd = 1'b1;
				SCR1_CSR_ADDR_MTVAL: csr_mtval_upd = 1'b1;
				SCR1_CSR_ADDR_MIP:
					;
				{SCR1_CSR_ADDR_MHPMCOUNTER_MASK, 5'bzzzzz}:
					case (exu2csr_rw_addr_i[4:0])
						5'd1: csr_w_exc = 1'b1;
						5'd0: csr_mcycle_upd[0] = 1'b1;
						5'd2: csr_minstret_upd[0] = 1'b1;
						default:
							;
					endcase
				{SCR1_CSR_ADDR_MHPMCOUNTERH_MASK, 5'bzzzzz}:
					case (exu2csr_rw_addr_i[4:0])
						5'd1: csr_w_exc = 1'b1;
						5'd0: csr_mcycle_upd[1] = 1'b1;
						5'd2: csr_minstret_upd[1] = 1'b1;
						default:
							;
					endcase
				{SCR1_CSR_ADDR_MHPMEVENT_MASK, 5'bzzzzz}:
					case (exu2csr_rw_addr_i[4:0])
						5'd0, 5'd1, 5'd2: csr_w_exc = 1'b1;
						default:
							;
					endcase
				SCR1_CSR_ADDR_MCOUNTEN: csr_mcounten_upd = 1'b1;
				SCR1_CSR_ADDR_IPIC_CICSR, SCR1_CSR_ADDR_IPIC_IPR, SCR1_CSR_ADDR_IPIC_EOI, SCR1_CSR_ADDR_IPIC_SOI, SCR1_CSR_ADDR_IPIC_IDX, SCR1_CSR_ADDR_IPIC_ICSR: csr2ipic_w_req_o = 1'b1;
				SCR1_CSR_ADDR_IPIC_CISV, SCR1_CSR_ADDR_IPIC_ISVR:
					;
				SCR1_HDU_DBGCSR_ADDR_DCSR, SCR1_HDU_DBGCSR_ADDR_DPC, SCR1_HDU_DBGCSR_ADDR_DSCRATCH0, SCR1_HDU_DBGCSR_ADDR_DSCRATCH1:
					;
				SCR1_CSR_ADDR_TDU_TSELECT, SCR1_CSR_ADDR_TDU_TDATA1, SCR1_CSR_ADDR_TDU_TDATA2, SCR1_CSR_ADDR_TDU_TINFO:
					;
				default: csr_w_exc = 1'b1;
			endcase
	end
	localparam [0:0] SCR1_CSR_MSTATUS_MIE_RST_VAL = 1'b0;
	localparam [0:0] SCR1_CSR_MSTATUS_MPIE_RST_VAL = 1'b1;
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			csr_mstatus_mie_ff <= SCR1_CSR_MSTATUS_MIE_RST_VAL;
			csr_mstatus_mpie_ff <= SCR1_CSR_MSTATUS_MPIE_RST_VAL;
		end
		else begin
			csr_mstatus_mie_ff <= csr_mstatus_mie_next;
			csr_mstatus_mpie_ff <= csr_mstatus_mpie_next;
		end
	localparam [31:0] SCR1_CSR_MSTATUS_MIE_OFFSET = 3;
	localparam [31:0] SCR1_CSR_MSTATUS_MPIE_OFFSET = 7;
	always @(*) begin
		case (1'b1)
			e_exc, e_irq: begin
				csr_mstatus_mie_next = 1'b0;
				csr_mstatus_mpie_next = csr_mstatus_mie_ff;
			end
			e_mret: begin
				csr_mstatus_mie_next = csr_mstatus_mpie_ff;
				csr_mstatus_mpie_next = 1'b1;
			end
			csr_mstatus_upd: begin
				csr_mstatus_mie_next = csr_w_data[SCR1_CSR_MSTATUS_MIE_OFFSET];
				csr_mstatus_mpie_next = csr_w_data[SCR1_CSR_MSTATUS_MPIE_OFFSET];
			end
			default: begin
				csr_mstatus_mie_next = csr_mstatus_mie_ff;
				csr_mstatus_mpie_next = csr_mstatus_mpie_ff;
			end
		endcase
	end
	localparam [1:0] SCR1_CSR_MSTATUS_MPP = 2'b11;
	localparam [31:0] SCR1_CSR_MSTATUS_MPP_OFFSET = 11;
	always @(*) begin
		csr_mstatus = 1'sb0;
		csr_mstatus[SCR1_CSR_MSTATUS_MIE_OFFSET] = csr_mstatus_mie_ff;
		csr_mstatus[SCR1_CSR_MSTATUS_MPIE_OFFSET] = csr_mstatus_mpie_ff;
		csr_mstatus[12:SCR1_CSR_MSTATUS_MPP_OFFSET] = SCR1_CSR_MSTATUS_MPP;
	end
	localparam [31:0] SCR1_CSR_MIE_MEIE_OFFSET = 11;
	localparam [0:0] SCR1_CSR_MIE_MEIE_RST_VAL = 1'b0;
	localparam [31:0] SCR1_CSR_MIE_MSIE_OFFSET = 3;
	localparam [0:0] SCR1_CSR_MIE_MSIE_RST_VAL = 1'b0;
	localparam [31:0] SCR1_CSR_MIE_MTIE_OFFSET = 7;
	localparam [0:0] SCR1_CSR_MIE_MTIE_RST_VAL = 1'b0;
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			csr_mie_mtie_ff <= SCR1_CSR_MIE_MTIE_RST_VAL;
			csr_mie_meie_ff <= SCR1_CSR_MIE_MEIE_RST_VAL;
			csr_mie_msie_ff <= SCR1_CSR_MIE_MSIE_RST_VAL;
		end
		else if (csr_mie_upd) begin
			csr_mie_mtie_ff <= csr_w_data[SCR1_CSR_MIE_MTIE_OFFSET];
			csr_mie_meie_ff <= csr_w_data[SCR1_CSR_MIE_MEIE_OFFSET];
			csr_mie_msie_ff <= csr_w_data[SCR1_CSR_MIE_MSIE_OFFSET];
		end
	always @(*) begin
		csr_mie = 1'sb0;
		csr_mie[SCR1_CSR_MIE_MSIE_OFFSET] = csr_mie_msie_ff;
		csr_mie[SCR1_CSR_MIE_MTIE_OFFSET] = csr_mie_mtie_ff;
		csr_mie[SCR1_CSR_MIE_MEIE_OFFSET] = csr_mie_meie_ff;
	end
	localparam [31:0] SCR1_MTVEC_BASE_WR_BITS = 26;
	localparam [31:0] SCR1_CSR_MTVEC_BASE_RO_BITS = 32 - (SCR1_CSR_MTVEC_BASE_ZERO_BITS + SCR1_MTVEC_BASE_WR_BITS);
	localparam [31:0] SCR1_ARCH_MTVEC_BASE = 'h1c0;
	localparam [31:0] SCR1_CSR_MTVEC_BASE_VAL_BITS = 26;
	function automatic [25:0] sv2v_cast_961FC;
		input reg [25:0] inp;
		sv2v_cast_961FC = inp;
	endfunction
	localparam [31:SCR1_CSR_MTVEC_BASE_ZERO_BITS] SCR1_CSR_MTVEC_BASE_WR_RST_VAL = sv2v_cast_961FC(SCR1_ARCH_MTVEC_BASE >> SCR1_CSR_MTVEC_BASE_ZERO_BITS);
	localparam [31:SCR1_CSR_MTVEC_BASE_ZERO_BITS] SCR1_CSR_MTVEC_BASE_RST_VAL = SCR1_CSR_MTVEC_BASE_WR_RST_VAL;
	generate
		if (1) begin : mtvec_base_rw
			always @(negedge rst_n or posedge clk)
				if (~rst_n)
					csr_mtvec_base <= SCR1_CSR_MTVEC_BASE_RST_VAL;
				else if (csr_mtvec_upd)
					csr_mtvec_base <= csr_w_data[31:SCR1_CSR_MTVEC_BASE_ZERO_BITS];
		end
	endgenerate
	localparam [0:0] SCR1_CSR_MTVEC_MODE_DIRECT = 1'b0;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			csr_mtvec_mode_ff <= SCR1_CSR_MTVEC_MODE_DIRECT;
		else if (csr_mtvec_upd)
			csr_mtvec_mode_ff <= csr_w_data[0];
	assign csr_mtvec_mode = csr_mtvec_mode_ff;
	localparam [0:0] SCR1_CSR_MTVEC_MODE_VECTORED = 1'b1;
	assign csr_mtvec_mode_vect = csr_mtvec_mode_ff == SCR1_CSR_MTVEC_MODE_VECTORED;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			csr_mscratch_ff <= 1'sb0;
		else if (csr_mscratch_upd)
			csr_mscratch_ff <= csr_w_data;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			csr_mepc_ff <= 1'sb0;
		else
			csr_mepc_ff <= csr_mepc_next;
	always @(*) begin
		csr_mepc_next = csr_mepc_ff;
		case (1'b1)
			e_exc: csr_mepc_next = exu2csr_pc_curr_i[31:PC_LSB];
			e_irq_nmret: csr_mepc_next = exu2csr_pc_next_i[31:PC_LSB];
			csr_mepc_upd: csr_mepc_next = csr_w_data[31:PC_LSB];
			default: csr_mepc_next = csr_mepc_ff;
		endcase
	end
	assign csr_mepc = {csr_mepc_ff, 1'b0};
	localparam [3:0] SCR1_EXC_CODE_RESET = 4'd0;
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			csr_mcause_i_ff <= 1'b0;
			csr_mcause_ec_ff <= sv2v_cast_92043(SCR1_EXC_CODE_RESET);
		end
		else begin
			csr_mcause_i_ff <= csr_mcause_i_next;
			csr_mcause_ec_ff <= csr_mcause_ec_next;
		end
	always @(*) begin
		case (1'b1)
			e_exc: begin
				csr_mcause_i_next = 1'b0;
				csr_mcause_ec_next = exu2csr_exc_code_i;
			end
			e_irq: begin
				csr_mcause_i_next = 1'b1;
				csr_mcause_ec_next = csr_mcause_ec_new;
			end
			csr_mcause_upd: begin
				csr_mcause_i_next = csr_w_data[31];
				csr_mcause_ec_next = csr_w_data[3:0];
			end
			default: begin
				csr_mcause_i_next = csr_mcause_i_ff;
				csr_mcause_ec_next = csr_mcause_ec_ff;
			end
		endcase
	end
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			csr_mtval_ff <= 1'sb0;
		else
			csr_mtval_ff <= csr_mtval_next;
	always @(*) begin
		csr_mtval_next = csr_mtval_ff;
		case (1'b1)
			e_exc: csr_mtval_next = exu2csr_trap_val_i;
			e_irq: csr_mtval_next = 1'sb0;
			csr_mtval_upd: csr_mtval_next = csr_w_data;
			default: csr_mtval_next = csr_mtval_ff;
		endcase
	end
	assign csr_mip_mtip = soc2csr_irq_mtimer_i;
	assign csr_mip_meip = soc2csr_irq_ext_i;
	assign csr_mip_msip = soc2csr_irq_soft_i;
	always @(*) begin
		csr_mip = 1'sb0;
		csr_mip[SCR1_CSR_MIE_MSIE_OFFSET] = csr_mip_msip;
		csr_mip[SCR1_CSR_MIE_MTIE_OFFSET] = csr_mip_mtip;
		csr_mip[SCR1_CSR_MIE_MEIE_OFFSET] = csr_mip_meip;
	end
	assign csr_mcycle_lo_inc = 1'b1 & csr_mcounten_cy_ff;
	assign csr_mcycle_hi_inc = csr_mcycle_lo_inc & (&csr_mcycle_lo_ff);
	assign csr_mcycle_lo_upd = csr_mcycle_lo_inc | csr_mcycle_upd[0];
	assign csr_mcycle_hi_upd = csr_mcycle_hi_inc | (|csr_mcycle_upd);
	always @(negedge rst_n or posedge clk_alw_on)
		if (~rst_n) begin
			csr_mcycle_lo_ff <= 1'sb0;
			csr_mcycle_hi_ff <= 1'sb0;
		end
		else begin
			if (csr_mcycle_lo_upd)
				csr_mcycle_lo_ff <= csr_mcycle_lo_next;
			if (csr_mcycle_hi_upd)
				csr_mcycle_hi_ff <= csr_mcycle_hi_next;
		end
	assign csr_mcycle_hi_new = csr_mcycle_hi_ff + 1'b1;
	assign csr_mcycle_lo_next = (csr_mcycle_upd[0] ? csr_w_data[7:0] : (csr_mcycle_lo_inc ? csr_mcycle_lo_ff + 1'b1 : csr_mcycle_lo_ff));
	assign csr_mcycle_hi_next = (csr_mcycle_upd[0] ? {csr_mcycle_hi_new[63:32], csr_w_data[31:8]} : (csr_mcycle_upd[1] ? {csr_w_data, csr_mcycle_hi_new[31:8]} : (csr_mcycle_hi_inc ? csr_mcycle_hi_new : csr_mcycle_hi_ff)));
	assign csr_mcycle = {csr_mcycle_hi_ff, csr_mcycle_lo_ff};
	assign csr_minstret_lo_inc = exu2csr_instret_no_exc_i & csr_mcounten_ir_ff;
	assign csr_minstret_hi_inc = csr_minstret_lo_inc & (&csr_minstret_lo_ff);
	assign csr_minstret_lo_upd = csr_minstret_lo_inc | csr_minstret_upd[0];
	assign csr_minstret_hi_upd = csr_minstret_hi_inc | (|csr_minstret_upd);
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			csr_minstret_lo_ff <= 1'sb0;
			csr_minstret_hi_ff <= 1'sb0;
		end
		else begin
			if (csr_minstret_lo_upd)
				csr_minstret_lo_ff <= csr_minstret_lo_next;
			if (csr_minstret_hi_upd)
				csr_minstret_hi_ff <= csr_minstret_hi_next;
		end
	assign csr_minstret_hi_new = csr_minstret_hi_ff + 1'b1;
	assign csr_minstret_lo_next = (csr_minstret_upd[0] ? csr_w_data[7:0] : (csr_minstret_lo_inc ? csr_minstret_lo_ff + 1'b1 : csr_minstret_lo_ff));
	assign csr_minstret_hi_next = (csr_minstret_upd[0] ? {csr_minstret_hi_new[63:32], csr_w_data[31:8]} : (csr_minstret_upd[1] ? {csr_w_data, csr_minstret_hi_new[31:8]} : (csr_minstret_hi_inc ? csr_minstret_hi_new : csr_minstret_hi_ff)));
	assign csr_minstret = {csr_minstret_hi_ff, csr_minstret_lo_ff};
	localparam [31:0] SCR1_CSR_MCOUNTEN_CY_OFFSET = 0;
	localparam [31:0] SCR1_CSR_MCOUNTEN_IR_OFFSET = 2;
	always @(negedge rst_n or posedge clk)
		if (~rst_n) begin
			csr_mcounten_cy_ff <= 1'b1;
			csr_mcounten_ir_ff <= 1'b1;
		end
		else if (csr_mcounten_upd) begin
			csr_mcounten_cy_ff <= csr_w_data[SCR1_CSR_MCOUNTEN_CY_OFFSET];
			csr_mcounten_ir_ff <= csr_w_data[SCR1_CSR_MCOUNTEN_IR_OFFSET];
		end
	always @(*) begin
		csr_mcounten = 1'sb0;
		csr_mcounten[SCR1_CSR_MCOUNTEN_CY_OFFSET] = csr_mcounten_cy_ff;
		csr_mcounten[SCR1_CSR_MCOUNTEN_IR_OFFSET] = csr_mcounten_ir_ff;
	end
	assign csr2exu_rw_exc_o = ((csr_r_exc | csr_w_exc) | (csr2hdu_req_o & (hdu2csr_resp_i != 1'd0))) | (csr2tdu_req_o & (tdu2csr_resp_i != 1'd0));
	assign csr2exu_ip_ie_o = (csr_eirq_pnd_en | csr_sirq_pnd_en) | csr_tirq_pnd_en;
	assign csr2exu_irq_o = csr2exu_ip_ie_o & csr_mstatus_mie_ff;
	assign csr2exu_mstatus_mie_up_o = (csr_mstatus_upd | csr_mie_upd) | e_mret;
	function automatic signed [5:0] sv2v_cast_13C0F_signed;
		input reg signed [5:0] inp;
		sv2v_cast_13C0F_signed = inp;
	endfunction
	always @(*) begin
		if (exu2csr_mret_instr_i & ~exu2csr_take_irq_i)
			csr2exu_new_pc_o = csr_mepc;
		else if (csr_mtvec_mode_vect)
			case (1'b1)
				exu2csr_take_exc_i: csr2exu_new_pc_o = {csr_mtvec_base, sv2v_cast_13C0F_signed(0)};
				csr_eirq_pnd_en: csr2exu_new_pc_o = {csr_mtvec_base, SCR1_EXC_CODE_IRQ_M_EXTERNAL, 2'd0};
				csr_sirq_pnd_en: csr2exu_new_pc_o = {csr_mtvec_base, SCR1_EXC_CODE_IRQ_M_SOFTWARE, 2'd0};
				csr_tirq_pnd_en: csr2exu_new_pc_o = {csr_mtvec_base, SCR1_EXC_CODE_IRQ_M_TIMER, 2'd0};
				default: csr2exu_new_pc_o = {csr_mtvec_base, sv2v_cast_13C0F_signed(0)};
			endcase
		else
			csr2exu_new_pc_o = {csr_mtvec_base, sv2v_cast_13C0F_signed(0)};
	end
	assign csr_ipic_req = csr2ipic_r_req_o | csr2ipic_w_req_o;
	assign csr2ipic_addr_o = (csr_ipic_req ? exu2csr_rw_addr_i[2:0] : {3 {1'sb0}});
	assign csr2ipic_wdata_o = (csr2ipic_w_req_o ? exu2csr_w_data_i : {32 {1'sb0}});
	assign csr2hdu_req_o = csr_hdu_req & exu_req_no_exc;
	assign csr2hdu_cmd_o = exu2csr_w_cmd_i;
	assign csr2hdu_addr_o = exu2csr_rw_addr_i[SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0];
	assign csr2hdu_wdata_o = exu2csr_w_data_i;
	assign csr2tdu_req_o = csr_brkm_req & exu_req_no_exc;
	assign csr2tdu_cmd_o = exu2csr_w_cmd_i;
	assign csr2tdu_addr_o = exu2csr_rw_addr_i[2:0];
	assign csr2tdu_wdata_o = exu2csr_w_data_i;
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_exu (
	rst_n,
	clk,
	clk_alw_on,
	clk_pipe_en,
	idu2exu_req_i,
	exu2idu_rdy_o,
	idu2exu_cmd_i,
	idu2exu_use_rs1_i,
	idu2exu_use_rs2_i,
	exu2mprf_rs1_addr_o,
	mprf2exu_rs1_data_i,
	exu2mprf_rs2_addr_o,
	mprf2exu_rs2_data_i,
	exu2mprf_w_req_o,
	exu2mprf_rd_addr_o,
	exu2mprf_rd_data_o,
	exu2csr_rw_addr_o,
	exu2csr_r_req_o,
	csr2exu_r_data_i,
	exu2csr_w_req_o,
	exu2csr_w_cmd_o,
	exu2csr_w_data_o,
	csr2exu_rw_exc_i,
	exu2csr_take_irq_o,
	exu2csr_take_exc_o,
	exu2csr_mret_update_o,
	exu2csr_mret_instr_o,
	exu2csr_exc_code_o,
	exu2csr_trap_val_o,
	csr2exu_new_pc_i,
	csr2exu_irq_i,
	csr2exu_ip_ie_i,
	csr2exu_mstatus_mie_up_i,
	exu2dmem_req_o,
	exu2dmem_cmd_o,
	exu2dmem_width_o,
	exu2dmem_addr_o,
	exu2dmem_wdata_o,
	dmem2exu_req_ack_i,
	dmem2exu_rdata_i,
	dmem2exu_resp_i,
	exu2pipe_exc_req_o,
	exu2pipe_brkpt_o,
	exu2pipe_init_pc_o,
	exu2pipe_wfi_run2halt_o,
	exu2pipe_instret_o,
	exu2csr_instret_no_exc_o,
	exu2pipe_exu_busy_o,
	hdu2exu_no_commit_i,
	hdu2exu_irq_dsbl_i,
	hdu2exu_pc_advmt_dsbl_i,
	hdu2exu_dmode_sstep_en_i,
	hdu2exu_pbuf_fetch_i,
	hdu2exu_dbg_halted_i,
	hdu2exu_dbg_run2halt_i,
	hdu2exu_dbg_halt2run_i,
	hdu2exu_dbg_run_start_i,
	hdu2exu_dbg_new_pc_i,
	exu2tdu_imon_o,
	tdu2exu_ibrkpt_match_i,
	tdu2exu_ibrkpt_exc_req_i,
	lsu2tdu_dmon_o,
	tdu2lsu_ibrkpt_exc_req_i,
	tdu2lsu_dbrkpt_match_i,
	tdu2lsu_dbrkpt_exc_req_i,
	exu2tdu_ibrkpt_ret_o,
	exu2hdu_ibrkpt_hw_o,
	exu2pipe_wfi_halted_o,
	exu2pipe_pc_curr_o,
	exu2csr_pc_next_o,
	exu2ifu_pc_new_req_o,
	exu2ifu_pc_new_o
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	input wire clk_alw_on;
	input wire clk_pipe_en;
	input wire idu2exu_req_i;
	output wire exu2idu_rdy_o;
	localparam SCR1_GPR_FIELD_WIDTH = 5;
	localparam SCR1_CSR_CMD_ALL_NUM_E = 4;
	localparam SCR1_CSR_CMD_WIDTH_E = 2;
	localparam SCR1_CSR_OP_ALL_NUM_E = 2;
	localparam SCR1_CSR_OP_WIDTH_E = 1;
	localparam [31:0] SCR1_EXC_CODE_WIDTH_E = 4;
	localparam SCR1_IALU_CMD_ALL_NUM_E = 23;
	localparam SCR1_IALU_CMD_WIDTH_E = 5;
	localparam SCR1_IALU_OP_ALL_NUM_E = 2;
	localparam SCR1_IALU_OP_WIDTH_E = 1;
	localparam SCR1_SUM2_OP_ALL_NUM_E = 2;
	localparam SCR1_SUM2_OP_WIDTH_E = 1;
	localparam SCR1_LSU_CMD_ALL_NUM_E = 9;
	localparam SCR1_LSU_CMD_WIDTH_E = 4;
	localparam SCR1_RD_WB_ALL_NUM_E = 7;
	localparam SCR1_RD_WB_WIDTH_E = 3;
	input wire [74:0] idu2exu_cmd_i;
	input wire idu2exu_use_rs1_i;
	input wire idu2exu_use_rs2_i;
	output wire [4:0] exu2mprf_rs1_addr_o;
	input wire [31:0] mprf2exu_rs1_data_i;
	output wire [4:0] exu2mprf_rs2_addr_o;
	input wire [31:0] mprf2exu_rs2_data_i;
	output wire exu2mprf_w_req_o;
	output wire [4:0] exu2mprf_rd_addr_o;
	output reg [31:0] exu2mprf_rd_data_o;
	localparam [31:0] SCR1_CSR_ADDR_WIDTH = 12;
	output wire [11:0] exu2csr_rw_addr_o;
	output reg exu2csr_r_req_o;
	input wire [31:0] csr2exu_r_data_i;
	output reg exu2csr_w_req_o;
	output wire [1:0] exu2csr_w_cmd_o;
	output wire [31:0] exu2csr_w_data_o;
	input wire csr2exu_rw_exc_i;
	output wire exu2csr_take_irq_o;
	output wire exu2csr_take_exc_o;
	output wire exu2csr_mret_update_o;
	output wire exu2csr_mret_instr_o;
	output wire [3:0] exu2csr_exc_code_o;
	output wire [31:0] exu2csr_trap_val_o;
	input wire [31:0] csr2exu_new_pc_i;
	input wire csr2exu_irq_i;
	input wire csr2exu_ip_ie_i;
	input wire csr2exu_mstatus_mie_up_i;
	output wire exu2dmem_req_o;
	output wire exu2dmem_cmd_o;
	output wire [1:0] exu2dmem_width_o;
	output wire [31:0] exu2dmem_addr_o;
	output wire [31:0] exu2dmem_wdata_o;
	input wire dmem2exu_req_ack_i;
	input wire [31:0] dmem2exu_rdata_i;
	input wire [1:0] dmem2exu_resp_i;
	output wire exu2pipe_exc_req_o;
	output wire exu2pipe_brkpt_o;
	output wire exu2pipe_init_pc_o;
	output wire exu2pipe_wfi_run2halt_o;
	output wire exu2pipe_instret_o;
	output wire exu2csr_instret_no_exc_o;
	output wire exu2pipe_exu_busy_o;
	input wire hdu2exu_no_commit_i;
	input wire hdu2exu_irq_dsbl_i;
	input wire hdu2exu_pc_advmt_dsbl_i;
	input wire hdu2exu_dmode_sstep_en_i;
	input wire hdu2exu_pbuf_fetch_i;
	input wire hdu2exu_dbg_halted_i;
	input wire hdu2exu_dbg_run2halt_i;
	input wire hdu2exu_dbg_halt2run_i;
	input wire hdu2exu_dbg_run_start_i;
	input wire [31:0] hdu2exu_dbg_new_pc_i;
	output wire [33:0] exu2tdu_imon_o;
	localparam [31:0] SCR1_TDU_TRIG_NUM = 2;
	localparam [31:0] SCR1_TDU_MTRIG_NUM = SCR1_TDU_TRIG_NUM;
	localparam [31:0] SCR1_TDU_ALLTRIG_NUM = SCR1_TDU_MTRIG_NUM + 1'b1;
	input wire [SCR1_TDU_ALLTRIG_NUM - 1:0] tdu2exu_ibrkpt_match_i;
	input wire tdu2exu_ibrkpt_exc_req_i;
	output wire [34:0] lsu2tdu_dmon_o;
	input wire tdu2lsu_ibrkpt_exc_req_i;
	input wire [1:0] tdu2lsu_dbrkpt_match_i;
	input wire tdu2lsu_dbrkpt_exc_req_i;
	output reg [SCR1_TDU_ALLTRIG_NUM - 1:0] exu2tdu_ibrkpt_ret_o;
	output wire exu2hdu_ibrkpt_hw_o;
	output wire exu2pipe_wfi_halted_o;
	output wire [31:0] exu2pipe_pc_curr_o;
	output wire [31:0] exu2csr_pc_next_o;
	output wire exu2ifu_pc_new_req_o;
	output reg [31:0] exu2ifu_pc_new_o;
	localparam SCR1_JUMP_MASK = 32'hfffffffe;
	wire exu_queue_vd;
	wire [74:0] exu_queue;
	wire exu_queue_barrier;
	wire dbg_run_start_npbuf;
	wire exu_queue_en;
	wire [31:0] exu_illegal_instr;
	wire ialu_rdy;
	wire ialu_vd;
	reg [31:0] ialu_main_op1;
	reg [31:0] ialu_main_op2;
	wire [31:0] ialu_main_res;
	reg [31:0] ialu_addr_op1;
	reg [31:0] ialu_addr_op2;
	wire [31:0] ialu_addr_res;
	wire ialu_cmp;
	wire exu_exc_req;
	reg exu_exc_req_ff;
	wire exu_exc_req_next;
	reg [3:0] exc_code;
	reg [31:0] exc_trap_val;
	wire instr_fault_rvi_hi;
	wire wfi_halt_cond;
	wire wfi_run_req;
	wire wfi_halt_req;
	reg wfi_run_start_ff;
	wire wfi_run_start_next;
	wire wfi_halted_upd;
	reg wfi_halted_ff;
	wire wfi_halted_next;
	reg [3:0] init_pc_v;
	wire init_pc;
	wire [31:0] inc_pc;
	wire branch_taken;
	wire jb_taken;
	wire [31:0] jb_new_pc;
	wire pc_curr_upd;
	reg [31:0] pc_curr_ff;
	wire [31:0] pc_curr_next;
	wire lsu_req;
	wire lsu_rdy;
	wire [31:0] lsu_l_data;
	wire lsu_exc_req;
	wire [3:0] lsu_exc_code;
	reg exu_rdy;
	wire mprf_rs1_req;
	wire mprf_rs2_req;
	wire [4:0] mprf_rs1_addr;
	wire [4:0] mprf_rs2_addr;
	reg csr_access_ff;
	wire csr_access_next;
	wire csr_access_init;
	assign dbg_run_start_npbuf = hdu2exu_dbg_run_start_i & ~hdu2exu_pbuf_fetch_i;
	assign exu_queue_barrier = ((wfi_halted_ff | wfi_run_start_ff) | hdu2exu_dbg_halted_i) | dbg_run_start_npbuf;
	assign exu_queue_vd = idu2exu_req_i & ~exu_queue_barrier;
	assign exu_queue = idu2exu_cmd_i;
	function automatic [4:0] sv2v_cast_8B244;
		input reg [4:0] inp;
		sv2v_cast_8B244 = inp;
	endfunction
	assign ialu_vd = (exu_queue_vd & (exu_queue[72-:5] != sv2v_cast_8B244(1'sb0))) & ~tdu2exu_ibrkpt_exc_req_i;
	function automatic [0:0] sv2v_cast_EFCFF;
		input reg [0:0] inp;
		sv2v_cast_EFCFF = inp;
	endfunction
	always @(*) begin
		if (~ialu_vd) begin
			ialu_main_op1 = 1'sb0;
			ialu_main_op2 = 1'sb0;
		end
		else if (exu_queue[73-:1] == sv2v_cast_EFCFF(1)) begin
			ialu_main_op1 = mprf2exu_rs1_data_i;
			ialu_main_op2 = mprf2exu_rs2_data_i;
		end
		else begin
			ialu_main_op1 = mprf2exu_rs1_data_i;
			ialu_main_op2 = exu_queue[36-:32];
		end
	end
	function automatic [0:0] sv2v_cast_64327;
		input reg [0:0] inp;
		sv2v_cast_64327 = inp;
	endfunction
	always @(*) begin
		if (exu_queue[67-:1] == sv2v_cast_64327(1)) begin
			ialu_addr_op1 = mprf2exu_rs1_data_i;
			ialu_addr_op2 = exu_queue[36-:32];
		end
		else begin
			ialu_addr_op1 = pc_curr_ff;
			ialu_addr_op2 = exu_queue[36-:32];
		end
	end
	scr1_pipe_ialu i_ialu(
		.clk(clk),
		.rst_n(rst_n),
		.exu2ialu_rvm_cmd_vd_i(ialu_vd),
		.ialu2exu_rvm_res_rdy_o(ialu_rdy),
		.exu2ialu_main_op1_i(ialu_main_op1),
		.exu2ialu_main_op2_i(ialu_main_op2),
		.exu2ialu_cmd_i(exu_queue[72-:5]),
		.ialu2exu_main_res_o(ialu_main_res),
		.ialu2exu_cmp_res_o(ialu_cmp),
		.exu2ialu_addr_op1_i(ialu_addr_op1),
		.exu2ialu_addr_op2_i(ialu_addr_op2),
		.ialu2exu_addr_res_o(ialu_addr_res)
	);
	assign exu_exc_req = exu_queue_vd & (((exu_queue[4] | lsu_exc_req) | csr2exu_rw_exc_i) | exu2hdu_ibrkpt_hw_o);
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			exu_exc_req_ff <= 1'b0;
		else
			exu_exc_req_ff <= exu_exc_req_next;
	assign exu_exc_req_next = (hdu2exu_dbg_halt2run_i ? 1'b0 : exu_exc_req);
	function automatic [3:0] sv2v_cast_92043;
		input reg [3:0] inp;
		sv2v_cast_92043 = inp;
	endfunction
	always @(*) begin
		exc_code = sv2v_cast_92043(4'd11);
		case (1'b1)
			exu2hdu_ibrkpt_hw_o: exc_code = sv2v_cast_92043(4'd3);
			exu_queue[4]: exc_code = exu_queue[3-:SCR1_EXC_CODE_WIDTH_E];
			lsu_exc_req: exc_code = lsu_exc_code;
			csr2exu_rw_exc_i: exc_code = sv2v_cast_92043(4'd2);
			default: exc_code = sv2v_cast_92043(4'd11);
		endcase
	end
	assign instr_fault_rvi_hi = exu_queue[74];
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	assign exu_illegal_instr = {exu2csr_rw_addr_o, sv2v_cast_5(exu_queue[51-:5]), exu_queue[19:17], sv2v_cast_5(exu_queue[41-:5]), 7'b1110011};
	always @(*) begin
		exc_trap_val = 1'sb0;
		case (exc_code)
			sv2v_cast_92043(4'd1): exc_trap_val = (instr_fault_rvi_hi ? inc_pc : pc_curr_ff);
			sv2v_cast_92043(4'd2): exc_trap_val = (exu_queue[4] ? exu_queue[36-:32] : exu_illegal_instr);
			sv2v_cast_92043(4'd3):
				case (1'b1)
					tdu2exu_ibrkpt_exc_req_i: exc_trap_val = pc_curr_ff;
					tdu2lsu_dbrkpt_exc_req_i: exc_trap_val = ialu_addr_res;
					default: exc_trap_val = 1'sb0;
				endcase
			sv2v_cast_92043(4'd4), sv2v_cast_92043(4'd5), sv2v_cast_92043(4'd6), sv2v_cast_92043(4'd7): exc_trap_val = ialu_addr_res;
			default: exc_trap_val = 1'sb0;
		endcase
	end
	assign wfi_halt_cond = (((~csr2exu_ip_ie_i & ((exu_queue_vd & exu_queue[52]) | wfi_run_start_ff)) & ~hdu2exu_no_commit_i) & ~hdu2exu_dmode_sstep_en_i) & ~hdu2exu_dbg_run2halt_i;
	assign wfi_halt_req = ~wfi_halted_ff & wfi_halt_cond;
	assign wfi_run_req = wfi_halted_ff & (csr2exu_ip_ie_i | hdu2exu_dbg_halt2run_i);
	always @(negedge rst_n or posedge clk_alw_on)
		if (~rst_n)
			wfi_run_start_ff <= 1'b0;
		else
			wfi_run_start_ff <= wfi_run_start_next;
	assign wfi_run_start_next = (wfi_halted_ff & csr2exu_ip_ie_i) & ~exu2csr_take_irq_o;
	assign wfi_halted_upd = wfi_halt_req | wfi_run_req;
	always @(negedge rst_n or posedge clk_alw_on)
		if (~rst_n)
			wfi_halted_ff <= 1'b0;
		else if (wfi_halted_upd)
			wfi_halted_ff <= wfi_halted_next;
	assign wfi_halted_next = wfi_halt_req | ~wfi_run_req;
	assign exu2pipe_wfi_run2halt_o = wfi_halt_req;
	assign exu2pipe_wfi_halted_o = wfi_halted_ff;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			init_pc_v <= 1'sb0;
		else if (~&init_pc_v)
			init_pc_v <= {init_pc_v[2:0], 1'b1};
	assign init_pc = ~init_pc_v[3] & init_pc_v[2];
	assign pc_curr_upd = ((exu2pipe_instret_o | exu2csr_take_irq_o) | dbg_run_start_npbuf) & (~hdu2exu_pc_advmt_dsbl_i & ~hdu2exu_no_commit_i);
	localparam [31:0] SCR1_ARCH_RST_VECTOR = 'h200;
	localparam [31:0] SCR1_RST_VECTOR = SCR1_ARCH_RST_VECTOR;
	always @(negedge rst_n or posedge clk)
		if (~rst_n)
			pc_curr_ff <= SCR1_RST_VECTOR;
		else if (pc_curr_upd)
			pc_curr_ff <= pc_curr_next;
	assign inc_pc = pc_curr_ff + (exu_queue[74] ? 32'd2 : 32'd4);
	assign pc_curr_next = (exu2ifu_pc_new_req_o ? exu2ifu_pc_new_o : (inc_pc[6] ^ pc_curr_ff[6] ? inc_pc : {pc_curr_ff[31:6], inc_pc[5:0]}));
	always @(*) begin
		exu2ifu_pc_new_o = ialu_addr_res & SCR1_JUMP_MASK;
		case (1'b1)
			init_pc: exu2ifu_pc_new_o = SCR1_RST_VECTOR;
			exu2csr_take_exc_o, exu2csr_take_irq_o, exu2csr_mret_instr_o: exu2ifu_pc_new_o = csr2exu_new_pc_i;
			dbg_run_start_npbuf: exu2ifu_pc_new_o = hdu2exu_dbg_new_pc_i;
			wfi_run_start_ff: exu2ifu_pc_new_o = pc_curr_ff;
			exu_queue[53]: exu2ifu_pc_new_o = inc_pc;
			default: exu2ifu_pc_new_o = ialu_addr_res & SCR1_JUMP_MASK;
		endcase
	end
	assign exu2ifu_pc_new_req_o = ((((((init_pc | exu2csr_take_irq_o) | exu2csr_take_exc_o) | (exu2csr_mret_instr_o & ~csr2exu_mstatus_mie_up_i)) | (exu_queue_vd & exu_queue[53])) | (wfi_run_start_ff & clk_pipe_en)) | dbg_run_start_npbuf) | (exu_queue_vd & jb_taken);
	assign branch_taken = exu_queue[55] & ialu_cmp;
	assign jb_taken = exu_queue[56] | branch_taken;
	assign jb_new_pc = ialu_addr_res & SCR1_JUMP_MASK;
	assign exu2csr_pc_next_o = (~exu_queue_vd ? pc_curr_ff : (jb_taken ? jb_new_pc : inc_pc));
	assign exu2pipe_pc_curr_o = pc_curr_ff;
	function automatic [3:0] sv2v_cast_5290E;
		input reg [3:0] inp;
		sv2v_cast_5290E = inp;
	endfunction
	assign lsu_req = (exu_queue[66-:4] != sv2v_cast_5290E(1'sb0)) & exu_queue_vd;
	scr1_pipe_lsu i_lsu(
		.rst_n(rst_n),
		.clk(clk),
		.exu2lsu_req_i(lsu_req),
		.exu2lsu_cmd_i(exu_queue[66-:4]),
		.exu2lsu_addr_i(ialu_addr_res),
		.exu2lsu_sdata_i(mprf2exu_rs2_data_i),
		.lsu2exu_rdy_o(lsu_rdy),
		.lsu2exu_ldata_o(lsu_l_data),
		.lsu2exu_exc_o(lsu_exc_req),
		.lsu2exu_exc_code_o(lsu_exc_code),
		.lsu2tdu_dmon_o(lsu2tdu_dmon_o),
		.tdu2lsu_ibrkpt_exc_req_i(tdu2lsu_ibrkpt_exc_req_i),
		.tdu2lsu_dbrkpt_exc_req_i(tdu2lsu_dbrkpt_exc_req_i),
		.lsu2dmem_req_o(exu2dmem_req_o),
		.lsu2dmem_cmd_o(exu2dmem_cmd_o),
		.lsu2dmem_width_o(exu2dmem_width_o),
		.lsu2dmem_addr_o(exu2dmem_addr_o),
		.lsu2dmem_wdata_o(exu2dmem_wdata_o),
		.dmem2lsu_req_ack_i(dmem2exu_req_ack_i),
		.dmem2lsu_rdata_i(dmem2exu_rdata_i),
		.dmem2lsu_resp_i(dmem2exu_resp_i)
	);
	always @(*) begin
		exu_rdy = 1'b1;
		case (1'b1)
			lsu_req: exu_rdy = lsu_rdy | lsu_exc_req;
			ialu_vd: exu_rdy = ialu_rdy;
			csr2exu_mstatus_mie_up_i: exu_rdy = 1'b0;
			default: exu_rdy = 1'b1;
		endcase
	end
	assign exu2pipe_init_pc_o = init_pc;
	assign exu2idu_rdy_o = exu_rdy & ~exu_queue_barrier;
	assign exu2pipe_exu_busy_o = exu_queue_vd & ~exu_rdy;
	assign exu2pipe_instret_o = exu_queue_vd & exu_rdy;
	assign exu2csr_instret_no_exc_o = exu2pipe_instret_o & ~exu_exc_req;
	assign exu2pipe_exc_req_o = (exu_queue_vd ? exu_exc_req : exu_exc_req_ff);
	assign exu2pipe_brkpt_o = exu_queue_vd & (exu_queue[3-:SCR1_EXC_CODE_WIDTH_E] == sv2v_cast_92043(4'd3));
	assign exu2hdu_ibrkpt_hw_o = tdu2exu_ibrkpt_exc_req_i | tdu2lsu_dbrkpt_exc_req_i;
	assign mprf_rs1_req = exu_queue_vd & idu2exu_use_rs1_i;
	assign mprf_rs2_req = exu_queue_vd & idu2exu_use_rs2_i;
	assign mprf_rs1_addr = exu_queue[51:47];
	assign mprf_rs2_addr = exu_queue[46:42];
	assign exu2mprf_rs1_addr_o = (mprf_rs1_req ? mprf_rs1_addr[4:0] : {5 {1'sb0}});
	assign exu2mprf_rs2_addr_o = (mprf_rs2_req ? mprf_rs2_addr[4:0] : {5 {1'sb0}});
	function automatic [2:0] sv2v_cast_2C11F;
		input reg [2:0] inp;
		sv2v_cast_2C11F = inp;
	endfunction
	function automatic [2:0] sv2v_cast_4D524;
		input reg [2:0] inp;
		sv2v_cast_4D524 = inp;
	endfunction
	assign exu2mprf_w_req_o = ((((exu_queue[59-:3] != sv2v_cast_2C11F(1'sb0)) & exu_queue_vd) & ~exu_exc_req) & ~hdu2exu_no_commit_i) & (exu_queue[59-:3] == sv2v_cast_4D524({32 {1'sb0}} + 6) ? csr_access_init : exu_rdy);
	assign exu2mprf_rd_addr_o = sv2v_cast_5(exu_queue[41-:5]);
	always @(*) begin
		exu2mprf_rd_data_o = ialu_main_res;
		case (exu_queue[59-:3])
			sv2v_cast_4D524({32 {1'sb0}} + 2): exu2mprf_rd_data_o = ialu_addr_res;
			sv2v_cast_4D524({32 {1'sb0}} + 3): exu2mprf_rd_data_o = exu_queue[36-:32];
			sv2v_cast_4D524({32 {1'sb0}} + 4): exu2mprf_rd_data_o = inc_pc;
			sv2v_cast_4D524({32 {1'sb0}} + 5): exu2mprf_rd_data_o = lsu_l_data;
			sv2v_cast_4D524({32 {1'sb0}} + 6): exu2mprf_rd_data_o = csr2exu_r_data_i;
			default: exu2mprf_rd_data_o = ialu_main_res;
		endcase
	end
	function automatic [1:0] sv2v_cast_999B9;
		input reg [1:0] inp;
		sv2v_cast_999B9 = inp;
	endfunction
	always @(*) begin
		if (~exu_queue_vd | tdu2exu_ibrkpt_exc_req_i) begin
			exu2csr_r_req_o = 1'b0;
			exu2csr_w_req_o = 1'b0;
		end
		else
			case (exu_queue[61-:2])
				sv2v_cast_999B9({32 {1'sb0}} + 1): begin
					exu2csr_r_req_o = |exu_queue[41-:5];
					exu2csr_w_req_o = csr_access_init;
				end
				sv2v_cast_999B9({32 {1'sb0}} + 2), sv2v_cast_999B9({32 {1'sb0}} + 3): begin
					exu2csr_r_req_o = 1'b1;
					exu2csr_w_req_o = |exu_queue[51-:5] & csr_access_init;
				end
				default: begin
					exu2csr_r_req_o = 1'b0;
					exu2csr_w_req_o = 1'b0;
				end
			endcase
	end
	assign exu2csr_w_cmd_o = exu_queue[61-:2];
	assign exu2csr_rw_addr_o = exu_queue[16:5];
	function automatic [0:0] sv2v_cast_E449B;
		input reg [0:0] inp;
		sv2v_cast_E449B = inp;
	endfunction
	assign exu2csr_w_data_o = (exu_queue[62-:1] == sv2v_cast_E449B(1) ? mprf2exu_rs1_data_i : {1'sb0, exu_queue[51-:5]});
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			csr_access_ff <= 1'd0;
		else
			csr_access_ff <= csr_access_next;
	assign csr_access_next = (csr_access_init & csr2exu_mstatus_mie_up_i ? 1'd1 : 1'd0);
	assign csr_access_init = csr_access_ff == 1'd0;
	assign exu2csr_take_exc_o = exu_exc_req & ~hdu2exu_dbg_halted_i;
	assign exu2csr_exc_code_o = exc_code;
	assign exu2csr_trap_val_o = exc_trap_val;
	assign exu2csr_take_irq_o = (((csr2exu_irq_i & ~exu2pipe_exu_busy_o) & ~hdu2exu_irq_dsbl_i) & ~hdu2exu_dbg_halted_i) & clk_pipe_en;
	assign exu2csr_mret_instr_o = ((exu_queue_vd & exu_queue[54]) & ~tdu2exu_ibrkpt_exc_req_i) & ~hdu2exu_dbg_halted_i;
	assign exu2csr_mret_update_o = exu2csr_mret_instr_o & csr_access_init;
	assign exu2tdu_imon_o[33] = exu_queue_vd;
	assign exu2tdu_imon_o[32] = exu2pipe_instret_o;
	assign exu2tdu_imon_o[31-:32] = pc_curr_ff;
	always @(*) begin
		exu2tdu_ibrkpt_ret_o = 1'sb0;
		if (exu_queue_vd) begin
			exu2tdu_ibrkpt_ret_o = tdu2exu_ibrkpt_match_i;
			if (lsu_req)
				exu2tdu_ibrkpt_ret_o[1:0] = exu2tdu_ibrkpt_ret_o[1:0] | tdu2lsu_dbrkpt_match_i;
		end
	end
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_ialu (
	clk,
	rst_n,
	exu2ialu_rvm_cmd_vd_i,
	ialu2exu_rvm_res_rdy_o,
	exu2ialu_main_op1_i,
	exu2ialu_main_op2_i,
	exu2ialu_cmd_i,
	ialu2exu_main_res_o,
	ialu2exu_cmp_res_o,
	exu2ialu_addr_op1_i,
	exu2ialu_addr_op2_i,
	ialu2exu_addr_res_o
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire exu2ialu_rvm_cmd_vd_i;
	output reg ialu2exu_rvm_res_rdy_o;
	input wire [31:0] exu2ialu_main_op1_i;
	input wire [31:0] exu2ialu_main_op2_i;
	localparam SCR1_IALU_CMD_ALL_NUM_E = 23;
	localparam SCR1_IALU_CMD_WIDTH_E = 5;
	input wire [4:0] exu2ialu_cmd_i;
	output reg [31:0] ialu2exu_main_res_o;
	output reg ialu2exu_cmp_res_o;
	input wire [31:0] exu2ialu_addr_op1_i;
	input wire [31:0] exu2ialu_addr_op2_i;
	output wire [31:0] ialu2exu_addr_res_o;
	localparam SCR1_MUL_WIDTH = 32;
	localparam SCR1_MUL_RES_WIDTH = 64;
	localparam SCR1_MDU_SUM_WIDTH = 33;
	localparam SCR1_DIV_WIDTH = 1;
	localparam SCR1_DIV_CNT_INIT = 32'b00000000000000000000000000000001 << 30;
	reg [32:0] main_sum_res;
	reg [3:0] main_sum_flags;
	reg main_sum_pos_ovflw;
	reg main_sum_neg_ovflw;
	wire main_ops_diff_sgn;
	wire main_ops_non_zero;
	wire ialu_cmd_shft;
	reg signed [31:0] shft_op1;
	reg [4:0] shft_op2;
	wire [1:0] shft_cmd;
	reg [31:0] shft_res;
	wire mdu_cmd_is_iter;
	wire mdu_iter_req;
	wire mdu_iter_rdy;
	wire mdu_corr_req;
	wire div_corr_req;
	wire rem_corr_req;
	reg [1:0] mdu_fsm_ff;
	reg [1:0] mdu_fsm_next;
	wire mdu_fsm_idle;
	wire mdu_fsm_corr;
	wire [1:0] mdu_cmd;
	wire mdu_cmd_mul;
	wire mdu_cmd_div;
	wire [1:0] mul_cmd;
	wire mul_cmd_hi;
	wire [1:0] div_cmd;
	wire div_cmd_div;
	wire div_cmd_rem;
	wire mul_op1_is_sgn;
	wire mul_op2_is_sgn;
	wire mul_op1_sgn;
	wire mul_op2_sgn;
	wire signed [32:0] mul_op1;
	wire signed [SCR1_MUL_WIDTH:0] mul_op2;
	wire signed [63:0] mul_res;
	wire div_ops_are_sgn;
	wire div_op1_is_neg;
	wire div_op2_is_neg;
	reg div_res_rem_c;
	reg [31:0] div_res_rem;
	reg [31:0] div_res_quo;
	reg div_quo_bit;
	wire div_dvdnd_lo_upd;
	reg [31:0] div_dvdnd_lo_ff;
	wire [31:0] div_dvdnd_lo_next;
	reg mdu_sum_sub;
	reg signed [32:0] mdu_sum_op1;
	reg signed [32:0] mdu_sum_op2;
	reg signed [32:0] mdu_sum_res;
	wire mdu_iter_cnt_en;
	reg [31:0] mdu_iter_cnt;
	wire [31:0] mdu_iter_cnt_next;
	wire mdu_res_upd;
	reg mdu_res_c_ff;
	wire mdu_res_c_next;
	reg [31:0] mdu_res_hi_ff;
	wire [31:0] mdu_res_hi_next;
	reg [31:0] mdu_res_lo_ff;
	wire [31:0] mdu_res_lo_next;
	function automatic [4:0] sv2v_cast_9DDEB;
		input reg [4:0] inp;
		sv2v_cast_9DDEB = inp;
	endfunction
	always @(*) begin
		main_sum_res = (exu2ialu_cmd_i != sv2v_cast_9DDEB({32 {1'sb0}} + 4) ? {1'b0, exu2ialu_main_op1_i} - {1'b0, exu2ialu_main_op2_i} : {1'b0, exu2ialu_main_op1_i} + {1'b0, exu2ialu_main_op2_i});
		main_sum_pos_ovflw = (~exu2ialu_main_op1_i[31] & exu2ialu_main_op2_i[31]) & main_sum_res[31];
		main_sum_neg_ovflw = (exu2ialu_main_op1_i[31] & ~exu2ialu_main_op2_i[31]) & ~main_sum_res[31];
		main_sum_flags[0] = main_sum_res[32];
		main_sum_flags[3] = ~|main_sum_res[31:0];
		main_sum_flags[2] = main_sum_res[31];
		main_sum_flags[1] = main_sum_pos_ovflw | main_sum_neg_ovflw;
	end
	assign ialu2exu_addr_res_o = exu2ialu_addr_op1_i + exu2ialu_addr_op2_i;
	assign ialu_cmd_shft = ((exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 12)) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 13))) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 14));
	assign shft_cmd = (ialu_cmd_shft ? {exu2ialu_cmd_i != sv2v_cast_9DDEB({32 {1'sb0}} + 12), exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 14)} : 2'b00);
	always @(*) begin
		shft_op1 = exu2ialu_main_op1_i;
		shft_op2 = exu2ialu_main_op2_i[4:0];
		case (shft_cmd)
			2'b10: shft_res = shft_op1 >> shft_op2;
			2'b11: shft_res = shft_op1 >>> shft_op2;
			default: shft_res = shft_op1 << shft_op2;
		endcase
	end
	assign mdu_cmd_div = (((exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 19)) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 20))) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 21))) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 22));
	assign mdu_cmd_mul = (((exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 15)) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 18))) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 16))) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 17));
	assign mdu_cmd = (mdu_cmd_div ? 2'd2 : (mdu_cmd_mul ? 2'd1 : 2'd0));
	assign main_ops_non_zero = |exu2ialu_main_op1_i & |exu2ialu_main_op2_i;
	assign main_ops_diff_sgn = exu2ialu_main_op1_i[31] ^ exu2ialu_main_op2_i[31];
	assign mdu_cmd_is_iter = mdu_cmd_div;
	assign mdu_iter_req = (mdu_cmd_is_iter ? main_ops_non_zero & mdu_fsm_idle : 1'b0);
	assign mdu_iter_rdy = mdu_iter_cnt[0];
	assign div_cmd_div = div_cmd == 2'b00;
	assign div_cmd_rem = div_cmd[1];
	assign div_corr_req = div_cmd_div & main_ops_diff_sgn;
	assign rem_corr_req = (div_cmd_rem & |div_res_rem) & (div_op1_is_neg ^ div_res_rem_c);
	assign mdu_corr_req = mdu_cmd_div & (div_corr_req | rem_corr_req);
	assign mdu_iter_cnt_en = exu2ialu_rvm_cmd_vd_i & ~ialu2exu_rvm_res_rdy_o;
	always @(posedge clk)
		if (mdu_iter_cnt_en)
			mdu_iter_cnt <= mdu_iter_cnt_next;
	assign mdu_iter_cnt_next = (~mdu_fsm_idle ? mdu_iter_cnt >> 1 : (mdu_cmd_div ? SCR1_DIV_CNT_INIT : mdu_iter_cnt));
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			mdu_fsm_ff <= 2'd0;
		else
			mdu_fsm_ff <= mdu_fsm_next;
	always @(*) begin
		mdu_fsm_next = 2'd0;
		if (exu2ialu_rvm_cmd_vd_i)
			case (mdu_fsm_ff)
				2'd0: mdu_fsm_next = (mdu_iter_req ? 2'd1 : 2'd0);
				2'd1: mdu_fsm_next = (~mdu_iter_rdy ? 2'd1 : (mdu_corr_req ? 2'd2 : 2'd0));
				2'd2: mdu_fsm_next = 2'd0;
			endcase
	end
	assign mdu_fsm_idle = mdu_fsm_ff == 2'd0;
	assign mdu_fsm_corr = mdu_fsm_ff == 2'd2;
	assign mul_cmd = {(exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 16)) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 17)), (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 16)) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 18))};
	assign mul_cmd_hi = |mul_cmd;
	assign mul_op1_is_sgn = ~&mul_cmd;
	assign mul_op2_is_sgn = ~mul_cmd[1];
	assign mul_op1_sgn = mul_op1_is_sgn & exu2ialu_main_op1_i[31];
	assign mul_op2_sgn = mul_op2_is_sgn & exu2ialu_main_op2_i[31];
	assign mul_op1 = (mdu_cmd_mul ? $signed({mul_op1_sgn, exu2ialu_main_op1_i}) : {33 {1'sb0}});
	assign mul_op2 = (mdu_cmd_mul ? $signed({mul_op2_sgn, exu2ialu_main_op2_i}) : {33 {1'sb0}});
	assign mul_res = (mdu_cmd_mul ? mul_op1 * mul_op2 : $signed(1'sb0));
	assign div_cmd = {(exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 21)) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 22)), (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 22)) | (exu2ialu_cmd_i == sv2v_cast_9DDEB({32 {1'sb0}} + 20))};
	assign div_ops_are_sgn = ~div_cmd[0];
	assign div_op1_is_neg = div_ops_are_sgn & exu2ialu_main_op1_i[31];
	assign div_op2_is_neg = div_ops_are_sgn & exu2ialu_main_op2_i[31];
	always @(*) begin
		div_res_rem_c = 1'sb0;
		div_res_rem = 1'sb0;
		div_res_quo = 1'sb0;
		div_quo_bit = 1'b0;
		if (mdu_cmd_div & ~mdu_fsm_corr) begin
			div_res_rem_c = mdu_sum_res[32];
			div_res_rem = mdu_sum_res[31:0];
			div_quo_bit = ~(div_op1_is_neg ^ div_res_rem_c) | (div_op1_is_neg & ({mdu_sum_res, div_dvdnd_lo_next} == {65 {1'sb0}}));
			div_res_quo = (mdu_fsm_idle ? {1'sb0, div_quo_bit} : {mdu_res_lo_ff[30:0], div_quo_bit});
		end
	end
	assign div_dvdnd_lo_upd = exu2ialu_rvm_cmd_vd_i & ~ialu2exu_rvm_res_rdy_o;
	always @(posedge clk)
		if (div_dvdnd_lo_upd)
			div_dvdnd_lo_ff <= div_dvdnd_lo_next;
	assign div_dvdnd_lo_next = (~mdu_cmd_div | mdu_fsm_corr ? {32 {1'sb0}} : (mdu_fsm_idle ? exu2ialu_main_op1_i << 1 : div_dvdnd_lo_ff << 1));
	always @(*) begin
		mdu_sum_sub = 1'b0;
		mdu_sum_op1 = 1'sb0;
		mdu_sum_op2 = 1'sb0;
		case (mdu_cmd)
			2'd2: begin : sv2v_autoblock_1
				reg sgn;
				reg inv;
				sgn = (mdu_fsm_corr ? div_op1_is_neg ^ mdu_res_c_ff : (mdu_fsm_idle ? 1'b0 : ~mdu_res_lo_ff[0]));
				inv = div_ops_are_sgn & main_ops_diff_sgn;
				mdu_sum_sub = ~inv ^ sgn;
				mdu_sum_op1 = (mdu_fsm_corr ? $signed({1'b0, mdu_res_hi_ff}) : (mdu_fsm_idle ? $signed({div_op1_is_neg, exu2ialu_main_op1_i[31]}) : $signed({mdu_res_hi_ff, div_dvdnd_lo_ff[31]})));
				mdu_sum_op2 = $signed({div_op2_is_neg, exu2ialu_main_op2_i});
			end
			default:
				;
		endcase
		mdu_sum_res = (mdu_sum_sub ? mdu_sum_op1 - mdu_sum_op2 : mdu_sum_op1 + mdu_sum_op2);
	end
	assign mdu_res_upd = exu2ialu_rvm_cmd_vd_i & ~ialu2exu_rvm_res_rdy_o;
	always @(posedge clk)
		if (mdu_res_upd) begin
			mdu_res_c_ff <= mdu_res_c_next;
			mdu_res_hi_ff <= mdu_res_hi_next;
			mdu_res_lo_ff <= mdu_res_lo_next;
		end
	assign mdu_res_c_next = (mdu_cmd_div ? div_res_rem_c : mdu_res_c_ff);
	assign mdu_res_hi_next = (mdu_cmd_div ? div_res_rem : mdu_res_hi_ff);
	assign mdu_res_lo_next = (mdu_cmd_div ? div_res_quo : mdu_res_lo_ff);
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin
		ialu2exu_main_res_o = 1'sb0;
		ialu2exu_cmp_res_o = 1'b0;
		ialu2exu_rvm_res_rdy_o = 1'b1;
		case (exu2ialu_cmd_i)
			sv2v_cast_9DDEB({32 {1'sb0}} + 1): ialu2exu_main_res_o = exu2ialu_main_op1_i & exu2ialu_main_op2_i;
			sv2v_cast_9DDEB({32 {1'sb0}} + 2): ialu2exu_main_res_o = exu2ialu_main_op1_i | exu2ialu_main_op2_i;
			sv2v_cast_9DDEB({32 {1'sb0}} + 3): ialu2exu_main_res_o = exu2ialu_main_op1_i ^ exu2ialu_main_op2_i;
			sv2v_cast_9DDEB({32 {1'sb0}} + 4): ialu2exu_main_res_o = main_sum_res[31:0];
			sv2v_cast_9DDEB({32 {1'sb0}} + 5): ialu2exu_main_res_o = main_sum_res[31:0];
			sv2v_cast_9DDEB({32 {1'sb0}} + 6): begin
				ialu2exu_main_res_o = sv2v_cast_32(main_sum_flags[2] ^ main_sum_flags[1]);
				ialu2exu_cmp_res_o = main_sum_flags[2] ^ main_sum_flags[1];
			end
			sv2v_cast_9DDEB({32 {1'sb0}} + 7): begin
				ialu2exu_main_res_o = sv2v_cast_32(main_sum_flags[0]);
				ialu2exu_cmp_res_o = main_sum_flags[0];
			end
			sv2v_cast_9DDEB({32 {1'sb0}} + 8): begin
				ialu2exu_main_res_o = sv2v_cast_32(main_sum_flags[3]);
				ialu2exu_cmp_res_o = main_sum_flags[3];
			end
			sv2v_cast_9DDEB({32 {1'sb0}} + 9): begin
				ialu2exu_main_res_o = sv2v_cast_32(~main_sum_flags[3]);
				ialu2exu_cmp_res_o = ~main_sum_flags[3];
			end
			sv2v_cast_9DDEB({32 {1'sb0}} + 10): begin
				ialu2exu_main_res_o = sv2v_cast_32(~(main_sum_flags[2] ^ main_sum_flags[1]));
				ialu2exu_cmp_res_o = ~(main_sum_flags[2] ^ main_sum_flags[1]);
			end
			sv2v_cast_9DDEB({32 {1'sb0}} + 11): begin
				ialu2exu_main_res_o = sv2v_cast_32(~main_sum_flags[0]);
				ialu2exu_cmp_res_o = ~main_sum_flags[0];
			end
			sv2v_cast_9DDEB({32 {1'sb0}} + 12), sv2v_cast_9DDEB({32 {1'sb0}} + 13), sv2v_cast_9DDEB({32 {1'sb0}} + 14): ialu2exu_main_res_o = shft_res;
			sv2v_cast_9DDEB({32 {1'sb0}} + 15), sv2v_cast_9DDEB({32 {1'sb0}} + 16), sv2v_cast_9DDEB({32 {1'sb0}} + 17), sv2v_cast_9DDEB({32 {1'sb0}} + 18): ialu2exu_main_res_o = (mul_cmd_hi ? mul_res[63:32] : mul_res[31:0]);
			sv2v_cast_9DDEB({32 {1'sb0}} + 19), sv2v_cast_9DDEB({32 {1'sb0}} + 20), sv2v_cast_9DDEB({32 {1'sb0}} + 21), sv2v_cast_9DDEB({32 {1'sb0}} + 22):
				case (mdu_fsm_ff)
					2'd0: begin
						ialu2exu_main_res_o = (|exu2ialu_main_op2_i | div_cmd_rem ? exu2ialu_main_op1_i : {32 {1'sb1}});
						ialu2exu_rvm_res_rdy_o = ~mdu_iter_req;
					end
					2'd1: begin
						ialu2exu_main_res_o = (div_cmd_rem ? div_res_rem : div_res_quo);
						ialu2exu_rvm_res_rdy_o = mdu_iter_rdy & ~mdu_corr_req;
					end
					2'd2: begin
						ialu2exu_main_res_o = (div_cmd_rem ? mdu_sum_res[31:0] : -mdu_res_lo_ff[31:0]);
						ialu2exu_rvm_res_rdy_o = 1'b1;
					end
				endcase
			default:
				;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_idu (
	idu2ifu_rdy_o,
	ifu2idu_instr_i,
	ifu2idu_imem_err_i,
	ifu2idu_err_rvi_hi_i,
	ifu2idu_vd_i,
	idu2exu_req_o,
	idu2exu_cmd_o,
	idu2exu_use_rs1_o,
	idu2exu_use_rs2_o,
	exu2idu_rdy_i
);
	reg _sv2v_0;
	output wire idu2ifu_rdy_o;
	input wire [31:0] ifu2idu_instr_i;
	input wire ifu2idu_imem_err_i;
	input wire ifu2idu_err_rvi_hi_i;
	input wire ifu2idu_vd_i;
	output wire idu2exu_req_o;
	localparam SCR1_GPR_FIELD_WIDTH = 5;
	localparam SCR1_CSR_CMD_ALL_NUM_E = 4;
	localparam SCR1_CSR_CMD_WIDTH_E = 2;
	localparam SCR1_CSR_OP_ALL_NUM_E = 2;
	localparam SCR1_CSR_OP_WIDTH_E = 1;
	localparam [31:0] SCR1_EXC_CODE_WIDTH_E = 4;
	localparam SCR1_IALU_CMD_ALL_NUM_E = 23;
	localparam SCR1_IALU_CMD_WIDTH_E = 5;
	localparam SCR1_IALU_OP_ALL_NUM_E = 2;
	localparam SCR1_IALU_OP_WIDTH_E = 1;
	localparam SCR1_SUM2_OP_ALL_NUM_E = 2;
	localparam SCR1_SUM2_OP_WIDTH_E = 1;
	localparam SCR1_LSU_CMD_ALL_NUM_E = 9;
	localparam SCR1_LSU_CMD_WIDTH_E = 4;
	localparam SCR1_RD_WB_ALL_NUM_E = 7;
	localparam SCR1_RD_WB_WIDTH_E = 3;
	output reg [74:0] idu2exu_cmd_o;
	output reg idu2exu_use_rs1_o;
	output reg idu2exu_use_rs2_o;
	input wire exu2idu_rdy_i;
	localparam [4:0] SCR1_MPRF_ZERO_ADDR = 5'd0;
	localparam [4:0] SCR1_MPRF_RA_ADDR = 5'd1;
	localparam [4:0] SCR1_MPRF_SP_ADDR = 5'd2;
	wire [31:0] instr;
	wire [1:0] instr_type;
	wire [6:2] rvi_opcode;
	reg rvi_illegal;
	wire [2:0] funct3;
	wire [6:0] funct7;
	wire [11:0] funct12;
	wire [4:0] shamt;
	reg rvc_illegal;
	assign idu2ifu_rdy_o = exu2idu_rdy_i;
	assign idu2exu_req_o = ifu2idu_vd_i;
	assign instr = ifu2idu_instr_i;
	assign instr_type = instr[1:0];
	assign rvi_opcode = instr[6:2];
	assign funct3 = (instr_type == 2'b11 ? instr[14:12] : instr[15:13]);
	assign funct7 = instr[31:25];
	assign funct12 = instr[31:20];
	assign shamt = instr[24:20];
	function automatic [0:0] sv2v_cast_EFCFF;
		input reg [0:0] inp;
		sv2v_cast_EFCFF = inp;
	endfunction
	function automatic [4:0] sv2v_cast_305D4;
		input reg [4:0] inp;
		sv2v_cast_305D4 = inp;
	endfunction
	function automatic [0:0] sv2v_cast_64327;
		input reg [0:0] inp;
		sv2v_cast_64327 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_268FE;
		input reg [3:0] inp;
		sv2v_cast_268FE = inp;
	endfunction
	function automatic [0:0] sv2v_cast_E449B;
		input reg [0:0] inp;
		sv2v_cast_E449B = inp;
	endfunction
	function automatic [1:0] sv2v_cast_AF896;
		input reg [1:0] inp;
		sv2v_cast_AF896 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_FEE4F;
		input reg [2:0] inp;
		sv2v_cast_FEE4F = inp;
	endfunction
	function automatic [3:0] sv2v_cast_92043;
		input reg [3:0] inp;
		sv2v_cast_92043 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_4D524;
		input reg [2:0] inp;
		sv2v_cast_4D524 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_4A511;
		input reg [3:0] inp;
		sv2v_cast_4A511 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_9DDEB;
		input reg [4:0] inp;
		sv2v_cast_9DDEB = inp;
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [1:0] sv2v_cast_999B9;
		input reg [1:0] inp;
		sv2v_cast_999B9 = inp;
	endfunction
	always @(*) begin
		idu2exu_cmd_o[74] = 1'b0;
		idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
		idu2exu_cmd_o[72-:5] = sv2v_cast_305D4(1'sb0);
		idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
		idu2exu_cmd_o[66-:4] = sv2v_cast_268FE(1'sb0);
		idu2exu_cmd_o[62-:1] = sv2v_cast_E449B(1);
		idu2exu_cmd_o[61-:2] = sv2v_cast_AF896(1'sb0);
		idu2exu_cmd_o[59-:3] = sv2v_cast_FEE4F(1'sb0);
		idu2exu_cmd_o[56] = 1'b0;
		idu2exu_cmd_o[55] = 1'b0;
		idu2exu_cmd_o[54] = 1'b0;
		idu2exu_cmd_o[53] = 1'b0;
		idu2exu_cmd_o[52] = 1'b0;
		idu2exu_cmd_o[51-:5] = 1'sb0;
		idu2exu_cmd_o[46-:5] = 1'sb0;
		idu2exu_cmd_o[41-:5] = 1'sb0;
		idu2exu_cmd_o[36-:32] = 1'sb0;
		idu2exu_cmd_o[4] = 1'b0;
		idu2exu_cmd_o[3-:SCR1_EXC_CODE_WIDTH_E] = sv2v_cast_92043(4'd0);
		idu2exu_use_rs1_o = 1'b0;
		idu2exu_use_rs2_o = 1'b0;
		rvi_illegal = 1'b0;
		rvc_illegal = 1'b0;
		if (ifu2idu_imem_err_i) begin
			idu2exu_cmd_o[4] = 1'b1;
			idu2exu_cmd_o[3-:SCR1_EXC_CODE_WIDTH_E] = sv2v_cast_92043(4'd1);
			idu2exu_cmd_o[74] = ifu2idu_err_rvi_hi_i;
		end
		else
			case (instr_type)
				2'b11: begin
					idu2exu_cmd_o[51-:5] = instr[19:15];
					idu2exu_cmd_o[46-:5] = instr[24:20];
					idu2exu_cmd_o[41-:5] = instr[11:7];
					case (rvi_opcode)
						5'b00101: begin
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 2);
							idu2exu_cmd_o[36-:32] = {instr[31:12], 12'b000000000000};
						end
						5'b01101: begin
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 3);
							idu2exu_cmd_o[36-:32] = {instr[31:12], 12'b000000000000};
						end
						5'b11011: begin
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 4);
							idu2exu_cmd_o[56] = 1'b1;
							idu2exu_cmd_o[36-:32] = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
						end
						5'b00000: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 5);
							idu2exu_cmd_o[36-:32] = {{21 {instr[31]}}, instr[30:20]};
							case (funct3)
								3'b000: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 1);
								3'b001: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 2);
								3'b010: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 3);
								3'b100: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 4);
								3'b101: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 5);
								default: rvi_illegal = 1'b1;
							endcase
						end
						5'b01000: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_use_rs2_o = 1'b1;
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
							idu2exu_cmd_o[36-:32] = {{21 {instr[31]}}, instr[30:25], instr[11:7]};
							case (funct3)
								3'b000: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 6);
								3'b001: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 7);
								3'b010: idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 8);
								default: rvi_illegal = 1'b1;
							endcase
						end
						5'b01100: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_use_rs2_o = 1'b1;
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
							case (funct7)
								7'b0000000:
									case (funct3)
										3'b000: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 4);
										3'b001: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 12);
										3'b010: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 6);
										3'b011: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 7);
										3'b100: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 3);
										3'b101: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 13);
										3'b110: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 2);
										3'b111: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 1);
									endcase
								7'b0100000:
									case (funct3)
										3'b000: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 5);
										3'b101: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 14);
										default: rvi_illegal = 1'b1;
									endcase
								7'b0000001:
									case (funct3)
										3'b000: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 15);
										3'b001: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 18);
										3'b010: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 17);
										3'b011: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 16);
										3'b100: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 19);
										3'b101: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 20);
										3'b110: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 21);
										3'b111: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 22);
									endcase
								default: rvi_illegal = 1'b1;
							endcase
						end
						5'b00100: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_cmd_o[36-:32] = {{21 {instr[31]}}, instr[30:20]};
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
							case (funct3)
								3'b000: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 4);
								3'b010: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 6);
								3'b011: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 7);
								3'b100: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 3);
								3'b110: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 2);
								3'b111: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 1);
								3'b001:
									case (funct7)
										7'b0000000: begin
											idu2exu_cmd_o[36-:32] = sv2v_cast_32(shamt);
											idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 12);
										end
										default: rvi_illegal = 1'b1;
									endcase
								3'b101:
									case (funct7)
										7'b0000000: begin
											idu2exu_cmd_o[36-:32] = sv2v_cast_32(shamt);
											idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 13);
										end
										7'b0100000: begin
											idu2exu_cmd_o[36-:32] = sv2v_cast_32(shamt);
											idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 14);
										end
										default: rvi_illegal = 1'b1;
									endcase
							endcase
						end
						5'b00011:
							case (funct3)
								3'b000:
									if (~|{instr[31:28], instr[19:15], instr[11:7]})
										;
									else
										rvi_illegal = 1'b1;
								3'b001:
									if (~|{instr[31:15], instr[11:7]})
										idu2exu_cmd_o[53] = 1'b1;
									else
										rvi_illegal = 1'b1;
								default: rvi_illegal = 1'b1;
							endcase
						5'b11000: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_use_rs2_o = 1'b1;
							idu2exu_cmd_o[36-:32] = {{20 {instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
							idu2exu_cmd_o[55] = 1'b1;
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
							case (funct3)
								3'b000: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 8);
								3'b001: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 9);
								3'b100: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 6);
								3'b101: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 10);
								3'b110: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 7);
								3'b111: idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 11);
								default: rvi_illegal = 1'b1;
							endcase
						end
						5'b11001: begin
							idu2exu_use_rs1_o = 1'b1;
							case (funct3)
								3'b000: begin
									idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 4);
									idu2exu_cmd_o[56] = 1'b1;
									idu2exu_cmd_o[36-:32] = {{21 {instr[31]}}, instr[30:20]};
								end
								default: rvi_illegal = 1'b1;
							endcase
						end
						5'b11100: begin
							idu2exu_cmd_o[36-:32] = sv2v_cast_32({funct3, instr[31:20]});
							case (funct3)
								3'b000:
									case ({instr[19:15], instr[11:7]})
										10'd0:
											case (funct12)
												12'h000: begin
													idu2exu_cmd_o[4] = 1'b1;
													idu2exu_cmd_o[3-:SCR1_EXC_CODE_WIDTH_E] = sv2v_cast_92043(4'd11);
												end
												12'h001: begin
													idu2exu_cmd_o[4] = 1'b1;
													idu2exu_cmd_o[3-:SCR1_EXC_CODE_WIDTH_E] = sv2v_cast_92043(4'd3);
												end
												12'h302: idu2exu_cmd_o[54] = 1'b1;
												12'h105: idu2exu_cmd_o[52] = 1'b1;
												default: rvi_illegal = 1'b1;
											endcase
										default: rvi_illegal = 1'b1;
									endcase
								3'b001: begin
									idu2exu_use_rs1_o = 1'b1;
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 6);
									idu2exu_cmd_o[61-:2] = sv2v_cast_999B9({32 {1'sb0}} + 1);
									idu2exu_cmd_o[62-:1] = sv2v_cast_E449B(1);
								end
								3'b010: begin
									idu2exu_use_rs1_o = 1'b1;
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 6);
									idu2exu_cmd_o[61-:2] = sv2v_cast_999B9({32 {1'sb0}} + 2);
									idu2exu_cmd_o[62-:1] = sv2v_cast_E449B(1);
								end
								3'b011: begin
									idu2exu_use_rs1_o = 1'b1;
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 6);
									idu2exu_cmd_o[61-:2] = sv2v_cast_999B9({32 {1'sb0}} + 3);
									idu2exu_cmd_o[62-:1] = sv2v_cast_E449B(1);
								end
								3'b101: begin
									idu2exu_use_rs1_o = 1'b1;
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 6);
									idu2exu_cmd_o[61-:2] = sv2v_cast_999B9({32 {1'sb0}} + 1);
									idu2exu_cmd_o[62-:1] = sv2v_cast_E449B(0);
								end
								3'b110: begin
									idu2exu_use_rs1_o = 1'b1;
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 6);
									idu2exu_cmd_o[61-:2] = sv2v_cast_999B9({32 {1'sb0}} + 2);
									idu2exu_cmd_o[62-:1] = sv2v_cast_E449B(0);
								end
								3'b111: begin
									idu2exu_use_rs1_o = 1'b1;
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 6);
									idu2exu_cmd_o[61-:2] = sv2v_cast_999B9({32 {1'sb0}} + 3);
									idu2exu_cmd_o[62-:1] = sv2v_cast_E449B(0);
								end
								default: rvi_illegal = 1'b1;
							endcase
						end
						default: rvi_illegal = 1'b1;
					endcase
				end
				2'b00: begin
					idu2exu_cmd_o[74] = 1'b1;
					idu2exu_use_rs1_o = 1'b1;
					case (funct3)
						3'b000: begin
							if (~|instr[12:5])
								rvc_illegal = 1'b1;
							idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 4);
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
							idu2exu_cmd_o[51-:5] = SCR1_MPRF_SP_ADDR;
							idu2exu_cmd_o[41-:5] = {2'b01, instr[4:2]};
							idu2exu_cmd_o[36-:32] = {22'd0, instr[10:7], instr[12:11], instr[5], instr[6], 2'b00};
						end
						3'b010: begin
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
							idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 3);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 5);
							idu2exu_cmd_o[51-:5] = {2'b01, instr[9:7]};
							idu2exu_cmd_o[41-:5] = {2'b01, instr[4:2]};
							idu2exu_cmd_o[36-:32] = {25'd0, instr[5], instr[12:10], instr[6], 2'b00};
						end
						3'b110: begin
							idu2exu_use_rs2_o = 1'b1;
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
							idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 8);
							idu2exu_cmd_o[51-:5] = {2'b01, instr[9:7]};
							idu2exu_cmd_o[46-:5] = {2'b01, instr[4:2]};
							idu2exu_cmd_o[36-:32] = {25'd0, instr[5], instr[12:10], instr[6], 2'b00};
						end
						default: rvc_illegal = 1'b1;
					endcase
				end
				2'b01: begin
					idu2exu_cmd_o[74] = 1'b1;
					case (funct3)
						3'b000: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 4);
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
							idu2exu_cmd_o[51-:5] = instr[11:7];
							idu2exu_cmd_o[41-:5] = instr[11:7];
							idu2exu_cmd_o[36-:32] = {{27 {instr[12]}}, instr[6:2]};
						end
						3'b001: begin
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 4);
							idu2exu_cmd_o[56] = 1'b1;
							idu2exu_cmd_o[41-:5] = SCR1_MPRF_RA_ADDR;
							idu2exu_cmd_o[36-:32] = {{21 {instr[12]}}, instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};
						end
						3'b010: begin
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 3);
							idu2exu_cmd_o[41-:5] = instr[11:7];
							idu2exu_cmd_o[36-:32] = {{27 {instr[12]}}, instr[6:2]};
						end
						3'b011: begin
							if (~|{instr[12], instr[6:2]})
								rvc_illegal = 1'b1;
							if (instr[11:7] == SCR1_MPRF_SP_ADDR) begin
								idu2exu_use_rs1_o = 1'b1;
								idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 4);
								idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
								idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
								idu2exu_cmd_o[51-:5] = SCR1_MPRF_SP_ADDR;
								idu2exu_cmd_o[41-:5] = SCR1_MPRF_SP_ADDR;
								idu2exu_cmd_o[36-:32] = {{23 {instr[12]}}, instr[4:3], instr[5], instr[2], instr[6], 4'd0};
							end
							else begin
								idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 3);
								idu2exu_cmd_o[41-:5] = instr[11:7];
								idu2exu_cmd_o[36-:32] = {{15 {instr[12]}}, instr[6:2], 12'd0};
							end
						end
						3'b100: begin
							idu2exu_cmd_o[51-:5] = {2'b01, instr[9:7]};
							idu2exu_cmd_o[41-:5] = {2'b01, instr[9:7]};
							idu2exu_cmd_o[46-:5] = {2'b01, instr[4:2]};
							idu2exu_use_rs1_o = 1'b1;
							case (instr[11:10])
								2'b00: begin
									if (instr[12])
										rvc_illegal = 1'b1;
									idu2exu_cmd_o[36-:32] = {27'd0, instr[6:2]};
									idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 13);
									idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
								end
								2'b01: begin
									if (instr[12])
										rvc_illegal = 1'b1;
									idu2exu_cmd_o[36-:32] = {27'd0, instr[6:2]};
									idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 14);
									idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
								end
								2'b10: begin
									idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 1);
									idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
									idu2exu_cmd_o[36-:32] = {{27 {instr[12]}}, instr[6:2]};
								end
								2'b11: begin
									idu2exu_use_rs2_o = 1'b1;
									case ({instr[12], instr[6:5]})
										3'b000: begin
											idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 5);
											idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
											idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
										end
										3'b001: begin
											idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 3);
											idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
											idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
										end
										3'b010: begin
											idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 2);
											idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
											idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
										end
										3'b011: begin
											idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 1);
											idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
											idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
										end
										default: rvc_illegal = 1'b1;
									endcase
								end
							endcase
						end
						3'b101: begin
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
							idu2exu_cmd_o[56] = 1'b1;
							idu2exu_cmd_o[36-:32] = {{21 {instr[12]}}, instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};
						end
						3'b110: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_use_rs2_o = 1'b1;
							idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 8);
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
							idu2exu_cmd_o[55] = 1'b1;
							idu2exu_cmd_o[51-:5] = {2'b01, instr[9:7]};
							idu2exu_cmd_o[46-:5] = SCR1_MPRF_ZERO_ADDR;
							idu2exu_cmd_o[36-:32] = {{24 {instr[12]}}, instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};
						end
						3'b111: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_use_rs2_o = 1'b1;
							idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 9);
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(0);
							idu2exu_cmd_o[55] = 1'b1;
							idu2exu_cmd_o[51-:5] = {2'b01, instr[9:7]};
							idu2exu_cmd_o[46-:5] = SCR1_MPRF_ZERO_ADDR;
							idu2exu_cmd_o[36-:32] = {{24 {instr[12]}}, instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};
						end
					endcase
				end
				2'b10: begin
					idu2exu_cmd_o[74] = 1'b1;
					idu2exu_use_rs1_o = 1'b1;
					case (funct3)
						3'b000: begin
							if (instr[12])
								rvc_illegal = 1'b1;
							idu2exu_cmd_o[51-:5] = instr[11:7];
							idu2exu_cmd_o[41-:5] = instr[11:7];
							idu2exu_cmd_o[36-:32] = {27'd0, instr[6:2]};
							idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 12);
							idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(0);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
						end
						3'b010: begin
							if (~|instr[11:7])
								rvc_illegal = 1'b1;
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
							idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 3);
							idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 5);
							idu2exu_cmd_o[51-:5] = SCR1_MPRF_SP_ADDR;
							idu2exu_cmd_o[41-:5] = instr[11:7];
							idu2exu_cmd_o[36-:32] = {24'd0, instr[3:2], instr[12], instr[6:4], 2'b00};
						end
						3'b100:
							if (~instr[12]) begin
								if (|instr[6:2]) begin
									idu2exu_use_rs2_o = 1'b1;
									idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 4);
									idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
									idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
									idu2exu_cmd_o[51-:5] = SCR1_MPRF_ZERO_ADDR;
									idu2exu_cmd_o[46-:5] = instr[6:2];
									idu2exu_cmd_o[41-:5] = instr[11:7];
								end
								else begin
									if (~|instr[11:7])
										rvc_illegal = 1'b1;
									idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
									idu2exu_cmd_o[56] = 1'b1;
									idu2exu_cmd_o[51-:5] = instr[11:7];
									idu2exu_cmd_o[36-:32] = 0;
								end
							end
							else if (~|instr[11:2]) begin
								idu2exu_cmd_o[4] = 1'b1;
								idu2exu_cmd_o[3-:SCR1_EXC_CODE_WIDTH_E] = sv2v_cast_92043(4'd3);
							end
							else if (~|instr[6:2]) begin
								idu2exu_use_rs1_o = 1'b1;
								idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
								idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 4);
								idu2exu_cmd_o[56] = 1'b1;
								idu2exu_cmd_o[51-:5] = instr[11:7];
								idu2exu_cmd_o[41-:5] = SCR1_MPRF_RA_ADDR;
								idu2exu_cmd_o[36-:32] = 0;
							end
							else begin
								idu2exu_use_rs1_o = 1'b1;
								idu2exu_use_rs2_o = 1'b1;
								idu2exu_cmd_o[72-:5] = sv2v_cast_9DDEB({32 {1'sb0}} + 4);
								idu2exu_cmd_o[73-:1] = sv2v_cast_EFCFF(1);
								idu2exu_cmd_o[59-:3] = sv2v_cast_4D524({32 {1'sb0}} + 1);
								idu2exu_cmd_o[51-:5] = instr[11:7];
								idu2exu_cmd_o[46-:5] = instr[6:2];
								idu2exu_cmd_o[41-:5] = instr[11:7];
							end
						3'b110: begin
							idu2exu_use_rs1_o = 1'b1;
							idu2exu_use_rs2_o = 1'b1;
							idu2exu_cmd_o[67-:1] = sv2v_cast_64327(1);
							idu2exu_cmd_o[66-:4] = sv2v_cast_4A511({32 {1'sb0}} + 8);
							idu2exu_cmd_o[51-:5] = SCR1_MPRF_SP_ADDR;
							idu2exu_cmd_o[46-:5] = instr[6:2];
							idu2exu_cmd_o[36-:32] = {24'd0, instr[8:7], instr[12:9], 2'b00};
						end
						default: rvc_illegal = 1'b1;
					endcase
				end
				default:
					;
			endcase
		if (rvi_illegal | rvc_illegal) begin
			idu2exu_cmd_o[72-:5] = sv2v_cast_305D4(1'sb0);
			idu2exu_cmd_o[66-:4] = sv2v_cast_268FE(1'sb0);
			idu2exu_cmd_o[61-:2] = sv2v_cast_AF896(1'sb0);
			idu2exu_cmd_o[59-:3] = sv2v_cast_FEE4F(1'sb0);
			idu2exu_cmd_o[56] = 1'b0;
			idu2exu_cmd_o[55] = 1'b0;
			idu2exu_cmd_o[54] = 1'b0;
			idu2exu_cmd_o[53] = 1'b0;
			idu2exu_cmd_o[52] = 1'b0;
			idu2exu_use_rs1_o = 1'b0;
			idu2exu_use_rs2_o = 1'b0;
			idu2exu_cmd_o[36-:32] = instr;
			idu2exu_cmd_o[4] = 1'b1;
			idu2exu_cmd_o[3-:SCR1_EXC_CODE_WIDTH_E] = sv2v_cast_92043(4'd2);
		end
	end
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_ifu (
	rst_n,
	clk,
	pipe2ifu_stop_fetch_i,
	imem2ifu_req_ack_i,
	ifu2imem_req_o,
	ifu2imem_cmd_o,
	ifu2imem_addr_o,
	imem2ifu_rdata_i,
	imem2ifu_resp_i,
	exu2ifu_pc_new_req_i,
	exu2ifu_pc_new_i,
	hdu2ifu_pbuf_fetch_i,
	ifu2hdu_pbuf_rdy_o,
	hdu2ifu_pbuf_vd_i,
	hdu2ifu_pbuf_err_i,
	hdu2ifu_pbuf_instr_i,
	ifu2pipe_imem_txns_pnd_o,
	idu2ifu_rdy_i,
	ifu2idu_instr_o,
	ifu2idu_imem_err_o,
	ifu2idu_err_rvi_hi_o,
	ifu2idu_vd_o
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	input wire pipe2ifu_stop_fetch_i;
	input wire imem2ifu_req_ack_i;
	output wire ifu2imem_req_o;
	output wire ifu2imem_cmd_o;
	output wire [31:0] ifu2imem_addr_o;
	input wire [31:0] imem2ifu_rdata_i;
	input wire [1:0] imem2ifu_resp_i;
	input wire exu2ifu_pc_new_req_i;
	input wire [31:0] exu2ifu_pc_new_i;
	input wire hdu2ifu_pbuf_fetch_i;
	output wire ifu2hdu_pbuf_rdy_o;
	input wire hdu2ifu_pbuf_vd_i;
	input wire hdu2ifu_pbuf_err_i;
	localparam [31:0] SCR1_HDU_CORE_INSTR_WIDTH = 32;
	input wire [31:0] hdu2ifu_pbuf_instr_i;
	output wire ifu2pipe_imem_txns_pnd_o;
	input wire idu2ifu_rdy_i;
	output reg [31:0] ifu2idu_instr_o;
	output reg ifu2idu_imem_err_o;
	output reg ifu2idu_err_rvi_hi_o;
	output reg ifu2idu_vd_o;
	localparam SCR1_IFU_Q_SIZE_WORD = 2;
	localparam SCR1_IFU_Q_SIZE_HALF = 4;
	localparam SCR1_TXN_CNT_W = 3;
	localparam SCR1_IFU_QUEUE_ADR_W = 2;
	localparam SCR1_IFU_QUEUE_PTR_W = 3;
	localparam SCR1_IFU_Q_FREE_H_W = 3;
	localparam SCR1_IFU_Q_FREE_W_W = 2;
	reg new_pc_unaligned_ff;
	wire new_pc_unaligned_next;
	wire new_pc_unaligned_upd;
	wire instr_hi_is_rvi;
	wire instr_lo_is_rvi;
	reg [2:0] instr_type;
	reg instr_hi_rvi_lo_ff;
	wire instr_hi_rvi_lo_next;
	wire [1:0] q_rd_size;
	wire q_rd_vd;
	wire q_rd_none;
	wire q_rd_hword;
	reg [1:0] q_wr_size;
	wire q_wr_none;
	wire q_wr_full;
	reg [2:0] q_rptr;
	wire [2:0] q_rptr_next;
	wire q_rptr_upd;
	reg [2:0] q_wptr;
	wire [2:0] q_wptr_next;
	wire q_wptr_upd;
	wire q_wr_en;
	wire q_flush_req;
	reg [63:0] q_data;
	wire [15:0] q_data_head;
	wire [15:0] q_data_next;
	reg [0:3] q_err;
	wire q_err_head;
	wire q_err_next;
	wire q_is_empty;
	wire q_has_free_slots;
	wire q_has_1_ocpd_hw;
	wire q_head_is_rvc;
	wire q_head_is_rvi;
	wire [2:0] q_ocpd_h;
	wire [2:0] q_free_h_next;
	wire [1:0] q_free_w_next;
	wire ifu_fetch_req;
	wire ifu_stop_req;
	reg ifu_fsm_curr;
	reg ifu_fsm_next;
	wire ifu_fsm_fetch;
	wire imem_resp_ok;
	wire imem_resp_er;
	wire imem_resp_er_discard_pnd;
	wire imem_resp_discard_req;
	wire imem_resp_received;
	wire imem_resp_vd;
	wire imem_handshake_done;
	wire [15:0] imem_rdata_lo;
	wire [31:16] imem_rdata_hi;
	wire imem_addr_upd;
	reg [31:2] imem_addr_ff;
	wire [31:2] imem_addr_next;
	wire imem_pnd_txns_cnt_upd;
	reg [2:0] imem_pnd_txns_cnt;
	wire [2:0] imem_pnd_txns_cnt_next;
	wire [2:0] imem_vd_pnd_txns_cnt;
	wire imem_pnd_txns_q_full;
	wire imem_resp_discard_cnt_upd;
	reg [2:0] imem_resp_discard_cnt;
	wire [2:0] imem_resp_discard_cnt_next;
	wire new_pc_req_ff;
	reg [1:0] instr_bypass_type;
	wire instr_bypass_vd;
	assign new_pc_unaligned_upd = exu2ifu_pc_new_req_i | imem_resp_vd;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			new_pc_unaligned_ff <= 1'b0;
		else if (new_pc_unaligned_upd)
			new_pc_unaligned_ff <= new_pc_unaligned_next;
	assign new_pc_unaligned_next = (exu2ifu_pc_new_req_i ? exu2ifu_pc_new_i[1] : (~imem_resp_vd ? new_pc_unaligned_ff : 1'b0));
	assign instr_hi_is_rvi = &imem2ifu_rdata_i[17:16];
	assign instr_lo_is_rvi = &imem2ifu_rdata_i[1:0];
	always @(*) begin
		instr_type = 3'd0;
		if (imem_resp_ok & ~imem_resp_discard_req) begin
			if (new_pc_unaligned_ff)
				instr_type = (instr_hi_is_rvi ? 3'd7 : 3'd6);
			else if (instr_hi_rvi_lo_ff)
				instr_type = (instr_hi_is_rvi ? 3'd5 : 3'd4);
			else
				case ({instr_hi_is_rvi, instr_lo_is_rvi})
					2'b00: instr_type = 3'd2;
					2'b10: instr_type = 3'd3;
					default: instr_type = 3'd1;
				endcase
		end
	end
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			instr_hi_rvi_lo_ff <= 1'b0;
		else if (exu2ifu_pc_new_req_i)
			instr_hi_rvi_lo_ff <= 1'b0;
		else if (imem_resp_vd)
			instr_hi_rvi_lo_ff <= instr_hi_rvi_lo_next;
	assign instr_hi_rvi_lo_next = ((instr_type == 3'd7) | (instr_type == 3'd5)) | (instr_type == 3'd3);
	assign q_rd_vd = (~q_is_empty & ifu2idu_vd_o) & idu2ifu_rdy_i;
	assign q_rd_hword = (q_head_is_rvc | q_err_head) | (q_head_is_rvi & instr_bypass_vd);
	assign q_rd_size = (~q_rd_vd ? 2'd0 : (q_rd_hword ? 2'd1 : 2'd2));
	assign q_rd_none = q_rd_size == 2'd0;
	always @(*) begin
		q_wr_size = 2'd0;
		if (~imem_resp_discard_req) begin
			if (imem_resp_ok)
				case (instr_type)
					3'd0: q_wr_size = 2'd0;
					3'd7: q_wr_size = 2'd2;
					3'd6: q_wr_size = (instr_bypass_vd & idu2ifu_rdy_i ? 2'd0 : 2'd2);
					3'd1: q_wr_size = (instr_bypass_vd & idu2ifu_rdy_i ? 2'd0 : 2'd1);
					3'd2, 3'd3, 3'd4, 3'd5: q_wr_size = (instr_bypass_vd & idu2ifu_rdy_i ? 2'd2 : 2'd1);
				endcase
			else if (imem_resp_er)
				q_wr_size = 2'd1;
		end
	end
	assign q_wr_none = q_wr_size == 2'd0;
	assign q_wr_full = q_wr_size == 2'd1;
	assign q_flush_req = exu2ifu_pc_new_req_i | pipe2ifu_stop_fetch_i;
	assign q_wptr_upd = q_flush_req | ~q_wr_none;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			q_wptr <= 1'sb0;
		else if (q_wptr_upd)
			q_wptr <= q_wptr_next;
	assign q_wptr_next = (q_flush_req ? {3 {1'sb0}} : (~q_wr_none ? q_wptr + (q_wr_full ? 3'b010 : 3'b001) : q_wptr));
	assign q_rptr_upd = q_flush_req | ~q_rd_none;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			q_rptr <= 1'sb0;
		else if (q_rptr_upd)
			q_rptr <= q_rptr_next;
	assign q_rptr_next = (q_flush_req ? {3 {1'sb0}} : (~q_rd_none ? q_rptr + (q_rd_hword ? 3'b001 : 3'b010) : q_rptr));
	assign imem_rdata_hi = imem2ifu_rdata_i[31:16];
	assign imem_rdata_lo = imem2ifu_rdata_i[15:0];
	assign q_wr_en = imem_resp_vd & ~q_flush_req;
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			q_data <= {SCR1_IFU_Q_SIZE_HALF {1'sb0}};
			q_err <= {SCR1_IFU_Q_SIZE_HALF {1'b0}};
		end
		else if (q_wr_en)
			case (q_wr_size)
				2'd2: begin
					q_data[(3 - sv2v_cast_2(q_wptr)) * 16+:16] <= imem_rdata_hi;
					q_err[sv2v_cast_2(q_wptr)] <= imem_resp_er;
				end
				2'd1: begin
					q_data[(3 - sv2v_cast_2(q_wptr)) * 16+:16] <= imem_rdata_lo;
					q_err[sv2v_cast_2(q_wptr)] <= imem_resp_er;
					q_data[(3 - sv2v_cast_2(q_wptr + 1'b1)) * 16+:16] <= imem_rdata_hi;
					q_err[sv2v_cast_2(q_wptr + 1'b1)] <= imem_resp_er;
				end
			endcase
	assign q_data_head = q_data[(3 - sv2v_cast_2(q_rptr)) * 16+:16];
	assign q_data_next = q_data[(3 - sv2v_cast_2(q_rptr + 1'b1)) * 16+:16];
	assign q_err_head = q_err[sv2v_cast_2(q_rptr)];
	assign q_err_next = q_err[sv2v_cast_2(q_rptr + 1'b1)];
	assign q_ocpd_h = q_wptr - q_rptr;
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	assign q_free_h_next = sv2v_cast_3(SCR1_IFU_Q_SIZE_HALF - (q_wptr - q_rptr_next));
	assign q_free_w_next = sv2v_cast_2(q_free_h_next >> 1'b1);
	assign q_is_empty = q_rptr == q_wptr;
	assign q_has_free_slots = sv2v_cast_3(q_free_w_next) > imem_vd_pnd_txns_cnt;
	assign q_has_1_ocpd_hw = q_ocpd_h == 3'sd1;
	assign q_head_is_rvi = &q_data_head[1:0];
	assign q_head_is_rvc = ~q_head_is_rvi;
	assign ifu_fetch_req = exu2ifu_pc_new_req_i & ~pipe2ifu_stop_fetch_i;
	assign ifu_stop_req = pipe2ifu_stop_fetch_i | (imem_resp_er_discard_pnd & ~exu2ifu_pc_new_req_i);
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			ifu_fsm_curr <= 1'd0;
		else
			ifu_fsm_curr <= ifu_fsm_next;
	always @(*) begin
		ifu_fsm_next = ifu_fsm_curr;
		case (ifu_fsm_curr)
			1'd0: ifu_fsm_next = (ifu_fetch_req ? 1'd1 : 1'd0);
			1'd1: ifu_fsm_next = (ifu_stop_req ? 1'd0 : 1'd1);
		endcase
	end
	assign ifu_fsm_fetch = ifu_fsm_curr == 1'd1;
	assign imem_resp_er = imem2ifu_resp_i == 2'b10;
	assign imem_resp_ok = imem2ifu_resp_i == 2'b01;
	assign imem_resp_received = imem_resp_ok | imem_resp_er;
	assign imem_resp_vd = imem_resp_received & ~imem_resp_discard_req;
	assign imem_resp_er_discard_pnd = imem_resp_er & ~imem_resp_discard_req;
	assign imem_handshake_done = ifu2imem_req_o & imem2ifu_req_ack_i;
	assign imem_addr_upd = imem_handshake_done | exu2ifu_pc_new_req_i;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			imem_addr_ff <= 1'sb0;
		else if (imem_addr_upd)
			imem_addr_ff <= imem_addr_next;
	assign imem_addr_next = (exu2ifu_pc_new_req_i ? exu2ifu_pc_new_i[31:2] : (&imem_addr_ff[5:2] ? imem_addr_ff + imem_handshake_done : {imem_addr_ff[31:6], imem_addr_ff[5:2] + imem_handshake_done}));
	assign imem_pnd_txns_cnt_upd = imem_handshake_done ^ imem_resp_received;
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			imem_pnd_txns_cnt <= 1'sb0;
		else if (imem_pnd_txns_cnt_upd)
			imem_pnd_txns_cnt <= imem_pnd_txns_cnt_next;
	assign imem_pnd_txns_cnt_next = imem_pnd_txns_cnt + (imem_handshake_done - imem_resp_received);
	assign imem_pnd_txns_q_full = &imem_pnd_txns_cnt;
	assign imem_resp_discard_cnt_upd = (exu2ifu_pc_new_req_i | imem_resp_er) | (imem_resp_ok & imem_resp_discard_req);
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			imem_resp_discard_cnt <= 1'sb0;
		else if (imem_resp_discard_cnt_upd)
			imem_resp_discard_cnt <= imem_resp_discard_cnt_next;
	assign imem_resp_discard_cnt_next = (exu2ifu_pc_new_req_i | imem_resp_er_discard_pnd ? imem_pnd_txns_cnt_next : imem_resp_discard_cnt - 1'b1);
	assign imem_vd_pnd_txns_cnt = imem_pnd_txns_cnt - imem_resp_discard_cnt;
	assign imem_resp_discard_req = |imem_resp_discard_cnt;
	assign ifu2imem_req_o = (ifu_fsm_fetch & ~imem_pnd_txns_q_full) & q_has_free_slots;
	assign ifu2imem_addr_o = {imem_addr_ff, 2'b00};
	assign ifu2imem_cmd_o = 1'b0;
	assign ifu2pipe_imem_txns_pnd_o = |imem_pnd_txns_cnt;
	assign instr_bypass_vd = instr_bypass_type != 2'd0;
	always @(*) begin
		instr_bypass_type = 2'd0;
		if (imem_resp_vd) begin
			if (q_is_empty)
				case (instr_type)
					3'd6, 3'd2, 3'd3: instr_bypass_type = 2'd1;
					3'd1: instr_bypass_type = 2'd3;
					default:
						;
				endcase
			else if (q_has_1_ocpd_hw & q_head_is_rvi) begin
				if (instr_hi_rvi_lo_ff)
					instr_bypass_type = 2'd2;
			end
		end
	end
	always @(*) begin
		ifu2idu_vd_o = 1'b0;
		ifu2idu_imem_err_o = 1'b0;
		ifu2idu_err_rvi_hi_o = 1'b0;
		if (ifu_fsm_fetch | ~q_is_empty) begin
			if (instr_bypass_vd) begin
				ifu2idu_vd_o = 1'b1;
				ifu2idu_imem_err_o = (instr_bypass_type == 2'd2 ? imem_resp_er | q_err_head : imem_resp_er);
				ifu2idu_err_rvi_hi_o = (instr_bypass_type == 2'd2) & imem_resp_er;
			end
			else if (~q_is_empty) begin
				if (q_has_1_ocpd_hw) begin
					ifu2idu_vd_o = q_head_is_rvc | q_err_head;
					ifu2idu_imem_err_o = q_err_head;
					ifu2idu_err_rvi_hi_o = (~q_err_head & q_head_is_rvi) & q_err_next;
				end
				else begin
					ifu2idu_vd_o = 1'b1;
					ifu2idu_imem_err_o = (q_err_head ? 1'b1 : q_head_is_rvi & q_err_next);
				end
			end
		end
		if (hdu2ifu_pbuf_fetch_i) begin
			ifu2idu_vd_o = hdu2ifu_pbuf_vd_i;
			ifu2idu_imem_err_o = hdu2ifu_pbuf_err_i;
		end
	end
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin
		ifu2idu_instr_o = sv2v_cast_32((q_head_is_rvc ? q_data_head : {q_data_next, q_data_head}));
		case (instr_bypass_type)
			2'd1: ifu2idu_instr_o = sv2v_cast_32((new_pc_unaligned_ff ? imem_rdata_hi : imem_rdata_lo));
			2'd3: ifu2idu_instr_o = imem2ifu_rdata_i;
			2'd2: ifu2idu_instr_o = {imem_rdata_lo, q_data_head};
			default: ifu2idu_instr_o = sv2v_cast_32((q_head_is_rvc ? q_data_head : {q_data_next, q_data_head}));
		endcase
		if (hdu2ifu_pbuf_fetch_i)
			ifu2idu_instr_o = sv2v_cast_32({1'sb0, hdu2ifu_pbuf_instr_i});
	end
	assign ifu2hdu_pbuf_rdy_o = idu2ifu_rdy_i;
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_lsu (
	rst_n,
	clk,
	exu2lsu_req_i,
	exu2lsu_cmd_i,
	exu2lsu_addr_i,
	exu2lsu_sdata_i,
	lsu2exu_rdy_o,
	lsu2exu_ldata_o,
	lsu2exu_exc_o,
	lsu2exu_exc_code_o,
	lsu2tdu_dmon_o,
	tdu2lsu_ibrkpt_exc_req_i,
	tdu2lsu_dbrkpt_exc_req_i,
	lsu2dmem_req_o,
	lsu2dmem_cmd_o,
	lsu2dmem_width_o,
	lsu2dmem_addr_o,
	lsu2dmem_wdata_o,
	dmem2lsu_req_ack_i,
	dmem2lsu_rdata_i,
	dmem2lsu_resp_i
);
	reg _sv2v_0;
	input wire rst_n;
	input wire clk;
	input wire exu2lsu_req_i;
	localparam SCR1_LSU_CMD_ALL_NUM_E = 9;
	localparam SCR1_LSU_CMD_WIDTH_E = 4;
	input wire [3:0] exu2lsu_cmd_i;
	input wire [31:0] exu2lsu_addr_i;
	input wire [31:0] exu2lsu_sdata_i;
	output wire lsu2exu_rdy_o;
	output reg [31:0] lsu2exu_ldata_o;
	output wire lsu2exu_exc_o;
	localparam [31:0] SCR1_EXC_CODE_WIDTH_E = 4;
	output reg [3:0] lsu2exu_exc_code_o;
	output wire [34:0] lsu2tdu_dmon_o;
	input wire tdu2lsu_ibrkpt_exc_req_i;
	input wire tdu2lsu_dbrkpt_exc_req_i;
	output wire lsu2dmem_req_o;
	output wire lsu2dmem_cmd_o;
	output wire [1:0] lsu2dmem_width_o;
	output wire [31:0] lsu2dmem_addr_o;
	output wire [31:0] lsu2dmem_wdata_o;
	input wire dmem2lsu_req_ack_i;
	input wire [31:0] dmem2lsu_rdata_i;
	input wire [1:0] dmem2lsu_resp_i;
	reg lsu_fsm_curr;
	reg lsu_fsm_next;
	wire lsu_fsm_idle;
	wire lsu_cmd_upd;
	reg [3:0] lsu_cmd_ff;
	wire lsu_cmd_ff_load;
	wire lsu_cmd_ff_store;
	wire dmem_cmd_load;
	wire dmem_cmd_store;
	wire dmem_wdth_word;
	wire dmem_wdth_hword;
	wire dmem_wdth_byte;
	wire dmem_resp_ok;
	wire dmem_resp_er;
	wire dmem_resp_received;
	wire dmem_req_vd;
	wire lsu_exc_req;
	wire dmem_addr_mslgn;
	wire dmem_addr_mslgn_l;
	wire dmem_addr_mslgn_s;
	wire lsu_exc_hwbrk;
	assign dmem_resp_ok = dmem2lsu_resp_i == 2'b01;
	assign dmem_resp_er = dmem2lsu_resp_i == 2'b10;
	assign dmem_resp_received = dmem_resp_ok | dmem_resp_er;
	assign dmem_req_vd = (exu2lsu_req_i & dmem2lsu_req_ack_i) & ~lsu_exc_req;
	function automatic [3:0] sv2v_cast_4A511;
		input reg [3:0] inp;
		sv2v_cast_4A511 = inp;
	endfunction
	assign dmem_cmd_load = ((((exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 1)) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 4))) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 2))) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 5))) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 3));
	assign dmem_cmd_store = ((exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 6)) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 7))) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 8));
	assign dmem_wdth_word = (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 3)) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 8));
	assign dmem_wdth_hword = ((exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 2)) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 5))) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 7));
	assign dmem_wdth_byte = ((exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 1)) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 4))) | (exu2lsu_cmd_i == sv2v_cast_4A511({32 {1'sb0}} + 6));
	assign lsu_cmd_upd = lsu_fsm_idle & dmem_req_vd;
	function automatic [3:0] sv2v_cast_9707C;
		input reg [3:0] inp;
		sv2v_cast_9707C = inp;
	endfunction
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			lsu_cmd_ff <= sv2v_cast_9707C(1'sb0);
		else if (lsu_cmd_upd)
			lsu_cmd_ff <= exu2lsu_cmd_i;
	assign lsu_cmd_ff_load = ((((lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 1)) | (lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 4))) | (lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 2))) | (lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 5))) | (lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 3));
	assign lsu_cmd_ff_store = ((lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 6)) | (lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 7))) | (lsu_cmd_ff == sv2v_cast_4A511({32 {1'sb0}} + 8));
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			lsu_fsm_curr <= 1'd0;
		else
			lsu_fsm_curr <= lsu_fsm_next;
	always @(*) begin
		lsu_fsm_next = lsu_fsm_curr;
		case (lsu_fsm_curr)
			1'd0: lsu_fsm_next = (dmem_req_vd ? 1'd1 : 1'd0);
			1'd1: lsu_fsm_next = (dmem_resp_received ? 1'd0 : 1'd1);
		endcase
	end
	assign lsu_fsm_idle = lsu_fsm_curr == 1'd0;
	assign dmem_addr_mslgn = exu2lsu_req_i & ((dmem_wdth_hword & exu2lsu_addr_i[0]) | (dmem_wdth_word & |exu2lsu_addr_i[1:0]));
	assign dmem_addr_mslgn_l = dmem_addr_mslgn & dmem_cmd_load;
	assign dmem_addr_mslgn_s = dmem_addr_mslgn & dmem_cmd_store;
	function automatic [3:0] sv2v_cast_92043;
		input reg [3:0] inp;
		sv2v_cast_92043 = inp;
	endfunction
	always @(*) begin
		lsu2exu_exc_code_o = sv2v_cast_92043(4'd0);
		case (1'b1)
			dmem_resp_er: lsu2exu_exc_code_o = (lsu_cmd_ff_load ? sv2v_cast_92043(4'd5) : (lsu_cmd_ff_store ? sv2v_cast_92043(4'd7) : sv2v_cast_92043(4'd0)));
			lsu_exc_hwbrk: lsu2exu_exc_code_o = sv2v_cast_92043(4'd3);
			dmem_addr_mslgn_l: lsu2exu_exc_code_o = sv2v_cast_92043(4'd4);
			dmem_addr_mslgn_s: lsu2exu_exc_code_o = sv2v_cast_92043(4'd6);
			default: lsu2exu_exc_code_o = sv2v_cast_92043(4'd0);
		endcase
	end
	assign lsu_exc_req = (dmem_addr_mslgn_l | dmem_addr_mslgn_s) | lsu_exc_hwbrk;
	assign lsu2exu_rdy_o = dmem_resp_received;
	assign lsu2exu_exc_o = dmem_resp_er | lsu_exc_req;
	always @(*) begin
		lsu2exu_ldata_o = dmem2lsu_rdata_i;
		case (lsu_cmd_ff)
			sv2v_cast_4A511({32 {1'sb0}} + 2): lsu2exu_ldata_o = {{16 {dmem2lsu_rdata_i[15]}}, dmem2lsu_rdata_i[15:0]};
			sv2v_cast_4A511({32 {1'sb0}} + 5): lsu2exu_ldata_o = {16'b0000000000000000, dmem2lsu_rdata_i[15:0]};
			sv2v_cast_4A511({32 {1'sb0}} + 1): lsu2exu_ldata_o = {{24 {dmem2lsu_rdata_i[7]}}, dmem2lsu_rdata_i[7:0]};
			sv2v_cast_4A511({32 {1'sb0}} + 4): lsu2exu_ldata_o = {24'b000000000000000000000000, dmem2lsu_rdata_i[7:0]};
			default: lsu2exu_ldata_o = dmem2lsu_rdata_i;
		endcase
	end
	assign lsu2dmem_req_o = (exu2lsu_req_i & ~lsu_exc_req) & lsu_fsm_idle;
	assign lsu2dmem_addr_o = exu2lsu_addr_i;
	assign lsu2dmem_wdata_o = exu2lsu_sdata_i;
	assign lsu2dmem_cmd_o = (dmem_cmd_store ? 1'b1 : 1'b0);
	assign lsu2dmem_width_o = (dmem_wdth_byte ? 2'b00 : (dmem_wdth_hword ? 2'b01 : 2'b10));
	assign lsu2tdu_dmon_o[34] = (exu2lsu_req_i & lsu_fsm_idle) & ~tdu2lsu_ibrkpt_exc_req_i;
	assign lsu2tdu_dmon_o[31-:32] = exu2lsu_addr_i;
	assign lsu2tdu_dmon_o[33] = dmem_cmd_load;
	assign lsu2tdu_dmon_o[32] = dmem_cmd_store;
	assign lsu_exc_hwbrk = (exu2lsu_req_i & tdu2lsu_ibrkpt_exc_req_i) | tdu2lsu_dbrkpt_exc_req_i;
	initial _sv2v_0 = 0;
endmodule
module scr1_pipe_mprf (
	rst_n,
	clk,
	exu2mprf_rs1_addr_i,
	mprf2exu_rs1_data_o,
	exu2mprf_rs2_addr_i,
	mprf2exu_rs2_data_o,
	exu2mprf_w_req_i,
	exu2mprf_rd_addr_i,
	exu2mprf_rd_data_i
);
	input wire rst_n;
	input wire clk;
	input wire [4:0] exu2mprf_rs1_addr_i;
	output wire [31:0] mprf2exu_rs1_data_o;
	input wire [4:0] exu2mprf_rs2_addr_i;
	output wire [31:0] mprf2exu_rs2_data_o;
	input wire exu2mprf_w_req_i;
	input wire [4:0] exu2mprf_rd_addr_i;
	input wire [31:0] exu2mprf_rd_data_i;
	wire wr_req_vd;
	wire rs1_addr_vd;
	wire rs2_addr_vd;
	reg [1023:32] mprf_int;
	assign rs1_addr_vd = |exu2mprf_rs1_addr_i;
	assign rs2_addr_vd = |exu2mprf_rs2_addr_i;
	assign wr_req_vd = exu2mprf_w_req_i & |exu2mprf_rd_addr_i;
	assign mprf2exu_rs1_data_o = (rs1_addr_vd ? mprf_int[(32 - exu2mprf_rs1_addr_i) * 32+:32] : {32 {1'sb0}});
	assign mprf2exu_rs2_data_o = (rs2_addr_vd ? mprf_int[(32 - exu2mprf_rs2_addr_i) * 32+:32] : {32 {1'sb0}});
	always @(posedge clk or negedge rst_n)
		if (~rst_n)
			mprf_int <= {31 {32'b00000000000000000000000000000000}};
		else if (wr_req_vd)
			mprf_int[(32 - exu2mprf_rd_addr_i) * 32+:32] <= exu2mprf_rd_data_i;
endmodule
module scr1_pipe_top (
	pipe_rst_n,
	pipe2hdu_rdc_qlfy_i,
	dbg_rst_n,
	clk,
	pipe2imem_req_o,
	pipe2imem_cmd_o,
	pipe2imem_addr_o,
	imem2pipe_req_ack_i,
	imem2pipe_rdata_i,
	imem2pipe_resp_i,
	pipe2dmem_req_o,
	pipe2dmem_cmd_o,
	pipe2dmem_width_o,
	pipe2dmem_addr_o,
	pipe2dmem_wdata_o,
	dmem2pipe_req_ack_i,
	dmem2pipe_rdata_i,
	dmem2pipe_resp_i,
	dbg_en,
	dm2pipe_active_i,
	dm2pipe_cmd_req_i,
	dm2pipe_cmd_i,
	pipe2dm_cmd_resp_o,
	pipe2dm_cmd_rcode_o,
	pipe2dm_hart_event_o,
	pipe2dm_hart_status_o,
	pipe2dm_pbuf_addr_o,
	dm2pipe_pbuf_instr_i,
	pipe2dm_dreg_req_o,
	pipe2dm_dreg_wr_o,
	pipe2dm_dreg_wdata_o,
	dm2pipe_dreg_resp_i,
	dm2pipe_dreg_fail_i,
	dm2pipe_dreg_rdata_i,
	pipe2dm_pc_sample_o,
	soc2pipe_irq_lines_i,
	soc2pipe_irq_soft_i,
	soc2pipe_irq_mtimer_i,
	soc2pipe_mtimer_val_i,
	pipe2clkctl_sleep_req_o,
	pipe2clkctl_wake_req_o,
	clkctl2pipe_clk_alw_on_i,
	clkctl2pipe_clk_dbgc_i,
	clkctl2pipe_clk_en_i,
	soc2pipe_fuse_mhartid_i
);
	input wire pipe_rst_n;
	input wire pipe2hdu_rdc_qlfy_i;
	input wire dbg_rst_n;
	input wire clk;
	output wire pipe2imem_req_o;
	output wire pipe2imem_cmd_o;
	output wire [31:0] pipe2imem_addr_o;
	input wire imem2pipe_req_ack_i;
	input wire [31:0] imem2pipe_rdata_i;
	input wire [1:0] imem2pipe_resp_i;
	output wire pipe2dmem_req_o;
	output wire pipe2dmem_cmd_o;
	output wire [1:0] pipe2dmem_width_o;
	output wire [31:0] pipe2dmem_addr_o;
	output wire [31:0] pipe2dmem_wdata_o;
	input wire dmem2pipe_req_ack_i;
	input wire [31:0] dmem2pipe_rdata_i;
	input wire [1:0] dmem2pipe_resp_i;
	input wire dbg_en;
	input wire dm2pipe_active_i;
	input wire dm2pipe_cmd_req_i;
	input wire [1:0] dm2pipe_cmd_i;
	output wire pipe2dm_cmd_resp_o;
	output wire pipe2dm_cmd_rcode_o;
	output wire pipe2dm_hart_event_o;
	output wire [3:0] pipe2dm_hart_status_o;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_SPAN = 8;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_WIDTH = 3;
	output wire [2:0] pipe2dm_pbuf_addr_o;
	localparam [31:0] SCR1_HDU_CORE_INSTR_WIDTH = 32;
	input wire [31:0] dm2pipe_pbuf_instr_i;
	output wire pipe2dm_dreg_req_o;
	output wire pipe2dm_dreg_wr_o;
	output wire [31:0] pipe2dm_dreg_wdata_o;
	input wire dm2pipe_dreg_resp_i;
	input wire dm2pipe_dreg_fail_i;
	input wire [31:0] dm2pipe_dreg_rdata_i;
	output wire [31:0] pipe2dm_pc_sample_o;
	localparam SCR1_IRQ_VECT_NUM = 16;
	localparam SCR1_IRQ_LINES_NUM = SCR1_IRQ_VECT_NUM;
	input wire [15:0] soc2pipe_irq_lines_i;
	input wire soc2pipe_irq_soft_i;
	input wire soc2pipe_irq_mtimer_i;
	input wire [63:0] soc2pipe_mtimer_val_i;
	output wire pipe2clkctl_sleep_req_o;
	output wire pipe2clkctl_wake_req_o;
	input wire clkctl2pipe_clk_alw_on_i;
	input wire clkctl2pipe_clk_dbgc_i;
	input wire clkctl2pipe_clk_en_i;
	input wire [31:0] soc2pipe_fuse_mhartid_i;
	wire [31:0] curr_pc;
	wire [31:0] next_pc;
	wire new_pc_req;
	wire [31:0] new_pc;
	wire stop_fetch;
	wire exu_exc_req;
	wire brkpt;
	wire exu_init_pc;
	wire wfi_run2halt;
	wire instret;
	wire instret_nexc;
	wire ipic2csr_irq;
	wire brkpt_hw;
	wire imem_txns_pending;
	wire wfi_halted;
	wire ifu2idu_vd;
	wire [31:0] ifu2idu_instr;
	wire ifu2idu_imem_err;
	wire ifu2idu_err_rvi_hi;
	wire idu2ifu_rdy;
	wire idu2exu_req;
	localparam SCR1_GPR_FIELD_WIDTH = 5;
	localparam SCR1_CSR_CMD_ALL_NUM_E = 4;
	localparam SCR1_CSR_CMD_WIDTH_E = 2;
	localparam SCR1_CSR_OP_ALL_NUM_E = 2;
	localparam SCR1_CSR_OP_WIDTH_E = 1;
	localparam [31:0] SCR1_EXC_CODE_WIDTH_E = 4;
	localparam SCR1_IALU_CMD_ALL_NUM_E = 23;
	localparam SCR1_IALU_CMD_WIDTH_E = 5;
	localparam SCR1_IALU_OP_ALL_NUM_E = 2;
	localparam SCR1_IALU_OP_WIDTH_E = 1;
	localparam SCR1_SUM2_OP_ALL_NUM_E = 2;
	localparam SCR1_SUM2_OP_WIDTH_E = 1;
	localparam SCR1_LSU_CMD_ALL_NUM_E = 9;
	localparam SCR1_LSU_CMD_WIDTH_E = 4;
	localparam SCR1_RD_WB_ALL_NUM_E = 7;
	localparam SCR1_RD_WB_WIDTH_E = 3;
	wire [74:0] idu2exu_cmd;
	wire idu2exu_use_rs1;
	wire idu2exu_use_rs2;
	wire exu2idu_rdy;
	wire [4:0] exu2mprf_rs1_addr;
	wire [31:0] mprf2exu_rs1_data;
	wire [4:0] exu2mprf_rs2_addr;
	wire [31:0] mprf2exu_rs2_data;
	wire exu2mprf_w_req;
	wire [4:0] exu2mprf_rd_addr;
	wire [31:0] exu2mprf_rd_data;
	localparam [31:0] SCR1_CSR_ADDR_WIDTH = 12;
	wire [11:0] exu2csr_rw_addr;
	wire exu2csr_r_req;
	wire [31:0] csr2exu_r_data;
	wire exu2csr_w_req;
	wire [1:0] exu2csr_w_cmd;
	wire [31:0] exu2csr_w_data;
	wire csr2exu_rw_exc;
	wire exu2csr_take_irq;
	wire exu2csr_take_exc;
	wire exu2csr_mret_update;
	wire exu2csr_mret_instr;
	wire [3:0] exu2csr_exc_code;
	wire [31:0] exu2csr_trap_val;
	wire [31:0] csr2exu_new_pc;
	wire csr2exu_irq;
	wire csr2exu_ip_ie;
	wire csr2exu_mstatus_mie_up;
	wire csr2ipic_r_req;
	wire csr2ipic_w_req;
	wire [2:0] csr2ipic_addr;
	wire [31:0] csr2ipic_wdata;
	wire [31:0] ipic2csr_rdata;
	wire csr2tdu_req;
	wire [1:0] csr2tdu_cmd;
	localparam SCR1_CSR_ADDR_TDU_OFFS_W = 3;
	wire [2:0] csr2tdu_addr;
	wire [31:0] csr2tdu_wdata;
	wire [31:0] tdu2csr_rdata;
	wire tdu2csr_resp;
	wire csr2tdu_req_qlfy;
	wire [33:0] exu2tdu_i_mon;
	wire [34:0] lsu2tdu_d_mon;
	localparam [31:0] SCR1_TDU_TRIG_NUM = 2;
	localparam [31:0] SCR1_TDU_MTRIG_NUM = SCR1_TDU_TRIG_NUM;
	localparam [31:0] SCR1_TDU_ALLTRIG_NUM = SCR1_TDU_MTRIG_NUM + 1'b1;
	wire [SCR1_TDU_ALLTRIG_NUM - 1:0] tdu2exu_i_match;
	wire [1:0] tdu2lsu_d_match;
	wire tdu2exu_i_x_req;
	wire tdu2lsu_i_x_req;
	wire tdu2lsu_d_x_req;
	wire [SCR1_TDU_ALLTRIG_NUM - 1:0] exu2tdu_bp_retire;
	wire [33:0] exu2tdu_i_mon_qlfy;
	wire [34:0] lsu2tdu_d_mon_qlfy;
	wire [SCR1_TDU_ALLTRIG_NUM - 1:0] exu2tdu_bp_retire_qlfy;
	wire fetch_pbuf;
	wire csr2hdu_req;
	wire [1:0] csr2hdu_cmd;
	function automatic [11:0] sv2v_cast_C1AAB;
		input reg [11:0] inp;
		sv2v_cast_C1AAB = inp;
	endfunction
	localparam [11:0] SCR1_CSR_ADDR_HDU_MSPAN = sv2v_cast_C1AAB('h4);
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_SPAN = SCR1_CSR_ADDR_HDU_MSPAN;
	localparam [31:0] SCR1_HDU_DEBUGCSR_ADDR_WIDTH = $clog2(SCR1_HDU_DEBUGCSR_ADDR_SPAN);
	wire [SCR1_HDU_DEBUGCSR_ADDR_WIDTH - 1:0] csr2hdu_addr;
	wire [31:0] csr2hdu_wdata;
	wire [31:0] hdu2csr_rdata;
	wire hdu2csr_resp;
	wire csr2hdu_req_qlfy;
	wire hwbrk_dsbl;
	wire hdu_hwbrk_dsbl;
	wire tdu2hdu_dmode_req;
	wire exu_no_commit;
	wire exu_irq_dsbl;
	wire exu_pc_advmt_dsbl;
	wire exu_dmode_sstep_en;
	wire dbg_halted;
	wire dbg_run2halt;
	wire dbg_halt2run;
	wire dbg_run_start;
	wire [31:0] dbg_new_pc;
	wire ifu2hdu_pbuf_rdy;
	wire hdu2ifu_pbuf_vd;
	wire hdu2ifu_pbuf_err;
	wire [31:0] hdu2ifu_pbuf_instr;
	wire ifu2hdu_pbuf_rdy_qlfy;
	wire exu_busy_qlfy;
	wire instret_qlfy;
	wire exu_init_pc_qlfy;
	wire exu_exc_req_qlfy;
	wire brkpt_qlfy;
	wire exu_busy;
	assign stop_fetch = wfi_run2halt | fetch_pbuf;
	assign pipe2clkctl_sleep_req_o = wfi_halted & ~imem_txns_pending;
	assign pipe2clkctl_wake_req_o = csr2exu_ip_ie | dm2pipe_active_i;
	assign pipe2dm_pc_sample_o = curr_pc;
	scr1_pipe_ifu i_pipe_ifu(
		.rst_n(pipe_rst_n),
		.clk(clk),
		.imem2ifu_req_ack_i(imem2pipe_req_ack_i),
		.ifu2imem_req_o(pipe2imem_req_o),
		.ifu2imem_cmd_o(pipe2imem_cmd_o),
		.ifu2imem_addr_o(pipe2imem_addr_o),
		.imem2ifu_rdata_i(imem2pipe_rdata_i),
		.imem2ifu_resp_i(imem2pipe_resp_i),
		.exu2ifu_pc_new_req_i(new_pc_req),
		.exu2ifu_pc_new_i(new_pc),
		.pipe2ifu_stop_fetch_i(stop_fetch),
		.hdu2ifu_pbuf_fetch_i(fetch_pbuf),
		.ifu2hdu_pbuf_rdy_o(ifu2hdu_pbuf_rdy),
		.hdu2ifu_pbuf_vd_i(hdu2ifu_pbuf_vd),
		.hdu2ifu_pbuf_err_i(hdu2ifu_pbuf_err),
		.hdu2ifu_pbuf_instr_i(hdu2ifu_pbuf_instr),
		.ifu2pipe_imem_txns_pnd_o(imem_txns_pending),
		.idu2ifu_rdy_i(idu2ifu_rdy),
		.ifu2idu_instr_o(ifu2idu_instr),
		.ifu2idu_imem_err_o(ifu2idu_imem_err),
		.ifu2idu_err_rvi_hi_o(ifu2idu_err_rvi_hi),
		.ifu2idu_vd_o(ifu2idu_vd)
	);
	scr1_pipe_idu i_pipe_idu(
		.idu2ifu_rdy_o(idu2ifu_rdy),
		.ifu2idu_instr_i(ifu2idu_instr),
		.ifu2idu_imem_err_i(ifu2idu_imem_err),
		.ifu2idu_err_rvi_hi_i(ifu2idu_err_rvi_hi),
		.ifu2idu_vd_i(ifu2idu_vd),
		.idu2exu_req_o(idu2exu_req),
		.idu2exu_cmd_o(idu2exu_cmd),
		.idu2exu_use_rs1_o(idu2exu_use_rs1),
		.idu2exu_use_rs2_o(idu2exu_use_rs2),
		.exu2idu_rdy_i(exu2idu_rdy)
	);
	scr1_pipe_exu i_pipe_exu(
		.rst_n(pipe_rst_n),
		.clk(clk),
		.clk_alw_on(clkctl2pipe_clk_alw_on_i),
		.clk_pipe_en(clkctl2pipe_clk_en_i),
		.idu2exu_req_i(idu2exu_req),
		.exu2idu_rdy_o(exu2idu_rdy),
		.idu2exu_cmd_i(idu2exu_cmd),
		.idu2exu_use_rs1_i(idu2exu_use_rs1),
		.idu2exu_use_rs2_i(idu2exu_use_rs2),
		.exu2mprf_rs1_addr_o(exu2mprf_rs1_addr),
		.mprf2exu_rs1_data_i(mprf2exu_rs1_data),
		.exu2mprf_rs2_addr_o(exu2mprf_rs2_addr),
		.mprf2exu_rs2_data_i(mprf2exu_rs2_data),
		.exu2mprf_w_req_o(exu2mprf_w_req),
		.exu2mprf_rd_addr_o(exu2mprf_rd_addr),
		.exu2mprf_rd_data_o(exu2mprf_rd_data),
		.exu2csr_rw_addr_o(exu2csr_rw_addr),
		.exu2csr_r_req_o(exu2csr_r_req),
		.csr2exu_r_data_i(csr2exu_r_data),
		.exu2csr_w_req_o(exu2csr_w_req),
		.exu2csr_w_cmd_o(exu2csr_w_cmd),
		.exu2csr_w_data_o(exu2csr_w_data),
		.csr2exu_rw_exc_i(csr2exu_rw_exc),
		.exu2csr_take_irq_o(exu2csr_take_irq),
		.exu2csr_take_exc_o(exu2csr_take_exc),
		.exu2csr_mret_update_o(exu2csr_mret_update),
		.exu2csr_mret_instr_o(exu2csr_mret_instr),
		.exu2csr_exc_code_o(exu2csr_exc_code),
		.exu2csr_trap_val_o(exu2csr_trap_val),
		.csr2exu_new_pc_i(csr2exu_new_pc),
		.csr2exu_irq_i(csr2exu_irq),
		.csr2exu_ip_ie_i(csr2exu_ip_ie),
		.csr2exu_mstatus_mie_up_i(csr2exu_mstatus_mie_up),
		.exu2dmem_req_o(pipe2dmem_req_o),
		.exu2dmem_cmd_o(pipe2dmem_cmd_o),
		.exu2dmem_width_o(pipe2dmem_width_o),
		.exu2dmem_addr_o(pipe2dmem_addr_o),
		.exu2dmem_wdata_o(pipe2dmem_wdata_o),
		.dmem2exu_req_ack_i(dmem2pipe_req_ack_i),
		.dmem2exu_rdata_i(dmem2pipe_rdata_i),
		.dmem2exu_resp_i(dmem2pipe_resp_i),
		.hdu2exu_no_commit_i(exu_no_commit),
		.hdu2exu_irq_dsbl_i(exu_irq_dsbl),
		.hdu2exu_pc_advmt_dsbl_i(exu_pc_advmt_dsbl),
		.hdu2exu_dmode_sstep_en_i(exu_dmode_sstep_en),
		.hdu2exu_pbuf_fetch_i(fetch_pbuf),
		.hdu2exu_dbg_halted_i(dbg_halted),
		.hdu2exu_dbg_run2halt_i(dbg_run2halt),
		.hdu2exu_dbg_halt2run_i(dbg_halt2run),
		.hdu2exu_dbg_run_start_i(dbg_run_start),
		.hdu2exu_dbg_new_pc_i(dbg_new_pc),
		.exu2tdu_imon_o(exu2tdu_i_mon),
		.tdu2exu_ibrkpt_match_i(tdu2exu_i_match),
		.tdu2exu_ibrkpt_exc_req_i(tdu2exu_i_x_req),
		.lsu2tdu_dmon_o(lsu2tdu_d_mon),
		.tdu2lsu_ibrkpt_exc_req_i(tdu2lsu_i_x_req),
		.tdu2lsu_dbrkpt_match_i(tdu2lsu_d_match),
		.tdu2lsu_dbrkpt_exc_req_i(tdu2lsu_d_x_req),
		.exu2tdu_ibrkpt_ret_o(exu2tdu_bp_retire),
		.exu2hdu_ibrkpt_hw_o(brkpt_hw),
		.exu2pipe_exc_req_o(exu_exc_req),
		.exu2pipe_brkpt_o(brkpt),
		.exu2pipe_init_pc_o(exu_init_pc),
		.exu2pipe_wfi_run2halt_o(wfi_run2halt),
		.exu2pipe_instret_o(instret),
		.exu2csr_instret_no_exc_o(instret_nexc),
		.exu2pipe_exu_busy_o(exu_busy),
		.exu2pipe_wfi_halted_o(wfi_halted),
		.exu2pipe_pc_curr_o(curr_pc),
		.exu2csr_pc_next_o(next_pc),
		.exu2ifu_pc_new_req_o(new_pc_req),
		.exu2ifu_pc_new_o(new_pc)
	);
	scr1_pipe_mprf i_pipe_mprf(
		.rst_n(pipe_rst_n),
		.clk(clk),
		.exu2mprf_rs1_addr_i(exu2mprf_rs1_addr),
		.mprf2exu_rs1_data_o(mprf2exu_rs1_data),
		.exu2mprf_rs2_addr_i(exu2mprf_rs2_addr),
		.mprf2exu_rs2_data_o(mprf2exu_rs2_data),
		.exu2mprf_w_req_i(exu2mprf_w_req),
		.exu2mprf_rd_addr_i(exu2mprf_rd_addr),
		.exu2mprf_rd_data_i(exu2mprf_rd_data)
	);
	scr1_pipe_csr i_pipe_csr(
		.rst_n(pipe_rst_n),
		.clk(clk),
		.clk_alw_on(clkctl2pipe_clk_alw_on_i),
		.exu2csr_r_req_i(exu2csr_r_req),
		.exu2csr_rw_addr_i(exu2csr_rw_addr),
		.csr2exu_r_data_o(csr2exu_r_data),
		.exu2csr_w_req_i(exu2csr_w_req),
		.exu2csr_w_cmd_i(exu2csr_w_cmd),
		.exu2csr_w_data_i(exu2csr_w_data),
		.csr2exu_rw_exc_o(csr2exu_rw_exc),
		.exu2csr_take_irq_i(exu2csr_take_irq),
		.exu2csr_take_exc_i(exu2csr_take_exc),
		.exu2csr_mret_update_i(exu2csr_mret_update),
		.exu2csr_mret_instr_i(exu2csr_mret_instr),
		.exu2csr_exc_code_i(exu2csr_exc_code),
		.exu2csr_trap_val_i(exu2csr_trap_val),
		.csr2exu_new_pc_o(csr2exu_new_pc),
		.csr2exu_irq_o(csr2exu_irq),
		.csr2exu_ip_ie_o(csr2exu_ip_ie),
		.csr2exu_mstatus_mie_up_o(csr2exu_mstatus_mie_up),
		.csr2ipic_r_req_o(csr2ipic_r_req),
		.csr2ipic_w_req_o(csr2ipic_w_req),
		.csr2ipic_addr_o(csr2ipic_addr),
		.csr2ipic_wdata_o(csr2ipic_wdata),
		.ipic2csr_rdata_i(ipic2csr_rdata),
		.exu2csr_pc_curr_i(curr_pc),
		.exu2csr_pc_next_i(next_pc),
		.exu2csr_instret_no_exc_i(instret_nexc),
		.soc2csr_irq_ext_i(ipic2csr_irq),
		.soc2csr_irq_soft_i(soc2pipe_irq_soft_i),
		.soc2csr_irq_mtimer_i(soc2pipe_irq_mtimer_i),
		.soc2csr_mtimer_val_i(soc2pipe_mtimer_val_i),
		.csr2hdu_req_o(csr2hdu_req),
		.csr2hdu_cmd_o(csr2hdu_cmd),
		.csr2hdu_addr_o(csr2hdu_addr),
		.csr2hdu_wdata_o(csr2hdu_wdata),
		.hdu2csr_rdata_i(hdu2csr_rdata),
		.hdu2csr_resp_i(hdu2csr_resp),
		.hdu2csr_no_commit_i(exu_no_commit),
		.csr2tdu_req_o(csr2tdu_req),
		.csr2tdu_cmd_o(csr2tdu_cmd),
		.csr2tdu_addr_o(csr2tdu_addr),
		.csr2tdu_wdata_o(csr2tdu_wdata),
		.tdu2csr_rdata_i(tdu2csr_rdata),
		.tdu2csr_resp_i(tdu2csr_resp),
		.soc2csr_fuse_mhartid_i(soc2pipe_fuse_mhartid_i)
	);
	scr1_ipic i_pipe_ipic(
		.rst_n(pipe_rst_n),
		.clk(clkctl2pipe_clk_alw_on_i),
		.soc2ipic_irq_lines_i(soc2pipe_irq_lines_i),
		.csr2ipic_r_req_i(csr2ipic_r_req),
		.csr2ipic_w_req_i(csr2ipic_w_req),
		.csr2ipic_addr_i(csr2ipic_addr),
		.csr2ipic_wdata_i(csr2ipic_wdata),
		.ipic2csr_rdata_o(ipic2csr_rdata),
		.ipic2csr_irq_m_req_o(ipic2csr_irq)
	);
	scr1_pipe_tdu i_pipe_tdu(
		.rst_n(dbg_rst_n),
		.clk(clk),
		.clk_en(1'b1),
		.tdu_dsbl_i(hwbrk_dsbl),
		.csr2tdu_req_i(csr2tdu_req_qlfy),
		.csr2tdu_cmd_i(csr2tdu_cmd),
		.csr2tdu_addr_i(csr2tdu_addr),
		.csr2tdu_wdata_i(csr2tdu_wdata),
		.tdu2csr_rdata_o(tdu2csr_rdata),
		.tdu2csr_resp_o(tdu2csr_resp),
		.exu2tdu_imon_i(exu2tdu_i_mon_qlfy),
		.tdu2exu_ibrkpt_match_o(tdu2exu_i_match),
		.tdu2exu_ibrkpt_exc_req_o(tdu2exu_i_x_req),
		.exu2tdu_bp_retire_i(exu2tdu_bp_retire_qlfy),
		.tdu2lsu_ibrkpt_exc_req_o(tdu2lsu_i_x_req),
		.lsu2tdu_dmon_i(lsu2tdu_d_mon_qlfy),
		.tdu2lsu_dbrkpt_match_o(tdu2lsu_d_match),
		.tdu2lsu_dbrkpt_exc_req_o(tdu2lsu_d_x_req),
		.tdu2hdu_dmode_req_o(tdu2hdu_dmode_req)
	);
	assign hwbrk_dsbl = ~dbg_en | hdu_hwbrk_dsbl;
	assign csr2tdu_req_qlfy = (dbg_en & csr2tdu_req) & pipe2hdu_rdc_qlfy_i;
	assign exu2tdu_i_mon_qlfy[33] = exu2tdu_i_mon[33] & pipe2hdu_rdc_qlfy_i;
	assign exu2tdu_i_mon_qlfy[32] = exu2tdu_i_mon[32];
	assign exu2tdu_i_mon_qlfy[31-:32] = exu2tdu_i_mon[31-:32];
	assign lsu2tdu_d_mon_qlfy[34] = lsu2tdu_d_mon[34] & pipe2hdu_rdc_qlfy_i;
	assign lsu2tdu_d_mon_qlfy[33] = lsu2tdu_d_mon[33];
	assign lsu2tdu_d_mon_qlfy[32] = lsu2tdu_d_mon[32];
	assign lsu2tdu_d_mon_qlfy[31-:32] = lsu2tdu_d_mon[31-:32];
	assign exu2tdu_bp_retire_qlfy = exu2tdu_bp_retire & {SCR1_TDU_ALLTRIG_NUM {pipe2hdu_rdc_qlfy_i}};
	scr1_pipe_hdu i_pipe_hdu(
		.rst_n(dbg_rst_n),
		.clk_en(dm2pipe_active_i),
		.clk_pipe_en(clkctl2pipe_clk_en_i),
		.clk(clkctl2pipe_clk_dbgc_i),
		.csr2hdu_req_i(csr2hdu_req_qlfy),
		.csr2hdu_cmd_i(csr2hdu_cmd),
		.csr2hdu_addr_i(csr2hdu_addr),
		.csr2hdu_wdata_i(csr2hdu_wdata),
		.hdu2csr_resp_o(hdu2csr_resp),
		.hdu2csr_rdata_o(hdu2csr_rdata),
		.pipe2hdu_rdc_qlfy_i(pipe2hdu_rdc_qlfy_i),
		.dm2hdu_cmd_req_i(dm2pipe_cmd_req_i),
		.dm2hdu_cmd_i(dm2pipe_cmd_i),
		.hdu2dm_cmd_resp_o(pipe2dm_cmd_resp_o),
		.hdu2dm_cmd_rcode_o(pipe2dm_cmd_rcode_o),
		.hdu2dm_hart_event_o(pipe2dm_hart_event_o),
		.hdu2dm_hart_status_o(pipe2dm_hart_status_o),
		.hdu2dm_pbuf_addr_o(pipe2dm_pbuf_addr_o),
		.dm2hdu_pbuf_instr_i(dm2pipe_pbuf_instr_i),
		.hdu2dm_dreg_req_o(pipe2dm_dreg_req_o),
		.hdu2dm_dreg_wr_o(pipe2dm_dreg_wr_o),
		.hdu2dm_dreg_wdata_o(pipe2dm_dreg_wdata_o),
		.dm2hdu_dreg_resp_i(dm2pipe_dreg_resp_i),
		.dm2hdu_dreg_fail_i(dm2pipe_dreg_fail_i),
		.dm2hdu_dreg_rdata_i(dm2pipe_dreg_rdata_i),
		.hdu2tdu_hwbrk_dsbl_o(hdu_hwbrk_dsbl),
		.tdu2hdu_dmode_req_i(tdu2hdu_dmode_req),
		.exu2hdu_ibrkpt_hw_i(brkpt_hw),
		.pipe2hdu_exu_busy_i(exu_busy_qlfy),
		.pipe2hdu_instret_i(instret_qlfy),
		.pipe2hdu_init_pc_i(exu_init_pc_qlfy),
		.pipe2hdu_exu_exc_req_i(exu_exc_req_qlfy),
		.pipe2hdu_brkpt_i(brkpt_qlfy),
		.hdu2exu_pbuf_fetch_o(fetch_pbuf),
		.hdu2exu_no_commit_o(exu_no_commit),
		.hdu2exu_irq_dsbl_o(exu_irq_dsbl),
		.hdu2exu_pc_advmt_dsbl_o(exu_pc_advmt_dsbl),
		.hdu2exu_dmode_sstep_en_o(exu_dmode_sstep_en),
		.hdu2exu_dbg_halted_o(dbg_halted),
		.hdu2exu_dbg_run2halt_o(dbg_run2halt),
		.hdu2exu_dbg_halt2run_o(dbg_halt2run),
		.hdu2exu_dbg_run_start_o(dbg_run_start),
		.pipe2hdu_pc_curr_i(curr_pc),
		.hdu2exu_dbg_new_pc_o(dbg_new_pc),
		.ifu2hdu_pbuf_instr_rdy_i(ifu2hdu_pbuf_rdy_qlfy),
		.hdu2ifu_pbuf_instr_vd_o(hdu2ifu_pbuf_vd),
		.hdu2ifu_pbuf_instr_err_o(hdu2ifu_pbuf_err),
		.hdu2ifu_pbuf_instr_o(hdu2ifu_pbuf_instr)
	);
	assign csr2hdu_req_qlfy = (csr2hdu_req & dbg_en) & pipe2hdu_rdc_qlfy_i;
	assign exu_busy_qlfy = exu_busy & {pipe2hdu_rdc_qlfy_i};
	assign instret_qlfy = instret & {pipe2hdu_rdc_qlfy_i};
	assign exu_init_pc_qlfy = exu_init_pc & {pipe2hdu_rdc_qlfy_i};
	assign exu_exc_req_qlfy = exu_exc_req & {pipe2hdu_rdc_qlfy_i};
	assign brkpt_qlfy = brkpt & {pipe2hdu_rdc_qlfy_i};
	assign ifu2hdu_pbuf_rdy_qlfy = ifu2hdu_pbuf_rdy & {pipe2hdu_rdc_qlfy_i};
endmodule
module scr1_core_top (
	pwrup_rst_n,
	rst_n,
	cpu_rst_n,
	test_mode,
	test_rst_n,
	clk,
	core_rst_n_o,
	core_rdc_qlfy_o,
	sys_rst_n_o,
	sys_rdc_qlfy_o,
	core_fuse_mhartid_i,
	tapc_fuse_idcode_i,
	core_irq_lines_i,
	core_irq_soft_i,
	core_irq_mtimer_i,
	core_mtimer_val_i,
	tapc_trst_n,
	tapc_tck,
	tapc_tms,
	tapc_tdi,
	tapc_tdo,
	tapc_tdo_en,
	imem2core_req_ack_i,
	core2imem_req_o,
	core2imem_cmd_o,
	core2imem_addr_o,
	imem2core_rdata_i,
	imem2core_resp_i,
	dmem2core_req_ack_i,
	core2dmem_req_o,
	core2dmem_cmd_o,
	core2dmem_width_o,
	core2dmem_addr_o,
	core2dmem_wdata_o,
	dmem2core_rdata_i,
	dmem2core_resp_i
);
	input wire pwrup_rst_n;
	input wire rst_n;
	input wire cpu_rst_n;
	input wire test_mode;
	input wire test_rst_n;
	input wire clk;
	output wire core_rst_n_o;
	output wire core_rdc_qlfy_o;
	output wire sys_rst_n_o;
	output wire sys_rdc_qlfy_o;
	input wire [31:0] core_fuse_mhartid_i;
	input wire [31:0] tapc_fuse_idcode_i;
	localparam SCR1_IRQ_VECT_NUM = 16;
	localparam SCR1_IRQ_LINES_NUM = SCR1_IRQ_VECT_NUM;
	input wire [15:0] core_irq_lines_i;
	input wire core_irq_soft_i;
	input wire core_irq_mtimer_i;
	input wire [63:0] core_mtimer_val_i;
	input wire tapc_trst_n;
	input wire tapc_tck;
	input wire tapc_tms;
	input wire tapc_tdi;
	output wire tapc_tdo;
	output wire tapc_tdo_en;
	input wire imem2core_req_ack_i;
	output wire core2imem_req_o;
	output wire core2imem_cmd_o;
	output wire [31:0] core2imem_addr_o;
	input wire [31:0] imem2core_rdata_i;
	input wire [1:0] imem2core_resp_i;
	input wire dmem2core_req_ack_i;
	output wire core2dmem_req_o;
	output wire core2dmem_cmd_o;
	output wire [1:0] core2dmem_width_o;
	output wire [31:0] core2dmem_addr_o;
	output wire [31:0] core2dmem_wdata_o;
	input wire [31:0] dmem2core_rdata_i;
	input wire [1:0] dmem2core_resp_i;
	localparam [31:0] SCR1_CORE_TOP_RST_SYNC_STAGES_NUM = 2;
	wire core_rst_n;
	wire core_rst_n_status_sync;
	wire core_rst_status;
	wire core2hdu_rdc_qlfy;
	wire core2dm_rdc_qlfy;
	wire pwrup_rst_n_sync;
	wire rst_n_sync;
	wire cpu_rst_n_sync;
	wire tapc_dmi_ch_sel;
	localparam SCR1_DBG_DMI_CH_ID_WIDTH = 2'd2;
	wire [SCR1_DBG_DMI_CH_ID_WIDTH - 1:0] tapc_dmi_ch_id;
	wire tapc_dmi_ch_capture;
	wire tapc_dmi_ch_shift;
	wire tapc_dmi_ch_update;
	wire tapc_dmi_ch_tdi;
	wire tapc_dmi_ch_tdo;
	wire tapc_dmi_ch_sel_tapout;
	wire [SCR1_DBG_DMI_CH_ID_WIDTH - 1:0] tapc_dmi_ch_id_tapout;
	wire tapc_dmi_ch_capture_tapout;
	wire tapc_dmi_ch_shift_tapout;
	wire tapc_dmi_ch_update_tapout;
	wire tapc_dmi_ch_tdi_tapout;
	wire tapc_dmi_ch_tdo_tapin;
	wire dmi_req;
	wire dmi_wr;
	localparam SCR1_DBG_DMI_ADDR_WIDTH = 6'd7;
	wire [SCR1_DBG_DMI_ADDR_WIDTH - 1:0] dmi_addr;
	localparam SCR1_DBG_DMI_DATA_WIDTH = 6'd32;
	wire [SCR1_DBG_DMI_DATA_WIDTH - 1:0] dmi_wdata;
	wire dmi_resp;
	wire [SCR1_DBG_DMI_DATA_WIDTH - 1:0] dmi_rdata;
	wire tapc_scu_ch_sel;
	wire tapc_scu_ch_sel_tapout;
	wire tapc_scu_ch_tdo;
	wire tapc_ch_tdo;
	wire sys_rst_n;
	wire sys_rst_status;
	wire hdu_rst_n;
	wire hdu2dm_rdc_qlfy;
	wire ndm_rst_n;
	wire dm_rst_n;
	wire hart_rst_n;
	wire dm_active;
	wire dm_cmd_req;
	wire [1:0] dm_cmd;
	wire dm_cmd_resp;
	wire dm_cmd_resp_qlfy;
	wire dm_cmd_rcode;
	wire dm_hart_event;
	wire dm_hart_event_qlfy;
	wire [3:0] dm_hart_status;
	wire [3:0] dm_hart_status_qlfy;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_SPAN = 8;
	localparam [31:0] SCR1_HDU_PBUF_ADDR_WIDTH = 3;
	wire [2:0] dm_pbuf_addr;
	wire [2:0] dm_pbuf_addr_qlfy;
	localparam [31:0] SCR1_HDU_CORE_INSTR_WIDTH = 32;
	wire [31:0] dm_pbuf_instr;
	wire dm_dreg_req;
	wire dm_dreg_req_qlfy;
	wire dm_dreg_wr;
	localparam [31:0] SCR1_HDU_DATA_REG_WIDTH = 32;
	wire [31:0] dm_dreg_wdata;
	wire dm_dreg_resp;
	wire dm_dreg_fail;
	wire [31:0] dm_dreg_rdata;
	wire [31:0] dm_pc_sample;
	wire [31:0] dm_pc_sample_qlfy;
	wire sleep_pipe;
	wire wake_pipe;
	wire clk_pipe;
	wire clk_pipe_en;
	wire clk_dbgc;
	wire clk_alw_on;
	localparam [0:0] sv2v_uu_i_scu_ext_tapcsync2scu_ch_id_i_0 = 1'sb0;
	scr1_scu i_scu(
		.pwrup_rst_n(pwrup_rst_n),
		.rst_n(rst_n),
		.cpu_rst_n(cpu_rst_n),
		.test_mode(test_mode),
		.test_rst_n(test_rst_n),
		.clk(clk),
		.tapcsync2scu_ch_sel_i(tapc_scu_ch_sel),
		.tapcsync2scu_ch_id_i(sv2v_uu_i_scu_ext_tapcsync2scu_ch_id_i_0),
		.tapcsync2scu_ch_capture_i(tapc_dmi_ch_capture),
		.tapcsync2scu_ch_shift_i(tapc_dmi_ch_shift),
		.tapcsync2scu_ch_update_i(tapc_dmi_ch_update),
		.tapcsync2scu_ch_tdi_i(tapc_dmi_ch_tdi),
		.scu2tapcsync_ch_tdo_o(tapc_scu_ch_tdo),
		.ndm_rst_n_i(ndm_rst_n),
		.hart_rst_n_i(hart_rst_n),
		.sys_rst_n_o(sys_rst_n),
		.core_rst_n_o(core_rst_n),
		.dm_rst_n_o(dm_rst_n),
		.hdu_rst_n_o(hdu_rst_n),
		.sys_rst_status_o(sys_rst_status),
		.core_rst_status_o(core_rst_status),
		.sys_rdc_qlfy_o(sys_rdc_qlfy_o),
		.core_rdc_qlfy_o(core_rdc_qlfy_o),
		.core2hdu_rdc_qlfy_o(core2hdu_rdc_qlfy),
		.core2dm_rdc_qlfy_o(core2dm_rdc_qlfy),
		.hdu2dm_rdc_qlfy_o(hdu2dm_rdc_qlfy)
	);
	assign sys_rst_n_o = sys_rst_n;
	assign pwrup_rst_n_sync = pwrup_rst_n;
	assign core_rst_n_o = core_rst_n;
	scr1_pipe_top i_pipe_top(
		.pipe_rst_n(core_rst_n),
		.pipe2hdu_rdc_qlfy_i(core2hdu_rdc_qlfy),
		.dbg_rst_n(hdu_rst_n),
		.clk(clk_pipe),
		.pipe2clkctl_sleep_req_o(sleep_pipe),
		.pipe2clkctl_wake_req_o(wake_pipe),
		.clkctl2pipe_clk_alw_on_i(clk_alw_on),
		.clkctl2pipe_clk_dbgc_i(clk_dbgc),
		.clkctl2pipe_clk_en_i(clk_pipe_en),
		.pipe2imem_req_o(core2imem_req_o),
		.pipe2imem_cmd_o(core2imem_cmd_o),
		.pipe2imem_addr_o(core2imem_addr_o),
		.imem2pipe_req_ack_i(imem2core_req_ack_i),
		.imem2pipe_rdata_i(imem2core_rdata_i),
		.imem2pipe_resp_i(imem2core_resp_i),
		.pipe2dmem_req_o(core2dmem_req_o),
		.pipe2dmem_cmd_o(core2dmem_cmd_o),
		.pipe2dmem_width_o(core2dmem_width_o),
		.pipe2dmem_addr_o(core2dmem_addr_o),
		.pipe2dmem_wdata_o(core2dmem_wdata_o),
		.dmem2pipe_req_ack_i(dmem2core_req_ack_i),
		.dmem2pipe_rdata_i(dmem2core_rdata_i),
		.dmem2pipe_resp_i(dmem2core_resp_i),
		.dbg_en(1'b1),
		.dm2pipe_active_i(dm_active),
		.dm2pipe_cmd_req_i(dm_cmd_req),
		.dm2pipe_cmd_i(dm_cmd),
		.pipe2dm_cmd_resp_o(dm_cmd_resp),
		.pipe2dm_cmd_rcode_o(dm_cmd_rcode),
		.pipe2dm_hart_event_o(dm_hart_event),
		.pipe2dm_hart_status_o(dm_hart_status),
		.pipe2dm_pbuf_addr_o(dm_pbuf_addr),
		.dm2pipe_pbuf_instr_i(dm_pbuf_instr),
		.pipe2dm_dreg_req_o(dm_dreg_req),
		.pipe2dm_dreg_wr_o(dm_dreg_wr),
		.pipe2dm_dreg_wdata_o(dm_dreg_wdata),
		.dm2pipe_dreg_resp_i(dm_dreg_resp),
		.dm2pipe_dreg_fail_i(dm_dreg_fail),
		.dm2pipe_dreg_rdata_i(dm_dreg_rdata),
		.pipe2dm_pc_sample_o(dm_pc_sample),
		.soc2pipe_irq_lines_i(core_irq_lines_i),
		.soc2pipe_irq_soft_i(core_irq_soft_i),
		.soc2pipe_irq_mtimer_i(core_irq_mtimer_i),
		.soc2pipe_mtimer_val_i(core_mtimer_val_i),
		.soc2pipe_fuse_mhartid_i(core_fuse_mhartid_i)
	);
	scr1_tapc i_tapc(
		.tapc_trst_n(tapc_trst_n),
		.tapc_tck(tapc_tck),
		.tapc_tms(tapc_tms),
		.tapc_tdi(tapc_tdi),
		.tapc_tdo(tapc_tdo),
		.tapc_tdo_en(tapc_tdo_en),
		.soc2tapc_fuse_idcode_i(tapc_fuse_idcode_i),
		.tapc2tapcsync_scu_ch_sel_o(tapc_scu_ch_sel_tapout),
		.tapc2tapcsync_dmi_ch_sel_o(tapc_dmi_ch_sel_tapout),
		.tapc2tapcsync_ch_id_o(tapc_dmi_ch_id_tapout),
		.tapc2tapcsync_ch_capture_o(tapc_dmi_ch_capture_tapout),
		.tapc2tapcsync_ch_shift_o(tapc_dmi_ch_shift_tapout),
		.tapc2tapcsync_ch_update_o(tapc_dmi_ch_update_tapout),
		.tapc2tapcsync_ch_tdi_o(tapc_dmi_ch_tdi_tapout),
		.tapcsync2tapc_ch_tdo_i(tapc_dmi_ch_tdo_tapin)
	);
	scr1_tapc_synchronizer i_tapc_synchronizer(
		.pwrup_rst_n(pwrup_rst_n_sync),
		.dm_rst_n(dm_rst_n),
		.clk(clk),
		.tapc_trst_n(tapc_trst_n),
		.tapc_tck(tapc_tck),
		.tapc2tapcsync_scu_ch_sel_i(tapc_scu_ch_sel_tapout),
		.tapcsync2scu_ch_sel_o(tapc_scu_ch_sel),
		.tapc2tapcsync_dmi_ch_sel_i(tapc_dmi_ch_sel_tapout),
		.tapcsync2dmi_ch_sel_o(tapc_dmi_ch_sel),
		.tapc2tapcsync_ch_id_i(tapc_dmi_ch_id_tapout),
		.tapcsync2core_ch_id_o(tapc_dmi_ch_id),
		.tapc2tapcsync_ch_capture_i(tapc_dmi_ch_capture_tapout),
		.tapcsync2core_ch_capture_o(tapc_dmi_ch_capture),
		.tapc2tapcsync_ch_shift_i(tapc_dmi_ch_shift_tapout),
		.tapcsync2core_ch_shift_o(tapc_dmi_ch_shift),
		.tapc2tapcsync_ch_update_i(tapc_dmi_ch_update_tapout),
		.tapcsync2core_ch_update_o(tapc_dmi_ch_update),
		.tapc2tapcsync_ch_tdi_i(tapc_dmi_ch_tdi_tapout),
		.tapcsync2core_ch_tdi_o(tapc_dmi_ch_tdi),
		.tapc2tapcsync_ch_tdo_i(tapc_dmi_ch_tdo_tapin),
		.tapcsync2core_ch_tdo_o(tapc_ch_tdo)
	);
	assign tapc_ch_tdo = (tapc_scu_ch_tdo & tapc_scu_ch_sel) | (tapc_dmi_ch_tdo & tapc_dmi_ch_sel);
	scr1_dmi i_dmi(
		.rst_n(dm_rst_n),
		.clk(clk),
		.tapcsync2dmi_ch_sel_i(tapc_dmi_ch_sel),
		.tapcsync2dmi_ch_id_i(tapc_dmi_ch_id),
		.tapcsync2dmi_ch_capture_i(tapc_dmi_ch_capture),
		.tapcsync2dmi_ch_shift_i(tapc_dmi_ch_shift),
		.tapcsync2dmi_ch_update_i(tapc_dmi_ch_update),
		.tapcsync2dmi_ch_tdi_i(tapc_dmi_ch_tdi),
		.dmi2tapcsync_ch_tdo_o(tapc_dmi_ch_tdo),
		.dm2dmi_resp_i(dmi_resp),
		.dm2dmi_rdata_i(dmi_rdata),
		.dmi2dm_req_o(dmi_req),
		.dmi2dm_wr_o(dmi_wr),
		.dmi2dm_addr_o(dmi_addr),
		.dmi2dm_wdata_o(dmi_wdata)
	);
	assign dm_cmd_resp_qlfy = dm_cmd_resp & {hdu2dm_rdc_qlfy};
	assign dm_hart_event_qlfy = dm_hart_event & {hdu2dm_rdc_qlfy};
	assign dm_hart_status_qlfy[1-:2] = (hdu2dm_rdc_qlfy ? dm_hart_status[1-:2] : 2'b00);
	assign dm_hart_status_qlfy[3] = dm_hart_status[3];
	assign dm_hart_status_qlfy[2] = dm_hart_status[2];
	assign dm_pbuf_addr_qlfy = dm_pbuf_addr & {SCR1_HDU_PBUF_ADDR_WIDTH {hdu2dm_rdc_qlfy}};
	assign dm_dreg_req_qlfy = dm_dreg_req & {hdu2dm_rdc_qlfy};
	assign dm_pc_sample_qlfy = dm_pc_sample & {32 {core2dm_rdc_qlfy}};
	scr1_dm i_dm(
		.rst_n(dm_rst_n),
		.clk(clk),
		.dmi2dm_req_i(dmi_req),
		.dmi2dm_wr_i(dmi_wr),
		.dmi2dm_addr_i(dmi_addr),
		.dmi2dm_wdata_i(dmi_wdata),
		.dm2dmi_resp_o(dmi_resp),
		.dm2dmi_rdata_o(dmi_rdata),
		.ndm_rst_n_o(ndm_rst_n),
		.hart_rst_n_o(hart_rst_n),
		.dm2pipe_active_o(dm_active),
		.dm2pipe_cmd_req_o(dm_cmd_req),
		.dm2pipe_cmd_o(dm_cmd),
		.pipe2dm_cmd_resp_i(dm_cmd_resp_qlfy),
		.pipe2dm_cmd_rcode_i(dm_cmd_rcode),
		.pipe2dm_hart_event_i(dm_hart_event_qlfy),
		.pipe2dm_hart_status_i(dm_hart_status_qlfy),
		.soc2dm_fuse_mhartid_i(core_fuse_mhartid_i),
		.pipe2dm_pc_sample_i(dm_pc_sample_qlfy),
		.pipe2dm_pbuf_addr_i(dm_pbuf_addr_qlfy),
		.dm2pipe_pbuf_instr_o(dm_pbuf_instr),
		.pipe2dm_dreg_req_i(dm_dreg_req_qlfy),
		.pipe2dm_dreg_wr_i(dm_dreg_wr),
		.pipe2dm_dreg_wdata_i(dm_dreg_wdata),
		.dm2pipe_dreg_resp_o(dm_dreg_resp),
		.dm2pipe_dreg_fail_o(dm_dreg_fail),
		.dm2pipe_dreg_rdata_o(dm_dreg_rdata)
	);
	scr1_clk_ctrl i_clk_ctrl(
		.clk(clk),
		.rst_n(core_rst_n),
		.test_mode(test_mode),
		.test_rst_n(test_rst_n),
		.pipe2clkctl_sleep_req_i(sleep_pipe),
		.pipe2clkctl_wake_req_i(wake_pipe),
		.clkctl2pipe_clk_alw_on_o(clk_alw_on),
		.clkctl2pipe_clk_o(clk_pipe),
		.clkctl2pipe_clk_en_o(clk_pipe_en),
		.clkctl2pipe_clk_dbgc_o(clk_dbgc)
	);
endmodule
