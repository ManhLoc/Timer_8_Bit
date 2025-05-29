module timer_8_bit (
	input wire PCLK,
	input wire PRESETn,
	input wire PSEL,
	input wire PWRITE,
	input wire PENABLE,
	input wire [1:0] PADDR,
	input wire [7:0] PWDATA,
	input wire [3:0] CLK_in,

	output reg [7:0] PRDATA,
	output reg PREADY,
	output reg PSLVERR,
	output reg tmr_udf,
	output reg tmr_ovf
);

wire [7:0] PRDATA_wire;
wire PREADY_wire;
wire PSLVERR_wire;
wire tmr_udf_wire;
wire tmr_ovf_wire;

wire [1:0] status;
wire [7:0] reg_TDR;
wire [7:0] reg_TCR;
wire [7:0] reg_TSR;
wire clock_counter;
wire [7:0] counter_value;

always @ (*) begin
	PRDATA = PRDATA_wire;
	PREADY = PREADY_wire;
	PSLVERR = PSLVERR_wire;
	tmr_udf = tmr_udf_wire;
	tmr_ovf = tmr_ovf_wire;
end

read_write_control IC1 (
	.PCLK(PCLK),
	.PRESETn(PRESETn),
	.PSEL(PSEL),
	.PWRITE(PWRITE),
	.PENABLE(PENABLE),
	.PADDR(PADDR),
	.PWDATA(PWDATA),
	.tmr_udf(tmr_udf),
	.tmr_ovf(tmr_ovf),
	.status(status),
	.PRDATA(PRDATA_wire),
	.PREADY(PREADY_wire),
	.PSLVERR(PSLVERR_wire),
	.reg_TDR(reg_TDR),
	.reg_TCR(reg_TCR),
	.reg_TSR(reg_TSR)
);

control_logic IC2 (
	.CLK_in(CLK_in),
	.reg_TCR(reg_TCR),
	.clock_counter(clock_counter)
);

timer_counter IC3 (
	.PCLK(PCLK),
	.PRESETn(PRESETn),
	.clock_counter(clock_counter),
	.reg_TDR(reg_TDR),
	.reg_TCR(reg_TCR),
	.counter_value(counter_value)
);

comparison IC4 (
	.PCLK(PCLK),
	.PRESETn(PRESETn),
	.status(status),
	.reg_TCR(reg_TCR),
	.reg_TSR(reg_TSR),
	.counter_value(counter_value),
	.tmr_udf(tmr_udf_wire),
	.tmr_ovf(tmr_ovf_wire)
);

endmodule
