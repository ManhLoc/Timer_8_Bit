module read_write_control (
	input wire PCLK,
	input wire PRESETn,
	input wire PSEL,
	input wire PWRITE,
	input wire PENABLE,
	input wire [1:0] PADDR,
	input wire [7:0] PWDATA,
	input wire tmr_udf,
	input wire tmr_ovf, 

	output reg [1:0] status,
	output reg [7:0] PRDATA,
	output reg PREADY,
	output reg PSLVERR,
	output reg [7:0] reg_TDR,
	output reg [7:0] reg_TCR,
	output reg [7:0] reg_TSR
);

localparam IDLE = 2'b00,
	   SETUP = 2'b01,
	   ACCESS = 2'b10;

reg [1:0] cur_state;
reg [1:0] next_state;

always @ (*) begin
	case (cur_state) 
		IDLE: begin
			if (PSEL & !PENABLE) begin
				next_state = SETUP;
			end else begin
				next_state = IDLE;
			end
		end
		SETUP: begin
			if (PSEL & PENABLE) begin
				next_state = ACCESS;
			end else begin
				next_state = SETUP;
			end
		end
		ACCESS: begin
			next_state = IDLE;
		end
		default: begin
			next_state = IDLE;
		end
	endcase
end

always @ (posedge PCLK or negedge PRESETn) begin
	if (!PRESETn) begin
		cur_state <= IDLE;
	end else begin
		cur_state <= next_state;
	end
end

always @ (posedge PCLK or negedge PRESETn) begin
	if (!PRESETn) begin
		reg_TDR <= 8'h00;
		reg_TCR <= 8'h00;
		reg_TSR <= 8'h00;
		PRDATA <= 8'h00;
		status <= 2'b00;
	end else begin
		if ((cur_state == ACCESS) & PWRITE & PSEL & PENABLE) begin
			reg_TDR <= (PADDR == 2'b00) ? PWDATA : reg_TDR;
			reg_TCR <= (PADDR == 2'b01) ? PWDATA : reg_TCR;
			if (PADDR <= 2'b01) begin
				reg_TCR[6] <= 1'b0;
				reg_TCR[3:2] <= 2'b00;
			end
			reg_TSR <= (PADDR == 2'b10) ? PWDATA : reg_TSR;
			if (PADDR == 2'b10) begin
				reg_TSR[7:2] <= 6'b000000;
				reg_TSR[1:0] <= reg_TSR[1:0] & ~PWDATA[1:0];
				if (PWDATA[1:0] == 2'b11) begin
					status <= 2'b11;
				end else if (PWDATA[1:0] == 2'b10) begin
					status <= 2'b10;
				end else if (PWDATA[1:0] == 2'b01) begin
					status <= 2'b01;
				end else begin
					status <= 2'b00;
				end
			end
		end else if ((cur_state == ACCESS) & !PWRITE & PSEL & PENABLE) begin
			case (PADDR)
				2'b00: PRDATA <= reg_TDR;
				2'b01: PRDATA <= reg_TCR;
				2'b10: PRDATA <= reg_TSR;
				default: PRDATA <= 8'h00;
			endcase
		end else begin
			reg_TDR <= reg_TDR;
			reg_TCR <= reg_TCR;
			reg_TSR <= reg_TSR;
		end
	end
end

always @ (posedge PCLK or negedge PRESETn) begin
	if (!PRESETn) begin
		PREADY <= 1'b0;
		PSLVERR <= 1'b0;
	end else begin
		PREADY <= (cur_state == ACCESS);
		PSLVERR <= (cur_state == ACCESS) & (PADDR > 2'b10);
	end
end

always @ (posedge PCLK) begin
	if (tmr_udf && tmr_ovf && status == 2'b00) begin
		reg_TSR[1:0] <= 2'b11;
	end else if (tmr_udf && !tmr_ovf && status == 2'b00) begin
		reg_TSR[1:0] <= 2'b10;
	end else if (!tmr_udf && tmr_ovf && status == 2'b00) begin
	        reg_TSR[1:0] <= 2'b01;
	end else begin
		reg_TSR[1:0] <= 2'b00;
		if (!tmr_udf && !tmr_ovf) begin
			status <= 2'b00;
		end
	end
end

endmodule





























































































