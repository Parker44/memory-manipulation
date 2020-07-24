module two_byte_memoryTest;
  
  reg			clk;			// clock
  reg			en;				// enable
  reg	[3:0] 	pc_in;			// command
  wire	[7:0] 	data_out;		// output data
  wire			int_wait;		// waiting for integer input
  wire	[7:0] 	data_a;			// for testing
  wire	[7:0] 	data_b;			// for testing
  
  two_byte_memory two_byte_memory_test(
    .clk(clk),
    .en(en),
    .pc_in(pc_in),
    .data_out(data_out),
    .int_wait(int_wait),
    .data_a(data_a),
    .data_b(data_b)
  );
  
  initial begin
    clk = 0;
    en = 0;
    pc_in = 0;
  end
  
  always
    #5 clk = ~clk;
  
  initial begin
    // Dump waves
    $dumpfile("dump.vcd");
    $dumpvars(1, two_byte_memoryTest);
    
    /* TESTS */
    
    /* Clear reg(A) and output */
    
    $display("TEST:");
    $display("Clear and output reg(A).");
    
    pc_in = 4'b0000;
    toggle_en;
	pc_in = 4'b1010;
    toggle_en;

    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    /* Clear reg(B) and output */
    
    $display("\nTEST:");
    $display("Clear and output reg(B).");
    
    pc_in = 4'b0001;
    toggle_en;
	pc_in = 4'b1011;
    toggle_en;

    $display("Expected reg(B): 0, Actual reg(B): %0b", data_out);
    
    /* Increment reg(A) once and reg(B) twice and output both */
    
    $display("\nTEST:");
    $display("Increment reg(A) once and increment reg(B) twice.");
    
    pc_in = 4'b0010;	// inc reg(A)
    toggle_en;
    
    pc_in = 4'b0011;	// inc reg(B)
    toggle_en;
    
    pc_in = 4'b0011;    // inc reg(B)
    toggle_en;
    
    pc_in = 4'b1010;	// output reg(A)
    toggle_en;

    $display("Expected reg(A): 1, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;	// output reg(B)
    toggle_en;

    $display("Expected reg(B): 10, Actual reg(B): %0b", data_out);
    
    /* Decrement reg(A) and reg(B) and output both */
    
    $display("\nTEST:");
    $display("Decrement reg(A) and reg(B) once.");
    
    pc_in = 4'b0100;	// dec reg(A)
    toggle_en;
    
    pc_in = 4'b0101;	// dec reg(B)
    toggle_en;
    
    pc_in = 4'b1010;	// output reg(A)
    toggle_en;
    
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;	// output reg(B)
    toggle_en;

    $display("Expected reg(B): 1, Actual reg(B): %0b", data_out);
    
    /* 
     * Input 1010 (10) to reg(A)
     * Input 1111 (15) to reg(B)
     * Output both
     */
    
    $display("\nTEST:");
    $display("Input 1010 (10) to reg(A) and input 1111 (15) to reg(B)");
    
    pc_in = 4'b0110;
    toggle_en;
    pc_in = 4'b1010;	// input value of 10
    toggle_en;
    
    pc_in = 4'b0111;
    toggle_en;
    pc_in = 4'b1111;	// input value of 15
    toggle_en;
    
    pc_in = 4'b1010;	// output reg(A)
    toggle_en;
    
    $display("Expected reg(A): 1010, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;	// output reg(B)
    toggle_en;
    
    $display("Expected reg(B): 1111, Actual reg(B): %0b", data_out);
    
    /*
     * Clear reg(A)
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 clear reg(A)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0000;
    toggle_en;
    
    pc_in = 4'b1000;
    toggle_en;
    
    $display("Clear reg(A)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    clear reg(A)");
    
    #20 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    /*
     * Clear reg(B) and clear reg(A)
     * Call dec/repeat command 
     * 		- decrement: reg(B)
     *		- repeat: 	 clear reg(A)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0001;
    toggle_en;
    
    pc_in = 4'b0000;
    toggle_en;
    
    pc_in = 4'b1001;
    toggle_en;
    
    $display("Clear reg(B) and clear reg(A)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(B)");
    $display("\t- repeat:    clear reg(A)");
    
    #20 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    #20 pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 0, Actual reg(B): %0b", data_out);
    
    /*
     * Clear reg(B)
     * Set reg(A) to 0101 (5)
     * Increment reg(B)
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 increment reg(B)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0001;		// clear reg(B)
    toggle_en;
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0101;		// input 5 reg(A)
    toggle_en;
    
    pc_in = 4'b0011;		// increment reg(B)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    $display("Clear reg(B) and set reg(A) = 0101 (5)");
    $display("Increment reg(B)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    increment reg(B)");
    
    // allow sufficient time for dec/repeat to finish
    #60 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 101, Actual reg(B): %0b", data_out);
    
    /*
     * Clear reg(A)
     * Set reg(B) to 0101 (5)
     * Increment reg(A)
     * Call dec/repeat command 
     * 		- decrement: reg(B)
     *		- repeat: 	 increment reg(A)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0000;		// clear reg(A)
    toggle_en;
    
    pc_in = 4'b0111;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b0101;		// input 5 reg(B)
    toggle_en;
    
    pc_in = 4'b0010;		// increment reg(A)
    toggle_en;
    
    pc_in = 4'b1001;		// dec/repeat
    toggle_en;
    
    $display("Clear reg(A) and set reg(B) = 0101 (5)");
    $display("Increment reg(A)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(B)");
    $display("\t- repeat:    increment reg(A)");
    
    // allow sufficient time for dec/repeat to finish
    #60 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 101, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 0, Actual reg(B): %0b", data_out);
    
    /*
     * Set reg(A) to 0110 (6)
     * Decrement reg(A)
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 decrement reg(A)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0110;		// input 6 reg(A)
    toggle_en;
    
    pc_in = 4'b0100;		// decrement reg(A)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    $display("Set reg(A) to 0110 (6)");
    $display("Decrement reg(A)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    decrement reg(A)");
    
    // allow sufficient time for dec/repeat to finish
    #60 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    /*
     * Set reg(B) to 0110 (6)
     * Decrement reg(B)
     * Call dec/repeat command 
     * 		- decrement: reg(B)
     *		- repeat: 	 decrement reg(B)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0111;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b0110;		// input 6 reg(B)
    toggle_en;
    
    pc_in = 4'b0101;		// decrement reg(B)
    toggle_en;
    
    pc_in = 4'b1001;		// dec/repeat
    toggle_en;
    
    $display("Set reg(B) to 0110 (6)");
    $display("Decrement reg(B)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(B)");
    $display("\t- repeat:    decrement reg(B)");
    
    // allow sufficient time for dec/repeat to finish
    #60 pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);

    /*
     * Set reg(A) to 0101 (5)
     * Set reg(B) to 0110 (6)
     * Decrement reg(B)
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 decrement reg(B)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0101;		// input 5 reg(A)
    toggle_en;
    
    pc_in = 4'b0111;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b0110;		// input 6 reg(B)
    toggle_en;
    
    pc_in = 4'b0101;		// decrement reg(B)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    $display("Set reg(A) to 0101 (5)");
    $display("Set reg(B) to 0110 (6)");
    $display("Decrement reg(B)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    decrement reg(B)");
    
    // allow sufficient time for dec/repeat to finish
    #70 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 1, Actual reg(B): %0b", data_out);
    
    /*
     * Set reg(A) to 0101 (5)
     * Output reg(A) value
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 output reg(A)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0101;		// input 5 reg(A)
    toggle_en;
    
    pc_in = 4'b1010;		// output reg(A)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    $display("Set reg(A) to 0101 (5)");
    $display("Output reg(A)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    decrement reg(A)");
    
    // allow sufficient time for dec/repeat to finish
    #70 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    /*
     * Set reg(B) to 0101 (5)
     * Output reg(B) value
     * Call dec/repeat command 
     * 		- decrement: reg(B)
     *		- repeat: 	 output reg(B)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0111;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b0101;		// input 5 reg(B)
    toggle_en;
    
    pc_in = 4'b1011;		// output reg(B)
    toggle_en;
    
    pc_in = 4'b1001;		// dec/repeat
    toggle_en;
    
    $display("Set reg(B) to 0101 (5)");
    $display("Output reg(B)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(B)");
    $display("\t- repeat:    output reg(B)");
    
    // allow sufficient time for dec/repeat to finish
    #70 pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    /*
     * Set reg(A) to 0101 (5)
     * Set reg(B) to 1010 (10)
     * Output reg(B) value
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 output reg(B)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0101;		// input 5 reg(A)
    toggle_en;
    
    pc_in = 4'b0111;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b1010;		// input 10 reg(B)
    toggle_en;
    
    pc_in = 4'b1011;		// output reg(B)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    $display("Set reg(A) to 0101 (5)");
    $display("Set reg(B) to 1010 (10)");
    $display("Output reg(B)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    output reg(B)");
    
    // allow sufficient time for dec/repeat to finish
    #70 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 1010, Actual reg(B): %0b", data_out);
    
    /*
     * Set reg(B) to 0101 (5)
     * Set reg(A) to 1010 (10)
     * Output reg(A) value
     * Call dec/repeat command 
     * 		- decrement: reg(B)
     *		- repeat: 	 output reg(A)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0111;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0101;		// input 5 reg(A)
    toggle_en;
    
    pc_in = 4'b0110;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b1010;		// input 10 reg(B)
    toggle_en;
    
    pc_in = 4'b1010;		// output reg(B)
    toggle_en;
    
    pc_in = 4'b1001;		// dec/repeat
    toggle_en;
    
    $display("Set reg(B) to 0101 (5)");
    $display("Set reg(A) to 1010 (10)");
    $display("Output reg(A)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(B)");
    $display("\t- repeat:    output reg(A)");
    
    // allow sufficient time for dec/repeat to finish
    #70 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 1010, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 0, Actual reg(B): %0b", data_out);
    
    /*
     * Input 1011 (11) to reg(A)
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 input reg(A)
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b1011;		// input 11 reg(A)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    #10 pc_in = 4'b0011;		// input 3 reg(A)
    toggle_en;
    
    #10 pc_in = 4'b0000;		// input 0 reg(A)
    toggle_en;
    
    $display("Set reg(A) to 1011 (11)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    input reg(A)");
    
    // allow sufficient time for dec/repeat to finish
    #10 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    /*
     * Input 1011 (11) to reg(B)
     * Call dec/repeat command 
     * 		- decrement: reg(B)
     *		- repeat: 	 input 3 reg(B)
     *					 input 0 reg(B) -> exits
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0111;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b1011;		// input 11 reg(A)
    toggle_en;
    
    pc_in = 4'b1001;		// dec/repeat
    toggle_en;
    
    #10 pc_in = 4'b0011;		// input 3 reg(A)
    toggle_en;
    
    #10 pc_in = 4'b0000;		// input 0 reg(A)
    toggle_en;
    
    $display("Set reg(B) to 1011 (11)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(B)");
    $display("\t- repeat:    input 3 to reg(B)");
    $display("\t- repeat:    input 0 to reg(B) -> exit since reg(A) = 0");
    
    // allow sufficient time for dec/repeat to finish
    #10 pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 0, Actual reg(B): %0b", data_out);
    
    /*
     * Input 0011 (3) to reg(B)
     * Input 1011 (11) to reg(A)
     * Call dec/repeat command 
     * 		- decrement: reg(B)
     *		- repeat: 	 input 3 to reg(A)
     *					 input 10 to reg(A) -> exits since reg(B) = 0
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0111;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b0011;		// input 3 reg(B)
    toggle_en;
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b1011;		// input 11 reg(A)
    toggle_en;
    
    pc_in = 4'b1001;		// dec/repeat
    toggle_en;
    
    pc_in = 4'b0011;		// input 3 reg(A)
    toggle_en;
    
    pc_in = 4'b1010;		// input 10 reg(A)
    toggle_en;
    
    $display("Set reg(B) to 0011 (3)");
    $display("Set reg(A) to 1010 (11)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(B)");
    $display("\t- repeat:    input 3 to reg(A)");
    $display("\t- repeat:    input 10 to reg(A) -> exits since reg(B) = 0");
    
    // allow sufficient time for dec/repeat to finish
    #10 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 1010, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 0, Actual reg(B): %0b", data_out);
    
    /*
     * Input 0011 (3) to reg(A)
     * Input 1011 (11) to reg(B)
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 input 3 to reg(B)
     *					 input 10 to reg(B) -> exits since reg(A) = 0
     */
    
    $display("\nTEST:");
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0011;		// input 3 reg(A)
    toggle_en;
    
    pc_in = 4'b0111;		// input reg(B)
    toggle_en;
    
    pc_in = 4'b1011;		// input 11 reg(B)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    pc_in = 4'b0011;		// input 3 reg(B)
    toggle_en;
    
    pc_in = 4'b1010;		// input 10 reg(B)
    toggle_en;
    
    $display("Set reg(A) to 0011 (3)");
    $display("Set reg(B) to 1010 (11)");
    $display("Call dec/repeat command");
    $display("\t- decrement: reg(A)");
    $display("\t- repeat:    input 3 to reg(B)");
    $display("\t- repeat:    input 10 to reg(B) -> exits since reg(A) = 0");
    
    // allow sufficient time for dec/repeat to finish
    #10 pc_in = 4'b1010;
    toggle_en;
    $display("Expected reg(A): 0, Actual reg(A): %0b", data_out);
    
    pc_in = 4'b1011;
    toggle_en;
    $display("Expected reg(B): 1010, Actual reg(B): %0b", data_out);
    
	/*
     * Input 0110 (6) to reg(A)
     * Increment reg(A)
     * Call dec/repeat command 
     * 		- decrement: reg(A)
     *		- repeat: 	 increment reg(A)
     *
     * INFINITE LOOP EXPECTED: VALUE WILL NEVER CHANGE
     *
     * View in waveform viewer to observe that value never changes
     */
    
    pc_in = 4'b0110;		// input reg(A)
    toggle_en;
    
    pc_in = 4'b0110;		// input 6 reg(A)
    toggle_en;
    
    pc_in = 4'b0010;		// increment reg(A)
    toggle_en;
    
    pc_in = 4'b1000;		// dec/repeat
    toggle_en;
    
    
  end
  
  task toggle_en;
    begin
      #10 en = ~en;
      #10 en = ~en;
    end
  endtask
  
  initial
    #3500 $finish;
  
endmodule