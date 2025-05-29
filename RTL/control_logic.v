module control_logic (
	input wire [3:0] CLK_in,	
	input wire [7:0] reg_TCR,

	output reg clock_counter
);

always @ (*) begin
	case (reg_TCR[1:0])
		2'b00: clock_counter = CLK_in[0];
		2'b01: clock_counter = CLK_in[1];
		2'b10: clock_counter = CLK_in[2];
		default: clock_counter = CLK_in[3];
	endcase
end
		
endmodule
