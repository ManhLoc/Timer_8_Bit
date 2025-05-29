module timer_8_bit_test;

reg PCLK;
reg PRESETn;
reg PSEL;
reg PWRITE;
reg PENABLE;
reg [1:0] PADDR;
reg [7:0] PWDATA;
reg [3:0] CLK_in;
reg [7:0] read_data;

wire [7:0] PRDATA;
wire PREADY;
wire PSLVERR;
wire tmr_udf;
wire tmr_ovf;

timer_8_bit DUT (
	.PCLK(PCLK),
	.PRESETn(PRESETn),
	.PSEL(PSEL),
	.PWRITE(PWRITE),
	.PENABLE(PENABLE),
	.PADDR(PADDR),
	.PWDATA(PWDATA),
	.CLK_in(CLK_in),
	.PRDATA(PRDATA),
	.PREADY(PREADY),
	.PSLVERR(PSVLERR),
	.tmr_udf(tmr_udf),
	.tmr_ovf(tmr_ovf)
);

integer i;

initial begin
	PCLK = 1'b1;
	forever #5 PCLK = !PCLK;
end

initial begin
        CLK_in[0] = 1'b0;
        forever #10 CLK_in[0] = !CLK_in[0];
end

initial begin
        CLK_in[1] = 1'b0;
	forever #20 CLK_in[1] = !CLK_in[1];
end

initial begin
        CLK_in[2] = 1'b0;
        forever #40 CLK_in[2] = !CLK_in[2];
end

initial begin
        CLK_in[3] = 1'b0;
	forever #80 CLK_in[3] = !CLK_in[3];
end

task APB_WRITE;
	input [7:0] addr;
	input [7:0] data_in;

	begin
		PWDATA = 0;
	        PSEL = 0;
		PENABLE = 0;
		PWRITE = 0;
                @ (posedge PCLK);
                PWRITE = 1;
	        PSEL = 1;
                PADDR = addr;
	        PWDATA = data_in;
		@ (posedge PCLK);
                PENABLE = 1;	
		wait (PREADY);
	        @ (posedge PCLK);
	        PSEL = 0;
		PENABLE = 0;
		PWRITE = 0;
		if (PSLVERR) begin
			//$display ("Write %d to %d unsuccessfully\n", data_in, addr);
		end else begin
			//$display ("Write %d to %d successfully\n", data_in, addr);
	        end
        end
endtask


task APB_READ;
	input [7:0] addr;
	output [7:0] data_out;

      	begin
		PSEL = 0;
	        PENABLE = 0;
		PWRITE = 0;
		@ (posedge PCLK);
		PSEL = 1;
		PADDR = addr;
		@ (posedge PCLK);
		PENABLE = 1;
		wait (PREADY);
		@ (posedge PCLK);
		data_out = PRDATA;
		PSEL = 0;
		PENABLE = 0;
		if (PSLVERR) begin
			//$display ("Read value %d from %d unsuccessfully\n", data_out, addr);
		end else begin
			//$display ("Read value %d from %d successfullly\n", data_out, addr);
		end
	end
endtask


// Task 1: Test TDR register
task tdr_test;
        begin
		$display("=================================================");
		$display("=====  Task 1 =====");
		APB_READ(2'b00, read_data);
		#15;
		
		for (i = 0; i < 20; i = i + 1) begin
			APB_WRITE(2'b00, $random);
			#15;

			APB_READ(2'b00, read_data);
                        #15;
                end
        end
endtask

// Task 2: Test TCR register
task tcr_test;
	reg [7:0] written_value;
    	reg [7:0] read_value;
    	begin
		$display("=================================================");
		$display("=====  Task 2 =====");
        	
        	APB_READ(2'b01, read_value);
        	$display("TCR default value: %h", read_value);
        	#15;
        
        	
        	for (i = 0; i < 20; i = i + 1) begin
            		written_value = $random;
            		APB_WRITE(2'b01, written_value);
            		#15;
            
            		APB_READ(2'b01, read_value);
            		#15;
            
            		if ((read_value & 8'hB3) == (written_value & 8'hB3)) begin
                		$display ("Test %0d: PASS - Written: %h, Read: %h, Masked: %h", 
                        		i, written_value, read_value, read_value & 8'hB3);
            		end else begin
						$display ("Test %0d: FAIL - Written: %h, Read: %h, Masked: %h", 
								i, written_value, read_value, read_value & 8'hB3);
					end
        	end
    	end
endtask

// Task 3: Test TSR register (read-only register)
task tsr_test;
    	reg [7:0] written_value;
    	reg [7:0] read_value;
    	begin
		$display("=================================================");
		$display("=====  Task 3 =====");
        	APB_READ(2'b10, read_value);
        	$display("TSR default value: %h", read_value);
        	#15;
        
        	for(i = 0; i < 20; i = i + 1) begin
            		written_value = $random;
            		APB_WRITE(2'b10, written_value);
            		#15;
            
            		APB_READ(2'b10, read_value);
            		#15;
            
            		if(read_value == 0) begin
                		$display("Test %0d: PASS - Written: %h, Read: %h", 
                        		i, written_value, read_value);
            		end else begin
                		$display("Test %0d: FAIL - Written: %h, Read: %h", 
                        	i, written_value, read_value);
            		end
        	end
    	end
endtask

// Task 4: Test null address
task null_address_test;
    	reg [1:0] random_addr;
    	reg [7:0] written_value;
    	reg [7:0] read_value;
    	begin
		$display("=================================================");
		$display("=====  Task 4 =====");
        	for(i = 0; i < 20; i = i + 1) begin
            		random_addr = $random;
            		written_value = $random;
            
            		APB_WRITE(random_addr, written_value);
            		#15;
            
            		APB_READ(random_addr, read_value);
            		#15;
            
            		if(random_addr > 2'b10) begin
                		$display("Test %0d: NULL-ADDRESS - Address: %b", i, random_addr);
            		end else begin
                		if(read_value == written_value) begin
                    			$display("Test %0d: PASS - Address: %b, Written: %h, Read: %h", 
                            			i, random_addr, written_value, read_value);
                		end else begin
                    			$display("Test %0d: FAIL - Address: %b, Written: %h, Read: %h", 
                            			i, random_addr, written_value, read_value);
                		end
            		end
        	end
    	end
endtask


// Task 5: Test mixed address
task mixed_address_test;
    	reg [1:0] random_addr;
    	reg [7:0] written_value;
    	reg [7:0] read_value;
    	begin
		$display("=================================================");
		$display("=====  Task 5 =====");
        	for(i = 0; i < 20; i = i + 1) begin
            		random_addr = $random;
            		written_value = $random;
            
            		APB_WRITE(random_addr, written_value);
            		#15;
            
            		APB_READ(random_addr, read_value);
            		#15;
            
            		if(random_addr > 2'b10) begin
                		$display("Test %0d: NULL-ADDRESS - Address: %b", i, random_addr);
            		end else begin
                		if(read_value == written_value) begin
                    			$display("Test %0d: PASS - Address: %b, Written: %h, Read: %h", 
                            			i, random_addr, written_value, read_value);
                		end else begin
                    			$display("Test %0d: FAIL - Address: %b, Written: %h, Read: %h", 
                            			i, random_addr, written_value, read_value);
                		end
            		end
        	end
    	end
endtask

// Task 6: Test parallel counting with overflow check (PCLKx2)
task countup_forkjoin_pclk2;
	reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 6 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;

		APB_WRITE(2'b01, 8'h10);
		#15;

		wait_cycles = 255 - written_value;
	
		fork
			begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[0]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 1: PASS - Overflow detected");
				end else begin
					$display("Thread 1: FAULTY - Overflow NOT detected");
				end
			end

			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[0]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 2: FAULTY - Unexpected overflow");
				end else begin
				        $display("Thread 2: PASS - No overflow (expected)");
				end
			end
		join
	end
endtask

// Task 7: Test parallel counting with overflow check (PCLKx4)
task countup_forkjoin_pclk4;
        reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 7 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;
  
  		APB_WRITE(2'b01, 8'h80);
		#15;

		APB_WRITE(2'b01, 8'h11);
                #15;

	        wait_cycles = 255 - written_value;
		
		fork
                begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[1]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 1: PASS - Overflow detected");
				end else begin
				        $display("Thread 1: FAULTY - Overflow NOT detected");
				end
			end
		
			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[1]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 2: FAULTY - Unexpected overflow");
				end else begin
					$display("Thread 2: PASS - No overflow (expected)");
				end
			end
		join
	end
endtask

// Task 8: Test parallel counting with overflow check (PCLKx8)
task countup_forkjoin_pclk8;
        reg [7:0] written_value;
	integer wait_cycles;
        
	begin
		$display("=================================================");
		$display("=====  Task 8 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;

		APB_WRITE(2'b01, 8'h12);
		#15;
                
		wait_cycles = 255 - written_value;

		fork
			begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[2]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 1: PASS - Overflow detected");
				end else begin
					$display("Thread 1: FAULTY - Overflow NOT detected");
				end
			end

			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[2]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 2: FAULTY - Unexpected overflow");
				end else begin
					$display("Thread 2: PASS - No overflow (expected)");
				end
			end
		join
	end
endtask

// Task 9: Test parallel counting with overflow check (PCLKx16)
task countup_forkjoin_pclk16;
        reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 9 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;
 		
		APB_WRITE(2'b01, 8'h80);
	        #15;
 
 		APB_WRITE(2'b01, 8'h13);
		#15;

		wait_cycles = 255 - written_value;
  
  		fork
			begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[3]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 1: PASS - Overflow detected");
				end else begin
					$display("Thread 1: FAULTY - Overflow NOT detected");
				end
			end

			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[3]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[0]) begin
					$display("Thread 2: FAULTY - Unexpected overflow");
				end else begin
					$display("Thread 2: PASS - No overflow (expected)");
				end
			end
		join
	end
endtask

// Task 10: Test parallel counting with underflow check (PCLKx2)
task countdown_forkjoin_pclk2;
        reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 10 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;
  
  		APB_WRITE(2'b01, 8'h80);
		#15;
	
		APB_WRITE(2'b01, 8'h30);
		#15;

		wait_cycles = written_value;
  
  		fork
			begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[0]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 1: PASS - Underflow detected");
				end else begin
				$display("Thread 1: FAULTY - Underflow NOT detected");
				end
			end

			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[0]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 2: FAULTY - Unexpected underflow");
				end else begin
				$display("Thread 2: PASS - No underflow (expected)");
				end
			end
		join
	end
endtask

// Task 11: Test parallel counting with underflow check (PCLKx4)
task countdown_forkjoin_pclk4;
        reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 11 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;
  
  		APB_WRITE(2'b01, 8'h80);
		#15;
	
		APB_WRITE(2'b01, 8'h31);
		#15;

		wait_cycles = written_value;
  
  		fork
			begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[1]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 1: PASS - Underflow detected");
				end else begin
				$display("Thread 1: FAULTY - Underflow NOT detected");
				end
			end

			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[1]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 2: FAULTY - Unexpected underflow");
				end else begin
				$display("Thread 2: PASS - No underflow (expected)");
				end
			end
		join
	end
endtask

// Task 12: Test parallel counting with underflow check (PCLKx8)
task countdown_forkjoin_pclk8;
        reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 12 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;
  
  		APB_WRITE(2'b01, 8'h80);
		#15;
	
		APB_WRITE(2'b01, 8'h32);
		#15;

		wait_cycles = written_value;
  
  		fork
			begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[2]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 1: PASS - Underflow detected");
				end else begin
				$display("Thread 1: FAULTY - Underflow NOT detected");
				end
			end

			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[2]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 2: FAULTY - Unexpected underflow");
				end else begin
				$display("Thread 2: PASS - No underflow (expected)");
				end
			end
		join
	end
endtask

// Task 13: Test parallel counting with underflow check (PCLKx16)
task countdown_forkjoin_pclk16;
        reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 13 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;
  
  		APB_WRITE(2'b01, 8'h80);
		#15;
	
		APB_WRITE(2'b01, 8'h33);
		#15;

		wait_cycles = written_value;
  
  		fork
			begin
				repeat (wait_cycles + 10) @ (posedge CLK_in[3]);
				APB_READ(2'b10, read_data);
				$display("Thread 1 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 1: PASS - Underflow detected");
				end else begin
				$display("Thread 1: FAULTY - Underflow NOT detected");
				end
			end

			begin
				repeat ((wait_cycles * 2) / 3) @ (posedge CLK_in[3]);
				APB_READ(2'b10, read_data);
				$display("Thread 2 - TSR: %b", read_data);
				if (read_data[1]) begin
				$display("Thread 2: FAULTY - Unexpected underflow");
				end else begin
				$display("Thread 2: PASS - No underflow (expected)");
				end
			end
		join
	end
endtask

// Task 14: Test countup with pause check (PCLKx2)
task countup_pause_countup_pclk2;
	reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 14 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;
		
		wait_cycles = 255 - written_value;

		APB_WRITE(2'b01, 8'h10);
		repeat (wait_cycles / 2) @ (posedge CLK_in[0]);
		
		APB_WRITE(2'b01, 8'h00);
		#500;
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[0]) begin
			$display("FAULTY - Abnormal operation");
		end else begin
			$display("PASS - Normal operation");
		end
		
		APB_WRITE(2'b01, 8'h10);
		repeat ((wait_cycles / 2) + 10) @ (posedge CLK_in[0]);
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[0]) begin
			$display("PASS - Normal operation");
		end else begin
			$display("FAULTY - Abnormal operation");
		end
	end
endtask

// Task 15: Test countdown with pause check (PCLKx2)
task countdw_pause_countdw_pclk2;
	reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 15 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;
		
		wait_cycles = written_value;

		APB_WRITE(2'b01, 8'h30);
		repeat (wait_cycles / 2) @ (posedge CLK_in[0]);
		
		APB_WRITE(2'b01, 8'h00);
		#500;
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[1]) begin
			$display("FAULTY - Abnormal operation");
		end else begin
			$display("PASS - Normal operation");
		end
		
		APB_WRITE(2'b01, 8'h30);
		repeat ((wait_cycles / 2) + 10) @ (posedge CLK_in[0]);
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[1]) begin
			$display("PASS - Normal operation");
		end else begin
			$display("FAULTY - Abnormal operation");
		end
	end
endtask

// Task 16: Test countup with reset check countdown (PCLKx2)
task countup_reset_countdw_pclk2;
	reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 16 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;
		
		wait_cycles = 255 - written_value;

		APB_WRITE(2'b01, 8'h10);
		repeat (wait_cycles / 2) @ (posedge CLK_in[0]);
		
		PRESETn = 1'b0;
		#30;
		
		@ (posedge PCLK);
		PRESETn = 1'b1;
		#30;
		
		APB_READ(2'b00, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TDR: PASS");
		end else begin	
			$display("Register TDR: FAILED");
		end
		
		APB_READ(2'b01, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TCR: PASS");
		end else begin	
			$display("Register TCR: FAILED");
		end
		
		APB_READ(2'b10, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TSR: PASS");
		end else begin	
			$display("Register TSR: FAILED");
		end
		
		wait_cycles = written_value;
		
		APB_WRITE(2'b00, written_value);
		#15;
		
		APB_WRITE(2'b01, 8'hB0);
		repeat (wait_cycles + 5) @ (posedge CLK_in[0]);
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[1]) begin
			$display("PASS - Normal operation");
		end else begin
			$display("FAULTY - Abnormal operation");
		end
	end
endtask

// Task 17: Test countdown with reset check countup (PCLKx2)
task countdw_reset_countup_pclk2;
	reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 17 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;
		
		wait_cycles = written_value;

		APB_WRITE(2'b01, 8'h30);
		repeat (wait_cycles / 2) @ (posedge CLK_in[0]);
		
		PRESETn = 1'b0;
		#30;
		
		//@ (posedge PCLK);
		PRESETn = 1'b1;
		#30;
		
		APB_READ(2'b00, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TDR: PASS");
		end else begin	
			$display("Register TDR: FAILED");
		end
		
		APB_READ(2'b01, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TCR: PASS");
		end else begin	
			$display("Register TCR: FAILED");
		end
		
		APB_READ(2'b10, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TSR: PASS");
		end else begin	
			$display("Register TSR: FAILED");
		end
		
		wait_cycles = 255 - written_value;
		
		APB_WRITE(2'b00, written_value);
		#15;
		
		APB_WRITE(2'b01, 8'h90);
		repeat (wait_cycles + 5) @ (posedge CLK_in[0]);
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[0]) begin
			$display("PASS - Normal operation");
		end else begin
			$display("FAULTY - Abnormal operation");
		end
	end
endtask

// Task 18: Test countup with reset load countdown (PCLKx2)
task countup_reset_load_countdw_pclk2;
	reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 18 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;
		
		wait_cycles = 255 - written_value;

		APB_WRITE(2'b01, 8'h10);
		repeat (wait_cycles / 2) @ (posedge CLK_in[0]);
		
		PRESETn = 1'b0;
		#30;
		
		@ (posedge PCLK);
		PRESETn = 1'b1;
		#30;
		
		APB_READ(2'b00, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TDR: PASS");
		end else begin	
			$display("Register TDR: FAILED");
		end
		
		APB_READ(2'b01, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TCR: PASS");
		end else begin	
			$display("Register TCR: FAILED");
		end
		
		APB_READ(2'b10, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TSR: PASS");
		end else begin	
			$display("Register TSR: FAILED");
		end
		
		written_value = $urandom_range(0, 254);
		
		wait_cycles = written_value;
		
		APB_WRITE(2'b00, written_value);
		#15;
		
		APB_WRITE(2'b01, 8'hB0);
		repeat (wait_cycles + 5) @ (posedge CLK_in[0]);
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[1]) begin
			$display("PASS - Normal operation");
		end else begin
			$display("FAULTY - Abnormal operation");
		end
	end
endtask

// Task 19: Test countdown with reset load countup (PCLKx2)
task countdw_reset_load_countup_pclk2;
	reg [7:0] written_value;
	integer wait_cycles;

	begin
		$display("=================================================");
		$display("=====  Task 19 =====");
		written_value = $urandom_range(0, 254);
		APB_WRITE(2'b00, written_value);
		#15;

		APB_WRITE(2'b01, 8'h80);
		#15;
		
		wait_cycles = written_value;

		APB_WRITE(2'b01, 8'h30);
		repeat (wait_cycles / 2) @ (posedge CLK_in[0]);
		
		PRESETn = 1'b0;
		#30;
		
		@ (posedge PCLK);
		PRESETn = 1'b1;
		#30;
		
		APB_READ(2'b00, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TDR: PASS");
		end else begin	
			$display("Register TDR: FAILED");
		end
		
		APB_READ(2'b01, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TCR: PASS");
		end else begin	
			$display("Register TCR: FAILED");
		end
		
		APB_READ(2'b10, read_data);
		#15;
		if (read_data == 8'h00) begin
			$display("Register TSR: PASS");
		end else begin	
			$display("Register TSR: FAILED");
		end
		
		written_value = $urandom_range(0, 254);
		
		wait_cycles = 255 - written_value;
		
		APB_WRITE(2'b00, written_value);
		#15;
		
		APB_WRITE(2'b01, 8'h90);
		repeat (wait_cycles + 5) @ (posedge CLK_in[0]);
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[0]) begin
			$display("PASS - Normal operation");
		end else begin
			$display("FAULTY - Abnormal operation");
		end
	end
endtask

// Task 20: Fake underflow (PCLKx2)
task fake_underflow;
	reg [7:0] written_value;
	integer wait_cycles;
	
	begin
		$display("=================================================");
		$display("=====  Task 20 =====");
		APB_WRITE(2'b00, 8'h00);
		#15;
		
		APB_WRITE(2'b01, 8'h80);
		#15;
		
		APB_WRITE(2'b01, 8'h20);
		#15;
		
		APB_WRITE(2'b00, 8'hff);
		#15;
		
		APB_WRITE(2'b01, 8'h80);
		#15;
		
		APB_WRITE(2'b01, 8'h20);
		#15;
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[1]) begin
			$display("FAULTY - Abnormal operation");
		end else begin
			$display("PASS - Normal operation");
		end
	end
endtask

// Task 21: Fake overflow (PCLKx2)
task fake_overflow;
	reg [7:0] written_value;
	integer wait_cycles;
	
	begin
		$display("=================================================");
		$display("=====  Task 21 =====");
		APB_WRITE(2'b00, 8'hff);
		#15;
		
		APB_WRITE(2'b01, 8'h80);
		#15;
		
		APB_WRITE(2'b01, 8'h00);
		#15;
		
		APB_WRITE(2'b00, 8'h00);
		#15;
		
		APB_WRITE(2'b01, 8'h80);
		#15;
		
		APB_WRITE(2'b01, 8'h00);
		#15;
		
		APB_READ(2'b10, read_data);
		$display("TSR: %b", read_data);
		if (read_data[0]) begin
			$display("FAULTY - Abnormal operation");
		end else begin
			$display("PASS - Normal operation");
		end
	end
endtask

initial begin
	PRESETn = 0;
	#20;
	@ (posedge PCLK);
	PRESETn = 1;

//	tdr_test;
//	Doc ghi cac thanh ghi
/*	APB_WRITE(2'b00, 8'h45);
	#15;
	
	APB_WRITE(2'b00, 8'hAB);
	#15;

OB	APB_WRITE(2'b00, 8'h19);
	#15;

	APB_WRITE(2'b01, 8'hE9);
	#15;

	APB_WRITE(2'b01, 8'h4F);
	#15;

	APB_WRITE(2'b01, 8'hEF);
	#15;

	APB_WRITE(2'b10, 8'hFF);
	#15;

	APB_READ(2'b00, read_data);
	#15;

	APB_READ(2'b01, read_data);
	#15;

	APB_READ(2'b10, read_data);
	#1000;
*/

//	Dem len voi gia tri load tu TDR
/*	APB_WRITE(2'b00, 8'hEF);
	#15;
	
	APB_WRITE(2'b01, 8'h90);
	#500;

	APB_WRITE(2'b00, 8'h54);
	#15;

	APB_WRITE(2'b01, 8'h90);
	#500;
*/

//	Dem len voi gia tri mac dinh
/*	APB_WRITE(2'b00, 8'hEF);
	#15;

	APB_WRITE(2'b01, 8'h10);
	#15;
*/

//      Dem xuong voi gia tri load tu TDR
/*        APB_WRITE(2'b00, 8'h08);
        #15;
	
	APB_WRITE(2'b01, 8'hB3);
	#15;
*/

//	Dem xuong voi gia tri mac dinh
/*	
	APB_WRITE(2'b00, 8'h04);
	#15;

	APB_WRITE(2'b01, 8'hFC);
	#150;

	APB_WRITE(2'b10, 8'hFF);
	#15;

	APB_WRITE(2'b11, 8'hAB);
	#15;
	
	APB_READ(2'b00, read_data);
	#15;

	APB_READ(2'b01, read_data);
	#15;

	APB_READ(2'b10, read_data);
	#15;
	#5500;

	APB_WRITE(2'b10, 8'hFF);
	#15;
*/

	tdr_test;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
		
	tcr_test;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	tsr_test;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	null_address_test;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	mixed_address_test;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countup_forkjoin_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countup_forkjoin_pclk4;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countup_forkjoin_pclk8;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countup_forkjoin_pclk16;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countdown_forkjoin_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countdown_forkjoin_pclk4;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countdown_forkjoin_pclk8;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countdown_forkjoin_pclk16;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countup_pause_countup_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countdw_pause_countdw_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countup_reset_countdw_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countdw_reset_countup_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countup_reset_load_countdw_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	countdw_reset_load_countup_pclk2;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	fake_underflow;
	
	PRESETn = 1'b0;
	#30;
	@ (posedge PCLK);
	PRESETn = 1'b1;
	#30;
	
	fake_overflow;

//	$exit;
//	#10000;
	$stop;
end
endmodule