module timer_counter (
	input wire PCLK,
	input wire PRESETn,
	input wire clock_counter,
	input wire [7:0] reg_TDR,
	input wire [7:0] reg_TCR,

	output reg [7:0] counter_value
);

wire detect_edge;
reg clock_counter_two;

reg [7:0] reg_TDR_pre;

always @ (posedge PCLK) begin
	clock_counter_two <= clock_counter;
end

assign detect_edge = ~clock_counter_two & clock_counter;

always @ (posedge PCLK or negedge PRESETn) begin
	if (!PRESETn) begin
		counter_value <= 8'h00;
		reg_TDR_pre <= 8'h00;
	end else if (reg_TCR[7] && reg_TDR_pre != reg_TDR) begin
		counter_value <= reg_TDR;
		reg_TDR_pre <= reg_TDR;
	end else if (!reg_TCR[5] && reg_TCR[4] && detect_edge) begin
		if (counter_value == 8'hff) begin
			counter_value <= 8'h00;
		end else begin
			counter_value <= counter_value + 1'b1;
		end
	 end else if (reg_TCR[5] && reg_TCR[4] && detect_edge) begin
	 	if (counter_value == 8'h00) begin
	 		counter_value <= 8'hff;
	 	end else begin
	 		counter_value <= counter_value - 1'b1;
	        end
	end else begin
		counter_value <= counter_value;
	end
end

endmodule
