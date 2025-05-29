module comparison (
	input wire PCLK,
	input wire PRESETn,
	input wire [1:0] status,
	input wire [7:0] reg_TCR,
	input wire [7:0] reg_TSR,
	input wire [7:0] counter_value,

	output reg tmr_udf,
	output reg tmr_ovf
);

reg [7:0] temp;

always @ (posedge PCLK or negedge PRESETn) begin
	if (!PRESETn) begin
		temp <= 8'h00;
	end else if (temp != counter_value) begin
		temp <= counter_value;
	end
end

always @ (posedge PCLK or negedge PRESETn) begin
	if (!PRESETn) begin
		tmr_udf <= 1'b0;
		tmr_ovf <= 1'b0;
	end else begin
		if (reg_TCR[4] && reg_TCR[5] && (counter_value == (8'h00 - 1'b1)) && temp == 8'h00 && status == 2'b00) begin
			tmr_udf <= 1'b1;
		end

		if (reg_TCR[4] && !reg_TCR[5] && (counter_value == (8'hff + 1'b1)) && temp == 8'hff && status == 2'b00) begin
			tmr_ovf <= 1'b1;
		end
	end
end

always @ (*) begin
        if (status == 2'b11) begin
        	tmr_udf = reg_TSR[1];
        	tmr_ovf = reg_TSR[0];
        end else if (status == 2'b10) begin
        	tmr_udf = reg_TSR[1];
                tmr_ovf = tmr_ovf;
        end else if (status== 2'b01) begin
                tmr_udf = tmr_udf;
                tmr_ovf = reg_TSR[0];
        end else begin
                tmr_udf = tmr_udf;
                tmr_ovf = tmr_ovf;
        end
end

endmodule
